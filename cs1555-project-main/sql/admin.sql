DROP PROCEDURE if exists delete_db();
CREATE OR REPLACE PROCEDURE delete_db()
AS $$
    BEGIN
        DROP TABLE IF EXISTS STATION CASCADE;
        DROP TABLE IF EXISTS RAIL_LINE CASCADE;
        DROP TABLE IF EXISTS RAIL_LINE_STATIONS CASCADE;
        DROP TABLE IF EXISTS ROUTE CASCADE;
        DROP TABLE IF EXISTS ROUTE_STATIONS CASCADE;
        DROP TABLE IF EXISTS ROUTE_STOPS CASCADE;
        DROP TABLE IF EXISTS SCHEDULE CASCADE;
        DROP TABLE IF EXISTS TRAIN CASCADE;
        DROP TABLE IF EXISTS PASSENGER CASCADE;
        DROP TABLE IF EXISTS CLOCK CASCADE;
        DROP TABLE IF EXISTS RESERVATION CASCADE;
    END;
    $$
LANGUAGE plpgsql;

-- CALL delete_db();