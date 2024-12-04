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