create or replace function common_line(INT, INT) RETURNS INT
as $$

DECLARE
    arrival_rls rail_line_stations%ROWTYPE;
    curs_arrival refcursor;
    depart_rls rail_line_stations%ROWTYPE;
    curs_depart refcursor;
    depart INT := $1;
    arrival INT := $2;
    line INT;
BEGIN

    OPEN curs_depart FOR SELECT * FROM rail_line_stations WHERE station_no = depart;
    OPEN curs_arrival FOR SELECT * FROM rail_line_stations WHERE station_no = arrival;


    LOOP
        FETCH curs_depart INTO depart_rls;
        IF depart_rls IS NULL
        THEN
            EXIT;
        end if;

        LOOP
            FETCH curs_arrival INTO arrival_rls;
            IF arrival_rls IS NULL
            THEN
                MOVE FIRST FROM curs_arrival;
                MOVE  -1 FROM curs_arrival;
                EXIT;
            end if;

            IF arrival_rls.line_no = depart_rls.line_no
            THEN
                line = arrival_rls.line_no;
                EXIT;
            end if;
        end loop;
        IF line IS NOT NULL
        THEN
            EXIT;
        end if;
    end loop;
    CLOSE curs_arrival;
    CLOSE curs_depart;
    return line;
end;$$ LANGUAGE plpgsql;

SELECT common_line(41, 8);
