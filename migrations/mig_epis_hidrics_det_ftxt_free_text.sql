-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15/06/2011 
-- CHANGE REASON: [ALERT-185057] : Intake and Output: It is not possible to use a created free text in more than one line
DECLARE
    l_id_epis_hidrics_line     epis_hidrics_line.id_epis_hidrics_line%TYPE;
    l_id_epis_hidrics_det_ftxt epis_hidrics_det_ftxt.id_epis_hidrics_det_ftxt%TYPE;
    l_id_way                   epis_hidrics_line.id_way%TYPE;
    l_dt_epis_hd_ftxt_hist     epis_hd_ftxt_hist.dt_epis_hd_ftxt_hist%TYPE;
    l_id_hidrics               hidrics.id_hidrics%TYPE;
    l_id_hidrics_location      hidrics_location.id_hidrics_location%TYPE;
    l_id_hidrics_device        hidrics_device.id_hidrics_device%TYPE;
    l_id_epis_hidrics_det      epis_hidrics_det.id_epis_hidrics_det%TYPE;
    l_id_hidrics_charact       hidrics_charact.id_hidrics_charact%TYPE;
    l_free_text                epis_hidrics_det_ftxt.free_text%TYPE;
    l_id_patient               patient.id_patient%TYPE;
    l_id_prof_last_change      epis_hidrics_det_ftxt.id_prof_last_change%TYPE;
    l_dt_eh_det_ftxt           epis_hidrics_det_ftxt.dt_eh_det_ftxt%TYPE;
    l_id_epis_hidrics          epis_hidrics.id_epis_hidrics%TYPE;

    CURSOR c_ftxt_ways IS
        SELECT ehl.id_epis_hidrics_line, ehdf.id_epis_hidrics_det_ftxt, ehl.id_way
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN way hw
            ON hw.id_way = ehdf.id_way
           AND ehdf.id_way IS NOT NULL
           AND hw.flg_way_type = 'O'
           AND ehdf.free_text IS NOT NULL;

    CURSOR c_ftxt_ways_hist IS
        SELECT ehl.id_epis_hidrics_line,
               ehdf.id_epis_hidrics_det_ftxt,
               ehl.id_way,
               ehdf.dt_epis_hd_ftxt_hist,
               ehdf.free_text,
               ehdf.id_patient,
               ehdf.id_prof_last_change,
               ehdf.dt_eh_det_ftxt,
               ehdf.id_epis_hidrics
          FROM epis_hidrics_line_hist ehl
          JOIN epis_hd_ftxt_hist ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN way hw
            ON hw.id_way = ehl.id_way
           AND ehdf.id_way IS NOT NULL
           AND hw.flg_way_type = 'O';

    CURSOR c_ftxt_hidrics IS
        SELECT ehl.id_epis_hidrics_line, ehdf.id_epis_hidrics_det_ftxt, ehl.id_hidrics
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics hd
            ON hd.id_hidrics = ehl.id_hidrics
           AND ehdf.id_hidrics IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehdf.free_text IS NOT NULL;

    CURSOR c_ftxt_hidrics_hist IS
        SELECT ehl.id_epis_hidrics_line,
               ehdf.id_epis_hidrics_det_ftxt,
               ehl.id_hidrics,
               ehdf.dt_epis_hd_ftxt_hist,
               ehdf.free_text,
               ehdf.id_patient,
               ehdf.id_prof_last_change,
               ehdf.dt_eh_det_ftxt,
               ehdf.id_epis_hidrics
          FROM epis_hidrics_line_hist ehl
          JOIN epis_hd_ftxt_hist ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics hd
            ON hd.id_hidrics = ehl.id_hidrics
           AND ehdf.id_hidrics IS NOT NULL
           AND hd.flg_free_txt = 'Y';

    CURSOR c_ftxt_body_part IS
        SELECT ehl.id_epis_hidrics_line, ehdf.id_epis_hidrics_det_ftxt, ehl.id_hidrics_location
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics_location hl
            ON hl.id_hidrics_location = ehl.id_hidrics_location
           AND ehdf.id_hidrics_location IS NOT NULL
           AND hl.id_body_part IS NULL
           AND ehdf.free_text IS NOT NULL;

    CURSOR c_ftxt_body_part_hist IS
        SELECT ehl.id_epis_hidrics_line,
               ehdf.id_epis_hidrics_det_ftxt,
               ehl.id_hidrics_location,
               ehdf.dt_epis_hd_ftxt_hist,
               ehdf.free_text,
               ehdf.id_patient,
               ehdf.id_prof_last_change,
               ehdf.dt_eh_det_ftxt,
               ehdf.id_epis_hidrics
          FROM epis_hidrics_line_hist ehl
          JOIN epis_hd_ftxt_hist ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics_location hl
            ON hl.id_hidrics_location = ehl.id_hidrics_location
           AND ehdf.id_hidrics_location IS NOT NULL
           AND hl.id_body_part IS NULL;

    CURSOR c_ftxt_device IS
        SELECT ehd.id_epis_hidrics_det, ehdf.id_epis_hidrics_det_ftxt, ehd.id_hidrics_device
          FROM epis_hidrics_det ehd
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehd.id_epis_hidrics_det
          JOIN hidrics_device hd
            ON hd.id_hidrics_device = ehd.id_hidrics_device
         WHERE ehdf.id_hidrics_device IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehdf.free_text IS NOT NULL;

    CURSOR c_ftxt_device_hist IS
        SELECT ehd.id_epis_hidrics_det,
               ehdf.id_epis_hidrics_det_ftxt,
               ehd.id_hidrics_device,
               ehd.dt_epis_hidrics_det_hist,
               ehdf.free_text,
               ehdf.id_patient,
               ehdf.id_prof_last_change,
               ehdf.dt_eh_det_ftxt,
               ehdf.id_epis_hidrics
          FROM epis_hidrics_det_hist ehd
          JOIN epis_hd_ftxt_hist ehdf
            ON ehdf.id_epis_hidrics_det = ehd.id_epis_hidrics_det
          JOIN hidrics_device hd
            ON hd.id_hidrics_device = ehd.id_hidrics_device
           AND ehdf.id_hidrics_device IS NOT NULL
           AND hd.flg_free_txt = 'Y';

    CURSOR c_ftxt_chars IS
        SELECT ehdc.id_epis_hidrics_det, ehdc.id_hidrics_charact, ehdf.id_epis_hidrics_det_ftxt
          FROM epis_hidrics_det_charact ehdc
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehdc.id_epis_hidrics_det
           AND ehdf.id_hidrics_charact = ehdc.id_hidrics_charact
         WHERE ehdf.id_hidrics_charact IS NOT NULL
           AND ehdc.id_hidrics_charact = 0
           AND ehdf.free_text IS NOT NULL;

    CURSOR c_ftxt_chars_hist IS
        SELECT ehdc.id_epis_hidrics_det,
               ehdc.id_hidrics_charact,
               ehdf.id_epis_hidrics_det_ftxt,
               ehdc.dt_epis_hd_char_hist,
               ehdf.free_text,
               ehdf.id_patient,
               ehdf.id_prof_last_change,
               ehdf.dt_eh_det_ftxt,
               ehdf.id_epis_hidrics
          FROM epis_hd_char_hist ehdc
          JOIN epis_hd_ftxt_hist ehdf
            ON ehdf.id_epis_hidrics_det = ehdc.id_epis_hidrics_det
           AND ehdf.id_hidrics_charact = ehdc.id_hidrics_charact
         WHERE ehdf.id_hidrics_charact IS NOT NULL
           AND ehdc.id_hidrics_charact = 0;
BEGIN
    --ways actual values
    OPEN c_ftxt_ways;
    LOOP
        FETCH c_ftxt_ways
            INTO l_id_epis_hidrics_line, l_id_epis_hidrics_det_ftxt, l_id_way;
        EXIT WHEN c_ftxt_ways%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            -- update the actual value        
            UPDATE epis_hidrics_line ehl
               SET ehl.id_epis_hid_ftxt_way = l_id_epis_hidrics_det_ftxt
             WHERE ehl.id_epis_hidrics_line = l_id_epis_hidrics_line;
        
        END IF;
    END LOOP;

    --ways history values
    OPEN c_ftxt_ways_hist;
    LOOP
        FETCH c_ftxt_ways_hist
            INTO l_id_epis_hidrics_line,
                 l_id_epis_hidrics_det_ftxt,
                 l_id_way,
                 l_dt_epis_hd_ftxt_hist,
                 l_free_text,
                 l_id_patient,
                 l_id_prof_last_change,
                 l_dt_eh_det_ftxt,
                 l_id_epis_hidrics;
        EXIT WHEN c_ftxt_ways_hist%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            IF (l_free_text IS NOT NULL)
            THEN
                --check if the free text in the history exists , if no create it 
                BEGIN
                    SELECT ft.id_epis_hidrics_det_ftxt
                      INTO l_id_epis_hidrics_det_ftxt
                      FROM epis_hidrics_det_ftxt ft
                     WHERE ft.id_way = l_id_way
                       AND ft.free_text = l_free_text
                       AND ft.id_way IS NOT NULL
                       AND ft.id_hidrics_location IS NULL
                       AND ft.id_hidrics IS NULL
                       AND ft.id_hidrics_charact IS NULL
                       AND ft.id_hidrics_device IS NULL
                       AND ft.id_patient = l_id_patient
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        --insert it
                        SELECT seq_epis_hidrics_det_ftxt.nextval
                          INTO l_id_epis_hidrics_det_ftxt
                          FROM dual;
                    
                        INSERT INTO epis_hidrics_det_ftxt
                            (id_epis_hidrics_det_ftxt,
                             id_epis_hidrics,
                             id_way,
                             id_hidrics_location,
                             id_hidrics,
                             id_hidrics_charact,
                             free_text,
                             id_prof_last_change,
                             dt_eh_det_ftxt,
                             id_hidrics_device,
                             id_patient)
                        VALUES
                            (l_id_epis_hidrics_det_ftxt,
                             l_id_epis_hidrics,
                             l_id_way,
                             NULL,
                             NULL,
                             NULL,
                             l_free_text,
                             l_id_prof_last_change,
                             l_dt_eh_det_ftxt,
                             NULL,
                             l_id_patient);
                END;
            ELSE
                l_id_epis_hidrics_det_ftxt := NULL;
            END IF;
        
            UPDATE epis_hidrics_line_hist ehlh
               SET ehlh.id_epis_hid_ftxt_way = l_id_epis_hidrics_det_ftxt
             WHERE ehlh.id_epis_hidrics_line = l_id_epis_hidrics_line
               AND ehlh.dt_epis_hid_line_hist = l_dt_epis_hd_ftxt_hist;
        
        END IF;
    END LOOP;

    --hidrics actual values
    OPEN c_ftxt_hidrics;
    LOOP
        FETCH c_ftxt_hidrics
            INTO l_id_epis_hidrics_line, l_id_epis_hidrics_det_ftxt, l_id_hidrics;
        EXIT WHEN c_ftxt_hidrics%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            -- update the actual value        
            UPDATE epis_hidrics_line ehl
               SET ehl.id_epis_hid_ftxt_fluid = l_id_epis_hidrics_det_ftxt
             WHERE ehl.id_epis_hidrics_line = l_id_epis_hidrics_line;
        
        END IF;
    END LOOP;

    --hidrics history values
    OPEN c_ftxt_hidrics_hist;
    LOOP
        FETCH c_ftxt_hidrics_hist
            INTO l_id_epis_hidrics_line,
                 l_id_epis_hidrics_det_ftxt,
                 l_id_hidrics,
                 l_dt_epis_hd_ftxt_hist,
                 l_free_text,
                 l_id_patient,
                 l_id_prof_last_change,
                 l_dt_eh_det_ftxt,
                 l_id_epis_hidrics;
        EXIT WHEN c_ftxt_hidrics_hist%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            IF (l_free_text IS NOT NULL)
            THEN
                --check if the free text in the history exists , if no create it 
                BEGIN
                    SELECT ft.id_epis_hidrics_det_ftxt
                      INTO l_id_epis_hidrics_det_ftxt
                      FROM epis_hidrics_det_ftxt ft
                     WHERE ft.id_hidrics = l_id_hidrics
                       AND ft.free_text = l_free_text
                       AND ft.id_way IS NULL
                       AND ft.id_hidrics_location IS NULL
                       AND ft.id_hidrics IS NOT NULL
                       AND ft.id_hidrics_charact IS NULL
                       AND ft.id_hidrics_device IS NULL
                       AND ft.id_patient = l_id_patient
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --insert it
                        SELECT seq_epis_hidrics_det_ftxt.nextval
                          INTO l_id_epis_hidrics_det_ftxt
                          FROM dual;
                    
                        INSERT INTO epis_hidrics_det_ftxt
                            (id_epis_hidrics_det_ftxt,
                             id_epis_hidrics,
                             id_way,
                             id_hidrics_location,
                             id_hidrics,
                             id_hidrics_charact,
                             free_text,
                             id_prof_last_change,
                             dt_eh_det_ftxt,
                             id_hidrics_device,
                             id_patient)
                        VALUES
                            (l_id_epis_hidrics_det_ftxt,
                             l_id_epis_hidrics,
                             NULL,
                             NULL,
                             l_id_hidrics,
                             NULL,
                             l_free_text,
                             l_id_prof_last_change,
                             l_dt_eh_det_ftxt,
                             NULL,
                             l_id_patient);
                END;
            ELSE
                l_id_epis_hidrics_det_ftxt := NULL;
            END IF;
        
            UPDATE epis_hidrics_line_hist ehlh
               SET ehlh.id_epis_hid_ftxt_fluid = l_id_epis_hidrics_det_ftxt
             WHERE ehlh.id_epis_hidrics_line = l_id_epis_hidrics_line
               AND ehlh.dt_epis_hid_line_hist = l_dt_epis_hd_ftxt_hist;
        
        END IF;
    END LOOP;

    --body part actual values
    OPEN c_ftxt_body_part;
    LOOP
        FETCH c_ftxt_body_part
            INTO l_id_epis_hidrics_line, l_id_epis_hidrics_det_ftxt, l_id_hidrics_location;
        EXIT WHEN c_ftxt_body_part%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            -- update the actual value        
            UPDATE epis_hidrics_line ehl
               SET ehl.id_epis_hid_ftxt_loc = l_id_epis_hidrics_det_ftxt
             WHERE ehl.id_epis_hidrics_line = l_id_epis_hidrics_line;
        
        END IF;
    END LOOP;

    --body part history values
    OPEN c_ftxt_body_part_hist;
    LOOP
        FETCH c_ftxt_body_part_hist
            INTO l_id_epis_hidrics_line,
                 l_id_epis_hidrics_det_ftxt,
                 l_id_hidrics_location,
                 l_dt_epis_hd_ftxt_hist,
                 l_free_text,
                 l_id_patient,
                 l_id_prof_last_change,
                 l_dt_eh_det_ftxt,
                 l_id_epis_hidrics;
        EXIT WHEN c_ftxt_body_part_hist%NOTFOUND;
    
        IF l_id_epis_hidrics_line IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            IF (l_free_text IS NOT NULL)
            THEN
                --check if the free text in the history exists , if no create it 
                BEGIN
                    SELECT ft.id_epis_hidrics_det_ftxt
                      INTO l_id_epis_hidrics_det_ftxt
                      FROM epis_hidrics_det_ftxt ft
                     WHERE ft.id_hidrics_location = l_id_hidrics_location
                       AND ft.free_text = l_free_text
                       AND ft.id_way IS NULL
                       AND ft.id_hidrics_location IS NOT NULL
                       AND ft.id_hidrics IS NULL
                       AND ft.id_hidrics_charact IS NULL
                       AND ft.id_hidrics_device IS NULL
                       AND ft.id_patient = l_id_patient
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --insert it
                        SELECT seq_epis_hidrics_det_ftxt.nextval
                          INTO l_id_epis_hidrics_det_ftxt
                          FROM dual;
                    
                        INSERT INTO epis_hidrics_det_ftxt
                            (id_epis_hidrics_det_ftxt,
                             id_epis_hidrics,
                             id_way,
                             id_hidrics_location,
                             id_hidrics,
                             id_hidrics_charact,
                             free_text,
                             id_prof_last_change,
                             dt_eh_det_ftxt,
                             id_hidrics_device,
                             id_patient)
                        VALUES
                            (l_id_epis_hidrics_det_ftxt,
                             l_id_epis_hidrics,
                             NULL,
                             l_id_hidrics_location,
                             NULL,
                             NULL,
                             l_free_text,
                             l_id_prof_last_change,
                             l_dt_eh_det_ftxt,
                             NULL,
                             l_id_patient);
                END;
            ELSE
                l_id_epis_hidrics_det_ftxt := NULL;
            END IF;
        
            UPDATE epis_hidrics_line_hist ehlh
               SET ehlh.id_epis_hid_ftxt_loc = l_id_epis_hidrics_det_ftxt
             WHERE ehlh.id_epis_hidrics_line = l_id_epis_hidrics_line
               AND ehlh.dt_epis_hid_line_hist = l_dt_epis_hd_ftxt_hist;
        
        END IF;
    END LOOP;

    --device actual values
    OPEN c_ftxt_device;
    LOOP
        FETCH c_ftxt_device
            INTO l_id_epis_hidrics_det, l_id_epis_hidrics_det_ftxt, l_id_hidrics_device;
        EXIT WHEN c_ftxt_device%NOTFOUND;
    
        IF l_id_epis_hidrics_det IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            UPDATE epis_hidrics_det ehd
               SET ehd.id_epis_hid_ftxt_dev = l_id_epis_hidrics_det_ftxt
             WHERE ehd.id_epis_hidrics_det = l_id_epis_hidrics_det;
        END IF;
    END LOOP;

    --device history values
    OPEN c_ftxt_device_hist;
    LOOP
        FETCH c_ftxt_device_hist
            INTO l_id_epis_hidrics_det,
                 l_id_epis_hidrics_det_ftxt,
                 l_id_hidrics_device,
                 l_dt_epis_hd_ftxt_hist,
                 l_free_text,
                 l_id_patient,
                 l_id_prof_last_change,
                 l_dt_eh_det_ftxt,
                 l_id_epis_hidrics;
        EXIT WHEN c_ftxt_device_hist%NOTFOUND;
    
        IF l_id_epis_hidrics_det IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            IF (l_free_text IS NOT NULL)
            THEN
                --check if the free text in the history exists , if no create it 
                BEGIN
                    SELECT ft.id_epis_hidrics_det_ftxt
                      INTO l_id_epis_hidrics_det_ftxt
                      FROM epis_hidrics_det_ftxt ft
                     WHERE ft.id_hidrics_device = l_id_hidrics_device
                       AND ft.free_text = l_free_text
                       AND ft.id_way IS NULL
                       AND ft.id_hidrics_location IS NULL
                       AND ft.id_hidrics IS NULL
                       AND ft.id_hidrics_charact IS NULL
                       AND ft.id_hidrics_device IS NOT NULL
                       AND ft.id_patient = l_id_patient
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --insert it
                        SELECT seq_epis_hidrics_det_ftxt.nextval
                          INTO l_id_epis_hidrics_det_ftxt
                          FROM dual;
                    
                        INSERT INTO epis_hidrics_det_ftxt
                            (id_epis_hidrics_det_ftxt,
                             id_epis_hidrics,
                             id_way,
                             id_hidrics_location,
                             id_hidrics,
                             id_hidrics_charact,
                             free_text,
                             id_prof_last_change,
                             dt_eh_det_ftxt,
                             id_hidrics_device,
                             id_patient)
                        VALUES
                            (l_id_epis_hidrics_det_ftxt,
                             l_id_epis_hidrics,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             l_free_text,
                             l_id_prof_last_change,
                             l_dt_eh_det_ftxt,
                             l_id_hidrics_device,
                             l_id_patient);
                END;
            ELSE
                l_id_epis_hidrics_det_ftxt := NULL;
            END IF;
        
            UPDATE epis_hidrics_det_hist ehd
               SET ehd.id_epis_hid_ftxt_dev = l_id_epis_hidrics_det_ftxt
             WHERE ehd.id_epis_hidrics_det = l_id_epis_hidrics_det
               AND ehd.dt_epis_hidrics_det_hist = l_dt_epis_hd_ftxt_hist;
        END IF;
    END LOOP;

    --characteristics actual values
    OPEN c_ftxt_chars;
    LOOP
        FETCH c_ftxt_chars
            INTO l_id_epis_hidrics_det, l_id_hidrics_charact, l_id_epis_hidrics_det_ftxt;
        EXIT WHEN c_ftxt_chars%NOTFOUND;
    
        IF l_id_epis_hidrics_det IS NOT NULL
           AND l_id_hidrics_charact IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            UPDATE epis_hidrics_det_charact ehdc
               SET ehdc.id_epis_hid_ftxt_char = l_id_epis_hidrics_det_ftxt
             WHERE ehdc.id_epis_hidrics_det = l_id_epis_hidrics_det
               AND ehdc.id_hidrics_charact = l_id_hidrics_charact;
        END IF;
    END LOOP;

    --characteristics history values
    OPEN c_ftxt_chars_hist;
    LOOP
        FETCH c_ftxt_chars_hist
            INTO l_id_epis_hidrics_det,
                 l_id_hidrics_charact,
                 l_id_epis_hidrics_det_ftxt,
                 l_dt_epis_hd_ftxt_hist,
                 l_free_text,
                 l_id_patient,
                 l_id_prof_last_change,
                 l_dt_eh_det_ftxt,
                 l_id_epis_hidrics;
        EXIT WHEN c_ftxt_chars_hist%NOTFOUND;
    
        IF l_id_epis_hidrics_det IS NOT NULL
           AND l_id_hidrics_charact IS NOT NULL
           AND l_id_epis_hidrics_det_ftxt IS NOT NULL
        THEN
            IF (l_free_text IS NOT NULL)
            THEN
                --check if the free text in the history exists , if no create it 
                BEGIN
                    SELECT ft.id_epis_hidrics_det_ftxt
                      INTO l_id_epis_hidrics_det_ftxt
                      FROM epis_hidrics_det_ftxt ft
                     WHERE ft.id_hidrics_charact = l_id_hidrics_charact
                       AND ft.free_text = l_free_text
                       AND ft.id_way IS NULL
                       AND ft.id_hidrics_location IS NULL
                       AND ft.id_hidrics IS NULL
                       AND ft.id_hidrics_charact IS NOT NULL
                       AND ft.id_hidrics_device IS NULL
                       AND ft.id_patient = l_id_patient
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --insert it
                        SELECT seq_epis_hidrics_det_ftxt.nextval
                          INTO l_id_epis_hidrics_det_ftxt
                          FROM dual;
                    
                        INSERT INTO epis_hidrics_det_ftxt
                            (id_epis_hidrics_det_ftxt,
                             id_epis_hidrics,
                             id_way,
                             id_hidrics_location,
                             id_hidrics,
                             id_hidrics_charact,
                             free_text,
                             id_prof_last_change,
                             dt_eh_det_ftxt,
                             id_hidrics_device,
                             id_patient)
                        VALUES
                            (l_id_epis_hidrics_det_ftxt,
                             l_id_epis_hidrics,
                             NULL,
                             NULL,
                             NULL,
                             l_id_hidrics_charact,
                             l_free_text,
                             l_id_prof_last_change,
                             l_dt_eh_det_ftxt,
                             NULL,
                             l_id_patient);
                END;
            ELSE
                l_id_epis_hidrics_det_ftxt := NULL;
            END IF;
        
            UPDATE epis_hd_char_hist ehd
               SET ehd.id_epis_hid_ftxt_char = l_id_epis_hidrics_det_ftxt
             WHERE ehd.id_epis_hidrics_det = l_id_epis_hidrics_det
               AND ehd.dt_epis_hd_char_hist = l_dt_epis_hd_ftxt_hist
               AND ehd.id_hidrics_charact = l_id_hidrics_charact;
        END IF;
    END LOOP;

END;
/
-- CHANGE END: Sofia Mendes
