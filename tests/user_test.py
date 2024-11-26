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
        u.create_account(username,password,birthday)
       #cur.execute(f"DELETE FROM app_user WHERE username = {username}")

        