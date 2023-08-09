create or replace function price(INT, INT, INT, VARCHAR(10), time) RETURNS INT
as $$
DECLARE
    route INT := $1;
    depart INT := $2;
    arrival INT := $3;
    given_day VARCHAR(10) := $4;
    time TIME := $5;
    price INT := 0;


BEGIN
    SELECT price_per_km into price
    FROM(
        SELECT *
        FROM SCHEDULE as S
            JOIN TRAIN as T on S.train_no = T.train_no) as ST
    WHERE ST.route_no = route
            AND ST.day = given_day
            AND ST.departure_time = time;

    price := price * find_distance_same_route(depart, arrival, route);
    IF(price = 0) THEN RAISE 'bad_data' USING errcode='MYERR';
    else RETURN price;
    end if;
    EXCEPTION
        WHEN sqlstate 'MYERR' then
            RAISE notice 'INVALID_RTORLN_ERROR: day:%, depart:%, arrival:%, day:%, time:%', $1, $2, $3, $4, $5;
end; $$ LANGUAGE plpgsql;

--SELECT price(22, 1, 20, 'Saturday', '02:28');

