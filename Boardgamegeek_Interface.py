#!/usr/bin/env python3

import json
from libbgg.apiv1 import BGG
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
        Returns a list containing all items that fit into a given category from a json.
        Expects each category to have TEXT and objectid fields.
        """
        items = []
    
        if hasattr(json_obj, category_name):
            category_items = getattr(json_obj, category_name)
            if isinstance(category_items, list):
                for item in category_items:
                    items.append({"name": getattr(item, "TEXT"), "id": getattr(item, "objectid")})
            else:
                items.append({"name": getattr(category_items, "TEXT"), "id": getattr(category_items, "objectid")})

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
        game.name = game.name[0].TEXT

        #collates all details that will be needed for the game object
        boardgame= {
            "boardgame_details" : 
                {
                    "gameID":game.objectid,
                    "name":game.name,
                    "publication date":game.yearpublished.TEXT,
                    "min players":game.minplayers.TEXT,
                    "max players":game.maxplayers.TEXT,
                    "min age": game.age.TEXT,
                    "description": game.description.TEXT.replace("<br/><br/>","\n")
                },
            "awards":self.extract_category(game, "boardgamehonor"),
            "mechanics": self.extract_category(game, "boardgamemechanic"),
            "categories": self.extract_category(game, "boardgamecategory"),
            "designers": self.extract_category(game, "boardgamedesigner"),
            "publshers": self.extract_category(game, "boardgamepublisher")
        }

        return boardgame


        

    def sample_game(self, id):
        """
        More of a 'toy' function that ensures that I understand how to fetch everything I need from a BGG lookup
        """
        results = self.connection.get_game(id , stats=False)
        game = results.boardgames.boardgame
        print("Below is all information that will be stored in board_game:")
        print(f"- gameID: {game.objectid}")
        game.name = game.name[0].TEXT
        print(f"- name: {game.name}")
        print(f"- publication date: {game.yearpublished.TEXT}")
        print(f"- min players: {game.minplayers.TEXT}")
        print(f"- max players: {game.maxplayers.TEXT}")
        print(f"- min age: {game.age.TEXT}")
        print(f"- description: {game.description.TEXT}")

        print(f"\nMechanics for {game.name}:")
        for mechanic in game.boardgamemechanic:
            print(f"- {mechanic.TEXT} with ID {mechanic.objectid}")

        print(f"\nCategories for {game.name}:")
        for category in game.boardgamecategory:
            print(f"- {category.TEXT} with ID {category.objectid}")

        if hasattr(game, "boardgamehonor"):
            print(f"\nAwards for {game.name}:")
            if isinstance(game.boardgamehonor, list):
                for honor in game.boardgamehonor:
                    print(f"- {honor.TEXT} with ID {honor.objectid}")
            else:
                print(f"- {game.boardgamehonor.TEXT} with ID {game.boardgamehonor.objectid}")
        else:
            print(f"\nNo awards information available for {game.name}.")
        
        print(f"\nDesigned by:")
        for designer in game.boardgamedesigner:
            print(f"- {designer.TEXT} with ID {designer.objectid}")
        
        print(f"\nPublished by:")
        for publisher in game.boardgamepublisher:
            print(f"- {publisher.TEXT} with ID {publisher.objectid}")
    
if __name__ == "__main__":
    bgg = Boardgamegeek_Interface()
    games = bgg.search_for_games("Arcadia Quest")
    # for game in games:
    #     print(f"I found {game.name.TEXT}")

    id = games[0].objectid
    thingy = bgg.lookup_game(id)
    print(thingy)

    