-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15-Jul-2011
-- CHANGE REASON: ALERT-82988 [Assessement tools]: Possibility to calculate partial scores
DECLARE
    l_id_docs              table_number;
    l_id_epis_scales_score epis_scales_score.id_epis_scales_score%TYPE;
    l_id_episode           episode.id_episode%TYPE;
    l_dt_creation_tstz     epis_documentation.dt_creation_tstz%TYPE;
    l_id_scales            scales.id_scales%TYPE;
    l_score_value          epis_scales_score.score_value%TYPE;
    l_id_visit             visit.id_visit%TYPE;
    l_id_patient           patient.id_patient%TYPE;
    l_id_prof_create       epis_documentation.id_professional%TYPE;
    l_dt_last_update_tstz  epis_documentation.dt_last_update_tstz%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation_parent IS NULL
                   AND ed.id_doc_area IN (SELECT d.id_doc_area
                                            FROM doc_area d
                                            JOIN summary_page_section sps
                                              ON sps.id_doc_area = d.id_doc_area
                                           WHERE sps.id_summary_page = 34))
    LOOP
        l_id_epis_scales_score := NULL;
    
        SELECT id_epis_documentation BULK COLLECT
          INTO l_id_docs
          FROM (SELECT ed.id_epis_documentation, ed.dt_last_update_tstz
                  FROM epis_documentation ed
                CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
                 START WITH ed.id_epis_documentation = rec.id_epis_documentation
                UNION ALL
                SELECT ed.id_epis_documentation, ed.dt_last_update_tstz
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation <> rec.id_epis_documentation
                CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
                 START WITH ed.id_epis_documentation = rec.id_epis_documentation)
         ORDER BY dt_last_update_tstz DESC;
    
        l_id_epis_scales_score := seq_epis_scales_score.nextval;
    
        FOR i IN 1 .. l_id_docs.count
        LOOP
            l_id_episode       := NULL;
            l_dt_creation_tstz := NULL;
            l_id_scales        := NULL;
            l_score_value      := NULL;
        
            BEGIN
                SELECT eb.id_episode,
                       eb.id_professional  id_prof_create,
                       eb.dt_creation_tstz dt_create,
                       sdv.id_scales,
                       SUM(sdv.value) soma,
                       eb.dt_last_update_tstz 
                  INTO l_id_episode,
                       l_id_prof_create,
                       l_dt_creation_tstz,
                       l_id_scales,
                       l_score_value,
                       l_dt_last_update_tstz
                  FROM epis_documentation     eb,
                       epis_documentation_det ebd,
                       documentation          d,
                       doc_element            de,
                       doc_component          dc,
                       doc_element_crit       decr,
                       doc_criteria           dcr,
                       scales_doc_value       sdv,
                       scales                 s,
                       episode                epi
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND eb.id_episode = epi.id_episode
                   AND d.id_documentation(+) = ebd.id_documentation
                   AND de.id_doc_element = ebd.id_doc_element
                   AND d.id_doc_component = dc.id_doc_component(+)
                   AND dc.flg_available(+) = 'Y'
                   AND d.flg_available(+) = 'Y'
                   AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                   AND decr.id_doc_criteria = dcr.id_doc_criteria
                   AND sdv.id_doc_element = de.id_doc_element
                   AND s.id_scales = sdv.id_scales
                   AND eb.id_epis_documentation = l_id_docs(i)
                 GROUP BY eb.id_episode,
                          eb.id_epis_documentation,
                          eb.dt_creation_tstz,
                          sdv.id_scales,
                          eb.id_professional,
                          eb.dt_last_update_tstz,
                          eb.flg_status;
            
                SELECT epi.id_visit, epi.id_patient
                  INTO l_id_visit, l_id_patient
                  FROM episode epi
                 WHERE epi.id_episode = l_id_episode;
            
                IF (i = 1)
                THEN
                    --actual value
                    BEGIN
                        INSERT INTO epis_scales_score
                            (id_epis_scales_score,
                             id_episode,
                             id_visit,
                             id_patient,
                             id_epis_documentation,
                             flg_status,
                             id_prof_create,
                             dt_create,
                             id_cancel_reason,
                             notes_cancel,
                             dt_cancel,
                             id_prof_cancel,
                             id_scales,
                             id_scales_group,
                             id_documentation,
                             score_value,
                             id_scales_formula)
                        VALUES
                            (l_id_epis_scales_score,
                             l_id_episode,
                             l_id_visit,
                             l_id_patient,
                             l_id_docs(i),
                             'A',
                             l_id_prof_create,
                             l_dt_creation_tstz,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             l_id_scales,
                             NULL,
                             NULL,
                             l_score_value,
                             NULL);
                    EXCEPTION
                        WHEN OTHERS THEN
                            dbms_output.put_line('OTHERS EPIS_SCALES_SCORE: ' || l_id_docs(i));
                    END;
                ELSE
                    --history value
                    BEGIN                    
                        INSERT INTO epis_scales_score_hist
                            (id_epis_scales_score,
                             dt_epis_scales_score,
                             id_episode,
                             id_visit,
                             id_patient,
                             id_epis_documentation,
                             flg_status,
                             id_prof_create,
                             dt_create,
                             id_cancel_reason,
                             notes_cancel,
                             dt_cancel,
                             id_prof_cancel,
                             id_scales,
                             id_scales_group,
                             id_documentation,
                             score_value,
                             id_scales_formula)
                        VALUES
                            (l_id_epis_scales_score,
                             l_dt_last_update_tstz,
                             l_id_episode,
                             l_id_visit,
                             l_id_patient,
                             l_id_docs(i),
                             'A',
                             l_id_prof_create,
                             l_dt_creation_tstz,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             l_id_scales,
                             NULL,
                             NULL,
                             l_score_value,
                             NULL);
                    EXCEPTION
                        WHEN OTHERS THEN
                            dbms_output.put_line('OTHERS HIST: ' || l_id_docs(i));
                    END;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    dbms_output.put_line('NO_DATA_FOUND SCORE CALCULATION: ' || l_id_docs(i));
                WHEN too_many_rows THEN
                    dbms_output.put_line('TOO_MANY_ROWS SCORE CALCULATION: ' || l_id_docs(i));
            END;
        
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15-Jul-2011
-- CHANGE REASON: ALERT-82988 [Assessement tools]: Possibility to calculate partial scores
DECLARE
    l_id_docs              table_number;
    l_id_epis_scales_score epis_scales_score.id_epis_scales_score%TYPE;
    l_id_episode           episode.id_episode%TYPE;
    l_dt_creation_tstz     epis_documentation.dt_creation_tstz%TYPE;
    l_id_scales            scales.id_scales%TYPE;
    l_score_value          epis_scales_score.score_value%TYPE;    
    l_id_patient           patient.id_patient%TYPE;
    l_id_prof_create       epis_documentation.id_professional%TYPE;
    l_dt_last_update_tstz  epis_documentation.dt_last_update_tstz%TYPE;
BEGIN
    FOR rec IN (SELECT *
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation_parent IS NULL
                   AND ed.id_doc_area IN (SELECT d.id_doc_area
                                            FROM doc_area d
                                            JOIN summary_page_section sps
                                              ON sps.id_doc_area = d.id_doc_area
                                           WHERE sps.id_summary_page = 34))
    LOOP
        l_id_epis_scales_score := NULL;
    
        SELECT id_epis_documentation BULK COLLECT
          INTO l_id_docs
          FROM (SELECT ed.id_epis_documentation, ed.dt_last_update_tstz
                  FROM epis_documentation ed
                CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
                 START WITH ed.id_epis_documentation = rec.id_epis_documentation
                UNION ALL
                SELECT ed.id_epis_documentation, ed.dt_last_update_tstz
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation <> rec.id_epis_documentation
                CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
                 START WITH ed.id_epis_documentation = rec.id_epis_documentation)
         ORDER BY dt_last_update_tstz DESC;
    
        l_id_epis_scales_score := seq_epis_scales_score.nextval;
    
        FOR i IN 1 .. l_id_docs.count
        LOOP
            l_id_episode       := NULL;
            l_dt_creation_tstz := NULL;
            l_id_scales        := NULL;
            l_score_value      := NULL;
        
            BEGIN
                SELECT eb.id_episode,
                       eb.id_professional  id_prof_create,
                       eb.dt_creation_tstz dt_create,
                       sdv.id_scales,
                       SUM(sdv.value) soma,
                       eb.dt_last_update_tstz 
                  INTO l_id_episode,
                       l_id_prof_create,
                       l_dt_creation_tstz,
                       l_id_scales,
                       l_score_value,
                       l_dt_last_update_tstz
                  FROM epis_documentation     eb,
                       epis_documentation_det ebd,
                       documentation          d,
                       doc_element            de,
                       doc_component          dc,
                       doc_element_crit       decr,
                       doc_criteria           dcr,
                       scales_doc_value       sdv,
                       scales                 s,
                       episode                epi
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND eb.id_episode = epi.id_episode
                   AND d.id_documentation(+) = ebd.id_documentation
                   AND de.id_doc_element = ebd.id_doc_element
                   AND d.id_doc_component = dc.id_doc_component(+)
                   AND dc.flg_available(+) = 'Y'
                   AND d.flg_available(+) = 'Y'
                   AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                   AND decr.id_doc_criteria = dcr.id_doc_criteria
                   AND sdv.id_doc_element = de.id_doc_element
                   AND s.id_scales = sdv.id_scales
                   AND eb.id_epis_documentation = l_id_docs(i)
                 GROUP BY eb.id_episode,
                          eb.id_epis_documentation,
                          eb.dt_creation_tstz,
                          sdv.id_scales,
                          eb.id_professional,
                          eb.dt_last_update_tstz,
                          eb.flg_status;
            
                SELECT epi.id_patient
                  INTO l_id_patient
                  FROM episode epi
                 WHERE epi.id_episode = l_id_episode;
            
                IF (i = 1)
                THEN
                    --actual value
                    BEGIN
                        INSERT INTO epis_scales_score
                            (id_epis_scales_score,
                             id_episode,                             
                             id_patient,
                             id_epis_documentation,
                             flg_status,
                             id_prof_create,
                             dt_create,
                             id_cancel_reason,
                             notes_cancel,
                             dt_cancel,
                             id_prof_cancel,
                             id_scales,
                             id_scales_group,
                             id_documentation,
                             score_value,
                             id_scales_formula)
                        VALUES
                            (l_id_epis_scales_score,
                             l_id_episode,                             
                             l_id_patient,
                             l_id_docs(i),
                             'A',
                             l_id_prof_create,
                             l_dt_creation_tstz,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             l_id_scales,
                             NULL,
                             NULL,
                             l_score_value,
                             NULL);
                    EXCEPTION
                        WHEN OTHERS THEN
                            dbms_output.put_line('OTHERS EPIS_SCALES_SCORE: ' || l_id_docs(i));
                    END;
                ELSE
                    --history value
                    BEGIN                    
                        INSERT INTO epis_scales_score_hist
                            (id_epis_scales_score,
                             dt_epis_scales_score,
                             id_episode,                             
                             id_patient,
                             id_epis_documentation,
                             flg_status,
                             id_prof_create,
                             dt_create,
                             id_cancel_reason,
                             notes_cancel,
                             dt_cancel,
                             id_prof_cancel,
                             id_scales,
                             id_scales_group,
                             id_documentation,
                             score_value,
                             id_scales_formula)
                        VALUES
                            (l_id_epis_scales_score,
                             l_dt_last_update_tstz,
                             l_id_episode,                             
                             l_id_patient,
                             l_id_docs(i),
                             'A',
                             l_id_prof_create,
                             l_dt_creation_tstz,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             l_id_scales,
                             NULL,
                             NULL,
                             l_score_value,
                             NULL);
                    EXCEPTION
                        WHEN OTHERS THEN
                            dbms_output.put_line('OTHERS HIST: ' || l_id_docs(i));
                    END;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    dbms_output.put_line('NO_DATA_FOUND SCORE CALCULATION: ' || l_id_docs(i));
                WHEN too_many_rows THEN
                    dbms_output.put_line('TOO_MANY_ROWS SCORE CALCULATION: ' || l_id_docs(i));
            END;
        
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Sofia Mendes

