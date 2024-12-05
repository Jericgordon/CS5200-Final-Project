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
	SELECT COUNT(category) INTO item_exists FROM category WHERE (category.c_id = c_id);
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
END $$

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

CALL add_game(1024,"test_game","2022",1,10,13,"a game");

-- test inserts
INSERT INTO app_user VALUES('tim','ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff','2000-10-10');
call add_category(1042,'Expansion for Base-game',1024);
select * from board_game;