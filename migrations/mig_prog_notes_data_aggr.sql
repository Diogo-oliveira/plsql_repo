-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Aug/2011
-- CHANGE REASON: ALERT-229699 Vital signs presentation in table within the Current visit single page
DECLARE
    l_count               PLS_INTEGER := 0;
    l_dt_group_import     epis_pn_det_task.dt_group_import%TYPE;
    l_id_group_import     epis_pn_det_task.id_group_import%TYPE;
    l_code_desc_group     epis_pn_det_task.code_desc_group%TYPE;
    l_id_sub_group_import epis_pn_det_task.id_sub_group_import%TYPE;
    l_code_desc_sub_group epis_pn_det_task.code_desc_sub_group%TYPE;
    l_id_task_type        epis_pn_det_task.id_task_type%TYPE;
BEGIN
    FOR rec IN (SELECT epdt.id_task, epdt.id_task_type
                  FROM epis_pn_det_task epdt
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                  JOIN epis_pn ep
                    ON ep.id_epis_pn = epd.id_epis_pn
                 WHERE epdt.id_task_type IN (5, 17, 54, 4, 15, 55)
                   AND ep.flg_status = 'D')
    LOOP
        l_id_task_type := CASE rec.id_task_type
                              WHEN pk_alert_constant.g_id_tl_task_analysis_recur THEN
                               pk_alert_constant.g_id_tl_task_analysis
                              WHEN pk_alert_constant.g_id_tl_task_exams_recur THEN
                               pk_alert_constant.g_id_tl_task_exams
                              ELSE
                               rec.id_task_type
                          END;
    
        BEGIN
            BEGIN
                SELECT t.dt_import, t.id_group_import, t.code_desc_group, t.id_sub_group_import, t.code_desc_sub_group
                  INTO l_dt_group_import,
                       l_id_group_import,
                       l_code_desc_group,
                       l_id_sub_group_import,
                       l_code_desc_sub_group
                  FROM v_pn_tasks t
                 WHERE t.id_task_refid = rec.id_task
                   AND t.id_tl_task = l_id_task_type
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    IF (l_id_task_type = 4) --exams
                    THEN
                        SELECT er.dt_req_tstz dt_req,
                               e.id_exam_cat,
                               'EXAM_CAT.CODE_EXAM_CAT.' || e.id_exam_cat code_group,
                               NULL,
                               NULL
                          INTO l_dt_group_import,
                               l_id_group_import,
                               l_code_desc_group,
                               l_id_sub_group_import,
                               l_code_desc_sub_group
                          FROM exam_req_det erd
                         INNER JOIN exam e
                            ON (erd.id_exam = e.id_exam)
                         INNER JOIN exam_req er
                            ON (erd.id_exam_req = er.id_exam_req)
                         WHERE erd.id_exam_req_det = rec.id_task;
                    ELSIF (l_id_task_type = 15) --exam results
                    THEN
                        SELECT erd.start_time,
                               e.id_exam_cat,
                               'EXAM_CAT.CODE_EXAM_CAT.' || e.id_exam_cat code_group,
                               NULL,
                               NULL
                          INTO l_dt_group_import,
                               l_id_group_import,
                               l_code_desc_group,
                               l_id_sub_group_import,
                               l_code_desc_sub_group
                          FROM exam_result er
                         INNER JOIN exam e
                            ON (er.id_exam = e.id_exam)
                         INNER JOIN exam_req_det erd
                            ON erd.id_exam_req_det = er.id_exam_req_det
                         WHERE er.id_exam_result = rec.id_task;
                    ELSIF (l_id_task_type = 5) --lab requests
                    THEN
                        SELECT ar.dt_req_tstz dt_req,
                               ard.id_exam_cat,
                               'EXAM_CAT.CODE_EXAM_CAT.' || ard.id_exam_cat code_group,
                               NULL,
                               NULL
                          INTO l_dt_group_import,
                               l_id_group_import,
                               l_code_desc_group,
                               l_id_sub_group_import,
                               l_code_desc_sub_group
                          FROM analysis_req_det ard
                         INNER JOIN analysis_req ar
                            ON (ard.id_analysis_req = ar.id_analysis_req)
                         INNER JOIN analysis a
                            ON (ard.id_analysis = a.id_analysis)
                          LEFT OUTER JOIN analysis_harvest ah
                            ON ah.id_analysis_req_det = ard.id_analysis_req_det
                          LEFT OUTER JOIN harvest h
                            ON h.id_harvest = ah.id_harvest
                           AND h.flg_status IN ('H', 'F', 'R', 'T')
                         WHERE ard.id_analysis_req_det = rec.id_task;
                    ELSIF (l_id_task_type = 17)
                    THEN
                        --lab results
                        SELECT h.dt_harvest_tstz dt_execution,
                               ares.id_exam_cat id_group_import,
                               'EXAM_CAT.CODE_EXAM_CAT.' || ares.id_exam_cat code_desc_group,
                               ares.id_analysis id_sub_group,
                               'ANALYSIS.CODE_ANALYSIS.' || ares.id_analysis code_desc_sub_group
                          INTO l_dt_group_import,
                               l_id_group_import,
                               l_code_desc_group,
                               l_id_sub_group_import,
                               l_code_desc_sub_group
                          FROM analysis_result_par arp
                         INNER JOIN analysis_result ares
                            ON ares.id_analysis_result = arp.id_analysis_result
                         INNER JOIN result_status rs
                            ON arp.id_result_status = rs.id_result_status
                          LEFT OUTER JOIN harvest h
                            ON ares.id_harvest = h.id_harvest
                         WHERE arp.id_analysis_result_par = rec.id_task;
                    
                    ELSE
                        dbms_output.put_line('record not found: id_task: ' || rec.id_task || ' id_task_type: ' ||
                                             rec.id_task_type || ' l_id_task_type: ' || l_id_task_type);
                    END IF;
                
            END;
        
            UPDATE epis_pn_det_task e
               SET e.dt_group_import     = l_dt_group_import,
                   e.id_group_import     = l_id_group_import,
                   e.code_desc_group     = l_code_desc_group,
                   e.id_sub_group_import = l_id_sub_group_import,
                   e.code_desc_sub_group = l_code_desc_sub_group
             WHERE e.id_task = rec.id_task
               AND e.id_task_type = rec.id_task_type;
        
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('record not found2: id_task: ' || rec.id_task || ' id_task_type: ' ||
                                     rec.id_task_type);
        END;
    END LOOP;
END;
/
