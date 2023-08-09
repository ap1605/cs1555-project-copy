

--CALL paid_ticket(1);

--5a Find all trains that pass through a specific station at a specific day/time combination

DROP FUNCTION IF EXISTS station_time_search(INT, VARCHAR, TIME);
CREATE OR REPLACE FUNCTION station_time_search(s_no INT, day_in VARCHAR, time_in TIME)
RETURNS TABLE(train_no INT)
AS $$
    BEGIN
        RETURN QUERY
            SELECT srs.train_no
            FROM (
                SELECT s.train_no, s.day, s.departure_time
                FROM schedule s NATURAL JOIN route_stations rs
                WHERE rs.station_no = $1
            ) srs
            WHERE srs.day = $2
            AND srs.departure_time = $3;
    END;
$$ LANGUAGE plpgsql;
SELECT *
FROM station_time_search(1, 'Sunday', '04:46:00');

-- 5b Find the routes that travel more than one rail line
DROP FUNCTION IF EXISTS routes_mlines();
CREATE OR REPLACE FUNCTION routes_mlines()
RETURNS TABLE(route_no INT, rank BIGINT)
AS $$
    BEGIN
        RETURN QUERY
            SELECT i.route_no, (1 + (select count(*)
                    FROM (SELECT rs.route_no, count(DISTINCT rls.line_no) AS num_lines
                    FROM rail_line_stations rls JOIN route_stations rs on rls.station_no = rs.station_no
                    GROUP BY rs.route_no
                    HAVING count(DISTINCT rls.line_no) > i.num_lines
                    ORDER BY num_lines desc) e )
                ) as rank
            FROM (SELECT rs.route_no, count(DISTINCT rls.line_no) AS num_lines
                FROM rail_line_stations rls JOIN route_stations rs on rls.station_no = rs.station_no
                GROUP BY rs.route_no
                ORDER BY num_lines desc) i
            ORDER BY rank;
    END;
$$ LANGUAGE plpgsql;

--SELECT *
--FROM routes_mlines();

--5c Rank the trains that are scheduled for more than one route.
-- Rank the trains that are scheduled for more than one route
DROP FUNCTION IF EXISTS rank_trains_mroutes();
CREATE OR REPLACE FUNCTION rank_trains_mroutes()
RETURNS TABLE(train_no INT, total_routes BIGINT, rank BIGINT)
AS $$
    BEGIN
        RETURN QUERY
        SELECT s.train_no, s.total_routes, RANK() OVER (
            ORDER BY s.total_routes
        ) AS rank
        FROM (SELECT s.train_no, count(DISTINCT s.route_no) as total_routes
            FROM schedule s
            WHERE route_no IS NOT NULL
            GROUP BY s.train_no
        ) s
        ORDER BY rank;
        END;
$$ LANGUAGE plpgsql;

SELECT *
FROM rank_trains_mroutes();

--5d Find routes that pass through the same stations but don’t have the same stops

DROP VIEW IF EXISTS all_stations_per_route CASCADE;
DROP VIEW IF EXISTS all_stops_per_route CASCADE;
DROP VIEW IF EXISTS route_stops_stations CASCADE;

CREATE view all_stations_per_route as
    SELECT route_no,
    array_to_string(array_agg(distinct station_no),',') AS station_no
    FROM route_stations
    GROUP BY route_no;

CREATE view all_stops_per_route as
    SELECT route_no,
    array_to_string(array_agg(distinct stop_no),',') AS stop_no
    FROM route_stops
    GROUP BY route_no;

CREATE view route_stops_stations as
    SELECT *
    FROM all_stations_per_route NATURAL JOIN all_stops_per_route;

create or replace function routes_same_stations() RETURNS TABLE(route_no int) -- do with cursor
AS $$
DECLARE
BEGIN
    RETURN QUERY
    SELECT DISTINCT rss1.route_no
    FROM route_stops_stations rss1 JOIN route_stops_stations rss2 ON rss1.route_no != rss2.route_no
                                                                         AND rss1.station_no = rss2.station_no
                                                                         AND rss1.stop_no != rss2.stop_no;
end; $$ LANGUAGE plpgsql;


--5e Find any stations through which all trains pass through
DROP function IF EXISTS stations_all_trains();
Create or replace function stations_all_trains ()
    RETURNS TABLE (
        station_no int
        )
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT station_no
    FROM  ( SELECT DISTINCT station_no, count(DISTINCT train_no) AS num_trains
            FROM (train t NATURAL JOIN schedule s) NATURAL JOIN route_stations
            GROUP BY station_no) AS trains_per_station
    WHERE num_trains = (SELECT count(train_no)
            FROM train);
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM stations_all_trains();
-- 5f: Find all the trains that do not stop at a specific station
DROP FUNCTION IF EXISTS does_not_stop_at(s_no INTEGER);
Create or replace function does_not_stop_at (s_no INTEGER)
    RETURNS TABLE (
        train_no INTEGER,
        train_name VARCHAR
        )
AS $$
    #variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT train_no, train_name
    FROM train
    WHERE train_no NOT IN(
        SELECT train_no
        FROM schedule s, route_stations rs
        WHERE s.route_no = rs.route_no
            AND rs.station_no = s_no);
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM does_not_stop_at(1);

/**
  * 5.g) Find routes that stop @ least @ XX% of the stations the visit:
  *         Find routes where they stop @ least in XX% (where XX number from 10-90)
  *         of the stations which they pass
 */
DROP VIEW IF EXISTS no_route_stations CASCADE;
DROP VIEW IF EXISTS no_route_stops CASCADE;
DROP VIEW IF EXISTS route_stops_percentage CASCADE;
DROP VIEW IF EXISTS route_percentage_gt CASCADE;

create view no_route_stations as
    SELECT route_no,
           (SELECT count(*)
               FROM ROUTE_STATIONS RST
               WHERE RST.route_no = RT.route_no) AS no_stations
    FROM ROUTE AS RT
    ORDER BY no_stations DESC;


create view no_route_stops as
    SELECT route_no,
           (SELECT count(*)
               FROM ROUTE_STOPS RSS
               WHERE RSS.route_no = RT.route_no) AS no_stops
    FROM ROUTE AS RT
    ORDER BY no_stops DESC;

create view route_stop_percentage as
    SELECT NST.route_no, NST.no_stations, NSS.no_stops, ((NSS.no_stops*100)/(NST.no_stations)) as percent
    FROM no_route_stations as NST
            JOIN no_route_stops as NSS on NST.route_no = NSS.route_no
    ORDER BY route_no;

create or replace function routes_percent_gt(INT) RETURNS TABLE(route_no int, percent text) -- do with cursor
AS $$
DECLARE
BEGIN
    RETURN QUERY
    SELECT rs.route_no, concat(rs.percent,'%') as percent
    FROM route_stop_percentage as rs
    WHERE rs.percent >= $1
    ORDER BY rs.route_no;
end; $$ LANGUAGE plpgsql;

SELECT *
FROM routes_percent_gt;


-- 5.h) Display the schedule of a route:
        -- For a specified route, list the days of departure, departure hours and trains that run it.
DROP FUNCTION IF EXISTS disp_schedule_route(INT);

CREATE OR REPLACE FUNCTION disp_schedule_route(INT)
RETURNS TABLE(day VARCHAR(10), departure_time TIME, train_no INT)AS $$
BEGIN
    RETURN QUERY SELECT SCHEDULE.day, SCHEDULE.departure_time, SCHEDULE.train_no
    FROM SCHEDULE
    WHERE SCHEDULE.route_no = $1;
END; $$ LANGUAGE plpgsql;


SELECT *
FROM disp_schedule_route(36);


--  5.i) Find the availability of a route at every stop on a specific day and time

DROP VIEW IF EXISTS route_schedule_stops CASCADE;
DROP VIEW IF EXISTS route_availability CASCADE;

create view route_schedule_stops as
    SELECT RS.*, RST.stop_no
FROM SCHEDULE as RS, ROUTE_STOPS as RST
WHERE RS.route_no = RST.route_no;

create view route_availability as
    SELECT RS.*, TS.num_seats_open
FROM route_schedule_stops as RS, TRAIN as TS
WHERE RS.train_no = TS.train_no
ORDER BY TS.num_seats_open ASC, RS.route_no ASC;

SELECT *
FROM route_availability;

DROP FUNCTION IF EXISTS route_avail(VARCHAR(10), time);
CREATE OR REPLACE FUNCTION route_avail(VARCHAR(10), time) RETURNS TABLE(route_no int, day VARCHAR(10), departure_time time, train_no int, stop_no int, seats_open int)
AS $$
    BEGIN
        RETURN QUERY
        SELECT *
        FROM route_availability as ra
        WHERE ra.day = $1 AND ra.departure_time = $2;
    end;
$$ LANGUAGE plpgsql;

SELECT *
FROM route_avail('Saturday', '09:21:00');

-------------------------------------------------------




DROP FUNCTION IF EXISTS list_cust_trips(INT);
CREATE OR REPLACE FUNCTION list_cust_trips(INT) RETURNS TABLE(reservation_no int, route_no int, day VARCHAR(10), departure_time time, train_no int, price int, depart_station int,destination int)
AS $$
    BEGIN
        RETURN QUERY
        SELECT reservation.reservation_no, reservation.route_no, reservation.day, reservation.departure_time,  reservation.train_no, reservation.price, reservation.depart_station,destination
        FROM reservation
        WHERE customer_no = $1;
    end;
$$ LANGUAGE plpgsql;

SELECT * FROM list_cust_trips(9);


CREATE OR REPLACE FUNCTION find_dist_from_same_line(INT, INT, INT) RETURNS INT
AS $$
DECLARE
    d_count INT := 0;
    x INT;
    y INT;
    line INT := $3;
    prev_station INT := $2;
    dest_station INT := $1;
    curs_RTS SCROLL CURSOR FOR SELECT * FROM RAIL_LINE_STATIONS;
    rls_station RAIL_LINE_STATIONS%ROWTYPE;
BEGIN
    OPEN curs_RTS;
    IF prev_station is NULL or dest_station is NULL or line is NULL
    THEN
        RETURN 0;
    end if;
    SELECT line_order into x
    FROM RAIL_LINE_STATIONS
    WHERE station_no = $1;

    SELECT line_order into y
    FROM RAIL_LINE_STATIONS
    WHERE station_no = $2;

    IF(x>y) THEN
        prev_station := $1;
        dest_station := $2;
    end if;

    LOOP
        FETCH curs_RTS INTO rls_station;
        IF prev_station = dest_station or rls_station is NULL THEN
            EXIT;
        END IF;
        IF rls_station.station_no = prev_station AND rls_station.line_no = line THEN
            prev_station := rls_station.prev_station_no;
            d_count := d_count + rls_station.dist_from_prev;
            MOVE FIRST FROM curs_RTS;
        end if;
    end loop;
    CLOSE curs_RTS;
    IF(rls_station is NULL) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN d_count;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: Dest:%, Arrival:%, Line:%', $1, $2, $3;
END; $$ LANGUAGE plpgsql;

SELECT find_dist_from_same_line(11, 1, 1);

create or replace view route_station_order as
SELECT RST.route_no, RST.station_no, RST.order_no
FROM ROUTE_STATIONS as RST;


create or replace view route_two_station as
SELECT RS.route_no as route_no, RS.station_no as depart_station_no, S.station_no as arrival_station_no, RS.order_no as depart_order_no, S.order_no as arrival_order_no
FROM route_station_order as RS
        JOIN route_station_order as S on RS.route_no = S.route_no AND RS.station_no != S.station_no
WHERE RS.order_no < S.order_no
GROUP By RS.route_no, RS.station_no, RS.order_no, S.station_no, S.order_no
ORDER BY route_no, depart_station_no, arrival_order_no;

create or replace view route_two_station_line as
SELECT RTS.route_no as route_no, RTS.depart_station_no as depart_station_no,
       RTS.arrival_station_no as arrival_station_no, RTS.depart_order_no as depart_order_no,
       RTS.arrival_order_no as arrival_order_no, RLS.line_no as depart_line_no
FROM route_two_station as RTS join
        rail_line_stations as RLS on RTS.depart_station_no = RLS.station_no
GROUP By route_no, RTS.depart_station_no, RTS.depart_order_no, RTS.arrival_station_no, RTS.arrival_order_no, RLS.line_no
ORDER BY route_no, depart_station_no, arrival_order_no;

create or replace view route_two_station_two_line as
SELECT RTS.route_no as route_no, RTS.depart_station_no as depart_station_no,
       RTS.arrival_station_no as arrival_station_no, RTS.depart_order_no as depart_order_no,
       RTS.arrival_order_no as arrival_order_no, RTS.depart_line_no as depart_line_no,
       RLS.line_no as arrival_line_no
FROM route_two_station_line as RTS join
        rail_line_stations as RLS on RTS.arrival_station_no = RLS.station_no
GROUP By route_no, RTS.depart_station_no, RTS.depart_order_no, RTS.arrival_station_no, RTS.arrival_order_no, RTS.depart_line_no, RLS.line_no
ORDER BY route_no, depart_station_no, arrival_order_no;


CREATE OR REPLACE FUNCTION multi_station_line(INT, INT, INT, INT, INT) RETURNS INT
as $$
DECLARE
    depart INT := $1;
    arrival INT := $2;
    depart_line INT := $3;
    arrival_line INT := $4;
    route INT := $5;
    distance INT := 0;
    temp_st INT := 0;
    temp_line INT := 0;
    prev_rls_station route_two_station_two_line%ROWTYPE;
    rls_station route_two_station_two_line%ROWTYPE;
    count_rls_station route_two_station_two_line%ROWTYPE;
    curs_RLS refcursor;
    curs_count_RLS refcursor;
    curs_prev_RLS refcursor;
    count INT := 0;


BEGIN
    OPEN curs_RLS SCROLL FOR SELECT * FROM route_two_station_two_line;
    OPEN curs_count_RLS SCROLL FOR SELECT * FROM route_two_station_two_line;
    OPEN curs_prev_RLS SCROLL FOR SELECT * FROM route_two_station_two_line;
    IF depart_line IS NOT NULL AND arrival_line is NOT NULL AND route is NOT NULL and depart_line is NOT NULL and arrival_line is NOT NULL
    THEN
        IF depart_line != arrival_line
        THEN
            LOOP
                FETCH curs_RLS INTO rls_station;
                IF(rls_station IS NULL)
                THEN
                    EXIT;
                end if;
                IF(rls_station.depart_station_no = depart
                        AND rls_station.arrival_station_no = arrival
                        AND rls_station.route_no = route
                        AND rls_station.depart_line_no = depart_line
                        AND rls_station.arrival_line_no = arrival_line)
                THEN
                    EXIT;
                end if;
            END LOOP;

            LOOP
                FETCH curs_count_RLS INTO count_rls_station;
                IF(count_rls_station IS NULL)
                THEN
                    EXIT;
                end if;
                IF(count_rls_station.arrival_order_no = rls_station.arrival_order_no
                        AND count_rls_station.depart_station_no = depart
                        AND count_rls_station.route_no = route
                        AND count_rls_station.arrival_station_no = arrival
                        AND count_rls_station.depart_order_no = rls_station.depart_order_no
                        AND count_rls_station.arrival_line_no != arrival_line)
                THEN
                    count := count + 1;
                end if;

            END LOOP;

            IF (count > 0)
            THEN
                LOOP
                    FETCH curs_prev_RLS into prev_rls_station;
                    IF(prev_rls_station IS NULL)
                    THEN
                        EXIT;
                    end if;
                    IF prev_rls_station.arrival_order_no = (rls_station.arrival_order_no - 1)
                                AND prev_rls_station.depart_station_no = depart
                                AND prev_rls_station.route_no = route
                                AND prev_rls_station.depart_order_no = rls_station.depart_order_no
                    THEN
                        arrival_line := prev_rls_station.arrival_line_no;
                        MOVE FIRST FROM curs_prev_RLS;
                        IF arrival_line = depart_line
                        THEN
                            distance := distance + (SELECT find_dist_from_same_line(depart, arrival, depart_line));
                            CLOSE curs_prev_RLS;
                            CLOSE curs_RLS;
                            CLOSE curs_count_RLS;
                            RETURN distance;
                        end if;
                        EXIT;
                    end if;
                end LOOP;
            end if;

            LOOP
                FETCH curs_prev_RLS into prev_rls_station;
                IF(prev_rls_station IS NULL)
                THEN
                    EXIT;
                end if;
                IF prev_rls_station.arrival_order_no = (rls_station.arrival_order_no - 1)
                    AND prev_rls_station.depart_station_no = depart
                    AND prev_rls_station.route_no = route
                    AND prev_rls_station.depart_order_no = rls_station.depart_order_no
                    AND prev_rls_station.arrival_line_no = arrival_line
                THEN
                    EXIT;
                end if;
            end LOOP;

            temp_st := prev_rls_station.arrival_station_no;
            temp_line := prev_rls_station.arrival_line_no;


            distance := distance + (SELECT (multi_station_line(temp_st, arrival, temp_line, arrival_line, route)));
            distance := distance + (SELECT (multi_station_line(depart, temp_st, depart_line, temp_line, route)));

        ELSE
            FETCH curs_RLS INTO rls_station;
            distance := distance + (SELECT find_dist_from_same_line(depart, arrival, depart_line));
        end if;
    ELSE
        FETCH curs_RLS INTO rls_station;
        RETURN 0;
    end if;

    CLOSE curs_prev_RLS;
    CLOSE curs_RLS;
    CLOSE curs_count_RLS;
    IF(rls_station is NULL) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN distance;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: Dest:%, Arrival:%, Depart_Line:%, Arrival_line:%, Route:%', $1, $2, $3, $4, $5;
            return -1;
END $$ LANGUAGE plpgsql;

SELECT multi_station_line(1, 20, 1, 2, 22);


create or replace view route_two_station as
SELECT RS.route_no as route_no, RS.station_no as depart_station_no, S.station_no as arrival_station_no, RS.order_no as depart_order_no, S.order_no as arrival_order_no
FROM route_station_order as RS
        JOIN route_station_order as S on RS.route_no = S.route_no AND RS.station_no != S.station_no
WHERE RS.order_no < S.order_no
GROUP By RS.route_no, RS.station_no, RS.order_no, S.station_no, S.order_no
ORDER BY route_no, depart_station_no, arrival_order_no;

create or replace function price(INT, INT, INT, VARCHAR(10), time) RETURNS INT
as $$
DECLARE
    route INT := $1;
    depart INT := $2;
    arrival INT := $3;
    given_day VARCHAR(10) := $4;
    time TIME := $5;
    depart_line INT := 0;
    arrival_line INT := 0;
    price INT := 0;
    rls_station route_two_station_two_line%ROWTYPE;
    curs_RLS SCROLL CURSOR FOR SELECT * FROM route_two_station_two_line;

BEGIN
    OPEN curs_RLS;
    SELECT price_per_km into price
    FROM(
        SELECT *
        FROM SCHEDULE as S
            JOIN TRAIN as T on S.train_no = T.train_no) as ST
    WHERE ST.route_no = route
            AND ST.day = given_day
            AND ST.departure_time = time;

    LOOP
        FETCH curs_RLS INTO rls_station;
        IF(rls_station IS NULL)
        THEN
            EXIT;
        end if;
        IF(rls_station.depart_station_no = depart
                AND rls_station.arrival_station_no = arrival
                AND rls_station.route_no = route)
        THEN
            depart_line = rls_station.depart_line_no;
            arrival_line = rls_station.arrival_line_no;
            EXIT;
        end if;
    END LOOP;
    price := price * multi_station_line(depart, arrival, depart_line, arrival_line, route);
    CLOSE curs_RLS;
    IF(rls_station is NULL) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN price;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: day:%, depart:%, arrival:%, day:%, time:%', $1, $2, $3, $4, $5;
            RETURN -1;
end; $$ LANGUAGE plpgsql;

SELECT price(22, 1, 20, 'Saturday', '02:28');




--------------------------------------------

CREATE OR REPLACE FUNCTION reserveSeat()
RETURNS TRIGGER as
$$
BEGIN
    UPDATE train
    SET num_seats_open = num_seats_open-1
    WHERE train_no = new.train_no;

    return new;
end;

$$ language plpgsql;

DROP TRIGGER IF EXISTS seatReservation ON reservation;
CREATE TRIGGER seatReservation
    AFTER INSERT OR UPDATE
    ON reservation
    for each row
    EXECUTE PROCEDURE reserveSeat();


 --INSERT INTO reservation VALUES (1,130405, 2922, 'Thursday','16:48:00',48, false, false, 125, 1,4 );



create or replace view route_stop_order as
SELECT RS.route_no,  RST.stop_no, RS.order_no
FROM ROUTE_STOPS as RST
        JOIN ROUTE_STATIONS RS on RST.route_no = RS.route_no and RST.stop_no = RS.station_no;


create or replace view route_two_stop as
SELECT RS.route_no as route_no, RS.stop_no as depart_stop_no, S.stop_no as arrival_stop_no
FROM route_stop_order as RS
        JOIN route_stop_order as S on RS.route_no = S.route_no AND RS.stop_no != S.stop_no
WHERE RS.order_no < S.order_no
GROUP By RS.route_no, RS.stop_no, RS.order_no, S.stop_no, S.order_no
ORDER BY RS.route_no, RS.stop_no;

create or replace view route_stop_order_day as
SELECT RTS.route_no as route_no, S.day as day, RTS.depart_stop_no as depart_stop_no, RTS.arrival_stop_no as arrival_stop_no, S.departure_time as time
FROM route_two_stop as RTS
        JOIN SCHEDULE S on RTS.route_no = S.route_no;

select * from route_stop_order_day;

select * from route_two_stop;

select * from route_stop_order;