--cancel all non-ticketed reservations 2 hours before the train departs
DROP FUNCTION IF EXISTS determineDay(day varchar)
CREATE OR REPLACE FUNCTION determineDay(day varchar)
returns integer AS $$
BEGIN
    IF(day = 'Sunday') THEN
        return 0;
    ELSIF (day = 'Monday') THEN
        return 1;
    ELSIF (day = 'Tuesday') THEN
        return 2;
    ELSIF (day = 'Wednesday') THEN
        return 3;
    ELSIF (day = 'Thursday') THEN
        return 4;
    ELSIF (day = 'Friday') THEN
        return 5;
    ELSE
        return 6;
END IF;
end;
$$ language plpgsql;

--SELECT * from determineDay('Monday');

-- Create a trigger, called reservation cancel, that cancels all reservations if they
-- haven’t ticketed two hours before departure. This trigger uses the CLOCK table.

CREATE or REPLACE FUNCTION reservation_cancel()
RETURNS TRIGGER AS
$$
DECLARE
currTimestamp timestamp;
currTime time;
currDay integer;
reserveDay integer;
reserveTime time;
curr_row RECORD;
reservationCursor CURSOR FOR
    SELECT *
    FROM reservation r
    WHERE ticketed = FALSE;
BEGIN
    currTimestamp := (SELECT * FROM clock LIMIT 1);
    currDay := (SELECT EXTRACT(DOW FROM currTimestamp));
    currTime := (SELECT currTimestamp :: time);
    OPEN reservationCursor;

    LOOP
         FETCH reservationCursor INTO curr_row;
         EXIT WHEN NOT FOUND;
         reserveDay = (SELECT * FROM determineDay(curr_row.day));
         reserveTime = curr_row.departure_Time-'02:00:00';
         IF (reserveDay = currDay AND (curr_row.departure_Time-'02:00:00') <= currTime AND currTime<= curr_row.departure_Time) THEN
             DELETE FROM reservation WHERE reservation_no = curr_row.reservation_no;
         ELSIF (reserveDay-1 = currDay AND (curr_row.departure_Time-'02:00:00') <= currTime AND currTime >= '22:00:00')THEN
            DELETE FROM reservation WHERE reservation_no = curr_row.reservation_no;
         END IF;

    end loop;
    close reservationCursor;
    return new;

END;

$$ language plpgsql;

DROP TRIGGER IF EXISTS cancelReservation ON clock;
CREATE TRIGGER cancelReservation
    AFTER INSERT OR UPDATE
    ON clock
    FOR EACH ROW
EXECUTE PROCEDURE reservation_cancel();

--INSERT INTO clock VALUES ('2022-08-10 1:00:00.000000');



-- Line_disruption trigger
-- Adjusts all tickets to the immediate next line when a line is closed
-- Cancels tickets when customer specifies no substitution
DROP FUNCTION IF EXISTS line_disruption() CASCADE;
CREATE OR REPLACE FUNCTION line_disruption()
RETURNS TRIGGER
AS $$
    DECLARE
        line_disrupted INT; -- Line that got shut down
        ticket RECORD; -- Ticket cursor
        depart_line_count INT; -- How many lines is the depart station on
        dest_line_count INT; -- How many lines is the destination station on
    BEGIN
        -- Assigning line that is being cancelled
        line_disrupted := old.line_no;
        raise notice 'LINE DISRUPTED IS %', line_disrupted;
        -- Loop through entire reservation table
        FOR ticket IN SELECT * FROM reservation
        LOOP
            --raise notice 'TICKET NO %', ticket.route_no;
            -- If current ticket part of rail line disrupted
            IF ticket.depart_station IN ( SELECT station_no FROM rail_line_stations NATURAL JOIN route_stations
                                            WHERE line_no = line_disrupted AND route_no = ticket.route_no )
                   OR ticket.destination_station IN
                                        ( SELECT station_no FROM rail_line_stations NATURAL JOIN route_stations
                                            WHERE line_no = line_disrupted AND route_no = ticket.route_no )
                THEN
                     -- If passenger does not want a substitution, cancel the ticket
                    IF ticket.substitution = FALSE
                        THEN
                            -- Delete from reservation
                            DELETE FROM reservation WHERE reservation_no = ticket.reservation_no;
                            raise notice 'cancelling reservation due to line disruption: %', ticket.reservation_no;

                    -- Assigning rail line counts for depart/destination stations (make sure that we can afford to switch lines)
                    SELECT count(line_no) INTO depart_line_count
                        FROM rail_line_stations NATURAL JOIN route_stations
                        WHERE route_no = ticket.route_no AND station_no = ticket.depart_station
                        GROUP BY station_no;
                    SELECT count(line_no) INTO dest_line_count
                        FROM rail_line_stations NATURAL JOIN route_stations
                        WHERE route_no = ticket.route_no AND station_no = ticket.destination_station
                        GROUP BY station_no;

                    -- If depart/destination station is ONLY on rail line disrupted, cancel the ticket
                    -- This means we cannot move to another line due to this being the only line
                    ELSIF depart_line_count OR dest_line_count = 1
                        THEN
                            -- Delete from reservation
                            DELETE FROM reservation WHERE reservation_no = ticket.reservation_no;
                            raise notice 'cancelling reservation due to line disruption and there are no lines available: %', ticket.reservation_no;

                    -- Move to next line
                    ELSE
                        raise notice 'Current reservation moved to next line';
                    END IF;
            END IF;
        end loop;
        RETURN old;
    END
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS line_disruption ON rail_line;
CREATE TRIGGER line_disruption
    BEFORE DELETE
    ON rail_line
    FOR EACH ROW
EXECUTE PROCEDURE line_disruption();

-- INSERT INTO rail_line VALUES(1,100);
-- DELETE FROM rail_line WHERE line_no = 1;