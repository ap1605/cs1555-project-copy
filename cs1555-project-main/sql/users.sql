DROP TABLE IF EXISTS USERS CASCADE;

CREATE TABLE USERS (
    user_name      VARCHAR(20) NOT NULL,
    password       VARCHAR (100) NOT NULL,
    isAdmin        BOOLEAN NOT NULL,
    CONSTRAINT PK_USER PRIMARY KEY (user_name)
);

DROP PROCEDURE IF EXISTS add_user(user_name VARCHAR, password VARCHAR, isadmin BOOLEAN);
CREATE OR REPLACE PROCEDURE add_user(user_name VARCHAR, password VARCHAR, isadmin BOOLEAN)
AS $$
BEGIN
        INSERT INTO users(user_name, password, isAdmin)
        VALUES ($1, $2, $3);
end;
$$ LANGUAGE plpgsql;

CALL add_user('Chase', 'pass', true);
CALL add_user('admin', 'root', true);

DROP FUNCTION IF EXISTS user_login(u_name VARCHAR, pass VARCHAR);
CREATE OR REPLACE FUNCTION user_login(u_name VARCHAR, pass VARCHAR)
RETURNS TABLE (user_name VARCHAR, password VARCHAR, isAdmin BOOLEAN)
AS $$
    BEGIN
        RETURN QUERY
        SELECT *
        FROM USERS u
        WHERE u.user_name = u_name AND u.password = pass;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM user_login('Chase', 'pass');



