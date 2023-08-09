DROP TABLE IF EXISTS STATION CASCADE;
DROP TABLE IF EXISTS RAIL_LINE CASCADE;
DROP TABLE IF EXISTS RAIL_LINE_STATIONS CASCADE;
DROP TABLE IF EXISTS ROUTE CASCADE;
DROP TABLE IF EXISTS ROUTE_STATIONS CASCADE;
DROP TABLE IF EXISTS ROUTE_STOPS CASCADE;
DROP TABLE IF EXISTS SCHEDULE CASCADE;
DROP TABLE IF EXISTS TRAIN CASCADE;
DROP TABLE IF EXISTS PASSENGER CASCADE;
DROP TABLE IF EXISTS CLOCK CASCADE;
DROP TABLE IF EXISTS RESERVATION CASCADE;

CREATE TABLE STATION (
    station_no  SERIAL,
    station_name VARCHAR(5),
    open_time   TIME NOT NULL,
    close_time  TIME NOT NULL,
    stop_delay  int,
    street      VARCHAR(50) NOT NULL,
    city        VARCHAR (50) NOT NULL,
    zip_code    VARCHAR(13) NOT NULL,

    CONSTRAINT PK_STATION PRIMARY KEY (station_no),
    CONSTRAINT UN_STATION UNIQUE (station_no, station_name)
);

CREATE TABLE TRAIN (
    train_no       SERIAL,
    train_name     VARCHAR(5),
    description    VARCHAR(150),
    num_seats_open int,
    top_speed      int,
    price_per_km   int,

    CONSTRAINT PK_TRAIN PRIMARY KEY (train_no),
    CONSTRAINT UN_TRAIN UNIQUE (train_no)
);

CREATE TABLE RAIL_LINE (
    line_no    SERIAL,
    speed_limit int,

    CONSTRAINT PK_RAIL_LINE PRIMARY KEY (line_no),
    CONSTRAINT UN_RAIL_LINE UNIQUE (line_no)
);

DROP TABLE IF EXISTS RAIL_LINE_STATIONS CASCADE;
CREATE TABLE RAIL_LINE_STATIONS (
  line_no       int,
  station_no    int,
  dist_from_prev int,
  prev_station_no int,
  next_station_no int,
  line_order int,

  CONSTRAINT PK_RAIL_LINE_STATIONS PRIMARY KEY (line_no, station_no),
  CONSTRAINT FK1_RAIL_LINE_STATIONS FOREIGN KEY (line_no) REFERENCES RAIL_LINE (line_no) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT FK2_RAIL_LINE_STATIONS FOREIGN KEY (station_no) REFERENCES STATION (station_no) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT FK3_RAIL_LINE_STATIONS FOREIGN KEY (prev_station_no) REFERENCES STATION (station_no) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT FK4_RAIL_LINE_STATIONS FOREIGN KEY (next_station_no) REFERENCES STATION (station_no) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PASSENGER (
    customer_no SERIAL,
    fname VARCHAR(32),
    lname VARCHAR(32),
    street VARCHAR(32),
    city VARCHAR(32),
    zip_code VARCHAR(13),

    CONSTRAINT PK_PASSENGER PRIMARY KEY (customer_no),
    CONSTRAINT UN_PASSENGER UNIQUE (customer_no)
);

CREATE TABLE ROUTE (
    route_no int,

    CONSTRAINT PK_ROUTE PRIMARY KEY (route_no)
);

CREATE TABLE ROUTE_STATIONS (
    route_no int,
    station_no int,
    order_no int,

    CONSTRAINT PK_ROUTE_STATIONS PRIMARY KEY (route_no, station_no),
    CONSTRAINT FK1_ROUTE_STATIONS FOREIGN KEY (station_no) REFERENCES STATION (station_no) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK2_ROUTE_STATIONS FOREIGN KEY (route_no) REFERENCES ROUTE (route_no) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ROUTE_STOPS (
    route_no int,
    stop_no int,

    CONSTRAINT PK_ROUTE_STOPS PRIMARY KEY (route_no, stop_no),
    CONSTRAINT FK_ROUTE_STOPS FOREIGN KEY (route_no) REFERENCES ROUTE (route_no) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE SCHEDULE (
    route_no int,
    day VARCHAR(10),
    departure_time time,
    train_no int,

    CONSTRAINT PK_SCHEDULE PRIMARY KEY (route_no, day, departure_time, train_no),
    CONSTRAINT UN_SCHEDULE UNIQUE (route_no, day, departure_time, train_no),
    CONSTRAINT FK_SCHEDULE_ROUTE FOREIGN KEY (route_no) REFERENCES ROUTE (route_no) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_SCHEDULE_TRAIN FOREIGN KEY (train_no) REFERENCES TRAIN (train_no) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE CLOCK (
    p_date  timestamp
);

CREATE TABLE RESERVATION (
    reservation_no SERIAL,
    customer_no int,
    route_no int, --Might not need this, might need a pointer to another table with this reservations different routes and stations.
    day VARCHAR(10),
    departure_time time,
    train_no int,
    ticketed BOOLEAN DEFAULT FALSE,
    substitution BOOLEAN,
    price int,
    depart_station int,
    destination_station int,


    CONSTRAINT PK_RESERVATION PRIMARY KEY (reservation_no),
    CONSTRAINT UN_RESERVATION UNIQUE (reservation_no),
    CONSTRAINT FK_RESERVATION_ROUTE FOREIGN KEY (route_no) REFERENCES ROUTE (route_no) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_RESERVATION_TRAIN FOREIGN KEY (train_no) REFERENCES TRAIN (train_no) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_RESERVATION_PASSENGER FOREIGN KEY (customer_no) REFERENCES PASSENGER (customer_no) ON DELETE CASCADE ON UPDATE CASCADE
);

