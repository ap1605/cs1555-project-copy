DROP function if exists find_transfer_to_line(INT, INT, INT);
create or replace function find_transfer_to_line(INT, INT, INT) RETURNS INT
as $$

DECLARE
    transfer_rls multi_line_values%ROWTYPE;
    temp_transfer_rls multi_line_values%ROWTYPE;
    check_transfer_rls multi_line_values%ROWTYPE;
    curs_transfer refcursor;
    curs_check refcursor;
    depart INT := $1;
    line_arrival INT := $2;
    transfer INT := 0;
    temp_transfer INT := 0;
    route INT := $3;
BEGIN

    OPEN curs_transfer SCROLL FOR SELECT * FROM multi_line_values WHERE route_no = route;
    OPEN curs_check SCROLL FOR SELECT * FROM multi_line_values WHERE route_no = route;
    FETCH curs_check INTO check_transfer_rls;

    LOOP
        FETCH curs_transfer INTO transfer_rls;
        IF transfer_rls IS NULL
        THEN
            EXIT;
        end if;

        IF common_line(transfer_rls.station_no, depart) IS NOT NULL AND transfer_rls.line_no = line_arrival
        THEN
            transfer := transfer_rls.station_no;
            EXIT;
        end if;
    end loop;

    IF(transfer = 0)
    THEN
        MOVE FIRST FROM curs_transfer;
        MOVE -1 FROM curs_transfer;
        temp_transfer := depart;
        LOOP
            FETCH curs_transfer INTO temp_transfer_rls;
            IF temp_transfer_rls IS NULL
            THEN
                temp_transfer := depart;
                MOVE FIRST FROM curs_transfer;
                MOVE -1 FROM curs_transfer;
                FETCH curs_check INTO check_transfer_rls;
                IF check_transfer_rls IS NULL
                THEN
                    EXIT;
                end if;
                LOOP
                    FETCH curs_transfer INTO temp_transfer_rls;
                    IF temp_transfer_rls = check_transfer_rls
                    THEN
                        EXIT;
                    end if;
                end loop;
            end if;


            IF common_line(temp_transfer_rls.station_no, temp_transfer) IS NOT NULL --AND transfer_rls.line_no = transfer_line
                   AND temp_transfer_rls.station_no != transfer
            THEN
                IF temp_transfer = depart
                THEN
                    transfer := temp_transfer_rls.station_no;
                end if;
                temp_transfer := temp_transfer_rls.station_no;
                MOVE FIRST FROM curs_transfer;
                MOVE -1 FROM curs_transfer;
            end if;

            IF is_on_line(temp_transfer, line_arrival)
            THEN
                EXIT;
            end if;
        end loop;

        CLOSE curs_check;
    end if;

    CLOSE curs_transfer;

    IF(transfer = 0 OR check_transfer_rls IS NULL) THEN RAISE 'bad_data' USING errcode='MYERR';
    ELSE return transfer;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'COULD NOT FIND A TRANSFER FOR depart:%, line_arrival:%, route:%', $1, $2, $3;
end;$$ LANGUAGE plpgsql;


--SELECT find_transfer_to_line(23, 3, 4343);