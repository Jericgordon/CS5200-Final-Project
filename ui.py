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
        title = input("What game are you thinking of?\n")
        #Try to look for game in database. If the game isn't there...
        games = self.bgg.search_for_games(title)
        choice = self.get_user_choice([game.name.TEXT for game in games])
        return self.bgg.lookup_game(games[choice-1].objectid)
    
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
                    print("ADDING GAME TO COLLECTION")
                    game = self.find_game()
                    cur = self.cnx.cursor()
                    print(type(cur))
                    
                case 3:
                    print("RATING GAME")
                    cur = self.cnx.cursor()
                    resultArgs = cur.callproc('add_designer', (100, "David Sirloin", 1))
                    print(resultArgs)
                case 4:
                    print("FINDING GAME")
                case 5:
                    print("DELETING ACCOUNT")
                    running = False
                case 6:
                    print("QUITTING")
                    running = False

if __name__ == "__main__":
    test = Python_Ui()