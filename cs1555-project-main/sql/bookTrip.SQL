--
CREATE OR REPLACE PROCEDURE book_trip(INT, INT, INT, INT, VARCHAR(10), TIME, BOOLEAN) -- BOOK A PASSENGER USING: CUSTOMER_NO, DEPART_STATION, DESTINATION_STATION, ROUTE_NO
AS $$
DECLARE
    price_calc INT := 0;
    customer_num INT;
    depart INT;
    arrival INT;
    route INT;
    given_day VARCHAR(10);
    depart_time time;
    sub BOOL;
    seats_open INT;
    train INT;

begin
    customer_num := $1;
    depart := $2;
    arrival := $3;
    route := $4;
    given_day := $5;
    depart_time := $6;
    sub := $7;

    SELECT num_seats_open into seats_open
    FROM(
        SELECT *
        FROM SCHEDULE as S
            JOIN TRAIN as T on S.train_no = T.train_no) as ST
    WHERE ST.route_no = route
            AND ST.day = given_day
            AND ST.departure_time = depart_time;

    IF seats_open > 0
    THEN
        price_calc := price(route, depart, arrival, given_day, depart_time);
        INSERT INTO RESERVATION(customer_no, depart_station, destination_station, route_no, day, departure_time, substitution, price, train_no) VALUES(customer_num, depart, arrival, route, given_day, depart_time, sub, price_calc, train);
    end if;
end;
    $$ LANGUAGE plpgsql; -- need trigger to update availability on route

--CALL book_trip(1,1,6,22,'Saturday', '02:28:00', true);


-- 4 Ticket a booked reservation when the passenger pays the total amount
DROP PROCEDURE IF EXISTS paid_ticket(resv_no INTEGER);
CREATE OR REPLACE procedure paid_ticket(resv_no INTEGER )
AS $$
    BEGIN
        UPDATE reservation
        SET ticketed = true
        WHERE reservation_no = $1;
    end;
$$ LANGUAGE plpgsql;