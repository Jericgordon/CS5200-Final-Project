USE final_project;

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

DROP PROCEDURE IF EXISTS get_libraries_for;
#Fetches all libraries belonging to a specific user
DELIMITER $$
CREATE PROCEDURE get_libraries_for(username VARCHAR(64))
BEGIN
	select collection_id, name 
		from collection 
        inner join owns using (collection_id)
        where owns.username = username;
END$$
delimiter ;

DROP PROCEDURE IF EXISTS add_game_to_library;
#Inserts a copy of a specified game into a library
DELIMITER $$
CREATE PROCEDURE add_game_to_library(collection_id int, game_id int)
BEGIN
	INSERT INTO owns (collection_id, game_id) VALUES (collection_id, game_id);
END$$
delimiter ;

call get_libraries_for('bimbo');
call add_library('zimbo', 'Zimbo Games', 'Hell');	

describe collection;

insert into app_user value('zimbo', 123123, '1999-12-23');
call add_library('zimbo', 'Zimbo Games', 'Hell');
select * from board_game;
select game_id, bg_name from board_game where bg_name like CONCAT('%', "e", '%');