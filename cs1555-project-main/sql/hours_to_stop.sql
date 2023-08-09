create or replace function hours_to_stop(INT, INT, INT, VARCHAR(10), TIME) RETURNS TIME
as $$
DECLARE
    depart INT := $1;
    arrival INT := $2;
    route INT := $3;
    given_day VARCHAR(10) := $4;
    given_time TIME := $5;
    result FLOAT := 0.0;
    depart_train INT;
    arrival_train INT;
    arrival_line INT;
    depart_line INT;
    curr_station INT;
    curr_train INT;
    curr_line INT;
    curr_order INT;
    depart_order INT;
    arrival_order INT;
    count INT := 0;
    start_segment speed_order%ROWTYPE;
    end_segment speed_order%ROWTYPE;
    search_segment speed_order%ROWTYPE;
    count_segment speed_order%ROWTYPE;
    curs_hts refcursor;
    count_curs refcursor;

BEGIN
    OPEN curs_hts SCROLL for SELECT * FROM speed_order WHERE speed_order.day = given_day AND speed_order.departure_time = given_time
                                                AND speed_order.route_no = route;
    OPEN count_curs SCROLL for SELECT * FROM speed_order WHERE speed_order.day = given_day AND speed_order.departure_time = given_time
                                                AND speed_order.route_no = route;

    LOOP
        FETCH curs_hts into start_segment;
        IF(start_segment is NULL)
        THEN
            RAISE 'bad_data' USING errcode='MYERR';
        end if;
        IF start_segment.station_no = depart
        THEN
            depart_order = start_segment.order_no;
            depart_line = start_segment.line_no;
            depart_train = start_segment.train_no;
            EXIT;
        end if;
    end loop;
    MOVE FIRST FROM curs_hts;
    MOVE -1 FROM curs_hts;
    LOOP
        FETCH curs_hts into end_segment;
        IF(end_segment is NULL)
        THEN
            RAISE 'bad_data' USING errcode='MYERR';
        end if;
        IF end_segment.station_no = arrival
        THEN
            arrival_order = end_segment.order_no;
            arrival_line = end_segment.line_no;
            arrival_train = end_segment.train_no;
            EXIT;
        end if;
    end loop;

    MOVE FIRST FROM curs_hts;
    IF depart_order > arrival_order
    THEN
        curr_station = arrival;
        curr_order = arrival_order;
        curr_line = arrival_line;
        curr_train = arrival_train;
    end IF;
    IF depart_order < arrival_order
    THEN
        curr_station = depart;
        curr_order = depart_order;
        curr_line = depart_line;
        curr_train = depart_train;
    end IF;

    IF(arrival_line != depart_line)
    THEN
        LOOP
            FETCH curs_hts into search_segment;
            IF(search_segment is NULL)
            THEN
                EXIT;
            end if;
            IF search_segment.order_no = curr_order + 1
            THEN
                IF curr_line != search_segment.line_no
                THEN
                    LOOP
                        FETCH count_curs into count_segment;
                        IF (count_segment IS NULL)
                        THEN
                            EXIT;
                        end if;
                        IF(count_segment.station_no = search_segment.station_no
                            AND count_segment.order_no = search_segment.order_no
                            AND count_segment.line_no != search_segment.line_no)
                        THEN
                            IF(count_segment.line_no = curr_line)
                            THEN
                                count := count + 1;
                                EXIT;
                            end if;
                        end if;
                    END LOOP;
                    IF(count > 0)
                    THEN
                        result := result + (find_dist_from_same_line(curr_station, search_segment.station_no)/speed_of_train(search_segment.train_no, curr_line));
                        curr_order := search_segment.order_no;
                        curr_train := search_segment.train_no;
                        curr_station := search_segment.station_no;
                        MOVE FIRST FROM curs_hts;
                    ELSE
                        curr_line = search_segment.line_no;
                        MOVE FIRST FROM curs_hts;
                    end if;
                ELSE
                    result := result + find_dist_from_same_line(curr_station, search_segment.station_no)/speed_of_train(search_segment.train_no, curr_line);
                    curr_order := search_segment.order_no;
                    curr_train := search_segment.train_no;
                    curr_station := search_segment.station_no;
                    MOVE FIRST FROM curs_hts;
                end if;

            end if;

        end loop;
    ELSE
        result := result + (find_dist_from_same_line(start_segment.station_no, end_segment.station_no)/speed_of_train(start_segment.train_no, start_segment.line_no));
    end if;

    CLOSE curs_hts;
    CLOSE count_curs;

    IF(result = 0) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN CAST((result*'1 HOUR'::INTERVAL) as TIME);
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: RESULT:%, CURR_STATION:%, CURR_TRAIN:%, CURR_LINE:%, CURR_ORDER:%, INPUT_DEPART:%, INPUT_ARRIVAL:%, INPUT_ROUTE:%, INPUT_DAY:%, INPUT_TIME:%',
                result, curr_station, curr_train, curr_line, curr_order, $1,$2,$3, $4, $5;
                return '00:00:00';
end; $$ LANGUAGE plpgsql;



SELECT hours_to_stop(1, 27, 36, 'Friday', '00:54:00');
