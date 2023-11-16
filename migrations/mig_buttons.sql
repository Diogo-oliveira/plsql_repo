-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Oct/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_count PLS_INTEGER := 0;
BEGIN
    --ProgressNotesAddTemplate, level 0
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block IN (62, 85, 67))
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 58
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 58
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 58
     WHERE c.id_parent IN (62, 85, 67);

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block IN (62, 85, 67);

    --
    --ShortcutBigIcon
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_profile_template IN (SELECT pt.id_profile_template
                                       FROM profile_template pt
                                      WHERE pt.id_software = 11);

    BEGIN
    
        FOR rec IN (SELECT p.*
                      FROM prof_conf_button_block p
                      JOIN profile_template pt
                        ON pt.id_profile_template = p.id_profile_template
                     WHERE p.id_conf_button_block IN (53, 54, 55, 72, 93)
                       AND pt.id_software = 11)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 66
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 66
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 66
     WHERE c.id_parent IN (53, 54, 55, 72, 93)
     and c.id_conf_button_block in (73, 77, 84, 89, 94);

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block IN (72, 93);
     
     --ProgressNotesAddTemplate
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 67
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 67
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 67
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_profile_template IN (SELECT pt.id_profile_template
                                       FROM profile_template pt
                                      WHERE pt.id_software = 11);

    BEGIN
    
        FOR rec IN (SELECT p.*
                      FROM prof_conf_button_block p
                      JOIN profile_template pt
                        ON pt.id_profile_template = p.id_profile_template
                     WHERE p.id_conf_button_block IN (2, 10)
                       AND pt.id_software = 11)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 67
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 67
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;
    
    --ProgressNotesReqSinaisvitais, level 1
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block = 84)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 71
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 71
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 71
     WHERE c.id_parent = 84;

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block = 84;
     
--Physical exam, level 2
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block = 68)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 15
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 15
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 15
     WHERE c.id_parent = 68;

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block = 68;
    
   
END;
/



-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Oct/2011
-- CHANGE REASON: ALERT-168848 H and P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_count PLS_INTEGER := 0;
BEGIN
    --ProgressNotesAddTemplate, level 0
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (62, 85, 67);

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block IN (62, 85, 67))
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 58
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 58
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;
    
    UPDATE conf_button_block c
       SET c.id_parent = 58
     WHERE c.id_parent IN (62, 85, 67);

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block IN (62, 85, 67);

    --
    --ShortcutBigIcon
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 66
     WHERE e.id_conf_button_block IN (53, 54, 55, 72, 93)
       AND e.id_profile_template IN (SELECT pt.id_profile_template
                                       FROM profile_template pt
                                      WHERE pt.id_software = 11);

    BEGIN
    
        FOR rec IN (SELECT p.*
                      FROM prof_conf_button_block p
                      JOIN profile_template pt
                        ON pt.id_profile_template = p.id_profile_template
                     WHERE p.id_conf_button_block IN (53, 54, 55, 72, 93)
                       AND pt.id_software = 11)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 66
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 66
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 66
     WHERE c.id_parent IN (53, 54, 55, 72, 93)
     and c.id_conf_button_block in (73, 77, 84, 89, 94);

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block IN (72, 93);
     
     --ProgressNotesAddTemplate
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_pn_note_type <> 1;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 58
     WHERE e.id_conf_button_block IN (2, 10)
       AND e.id_profile_template IN (SELECT pt.id_profile_template
                                       FROM profile_template pt
                                      WHERE pt.id_software = 11);

    BEGIN
    
        FOR rec IN (SELECT p.*
                      FROM prof_conf_button_block p
                      JOIN profile_template pt
                        ON pt.id_profile_template = p.id_profile_template
                     WHERE p.id_conf_button_block IN (2, 10)
                       AND pt.id_software = 11)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 58
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 58
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;
    
    --ProgressNotesReqSinaisvitais, level 1
    UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 71
     WHERE e.id_conf_button_block = 84;

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block = 84)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 71
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 71
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 71
     WHERE c.id_parent = 84;

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block = 84;
     
--Physical exam, level 2
    /*UPDATE pn_button_mkt e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    UPDATE pn_button_soft_inst e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    UPDATE pn_prof_soap_button e
       SET e.id_conf_button_block = 15
     WHERE e.id_conf_button_block = 68;

    BEGIN
    
        FOR rec IN (SELECT *
                      FROM prof_conf_button_block p
                     WHERE p.id_conf_button_block = 68)
        LOOP
            --check if there 
            SELECT COUNT(1)
              INTO l_count
              FROM prof_conf_button_block p
             WHERE p.id_conf_button_block = 15
               AND p.id_profile_template = rec.id_profile_template
               AND p.id_market = rec.id_market;
        
            IF (l_count > 0)
            THEN
                DELETE FROM prof_conf_button_block p
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            ELSE
                UPDATE prof_conf_button_block p
                   SET p.id_conf_button_block = 15
                 WHERE p.id_conf_button_block = rec.id_conf_button_block
                   AND p.id_profile_template = rec.id_profile_template
                   AND p.id_market = rec.id_market;
            END IF;
        
        END LOOP;
    END;

    UPDATE conf_button_block c
       SET c.id_parent = 15
     WHERE c.id_parent = 68;

    DELETE FROM conf_button_block c
     WHERE c.id_conf_button_block = 68;*/
    
   
END;
/
