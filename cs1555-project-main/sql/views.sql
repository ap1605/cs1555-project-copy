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

create or replace view route_stop_order_day_price as
SELECT *, price(rsod.route_no, rsod.depart_stop_no, rsod.arrival_stop_no, rsod.day, rsod.time)
FROM route_stop_order_day as rsod;


create or replace view route_station_order as
SELECT RST.route_no, RST.station_no, RST.order_no
FROM ROUTE_STATIONS as RST;


create or replace view route_two_station as
SELECT RS.route_no as route_no, RS.station_no as depart_station_no, S.station_no as arrival_station_no, RS.order_no as depart_order_no, S.order_no as arrival_order_no
FROM route_station_order as RS
        JOIN route_station_order as S on RS.route_no = S.route_no AND RS.station_no != S.station_no
WHERE RS.order_no < S.order_no
GROUP By RS.route_no, RS.station_no, RS.order_no, S.station_no, S.order_no
ORDER BY RS.route_no, depart_station_no, arrival_order_no;


create or replace view route_two_station_line as
SELECT RTS.route_no as route_no, RTS.depart_station_no as depart_station_no,
       RTS.arrival_station_no as arrival_station_no, RTS.depart_order_no as depart_order_no,
       RTS.arrival_order_no as arrival_order_no, RLS.line_no as depart_line_no
FROM route_two_station as RTS join
        rail_line_stations as RLS on RTS.depart_station_no = RLS.station_no
GROUP By RTS.route_no, RTS.depart_station_no, RTS.depart_order_no, RTS.arrival_station_no, RTS.arrival_order_no, RLS.line_no
ORDER BY RTS.route_no, RTS.depart_station_no, RTS.arrival_order_no;


create or replace view route_two_station_two_line as
SELECT RTS.route_no as route_no, RTS.depart_station_no as depart_station_no,
       RTS.arrival_station_no as arrival_station_no, RTS.depart_order_no as depart_order_no,
       RTS.arrival_order_no as arrival_order_no, RTS.depart_line_no as depart_line_no,
       RLS.line_no as arrival_line_no
FROM route_two_station_line as RTS join
        rail_line_stations as RLS on RTS.arrival_station_no = RLS.station_no
GROUP By RTS.route_no, RTS.depart_station_no, RTS.depart_order_no, RTS.arrival_station_no, RTS.arrival_order_no, RTS.depart_line_no, RLS.line_no
ORDER BY RTS.route_no, depart_station_no, arrival_order_no;

drop materialized view if exists multi_line_values ;

create materialized view multi_line_values as
SELECT rls.line_no as line_no, rls.station_no as station_no, rs.route_no as route_no
FROM rail_line_stations as rls JOIN
        (SELECT * FROM route_stations WHERE is_multiline_station(station_no)) as rs
            ON rs.station_no = rls.station_no
ORDER BY rs.station_no;


create or replace view speed_compare as
SELECT t.train_no, t.top_speed, LT.line_no, LT.route_no, LT.station_no, LT.speed_limit, LT.day, LT.departure_time
    FROM(SELECT rl.speed_limit, TS.line_no, TS.route_no, TS.train_no, TS.station_no, TS.day, TS.departure_time
        FROM(SELECT rls.line_no, ST.route_no, ST.train_no, ST.station_no, ST.day, ST.departure_time
             FROM(SELECT S.route_no, S.train_no, RS.station_no, S.day, S.departure_time
                 FROM schedule as S
                        JOIN route_stations as rs on S.route_no = rs.route_no) as ST
                JOIN rail_line_stations as rls on ST.station_no = rls.station_no) as TS
            JOIN rail_line as rl on rl.line_no = TS.line_no) as LT
        JOIN train as t on t.train_no = LT.train_no;


create or replace view speed_order as
SELECT SC.line_no, SC.train_no, SC.top_speed, SC.speed_limit, SC.route_no, SC.station_no, RSO.order_no,
       SC.day, SC.departure_time
FROM speed_compare as SC
        JOIN route_station_order as RSO on SC.route_no = RSO.route_no and SC.station_no = RSO.station_no;



create or replace view no_route_stations as
    SELECT route_no,
           (SELECT count(*)
               FROM ROUTE_STATIONS RST
               WHERE RST.route_no = RT.route_no) AS no_stations
    FROM ROUTE AS RT
    ORDER BY no_stations DESC;


create or replace view no_route_stops as
    SELECT route_no,
           (SELECT count(*)
               FROM ROUTE_STOPS RSS
               WHERE RSS.route_no = RT.route_no) AS no_stops
    FROM ROUTE AS RT
    ORDER BY no_stops DESC;

create or replace view route_stop_percentage as
    SELECT NST.route_no, NST.no_stations, NSS.no_stops, ((NSS.no_stops*100)/(NST.no_stations)) as percent
    FROM no_route_stations as NST
            JOIN no_route_stops as NSS on NST.route_no = NSS.route_no
    ORDER BY route_no;


create or replace view route_schedule_stops as
    SELECT RS.*, RST.stop_no
FROM SCHEDULE as RS, ROUTE_STOPS as RST
WHERE RS.route_no = RST.route_no;


CREATE OR REPLACE VIEW distance_helper as
SELECT rls.line_no, rls.station_no as station_one, rls.line_order as order_one, rst.station_no as station_two, rst.line_order as order_two
FROM RAIL_LINE_STATIONS as rls
                JOIN rail_line_stations as rst on rls.line_no = rst.line_no where rls.station_no != rst.station_no;

SELECT * FROM distance_helper;

select * from speed_order;

select * from speed_compare;

select * from route_stop_order_day_price;

select * from route_stop_order_day;

select * from route_two_stop;

select * from route_stop_order;

select * from route_station_order;

select * from route_two_station_two_line;

select * from route_two_station;

select * from rail_line_stations;

select * from route_two_station_line;

select * from multi_line_values;