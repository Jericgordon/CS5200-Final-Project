import hashlib
import pymysql
from datetime import date



class User():
    def __init__(self,cnx:pymysql.connect):
        self.cnx = cnx
        self.username = ""
        self.status = 0 #we need a marker to see if folks are actually logged in or not, as it would be unwise to keep the password

    def _hash(self,password:str):
        h = hashlib.sha512()
        h.update(password.encode('ASCII'))
        hash = h.hexdigest()
        return hash


    def login(self,username,password:str) -> bool:
        cur = self.cnx.cursor()
        if len(username) > 64 or len(username) == 0: #check for too large of a username
            raise AttributeError("Cannot have a username larger than 64 characters or null username")
        hash = self._hash(password)
        cur.execute(f'SELECT check_password("{username}","{hash}")')
        self.status = cur.fetchone()[0]
        cur.close()
        if (self.status == 1):
            self.username = username
        return self.status
    
    def create_account(self,username,password,date_of_birth:date) -> None:
        if len(username) > 64 or len(username) == 0: #check for too large of a username
            raise AttributeError("Cannot have a username larger than 64 characters or null username")
        
        cur = self.cnx.cursor()
        cur.execute(f'INSERT INTO app_user VALUES("{username}","{self._hash(password)}","{date_of_birth.year}-{date_of_birth.month}-{date_of_birth.day}");')
        self.cnx.commit()
        cur.close()
        self.login(username,password)

    def delete_account(self,username,password) -> int:
        if (self.login(username,password) != 1): #check for valide credentials
            return False
        
        cur = self.cnx.cursor()
        cur.execute(f"DELETE FROM app_user WHERE username = '{username}'")
        self.cnx.commit()
        cur.close()
        return True

    def add_friend(self,f_username:str) -> None:
        cur = self.cnx.cursor()
        cur.execute(f"SELECT * FROM app_user WHERE username = '{f_username}'")
        if (cur.fetchone()[0] != f_username):
            raise ValueError("Could not find friend to add")
        if (self.status == 0):
            raise PermissionError("Must login first")
        cur.callproc("friend_user",[self.username,f_username])
        self.cnx.commit()
        cur.close()

    def create_collection(self,collection_name:str,collection_location:str):
        if len(collection_name) <= 0 or len(collection_name) > 64:
            raise AttributeError("Invalid length of collection name")
        if len(collection_location) <= 0 or len(collection_location) > 64:
            raise AttributeError("Invalid length of collection location")
        if (self.status == 0):
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.execute(f'CALL create_collection("{self.username}","{collection_name}","{collection_location}");')
        self.cnx.commit()
        cur.close()

    def get_user_collections(self) -> list:
        if self.status == 0:
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.callproc('get_libraries_for', [self.username])
        libs = cur.fetchall()
        cur.close()
        return [lib[1] for lib in libs]
    
    def get_list_of_friends(self) -> list:
        if self.status == 0:
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.callproc('get_friends_of', [self.username])
        friends = cur.fetchall()
        return [tuple[0] for tuple in friends]


    def get_friends_libraries(self,friend) -> dict:
        if self.status == 0:
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.callproc('get_libraries_for', [friend])
        libraries_tuple = cur.fetchall()
        return {tuple[1]:tuple[0] for tuple in libraries_tuple}

    def add_game_to_collection(self,name,game_id) -> None:
        if (self.status == 0):
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.execute(f'CALL add_game_to_collection("{game_id}","{self.username}","{name}");')
        self.cnx.commit()
        cur.close()
    
    def get_potential_friends(self) -> list: #users need a list of users they could friend
        cur = self.cnx.cursor()
        cur.callproc('get_potential_friends', [self.username])
        users = cur.fetchall()
        cur.close()
        return [user[0] for user in users] 

    def get_recommendations_from(self,library_id:int):
        cur = self.cnx.cursor()
        cur.callproc("recommend_games_from_library",[self.username, library_id])
        results = cur.fetchall()
        cur.close()
        return results
    
    def get_recommended_games_from_all(self):
        cur = self.cnx.cursor()
        cur.callproc("recommend_games", [self.username])
        res = cur.fetchall()
        cur.close()
        return res

    def rate_game(self,game_id:int,rating:int,user_comment:str) -> None:
        if rating < 1 or rating > 10:
            raise AttributeError("Must have attribute between 1 and 10")
        if len(user_comment) > 1024:
            raise AttributeError("Must have user comment between 1 and 1024 characters")
        if self.status != 1:
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.callproc("rate_game",[self.username,game_id,rating,user_comment])
        self.cnx.commit()
        cur.close()

    def get_review(self,game_id:int):
        if self.status != 1:
            raise PermissionError("Must login first")
        cur = self.cnx.cursor()
        cur.callproc("get_review",[self.username,game_id])
        res = cur.fetchone()
        cur.close()
        return res
    
    def delete_review(self,game_id:int)-> None:
        cur = self.cnx.cursor()
        cur.execute(f'DELETE FROM rates WHERE username = "{self.username}" AND game_id = {game_id}')
        self.cnx.commit()
        cur.close()

    def edit_review(self, game_id:int, new_rating:int, new_description:str)->None:
        cur = self.cnx.cursor()
        cur.execute('update_rating', (self.username, game_id, new_rating, new_description))
        self.cnx.commit()
        cur.close()
    



