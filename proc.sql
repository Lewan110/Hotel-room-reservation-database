--------------------------------------------------------
--  DDL for Sequence RESERVATION_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  RESERVATION_SEQ  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--------------------------------------------------------
--  DDL for View CLIENT_RESERVATIONS
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW CLIENT_RESERVATIONS ("PESEL", "FIRST_NAME", "LAST_NAME", "RESERVATION_ID", "BEGINNING", "ENDING", "ROOM_ID", "CAPACITY") AS 
  SELECT
    c.pesel,
    c.first_name,
    c.last_name,
    res.reservation_id,
    res.beginning,
    res.ending,
    r.room_id,
    r.capacity
FROM
    clients c
    LEFT JOIN client_reservation cr ON c.pesel = cr.pesel
    JOIN reservations res ON res.reservation_id = cr.reservation_id
    LEFT JOIN rooms r ON r.room_id = res.room_id
ORDER BY
    reservation_id
;
--------------------------------------------------------
--  DDL for Trigger RESERVATION_ID_SEQ
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER RESERVATION_ID_SEQ 
  BEFORE INSERT ON reservations
  FOR EACH ROW
BEGIN
  SELECT reservation_seq.nextval
    INTO :new.reservation_id
    FROM dual;
END;
/
ALTER TRIGGER RESERVATION_ID_SEQ ENABLE;
--------------------------------------------------------
--  DDL for Trigger RESERVATION_ID_SEQ
--------------------------------------------------------
CREATE OR REPLACE TRIGGER update_client_summary AFTER
    INSERT OR UPDATE ON reservations
    FOR EACH ROW
DECLARE
    p_pesel   number;
BEGIN
    IF
        (:new.status = 'completed' )
    THEN
        SELECT
            c.pesel
        INTO p_pesel
        FROM
            clients c
            JOIN client_reservation cr ON c.pesel = cr.pesel
        WHERE
            cr.reservation_id =:new.reservation_id
            AND ROWNUM = 1;

        UPDATE client_summary
        SET
            n_o_visits = n_o_visits + 1,
            time_of_visits = time_of_visits + (:new.ending -:new.beginning );

    END IF;
END;
--------------------------------------------------------
--  DDL for Procedure ADD_RESERVATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE ADD_RESERVATION
(p_pesel IN number)
is

begin
    insert into reservations(status,date_of_reservation)
        values ('pending', sysdate);

    insert into client_reservation
        values(p_pesel,reservation_seq.CURRVAL);

end;

/
--------------------------------------------------------
--  DDL for Procedure CLIENT_VISITS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE CLIENT_VISITS (
    p_pesel IN VARCHAR2
) IS

    CURSOR summary IS SELECT
        c.pesel,
        c.first_name,
        c.last_name,
        COUNT(res.reservation_id) n_o_visits,
        SUM(res.ending - res.beginning) days_in_hotel
                      FROM
        clients c
        JOIN client_reservation cr ON c.pesel = cr.pesel
        JOIN reservations res ON cr.reservation_id = res.reservation_id
                      WHERE
        res.status = 'completed'
                      GROUP BY
        c.pesel,
        c.first_name,
        c.last_name;

BEGIN
    DELETE FROM client_summary;

    FOR v_summary IN summary LOOP
        INSERT INTO client_summary (
            pesel,
            firstname,
            lastname,
            n_o_visits,
            time_of_visits
        ) VALUES (
            v_summary.pesel,
            v_summary.first_name,
            v_summary.last_name,
            v_summary.n_o_visits,
            v_summary.days_in_hotel
        );

    END LOOP;

END;

/
--------------------------------------------------------
--  DDL for Procedure RANDOM_RESERVATIONS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE RANDOM_RESERVATIONS (
    range IN NUMBER
) IS

    v_date_of_purchase      DATE;
    v_beginning             DATE;
    v_ending                DATE;
    v_status                VARCHAR2(10);
    v_date_of_reservation   DATE;
    v_room_id               INTEGER;
    v_random_client         NUMBER;
BEGIN
    FOR loop_counter IN 1..range LOOP
        v_beginning := TO_DATE(trunc(dbms_random.value(TO_CHAR(DATE '2010-01-01','J'),TO_CHAR(DATE '2018-3-12','J') ) ),'J');

        v_ending := trunc(v_beginning + dbms_random.value(1,20) );
        v_date_of_reservation := ( v_beginning - dbms_random.value(1,100) );
        v_status := 'completed';
        v_room_id := dbms_random.value(1,20);
        v_date_of_purchase := trunc(v_ending - dbms_random.value(0,1) );
        SELECT
            pesel
        INTO v_random_client
        FROM
            (
                SELECT
                    pesel,
                    dbms_random.value
                FROM
                    clients
                ORDER BY
                    2
            )
        WHERE
            ROWNUM = 1;

        INSERT INTO reservations (
            date_of_purchase,
            beginning,
            ending,
            status,
            date_of_reservation,
            room_id
        ) VALUES (
            v_date_of_purchase,
            v_beginning,
            v_ending,
            v_status,
            v_date_of_reservation,
            v_room_id
        );

        INSERT INTO client_reservation (
            pesel,
            reservation_id
        ) VALUES (
            v_random_client,
            reservation_seq.CURRVAL
        );

    END LOOP;

    COMMIT;
END;

/
--------------------------------------------------------
--  DDL for Package CLIENT_SUPPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE CLIENT_SUPPORT IS
    
    PROCEDURE print_client (
        p_pesel VARCHAR2
    );

    PROCEDURE all_free_rooms (
        starting_date   IN DATE,
        ending_date     IN DATE
    );
    PROCEDURE BILL(
    p_reservation_id IN NUMBER);

END;

/
--------------------------------------------------------
--  DDL for Package ROOM_RESERVATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE ROOM_RESERVATION IS
    
    PROCEDURE add_reservation (
        p_pesel IN VARCHAR2
    );

    FUNCTION is_free_room (
        starting_date     IN DATE,
        ending_date       IN DATE,
        p_room_capacity   IN NUMBER,
        p_room_category   IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE are_free_rooms (
        starting_date     IN DATE,
        ending_date       IN DATE,
        p_room_capacity   IN NUMBER,
        p_room_category   IN VARCHAR2
    );

    PROCEDURE make_reservation (
        p_room_id         IN NUMBER,
        p_reservation_id  IN NUMBER,
        starting_date   IN DATE,
        ending_date     IN DATE
    );
    PROCEDURE cancel_reservation(
    p_reservation_id  IN NUMBER);

    PROCEDURE complete_reservation(
    p_reservation_id  IN NUMBER);

END;

/
--------------------------------------------------------
--  DDL for Package Body CLIENT_SUPPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY CLIENT_SUPPORT IS

    PROCEDURE print_client (
        p_pesel VARCHAR2
    ) IS
        v_client   clients%rowtype;
        CURSOR p_clients IS SELECT
            *
                            FROM
            clients
                            WHERE
            pesel = p_pesel;

    BEGIN
        FOR v_client IN p_clients LOOP
            dbms_output.put_line(v_client.first_name
                                   || ' '
                                   || v_client.last_name
                                   || ' '
                                   || v_client.telephone);
        END LOOP;
    END;

    PROCEDURE all_free_rooms (
        starting_date   IN DATE,
        ending_date     IN DATE
    ) IS

        v_room       rooms%rowtype;
        v_category   VARCHAR2(50);
        CURSOR c_rooms IS SELECT
            r.room_id,
            r.capacity,
            r.price_per_day,
            r.room_category
                          FROM
            rooms r
            LEFT JOIN reservations res ON r.room_id = res.room_id
                          WHERE
            starting_date <= nvl(res.ending,SYSDATE + 10000)
            AND ending_date >= nvl(res.beginning,SYSDATE - 10);

    BEGIN
        FOR v_room IN c_rooms LOOP
            SELECT
                name
            INTO v_category
            FROM
                room_category
            WHERE
                category_id = v_room.room_category;

            dbms_output.put_line(v_room.room_id
                                   || ' '
                                   || v_room.capacity
                                   || ' '
                                   || v_room.price_per_day
                                   || ' '
                                   || v_category);

        END LOOP;
    END;

    PROCEDURE bill (
        p_reservation_id IN NUMBER
    ) IS
        n_o_visits   NUMBER;
        final_cost   NUMBER;
        to_pay      number;
        discount     NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO n_o_visits
        FROM
            clients c
            JOIN client_reservation cr ON c.pesel = cr.pesel
            JOIN reservations r ON cr.reservation_id = r.reservation_id
        WHERE
            r.status = 'completed';

        IF
            ( n_o_visits > 10 )
        THEN
            discount := 10;
        ELSE
            discount := 0;
        END IF;


        SELECT
            SUM(r.price_per_day)
        INTO final_cost
        FROM
            rooms r
            JOIN reservations res ON r.room_id = res.room_id
        WHERE
            res.reservation_id = p_reservation_id;

        to_pay:=final_cost-final_cost*(discount/100);
        dbms_output.put_line('Final price: '
                               || final_cost
                               || ' discount: '
                               || discount
                               || '% '
                               || 'To pay: '
                               || to_pay );

    END;

END;

/
--------------------------------------------------------
--  DDL for Package Body ROOM_RESERVATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY ROOM_RESERVATION IS
    
    procedure add_reservation(
    p_pesel IN VARCHAR2)
    is 
    begin
    insert into reservations(status,date_of_reservation)
        values ('pending', sysdate);

        insert into client_reservation
        values(p_pesel,reservation_seq.CURRVAL);

        dbms_output.put_line(reservation_seq.CURRVAL);
    end;

    FUNCTION is_free_room (
        starting_date   IN DATE,
        ending_date     IN DATE,
        p_room_capacity   IN NUMBER,
        p_room_category   IN VARCHAR2
    ) RETURN NUMBER IS
        v_room_id   NUMBER;
    BEGIN
        SELECT
            r.room_id
        INTO v_room_id
        FROM
            rooms r
            LEFT JOIN reservations res ON r.room_id = res.room_id
            JOIN room_category rc ON rc.category_id = r.room_category
        WHERE
            r.capacity = p_room_capacity
            AND rc.name = p_room_category
                AND NOT (
                    starting_date BETWEEN res.BEGINNING AND res.ending
                    OR ending_date BETWEEN res.BEGINNING AND res.ending
                    OR res.BEGINNING BETWEEN starting_date AND ending_date
                    OR res.ending BETWEEN starting_date AND ending_date
                )

            AND ROWNUM = 1;

        --dbms_output.put_line(v_room_id);

    EXCEPTION
        WHEN no_data_found THEN
            v_room_id := 0;
    END;

    PROCEDURE are_free_rooms (
        starting_date   IN DATE,
        ending_date     IN DATE,
        p_room_capacity   IN NUMBER,
        p_room_category   IN VARCHAR2
    ) IS

        v_room_id   NUMBER;
        CURSOR rooms IS SELECT
            r.room_id
                        FROM
            rooms r
            LEFT JOIN reservations res ON r.room_id = res.room_id
            JOIN room_category rc ON rc.category_id = r.room_category
                        WHERE
            r.capacity = p_room_capacity
            AND rc.name = p_room_category 

            AND
            starting_date<=nvl(res.ENDING,sysdate+10000) AND
            ending_date>=nvl(res.BEGINNING,sysdate-10)

                ;

    BEGIN
        FOR v_room_id IN rooms LOOP
         dbms_output.put_line(v_room_id.room_id);
        END LOOP;
    END;

    PROCEDURE make_reservation (
        p_room_id         IN NUMBER,
        p_reservation_id  IN NUMBER,
        starting_date   IN DATE,
        ending_date     IN DATE
    )
        IS
        BEGIN
         update reservations
                set BEGINNING=starting_date, 
                    ending=ending_date,
                    ROOM_Id=p_room_id,
                    status='booked'
                where reservation_id=p_reservation_id; 
        END;
        PROCEDURE cancel_reservation(
    p_reservation_id  IN NUMBER)
        is 
        begin
        update reservations
            set status='canceled',
            room_id=null
            where reservation_id=p_reservation_id; 
        end;

        PROCEDURE complete_reservation(
    p_reservation_id  IN NUMBER)
        is 
        begin
        update reservations
            set status='completed',
            date_of_purchase =sysdate
            where reservation_id=p_reservation_id; 
        end;
END;

