CREATE DATABASE final_project;
USE final_project;

CREATE TABLE publisher (
	publisher_id INT PRIMARY KEY,
    p_name VARCHAR(64) not null,
    p_description VARCHAR(1024)
	);
    
CREATE TABLE designer (
	designer_id INT PRIMARY KEY,
    d_name VARCHAR(64) not null,
    d_description VARCHAR(1024)
	);
    
CREATE TABLE category (
	c_name VARCHAR(64) PRIMARY KEY
    );
    
CREATE TABLE mechanic (
	m_name VARCHAR(64) PRIMARY KEY
    );
    
CREATE TABLE award (
	a_name VARCHAR(64),
    a_year YEAR,
    PRIMARY KEY (a_name,a_year));
    
    
CREATE TABLE board_game(
	game_id INT PRIMARY KEY,
    bg_name VARCHAR(64) NOT NULL,
    publication_date DATE,
    min_players INT CHECK(min_players > 0),
    max_players INT CHECK(max_players > 0),
    min_player_age INT,
    bg_description VARCHAR(1024)
	);

CREATE TABLE publishes(
	publisher_id INT,
    game_id INT,
    PRIMARY KEY(publisher_id,game_id),
    FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id),
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
    );

CREATE TABLE designs(
	designer_id INT,
    game_id INT,
    PRIMARY KEY(designer_id,game_id),
    FOREIGN KEY (designer_id) REFERENCES designer(designer_id),
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
    );
    

CREATE TABLE game_category(
	c_name VARCHAR(64),
    game_id INT,
    PRIMARY KEY(c_name,game_id),
    FOREIGN KEY (c_name) REFERENCES category(c_name),
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
    );
    

CREATE TABLE game_award(
	a_name VARCHAR(64),
    a_year YEAR,
    game_id INT,
    PRIMARY KEY(a_name,a_year,game_id),
    FOREIGN KEY (a_name,a_year) REFERENCES award (a_name,a_year),
	FOREIGN KEY (game_id) REFERENCES board_game(game_id) 
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
	FOREIGN KEY (game_id) REFERENCES board_game(game_id),
    FOREIGN KEY (username) REFERENCES app_user(username)
    );
    
CREATE TABLE friends (
	username_one VARCHAR(64),
    username_two VARCHAR(64),
    PRIMARY KEY(username_one,username_two),
    FOREIGN KEY (username_one) REFERENCES app_user(username),
	FOREIGN KEY (username_two) REFERENCES app_user(username)
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
    FOREIGN KEY (username) REFERENCES app_user(username),
    FOREIGN KEY (collection_id) REFERENCES collection(collection_id)
    );
    
CREATE TABLE collection_contains (
	collection_id INT,
    game_id INT,
    PRIMARY KEY(collection_id,game_id),
    FOREIGN KEY (collection_id) REFERENCES collection(collection_id),
    FOREIGN KEY (game_id) REFERENCES board_game(game_id)
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



-- test inserts
INSERT INTO app_user VALUES('tim','ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff','2000-10-10');

INSERT INTO app_user VALUES('tim2','DASDF',"2022-11-11");
