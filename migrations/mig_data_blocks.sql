-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Oct/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_count PLS_INTEGER := 0;
BEGIN
    --social history
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 58;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 80;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 58
             WHERE e.id_pn_data_block = 80;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 58;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 80;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 58
             WHERE e.id_pn_data_block = 80;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 80;

    --assessment tools
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 33;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 91;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 33
             WHERE e.id_pn_data_block = 91;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 33;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 91;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 33
             WHERE e.id_pn_data_block = 91;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 91;

    --free text notes
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 92;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 92
             WHERE e.id_pn_data_block = 96;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 92;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 92
             WHERE e.id_pn_data_block = 96;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 96;
     
    --care plans
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 43;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 68;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 43
             WHERE e.id_pn_data_block = 68;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 43;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 43
             WHERE e.id_pn_data_block = 68;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 68;

END;
/


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Oct/2011
-- CHANGE REASON: ALERT-168848 H and P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_count PLS_INTEGER := 0;
BEGIN
    --social history
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 58
     WHERE e.id_pn_data_block = 80;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 58;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 80;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 58
             WHERE e.id_pn_data_block = 80;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 58;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 80;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 58
             WHERE e.id_pn_data_block = 80;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 80;

    --assessment tools
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 33
     WHERE e.id_pn_data_block = 91;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 33;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 91;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 33
             WHERE e.id_pn_data_block = 91;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 33;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 91;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 33
             WHERE e.id_pn_data_block = 91;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 91;

    --free text notes
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 92
     WHERE e.id_pn_data_block = 96;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 92;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 92
             WHERE e.id_pn_data_block = 96;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 92;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 92
             WHERE e.id_pn_data_block = 96;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 96;
     
    --care plans
    UPDATE epis_pn_det_hist e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE epis_pn_det e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE epis_pn_det_work e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE conf_button_block e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_mkt e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_soft_inst e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    UPDATE pn_dblock_task_type e
       SET e.id_pn_data_block = 43
     WHERE e.id_pn_data_block = 68;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_inst p
         WHERE p.id_pn_data_block = 43;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_inst e
             WHERE e.id_pn_data_block = 68;
        ELSE
            UPDATE pn_free_text_inst e
               SET e.id_pn_data_block = 43
             WHERE e.id_pn_data_block = 68;
        END IF;
    END;

    BEGIN
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM pn_free_text_mkt p
         WHERE p.id_pn_data_block = 43;
    
        IF (l_count > 0)
        THEN
            DELETE FROM pn_free_text_mkt e
             WHERE e.id_pn_data_block = 96;
        ELSE
            UPDATE pn_free_text_mkt e
               SET e.id_pn_data_block = 43
             WHERE e.id_pn_data_block = 68;
        END IF;
    END;

    DELETE FROM pn_data_block p
     WHERE p.id_pn_data_block = 68;

END;
/
