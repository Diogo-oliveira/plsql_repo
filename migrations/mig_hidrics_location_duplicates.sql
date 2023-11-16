-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 24/Oct/2011 
-- CHANGE REASON: [ALERT-200929 ] 

DECLARE

    CURSOR c_hl1 IS
        SELECT ev1.id_hidrics_location to_rem
          FROM (SELECT *
                  FROM hidrics_location a
                 WHERE a.flg_available = 'Y') ev1,
               (SELECT *
                  FROM hidrics_location a
                 WHERE a.flg_available = 'Y') ev2
         WHERE ((ev1.id_body_part = ev2.id_body_part) OR (ev1.id_body_part IS NULL AND ev2.id_body_part IS NULL))
           AND ((ev1.id_body_side = ev2.id_body_side) OR (ev1.id_body_side IS NULL AND ev2.id_body_side IS NULL))
           AND ev1.flg_available = 'Y'
           AND ev2.flg_available = 'Y'
           AND ev1.id_hidrics_location > ev2.id_hidrics_location;

BEGIN

    FOR ev IN c_hl1
    LOOP
    
        DELETE hidrics_location_rel a
         WHERE a.id_hidrics_location = ev.to_rem;
    
        UPDATE hidrics_location a
           SET a.flg_available = 'N'
         WHERE a.id_hidrics_location = ev.to_rem;
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLERRM);
END;
/
