-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: ALERT-245633 Single page error inserting vital signs
BEGIN
    UPDATE epis_pn_det_task e
       SET e.flg_action = 'S'
     WHERE e.flg_action IS NULL;
END;
/
--CHANGE END: Sofia Mendes
