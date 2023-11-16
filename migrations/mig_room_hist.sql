-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/04/2011 
-- CHANGE REASON: [ALERT-173188] 

DECLARE
    TYPE tab_room_hist IS TABLE OF room_hist%ROWTYPE;

    l_tab_room_hist tab_room_hist;

    l_error     t_error_out;
    l_error_msg VARCHAR2(4000);

BEGIN
    SELECT rh.* BULK COLLECT
      INTO l_tab_room_hist
      FROM room_hist rh;

    IF (l_tab_room_hist.exists(1))
    THEN
        FOR rec IN 1 .. l_tab_room_hist.count
        LOOP
            IF (l_tab_room_hist(rec).dcs_ids IS NOT NULL AND l_tab_room_hist(rec).dcs_ids.exists(1))
            THEN
                FOR i IN 1 .. l_tab_room_hist(rec).dcs_ids.count
                LOOP
                    INSERT INTO room_dep_clin_serv_hist
                        (id_room_hist, id_room_dep_clin_serv, id_room, id_dep_clin_serv)
                    VALUES
                        (l_tab_room_hist(rec).id_room_hist,
                         NULL,
                         l_tab_room_hist(rec).id_room,
                         l_tab_room_hist(rec).dcs_ids(i));
                END LOOP;
            END IF;
        END LOOP;
    END IF;
END;
/
