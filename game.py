import pymysql
import pymysql.cursors
from Boardgamegeek_Interface import Boardgamegeek_Interface
class Game(): #
    def __init__(self,cnx:pymysql.connect):
        self.is_loaded = False #is the game loaded into the class?
        self.cnx = cnx
        self.game_id = 0
        self.bg_name = ""
        self.publication_date = ""
        self.min_players = 0
        self.max_players = 0
        self.min_playeer_age = 0
        self.bg_description = ""
        self.designers = {}
        self.categories = {}
        self.game_awards = {} # we need to have tuples in here with (award_name,award_year). This is to deal with being able to use it as a primary key
        self.game_mechanics = {}
        self.game_categories = {}

    def load_stored_game(self,game_id:int) -> None:
        ...

    def load_game_from_bgg(self,game_id):
        b = Boardgamegeek_Interface()
        results = b.lookup_game(game_id)
        self.game_id = results["boardgame_details"]["gameID"]
        self.bg_name = results["boardgame_details"]["name"]
        self.publication_date = results["boardgame_details"]["publication date"]
        self.min_players = results["boardgame_details"]["min players"]
        self.max_players = results["boardgame_details"]["max players"]
        self.min_player_age = results["boardgame_details"]["min age"]
        self.bg_description = results["boardgame_details"]["description"]
        self.designers = self._load_setup_dict(results,"designers") # {designer_id:designer}
        self.categories = self._load_setup_dict(results,"categories") #category_id:category
        self.game_awards = self._load_setup_dict(results,"awards") # we need to have tuples in here with (award_name,award_year). This is to deal with being able to use it as a primary key
        self.game_mechanics = self._load_setup_dict(results,"mechanics")
        self.game_publishers = self._load_setup_dict(results,"publishers")
        self.is_loaded = True

    def create_game(self):
        ...

    def save_game_to_db(self):
  
        cur = self.cnx.cursor()
        #cur.execute(f"""CALL add_game({self.game_id},"{self.bg_name}","{self.publication_date}",{self.min_players},{self.max_players},{self.min_player_age},"{self.bg_description}");""")
        self._add_designers(cur)
        self.cnx.commit()
        cur.close()

    def _add_designers(self,cur):
        for id,designer in self.designers.items():
            cur.execute(f"CALL add_designer({id},'{designer}',{self.game_id});")
            print(f"added designer {id},{designer}")
        self.cnx.commit()

    def _load_setup_dict(self,data:dict,kind:str):
        all = data[kind]
        return_dict = {}
        for entity in all:
            return_dict[entity["id"]] = entity["name"]
        return return_dict

    def _check_not_present(self,table:str,pk_name:str,pk) -> bool:
        cur = self.cnx.cursor()
        cur.execute(f"SELECT * FROM {table} WHERE {pk_name} = {pk};")
        if cur.fetchone() != None:
            return False
        return True

        
# add a game ->
# what's the name? ->
# api calls -> is it one of these?
    # IF one result;
    # display 3 options
# nope, manually create
#
#