CREATE OR REPLACE FUNCTION find_distance_same_route(INT, INT, INT) RETURNS INT
as $$
DECLARE
    depart INT := $1;
    arrival INT := $2;
    depart_order INT;
    arrival_order INT;
    route INT := $3;
    curr_depart INT;
    curr_arrival INT;
    curr_order INT;
    transfer_station INT := 0;
    distance INT := 0;
    rls_station route_two_station_two_line%ROWTYPE;
    prls_station route_two_station_two_line%ROWTYPE;
    curs_RLS refcursor;

BEGIN
    OPEN curs_RLS SCROLL FOR SELECT * FROM route_two_station_two_line WHERE route_no = route;

    LOOP
        FETCH curs_RLS INTO rls_station;
        IF rls_station is NULL
        THEN
            EXIT;
        end if;
        IF (rls_station.depart_station_no = depart AND rls_station.arrival_station_no = arrival)
        THEN
            depart_order := rls_station.depart_order_no;
            arrival_order := rls_station.arrival_order_no;

            EXIT;
        ELSE
            IF rls_station.depart_station_no = arrival AND rls_station.arrival_station_no = depart
            THEN
                depart_order := rls_station.arrival_order_no;
                arrival_order := rls_station.depart_order_no;
                depart := rls_station.arrival_station_no;
                arrival := rls_station.depart_station_no;
                EXIT;
            end if;
        END if;
    end loop;

    MOVE FIRST FROM curs_RLS;
    MOVE -1 FROM curs_RLS;

    IF(depart_order > arrival_order)
    THEN
        curr_order := depart_order;
        depart_order := arrival_order;
        arrival_order := curr_order;
        curr_depart := arrival;
        arrival := depart;
        depart := curr_depart;
    end if;

    curr_order := depart_order;
    curr_depart := depart;
    LOOP
        FETCH curs_RLS into prls_station;
        IF prls_station is NULL
        THEN
            EXIT;
        end if;

        IF curr_order = arrival_order
        THEN
            EXIT;
        end if;

        IF prls_station.depart_station_no = curr_depart AND prls_station.arrival_order_no = (curr_order + 1)
        THEN
            curr_arrival := prls_station.arrival_station_no;
            IF common_line(curr_depart, curr_arrival) IS NOT NULL
            THEN
                distance := distance + find_dist_from_same_line(curr_depart, curr_arrival);
                curr_order := curr_order + 1;
                curr_depart := prls_station.arrival_station_no;
                MOVE FIRST FROM curs_RLS;
                MOVE -1 FROM curs_RLS;
            ELSE
                transfer_station := find_transfer_to_line(curr_depart, prls_station.arrival_line_no, route);
                distance := distance + find_dist_from_same_line(curr_depart, transfer_station);
                curr_depart := transfer_station;
                MOVE FIRST FROM curs_RLS;
                MOVE -1 FROM curs_RLS;
            end if;
        end if;
    end loop;

    CLOSE curs_RLS;

    IF(distance = 0) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN distance;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: Depart:%, Arrival:%, Route:%, Curr_depart:%, curr_order:%, curr_arrival:%, arrival_order:%', depart, arrival, route, curr_depart, curr_order, curr_arrival, arrival_order;
            return -1;

end; $$ LANGUAGE plpgsql;


SELECT find_distance_same_route(41, 7, 842);
SELECT find_distance_same_route(41, 27, 36);
SELECT find_distance_same_route(1, 20, 22);