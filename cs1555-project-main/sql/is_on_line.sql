
create or replace function is_on_line(INT, INT) RETURNS bool
as $$

DECLARE
    count_rls rail_line_stations%ROWTYPE;
    curs_on_line refcursor;
    station INT := $1;
    line INT := $2;
BEGIN

    OPEN curs_on_line FOR SELECT * FROM rail_line_stations;

    LOOP
        FETCH curs_on_line INTO count_rls;
        IF count_rls IS NULL
        THEN
            EXIT;
        end if;

        IF station = count_rls.station_no AND line = count_rls.line_no
        THEN
            return TRUE;
        end if;
    end loop;
    CLOSE curs_on_line;
    return FALSE;
end;$$ LANGUAGE plpgsql;

SELECT is_on_line(1, 4);
