-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_id_epis_pn_det epis_pn_det.id_epis_pn_det%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM epis_pn_det e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
    
    FOR rec IN (SELECT *
                  FROM epis_pn_det_work e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det_work epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det_work e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det_work e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det_work e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
END;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_id_epis_pn_det epis_pn_det.id_epis_pn_det%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM epis_pn_det e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
    
    FOR rec IN (SELECT *
                  FROM epis_pn_det_work e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det_work epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det_work e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det_work e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det_work e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
END;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Set/2011
-- CHANGE REASON: ALERT-168848 H and P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_id_epis_pn_det epis_pn_det.id_epis_pn_det%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM epis_pn_det e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
    
    FOR rec IN (SELECT *
                  FROM epis_pn_det_work e
                 WHERE e.id_pn_data_block = 66
                   AND e.flg_status = 'A')
    LOOP
        l_id_epis_pn_det := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT epd.id_epis_pn_det
              INTO l_id_epis_pn_det
              FROM epis_pn_det_work epd
             WHERE epd.id_epis_pn = rec.id_epis_pn
               AND epd.id_pn_data_block = 65
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn_det := NULL;
        END;
    
        IF (l_id_epis_pn_det IS NOT NULL)
        THEN
            --join the other exam and the image texts
            UPDATE epis_pn_det_work e
               SET e.pn_note = e.pn_note || chr(10) || rec.pn_note
             WHERE e.id_epis_pn_det = l_id_epis_pn_det;
             
             UPDATE epis_pn_det_work e
               SET e.flg_status = 'R'
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        ELSE
            --just update the data block id
            UPDATE epis_pn_det_work e
               SET e.id_pn_data_block = 65
             WHERE e.id_epis_pn_det = rec.id_epis_pn_det;
        END IF;
    
    END LOOP;
END;
/

