drop function interchange_route(INT, INT, VARCHAR(10));

CREATE OR REPLACE FUNCTION interchange_route(INT, INT, VARCHAR(10)) -- need to incorporate available seats, price, total time, num of stops and num of stations, and grab next 10
RETURNS TABLE(day VARCHAR(10), route_one int, route_two int, stop_one int, depart_time_one time, to_interchange time, interchange_stop int, price_1st_leg int,
                depart_time_two time, to_final_stop time, arrival_stop_two int, price_2nd_leg int, total_price int, total_trip_time time,
                num_stops_1st_leg int, num_stations_1st_leg int, num_stops_2nd_leg int, num_stations_2nd_leg int, num_stops_total int, num_stations_total int, arrival_time_one time, final_arrival_time time)
AS $$
BEGIN
    RETURN QUERY
    SELECT trs.day, trs.route_one, trs.route_two, trs.stop_one, trs.depart_time_one,
           hours_to_stop(trs.stop_one, trs.interchange_stop, trs.route_one, trs.day, trs.depart_time_one) as time_to_interchange,
           trs.interchange_stop, price(trs.route_one, trs.stop_one, trs.interchange_stop, trs.day, trs.depart_time_one) as price_1st_leg,
           trs.depart_time_two, hours_to_stop(trs.interchange_stop, trs.stop_two, trs.route_two, trs.day, trs.depart_time_two) as time_to_final_stop,
           trs.stop_two, price(trs.route_two, trs.interchange_stop, trs.stop_two, trs.day, trs.depart_time_two) as price_2nd_leg,
           (price(trs.route_one, trs.stop_one, trs.interchange_stop, trs.day, trs.depart_time_one)
                 + price(trs.route_two, trs.interchange_stop, trs.stop_two, trs.day, trs.depart_time_two)) as total_price,
           ((trs.depart_time_two - trs.depart_time_one)
                + hours_to_stop(trs.interchange_stop, trs.stop_two, trs.route_two, trs.day, trs.depart_time_two)) as total_time,
           num_stops(trs.stop_one, trs.interchange_stop, trs.route_one), num_stations(trs.stop_one, trs.interchange_stop, trs.route_one),
           num_stops(trs.interchange_stop, trs.stop_two, trs.route_two), num_stations(trs.interchange_stop, trs.stop_two, trs.route_two),
           (num_stops(trs.interchange_stop, trs.stop_two, trs.route_two) + num_stops(trs.stop_one, trs.interchange_stop, trs.route_one)),
           (num_stations(trs.stop_one, trs.interchange_stop, trs.route_one) + num_stations(trs.interchange_stop, trs.stop_two, trs.route_two)),
           (trs.depart_time_one + hours_to_stop(trs.stop_one, trs.interchange_stop, trs.route_one, trs.day, trs.depart_time_one)::interval) as arrival_time_one,
           (trs.depart_time_two + hours_to_stop(trs.interchange_stop, trs.stop_two, trs.route_two, trs.day, trs.depart_time_two)::interval) as final_arrival_time

    FROM(
        SELECT RSOD.route_no as route_one, RSODJ.route_no as route_two, RSOD.day as day, RSOD.depart_stop_no as stop_one,
               RSOD.time as depart_time_one, RSOD.arrival_stop_no as interchange_stop,
               RSODJ.time as depart_time_two, RSODJ.arrival_stop_no as stop_two
        FROM route_stop_order_day as RSOD
            JOIN route_stop_order_day as RSODJ on RSOD.arrival_stop_no = RSODJ.depart_stop_no
        WHERE RSOD.depart_stop_no = $1 AND RSODJ.arrival_stop_no = $2 AND RSOD.day = $3 AND RSODJ.day = $3) as trs
    WHERE (trs.depart_time_one + hours_to_stop(trs.stop_one, trs.interchange_stop, trs.route_one, trs.day, trs.depart_time_one)::interval) < trs.depart_time_two
            AND has_seats(trs.route_one, $3, trs.depart_time_one) AND has_seats(trs.route_two, $3, trs.depart_time_two);

END; $$ LANGUAGE plpgsql;


select *
    FROM interchange_route(1, 7, 'Wednesday');
