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

call rate_game('tim2', 1, 300, 'racial!!');
select * from rates;