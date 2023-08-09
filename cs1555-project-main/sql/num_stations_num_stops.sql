create or replace function num_stations(INT, INT, INT) RETURNS INT
AS $$
DECLARE
    depart INT := $1;
    arrival INT := $2;
    route INT := $3;
    depart_pos INT;
    arrival_pos INT;
    hold INT;
    rs_count route_stations%ROWTYPE;
    curs_rs refcursor;
    count INT := 0;
    curr_pos INT := 0;
BEGIN
        OPEN curs_rs SCROLL for SELECT * FROM route_stations where route_no = route;
    SELECT order_no FROM route_stations where route_no = route AND station_no = depart INTO depart_pos;
    SELECT order_no FROM route_stations where route_no = route AND station_no = arrival INTO arrival_pos;

    IF depart_pos > arrival_pos
    THEN
        hold := depart;
        depart := arrival;
        arrival := depart;
        hold := depart_pos;
        depart_pos := arrival_pos;
        arrival_pos := hold;
    end if;

    curr_pos := depart_pos;
    LOOP
        IF curr_pos > arrival_pos
        THEN
            EXIT;
        end if;

        FETCH curs_rs INTO rs_count;

        IF rs_count IS NULL
        THEN
            EXIT;
        end if;

        IF rs_count.order_no = curr_pos
        THEN
            count := count + 1;
            curr_pos := curr_pos + 1;
            MOVE FIRST FROM curs_rs;
            MOVE -1 FROM curs_rs;
        end if;
    end loop;

    RETURN count;
end; $$ LANGUAGE plpgsql;




create or replace function num_stops(INT, INT, INT) RETURNS INT
AS $$
DECLARE
    depart INT := $1;
    arrival INT := $2;
    route INT := $3;
    depart_pos INT;
    arrival_pos INT;
    hold INT;
    rs_count route_stations%ROWTYPE;
    curs_rs refcursor;
    count INT := 0;
    curr_pos INT := 0;
BEGIN
    OPEN curs_rs SCROLL for SELECT * FROM route_stop_order where route_no = route;
    SELECT order_no FROM route_stations where route_no = route AND station_no = depart INTO depart_pos;
    SELECT order_no FROM route_stations where route_no = route AND station_no = arrival INTO arrival_pos;

    IF depart_pos > arrival_pos
    THEN
        hold := depart;
        depart := arrival;
        arrival := depart;
        hold := depart_pos;
        depart_pos := arrival_pos;
        arrival_pos := hold;
    end if;

    curr_pos := depart_pos;
    LOOP
        IF curr_pos > arrival_pos
        THEN
            EXIT;
        end if;

        FETCH curs_rs INTO rs_count;

        IF rs_count IS NULL
        THEN
            curr_pos := curr_pos + 1;
            MOVE FIRST FROM curs_rs;
            MOVE -1 FROM curs_rs;
        end if;

        IF rs_count.order_no = curr_pos
        THEN
            count := count + 1;
            curr_pos := curr_pos + 1;
            MOVE FIRST FROM curs_rs;
            MOVE -1 FROM curs_rs;
        end if;
    end loop;

    RETURN count;

end; $$ LANGUAGE plpgsql;

--SELECT num_stops(1, 2, 22);
--SELECT num_stations(1, 2, 22);