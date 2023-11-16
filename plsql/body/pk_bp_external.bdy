CREATE OR REPLACE PACKAGE BODY pk_bp_external IS

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_blood_products_core.get_bp_detail(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_episode               => i_episode,
                                                    i_blood_product_det     => i_blood_product_det,
                                                    i_flg_report            => pk_blood_products_constant.g_yes,
                                                    o_bp_detail             => o_bp_detail,
                                                    o_bp_clinical_questions => o_bp_clinical_questions,
                                                    o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL',
                                              o_error);
            RETURN FALSE;
        
    END get_bp_detail;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_blood_products_core.get_bp_detail_history(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_episode               => i_episode,
                                                            i_blood_product_det     => i_blood_product_det,
                                                            i_flg_report            => pk_blood_products_constant.g_yes,
                                                            o_bp_detail             => o_bp_detail,
                                                            o_bp_clinical_questions => o_bp_clinical_questions,
                                                            o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL_HISTORY',
                                              o_error);
            RETURN FALSE;
        
    END get_bp_detail_history;

    FUNCTION get_bp_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        o_bp_list   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_id_blood_product_det table_number := table_number();
    
    BEGIN
    
        IF i_flg_scope = pk_alert_constant.g_scope_type_episode
        THEN
            --l_tbl_id_blood_product_det.extend();
            --l_tbl_id_blood_product_det(1) := i_scope;
        
            SELECT e.id_episode
              BULK COLLECT
              INTO l_tbl_id_blood_product_det
              FROM episode e
             WHERE e.id_visit IN (SELECT id_visit
                                    FROM episode
                                   WHERE id_episode = i_scope);
        
        ELSIF i_flg_scope = pk_alert_constant.g_scope_type_visit
        THEN
            SELECT e.id_episode
              BULK COLLECT
              INTO l_tbl_id_blood_product_det
              FROM episode e
             WHERE e.id_visit = i_scope;
        ELSIF i_flg_scope = pk_alert_constant.g_scope_type_patient
        THEN
            SELECT e.id_episode
              BULK COLLECT
              INTO l_tbl_id_blood_product_det
              FROM episode e
             WHERE e.id_patient = i_scope;
        END IF;
    
        OPEN o_bp_list FOR
            SELECT bpd.id_blood_product_req,
                   bpd.id_blood_product_det,
                   pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T14') desc_transfusion,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_prof => i_prof, i_date => bpr.dt_begin_tstz) dt_begin_req,
                   pk_translation.get_translation(i_lang, ht.code_hemo_type) desc_hemo_type
              FROM blood_product_det bpd
              JOIN blood_product_req bpr
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
              JOIN hemo_type ht
                ON ht.id_hemo_type = bpd.id_hemo_type
             WHERE bpr.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                       t.column_value
                                        FROM TABLE(l_tbl_id_blood_product_det) t)
             ORDER BY bpd.id_blood_product_req ASC, bpd.id_blood_product_det ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TASK_LIST',
                                              o_error);
            RETURN FALSE;
        
    END get_bp_task_list;

    FUNCTION get_bp_adverse_reaction
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_data_transfusion    OUT pk_types.cursor_type,
        o_data_vital_signs    OUT pk_types.cursor_type,
        o_data_clinical_sympt OUT VARCHAR2,
        o_data_medicine       OUT VARCHAR2,
        o_data_lab_tests_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
        l_analysis_req_det table_number;
    
        l_data_lab_tests_list t_tbl_lab_tests_results;
    
    BEGIN
    
        OPEN o_data_transfusion FOR
            SELECT DISTINCT pk_date_utils.date_char_tsz(i_lang, bpr.dt_req_tstz, i_prof.institution, i_prof.software) requisition_date,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, bpr.id_professional) ordering_physician,
                            (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                  i_prof,
                                                                                  bpd.id_blood_product_det,
                                                                                  pk_blood_products_constant.g_no)
                               FROM dual) desc_hemo_type,
                            bpd.barcode_lab barcode_number,
                            (bpd.blood_group || ' ' || pk_sysdomain.get_domain(i_lang,
                                                                               i_prof,
                                                                               'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS',
                                                                               bpd.blood_group_rh,
                                                                               NULL)) type_of_blood,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, bpe_admin.id_prof_performed) check_professional,
                            pk_prof_utils.get_prof_num_order(i_lang,
                                                             profissional(bpe_admin.id_prof_performed,
                                                                          i_prof.institution,
                                                                          i_prof.software)) check_professional_num,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, bpe_admin.id_prof_match) revised_professional,
                            pk_prof_utils.get_prof_num_order(i_lang,
                                                             profissional(bpe_admin.id_prof_match,
                                                                          i_prof.institution,
                                                                          i_prof.software)) revised_professional_num,
                            pk_date_utils.date_char_tsz(i_lang, bpe_admin.dt_begin, i_prof.institution, i_prof.software) transfusion_begin,
                            pk_date_utils.date_char_tsz(i_lang, bpe_con.dt_end, i_prof.institution, i_prof.software) tranfusion_end,
                            (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                 i_prof,
                                                                                 bpd.qty_given,
                                                                                 bpd.id_unit_mea_qty_given)
                               FROM dual) qty_given,
                            (SELECT (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                        pk_touch_option.get_value_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       a.id_doc_element_crit,
                                                                                                       a.id_epis_documentation),
                                                                        i_prof.institution,
                                                                        i_prof.software)
                                       FROM dual)
                               FROM epis_documentation_det a
                              INNER JOIN doc_element_crit b
                                 ON a.id_doc_element_crit = b.id_doc_element_crit
                              WHERE b.id_content = 'TPT.EC.5194774'
                                AND a.id_epis_documentation = edd.id_epis_documentation) react_begin,
                            (SELECT (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                        pk_touch_option.get_value_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       a.id_doc_element_crit,
                                                                                                       a.id_epis_documentation),
                                                                        i_prof.institution,
                                                                        i_prof.software)
                                       FROM dual)
                               FROM epis_documentation_det a
                              INNER JOIN doc_element_crit b
                                 ON a.id_doc_element_crit = b.id_doc_element_crit
                              WHERE b.id_content = 'TPT.EC.5194776'
                                AND a.id_epis_documentation = edd_1.id_epis_documentation) react_send
              FROM blood_product_det bpd
             INNER JOIN blood_product_req bpr
                ON bpd.id_blood_product_req = bpr.id_blood_product_req
             INNER JOIN blood_product_execution bpe_admin
                ON bpe_admin.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_admin.action = pk_blood_products_constant.g_bp_action_administer
              LEFT JOIN blood_product_execution bpe_con
                ON bpe_con.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_con.action = pk_blood_products_constant.g_bp_action_conclude
              LEFT JOIN blood_product_execution bpe_rep
                ON bpe_rep.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_rep.action = pk_blood_products_constant.g_bp_action_report
              LEFT JOIN epis_documentation_det edd
                ON edd.id_epis_documentation = bpe_rep.id_epis_documentation
              LEFT JOIN epis_documentation_det edd_1
                ON edd_1.id_epis_documentation = bpe_rep.id_epis_documentation
             WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        OPEN o_data_vital_signs FOR
            SELECT t.vs_type,
                   t.intern_name,
                   listagg(t.pre_transfusion, ',') within GROUP(ORDER BY t.pre_transfusion) pre_transfusion,
                   listagg(t.end_transfusion, ',') within GROUP(ORDER BY t.end_transfusion) end_transfusion
              FROM (SELECT pk_translation.get_translation(i_lang, dec.code_element_open) vs_type,
                           (SELECT column_value
                              FROM TABLE(pk_string_utils.str_split(de.internal_name, '_'))
                             WHERE rownum = 1) intern_name,
                           pk_vital_sign_core.get_vital_sign_desc(i_lang, edd.value_properties) pre_transfusion,
                           NULL end_transfusion
                      FROM blood_product_det bpd
                     INNER JOIN blood_product_execution bpe
                        ON bpd.id_blood_product_det = bpe.id_blood_product_det
                       AND bpe.action = pk_blood_products_constant.g_bp_action_administer
                     INNER JOIN epis_documentation_det edd
                        ON edd.id_epis_documentation = bpe.id_epis_documentation
                     INNER JOIN doc_element de
                        ON de.id_doc_element = edd.id_doc_element
                       AND de.flg_type = pk_touch_option.g_elem_flg_type_vital_sign
                     INNER JOIN doc_element_crit DEC
                        ON dec.id_doc_element_crit = edd.id_doc_element_crit
                     WHERE bpd.id_blood_product_det = i_blood_product_det
                    UNION ALL
                    SELECT pk_translation.get_translation(i_lang, dec1.code_element_open) vs_type,
                           (SELECT column_value
                              FROM TABLE(pk_string_utils.str_split(de1.internal_name, '_'))
                             WHERE rownum = 1) intern_name,
                           NULL pre_transfusion,
                           pk_vital_sign_core.get_vital_sign_desc(i_lang, edd1.value_properties) end_transfusion
                      FROM blood_product_det bpd
                      LEFT JOIN blood_product_execution bpe1
                        ON bpd.id_blood_product_det = bpe1.id_blood_product_det
                       AND bpe1.action = pk_blood_products_constant.g_bp_action_conclude
                      LEFT JOIN epis_documentation_det edd1
                        ON edd1.id_epis_documentation = bpe1.id_epis_documentation
                      LEFT JOIN doc_element de1
                        ON de1.id_doc_element = edd1.id_doc_element
                       AND de1.flg_type = pk_touch_option.g_elem_flg_type_vital_sign
                      LEFT JOIN doc_element_crit dec1
                        ON dec1.id_doc_element_crit = edd1.id_doc_element_crit
                     WHERE bpd.id_blood_product_det = i_blood_product_det) t
             GROUP BY t.vs_type, t.intern_name;
    
        SELECT listagg(clinical_symptoms, ',') within GROUP(ORDER BY rank),
               listagg(medical) within GROUP(ORDER BY rank)
          INTO o_data_clinical_sympt, o_data_medicine
          FROM (SELECT de.rank,
                       CASE
                            WHEN d.id_content = 'TPT.D.430317' THEN
                             pk_translation.get_translation(i_lang, dec.code_element_open) ||
                             decode(edd.value, NULL, NULL, ': ' || edd.value)
                            ELSE
                             NULL
                        END clinical_symptoms,
                       CASE
                            WHEN d.id_content = 'TPT.D.430318' THEN
                             pk_translation.get_translation(i_lang, dec.code_element_open) ||
                             decode(edd.value, NULL, NULL, ': ' || edd.value || ' <br/>')
                            ELSE
                             NULL
                        END medical
                  FROM blood_product_det bpd
                 INNER JOIN blood_product_execution bpe
                    ON bpd.id_blood_product_det = bpe.id_blood_product_det
                   AND bpe.action = pk_blood_products_constant.g_bp_action_report
                 INNER JOIN epis_documentation_det edd
                    ON bpe.id_epis_documentation = edd.id_epis_documentation
                 INNER JOIN doc_element de
                    ON edd.id_doc_element = de.id_doc_element
                 INNER JOIN doc_element_crit DEC
                    ON edd.id_doc_element_crit = dec.id_doc_element_crit
                 INNER JOIN documentation d
                    ON d.id_documentation = edd.id_documentation
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                 ORDER BY dec.id_doc_element_crit);
    
        SELECT bpa.id_analysis_req_det
          BULK COLLECT
          INTO l_analysis_req_det
          FROM blood_product_analysis bpa
         WHERE bpa.id_blood_product_det = i_blood_product_det;
    
        SELECT bpr.id_episode
          INTO l_id_episode
          FROM blood_product_det bpd
         INNER JOIN blood_product_req bpr
            ON bpd.id_blood_product_req = bpr.id_blood_product_req
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => pk_episode.get_id_patient(l_id_episode),
                                                          i_analysis_req_det => l_analysis_req_det,
                                                          i_flg_type         => 'H',
                                                          i_dt_min           => NULL,
                                                          i_dt_max           => NULL,
                                                          i_flg_report       => pk_alert_constant.g_yes,
                                                          o_list             => l_data_lab_tests_list,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        OPEN o_data_lab_tests_list FOR
            SELECT ar.id_analysis_req_det id_analysis_req_det,
                   ar.id_analysis_req_par id_analysis_req_par,
                   ar.id_analysis_result id_analysis_result,
                   ar.id_analysis_result_par id_analysis_result_par,
                   pk_lab_tests_utils.get_lab_test_id_content(i_lang, i_prof, ar.id_analysis, ar.id_sample_type) id_content,
                   ar.id_analysis id_analysis,
                   ar.id_analysis_parameter id_analysis_parameter,
                   ar.id_sample_type id_sample_type,
                   ar.id_harvest id_harvest,
                   ar.desc_analysis desc_analysis,
                   ar.desc_parameter desc_parameter,
                   ar.desc_sample desc_sample,
                   ar.dt_harvest dt_harvest,
                   ar.dt_result dt_result,
                   ar.result || ' ' || desc_unit_measure RESULT,
                   decode(bpe.id_blood_product_execution, NULL, 'REQ', bpe.action) bp_action
              FROM TABLE(l_data_lab_tests_list) ar
             INNER JOIN analysis_result ares
                ON ares.id_analysis_result = ar.id_analysis_result
              LEFT JOIN blood_product_analysis bpa
                ON ares.id_analysis_req_det = bpa.id_analysis_req_det
              LEFT JOIN blood_product_execution bpe
                ON bpa.id_blood_product_execution = bpe.id_blood_product_execution
             WHERE ar.flg_type = 'P'
               AND ar.result IS NOT NULL
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      ar.dt_harvest_ord,
                      ar.id_harvest,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_ADVERSE_REACTIONP',
                                              o_error);
            RETURN FALSE;
    END get_bp_adverse_reaction;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_desc CLOB;
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => ht.code_hemo_type) || '(' ||
               pk_date_utils.dt_chr_date_hour_tsz(i_lang, bpd.dt_begin_tstz, i_prof) || ')'
          INTO l_desc
          FROM blood_product_det bpd
          JOIN hemo_type ht
            ON bpd.id_hemo_type = ht.id_hemo_type
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_bp_description;

    FUNCTION get_bp_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
        l_task_instructions VARCHAR2(1000 CHAR);
    
        l_instructions CLOB;
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_blood_product_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_TASK_INSTRUCTIONS';
        IF NOT pk_bp_external.get_bp_task_instructions(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_task_request      => NULL,
                                                       i_task_request_det  => i_blood_product_det,
                                                       o_task_instructions => l_task_instructions,
                                                       o_error             => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_instructions := CASE
                              WHEN l_task_instructions IS NOT NULL THEN
                               l_task_instructions
                              ELSE
                               NULL
                          END;
    
        RETURN l_instructions;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_bp_instructions;

    FUNCTION get_bp_action_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_action            IN co_sign.id_action%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_cosign_action_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M146');
        l_msg_cosign_action_cancel sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M147');
        l_msg_action               sys_message.desc_message%TYPE;
    
    BEGIN
    
        SELECT CASE
                   WHEN bpd.id_co_sign_cancel = i_co_sign_hist THEN
                    l_msg_cosign_action_cancel
                   ELSE
                    l_msg_cosign_action_order
               END
          INTO l_msg_action
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        RETURN l_msg_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_bp_action_desc;

    FUNCTION get_bp_date_to_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_blood_product_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT coalesce(bpe.dt_begin_det, bpe.dt_begin_req)
          INTO l_date
          FROM blood_products_ea bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det;
    
        l_date := current_timestamp;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_bp_date_to_order;

    PROCEDURE cpoe_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diagnosis_list(l_bp_det blood_product_det.id_blood_product_det%TYPE) IS
            SELECT mrd.id_diagnosis, ed.desc_epis_diagnosis desc_diagnosis
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed
             WHERE mrd.id_blood_product_det = l_bp_det
               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        l_bp_req blood_product_req%ROWTYPE;
        l_bp_det blood_product_det%ROWTYPE;
    
        l_id_req blood_product_req.id_blood_product_req%TYPE;
    
        l_dt_begin_tstz blood_product_det.dt_begin_tstz%TYPE;
    
        l_diagnosis      table_number := table_number();
        l_diagnosis_desc table_varchar := table_varchar();
    
        l_clinical_question       table_number;
        l_response                table_varchar;
        l_clinical_question_notes table_varchar;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        SELECT bpd.*
          INTO l_bp_det
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_det = i_task_request;
    
        SELECT bpr.*
          INTO l_bp_req
          FROM blood_product_req bpr
         WHERE bpr.id_blood_product_req = l_bp_det.id_blood_product_req;
    
        SELECT bqr.id_questionnaire, bqr.id_response, bqr.notes
          BULK COLLECT
          INTO l_clinical_question, l_response, l_clinical_question_notes
          FROM bp_question_response bqr
         WHERE bqr.id_blood_product_det = i_task_request;
    
        IF l_diagnosis IS NULL
           OR l_diagnosis.count = 0
        THEN
            FOR l_diagnosis_list IN c_diagnosis_list(i_task_request)
            LOOP
                l_diagnosis.extend;
                l_diagnosis(l_diagnosis.count) := l_diagnosis_list.id_diagnosis;
            
                l_diagnosis_desc.extend;
                l_diagnosis_desc(l_diagnosis.count) := l_diagnosis_list.desc_diagnosis;
            END LOOP;
        END IF;
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_begin_tstz := i_task_start_timestamp;
        ELSE
            IF pk_date_utils.trunc_insttimezone(i_prof, l_bp_det.dt_end_tstz) >
               pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
            THEN
                l_dt_begin_tstz := g_sysdate_tstz;
            END IF;
        
        END IF;
    
        l_id_req := seq_blood_product_req.nextval;
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.CREATE_BP_REQUEST';
        IF NOT pk_blood_products_core.create_bp_request(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_patient                 => l_bp_req.id_patient,
                                                        i_episode                 => i_episode,
                                                        i_blood_product_req       => l_id_req,
                                                        i_hemo_type               => l_bp_det.id_hemo_type,
                                                        i_flg_time                => l_bp_req.flg_time,
                                                        i_dt_begin                => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                 l_dt_begin_tstz,
                                                                                                                 i_prof),
                                                        i_episode_destination     => l_bp_req.id_episode_destination,
                                                        i_order_recurrence        => NULL,
                                                        i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                                                                               i_prof      => i_prof,
                                                                                                               i_patient   => l_bp_req.id_patient,
                                                                                                               i_episode   => i_episode,
                                                                                                               i_diagnosis => l_diagnosis,
                                                                                                               i_desc_diag => l_diagnosis_desc),
                                                        i_clinical_purpose        => l_bp_det.id_clinical_purpose,
                                                        i_clinical_purpose_notes  => l_bp_det.clinical_purpose_notes,
                                                        i_priority                => l_bp_det.flg_priority,
                                                        i_special_type            => l_bp_det.id_special_type,
                                                        i_screening               => l_bp_det.flg_with_screening,
                                                        i_without_nat             => l_bp_det.flg_without_nat_test,
                                                        i_not_send_unit           => l_bp_det.flg_prepare_not_send,
                                                        i_transf_type             => l_bp_det.transfusion_type,
                                                        i_qty_exec                => l_bp_det.qty_exec,
                                                        i_unit_qty_exec           => l_bp_det.id_unit_mea_qty_exec,
                                                        i_exec_institution        => l_bp_det.id_exec_institution,
                                                        i_not_order_reason        => l_bp_det.id_not_order_reason,
                                                        i_special_instr           => l_bp_det.special_instr,
                                                        i_notes                   => l_bp_det.notes_tech,
                                                        i_prof_order              => NULL,
                                                        i_dt_order                => NULL,
                                                        i_order_type              => NULL,
                                                        i_health_plan             => l_bp_det.id_pat_health_plan,
                                                        i_exemption               => l_bp_det.id_pat_exemption,
                                                        i_clinical_question       => l_clinical_question,
                                                        i_response                => l_response,
                                                        i_clinical_question_notes => l_clinical_question_notes,
                                                        i_clinical_decision_rule  => NULL,
                                                        i_flg_origin_req          => pk_alert_constant.g_task_origin_cpoe,
                                                        o_blood_prod_det          => l_bp_det.id_blood_product_det,
                                                        o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := l_bp_req.id_patient;
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode, o_error);
            l_sys_alert_event.dt_record       := g_sysdate_tstz;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_to_draft;

    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_conflict table_varchar := table_varchar();
        l_msg_title    table_varchar := table_varchar();
        l_msg_body     table_varchar := table_varchar();
        l_msg_template table_varchar := table_varchar();
    
    BEGIN
    
        o_flg_conflict := l_flg_conflict;
        o_msg_title    := l_msg_title;
        o_msg_body     := l_msg_body;
        o_msg_template := l_msg_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DRAFT_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END check_draft_conflicts;

    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_bp_draft IS
            SELECT a.id_blood_product_req,
                   a.id_blood_product_det,
                   b.id_episode,
                   decode(pk_date_utils.compare_dates_tsz(i_prof, a.dt_begin_tstz, g_sysdate_tstz),
                          pk_alert_constant.g_date_lower,
                          g_sysdate_tstz,
                          a.dt_begin_tstz) dt_begin,
                   b.flg_time,
                   a.id_exec_institution,
                   a.id_co_sign_order,
                   a.id_hemo_type,
                   a.flg_priority,
                   b.id_patient
              FROM blood_product_det a
              JOIN blood_product_req b
                ON a.id_blood_product_req = b.id_blood_product_req
              JOIN hemo_type c
                ON c.id_hemo_type = a.id_hemo_type
             WHERE a.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                               *
                                                FROM TABLE(i_draft) t);
    
        CURSOR c_hemo_analysis
        (
            i_hemo_type   blood_product_det.id_hemo_type%TYPE,
            dt_begin_hemo TIMESTAMP WITH LOCAL TIME ZONE
        ) IS
            SELECT t.id_analysis_req_det, t.id_analysis, t.id_sample_type, t.flg_analysis, t.flg_collected
              FROM (SELECT id_analysis_req_det,
                           id_analysis,
                           id_sample_type,
                           dt_req_tstz,
                           flg_analysis,
                           flg_collected,
                           row_number() over(PARTITION BY id_analysis, id_sample_type ORDER BY flg_analysis DESC, flg_collected DESC) rn
                      FROM (SELECT a.id_analysis_req_det,
                                   hta.id_analysis,
                                   hta.id_sample_type,
                                   a.dt_req_tstz,
                                   CASE
                                        WHEN pk_date_utils.add_to_ltstz(a.dt_req_tstz, hta.time_req, hta.unit_time_req) <=
                                             dt_begin_hemo THEN
                                         pk_alert_constant.g_no
                                        WHEN a.id_analysis IS NULL THEN
                                         pk_alert_constant.g_no
                                        ELSE
                                         pk_alert_constant.g_yes
                                    END flg_analysis,
                                   CASE
                                        WHEN a.flg_status IN (pk_lab_tests_constant.g_harvest_pending,
                                                              pk_lab_tests_constant.g_harvest_waiting,
                                                              pk_lab_tests_constant.g_harvest_rejected,
                                                              pk_lab_tests_constant.g_harvest_cancel)
                                             OR a.flg_status IS NULL THEN
                                         pk_alert_constant.g_no
                                        ELSE
                                         pk_alert_constant.g_yes
                                    END flg_collected
                              FROM hemo_type_analysis hta
                              LEFT JOIN (SELECT ar.dt_req_tstz,
                                               ard.id_analysis,
                                               ard.id_sample_type,
                                               h.flg_status,
                                               ard.id_analysis_req_det
                                          FROM analysis_req ar
                                          JOIN analysis_req_det ard
                                            ON ard.id_analysis_req = ar.id_analysis_req
                                          LEFT JOIN analysis_harvest ah
                                            ON ah.id_analysis_req_det = ard.id_analysis_req_det
                                          JOIN harvest h
                                            ON h.id_harvest = ah.id_harvest
                                         WHERE ar.id_episode = i_episode
                                           AND ard.flg_status NOT IN
                                               (pk_lab_tests_constant.g_analysis_cancel,
                                                pk_lab_tests_constant.g_analysis_predefined,
                                                pk_lab_tests_constant.g_analysis_draft)) a
                                ON a.id_analysis = hta.id_analysis
                               AND a.id_sample_type = hta.id_sample_type
                             WHERE hta.id_hemo_type = i_hemo_type
                               AND hta.id_institution = i_prof.institution
                               AND hta.flg_available = pk_alert_constant.g_yes
                               AND hta.flg_reaction_form = pk_alert_constant.g_no
                               AND (hta.flg_newborn IS NULL OR hta.flg_newborn = pk_alert_constant.g_no))) t
             WHERE t.rn = 1;
    
        l_next_req        blood_product_req.id_blood_product_req%TYPE;
        l_next_det        blood_product_det.id_blood_product_det%TYPE;
        l_dt_req          blood_product_req.dt_req_tstz%TYPE;
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_id_patient_mother patient.id_patient%TYPE;
        l_visit_mother      visit.id_visit%TYPE;
        l_epis_mother       episode.id_episode%TYPE;
    
        l_aux               table_varchar2;
        l_flg_show_analysis VARCHAR2(1000 CHAR);
    
        l_qty_exec NUMBER(24);
    
        l_not_order_reason not_order_reason.id_not_order_reason%TYPE;
    
        l_analysis_req     table_number;
        l_analysis_req_det table_number;
        l_analysis_req_par table_number;
    
        l_harvest_state VARCHAR2(1 CHAR);
    
        l_hemo_analysis_req_det table_number;
        l_hemo_id_analysis      table_number;
        l_hemo_id_sample_type   table_number;
        l_hemo_flg_analysis     table_varchar;
        l_hemo_flg_collected    table_varchar;
        l_analysis_ins          analysis_req_det.id_analysis_req_det%TYPE;
        l_flg_status_det        analysis_req_det.flg_status%TYPE;
    
        l_volume_default sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_PRODUCT_UNIT_VOL', i_prof);
    
        l_rapid_crossmatching     sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_PRODUCTS_RAPID_CROSSMATCHING',
                                                                                   i_prof);
        l_rapid_crossmatching_tbl table_varchar;
        l_split_crossmatching     table_varchar;
    
        l_status     blood_product_req.flg_status%TYPE;
        l_status_det blood_product_det.flg_status%TYPE;
        l_dt_begin   blood_product_det.dt_begin_tstz%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_created_tasks := i_draft;
    
        FOR rec IN c_bp_draft
        LOOP
            g_error := 'GET STATUS';
        
            -- realização neste epis.
            IF rec.id_episode IS NOT NULL
            THEN
                IF pk_sysconfig.get_config('REQ_NEXT_DAY', i_prof) = pk_alert_constant.g_no
                THEN
                    IF pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_begin, g_sysdate_tstz), 'DD') !=
                       pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
                    THEN
                    
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            l_dt_begin := rec.dt_begin;
        
            l_status     := pk_blood_products_constant.g_status_req_r;
            l_status_det := pk_blood_products_constant.g_status_det_r_sc;
        
            IF nvl(l_dt_begin, g_sysdate_tstz) <= g_sysdate_tstz
            THEN
                l_dt_begin := g_sysdate_tstz;
            END IF;
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_blood_product_req_in => rec.id_blood_product_req,
                                     flg_status_in           => l_status,
                                     dt_begin_tstz_in        => l_dt_begin,
                                     id_prof_last_update_in  => i_prof.id,
                                     dt_last_update_tstz_in  => g_sysdate_tstz,
                                     rows_out                => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE BLOOD_PRODUCT_DET';
            ts_blood_product_det.upd(id_blood_product_det_in => rec.id_blood_product_det,
                                     flg_status_in           => l_status_det,
                                     dt_begin_tstz_in        => l_dt_begin,
                                     id_prof_last_update_in  => i_prof.id,
                                     dt_last_update_tstz_in  => g_sysdate_tstz,
                                     rows_out                => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            OPEN c_hemo_analysis(rec.id_hemo_type, l_dt_begin);
            FETCH c_hemo_analysis BULK COLLECT
                INTO l_hemo_analysis_req_det,
                     l_hemo_id_analysis,
                     l_hemo_id_sample_type,
                     l_hemo_flg_analysis,
                     l_hemo_flg_collected;
            CLOSE c_hemo_analysis;
        
            IF l_status_det NOT IN
               (pk_blood_products_constant.g_status_req_df, pk_blood_products_constant.g_status_req_pd)
            THEN
            
                l_rapid_crossmatching_tbl := pk_string_utils.str_split(i_list => l_rapid_crossmatching, i_delim => '|');
            
                IF l_rapid_crossmatching_tbl IS NOT NULL
                   AND l_rapid_crossmatching_tbl.count > 0
                   AND rec.flg_priority = pk_blood_products_constant.g_flg_priority_urgent
                THEN
                    IF l_hemo_id_analysis IS NULL
                    THEN
                        l_hemo_analysis_req_det := table_number();
                        l_hemo_id_analysis      := table_number();
                        l_hemo_id_sample_type   := table_number();
                        l_hemo_flg_analysis     := table_varchar();
                        l_hemo_flg_collected    := table_varchar();
                    END IF;
                
                    FOR i IN 1 .. l_rapid_crossmatching_tbl.count
                    LOOP
                        l_split_crossmatching := pk_string_utils.str_split(i_list  => l_rapid_crossmatching_tbl(i),
                                                                           i_delim => ',');
                    
                        IF l_split_crossmatching(1) != -1
                        THEN
                            l_hemo_id_analysis.extend;
                            l_hemo_id_analysis(l_hemo_id_analysis.count) := l_split_crossmatching(1);
                            l_hemo_id_sample_type.extend;
                            l_hemo_id_sample_type(l_hemo_id_sample_type.count) := l_split_crossmatching(2);
                            l_hemo_flg_analysis.extend;
                            l_hemo_flg_analysis(l_hemo_flg_analysis.count) := pk_alert_constant.g_no;
                            l_hemo_flg_collected.extend;
                            l_hemo_flg_collected(l_hemo_flg_collected.count) := pk_alert_constant.g_no;
                        END IF;
                    END LOOP;
                
                END IF;
            
                IF l_hemo_id_analysis IS NOT NULL
                   AND l_hemo_id_analysis.count > 0
                THEN
                    FOR i IN 1 .. l_hemo_id_analysis.count
                    LOOP
                        IF l_hemo_flg_analysis(i) = pk_alert_constant.g_no
                        THEN
                            g_error := 'CALL PK_LAB_TESTS_API_DB.CREATE_LAB_TEST_ORDER';
                            IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                                             i_prof                    => i_prof,
                                                                             i_patient                 => rec.id_patient,
                                                                             i_episode                 => i_episode,
                                                                             i_analysis_req            => NULL,
                                                                             i_analysis_req_det        => table_number(NULL),
                                                                             i_analysis_req_det_parent => table_number(NULL),
                                                                             i_harvest                 => NULL,
                                                                             i_analysis                => table_number(l_hemo_id_analysis(i)),
                                                                             i_analysis_group          => table_table_varchar(table_varchar(NULL)),
                                                                             i_flg_type                => table_varchar('A'),
                                                                             i_dt_req                  => table_varchar(NULL),
                                                                             i_flg_time                => table_varchar(pk_lab_tests_constant.g_flg_time_e),
                                                                             i_dt_begin                => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                                    l_dt_begin,
                                                                                                                                                    i_prof)),
                                                                             i_dt_begin_limit          => table_varchar(NULL),
                                                                             i_episode_destination     => table_number(NULL),
                                                                             i_order_recurrence        => table_number(NULL),
                                                                             i_priority                => table_varchar(rec.flg_priority),
                                                                             i_flg_prn                 => table_varchar(pk_lab_tests_constant.g_analysis_normal),
                                                                             i_notes_prn               => table_varchar(NULL),
                                                                             i_specimen                => table_number(l_hemo_id_sample_type(i)),
                                                                             i_body_location           => table_table_number(table_number(NULL)),
                                                                             i_laterality              => table_table_varchar(table_varchar(NULL)),
                                                                             i_collection_room         => table_number(NULL),
                                                                             i_notes                   => table_varchar(NULL),
                                                                             i_notes_scheduler         => table_varchar(NULL),
                                                                             i_notes_technician        => table_varchar(NULL),
                                                                             i_notes_patient           => table_varchar(NULL),
                                                                             i_diagnosis_notes         => table_varchar(NULL),
                                                                             i_diagnosis               => NULL,
                                                                             i_exec_institution        => table_number(NULL),
                                                                             i_clinical_purpose        => table_number(NULL),
                                                                             i_clinical_purpose_notes  => table_varchar(NULL),
                                                                             i_flg_col_inst            => table_varchar(pk_lab_tests_constant.g_yes),
                                                                             i_flg_fasting             => table_varchar(pk_lab_tests_constant.g_no),
                                                                             i_lab_req                 => table_number(NULL),
                                                                             i_prof_cc                 => table_table_varchar(table_varchar(NULL)),
                                                                             i_prof_bcc                => table_table_varchar(table_varchar(NULL)),
                                                                             i_codification            => table_number(NULL),
                                                                             i_health_plan             => table_number(NULL),
                                                                             i_exemption               => table_number(NULL),
                                                                             i_prof_order              => table_number(i_prof.id),
                                                                             i_dt_order                => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                                    l_dt_begin,
                                                                                                                                                    i_prof)),
                                                                             i_order_type              => table_number(NULL),
                                                                             i_clinical_question       => table_table_number(table_number(NULL)),
                                                                             i_response                => table_table_varchar(table_varchar(NULL)),
                                                                             i_clinical_question_notes => table_table_varchar(table_varchar(NULL)),
                                                                             i_clinical_decision_rule  => table_number(NULL),
                                                                             i_flg_origin_req          => 'B',
                                                                             i_task_dependency         => table_number(NULL),
                                                                             i_flg_task_depending      => table_varchar(pk_lab_tests_constant.g_no),
                                                                             i_episode_followup_app    => table_number(NULL),
                                                                             i_schedule_followup_app   => table_number(NULL),
                                                                             i_event_followup_app      => table_number(NULL),
                                                                             i_test                    => pk_blood_products_constant.g_no,
                                                                             o_flg_show                => l_flg_show_analysis,
                                                                             o_msg_title               => l_flg_show_analysis,
                                                                             o_msg_req                 => l_flg_show_analysis,
                                                                             o_button                  => l_flg_show_analysis,
                                                                             o_analysis_req_array      => l_analysis_req,
                                                                             o_analysis_req_det_array  => l_analysis_req_det,
                                                                             o_analysis_req_par_array  => l_analysis_req_par,
                                                                             o_error                   => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            l_analysis_ins := l_analysis_req_det(1);
                        ELSE
                            l_analysis_ins := l_hemo_analysis_req_det(i);
                        END IF;
                    
                        IF (l_analysis_req IS NOT NULL AND l_analysis_req.count > 0)
                           OR (l_analysis_ins IS NOT NULL)
                        THEN
                            ts_blood_product_analysis.ins(id_blood_product_analysis_in => seq_blood_product_analysis.nextval,
                                                          id_analysis_req_det_in       => l_analysis_ins,
                                                          id_blood_product_det_in      => l_next_det,
                                                          rows_out                     => l_rows_out);
                        END IF;
                    
                        IF l_hemo_flg_collected(i) = pk_alert_constant.g_no
                        THEN
                            l_harvest_state := pk_alert_constant.g_yes;
                        END IF;
                    END LOOP;
                
                    IF l_harvest_state = pk_blood_products_constant.g_yes
                    THEN
                        l_flg_status_det := pk_blood_products_constant.g_status_det_r_cc;
                    ELSE
                        l_flg_status_det := pk_blood_products_constant.g_status_det_r_w;
                    END IF;
                
                    ts_blood_product_det.upd(id_blood_product_det_in => l_next_det,
                                             flg_status_in           => l_flg_status_det,
                                             rows_out                => l_rows_out);
                
                    g_error := 'CALL PROCESS_INSERT';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'BLOOD_PRODUCT_DET',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                END IF;
            END IF; --req analysis
        
            g_error := 'CALL PK_CPOE.SYNC_TASK';
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => pk_blood_products_constant.g_task_type_cpoe_bp,
                                     i_task_request         => rec.id_blood_product_det,
                                     i_task_start_timestamp => rec.dt_begin,
                                     o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END LOOP;
    
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_drafts;

    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_req blood_product_req.id_blood_product_req%TYPE;
    
    BEGIN
    
        FOR i IN 1 .. i_draft.count
        LOOP
        
            SELECT id_blood_product_req
              INTO l_bp_req
              FROM blood_product_det
             WHERE id_blood_product_det = i_draft(i);
        
            ts_blood_product_analysis.del_by(where_clause_in => 'id_blood_product_det = ' || i_draft(i));
        
            ts_blood_products_ea.del_by(where_clause_in => 'id_blood_product_det = ' || i_draft(i));
        
            DELETE FROM mcdt_req_diagnosis mrd
             WHERE mrd.id_blood_product_req = l_bp_req;
        
            ts_blood_product_det.del(id_blood_product_det_in => i_draft(i));
        
            ts_blood_product_req.del_by(where_clause_in => 'id_blood_product_req = ' || l_bp_req);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_draft;

    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_det    table_number;
        l_bp_req    table_number;
        l_cos_order table_number;
    
        l_expired_note    sys_message.desc_message%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- Sanity check
        IF i_task_requests IS NULL
           OR i_episode IS NULL
        THEN
            g_error := 'Invalid input arguments';
            RETURN TRUE;
        END IF;
    
        l_expired_note := pk_message.get_message(i_lang, 'CPOE_M014');
    
        SELECT bpd.id_blood_product_det, bpd.id_blood_product_req, bpd.id_co_sign_order
          BULK COLLECT
          INTO l_bp_det, l_bp_req, l_cos_order
          FROM blood_product_req bpr
          JOIN blood_product_det bpd
            ON bpr.id_blood_product_req = bpd.id_blood_product_det
         WHERE bpr.id_episode = i_episode
           AND bpd.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                             column_value
                                              FROM TABLE(i_task_requests) t);
    
        IF l_bp_det.count > 0
        THEN
            FOR i IN 1 .. l_bp_det.count
            LOOP
                ts_blood_product_det.upd(id_blood_product_det_in => l_bp_det(i),
                                         flg_status_in           => pk_blood_products_constant.g_status_det_e,
                                         id_prof_cancel_in       => i_prof.id,
                                         notes_cancel_in         => l_expired_note,
                                         dt_cancel_tstz_in       => g_sysdate_tstz,
                                         dt_last_update_tstz_in  => g_sysdate_tstz,
                                         rows_out                => l_rows_out);
            
                g_error := 'PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END LOOP;
        
            FOR i IN 1 .. l_bp_req.count
            LOOP
                ts_blood_product_req.upd(id_blood_product_req_in => l_bp_req(i),
                                         flg_status_in           => pk_blood_products_constant.g_status_req_e,
                                         id_prof_cancel_in       => i_prof.id,
                                         notes_cancel_in         => l_expired_note,
                                         dt_cancel_tstz_in       => g_sysdate_tstz,
                                         dt_last_update_tstz_in  => g_sysdate_tstz,
                                         rows_out                => l_rows_out);
            
                g_error := 'PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_REQ',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END LOOP;
        
            FOR i IN 1 .. l_cos_order.count
            LOOP
                g_error := 'CALL PK_CO_SIGN_API.SET_TASK_OUTDATED';
                IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_episode         => i_episode,
                                                        i_id_co_sign      => NULL,
                                                        i_id_co_sign_hist => l_cos_order(i),
                                                        i_dt_update       => g_sysdate_tstz,
                                                        o_id_co_sign_hist => l_id_co_sign_hist,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EXPIRE_TASK',
                                              o_error);
            RETURN FALSE;
    END expire_task;

    FUNCTION get_cpoe_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        OPEN o_task_list FOR
            WITH tcs_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    i_episode,
                                                                    pk_blood_products_constant.g_task_type_bp)))
            SELECT task_type,
                   task_description,
                   id_professional,
                   icon_warning,
                   status_string,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   create_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_task,
                   task_title,
                   task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   pk_blood_products_constant.g_task_type_bp AS id_task_type_source,
                   id_task_dependency AS id_task_dependency,
                   decode(flg_status,
                          pk_blood_products_constant.g_status_req_c,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_rep_cancel,
                   NULL flg_prn_conditional
              FROM (SELECT pk_blood_products_constant.g_task_type_bp task_type,
                           decode(i_flg_report,
                                  pk_alert_constant.g_yes,
                                  pk_translation.get_translation(i_lang, 'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type) || ', ' ||
                                  nvl(bpea.qty_received, bpea.qty_exec) || ' mL',
                                  (pk_translation.get_translation(i_lang,
                                                                  'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type) || ' (' ||
                                  pk_date_utils.date_char_tsz(i_lang,
                                                               bpea.dt_begin_det,
                                                               i_prof.institution,
                                                               i_prof.software) || ') <br>' ||
                                  nvl(bpea.qty_received, bpea.qty_exec) || ' mL')) task_description,
                           nvl(bpd.id_prof_last_update, bpea.id_professional) id_professional,
                           NULL icon_warning,
                           pk_blood_products_utils.get_status_string(i_lang, i_prof, i_episode, bpd.id_blood_product_det) status_string,
                           bpea.id_blood_product_det id_request,
                           nvl(bpea.dt_begin_det, bpea.dt_begin_req) start_date_tstz,
                           (SELECT bpe.dt_begin
                              FROM blood_product_execution bpe
                             WHERE bpe.id_blood_product_det = bpea.id_blood_product_det
                               AND bpe.action = pk_blood_products_constant.g_bp_action_administer) end_date_tstz, --No caso dos blood products, o end_date é a data de administração
                           coalesce(bpd.dt_last_update_tstz, bpd.update_time, bpr.dt_req_tstz) AS create_date_tstz,
                           bpea.flg_status_det flg_status,
                           decode(bpea.flg_status_det,
                                  pk_blood_products_constant.g_status_det_rt,
                                  pk_blood_products_constant.g_no,
                                  pk_blood_products_constant.g_status_det_f,
                                  pk_blood_products_constant.g_no,
                                  pk_blood_products_constant.g_status_det_c,
                                  pk_blood_products_constant.g_no,
                                  pk_blood_products_constant.g_status_det_d,
                                  pk_blood_products_constant.g_no,
                                  pk_blood_products_constant.g_status_det_br,
                                  pk_blood_products_constant.g_no,
                                  pk_blood_products_constant.g_yes) flg_cancel,
                           NULL flg_conflict,
                           pk_translation.get_translation(i_lang, 'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type) task_title,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                            i_prof,
                                                                                            bpd.id_order_recurrence),
                                      pk_translation.get_translation(i_lang,
                                                                     'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'))) task_instructions,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  decode(bpd.notes_cancel,
                                         NULL,
                                         decode(bpd.notes, NULL, NULL, bpd.notes),
                                         bpd.notes_cancel)) task_notes,
                           NULL drug_dose,
                           NULL drug_route,
                           NULL drug_take_in_case,
                           decode(i_flg_report,
                                  pk_alert_constant.get_yes,
                                  pk_sysdomain.get_domain('BLOOD_PRODUCT_DET.FLG_STATUS', bpea.flg_status_det, i_lang)) task_status,
                           nvl(bpea.dt_begin_det, bpea.dt_begin_req) TIMESTAMP,
                           1 rank,
                           nvl(bpea.id_episode, bpea.id_episode_origin) AS id_episode,
                           bpea.id_hemo_type id_task,
                           bpea.id_blood_product_req id_task_dependency -- Não temos sitio para ir a REQ e para evitar alterar em todas as funcionalidades usou-se este campo
                      FROM blood_products_ea bpea
                      JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpea.id_blood_product_req
                      JOIN blood_product_det bpd
                        ON bpd.id_blood_product_det = bpea.id_blood_product_det
                      LEFT JOIN tcs_table tcs
                        ON bpd.id_co_sign_order = tcs.id_co_sign_hist
                     WHERE bpea.id_patient = i_patient
                       AND (bpea.id_episode IN
                           (SELECT id_episode
                               FROM episode
                              WHERE id_visit = pk_episode.get_id_visit(i_episode)) OR
                           bpea.id_episode_origin IN
                           (SELECT id_episode
                               FROM episode
                              WHERE id_visit = pk_episode.get_id_visit(i_episode)))
                       AND ((i_flg_out_of_cpoe = pk_alert_constant.g_yes AND i_flg_print_items = pk_alert_constant.g_no) OR
                           (i_task_request IS NULL OR (bpea.id_blood_product_det IN
                           (SELECT /*+opt_estimate (table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(i_task_request) t))) AND
                           (bpea.flg_status_det NOT IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(i_filter_status) t) OR
                           ((bpd.dt_cancel_tstz >= l_cancelled_task_filter_tstz AND
                           bpd.flg_status = pk_blood_products_constant.g_status_req_c) OR
                           (bpd.dt_begin_tstz >= i_filter_tstz AND
                           bpd.flg_status != pk_blood_products_constant.g_status_req_c)))))
             ORDER BY rank;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_cpoe_task_list;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cp_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end   TIMESTAMP WITH LOCAL TIME ZONE;
        l_tbl_diet table_number;
    
        l_tbl_rec_exec_static t_tbl_cpoe_execution;
        l_last_date           monitorization_vs_plan.dt_plan_tstz%TYPE;
        l_interval            monitorization.interval%TYPE;
        l_calc_last_date      monitorization_vs_plan.dt_plan_tstz%TYPE;
    
        l_error t_error_out;
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := nvl(pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_begin, i_days => 1),
                            current_timestamp);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        OPEN o_plan_rep FOR
            SELECT d.id_blood_product_det id_prescription,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => d.dt_begin_tstz, i_prof => i_prof) planned_date,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => nvl(bpe.dt_begin, bpe.dt_bp_execution_tstz),
                                               i_prof => i_prof) exec_date,
                   bpe.description exec_notes,
                   'N' out_of_period
              FROM blood_product_req t
             INNER JOIN blood_product_det d
                ON t.id_blood_product_req = d.id_blood_product_req
              LEFT JOIN blood_product_execution bpe
                ON bpe.id_blood_product_det = d.id_blood_product_det
               AND bpe.action = 'ADMIN'
             WHERE t.id_episode = i_episode
               AND t.dt_begin_tstz BETWEEN l_cp_begin AND l_cp_end
               AND t.flg_status NOT IN
                   (pk_blood_products_constant.g_status_req_df, pk_blood_products_constant.g_status_req_c)
            /*UNION ALL
            SELECT d.id_blood_product_det id_prescription,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_begin_tstz, i_prof => i_prof) planned_date,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => nvl(bpe.dt_begin, bpe.dt_bp_execution_tstz),
                                               i_prof => i_prof) exec_date,
                   bpe.description exec_notes,
                   'Y' out_of_period
              FROM blood_product_req t
             INNER JOIN blood_product_det d
                ON t.id_blood_product_req = d.id_blood_product_req
              LEFT JOIN blood_product_execution bpe
                ON bpe.id_blood_product_det = d.id_blood_product_det
               AND bpe.action = 'ADMIN'
             WHERE t.id_episode = i_episode
               AND t.dt_begin_tstz < l_cp_begin
               AND t.flg_status NOT IN
                   (pk_blood_products_constant.g_status_req_df, pk_blood_products_constant.g_status_req_c)*/
             ORDER BY planned_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'INACTIVATE_MONITORZTN_TASKS',
                                              l_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status blood_product_det.flg_status%TYPE;
        l_bp_req     blood_product_req.id_blood_product_req%TYPE;
    
        l_id_action   NUMBER(24);
        l_id_parent   NUMBER(24);
        l_level_num   NUMBER(24);
        l_from_state  VARCHAR2(20 CHAR);
        l_to_state    VARCHAR2(2 CHAR);
        l_desc_action VARCHAR2(200 CHAR);
        l_icon        VARCHAR2(200 CHAR);
        l_flg_default VARCHAR2(1 CHAR);
        l_flg_active  VARCHAR2(1 CHAR);
        l_rank        NUMBER(24);
    
        l_rec t_rec_cpoe_actions_list := t_rec_cpoe_actions_list(NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
    
        l_rec_index PLS_INTEGER := 0;
    
        l_task_actions t_tbl_cpoe_actions_list;
    
    BEGIN
    
        l_task_actions := t_tbl_cpoe_actions_list();
    
        SELECT bpd.flg_status, bpd.id_blood_product_req
          INTO l_flg_status, l_bp_req
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_det = i_task_request;
    
        IF NOT pk_action.get_cross_actions(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_subject    => 'BP_BAGS',
                                           i_from_state => table_varchar(l_flg_status),
                                           o_actions    => o_action,
                                           o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            -- if this task type support actions then fetch them
        
            g_error := 'fetch record from l_task_actions cursor';
            IF o_action IS NOT NULL
            THEN
                FETCH o_action
                    INTO l_id_action,
                         l_id_parent,
                         l_level_num,
                         l_to_state,
                         l_desc_action,
                         l_icon,
                         l_flg_default,
                         l_flg_active,
                         l_from_state,
                         l_rank;
                EXIT WHEN o_action%NOTFOUND;
            ELSE
                pk_types.open_my_cursor(o_action);
                EXIT;
            END IF;
        
            l_rec.id_action     := l_id_action;
            l_rec.id_parent     := l_id_parent;
            l_rec.level_num     := l_level_num;
            l_rec.from_state    := NULL;
            l_rec.to_state      := l_to_state;
            l_rec.desc_action   := l_desc_action;
            l_rec.icon          := l_icon;
            l_rec.flg_default   := l_flg_default;
            l_rec.flg_active    := l_flg_active;
            l_rec.internal_name := l_from_state;
        
            l_task_actions.extend;
            l_rec_index := l_rec_index + 1;
            l_task_actions(l_rec_index) := l_rec;
        END LOOP;
    
        CLOSE o_action;
    
        OPEN o_action FOR
            SELECT *
              FROM TABLE(l_task_actions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_task_actions;

    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_TASK_STATUS';
        OPEN o_task_status FOR
            SELECT pk_blood_products_constant.g_task_type_bp id_task_type,
                   bpea.id_blood_product_det                 id_task_request,
                   bpea.flg_status_det                       flg_status
              FROM blood_products_ea bpea
             WHERE bpea.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_task_status',
                                              o_error);
            RETURN FALSE;
    END get_task_status;

    PROCEDURE order_sets________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN blood_product_req.id_blood_product_req%TYPE,
        i_task_request_det IN blood_product_det.id_blood_product_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_det_desc VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT listagg(pk_translation.get_translation(i_lang, ht.code_hemo_type), '; ') within GROUP(ORDER BY bpd.id_blood_product_det)
          INTO l_det_desc
          FROM blood_product_det bpd
          JOIN hemo_type ht
            ON ht.id_hemo_type = bpd.id_hemo_type
         WHERE bpd.id_blood_product_req = i_task_request;
    
        BEGIN
            SELECT pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T14') || ' (' || l_det_desc || ')'
              INTO o_task_desc
              FROM blood_product_req bpd
             WHERE (bpd.id_blood_product_req = i_task_request AND i_task_request_det IS NULL);
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_bp_task_title;

    FUNCTION get_bp_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN blood_product_req.id_blood_product_req%TYPE,
        i_task_request_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('PROCEDURES_T091',
                                                        'PROCEDURES_T023',
                                                        'PROCEDURES_T025',
                                                        'PROCEDURES_T130',
                                                        'PROCEDURES_T130',
                                                        'PROCEDURES_T078');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i)) || ' ';
        END LOOP;
    
        g_error := 'Fetch instructions for interv_prescription: ' || i_task_request;
        BEGIN
            SELECT DISTINCT decode(bpd.flg_priority,
                                   NULL,
                                   NULL,
                                   aa_code_messages('PROCEDURES_T091') ||
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'BLOOD_PRODUCT_DET.FLG_PRIORITY',
                                                           bpd.flg_priority,
                                                           NULL) || '; ') ||
                            decode(i_flg_showdate,
                                   pk_alert_constant.g_yes,
                                   aa_code_messages('PROCEDURES_T023') ||
                                   decode(bpr.flg_time,
                                          pk_procedures_constant.g_flg_time_e,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                  bpr.flg_time,
                                                                  NULL),
                                          pk_procedures_constant.g_flg_time_b,
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                  bpr.flg_time,
                                                                  NULL),
                                          pk_sysdomain.get_domain(i_lang,
                                                                  i_prof,
                                                                  'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                  bpr.flg_time,
                                                                  NULL)) || '; ') ||
                            aa_code_messages('PROCEDURES_T025') ||
                            nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                      i_prof,
                                                                                      bpd.id_order_recurrence),
                                pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) || '; ' instructions
              INTO o_task_instructions
              FROM blood_product_det bpd, blood_product_req bpr
             WHERE ((bpd.id_blood_product_req = i_task_request AND i_task_request_det IS NULL) OR
                   (bpd.id_blood_product_det = i_task_request_det AND i_task_request IS NULL))
               AND bpd.id_blood_product_req = bpr.id_blood_product_req;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_bp_task_instructions;

    FUNCTION get_bp_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN blood_product_det.id_blood_product_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT bpea.flg_status_det flg_status,
               pk_utils.get_status_string(i_lang,
                                          i_prof,
                                          bpea.status_str_req,
                                          bpea.status_msg_req,
                                          bpea.status_icon_req,
                                          bpea.status_flg_req)
          INTO o_flg_status, o_status_string
          FROM blood_products_ea bpea
         WHERE bpea.id_blood_product_req = i_task_request
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_bp_status',
                                              o_error);
            RETURN FALSE;
    END get_bp_status;

    FUNCTION get_bp_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_hemo_type hemo_type.id_hemo_type%TYPE;
    
    BEGIN
    
        g_error := 'GET PREDEFINED BLOOD PRODUCT INFO';
        SELECT bpd.id_hemo_type AS id_hemo_type
          INTO l_id_hemo_type
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req = i_task_request
           AND rownum = 1;
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_QUESTIONNAIRE';
        IF NOT pk_blood_products_core.get_bp_questionnaire(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_patient   => i_patient,
                                                           i_episode   => i_episode,
                                                           i_hemo_type => l_id_hemo_type,
                                                           i_flg_time  => pk_blood_products_constant.g_bp_cq_on_order,
                                                           o_list      => o_list,
                                                           o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
    END get_bp_questionnaire;

    FUNCTION get_bp_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT bpr.id_blood_product_req, bpr.dt_begin_tstz, NULL dt_end
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 *
                                                  FROM TABLE(i_task_request) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_bp_date_limits;

    FUNCTION set_bp_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        o_bp_req                  OUT table_number,
        o_bp_det                  OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_bp_req(i_id blood_product_req.id_blood_product_req%TYPE) IS
            SELECT bpr.*
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_id;
    
        CURSOR c_bp_det(in_blood_product_req blood_product_req.id_blood_product_req%TYPE) IS
            SELECT bpd.*
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = in_blood_product_req;
    
        TYPE t_bp_req IS TABLE OF c_bp_req%ROWTYPE;
        t_tbl_bp_req t_bp_req;
    
        TYPE t_bp_det IS TABLE OF c_bp_det%ROWTYPE;
        t_tbl_bp_det t_bp_det;
    
        l_dt_begin VARCHAR2(100 CHAR);
    
        l_count_out_reqs NUMBER := 0;
        l_req_det_idx    NUMBER;
    
        TYPE t_record_bp_req_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_bp_req_map t_record_bp_req_map;
    
        l_all_bp_det table_number := table_number();
    
        l_bp_req blood_product_req.id_blood_product_req%TYPE;
        l_bp_det blood_product_det.id_blood_product_det%TYPE;
    
        l_order_recurrence_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        l_order_recurrence order_recurr_plan.id_order_recurr_plan%TYPE;
    
        l_order_recurr_final_array table_number := table_number();
    
        g_sysdate_char VARCHAR2(50);
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        o_bp_req := table_number();
        o_bp_det := table_table_number();
    
        FOR k IN 1 .. i_task_request.count
        LOOP
            l_bp_req := NULL;
            l_bp_det := NULL;
        
            g_error := 'OPEN C_BP_REQ';
            OPEN c_bp_req(i_id => i_task_request(k));
            FETCH c_bp_req BULK COLLECT
                INTO t_tbl_bp_req;
            CLOSE c_bp_req;
        
            FOR i IN 1 .. t_tbl_bp_req.count
            LOOP
                OPEN c_bp_det(t_tbl_bp_req(i).id_blood_product_req);
                FETCH c_bp_det BULK COLLECT
                    INTO t_tbl_bp_det;
                CLOSE c_bp_det;
            
                o_bp_det.extend;
                o_bp_det(o_bp_det.count) := table_number();
            
                FOR j IN 1 .. t_tbl_bp_det.count
                LOOP
                
                    IF t_tbl_bp_det(j).id_order_recurrence IS NOT NULL
                    THEN
                        -- get order recurrence option
                        IF NOT
                            pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                     i_prof                => i_prof,
                                                                                     i_order_plan          => t_tbl_bp_det(j).id_order_recurrence,
                                                                                     o_order_recurr_desc   => l_order_recurr_desc,
                                                                                     o_order_recurr_option => l_order_recurr_option,
                                                                                     o_start_date          => l_start_date,
                                                                                     o_occurrences         => l_occurrences,
                                                                                     o_duration            => l_duration,
                                                                                     o_unit_meas_duration  => l_unit_meas_duration,
                                                                                     o_duration_desc       => l_duration_desc,
                                                                                     o_end_date            => l_end_date,
                                                                                     o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                     o_error               => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        -- if recurrence option is once ou schedule, then delete reference
                        IF l_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_once
                           OR l_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                        THEN
                            g_error := 'UPDATE BLOOD_PRODUCT_DET';
                            ts_blood_product_det.upd(id_blood_product_det_in => t_tbl_bp_det(j).id_blood_product_det,
                                                     id_order_recurrence_in  => NULL,
                                                     id_order_recurrence_nin => FALSE,
                                                     rows_out                => l_rows_out);
                        
                        END IF;
                    
                        g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                        IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                                i_prof                    => i_prof,
                                                                                i_order_recurr_plan       => t_tbl_bp_det(j).id_order_recurrence,
                                                                                o_order_recurr_option     => l_order_recurrence_option,
                                                                                o_final_order_recurr_plan => l_order_recurrence,
                                                                                o_error                   => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                
                    IF pk_date_utils.date_send_tsz(i_lang, t_tbl_bp_req(i).dt_begin_tstz, i_prof) < g_sysdate_char
                    THEN
                        l_dt_begin := g_sysdate_char;
                    ELSE
                        l_dt_begin := pk_date_utils.date_send_tsz(i_lang, t_tbl_bp_req(i).dt_begin_tstz, i_prof);
                    END IF;
                
                    IF l_bp_req IS NULL
                    THEN
                        l_bp_req := ts_blood_product_req.next_key();
                    END IF;
                
                    pk_ia_event_blood_bank.blood_product_req_new(i_id_institution       => i_prof.institution,
                                                                 i_id_blood_product_req => l_bp_req);
                
                    g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.CREATE_BP_REQUEST';
                    IF NOT pk_blood_products_core.create_bp_request(i_lang                    => i_lang,
                                                                    i_prof                    => i_prof,
                                                                    i_patient                 => t_tbl_bp_req(i).id_patient,
                                                                    i_episode                 => t_tbl_bp_req(i).id_episode,
                                                                    i_blood_product_req       => l_bp_req,
                                                                    i_hemo_type               => t_tbl_bp_det(j).id_hemo_type,
                                                                    i_flg_time                => t_tbl_bp_req(i).flg_time,
                                                                    i_dt_begin                => l_dt_begin,
                                                                    i_episode_destination     => t_tbl_bp_req(i).id_episode_destination,
                                                                    i_order_recurrence        => l_order_recurrence,
                                                                    i_diagnosis               => NULL,
                                                                    i_clinical_purpose        => t_tbl_bp_det(j).id_clinical_purpose,
                                                                    i_clinical_purpose_notes  => t_tbl_bp_det(j).clinical_purpose_notes,
                                                                    i_priority                => t_tbl_bp_det(j).flg_priority,
                                                                    i_special_type            => t_tbl_bp_det(j).id_special_type,
                                                                    i_screening               => t_tbl_bp_det(j).flg_with_screening,
                                                                    i_without_nat             => t_tbl_bp_det(j).flg_without_nat_test,
                                                                    i_not_send_unit           => t_tbl_bp_det(j).flg_prepare_not_send,
                                                                    i_transf_type             => t_tbl_bp_det(j).transfusion_type,
                                                                    i_qty_exec                => t_tbl_bp_det(j).qty_exec,
                                                                    i_unit_qty_exec           => t_tbl_bp_det(j).id_unit_mea_qty_exec,
                                                                    i_exec_institution        => t_tbl_bp_det(j).id_exec_institution,
                                                                    i_not_order_reason        => t_tbl_bp_det(j).id_not_order_reason,
                                                                    i_special_instr           => t_tbl_bp_det(j).special_instr,
                                                                    i_notes                   => t_tbl_bp_det(j).notes_tech,
                                                                    i_prof_order              => i_prof_order(i),
                                                                    i_dt_order                => i_dt_order(i),
                                                                    i_order_type              => i_order_type(i),
                                                                    i_health_plan             => t_tbl_bp_det(j).id_pat_health_plan,
                                                                    i_exemption               => t_tbl_bp_det(j).id_pat_exemption,
                                                                    i_clinical_question       => i_clinical_question(i),
                                                                    i_response                => i_response(i),
                                                                    i_clinical_question_notes => i_clinical_question_notes(i),
                                                                    i_clinical_decision_rule  => i_clinical_decision_rule,
                                                                    o_blood_prod_det          => l_bp_det,
                                                                    o_error                   => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- check if blood_req not exists
                    IF NOT ibt_bp_req_map.exists(to_char(l_bp_req))
                    THEN
                        o_bp_req.extend;
                        l_count_out_reqs := l_count_out_reqs + 1;
                    
                        -- set mapping between blood_req and its position in the output array
                        ibt_bp_req_map(to_char(l_bp_req)) := l_count_out_reqs;
                    
                        -- set blood_req output 
                        o_bp_req(l_count_out_reqs) := l_bp_req;
                    END IF;
                
                    IF l_order_recurrence IS NOT NULL
                    THEN
                        l_order_recurr_final_array.extend;
                        l_order_recurr_final_array(1) := t_tbl_bp_det(j).id_order_recurrence;
                    
                        g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                        IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                                    i_prof       => i_prof,
                                                                                    i_order_plan => l_order_recurr_final_array,
                                                                                    o_error      => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                
                    -- append req det of this bp request to all req dets array
                    l_all_bp_det.extend;
                    l_all_bp_det(l_all_bp_det.count) := l_bp_det;
                
                    l_req_det_idx := o_bp_det.count;
                    o_bp_det(l_req_det_idx).extend;
                    o_bp_det(l_req_det_idx)(o_bp_det(l_req_det_idx).count) := l_bp_det;
                END LOOP;
            END LOOP;
        
            FOR i IN 1 .. l_all_bp_det.count
            LOOP
                g_error := 'UPDATE BLOOD_PRODUCT_DET';
                ts_blood_product_det.upd(id_blood_product_det_in  => l_all_bp_det(i),
                                         flg_req_origin_module_in => pk_alert_constant.g_task_origin_order_set,
                                         rows_out                 => l_rows_out);
            END LOOP;
        
            g_error := 'CALL TO PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END LOOP;
    
        g_error := 'CALL PK_BP_EXTERNAL_API_DB.SET_BP_DELETE_TASK';
        IF NOT pk_bp_external_api_db.set_bp_delete_task(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_task_request => i_task_request,
                                                        o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_request_task;

    FUNCTION set_bp_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_bp_req       OUT blood_product_req.id_blood_product_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_req blood_product_req%ROWTYPE;
        l_bp_det blood_product_det%ROWTYPE;
    
        l_rows_out     table_varchar := table_varchar();
        l_rows_req_out table_varchar := table_varchar();
    
        l_order_recurr_desc   VARCHAR2(1000 CHAR);
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date          order_recurr_plan.start_date%TYPE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc       VARCHAR2(1000 CHAR);
        l_end_date            order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable VARCHAR2(1 CHAR);
    
        l_flg_time VARCHAR2(1 CHAR);
        error_unexpected EXCEPTION;
    
        -- function that returns the default value for "to be performed" field
        FUNCTION get_default_flg_time
        (
            i_lang  IN language.id_language%TYPE,
            i_prof  IN profissional,
            o_error OUT t_error_out
        ) RETURN VARCHAR2 IS
            l_epis_type   epis_type.id_epis_type%TYPE := pk_episode.get_epis_type(i_lang    => i_lang,
                                                                                  i_id_epis => i_episode);
            c_data        pk_types.cursor_type;
            l_val         sys_domain.val%TYPE;
            l_rank        NUMBER;
            l_desc_val    sys_domain.desc_val%TYPE;
            l_flg_default VARCHAR2(1 CHAR);
        BEGIN
            -- gets default value for "to be performed" field
            IF NOT pk_blood_products_core.get_bp_time_list(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_epis_type => l_epis_type,
                                                           o_list      => c_data,
                                                           o_error     => o_error)
            THEN
                RAISE error_unexpected;
            END IF;
        
            -- loop until fetch default value
            LOOP
                FETCH c_data
                    INTO l_val, l_rank, l_desc_val, l_flg_default;
            
                EXIT WHEN l_flg_default = pk_procedures_constant.g_yes OR c_data%NOTFOUND;
            
            END LOOP;
            CLOSE c_data;
        
            RETURN l_val;
        END;
    
    BEGIN
    
        g_error := 'GET INTERV_PRESCRIPTION';
        SELECT bpr.*
          INTO l_bp_req
          FROM blood_product_req bpr
         WHERE bpr.id_blood_product_req = i_task_request;
    
        l_bp_req.id_blood_product_req := ts_blood_product_req.next_key();
        l_bp_req.dt_begin_tstz        := current_timestamp;
        l_bp_req.dt_req_tstz          := current_timestamp;
    
        -- gets default value for "to be performed" field
        l_flg_time := get_default_flg_time(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        --Duplicate row to interv_prescription
        g_error := 'INSERT INTERV_PRESCRIPTION';
        ts_blood_product_req.ins(rec_in => l_bp_req, gen_pky_in => FALSE, rows_out => l_rows_req_out);
    
        IF i_patient IS NOT NULL
           AND i_episode IS NOT NULL
        THEN
            ts_blood_product_req.upd(id_blood_product_req_in => l_bp_req.id_blood_product_req,
                                     id_patient_in           => i_patient,
                                     id_episode_in           => i_episode,
                                     flg_time_in             => l_flg_time,
                                     rows_out                => l_rows_req_out);
        END IF;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_REQ',
                                      i_rowids     => l_rows_req_out,
                                      o_error      => o_error);
    
        l_rows_out     := NULL;
        l_rows_req_out := NULL;
    
        FOR rec IN (SELECT bpd.id_blood_product_det
                      FROM blood_product_det bpd
                     WHERE bpd.id_blood_product_req = i_task_request)
        LOOP
            g_error := 'GET BLOOD_PRODUCT_DET';
            SELECT bpd.*
              INTO l_bp_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = rec.id_blood_product_det;
        
            -- check if this interv_presc_det has an order recurrence plan
            IF l_bp_det.id_order_recurrence IS NOT NULL
            THEN
                -- copy order recurrence plan
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.COPY_FROM_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                              i_prof                   => i_prof,
                                                                              i_order_recurr_area      => NULL,
                                                                              i_order_recurr_plan_from => l_bp_det.id_order_recurrence,
                                                                              i_flg_force_temp_plan    => pk_alert_constant.g_no,
                                                                              o_order_recurr_desc      => l_order_recurr_desc,
                                                                              o_order_recurr_option    => l_order_recurr_option,
                                                                              o_start_date             => l_start_date,
                                                                              o_occurrences            => l_occurrences,
                                                                              o_duration               => l_duration,
                                                                              o_unit_meas_duration     => l_unit_meas_duration,
                                                                              o_duration_desc          => l_duration_desc,
                                                                              o_end_date               => l_end_date,
                                                                              o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                              o_order_recurr_plan      => l_bp_det.id_order_recurrence,
                                                                              o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                l_start_date := current_timestamp;
            END IF;
        
            -- update start dates (according to order recurr plan)
            l_bp_req.dt_begin_tstz := l_start_date;
            l_bp_det.dt_begin_tstz := l_start_date;
        
            ts_blood_product_req.upd(id_blood_product_req_in => l_bp_req.id_blood_product_req,
                                     dt_begin_tstz_in        => l_bp_req.dt_begin_tstz,
                                     rows_out                => l_rows_req_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_REQ',
                                          i_rowids     => l_rows_req_out,
                                          o_error      => o_error);
        
            l_bp_det.id_blood_product_req := l_bp_req.id_blood_product_req;
            l_bp_det.id_blood_product_det := ts_blood_product_det.next_key();
        
            --Duplicate row to interv_presc_det
            g_error := 'INSERT BLOOD_PRODUCT_DET';
            ts_blood_product_det.ins(rec_in => l_bp_det, rows_out => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END LOOP;
    
        o_bp_req := l_bp_req.id_blood_product_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_copy_task;

    FUNCTION set_bp_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            g_error := 'DELETE BLOOD_PRODCUT_DET_HIST';
            ts_blood_product_det_hist.del_by(where_clause_in => 'id_blood_product_req = ' || i_task_request(i));
        
            g_error := 'DELETE BLOOD_PRODCUT_DET';
            ts_blood_product_det.del_by(where_clause_in => 'id_blood_product_req = ' || i_task_request(i));
        
            g_error := 'DELETE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.del(id_blood_product_req_in => i_task_request(i));
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_delete_task;

    FUNCTION set_bp_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_det table_number;
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
        
            SELECT bpd.id_blood_product_det
              BULK COLLECT
              INTO l_bp_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = i_task_request(i);
        
            -- loop through all req dets
            FOR j IN 1 .. l_bp_det.count
            LOOP
            
                g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAG_NO_COMMIT';
                IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_epis              => i_episode,
                                                                i_diag              => i_diagnosis,
                                                                i_exam_req          => NULL,
                                                                i_analysis_req      => NULL,
                                                                i_interv_presc      => NULL,
                                                                i_exam_req_det      => NULL,
                                                                i_analysis_req_det  => NULL,
                                                                i_interv_presc_det  => NULL,
                                                                i_blood_product_req => i_task_request(i),
                                                                i_blood_product_det => l_bp_det(j),
                                                                o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_bp_diagnosis;

    FUNCTION cancel_bp_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_bp_det        IN table_number,
        i_dt_cancel     IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN VARCHAR2,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.CANCEL_BP_ORDER';
        IF NOT pk_blood_products_core.cancel_bp_order(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_blood_product_req => i_bp_det,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes_cancel      => i_cancel_notes,
                                                      o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'cancel_bp_task',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_task;

    FUNCTION check_bp_mandatory
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_check table_varchar;
    
        l_clinical_purpose sys_config.value%TYPE;
    
    BEGIN
    
        l_clinical_purpose := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_BP', i_prof);
    
        g_error := 'Fetch instructions for i_interv_prescription: ' || i_task_request;
        SELECT decode(bpd.flg_priority,
                      NULL,
                      pk_alert_constant.g_no,
                      decode(bpr.flg_time,
                             NULL,
                             pk_alert_constant.g_no,
                             decode(l_clinical_purpose,
                                    pk_alert_constant.g_yes,
                                    decode(bpd.id_clinical_purpose, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                    pk_alert_constant.g_yes)))
          BULK COLLECT
          INTO l_tbl_check
          FROM blood_product_req bpr
          JOIN blood_product_det bpd
            ON bpd.id_blood_product_req = bpd.id_blood_product_req
         WHERE bpr.id_blood_product_req = i_task_request;
    
        -- check if there's no req dets with mandatory fields empty
        FOR i IN 1 .. l_tbl_check.count
        LOOP
            IF l_tbl_check(i) = pk_alert_constant.g_no
            THEN
                o_check := pk_alert_constant.g_no;
            
                RETURN TRUE;
            END IF;
        END LOOP;
    
        -- all mandatory fields have a value
        o_check := pk_procedures_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BP_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_bp_mandatory;

    FUNCTION check_bp_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_flg_conflict := pk_procedures_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BP_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_bp_conflict;

    FUNCTION check_bp_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_det.id_blood_product_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --pk_procedures_external.check_procedure_cancel
        o_flg_cancel := pk_blood_products_utils.get_bp_permission(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_button              => pk_procedures_constant.g_interv_button_cancel,
                                                                  i_episode             => i_episode,
                                                                  i_blood_product_det   => i_task_request,
                                                                  i_flg_current_episode => pk_alert_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BP_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_bp_cancel;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_type_bp CONSTANT VARCHAR2(5) := 'BP';
    
        l_records t_table_rec_gen_area_rank_tmp;
    
        l_viewer_lim_tasktime_interv sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_INTERV',
                                                                                      i_prof);
    
        l_episode table_number;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T327');
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
    
        g_error := 'INSERT ON VARIABLE';
        SELECT t_rec_gen_area_rank_tmp(t.varch1,
                                       t.varch2,
                                       t.varch3,
                                       t.varch4,
                                       t.varch5,
                                       t.varch6,
                                       t.varch7,
                                       t.varch8,
                                       t.varch9,
                                       t.varch10,
                                       t.varch11,
                                       t.varch12,
                                       t.varch13,
                                       t.varch14,
                                       t.varch15,
                                       t.numb1,
                                       t.numb2,
                                       t.numb3,
                                       t.numb4,
                                       t.numb5,
                                       t.numb6,
                                       t.numb7,
                                       t.numb8,
                                       t.numb9,
                                       t.numb10,
                                       t.numb11,
                                       t.numb12,
                                       t.numb13,
                                       t.numb14,
                                       t.numb15,
                                       t.dt_tstz1,
                                       t.dt_tstz2,
                                       t.dt_tstz3,
                                       t.dt_tstz4,
                                       t.dt_tstz5,
                                       t.dt_tstz6,
                                       t.dt_tstz7,
                                       t.dt_tstz8,
                                       t.dt_tstz9,
                                       t.dt_tstz10,
                                       t.dt_tstz11,
                                       t.dt_tstz12,
                                       t.dt_tstz13,
                                       t.dt_tstz14,
                                       t.dt_tstz15,
                                       t.rank)
          BULK COLLECT
          INTO l_records
          FROM (SELECT bpea.flg_status_det varch1,
                       bpea.flg_time varch2,
                       NULL varch3,
                       'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type varch4,
                       l_type_bp varch5,
                       bpea.flg_status_det varch6,
                       bpea.status_str varch7,
                       bpea.status_msg varch8,
                       bpea.status_icon varch9,
                       bpea.status_flg varch10,
                       NULL varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       bpea.id_episode_origin numb1,
                       bpea.id_blood_product_det numb2,
                       NULL numb3,
                       NULL numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       bpea.dt_begin_det dt_tstz1,
                       coalesce(bpea.dt_dg_last_update, bpea.dt_blood_product_det, bpea.dt_blood_product) dt_tstz2,
                       g_sysdate_tstz dt_tstz3,
                       bpea.dt_blood_product_det dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       pk_sysdomain.get_rank(i_lang, 'BLOOD_PRODUCT_DET.FLG_STATUS', bpea.flg_status_det) rank
                  FROM blood_products_ea bpea
                 WHERE bpea.id_patient = i_patient
                   AND bpea.flg_status_det NOT IN
                       (pk_blood_products_constant.g_status_det_c,
                        pk_blood_products_constant.g_status_det_df,
                        pk_blood_products_constant.g_status_det_d,
                        pk_blood_products_constant.g_status_det_e,
                        pk_blood_products_constant.g_status_det_n,
                        pk_blood_products_constant.g_status_det_pd)
                   AND ((i_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                       bpea.flg_status_det = pk_blood_products_constant.g_status_det_f) OR
                       (i_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                       bpea.flg_status_det NOT IN
                       (pk_blood_products_constant.g_status_det_f, pk_blood_products_constant.g_status_det_c)))
                   AND trunc(months_between(SYSDATE, bpea.dt_begin_req) / 12) <= l_viewer_lim_tasktime_interv) t;
    
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT id,
                   code_description,
                   description,
                   dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_req_tstz, i_prof) dt_req,
                   flg_status,
                   flg_type,
                   desc_status,
                   rank,
                   rank_order,
                   COUNT(0) over() num_count,
                   l_task_title task_title
              FROM (SELECT /*+opt_estimate(table gart rows=1)*/
                     gart.numb2 id,
                     gart.varch4 code_description,
                     decode(i_translate,
                            pk_blood_products_constant.g_no,
                            NULL,
                            pk_blood_products_utils.get_bp_desc_hemo_type(i_lang, i_prof, gart.numb2)) description,
                     gart.dt_tstz2 dt_req_tstz,
                     gart.varch1 flg_status,
                     gart.varch5 flg_type,
                     pk_blood_products_utils.get_status_string(i_lang, i_prof, i_episode, gart.numb2) desc_status,
                     gart.rank rank,
                     gart.numb2 * gart.numb3 rank_order
                      FROM TABLE(l_records) gart)
             ORDER BY rank DESC, rank_order DESC, id DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_ordered_list_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_ordered_list_det  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_ORDERED_LIST_DET';
        OPEN o_ordered_list_det FOR
            SELECT nvl(pk_translation.get_translation(i_lang, 'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type),
                       'HEMO_TYPE.CODE_HEMO_TYPE.' || bpea.id_hemo_type) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, bpea.id_professional) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    bpea.id_professional,
                                                    bpea.dt_blood_product,
                                                    bpea.id_episode) prof_spec_reg,
                   bpea.flg_time,
                   nvl(bpea.dt_dg_last_update, bpea.dt_blood_product) dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(bpd.dt_last_update_tstz, bpea.dt_begin_req), i_prof) dt_req,
                   nvl(bpea.dt_dg_last_update, bpea.dt_begin_req) dt_begin_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(bpd.dt_last_update_tstz, bpea.dt_begin_req), i_prof) dt_begin,
                   bpea.dt_blood_product_det dt_plan_tstz,
                   --bpd.dt_last_update_tstz dt_plan_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      nvl(bpd.dt_last_update_tstz, bpea.dt_blood_product_det),
                                                      i_prof) dt_pend_req,
                   bpea.flg_status_det flg_status,
                   pk_sysdomain.get_img(i_lang, 'BLOOD_PRODUCT_DET.FLG_STATUS', bpea.flg_status_det) icon_name,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || bpr.id_institution) institution,
                   bpea.id_episode_origin
              FROM blood_products_ea bpea, blood_product_req bpr, blood_product_det bpd
             WHERE bpea.id_blood_product_det = i_blood_product_det
               AND bpea.id_blood_product_det = bpd.id_blood_product_det
               AND bpea.id_blood_product_req = bpr.id_blood_product_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_ordered_list_det;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_viewer_area IN VARCHAR2,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list  pk_types.cursor_type;
        l_count NUMBER := 0;
        l_str   VARCHAR2(4000);
    
        l_task_type sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET ORDERED LIST';
        IF pk_bp_external.get_ordered_list(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_patient      => i_patient,
                                           i_episode      => i_episode,
                                           i_translate    => pk_procedures_constant.g_no,
                                           i_viewer_area  => i_viewer_area,
                                           o_ordered_list => l_list,
                                           o_error        => o_error)
        THEN
            FETCH l_list
                INTO l_str,
                     o_code_first,
                     o_desc_first,
                     o_dt_first,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_str,
                     l_count,
                     l_task_type;
        
            o_num_occur := l_count;
        
            RETURN TRUE;
        ELSE
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            RAISE g_user_exception;
        END IF;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              'U',
                                              g_error,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_count_and_first;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_bp_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_episode(i_episode episode.id_episode%TYPE) IS
            SELECT e.id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        IF i_patient IS NULL
        THEN
            g_error := 'OPEN C_EPISODE - i_episode: ' || i_episode;
            OPEN c_episode(i_episode);
            FETCH c_episode
                INTO l_patient;
            CLOSE c_episode;
        
            l_episode := i_episode;
        
            IF l_patient IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE BP_QUESTION_RESPONSE';
            UPDATE bp_question_response bqr
               SET bqr.id_episode = i_episode
             WHERE bqr.id_episode = i_episode_temp;
        
            g_error := 'UPDATE BP_QUESTION_RESPONSE_HIST';
            UPDATE bp_question_response_hist bqrh
               SET bqrh.id_episode = i_episode
             WHERE bqrh.id_episode = i_episode_temp;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ (id_episode_origin)';
            ts_blood_product_req.upd(id_episode_origin_in  => i_episode,
                                     id_episode_origin_nin => FALSE,
                                     where_in              => 'id_episode_origin = ' || i_episode_temp,
                                     rows_out              => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ (id_episode_destination)';
            ts_blood_product_req.upd(id_episode_destination_in  => i_episode,
                                     id_episode_destination_nin => FALSE,
                                     where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                     rows_out                   => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ (id_prev_episode) ';
            ts_blood_product_req.upd(id_prev_episode_in  => i_episode,
                                     id_prev_episode_nin => FALSE,
                                     where_in            => 'id_prev_episode = ' || i_episode_temp,
                                     rows_out            => l_rows_out);
        
            g_error := 'PROCESS UPDATE BLOOD_PRODUCT_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'BLOOD_PRODUCT_REQ',
                                          i_list_columns => table_varchar('ID_EPISODE',
                                                                          'ID_EPISODE_ORIGIN',
                                                                          'ID_EPISODE_DESTINATION',
                                                                          'ID_PREV_EPISODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
        ELSE
            g_error := 'OPEN C_EPISODE - i_episode_temp: ' || i_episode_temp;
            OPEN c_episode(i_episode_temp);
            FETCH c_episode
                INTO l_patient;
            CLOSE c_episode;
        
            l_episode := i_episode_temp;
        
            IF l_patient IS NULL
               OR l_episode IS NULL
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_prev_episode = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode_origin = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'UPDATE BLOOD_PRODUCT_REQ';
            ts_blood_product_req.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode_destination = ' || i_episode_temp,
                                     rows_out       => l_rows_out);
        
            g_error := 'PROCESS UPDATE BLOOD_PRODUCT_REQ';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'BLOOD_PRODUCT_REQ',
                                          i_list_columns => table_varchar('ID_PATIENT'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_MATCH',
                                              o_error);
            RETURN FALSE;
    END set_bp_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_bp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient_count NUMBER;
        l_episode_count NUMBER;
    
        l_blood_product_req table_number;
        l_blood_product_det table_number;
    
    BEGIN
    
        l_patient_count := i_patient.count;
        l_episode_count := i_episode.count;
    
        -- checks if the delete process can be executed
        IF l_patient_count = 0
           AND l_episode_count = 0
        THEN
            g_error := 'EMPTY ARRAYS FOR I_PATIENT AND I_EPISODE';
            RETURN FALSE;
        END IF;
    
        -- selects the lists of all BLOOD_PRODUCT_REQ ids to be removed
        g_error := 'BLOOD_PRODUCT_REQ BULK COLLECT ERROR';
        SELECT bpr.id_blood_product_req
          BULK COLLECT
          INTO l_blood_product_req
          FROM blood_product_req bpr
         WHERE bpr.id_episode IN (SELECT /*+ opt_estimate(table epis rows = 1)*/
                                   *
                                    FROM TABLE(i_episode) epis)
            OR (bpr.id_episode IS NULL AND
               bpr.id_patient IN (SELECT /*+ opt_estimate(table pat rows = 1)*/
                                    *
                                     FROM TABLE(i_patient) pat));
    
        -- selects the lists of all BLOOD_PRODUCT_DET ids to be removed
        g_error := 'BLOOD_PRODUCT_DET BULK COLLECT ERROR';
        SELECT bpd.id_blood_product_det
          BULK COLLECT
          INTO l_blood_product_det
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req IN (SELECT /*+ opt_estimate(table bpr rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_req) bpr);
    
        -- remove data from MCDT_REQ_DIAGNOSIS
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BLOOD_PRODUCT_DET_HIST
        g_error := 'BLOOD_PRODUCT_DET_HIST BULK COLLECT ERROR';
        DELETE FROM blood_product_det_hist bpdh
         WHERE bpdh.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                              *
                                               FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BP_QUESTION_RESPONSE_HIST
        g_error := 'BP_QUESTION_RESPONSE_HIST BULK COLLECT ERROR';
        DELETE FROM bp_question_response_hist bpqrh
         WHERE bpqrh.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                               *
                                                FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BP_QUESTION_RESPONSE
        g_error := 'BP_QUESTION_RESPONSE BULK COLLECT ERROR';
        DELETE FROM bp_question_response bpqr
         WHERE bpqr.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                              *
                                               FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BLOOD_PRODUCT_EXECUTION
        g_error := 'BLOOD_PRODUCT_EXECUTION BULK COLLECT ERROR';
        DELETE FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BLOOD_PRODUCT_ANALYSIS
        g_error := 'BLOOD_PRODUCT_ANALYSIS BULK COLLECT ERROR';
        DELETE FROM blood_product_analysis bpa
         WHERE bpa.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BLOOD_PRODUCTS_EA
        g_error := 'BLOOD_PRODUCTS_EA BULK COLLECT ERROR';
        DELETE FROM blood_products_ea bpe
         WHERE bpe.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from BLOOD_PRODUCT_DET
        g_error := 'BLOOD_PRODUCT_DET BULK COLLECT ERROR';
        DELETE FROM blood_product_det bpe
         WHERE bpe.id_blood_product_det IN (SELECT /*+ opt_estimate(table bpd rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_det) bpd);
    
        -- remove data from MCDT_REQ_DIAGNOSIS
        g_error := 'MCDT_REQ_DIAGNOSIS DELETE ERROR';
        DELETE FROM mcdt_req_diagnosis mrd
         WHERE mrd.id_blood_product_req IN (SELECT /*+ opt_estimate(table bpr rows = 1)*/
                                             *
                                              FROM TABLE(l_blood_product_req) bpr);
    
        -- remove data from BLOOD_PRODUCT_REQ
        g_error := 'BLOOD_PRODUCT_REQ DELETE ERROR';
        DELETE FROM blood_product_req
         WHERE blood_product_req.id_blood_product_req IN
               (SELECT /*+ opt_estimate(table bpr rows = 1)*/
                 *
                  FROM TABLE(l_blood_product_req) bpr);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_BP',
                                              o_error);
            RETURN FALSE;
    END reset_bp;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_bp_external;
/
