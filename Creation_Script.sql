DROP DATABASE IF EXISTS final_project;
CREATE DATABASE final_project;
USE final_project;

CREATE TABLE publisher (
	publisher_id INT PRIMARY KEY,
    p_name VARCHAR(64) not null
	);
    
CREATE TABLE designer (
	designer_id INT PRIMARY KEY,
    d_name VARCHAR(64) not null
	);
    
CREATE TABLE category (
	c_id INT PRIMARY KEY,
	c_name VARCHAR(64) 
    );
    
CREATE TABLE mechanic (
	m_id INT PRIMARY KEY,
	m_name VARCHAR(64) not null
    );
    
CREATE TABLE award (
	award_id INT PRIMARY KEY,
	a_name VARCHAR(64)
	);
    
CREATE TABLE board_game(
	game_id INT PRIMARY KEY,
    bg_name VARCHAR(64) NOT NULL,
    publication_date INT,
    min_players INT CHECK(min_players > 0),
    max_players INT CHECK(max_players > 0),
    min_player_age INT,
    bg_description VARCHAR(1024)
	);

CREATE TABLE publishes(
	publisher_id INT,
    game_id INT,
    PRIMARY KEY(publisher_id,game_id),
    FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
    );

CREATE TABLE designs(
	designer_id INT,
    game_id INT,
    PRIMARY KEY(designer_id,game_id),
    FOREIGN KEY (designer_id) REFERENCES designer(designer_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    

CREATE TABLE game_category(
	c_id INT,
    game_id INT,
    PRIMARY KEY(c_id,game_id),
    FOREIGN KEY (c_id) REFERENCES category(c_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    

CREATE TABLE game_award(
	award_id INT,
    game_id INT,
    PRIMARY KEY(award_id,game_id),
    FOREIGN KEY (award_id) REFERENCES award (award_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    
CREATE TABLE game_mechanic (
	m_id INT,
    game_id INT,
    PRIMARY KEY (m_id,game_id),
	FOREIGN KEY (m_id) REFERENCES mechanic(m_id) 
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
        );


CREATE TABLE app_user (
	username VARCHAR(64) PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    birth_date DATE
    );
    
CREATE TABLE rates (
	username VARCHAR(64),
	game_id INT,
	rating INT not null CHECK(rating > 0 and rating <= 10),
    user_comment VARCHAR(1024),
    PRIMARY KEY(username,game_id),
	FOREIGN KEY (game_id) REFERENCES board_game(game_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (username) REFERENCES app_user(username)
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    
CREATE TABLE friends (
	username_one VARCHAR(64),
    username_two VARCHAR(64),
    PRIMARY KEY(username_one,username_two),
    FOREIGN KEY (username_one) REFERENCES app_user(username)
		ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (username_two) REFERENCES app_user(username)
		ON DELETE CASCADE ON UPDATE CASCADE
    );

CREATE TABLE collection (
	collection_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL,
    location VARCHAR(64)
    );
    
CREATE TABLE owns (
	username VARCHAR(64),
    collection_id INT,
    PRIMARY KEY (username,collection_id),
    FOREIGN KEY (username) REFERENCES app_user(username)
		ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (collection_id) REFERENCES collection(collection_id)
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    
CREATE TABLE collection_contains (
	collection_id INT,
    game_id INT,
    PRIMARY KEY(collection_id,game_id),
    FOREIGN KEY (collection_id) REFERENCES collection(collection_id)
		ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (game_id) REFERENCES board_game(game_id)
		ON DELETE CASCADE ON UPDATE CASCADE
    );
    
    
drop function if exists check_password;
delimiter $$
CREATE FUNCTION check_password(username VARCHAR(64), password VARCHAR(128))
	RETURNS tinyint
    DETERMINISTIC
    READS SQL DATA
    BEGIN
		DECLARE password_hash VARCHAR(128);
		SELECT app_user.password into password_hash FROM app_user WHERE app_user.username = username;
        
        IF (password_hash = password)
			THEN RETURN true;
		END IF;
		RETURN false;
    END$$

delimiter ;

DROP PROCEDURE IF EXISTS get_review;
DELIMITER $$
CREATE PROCEDURE get_review(username VARCHAR(64),game_id INT)
BEGIN
	SELECT * FROM rates WHERE rates.username = username AND rates.game_id = game_id;
END $$
delimiter ;

DROP PROCEDURE IF EXISTS add_user;
DELIMITER $$
CREATE PROCEDURE add_user(username VARCHAR(64), password VARCHAR(128))
BEGIN
	DECLARE item_exists INT;
	DECLARE message VARCHAR(64);
	SELECT COUNT(username) INTO item_exists FROM app_user WHERE (app_user.username = username);
		IF (item_exists >= 1)
			THEN
				set message = CONCAT("username ", username, " already exists");
				SIGNAL SQLSTATE '45000'
				set message_text = message;
		END IF;
	INSERT INTO app_user VALUES(username,password);
END $$

delimiter ;


DROP PROCEDURE IF EXISTS add_designer;
DELIMITER $$
CREATE PROCEDURE add_designer(designer_id INT,designer_name VARCHAR(64),game_id INT)
BEGIN
	DECLARE item_exists INT;
	DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
		IF (item_exists < 1)
			THEN
				set message = CONCAT("board_game ",game_id," does not exist");
				SIGNAL SQLSTATE '45000'
				set message_text = message;
		END IF;
	SET item_exists = 0;
	SELECT COUNT(designer_id) INTO item_exists FROM designer WHERE (designer.designer_id = designer_id);
		IF (item_exists < 1)
			THEN 
			INSERT INTO designer VALUES(designer_id,designer_name);
		END IF;
	INSERT INTO designs VALUES (designer_id,game_id);
END $$

delimiter ;



DROP PROCEDURE IF EXISTS add_mechanic;
DELIMITER $$
CREATE PROCEDURE add_mechanic(m_id INT, m_name VARCHAR(64),game_id INT)
BEGIN
	DECLARE item_exists INT;
	DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists < 1)
		THEN
			set message = CONCAT("board_game ",game_id," does not exist");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
	SELECT COUNT(m_id) INTO item_exists FROM mechanic WHERE (mechanic.m_id = m_id);
		IF (item_exists < 1)
			THEN 
			INSERT INTO mechanic VALUES(m_id,m_name);
		END IF;
	INSERT INTO game_mechanic VALUES(m_id,game_id);
END $$

delimiter ;

DROP PROCEDURE IF EXISTS add_category;
DELIMITER $$
CREATE PROCEDURE add_category(c_id INT, c_name VARCHAR(64),game_id INT)
BEGIN
	DECLARE item_exists INT;
    DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists < 1)
		THEN
			set message = CONCAT("board_game ",game_id," does not exist");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
	SELECT COUNT(c_id) INTO item_exists FROM category WHERE (category.c_id = c_id);
		IF (item_exists < 1)
			THEN 
			INSERT INTO category VALUES(c_id,c_name);
		END IF;
	INSERT INTO game_category VALUES(c_id,game_id);
END $$

delimiter ;

DROP PROCEDURE IF EXISTS add_publisher;
DELIMITER $$
CREATE PROCEDURE add_publisher(publisher_id INT,p_name VARCHAR(64),game_id INT)
BEGIN
	DECLARE item_exists INT;
    DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists < 1)
		THEN
			set message = CONCAT("board_game ",game_id," does not exist");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
	SELECT COUNT(publisher_id) INTO item_exists FROM publisher WHERE (publisher.publisher_id = publisher_id);
		IF (item_exists < 1)
			THEN 
			INSERT INTO publisher VALUES(publisher_id,p_name);
		END IF;
	INSERT INTO publishes VALUES(publisher_id,game_id);
END $$

delimiter ;

DROP PROCEDURE IF EXISTS add_award;
DELIMITER $$
CREATE PROCEDURE add_award(award_id INT,a_name VARCHAR(64),game_id INT)
BEGIN
	DECLARE item_exists INT;
    DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists < 1)
		THEN
			set message = CONCAT("board_game ",game_id," does not exist");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
	SELECT COUNT(award_id) INTO item_exists FROM award WHERE (award.award_id = award_id);
		IF (item_exists < 1)
			THEN 
			INSERT INTO award VALUES(award_id,a_name);
		END IF;
	INSERT INTO game_award VALUES(award_id,game_id);
END $$

delimiter ;

DROP PROCEDURE IF EXISTS query_game;
#Finds all games which contain the query as a substring in their title
DELIMITER $$
CREATE PROCEDURE query_game(title VARCHAR(64))
BEGIN
	select game_id, bg_name 
    from board_game
    where bg_name like
    CONCAT('%', title, '%');
END$$
delimiter ;

DROP PROCEDURE IF EXISTS add_game;
DELIMITER $$
CREATE PROCEDURE add_game(game_id INT,bg_name VARCHAR(64),publication_date INT,min_players INT,max_players INT,min_player_age INT,bg_description VARCHAR(1024))
BEGIN
	DECLARE item_exists INT;
    DECLARE message VARCHAR(64);
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists >= 1)
		THEN
			set message = CONCAT("board_game ",game_id," already exists");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
	INSERT INTO board_game VALUES(game_id,bg_name,publication_date,min_players,max_players,min_player_age,bg_description);
END $$

delimiter ;

DROP PROCEDURE IF EXISTS get_potential_friends;
DELIMITER $$
CREATE PROCEDURE get_potential_friends(friend_username VARCHAR(64))
BEGIN
	SELECT username from app_user
    WHERE username != friend_username
    and username not in 
		(select username_two from friends 
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

DROP PROCEDURE IF EXISTS create_collection;
DELIMITER $$
CREATE PROCEDURE create_collection(my_username VARCHAR(64),collection_name VARCHAR(64),collection_location VARCHAR(64))
BEGIN 
	declare item_exists INT;
    DECLARE max_val INT;
    DECLARE message VARCHAR(64);
    SELECT max(collection_id) INTO max_val FROM collection;
    if (max_val is null)
		then set max_val = 1;
	ELSE
		SET max_val = max_val + 1;
	END IF;
    SELECT count(collection.collection_id) INTO item_exists FROM collection join owns USING(collection_id) WHERE (owns.username = my_username) and (collection.name = collection_name);
    if (item_exists >= 1)
		then
		set message = CONCAT("board game collection ",collection_name," already exists");
		SIGNAL SQLSTATE '45000'
		set message_text = message;
	end if;
    INSERT INTO collection VALUES(max_val,collection_name,collection_location);
    INSERT INTO owns VALUES(my_username,max_val);
    
END $$
delimiter ;

DROP PROCEDURE IF EXISTS add_game_to_collection;
DELIMITER $$

CREATE PROCEDURE add_game_to_collection(game_id INT,username VARCHAR(64),collection_name VARCHAR(64))
BEGIN 
    DECLARE id INT;
	DECLARE message VARCHAR(64);
    DECLARE item_exists INT;
	SELECT COUNT(game_id) INTO item_exists FROM board_game WHERE (board_game.game_id = game_id);
	IF (item_exists < 1)
		THEN
			set message = CONCAT("board_game ",game_id," does not exist");
			SIGNAL SQLSTATE '45000'
			set message_text = message;
	END IF;
    SELECT collection_id INTO id FROM owns join collection USING(collection_id) WHERE (owns.username = username) and (collection.name = collection_name);
    
    INSERT INTO collection_contains VALUES(id,game_id);
    
END $$
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

select * from rates;

CALL add_game(1024,"test_game","2022",1,10,13,"a game");

-- test inserts
INSERT INTO app_user VALUES('tim','ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff','2000-10-10');
call add_category(1042,'Expansion for Base-game',1024);
