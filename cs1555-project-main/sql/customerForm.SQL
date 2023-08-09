-- 1. Insert Customer
DROP FUNCTION IF EXISTS insert_customer(firstn VARCHAR, lastn VARCHAR, st varchar, c VARCHAR, zc varchar);
CREATE OR REPLACE FUNCTION insert_customer(firstn VARCHAR, lastn VARCHAR, st varchar, c VARCHAR, zc varchar) returns integer
AS $$
BEGIN
        INSERT INTO passenger(fname, lname, street, city, zip_code)
        VALUES ($1, $2, $3, $4, $5);
        RETURN currval('passenger_customer_no_seq');
end;
$$ LANGUAGE plpgsql;

SELECT* FROM insert_customer('April', 'Rigot', '243 Fifth Ave', 'Pittsburgh', 'PA 13244-2497');
-- 1. Edit customer
DROP procedure IF EXISTS edit_customer(id INTEGER, firstn VARCHAR, lastn VARCHAR, st varchar, c VARCHAR, zc varchar)
CREATE OR REPLACE PROCEDURE edit_customer(id INTEGER, firstn VARCHAR, lastn VARCHAR, st varchar, c VARCHAR, zc varchar)
AS $$
    BEGIN
        UPDATE  passenger
        SET fname = $2,
            lname = $3,
            street = $4,
            city= $5,
            zip_code = $6
        WHERE customer_no = $1;
    END;
$$ LANGUAGE plpgsql;

CALL edit_customer(9, 'April', 'Rigot', '487 Sennott Sq.', 'Pittsburgh', 'PA 13244-2497');

-- 1. View customer
Drop FUNCTION IF EXISTS view_customer(id INTEGER)
CREATE OR REPLACE FUNCTION view_customer(
    id INTEGER)
    RETURNS TABLE(
    customer_no INTEGER,
    fname VARCHAR,
    lname VARCHAR,
    street VARCHAR,
    city VARCHAR,
    zip_code VARCHAR
    )
AS $$
    #variable_conflict use_column
    BEGIN
            RETURN QUERY
            SELECT *
            FROM passenger
            WHERE customer_no = id;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM view_customer(124641);
