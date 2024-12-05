from user import User
import unittest
import pymysql
import datetime

class user_tests(unittest.TestCase):
    def connect(self):
        cnx = pymysql.connect(host='localhost',user = "root",password="psswd",db ='final_project',charset='utf8mb4')
        return cnx

    def test_valid_invalid_login(self):
        cnx = self.connect()
        u = User(cnx)
        self.assertEqual(1,u.login("tim","test")) #valid tests
        self.assertEqual(0,u.login("tim","albert")) #invalid test
    
    def test_invalid_username(self):
        long_username = "1234212kasdfasdfasdfasdfasdfasdfasdfasdfasdfsdfasdfasdfasdfsasdfasdfasdfsdfasdf"
        while len(long_username) < 64:
            print("hi")
            long_username = long_username + long_username
        cnx = self.connect()
        u = User(cnx) 
        self.assertRaises(AttributeError,u.login,long_username,"hi")
        self.assertRaises(AttributeError,u.login,"","hi")

    def test_create_user(self):
        cnx = self.connect()
        u = User(cnx)
        birthday = datetime.date(1950,12,12)
        username = "alex"
        password = "super343"
        cur = cnx.cursor()
        cur.execute(f"DELETE FROM app_user WHERE username = '{username}'")
        u.create_account(username,password,birthday)

    def test_delete_user(self):
        cnx = self.connect()
        u = User(cnx)
        u.create_account("dave","123",datetime.date(1950,12,12))
        u.delete_account("dave","123")

    def test_add_friend(self):
        cnx = self.connect()
        u = User(cnx)
        u.delete_account("test1","123")
        u.delete_account("test2","123")
        u.create_account("test1","123",datetime.date(1950,12,12))
        u.create_account("test2","123",datetime.date(1950,12,12))
        u.login("test1","123")
        u.add_friend("test2")
        
    def test_create_collection(self):
        cur = self.connect()
        u = User(cur)
        #u.create_account("test3","123",datetime.date(1950,12,12))
        u.login("tim","test")
        u.create_collection("my_collection","home")

    def test_add_game_to_collection(self):
        u = User(self.connect())
        u.login("tim","test")
        u.add_game_to_collection("my_collection",98778)

    def test_rate_game(self):
        u = User(self.connect())
        u.login("tim","test")
        u.rate_game(98778,10,"very good game, played a bunch of it")
