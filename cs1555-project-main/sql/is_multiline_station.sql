
CREATE or REPLACE function is_multiline_station(INT) RETURNS bool
as $$

DECLARE
    count_rls rail_line_stations%ROWTYPE;
    curs_count refcursor;
    count INT := 0;
    station INT := $1;
BEGIN

    OPEN curs_count FOR SELECT * FROM rail_line_stations;

    LOOP
        FETCH curs_count INTO count_rls;
        IF count_rls IS NULL
        THEN
            EXIT;
        end if;

        IF station = count_rls.station_no
        THEN
            count:= count+1;
        end if;

        IF count > 1
        THEN
            RETURN true;
        end if;
    end loop;

    CLOSE curs_count;

    IF(count = 0) THEN RAISE 'bad_data' USING errcode='MYERR';
    ELSE return false;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'COULD NOT FIND A COUNT FOR:%', $1;
            return false;
end;$$ LANGUAGE plpgsql;

SELECT is_multiline_station(4);