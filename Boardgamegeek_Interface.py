#!/usr/bin/env python3
from libbgg.apiv1 import BGG
#INSTALL WITH pip install py-bgg
# You can also use version 2 of the api:
# from libbgg.apiv2 import BGG as BGG2


class Boardgamegeek_Interface():
    """
    A connection to the BoardGameGeek API
    """
    def __init__(self):
        self.connection = BGG()
        #Can also use BGG2(). I'm not sure which is better yet.

    def extract_category(self, json_obj, category_name):
        """
        Extracts items from a category in a JSON object and returns a list of dictionaries.
        """
        items = []
        try:
            # Try accessing the category name
            category_items = getattr(json_obj, category_name)

            # Check if the category items are a list or a single object
            if isinstance(category_items, list):
                for item in category_items:
                    items.append({
                        "name": getattr(item, "TEXT", None).replace("'", "")[0:63],
                        "id": getattr(item, "objectid", None)
                    })
            else:
                items.append({
                    "name": getattr(category_items, "TEXT", None).replace("'", "")[0:63],
                    "id": getattr(category_items, "objectid", None)
                })
        except KeyError:
            pass
        except AttributeError:
            pass

        return items
    
    def search_for_games(self, title):
        """
        Grabs a list of games matching the title. Games will be formatted as ditionaries with name.text, objectid, and yearpublished.text
        """
        results = self.connection.search(title)
        return results.boardgames.boardgame
    
    def lookup_game(self, id):
        """
        Retrieves all details about a specific game.
        Returns all details set up as a JSON based off of
        """
        #Fetches the game using its id
        results = self.connection.get_game(id , stats=False)
        game = results.boardgames.boardgame
        if isinstance(game.name, list):
            game.name = next((item['TEXT'] for item in game.name if item.get('primary') == 'true'), None)
        else:
            game.name = game.name.TEXT

        #collates all details that will be needed for the game object
        boardgame= {
            "boardgame_details" : 
                {
                    "gameID":game.objectid.replace("'", ""),
                    "name":game.name.replace("'", "")[0:63],
                    "publication date":game.yearpublished.TEXT.replace("'", ""),
                    "min players":game.minplayers.TEXT.replace("'", ""),
                    "max players":game.maxplayers.TEXT.replace("'", ""),
                    "min age": game.age.TEXT.replace("'", ""),
                    "description": game.description.TEXT.replace("<br/><br/>","\n").replace("'", "")
                },
            "awards":self.extract_category(game, "boardgamehonor"),
            "mechanics": self.extract_category(game, "boardgamemechanic"),
            "categories": self.extract_category(game, "boardgamecategory"),
            "designers": self.extract_category(game, "boardgamedesigner"),
            "publishers": self.extract_category(game, "boardgamepublisher")
        }

        return boardgame
    
if __name__ == "__main__":
    import pymysql
    import game
    username = "foo"
    password = "poplop"
    try:
        cnx = pymysql.connect(host='localhost',user = username,password=password,\
                                    db ='final_project',charset='utf8mb4')
    except pymysql.err.OperationalError:
        print("Invalid credentials")
    gameobj = game.Game(cnx)
    bgg = Boardgamegeek_Interface()
    games = bgg.search_for_games("Wingspan")
    game = games[1]
    print(game)
    id = game.objectid
    gameobj.load_game_from_bgg(id)
    print(gameobj.bg_name)
    # gameobj.save_game_to_db()

    