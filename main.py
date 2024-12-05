import pymysql
from user import User
from ui import Python_Ui


def login():
    while True:
        username = input("Wha1t is your db username?")
        password = input("What is your db password?")
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
    u = Python_Ui(cnx)



if __name__ == '__main__':
    main()