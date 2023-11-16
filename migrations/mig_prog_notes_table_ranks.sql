-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
DECLARE
    l_count       PLS_INTEGER := 0;
    l_id_software software.id_software%TYPE;
    l_rank        vs_soft_inst.rank%TYPE;
BEGIN
    UPDATE epis_pn_det_task epdt
       SET epdt.table_position = epdt.rank_task
     WHERE epdt.id_epis_pn_det IN (SELECT epd.id_epis_pn_det
                                     FROM epis_pn_det epd
                                    WHERE epd.id_pn_data_block = 143)
       AND epdt.table_position IS NULL;

    FOR rec IN (SELECT epdt.id_epis_pn_det_task,
                       epdt.id_group_table,
                       epi.id_institution,
                       epi.id_episode,
                       epi.id_epis_type
                  FROM epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                  JOIN epis_pn ep
                    ON ep.id_epis_pn = epd.id_epis_pn
                  JOIN episode epi
                    ON epi.id_episode = ep.id_episode
                 WHERE epd.id_pn_data_block = 143
                   AND epdt.id_group_table IS NOT NULL)
    LOOP
    
        --get episode SW
        BEGIN
            SELECT id_software
              INTO l_id_software
              FROM (SELECT etsi.id_software
                      FROM epis_type_soft_inst etsi
                     WHERE etsi.id_epis_type = rec.id_epis_type
                       AND etsi.id_institution IN (rec.id_institution, 0)
                     ORDER BY etsi.id_institution DESC, etsi.id_software DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_software := NULL;
                dbms_output.put_line('No software found. id_epis_type: ' || rec.id_epis_type || ' id_institution: ' ||
                                     rec.id_institution);
        END;
    
        IF (l_id_software IS NOT NULL)
        THEN
            BEGIN
                SELECT v.rank
                  INTO l_rank
                  FROM vs_soft_inst v
                 WHERE v.id_vital_sign = rec.id_group_table
                   AND v.id_software = l_id_software
                   AND v.id_institution = rec.id_institution
                   AND v.flg_view = 'V2';
            EXCEPTION
                WHEN OTHERS THEN
                    l_rank := NULL;
                    dbms_output.put_line('No rank found. id_vital_sign: ' || rec.id_group_table || ' id_software: ' ||
                                         l_id_software || ' id_institution: ' || rec.id_institution);
            END;
        
            UPDATE epis_pn_det_task epdt
               SET epdt.rank_task = l_rank
             WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task;
        
        END IF;
    END LOOP;

END;
/
-- CHANGED END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
DECLARE
    l_count          PLS_INTEGER := 0;
    l_id_software    software.id_software%TYPE;
    l_rank           vs_soft_inst.rank%TYPE;
    l_table_position epis_pn_det_task.table_position%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM alert.epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = epd.id_epis_pn
                  JOIN episode epi
                    ON epi.id_episode = epn.id_episode
                 WHERE epdt.table_position IS NULL
                   AND epd.id_pn_data_block = 143
                   AND epd.flg_status = 'A'
                   AND epdt.flg_status = 'A')
    LOOP
        BEGIN
            SELECT decode(rn_asc, 1, 1, decode(rn_desc, 2, 2, 3)) rank
              INTO l_table_position
              FROM (SELECT row_number() over(PARTITION BY epi.id_visit, v.id_vital_sign ORDER BY v.dt_vital_sign_read_tstz ASC) rn_asc,
                           row_number() over(PARTITION BY epi.id_visit, v.id_vital_sign ORDER BY v.dt_vital_sign_read_tstz DESC) rn_desc,
                           v.*
                      FROM vital_sign_read v
                      JOIN episode epi
                        ON epi.id_episode = v.id_episode
                     WHERE epi.id_visit = epi.id_visit
                       AND v.id_vital_sign_read = rec.id_task) t
             WHERE t.rn_asc = 1 --1st records
                OR t.rn_desc IN (1, 2); --last 2 records
        EXCEPTION
            WHEN OTHERS THEN
                l_table_position := NULL;
                dbms_output.put_line('No table poistion found');
        END;
    
        UPDATE epis_pn_det_task epdt
           SET epdt.table_position = l_table_position
         WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task;
    
    END LOOP;

    FOR rec IN (SELECT epdt.id_epis_pn_det_task,
                       epdt.id_group_table,
                       epi.id_institution,
                       epi.id_episode,
                       epi.id_epis_type
                  FROM epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                  JOIN epis_pn ep
                    ON ep.id_epis_pn = epd.id_epis_pn
                  JOIN episode epi
                    ON epi.id_episode = ep.id_episode
                 WHERE epd.id_pn_data_block = 143
                   AND epdt.id_group_table IS NOT NULL)
    LOOP
    
        --get episode SW
        BEGIN
            SELECT id_software
              INTO l_id_software
              FROM (SELECT etsi.id_software
                      FROM epis_type_soft_inst etsi
                     WHERE etsi.id_epis_type = rec.id_epis_type
                       AND etsi.id_institution IN (rec.id_institution, 0)
                     ORDER BY etsi.id_institution DESC, etsi.id_software DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_software := NULL;
                dbms_output.put_line('No software found. id_epis_type: ' || rec.id_epis_type || ' id_institution: ' ||
                                     rec.id_institution);
        END;
    
        IF (l_id_software IS NOT NULL)
        THEN
            BEGIN
                SELECT v.rank
                  INTO l_rank
                  FROM vs_soft_inst v
                 WHERE v.id_vital_sign = rec.id_group_table
                   AND v.id_software = l_id_software
                   AND v.id_institution = rec.id_institution
                   AND v.flg_view = 'V2';
            EXCEPTION
                WHEN OTHERS THEN
                    l_rank := NULL;
                    dbms_output.put_line('No rank found. id_vital_sign: ' || rec.id_group_table || ' id_software: ' ||
                                         l_id_software || ' id_institution: ' || rec.id_institution);
            END;
        
            UPDATE epis_pn_det_task epdt
               SET epdt.rank_task = l_rank
             WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task;
        
        END IF;
    END LOOP;

    COMMIT;

END;
/
-- CHANGED END: Sofia Mendes

