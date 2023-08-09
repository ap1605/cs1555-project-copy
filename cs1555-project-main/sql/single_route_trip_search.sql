DROP FUNCTION IF EXISTS  single_route_trip_search(INT, INT, VARCHAR(10));
CREATE OR REPLACE FUNCTION single_route_trip_search(INT, INT, VARCHAR(10)) -- need to incorporate available seats, price, total time, num of stops and num of stations, and grab next 10
RETURNS TABLE(route_no int, day VARCHAR(10), depart_stop_no int, arrival_stop_no int, departure_time time,
                hours_to_stop time, arrival_time time, price int, num_stops int, num_stations int)
AS $$
BEGIN
    RETURN QUERY SELECT *, hours_to_stop($1, $2, RSOD.route_no, $3, RSOD.time),
                        (RSOD.time + hours_to_stop($1, $2, RSOD.route_no, $3, RSOD.time)::interval) as arrival_time,
                        price(RSOD.route_no, $1, $2, $3, RSOD.time), num_stops($1, $2, RSOD.route_no),
                        num_stations($1, $2, RSOD.route_no)
    FROM route_stop_order_day as RSOD
    WHERE RSOD.depart_stop_no = $1 AND RSOD.arrival_stop_no = $2 AND RSOD.day = $3
            AND has_seats(RSOD.route_no, $3, RSOD.time);
end $$ LANGUAGE plpgsql;


--select *
--    FROM single_route_trip_search(1, 7, 'Wednesday');