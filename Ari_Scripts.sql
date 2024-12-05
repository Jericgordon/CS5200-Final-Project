USE final_project;

DROP PROCEDURE IF EXISTS get_potential_friends;
DELIMITER $$
CREATE PROCEDURE get_potential_friends(friend_username VARCHAR(64))
BEGIN
	SELECT username FROM app_user
    WHERE username != friend_username
    and username not in 
		(select username_two FROM friends 
        where username_one = friend_username);
END $$
delimiter ;

DROP PROCEDURE IF EXISTS friend_user;
DELIMITER $$
CREATE PROCEDURE friend_user(my_username VARCHAR(64), friend_username VARCHAR(64))
BEGIN
	INSERT INTO friends VALUES(my_username, friend_username);
END $$
delimiter ;

DROP PROCEDURE IF EXISTS rate_game;
DELIMITER $$
CREATE PROCEDURE rate_game(my_username VARCHAR(64), game_id int, rating int, user_comment varchar(1024))
BEGIN
	DECLARE clamped_value INT;
    DECLARE clamped_string VARCHAR(1024);
    SET clamped_value = least(greatest(rating, 1), 10);
    SET clamped_string = LEFT(user_comment, 1024);
	INSERT INTO rates VALUES(my_username, game_id, clamped_value, clamped_string);
END $$
delimiter ;

DROP PROCEDURE IF EXISTS query_game;
#Finds all games which contain the query AS a substring in their title
DELIMITER $$
CREATE PROCEDURE query_game(title VARCHAR(64))
BEGIN
	select game_id, bg_name 
    FROM board_game
    where bg_name like
    CONCAT('%', title, '%');
END$$
delimiter ;

DROP PROCEDURE IF EXISTS add_library;
#Creates a library belonging to a user
DELIMITER $$
CREATE PROCEDURE add_library(username VARCHAR(64), collection_name VARCHAR(64), location VARCHAR(64))
BEGIN
	DECLARE c_id INT;
	    INSERT INTO collection (name, location) VALUES (collection_name, location);
    SET c_id = LAST_INSERT_ID();
    INSERT INTO owns (username, collection_id) VALUES (username, c_id);
END$$
delimiter ;

DROP PROCEDURE IF EXISTS get_friends_of;
#Fetches a list of friends belonging to a specified user
DELIMITER $$
CREATE PROCEDURE get_friends_of(username VARCHAR(64))
BEGIN
	select username_two 
		FROM friends 
        where username_one = username;
END$$
delimiter ;


DROP PROCEDURE IF EXISTS get_libraries_for;
#Fetches all libraries belonging to a specific user
DELIMITER $$
CREATE PROCEDURE get_libraries_for(username VARCHAR(64))
BEGIN
	select collection_id, name 
		FROM collection 
        INNER JOIN owns USING (collection_id)
        where owns.username = username;
END$$
delimiter ;

DROP PROCEDURE IF EXISTS add_game_to_library;
#Inserts a copy of a specified game into a library
DELIMITER $$
CREATE PROCEDURE add_game_to_library(collection_id int, game_id int)
BEGIN
	INSERT INTO collection_contains (collection_id, game_id) VALUES (collection_id, game_id);
END$$
delimiter ;

DROP PROCEDURE IF EXISTS recommend_games;
#Orders games by how likely a user is to enjoy playing them
DELIMITER $$
CREATE PROCEDURE recommend_games(user_name varchar(64))
BEGIN
	#This one is REALLY COMPLEX, so I'll put down some notes.
	WITH category_to_positivity AS (select c_id, AVG(COALESCE(rating, 5)) AS positivity FROM (select * from rates where username = user_name) as rated_c 
		RIGHT JOIN game_category USING (game_id) INNER JOIN category USING (c_id) group by c_id),
	mechanic_to_positivity AS (select m_id, AVG(COALESCE(rating, 5)) AS positivity FROM (select * from rates where username = user_name) as rated_m 
		RIGHT JOIN game_mechanic USING (game_id) INNER JOIN mechanic USING (m_id) group by m_id),
	#The first two chunks find the average ratings the user has assigned to all individual mechanics and categories
    #The assumption is that if the user has rated many games with a given mechanic highly, that mechanic contributes to their enjoyment
    category_avg AS (select game_id, avg(positivity) AS expected_rating FROM category_to_positivity INNER JOIN game_category USING (c_id) group by game_id),
    mechanic_avg AS (select game_id, avg(positivity) AS expected_rating FROM mechanic_to_positivity INNER JOIN game_mechanic USING(m_id) group by game_id)
    #We then apply these guesses of the user's tastes to all games in the system. If a game has many mechanics and categories they like, it will have a high
    #average. If it has mostly mechanics and categories they dislike, the average will be lower.
    SELECT bg_name, game_id, AVG(expected_rating) AS total_expected_rating
	FROM (
		SELECT game_id, expected_rating FROM category_avg
		UNION ALL
		SELECT game_id, expected_rating FROM mechanic_avg
		) AS combined inner join board_game using (game_id) 
        where game_id not in (select game_id from rates where username = user_name) 
        GROUP BY game_id ORDER BY total_expected_rating DESC;
        #Finally we average the two averages to get our guess of how much they'll like each game they haven't rated.
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS recommend_games_from_library;
	#Orders games by how likely a user is to enjoy playing them
    #Not an ideal way to do it, but this reuses a lot of code from recommend_games
DELIMITER $$
CREATE PROCEDURE recommend_games_from_library(user_name varchar(64), library int)
BEGIN
	#This one is REALLY COMPLEX, so I'll put down some notes.
	WITH category_to_positivity AS (select c_id, AVG(COALESCE(rating, 5)) AS positivity FROM (select * from rates where username = user_name) as rated_c 
		RIGHT JOIN game_category USING (game_id) INNER JOIN category USING (c_id) group by c_id),
	mechanic_to_positivity AS (select m_id, AVG(COALESCE(rating, 5)) AS positivity FROM (select * from rates where username = user_name) as rated_m 
		RIGHT JOIN game_mechanic USING (game_id) INNER JOIN mechanic USING (m_id) group by m_id),
	#The first two chunks find the average ratings the user has assigned to all individual mechanics and categories
    #The assumption is that if the user has rated many games with a given mechanic highly, that mechanic contributes to their enjoyment
    category_avg AS (select game_id, avg(positivity) AS expected_rating FROM category_to_positivity INNER JOIN game_category USING (c_id) group by game_id),
    mechanic_avg AS (select game_id, avg(positivity) AS expected_rating FROM mechanic_to_positivity INNER JOIN game_mechanic USING(m_id) group by game_id)
    #We then apply these guesses of the user's tastes to all games in the system. If a game has many mechanics and categories they like, it will have a high
    #average. If it has mostly mechanics and categories they dislike, the average will be lower.
    SELECT bg_name, game_id, AVG(expected_rating) AS total_expected_rating
	FROM (
		SELECT game_id, expected_rating FROM category_avg
		UNION ALL
		SELECT game_id, expected_rating FROM mechanic_avg
		) AS combined inner join board_game using (game_id) 
        where game_id not in (select game_id from rates where username = user_name)
        and game_id in (select game_id from collection_contains where collection_id = collection_id)
        GROUP BY game_id ORDER BY total_expected_rating DESC;
        #Finally we average the two averages to get our guess of how much they'll like each game they haven't rated.
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS update_rating;
	#Orders games by how likely a user is to enjoy playing them
    #Not an ideal way to do it, but this reuses a lot of code from recommend_games
DELIMITER $$
CREATE PROCEDURE update_rating(user_name varchar(64), edited_game_id int, new_rating int, new_comment varchar(1024))
BEGIN
	UPDATE rates
	SET rating=new_rating, user_comment = new_comment
	WHERE (username=user_name AND game_id=edited_game_id);
END$$
DELIMITER ;

