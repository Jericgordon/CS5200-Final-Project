"""
A simple API which runs our database.
Actions contained:
-Add User
-Add Friend
-Add Game to Library
-Rate Game
"""
import pymysql
import Boardgamegeek_Interface
import game as g
from user import User
import datetime
class Python_Ui:
    """
    Needs to be integrated with User
    """
    def __init__(self,cnx:pymysql.connect):
        self.cnx = cnx
        self.bgg = Boardgamegeek_Interface.Boardgamegeek_Interface()
        self.user = self.login()
        self.game_object = g.Game(cnx) #not really for storing a game, but for game operations
        self.run_main_loop()
        

    def get_user_choice(self, options, message="\n"): 
        """
        When given a list of possible choices as strings, 
        enters a loop which repeats until the user selects a valid choice.
        Returns the choice the user made.
        """
        for i in range(1, len(options)+1):
            print(f"{i}) {options[i-1]}")
        user_choice = -1
        while user_choice not in range(1, len(options)+1):
            user_choice = input(message)
            if user_choice.isnumeric():
                user_choice = int(user_choice)
            else:
                print(f"Sorry, please enter a number between 1 and {len(options)+1}")
                user_choice = -1
        return user_choice
    
    def _get_birthday(self):
        while True:
            year = input("What year were you born?")
            month = input("What number month were you born?")
            day = input("What day were you born on?")
            if year.isnumeric() and month.isnumeric() and day.isnumeric():
                try:
                    d = datetime.date(int(year),int(month),int(day))
                    return d
                except ValueError:
                    print("Not a valid date")
            else:
                print("Please type only numbers")

    def _get_rating_and_description(self):
        rating = "q"
        while True: # rating input filtering
            rating = input("What would you rate this game (out of ten)? ")
            if not rating.isnumeric(): 
                print("Sorry, integers only please!")
            else:
                rating = int(rating)
                break
        while True: #  #description input filtering
            desc = input("What would you like to say about this game?\n")
            if len(desc) >= 1024:
                print("length of comment not supported")
            else:
                break
        return (rating, desc)

    def login(self):
        while True:
            print("Welcome to Jen and Ari's Board Game Hub! What would you like to do?")
            choice = self.get_user_choice(["Login", "Create a New Account"])
            user = User(self.cnx)
            if choice == 1:
                while True:
                    username = input("What is your username?")
                    password = input("What is your password?")
                    if len(username) > 64 or len(username) == 0:
                        print("Invalid length of username")
                        continue
                   
                    user.login(username,password)
                    if user.status == 1:
                        print("login successful")
                        return user
                    else:
                        print("INVALID LOGIN")
            else:
                while True:
                    username = input("What would you like your username to be?\n")
                    password = input("What would you like your password to be?\n")
                    birthday = self._get_birthday()
                    try:
                        user.create_account(username,password,birthday)
                        return user
                    except pymysql.err.IntegrityError:
                        print("username already in use. Please choose another one")
            
    def find_game(self):
        """
        Queries the database for a game the user wants to review or add to a collection.
        If the game cannot be found, moves on to query boardgamegeek and proactively insert the selected game into the database.
        """
        title = input("What game are you thinking of?\n")
        #Try to look for game in database.

        print("Is the game you have in mind contained below?")
      
        results = self.game_object.get_list_of_games_in_db(title)
        choices = [key for key in results.keys()]
        choices.append("None of the Above")
        choice = self.get_user_choice(choices)
        if choice < len(choices):
            return results[choices[choice-1]]
            #Return the ID
        else:
            games = self.bgg.search_for_games(title)
            options = [key for key in games.keys()]
            choice = self.get_user_choice(options)
            id = games[options[choice-1]]
            game = g.Game(self.cnx)
            game.load_game_from_bgg(id)
            game.save_game_to_db()
            return id
    
    def add_friend(self):
        user_list = self.user.get_potential_friends()
        user_list.append("None")
        print("Which of the following users would you like to befriend?")
        choice = self.get_user_choice(user_list)
        if choice == len(user_list):
            return
        print(f"Friending... {user_list[choice-1]}")
        self.user.add_friend(user_list[choice-1])
    
    def rate_game(self):
        game = self.find_game()
        review = self.user.get_review(game)
        if review != None:
            print("You have already reviewed this game.")
            print(f"You wrote: {review}")
            options = ["Edit the review","Delete the review","go back"]
            choice = self.get_user_choice(options)
            if choice == 3: #leaves the revew as is
                return
            self.user.delete_review(game) # Deletes the game
            if choice == 2: 
                return
            else:
                rating, desc = self._get_rating_and_description()
                self.user.edit_review(game, rating, desc)
                return
            
        rating, desc = self._get_rating_and_description()
        self.user.rate_game(game,rating,desc)


    def collect_game(self):
        print("Which library are you going to be modifying?")
        libs = self.user.get_user_collections()

        libs.append("Add a New Library")
        while True:
            #Using a loop here-- the user can keep adding new libraries until they pick one
            choice = self.get_user_choice(libs)
            if choice == len(libs):
                #This indicates that the user wishes to create a new library
                name = "a"*500
                while len(name) >=64:
                    name = input("Please enter a name for your new library (max length 64 characters)")
                location = "a"*500
                while len(location) >=64:
                    location = input("Where is this library located? (max length 64 characters)")
                self.user.create_collection(name,location)
                library_name = name
            else:
                library_name = libs[choice-1]
            break

        print(f"You're working with the library called {library_name}")

        game = self.find_game()
        self.user.add_game_to_collection(library_name,game)


    def query_games(self):
        print("Would you like to find a game to play in a friend's library, or find a brand new game to try?")
        choice = self.get_user_choice(["Check a friend's library", "Query all known games"])
        cur = self.cnx.cursor()

        if choice == 1:
            #Case that we are examining a friend's library
            friends = self.user.get_list_of_friends()
            friends.append("I changed my mind")
            friend = self.get_user_choice(friends)
            if friend == len(friends):
                choice = 2
                #switch to other case
            else:
                friend = friends[friend-1]
                print("Which library would you like to query?")
                libarary_results = self.user.get_friends_libraries(friend)
                libraries = [library for library in libarary_results.keys()]
                libraries.append("query all libraries")
                choice = self.get_user_choice(libraries)
                if choice < len(libraries):
                    library_id = libarary_results[libraries[choice]] #Accessing library ID
                    response = self.user.get_recommendations_from(library_id)
                else:
                    response = self.user.get_recommended_games_from_all()

        if choice == 2:
            #Case that we are querying ALL libraries
            response = self.user.get_recommended_games_from_all()
        if response == None:
            print("No valid games to rate")
        else:
            for each in response:
                print(f"We think you'll rate {each[0]} a {each[2]:.2f}")
            input("Press enter to continue")

    def run_main_loop(self):
        
        supported_actions = [
            "Add a Friend",
            "Add a Game to a Collection",
            "Rate a Game I Played",
            "Find a Game I'd Like",
            "Delete my account",
            "Quit"
        ]
        running = True
        while running:
            print("\nWhat would you like to do?")
            choice = self.get_user_choice(supported_actions)
            match choice:
                case 1:
                    self.add_friend()
                case 2:
                    self.collect_game()
                case 3:
                    self.rate_game()
                case 4:
                    self.query_games()
                case 5:
                    
                    passwd = input("Type your password to confirm\n")
                    if self.user.delete_account(self.user.username,passwd):
                        print("Account Deleted successfully")
                        running = False
                    else:
                        print("Incorrect password, cannot delete\n")
                case 6:
                    print("QUITTING")
                    running = False
