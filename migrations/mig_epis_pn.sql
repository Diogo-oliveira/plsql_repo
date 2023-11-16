-- CHANGED BY: António Neto
-- CHANGE DATE: 06/01/2012
-- CHANGE REASON: [ALERT-211833] Fix findings based on the Arch script - Solve findings identified by Technical Arq. BD for H&P v.1
BEGIN
    EXECUTE IMMEDIATE 'UPDATE epis_pn epn
       SET epn.dt_pn_date = epn.pn_date
     WHERE epn.pn_date IS NOT NULL
       AND epn.dt_pn_date IS NULL';
EXCEPTION
    WHEN OTHERS THEN
		    --If Column dropped after running first upgrade ignore error (AN)
        IF SQLCODE <> '-904'
        THEN
            RAISE;
        END IF;
END;
/
--CHANGE END: António Neto



-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 27/03/2014 09:28
-- CHANGE REASON: [ALERT-280237] 
UPDATE epis_pn a
   SET a.id_pn_area = 12
 WHERE a.id_pn_area = 4
   AND a.id_pn_note_type = 30;
 
-- CHANGE END: Paulo Teixeira