create or replace function has_seats(INT, VARCHAR(10), time) RETURNS BOOLEAN
AS $$
DECLARE
    route INT := $1;
    given_day VARCHAR(10) := $2;
    depart_time time := $3;
    train INT;
    num_seats INT;
BEGIN
    SELECT S.train_no FROM schedule as S WHERE S.route_no = route AND S.day = given_day AND S.departure_time = depart_time INTO train;
    SELECT T.num_seats_open FROM train as T WHERE T.train_no = train INTO num_seats;
    IF num_seats > 0
    THEN RETURN TRUE;
    ELSE RETURN FALSE;
    end if;

end; $$ language plpgsql;

SELECT has_seats(85, 'Wednesday', '01:14:00');