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

class Python_Ui:
    """
    Needs to be integrated with User
    """
    def __init__(self):
        self.bgg = Boardgamegeek_Interface.Boardgamegeek_Interface()
        self.login()
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
    
    def login(self):
        print("Welcome to Jen and Ari's Board Game Hub! What would you like to do?")
        choice = self.get_user_choice(["Login", "Create a New Account"])
        if choice == 1:
            while True:
                # username = input("What is your username?")
                # password = input("What is your password?")
                username = "foo"
                password = "poplop"
                try:
                    cnx = pymysql.connect(host='localhost',user = username,password=password,\
                                    db ='final_project',charset='utf8mb4')
                    break
                except pymysql.err.OperationalError:
                    print("Invalid credentials")
            self.cnx = cnx
        else:
            username = input("What would you like your username to be?\n")
            password = input("What would you like your password to be?\n")
            print("You're logged in!")

    def find_game(self):
        """
        Queries the database for a game the user wants to review or add to a collection.
        If the game cannot be found, moves on to query boardgamegeek and proactively insert the selected game into the database.
        """
        title = input("What game are you thinking of?\n")
        #Try to look for game in database.
        cur = self.cnx.cursor()
        cur.callproc('query_game', (title,))
        games = cur.fetchall()
        print("Is the game you have in mind contained below?")
        choices = [game[1] for game in games]
        choices.append("None of the Above")
        choice = self.get_user_choice(choices)
        if choices[choice-1] != "None of the Above":
            cur.close()
            id = games[choice-1][0]
            return id
            #Return the ID
        else:
            games = self.bgg.search_for_games(title)
            choice = self.get_user_choice([game.name.TEXT for game in games])
            id = games[choice-1].objectid
            game = g.Game(self.cnx)
            game.load_game_from_bgg(id)
            game.save_game_to_db()
            cur.close()
            self.cnx.commit()
            return id
    
    def add_friend(self):
        cur = self.cnx.cursor()
        cur.callproc('get_potential_friends', ('zimbo',))
        users = cur.fetchall()
        choices = []
        for each in users:
            choices.append(each[0])
        choices.append("None")
        print("Which of the following users would you like to befriend?")
        choice = self.get_user_choice(choices)
        if choice == len(choices):
            return
        print(f"Friending... {choices[choice-1]}")
        cur.callproc('friend_user', ('zimbo', choices[choice-1]))
        cur.close()
        self.cnx.commit()
    
    def rate_game(self):
        game = self.find_game()
        searching = True
        while searching:
            rating = input("What would you rate this game (out of five)? ")
            if rating.isnumeric():
                searching=False
                rating = int(rating)
            else:
                print("Sorry, integers only please!")
        desc = input("What would you like to say about this game?\n")
        cur = self.cnx.cursor()
        cur.callproc('rate_game', ('zimbo', game, rating, desc))
        cur.close()
        self.cnx.commit()

    def collect_game(self):
        print("Which library are you going to be modifying?")
        cur = self.cnx.cursor()
        cur.callproc('get_libraries_for', ('zimbo',))
        libs = cur.fetchall()
        library_names = [lib[1] for lib in libs]
        library_names.append("Add a New Library")
        choosing = True
        while choosing:
            #Using a loop here-- the user can keep adding new libraries until they pick one
            choice = self.get_user_choice(library_names)
            if choice == len(library_names):
                #This indicates that the user wishes to create a new library
                name = "a"*500
                while len(name) >=64:
                    name = input("Please enter a name for your new library (max length 64 characters)")
                location = "a"*500
                while len(location) >=64:
                    location = input("Where is this library located? (max length 64 characters)")
                cur.callproc("add_library", ["zimbo", name, location])
                self.cnx.commit()
            else:
                choosing = False
        library_id = libs[choice-1][0]
        print(f"You're working with the library called {libs[choice-1][1]}")

        game = self.find_game()
        print(game)
        cur.callproc('add_game_to_library', (library_id, game))
        cur.close()
        self.cnx.commit()
    
    def query_games(self):
        print("Would you like to find a game to play in a friend's library, or find a brand new game to try?")
        choice = self.get_user_choice(["Check a friend's library", "Query all known games"])
        cur = self.cnx.cursor()
        if choice == 1:
            #Case that we are examining a friend's library
            print("Whose library would you like to query?")
            cur.callproc('get_friends_of', ('zimbo',))
            friends = cur.fetchall()
            friends = [tuple[0] for tuple in friends]
            friends.append("I changed my mind")
            friend = self.get_user_choice(friends)
            if friend == len(friends):
                choice = 2
                #switch to other case
            else:
                friend = friends[friend-1]
                print("Which library would you like to query?")
                cur.callproc("get_libraries_for", (friend,))
                libraries_tuple = cur.fetchall()
                libraries = [tuple[1] for tuple in libraries_tuple]
                libraries.append("None of these options")
                library = libraries_tuple[self.get_user_choice(libraries)-1][0] #Accessing library ID
                cur.callproc("recommend_games_from_library", ("zimbo", library))

        if choice == 2:
            #Case that we are querying ALL libraries
            cur.callproc("recommend_games", ("zimbo",))
        #NO PRINT EXISTS YET. DECIDE HOW WE WANT TO DISPLAY THIS
        

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
            print("What would you like to do?")
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
                    print("DELETING ACCOUNT")
                    running = False
                case 6:
                    print("QUITTING")
                    running = False

if __name__ == "__main__":
    test = Python_Ui()