DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */
        /* example: */
        e_has_findings EXCEPTION;
        l_count_dcs_ids             PLS_INTEGER;
        l_count_dcs_ids_hist        PLS_INTEGER;
        l_count_escape_dcs_ids      PLS_INTEGER;
        l_count_escape_dcs_ids_hist PLS_INTEGER;
    
        TYPE tab_adm_ind_hist IS TABLE OF adm_indication_hist%ROWTYPE;
    
        l_dt_group_import     epis_pn_det_task.dt_group_import%TYPE;
        l_id_group_import     epis_pn_det_task.id_group_import%TYPE;
        l_code_desc_group     epis_pn_det_task.code_desc_group%TYPE;
        l_id_sub_group_import epis_pn_det_task.id_sub_group_import%TYPE;
        l_code_desc_sub_group epis_pn_det_task.code_desc_sub_group%TYPE;
        l_id_task_type        epis_pn_det_task.id_task_type%TYPE;
        l_has_error           PLS_INTEGER := 0;
    BEGIN
        /* Initializations */
    
        /* Data validation */
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
                    SELECT t.dt_import,
                           t.id_group_import,
                           t.code_desc_group,
                           t.id_sub_group_import,
                           t.code_desc_sub_group
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
                            log_error('ERROR ON PROG notes aggregations: id_task: ' || rec.id_task ||
                                      '  id_task_type: ' || rec.id_task_type);
                            l_has_error := 1;
                        END IF;
                    
                END;
            
            EXCEPTION
                WHEN OTHERS THEN
                    null;
            END;
        END LOOP;
    
        IF (l_has_error = 1)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR on prog notes aggregations data migration');
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
