import hashlib
import pymysql
from datetime import date



class User():
    def __init__(self,cnx):
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

    def delete_account(self,username,password) -> None:
        if (self.login(username,password) != 1): #check for valide credentials
            return
        
        cur = self.cnx.cursor()
        cur.execute(f"DELETE FROM app_user WHERE username = '{username}'")
        self.cnx.commit()
        cur.close()

    def add_friend(self,f_username:str) -> None:
        cur = self.cnx.cursor()
        cur.execute(f"SELECT * FROM app_user WHERE username = '{f_username}'")
        if (cur.fetchone()[0] != f_username):
            raise ValueError("Could not find friend to add")
        if (self.status == 0):
            raise PermissionError("Must login first")
        cur.execute(f"INSERT INTO friends VALUES('{self.username}','{f_username}');")
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
        cur.execute(f"SELECT MAX(collection_id) FROM collection;")
        id = cur.fetchone()[0]
        if id == None:
            id = 1
        else:
            id += 1
        cur.execute(f"INSERT INTO collection VALUES({id},'{collection_name}','{collection_location}');")
        cur.execute(f"INSERT INTO owns VALUES('{self.username}',{id}) ")
        self.cnx.commit()
        cur.close() 

    def add_game_to_collection(self,name,game_id) -> None:
        ... # to be implemented after the game class is created



    



