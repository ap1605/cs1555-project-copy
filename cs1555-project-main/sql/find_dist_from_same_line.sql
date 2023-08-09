DROP FUNCTION IF EXISTS find_dist_from_same_line(INT, INT, INT);
DROP FUNCTION IF EXISTS find_dist_from_same_line(integer, integer) CASCADE;


CREATE OR REPLACE VIEW distance_helper as
SELECT rls.line_no, rls.station_no as station_one, rls.line_order as order_one, rst.station_no as station_two, rst.line_order as order_two
FROM RAIL_LINE_STATIONS as rls
                JOIN rail_line_stations as rst on rls.line_no = rst.line_no where rls.station_no != rst.station_no;

SELECT * FROM distance_helper;

CREATE OR REPLACE FUNCTION find_dist_from_same_line(INT, INT) RETURNS INT
AS $$
DECLARE
    d_count INT := 0;
    x INT;
    y INT;
    line INT;
    prev_station INT := $2;
    dest_station INT := $1;
    cursor_one refcursor;
    cursor_line refcursor;
    rls_station RAIL_LINE_STATIONS%ROWTYPE;
    line_record distance_helper%ROWTYPE;
BEGIN

    IF prev_station is NULL or dest_station is NULL
    THEN
        RETURN 0;
    end if;
    OPEN cursor_line SCROLL FOR SELECT * FROM distance_helper;

    LOOP
        FETCH cursor_line INTO line_record;
        IF line_record is NULL
        THEN
            EXIT;
        end if;
        IF ((line_record.station_one = prev_station AND line_record.station_two = dest_station) OR (line_record.station_one = dest_station AND line_record.station_two = prev_station))
        THEN
            line := line_record.line_no;
            EXIT;
        end if;
    end loop;

    IF line IS NULL
    THEN
        CLOSE cursor_line;
        RETURN 0;
    end if;

    SELECT line_order into x
    FROM RAIL_LINE_STATIONS
    WHERE station_no = $1 AND line_no = line;

    SELECT line_order into y
    FROM RAIL_LINE_STATIONS
    WHERE station_no = $2 AND line_no = line;

    IF(x>y) THEN
        prev_station := $1;
        dest_station := $2;
    end if;

    OPEN cursor_one SCROLL FOR SELECT * FROM RAIL_LINE_STATIONS WHERE line_no = line;


    LOOP
        FETCH cursor_one INTO rls_station;
        IF prev_station = dest_station or rls_station is NULL THEN
            EXIT;
        END IF;
        IF rls_station.station_no = prev_station THEN
            prev_station := rls_station.prev_station_no;
            d_count := d_count + rls_station.dist_from_prev;
            MOVE FIRST FROM cursor_one;
        end if;
    end loop;
    CLOSE cursor_one;
    CLOSE cursor_line;
    IF(d_count = 0) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN d_count;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: Dest:%, Arrival:%, Line:%', $1, $2, line;
END; $$ LANGUAGE plpgsql;

SELECT find_dist_from_same_line(21, 40);



SELECT *
FROM route_two_station_two_line;

SELECT * FROM RAIL_LINE_STATIONS;

create or replace view route_two_station_two_line
            (route_no, depart_station_no, arrival_station_no, depart_order_no, arrival_order_no, depart_line_no,
             arrival_line_no) as
SELECT rts.route_no,
       rts.depart_station_no,
       rts.arrival_station_no,
       rts.depart_order_no,
       rts.arrival_order_no,
       rts.depart_line_no,
       rls.line_no AS arrival_line_no
FROM route_two_station_line rts
         JOIN rail_line_stations rls ON rts.arrival_station_no = rls.station_no
GROUP BY rts.route_no, rts.depart_station_no, rts.depart_order_no, rts.arrival_station_no, rts.arrival_order_no,
         rts.depart_line_no, rls.line_no
ORDER BY rts.route_no, rts.depart_station_no, rts.arrival_order_no;