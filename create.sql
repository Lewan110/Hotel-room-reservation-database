
CREATE TABLE client_reservation (
    pesel       Number(11) NOT NULL,
    reservation_id   INTEGER NOT NULL
)
LOGGING;

ALTER TABLE client_reservation ADD CONSTRAINT client_reservation_pk PRIMARY KEY ( pesel,
reservation_id );

CREATE TABLE clients (
    pesel       Number(11) NOT NULL,
    first_name   VARCHAR2(50) NOT NULL,
    last_name    VARCHAR2(100) NOT NULL,
    telephone    VARCHAR2(15) NOT NULL
)
LOGGING;

ALTER TABLE clients ADD CONSTRAINT clients_pk PRIMARY KEY ( pesel );

CREATE TABLE reservations (
    reservation_id        INTEGER NOT NULL,
    date_of_purchase      DATE,
    beginning             DATE,
    ending                DATE,
    status                VARCHAR2(10) NOT NULL,
    date_of_reservation   DATE NOT NULL,
    room_id               INTEGER
)
LOGGING;

ALTER TABLE reservations ADD CONSTRAINT reservation_pk PRIMARY KEY ( reservation_id );

CREATE TABLE room_category (
    category_id   INTEGER NOT NULL,
    name          VARCHAR2(50) NOT NULL,
    description   VARCHAR2(200)
)
LOGGING;

ALTER TABLE room_category ADD CONSTRAINT room_category_pk PRIMARY KEY ( category_id );

CREATE TABLE rooms (
    room_id         INTEGER NOT NULL,
    capacity        INTEGER NOT NULL,
    price_per_day   NUMBER(10) NOT NULL,
    room_category   INTEGER NOT NULL
)
LOGGING;

ALTER TABLE rooms ADD CONSTRAINT room_pk PRIMARY KEY ( room_id );

ALTER TABLE client_reservation
    ADD CONSTRAINT client_fk FOREIGN KEY ( pesel )
        REFERENCES clients ( pesel )
    NOT DEFERRABLE;

ALTER TABLE client_reservation
    ADD CONSTRAINT reservation_fk FOREIGN KEY ( reservation_id )
        REFERENCES reservations ( reservation_id )
    NOT DEFERRABLE;

ALTER TABLE reservations
    ADD CONSTRAINT reservations_rooms_fk FOREIGN KEY ( room_id )
        REFERENCES rooms ( room_id )
    NOT DEFERRABLE;

ALTER TABLE rooms
    ADD CONSTRAINT room_category_fk FOREIGN KEY ( room_category )
        REFERENCES room_category ( category_id )
    NOT DEFERRABLE;

CREATE TABLE CLIENT_SUMMARY
   (	PESEL number(11), 
	FIRSTNAME VARCHAR2(50), 
	LASTNAME VARCHAR2(50), 
	N_O_VISITS NUMBER, 
	TIME_OF_VISITS NUMBER
   )
