import unittest
from game import Game
import pymysql

class game_tests(unittest.TestCase):
    def connect(self):
        cnx = pymysql.connect(host='localhost',user = "root",password="psswd",db ='final_project',charset='utf8mb4')
        return cnx
    
    def test_create_designer(self):
        cnx = self.connect()
        g = Game(cnx)

    def test_load_object(self):
        g = Game(self.connect())
        g.load_game_from_bgg(98778)
        self.assertEqual("Hanabi",g.bg_name)
        
    def test_check_not_present(self):
        g = Game(self.connect())
        self.assertTrue(g._check_not_present("designer","designer_id",500))

    def test_save_to_db(self):
        g = Game(self.connect())
        g.load_game_from_bgg(98778)
        g.save_game_to_db()