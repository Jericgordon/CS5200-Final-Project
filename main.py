import pymysql
from user import User
import unittest

def login():
    while True:
        username = input("What is your username?")
        password = input("What is your password?")
        try:
            cnx = pymysql.connect(host='localhost',user = username,password=password,\
                                db ='final_project',charset='utf8mb4')
            break
        except pymysql.err.OperationalError:
            print("Invalid credentials")
        
    return cnx


def main():
    # cnx = login()
    cnx = pymysql.connect(host='localhost',user = "root",password="psswd",\
                                db ='final_project',charset='utf8mb4')
    cur = cnx.cursor()



if __name__ == '__main__':
    main()