CREATE OR REPLACE PACKAGE BODY pk_blood_products_core IS

    FUNCTION create_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_hemo_type               IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number, --15
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number, --20
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --25
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2, --30
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_blood_prod_req_array    OUT NOCOPY table_number,
        o_blood_prod_det_array    OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_continue BOOLEAN := TRUE;
    
        l_patient patient.id_patient%TYPE;
    
        l_blood_product_req blood_product_req.id_blood_product_req%TYPE;
        l_blood_prod_det    blood_product_det.id_blood_product_det%TYPE;
    
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_varchar := table_varchar();
    
        l_order_recurrence         order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurrence_option  order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_array table_number := table_number();
    
        l_order_plan      t_tbl_order_recurr_plan;
        l_order_plan_aux  t_tbl_order_recurr_plan;
        l_exec_to_process t_tbl_order_recurr_plan_sts;
    
        TYPE t_order_recurr_plan_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_order_recurr_plan_map t_order_recurr_plan_map;
    
        l_count_out_reqs NUMBER := 0;
    
        TYPE t_record_bp_req_map IS TABLE OF NUMBER INDEX BY VARCHAR2(200 CHAR);
        ibt_blood_product_req_map t_record_bp_req_map;
    
    BEGIN
    
        o_blood_prod_req_array := table_number();
        o_blood_prod_det_array := table_number();
    
        IF i_episode IS NOT NULL
        THEN
            l_patient := pk_episode.get_id_patient(i_episode => i_episode);
        
            g_error := 'PATIENT / EPISODE DON''T MATCH';
            IF l_patient != i_patient
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF i_test = pk_blood_products_constant.g_yes
        THEN
            -- Verificar se o blood product já tinha sido requisitado recentemente
            g_error := 'CALL TO GET_BLOOD_PRODUCT_REQUEST';
        
            IF o_flg_show = pk_blood_products_constant.g_yes
            THEN
                l_continue := FALSE;
            END IF;
        END IF;
    
        IF l_continue
        THEN
            FOR i IN 1 .. 1
            LOOP
                IF i_order_recurrence(i) IS NOT NULL
                   AND i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                THEN
                    BEGIN
                        -- check if this order recurrence plan was already set as finished
                        l_order_recurrence := ibt_order_recurr_plan_map(i_order_recurrence(i));
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                        
                            -- set order recurrence plan as finished
                            g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                            IF NOT
                                pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                                 i_prof                    => i_prof,
                                                                                 i_order_recurr_plan       => i_order_recurrence(i),
                                                                                 o_order_recurr_option     => l_order_recurrence_option,
                                                                                 o_final_order_recurr_plan => l_order_recurrence,
                                                                                 o_error                   => o_error)
                            
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            -- add new order recurrence plan to map collection
                            ibt_order_recurr_plan_map(i_order_recurrence(i)) := l_order_recurrence;
                        
                            IF l_order_recurrence IS NOT NULL
                            THEN
                                l_order_recurr_final_array.extend;
                                l_order_recurr_final_array(l_order_recurr_final_array.count) := l_order_recurrence;
                            END IF;
                    END;
                ELSIF i_order_recurrence(i) IS NOT NULL
                      AND i_flg_origin_req = pk_alert_constant.g_task_origin_order_set
                THEN
                    l_order_recurrence := i_order_recurrence(i);
                END IF;
            
                l_clinical_question := table_number();
                IF i_clinical_question.count > 0
                   AND i_clinical_question(i).count > 0
                THEN
                    FOR j IN i_clinical_question(i).first .. i_clinical_question(i).last
                    LOOP
                        l_clinical_question.extend;
                        l_clinical_question(j) := i_clinical_question(i) (j);
                    END LOOP;
                END IF;
            
                l_response := table_varchar();
                IF i_response.count > 0
                   AND i_response(i).count > 0
                THEN
                    FOR j IN i_response(i).first .. i_response(i).last
                    LOOP
                        l_response.extend;
                        l_response(j) := i_response(i) (j);
                    END LOOP;
                END IF;
            
                l_clinical_question_notes := table_varchar();
                IF i_clinical_question_notes.count > 0
                   AND i_clinical_question_notes(i).count > 0
                THEN
                    FOR j IN i_clinical_question_notes(i).first .. i_clinical_question_notes(i).last
                    LOOP
                        l_clinical_question_notes.extend;
                        l_clinical_question_notes(j) := i_clinical_question_notes(i) (j);
                    END LOOP;
                END IF;
            
                l_blood_product_req := seq_blood_product_req.nextval;
            
                IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
                THEN
                    pk_ia_event_blood_bank.blood_product_req_new(i_id_institution       => i_prof.institution,
                                                                 i_id_blood_product_req => l_blood_product_req);
                END IF;
            
                FOR j IN 1 .. i_hemo_type.count
                LOOP
                
                    g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.CREATE_BP_REQUEST';
                    IF NOT pk_blood_products_core.create_bp_request(i_lang                    => i_lang,
                                                                    i_prof                    => i_prof,
                                                                    i_patient                 => i_patient,
                                                                    i_episode                 => i_episode,
                                                                    i_blood_product_req       => l_blood_product_req,
                                                                    i_hemo_type               => i_hemo_type(j),
                                                                    i_flg_time                => i_flg_time(j),
                                                                    i_dt_begin                => i_dt_begin(j),
                                                                    i_episode_destination     => i_episode_destination(j),
                                                                    i_order_recurrence        => l_order_recurrence,
                                                                    i_diagnosis               => i_diagnosis(j),
                                                                    i_clinical_purpose        => i_clinical_purpose(j),
                                                                    i_clinical_purpose_notes  => i_clinical_purpose_notes(j),
                                                                    i_priority                => i_priority(j),
                                                                    i_special_type            => i_special_type(j),
                                                                    i_screening               => i_screening(j),
                                                                    i_without_nat             => i_without_nat(j),
                                                                    i_not_send_unit           => i_not_send_unit(j),
                                                                    i_transf_type             => i_transf_type(j),
                                                                    i_qty_exec                => i_qty_exec(j),
                                                                    i_unit_qty_exec           => i_unit_qty_exec(j),
                                                                    i_exec_institution        => i_exec_institution(j),
                                                                    i_not_order_reason        => i_not_order_reason(j),
                                                                    i_special_instr           => i_special_instr(j),
                                                                    i_notes                   => i_notes(j),
                                                                    i_prof_order              => i_prof_order(j),
                                                                    i_dt_order                => i_dt_order(j),
                                                                    i_order_type              => i_order_type(j),
                                                                    i_health_plan             => i_health_plan(j),
                                                                    i_exemption               => i_exemption(j),
                                                                    i_clinical_question       => l_clinical_question,
                                                                    i_response                => l_response,
                                                                    i_clinical_question_notes => l_clinical_question_notes,
                                                                    i_clinical_decision_rule  => i_clinical_decision_rule(j),
                                                                    i_flg_origin_req          => i_flg_origin_req,
                                                                    i_flg_mother_lab_tests    => i_flg_mother_lab_tests,
                                                                    o_blood_prod_det          => l_blood_prod_det,
                                                                    o_error                   => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- check if exam_req not exists
                    g_error := 'OUT VARIABLES';
                    IF NOT ibt_blood_product_req_map.exists(to_char(l_blood_product_req))
                    THEN
                        o_blood_prod_req_array.extend;
                        l_count_out_reqs := l_count_out_reqs + 1;
                    
                        -- set mapping between analysis_req and its position in the output array
                        ibt_blood_product_req_map(to_char(l_blood_product_req)) := l_count_out_reqs;
                    
                        -- set analysis_req output 
                        o_blood_prod_req_array(l_count_out_reqs) := l_blood_product_req;
                    END IF;
                
                    o_blood_prod_det_array.extend;
                    o_blood_prod_det_array(o_blood_prod_det_array.count) := l_blood_prod_det;
                
                END LOOP;
                --   
            
            END LOOP;
        
            IF l_order_recurr_final_array IS NOT NULL
               OR l_order_recurr_final_array.count > 0
            THEN
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                            i_prof            => i_prof,
                                                                            i_order_plan      => l_order_recurr_final_array,
                                                                            o_order_plan_exec => l_order_plan,
                                                                            o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- removing first element (first req was already created)
                SELECT t_rec_order_recurr_plan(t.id_order_recurrence_plan, t.exec_number, t.exec_timestamp)
                  BULK COLLECT
                  INTO l_order_plan_aux
                  FROM TABLE(CAST(l_order_plan AS t_tbl_order_recurr_plan)) t
                 WHERE t.exec_number > 1;
            
                g_error := 'CALL CREATE_BP_RECURRENCE / l_order_plan_aux.count=' || l_order_plan_aux.count;
                pk_alertlog.log_info(g_error);
                IF NOT pk_blood_products_core.create_bp_recurrence(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_exec_tab        => l_order_plan_aux,
                                                                   o_exec_to_process => l_exec_to_process,
                                                                   o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
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
                                              'CREATE_BLOOD_PRODUCT_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_bp_order;

    FUNCTION create_bp_request
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE, --5
        i_hemo_type               IN blood_product_det.id_hemo_type%TYPE,
        i_flg_time                IN blood_product_req.flg_time%TYPE,
        i_dt_begin                IN VARCHAR2,
        i_episode_destination     IN episode.id_episode%TYPE,
        i_order_recurrence        IN order_recurr_plan.id_order_recurr_plan%TYPE, --10
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis,
        i_clinical_purpose        IN blood_product_det.id_clinical_purpose%TYPE,
        i_clinical_purpose_notes  IN VARCHAR2,
        i_priority                IN blood_product_det.flg_priority%TYPE,
        i_special_type            IN blood_product_det.id_special_type%TYPE,
        i_screening               IN VARCHAR2,
        i_without_nat             IN VARCHAR2,
        i_not_send_unit           IN VARCHAR2,
        i_transf_type             IN blood_product_det.transfusion_type%TYPE,
        i_qty_exec                IN blood_product_det.qty_exec%TYPE, --15
        i_unit_qty_exec           IN blood_product_det.id_unit_mea_qty_exec%TYPE,
        i_exec_institution        IN blood_product_det.id_exec_institution%TYPE,
        i_not_order_reason        IN not_order_reason.id_not_order_reason%TYPE,
        i_special_instr           IN blood_product_det.special_instr%TYPE,
        i_notes                   IN blood_product_det.notes_tech%TYPE, --20
        i_prof_order              IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order                IN VARCHAR2,
        i_order_type              IN co_sign.id_order_type%TYPE,
        i_health_plan             IN blood_product_det.id_pat_health_plan%TYPE,
        i_exemption               IN blood_product_det.id_pat_exemption%TYPE, --25
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D', --30
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_blood_prod_det          OUT blood_product_det.id_blood_product_det%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_blood_product_req IS
            SELECT bpr.id_blood_product_req
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_blood_product_req;
    
        CURSOR c_hemo_analysis(dt_begin_hemo TIMESTAMP WITH LOCAL TIME ZONE) IS
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
    
        CURSOR c_lab_test_newborn(i_epis episode.id_episode%TYPE) IS
            SELECT t.id_analysis, t.id_sample_type
              FROM (WITH analysis AS (SELECT DISTINCT ard.id_analysis, ard.id_sample_type, lte.dt_target
                                        FROM analysis_req ar
                                        JOIN analysis_req_det ard
                                          ON ard.id_analysis_req = ar.id_analysis_req
                                        JOIN lab_tests_ea lte
                                          ON lte.id_analysis_req_det = ard.id_analysis_req_det
                                       WHERE ar.id_episode = i_epis
                                         AND ard.flg_status NOT IN
                                             (pk_lab_tests_constant.g_analysis_cancel,
                                              pk_lab_tests_constant.g_analysis_predefined,
                                              pk_lab_tests_constant.g_analysis_draft))
                       SELECT hta.id_analysis, hta.id_sample_type
                         FROM hemo_type_analysis hta
                         LEFT JOIN analysis a
                           ON hta.id_analysis = a.id_analysis
                          AND hta.id_sample_type = a.id_sample_type
                        WHERE hta.id_hemo_type = i_hemo_type
                          AND hta.flg_newborn = pk_alert_constant.g_yes
                          AND hta.id_institution = i_prof.institution
                          AND hta.flg_available = pk_alert_constant.g_yes
                          AND (a.id_analysis IS NULL OR
                              ((hta.time_req IS NOT NULL AND hta.unit_time_req IS NOT NULL) AND
                              pk_date_utils.add_to_ltstz(i_timestamp => a.dt_target,
                                                           i_amount    => hta.time_req,
                                                           i_unit      => hta.unit_time_req) <= current_timestamp))) t;
    
    
        l_next_req        blood_product_req.id_blood_product_req%TYPE;
        l_next_det        blood_product_det.id_blood_product_det%TYPE;
        l_status          blood_product_req.flg_status%TYPE;
        l_status_det      blood_product_det.flg_status%TYPE;
        l_dt_req          blood_product_req.dt_req_tstz%TYPE;
        l_dt_begin        blood_product_req.dt_begin_tstz%TYPE;
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_id_patient_mother patient.id_patient%TYPE;
        l_visit_mother      visit.id_visit%TYPE;
        l_epis_mother       episode.id_episode%TYPE;
        l_num_exec          blood_product_execution.exec_number%TYPE;
    
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
    
        l_patient_age PLS_INTEGER; --Patient age in days 
    
        l_flg_req_without_crossmatch  VARCHAR2(1);
        l_blood_crossmatch_popup_show sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_CROSSMATCH_POPUP_SHOW',
                                                                                       i_prof);
        l_prof_crossmatch             blood_product_det.id_prof_crossmatch%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_req        := g_sysdate_tstz;
        l_dt_begin      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_harvest_state := pk_alert_constant.g_no;
    
        IF i_unit_qty_exec = pk_blood_products_constant.g_bp_unit_ml
        THEN
            l_qty_exec := i_qty_exec;
        ELSE
            l_qty_exec := i_qty_exec * l_volume_default;
        END IF;
    
        IF i_flg_time != pk_blood_products_constant.g_flg_time_e
        THEN
            -- realização futura
            l_status     := pk_blood_products_constant.g_status_req_p;
            l_status_det := pk_blood_products_constant.g_status_det_r_sc;
            l_dt_begin   := NULL;
        ELSE
            IF nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
            THEN
                -- pendente
                l_status     := pk_blood_products_constant.g_status_req_p;
                l_status_det := pk_blood_products_constant.g_status_det_r_sc;
            ELSE
                l_dt_begin   := g_sysdate_tstz;
                l_status     := pk_blood_products_constant.g_status_req_r;
                l_status_det := pk_blood_products_constant.g_status_det_r_sc;
            END IF;
        END IF;
    
        IF i_flg_origin_req = pk_alert_constant.g_task_origin_order_set
        THEN
            l_status     := pk_blood_products_constant.g_status_req_pd;
            l_status_det := pk_blood_products_constant.g_status_det_pd;
        ELSIF i_flg_origin_req = pk_alert_constant.g_task_origin_cpoe
        THEN
            l_status     := pk_blood_products_constant.g_status_req_df;
            l_status_det := pk_blood_products_constant.g_status_det_df;
        
            l_dt_req := NULL;
        END IF;
    
        IF i_not_order_reason IS NOT NULL
        THEN
            l_status     := pk_blood_products_constant.g_status_req_n;
            l_status_det := pk_blood_products_constant.g_status_det_n;
        
            g_error := 'CALL TO PK_NOT_ORDER_REASON_DB.SET_NOT_ORDER_REASON';
            IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_not_order_reason_ea => i_not_order_reason,
                                                               o_id_not_order_reason => l_not_order_reason,
                                                               o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        OPEN c_blood_product_req;
        FETCH c_blood_product_req
            INTO l_next_req;
        g_found := c_blood_product_req%FOUND;
        CLOSE c_blood_product_req;
    
        IF NOT g_found
        THEN
            ts_blood_product_req.ins(id_blood_product_req_in   => i_blood_product_req,
                                     id_episode_in             => CASE
                                                                      WHEN i_flg_time = pk_blood_products_constant.g_flg_time_e THEN
                                                                       i_episode
                                                                      ELSE
                                                                       NULL
                                                                  END,
                                     id_professional_in        => i_prof.id,
                                     id_institution_in         => i_prof.institution,
                                     flg_time_in               => i_flg_time,
                                     flg_status_in             => l_status,
                                     id_episode_origin_in      => CASE
                                                                      WHEN i_flg_time = pk_blood_products_constant.g_flg_time_e THEN
                                                                       NULL
                                                                      ELSE
                                                                       i_episode
                                                                  END,
                                     id_episode_destination_in => CASE
                                                                      WHEN i_flg_time = pk_blood_products_constant.g_flg_time_n THEN
                                                                       i_episode_destination
                                                                      ELSE
                                                                       NULL
                                                                  END,
                                     dt_req_tstz_in            => l_dt_req,
                                     dt_begin_tstz_in          => l_dt_begin,
                                     id_patient_in             => i_patient,
                                     rows_out                  => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
    
        l_next_det := seq_blood_product_det.nextval;
    
        IF i_order_type IS NOT NULL
        THEN
            g_error := 'CALL PK_CO_SIGN_API.SET_PENDING_CO_SIGN_TASK';
            IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_episode,
                                                           i_id_task_type           => pk_blood_products_constant.g_task_type_bp,
                                                           i_cosign_def_action_type => pk_co_sign_api.g_cosign_action_def_add,
                                                           i_id_task                => l_next_det,
                                                           i_id_task_group          => l_next_det,
                                                           i_id_order_type          => i_order_type,
                                                           i_id_prof_created        => i_prof.id,
                                                           i_id_prof_ordered_by     => i_prof_order,
                                                           i_dt_created             => g_sysdate_tstz,
                                                           i_dt_ordered_by          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_dt_order,
                                                                                                                     NULL),
                                                           o_id_co_sign             => l_id_co_sign,
                                                           o_id_co_sign_hist        => l_id_co_sign_hist,
                                                           o_error                  => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF l_blood_crossmatch_popup_show = pk_alert_constant.g_yes
           AND
           i_priority IN
           ( /*pk_blood_products_constant.g_flg_priority_urgent,*/ pk_blood_products_constant.g_flg_priority_emergency)
        THEN
            l_flg_req_without_crossmatch := pk_alert_constant.g_yes;
            l_prof_crossmatch            := i_prof.id;
        ELSE
            l_flg_req_without_crossmatch := pk_alert_constant.g_no;
            l_prof_crossmatch            := NULL;
        END IF;
    
        ts_blood_product_det.ins(id_blood_product_det_in       => l_next_det,
                                 id_blood_product_req_in       => i_blood_product_req,
                                 id_hemo_type_in               => i_hemo_type,
                                 flg_status_in                 => l_status_det,
                                 notes_tech_in                 => i_notes,
                                 flg_priority_in               => i_priority,
                                 id_special_type_in            => i_special_type,
                                 flg_with_screening_in         => i_screening,
                                 flg_without_nat_test_in       => i_without_nat,
                                 flg_prepare_not_send_in       => i_not_send_unit,
                                 dt_begin_tstz_in              => l_dt_begin,
                                 id_exec_institution_in        => i_exec_institution,
                                 id_not_order_reason_in        => i_not_order_reason,
                                 id_co_sign_order_in           => l_id_co_sign,
                                 id_order_recurrence_in        => i_order_recurrence,
                                 id_clinical_purpose_in        => i_clinical_purpose,
                                 clinical_purpose_notes_in     => i_clinical_purpose_notes,
                                 transfusion_type_in           => i_transf_type,
                                 qty_exec_in                   => l_qty_exec,
                                 id_unit_mea_qty_exec_in       => pk_blood_products_constant.g_bp_unit_ml,
                                 special_instr_in              => i_special_instr,
                                 id_pat_health_plan_in         => i_health_plan,
                                 id_pat_exemption_in           => i_exemption,
                                 flg_req_origin_module_in      => i_flg_origin_req,
                                 flg_req_without_crossmatch_in => l_flg_req_without_crossmatch,
                                 id_prof_crossmatch_in         => l_prof_crossmatch,
                                 rows_out                      => l_rows_out);
    
        l_sys_alert_event.id_sys_alert   := 336;
        l_sys_alert_event.id_software    := i_prof.software;
        l_sys_alert_event.id_institution := i_prof.institution;
        l_sys_alert_event.id_episode     := i_episode;
        l_sys_alert_event.id_patient     := i_patient;
        l_sys_alert_event.id_record      := l_next_det;
        l_sys_alert_event.id_visit       := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
        l_sys_alert_event.dt_record      := current_timestamp;
        l_sys_alert_event.id_prof_order  := i_prof.id;
    
        g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT';
    
        IF l_status_det != pk_blood_products_constant.g_status_det_pd
        THEN
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            pk_ia_event_blood_bank.blood_product_det_new(i_id_institution       => i_prof.institution,
                                                         i_id_blood_product_det => l_next_det);
        END IF;
    
        g_error := 'CALL PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        OPEN c_hemo_analysis(l_dt_begin);
        FETCH c_hemo_analysis BULK COLLECT
            INTO l_hemo_analysis_req_det,
                 l_hemo_id_analysis,
                 l_hemo_id_sample_type,
                 l_hemo_flg_analysis,
                 l_hemo_flg_collected;
        CLOSE c_hemo_analysis;
    
        IF l_status_det NOT IN (pk_blood_products_constant.g_status_req_df, pk_blood_products_constant.g_status_req_pd)
        THEN
        
            l_rapid_crossmatching_tbl := pk_string_utils.str_split(i_list => l_rapid_crossmatching, i_delim => '|');
        
            IF l_rapid_crossmatching_tbl IS NOT NULL
               AND l_rapid_crossmatching_tbl.count > 0
               AND i_priority = pk_blood_products_constant.g_flg_priority_urgent
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
                                                                         i_patient                 => i_patient,
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
                                                                         i_priority                => table_varchar(i_priority),
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
                                                                         i_diagnosis               => pk_edis_types.table_in_epis_diagnosis(i_diagnosis),
                                                                         i_exec_institution        => table_number(NULL),
                                                                         i_clinical_purpose        => table_number(i_clinical_purpose),
                                                                         i_clinical_purpose_notes  => table_varchar(i_clinical_purpose_notes),
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
    
        IF i_flg_mother_lab_tests = pk_alert_constant.g_yes
        THEN
            l_hemo_id_analysis    := table_number();
            l_hemo_id_sample_type := table_number();
        
            --Get patient id of mother   
            BEGIN
                SELECT p.id_patient
                  INTO l_id_patient_mother
                  FROM patient p
                  LEFT JOIN pat_family_member pfm
                    ON p.id_patient = pfm.id_pat_related
                   AND (pfm.id_patient = i_patient OR pfm.id_pat_related = i_patient OR pfm.id_pat_related IS NULL)
                   AND pfm.flg_status = 'A'
                  LEFT JOIN family_relationship fr
                    ON pfm.id_family_relationship = fr.id_family_relationship
                 WHERE fr.id_family_relationship = 2;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_patient_mother := NULL;
            END;
        
            IF l_id_patient_mother IS NOT NULL
            THEN
                g_error := 'CALL PK_VISIT.GET_ACTIVE_VIS_EPIS';
                IF NOT pk_visit.get_active_vis_epis(i_lang           => i_lang,
                                                    i_id_pat         => l_id_patient_mother,
                                                    i_id_institution => i_prof.institution,
                                                    i_prof           => i_prof,
                                                    o_id_visit       => l_visit_mother,
                                                    o_id_episode     => l_epis_mother,
                                                    o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF l_epis_mother IS NOT NULL
                THEN
                
                    OPEN c_lab_test_newborn(l_epis_mother);
                    FETCH c_lab_test_newborn BULK COLLECT
                        INTO l_hemo_id_analysis, l_hemo_id_sample_type;
                    CLOSE c_lab_test_newborn;
                
                    IF l_status_det NOT IN
                       (pk_blood_products_constant.g_status_req_df, pk_blood_products_constant.g_status_req_pd)
                    THEN
                        IF l_hemo_id_analysis IS NOT NULL
                           AND l_hemo_id_analysis.count > 0
                        THEN
                            FOR i IN l_hemo_id_analysis.first .. l_hemo_id_analysis.last
                            LOOP
                                g_error := 'CALL PK_LAB_TESTS_API_DB.CREATE_LAB_TEST_ORDER';
                                IF NOT
                                    pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                                              i_prof                    => i_prof,
                                                                              i_patient                 => l_id_patient_mother,
                                                                              i_episode                 => l_epis_mother,
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
                                                                              i_priority                => table_varchar(i_priority),
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
                                                                              i_clinical_purpose        => table_number(i_clinical_purpose),
                                                                              i_clinical_purpose_notes  => table_varchar(i_clinical_purpose_notes),
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
                                FOR j IN l_analysis_req_det.first .. l_analysis_req_det.last
                                LOOP
                                    g_error := 'UPDATING BLOOD_PRODUCT_EXECUTION WITH MOTHER''S LAB TEST ID';
                                    SELECT COUNT(*)
                                      INTO l_num_exec
                                      FROM blood_product_execution bpe
                                     WHERE bpe.id_blood_product_det = l_next_det;
                                
                                    ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                                                   id_blood_product_det_in       => l_next_det,
                                                                   action_in                     => pk_blood_products_constant.g_bp_action_lab_mother_id,
                                                                   id_prof_performed_in          => i_prof.id,
                                                                   dt_execution_in               => g_sysdate_tstz,
                                                                   exec_number_in                => l_num_exec + 1,
                                                                   id_professional_in            => i_prof.id,
                                                                   dt_bp_execution_tstz_in       => g_sysdate_tstz,
                                                                   flg_lab_mother_in             => i_flg_mother_lab_tests,
                                                                   id_analysis_req_det_in        => l_analysis_req_det(j),
                                                                   rows_out                      => l_rows_out);
                                END LOOP;
                            END LOOP;
                        
                            g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_LAB_MOTHER';
                            IF NOT pk_blood_products_core.set_bp_lab_mother(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_blood_product_det => l_next_det,
                                                                            i_flg_lab_mother    => i_flg_mother_lab_tests,
                                                                            o_error             => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
        ELSIF i_flg_mother_lab_tests = pk_alert_constant.g_no
        THEN
            l_patient_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => NULL,
                                                    i_dt_deceased => NULL,
                                                    i_age         => NULL,
                                                    i_age_format  => 'DAYS',
                                                    i_patient     => i_patient);
        
            IF l_patient_age <= pk_blood_products_constant.g_bp_newborn_age_limit
            THEN
                g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_LAB_MOTHER';
                IF NOT pk_blood_products_core.set_bp_lab_mother(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_blood_product_det => l_next_det,
                                                                i_flg_lab_mother    => i_flg_mother_lab_tests,
                                                                o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => l_status_det,
                                    i_id_record  => l_next_det,
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        o_blood_prod_det := l_next_det;
    
        IF i_clinical_question.count != 0
        THEN
            FOR i IN 1 .. i_clinical_question.count
            LOOP
                IF i_clinical_question(i) IS NOT NULL
                THEN
                    IF i_response(i) IS NOT NULL
                    THEN
                        l_aux := pk_utils.str_split(i_response(i), '|');
                    
                        FOR j IN 1 .. l_aux.count
                        LOOP
                            g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                            INSERT INTO bp_question_response
                                (id_bp_question_response,
                                 id_episode,
                                 id_blood_product_det,
                                 flg_time,
                                 id_questionnaire,
                                 id_response,
                                 notes,
                                 id_prof_last_update,
                                 dt_last_update_tstz)
                            VALUES
                                (seq_bp_question_response.nextval,
                                 i_episode,
                                 l_next_det,
                                 pk_blood_products_constant.g_bp_cq_on_order,
                                 i_clinical_question(i),
                                 to_number(l_aux(j)),
                                 i_clinical_question_notes(i),
                                 i_prof.id,
                                 g_sysdate_tstz);
                        END LOOP;
                    ELSE
                        g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                        INSERT INTO bp_question_response
                            (id_bp_question_response,
                             id_episode,
                             id_blood_product_det,
                             flg_time,
                             id_questionnaire,
                             id_response,
                             notes,
                             id_prof_last_update,
                             dt_last_update_tstz)
                        VALUES
                            (seq_bp_question_response.nextval,
                             i_episode,
                             l_next_det,
                             pk_blood_products_constant.g_bp_cq_on_order,
                             i_clinical_question(i),
                             NULL,
                             i_clinical_question_notes(i),
                             i_prof.id,
                             g_sysdate_tstz);
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            IF i_diagnosis.tbl_diagnosis IS NOT NULL
               AND i_diagnosis.tbl_diagnosis.count != 0
            THEN
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
                                                                i_blood_product_req => i_blood_product_req,
                                                                i_blood_product_det => l_next_det,
                                                                o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            IF l_status != pk_blood_products_constant.g_status_det_df
               AND i_flg_time != pk_blood_products_constant.g_flg_time_n
            THEN
                g_error := 'CALL PK_CPOE.SYNC_TASK';
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_episode,
                                         i_task_type            => pk_blood_products_constant.g_task_type_cpoe_bp,
                                         i_task_request         => l_next_det,
                                         i_task_start_timestamp => l_dt_begin,
                                         o_error                => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => i_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
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
                                              'CREATE_BP_REQUEST',
                                              o_error);
            RETURN FALSE;
    END create_bp_request;

    FUNCTION create_bp_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT DISTINCT v.flg_status
              FROM blood_product_req bpr
              JOIN blood_product_det bpd
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
              JOIN episode e
                ON e.id_episode = bpr.id_episode
              JOIN visit v
                ON e.id_visit = v.id_visit
             WHERE v.flg_status = pk_visit.g_active
               AND bpd.id_order_recurrence IN
                   (SELECT /*+opt_estimate(table o rows=1)*/
                    DISTINCT o.id_order_recurrence_plan
                      FROM TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) o)
               AND NOT (bpr.flg_time = pk_blood_products_constant.g_flg_time_b)
               AND bpd.flg_status != pk_blood_products_constant.g_status_req_c;
    
        -- get all order_plan info and one id_exam_req associated to this plan
        CURSOR c_blood_product(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT /*+opt_estimate(table t rows=1)*/
             t.id_order_recurrence_plan, t.exec_number, t.exec_timestamp, r.id_blood_product_req
              FROM TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t,
                   (SELECT DISTINCT id_blood_product_req, id_order_recurrence
                      FROM (SELECT bpr.id_blood_product_req,
                                   bpd.id_order_recurrence,
                                   row_number() over(PARTITION BY bpd.id_hemo_type ORDER BY bpr.dt_begin_tstz DESC NULLS LAST) rn
                              FROM blood_product_req bpr
                              JOIN blood_product_det bpd
                                ON bpr.id_blood_product_req = bpd.id_blood_product_req
                             WHERE bpd.id_order_recurrence IN
                                   (SELECT /*+opt_estimate(table o rows=1)*/
                                    DISTINCT o.id_order_recurrence_plan
                                      FROM TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) o)
                               AND NOT bpr.flg_time = pk_blood_products_constant.g_flg_time_b
                               AND bpr.flg_status != pk_blood_products_constant.g_status_req_c)
                     WHERE rn = 1) r
             WHERE t.id_order_recurrence_plan = r.id_order_recurrence(+);
    
        TYPE t_blood_product IS TABLE OF c_blood_product%ROWTYPE;
        l_blood_product_tab t_blood_product;
    
        l_prev_bp_req blood_product_req.id_blood_product_req%TYPE;
        CURSOR c_bp_req(x_id_bp_req IN blood_product_req.id_blood_product_req%TYPE) IS
            SELECT *
              FROM blood_product_req
             WHERE id_blood_product_req = x_id_bp_req;
        l_bp_req_data blood_product_req%ROWTYPE;
    
        CURSOR c_bp_req_det(x_id_bp_req IN blood_product_det.id_blood_product_req%TYPE) IS
            SELECT *
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = x_id_bp_req;
    
        TYPE t_bp_req_det IS TABLE OF c_bp_req_det%ROWTYPE;
        l_bp_req_det_data t_bp_req_det;
    
        CURSOR c_diagnosis_list(l_bp_req_det blood_product_det.id_blood_product_det%TYPE) IS
            SELECT mrd.id_diagnosis, ed.desc_epis_diagnosis desc_diagnosis
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed
             WHERE mrd.id_blood_product_det = l_bp_req_det
               AND nvl(mrd.flg_status, '@') != pk_blood_products_constant.g_status_req_c
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        CURSOR c_hemo_analysis
        (
            dt_begin_hemo TIMESTAMP WITH LOCAL TIME ZONE,
            l_hemo_type   hemo_type.id_hemo_type%TYPE,
            l_episode     episode.id_episode%TYPE
        ) IS
            SELECT b.id_analysis, b.id_sample_type
              FROM hemo_type_analysis a
              JOIN lab_tests_ea b
                ON a.id_analysis = b.id_analysis
               AND a.id_sample_type = b.id_sample_type
             WHERE b.id_institution = i_prof.institution
               AND a.id_hemo_type = l_hemo_type
               AND b.id_episode = l_episode
               AND a.flg_available = pk_alert_constant.g_yes
               AND pk_date_utils.add_to_ltstz(i_timestamp => b.dt_target,
                                              i_amount    => a.time_req,
                                              i_unit      => a.unit_time_req) <= dt_begin_hemo;
    
        l_prof profissional;
    
        l_req_analysis_id    table_number;
        l_req_sample_type_id table_number;
    
        l_exec_to_process t_tbl_order_recurr_plan_sts;
    
        l_id_bp_req blood_product_req.id_blood_product_req%TYPE;
    
        l_status_visit visit.flg_status%TYPE;
    
        l_prof_order co_sign.id_prof_ordered_by%TYPE;
        l_dt_order   VARCHAR2(200 CHAR);
        l_order_type co_sign.id_order_type%TYPE;
    
        l_diagnosis      table_number := table_number();
        l_diagnosis_desc table_varchar := table_varchar();
    
        l_blood_prod_det blood_product_det.id_blood_product_det%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        l_exec_to_process := t_tbl_order_recurr_plan_sts();
    
        OPEN c_visit(i_exec_tab);
        FETCH c_visit
            INTO l_status_visit;
        CLOSE c_visit;
    
        IF l_status_visit != pk_visit.g_active
        THEN
            RETURN TRUE;
        END IF;
    
        OPEN c_blood_product(i_exec_tab);
        FETCH c_blood_product BULK COLLECT
            INTO l_blood_product_tab;
        CLOSE c_blood_product;
    
        <<exec>>
        FOR exec_idx IN 1 .. l_blood_product_tab.count
        LOOP
            IF l_blood_product_tab(exec_idx).id_blood_product_req IS NULL
            THEN
            
                -- plan outdated
                g_error := 'Plan ' || l_blood_product_tab(exec_idx).id_order_recurrence_plan || ' outdated';
                pk_alertlog.log_info(g_error);
            
                g_error := 'l_exec_to_process 1';
                l_exec_to_process.extend;
                l_exec_to_process(l_exec_to_process.count) := t_rec_order_recurr_plan_sts(l_blood_product_tab(exec_idx).id_order_recurrence_plan,
                                                                                          pk_blood_products_constant.g_no);
            ELSE
                IF l_prev_bp_req IS NULL
                   OR l_prev_bp_req != l_blood_product_tab(exec_idx).id_blood_product_req
                THEN
                    l_bp_req_data     := NULL;
                    l_bp_req_det_data := NULL;
                
                    -- getting exam_req info
                    g_error := 'OPEN c_exam_req(' || l_blood_product_tab(exec_idx).id_blood_product_req || ')';
                    OPEN c_bp_req(l_blood_product_tab(exec_idx).id_blood_product_req);
                    FETCH c_bp_req
                        INTO l_bp_req_data;
                    CLOSE c_bp_req;
                
                    -- getting exam_req_det info
                    g_error := 'OPEN c_exam_req_det(' || l_blood_product_tab(exec_idx).id_blood_product_req || ')';
                    OPEN c_bp_req_det(l_blood_product_tab(exec_idx).id_blood_product_req);
                    FETCH c_bp_req_det BULK COLLECT
                        INTO l_bp_req_det_data;
                    CLOSE c_bp_req_det;
                END IF;
            
                g_error := 'GET L_ID_EXAM_REQ / ID_EXAM_REQ=' || l_blood_product_tab(exec_idx).id_blood_product_req;
                pk_alertlog.log_info(g_error);
                l_id_bp_req := seq_blood_product_req.nextval();
            
                <<req_det>>
                FOR req_det_idx IN 1 .. l_bp_req_det_data.count
                LOOP
                
                    IF l_blood_product_tab(exec_idx).id_order_recurrence_plan = l_bp_req_det_data(req_det_idx).id_order_recurrence
                    THEN
                        IF i_prof.id IS NULL
                        THEN
                            l_prof := profissional(l_bp_req_data.id_professional, i_prof.institution, NULL);
                        
                            IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                                                   i_prof        => l_prof,
                                                                   i_id_episode  => l_bp_req_data.id_episode,
                                                                   o_id_software => l_prof.software,
                                                                   o_error       => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    
                        IF l_diagnosis IS NULL
                           OR l_diagnosis.count = 0
                        THEN
                            FOR l_diagnosis_list IN c_diagnosis_list(l_bp_req_det_data(req_det_idx).id_blood_product_det)
                            LOOP
                                l_diagnosis.extend;
                                l_diagnosis(l_diagnosis.count) := l_diagnosis_list.id_diagnosis;
                            
                                l_diagnosis_desc.extend;
                                l_diagnosis_desc(l_diagnosis.count) := l_diagnosis_list.desc_diagnosis;
                            END LOOP;
                        END IF;
                    
                        IF l_bp_req_det_data(req_det_idx).id_co_sign_order IS NOT NULL
                        THEN
                            SELECT cs.id_prof_ordered_by,
                                   pk_date_utils.date_send_tsz(i_lang,
                                                                cs.dt_ordered_by,
                                                                CASE
                                                                    WHEN i_prof.id IS NULL THEN
                                                                     l_prof
                                                                    ELSE
                                                                     i_prof
                                                                END),
                                   cs.id_order_type
                              INTO l_prof_order, l_dt_order, l_order_type
                              FROM TABLE(pk_co_sign_api.tf_co_sign_tasks_info(i_lang,
                                                                               CASE
                                                                                   WHEN i_prof.id IS NULL THEN
                                                                                    l_prof
                                                                                   ELSE
                                                                                    i_prof
                                                                               END,
                                                                               l_bp_req_data.id_episode,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               l_bp_req_det_data(req_det_idx).id_blood_product_det)) cs
                             WHERE cs.id_co_sign_hist = l_bp_req_det_data(req_det_idx).id_co_sign_order;
                        END IF;
                    
                        IF NOT pk_blood_products_core.create_bp_request(i_lang                    => i_lang,
                                                                   i_prof                    => CASE
                                                                                                    WHEN i_prof.id IS NULL THEN
                                                                                                     l_prof
                                                                                                    ELSE
                                                                                                     i_prof
                                                                                                END,
                                                                   i_patient                 => l_bp_req_data.id_patient,
                                                                   i_episode                 => CASE
                                                                                                    WHEN l_bp_req_data.flg_time =
                                                                                                         pk_blood_products_constant.g_flg_time_e THEN
                                                                                                     l_bp_req_data.id_episode
                                                                                                    ELSE
                                                                                                     l_bp_req_data.id_episode_origin
                                                                                                END,
                                                                   i_blood_product_req       => l_id_bp_req,
                                                                   i_hemo_type               => l_bp_req_det_data(req_det_idx).id_hemo_type,
                                                                   i_flg_time                => l_bp_req_data.flg_time,
                                                                   i_dt_begin                => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                            l_blood_product_tab(exec_idx).exec_timestamp,
                                                                                                                            i_prof),
                                                                   i_episode_destination     => l_bp_req_data.id_episode_destination,
                                                                   i_order_recurrence        => l_blood_product_tab(exec_idx).id_order_recurrence_plan,
                                                                   i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                                                                                          i_prof      => i_prof,
                                                                                                                          i_patient   => l_bp_req_data.id_patient,
                                                                                                                          i_episode   => l_bp_req_data.id_episode,
                                                                                                                          i_diagnosis => l_diagnosis,
                                                                                                                          i_desc_diag => l_diagnosis_desc),
                                                                   i_clinical_purpose        => l_bp_req_det_data(req_det_idx).id_clinical_purpose,
                                                                   i_clinical_purpose_notes  => l_bp_req_det_data(req_det_idx).clinical_purpose_notes,
                                                                   i_priority                => l_bp_req_det_data(req_det_idx).flg_priority,
                                                                   i_special_type            => l_bp_req_det_data(req_det_idx).id_special_type,
                                                                   i_screening               => l_bp_req_det_data(req_det_idx).flg_with_screening,
                                                                   i_without_nat             => l_bp_req_det_data(req_det_idx).flg_without_nat_test,
                                                                   i_not_send_unit           => l_bp_req_det_data(req_det_idx).flg_prepare_not_send,
                                                                   i_transf_type             => l_bp_req_det_data(req_det_idx).transfusion_type,
                                                                   i_qty_exec                => l_bp_req_det_data(req_det_idx).qty_exec,
                                                                   i_unit_qty_exec           => l_bp_req_det_data(req_det_idx).id_unit_mea_qty_exec,
                                                                   i_exec_institution        => l_bp_req_det_data(req_det_idx).id_exec_institution,
                                                                   i_not_order_reason        => NULL,
                                                                   i_special_instr           => l_bp_req_det_data(req_det_idx).special_instr,
                                                                   i_notes                   => l_bp_req_det_data(req_det_idx).notes_tech,
                                                                   i_prof_order              => l_prof_order,
                                                                   i_dt_order                => l_dt_order,
                                                                   i_order_type              => l_order_type,
                                                                   i_health_plan             => l_bp_req_det_data(req_det_idx).id_pat_health_plan,
                                                                   i_exemption               => l_bp_req_det_data(req_det_idx).id_pat_exemption,
                                                                   i_clinical_question       => table_number(NULL),
                                                                   i_response                => table_varchar(NULL),
                                                                   i_clinical_question_notes => table_varchar(NULL),
                                                                   i_clinical_decision_rule  => NULL,
                                                                   o_blood_prod_det          => l_blood_prod_det,
                                                                   o_error                   => o_error)
                        
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        OPEN c_hemo_analysis(dt_begin_hemo => l_blood_product_tab(exec_idx).exec_timestamp,
                                             l_hemo_type   => l_bp_req_det_data(req_det_idx).id_hemo_type,
                                             l_episode     => CASE
                                                                  WHEN l_bp_req_data.flg_time = pk_blood_products_constant.g_flg_time_e THEN
                                                                   l_bp_req_data.id_episode
                                                                  ELSE
                                                                   l_bp_req_data.id_episode_origin
                                                              END);
                        FETCH c_hemo_analysis BULK COLLECT
                            INTO l_req_analysis_id, l_req_sample_type_id;
                        CLOSE c_hemo_analysis;
                    
                        IF l_req_analysis_id IS NOT NULL
                           AND l_req_analysis_id.count > 0
                        THEN
                            NULL;
                        END IF;
                    
                        g_error := 'UPDATE EXAM_REQ_DET';
                        ts_blood_product_det.upd(id_blood_product_det_in  => l_blood_prod_det,
                                                 flg_req_origin_module_in => l_bp_req_det_data(req_det_idx).flg_req_origin_module,
                                                 rows_out                 => l_rows_out);
                    
                    END IF;
                END LOOP req_det;
            END IF;
        END LOOP exec;
    
        g_error := 'CALL TO PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        -- removing duplicates
        g_error := 'O_EXEC_TO_PROCESS';
        SELECT t_rec_order_recurr_plan_sts(id_order_recurrence_plan, flg_status)
          BULK COLLECT
          INTO o_exec_to_process
          FROM (SELECT DISTINCT t.id_order_recurrence_plan, t.flg_status
                  FROM TABLE(CAST(l_exec_to_process AS t_tbl_order_recurr_plan_sts)) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_BP_RECURRENCE',
                                              o_error);
            RETURN FALSE;
    END create_bp_recurrence;

    FUNCTION set_bp_component_add
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type         IN hemo_type.id_hemo_type%TYPE,
        i_qty_exec          IN blood_product_det.qty_exec%TYPE,
        i_unit_mea          IN blood_product_det.id_unit_mea_qty_exec%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_det blood_product_det%ROWTYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        l_bp_det.id_blood_product_det := seq_blood_product_det.nextval;
        l_bp_det.id_blood_product_req := i_blood_product_req;
        l_bp_det.qty_exec             := i_qty_exec;
        l_bp_det.id_unit_mea_qty_exec := pk_blood_products_constant.g_bp_unit_ml;
        l_bp_det.flg_status           := pk_blood_products_constant.g_status_det_r_sc;
    
        ts_blood_product_det.ins(rec_in => l_bp_det, rows_out => l_rows_out);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_COMPONENT_ADD',
                                              o_error);
            RETURN FALSE;
    END set_bp_component_add;

    FUNCTION set_bp_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_req  IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type          IN hemo_type.id_hemo_type%TYPE,
        i_barcode            IN VARCHAR2,
        i_qty_rec            IN NUMBER,
        i_unit_mea           IN NUMBER,
        i_expiration_date    IN VARCHAR2,
        i_blood_group        IN VARCHAR2,
        i_blood_group_rh     IN VARCHAR2,
        i_desc_hemo_type_lab IN VARCHAR2,
        i_donation_code      IN VARCHAR2,
        i_flg_interface      IN VARCHAR2 DEFAULT 'N',
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_blood_product_det IS
            SELECT *
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = i_blood_product_req
               AND bpd.id_hemo_type = i_hemo_type
               AND bpd.qty_received IS NULL;
    
        l_bp_det c_blood_product_det%ROWTYPE;
    
        l_bp_det_status blood_product_det.flg_status%TYPE;
        l_bp_det_id     blood_product_det.id_blood_product_det%TYPE;
    
        l_qty_ask  blood_product_det.qty_exec%TYPE;
        l_qty_rec  blood_product_det.qty_received%TYPE;
        l_qty_miss blood_product_det.qty_received%TYPE;
        l_qty_over blood_product_det.qty_received%TYPE;
    
        l_volume_default sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                          i_code_cf => 'BLOOD_PRODUCT_UNIT_VOL');
    
        l_divide_bag sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                      i_code_cf => 'BLOOD_PRODUCT_FRACTIONED_BAG');
    
        l_exec_number NUMBER := 0;
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT bpr.id_episode, bpr.id_patient
          INTO l_id_episode, l_id_patient
          FROM blood_product_req bpr
         WHERE bpr.id_blood_product_req = i_blood_product_req;
    
        l_qty_over := 0;
    
        IF i_unit_mea = pk_blood_products_constant.g_bp_unit_ml
        THEN
            l_qty_rec := nvl(i_qty_rec, 0);
        ELSE
            l_qty_rec := nvl(i_qty_rec * l_volume_default, 0);
        END IF;
    
        OPEN c_blood_product_det;
        FETCH c_blood_product_det
            INTO l_bp_det;
        CLOSE c_blood_product_det;
    
        IF l_bp_det.id_blood_product_det IS NOT NULL
        THEN
        
            l_bp_det_status := l_bp_det.flg_status;
            l_bp_det_id     := l_bp_det.id_blood_product_det;
        
            l_qty_ask  := nvl(l_bp_det.qty_exec, 0);
            l_qty_miss := l_qty_ask - nvl(l_qty_rec, 0);
        
            IF l_qty_miss < 0
               AND l_qty_rec > to_number(l_volume_default)
            THEN
                l_qty_over := l_qty_rec - to_number(l_volume_default);
                l_qty_miss := 0;
            ELSIF l_qty_miss < 0
            THEN
                l_qty_miss := 0;
            END IF;
        
            ts_blood_product_det.upd(id_blood_product_det_in     => l_bp_det.id_blood_product_det,
                                     flg_status_in               => CASE
                                                                        WHEN l_bp_det.flg_prepare_not_send =
                                                                             pk_alert_constant.g_yes THEN
                                                                         pk_blood_products_constant.g_status_det_wt
                                                                        ELSE
                                                                         pk_blood_products_constant.g_status_det_ns
                                                                    END,
                                     barcode_lab_in              => i_barcode,
                                     qty_received_in             => CASE
                                                                        WHEN l_divide_bag = pk_alert_constant.g_no THEN
                                                                         l_qty_rec
                                                                        WHEN l_qty_over = 0 THEN
                                                                         l_qty_rec
                                                                        WHEN l_qty_over > 0
                                                                             AND l_qty_rec > to_number(l_volume_default) THEN
                                                                         l_volume_default
                                                                        ELSE
                                                                         l_qty_ask
                                                                    END,
                                     id_unit_mea_qty_received_in => pk_blood_products_constant.g_bp_unit_ml,
                                     expiration_date_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_expiration_date,
                                                                                                  NULL),
                                     blood_group_in              => i_blood_group,
                                     blood_group_rh_in           => i_blood_group_rh,
                                     desc_hemo_type_lab_in       => i_desc_hemo_type_lab,
                                     donation_code_in            => i_donation_code,
                                     dt_last_update_tstz_in      => current_timestamp,
                                     rows_out                    => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_id_episode,
                                    i_flg_status => pk_blood_products_constant.g_status_det_wt,
                                    i_id_record  => l_bp_det.id_blood_product_det,
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_sys_alert_event.id_sys_alert    := 323;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := l_id_episode;
            l_sys_alert_event.id_patient      := l_id_patient;
            l_sys_alert_event.id_record       := l_bp_det.id_blood_product_det;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => l_id_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => l_id_episode,
                                                                                     o_error      => o_error);
        
            g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            BEGIN
                SELECT COUNT(1)
                  INTO l_exec_number
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = l_bp_det.id_blood_product_det;
            END;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => l_bp_det.id_blood_product_det,
                                           action_in                     => pk_blood_products_constant.g_bp_action_lab_service,
                                           id_prof_performed_in          => i_prof.id,
                                           dt_execution_in               => current_timestamp,
                                           exec_number_in                => l_exec_number + 1,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        
            IF l_bp_det.flg_prepare_not_send = pk_alert_constant.g_no
            THEN
            
                ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                               id_blood_product_det_in       => l_bp_det.id_blood_product_det,
                                               action_in                     => pk_blood_products_constant.g_bp_action_prepare_not_send,
                                               id_prof_performed_in          => i_prof.id,
                                               dt_execution_in               => current_timestamp,
                                               exec_number_in                => l_exec_number + 2,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz);
            
            END IF;
        
            IF l_qty_over > 0
               AND l_divide_bag = pk_alert_constant.g_yes
            THEN
                l_bp_det.id_blood_product_det     := seq_blood_product_det.nextval;
                l_bp_det.qty_exec                 := l_qty_over;
                l_bp_det.id_unit_mea_qty_exec     := pk_blood_products_constant.g_bp_unit_ml;
                l_bp_det.qty_received             := l_qty_over;
                l_bp_det.id_unit_mea_qty_received := pk_blood_products_constant.g_bp_unit_ml;
                l_bp_det.barcode_lab              := i_barcode;
                l_bp_det.expiration_date          := pk_date_utils.get_string_tstz(i_lang,
                                                                                   i_prof,
                                                                                   i_expiration_date,
                                                                                   NULL);
                l_bp_det.flg_status               := pk_blood_products_constant.g_status_det_wt;
                l_bp_det.blood_group              := i_blood_group;
                l_bp_det.blood_group_rh           := i_blood_group_rh;
                l_bp_det.desc_hemo_type_lab       := i_desc_hemo_type_lab;
                l_bp_det.id_bpd_origin            := l_bp_det_id;
                l_bp_det.donation_code            := i_donation_code;
            
                ts_blood_product_det.ins(rec_in => l_bp_det, rows_out => l_rows_out);
            
                BEGIN
                    SELECT COUNT(1)
                      INTO l_exec_number
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = l_bp_det.id_blood_product_det;
                
                END;
            
                ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                               id_blood_product_det_in       => l_bp_det.id_blood_product_det,
                                               action_in                     => pk_blood_products_constant.g_bp_action_lab_service,
                                               id_prof_performed_in          => i_prof.id,
                                               dt_execution_in               => current_timestamp,
                                               exec_number_in                => l_exec_number + 1,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => l_id_episode,
                                        i_flg_status => pk_blood_products_constant.g_status_det_wt,
                                        i_id_record  => l_bp_det.id_blood_product_det,
                                        i_flg_type   => pk_blood_products_constant.g_bp_type,
                                        o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_sys_alert_event.id_sys_alert    := 323;
                l_sys_alert_event.id_software     := i_prof.software;
                l_sys_alert_event.id_institution  := i_prof.institution;
                l_sys_alert_event.id_episode      := l_id_episode;
                l_sys_alert_event.id_patient      := l_id_patient;
                l_sys_alert_event.id_record       := l_bp_det.id_blood_product_det;
                l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => l_id_episode, o_error => o_error);
                l_sys_alert_event.dt_record       := current_timestamp;
                l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                         i_prof       => i_prof,
                                                                                         i_id_episode => l_id_episode,
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
        
            IF l_qty_miss > 0
               AND l_divide_bag = pk_alert_constant.g_yes
            THEN
                --Cria uma nova linha na Blood Product Det            
                l_bp_det.id_blood_product_det     := seq_blood_product_det.nextval;
                l_bp_det.qty_exec                 := l_qty_miss;
                l_bp_det.id_unit_mea_qty_exec     := pk_blood_products_constant.g_bp_unit_ml;
                l_bp_det.qty_received             := NULL;
                l_bp_det.id_unit_mea_qty_received := NULL;
                l_bp_det.barcode_lab              := NULL;
                l_bp_det.expiration_date          := NULL;
                l_bp_det.flg_status               := l_bp_det_status;
                l_bp_det.blood_group              := NULL;
                l_bp_det.blood_group_rh           := NULL;
                l_bp_det.id_bpd_origin            := l_bp_det_id;
                l_bp_det.donation_code            := i_donation_code;
            
                ts_blood_product_det.ins(rec_in => l_bp_det, rows_out => l_rows_out);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => l_id_episode,
                                        i_flg_status => l_bp_det_status,
                                        i_id_record  => l_bp_det.id_blood_product_det,
                                        i_flg_type   => pk_blood_products_constant.g_bp_type,
                                        o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        ELSE
            SELECT bpd.*
              INTO l_bp_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = i_blood_product_req
               AND bpd.id_hemo_type = i_hemo_type
               AND bpd.id_bpd_origin IS NULL;
        
            l_bp_det_id := l_bp_det.id_blood_product_det;
        
            l_bp_det.id_blood_product_det     := seq_blood_product_det.nextval;
            l_bp_det.qty_exec                 := l_qty_rec;
            l_bp_det.id_unit_mea_qty_exec     := pk_blood_products_constant.g_bp_unit_ml;
            l_bp_det.qty_received             := l_qty_rec;
            l_bp_det.id_unit_mea_qty_received := pk_blood_products_constant.g_bp_unit_ml;
            l_bp_det.barcode_lab              := i_barcode;
            l_bp_det.expiration_date          := pk_date_utils.get_string_tstz(i_lang, i_prof, i_expiration_date, NULL);
            l_bp_det.flg_status               := pk_blood_products_constant.g_status_det_wt;
            l_bp_det.blood_group              := i_blood_group;
            l_bp_det.blood_group_rh           := i_blood_group_rh;
            l_bp_det.desc_hemo_type_lab       := i_desc_hemo_type_lab;
            l_bp_det.id_bpd_origin            := l_bp_det_id;
            l_bp_det.donation_code            := i_donation_code;
        
            ts_blood_product_det.ins(rec_in => l_bp_det, rows_out => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_id_episode,
                                    i_flg_status => pk_blood_products_constant.g_status_det_wt,
                                    i_id_record  => l_bp_det.id_blood_product_det,
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_sys_alert_event.id_sys_alert    := 323;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := l_id_episode;
            l_sys_alert_event.id_patient      := l_id_patient;
            l_sys_alert_event.id_record       := l_bp_det.id_blood_product_det;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => l_id_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => l_id_episode,
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
    
        ts_blood_product_req.upd(id_blood_product_req_in => l_bp_det.id_blood_product_req,
                                 flg_status_in           => pk_blood_products_constant.g_status_req_o,
                                 rows_out                => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_REQ',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_PREPARATION',
                                              o_error);
            RETURN FALSE;
    END set_bp_preparation;

    FUNCTION set_bp_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_to_state          IN VARCHAR2,
        i_barcode           IN VARCHAR2,
        i_prof_match        IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode           episode.id_episode%TYPE;
        l_blood_product_req blood_product_det.id_blood_product_req%TYPE;
        l_status_req        blood_product_req.flg_status%TYPE;
    
        l_exec_number NUMBER := 0;
    
        l_exec_id  blood_product_execution.id_blood_product_execution%TYPE;
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT bpd.id_blood_product_req
          INTO l_blood_product_req
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 flg_status_in           => i_to_state,
                                 dt_last_update_tstz_in  => g_sysdate_tstz,
                                 rows_out                => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        SELECT bpr.id_episode
          INTO l_episode
          FROM blood_product_det bpd, blood_product_req bpr
         WHERE bpd.id_blood_product_det = i_blood_product_det
           AND bpd.id_blood_product_req = bpr.id_blood_product_req;
    
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => l_episode,
                                i_flg_status => i_to_state,
                                i_id_record  => i_blood_product_det,
                                i_flg_type   => pk_blood_products_constant.g_bp_type,
                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_exec_number
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det;
        END;
    
        l_exec_id := seq_blood_product_execution.nextval;
        ts_blood_product_execution.ins(id_blood_product_execution_in => l_exec_id,
                                       id_blood_product_det_in       => i_blood_product_det,
                                       action_in                     => CASE i_to_state
                                                                            WHEN pk_blood_products_constant.g_status_det_ot THEN
                                                                             pk_blood_products_constant.g_bp_action_begin_transp
                                                                            WHEN pk_blood_products_constant.g_status_det_or THEN
                                                                             pk_blood_products_constant.g_bp_action_begin_return
                                                                            WHEN pk_blood_products_constant.g_status_det_cr THEN
                                                                             pk_blood_products_constant.g_bp_action_end_return
                                                                            ELSE
                                                                             pk_blood_products_constant.g_bp_action_end_transp
                                                                        END,
                                       id_prof_performed_in          => i_prof.id,
                                       exec_number_in                => l_exec_number + 1,
                                       id_prof_match_in              => i_prof_match,
                                       dt_match_tstz_in              => CASE
                                                                            WHEN i_prof_match IS NULL THEN
                                                                             NULL
                                                                            ELSE
                                                                             g_sysdate_tstz
                                                                        END,
                                       id_professional_in            => i_prof.id,
                                       dt_bp_execution_tstz_in       => g_sysdate_tstz);
    
        IF i_to_state = pk_blood_products_constant.g_status_det_ot
        THEN
            pk_ia_event_blood_bank.blood_product_det_transp_begin(i_id_institution        => i_prof.institution,
                                                                  i_id_blood_product_exec => l_exec_id);
        ELSE
            pk_ia_event_blood_bank.blood_product_det_transp_end(i_id_institution        => i_prof.institution,
                                                                i_id_blood_product_exec => l_exec_id);
        END IF;
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_UTILS.GET_BP_STATUS_TO_UPDATE';
        IF pk_blood_products_utils.get_bp_status_to_update(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_blood_product_req => l_blood_product_req,
                                                           o_status            => l_status_req,
                                                           o_error             => o_error)
        THEN
            g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
            IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_blood_product_req => l_blood_product_req,
                                                            i_state             => l_status_req,
                                                            i_cancel_reason     => NULL,
                                                            i_notes_cancel      => NULL,
                                                            o_error             => o_error)
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
                                              'SET_BP_TRANSPORT',
                                              o_error);
            RETURN FALSE;
    END set_bp_transport;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_num_exec NUMBER;
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(*)
          INTO l_num_exec
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 rows_out                => l_rows_out);
    
        ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                       id_blood_product_det_in       => i_blood_product_det,
                                       action_in                     => pk_blood_products_constant.g_bp_action_compability,
                                       id_prof_performed_in          => i_prof.id,
                                       dt_execution_in               => current_timestamp,
                                       exec_number_in                => l_num_exec + 1,
                                       id_professional_in            => i_prof.id,
                                       dt_bp_execution_tstz_in       => g_sysdate_tstz,
                                       flg_compatibility_in          => i_flg_compatibility,
                                       notes_compatibility_in        => i_notes,
                                       rows_out                      => l_rows_out);
    
        SELECT bpr.id_episode, bpr.id_patient
          INTO l_id_episode, l_id_patient
          FROM blood_product_det bpd
          JOIN blood_product_req bpr
            ON bpr.id_blood_product_req = bpd.id_blood_product_req
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        IF i_flg_compatibility = pk_blood_products_constant.g_bp_warning_compatibility
        THEN
            l_sys_alert_event.id_sys_alert   := 335;
            l_sys_alert_event.id_software    := i_prof.software;
            l_sys_alert_event.id_institution := i_prof.institution;
            l_sys_alert_event.id_episode     := l_id_episode;
            l_sys_alert_event.id_patient     := l_id_patient;
            l_sys_alert_event.id_record      := i_blood_product_det;
            l_sys_alert_event.id_visit       := pk_visit.get_visit(i_episode => l_id_episode, o_error => o_error);
            l_sys_alert_event.dt_record      := current_timestamp;
            l_sys_alert_event.id_prof_order  := i_prof.id;
        
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
                                              'SET_BP_COMPATIBILITY',
                                              o_error);
            RETURN FALSE;
    END set_bp_compatibility;

    FUNCTION set_bp_transfusion
    (
        i_lang                  IN language.id_language%TYPE, --1
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_from_state            IN action.to_state%TYPE DEFAULT NULL, --5
        i_to_state              IN action.to_state%TYPE DEFAULT NULL,
        i_performed_by          IN professional.id_professional%TYPE,
        i_start_date            IN VARCHAR2,
        i_duration              IN blood_product_execution.duration%TYPE, --10
        i_duration_unit_measure IN blood_product_execution.id_unit_mea_duration%TYPE,
        i_end_date              IN VARCHAR2,
        i_description           IN blood_product_execution.description%TYPE,
        i_prof_match            IN NUMBER DEFAULT NULL,
        i_documentation_notes   IN epis_interv.notes%TYPE, --15
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number, --20
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number, --25
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number, --30
        i_amount_given          IN blood_product_det.qty_given%TYPE,
        i_amount_given_unit     IN blood_product_det.id_unit_mea_qty_given%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_documentation   table_number := table_number();
    
        l_exec_number NUMBER;
        l_state       action.to_state%TYPE;
        l_action      action.internal_name%TYPE;
    
        l_blood_product_req blood_product_req.id_blood_product_req%TYPE;
        l_status_req        blood_product_req.flg_status%TYPE;
    
        l_qty_given      blood_product_det.qty_given%TYPE;
        l_qty_received   blood_product_det.qty_received%TYPE;
        l_volume_default sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                          i_code_cf => 'BLOOD_PRODUCT_UNIT_VOL');
    
        l_id_execution blood_product_execution.id_blood_product_execution%TYPE;
        l_rows_out     table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_amount_given_unit = pk_blood_products_constant.g_bp_unit_ml
        THEN
            l_qty_given := i_amount_given;
        ELSE
            l_qty_given := i_amount_given * l_volume_default;
        END IF;
    
        l_id_documentation := nvl(i_id_documentation, table_number());
    
        IF nvl(l_id_documentation.count, 0) > 0
           OR (nvl(l_id_documentation.count, 0) = 0 AND i_documentation_notes IS NOT NULL AND
               dbms_lob.getlength(i_documentation_notes) > 0)
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION';
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => pk_prof_utils.get_category(i_lang,
                                                                                                                    i_prof),
                                                              i_epis                  => i_episode,
                                                              i_doc_area              => CASE i_from_state
                                                                                             WHEN
                                                                                              pk_blood_products_constant.g_status_det_rt THEN
                                                                                              pk_blood_products_constant.g_bp_doc_area_pre
                                                                                             WHEN
                                                                                              pk_blood_products_constant.g_status_det_o THEN
                                                                                              CASE i_to_state
                                                                                                  WHEN
                                                                                                   pk_blood_products_constant.g_status_det_f THEN
                                                                                                   pk_blood_products_constant.g_bp_doc_area_post
                                                                                                  ELSE
                                                                                                   pk_blood_products_constant.g_bp_doc_area_obs
                                                                                              END
                                                                                         END,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => NULL,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => l_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_documentation_notes,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_blood_product_det,
                                                              i_vs_element_list       => i_vs_element_list,
                                                              i_vs_save_mode_list     => i_vs_save_mode_list,
                                                              i_vs_list               => i_vs_list,
                                                              i_vs_value_list         => i_vs_value_list,
                                                              i_vs_uom_list           => i_vs_uom_list,
                                                              i_vs_scales_list        => i_vs_scales_list,
                                                              i_vs_date_list          => i_vs_date_list,
                                                              i_vs_read_list          => i_vs_read_list,
                                                              o_epis_documentation    => l_epis_documentation,
                                                              o_error                 => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_exec_number
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det;
        END;
    
        IF i_from_state = pk_blood_products_constant.g_status_det_rt
        THEN
            l_state := pk_blood_products_constant.g_status_det_o;
        
            l_action := pk_blood_products_constant.g_bp_action_administer;
        
            ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                     flg_status_in           => l_state,
                                     dt_last_update_tstz_in  => current_timestamp,
                                     rows_out                => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => l_state,
                                    i_id_record  => i_blood_product_det,
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => l_action,
                                           id_prof_performed_in          => i_performed_by,
                                           dt_execution_in               => current_timestamp,
                                           dt_begin_in                   => pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          i_start_date,
                                                                                                          NULL),
                                           description_in                => i_description,
                                           exec_number_in                => l_exec_number + 1,
                                           id_epis_documentation_in      => l_epis_documentation,
                                           id_prof_match_in              => i_prof_match,
                                           dt_match_tstz_in              => CASE
                                                                                WHEN i_prof_match IS NULL THEN
                                                                                 NULL
                                                                                ELSE
                                                                                 current_timestamp
                                                                            END,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        ELSIF i_from_state = pk_blood_products_constant.g_status_det_o
              AND i_to_state = pk_blood_products_constant.g_status_det_f
        THEN
            SELECT bpd.qty_received
              INTO l_qty_received
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = i_blood_product_det;
        
            IF l_qty_received = l_qty_given
            THEN
                l_state := pk_blood_products_constant.g_status_det_f;
            ELSE
                l_state := pk_blood_products_constant.g_status_det_wr;
            END IF;
        
            l_action := pk_blood_products_constant.g_bp_action_conclude;
        
            ts_blood_product_det.upd(id_blood_product_det_in  => i_blood_product_det,
                                     flg_status_in            => l_state,
                                     qty_given_in             => l_qty_given,
                                     id_unit_mea_qty_given_in => pk_blood_products_constant.g_bp_unit_ml,
                                     dt_last_update_tstz_in   => current_timestamp,
                                     rows_out                 => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => l_state,
                                    i_id_record  => i_blood_product_det,
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
            l_id_execution := seq_blood_product_execution.nextval;
            ts_blood_product_execution.ins(id_blood_product_execution_in => l_id_execution,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => l_action,
                                           id_prof_performed_in          => i_performed_by,
                                           duration_in                   => i_duration,
                                           id_unit_mea_duration_in       => i_duration_unit_measure,
                                           dt_end_in                     => pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          i_end_date,
                                                                                                          NULL),
                                           description_in                => i_description,
                                           dt_execution_in               => g_sysdate_tstz,
                                           exec_number_in                => l_exec_number + 1,
                                           id_epis_documentation_in      => l_epis_documentation,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        
            g_error := 'CALL PK_IA_EVENT_BLOOD_BANK.BLOOD_PROD_DETAIL_ADMIN';
            pk_ia_event_blood_bank.blood_prod_detail_admin(i_id_institution             => i_prof.institution,
                                                           i_id_blood_product_execution => l_id_execution);
        
            --Check it is necessary to update the requisition status
            SELECT d.id_blood_product_req
              INTO l_blood_product_req
              FROM blood_product_det d
             WHERE d.id_blood_product_det = i_blood_product_det;
        
            g_error := 'CALL PK_BLOOD_PRODUCTS_UTILS.GET_BP_STATUS_TO_UPDATE';
            IF pk_blood_products_utils.get_bp_status_to_update(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_blood_product_req => l_blood_product_req,
                                                               o_status            => l_status_req,
                                                               o_error             => o_error)
            THEN
                g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
                IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_blood_product_req => l_blood_product_req,
                                                                i_state             => l_status_req,
                                                                i_cancel_reason     => NULL,
                                                                i_notes_cancel      => NULL,
                                                                o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        ELSE
            l_state := pk_blood_products_constant.g_status_det_o;
        
            l_action := pk_blood_products_constant.g_bp_action_reevaluate;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => l_action,
                                           id_prof_performed_in          => i_performed_by,
                                           duration_in                   => i_duration,
                                           id_unit_mea_duration_in       => i_duration_unit_measure,
                                           dt_end_in                     => pk_date_utils.get_string_tstz(i_lang,
                                                                                                          i_prof,
                                                                                                          i_end_date,
                                                                                                          NULL),
                                           description_in                => i_description,
                                           dt_execution_in               => g_sysdate_tstz,
                                           exec_number_in                => l_exec_number + 1,
                                           id_epis_documentation_in      => l_epis_documentation,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        END IF;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 rows_out                => l_rows_out);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_TRANSFUSION',
                                              o_error);
            RETURN FALSE;
    END set_bp_transfusion;

    FUNCTION set_bp_adverse_reaction
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_documentation_notes   IN epis_interv.notes%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_documentation   table_number := table_number();
    
        l_exec_number NUMBER;
        l_action      action.internal_name%TYPE := pk_blood_products_constant.g_bp_action_report;
    
        l_rows_out table_varchar;
    
        l_bp_execution_id blood_product_execution.id_blood_product_execution%TYPE;
    
        l_req_analysis_id    table_number;
        l_req_sample_type_id table_number;
    
        l_flg_show_analysis VARCHAR2(1000 CHAR);
    
        l_patient  patient.id_patient%TYPE := pk_episode.get_id_patient(i_episode => i_episode);
        l_dt_begin analysis_req_det.dt_target_tstz%TYPE := current_timestamp;
        l_priority analysis_req.flg_priority%TYPE;
    
        l_analysis_req     table_number;
        l_analysis_req_det table_number;
        l_analysis_req_par table_number;
    
        l_create_lab_test NUMBER;
    
        CURSOR c_hemo_analysis(dt_begin_hemo TIMESTAMP WITH LOCAL TIME ZONE) IS
        
            SELECT hta.id_analysis, hta.id_sample_type
              FROM hemo_type_analysis hta
              JOIN blood_product_det bpd
                ON bpd.id_hemo_type = hta.id_hemo_type
             WHERE bpd.id_blood_product_det = i_blood_product_det
               AND hta.flg_available = pk_alert_constant.g_yes
               AND hta.id_institution = i_prof.institution
               AND hta.flg_reaction_form = pk_alert_constant.g_yes;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_id_documentation := nvl(i_id_documentation, table_number());
    
        IF nvl(l_id_documentation.count, 0) > 0
           OR (nvl(l_id_documentation.count, 0) = 0 AND i_documentation_notes IS NOT NULL AND
               dbms_lob.getlength(i_documentation_notes) > 0)
        THEN
            g_error := 'CALL pk_touch_option.set_epis_documentation';
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => pk_prof_utils.get_category(i_lang,
                                                                                                                    i_prof),
                                                              i_epis                  => i_episode,
                                                              i_doc_area              => pk_blood_products_constant.g_bp_doc_area_adv_reac,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => NULL,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => l_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_documentation_notes,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_blood_product_det, -------
                                                              i_vs_element_list       => i_vs_element_list,
                                                              i_vs_save_mode_list     => i_vs_save_mode_list,
                                                              i_vs_list               => i_vs_list,
                                                              i_vs_value_list         => i_vs_value_list,
                                                              i_vs_uom_list           => i_vs_uom_list,
                                                              i_vs_scales_list        => i_vs_scales_list,
                                                              i_vs_date_list          => i_vs_date_list,
                                                              i_vs_read_list          => i_vs_read_list,
                                                              o_epis_documentation    => l_epis_documentation,
                                                              o_error                 => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        BEGIN
            SELECT COUNT(1)
              INTO l_exec_number
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det;
        END;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 adverse_reaction_in     => pk_blood_products_constant.g_yes,
                                 adverse_reaction_nin    => FALSE,
                                 dt_last_update_tstz_in  => g_sysdate_tstz,
                                 rows_out                => l_rows_out);
    
        SELECT ROWID
          BULK COLLECT
          INTO l_rows_out
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req IN
               (SELECT bpd1.id_blood_product_req
                  FROM blood_product_det bpd1
                 WHERE bpd1.id_blood_product_det = i_blood_product_det);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        l_bp_execution_id := seq_blood_product_execution.nextval;
        ts_blood_product_execution.ins(id_blood_product_execution_in => l_bp_execution_id,
                                       id_blood_product_det_in       => i_blood_product_det,
                                       id_prof_performed_in          => i_prof.id,
                                       action_in                     => l_action,
                                       exec_number_in                => l_exec_number + 1,
                                       id_epis_documentation_in      => l_epis_documentation,
                                       id_professional_in            => i_prof.id,
                                       dt_bp_execution_tstz_in       => g_sysdate_tstz);
    
        pk_ia_event_blood_bank.blood_prod_detail_adv_reaction(i_id_institution             => i_prof.institution,
                                                              i_id_blood_product_execution => l_bp_execution_id);
    
        /* Fire lab tests */
    
        OPEN c_hemo_analysis(l_dt_begin);
        FETCH c_hemo_analysis BULK COLLECT
            INTO l_req_analysis_id, l_req_sample_type_id;
        CLOSE c_hemo_analysis;
    
        IF l_req_analysis_id IS NOT NULL
           AND l_req_analysis_id.count > 0
        THEN
        
            SELECT bpd.flg_priority
              INTO l_priority
              FROM blood_product_det bpd
             INNER JOIN blood_product_req bpr
                ON bpd.id_blood_product_req = bpr.id_blood_product_req
             WHERE bpd.id_blood_product_det = i_blood_product_det;
        
            FOR i IN 1 .. l_req_analysis_id.count
            LOOP
                l_create_lab_test := 0;
                g_error           := 'CALL PK_LAB_TESTS_API_DB.CREATE_LAB_TEST_ORDER';
                IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_patient                 => l_patient,
                                                                 i_episode                 => i_episode,
                                                                 i_analysis_req            => NULL,
                                                                 i_analysis_req_det        => table_number(NULL),
                                                                 i_analysis_req_det_parent => table_number(NULL),
                                                                 i_harvest                 => NULL,
                                                                 i_analysis                => table_number(l_req_analysis_id(i)),
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
                                                                 i_priority                => table_varchar(l_priority),
                                                                 i_flg_prn                 => table_varchar(pk_lab_tests_constant.g_analysis_normal),
                                                                 i_notes_prn               => table_varchar(NULL),
                                                                 i_specimen                => table_number(l_req_sample_type_id(i)),
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
                    l_create_lab_test := -1;
                    RAISE g_other_exception;
                END IF;
            
                IF l_create_lab_test > -1
                THEN
                    ts_blood_product_analysis.ins(id_blood_product_analysis_in  => seq_blood_product_analysis.nextval,
                                                  id_analysis_req_det_in        => l_analysis_req_det(1),
                                                  id_blood_product_det_in       => i_blood_product_det,
                                                  id_blood_product_execution_in => l_bp_execution_id,
                                                  rows_out                      => l_rows_out);
                END IF;
            
            END LOOP;
        END IF;
    
        /*Send event*/
        /*pk_ia_event_blood_bank.blood_product_adv_react(i_id_institution       => i_prof.institution,
        i_id_blood_product_exec => l_bp_execution_id);*/
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_ADVERSE_REACTION',
                                              o_error);
            RETURN FALSE;
    END set_bp_adverse_reaction;

    FUNCTION set_bp_adv_reaction_confirm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_blood_product_exec IN blood_product_execution.id_blood_product_execution%TYPE,
        i_date               IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar;
    
    BEGIN
    
        ts_blood_product_execution.upd(id_blood_product_execution_in => i_blood_product_exec,
                                       id_prof_match_in              => i_prof.id,
                                       id_prof_match_nin             => FALSE,
                                       dt_match_tstz_in              => pk_date_utils.get_string_tstz(i_lang,
                                                                                                      i_prof,
                                                                                                      i_date,
                                                                                                      NULL),
                                       dt_match_tstz_nin             => FALSE,
                                       rows_out                      => l_rows_out);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_ADV_REACTION_CONFIRM',
                                              o_error);
            RETURN FALSE;
    END set_bp_adv_reaction_confirm;

    FUNCTION set_bp_req_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_state             IN blood_product_req.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        i_upd_det           IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_bp_det(i_id_blood_product_req blood_product_req.id_blood_product_req%TYPE) IS
            SELECT bpd.id_blood_product_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = i_id_blood_product_req
               AND ((i_state = pk_blood_products_constant.g_status_det_h AND
                   bpd.flg_status IN (pk_blood_products_constant.g_status_det_o)) OR
                   (i_state = pk_blood_products_constant.g_status_det_o AND
                   bpd.flg_status IN (pk_blood_products_constant.g_status_det_h)) OR
                   i_state NOT IN
                   (pk_blood_products_constant.g_status_det_h, pk_blood_products_constant.g_status_det_o));
    
        l_id_bpd table_number := table_number();
    
        l_episode episode.id_episode%TYPE;
    
        l_exec_number NUMBER;
        l_action      VARCHAR2(20 CHAR);
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        ts_blood_product_req.upd(id_blood_product_req_in => i_blood_product_req,
                                 flg_status_in           => i_state,
                                 id_prof_cancel_in       => CASE
                                                                WHEN i_state = pk_blood_products_constant.g_status_det_c
                                                                     OR i_state = pk_blood_products_constant.g_status_det_d THEN
                                                                 i_prof.id
                                                                ELSE
                                                                 NULL
                                                            END,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 notes_cancel_in         => i_notes_cancel,
                                 dt_cancel_tstz_in       => CASE
                                                                WHEN i_state = pk_blood_products_constant.g_status_det_c
                                                                     OR i_state = pk_blood_products_constant.g_status_det_d THEN
                                                                 current_timestamp
                                                                ELSE
                                                                 NULL
                                                            END,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 id_prof_last_update_in  => i_prof.id,
                                 rows_out                => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_REQ',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        IF i_upd_det
        THEN
            OPEN c_bp_det(i_blood_product_req);
            FETCH c_bp_det BULK COLLECT
                INTO l_id_bpd;
            CLOSE c_bp_det;
        
            CASE i_state
                WHEN pk_blood_products_constant.g_status_det_h THEN
                    l_action := pk_blood_products_constant.g_bp_action_hold;
                WHEN pk_blood_products_constant.g_status_det_o THEN
                    l_action := pk_blood_products_constant.g_bp_action_resume;
                ELSE
                    l_action := pk_blood_products_constant.g_bp_action_return;
            END CASE;
        
            SELECT bpr.id_episode
              INTO l_episode
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_blood_product_req;
        
            FOR j IN 1 .. l_id_bpd.count
            LOOP
                ts_blood_product_det.upd(id_blood_product_det_in => l_id_bpd(j),
                                         id_cancel_reason_in     => i_cancel_reason,
                                         flg_status_in           => i_state,
                                         notes_cancel_in         => i_notes_cancel,
                                         dt_last_update_tstz_in  => g_sysdate_tstz,
                                         id_prof_last_update_in  => i_prof.id,
                                         rows_out                => l_rows_out);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => l_episode,
                                        i_flg_status => i_state,
                                        i_id_record  => l_id_bpd(j),
                                        i_flg_type   => pk_blood_products_constant.g_bp_type,
                                        o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                BEGIN
                    SELECT COUNT(1)
                      INTO l_exec_number
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = l_id_bpd(j);
                END;
            
                ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                               id_blood_product_det_in       => l_id_bpd(j),
                                               action_in                     => l_action,
                                               id_prof_performed_in          => i_prof.id,
                                               id_action_reason_in           => i_cancel_reason,
                                               notes_reason_in               => i_notes_cancel,
                                               exec_number_in                => l_exec_number + 1,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz);
            
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
                                              'SET_BP_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_bp_req_status;

    FUNCTION set_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_state             IN blood_product_det.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode episode.id_episode%TYPE;
    
        l_exec_number NUMBER;
        l_action      VARCHAR2(20 CHAR);
    
        l_blood_product_req blood_product_req.id_blood_product_req%TYPE;
        l_status_req        blood_product_req.flg_status%TYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        CASE i_state
            WHEN pk_blood_products_constant.g_status_det_h THEN
                l_action := pk_blood_products_constant.g_bp_action_hold;
            WHEN pk_blood_products_constant.g_status_det_o THEN
                l_action := pk_blood_products_constant.g_bp_action_resume;
            WHEN pk_blood_products_constant.g_status_det_br THEN
                l_action := pk_blood_products_constant.g_bp_action_return;
            WHEN pk_blood_products_constant.g_status_det_wr THEN
                l_action := pk_blood_products_constant.g_bp_action_return;
            WHEN pk_blood_products_constant.g_status_det_wt THEN
                l_action := pk_blood_products_constant.g_status_det_wt;
            ELSE
                l_action := NULL;
        END CASE;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 flg_status_in           => i_state,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 notes_cancel_in         => i_notes_cancel,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 rows_out                => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        SELECT bpr.id_episode
          INTO l_episode
          FROM blood_product_det bpd, blood_product_req bpr
         WHERE bpd.id_blood_product_det = i_blood_product_det
           AND bpd.id_blood_product_req = bpr.id_blood_product_req;
    
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => l_episode,
                                i_flg_status => i_state,
                                i_id_record  => i_blood_product_det,
                                i_flg_type   => pk_blood_products_constant.g_bp_type,
                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_action IS NOT NULL
        THEN
            BEGIN
                SELECT COUNT(1)
                  INTO l_exec_number
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det;
            END;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => l_action,
                                           id_prof_performed_in          => i_prof.id,
                                           id_action_reason_in           => i_cancel_reason,
                                           notes_reason_in               => i_notes_cancel,
                                           exec_number_in                => l_exec_number + 1,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        
            SELECT d.id_blood_product_req
              INTO l_blood_product_req
              FROM blood_product_det d
             WHERE d.id_blood_product_det = i_blood_product_det;
        
            IF l_action = pk_blood_products_constant.g_bp_action_resume
            THEN
                g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
                IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_blood_product_req => l_blood_product_req,
                                                                i_state             => i_state,
                                                                i_cancel_reason     => i_cancel_reason,
                                                                i_notes_cancel      => i_notes_cancel,
                                                                o_error             => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                g_error := 'CALL PK_BLOOD_PRODUCTS_UTILS.GET_BP_STATUS_TO_UPDATE';
                IF pk_blood_products_utils.get_bp_status_to_update(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_blood_product_req => l_blood_product_req,
                                                                   o_status            => l_status_req,
                                                                   o_error             => o_error)
                THEN
                    g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
                    IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_blood_product_req => l_blood_product_req,
                                                                    i_state             => l_status_req,
                                                                    i_cancel_reason     => i_cancel_reason,
                                                                    i_notes_cancel      => i_notes_cancel,
                                                                    o_error             => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
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
                                              'SET_BP_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_bp_status;

    FUNCTION set_bp_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diagnosis_list(l_blood_product_det blood_product_det.id_blood_product_det%TYPE) IS
            SELECT mrd.id_mcdt_req_diagnosis
              FROM mcdt_req_diagnosis mrd
             WHERE mrd.id_blood_product_det = l_blood_product_det
               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled;
    
        l_blood_product_det blood_product_det%ROWTYPE;
    
        l_blood_product_det_hist blood_product_det_hist%ROWTYPE;
    
        l_diagnosis_list blood_product_det_hist.id_diagnosis_list%TYPE;
    
        l_user             blood_product_req.id_professional%TYPE;
        l_dt_blood_product blood_product_det.dt_last_update_tstz%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN LOOP';
        FOR i IN 1 .. i_blood_product_det.count
        LOOP
            IF i_blood_product_det(i) IS NOT NULL
            THEN
                g_error := 'GET INTERV_PRESC_DET';
                SELECT bpd.*
                  INTO l_blood_product_det
                  FROM blood_product_det bpd
                 WHERE bpd.id_blood_product_det = i_blood_product_det(i);
            
                IF l_blood_product_det.flg_status != pk_blood_products_constant.g_status_det_pd
                THEN
                    l_diagnosis_list := NULL;
                    g_error          := 'CREATE DIAGNOSIS LIST';
                    FOR rec IN c_diagnosis_list(i_blood_product_det(i))
                    LOOP
                        IF l_diagnosis_list IS NULL
                        THEN
                            l_diagnosis_list := rec.id_mcdt_req_diagnosis;
                        ELSE
                            l_diagnosis_list := l_diagnosis_list || ';' || rec.id_mcdt_req_diagnosis;
                        END IF;
                    END LOOP;
                
                    l_blood_product_det_hist.id_blood_product_det_hist := ts_blood_product_det_hist.next_key;
                    --l_blood_product_det_hist.dt_blood_product_det_hist := g_sysdate_tstz;
                    l_blood_product_det_hist.id_blood_product_det       := l_blood_product_det.id_blood_product_det;
                    l_blood_product_det_hist.id_blood_product_req       := l_blood_product_det.id_blood_product_req;
                    l_blood_product_det_hist.id_hemo_type               := l_blood_product_det.id_hemo_type;
                    l_blood_product_det_hist.id_movement                := l_blood_product_det.id_movement;
                    l_blood_product_det_hist.flg_status                 := l_blood_product_det.flg_status;
                    l_blood_product_det_hist.notes                      := l_blood_product_det.notes;
                    l_blood_product_det_hist.notes_tech                 := l_blood_product_det.notes_tech;
                    l_blood_product_det_hist.id_prof_cancel             := l_blood_product_det.id_prof_cancel;
                    l_blood_product_det_hist.notes_cancel               := l_blood_product_det.notes_cancel;
                    l_blood_product_det_hist.flg_priority               := l_blood_product_det.flg_priority;
                    l_blood_product_det_hist.dt_end_tstz                := l_blood_product_det.dt_end_tstz;
                    l_blood_product_det_hist.dt_begin_tstz              := l_blood_product_det.dt_begin_tstz;
                    l_blood_product_det_hist.dt_cancel_tstz             := l_blood_product_det.dt_cancel_tstz;
                    l_blood_product_det_hist.dt_blood_product_det       := l_blood_product_det.dt_blood_product_det;
                    l_blood_product_det_hist.dt_pend_req_tstz           := l_blood_product_det.dt_pend_req_tstz;
                    l_blood_product_det_hist.id_exec_institution        := l_blood_product_det.id_exec_institution;
                    l_blood_product_det_hist.id_cancel_reason           := l_blood_product_det.id_cancel_reason;
                    l_blood_product_det_hist.id_not_order_reason        := l_blood_product_det.id_not_order_reason;
                    l_blood_product_det_hist.id_co_sign_order           := l_blood_product_det.id_co_sign_order;
                    l_blood_product_det_hist.id_co_sign_cancel          := l_blood_product_det.id_co_sign_cancel;
                    l_blood_product_det_hist.id_prof_last_update        := l_blood_product_det.id_prof_last_update;
                    l_blood_product_det_hist.dt_last_update_tstz        := l_blood_product_det.dt_last_update_tstz;
                    l_blood_product_det_hist.id_order_recurrence        := l_blood_product_det.id_order_recurrence;
                    l_blood_product_det_hist.flg_fasting                := l_blood_product_det.flg_fasting;
                    l_blood_product_det_hist.id_pat_health_plan         := l_blood_product_det.id_pat_health_plan;
                    l_blood_product_det_hist.id_pat_exemption           := l_blood_product_det.id_pat_exemption;
                    l_blood_product_det_hist.flg_req_origin_module      := l_blood_product_det.flg_req_origin_module;
                    l_blood_product_det_hist.id_clinical_purpose        := l_blood_product_det.id_clinical_purpose;
                    l_blood_product_det_hist.clinical_purpose_notes     := l_blood_product_det.clinical_purpose_notes;
                    l_blood_product_det_hist.transfusion_type           := l_blood_product_det.transfusion_type;
                    l_blood_product_det_hist.qty_exec                   := l_blood_product_det.qty_exec;
                    l_blood_product_det_hist.id_unit_mea_qty_exec       := l_blood_product_det.id_unit_mea_qty_exec;
                    l_blood_product_det_hist.special_instr              := l_blood_product_det.special_instr;
                    l_blood_product_det_hist.barcode_lab                := l_blood_product_det.barcode_lab;
                    l_blood_product_det_hist.qty_received               := l_blood_product_det.qty_received;
                    l_blood_product_det_hist.id_unit_mea_qty_received   := l_blood_product_det.id_unit_mea_qty_received;
                    l_blood_product_det_hist.expiration_date            := l_blood_product_det.expiration_date;
                    l_blood_product_det_hist.blood_group                := l_blood_product_det.blood_group;
                    l_blood_product_det_hist.id_bpd_origin              := l_blood_product_det.id_bpd_origin;
                    l_blood_product_det_hist.adverse_reaction           := l_blood_product_det.adverse_reaction;
                    l_blood_product_det_hist.blood_group_rh             := l_blood_product_det.blood_group_rh;
                    l_blood_product_det_hist.id_diagnosis_list          := l_diagnosis_list;
                    l_blood_product_det_hist.donation_code              := l_blood_product_det.donation_code;
                    l_blood_product_det_hist.id_special_type            := l_blood_product_det.id_special_type;
                    l_blood_product_det_hist.flg_req_without_crossmatch := l_blood_product_det.flg_req_without_crossmatch;
                    l_blood_product_det_hist.id_prof_crossmatch         := l_blood_product_det.id_prof_crossmatch;
                
                    BEGIN
                        SELECT nvl(bpd.id_prof_last_update, bpr.id_professional),
                               nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz)
                          INTO l_user, l_dt_blood_product
                          FROM blood_product_det bpd
                          JOIN blood_product_req bpr
                            ON bpr.id_blood_product_req = bpd.id_blood_product_req
                         WHERE bpd.id_blood_product_det = i_blood_product_det(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_user             := NULL;
                            l_dt_blood_product := NULL;
                    END;
                
                    IF l_user IS NOT NULL
                    THEN
                        l_blood_product_det_hist.id_professional := l_user;
                    END IF;
                    IF l_dt_blood_product IS NOT NULL
                    THEN
                        l_blood_product_det_hist.dt_blood_product_det_hist := l_dt_blood_product;
                    END IF;
                
                    g_error := 'INSERT BLOOD_PRODUCT_DET_HIST';
                    ts_blood_product_det_hist.ins(rec_in => l_blood_product_det_hist);
                END IF;
            END IF;
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
                                              'SET_BP_HISTORY',
                                              o_error);
            RETURN FALSE;
    END set_bp_history;

    FUNCTION set_bp_condition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_condition     IN VARCHAR2,
        i_id_reason         IN blood_product_execution.id_action_reason%TYPE,
        i_notes             IN blood_product_execution.notes_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exec_number PLS_INTEGER := 0;
    
        l_exec_id  blood_product_execution.id_blood_product_execution%TYPE;
        l_rows_out table_varchar;
    
        l_previous_tag        blood_product_execution.action%TYPE := NULL;
        l_previous_id_bp_exec blood_product_execution.id_blood_product_execution%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_exec_number
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det;
    
        BEGIN
            SELECT bpe.id_blood_product_execution, bpe.action
              INTO l_previous_id_bp_exec, l_previous_tag
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det
               AND bpe.exec_number = l_exec_number;
        EXCEPTION
            WHEN no_data_found THEN
                l_previous_tag := NULL;
        END;
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 rows_out                => l_rows_out);
    
        IF l_previous_tag IS NULL
           OR l_previous_tag <> pk_blood_products_constant.g_bp_action_condition
        THEN
            l_exec_id := seq_blood_product_execution.nextval;
            ts_blood_product_execution.ins(id_blood_product_execution_in => l_exec_id,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => pk_blood_products_constant.g_bp_action_condition,
                                           id_action_reason_in           => i_id_reason,
                                           notes_reason_in               => i_notes,
                                           id_prof_performed_in          => i_prof.id,
                                           exec_number_in                => l_exec_number + 1,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz,
                                           flg_condition_in              => i_flg_condition,
                                           rows_out                      => l_rows_out);
        
        ELSE
            ts_blood_product_execution.upd_ins(id_blood_product_execution_in => l_previous_id_bp_exec,
                                               id_blood_product_det_in       => i_blood_product_det,
                                               action_in                     => pk_blood_products_constant.g_bp_action_condition,
                                               id_action_reason_in           => i_id_reason,
                                               notes_reason_in               => i_notes,
                                               id_prof_performed_in          => i_prof.id,
                                               exec_number_in                => l_exec_number,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz,
                                               flg_condition_in              => i_flg_condition,
                                               rows_out                      => l_rows_out);
        
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
                                              'SET_BP_CONDITION',
                                              o_error);
            RETURN FALSE;
    END set_bp_condition;

    FUNCTION set_bp_lab_mother
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_lab_mother    IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_num_exec NUMBER;
        l_count    NUMBER;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_count
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_lab_mother;
    
        IF l_count = 0
        THEN
            SELECT COUNT(*)
              INTO l_num_exec
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => i_blood_product_det,
                                           action_in                     => pk_blood_products_constant.g_bp_action_lab_mother,
                                           id_prof_performed_in          => i_prof.id,
                                           dt_execution_in               => current_timestamp,
                                           exec_number_in                => l_num_exec + 1,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz,
                                           flg_lab_mother_in             => i_flg_lab_mother,
                                           rows_out                      => l_rows_out);
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
                                              'SET_BP_LAB_MOTHER',
                                              o_error);
            RETURN FALSE;
    END set_bp_lab_mother;

    FUNCTION set_bp_transfusion_confirm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exec_number NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF cardinality(i_blood_product_det) > 0
        THEN
            FOR i IN i_blood_product_det.first .. i_blood_product_det.last
            LOOP
                SELECT COUNT(1)
                  INTO l_exec_number
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det(i);
            
                ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                               id_blood_product_det_in       => i_blood_product_det(i),
                                               action_in                     => 'CONFIRM_TRANSFUSION',
                                               id_prof_performed_in          => i_prof.id,
                                               exec_number_in                => l_exec_number + 1,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz);
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
                                              'SET_BP_TRANSFUSION_CONFIRM',
                                              o_error);
            RETURN FALSE;
    END set_bp_transfusion_confirm;

    FUNCTION update_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE,
        i_blood_product_det       IN table_number,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --25
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_req blood_product_req%ROWTYPE;
        l_bp_det blood_product_det%ROWTYPE;
    
        l_bp_question_response bp_question_response%ROWTYPE;
    
        l_order_recurrence        order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurrence_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        l_status     blood_product_req.flg_status%TYPE;
        l_status_det blood_product_det.flg_status%TYPE;
    
        l_dt_begin blood_product_det.dt_begin_tstz%TYPE;
    
        l_not_order_reason not_order_reason.id_not_order_reason%TYPE;
    
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_count PLS_INTEGER := 0;
    
        l_diagnosis           table_number := table_number();
        l_tbl_alert_diagnosis table_number := table_number();
        l_diagnosis_new       table_number := table_number();
        l_epis_diagnosis      table_varchar := table_varchar();
        l_tbl_diag_desc       table_varchar := table_varchar();
    
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_varchar := table_varchar();
        l_aux                     table_varchar2;
    
        l_prof_crossmatch blood_product_det.id_prof_crossmatch%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
        l_flg_req_without_crossmatch  VARCHAR2(1);
        l_blood_crossmatch_popup_show sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_CROSSMATCH_POPUP_SHOW',
                                                                                       i_prof);
    
        FUNCTION get_sub_diag_table
        (
            i_tbl_diagnosis IN pk_edis_types.rec_in_epis_diagnosis,
            i_sub_diag_list IN table_number
        ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
            l_ret      pk_edis_types.rec_in_epis_diagnosis;
            l_tbl_diag pk_edis_types.table_in_diagnosis;
        BEGIN
            l_ret := i_tbl_diagnosis;
        
            IF i_sub_diag_list.exists(1)
            THEN
                l_tbl_diag          := l_ret.tbl_diagnosis;
                l_ret.tbl_diagnosis := pk_edis_types.table_in_diagnosis();
            
                IF l_tbl_diag.exists(1)
                THEN
                    FOR j IN i_sub_diag_list.first .. i_sub_diag_list.last
                    LOOP
                        FOR i IN l_tbl_diag.first .. l_tbl_diag.last
                        LOOP
                            IF l_tbl_diag(i).id_diagnosis = i_sub_diag_list(j)
                            THEN
                                l_ret.tbl_diagnosis.extend;
                                l_ret.tbl_diagnosis(l_ret.tbl_diagnosis.count) := l_tbl_diag(i);
                                EXIT;
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;
            END IF;
        
            RETURN l_ret;
        END get_sub_diag_table;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL SET_BP_HISTORY';
        IF NOT set_bp_history(i_lang              => i_lang,
                              i_prof              => i_prof,
                              i_blood_product_det => i_blood_product_det,
                              o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        FOR i IN 1 .. i_blood_product_det.count
        LOOP
            g_error := 'GET BLOOD_PRODUCT_DET';
            SELECT bpd.*
              INTO l_bp_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = i_blood_product_det(i);
        
            g_error := 'GET BLOOD_PRODUCT_REQ';
            SELECT bpr.*
              INTO l_bp_req
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = l_bp_det.id_blood_product_req;
        
            IF i_order_recurrence(i) IS NOT NULL
            THEN
                -- set order recurrence plan as finished or cancel plan (order_recurr_option - 0 OR -2 ---- order_recurr_area NOT IN (7,8,9)
                g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.SET_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => i_order_recurrence(i),
                                                                        o_order_recurr_option     => l_order_recurrence_option,
                                                                        o_final_order_recurr_plan => l_order_recurrence,
                                                                        o_error                   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF l_order_recurrence IS NOT NULL
                THEN
                    g_error := 'CALL PK_ORDER_RECURRENCE_API_DB.PREPARE_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                                i_prof       => i_prof,
                                                                                i_order_plan => table_number(l_order_recurrence),
                                                                                o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin(i), NULL);
        
            g_error := 'FLG_TIME';
            IF i_flg_time(i) != pk_blood_products_constant.g_flg_time_e
            THEN
                l_status     := pk_blood_products_constant.g_status_req_p;
                l_status_det := pk_blood_products_constant.g_status_det_r_sc;
            ELSE
                -- realização neste epis.
                IF i_episode IS NOT NULL
                THEN
                    IF pk_sysconfig.get_config('REQ_NEXT_DAY', i_prof) = pk_blood_products_constant.g_no
                    THEN
                        IF pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_begin, g_sysdate_tstz), 'DD') !=
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, 'DD')
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            
                IF nvl(l_dt_begin, g_sysdate_tstz) > g_sysdate_tstz
                THEN
                    -- pendente
                    l_status     := pk_blood_products_constant.g_status_req_p;
                    l_status_det := pk_blood_products_constant.g_status_det_r_sc;
                ELSE
                    -- l_dt_begin   := g_sysdate_tstz;
                    l_status     := pk_blood_products_constant.g_status_req_r;
                    l_status_det := pk_blood_products_constant.g_status_det_r_sc;
                END IF;
            END IF;
        
            -- getting not order reason id                                              
            IF i_not_order_reason IS NOT NULL
               AND i_not_order_reason.count > 0
               AND i_not_order_reason(i) IS NOT NULL
            THEN
                l_status     := pk_blood_products_constant.g_status_req_n;
                l_status_det := pk_blood_products_constant.g_status_det_n;
            
                g_error := 'CALL TO PK_NOT_ORDER_REASON_DB.SET_NOT_ORDER_REASON';
                IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_not_order_reason_ea => i_not_order_reason(i),
                                                                   o_id_not_order_reason => l_not_order_reason,
                                                                   o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            IF l_bp_det.flg_status IN
               (pk_blood_products_constant.g_status_det_df, pk_blood_products_constant.g_status_det_pd)
               OR l_status_det IS NULL
            THEN
                l_status     := l_bp_req.flg_status;
                l_status_det := l_bp_det.flg_status;
            END IF;
        
            g_error := 'UPDATE INTERV_PRESCRIPTION';
            ts_blood_product_req.upd(id_blood_product_req_in => l_bp_det.id_blood_product_req,
                                     id_institution_in       => i_prof.institution,
                                     flg_time_in             => CASE
                                                                    WHEN i_flg_time IS NOT NULL
                                                                         AND i_flg_time.count > 0 THEN
                                                                     i_flg_time(i)
                                                                    ELSE
                                                                     l_bp_req.flg_time
                                                                END,
                                     flg_status_in           => l_status,
                                     dt_begin_tstz_in        => l_dt_begin,
                                     dt_begin_tstz_nin       => FALSE,
                                     id_prof_last_update_in  => i_prof.id,
                                     dt_last_update_tstz_in  => g_sysdate_tstz,
                                     rows_out                => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF l_bp_det.id_co_sign_order IS NOT NULL
               OR i_order_type(i) IS NOT NULL
            THEN
                IF i_order_type(i) IS NOT NULL
                THEN
                
                    g_error := 'CALL PK_CO_SIGN_API.SET_PENDING_CO_SIGN_TASK';
                    IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => i_lang,
                                                                   i_prof                   => i_prof,
                                                                   i_episode                => i_episode,
                                                                   i_id_co_sign_hist        => l_bp_det.id_co_sign_order,
                                                                   i_id_task_type           => pk_blood_products_constant.g_task_type_bp,
                                                                   i_cosign_def_action_type => pk_co_sign_api.g_cosign_action_def_add,
                                                                   i_id_task                => i_blood_product_det(i),
                                                                   i_id_task_group          => i_blood_product_det(i),
                                                                   i_id_order_type          => i_order_type(i),
                                                                   i_id_prof_created        => i_prof.id,
                                                                   i_id_prof_ordered_by     => i_prof_order(i),
                                                                   i_dt_created             => g_sysdate_tstz,
                                                                   i_dt_ordered_by          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                             i_prof,
                                                                                                                             i_dt_order(i),
                                                                                                                             NULL),
                                                                   o_id_co_sign             => l_id_co_sign,
                                                                   o_id_co_sign_hist        => l_id_co_sign_hist,
                                                                   o_error                  => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                ELSE
                    g_error := 'CALL PK_CO_SIGN_API.SET_TASK_OUTDATED';
                    IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            i_id_co_sign      => NULL,
                                                            i_id_co_sign_hist => l_bp_det.id_co_sign_order,
                                                            i_dt_update       => g_sysdate_tstz,
                                                            o_id_co_sign_hist => l_id_co_sign_hist,
                                                            o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            l_rows_out := NULL;
        
            IF l_blood_crossmatch_popup_show = pk_alert_constant.g_yes
               AND
               i_priority(i) IN
               ( /*pk_blood_products_constant.g_flg_priority_urgent,*/pk_blood_products_constant.g_flg_priority_emergency)
            THEN
                l_flg_req_without_crossmatch := pk_alert_constant.g_yes;
                l_prof_crossmatch            := i_prof.id;
            ELSE
                l_flg_req_without_crossmatch := pk_alert_constant.g_no;
                l_prof_crossmatch            := NULL;
            END IF;
        
            g_error := 'UPDATE BLOOD_PRODUCT_DET';
            ts_blood_product_det.upd(id_blood_product_det_in       => i_blood_product_det(i),
                                     flg_status_in                 => l_status_det,
                                     dt_begin_tstz_in              => l_dt_begin,
                                     dt_blood_product_det_in       => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_order(i),
                                                                                                    NULL),
                                     id_order_recurrence_in        => l_order_recurrence,
                                     id_order_recurrence_nin       => FALSE,
                                     flg_priority_in               => i_priority(i),
                                     flg_priority_nin              => FALSE,
                                     id_special_type_in            => i_special_type(i),
                                     id_special_type_nin           => FALSE,
                                     flg_with_screening_in         => i_screening(i),
                                     flg_with_screening_nin        => FALSE,
                                     flg_without_nat_test_in       => i_without_nat(i),
                                     flg_without_nat_test_nin      => FALSE,
                                     flg_prepare_not_send_in       => i_not_send_unit(i),
                                     flg_prepare_not_send_nin      => FALSE,
                                     id_clinical_purpose_in        => i_clinical_purpose(i),
                                     id_clinical_purpose_nin       => FALSE,
                                     clinical_purpose_notes_in     => i_clinical_purpose_notes(i),
                                     clinical_purpose_notes_nin    => FALSE,
                                     id_exec_institution_in        => i_exec_institution(i),
                                     id_exec_institution_nin       => FALSE,
                                     notes_tech_in                 => i_notes(i),
                                     notes_tech_nin                => FALSE,
                                     id_not_order_reason_in        => l_not_order_reason,
                                     id_not_order_reason_nin       => FALSE,
                                     id_pat_health_plan_in         => i_health_plan(i),
                                     id_pat_health_plan_nin        => FALSE,
                                     id_pat_exemption_in           => i_exemption(i),
                                     id_pat_exemption_nin          => FALSE,
                                     id_co_sign_order_in           => l_id_co_sign,
                                     id_co_sign_order_nin          => FALSE,
                                     id_prof_last_update_in        => i_prof.id,
                                     id_prof_last_update_nin       => FALSE,
                                     dt_last_update_tstz_in        => g_sysdate_tstz,
                                     dt_last_update_tstz_nin       => FALSE,
                                     transfusion_type_in           => i_transf_type(i),
                                     transfusion_type_nin          => FALSE,
                                     qty_exec_in                   => i_qty_exec(i),
                                     qty_exec_nin                  => FALSE,
                                     id_unit_mea_qty_exec_in       => pk_blood_products_constant.g_bp_unit_ml,
                                     id_unit_mea_qty_exec_nin      => FALSE,
                                     special_instr_in              => i_special_instr(i),
                                     special_instr_nin             => FALSE,
                                     flg_req_without_crossmatch_in => l_flg_req_without_crossmatch,
                                     id_prof_crossmatch_in         => l_prof_crossmatch,
                                     id_prof_crossmatch_nin        => FALSE,
                                     rows_out                      => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF i_episode IS NOT NULL
            THEN
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_episode,
                                        i_flg_status => l_status_det,
                                        i_id_record  => i_blood_product_det(i),
                                        i_flg_type   => pk_blood_products_constant.g_bp_type,
                                        o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error     := 'VALIDATE DIAGNOSIS';
                l_diagnosis := table_number();
                IF i_diagnosis(i).tbl_diagnosis.count > 0
                THEN
                    FOR j IN i_diagnosis(i).tbl_diagnosis.first .. i_diagnosis(i).tbl_diagnosis.last
                    LOOP
                        IF i_diagnosis(i).tbl_diagnosis(j).id_diagnosis IS NOT NULL
                            OR i_diagnosis(i).tbl_diagnosis(j).id_diagnosis != -1
                        THEN
                            l_diagnosis.extend;
                            l_diagnosis(l_diagnosis.count) := i_diagnosis(i).tbl_diagnosis(j).id_diagnosis;
                        
                            l_tbl_alert_diagnosis.extend;
                            l_tbl_alert_diagnosis(l_tbl_alert_diagnosis.count) := i_diagnosis(i).tbl_diagnosis(j).id_alert_diagnosis;
                        
                            l_tbl_diag_desc.extend();
                            l_tbl_diag_desc(l_tbl_diag_desc.count) := i_diagnosis(i).tbl_diagnosis(j).desc_diagnosis;
                        END IF;
                    END LOOP;
                END IF;
            
                --Counts not null records
                g_error := 'COUNT EPIS_DIAGNOSIS';
                SELECT COUNT(*)
                  INTO l_count
                  FROM (SELECT /*+opt_estimate(table t rows=1)*/
                         *
                          FROM TABLE(l_diagnosis) t);
            
                --Cancels previously associated diagnosis that don't apply
                g_error := 'CANCEL MCTD_REQ_DIAGNOSIS';
                UPDATE mcdt_req_diagnosis
                   SET flg_status     = pk_alert_constant.g_cancelled,
                       id_prof_cancel = i_prof.id,
                       dt_cancel_tstz = g_sysdate_tstz
                 WHERE (id_mcdt_req_diagnosis IN
                       (SELECT mrd.id_mcdt_req_diagnosis
                           FROM mcdt_req_diagnosis mrd
                           JOIN epis_diagnosis ed
                             ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
                           LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                      column_value, rownum AS rn
                                       FROM TABLE(l_tbl_diag_desc) t) t_desc
                             ON t_desc.column_value = ed.desc_epis_diagnosis
                          WHERE mrd.id_blood_product_det = i_blood_product_det(i)
                            AND mrd.flg_status != pk_blood_products_constant.g_status_det_c
                            AND ((t_desc.column_value IS NULL AND ed.desc_epis_diagnosis IS NOT NULL) OR
                                (mrd.id_alert_diagnosis NOT IN
                                (SELECT /*+opt_estimate(table t rows=1)*/
                                    *
                                     FROM TABLE(l_tbl_alert_diagnosis)) AND ed.desc_epis_diagnosis IS NULL))
                            AND l_count > 0))
                    OR (id_blood_product_det = i_blood_product_det(i) AND
                       flg_status != pk_blood_products_constant.g_status_det_c AND l_count = 0);
            
                g_error := 'I_DIAGNOSIS LOOP';
                IF i_diagnosis(i).tbl_diagnosis IS NOT NULL
                THEN
                    IF i_diagnosis(i).tbl_diagnosis.count > 0
                    THEN
                        g_error := 'CALL PK_DIAGNOSIS.CONCAT_DIAG_ID';
                        l_epis_diagnosis.extend;
                        l_epis_diagnosis := pk_diagnosis.concat_diag_id(i_lang              => i_lang,
                                                                        i_prof              => i_prof,
                                                                        i_exam_req_det      => NULL,
                                                                        i_analysis_req_det  => NULL,
                                                                        i_interv_presc_det  => NULL,
                                                                        i_type              => 'E',
                                                                        i_nurse_tea_req     => NULL,
                                                                        i_exam_result       => NULL,
                                                                        i_blood_product_det => i_blood_product_det(i));
                    
                        l_count := 0;
                        IF l_epis_diagnosis IS NOT NULL
                           AND l_epis_diagnosis.count > 0
                        THEN
                            --Verifies if diagnosis exist
                            g_error := 'SELECT COUNT(*)';
                            SELECT COUNT(*)
                              INTO l_count
                              FROM mcdt_req_diagnosis mrd
                             WHERE mrd.id_blood_product_det = i_blood_product_det(i)
                               AND nvl(mrd.flg_status, '@') != pk_blood_products_constant.g_status_det_c
                               AND mrd.id_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                         *
                                                          FROM TABLE(l_diagnosis) t)
                               AND mrd.id_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                              *
                                                               FROM TABLE(l_epis_diagnosis) t);
                        END IF;
                    
                        IF l_count = 0
                        THEN
                            --Inserts new diagnosis code
                            g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                            IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_epis              => i_episode,
                                                                            i_diag              => i_diagnosis(i),
                                                                            i_exam_req          => NULL,
                                                                            i_analysis_req      => NULL,
                                                                            i_interv_presc      => NULL,
                                                                            i_exam_req_det      => NULL,
                                                                            i_analysis_req_det  => NULL,
                                                                            i_interv_presc_det  => NULL,
                                                                            i_blood_product_req => l_bp_det.id_blood_product_req,
                                                                            i_blood_product_det => i_blood_product_det(i),
                                                                            o_error             => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        ELSIF l_count > 0
                              AND l_count < i_diagnosis(i).tbl_diagnosis.count
                        THEN
                            SELECT DISTINCT t.column_value
                              BULK COLLECT
                              INTO l_diagnosis_new
                              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(l_diagnosis) t) t
                             WHERE t.column_value NOT IN
                                   (SELECT mrd.id_diagnosis
                                      FROM mcdt_req_diagnosis mrd
                                     WHERE mrd.id_blood_product_det = i_blood_product_det(i)
                                       AND mrd.id_epis_diagnosis IN
                                           (SELECT /*+opt_estimate (table t rows=1)*/
                                             *
                                              FROM TABLE(l_epis_diagnosis) t)
                                       AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled);
                        
                            --Inserts new diagnosis code
                            g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                            IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_epis              => i_episode,
                                                                            i_diag              => get_sub_diag_table(i_tbl_diagnosis => i_diagnosis(i),
                                                                                                                      i_sub_diag_list => l_diagnosis_new),
                                                                            i_exam_req          => NULL,
                                                                            i_analysis_req      => NULL,
                                                                            i_interv_presc      => NULL,
                                                                            i_exam_req_det      => NULL,
                                                                            i_analysis_req_det  => NULL,
                                                                            i_interv_presc_det  => NULL,
                                                                            i_blood_product_req => l_bp_det.id_blood_product_req,
                                                                            i_blood_product_det => i_blood_product_det(i),
                                                                            o_error             => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            
                IF i_flg_time(i) != pk_blood_products_constant.g_flg_time_n
                THEN
                    g_error := 'CALL PK_CPOE.SYNC_TASK';
                    IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                             i_prof                 => i_prof,
                                             i_episode              => i_episode,
                                             i_task_type            => pk_blood_products_constant.g_task_type_cpoe_bp,
                                             i_task_request         => i_blood_product_det(i),
                                             i_task_start_timestamp => l_dt_begin,
                                             o_error                => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            g_error             := 'VALIDATE CLINICAL QUESTIONS';
            l_clinical_question := table_number();
            IF i_clinical_question(i).count > 0
            THEN
                FOR j IN i_clinical_question(i).first .. i_clinical_question(i).last
                LOOP
                    l_clinical_question.extend;
                    l_clinical_question(j) := i_clinical_question(i) (j);
                END LOOP;
            END IF;
        
            l_response := table_varchar();
            IF i_response(i).count > 0
            THEN
                FOR j IN i_response(i).first .. i_response(i).last
                LOOP
                    l_response.extend;
                    l_response(j) := i_response(i) (j);
                END LOOP;
            END IF;
        
            l_clinical_question_notes := table_varchar();
            IF i_clinical_question_notes(i).count > 0
            THEN
                FOR j IN i_clinical_question_notes(i).first .. i_clinical_question_notes(i).last
                LOOP
                    l_clinical_question_notes.extend;
                    l_clinical_question_notes(j) := i_clinical_question_notes(i) (j);
                END LOOP;
            END IF;
        
            IF l_clinical_question.count != 0
            THEN
                FOR k IN 1 .. l_clinical_question.count
                LOOP
                    IF l_clinical_question(k) IS NOT NULL
                    THEN
                        IF l_response(k) IS NOT NULL
                        THEN
                            l_aux := pk_utils.str_split(l_response(k), '|');
                        
                            FOR j IN 1 .. l_aux.count
                            LOOP
                                SELECT COUNT(*)
                                  INTO l_count
                                  FROM (SELECT bqr.*,
                                               row_number() over(PARTITION BY bqr.id_questionnaire ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM bp_question_response bqr
                                         WHERE bqr.id_blood_product_det = i_blood_product_det(i)
                                           AND bqr.id_questionnaire = l_clinical_question(k)
                                           AND (bqr.id_response = to_number(l_aux(j)) OR
                                               dbms_lob.substr(bqr.notes, 3800) = l_clinical_question_notes(k)))
                                 WHERE rn = 1;
                            
                                IF l_count = 0
                                THEN
                                    g_error := 'INSERT INTO BP_QUESTION_RESPONSE';
                                    INSERT INTO bp_question_response
                                        (id_bp_question_response,
                                         id_episode,
                                         id_blood_product_det,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_bp_question_response.nextval,
                                         i_episode,
                                         i_blood_product_det(i),
                                         pk_blood_products_constant.g_bp_cq_on_order,
                                         l_clinical_question(k),
                                         to_number(l_aux(j)),
                                         l_clinical_question_notes(k),
                                         i_prof.id,
                                         g_sysdate_tstz);
                                ELSE
                                    SELECT id_bp_question_response,
                                           id_blood_product_det,
                                           id_questionnaire,
                                           id_response,
                                           notes,
                                           flg_time,
                                           id_episode,
                                           id_prof_last_update,
                                           dt_last_update_tstz,
                                           create_user,
                                           create_time,
                                           create_institution,
                                           update_user,
                                           update_time,
                                           update_institution
                                    
                                      INTO l_bp_question_response
                                      FROM (SELECT bpr.*,
                                                   row_number() over(PARTITION BY bpr.id_questionnaire ORDER BY bpr.dt_last_update_tstz DESC NULLS FIRST) rn
                                              FROM bp_question_response bpr
                                             WHERE bpr.id_blood_product_det = i_blood_product_det(i)
                                               AND bpr.id_questionnaire = l_clinical_question(k)
                                               AND (bpr.id_response = to_number(l_aux(j)) OR
                                                   dbms_lob.substr(bpr.notes, 3800) = l_clinical_question_notes(k)))
                                     WHERE rn = 1;
                                
                                    g_error := 'INSERT INTO BP_QUESTION_RESPONSE_HIST';
                                    INSERT INTO bp_question_response_hist
                                        (dt_bp_question_resp_hist,
                                         id_bp_question_response,
                                         id_episode,
                                         id_blood_product_det,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (g_sysdate_tstz,
                                         l_bp_question_response.id_bp_question_response,
                                         l_bp_question_response.id_episode,
                                         l_bp_question_response.id_blood_product_det,
                                         l_bp_question_response.flg_time,
                                         l_bp_question_response.id_questionnaire,
                                         l_bp_question_response.id_response,
                                         l_bp_question_response.notes,
                                         l_bp_question_response.id_prof_last_update,
                                         l_bp_question_response.dt_last_update_tstz);
                                
                                    g_error := 'INSERT INTO BP_QUESTION_RESPONSE';
                                    INSERT INTO bp_question_response
                                        (id_bp_question_response,
                                         id_episode,
                                         id_blood_product_det,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_bp_question_response.nextval,
                                         i_episode,
                                         i_blood_product_det(i),
                                         pk_blood_products_constant.g_bp_cq_on_order,
                                         l_clinical_question(k),
                                         to_number(l_aux(j)),
                                         l_clinical_question_notes(k),
                                         i_prof.id,
                                         g_sysdate_tstz);
                                END IF;
                            END LOOP;
                        ELSE
                            SELECT COUNT(*)
                              INTO l_count
                              FROM (SELECT bqr.*,
                                           row_number() over(PARTITION BY bqr.id_questionnaire ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                      FROM bp_question_response bqr
                                     WHERE bqr.id_blood_product_det = i_blood_product_det(i)
                                       AND bqr.id_questionnaire = l_clinical_question(k)
                                       AND (bqr.id_response IS NULL OR
                                           to_char(dbms_lob.substr(bqr.notes, 3800)) = l_clinical_question_notes(k)))
                             WHERE rn = 1;
                        
                            IF l_count = 0
                            THEN
                                g_error := 'INSERT INTO BP_QUESTION_RESPONSE';
                                INSERT INTO bp_question_response
                                    (id_bp_question_response,
                                     id_episode,
                                     id_blood_product_det,
                                     flg_time,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (seq_bp_question_response.nextval,
                                     i_episode,
                                     i_blood_product_det(i),
                                     pk_blood_products_constant.g_bp_cq_on_order,
                                     l_clinical_question(k),
                                     NULL,
                                     l_clinical_question_notes(k),
                                     i_prof.id,
                                     g_sysdate_tstz);
                            ELSE
                                SELECT id_bp_question_response,
                                       id_blood_product_det,
                                       id_questionnaire,
                                       id_response,
                                       notes,
                                       flg_time,
                                       id_episode,
                                       id_prof_last_update,
                                       dt_last_update_tstz,
                                       create_user,
                                       create_time,
                                       create_institution,
                                       update_user,
                                       update_time,
                                       update_institution
                                
                                  INTO l_bp_question_response
                                  FROM (SELECT bqr.*,
                                               row_number() over(PARTITION BY bqr.id_questionnaire ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM bp_question_response bqr
                                         WHERE bqr.id_blood_product_det = i_blood_product_det(i)
                                           AND bqr.id_questionnaire = l_clinical_question(k)
                                           AND (bqr.id_response IS NULL OR
                                               dbms_lob.substr(bqr.notes, 3800) = l_clinical_question_notes(k)))
                                 WHERE rn = 1;
                            
                                g_error := 'INSERT INTO BP_QUESTION_RESPONSE_HIST';
                                INSERT INTO bp_question_response_hist
                                    (dt_bp_question_resp_hist,
                                     id_bp_question_response,
                                     id_episode,
                                     id_blood_product_det,
                                     flg_time,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (g_sysdate_tstz,
                                     l_bp_question_response.id_bp_question_response,
                                     l_bp_question_response.id_episode,
                                     l_bp_question_response.id_blood_product_det,
                                     l_bp_question_response.flg_time,
                                     l_bp_question_response.id_questionnaire,
                                     l_bp_question_response.id_response,
                                     l_bp_question_response.notes,
                                     l_bp_question_response.id_prof_last_update,
                                     l_bp_question_response.dt_last_update_tstz);
                            
                                g_error := 'INSERT INTO BP_QUESTION_RESPONSE';
                                INSERT INTO bp_question_response
                                    (id_bp_question_response,
                                     id_episode,
                                     id_blood_product_det,
                                     flg_time,
                                     id_questionnaire,
                                     id_response,
                                     notes,
                                     id_prof_last_update,
                                     dt_last_update_tstz)
                                VALUES
                                    (seq_bp_question_response.nextval,
                                     i_episode,
                                     i_blood_product_det(i),
                                     pk_blood_products_constant.g_bp_cq_on_order,
                                     l_clinical_question(k),
                                     NULL,
                                     l_clinical_question_notes(k),
                                     i_prof.id,
                                     g_sysdate_tstz);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
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
                                              'UPDATE_BP_ORDER',
                                              o_error);
            RETURN FALSE;
    END update_bp_order;

    FUNCTION update_bp_status -- interface
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_status        IN blood_product_det.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode episode.id_episode%TYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        ts_blood_product_det.upd(id_blood_product_det_in => i_blood_product_det,
                                 flg_status_in           => i_flg_status,
                                 dt_last_update_tstz_in  => current_timestamp,
                                 id_prof_last_update_in  => i_prof.id,
                                 rows_out                => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BLOOD_PRODUCT_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        SELECT bpr.id_episode
          INTO l_episode
          FROM blood_product_det bpd, blood_product_req bpr
         WHERE bpd.id_blood_product_det = i_blood_product_det
           AND bpd.id_blood_product_req = bpr.id_blood_product_req;
    
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => l_episode,
                                i_flg_status => i_flg_status,
                                i_id_record  => i_blood_product_det,
                                i_flg_type   => pk_blood_products_constant.g_bp_type,
                                o_error      => o_error)
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
                                              'UPDATE_BP_STATUS',
                                              o_error);
            RETURN FALSE;
    END update_bp_status;

    FUNCTION cancel_bp_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN table_number,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        i_flg_interface     IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_qty_given         IN table_number DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_bp_det_bag_return(i_id_blood_product_req blood_product_req.id_blood_product_req%TYPE) IS
            SELECT bpd.id_blood_product_det, bpd.flg_status, qty.column_value AS qty_given
              FROM blood_product_det bpd
              LEFT JOIN (SELECT t.column_value, rownum AS rn
                           FROM TABLE(i_blood_product_det) t) det
                ON det.column_value = bpd.id_blood_product_det
              LEFT JOIN (SELECT t.column_value, rownum AS rn
                           FROM TABLE(i_qty_given) t) qty
                ON qty.rn = det.rn
             WHERE bpd.id_blood_product_req = i_id_blood_product_req
               AND bpd.flg_status NOT IN (pk_blood_products_constant.g_status_det_f,
                                          pk_blood_products_constant.g_status_det_br,
                                          pk_blood_products_constant.g_status_det_d,
                                          pk_blood_products_constant.g_status_det_c);
    
        TYPE t_tbl_det_bag_return IS TABLE OF c_bp_det_bag_return%ROWTYPE;
        l_tbl_det_bag_return t_tbl_det_bag_return := t_tbl_det_bag_return();
    
        l_id_bpd table_number;
    
        l_episode episode.id_episode%TYPE;
    
        l_state       blood_product_det.flg_status%TYPE;
        l_state_final blood_product_det.flg_status%TYPE;
        l_exec_number NUMBER;
    
        l_rows_out table_varchar;
    
        FUNCTION check_ongoing_transfusion(i_id_blood_product_req IN blood_product_req.id_blood_product_req%TYPE)
            RETURN BOOLEAN IS
            l_count NUMBER := 0;
        BEGIN
            SELECT COUNT(*)
              INTO l_count
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req = i_id_blood_product_req
               AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_o,
                                      pk_blood_products_constant.g_status_det_ot,
                                      pk_blood_products_constant.g_status_det_rt,
                                      pk_blood_products_constant.g_status_det_h);
        
            IF l_count > 0
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END check_ongoing_transfusion;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_blood_product_req.count
        LOOP
        
            SELECT bpr.flg_status
              INTO l_state
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_blood_product_req(i);
        
            IF l_state IN (pk_blood_products_constant.g_status_req_r, pk_blood_products_constant.g_status_req_p)
            THEN
                l_state_final := pk_blood_products_constant.g_status_req_c;
            ELSIF check_ongoing_transfusion(i_blood_product_req(i))
            THEN
                l_state_final := pk_blood_products_constant.g_status_req_wr;
            ELSE
                l_state_final := pk_blood_products_constant.g_status_req_d;
            END IF;
        
            ts_blood_product_req.upd(id_blood_product_req_in => i_blood_product_req(i),
                                     flg_status_in           => l_state_final,
                                     id_prof_cancel_in       => i_prof.id,
                                     notes_cancel_in         => i_notes_cancel,
                                     dt_cancel_tstz_in       => g_sysdate_tstz,
                                     id_prof_last_update_in  => i_prof.id,
                                     dt_last_update_tstz_in  => current_timestamp,
                                     id_cancel_reason_in     => i_cancel_reason,
                                     rows_out                => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF i_flg_interface = pk_blood_products_constant.g_no
            THEN
                pk_ia_event_blood_bank.blood_product_req_cancel(i_id_institution       => i_prof.institution,
                                                                i_id_blood_product_req => i_blood_product_req(i));
            END IF;
        
            --DET
            IF l_state_final = pk_blood_products_constant.g_status_req_wr
            THEN
                l_state_final := pk_blood_products_constant.g_status_req_d;
            END IF;
        
            OPEN c_bp_det_bag_return(i_blood_product_req(i));
        
            FETCH c_bp_det_bag_return BULK COLLECT
                INTO l_tbl_det_bag_return;
        
            SELECT bpr.id_episode
              INTO l_episode
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_blood_product_req(i);
        
            FOR j IN l_tbl_det_bag_return.first .. l_tbl_det_bag_return.last
            LOOP
                ts_blood_product_det.upd(id_blood_product_det_in  => l_tbl_det_bag_return(j).id_blood_product_det,
                                         id_cancel_reason_in      => i_cancel_reason,
                                         flg_status_in            => CASE
                                                                         WHEN l_tbl_det_bag_return(j).flg_status IN (pk_blood_products_constant.g_status_det_o,
                                                                                              pk_blood_products_constant.g_status_det_ot,
                                                                                              pk_blood_products_constant.g_status_det_rt,
                                                                                              pk_blood_products_constant.g_status_det_h) THEN
                                                                          pk_blood_products_constant.g_status_det_wr
                                                                         WHEN l_tbl_det_bag_return(j).flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                                                                              pk_blood_products_constant.g_status_det_r_cc,
                                                                                              pk_blood_products_constant.g_status_det_r_w) THEN
                                                                          pk_blood_products_constant.g_status_det_c
                                                                         ELSE
                                                                          l_state_final
                                                                     END,
                                         notes_cancel_in          => i_notes_cancel,
                                         id_prof_cancel_in        => i_prof.id,
                                         dt_cancel_tstz_in        => g_sysdate_tstz,
                                         qty_given_in             => l_tbl_det_bag_return(j).qty_given,
                                         id_unit_mea_qty_given_in => CASE
                                                                         WHEN l_tbl_det_bag_return(j).qty_given IS NOT NULL THEN
                                                                          pk_blood_products_constant.g_bp_unit_ml
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                         rows_out                 => l_rows_out);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BLOOD_PRODUCT_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_id_episode => l_episode,
                                   i_flg_status => CASE
                                                       WHEN l_tbl_det_bag_return(j)
                                                        .flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                                                            pk_blood_products_constant.g_status_det_r_cc,
                                                                            pk_blood_products_constant.g_status_det_r_w) THEN
                                                        pk_blood_products_constant.g_status_det_wr
                                                       WHEN l_tbl_det_bag_return(j)
                                                        .flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                                                            pk_blood_products_constant.g_status_det_r_cc,
                                                                            pk_blood_products_constant.g_status_det_r_w) THEN
                                                        pk_blood_products_constant.g_status_det_c
                                                       ELSE
                                                        l_state_final
                                                   END,
                                   i_id_record  => l_tbl_det_bag_return(j).id_blood_product_det,
                                   i_flg_type   => pk_blood_products_constant.g_bp_type,
                                   o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                BEGIN
                    SELECT COUNT(1)
                      INTO l_exec_number
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = l_tbl_det_bag_return(j).id_blood_product_det;
                END;
            
                ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                               id_blood_product_det_in       => l_tbl_det_bag_return(j).id_blood_product_det,
                                               action_in                     => pk_blood_products_constant.g_bp_action_cancel,
                                               id_prof_performed_in          => i_prof.id,
                                               id_action_reason_in           => i_cancel_reason,
                                               notes_reason_in               => i_notes_cancel,
                                               exec_number_in                => l_exec_number + 1,
                                               id_professional_in            => i_prof.id,
                                               dt_bp_execution_tstz_in       => g_sysdate_tstz);
            
                IF i_flg_interface = pk_blood_products_constant.g_no
                THEN
                    pk_ia_event_blood_bank.blood_prod_detail_cancel(i_id_institution       => i_prof.institution,
                                                                    i_id_blood_product_det => l_tbl_det_bag_return(j).id_blood_product_det);
                END IF;
            END LOOP;
        
            CLOSE c_bp_det_bag_return;
        
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
                                              'CANCEL_BP_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_order;

    FUNCTION cancel_bp_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_blood_product_det     IN table_number,
        i_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel          IN blood_product_req.notes%TYPE,
        i_flg_interface         IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode episode.id_episode%TYPE;
    
        l_state       blood_product_det.flg_status%TYPE;
        l_state_final blood_product_det.flg_status%TYPE;
        l_status_req  blood_product_det.flg_status%TYPE;
    
        l_blood_product_req blood_product_req.id_blood_product_req%TYPE;
        l_exec_number       NUMBER;
    
        l_rows_out table_varchar;
    
        l_qty_given blood_product_det.qty_given%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_blood_product_det.count
        LOOP
        
            SELECT bpd.flg_status
              INTO l_state
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_det = i_blood_product_det(i);
        
            IF l_state IN (pk_blood_products_constant.g_status_det_r_sc, pk_blood_products_constant.g_status_det_r_cc)
            THEN
                l_state_final := pk_blood_products_constant.g_status_det_c;
            ELSIF l_state IN (pk_blood_products_constant.g_status_det_o,
                              pk_blood_products_constant.g_status_det_ot,
                              pk_blood_products_constant.g_status_det_rt,
                              pk_blood_products_constant.g_status_det_h)
            THEN
                l_state_final := pk_blood_products_constant.g_status_det_wr;
            ELSE
                l_state_final := pk_blood_products_constant.g_status_det_d;
            END IF;
        
            BEGIN
                SELECT qty.column_value
                  INTO l_qty_given
                  FROM blood_product_det bpd
                  LEFT JOIN (SELECT t.column_value, rownum AS rn
                               FROM TABLE(i_blood_product_det_qty) t) det
                    ON det.column_value = bpd.id_blood_product_det
                  LEFT JOIN (SELECT t.column_value, rownum AS rn
                               FROM TABLE(i_qty_given) t) qty
                    ON qty.rn = det.rn
                 WHERE bpd.id_blood_product_det = i_blood_product_det(i);
            EXCEPTION
                WHEN no_data_found THEN
                    l_qty_given := NULL;
            END;
        
            ts_blood_product_det.upd(id_blood_product_det_in  => i_blood_product_det(i),
                                     flg_status_in            => l_state_final,
                                     id_cancel_reason_in      => i_cancel_reason,
                                     notes_cancel_in          => i_notes_cancel,
                                     id_prof_cancel_in        => i_prof.id,
                                     dt_cancel_tstz_in        => g_sysdate_tstz,
                                     qty_given_in             => l_qty_given,
                                     id_unit_mea_qty_given_in => CASE
                                                                     WHEN l_qty_given IS NOT NULL THEN
                                                                      pk_blood_products_constant.g_bp_unit_ml
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                     rows_out                 => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BLOOD_PRODUCT_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            SELECT bpr.id_episode
              INTO l_episode
              FROM blood_product_det bpd, blood_product_req bpr
             WHERE bpd.id_blood_product_det = i_blood_product_det(i)
               AND bpd.id_blood_product_req = bpr.id_blood_product_req;
        
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_episode,
                                    i_flg_status => l_state_final,
                                    i_id_record  => i_blood_product_det(i),
                                    i_flg_type   => pk_blood_products_constant.g_bp_type,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            BEGIN
                SELECT COUNT(1)
                  INTO l_exec_number
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det = i_blood_product_det(i);
            END;
        
            ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                           id_blood_product_det_in       => i_blood_product_det(i),
                                           action_in                     => pk_blood_products_constant.g_bp_action_cancel,
                                           id_prof_performed_in          => i_prof.id,
                                           id_action_reason_in           => i_cancel_reason,
                                           notes_reason_in               => i_notes_cancel,
                                           exec_number_in                => l_exec_number + 1,
                                           id_professional_in            => i_prof.id,
                                           dt_bp_execution_tstz_in       => g_sysdate_tstz);
        
            IF i_flg_interface = pk_blood_products_constant.g_no
            THEN
                pk_ia_event_blood_bank.blood_prod_detail_cancel(i_id_institution       => i_prof.institution,
                                                                i_id_blood_product_det => i_blood_product_det(i));
            END IF;
        END LOOP;
    
        SELECT d.id_blood_product_req
          INTO l_blood_product_req
          FROM blood_product_det d
         WHERE d.id_blood_product_det = i_blood_product_det(1);
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_UTILS.GET_BP_STATUS_TO_UPDATE';
        IF pk_blood_products_utils.get_bp_status_to_update(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_blood_product_req => l_blood_product_req,
                                                           o_status            => l_status_req,
                                                           o_error             => o_error)
        THEN
            g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
            IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_blood_product_req => l_blood_product_req,
                                                            i_state             => l_status_req,
                                                            i_cancel_reason     => i_cancel_reason,
                                                            i_notes_cancel      => i_notes_cancel,
                                                            o_error             => o_error)
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
                                              'CANCEL_BP_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_request;

    FUNCTION get_bp_selection_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM (SELECT DISTINCT ht.id_hemo_type,
                                    pk_translation.get_translation(i_lang, ht.code_hemo_type) hemo_name,
                                    decode(bpq.id_bp_questionnaire,
                                           NULL,
                                           pk_blood_products_constant.g_no,
                                           pk_blood_products_constant.g_yes) flg_clinical_question
                      FROM hemo_type ht
                     INNER JOIN hemo_type_instit_soft htsi
                        ON ht.id_hemo_type = htsi.id_hemo_type
                      LEFT JOIN bp_questionnaire bpq
                        ON bpq.id_hemo_type = ht.id_hemo_type
                       AND bpq.id_institution = i_prof.institution
                       AND bpq.flg_available = pk_blood_products_constant.g_yes
                     WHERE htsi.flg_available = pk_blood_products_constant.g_yes
                       AND ht.flg_available = pk_blood_products_constant.g_yes
                       AND htsi.id_software IN (0, i_prof.software)
                       AND htsi.id_institution IN (0, i_prof.institution)) t
             ORDER BY t.hemo_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_selection_list;

    FUNCTION get_bp_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => i_internal_name,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT DISTINCT ht.id_hemo_type data,
                                        pk_translation.get_translation(i_lang, ht.code_hemo_type) label
                          FROM hemo_type ht
                         INNER JOIN hemo_type_instit_soft htsi
                            ON ht.id_hemo_type = htsi.id_hemo_type
                          LEFT JOIN bp_questionnaire bpq
                            ON bpq.id_hemo_type = ht.id_hemo_type
                           AND bpq.id_institution = i_prof.institution
                           AND bpq.flg_available = pk_blood_products_constant.g_yes
                         WHERE htsi.flg_available = pk_blood_products_constant.g_yes
                           AND ht.flg_available = pk_blood_products_constant.g_yes
                           AND htsi.id_software IN (0, i_prof.software)
                           AND htsi.id_institution IN (0, i_prof.institution)) t
                 ORDER BY t.label);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SELECTION_LIST',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_bp_selection_list;

    FUNCTION get_bp_transport_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_list FOR
            SELECT bpr.id_blood_product_req,
                   bpd.id_blood_product_det,
                   bpd.id_hemo_type,
                   (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                         i_prof,
                                                                         bpd.id_blood_product_det,
                                                                         pk_blood_products_constant.g_no)
                      FROM dual) desc_hemo_type,
                   pk_blood_products_utils.get_status_string(i_lang, i_prof, i_episode, bpd.id_blood_product_det) status_string,
                   'BLOOD BANK' place_of_service,
                   pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || r.id_department) destiny,
                   bpd.flg_status
              FROM blood_product_req bpr
              JOIN blood_product_det bpd
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
              JOIN episode e
                ON e.id_episode = bpr.id_episode
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
              LEFT JOIN room r
                ON r.id_room = ei.id_room
             WHERE bpr.id_episode = i_episode
               AND bpd.flg_status IN
                   (pk_blood_products_constant.g_status_det_wt, pk_blood_products_constant.g_status_det_ot);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TRANSPORT_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_transport_listview;

    FUNCTION get_bp_compatibility
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_show_popup       OUT VARCHAR2,
        o_title            OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_shortcut         OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_bp_det        OUT blood_product_det.id_blood_product_det%TYPE,
        o_flg_warning_type OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_sys_config             sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                          i_code_cf => 'BLOOD_INCOMPATIBLE_POPUP_SHOW');
        l_limit                  sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                          i_code_cf => 'BLOOD_TRANSFUSION_TIME_LIMIT');
        l_sys_config_popup_limit sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                          i_code_cf => 'BLOOD_TIME_LIMIT_POPUP_SHOW');
    
        l_message sys_message.desc_message%TYPE;
    
        l_bp_det                table_number;
        l_bp_det_incompatible   table_number;
        l_bp_det_description    table_varchar;
        l_bpe_flg_compatibility table_varchar;
    
        l_dt_begin        blood_product_execution.dt_bp_execution_tstz%TYPE;
        l_elapsed_minutes NUMBER;
    
        l_warning_compatibility BOOLEAN := FALSE;
        l_warning_time_limit    BOOLEAN := FALSE;
    
    BEGIN
    
        IF l_sys_config = pk_alert_constant.g_yes
           OR l_sys_config_popup_limit = pk_alert_constant.g_yes
        THEN
            o_show_popup := pk_alert_constant.g_yes;
        ELSE
            o_show_popup := pk_alert_constant.g_no;
        END IF;
    
        IF l_sys_config = pk_alert_constant.g_yes
        THEN
            SELECT t.id_blood_product_det, t.flg_compatibility
              BULK COLLECT
              INTO l_bp_det, l_bpe_flg_compatibility
              FROM (SELECT bpd.id_blood_product_det,
                           bpe.flg_compatibility,
                           row_number() over(PARTITION BY bpe.id_blood_product_det ORDER BY bpe.exec_number DESC) rn
                      FROM blood_product_req bpr
                     INNER JOIN blood_product_det bpd
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                     INNER JOIN blood_product_execution bpe
                        ON bpe.id_blood_product_det = bpd.id_blood_product_det
                       AND bpe.action = pk_blood_products_constant.g_bp_action_compability
                     WHERE bpr.id_episode = i_episode
                       AND bpd.flg_status NOT IN (pk_blood_products_constant.g_status_det_c,
                                                  pk_blood_products_constant.g_status_det_f,
                                                  pk_blood_products_constant.g_status_det_d,
                                                  pk_blood_products_constant.g_status_det_br,
                                                  pk_blood_products_constant.g_status_det_f,
                                                  pk_blood_products_constant.g_status_det_e,
                                                  pk_blood_products_constant.g_status_det_x,
                                                  pk_blood_products_constant.g_status_det_wr,
                                                  pk_blood_products_constant.g_status_det_or,
                                                  pk_blood_products_constant.g_status_det_cr)) t
             WHERE t.rn = 1;
        
            l_bp_det_incompatible := table_number();
        
            IF l_bp_det.count > 0
            THEN
                FOR i IN 1 .. l_bp_det.count
                LOOP
                    IF l_bpe_flg_compatibility(i) = 'I'
                    THEN
                        l_bp_det_incompatible.extend;
                        l_bp_det_incompatible(l_bp_det_incompatible.count) := l_bp_det(i);
                    END IF;
                END LOOP;
            END IF;
        
            IF l_bp_det_incompatible.count > 0
            THEN
            
                l_bp_det_description := table_varchar();
            
                FOR i IN 1 .. l_bp_det_incompatible.count
                LOOP
                    l_bp_det_description.extend;
                    l_bp_det_description(l_bp_det_description.count) := pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                                                      i_prof,
                                                                                                                      l_bp_det_incompatible(i));
                END LOOP;
            
                l_message := '<b>' || pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => 'BLOOD_PRODUCTS_T129') || '</b>' ||
                             '<br><br>';
            
                FOR i IN 1 .. l_bp_det_description.count
                LOOP
                    l_message := l_message || ' - ' || l_bp_det_description(i) || '<br>';
                END LOOP;
            
                IF l_bp_det_incompatible.count = 1
                THEN
                    SELECT bpd.id_blood_product_req
                      INTO o_id_bp_det
                      FROM blood_product_det bpd
                     WHERE bpd.id_blood_product_det = l_bp_det_incompatible(1);
                END IF;
            
                l_warning_compatibility := TRUE;
            END IF;
        END IF;
    
        IF l_sys_config_popup_limit = pk_alert_constant.g_yes
        THEN
        
            BEGIN
                SELECT MIN(bpe.dt_bp_execution_tstz)
                  INTO l_dt_begin
                  FROM blood_product_det bpd
                  JOIN blood_product_req bpr
                    ON bpr.id_blood_product_req = bpd.id_blood_product_req
                  JOIN blood_product_execution bpe
                    ON bpe.id_blood_product_det = bpd.id_blood_product_det
                 WHERE bpr.id_episode = i_episode
                   AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_r_sc,
                                          pk_blood_products_constant.g_status_det_r_cc,
                                          pk_blood_products_constant.g_status_det_r_w,
                                          pk_blood_products_constant.g_status_det_ot,
                                          pk_blood_products_constant.g_status_det_ct,
                                          pk_blood_products_constant.g_status_det_rt,
                                          pk_blood_products_constant.g_status_det_o,
                                          pk_blood_products_constant.g_status_det_h,
                                          pk_blood_products_constant.g_status_det_df)
                   AND bpe.action = pk_blood_products_constant.g_bp_action_begin_transp
                 GROUP BY bpr.id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_begin := NULL;
            END;
        
            IF l_dt_begin IS NOT NULL
            THEN
                l_elapsed_minutes := pk_date_utils.get_elapsed_minutes_abs_tsz(l_dt_begin);
                IF l_elapsed_minutes >= to_number(l_limit)
                THEN
                    l_message := l_message || CASE
                                     WHEN l_message IS NOT NULL THEN
                                      '<br>'
                                     ELSE
                                      NULL
                                 END || '<b>' || pk_message.get_message(i_lang, i_prof, 'BLOOD_PRODUCTS_T133') || '</b><br>';
                
                    l_warning_time_limit := TRUE;
                END IF;
            END IF;
        
        END IF;
    
        IF (l_sys_config_popup_limit = pk_alert_constant.g_yes OR l_sys_config = pk_alert_constant.g_yes)
           AND l_message IS NOT NULL
        THEN
            IF l_message IS NOT NULL
            THEN
            
                l_message := l_message || '<br><b>' || pk_message.get_message(i_lang, i_prof, 'BLOOD_PRODUCTS_T132') ||
                             '</b>';
            
                o_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M080');
                o_msg   := l_message;
            
                g_error := 'CALL PK_ACCESS.PRELOAD_SHORTCUTS';
                IF NOT pk_access.preload_shortcuts(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_screens => table_varchar('BLOOD_PRODUCTS_DEEPNAV'),
                                                   o_error   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                o_shortcut := pk_access.get_shortcut('BLOOD_PRODUCTS_DEEPNAV');
            
                IF l_warning_compatibility = TRUE
                   AND l_warning_time_limit = TRUE
                THEN
                    o_flg_warning_type := pk_blood_products_constant.g_bp_warning_both;
                ELSIF l_warning_compatibility = TRUE
                THEN
                    o_flg_warning_type := pk_blood_products_constant.g_bp_warning_compatibility;
                ELSIF l_warning_time_limit = TRUE
                THEN
                    o_flg_warning_type := pk_blood_products_constant.g_bp_warning_time_limit;
                END IF;
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
                                              'GET_BP_COMPATIBILITY',
                                              o_error);
            RETURN FALSE;
    END get_bp_compatibility;

    FUNCTION get_bp_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_patient IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'OPEN O_LIST BY ID_HEMO_TYPE';
        OPEN o_list FOR
            SELECT q.id_hemo_type,
                   q.id_questionnaire,
                   q.id_questionnaire_parent,
                   q.id_response_parent,
                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                   i_prof,
                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || q.id_questionnaire) desc_questionnaire,
                   q.flg_type,
                   q.flg_mandatory,
                   q.flg_copy flg_apply_to_all,
                   q.id_unit_measure,
                   pk_mcdt.get_questionnaire_response(i_lang,
                                                      i_prof,
                                                      i_patient,
                                                      q.id_questionnaire,
                                                      i_hemo_type,
                                                      NULL,
                                                      i_flg_time,
                                                      'BP') desc_response,
                   decode(q.flg_validation,
                          pk_blood_products_constant.g_yes,
                          --if date then should return the serialized value stored in the field "notes"
                          decode(instr(q.flg_type, 'D'), 0, to_char(bpqr1.id_response), to_char(bpqr1.notes)),
                          NULL) episode_id_response,
                   decode(q.flg_validation,
                          pk_blood_products_constant.g_yes,
                          decode(dbms_lob.getlength(bpqr1.notes),
                                 NULL,
                                 to_clob(pk_mcdt.get_response_alias(i_lang,
                                                                    i_prof,
                                                                    'RESPONSE.CODE_RESPONSE.' || bpqr1.id_response)),
                                 pk_blood_products_utils.get_bp_response(i_lang, i_prof, bpqr1.notes)),
                          to_clob('')) episode_desc_response
              FROM (SELECT DISTINCT bpq.id_hemo_type,
                                    bpq.id_questionnaire,
                                    qr.id_questionnaire_parent,
                                    qr.id_response_parent,
                                    bpq.flg_type,
                                    bpq.flg_mandatory,
                                    bpq.flg_copy,
                                    bpq.flg_validation,
                                    bpq.id_unit_measure,
                                    bpq.rank
                      FROM bp_questionnaire bpq, questionnaire_response qr
                     WHERE bpq.id_hemo_type = i_hemo_type
                       AND bpq.flg_time = i_flg_time
                       AND bpq.id_institution = i_prof.institution
                       AND bpq.flg_available = pk_blood_products_constant.g_available
                       AND bpq.id_questionnaire = qr.id_questionnaire
                       AND bpq.id_response = qr.id_response
                       AND qr.flg_available = pk_blood_products_constant.g_available
                       AND EXISTS
                     (SELECT 1
                              FROM questionnaire q
                             WHERE q.id_questionnaire = bpq.id_questionnaire
                               AND q.flg_available = pk_blood_products_constant.g_available
                               AND (((l_patient.gender IS NOT NULL AND
                                   coalesce(q.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                                   l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                                   (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                                   nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)))) q,
                   (SELECT id_questionnaire, id_response, notes
                      FROM (SELECT bpqr.id_questionnaire,
                                   pk_procedures_utils.get_procedure_episode_response(i_lang,
                                                                                      i_prof,
                                                                                      i_episode,
                                                                                      bpqr.id_questionnaire) id_response,
                                   bpqr.notes,
                                   row_number() over(PARTITION BY bpqr.id_questionnaire ORDER BY bpqr.dt_last_update_tstz DESC) rn
                              FROM bp_question_response bpqr
                             WHERE bpqr.id_episode = i_episode)
                     WHERE rn = 1) bpqr1
             WHERE q.id_questionnaire = bpqr1.id_questionnaire(+)
             ORDER BY q.rank;
    
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
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_questionnaire;

    FUNCTION get_bp_barcode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_barcode           IN blood_product_det.barcode_lab%TYPE DEFAULT NULL,
        i_details           IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT bpd.barcode_lab,
                   CASE
                        WHEN bpd.qty_given IS NOT NULL THEN
                         bpd.qty_received - bpd.qty_given
                        ELSE
                         bpd.qty_received
                    END qty_received,
                   bpd.id_unit_mea_qty_received,
                   pk_date_utils.date_send_tsz(i_lang, bpd.expiration_date, i_prof) expiration_date,
                   bpd.id_hemo_type,
                   pk_translation.get_translation(i_lang, ht.code_hemo_type) blood_component,
                   bpd.blood_group,
                   (CASE
                        WHEN bpd.qty_given IS NOT NULL THEN
                         bpd.qty_received - bpd.qty_given
                        ELSE
                         bpd.qty_received
                    END || ' ' || nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                                       pk_translation.get_translation(i_lang, um.code_unit_measure))) qty_received_desc,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', bpd.blood_group_rh, NULL) blood_group_rh,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(bpd.id_prof_last_update, bpr.id_professional)) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(bpd.id_prof_last_update, bpr.id_professional),
                                                    NULL) prof_spec_reg,
                   (SELECT pk_blood_products_utils.get_bp_pat_blood_group(i_lang, i_prof, bpr.id_patient)
                      FROM dual) patient_blood_group,
                   bpd.donation_code
              FROM blood_product_det bpd
             INNER JOIN blood_product_req bpr
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
             INNER JOIN hemo_type ht
                ON ht.id_hemo_type = bpd.id_hemo_type
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = bpd.id_unit_mea_qty_received
             WHERE bpd.id_blood_product_det = i_blood_product_det
               AND ((i_barcode IS NOT NULL AND bpd.barcode_lab = i_barcode) OR
                   (i_barcode IS NULL AND i_details = pk_blood_products_constant.g_yes));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_barcode;

    FUNCTION get_bp_donation_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_donation_code     IN blood_product_det.donation_code%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT bpd.barcode_lab,
                   bpd.qty_received,
                   bpd.id_unit_mea_qty_received,
                   pk_date_utils.date_send_tsz(i_lang, bpd.expiration_date, i_prof) expiration_date,
                   bpd.id_hemo_type,
                   pk_translation.get_translation(i_lang, ht.code_hemo_type) blood_component,
                   bpd.blood_group,
                   (bpd.qty_received || ' ' ||
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure_abrv),
                        pk_translation.get_translation(i_lang, um.code_unit_measure))) qty_received_desc,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', bpd.blood_group_rh, NULL) blood_group_rh,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(bpd.id_prof_last_update, bpr.id_professional)) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(bpd.id_prof_last_update, bpr.id_professional),
                                                    NULL) prof_spec_reg,
                   (SELECT pk_blood_products_utils.get_bp_pat_blood_group(i_lang, i_prof, bpr.id_patient)
                      FROM dual) patient_blood_group,
                   bpd.donation_code
              FROM blood_product_det bpd
             INNER JOIN blood_product_req bpr
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
             INNER JOIN hemo_type ht
                ON ht.id_hemo_type = bpd.id_hemo_type
              LEFT JOIN unit_measure um
                ON um.id_unit_measure = bpd.id_unit_mea_qty_received
             WHERE bpd.id_blood_product_det = i_blood_product_det
               AND (i_donation_code IS NOT NULL AND bpd.donation_code = i_donation_code);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DONATION_CODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_donation_code;

    FUNCTION get_bp_blood_group_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN NUMBER IS
        l_rank NUMBER;
    BEGIN
    
        SELECT (MAX(bpe.exec_number) * 10) + 1 AS rank
          INTO l_rank
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action IN (pk_blood_products_constant.g_bp_action_end_transp);
    
        RETURN l_rank;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 1;
    END get_bp_blood_group_rank;

    FUNCTION get_bp_blood_group_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_result_1          OUT VARCHAR2,
        o_result_2          OUT VARCHAR2,
        o_dt_result_1       OUT VARCHAR2,
        o_dt_result_2       OUT VARCHAR2,
        o_result_reg_1      OUT VARCHAR2,
        o_result_reg_2      OUT VARCHAR2,
        o_match_info        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_id_analysis    table_number := table_number();
        l_tbl_id_sample_type table_number := table_number();
        l_tbl_aux            table_varchar := table_varchar();
    
        l_group_config sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'BLOOD_PRODUCTS_GROUP',
                                                                        i_prof    => i_prof);
    
        l_tbl_results     table_varchar := table_varchar();
        l_tbl_dt_results  table_varchar := table_varchar();
        l_tbl_results_reg table_varchar := table_varchar();
    
        l_match_info PLS_INTEGER;
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        SELECT *
          BULK COLLECT
          INTO l_tbl_aux
          FROM TABLE(pk_utils.str_split(i_list => l_group_config, i_delim => '|'));
    
        IF l_tbl_aux.exists(1)
        THEN
            FOR i IN l_tbl_aux.first .. l_tbl_aux.last
            LOOP
                l_tbl_id_analysis.extend;
                l_tbl_id_analysis(i) := pk_utils.str_token(i_string => l_tbl_aux(i), i_token => 1, i_sep => ',');
            
                l_tbl_id_sample_type.extend();
                l_tbl_id_sample_type(i) := pk_utils.str_token(i_string => l_tbl_aux(i), i_token => 2, i_sep => ',');
            
            END LOOP;
        END IF;
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF NOT pk_blood_products_utils.get_analysis_result_blood(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_patient      => l_id_patient,
                                                                 i_analysis     => l_tbl_id_analysis,
                                                                 i_sample_type  => l_tbl_id_sample_type,
                                                                 i_flg_html_det => i_flg_html_det,
                                                                 o_result_data  => l_tbl_results,
                                                                 o_result_date  => l_tbl_dt_results,
                                                                 o_match        => l_match_info,
                                                                 o_result_reg   => l_tbl_results_reg,
                                                                 o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_tbl_results.exists(1)
        THEN
            o_result_1 := l_tbl_results(1);
        ELSE
            o_result_1 := NULL;
        END IF;
    
        IF l_tbl_results.exists(2)
        THEN
            o_result_2 := l_tbl_results(2);
        ELSE
            o_result_2 := NULL;
        END IF;
    
        IF l_tbl_dt_results.exists(1)
        THEN
            o_dt_result_1 := l_tbl_dt_results(1);
        ELSE
            o_dt_result_1 := NULL;
        END IF;
    
        IF l_tbl_dt_results.exists(2)
        THEN
            o_dt_result_2 := l_tbl_dt_results(2);
        ELSE
            o_dt_result_2 := NULL;
        END IF;
    
        IF l_tbl_results_reg.exists(1)
        THEN
            o_result_reg_1 := l_tbl_results_reg(1);
        ELSE
            o_result_reg_1 := NULL;
        END IF;
    
        IF l_tbl_results_reg.exists(2)
        THEN
            o_result_reg_2 := l_tbl_results_reg(2);
        ELSE
            o_result_reg_2 := NULL;
        END IF;
    
        o_match_info := l_match_info;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_bp_blood_group_info;

    FUNCTION get_bp_blood_group_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(4000);
        l_error t_error_out;
    
        l_result_1     VARCHAR2(100);
        l_result_2     VARCHAR2(100);
        l_dt_result_1  VARCHAR2(100);
        l_dt_result_2  VARCHAR2(100);
        l_result_reg_1 VARCHAR2(1000);
        l_result_reg_2 VARCHAR2(1000);
        l_match_info   NUMBER;
    BEGIN
    
        IF NOT get_bp_blood_group_info(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_episode           => i_episode,
                                       i_blood_product_det => i_blood_product_det,
                                       o_result_1          => l_result_1,
                                       o_result_2          => l_result_2,
                                       o_dt_result_1       => l_dt_result_1,
                                       o_dt_result_2       => l_dt_result_2,
                                       o_result_reg_1      => l_result_reg_1,
                                       o_result_reg_2      => l_result_reg_2,
                                       o_match_info        => l_match_info,
                                       o_error             => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        SELECT decode(i_flg_report, pk_alert_constant.g_yes, '<p><b>') ||
                CASE l_match_info
                    WHEN pk_blood_products_constant.g_an_blood_no_result THEN
                     pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T142')
                    WHEN pk_blood_products_constant.g_an_blood_no_confirmed THEN
                     pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T140')
                    WHEN pk_blood_products_constant.g_an_blood_confirmed THEN
                     pk_message.get_message(i_lang, 'COMMON_M046')
                    WHEN pk_blood_products_constant.g_an_blood_no_coincident THEN
                     pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T141')
                END || decode(i_flg_report, pk_alert_constant.g_yes, '</b></p>') || chr(10) || CASE
                    WHEN l_result_1 IS NOT NULL THEN
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') ||
                     ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_M110') || '</b>' || ' ' || l_result_1) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10)
                    ELSE
                     NULL
                END || CASE
                    WHEN l_dt_result_1 IS NOT NULL THEN
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') ||
                     ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T135') || '</b>' || ' ' || l_dt_result_1) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') || l_result_reg_1 ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10) || CASE
                         WHEN l_result_2 IS NOT NULL
                              OR l_dt_result_2 IS NOT NULL THEN
                          decode(i_flg_report, pk_alert_constant.g_yes, '<p>') ||
                          decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10)
                         ELSE
                          NULL
                     END
                    ELSE
                     NULL
                END || CASE
                    WHEN l_result_2 IS NOT NULL THEN
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') ||
                     ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_M110') || '</b>' || ' ' || l_result_2) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10)
                    ELSE
                     NULL
                END || CASE
                    WHEN l_dt_result_2 IS NOT NULL THEN
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') ||
                     ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T135') || '</b>' || ' ' || l_dt_result_2) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>') || chr(10) ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '<p>') || l_result_reg_2 ||
                     decode(i_flg_report, pk_alert_constant.g_yes, '</p>')
                    ELSE
                     NULL
                END
          INTO l_ret
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_end_transp
           AND rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_bp_blood_group_desc;

    --Function to be used for the HTML details
    FUNCTION get_bp_blood_group_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_blood_group_desc  OUT VARCHAR2,
        o_result_1          OUT VARCHAR2,
        o_dt_result_1       OUT VARCHAR2,
        o_result_sig_1      OUT VARCHAR2,
        o_result_2          OUT VARCHAR2,
        o_dt_result_2       OUT VARCHAR2,
        o_result_sig_2      OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_ret   VARCHAR2(4000);
        l_error t_error_out;
    
        l_blood_group_desc VARCHAR2(4000);
        l_result_1         VARCHAR2(200);
        l_result_2         VARCHAR2(200);
        l_dt_result_1      VARCHAR2(200);
        l_dt_result_2      VARCHAR2(200);
        l_result_reg_1     VARCHAR2(200);
        l_result_reg_2     VARCHAR2(200);
        l_match_info       NUMBER;
    
    BEGIN
    
        IF NOT get_bp_blood_group_info(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_episode           => i_episode,
                                       i_blood_product_det => i_blood_product_det,
                                       i_flg_html_det      => pk_alert_constant.g_yes,
                                       o_result_1          => l_result_1,
                                       o_result_2          => l_result_2,
                                       o_dt_result_1       => l_dt_result_1,
                                       o_dt_result_2       => l_dt_result_2,
                                       o_result_reg_1      => l_result_reg_1,
                                       o_result_reg_2      => l_result_reg_2,
                                       o_match_info        => l_match_info,
                                       o_error             => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        SELECT CASE l_match_info
                   WHEN pk_blood_products_constant.g_an_blood_no_result THEN
                    pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T142')
                   WHEN pk_blood_products_constant.g_an_blood_no_confirmed THEN
                    pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T140')
                   WHEN pk_blood_products_constant.g_an_blood_confirmed THEN
                    pk_message.get_message(i_lang, 'COMMON_M046')
                   WHEN pk_blood_products_constant.g_an_blood_no_coincident THEN
                    pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T141')
               END blood_group_desc,
               --ANALYSIS_M110       
               l_result_1 AS result_1,
               --ANALYSIS_T135
               l_dt_result_1  AS dt_result_1,
               l_result_reg_1 AS result_reg_1,
               --ANALYSIS_M110       
               l_result_2 AS result_2,
               --ANALYSIS_T135
               l_dt_result_2  AS dt_result_2,
               l_result_reg_2 AS result_reg_2
          INTO o_blood_group_desc, o_result_1, o_dt_result_1, o_result_sig_1, o_result_2, o_dt_result_2, o_result_sig_2
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_end_transp
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_blood_group_desc := NULL;
            o_result_1         := NULL;
            o_dt_result_1      := NULL;
            o_result_sig_1     := NULL;
            o_result_2         := NULL;
            o_dt_result_2      := NULL;
            o_result_sig_2     := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_bp_blood_group_desc;

    FUNCTION get_bp_lab_mother_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT decode(i_flg_html_det,
                      pk_alert_constant.g_no,
                      '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T145') || ':</b>' || ' ',
                      NULL) || decode(bpe.flg_lab_mother,
                                      pk_alert_constant.g_yes,
                                      pk_message.get_message(i_lang, 'COMMON_M022'),
                                      pk_alert_constant.g_no,
                                      pk_message.get_message(i_lang, 'COMMON_M023'))
          INTO l_ret
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_lab_mother
           AND rownum = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_bp_lab_mother_desc;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_bp_detail t_tbl_bp_task_detail;
    
        l_ident VARCHAR2(3);
        l_rn_cq NUMBER := 0;
    
    BEGIN
    
        l_tbl_bp_detail := pk_blood_products_core.tf_get_bp_detail(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_episode           => i_episode,
                                                                   i_blood_product_det => i_blood_product_det);
        g_error         := 'OPEN O_BP_DETAIL';
        OPEN o_bp_detail FOR
            SELECT *
              FROM TABLE(l_tbl_bp_detail);
    
        --Counts the number o records to be displayed in order to obtain the index
        --on where the clinical questions will be shown.    
        SELECT COUNT(*)
          INTO l_rn_cq
          FROM (SELECT 1
                  FROM blood_product_det bpd
                 INNER JOIN blood_product_req bpr
                    ON bpr.id_blood_product_req = bpd.id_blood_product_req
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                UNION ALL
                SELECT 1
                  FROM blood_product_execution bpe
                  JOIN blood_product_det bpd
                    ON bpd.id_blood_product_det = bpe.id_blood_product_det
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                   AND bpe.action != pk_blood_products_constant.g_bp_action_lab_collected) t;
    
        g_error := 'OPEN O_BP_CLINICAL_QUESTIONS';
        OPEN o_bp_clinical_questions FOR
            SELECT id_blood_product_det, id_content, flg_time, desc_clinical_question, l_rn_cq - 1 rn --For flash processing
              FROM (SELECT id_blood_product_det,
                           id_content,
                           flg_time,
                           id_questionnaire,
                           decode(i_flg_report,
                                  pk_blood_products_constant.g_no,
                                  decode(rownum,
                                         1,
                                         '<b>' || pk_message.get_message(i_lang, i_prof, 'BLOOD_PRODUCTS_T89') || '</b> ' ||
                                         chr(10),
                                         NULL) || l_ident || desc_clinical_question || desc_response,
                                  desc_clinical_question || desc_response) desc_clinical_question
                      FROM (SELECT id_blood_product_det,
                                   id_content,
                                   flg_time,
                                   id_questionnaire,
                                   desc_clinical_question,
                                   desc_response
                              FROM (SELECT DISTINCT bqr1.id_blood_product_det,
                                                    bqr1.id_content,
                                                    bqr1.flg_time,
                                                    bqr1.id_questionnaire,
                                                    '<b>' ||
                                                    pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                    i_prof,
                                                                                    'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                    bqr1.id_questionnaire) || ':</b> ' desc_clinical_question,
                                                    dbms_lob.substr(decode(dbms_lob.getlength(bqr.notes),
                                                                           NULL,
                                                                           to_clob(decode(bqr1.desc_response,
                                                                                          NULL,
                                                                                          '---',
                                                                                          bqr1.desc_response)),
                                                                           pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                                      i_prof,
                                                                                                                      bqr.notes)),
                                                                    3800) desc_response,
                                                    (SELECT pk_blood_products_utils.get_bp_questionnaire_rank(i_lang,
                                                                                                              i_prof,
                                                                                                              bpd.id_hemo_type,
                                                                                                              bqr.id_questionnaire,
                                                                                                              bqr.flg_time)
                                                       FROM dual) rank
                                      FROM (SELECT bqr.id_blood_product_det,
                                                   bqr.id_questionnaire,
                                                   listagg(pk_blood_products_utils.get_questionnaire_id_content(i_lang,
                                                                                                                i_prof,
                                                                                                                bqr.id_questionnaire,
                                                                                                                bqr.id_response),
                                                           '; ') within GROUP(ORDER BY bqr.id_response) id_content,
                                                   bqr.flg_time,
                                                   listagg(pk_mcdt.get_response_alias(i_lang,
                                                                                      i_prof,
                                                                                      'RESPONSE.CODE_RESPONSE.' ||
                                                                                      bqr.id_response),
                                                           '; ') within GROUP(ORDER BY bqr.id_response) desc_response,
                                                   bqr.dt_last_update_tstz,
                                                   row_number() over(PARTITION BY bqr.id_questionnaire, bqr.flg_time ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                              FROM bp_question_response bqr
                                             WHERE bqr.id_blood_product_det = i_blood_product_det
                                             GROUP BY bqr.id_blood_product_det,
                                                      bqr.id_questionnaire,
                                                      bqr.flg_time,
                                                      bqr.dt_last_update_tstz) bqr1,
                                           bp_question_response bqr,
                                           blood_product_det bpd
                                     WHERE bqr1.rn = 1
                                       AND bqr1.id_blood_product_det = bqr.id_blood_product_det
                                       AND bqr1.id_questionnaire = bqr.id_questionnaire
                                       AND bqr1.dt_last_update_tstz = bqr.dt_last_update_tstz
                                       AND bqr1.flg_time = bqr.flg_time
                                       AND bqr.id_blood_product_det = bpd.id_blood_product_det)
                             ORDER BY flg_time, rank));
    
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
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            RETURN FALSE;
    END get_bp_detail;

    FUNCTION get_bp_detail_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
        l_tbl_bp_detail     t_tbl_bp_task_detail;
        l_tbl_bp_detail_rec t_bp_task_detail;
    
        l_tab_dd_block_data     t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_aux t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
        l_tbl_actions table_varchar := table_varchar();
    
        l_tbl_questionnaire t_tbl_bp_clinical_question;
        l_count             NUMBER := 0;
        l_count_qc          NUMBER := 0;
    
    BEGIN
    
        SELECT bpr.id_episode
          INTO l_id_episode
          FROM blood_product_det bpd
          JOIN blood_product_req bpr
            ON bpr.id_blood_product_req = bpd.id_blood_product_req
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        l_tbl_bp_detail := pk_blood_products_core.tf_get_bp_detail(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_episode           => l_id_episode,
                                                                   i_blood_product_det => i_blood_product_det,
                                                                   i_flg_html_det      => pk_alert_constant.g_yes);
    
        FOR i IN l_tbl_bp_detail.first .. l_tbl_bp_detail.last
        LOOP
            l_tbl_actions.extend();
            l_tbl_actions(i) := l_tbl_bp_detail(i).action;
        END LOOP;
    
        FOR i IN l_tbl_bp_detail.first .. l_tbl_bp_detail.last
        LOOP
        
            l_tbl_bp_detail_rec := l_tbl_bp_detail(i);
        
            l_tab_dd_block_data_aux := t_tab_dd_block_data();
        
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       i, --rnk
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_dd_block_data_aux
              FROM (SELECT data_source, data_source_val
                      FROM (SELECT *
                              FROM (SELECT l_tbl_bp_detail_rec.action,
                                           l_tbl_bp_detail_rec.desc_hemo_type,
                                           --l_tbl_bp_detail_rec.instructions,
                                           ' ' instructions,
                                           l_tbl_bp_detail_rec.priority,
                                           l_tbl_bp_detail_rec.special_type,
                                           l_tbl_bp_detail_rec.screening,
                                           l_tbl_bp_detail_rec.nat_test,
                                           l_tbl_bp_detail_rec.send_unit,
                                           l_tbl_bp_detail_rec.desc_time,
                                           l_tbl_bp_detail_rec.order_recurrence,
                                           l_tbl_bp_detail_rec.transfusion_type_desc,
                                           l_tbl_bp_detail_rec.quantity_ordered,
                                           l_tbl_bp_detail_rec.perform_location,
                                           l_tbl_bp_detail_rec.special_instr,
                                           l_tbl_bp_detail_rec.tech_notes,
                                           l_tbl_bp_detail_rec.dt_req,
                                           l_tbl_bp_detail_rec.lab_test_mother,
                                           l_tbl_bp_detail_rec.barcode,
                                           l_tbl_bp_detail_rec.donation_code,
                                           l_tbl_bp_detail_rec.blood_group,
                                           l_tbl_bp_detail_rec.blood_group_rh,
                                           l_tbl_bp_detail_rec.expiration_date,
                                           l_tbl_bp_detail_rec.quantity_received,
                                           l_tbl_bp_detail_rec.condition,
                                           l_tbl_bp_detail_rec.action_reason,
                                           l_tbl_bp_detail_rec.notes,
                                           l_tbl_bp_detail_rec.id_prof_match,
                                           l_tbl_bp_detail_rec.dt_match_tstz,
                                           l_tbl_bp_detail_rec.blood_group_desc,
                                           l_tbl_bp_detail_rec.result_1,
                                           l_tbl_bp_detail_rec.dt_result_1,
                                           l_tbl_bp_detail_rec.result_sig_1,
                                           l_tbl_bp_detail_rec.result_2,
                                           l_tbl_bp_detail_rec.dt_result_2,
                                           l_tbl_bp_detail_rec.result_sig_2,
                                           l_tbl_bp_detail_rec.prof_perform,
                                           l_tbl_bp_detail_rec.start_time,
                                           l_tbl_bp_detail_rec.exec_notes,
                                           l_tbl_bp_detail_rec.desc_perform,
                                           l_tbl_bp_detail_rec.duration,
                                           l_tbl_bp_detail_rec.end_time,
                                           l_tbl_bp_detail_rec.qty_given,
                                           l_tbl_bp_detail_rec.clinical_indication,
                                           l_tbl_bp_detail_rec.desc_diagnosis,
                                           l_tbl_bp_detail_rec.clinical_purpose,
                                           l_tbl_bp_detail_rec.action_notes,
                                           l_tbl_bp_detail_rec.registry,
                                           CASE
                                                WHEN l_tbl_bp_detail_rec.req_statement_without_crossmatch IS NOT NULL THEN
                                                 ' '
                                                ELSE
                                                 NULL
                                            END req_without_crossmatch,
                                           l_tbl_bp_detail_rec.req_statement_without_crossmatch,
                                           l_tbl_bp_detail_rec.req_prof_without_crossmatch
                                      FROM dual) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                          desc_hemo_type,
                                                                                                          instructions,
                                                                                                          priority,
                                                                                                          special_type,
                                                                                                          screening,
                                                                                                          nat_test,
                                                                                                          send_unit,
                                                                                                          desc_time,
                                                                                                          order_recurrence,
                                                                                                          transfusion_type_desc,
                                                                                                          quantity_ordered,
                                                                                                          perform_location,
                                                                                                          special_instr,
                                                                                                          tech_notes,
                                                                                                          dt_req,
                                                                                                          lab_test_mother,
                                                                                                          barcode,
                                                                                                          donation_code,
                                                                                                          blood_group,
                                                                                                          blood_group_rh,
                                                                                                          expiration_date,
                                                                                                          quantity_received,
                                                                                                          condition,
                                                                                                          action_reason,
                                                                                                          notes,
                                                                                                          id_prof_match,
                                                                                                          dt_match_tstz,
                                                                                                          blood_group_desc,
                                                                                                          result_1,
                                                                                                          dt_result_1,
                                                                                                          result_sig_1,
                                                                                                          result_2,
                                                                                                          dt_result_2,
                                                                                                          result_sig_2,
                                                                                                          prof_perform,
                                                                                                          start_time,
                                                                                                          exec_notes,
                                                                                                          desc_perform,
                                                                                                          duration,
                                                                                                          end_time,
                                                                                                          qty_given,
                                                                                                          clinical_indication,
                                                                                                          desc_diagnosis,
                                                                                                          clinical_purpose,
                                                                                                          action_notes,
                                                                                                          registry,
                                                                                                          req_without_crossmatch,
                                                                                                          req_statement_without_crossmatch,
                                                                                                          req_prof_without_crossmatch)))) dd
            
              JOIN dd_block ddb
                ON ddb.area = 'BLOOD_PRODUCTS'
               AND ddb.internal_name = l_tbl_actions(i)
               AND ddb.flg_available = pk_alert_constant.g_yes;
        
            FOR j IN l_tab_dd_block_data_aux.first .. l_tab_dd_block_data_aux.last
            LOOP
                l_tab_dd_block_data.extend();
                l_tab_dd_block_data(l_tab_dd_block_data.count) := l_tab_dd_block_data_aux(j);
            END LOOP;
        
        END LOOP;
    
        l_tbl_questionnaire := pk_blood_products_core.tf_get_bp_clinical_questions(i_lang              => i_lang,
                                                                                   i_prof              => i_prof,
                                                                                   i_blood_product_det => i_blood_product_det,
                                                                                   i_flg_time          => 'O');
        l_count             := l_tbl_bp_detail.count;
        --Check if there are CQs in order to know if the label 'Clinical questions' should be displayed      
        l_count_qc := l_tbl_questionnaire.count;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type <> 'L3CQ' THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L3CQ' THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', flg_type),
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'BLOOD_PRODUCTS'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1' /*, 'L2B'*/))
                UNION ALL
                --Clinical questions
                 (SELECT ddc.data_code_message,
                        'L2B' flg_type,
                        NULL data_source_val,
                        ddc.data_source,
                        (l_count) AS rnk, --To assure they are shown on the Order block
                        ddc.rank,
                        ddc.id_dd_block,
                        0 AS rank_cq,
                        flg_html,
                        flg_clob
                   FROM dd_content ddc
                  WHERE ddc.data_source = 'CLINICAL_QUESTIONS_TITLE'
                    AND ddc.flg_available = pk_alert_constant.g_yes
                    AND ddc.area = 'BLOOD_PRODUCTS'
                    AND flg_type IN ('L2CQ')
                    AND l_count_qc > 0
                 UNION ALL
                 SELECT t_cq.desc_clinical_question data_code_message,
                        flg_type,
                        t_cq.desc_response data_source_val,
                        ddc.data_source,
                        (l_count) AS rnk, --To assure they are shown on the Order block
                        ddc.rank,
                        ddc.id_dd_block,
                        t_cq.rank AS rank_cq,
                        flg_html,
                        flg_clob
                   FROM TABLE(l_tbl_questionnaire) t_cq
                   JOIN dd_content ddc
                     ON ddc.data_source = 'CLINICAL_QUESTIONS'
                    AND ddc.flg_available = pk_alert_constant.g_yes
                    AND ddc.area = 'BLOOD_PRODUCTS'
                  WHERE flg_type IN ('L3CQ'))
                UNION ALL
                --White lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       tt.rn                 rnk,
                       ddc.rank,
                       NULL                  AS id_dd_block,
                       0                     AS rank_cq,
                       flg_html,
                       flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = 'BLOOD_PRODUCTS'
                  JOIN (SELECT DISTINCT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_actions)) tt
                    ON tt.column_value = ddb.internal_name
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'BLOOD_PRODUCTS'
                   AND ddc.flg_type = 'WL')
         ORDER BY rnk DESC, rank, rank_cq;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ' '
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL_HTML',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_bp_detail_html;

    FUNCTION get_bp_detail_history_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
        l_tbl_bp_hist_info  t_tbl_bp_task_detail_hist;
        l_tbl_bp_detail_rec t_bp_task_detail_hist;
    
        l_tab_dd_block_data     t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_data_aux t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
        l_tbl_actions table_varchar := table_varchar();
    
        l_tbl_questionnaire t_tbl_bp_clinical_question;
        l_count             NUMBER := 0;
        l_count_qc          NUMBER := 0;
        l_count_order       NUMBER := 0;
    
        l_tbl_qc_order table_number := table_number();
    
    BEGIN
    
        SELECT bpr.id_episode
          INTO l_id_episode
          FROM blood_product_det bpd
          JOIN blood_product_req bpr
            ON bpr.id_blood_product_req = bpd.id_blood_product_req
         WHERE bpd.id_blood_product_det = i_blood_product_det;
    
        l_tbl_bp_hist_info := pk_blood_products_core.tf_get_bp_detail_history(i_lang              => i_lang,
                                                                              i_prof              => i_prof,
                                                                              i_episode           => l_id_episode,
                                                                              i_blood_product_det => i_blood_product_det,
                                                                              i_flg_report        => pk_alert_constant.g_no,
                                                                              i_flg_html_det      => pk_alert_constant.g_yes);
    
        FOR i IN l_tbl_bp_hist_info.first .. l_tbl_bp_hist_info.last
        LOOP
            l_tbl_actions.extend();
            l_tbl_actions(i) := l_tbl_bp_hist_info(i).action;
        END LOOP;
    
        FOR i IN l_tbl_bp_hist_info.first .. l_tbl_bp_hist_info.last
        LOOP
        
            l_tbl_bp_detail_rec := l_tbl_bp_hist_info(i);
        
            l_tab_dd_block_data_aux := t_tab_dd_block_data();
        
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       i, --rnk
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_dd_block_data_aux
              FROM (SELECT data_source, data_source_val
                      FROM (SELECT *
                              FROM (SELECT l_tbl_bp_detail_rec.action,
                                           l_tbl_bp_detail_rec.desc_hemo_type,
                                           l_tbl_bp_detail_rec.instructions,
                                           l_tbl_bp_detail_rec.priority,
                                           l_tbl_bp_detail_rec.priority_new,
                                           l_tbl_bp_detail_rec.special_type,
                                           l_tbl_bp_detail_rec.special_type_new,
                                           l_tbl_bp_detail_rec.screening,
                                           l_tbl_bp_detail_rec.nat_test,
                                           l_tbl_bp_detail_rec.send_unit,
                                           l_tbl_bp_detail_rec.desc_time,
                                           l_tbl_bp_detail_rec.desc_time_new,
                                           l_tbl_bp_detail_rec.order_recurrence,
                                           l_tbl_bp_detail_rec.transfusion_type_desc,
                                           l_tbl_bp_detail_rec.transfusion_type_desc_new,
                                           l_tbl_bp_detail_rec.quantity_ordered,
                                           l_tbl_bp_detail_rec.quantity_ordered_new,
                                           l_tbl_bp_detail_rec.perform_location,
                                           l_tbl_bp_detail_rec.perform_location_new,
                                           l_tbl_bp_detail_rec.special_instr,
                                           l_tbl_bp_detail_rec.special_instr_new,
                                           l_tbl_bp_detail_rec.tech_notes,
                                           l_tbl_bp_detail_rec.tech_notes_new,
                                           l_tbl_bp_detail_rec.dt_req,
                                           l_tbl_bp_detail_rec.lab_test_mother,
                                           l_tbl_bp_detail_rec.barcode,
                                           l_tbl_bp_detail_rec.donation_code,
                                           l_tbl_bp_detail_rec.blood_group,
                                           l_tbl_bp_detail_rec.blood_group_rh,
                                           l_tbl_bp_detail_rec.expiration_date,
                                           l_tbl_bp_detail_rec.quantity_received,
                                           l_tbl_bp_detail_rec.condition,
                                           l_tbl_bp_detail_rec.action_reason,
                                           l_tbl_bp_detail_rec.notes,
                                           l_tbl_bp_detail_rec.id_prof_match,
                                           l_tbl_bp_detail_rec.dt_match_tstz,
                                           l_tbl_bp_detail_rec.blood_group_desc,
                                           l_tbl_bp_detail_rec.result_1,
                                           l_tbl_bp_detail_rec.dt_result_1,
                                           l_tbl_bp_detail_rec.result_sig_1,
                                           l_tbl_bp_detail_rec.result_2,
                                           l_tbl_bp_detail_rec.dt_result_2,
                                           l_tbl_bp_detail_rec.result_sig_2,
                                           l_tbl_bp_detail_rec.prof_perform,
                                           l_tbl_bp_detail_rec.start_time,
                                           l_tbl_bp_detail_rec.exec_notes,
                                           l_tbl_bp_detail_rec.desc_perform,
                                           l_tbl_bp_detail_rec.duration,
                                           l_tbl_bp_detail_rec.end_time,
                                           l_tbl_bp_detail_rec.qty_given,
                                           l_tbl_bp_detail_rec.clinical_indication,
                                           l_tbl_bp_detail_rec.desc_diagnosis,
                                           l_tbl_bp_detail_rec.desc_diagnosis_new,
                                           l_tbl_bp_detail_rec.clinical_purpose,
                                           l_tbl_bp_detail_rec.clinical_purpose_new,
                                           l_tbl_bp_detail_rec.action_notes,
                                           l_tbl_bp_detail_rec.registry,
                                           CASE
                                                WHEN l_tbl_bp_detail_rec.req_statement_without_crossmatch IS NOT NULL
                                                     OR l_tbl_bp_detail_rec.req_statement_without_crossmatch_new IS NOT NULL THEN
                                                 ' '
                                                ELSE
                                                 NULL
                                            END req_without_crossmatch,
                                           l_tbl_bp_detail_rec.req_statement_without_crossmatch,
                                           l_tbl_bp_detail_rec.req_statement_without_crossmatch_new,
                                           l_tbl_bp_detail_rec.req_prof_without_crossmatch,
                                           l_tbl_bp_detail_rec.req_prof_without_crossmatch_new
                                      FROM dual) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                          desc_hemo_type,
                                                                                                          instructions,
                                                                                                          priority,
                                                                                                          priority_new,
                                                                                                          special_type,
                                                                                                          special_type_new,
                                                                                                          screening,
                                                                                                          nat_test,
                                                                                                          send_unit,
                                                                                                          desc_time,
                                                                                                          desc_time_new,
                                                                                                          order_recurrence,
                                                                                                          transfusion_type_desc,
                                                                                                          transfusion_type_desc_new,
                                                                                                          quantity_ordered,
                                                                                                          quantity_ordered_new,
                                                                                                          perform_location,
                                                                                                          perform_location_new,
                                                                                                          special_instr,
                                                                                                          special_instr_new,
                                                                                                          tech_notes,
                                                                                                          tech_notes_new,
                                                                                                          dt_req,
                                                                                                          lab_test_mother,
                                                                                                          barcode,
                                                                                                          donation_code,
                                                                                                          blood_group,
                                                                                                          blood_group_rh,
                                                                                                          expiration_date,
                                                                                                          quantity_received,
                                                                                                          condition,
                                                                                                          action_reason,
                                                                                                          notes,
                                                                                                          id_prof_match,
                                                                                                          dt_match_tstz,
                                                                                                          blood_group_desc,
                                                                                                          result_1,
                                                                                                          dt_result_1,
                                                                                                          result_sig_1,
                                                                                                          result_2,
                                                                                                          dt_result_2,
                                                                                                          result_sig_2,
                                                                                                          prof_perform,
                                                                                                          start_time,
                                                                                                          exec_notes,
                                                                                                          desc_perform,
                                                                                                          duration,
                                                                                                          end_time,
                                                                                                          qty_given,
                                                                                                          clinical_indication,
                                                                                                          desc_diagnosis,
                                                                                                          desc_diagnosis_new,
                                                                                                          clinical_purpose,
                                                                                                          clinical_purpose_new,
                                                                                                          action_notes,
                                                                                                          registry,
                                                                                                          req_without_crossmatch,
                                                                                                          req_statement_without_crossmatch,
                                                                                                          req_statement_without_crossmatch_new,
                                                                                                          req_prof_without_crossmatch,
                                                                                                          req_prof_without_crossmatch_new)))) dd
            
              JOIN dd_block ddb
                ON ddb.area = 'BLOOD_PRODUCTS'
               AND ddb.internal_name = l_tbl_actions(i)
               AND ddb.flg_available = pk_alert_constant.g_yes;
        
            FOR j IN l_tab_dd_block_data_aux.first .. l_tab_dd_block_data_aux.last
            LOOP
                l_tab_dd_block_data.extend();
                l_tab_dd_block_data(l_tab_dd_block_data.count) := l_tab_dd_block_data_aux(j);
            END LOOP;
        
            --Determine the number of Order blocks in order to know where to display the clinical questions
            IF l_tbl_bp_hist_info(i).action = pk_blood_products_constant.g_bp_action_order
            THEN
                l_count_order := l_count_order + 1;
            END IF;
        
        END LOOP;
    
        l_tbl_questionnaire := pk_blood_products_core.tf_get_bp_clinical_questions(i_lang              => i_lang,
                                                                                   i_prof              => i_prof,
                                                                                   i_blood_product_det => i_blood_product_det,
                                                                                   i_flg_time          => 'O',
                                                                                   i_flg_history       => pk_alert_constant.g_yes);
    
        l_count := l_tbl_bp_hist_info.count;
        --Check if there are CQs in order to know if the label 'Clinical questions' should be displayed
        l_count_qc := l_tbl_questionnaire.count;
        --l_tbl_qc_order is used for the ranking of the clinical questions labels
        FOR i IN 1 .. l_count_order
        LOOP
            l_tbl_qc_order.extend();
            l_tbl_qc_order(i) := i;
        END LOOP;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL
                                       AND flg_type NOT IN ('L3CQ', 'L3CQN') THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  WHEN flg_type IN ('L3CQ', 'L3CQN') THEN
                                   data_code_message
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              decode(flg_type, 'L3CQ', 'L3B', 'L3CQN', 'L3N', flg_type),
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 rank_cq,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'BLOOD_PRODUCTS'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1' /*, 'L2B'*/))
                UNION ALL
                --Clinical qestions
                 (SELECT ddc.data_code_message,
                        'L2B' flg_type,
                        NULL data_source_val,
                        ddc.data_source,
                        (l_count - t.column_value + 1) AS rnk, --To assure they are shown on the Order blocks
                        ddc.rank,
                        ddc.id_dd_block,
                        0 rank_cq,
                        flg_html,
                        flg_clob
                   FROM TABLE(l_tbl_qc_order) t
                   JOIN dd_content ddc
                     ON ddc.data_source = 'CLINICAL_QUESTIONS_TITLE'
                    AND ddc.flg_available = pk_alert_constant.g_yes
                    AND ddc.area = 'BLOOD_PRODUCTS'
                    AND flg_type IN ('L2CQ')
                  WHERE l_count_qc > 0
                 UNION ALL
                 SELECT data_code_message,
                        flg_type,
                        data_source_val,
                        data_source,
                        rnk,
                        rank,
                        id_dd_block,
                        rank_qc,
                        flg_html,
                        flg_clob
                   FROM (( --Original/Previous clinical questions
                          SELECT t_cq.desc_clinical_question data_code_message,
                                  flg_type,
                                  t_cq.desc_response data_source_val,
                                  ddc.data_source,
                                  (l_count - t_cq.num_order + 1) AS rnk, --To assure they are shown on the Order blocks
                                  ddc.rank,
                                  ddc.id_dd_block,
                                  t_cq.num_order,
                                  t_cq.rank + 1 AS rank_qc, --+1 to assure that they are shown afer the new CQ
                                  flg_html,
                                  flg_clob
                            FROM TABLE(l_tbl_questionnaire) t_cq
                            JOIN dd_content ddc
                              ON ddc.data_source = 'CLINICAL_QUESTIONS'
                             AND ddc.flg_available = pk_alert_constant.g_yes
                             AND ddc.area = 'BLOOD_PRODUCTS'
                           WHERE flg_type IN ('L3CQ')
                          UNION ALL
                          --Edited Clinical questions
                          SELECT t_cq.desc_clinical_question_new data_code_message,
                                  flg_type,
                                  t_cq.desc_response_new data_source_val,
                                  ddc.data_source,
                                  (l_count - t_cq.num_order + 1) AS rnk, --To assure they are shown on the Order blocks
                                  ddc.rank,
                                  ddc.id_dd_block,
                                  t_cq.num_order,
                                  t_cq.rank AS rank_qc,
                                  flg_html,
                                  flg_clob
                            FROM TABLE(l_tbl_questionnaire) t_cq
                            JOIN dd_content ddc
                              ON ddc.data_source = 'CLINICAL_QUESTIONS_NEW'
                             AND ddc.flg_available = pk_alert_constant.g_yes
                             AND ddc.area = 'BLOOD_PRODUCTS'
                           WHERE flg_type IN ('L3CQN')
                             AND t_cq.desc_clinical_question_new IS NOT NULL)))
                UNION ALL
                --White lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       tt.rn                 rnk,
                       ddc.rank,
                       NULL                  AS id_dd_block,
                       0                     AS rank_qc,
                       flg_html,
                       flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = 'BLOOD_PRODUCTS'
                  JOIN (SELECT DISTINCT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_actions)) tt
                    ON tt.column_value = ddb.internal_name
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'BLOOD_PRODUCTS'
                   AND ddc.flg_type = 'WL') t
         ORDER BY rnk, rank, t.rank_cq;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ' '
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL_HTML',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_bp_detail_history_html;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ident VARCHAR2(3) := '   ';
        l_rn_cq NUMBER := 0;
    
        l_tbl_bp_hist_info t_tbl_bp_task_detail_hist;
    
    BEGIN
    
        l_tbl_bp_hist_info := tf_get_bp_detail_history(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_episode           => i_episode,
                                                       i_blood_product_det => i_blood_product_det,
                                                       i_flg_report        => i_flg_report);
        g_error            := 'OPEN O_BP_DETAIL';
        OPEN o_bp_detail FOR
            SELECT *
              FROM TABLE(l_tbl_bp_hist_info);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_ident := '';
        ELSE
            l_ident := '   ';
        END IF;
    
        --Counts the number o records to be displayed in order to obtain the index
        --on where the clinical questions will be shown.  
        SELECT COUNT(*)
          INTO l_rn_cq
          FROM (SELECT 1
                  FROM blood_product_det bpd
                 INNER JOIN blood_product_req bpr
                    ON bpr.id_blood_product_req = bpd.id_blood_product_req
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                
                UNION ALL
                
                SELECT 1
                  FROM blood_product_det_hist bpdh
                 INNER JOIN blood_product_det bpd
                    ON bpd.id_blood_product_det = bpdh.id_blood_product_det
                 INNER JOIN blood_product_req bpr
                    ON bpr.id_blood_product_req = bpdh.id_blood_product_req
                 WHERE bpdh.id_blood_product_det = i_blood_product_det
                
                UNION ALL
                
                SELECT 1
                  FROM blood_product_execution bpe
                  JOIN blood_product_det bpd
                    ON bpd.id_blood_product_det = bpe.id_blood_product_det
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                   AND bpe.action != pk_blood_products_constant.g_bp_action_lab_collected);
    
        g_error := 'OPEN O_BP_CLINICAL_QUESTIONS';
        OPEN o_bp_clinical_questions FOR
            SELECT id_blood_product_det,
                   id_content,
                   flg_time,
                   desc_clinical_question,
                   dt_last_update_tstz,
                   num_clinical_question + 1 num_clinical_question,
                   l_rn_cq - rn rn --For flash processing
              FROM (SELECT id_blood_product_det,
                           id_content,
                           flg_time,
                           desc_clinical_question,
                           dt_last_update_tstz,
                           num_clinical_question,
                           row_number() over(PARTITION BY id_content ORDER BY dt_last_update_tstz ASC) rn
                      FROM (SELECT t.id_blood_product_det,
                                   t.id_content,
                                   t.flg_time,
                                   --decode(i_flg_report, pk_blood_products_constant.g_no, t.desc_clinical_question, NULL) desc_clinical_question,
                                   t.desc_clinical_question,
                                   t.dt_last_update_tstz,
                                   row_number() over(PARTITION BY t.id_blood_product_det, t.current_rownum ORDER BY t.current_rownum DESC) num_clinical_question,
                                   t.current_rownum rn
                              FROM (SELECT bqro.id_blood_product_det,
                                           qst.id_content,
                                           bqro.flg_time,
                                           decode(i_flg_report,
                                                   pk_blood_products_constant.g_no,
                                                   CASE
                                                       WHEN bqro.previous_rownum IS NULL THEN
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ':</b> ' || CASE
                                                            WHEN bqro.current_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.current_questionnaire)
                                                        END
                                                       WHEN bqro.flg_new = pk_blood_products_constant.g_yes THEN
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ' ' ||
                                                        lower(pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T236')) || '</b>' || '§' || CASE
                                                            WHEN bqro.current_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.current_questionnaire)
                                                        END || chr(10) || '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ':</b> ' || CASE
                                                            WHEN bqro.previous_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.previous_questionnaire)
                                                        END
                                                       ELSE --WHEN THE ANSWER HAS NOT BEEN CHANGED => SHOW NONTHELESS
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ':</b> ' || CASE
                                                            WHEN bqro.previous_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.previous_questionnaire)
                                                        END
                                                   END,
                                                   CASE
                                                       WHEN bqro.previous_rownum IS NULL THEN
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ':</b> ' || CASE
                                                            WHEN bqro.current_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.current_questionnaire)
                                                        END
                                                       WHEN bqro.flg_new = pk_blood_products_constant.g_yes THEN
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ' ' ||
                                                        lower(pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T236')) || '</b>' || '§' || CASE
                                                            WHEN bqro.current_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.current_questionnaire)
                                                        END
                                                       ELSE --WHEN THE ANSWER HAS NOT BEEN CHANGED => SHOW NONTHELESS
                                                        '<b>' || l_ident ||
                                                        pk_translation.get_translation(i_lang, qst.code_questionnaire) || ':</b> ' || CASE
                                                            WHEN bqro.previous_questionnaire IS NULL THEN
                                                             '---'
                                                            ELSE
                                                             to_char(bqro.previous_questionnaire)
                                                        END
                                                   END) desc_clinical_question,
                                           bqro.current_rownum,
                                           bqro.id_questionnaire,
                                           bqro.dt_last_update_tstz,
                                           bqro.rank
                                      FROM (SELECT erd1.id_questionnaire,
                                                   erd1.id_blood_product_det,
                                                   erd1.notes current_questionnaire,
                                                   erd1.flg_time,
                                                   erd1.dt_last_update_tstz,
                                                   erd1.rn current_rownum,
                                                   erd2.notes previous_questionnaire,
                                                   erd2.rn previous_rownum,
                                                   CASE
                                                        WHEN erd2.rn IS NULL THEN
                                                         pk_blood_products_constant.g_yes
                                                        WHEN to_char(erd1.notes) IS NULL
                                                             AND to_char(erd2.notes) IS NULL THEN
                                                         pk_blood_products_constant.g_no
                                                        WHEN to_char(erd1.notes) = to_char(erd2.notes) THEN
                                                         pk_blood_products_constant.g_no
                                                        ELSE
                                                         pk_blood_products_constant.g_yes
                                                    END AS flg_new,
                                                   (SELECT pk_blood_products_utils.get_bp_questionnaire_rank(i_lang,
                                                                                                             i_prof,
                                                                                                             erd1.id_hemo_type,
                                                                                                             erd1.id_questionnaire,
                                                                                                             erd1.flg_time)
                                                      FROM dual) rank
                                              FROM (SELECT id_questionnaire,
                                                           id_blood_product_det,
                                                           notes,
                                                           flg_time,
                                                           dt_last_update_tstz,
                                                           row_number() over(PARTITION BY id_questionnaire ORDER BY id_questionnaire ASC, dt_last_update_tstz DESC) rn,
                                                           dt_last_update,
                                                           id_hemo_type
                                                      FROM (SELECT *
                                                              FROM (SELECT bqr.id_bp_question_response,
                                                                           bqr.id_blood_product_det,
                                                                           bqr.id_questionnaire,
                                                                           bqr.dt_last_update_tstz,
                                                                           bqr.notes,
                                                                           bqr.flg_time flg_time,
                                                                           row_number() over(PARTITION BY bqr.id_questionnaire, bqr.dt_last_update_tstz ORDER BY bqr.id_bp_question_response) AS rn,
                                                                           pk_date_utils.date_send_tsz(i_lang,
                                                                                                       bqr.dt_last_update_tstz,
                                                                                                       i_prof) dt_last_update,
                                                                           bpd.id_hemo_type
                                                                      FROM bp_question_response bqr
                                                                      JOIN blood_product_det bpd
                                                                        ON bpd.id_blood_product_det = bqr.id_blood_product_det
                                                                     WHERE bpd.id_blood_product_det = i_blood_product_det)
                                                             WHERE rn = 1)) erd1
                                              LEFT JOIN (SELECT id_questionnaire,
                                                               id_blood_product_det,
                                                               notes,
                                                               dt_last_update_tstz,
                                                               row_number() over(PARTITION BY id_questionnaire ORDER BY id_questionnaire ASC, dt_last_update_tstz DESC) rn
                                                          FROM (SELECT *
                                                                  FROM (SELECT bqr.id_bp_question_response,
                                                                               bqr.id_blood_product_det,
                                                                               bqr.id_questionnaire,
                                                                               bqr.dt_last_update_tstz,
                                                                               bqr.notes,
                                                                               row_number() over(PARTITION BY bqr.id_questionnaire, bqr.dt_last_update_tstz ORDER BY bqr.id_bp_question_response) AS rn --Because of multichoice options
                                                                          FROM bp_question_response bqr
                                                                         WHERE bqr.id_blood_product_det = i_blood_product_det)
                                                                 WHERE rn = 1)) erd2
                                                ON erd2.id_questionnaire = erd1.id_questionnaire
                                               AND erd2.id_blood_product_det = erd1.id_blood_product_det
                                               AND erd1.rn = (erd2.rn - 1)
                                             ORDER BY erd1.rn ASC, rank ASC) bqro
                                      JOIN questionnaire qst
                                        ON qst.id_questionnaire = bqro.id_questionnaire) t))
            UNION ALL
            SELECT i_blood_product_det id_blood_product_det,
                   NULL id_content,
                   flg_time,
                   '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T89') || '</b>' desc_clinical_question,
                   dt_last_update_tstz,
                   1 num_clinical_question,
                   l_rn_cq - rownum() rn --For flash processing
              FROM (SELECT bqr.dt_last_update_tstz, bqr.flg_time
                      FROM bp_question_response bqr
                     WHERE bqr.id_blood_product_det = i_blood_product_det
                     GROUP BY bqr.dt_last_update_tstz, bqr.flg_time)
             ORDER BY rn ASC, num_clinical_question ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TASK_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            RETURN FALSE;
    END get_bp_detail_history;

    FUNCTION get_bp_transfusions_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN table_number,
        i_flg_report          IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exec_number_compability NUMBER;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('BLOOD_PRODUCTS_T01',
                                                        'BLOOD_PRODUCTS_T02',
                                                        'BLOOD_PRODUCTS_T03',
                                                        'BLOOD_PRODUCTS_T04',
                                                        'BLOOD_PRODUCTS_T05',
                                                        'BLOOD_PRODUCTS_T08',
                                                        'BLOOD_PRODUCTS_T09',
                                                        'BLOOD_PRODUCTS_T13',
                                                        'BLOOD_PRODUCTS_T14',
                                                        'BLOOD_PRODUCTS_T20',
                                                        'BLOOD_PRODUCTS_T24',
                                                        'BLOOD_PRODUCTS_T25',
                                                        'BLOOD_PRODUCTS_T30',
                                                        'BLOOD_PRODUCTS_T32',
                                                        'BLOOD_PRODUCTS_T33',
                                                        'BLOOD_PRODUCTS_T37',
                                                        'BLOOD_PRODUCTS_T39',
                                                        'BLOOD_PRODUCTS_T40',
                                                        'BLOOD_PRODUCTS_T42',
                                                        'BLOOD_PRODUCTS_T43',
                                                        'BLOOD_PRODUCTS_T51',
                                                        'BLOOD_PRODUCTS_T52',
                                                        'BLOOD_PRODUCTS_T53',
                                                        'BLOOD_PRODUCTS_T54',
                                                        'BLOOD_PRODUCTS_T55',
                                                        'BLOOD_PRODUCTS_T56',
                                                        'BLOOD_PRODUCTS_T57',
                                                        'BLOOD_PRODUCTS_T58',
                                                        'BLOOD_PRODUCTS_T59',
                                                        'BLOOD_PRODUCTS_T60',
                                                        'BLOOD_PRODUCTS_T61',
                                                        'BLOOD_PRODUCTS_T62',
                                                        'BLOOD_PRODUCTS_T63',
                                                        'BLOOD_PRODUCTS_T64',
                                                        'BLOOD_PRODUCTS_T65',
                                                        'BLOOD_PRODUCTS_T66',
                                                        'BLOOD_PRODUCTS_T67',
                                                        'BLOOD_PRODUCTS_T68',
                                                        'BLOOD_PRODUCTS_T69',
                                                        'BLOOD_PRODUCTS_T70',
                                                        'BLOOD_PRODUCTS_T72',
                                                        'BLOOD_PRODUCTS_T73',
                                                        'BLOOD_PRODUCTS_T74',
                                                        'BLOOD_PRODUCTS_T77',
                                                        'BLOOD_PRODUCTS_T78',
                                                        'BLOOD_PRODUCTS_T79',
                                                        'BLOOD_PRODUCTS_T85',
                                                        'BLOOD_PRODUCTS_T86',
                                                        'BLOOD_PRODUCTS_T88',
                                                        'BLOOD_PRODUCTS_T92',
                                                        'BLOOD_PRODUCTS_T93',
                                                        'BLOOD_PRODUCTS_T94',
                                                        'BLOOD_PRODUCTS_T121',
                                                        'BLOOD_PRODUCTS_T128',
                                                        'BLOOD_PRODUCTS_T127',
                                                        'BLOOD_PRODUCTS_T146');
    
        l_epis_documentation         epis_documentation.id_epis_documentation%TYPE := NULL;
        l_notes                      CLOB;
        l_id_blood_product_execution blood_product_execution.id_blood_product_execution%TYPE;
    
        l_tbl_bp_notes t_tbl_blood_product_notes := t_tbl_blood_product_notes();
    
        l_cur_bp_doc_val pk_touch_option_out.t_cur_plain_text_entry;
        l_bp_doc_val     pk_touch_option_out.t_rec_plain_text_entry;
    
        l_count NUMBER(12) := 0;
    
        l_ident VARCHAR2(5) := '     ';
    
        l_result_1     VARCHAR2(200);
        l_result_2     VARCHAR2(200);
        l_dt_result_1  VARCHAR2(200);
        l_dt_result_2  VARCHAR2(200);
        l_result_reg_1 VARCHAR2(1000);
        l_result_reg_2 VARCHAR2(1000);
    
        l_match_info PLS_INTEGER;
    
        l_tbl_bp_execution            t_tbl_bp_execution := t_tbl_bp_execution();
        l_tbl_bp_execution_aux        t_tbl_bp_execution := t_tbl_bp_execution();
        l_tbl_bp_adverse_reaction     t_tbl_bp_adverse_reaction := t_tbl_bp_adverse_reaction();
        l_tbl_bp_adverse_reaction_aux t_tbl_bp_adverse_reaction := t_tbl_bp_adverse_reaction();
        l_tbl_bp_reevaluation         t_tbl_bp_reevaluation := t_tbl_bp_reevaluation();
        l_tbl_bp_reevaluation_aux     t_tbl_bp_reevaluation := t_tbl_bp_reevaluation();
    
    BEGIN
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' ||
                                                     pk_message.get_message(i_lang, i_prof, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_BP_ORDER';
        OPEN o_bp_order FOR
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang, i_prof, i_episode, NULL)))
            SELECT bp.id_blood_product_det,
                   '<b>' || (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                  i_prof,
                                                                                  bp.id_blood_product_det,
                                                                                  pk_blood_products_constant.g_no)
                               FROM dual) || '</b>' hemo_type,
                   aa_code_messages('BLOOD_PRODUCTS_T37') desc_action,
                   l_ident || bp.desc_hemo_type desc_hemo_type,
                   l_ident || bp.quantity_ordered quantity_ordered,
                   bp.registry,
                   bp.qty_received qty_exec
              FROM (SELECT /*+ opt_estimate(table cso rows=2) opt_estimate(table csc rows=2) */
                     bpd.id_blood_product_det,
                     bpd.qty_received,
                     aa_code_messages('BLOOD_PRODUCTS_T20') || (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                                                     i_prof,
                                                                                                                     bpd.id_blood_product_det,
                                                                                                                     pk_blood_products_constant.g_no)
                                                                  FROM dual) desc_hemo_type,
                     aa_code_messages('BLOOD_PRODUCTS_T85') transfusion,
                     decode(bpd.transfusion_type,
                            NULL,
                            NULL,
                            aa_code_messages('BLOOD_PRODUCTS_T02') ||
                            (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                               i_prof,
                                                                               to_number(bpd.transfusion_type))
                               FROM dual)) transfusion_type_desc,
                     decode(bpd.qty_exec,
                            NULL,
                            NULL,
                            aa_code_messages('BLOOD_PRODUCTS_T03') ||
                            (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                 i_prof,
                                                                                 bpd.qty_exec,
                                                                                 bpd.id_unit_mea_qty_exec)
                               FROM dual)) quantity_ordered,
                     decode(bpd.notes_tech,
                            NULL,
                            NULL,
                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T04') || bpd.notes_tech) tech_notes,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                 i_prof.institution,
                                                 i_prof.software) || decode(i_flg_html, pk_alert_constant.g_no, chr(10)) ||
                     pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(bpd.id_prof_last_update, bpr.id_professional)) ||
                     decode(pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             nvl(bpd.id_prof_last_update, bpr.id_professional),
                                                             nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                             bpr.id_episode),
                            NULL,
                            ' ',
                            ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     nvl(bpd.id_prof_last_update, bpr.id_professional),
                                                                     nvl(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                                     bpr.id_episode) || ')') registry
                      FROM blood_product_det bpd
                     INNER JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                      LEFT JOIN cso_table cso
                        ON cso.id_co_sign = bpd.id_co_sign_order
                      LEFT JOIN cso_table csc
                        ON csc.id_co_sign_hist = bpd.id_co_sign_cancel
                     WHERE bpd.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                         t.*
                                                          FROM TABLE(i_blood_product_det) t)) bp;
    
        FOR i IN i_blood_product_det.first .. i_blood_product_det.last
        LOOP
            --obtain template of execution   
            SELECT COUNT(1)
              INTO l_count
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det(i)
               AND bpe.action = pk_blood_products_constant.g_bp_action_administer
               AND bpe.id_epis_documentation IS NOT NULL;
        
            IF (l_count) > 0
            THEN
                DECLARE
                    l_string_aux     CLOB;
                    l_length_title   NUMBER;
                    l_original_title CLOB := '';
                BEGIN
                
                    SELECT id_epis_documentation, id_blood_product_execution
                      INTO l_epis_documentation, l_id_blood_product_execution
                      FROM (SELECT bpe.id_epis_documentation, bpe.id_blood_product_execution
                              FROM blood_product_execution bpe
                             WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                               AND bpe.action = pk_blood_products_constant.g_bp_action_administer
                               AND bpe.id_epis_documentation IS NOT NULL
                             ORDER BY bpe.id_blood_product_execution DESC)
                     WHERE rownum = 1;
                
                    g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES';
                    pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_epis_documentation_list => table_number(l_epis_documentation),
                                                               i_use_html_format         => pk_blood_products_constant.g_yes,
                                                               o_entries                 => l_cur_bp_doc_val);
                
                    FETCH l_cur_bp_doc_val
                        INTO l_bp_doc_val;
                    CLOSE l_cur_bp_doc_val;
                
                    l_notes := REPLACE(l_bp_doc_val.plain_text_entry, chr(10));
                    l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
                    IF i_flg_report = pk_blood_products_constant.g_no
                    THEN
                        l_notes := REPLACE(l_notes, '.<b>', '.<br><b>');
                    END IF;
                
                    --l_notes parse to change the label 'Pre-transfusion vital signs' => Request from Analysis team.
                    l_length_title   := instr(l_notes, ':');
                    l_original_title := substr(l_notes, 1, l_length_title);
                    l_string_aux     := REPLACE(l_notes, l_original_title, aa_code_messages('BLOOD_PRODUCTS_T94'));
                    l_notes          := l_string_aux;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        l_epis_documentation         := NULL;
                        l_id_blood_product_execution := NULL;
                END;
            END IF;
        
            SELECT t_bp_execution(id_blood_product_det       => t.id_blood_product_det,
                                  id_blood_product_execution => t.id_blood_product_execution,
                                  desc_action                => t.desc_action,
                                  registry                   => t.registry,
                                  prof_perform               => t.prof_perform,
                                  start_time                 => t.start_time,
                                  end_time                   => t.end_time,
                                  qty_given                  => t.qty_given,
                                  desc_perform               => t.desc_perform,
                                  id_prof_match              => t.id_prof_match,
                                  dt_match_tstz              => t.dt_match_tstz)
              BULK COLLECT
              INTO l_tbl_bp_execution_aux
              FROM (SELECT bpd.id_blood_product_det,
                           bpe.id_blood_product_execution,
                           aa_code_messages('BLOOD_PRODUCTS_T92') desc_action,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       bpe.dt_bp_execution_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) ||
                           decode(i_flg_html, pk_alert_constant.g_no, chr(10)) ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_professional) ||
                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   bpe.id_professional,
                                                                   bpe.dt_execution,
                                                                   bpr.id_episode),
                                  NULL,
                                  ' ',
                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           bpe.id_professional,
                                                                           bpe.dt_execution,
                                                                           bpr.id_episode) || ') ') registry,
                           decode(bpe.id_prof_performed,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T39') ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_performed)) prof_perform,
                           decode(bpe.dt_begin,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T40') ||
                                  pk_date_utils.date_char_tsz(i_lang, bpe.dt_begin, i_prof.institution, i_prof.software)) start_time,
                           decode(bpe.dt_end,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T42') ||
                                  pk_date_utils.date_char_tsz(i_lang, bpe.dt_end, i_prof.institution, i_prof.software)) end_time,
                           decode(bpe.dt_end,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T121') ||
                                  (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                       i_prof,
                                                                                       bpd.qty_given,
                                                                                       bpd.id_unit_mea_qty_given)
                                     FROM dual)) qty_given,
                           l_ident ||
                           decode(dbms_lob.getlength(l_notes),
                                  NULL,
                                  to_clob(''),
                                  decode(instr(lower(decode(i_flg_report,
                                                            pk_blood_products_constant.g_no,
                                                            REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                                    chr(10),
                                                                    chr(10) || chr(9)),
                                                            REPLACE(l_notes, chr(10) || chr(10), chr(10)))),
                                               '<b>'),
                                         0,
                                         to_clob(aa_code_messages('BLOOD_PRODUCTS_T43') ||
                                                 decode(i_flg_report,
                                                        pk_blood_products_constant.g_no,
                                                        REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                                chr(10),
                                                                chr(10) || chr(9)),
                                                        REPLACE(l_notes, chr(10) || chr(10), chr(10)))),
                                         decode(i_flg_report,
                                                pk_blood_products_constant.g_no,
                                                REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                        chr(10),
                                                        chr(10) || chr(9)),
                                                REPLACE(l_notes, chr(10) || chr(10), chr(10))))) desc_perform,
                           decode(bpe.id_prof_match,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T33') ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_match)) id_prof_match,
                           decode(bpe.dt_match_tstz,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T88') ||
                                  pk_date_utils.date_char_tsz(i_lang,
                                                              bpe.dt_match_tstz,
                                                              i_prof.institution,
                                                              i_prof.software)) dt_match_tstz
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpe.id_blood_product_det = bpd.id_blood_product_det
                      JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                     WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                       AND (bpe.id_blood_product_execution = l_id_blood_product_execution OR
                           l_id_blood_product_execution IS NULL)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_administer) t;
        
            IF l_tbl_bp_execution_aux.exists(1)
            THEN
                FOR j IN l_tbl_bp_execution_aux.first .. l_tbl_bp_execution_aux.last
                LOOP
                    l_tbl_bp_execution.extend();
                    l_tbl_bp_execution(l_tbl_bp_execution.count) := l_tbl_bp_execution_aux(j);
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_BP_EXECUTION';
        OPEN o_bp_execution FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_tbl_bp_execution) t;
    
        FOR i IN i_blood_product_det.first .. i_blood_product_det.last
        LOOP
            --obtain template of adverse reaction   
            l_count := 0;
        
            SELECT COUNT(1)
              INTO l_count
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det(i)
               AND bpe.action = pk_blood_products_constant.g_bp_action_report
               AND bpe.id_epis_documentation IS NOT NULL;
        
            IF l_count > 0
            THEN
                BEGIN
                    SELECT id_epis_documentation, id_blood_product_execution
                      INTO l_epis_documentation, l_id_blood_product_execution
                      FROM (SELECT bpe.id_epis_documentation, bpe.id_blood_product_execution
                              FROM blood_product_execution bpe
                             WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                               AND bpe.action = pk_blood_products_constant.g_bp_action_report
                               AND bpe.id_epis_documentation IS NOT NULL
                             ORDER BY bpe.id_blood_product_execution DESC)
                     WHERE rownum = 1;
                
                    g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES';
                    pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_epis_documentation_list => table_number(l_epis_documentation),
                                                               i_use_html_format         => pk_blood_products_constant.g_yes,
                                                               o_entries                 => l_cur_bp_doc_val);
                
                    FETCH l_cur_bp_doc_val
                        INTO l_bp_doc_val;
                    CLOSE l_cur_bp_doc_val;
                
                    l_notes := NULL;
                    l_notes := REPLACE(l_bp_doc_val.plain_text_entry, chr(10));
                    l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
                
                    IF i_flg_report = pk_blood_products_constant.g_no
                    THEN
                        l_notes := REPLACE(l_notes, '.<b>', '.<br><b>');
                    END IF;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        l_epis_documentation         := NULL;
                        l_id_blood_product_execution := NULL;
                END;
            END IF;
        
            SELECT t_bp_adverse_reaction(id_blood_product_det       => t.id_blood_product_det,
                                         id_blood_product_execution => t.id_blood_product_execution,
                                         desc_action                => t.desc_action,
                                         desc_message               => t.desc_message,
                                         registry                   => t.registry,
                                         desc_perform               => t.desc_perform)
              BULK COLLECT
              INTO l_tbl_bp_adverse_reaction_aux
              FROM (SELECT aa_code_messages('BLOOD_PRODUCTS_T73') desc_action,
                           aa_code_messages('BLOOD_PRODUCTS_T74') desc_message,
                           bpd.id_blood_product_det,
                           bpe.id_blood_product_execution,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       bpe.dt_bp_execution_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) ||
                           decode(i_flg_html, pk_alert_constant.g_no, chr(10)) ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_professional) ||
                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   bpe.id_prof_performed,
                                                                   bpe.dt_bp_execution_tstz,
                                                                   bpr.id_episode),
                                  NULL,
                                  ' ',
                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           bpe.id_prof_performed,
                                                                           bpe.dt_bp_execution_tstz,
                                                                           bpr.id_episode) || ') ') registry,
                           l_ident ||
                           decode(dbms_lob.getlength(l_notes),
                                  NULL,
                                  to_clob(''),
                                  decode(instr(lower(decode(i_flg_report,
                                                            pk_blood_products_constant.g_no,
                                                            REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                                    chr(10),
                                                                    chr(10) || chr(9)),
                                                            REPLACE(l_notes, chr(10) || chr(10), chr(10)))),
                                               '<b>'),
                                         0,
                                         to_clob(aa_code_messages('BLOOD_PRODUCTS_T43') ||
                                                 decode(i_flg_report,
                                                        pk_blood_products_constant.g_no,
                                                        REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                                chr(10),
                                                                chr(10) || chr(9)),
                                                        REPLACE(l_notes, chr(10) || chr(10), chr(10)))),
                                         decode(i_flg_report,
                                                pk_blood_products_constant.g_no,
                                                REPLACE((REPLACE(l_notes, chr(10) || chr(10), chr(10))),
                                                        chr(10),
                                                        chr(10) || chr(9)),
                                                REPLACE(l_notes, chr(10) || chr(10), chr(10))))) desc_perform
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpe.id_blood_product_det = bpd.id_blood_product_det
                      JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                     WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                       AND (bpe.id_blood_product_execution = l_id_blood_product_execution OR
                           l_id_blood_product_execution IS NULL)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_report) t;
        
            IF l_tbl_bp_adverse_reaction_aux.exists(1)
            THEN
                FOR j IN l_tbl_bp_adverse_reaction_aux.first .. l_tbl_bp_adverse_reaction_aux.last
                LOOP
                    l_tbl_bp_adverse_reaction.extend();
                    l_tbl_bp_adverse_reaction(l_tbl_bp_adverse_reaction.count) := l_tbl_bp_adverse_reaction_aux(j);
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_BP_ADVERSE_REACTION';
        OPEN o_bp_adverse_reaction FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_tbl_bp_adverse_reaction) t;
    
        FOR i IN i_blood_product_det.first .. i_blood_product_det.last
        LOOP
            --obtain template of reevaluation   
            l_count := 0;
        
            SELECT COUNT(1)
              INTO l_count
              FROM blood_product_execution bpe
             WHERE bpe.id_blood_product_det = i_blood_product_det(i)
               AND bpe.action = pk_blood_products_constant.g_bp_action_reevaluate
               AND bpe.id_epis_documentation IS NOT NULL;
        
            IF l_count > 0
            THEN
                SELECT t_blood_product_notes(t.id_blood_product_det,
                                             t.id_blood_product_execution,
                                             t.id_epis_documentation,
                                             NULL)
                  BULK COLLECT
                  INTO l_tbl_bp_notes
                  FROM (SELECT bpe.id_blood_product_det, bpe.id_blood_product_execution, bpe.id_epis_documentation
                          FROM blood_product_execution bpe
                         WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                           AND bpe.action = pk_blood_products_constant.g_bp_action_reevaluate
                           AND bpe.id_epis_documentation IS NOT NULL) t;
            
                FOR i IN l_tbl_bp_notes.first .. l_tbl_bp_notes.last
                LOOP
                
                    g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES';
                    pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_epis_documentation_list => table_number(l_tbl_bp_notes(i).l_id_epis_documentation),
                                                               i_use_html_format         => pk_blood_products_constant.g_yes,
                                                               o_entries                 => l_cur_bp_doc_val);
                
                    FETCH l_cur_bp_doc_val
                        INTO l_bp_doc_val;
                    CLOSE l_cur_bp_doc_val;
                
                    l_notes := NULL;
                    l_notes := REPLACE(l_bp_doc_val.plain_text_entry, chr(10));
                    l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
                
                    IF i_flg_report = pk_blood_products_constant.g_no
                    THEN
                        l_notes := REPLACE(l_notes, '.<b>', '.<br><b>');
                    END IF;
                
                    --l_notes parse to change the label 'Pre-transfusion vital signs' => Request from Analysis team.
                    DECLARE
                        l_string_aux     CLOB;
                        l_length_title   NUMBER;
                        l_original_title CLOB := '';
                    BEGIN
                        l_length_title   := instr(l_notes, ':');
                        l_original_title := substr(l_notes, 1, l_length_title);
                        l_string_aux     := REPLACE(l_notes, l_original_title, aa_code_messages('BLOOD_PRODUCTS_T94'));
                        l_notes          := l_string_aux;
                    END;
                
                    l_tbl_bp_notes(i).l_notes := l_notes;
                
                END LOOP;
            END IF;
        
            SELECT t_bp_reevaluation(id_blood_product_det       => t.id_blood_product_det,
                                      id_blood_product_execution => t.id_blood_product_execution,
                                      desc_action                => CASE
                                                                        WHEN rownum = 1 THEN
                                                                         aa_code_messages('BLOOD_PRODUCTS_T74')
                                                                        ELSE
                                                                         NULL
                                                                    END,
                                      registry                   => t.registry,
                                      desc_perform               => t.desc_perform,
                                      prof_perform               => t.prof_perform,
                                      start_time                 => t.start_time)
              BULK COLLECT
              INTO l_tbl_bp_reevaluation_aux
              FROM (SELECT bpd.id_blood_product_det,
                           bpe.id_blood_product_execution,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       bpe.dt_bp_execution_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) ||
                           decode(i_flg_html, pk_alert_constant.g_no, chr(10)) ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_professional) ||
                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   bpe.id_prof_performed,
                                                                   bpe.dt_bp_execution_tstz,
                                                                   bpr.id_episode),
                                  NULL,
                                  ' ',
                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           bpe.id_prof_performed,
                                                                           bpe.dt_bp_execution_tstz,
                                                                           bpr.id_episode) || ') ') registry,
                           l_ident ||
                           decode(dbms_lob.getlength(t.l_notes),
                                  NULL,
                                  to_clob(''),
                                  decode(instr(lower(decode(i_flg_report,
                                                            pk_blood_products_constant.g_no,
                                                            REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                                    chr(10),
                                                                    chr(10) || chr(9)),
                                                            REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                               '<b>'),
                                         0,
                                         to_clob(aa_code_messages('BLOOD_PRODUCTS_T43') ||
                                                 decode(i_flg_report,
                                                        pk_blood_products_constant.g_no,
                                                        REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                                chr(10),
                                                                chr(10) || chr(9)),
                                                        REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                         decode(i_flg_report,
                                                pk_blood_products_constant.g_no,
                                                REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                        chr(10),
                                                        chr(10) || chr(9)),
                                                REPLACE(t.l_notes, chr(10) || chr(10), chr(10))))) desc_perform,
                           decode(bpe.id_prof_performed,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T39') ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_performed)) prof_perform,
                           decode(bpe.dt_begin,
                                  NULL,
                                  NULL,
                                  l_ident || aa_code_messages('BLOOD_PRODUCTS_T93') ||
                                  pk_date_utils.date_char_tsz(i_lang, bpe.dt_begin, i_prof.institution, i_prof.software)) start_time
                      FROM blood_product_execution bpe
                      JOIN blood_product_det bpd
                        ON bpe.id_blood_product_det = bpd.id_blood_product_det
                      JOIN blood_product_req bpr
                        ON bpr.id_blood_product_req = bpd.id_blood_product_req
                      JOIN TABLE(l_tbl_bp_notes) t
                        ON t.l_id_blood_product_det = bpe.id_blood_product_det
                       AND t.l_id_blod_product_execution = bpe.id_blood_product_execution
                     WHERE bpe.id_blood_product_det = i_blood_product_det(i)
                       AND bpe.action = pk_blood_products_constant.g_bp_action_reevaluate
                     ORDER BY bpe.exec_number ASC) t;
        
            IF l_tbl_bp_reevaluation_aux.exists(1)
            THEN
                FOR j IN l_tbl_bp_reevaluation_aux.first .. l_tbl_bp_reevaluation_aux.last
                LOOP
                    l_tbl_bp_reevaluation.extend();
                    l_tbl_bp_reevaluation(l_tbl_bp_reevaluation.count) := l_tbl_bp_reevaluation_aux(j);
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_BP_REEVALUATION';
        OPEN o_bp_reevaluation FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_tbl_bp_reevaluation) t;
    
        g_error := 'OPEN O_BP_BLOOD_GROUP';
        OPEN o_bp_blood_bank FOR
            SELECT bpd.id_blood_product_det,
                   aa_code_messages('BLOOD_PRODUCTS_T77') desc_action,
                   (l_ident || aa_code_messages('BLOOD_PRODUCTS_T20') ||
                   (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                          i_prof,
                                                                          bpd.id_blood_product_det,
                                                                          pk_blood_products_constant.g_yes)
                       FROM dual)) desc_hemo_type,
                   decode(bpd.qty_received,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T32') ||
                          (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                               i_prof,
                                                                               bpd.qty_received,
                                                                               bpd.id_unit_mea_qty_received)
                             FROM dual)) quantity_received,
                   decode(bpd.barcode_lab,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T24') || bpd.barcode_lab) barcode,
                   decode(bpd.blood_group,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T30') || bpd.blood_group) blood_group,
                   decode(bpd.blood_group_rh,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T86') ||
                          pk_sysdomain.get_domain(i_lang,
                                                  i_prof,
                                                  'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS',
                                                  bpd.blood_group_rh,
                                                  NULL)) blood_group_rh,
                   decode(bpd.expiration_date,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T25') ||
                          pk_date_utils.date_char_tsz(i_lang, bpd.expiration_date, i_prof.institution, i_prof.software)) expiration_date,
                   pk_date_utils.date_char_tsz(i_lang, bpe.dt_bp_execution_tstz, i_prof.institution, i_prof.software) ||
                   decode(i_flg_html, pk_alert_constant.g_no, chr(10)) ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_professional) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           bpe.id_professional,
                                                           bpe.dt_bp_execution_tstz,
                                                           bpr.id_episode),
                          NULL,
                          ' ',
                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   bpe.id_professional,
                                                                   bpe.dt_bp_execution_tstz,
                                                                   bpr.id_episode) || ') ') registry,
                   decode((SELECT pk_blood_products_utils.get_bp_compatibility_desc(i_lang,
                                                                                   i_prof,
                                                                                   bpd.id_blood_product_det,
                                                                                   pk_alert_constant.g_yes)
                            FROM dual),
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T128') ||
                          (SELECT pk_blood_products_utils.get_bp_compatibility_desc(i_lang,
                                                                                    i_prof,
                                                                                    bpd.id_blood_product_det,
                                                                                    pk_alert_constant.g_yes)
                             FROM dual)) desc_compatibility,
                   decode((SELECT pk_blood_products_utils.get_bp_compatibility_notes(i_lang,
                                                                                    i_prof,
                                                                                    bpd.id_blood_product_det)
                            FROM dual),
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T127') ||
                          (SELECT pk_blood_products_utils.get_bp_compatibility_notes(i_lang,
                                                                                     i_prof,
                                                                                     bpd.id_blood_product_det)
                             FROM dual)) notes_compatibility,
                   decode(bpd.donation_code,
                          NULL,
                          NULL,
                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T146') || bpd.donation_code) donation_code
              FROM blood_product_det bpd
             INNER JOIN blood_product_req bpr
                ON bpr.id_blood_product_req = bpd.id_blood_product_req
             INNER JOIN blood_product_execution bpe
                ON bpe.id_blood_product_det = bpd.id_blood_product_det
               AND bpe.action = pk_blood_products_constant.g_bp_action_lab_service
             WHERE bpd.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                 t.*
                                                  FROM TABLE(i_blood_product_det) t);
    
        g_error := 'GET BLOOD GROUP INFO';
        IF NOT get_bp_blood_group_info(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_episode           => i_episode,
                                       i_blood_product_det => NULL,
                                       o_result_1          => l_result_1,
                                       o_result_2          => l_result_2,
                                       o_dt_result_1       => l_dt_result_1,
                                       o_dt_result_2       => l_dt_result_2,
                                       o_result_reg_1      => l_result_reg_1,
                                       o_result_reg_2      => l_result_reg_2,
                                       o_match_info        => l_match_info,
                                       o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_BP_GROUP';
        OPEN o_bp_group FOR
            SELECT '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T139') || '</b>' AS header,
                   CASE l_match_info
                       WHEN pk_blood_products_constant.g_an_blood_no_result THEN
                        '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T142') || '</b>'
                       WHEN pk_blood_products_constant.g_an_blood_no_confirmed THEN
                        '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T140') || '</b>'
                       WHEN pk_blood_products_constant.g_an_blood_confirmed THEN
                        '<b>' || pk_message.get_message(i_lang, 'COMMON_M046') || '</b>'
                       WHEN pk_blood_products_constant.g_an_blood_no_coincident THEN
                        '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T141') || '</b>'
                   END confirmation,
                   CASE
                        WHEN l_result_1 IS NOT NULL THEN
                         l_ident ||
                         ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_M110') || '</b>' || ' ' || l_result_1)
                        ELSE
                         NULL
                    END result_1,
                   CASE
                        WHEN l_dt_result_1 IS NOT NULL THEN
                         l_ident ||
                         ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T135') || '</b>' || ' ' || l_dt_result_1) || CASE
                             WHEN l_result_2 IS NOT NULL
                                  OR l_dt_result_2 IS NOT NULL THEN
                              '<br>'
                             ELSE
                              NULL
                         END
                        ELSE
                         NULL
                    END dt_result_1,
                   CASE
                        WHEN l_result_2 IS NOT NULL THEN
                         l_ident ||
                         ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_M110') || '</b>' || ' ' || l_result_2)
                        ELSE
                         NULL
                    END result_2,
                   CASE
                        WHEN l_dt_result_2 IS NOT NULL THEN
                         l_ident ||
                         ('<b>' || pk_message.get_message(i_lang, 'ANALYSIS_T135') || '</b>' || ' ' || l_dt_result_2)
                        ELSE
                         NULL
                    END dt_result_2
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TRANSFUSION_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_bp_order);
            pk_types.open_my_cursor(o_bp_execution);
            pk_types.open_my_cursor(o_bp_adverse_reaction);
            pk_types.open_my_cursor(o_bp_reevaluation);
            pk_types.open_my_cursor(o_bp_blood_bank);
            RETURN FALSE;
    END get_bp_transfusions_summary;

    FUNCTION get_bp_to_edit
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_bp_req                IN table_number,
        i_bp_det                IN table_number,
        o_list                  OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bp_det        table_number := table_number();
        l_count_cq_det  NUMBER := 0;
        l_tbl_hemo_type table_number := table_number();
        l_id_hemo_type  hemo_type.id_hemo_type%TYPE;
    
        CURSOR c_patient IS
            SELECT p.gender, trunc(months_between(SYSDATE, p.dt_birth) / 12) age
              FROM patient p
              JOIN episode e
                ON e.id_patient = p.id_patient
             WHERE e.id_episode = i_episode;
    
        l_patient c_patient%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        IF i_bp_req IS NOT NULL
           AND i_bp_req.count > 0
        THEN
            SELECT id_blood_product_det
              BULK COLLECT
              INTO l_bp_det
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req IN (SELECT /*+ opt_estimate (t rows = 1)*/
                                                 t.column_value
                                                  FROM TABLE(i_bp_req) t)
               AND bpd.flg_status <> pk_blood_products_constant.g_status_req_c;
        ELSE
            l_bp_det := i_bp_det;
        END IF;
    
        OPEN o_list FOR
            WITH cso_table AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang, i_prof, i_episode, NULL)))
            SELECT bpd.id_blood_product_req,
                   bpd.id_blood_product_det,
                   bpd.flg_status,
                   (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                         i_prof,
                                                                         bpd.id_blood_product_det,
                                                                         pk_blood_products_constant.g_no)
                      FROM dual) desc_hemo_type,
                   bpd.qty_exec,
                   bpd.id_unit_mea_qty_exec,
                   (SELECT pk_translation.get_translation(i_lang, code_unit_measure)
                      FROM unit_measure
                     WHERE id_unit_measure = bpd.id_unit_mea_qty_exec) desc_unit_measure,
                   bpd.transfusion_type,
                   decode(bpd.transfusion_type,
                          NULL,
                          NULL,
                          (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                             i_prof,
                                                                             to_number(bpd.transfusion_type))
                             FROM dual)) transfusion_type_desc,
                   bpd.special_instr,
                   decode(bpd.special_instr,
                          NULL,
                          NULL,
                          (SELECT pk_multichoice.get_multichoice_option_desc(i_lang, i_prof, to_number(bpd.special_instr))
                             FROM dual)) special_instr_desc,
                   bpd.id_special_type,
                   decode(bpd.id_special_type,
                          NULL,
                          NULL,
                          (SELECT pk_multichoice.get_multichoice_option_desc(i_lang, i_prof, bpd.id_special_type)
                             FROM dual)) id_special_type_desc,
                   
                   bpd.flg_with_screening,
                   decode(bpd.flg_with_screening,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_with_screening, NULL)) flg_with_screening_desc,
                   bpd.flg_without_nat_test,
                   decode(bpd.flg_without_nat_test,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_without_nat_test, NULL)) flg_without_nat_test_desc,
                   bpd.flg_prepare_not_send,
                   decode(bpd.flg_prepare_not_send,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_prepare_not_send, NULL)) flg_prepare_not_send_desc,
                   pk_diagnosis.concat_diag_id(i_lang,
                                               NULL,
                                               NULL,
                                               NULL,
                                               i_prof,
                                               'D',
                                               NULL,
                                               NULL,
                                               bpd.id_blood_product_det) id_diagnosis,
                   pk_diagnosis.concat_diag_id(i_lang,
                                               NULL,
                                               NULL,
                                               NULL,
                                               i_prof,
                                               'S',
                                               NULL,
                                               NULL,
                                               bpd.id_blood_product_det) id_alert_diagnosis,
                   pk_diagnosis.concat_diag_id(i_lang,
                                               NULL,
                                               NULL,
                                               NULL,
                                               i_prof,
                                               'C',
                                               NULL,
                                               NULL,
                                               bpd.id_blood_product_det) code_diagnosis,
                   pk_diagnosis.concat_diag(i_lang, NULL, NULL, NULL, i_prof, NULL, NULL, bpd.id_blood_product_det) desc_diagnosis,
                   bpd.id_clinical_purpose,
                   decode(bpd.id_clinical_purpose,
                          0,
                          bpd.clinical_purpose_notes,
                          pk_translation.get_translation(i_lang,
                                                         'MULTICHOICE_OPTION.CODE_MULTICHOICE_OPTION.' ||
                                                         bpd.id_clinical_purpose)) clinical_purpose,
                   bpd.flg_priority flg_priority,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'BLOOD_PRODUCT_DET.FLG_PRIORITY', bpd.flg_priority, NULL) priority,
                   decode(nvl(bpr.id_episode, bpr.id_episode_origin), NULL, NULL, bpr.flg_time) flg_time,
                   decode(nvl(bpr.id_episode, bpr.id_episode_origin),
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'BLOOD_PRODUCT_REQ.FLG_TIME', bpr.flg_time, NULL)) desc_time,
                   pk_date_utils.trunc_insttimezone_str(i_prof, bpd.dt_begin_tstz, 'MI') dt_begin_str,
                   pk_date_utils.date_char_tsz(i_lang, bpd.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   bpd.id_order_recurrence,
                   decode(bpd.id_order_recurrence,
                          NULL,
                          pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0'),
                          pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, bpd.id_order_recurrence)) order_recurrence,
                   bpd.id_exec_institution,
                   decode(bpd.id_exec_institution,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(i_lang,
                                                  i_prof,
                                                  'BLOOD_PRODUCT_DET.ID_EXEC_INSTITUTION',
                                                  bpd.id_exec_institution,
                                                  NULL)) perform_location,
                   bpd.id_not_order_reason,
                   pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpd.id_not_order_reason) not_order_reason,
                   bpd.notes notes,
                   bpd.notes_tech,
                   bpd.id_co_sign_order,
                   cso.id_prof_ordered_by id_prof_order,
                   cso.desc_prof_ordered_by prof_order,
                   pk_date_utils.date_send_tsz(i_lang, nvl(cso.dt_ordered_by, bpd.dt_blood_product_det), i_prof) dt_order_str,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(cso.dt_ordered_by, bpd.dt_blood_product_det),
                                               i_prof.institution,
                                               i_prof.software) dt_order,
                   cso.id_order_type,
                   cso.desc_order_type order_type,
                   bpd.id_pat_health_plan,
                   pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'F') financial_entity,
                   pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'H') health_plan,
                   pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'N') insurance_number,
                   bpd.id_pat_exemption,
                   pk_adt.get_pat_exemption_detail(i_lang, i_prof, bpd.id_pat_exemption) exemption,
                   bpd.id_hemo_type
              FROM blood_product_det bpd
              JOIN blood_product_req bpr
                ON bpd.id_blood_product_req = bpr.id_blood_product_req
              LEFT JOIN cso_table cso
                ON cso.id_co_sign = bpd.id_co_sign_order
             WHERE bpd.id_blood_product_det IN (SELECT /*+ opt_estimate (t rows = 1)*/
                                                 t.column_value
                                                  FROM TABLE(l_bp_det) t);
    
        IF l_bp_det.exists(1)
        THEN
            FOR i IN l_bp_det.first .. l_bp_det.last
            LOOP
            
                SELECT bpd.id_hemo_type
                  INTO l_id_hemo_type
                  FROM blood_product_det bpd
                 WHERE bpd.id_blood_product_det = l_bp_det(i);
            
                SELECT COUNT(*)
                  INTO l_count_cq_det
                  FROM bp_questionnaire bpq, questionnaire_response qr
                 WHERE bpq.id_hemo_type = l_id_hemo_type
                   AND bpq.flg_time = pk_blood_products_constant.g_bp_cq_on_order
                   AND bpq.id_institution = i_prof.institution
                   AND bpq.flg_available = pk_blood_products_constant.g_available
                   AND bpq.id_questionnaire = qr.id_questionnaire
                   AND bpq.id_response = qr.id_response
                   AND qr.flg_available = pk_blood_products_constant.g_available
                   AND EXISTS (SELECT 1
                          FROM questionnaire q
                         WHERE q.id_questionnaire = bpq.id_questionnaire
                           AND q.flg_available = pk_blood_products_constant.g_available
                           AND (((l_patient.gender IS NOT NULL AND
                               coalesce(q.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                               l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                               (nvl(l_patient.age, 0) BETWEEN nvl(q.age_min, 0) AND
                               nvl(q.age_max, nvl(l_patient.age, 0)) OR nvl(l_patient.age, 0) = 0)));
            
                IF l_count_cq_det > 0
                THEN
                    l_tbl_hemo_type.extend();
                    l_tbl_hemo_type(l_tbl_hemo_type.count()) := l_id_hemo_type;
                END IF;
            END LOOP;
        END IF;
    
        OPEN o_bp_clinical_questions FOR
            SELECT /*+ opt_estimate (t rows = 1)*/
             t.column_value AS id_hemo_type
              FROM TABLE(l_tbl_hemo_type) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            RETURN FALSE;
    END get_bp_to_edit;

    FUNCTION get_bp_response_to_edit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_blood_product_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time             IN bp_question_response.flg_time%TYPE,
        o_bp_question_response OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_BP_QUESTION_RESPONSE';
        OPEN o_bp_question_response FOR
            SELECT bqr.id_questionnaire, bqr.id_response, bqr.desc_response
              FROM (SELECT bqr.id_questionnaire,
                           bqr.id_response,
                           decode(bqr.id_response,
                                  NULL,
                                  pk_blood_products_utils.get_bp_response(i_lang, i_prof, bqr.notes),
                                  pk_translation.get_translation(i_lang, 'RESPONSE.CODE_RESPONSE.' || bqr.id_response)) desc_response,
                           row_number() over(PARTITION BY bqr.id_questionnaire ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                      FROM bp_question_response bqr
                     WHERE bqr.id_blood_product_det = i_blood_product_det
                       AND bqr.flg_time = i_flg_time) bqr
             WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_RESPONSE_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_bp_question_response);
            RETURN FALSE;
    END get_bp_response_to_edit;

    FUNCTION get_bp_to_match_and_revise
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_list_match_screen OUT pk_types.cursor_type,
        o_list_revised      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_cfg t_tbl_config_table;
    
    BEGIN
    
        g_error   := 'CALL PK_CORE_CONFIG.TF_CONFIG';
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_config_table => 'BP_MATCH_SCREENS',
                                              i_prof_dcs     => table_number(NULL),
                                              i_episode      => i_episode);
    
        OPEN o_list_match_screen FOR
            SELECT /*+ opt_estimate(table cfg rows=1) */
             cfg.id_config,
             cfg.id_inst_owner,
             cfg.field_01      flg_begin_trsp,
             cfg.field_02      flg_end_trsp,
             cfg.field_03      flg_administer
              FROM TABLE(l_tbl_cfg) cfg
             WHERE cfg.id_record = 1;
    
        OPEN o_list_revised FOR
            SELECT /*+ opt_estimate(table cfg rows=1) */
             cfg.id_config,
             cfg.id_inst_owner,
             cfg.field_01      flg_begin_trsp,
             cfg.field_02      flg_end_trsp,
             cfg.field_03      flg_administer
              FROM TABLE(l_tbl_cfg) cfg
             WHERE cfg.id_record = 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TO_MATCH_AND_REVISE',
                                              o_error);
            pk_types.open_my_cursor(o_list_match_screen);
            pk_types.open_my_cursor(o_list_revised);
            RETURN FALSE;
    END get_bp_to_match_and_revise;

    FUNCTION get_bp_action_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_subject               IN action.subject%TYPE,
        i_from_state            IN action.from_state%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_actions               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status_req       blood_product_req.flg_status%TYPE := NULL;
        l_count_status_req NUMBER := 0;
        l_count_req        NUMBER;
    
        l_count_records NUMBER := 0;
    
        l_count_not_editable NUMBER := 0;
    
    BEGIN
    
        g_error := 'COUNT status_req';
        SELECT COUNT(1)
          INTO l_count_status_req
          FROM (SELECT DISTINCT bpr.flg_status
                  FROM blood_product_req bpr
                 WHERE bpr.id_blood_product_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                     *
                                                      FROM TABLE(i_tbl_blood_product_req) t));
    
        l_count_req := i_tbl_blood_product_req.count();
    
        IF l_count_status_req = 1
        THEN
            g_error := 'GET l_status_req';
            SELECT bpr.flg_status
              INTO l_status_req
              FROM blood_product_req bpr
             WHERE bpr.id_blood_product_req = i_tbl_blood_product_req(1);
        END IF;
    
        g_error := 'GET l_count_records';
        SELECT COUNT(*)
          INTO l_count_records
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(i_tbl_blood_product_req) t)
           AND bpd.flg_status NOT IN (pk_blood_products_constant.g_status_det_o,
                                      pk_blood_products_constant.g_status_det_c,
                                      pk_blood_products_constant.g_status_det_f,
                                      pk_blood_products_constant.g_status_det_d,
                                      pk_blood_products_constant.g_status_det_h,
                                      pk_blood_products_constant.g_status_det_br);
    
        --Check how many records there are already on the blood_product_execution table
        --If there are records on that table, the requisition can no longer be edited   
        SELECT COUNT(*)
          INTO l_count_not_editable
          FROM blood_product_det bpd
          JOIN blood_product_execution bpe
            ON bpe.id_blood_product_det = bpd.id_blood_product_det
          JOIN blood_product_req bpr
            ON bpr.id_blood_product_req = bpd.id_blood_product_req
         WHERE bpd.id_blood_product_req IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             *
                                              FROM TABLE(i_tbl_blood_product_req) t)
           AND (bpd.flg_status <> pk_blood_products_constant.g_status_req_c OR
               bpr.flg_status = pk_blood_products_constant.g_status_req_c)
           AND bpe.action NOT IN
               (pk_blood_products_constant.g_bp_action_lab_mother, pk_blood_products_constant.g_bp_action_lab_mother_id);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr,
                   a.desc_action,
                   a.icon,
                   a.flg_default, --default action
                   CASE
                        WHEN l_status_req IS NULL
                             AND a.to_state <> pk_blood_products_constant.g_status_req_c THEN
                         pk_blood_products_constant.g_inactive
                        WHEN l_status_req = pk_blood_products_constant.g_status_req_df THEN
                         pk_blood_products_constant.g_inactive
                        WHEN a.to_state = l_status_req THEN
                         pk_blood_products_constant.g_inactive
                        WHEN l_status_req IN (pk_blood_products_constant.g_status_req_c,
                                              pk_blood_products_constant.g_status_req_f,
                                              pk_blood_products_constant.g_status_req_d,
                                              pk_blood_products_constant.g_status_det_wr)
                             AND a.to_state IN (pk_blood_products_constant.g_status_req_c,
                                                pk_blood_products_constant.g_status_det_h,
                                                pk_blood_products_constant.g_status_det_o) THEN
                         pk_blood_products_constant.g_inactive
                        WHEN l_status_req IN
                             (pk_blood_products_constant.g_status_req_r, pk_blood_products_constant.g_status_req_p)
                             AND a.to_state IN
                             (pk_blood_products_constant.g_status_det_h, pk_blood_products_constant.g_status_det_o) THEN
                         pk_blood_products_constant.g_inactive
                        WHEN a.to_state = pk_blood_products_constant.g_status_det_h
                             AND l_count_records > 0 THEN
                         pk_blood_products_constant.g_inactive
                        WHEN a.to_state = pk_blood_products_constant.g_status_req_e
                             AND (l_count_not_editable > 0 OR l_count_req > 1) THEN
                         pk_blood_products_constant.g_inactive
                        ELSE
                         a.flg_active
                    END AS flg_active, --action's state
                   a.action,
                   a.to_state
              FROM TABLE(pk_action.tf_get_actions_with_exceptions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_ACTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_bp_action_list;

    FUNCTION get_bp_cross_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN table_varchar,
        i_blood_product_det IN table_number,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_department            department.id_department%TYPE;
        l_confirm_transfusion_needed VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count_confirmations        PLS_INTEGER := 0;
        l_count_bags                 PLS_INTEGER := i_blood_product_det.count;
        l_config                     t_config;
        l_prof_cat                   category.flg_type%TYPE;
    
    BEGIN
    
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        l_epis_department := pk_episode.get_epis_department(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        l_config := pk_core_config.get_config(i_area             => 'TRANSFUSION_CONFIRMATION',
                                              i_prof             => i_prof,
                                              i_market           => NULL,
                                              i_category         => NULL,
                                              i_profile_template => NULL,
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        SELECT decode(cnt, 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_confirm_transfusion_needed
          FROM (SELECT COUNT(1) AS cnt
                  FROM v_transfusion_confirmation v
                 WHERE v.id_config = l_config.id_config
                   AND v.id_department = l_epis_department);
    
        SELECT COUNT(1)
          INTO l_count_confirmations
          FROM (SELECT DISTINCT bpe.id_blood_product_det
                  FROM blood_product_execution bpe
                 WHERE bpe.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     t.*
                                                      FROM TABLE(i_blood_product_det) t)
                   AND bpe.action = 'CONFIRM_TRANSFUSION');
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l "LEVEL",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   CASE action
                        WHEN 'CONFIRM_TRANSFUSION' THEN
                         CASE
                             WHEN l_confirm_transfusion_needed = pk_alert_constant.g_yes THEN
                              decode(l_prof_cat,
                                     pk_alert_constant.g_cat_type_doc,
                                     decode(l_count_confirmations, l_count_bags, pk_alert_constant.g_inactive, MAX(flg_active)),
                                     pk_alert_constant.g_inactive)
                             ELSE
                              pk_alert_constant.g_inactive
                         END
                        WHEN 'ADMIN' THEN
                         CASE
                             WHEN l_confirm_transfusion_needed = pk_alert_constant.g_yes THEN
                              decode(l_count_confirmations, l_count_bags, MAX(flg_active), pk_alert_constant.g_inactive)
                             ELSE
                              MAX(flg_active)
                         END
                        ELSE
                         MAX(flg_active)
                    END flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT id_action,
                           id_parent,
                           LEVEL l,
                           to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           icon,
                           decode(flg_default, 'D', 'Y', 'N') flg_default,
                           nvl(pk_action.get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                           internal_name action,
                           a.from_state,
                           rank
                      FROM action a
                     WHERE subject = i_subject
                       AND from_state IN (SELECT *
                                            FROM TABLE(i_from_state))
                    CONNECT BY PRIOR id_action = id_parent
                     START WITH id_parent IS NULL)
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (SELECT COUNT(*)
                                          FROM TABLE(table_varchar() MULTISET UNION DISTINCT i_from_state))
             ORDER BY "LEVEL", rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_CROSS_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_bp_cross_actions;

    FUNCTION get_bp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_domain IN sys_domain.code_domain%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_list FOR
            SELECT val data, rank, desc_val label
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, i_domain, NULL)) s
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_list;

    FUNCTION get_bp_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_software software.id_software%TYPE;
        l_flg_time sys_config.value%TYPE;
    
    BEGIN
    
        l_flg_time := pk_sysconfig.get_config('FLG_TIME_E', i_prof.institution, i_prof.software);
    
        SELECT MAX(etsi.id_software) keep(dense_rank FIRST ORDER BY etsi.id_institution DESC) id_software
          INTO l_software
          FROM epis_type_soft_inst etsi
         WHERE etsi.id_institution IN (0, i_prof.institution)
           AND etsi.id_epis_type = i_epis_type;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT val data,
                   rank,
                   desc_val label,
                   decode(l_flg_time, val, pk_blood_products_constant.g_yes, pk_blood_products_constant.g_no) flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                  decode(i_epis_type,
                                                                         NULL,
                                                                         i_prof,
                                                                         profissional(i_prof.id,
                                                                                      i_prof.institution,
                                                                                      l_software)),
                                                                  'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                  NULL));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TIME_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_time_list;

    FUNCTION get_bp_time_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_software  software.id_software%TYPE;
        l_flg_time  sys_config.value%TYPE;
        l_epis_type epis_type.id_epis_type%TYPE;
    
        l_ret t_tbl_core_domain;
    
    BEGIN
    
        l_flg_time := pk_sysconfig.get_config('FLG_TIME_E', i_prof.institution, i_prof.software);
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        SELECT MAX(etsi.id_software) keep(dense_rank FIRST ORDER BY etsi.id_institution DESC) id_software
          INTO l_software
          FROM epis_type_soft_inst etsi
         WHERE etsi.id_institution IN (0, i_prof.institution)
           AND etsi.id_epis_type = l_epis_type;
    
        g_error := 'GET L_RET';
        SELECT t_row_core_domain(internal_name => i_internal_name,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT val data, rank, desc_val label
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      decode(l_epis_type,
                                                                             NULL,
                                                                             i_prof,
                                                                             profissional(i_prof.id,
                                                                                          i_prof.institution,
                                                                                          l_software)),
                                                                      'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                      NULL)));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TIME_LIST',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_bp_time_list;

    FUNCTION get_bp_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS', i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_tbl_diags t_coll_diagnosis_config := t_coll_diagnosis_config();
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            l_tbl_diags := pk_diagnosis.get_associated_diagnosis_tf(i_lang, i_prof, i_episode, pk_alert_constant.g_yes);
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT id_diagnosis, desc_diagnosis, code_icd, flg_other, rank, id_alert_diagnosis
              FROM (SELECT NULL id_diagnosis,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_T073') desc_diagnosis,
                           NULL code_icd,
                           NULL flg_other,
                           10 rank,
                           NULL id_alert_diagnosis
                      FROM dual
                     WHERE instr(nvl(l_search_diagnosis, '#'), l_profile_template) != 0
                    UNION ALL
                    SELECT /*+opt_estimate (table t rows=1)*/
                     t.id_diagnosis, t.desc_diagnosis, t.code_icd, t.flg_other, 20 rank, t.id_alert_diagnosis
                      FROM TABLE(l_tbl_diags) t)
             ORDER BY rank ASC, desc_diagnosis ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_diagnosis_list;

    FUNCTION get_bp_special_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_priority      IN blood_product_det.flg_priority%TYPE,
        o_flg_mandatory OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE;
        l_age         patient.age%TYPE;
        l_config      t_config;
    
    BEGIN
    
        IF i_priority = pk_blood_products_constant.g_flg_priority_routine
        THEN
            o_flg_mandatory := pk_alert_constant.g_no;
        ELSE
            o_flg_mandatory := pk_alert_constant.g_yes;
        END IF;
    
        IF i_patient IS NOT NULL
        THEN
            SELECT p.dt_birth, p.dt_deceased, p.age
              INTO l_dt_birth, l_dt_deceased, l_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        END IF;
    
        l_config := pk_core_config.get_config(i_area             => pk_blood_products_constant.g_bp_special_type_area,
                                              i_prof             => i_prof,
                                              i_market           => pk_utils.get_institution_market(i_lang           => i_lang,
                                                                                                    i_id_institution => i_prof.institution),
                                              i_category         => pk_prof_utils.get_id_category(i_lang => i_lang,
                                                                                                  i_prof => i_prof),
                                              i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof => i_prof),
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        pk_context_api.set_parameter(p_name => 'i_lang', p_value => i_lang);
        pk_context_api.set_parameter(p_name => 'i_prof_id', p_value => i_prof.id);
        pk_context_api.set_parameter(p_name => 'i_institution', p_value => i_prof.institution);
        pk_context_api.set_parameter(p_name => 'i_software', p_value => i_prof.software);
    
        OPEN o_list FOR
            SELECT t.id_multichoice_option data, t.desc_option label, t.rank, t.id_config
              FROM v_bp_special_type_cfg t
             WHERE t.id_config = l_config.id_config
               AND t.id_hemo_type = i_hemo_type
               AND t.priority_val = i_priority
               AND t.priority_lang = i_lang
               AND (t.age_min IS NULL OR
                   pk_patient.get_pat_age(i_lang,
                                           l_dt_birth,
                                           l_dt_deceased,
                                           l_age,
                                           coalesce(t.age_min_format, 'YEARS')) >= t.age_min)
               AND (t.age_max IS NULL OR
                   pk_patient.get_pat_age(i_lang,
                                           l_dt_birth,
                                           l_dt_deceased,
                                           l_age,
                                           coalesce(t.age_max_format, 'YEARS')) <= t.age_max)
             ORDER BY t.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SPECIAL_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_special_type_list;

    FUNCTION get_bp_special_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        i_patient       IN patient.id_patient%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_priority      IN blood_product_det.flg_priority%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain;
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE;
        l_age         patient.age%TYPE;
        l_config      t_config;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_alertlog.log_error('i_hemo_type ' || i_hemo_type);
        pk_alertlog.log_error('i_priority ' || i_priority);
        IF i_patient IS NOT NULL
        THEN
            SELECT p.dt_birth, p.dt_deceased, p.age
              INTO l_dt_birth, l_dt_deceased, l_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        END IF;
    
        l_config := pk_core_config.get_config(i_area             => pk_blood_products_constant.g_bp_special_type_area,
                                              i_prof             => i_prof,
                                              i_market           => pk_utils.get_institution_market(i_lang           => i_lang,
                                                                                                    i_id_institution => i_prof.institution),
                                              i_category         => pk_prof_utils.get_id_category(i_lang => i_lang,
                                                                                                  i_prof => i_prof),
                                              i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof => i_prof),
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        pk_context_api.set_parameter(p_name => 'i_lang', p_value => i_lang);
        pk_context_api.set_parameter(p_name => 'i_prof_id', p_value => i_prof.id);
        pk_context_api.set_parameter(p_name => 'i_institution', p_value => i_prof.institution);
        pk_context_api.set_parameter(p_name => 'i_software', p_value => i_prof.software);
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.id_multichoice_option data, t.desc_option label, t.rank, t.id_config
                  FROM v_bp_special_type_cfg t
                 WHERE t.id_config = l_config.id_config
                   AND t.id_hemo_type = i_hemo_type
                   AND t.priority_val = i_priority
                   AND t.priority_lang = i_lang
                   AND (t.age_min IS NULL OR
                       pk_patient.get_pat_age(i_lang,
                                               l_dt_birth,
                                               l_dt_deceased,
                                               l_age,
                                               coalesce(t.age_min_format, 'YEARS')) >= t.age_min)
                   AND (t.age_max IS NULL OR
                       pk_patient.get_pat_age(i_lang,
                                               l_dt_birth,
                                               l_dt_deceased,
                                               l_age,
                                               coalesce(t.age_max_format, 'YEARS')) <= t.age_max)
                 ORDER BY t.rank);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SPECIAL_TYPE_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_bp_special_type_list;

    FUNCTION get_bp_transfusion_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT t.id_multichoice_option data, t.desc_option label, t.rank
              FROM TABLE(pk_multichoice.tf_multichoice_options(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_multichoice_type => 'BLOOD_PRODUCT_DET.TRANSFUSION_TYPE')) t
             ORDER BY t.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TRANSFUSION_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_transfusion_type_list;

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config t_config;
    
    BEGIN
    
        l_config := pk_core_config.get_config(i_area             => pk_blood_products_constant.g_bp_special_instr_area,
                                              i_prof             => i_prof,
                                              i_market           => pk_utils.get_institution_market(i_lang           => i_lang,
                                                                                                    i_id_institution => i_prof.institution),
                                              i_category         => pk_prof_utils.get_id_category(i_lang => i_lang,
                                                                                                  i_prof => i_prof),
                                              i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof => i_prof),
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        pk_context_api.set_parameter(p_name => 'i_lang', p_value => i_lang);
        pk_context_api.set_parameter(p_name => 'i_prof_id', p_value => i_prof.id);
        pk_context_api.set_parameter(p_name => 'i_institution', p_value => i_prof.institution);
        pk_context_api.set_parameter(p_name => 'i_software', p_value => i_prof.software);
    
        OPEN o_list FOR
            SELECT t.id_multichoice_option data, t.desc_option label, t.rank, t.id_config
              FROM v_bp_special_instr_cfg t
             WHERE t.id_config = l_config.id_config
               AND t.id_hemo_type = i_hemo_type
               AND t.priority_val = i_priority
               AND t.priority_lang = i_lang
             ORDER BY t.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SPECIAL_INSTR_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_special_instr_list;

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_config t_config;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    
    BEGIN
    
        l_config := pk_core_config.get_config(i_area             => pk_blood_products_constant.g_bp_special_instr_area,
                                              i_prof             => i_prof,
                                              i_market           => pk_utils.get_institution_market(i_lang           => i_lang,
                                                                                                    i_id_institution => i_prof.institution),
                                              i_category         => pk_prof_utils.get_id_category(i_lang => i_lang,
                                                                                                  i_prof => i_prof),
                                              i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof => i_prof),
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        pk_context_api.set_parameter(p_name => 'i_lang', p_value => i_lang);
        pk_context_api.set_parameter(p_name => 'i_prof_id', p_value => i_prof.id);
        pk_context_api.set_parameter(p_name => 'i_institution', p_value => i_prof.institution);
        pk_context_api.set_parameter(p_name => 'i_software', p_value => i_prof.software);
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.id_multichoice_option data, t.desc_option label, t.rank
                  FROM v_bp_special_instr_cfg t
                 WHERE t.id_config = l_config.id_config
                   AND t.id_hemo_type = i_hemo_type
                   AND t.priority_val = i_priority
                   AND t.priority_lang = i_lang
                 ORDER BY t.rank);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_SPECIAL_INSTR_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_bp_special_instr_list;

    FUNCTION get_bp_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_ADT.GET_PAT_HEALTH_PLANS';
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        INSERT INTO tbl_temp
            (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
        VALUES
            (NULL, NULL, pk_message.get_message(i_lang, i_prof, 'PROCEDURES_M011'), NULL, NULL, NULL, 10);
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
            VALUES
                (l_id_pat_health_plan,
                 l_id_health_plan_entity,
                 l_desc_health_plan_entity,
                 l_id_health_plan,
                 l_desc_health_plan,
                 l_num_health_plan,
                 20);
        END LOOP;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT num_1 id_pat_health_plan,
                   num_2 id_health_plan_entity,
                   vc_1  desc_health_plan_entity,
                   num_2 id_health_plan,
                   vc_2  desc_health_plan,
                   vc_3  num_health_plan
              FROM tbl_temp
             ORDER BY num_3;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_HEALTH_PLAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_health_plan_list;

    FUNCTION get_bp_health_plan_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_internal_name      IN VARCHAR2,
        i_health_plan_entity IN NUMBER,
        o_error              OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_ADT.GET_PAT_HEALTH_PLANS';
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        INSERT INTO tbl_temp
            (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
        VALUES
            (NULL, NULL, pk_message.get_message(i_lang, i_prof, 'PROCEDURES_M011'), NULL, NULL, NULL, 10);
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
            VALUES
                (l_id_pat_health_plan,
                 l_id_health_plan_entity,
                 l_desc_health_plan_entity,
                 l_id_health_plan,
                 l_desc_health_plan,
                 l_num_health_plan,
                 20);
        END LOOP;
    
        g_error := 'OPEN L_RET';
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => desc_health_plan,
                                 domain_value  => id_health_plan,
                                 order_rank    => NULL,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT num_2 id_health_plan, vc_2 desc_health_plan
                  FROM tbl_temp
                 ORDER BY num_3) t
         WHERE t.id_health_plan = i_health_plan_entity;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_HEALTH_PLAN_LIST',
                                              o_error);
            RETURN l_ret;
    END get_bp_health_plan_list;

    FUNCTION get_bp_financial_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_ADT.GET_PAT_HEALTH_PLANS';
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        INSERT INTO tbl_temp
            (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
        VALUES
            (NULL, NULL, pk_message.get_message(i_lang, i_prof, 'PROCEDURES_M011'), NULL, NULL, NULL, 10);
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
            VALUES
                (l_id_pat_health_plan,
                 l_id_health_plan_entity,
                 l_desc_health_plan_entity,
                 l_id_health_plan,
                 l_desc_health_plan,
                 l_num_health_plan,
                 20);
        END LOOP;
    
        g_error := 'OPEN L_RET';
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => desc_health_plan_entity,
                                 domain_value  => id_health_plan_entity,
                                 order_rank    => NULL,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT coalesce(num_2, -1) id_health_plan_entity, vc_1 desc_health_plan_entity
                  FROM tbl_temp
                 ORDER BY num_3) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_FINANCIAL_LIST',
                                              o_error);
            RETURN l_ret;
    END get_bp_financial_list;

    FUNCTION get_bp_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_instit_master institution.id_institution%TYPE;
        l_insti_list    table_number := table_number();
    BEGIN
        -- get institution master (tree root)
        SELECT i.id_institution
          INTO l_instit_master
          FROM institution i
         WHERE i.flg_available = pk_blood_products_constant.g_available
           AND i.id_parent IS NULL
         START WITH i.id_institution = i_prof.institution
        CONNECT BY nocycle i.id_institution = PRIOR i.id_parent;
    
        -- get complete tree from root identifier
        SELECT i.id_institution
          BULK COLLECT
          INTO l_insti_list
          FROM institution i
         WHERE i.flg_available = pk_blood_products_constant.g_available
         START WITH i.id_institution = l_instit_master
        CONNECT BY nocycle PRIOR i.id_institution = i.id_parent;
    
        OPEN o_list FOR
            SELECT p.id_professional, p.name
              FROM professional p
              JOIN ab_user_info ui
                ON (ui.id_ab_user_info = p.id_professional)
             WHERE ui.login IS NOT NULL
               AND EXISTS
             (SELECT 0
                      FROM prof_institution pi
                     INNER JOIN prof_profile_template ppt
                        ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
                     INNER JOIN profile_template pt
                        ON (pt.id_profile_template = ppt.id_profile_template)
                     WHERE pi.id_professional = p.id_professional
                       AND pi.id_institution IN (SELECT /*+ opt_estimate (inst rows = 1)*/
                                                  column_value
                                                   FROM TABLE(l_insti_list) inst)
                       AND pi.dt_end_tstz IS NULL
                       AND pi.flg_state = 'A'
                       AND pi.flg_external = 'N'
                       AND pt.flg_group IN ('P', 'C'))
             ORDER BY p.name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_prof_list;

    FUNCTION get_bp_det_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_bp_req   blood_product_det.id_blood_product_req%TYPE,
        o_det_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        SELECT bpr.id_patient
          INTO l_id_patient
          FROM blood_product_req bpr
         WHERE bpr.id_blood_product_req = i_bp_req;
    
        OPEN o_det_info FOR
            SELECT id_blood_product_det,
                   status_string_det,
                   id_hemo_type,
                   flg_status_det,
                   desc_hemo_type,
                   desc_compatibility,
                   qty_det,
                   rank
              FROM (SELECT t.id_blood_product_det,
                           t.id_blood_product_req,
                           t.status_string_det,
                           t.id_hemo_type,
                           t.flg_status_det,
                           t.desc_hemo_type,
                           t.desc_compatibility,
                           t.qty_det,
                           t.dt_begin_req,
                           decode(flg_status_det,
                                  'R',
                                  row_number() over(ORDER BY t.rank_det, t.dt_begin_req),
                                  row_number() over(ORDER BY t.rank_req, t.dt_begin_req DESC)) rank
                      FROM (SELECT bpea.id_blood_product_det,
                                   bpea.id_blood_product_req,
                                   pk_blood_products_utils.get_status_string(i_lang,
                                                                             i_prof,
                                                                             bpea.id_episode,
                                                                             bpea.id_blood_product_det) status_string_det,
                                   bpea.id_hemo_type,
                                   bpea.flg_status_det,
                                   pk_translation.get_translation(i_lang, ht.code_hemo_type) desc_hemo_type,
                                   pk_blood_products_utils.get_bp_compatibility_desc(i_lang,
                                                                                     i_prof,
                                                                                     bpea.id_blood_product_det) desc_compatibility,
                                   coalesce(bpea.qty_received, bpea.qty_exec) || ' ' || CASE
                                        WHEN bpea.qty_received IS NOT NULL THEN
                                         pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                      i_prof         => i_prof,
                                                                                      i_unit_measure => bpea.id_unit_mea_qty_received)
                                        WHEN bpea.qty_exec IS NOT NULL THEN
                                         pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                      i_prof         => i_prof,
                                                                                      i_unit_measure => bpea.id_unit_mea_qty_exec)
                                    END qty_det,
                                   bpea.dt_begin_req,
                                   (SELECT pk_sysdomain.get_rank(i_lang,
                                                                 'BLOOD_PRODUCT_DET.FLG_STATUS',
                                                                 bpea.flg_status_det)
                                      FROM dual) rank_det,
                                   (SELECT pk_sysdomain.get_rank(i_lang,
                                                                 'BLOOD_PRODUCT_REQ.FLG_STATUS',
                                                                 bpea.flg_status_req)
                                      FROM dual) rank_req
                              FROM blood_products_ea bpea
                              JOIN hemo_type ht
                                ON ht.id_hemo_type = bpea.id_hemo_type
                              JOIN episode e
                                ON e.id_episode = bpea.id_episode
                             WHERE bpea.id_patient = l_id_patient) t)
             WHERE id_blood_product_req = i_bp_req
             ORDER BY rank, dt_begin_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DET_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_det_info);
            RETURN FALSE;
    END get_bp_det_info;

    FUNCTION get_bp_condition_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_exec_number       IN blood_product_execution.exec_number%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html          IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html_mode     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_condition_flg blood_product_execution.flg_condition%TYPE;
        l_id_reason     blood_product_execution.id_action_reason%TYPE;
        l_notes         blood_product_execution.notes_reason%TYPE;
    
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT bpe.flg_condition, bpe.id_action_reason, bpe.notes_reason
          INTO l_condition_flg, l_id_reason, l_notes
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.action = pk_blood_products_constant.g_bp_action_condition
           AND bpe.exec_number = i_exec_number;
    
        IF l_condition_flg IS NOT NULL
        THEN
            --Condition label (Only to be shown for flash details and reports)
            IF i_flg_html = pk_alert_constant.g_no
            THEN
                l_ret := l_ret || CASE i_flg_report
                             WHEN pk_alert_constant.g_yes THEN
                              '<p>'
                         END || '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T137') || '</b> ';
            END IF;
        
            --Condition value (To be shown for flash details and reports, and for HTML details when on mode 'C' (Condition))
            IF l_condition_flg = pk_alert_constant.g_yes
               AND (i_flg_html_mode = pk_blood_products_constant.g_bp_condition OR i_flg_html = pk_alert_constant.g_no)
            THEN
                l_ret := l_ret || pk_message.get_message(i_lang, 'COMMON_M022') || CASE i_flg_report
                             WHEN pk_alert_constant.g_yes THEN
                              '</p>'
                         END;
            ELSIF l_condition_flg = pk_alert_constant.g_no
                  AND
                  (i_flg_html_mode = pk_blood_products_constant.g_bp_condition OR i_flg_html = pk_alert_constant.g_no)
            THEN
                l_ret := l_ret || pk_message.get_message(i_lang, 'COMMON_M023');
            END IF;
        
            --Break line (Only to be shown for flash details and reports when there are reason/condition notes to be shown)
            IF (l_id_reason IS NOT NULL OR l_notes IS NOT NULL)
               AND i_flg_html = pk_alert_constant.g_no
            THEN
                l_ret := l_ret || CASE i_flg_report
                             WHEN pk_alert_constant.g_yes THEN
                              '</p>'
                         END || chr(10);
            END IF;
        END IF;
    
        --Condition reason label
        IF l_id_reason IS NOT NULL
           AND i_flg_html = pk_alert_constant.g_no
        THEN
            l_ret := l_ret || CASE i_flg_report
                         WHEN pk_alert_constant.g_yes THEN
                          '<p>'
                     END || '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T138') || '</b> ' ||
                     pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_cancel_reason => l_id_reason) || CASE
                         WHEN l_notes IS NOT NULL THEN
                          CASE i_flg_report
                              WHEN pk_alert_constant.g_yes THEN
                               '</p>'
                          END || chr(10)
                     END;
        ELSIF l_id_reason IS NOT NULL
              AND i_flg_html_mode = pk_blood_products_constant.g_bp_condition_reason
        THEN
            l_ret := pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_cancel_reason => l_id_reason);
        END IF;
    
        IF l_notes IS NOT NULL
           AND i_flg_html = pk_alert_constant.g_no
        THEN
            l_ret := l_ret || CASE i_flg_report
                         WHEN pk_alert_constant.g_yes THEN
                          '<p>'
                     END || '<b>' || pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T43') || '</b> ' || l_notes ||
                     CASE i_flg_report
                         WHEN pk_alert_constant.g_yes THEN
                          '</p>'
                     END;
        ELSIF l_id_reason IS NOT NULL
              AND i_flg_html_mode = pk_blood_products_constant.g_bp_condition_notes
        THEN
            l_ret := l_notes;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_condition_detail;

    FUNCTION get_bp_newborn
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_tbl_hemo_type IN table_number,
        o_show_popup    OUT VARCHAR2,
        o_title         OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
    
        CURSOR c_lab_test_newborn(i_epis episode.id_episode%TYPE) IS
            SELECT qt.id_analysis, qt.id_sample_type
              FROM (WITH an AS (SELECT DISTINCT ard.id_analysis, ard.id_sample_type, lte.dt_target
                                  FROM analysis_req ar
                                  JOIN analysis_req_det ard
                                    ON ard.id_analysis_req = ar.id_analysis_req
                                  JOIN lab_tests_ea lte
                                    ON lte.id_analysis_req_det = ard.id_analysis_req_det
                                 WHERE ar.id_episode = i_epis
                                   AND ard.flg_status NOT IN
                                       (pk_lab_tests_constant.g_analysis_cancel,
                                        pk_lab_tests_constant.g_analysis_predefined,
                                        pk_lab_tests_constant.g_analysis_draft))
                   
                       SELECT a.id_analysis, a.id_sample_type
                         FROM hemo_type_analysis a
                         LEFT JOIN an
                           ON an.id_analysis = a.id_analysis
                          AND an.id_sample_type = a.id_sample_type
                        WHERE a.id_institution = i_prof.institution
                          AND a.id_hemo_type IN (SELECT *
                                                   FROM TABLE(i_tbl_hemo_type) t)
                          AND a.flg_available = pk_alert_constant.g_yes
                          AND a.flg_newborn = pk_alert_constant.g_yes
                          AND (an.id_analysis IS NULL OR
                              ((a.time_req IS NOT NULL AND a.unit_time_req IS NOT NULL) AND
                              pk_date_utils.add_to_ltstz(i_timestamp => an.dt_target,
                                                           i_amount    => a.time_req,
                                                           i_unit      => a.unit_time_req) <= current_timestamp))) qt;
    
    
        l_req_analysis_id    table_number;
        l_req_sample_type_id table_number;
    
        l_id_patient_mother patient.id_patient%TYPE;
        l_visit_mother      visit.id_visit%TYPE;
        l_epis_mother       episode.id_episode%TYPE;
        l_patient_age       PLS_INTEGER; --Patient age in days        
    
        l_message sys_message.desc_message%TYPE;
    
        l_show_popup sys_config.value%TYPE := pk_sysconfig.get_config('BLOOD_NEWBORN_POPUP_SHOW', i_prof);
    
    BEGIN
    
        o_show_popup := pk_alert_constant.g_no;
    
        IF l_show_popup = pk_alert_constant.g_yes
        THEN
            --Get patient age
            l_patient_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => NULL,
                                                    i_dt_deceased => NULL,
                                                    i_age         => NULL,
                                                    i_age_format  => 'DAYS',
                                                    i_patient     => i_patient);
        
            IF l_patient_age <= pk_blood_products_constant.g_bp_newborn_age_limit
            THEN
                --Get patient id of mother   
                BEGIN
                    SELECT p.id_patient
                      INTO l_id_patient_mother
                      FROM patient p
                      LEFT JOIN pat_family_member pfm
                        ON p.id_patient = pfm.id_pat_related
                       AND (pfm.id_patient = i_patient OR pfm.id_pat_related = i_patient OR pfm.id_pat_related IS NULL)
                       AND pfm.flg_status = pk_alert_constant.g_active
                      LEFT JOIN family_relationship fr
                        ON pfm.id_family_relationship = fr.id_family_relationship
                     WHERE fr.id_family_relationship = pk_blood_products_constant.g_bp_fam_rel_mother;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_patient_mother := NULL;
                END;
            
                --Get active episode of mother
                IF l_id_patient_mother IS NOT NULL
                THEN
                    IF NOT pk_visit.get_active_vis_epis(i_lang           => i_lang,
                                                        i_id_pat         => l_id_patient_mother,
                                                        i_id_institution => i_prof.institution,
                                                        i_prof           => i_prof,
                                                        o_id_visit       => l_visit_mother,
                                                        o_id_episode     => l_epis_mother,
                                                        o_error          => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF l_epis_mother IS NOT NULL
                    THEN
                        --Check if there are lab tests configured for the selected hemo type    
                        OPEN c_lab_test_newborn(l_epis_mother);
                        FETCH c_lab_test_newborn BULK COLLECT
                            INTO l_req_analysis_id, l_req_sample_type_id;
                        CLOSE c_lab_test_newborn;
                    
                        IF l_req_analysis_id IS NOT NULL
                           AND l_req_analysis_id.count > 0
                        THEN
                            o_show_popup := pk_alert_constant.g_yes;
                        
                            o_msg := '<b>' || pk_message.get_message(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_code_mess => 'BLOOD_PRODUCTS_T144') || '</b>' ||
                                     '<br>';
                        
                            o_title := pk_message.get_message(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_code_mess => 'COMMON_M080');
                        END IF;
                    END IF;
                END IF;
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
                                              'GET_BP_NEWBORN',
                                              o_error);
            RETURN FALSE;
    END get_bp_newborn;

    FUNCTION get_bp_cancel_req_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_bp_req_info           OUT pk_types.cursor_type,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN AS
    
    BEGIN
    
        OPEN o_bp_req_info FOR
            SELECT bpr.id_blood_product_req,
                   (pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T14') || ' - ' ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, bpr.dt_begin_tstz, i_prof)) AS desc_transfusion
              FROM blood_product_req bpr
             WHERE bpr.id_patient = i_patient
               AND bpr.id_blood_product_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(i_tbl_blood_product_req) t);
    
        OPEN o_bp_det_info FOR
            SELECT bpd.id_blood_product_req,
                   bpd.id_blood_product_det,
                   bpd.qty_received,
                   pk_translation.get_translation(i_lang, ht.code_hemo_type) || ' - ' ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      coalesce(bpe_hold.dt_bp_execution_tstz,
                                                               bpe_exec.dt_bp_execution_tstz),
                                                      i_prof) AS desc_hemo_type
              FROM blood_product_det bpd
              JOIN hemo_type ht
                ON ht.id_hemo_type = bpd.id_hemo_type
              LEFT JOIN blood_product_execution bpe_exec
                ON bpe_exec.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_exec.action = pk_blood_products_constant.g_bp_action_administer
              LEFT JOIN blood_product_execution bpe_hold
                ON bpe_hold.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_hold.action = pk_blood_products_constant.g_bp_action_hold
             WHERE bpd.id_blood_product_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(i_tbl_blood_product_req) t)
               AND bpd.flg_status IN
                   (pk_blood_products_constant.g_status_det_o, pk_blood_products_constant.g_status_det_h);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_CANCEL_INFO_REQ',
                                              o_error);
            RETURN FALSE;
    END get_bp_cancel_req_info;

    FUNCTION get_bp_cancel_det_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_det IN table_number,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN AS
    
    BEGIN
    
        OPEN o_bp_det_info FOR
            SELECT bpd.id_blood_product_det,
                   bpd.qty_received,
                   pk_translation.get_translation(i_lang, ht.code_hemo_type) || ' - ' ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      coalesce(bpe_hold.dt_bp_execution_tstz,
                                                               bpe_exec.dt_bp_execution_tstz,
                                                               bpd.dt_begin_tstz),
                                                      i_prof) AS desc_hemo_type,
                   CASE
                        WHEN bpd.flg_status IN
                             (pk_blood_products_constant.g_status_det_o, pk_blood_products_constant.g_status_det_h) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_init_administration
              FROM blood_product_det bpd
              JOIN hemo_type ht
                ON ht.id_hemo_type = bpd.id_hemo_type
              LEFT JOIN blood_product_execution bpe_exec
                ON bpe_exec.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_exec.action = pk_blood_products_constant.g_bp_action_administer
              LEFT JOIN blood_product_execution bpe_hold
                ON bpe_hold.id_blood_product_det = bpd.id_blood_product_det
               AND bpe_hold.action = pk_blood_products_constant.g_bp_action_hold
             WHERE bpd.id_blood_product_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                 *
                                                  FROM TABLE(i_tbl_blood_product_det) t);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_CANCEL_INFO_DET',
                                              o_error);
            RETURN FALSE;
    END get_bp_cancel_det_info;

    FUNCTION get_bp_permission_cancel_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(1);
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req = i_id_blood_product_req
           AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_h,
                                  pk_blood_products_constant.g_status_det_wr,
                                  pk_blood_products_constant.g_status_det_or,
                                  pk_blood_products_constant.g_status_det_cr,
                                  pk_blood_products_constant.g_status_det_f,
                                  pk_blood_products_constant.g_status_det_d,
                                  pk_blood_products_constant.g_status_det_c,
                                  pk_blood_products_constant.g_status_det_br);
    
        --If the requisition has bags with the following statuse it shoul no longer be possible to cancel it
        --Ongoin transfusion/Ongoin transport/Ready for transfusion/Hold transfusion
        IF l_count > 0
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    END get_bp_permission_cancel_req;

    FUNCTION get_bp_permission_cancel_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2 IS
        l_ret        VARCHAR2(1);
        l_flg_status blood_product_det.flg_status%TYPE;
    BEGIN
        SELECT bpd.flg_status
          INTO l_flg_status
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_det = i_id_blood_product_det;
    
        IF l_flg_status IN (pk_blood_products_constant.g_status_det_h,
                            pk_blood_products_constant.g_status_det_wr,
                            pk_blood_products_constant.g_status_det_or,
                            pk_blood_products_constant.g_status_det_cr,
                            pk_blood_products_constant.g_status_det_f,
                            pk_blood_products_constant.g_status_det_d,
                            pk_blood_products_constant.g_status_det_c,
                            pk_blood_products_constant.g_status_det_br)
        THEN
        
            l_ret := pk_alert_constant.g_no;
        ELSE
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_bp_permission_cancel_det;

    FUNCTION tf_get_bp_clinical_questions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time          IN bp_question_response.flg_time%TYPE,
        i_flg_history       IN VARCHAR DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_bp_clinical_question IS
        l_ret t_tbl_bp_clinical_question := t_tbl_bp_clinical_question();
    BEGIN
    
        IF i_flg_history = pk_alert_constant.g_no
        THEN
            SELECT t_bp_clinical_question(desc_clinical_question     => desc_clinical_question,
                                          desc_clinical_question_new => NULL,
                                          desc_response              => desc_response,
                                          desc_response_new          => NULL,
                                          num_order                  => 1,
                                          rank                       => rank)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT id_blood_product_det,
                           id_content,
                           flg_time,
                           id_questionnaire,
                           desc_clinical_question,
                           desc_response,
                           rank
                      FROM (SELECT DISTINCT bqr1.id_blood_product_det,
                                            bqr1.id_content,
                                            bqr1.flg_time,
                                            bqr1.id_questionnaire,
                                            pk_mcdt.get_questionnaire_alias(i_lang,
                                                                            i_prof,
                                                                            'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                            bqr1.id_questionnaire) desc_clinical_question,
                                            dbms_lob.substr(decode(dbms_lob.getlength(bqr.notes),
                                                                   NULL,
                                                                   to_clob(decode(bqr1.desc_response,
                                                                                  NULL,
                                                                                  '---',
                                                                                  bqr1.desc_response)),
                                                                   pk_procedures_utils.get_procedure_response(i_lang,
                                                                                                              i_prof,
                                                                                                              bqr.notes)),
                                                            3800) desc_response,
                                            (SELECT pk_blood_products_utils.get_bp_questionnaire_rank(i_lang,
                                                                                                      i_prof,
                                                                                                      bpd.id_hemo_type,
                                                                                                      bqr.id_questionnaire,
                                                                                                      bqr.flg_time)
                                               FROM dual) rank
                              FROM (SELECT bqr.id_blood_product_det,
                                           bqr.id_questionnaire,
                                           listagg(pk_blood_products_utils.get_questionnaire_id_content(i_lang,
                                                                                                        i_prof,
                                                                                                        bqr.id_questionnaire,
                                                                                                        bqr.id_response),
                                                   '; ') within GROUP(ORDER BY bqr.id_response) id_content,
                                           bqr.flg_time,
                                           listagg(pk_mcdt.get_response_alias(i_lang,
                                                                              i_prof,
                                                                              'RESPONSE.CODE_RESPONSE.' || bqr.id_response),
                                                   '; ') within GROUP(ORDER BY bqr.id_response) desc_response,
                                           bqr.dt_last_update_tstz,
                                           row_number() over(PARTITION BY bqr.id_questionnaire, bqr.flg_time ORDER BY bqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                      FROM bp_question_response bqr
                                     WHERE bqr.id_blood_product_det IN
                                           (SELECT id_blood_product_det
                                              FROM blood_product_det
                                             WHERE id_blood_product_req IN
                                                   ((SELECT bpd_q.id_blood_product_req
                                                      FROM blood_product_det bpd_q
                                                     WHERE bpd_q.id_blood_product_det = i_blood_product_det)))
                                     GROUP BY bqr.id_blood_product_det,
                                              bqr.id_questionnaire,
                                              bqr.flg_time,
                                              bqr.dt_last_update_tstz) bqr1,
                                   bp_question_response bqr,
                                   blood_product_det bpd
                             WHERE bqr1.rn = 1
                               AND bqr1.id_blood_product_det = bqr.id_blood_product_det
                               AND bqr1.id_questionnaire = bqr.id_questionnaire
                               AND bqr1.dt_last_update_tstz = bqr.dt_last_update_tstz
                               AND bqr1.flg_time = bqr.flg_time
                               AND bqr.id_blood_product_det = bpd.id_blood_product_det
                               AND bqr1.flg_time = i_flg_time)
                     ORDER BY flg_time, rank);
        ELSE
            SELECT t_bp_clinical_question(desc_clinical_question     => desc_clinical_question,
                                          desc_clinical_question_new => desc_clinical_question_new,
                                          desc_response              => desc_response,
                                          desc_response_new          => desc_response_new,
                                          num_order                  => num_order,
                                          rank                       => rank)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT id_blood_product_det,
                           id_content,
                           flg_time,
                           id_questionnaire,
                           desc_clinical_question,
                           desc_clinical_question_new,
                           desc_response,
                           desc_response_new,
                           rank,
                           row_number() over(PARTITION BY id_questionnaire ORDER BY dt_last_update_tstz) AS num_order
                      FROM (SELECT bqro.id_blood_product_det,
                                   qst.id_content,
                                   bqro.flg_time,
                                   pk_translation.get_translation(i_lang, qst.code_questionnaire) desc_clinical_question,
                                   CASE
                                        WHEN bqro.previous_rownum IS NULL THEN
                                        --Primeiro questionário
                                         NULL
                                    --EDIÇÕES
                                        WHEN bqro.flg_new = pk_blood_products_constant.g_yes THEN
                                         pk_translation.get_translation(i_lang, qst.code_questionnaire) || ' ' ||
                                         lower(pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T236'))
                                    --ANTIGO
                                        ELSE
                                         NULL
                                    END desc_clinical_question_new,
                                   CASE
                                        WHEN bqro.previous_rownum IS NULL THEN
                                        --Primeiro questionário                                           
                                         CASE
                                             WHEN bqro.current_questionnaire IS NULL THEN
                                              '---'
                                             ELSE
                                              to_char(bqro.current_questionnaire)
                                         END
                                    --EDIÇÕES
                                        WHEN bqro.flg_new = pk_blood_products_constant.g_yes THEN
                                        --NOVO
                                         CASE
                                             WHEN bqro.previous_questionnaire IS NULL THEN
                                              '---'
                                             ELSE
                                              to_char(bqro.previous_questionnaire)
                                         END
                                    --ANTIGO
                                        ELSE --WHEN THE ANSWER HAS NOT BEEN CHANGED => SHOW NONTHELESS
                                         CASE
                                             WHEN bqro.previous_questionnaire IS NULL THEN
                                              '---'
                                             ELSE
                                              to_char(bqro.previous_questionnaire)
                                         END
                                    END desc_response,
                                   CASE
                                        WHEN bqro.previous_rownum IS NULL THEN
                                         NULL
                                    --EDIÇÕES
                                        WHEN bqro.flg_new = pk_blood_products_constant.g_yes THEN
                                        --NOVO
                                         CASE
                                             WHEN bqro.current_questionnaire IS NULL THEN
                                              '---'
                                             ELSE
                                              to_char(bqro.current_questionnaire)
                                         END
                                    --ANTIGO
                                        ELSE --WHEN THE ANSWER HAS NOT BEEN CHANGED => SHOW NONTHELESS
                                         NULL
                                    END desc_response_new,
                                   bqro.current_rownum,
                                   bqro.id_questionnaire,
                                   bqro.dt_last_update_tstz,
                                   bqro.rank
                              FROM (SELECT erd1.id_questionnaire,
                                           erd1.id_blood_product_det,
                                           erd1.notes current_questionnaire,
                                           erd1.flg_time,
                                           erd1.dt_last_update_tstz,
                                           erd1.rn current_rownum,
                                           erd2.notes previous_questionnaire,
                                           erd2.rn previous_rownum,
                                           CASE
                                                WHEN erd2.rn IS NULL THEN
                                                 pk_blood_products_constant.g_yes
                                                WHEN to_char(erd1.notes) IS NULL
                                                     AND to_char(erd2.notes) IS NULL THEN
                                                 pk_blood_products_constant.g_no
                                                WHEN to_char(erd1.notes) = to_char(erd2.notes) THEN
                                                 pk_blood_products_constant.g_no
                                                ELSE
                                                 pk_blood_products_constant.g_yes
                                            END AS flg_new,
                                           (SELECT pk_blood_products_utils.get_bp_questionnaire_rank(i_lang,
                                                                                                     i_prof,
                                                                                                     erd1.id_hemo_type,
                                                                                                     erd1.id_questionnaire,
                                                                                                     erd1.flg_time)
                                              FROM dual) rank
                                      FROM (SELECT id_questionnaire,
                                                   id_blood_product_det,
                                                   notes,
                                                   flg_time,
                                                   dt_last_update_tstz,
                                                   row_number() over(PARTITION BY id_questionnaire ORDER BY id_questionnaire ASC, dt_last_update_tstz DESC) rn,
                                                   dt_last_update,
                                                   id_hemo_type
                                              FROM (SELECT *
                                                      FROM (SELECT bqr.id_bp_question_response,
                                                                   bqr.id_blood_product_det,
                                                                   bqr.id_questionnaire,
                                                                   bqr.dt_last_update_tstz,
                                                                   bqr.notes,
                                                                   bqr.flg_time flg_time,
                                                                   row_number() over(PARTITION BY bqr.id_questionnaire, bqr.dt_last_update_tstz ORDER BY bqr.id_bp_question_response) AS rn,
                                                                   pk_date_utils.date_send_tsz(i_lang,
                                                                                               bqr.dt_last_update_tstz,
                                                                                               i_prof) dt_last_update,
                                                                   bpd.id_hemo_type
                                                              FROM bp_question_response bqr
                                                              JOIN blood_product_det bpd
                                                                ON bpd.id_blood_product_det = bqr.id_blood_product_det
                                                             WHERE bpd.id_blood_product_det IN
                                                                   (SELECT id_blood_product_det
                                                                      FROM blood_product_det
                                                                     WHERE id_blood_product_req IN
                                                                           ((SELECT bpd_q.id_blood_product_req
                                                                              FROM blood_product_det bpd_q
                                                                             WHERE bpd_q.id_blood_product_det =
                                                                                   i_blood_product_det))))
                                                     WHERE rn = 1)) erd1
                                      LEFT JOIN (SELECT id_questionnaire,
                                                       id_blood_product_det,
                                                       notes,
                                                       dt_last_update_tstz,
                                                       row_number() over(PARTITION BY id_questionnaire ORDER BY id_questionnaire ASC, dt_last_update_tstz DESC) rn
                                                  FROM (SELECT *
                                                          FROM (SELECT bqr.id_bp_question_response,
                                                                       bqr.id_blood_product_det,
                                                                       bqr.id_questionnaire,
                                                                       bqr.dt_last_update_tstz,
                                                                       bqr.notes,
                                                                       row_number() over(PARTITION BY bqr.id_questionnaire, bqr.dt_last_update_tstz ORDER BY bqr.id_bp_question_response) AS rn --Because of multichoice options
                                                                  FROM bp_question_response bqr
                                                                 WHERE bqr.id_blood_product_det IN
                                                                       (SELECT id_blood_product_det
                                                                          FROM blood_product_det
                                                                         WHERE id_blood_product_req IN
                                                                               ((SELECT bpd_q.id_blood_product_req
                                                                                  FROM blood_product_det bpd_q
                                                                                 WHERE bpd_q.id_blood_product_det =
                                                                                       i_blood_product_det))))
                                                         WHERE rn = 1)) erd2
                                        ON erd2.id_questionnaire = erd1.id_questionnaire
                                       AND erd2.id_blood_product_det = erd1.id_blood_product_det
                                       AND erd1.rn = (erd2.rn - 1)
                                     ORDER BY erd1.rn ASC, rank ASC) bqro
                              JOIN questionnaire qst
                                ON qst.id_questionnaire = bqro.id_questionnaire)
                     ORDER BY dt_last_update_tstz, rank);
        END IF;
    
        RETURN l_ret;
    END tf_get_bp_clinical_questions;

    FUNCTION check_bp_init_admin
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2 IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM blood_product_det bpd
         WHERE bpd.id_blood_product_req = i_id_blood_product_req
           AND bpd.flg_status IN (pk_blood_products_constant.g_status_det_o, pk_blood_products_constant.g_status_det_h);
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END check_bp_init_admin;

    FUNCTION tf_get_bp_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail IS
    
        l_tbl_bp_detail t_tbl_bp_task_detail := t_tbl_bp_task_detail();
    
        -- TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('BLOOD_PRODUCTS_T01',
                                                        'BLOOD_PRODUCTS_T02',
                                                        'BLOOD_PRODUCTS_T03',
                                                        'BLOOD_PRODUCTS_T04',
                                                        'BLOOD_PRODUCTS_T05',
                                                        'BLOOD_PRODUCTS_T08',
                                                        'BLOOD_PRODUCTS_T09',
                                                        'BLOOD_PRODUCTS_T13',
                                                        'BLOOD_PRODUCTS_T14',
                                                        'BLOOD_PRODUCTS_T20',
                                                        'BLOOD_PRODUCTS_T24',
                                                        'BLOOD_PRODUCTS_T25',
                                                        'BLOOD_PRODUCTS_T30',
                                                        'BLOOD_PRODUCTS_T32',
                                                        'BLOOD_PRODUCTS_T33',
                                                        'BLOOD_PRODUCTS_T37',
                                                        'BLOOD_PRODUCTS_T39',
                                                        'BLOOD_PRODUCTS_T40',
                                                        'BLOOD_PRODUCTS_T41',
                                                        'BLOOD_PRODUCTS_T42',
                                                        'BLOOD_PRODUCTS_T43',
                                                        'BLOOD_PRODUCTS_T51',
                                                        'BLOOD_PRODUCTS_T52',
                                                        'BLOOD_PRODUCTS_T53',
                                                        'BLOOD_PRODUCTS_T54',
                                                        'BLOOD_PRODUCTS_T55',
                                                        'BLOOD_PRODUCTS_T56',
                                                        'BLOOD_PRODUCTS_T57',
                                                        'BLOOD_PRODUCTS_T58',
                                                        'BLOOD_PRODUCTS_T59',
                                                        'BLOOD_PRODUCTS_T60',
                                                        'BLOOD_PRODUCTS_T61',
                                                        'BLOOD_PRODUCTS_T62',
                                                        'BLOOD_PRODUCTS_T63',
                                                        'BLOOD_PRODUCTS_T64',
                                                        'BLOOD_PRODUCTS_T65',
                                                        'BLOOD_PRODUCTS_T66',
                                                        'BLOOD_PRODUCTS_T67',
                                                        'BLOOD_PRODUCTS_T68',
                                                        'BLOOD_PRODUCTS_T69',
                                                        'BLOOD_PRODUCTS_T70',
                                                        'BLOOD_PRODUCTS_T72',
                                                        'BLOOD_PRODUCTS_T73',
                                                        'BLOOD_PRODUCTS_T74',
                                                        'BLOOD_PRODUCTS_T77',
                                                        'COMMON_M044',
                                                        'CANCEL_SCREEN_LABELS_T003',
                                                        'BLOOD_PRODUCTS_T80',
                                                        'BLOOD_PRODUCTS_T81',
                                                        'BLOOD_PRODUCTS_T82',
                                                        'BLOOD_PRODUCTS_T83',
                                                        'BLOOD_PRODUCTS_T84',
                                                        'BLOOD_PRODUCTS_T85',
                                                        'BLOOD_PRODUCTS_T86',
                                                        'BLOOD_PRODUCTS_T88',
                                                        'BLOOD_PRODUCTS_T89',
                                                        'BLOOD_PRODUCTS_T90',
                                                        'BLOOD_PRODUCTS_T91',
                                                        'BLOOD_PRODUCTS_T93',
                                                        'BLOOD_PRODUCTS_T121',
                                                        'BLOOD_PRODUCTS_T124',
                                                        'BLOOD_PRODUCTS_T128',
                                                        'BLOOD_PRODUCTS_T127',
                                                        'BLOOD_PRODUCTS_T143',
                                                        'BLOOD_PRODUCTS_T146',
                                                        'BLOOD_PRODUCTS_T150',
                                                        'BLOOD_PRODUCTS_T151',
                                                        'BLOOD_PRODUCTS_T152',
                                                        'BLOOD_PRODUCTS_T162',
                                                        'BLOOD_PRODUCTS_T165',
                                                        'BLOOD_PRODUCTS_T169',
                                                        'BLOOD_PRODUCTS_T170',
                                                        'BLOOD_PRODUCTS_T171',
                                                        'BLOOD_PRODUCTS_T172');
    
        --DOCUMENTED
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        l_tbl_bp_notes t_tbl_blood_product_notes := t_tbl_blood_product_notes();
    
        l_cur_bp_doc_val pk_touch_option_out.t_cur_plain_text_entry;
        l_bp_doc_val     pk_touch_option_out.t_rec_plain_text_entry;
        l_notes          CLOB;
    
        l_count NUMBER(12) := 0;
    
        l_health_insurance sys_config.value%TYPE := pk_sysconfig.get_config('MCDT_HEALTH_INSURANCE', i_prof);
    
        l_ident VARCHAR2(3);
    
        l_rn_cq NUMBER := 0;
    
        l_compatibility_desc     VARCHAR2(200 CHAR);
        l_compatibility_notes    VARCHAR2(200 CHAR);
        l_compatibility_date_reg blood_product_execution.dt_bp_execution_tstz%TYPE;
    
        l_blood_group_desc VARCHAR2(4000);
    
        l_result_1     VARCHAR2(200);
        l_dt_result_1  VARCHAR2(200);
        l_result_sig_1 VARCHAR2(200);
    
        l_result_2     VARCHAR2(200);
        l_dt_result_2  VARCHAR2(200);
        l_result_sig_2 VARCHAR2(200);
    
        l_aux VARCHAR2(1000);
    
    BEGIN
    
        l_compatibility_desc     := pk_blood_products_utils.get_bp_compatibility_desc(i_lang,
                                                                                      i_prof,
                                                                                      i_blood_product_det);
        l_compatibility_notes    := pk_blood_products_utils.get_bp_compatibility_notes(i_lang,
                                                                                       i_prof,
                                                                                       i_blood_product_det);
        l_compatibility_date_reg := pk_blood_products_utils.get_bp_compatibility_reg_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_blood_product_det);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_ident := '';
        ELSE
            l_ident := '   ';
        END IF;
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' ||
                                                     pk_message.get_message(i_lang, i_prof, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        --Obtain templates
        l_count := 0;
        SELECT COUNT(1)
          INTO l_count
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.id_epis_documentation IS NOT NULL;
    
        IF (l_count) > 0
        THEN
        
            SELECT t_blood_product_notes(t.id_blood_product_det,
                                         t.id_blood_product_execution,
                                         t.id_epis_documentation,
                                         NULL)
              BULK COLLECT
              INTO l_tbl_bp_notes
              FROM (SELECT bpe.id_blood_product_det, bpe.id_blood_product_execution, bpe.id_epis_documentation
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = i_blood_product_det
                       AND bpe.id_epis_documentation IS NOT NULL) t;
        
            g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES';
            FOR i IN l_tbl_bp_notes.first .. l_tbl_bp_notes.last
            LOOP
            
                pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                           i_prof                    => i_prof,
                                                           i_epis_documentation_list => table_number(l_tbl_bp_notes(i).l_id_epis_documentation),
                                                           i_use_html_format         => CASE
                                                                                            WHEN i_flg_html_det = pk_alert_constant.g_no THEN
                                                                                             pk_blood_products_constant.g_yes
                                                                                            ELSE
                                                                                             pk_blood_products_constant.g_no
                                                                                        END,
                                                           o_entries                 => l_cur_bp_doc_val);
            
                FETCH l_cur_bp_doc_val
                    INTO l_bp_doc_val;
                CLOSE l_cur_bp_doc_val;
            
                l_notes := NULL;
                l_notes := REPLACE(l_bp_doc_val.plain_text_entry, chr(10));
                l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
            
                IF i_flg_report = pk_blood_products_constant.g_no
                THEN
                    l_notes := REPLACE(l_notes, '.<b>', '.<br><b>');
                END IF;
            
                IF i_flg_html_det = pk_alert_constant.g_yes
                THEN
                
                    l_notes := REPLACE(l_notes, substr(l_notes, 1, instr(l_notes, ': ') + 1), '');
                END IF;
            
                l_tbl_bp_notes(i).l_notes := l_notes;
            END LOOP;
        END IF;
    
        g_error := 'GET BLOOD GROUP INFORMATION';
        IF i_flg_html_det = pk_alert_constant.g_no
        THEN
            l_blood_group_desc := get_bp_blood_group_desc(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_episode           => i_episode,
                                                          i_blood_product_det => i_blood_product_det,
                                                          i_flg_report        => i_flg_report);
        ELSE
            IF NOT get_bp_blood_group_desc(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_episode           => i_episode,
                                           i_blood_product_det => i_blood_product_det,
                                           o_blood_group_desc  => l_blood_group_desc,
                                           o_result_1          => l_result_1,
                                           o_dt_result_1       => l_dt_result_1,
                                           o_result_sig_1      => l_result_sig_1,
                                           o_result_2          => l_result_2,
                                           o_dt_result_2       => l_dt_result_2,
                                           o_result_sig_2      => l_result_sig_2)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'OPEN O_BP_DETAIL';
    
        SELECT t_bp_task_detail(id_blood_product_det             => t.id_blood_product_det,
                                id_blood_product_execution       => t.id_blood_product_execution,
                                action                           => t.action,
                                desc_action                      => t.desc_action,
                                exec_number                      => t.exec_number,
                                registry                         => t.registry,
                                desc_hemo_type                   => t.desc_hemo_type,
                                clinical_indication              => t.clinical_indication,
                                desc_diagnosis                   => t.desc_diagnosis,
                                clinical_purpose                 => t.clinical_purpose,
                                instructions                     => t.instructions,
                                priority                         => t.priority,
                                special_type                     => t.special_type,
                                desc_time                        => t.desc_time,
                                order_recurrence                 => t.order_recurrence,
                                execution                        => t.execution,
                                perform_location                 => t.perform_location,
                                dt_req                           => t.dt_req,
                                not_order_reason                 => t.not_order_reason,
                                notes                            => t.notes,
                                co_sign                          => t.co_sign,
                                prof_order                       => t.prof_order,
                                dt_order                         => t.dt_order,
                                order_type                       => t.order_type,
                                health_insurance                 => t.health_insurance,
                                financial_entity                 => t.financial_entity,
                                health_plan                      => t.health_plan,
                                insurance_number                 => t.insurance_number,
                                exemption                        => t.exemption,
                                transfusion                      => t.transfusion,
                                transfusion_type_desc            => t.transfusion_type_desc,
                                quantity_received                => t.quantity_received,
                                quantity_ordered                 => t.quantity_ordered,
                                barcode                          => t.barcode,
                                blood_group                      => t.blood_group,
                                blood_group_rh                   => t.blood_group_rh,
                                expiration_date                  => t.expiration_date,
                                special_instr                    => t.special_instr,
                                tech_notes                       => t.tech_notes,
                                prof_perform                     => t.prof_perform,
                                start_time                       => t.start_time,
                                duration                         => t.duration,
                                end_time                         => t.end_time,
                                qty_given                        => t.qty_given,
                                desc_perform                     => t.desc_perform,
                                exec_notes                       => t.exec_notes,
                                action_reason                    => t.action_reason,
                                action_notes                     => t.action_notes,
                                id_prof_match                    => t.id_prof_match,
                                dt_match_tstz                    => t.dt_match_tstz,
                                desc_clinical_question           => t.desc_clinical_question,
                                desc_compatibility               => t.desc_compatibility,
                                notes_compatibility              => t.notes_compatibility,
                                condition                        => t.condition,
                                blood_group_desc                 => t.blood_group_desc,
                                lab_test_mother                  => t.lab_test_mother,
                                donation_code                    => t.donation_code,
                                result_1                         => t.result_1,
                                dt_result_1                      => t.dt_result_1,
                                result_sig_1                     => t.result_sig_1,
                                result_2                         => t.result_2,
                                dt_result_2                      => t.dt_result_2,
                                result_sig_2                     => t.result_sig_2,
                                req_prof_without_crossmatch      => t.req_prof_without_crossmatch,
                                req_statement_without_crossmatch => t.req_statement_without_crossmatch,
                                screening                        => t.screening,
                                nat_test                         => t.nat_test,
                                send_unit                        => t.send_unit)
          BULK COLLECT
          INTO l_tbl_bp_detail
          FROM (WITH cso_table AS (SELECT *
                                     FROM TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang, i_prof, i_episode, NULL)))
                   SELECT bp.id_blood_product_det,
                          bp.id_blood_product_execution,
                          bp.action,
                          bp.desc_action,
                          bp.exec_number,
                          bp.registry,
                          bp.desc_hemo_type,
                          CASE
                               WHEN bp.desc_diagnosis IS NOT NULL
                                    OR bp.clinical_purpose IS NOT NULL THEN
                                bp.clinical_indication
                               ELSE
                                NULL
                           END clinical_indication,
                          bp.desc_diagnosis,
                          bp.clinical_purpose,
                          bp.instructions,
                          bp.priority,
                          bp.special_type,
                          bp.desc_time,
                          bp.order_recurrence,
                          NULL execution,
                          bp.perform_location,
                          bp.dt_req,
                          bp.not_order_reason,
                          bp.notes,
                          bp.co_sign,
                          bp.prof_order,
                          bp.dt_order,
                          bp.order_type,
                          bp.health_insurance,
                          bp.financial_entity,
                          bp.health_plan,
                          bp.insurance_number,
                          bp.exemption,
                          CASE
                               WHEN bp.quantity_received IS NOT NULL
                                    OR bp.barcode IS NOT NULL
                                    OR bp.blood_group IS NOT NULL
                                    OR bp.blood_group_rh IS NOT NULL
                                    OR bp.expiration_date IS NOT NULL THEN
                                bp.transfusion
                               ELSE
                                NULL
                           END transfusion,
                          bp.transfusion_type_desc,
                          bp.quantity_received,
                          bp.quantity_ordered,
                          bp.barcode,
                          bp.blood_group,
                          bp.blood_group_rh,
                          bp.expiration_date,
                          bp.special_instr,
                          bp.tech_notes,
                          bp.prof_perform,
                          bp.start_time,
                          bp.duration,
                          bp.end_time,
                          bp.qty_given,
                          bp.desc_perform,
                          bp.exec_notes,
                          bp.action_reason,
                          bp.action_notes,
                          bp.id_prof_match,
                          bp.dt_match_tstz,
                          NULL desc_clinical_question,
                          bp.desc_compatibility,
                          bp.notes_compatibility,
                          bp.condition,
                          bp.blood_group_desc,
                          bp.lab_test_mother,
                          bp.donation_code,
                          bp.result_1,
                          bp.dt_result_1,
                          bp.result_sig_1,
                          bp.result_2,
                          bp.dt_result_2,
                          bp.result_sig_2,
                          bp.req_prof_without_crossmatch,
                          bp.req_statement_without_crossmatch,
                          bp.screening,
                          bp.nat_test,
                          bp.send_unit
                     FROM (SELECT /*+ opt_estimate(table cso rows=2) opt_estimate(table csc rows=2) */
                            bpd.id_blood_product_det,
                            NULL id_blood_product_execution,
                            'ORDER' action,
                            aa_code_messages('BLOOD_PRODUCTS_T37') desc_action,
                            NULL exec_number,
                            decode(i_flg_html_det, pk_alert_constant.g_no, l_msg_reg || ' ', NULL) ||
                            pk_prof_utils.get_name_signature(i_lang,
                                                             i_prof,
                                                             coalesce(bpd.id_prof_last_update, bpr.id_professional)) ||
                            decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                    i_prof,
                                                                    coalesce(bpd.id_prof_last_update, bpr.id_professional),
                                                                    coalesce(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                                    bpr.id_episode),
                                   NULL,
                                   '; ',
                                   ' (' ||
                                   pk_prof_utils.get_spec_signature(i_lang,
                                                                    i_prof,
                                                                    coalesce(bpd.id_prof_last_update, bpr.id_professional),
                                                                    coalesce(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                                    bpr.id_episode) || '); ') ||
                            pk_date_utils.date_char_tsz(i_lang,
                                                        coalesce(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                        i_prof.institution,
                                                        i_prof.software) registry,
                            decode(i_flg_html_det, pk_alert_constant.g_no, aa_code_messages('BLOOD_PRODUCTS_T20'), NULL) ||
                            (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                  i_prof,
                                                                                  bpd.id_blood_product_det,
                                                                                  pk_blood_products_constant.g_no)
                               FROM dual) desc_hemo_type,
                            decode(i_flg_html_det, pk_alert_constant.g_no, aa_code_messages('BLOOD_PRODUCTS_T51'), ' ') clinical_indication,
                            decode(pk_diagnosis.concat_diag(i_lang,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            i_prof,
                                                            NULL,
                                                            NULL,
                                                            bpd.id_blood_product_det),
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T52'),
                                          NULL) || pk_diagnosis.concat_diag(i_lang,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            i_prof,
                                                                            NULL,
                                                                            NULL,
                                                                            bpd.id_blood_product_det)) desc_diagnosis,
                            decode(bpd.id_clinical_purpose,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T53'),
                                          NULL) ||
                                   decode(bpd.id_clinical_purpose,
                                          0,
                                          bpd.clinical_purpose_notes,
                                          pk_translation.get_translation(i_lang,
                                                                         'MULTICHOICE_OPTION.CODE_MULTICHOICE_OPTION.' ||
                                                                         bpd.id_clinical_purpose))) clinical_purpose,
                            decode(i_flg_html_det, pk_alert_constant.g_no, aa_code_messages('BLOOD_PRODUCTS_T54'), NULL) instructions,
                            decode(bpd.flg_priority,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T55')) ||
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'BLOOD_PRODUCT_DET.FLG_PRIORITY',
                                                           bpd.flg_priority,
                                                           NULL)) priority,
                            decode(bpd.id_special_type,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T124'),
                                          NULL) ||
                                   (SELECT pk_multichoice.get_multichoice_option_desc(i_lang, i_prof, bpd.id_special_type)
                                      FROM dual)) special_type,
                            decode(i_flg_html_det,
                                   pk_alert_constant.g_no,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T56'),
                                   NULL) ||
                            pk_sysdomain.get_domain(i_lang, i_prof, 'INTERV_PRESCRIPTION.FLG_TIME', bpr.flg_time, NULL) || ' (' ||
                            pk_date_utils.date_char_tsz(i_lang, bpd.dt_begin_tstz, i_prof.institution, i_prof.software) || ')' desc_time,
                            decode(i_flg_html_det,
                                   pk_alert_constant.g_no,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T57'),
                                   NULL) ||
                            decode(bpd.id_order_recurrence,
                                   NULL,
                                   pk_message.get_message(i_lang, i_prof, 'ORDER_RECURRENCE_M004'),
                                   pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                         i_prof,
                                                                                         bpd.id_order_recurrence)) order_recurrence,
                            aa_code_messages('BLOOD_PRODUCTS_T58') execution,
                            decode(bpd.id_exec_institution,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T13'))) ||
                            decode(bpd.id_exec_institution,
                                   NULL,
                                   NULL,
                                   pk_sysdomain.get_domain(i_lang,
                                                           i_prof,
                                                           'BLOOD_PRODUCT_DET.ID_EXEC_INSTITUTION',
                                                           bpd.id_exec_institution,
                                                           NULL)) perform_location,
                            decode(cso.dt_ordered_by,
                                   NULL,
                                   decode(bpr.dt_req_tstz, --dt_order_tstz,
                                          NULL,
                                          NULL,
                                          decode(i_flg_html_det,
                                                 pk_alert_constant.g_no,
                                                 l_ident || aa_code_messages('BLOOD_PRODUCTS_T59'),
                                                 NULL) || pk_date_utils.date_char_tsz(i_lang,
                                                                                      bpr.dt_req_tstz, --ipd.dt_order_tstz
                                                                                      i_prof.institution,
                                                                                      i_prof.software)),
                                   NULL) dt_req,
                            decode(pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpd.id_not_order_reason),
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T05') ||
                                   pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpd.id_not_order_reason)) not_order_reason,
                            decode(bpd.notes, NULL, NULL, l_ident || aa_code_messages('BLOOD_PRODUCTS_T43') || bpd.notes) notes,
                            decode(cso.id_order_type, NULL, NULL, aa_code_messages('BLOOD_PRODUCTS_T09')) co_sign,
                            decode(cso.desc_prof_ordered_by,
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T08') || cso.desc_prof_ordered_by) prof_order,
                            decode(cso.dt_ordered_by,
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               cso.dt_ordered_by,
                                                               i_prof.institution,
                                                               i_prof.software)) dt_order,
                            decode(cso.id_order_type,
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T60') || cso.desc_order_type) order_type,
                            CASE
                                 WHEN bpd.flg_status IN
                                      (pk_blood_products_constant.g_status_det_c, pk_blood_products_constant.g_status_det_d) THEN
                                  aa_code_messages('BLOOD_PRODUCTS_T61')
                                 ELSE
                                  NULL
                             END cancellation,
                            CASE
                                 WHEN bpd.flg_status IN
                                      (pk_blood_products_constant.g_status_det_c, pk_blood_products_constant.g_status_det_d) THEN
                                  decode(bpd.flg_status,
                                         pk_blood_products_constant.g_status_req_i,
                                         l_ident || aa_code_messages('BLOOD_PRODUCTS_T62'),
                                         l_ident || aa_code_messages('BLOOD_PRODUCTS_T63')) ||
                                  pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, bpd.id_cancel_reason)
                                 ELSE
                                  NULL
                             END cancel_reason,
                            CASE
                                 WHEN bpd.flg_status IN
                                      (pk_blood_products_constant.g_status_det_c, pk_blood_products_constant.g_status_det_d) THEN
                                  decode(bpd.notes_cancel,
                                         NULL,
                                         NULL,
                                         l_ident || aa_code_messages('BLOOD_PRODUCTS_T64') || bpd.notes_cancel)
                                 ELSE
                                  NULL
                             END cancel_notes,
                            decode(csc.desc_prof_ordered_by,
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T08') || csc.desc_prof_ordered_by) cancel_prof_order,
                            decode(csc.dt_ordered_by,
                                   NULL,
                                   NULL,
                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               csc.dt_ordered_by,
                                                               i_prof.institution,
                                                               i_prof.software)) cancel_dt_order,
                            decode(csc.id_order_type,
                                   NULL,
                                   NULL,
                                   aa_code_messages('BLOOD_PRODUCTS_T60') || csc.desc_order_type) cancel_order_type,
                            CASE
                                 WHEN l_health_insurance = pk_blood_products_constant.g_no THEN
                                  NULL
                                 ELSE
                                  CASE
                                      WHEN bpd.id_pat_health_plan IS NOT NULL
                                           OR bpd.id_pat_health_plan IS NOT NULL
                                           OR bpd.id_pat_health_plan IS NOT NULL THEN
                                       aa_code_messages('BLOOD_PRODUCTS_T65')
                                  END
                             END health_insurance,
                            decode(l_health_insurance,
                                   pk_blood_products_constant.g_no,
                                   NULL,
                                   decode(bpd.id_pat_health_plan,
                                          NULL,
                                          NULL,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T66') ||
                                          pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'F'))) financial_entity,
                            decode(l_health_insurance,
                                   pk_blood_products_constant.g_no,
                                   NULL,
                                   decode(bpd.id_pat_health_plan,
                                          NULL,
                                          NULL,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T67') ||
                                          pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'H'))) health_plan,
                            decode(l_health_insurance,
                                   pk_blood_products_constant.g_no,
                                   NULL,
                                   decode(bpd.id_pat_health_plan,
                                          NULL,
                                          NULL,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T68') ||
                                          pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'N'))) insurance_number,
                            decode(l_health_insurance,
                                   pk_blood_products_constant.g_no,
                                   NULL,
                                   decode(bpd.id_pat_exemption,
                                          NULL,
                                          NULL,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T69') ||
                                          pk_adt.get_pat_exemption_detail(i_lang, i_prof, bpd.id_pat_exemption))) exemption,
                            --aa_code_messages('BLOOD_PRODUCTS_T85') transfusion,
                            NULL transfusion,
                            decode(bpd.transfusion_type,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T02'),
                                          NULL) || (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                                      i_prof,
                                                                                                      to_number(bpd.transfusion_type))
                                                      FROM dual)) transfusion_type_desc,
                            decode(bpd.qty_exec,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T03'),
                                          NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                        i_prof,
                                                                                                        (SELECT MAX(bpd_qty.qty_exec)
                                                                                                           FROM blood_product_det bpd_qty
                                                                                                          WHERE bpd_qty.id_blood_product_req IN
                                                                                                                (SELECT bpd_i.id_blood_product_req
                                                                                                                   FROM blood_product_det bpd_i
                                                                                                                  WHERE bpd_i.id_blood_product_det =
                                                                                                                        bpd.id_blood_product_det)),
                                                                                                        bpd.id_unit_mea_qty_exec)
                                                      FROM dual)) quantity_ordered,
                            NULL quantity_received,
                            NULL barcode,
                            NULL blood_group,
                            NULL blood_group_rh,
                            NULL desc_compatibility,
                            NULL notes_compatibility,
                            NULL expiration_date,
                            decode(bpd.special_instr,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T01'),
                                          NULL) || (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                                      i_prof,
                                                                                                      to_number(bpd.special_instr))
                                                      FROM dual)) special_instr,
                            decode(bpd.notes_tech,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T04')) || bpd.notes_tech) tech_notes,
                            NULL prof_perform,
                            NULL start_time,
                            NULL duration,
                            NULL end_time,
                            NULL qty_given,
                            NULL desc_perform,
                            NULL exec_notes,
                            NULL action_reason,
                            NULL action_notes,
                            NULL id_prof_match,
                            NULL dt_match_tstz,
                            NULL condition,
                            NULL blood_group_desc,
                            get_bp_lab_mother_desc(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_episode           => i_episode,
                                                   i_blood_product_det => bpd.id_blood_product_det,
                                                   i_flg_html_det      => i_flg_html_det) lab_test_mother,
                            NULL donation_code,
                            NULL result_1,
                            NULL dt_result_1,
                            NULL result_sig_1,
                            NULL result_2,
                            NULL dt_result_2,
                            NULL result_sig_2,
                            decode(bpd.id_prof_crossmatch,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          aa_code_messages('BLOOD_PRODUCTS_T165') || ' ',
                                          NULL) ||
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, bpd.id_prof_crossmatch) ||
                                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           bpd.id_prof_crossmatch,
                                                                           coalesce(bpd.dt_last_update_tstz,
                                                                                    bpr.dt_req_tstz),
                                                                           bpr.id_episode),
                                          NULL,
                                          '; ',
                                          ' (' ||
                                          pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           bpd.id_prof_crossmatch,
                                                                           coalesce(bpd.dt_last_update_tstz, bpr.dt_req_tstz),
                                                                           bpr.id_episode) || ')')) req_prof_without_crossmatch,
                            decode(bpd.flg_req_without_crossmatch,
                                   pk_alert_constant.g_yes,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          aa_code_messages('BLOOD_PRODUCTS_T162'),
                                          NULL) || (SELECT pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T153')
                                                      FROM dual)) req_statement_without_crossmatch,
                            decode(bpd.flg_with_screening,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T169'),
                                          NULL) ||
                                   pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_with_screening, NULL)) screening,
                            decode(bpd.flg_without_nat_test,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T170'),
                                          NULL) ||
                                   pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_without_nat_test, NULL)) nat_test,
                            decode(bpd.flg_prepare_not_send,
                                   NULL,
                                   NULL,
                                   decode(i_flg_html_det,
                                          pk_alert_constant.g_no,
                                          l_ident || aa_code_messages('BLOOD_PRODUCTS_T171'),
                                          NULL) ||
                                   pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_prepare_not_send, NULL)) send_unit
                             FROM blood_product_det bpd
                            INNER JOIN blood_product_req bpr
                               ON bpr.id_blood_product_req = bpd.id_blood_product_req
                             LEFT JOIN cso_table cso
                               ON cso.id_co_sign = bpd.id_co_sign_order
                             LEFT JOIN cso_table csc
                               ON csc.id_co_sign_hist = bpd.id_co_sign_cancel
                            WHERE bpd.id_blood_product_det = i_blood_product_det
                           UNION
                           SELECT bpd.id_blood_product_det,
                                  bpe.id_blood_product_execution,
                                  decode(i_flg_html_det,
                                         pk_alert_constant.g_no,
                                         bpe.action,
                                         decode(bpe.action,
                                                pk_blood_products_constant.g_bp_action_cancel,
                                                decode(bpd.qty_given,
                                                       NULL,
                                                       pk_blood_products_constant.g_bp_action_cancel,
                                                       pk_blood_products_constant.g_bp_action_discontinue),
                                                bpe.action)) action,
                                  decode(bpe.action,
                                         pk_blood_products_constant.g_bp_action_administer,
                                         aa_code_messages('BLOOD_PRODUCTS_T58'),
                                         pk_blood_products_constant.g_bp_action_hold,
                                         aa_code_messages('BLOOD_PRODUCTS_T80'),
                                         pk_blood_products_constant.g_bp_action_resume,
                                         aa_code_messages('BLOOD_PRODUCTS_T81'),
                                         pk_blood_products_constant.g_bp_action_report,
                                         aa_code_messages('BLOOD_PRODUCTS_T73'),
                                         pk_blood_products_constant.g_bp_action_reevaluate,
                                         aa_code_messages('BLOOD_PRODUCTS_T74'),
                                         pk_blood_products_constant.g_bp_action_conclude,
                                         aa_code_messages('BLOOD_PRODUCTS_T82'),
                                         pk_blood_products_constant.g_bp_action_return,
                                         aa_code_messages('BLOOD_PRODUCTS_T83'),
                                         pk_blood_products_constant.g_bp_action_cancel,
                                         decode(bpd.qty_given,
                                                NULL,
                                                aa_code_messages('BLOOD_PRODUCTS_T84'),
                                                aa_code_messages('BLOOD_PRODUCTS_T152')),
                                         pk_blood_products_constant.g_bp_action_begin_transp,
                                         aa_code_messages('BLOOD_PRODUCTS_T90'),
                                         pk_blood_products_constant.g_bp_action_end_transp,
                                         aa_code_messages('BLOOD_PRODUCTS_T91'),
                                         pk_blood_products_constant.g_bp_action_lab_service,
                                         aa_code_messages('BLOOD_PRODUCTS_T77'),
                                         pk_blood_products_constant.g_bp_action_compability,
                                         aa_code_messages('BLOOD_PRODUCTS_T77'),
                                         pk_blood_products_constant.g_bp_action_begin_return,
                                         aa_code_messages('BLOOD_PRODUCTS_T150'),
                                         pk_blood_products_constant.g_bp_action_end_return,
                                         aa_code_messages('BLOOD_PRODUCTS_T151'),
                                         'CONFIRM_TRANSFUSION',
                                         aa_code_messages('BLOOD_PRODUCTS_T172'),
                                         NULL) desc_action,
                                  (bpe.exec_number * 10) exec_number, --multiplier used in order to allow for the blood group info to be inserted after transport end
                                  decode(i_flg_html_det, pk_alert_constant.g_no, l_msg_reg || ' ') ||
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_professional) ||
                                  decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                          i_prof,
                                                                          bpe.id_professional,
                                                                          bpe.dt_bp_execution_tstz,
                                                                          i_episode),
                                         NULL,
                                         '; ',
                                         ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                  i_prof,
                                                                                  bpe.id_professional,
                                                                                  bpe.dt_bp_execution_tstz,
                                                                                  i_episode) || '); ') ||
                                  pk_date_utils.date_char_tsz(i_lang,
                                                              decode(bpe.action,
                                                                     pk_blood_products_constant.g_bp_action_lab_service,
                                                                     nvl(l_compatibility_date_reg, bpe.dt_bp_execution_tstz),
                                                                     pk_blood_products_constant.g_bp_action_lab_collected,
                                                                     nvl(l_compatibility_date_reg, bpe.dt_bp_execution_tstz),
                                                                     bpe.dt_bp_execution_tstz),
                                                              i_prof.institution,
                                                              i_prof.software) registry,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(i_flg_html_det,
                                              pk_alert_constant.g_no,
                                              aa_code_messages('BLOOD_PRODUCTS_T20'),
                                              NULL) || (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                                             i_prof,
                                                                                                             bpd.id_blood_product_det,
                                                                                                             pk_blood_products_constant.g_yes)
                                                          FROM dual)
                                      ELSE
                                       NULL
                                  END desc_hemo_type,
                                  NULL clinical_indication,
                                  NULL desc_diagnosis,
                                  NULL clinical_purpose,
                                  NULL instructions,
                                  NULL priority,
                                  NULL special_type,
                                  NULL desc_time,
                                  NULL order_recurrence,
                                  NULL execution,
                                  NULL perform_location,
                                  NULL dt_req,
                                  NULL not_order_reason,
                                  CASE
                                      WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                          pk_blood_products_constant.g_bp_action_end_transp,
                                                          pk_blood_products_constant.g_bp_action_administer,
                                                          pk_blood_products_constant.g_bp_action_begin_return,
                                                          pk_blood_products_constant.g_bp_action_end_return)
                                           AND i_flg_html_det = pk_alert_constant.g_yes THEN
                                       pk_blood_products_core.get_bp_condition_detail(i_lang              => i_lang,
                                                                                      i_prof              => i_prof,
                                                                                      i_blood_product_det => bpe.id_blood_product_det,
                                                                                      i_exec_number       => bpe.exec_number - 1,
                                                                                      i_flg_report        => i_flg_report,
                                                                                      i_flg_html          => i_flg_html_det,
                                                                                      i_flg_html_mode     => CASE
                                                                                                                 WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                                                  pk_blood_products_constant.g_bp_condition_notes
                                                                                                                 ELSE
                                                                                                                  NULL
                                                                                                             END)
                                      ELSE
                                       NULL
                                  END notes,
                                  NULL co_sign,
                                  NULL prof_order,
                                  NULL dt_order,
                                  NULL order_type,
                                  NULL cancellation,
                                  NULL cancel_reason,
                                  NULL cancel_notes,
                                  NULL cancel_prof_order,
                                  NULL cancel_dt_order,
                                  NULL cancel_order_type,
                                  NULL health_insurance,
                                  NULL financial_entity,
                                  NULL health_plan,
                                  NULL insurance_number,
                                  NULL exemption,
                                  NULL transfusion,
                                  NULL transfusion_type_desc,
                                  NULL quantity_ordered,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.qty_received,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T32'),
                                                     NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                                   i_prof,
                                                                                                                   bpd.qty_received,
                                                                                                                   bpd.id_unit_mea_qty_received)
                                                                 FROM dual))
                                      ELSE
                                       NULL
                                  END quantity_received,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.barcode_lab,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T24'),
                                                     NULL) || bpd.barcode_lab)
                                      ELSE
                                       NULL
                                  END barcode,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.blood_group,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T30'),
                                                     NULL) || bpd.blood_group)
                                      ELSE
                                       NULL
                                  END blood_group,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.blood_group_rh,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T86'),
                                                     NULL) || pk_sysdomain.get_domain(i_lang,
                                                                                      i_prof,
                                                                                      'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS',
                                                                                      bpd.blood_group_rh,
                                                                                      NULL))
                                      ELSE
                                       NULL
                                  END blood_group_rh,
                                  decode(l_compatibility_desc,
                                         NULL,
                                         NULL,
                                         decode(bpe.action,
                                                pk_blood_products_constant.g_bp_action_lab_service,
                                                aa_code_messages('BLOOD_PRODUCTS_T128') ||
                                                pk_blood_products_utils.get_bp_compatibility_desc(i_lang,
                                                                                                  i_prof,
                                                                                                  i_blood_product_det),
                                                NULL)) desc_compatibility,
                                  decode(l_compatibility_notes,
                                         NULL,
                                         NULL,
                                         decode(bpe.action,
                                                pk_blood_products_constant.g_bp_action_lab_service,
                                                decode(i_flg_report,
                                                       pk_alert_constant.g_yes,
                                                       aa_code_messages('BLOOD_PRODUCTS_T127') ||
                                                       pk_blood_products_utils.get_bp_compatibility_notes(i_lang,
                                                                                                          i_prof,
                                                                                                          i_blood_product_det),
                                                       aa_code_messages('BLOOD_PRODUCTS_T127') ||
                                                       pk_blood_products_utils.get_bp_compatibility_notes(i_lang,
                                                                                                          i_prof,
                                                                                                          i_blood_product_det)),
                                                NULL)) notes_compatibility,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.expiration_date,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T25'),
                                                     NULL) || pk_date_utils.date_char_tsz(i_lang,
                                                                                          bpd.expiration_date,
                                                                                          i_prof.institution,
                                                                                          i_prof.software))
                                      ELSE
                                       NULL
                                  END expiration_date,
                                  NULL special_instr,
                                  NULL tech_notes,
                                  CASE
                                      WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_administer,
                                                          pk_blood_products_constant.g_bp_action_reevaluate,
                                                          pk_blood_products_constant.g_bp_action_conclude) THEN
                                       decode(bpe.id_prof_performed,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T39'),
                                                     NULL) ||
                                              pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_performed))
                                      ELSE
                                       NULL
                                  END prof_perform,
                                  decode(bpe.dt_begin,
                                         NULL,
                                         NULL,
                                         CASE
                                             WHEN bpe.action = pk_blood_products_constant.g_bp_action_reevaluate THEN
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T93'),
                                                     NULL)
                                             ELSE
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T40'),
                                                     NULL)
                                         END || pk_date_utils.date_char_tsz(i_lang,
                                                                            bpe.dt_begin,
                                                                            i_prof.institution,
                                                                            i_prof.software)) start_time,
                                  decode(bpe.duration,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('BLOOD_PRODUCTS_T41'),
                                                NULL) || bpe.duration || ' ' ||
                                         pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                      i_prof,
                                                                                      bpe.id_unit_mea_duration)) duration,
                                  decode(bpe.dt_end,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('BLOOD_PRODUCTS_T42'),
                                                NULL) || pk_date_utils.date_char_tsz(i_lang,
                                                                                     bpe.dt_end,
                                                                                     i_prof.institution,
                                                                                     i_prof.software)) end_time,
                                  decode(bpe.dt_end,
                                         NULL,
                                         CASE
                                             WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_cancel)
                                                  AND bpd.qty_given IS NOT NULL THEN
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T121'),
                                                     NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                                   i_prof,
                                                                                                                   bpd.qty_given,
                                                                                                                   bpd.id_unit_mea_qty_given)
                                                                 FROM dual)
                                             ELSE
                                              NULL
                                         END,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('BLOOD_PRODUCTS_T121'),
                                                NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                              i_prof,
                                                                                                              bpd.qty_given,
                                                                                                              bpd.id_unit_mea_qty_given)
                                                            FROM dual)) qty_given,
                                  to_char(decode(dbms_lob.getlength(t.l_notes),
                                                 NULL,
                                                 to_clob(''),
                                                 decode(instr(lower(decode(i_flg_report,
                                                                           pk_blood_products_constant.g_no,
                                                                           REPLACE((REPLACE(t.l_notes,
                                                                                            chr(10) || chr(10),
                                                                                            chr(10))),
                                                                                   chr(10),
                                                                                   chr(10) || chr(9)),
                                                                           REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                                              '<b>'),
                                                        0,
                                                        to_clob(decode(i_flg_html_det,
                                                                       pk_alert_constant.g_no,
                                                                       aa_code_messages('BLOOD_PRODUCTS_T43'),
                                                                       NULL) ||
                                                                decode(i_flg_report,
                                                                       pk_blood_products_constant.g_no,
                                                                       REPLACE((REPLACE(t.l_notes,
                                                                                        chr(10) || chr(10),
                                                                                        chr(10))),
                                                                               chr(10),
                                                                               chr(10) || chr(9)),
                                                                       REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                                        decode(i_flg_report,
                                                               pk_blood_products_constant.g_no,
                                                               REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                                       chr(10),
                                                                       chr(10) || chr(9)),
                                                               REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))))) desc_perform,
                                  decode(bpe.description,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('COMMON_M044'),
                                                NULL) || ' ' || bpe.description) exec_notes,
                                  CASE
                                      WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                          pk_blood_products_constant.g_bp_action_end_transp,
                                                          pk_blood_products_constant.g_bp_action_administer,
                                                          pk_blood_products_constant.g_bp_action_begin_return,
                                                          pk_blood_products_constant.g_bp_action_end_return)
                                           AND i_flg_html_det = pk_alert_constant.g_yes THEN
                                       pk_blood_products_core.get_bp_condition_detail(i_lang              => i_lang,
                                                                                      i_prof              => i_prof,
                                                                                      i_blood_product_det => bpe.id_blood_product_det,
                                                                                      i_exec_number       => bpe.exec_number - 1,
                                                                                      i_flg_report        => i_flg_report,
                                                                                      i_flg_html          => i_flg_html_det,
                                                                                      i_flg_html_mode     => CASE
                                                                                                                 WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                                                  pk_blood_products_constant.g_bp_condition_reason
                                                                                                                 ELSE
                                                                                                                  NULL
                                                                                                             END)
                                      ELSE
                                       decode(bpe.id_action_reason,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('CANCEL_SCREEN_LABELS_T003') || ' ',
                                                     NULL) ||
                                              pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, bpe.id_action_reason))
                                  END action_reason,
                                  decode(bpe.notes_reason,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('COMMON_M044') || ' ',
                                                NULL) || bpe.notes_reason) action_notes,
                                  decode(bpe.id_prof_match,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('BLOOD_PRODUCTS_T33'),
                                                NULL) ||
                                         pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_match)) id_prof_match,
                                  decode(bpe.dt_match_tstz,
                                         NULL,
                                         NULL,
                                         decode(i_flg_html_det,
                                                pk_alert_constant.g_no,
                                                aa_code_messages('BLOOD_PRODUCTS_T88'),
                                                NULL) || pk_date_utils.date_char_tsz(i_lang,
                                                                                     bpe.dt_match_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software)) dt_match_tstz,
                                  CASE
                                      WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                          pk_blood_products_constant.g_bp_action_end_transp,
                                                          pk_blood_products_constant.g_bp_action_administer,
                                                          pk_blood_products_constant.g_bp_action_begin_return,
                                                          pk_blood_products_constant.g_bp_action_end_return) THEN
                                       get_bp_condition_detail(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_blood_product_det => bpe.id_blood_product_det,
                                                               i_exec_number       => bpe.exec_number - 1,
                                                               i_flg_report        => i_flg_report,
                                                               i_flg_html          => i_flg_html_det,
                                                               i_flg_html_mode     => CASE
                                                                                          WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                           'C'
                                                                                          ELSE
                                                                                           NULL
                                                                                      END)
                                      ELSE
                                       NULL
                                  END condition,
                                  NULL blood_group_desc,
                                  NULL lab_test_mother,
                                  CASE
                                      WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                                       decode(bpd.donation_code,
                                              NULL,
                                              NULL,
                                              decode(i_flg_html_det,
                                                     pk_alert_constant.g_no,
                                                     aa_code_messages('BLOOD_PRODUCTS_T146'),
                                                     NULL) || bpd.donation_code)
                                      ELSE
                                       NULL
                                  END donation_code,
                                  NULL result_1,
                                  NULL dt_result_1,
                                  NULL result_sig_1,
                                  NULL result_2,
                                  NULL dt_result_2,
                                  NULL result_sig_2,
                                  NULL req_prof_without_crossmatch,
                                  NULL req_statement_without_crossmatch,
                                  NULL screening,
                                  NULL nat_test,
                                  NULL send_unit
                             FROM blood_product_execution bpe
                             JOIN blood_product_det bpd
                               ON bpd.id_blood_product_det = bpe.id_blood_product_det
                             LEFT JOIN TABLE(l_tbl_bp_notes) t
                               ON t.l_id_blood_product_det = bpe.id_blood_product_det
                              AND t.l_id_blod_product_execution = bpe.id_blood_product_execution
                            WHERE bpd.id_blood_product_det = i_blood_product_det
                              AND bpe.action NOT IN
                                  (pk_blood_products_constant.g_bp_action_compability,
                                   pk_blood_products_constant.g_bp_action_condition,
                                   pk_blood_products_constant.g_bp_action_lab_mother,
                                   pk_blood_products_constant.g_bp_action_lab_mother_id)
                           UNION
                           --Select to fetch the blood group information
                           SELECT NULL id_blood_product_det,
                                  NULL id_blood_product_execution,
                                  CASE
                                      WHEN l_blood_group_desc IS NOT NULL THEN
                                       pk_blood_products_constant.g_bp_action_blood_group
                                      ELSE
                                       NULL
                                  END action,
                                  CASE
                                      WHEN l_blood_group_desc IS NOT NULL THEN
                                       decode(i_flg_html_det,
                                              pk_alert_constant.g_no,
                                              aa_code_messages('BLOOD_PRODUCTS_T143'))
                                      ELSE
                                       NULL
                                  END desc_action,
                                  CASE
                                      WHEN l_blood_group_desc IS NOT NULL THEN
                                       get_bp_blood_group_rank(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_blood_product_det => i_blood_product_det)
                                      ELSE
                                       NULL
                                  END exec_number,
                                  NULL registry,
                                  NULL desc_hemo_type,
                                  NULL clinical_indication,
                                  NULL desc_diagnosis,
                                  NULL clinical_purpose,
                                  NULL instructions,
                                  NULL priority,
                                  NULL special_type,
                                  NULL desc_time,
                                  NULL order_recurrence,
                                  NULL execution,
                                  NULL perform_location,
                                  NULL dt_req,
                                  NULL not_order_reason,
                                  NULL notes,
                                  NULL co_sign,
                                  NULL prof_order,
                                  NULL dt_order,
                                  NULL order_type,
                                  NULL cancellation,
                                  NULL cancel_reason,
                                  NULL cancel_notes,
                                  NULL cancel_prof_order,
                                  NULL cancel_dt_order,
                                  NULL cancel_order_type,
                                  NULL health_insurance,
                                  NULL financial_entity,
                                  NULL health_plan,
                                  NULL insurance_number,
                                  NULL exemption,
                                  NULL transfusion,
                                  NULL transfusion_type_desc,
                                  NULL quantity_ordered,
                                  NULL quantity_received,
                                  NULL barcode,
                                  NULL blood_group,
                                  NULL blood_group_rh,
                                  NULL desc_compatibility,
                                  NULL notes_compatibility,
                                  NULL expiration_date,
                                  NULL special_instr,
                                  NULL tech_notes,
                                  NULL prof_perform,
                                  NULL start_time,
                                  NULL duration,
                                  NULL end_time,
                                  NULL qty_given,
                                  NULL desc_perform,
                                  NULL exec_notes,
                                  NULL action_reason,
                                  NULL action_notes,
                                  NULL id_prof_match,
                                  NULL dt_match_tstz,
                                  NULL condition,
                                  l_blood_group_desc blood_group_desc,
                                  NULL lab_test_mother,
                                  NULL donation_code,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_1) result_1,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_dt_result_1) dt_result_1,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_sig_1) result_sig_1,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_2) result_2,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_dt_result_2) dt_result_2,
                                  decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_sig_2) result_sig_2,
                                  NULL req_prof_without_crossmatch,
                                  NULL req_statement_without_crossmatch,
                                  NULL screening,
                                  NULL nat_test,
                                  NULL send_unit
                             FROM dual) bp
                    WHERE bp.action IS NOT NULL
                      AND bp.action != pk_blood_products_constant.g_bp_action_lab_collected
                    ORDER BY bp.exec_number DESC NULLS LAST) t;
    
    
        RETURN l_tbl_bp_detail;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_tbl_bp_detail;
    END tf_get_bp_detail;

    FUNCTION tf_get_bp_detail_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail_hist IS
    
        l_tbl_bp_hist_info_core t_tbl_bp_task_detail_hist_core;
        l_tbl_bp_hist_info      t_tbl_bp_task_detail_hist;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('BLOOD_PRODUCTS_T01',
                                                        'BLOOD_PRODUCTS_T02',
                                                        'BLOOD_PRODUCTS_T03',
                                                        'BLOOD_PRODUCTS_T04',
                                                        'BLOOD_PRODUCTS_T05',
                                                        'BLOOD_PRODUCTS_T08',
                                                        'BLOOD_PRODUCTS_T09',
                                                        'BLOOD_PRODUCTS_T13',
                                                        'BLOOD_PRODUCTS_T14',
                                                        'BLOOD_PRODUCTS_T20',
                                                        'BLOOD_PRODUCTS_T24',
                                                        'BLOOD_PRODUCTS_T25',
                                                        'BLOOD_PRODUCTS_T30',
                                                        'BLOOD_PRODUCTS_T32',
                                                        'BLOOD_PRODUCTS_T33',
                                                        'BLOOD_PRODUCTS_T37',
                                                        'BLOOD_PRODUCTS_T39',
                                                        'BLOOD_PRODUCTS_T40',
                                                        'BLOOD_PRODUCTS_T41',
                                                        'BLOOD_PRODUCTS_T42',
                                                        'BLOOD_PRODUCTS_T43',
                                                        'BLOOD_PRODUCTS_T51',
                                                        'BLOOD_PRODUCTS_T52',
                                                        'BLOOD_PRODUCTS_T53',
                                                        'BLOOD_PRODUCTS_T54',
                                                        'BLOOD_PRODUCTS_T55',
                                                        'BLOOD_PRODUCTS_T56',
                                                        'BLOOD_PRODUCTS_T57',
                                                        'BLOOD_PRODUCTS_T58',
                                                        'BLOOD_PRODUCTS_T59',
                                                        'BLOOD_PRODUCTS_T60',
                                                        'BLOOD_PRODUCTS_T61',
                                                        'BLOOD_PRODUCTS_T62',
                                                        'BLOOD_PRODUCTS_T63',
                                                        'BLOOD_PRODUCTS_T64',
                                                        'BLOOD_PRODUCTS_T65',
                                                        'BLOOD_PRODUCTS_T66',
                                                        'BLOOD_PRODUCTS_T67',
                                                        'BLOOD_PRODUCTS_T68',
                                                        'BLOOD_PRODUCTS_T69',
                                                        'BLOOD_PRODUCTS_T70',
                                                        'BLOOD_PRODUCTS_T72',
                                                        'BLOOD_PRODUCTS_T73',
                                                        'BLOOD_PRODUCTS_T74',
                                                        'BLOOD_PRODUCTS_T77',
                                                        'COMMON_M044',
                                                        'CANCEL_SCREEN_LABELS_T003',
                                                        'BLOOD_PRODUCTS_T80',
                                                        'BLOOD_PRODUCTS_T81',
                                                        'BLOOD_PRODUCTS_T82',
                                                        'BLOOD_PRODUCTS_T83',
                                                        'BLOOD_PRODUCTS_T84',
                                                        'BLOOD_PRODUCTS_T85',
                                                        'BLOOD_PRODUCTS_T86',
                                                        'BLOOD_PRODUCTS_T88',
                                                        'BLOOD_PRODUCTS_T89',
                                                        'BLOOD_PRODUCTS_T90',
                                                        'BLOOD_PRODUCTS_T91',
                                                        'BLOOD_PRODUCTS_T96',
                                                        'BLOOD_PRODUCTS_T97',
                                                        'BLOOD_PRODUCTS_T98',
                                                        'BLOOD_PRODUCTS_T99',
                                                        'BLOOD_PRODUCTS_T100',
                                                        'BLOOD_PRODUCTS_T101',
                                                        'BLOOD_PRODUCTS_T102',
                                                        'BLOOD_PRODUCTS_T103',
                                                        'BLOOD_PRODUCTS_T104',
                                                        'BLOOD_PRODUCTS_T105',
                                                        'BLOOD_PRODUCTS_T106',
                                                        'BLOOD_PRODUCTS_T107',
                                                        'BLOOD_PRODUCTS_T108',
                                                        'BLOOD_PRODUCTS_T109',
                                                        'BLOOD_PRODUCTS_T114',
                                                        'BLOOD_PRODUCTS_T115',
                                                        'BLOOD_PRODUCTS_T116',
                                                        'BLOOD_PRODUCTS_T117',
                                                        'BLOOD_PRODUCTS_T118',
                                                        'BLOOD_PRODUCTS_T119',
                                                        'BLOOD_PRODUCTS_T120',
                                                        'BLOOD_PRODUCTS_T121',
                                                        'BLOOD_PRODUCTS_T123',
                                                        'BLOOD_PRODUCTS_T124',
                                                        'BLOOD_PRODUCTS_T127',
                                                        'BLOOD_PRODUCTS_T128',
                                                        'BLOOD_PRODUCTS_T130',
                                                        'BLOOD_PRODUCTS_T131',
                                                        'BLOOD_PRODUCTS_T143',
                                                        'BLOOD_PRODUCTS_T146',
                                                        'BLOOD_PRODUCTS_T150',
                                                        'BLOOD_PRODUCTS_T151',
                                                        'BLOOD_PRODUCTS_T152',
                                                        'BLOOD_PRODUCTS_T162',
                                                        'BLOOD_PRODUCTS_T163',
                                                        'BLOOD_PRODUCTS_T165',
                                                        'BLOOD_PRODUCTS_T166',
                                                        'BLOOD_PRODUCTS_T169',
                                                        'BLOOD_PRODUCTS_T170',
                                                        'BLOOD_PRODUCTS_T171',
                                                        'BLOOD_PRODUCTS_T172');
    
        l_ident VARCHAR2(3) := '   ';
    
        --DOCUMENTED
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        l_cur_bp_doc_val pk_touch_option_out.t_cur_plain_text_entry;
        l_bp_doc_val     pk_touch_option_out.t_rec_plain_text_entry;
    
        l_health_insurance sys_config.value%TYPE := pk_sysconfig.get_config('MCDT_HEALTH_INSURANCE', i_prof);
    
        l_formated_text VARCHAR2(100 CHAR) := '<br>' || chr(9) || chr(32) || chr(32);
        l_msg_del       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M106');
    
        l_rn_cq NUMBER := 0;
    
        l_compatibility_desc     VARCHAR2(200 CHAR);
        l_compatibility_notes    VARCHAR2(200 CHAR);
        l_compatibility_date_reg blood_product_execution.dt_bp_execution_tstz%TYPE;
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' ||
                                                     pk_message.get_message(i_lang, i_prof, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_ident := '';
        ELSE
            l_ident := '   ';
        END IF;
    
        l_tbl_bp_hist_info_core := tf_get_bp_detail_history_core(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_episode           => i_episode,
                                                                 i_blood_product_det => i_blood_product_det,
                                                                 i_flg_report        => i_flg_report,
                                                                 i_aa_code_messages  => aa_code_messages,
                                                                 i_flg_html_det      => i_flg_html_det);
    
        WITH cso_table AS
         (SELECT *
            FROM TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang, i_prof, i_episode, NULL)))
        SELECT t_bp_task_detail_hist(action                               => b.action,
                                      desc_action                          => b.desc_action,
                                      exec_number                          => b.exec_number,
                                      desc_hemo_type                       => b.desc_hemo_type,
                                      desc_diagnosis                       => b.desc_diagnosis,
                                      desc_diagnosis_new                   => b.desc_diagnosis_new,
                                      clinical_purpose                     => b.clinical_purpose,
                                      clinical_purpose_new                 => b.clinical_purpose_new,
                                      priority                             => b.priority,
                                      priority_new                         => b.priority_new,
                                      special_type                         => b.special_type,
                                      special_type_new                     => b.special_type_new,
                                      desc_time                            => b.desc_time,
                                      desc_time_new                        => b.desc_time_new,
                                      order_recurrence                     => b.order_recurrence,
                                      execution                            => b.execution,
                                      transfusion_type_desc                => b.transfusion_type_desc,
                                      transfusion_type_desc_new            => b.transfusion_type_desc_new,
                                      quantity_ordered                     => b.quantity_ordered,
                                      quantity_ordered_new                 => b.quantity_ordered_new,
                                      perform_location                     => b.perform_location,
                                      perform_location_new                 => b.perform_location_new,
                                      dt_req                               => b.dt_req,
                                      special_instr                        => b.special_instr,
                                      special_instr_new                    => b.special_instr_new,
                                      tech_notes                           => b.tech_notes,
                                      tech_notes_new                       => b.tech_notes_new,
                                      notes                                => b.notes,
                                      prof_order                           => b.prof_order,
                                      dt_order                             => b.dt_order,
                                      order_type                           => b.order_type,
                                      financial_entity                     => b.financial_entity,
                                      health_plan                          => b.health_plan,
                                      insurance_number                     => b.insurance_number,
                                      dt_blood_product_det_hist            => b.dt_blood_product_det_hist,
                                      transfusion                          => b.transfusion,
                                      quantity_received                    => b.quantity_received,
                                      barcode                              => b.barcode,
                                      blood_group                          => b.blood_group,
                                      blood_group_rh                       => b.blood_group_rh,
                                      expiration_date                      => b.expiration_date,
                                      prof_perform                         => b.prof_perform,
                                      start_time                           => b.start_time,
                                      end_time                             => b.end_time,
                                      qty_given                            => b.qty_given,
                                      desc_perform                         => b.desc_perform,
                                      exec_notes                           => b.exec_notes,
                                      action_reason                        => b.action_reason,
                                      action_notes                         => b.action_notes,
                                      id_prof_match                        => b.id_prof_match,
                                      dt_match_tstz                        => b.dt_match_tstz,
                                      dt_req_tstz                          => b.dt_req_tstz,
                                      dt_last_update_tstz                  => b.dt_last_update_tstz,
                                      dt_blood_product_det_h               => b.dt_blood_product_det_h,
                                      dt_last_update_h                     => b.dt_last_update_h,
                                      id_professional                      => b.id_professional,
                                      id_prof_last_update                  => b.id_prof_last_update,
                                      id_professional_h                    => b.id_professional_h,
                                      id_prof_last_update_h                => b.id_prof_last_update_h,
                                      co_sign                              => CASE
                                                                                  WHEN b.prof_order IS NOT NULL
                                                                                       OR b.dt_order IS NOT NULL
                                                                                       OR b.order_type IS NOT NULL THEN
                                                                                   b.co_sign
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                      clinical_indication                  => CASE
                                                                                  WHEN b.desc_diagnosis IS NULL
                                                                                       AND b.clinical_purpose IS NULL THEN
                                                                                   NULL
                                                                                  ELSE
                                                                                   b.clinical_indication
                                                                              END,
                                      instructions                         => CASE
                                                                                  WHEN b.priority IS NOT NULL
                                                                                       OR b.desc_time IS NOT NULL
                                                                                       OR b.order_recurrence IS NOT NULL
                                                                                       OR b.transfusion_type_desc IS NOT NULL
                                                                                       OR b.quantity_ordered IS NOT NULL
                                                                                       OR b.perform_location IS NOT NULL
                                                                                       OR b.dt_req IS NOT NULL
                                                                                       OR special_instr IS NOT NULL
                                                                                       OR b.tech_notes IS NOT NULL THEN
                                                                                   b.instructions
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                      health_insurance                     => CASE
                                                                                  WHEN b.financial_entity IS NOT NULL
                                                                                       OR b.health_plan IS NOT NULL
                                                                                       OR b.insurance_number IS NOT NULL THEN
                                                                                   b.health_insurance
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                      registry                             => CASE
                                                                                  WHEN rownum = 1 THEN
                                                                                   decode(i_flg_html_det, pk_alert_constant.g_no, l_msg_reg || ' ', NULL) ||
                                                                                   pk_prof_utils.get_name_signature(i_lang, i_prof, coalesce(id_professional, id_professional_h)) ||
                                                                                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                                                           i_prof,
                                                                                                                           coalesce(id_professional, id_professional_h),
                                                                                                                           coalesce(dt_req_tstz, dt_blood_product_det_h),
                                                                                                                           i_episode),
                                                                                          NULL,
                                                                                          '; ',
                                                                                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   coalesce(id_professional, id_professional_h),
                                                                                                                                   coalesce(dt_req_tstz, dt_blood_product_det_h),
                                                                                                                                   i_episode) || '); ') ||
                                                                                   pk_date_utils.date_char_tsz(i_lang,
                                                                                                               coalesce(dt_req_tstz, dt_blood_product_det_h),
                                                                                                               i_prof.institution,
                                                                                                               i_prof.software)
                                                                                  WHEN action <> pk_blood_products_constant.g_bp_action_blood_group THEN
                                                                                   decode(i_flg_html_det, pk_alert_constant.g_no, l_msg_reg || ' ', NULL) ||
                                                                                   pk_prof_utils.get_name_signature(i_lang,
                                                                                                                    i_prof,
                                                                                                                    coalesce(id_professional_h, id_prof_last_update, id_professional)) ||
                                                                                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                                                           i_prof,
                                                                                                                           coalesce(id_professional_h,
                                                                                                                                    id_prof_last_update,
                                                                                                                                    id_professional),
                                                                                                                           coalesce(dt_blood_product_det_h,
                                                                                                                                    dt_last_update_tstz,
                                                                                                                                    dt_req_tstz),
                                                                                                                           i_episode),
                                                                                          NULL,
                                                                                          '; ',
                                                                                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   coalesce(id_professional_h,
                                                                                                                                            id_prof_last_update,
                                                                                                                                            id_professional),
                                                                                                                                   coalesce(dt_blood_product_det_h,
                                                                                                                                            dt_last_update_tstz,
                                                                                                                                            dt_req_tstz),
                                                                                                                                   i_episode) || '); ') ||
                                                                                   pk_date_utils.date_char_tsz(i_lang,
                                                                                                               coalesce(dt_blood_product_det_h, dt_last_update_tstz, dt_req_tstz),
                                                                                                               i_prof.institution,
                                                                                                               i_prof.software)
                                                                              END,
                                      desc_compatibility                   => desc_compatibility,
                                      notes_compatibility                  => notes_compatibility,
                                      condition                            => condition,
                                      blood_group_desc                     => b.blood_group_desc,
                                      lab_test_mother                      => lab_test_mother,
                                      donation_code                        => donation_code,
                                      duration                             => duration,
                                      result_1                             => result_1,
                                      dt_result_1                          => dt_result_1,
                                      result_sig_1                         => result_sig_1,
                                      result_2                             => result_2,
                                      dt_result_2                          => dt_result_2,
                                      result_sig_2                         => result_sig_2,
                                      req_statement_without_crossmatch     => req_statement_without_crossmatch,
                                      req_statement_without_crossmatch_new => req_statement_without_crossmatch_new,
                                      req_prof_without_crossmatch          => req_prof_without_crossmatch,
                                      req_prof_without_crossmatch_new      => req_prof_without_crossmatch_new,
                                      screening                            => screening,
                                      nat_test                             => nat_test,
                                      send_unit                            => send_unit)
          BULK COLLECT
          INTO l_tbl_bp_hist_info
          FROM (SELECT t.cnt,
                       t.rn,
                       t.action,
                       t.desc_action,
                       t.exec_number,
                       decode(t.cnt,
                              t.rn,
                              decode(i_flg_html_det, pk_alert_constant.g_no, aa_code_messages('BLOOD_PRODUCTS_T20')) ||
                              t.desc_hemo_type,
                              NULL) desc_hemo_type,
                       decode(i_flg_html_det, pk_alert_constant.g_no, t.clinical_indication, ' ') clinical_indication,
                       decode(t.cnt,
                              t.rn,
                              decode(t.desc_diagnosis,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T52') || t.desc_diagnosis,
                                            t.desc_diagnosis)),
                              decode(t.desc_diagnosis,
                                     t.desc_diagnosis_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T97') || '§' ||
                                                   decode(t.desc_diagnosis, NULL, l_msg_del, t.desc_diagnosis) ||
                                                   decode(t.desc_diagnosis_new,
                                                          NULL,
                                                          NULL,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T52') ||
                                                          t.desc_diagnosis_new),
                                                   t.desc_diagnosis_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T97') ||
                                            decode(t.desc_diagnosis, NULL, l_msg_del, t.desc_diagnosis) ||
                                            decode(t.desc_diagnosis_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T52') ||
                                                   t.desc_diagnosis_new)))) desc_diagnosis,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.cnt,
                                     t.rn,
                                     NULL,
                                     decode(t.desc_diagnosis,
                                            t.desc_diagnosis_new,
                                            NULL,
                                            decode(t.desc_diagnosis, NULL, l_msg_del, t.desc_diagnosis)))) desc_diagnosis_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.clinical_purpose,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T53'),
                                            NULL) || t.clinical_purpose),
                              decode(t.clinical_purpose,
                                     t.clinical_purpose_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T98') || '§' ||
                                                   decode(t.clinical_purpose, NULL, l_msg_del, t.clinical_purpose),
                                                   NULL) ||
                                            decode(t.clinical_purpose_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T53'),
                                                          NULL) || t.clinical_purpose_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T98') ||
                                            decode(t.clinical_purpose, NULL, l_msg_del, t.clinical_purpose) ||
                                            decode(t.clinical_purpose_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T53') ||
                                                   t.clinical_purpose_new)))) clinical_purpose,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.clinical_purpose,
                                     t.clinical_purpose_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.clinical_purpose)) clinical_purpose_new,
                       decode(i_flg_html_det, pk_alert_constant.g_no, t.instructions, ' ') instructions,
                       decode(t.cnt,
                              t.rn,
                              decode(t.priority,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T55'),
                                            NULL) || t.priority),
                              decode(t.priority,
                                     t.priority_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T99') || '§' ||
                                                   decode(t.priority, NULL, l_msg_del, t.priority),
                                                   NULL) ||
                                            decode(t.priority_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T55'),
                                                          NULL) || t.priority_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T99') ||
                                            decode(t.priority, NULL, l_msg_del, t.priority) ||
                                            decode(t.priority_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T55') ||
                                                   t.priority_new)))) priority,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.priority, t.priority_new, NULL, NULL, l_msg_del, t.priority)) priority_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.special_type,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T124'),
                                            NULL) || t.special_type),
                              decode(t.special_type,
                                     t.special_type_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T123') || '§' ||
                                                   decode(t.special_type, NULL, l_msg_del, t.special_type)) ||
                                            decode(t.special_type_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T124'),
                                                          NULL) || t.special_type_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T123') ||
                                            decode(t.special_type, NULL, l_msg_del, t.special_type) ||
                                            decode(t.special_type_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T124') ||
                                                   t.special_type_new)))) special_type,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.special_type, t.special_type_new, NULL, NULL, l_msg_del, t.special_type)) special_type_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.desc_time,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T56'),
                                            NULL) || t.desc_time),
                              decode(t.desc_time,
                                     t.desc_time_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T100') || '§' ||
                                                   decode(t.desc_time, NULL, l_msg_del, t.desc_time),
                                                   NULL) ||
                                            decode(t.desc_time_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T56'),
                                                          NULL) || t.desc_time_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T100') ||
                                            decode(t.desc_time, NULL, l_msg_del, t.desc_time) ||
                                            decode(t.desc_time_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T56') ||
                                                   t.desc_time_new)))) desc_time,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.desc_time, t.desc_time_new, NULL, NULL, l_msg_del, t.desc_time)) desc_time_new,
                       decode(t.order_recurrence,
                              NULL,
                              NULL,
                              decode(t.cnt,
                                     t.rn,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T57'),
                                            NULL) || t.order_recurrence,
                                     NULL)) order_recurrence,
                       t.execution,
                       decode(t.cnt,
                              t.rn,
                              decode(t.transfusion_type_desc,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T02'),
                                            NULL) || t.transfusion_type_desc),
                              decode(t.transfusion_type_desc,
                                     t.transfusion_type_desc_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T115') || '§' ||
                                                   decode(t.transfusion_type_desc, NULL, l_msg_del, t.transfusion_type_desc),
                                                   NULL) ||
                                            decode(t.transfusion_type_desc_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T02'),
                                                          NULL) || t.transfusion_type_desc_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T115') ||
                                            decode(t.transfusion_type_desc, NULL, l_msg_del, t.transfusion_type_desc) ||
                                            decode(t.transfusion_type_desc_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T02') ||
                                                   t.transfusion_type_desc_new)))) transfusion_type_desc,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.transfusion_type_desc,
                                     t.transfusion_type_desc_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.transfusion_type_desc)) transfusion_type_desc_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.quantity_ordered,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T03'),
                                            NULL) || t.quantity_ordered),
                              decode(t.quantity_ordered,
                                     t.quantity_ordered_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T116') || '§' ||
                                                   decode(t.quantity_ordered, NULL, l_msg_del, t.quantity_ordered),
                                                   NULL) ||
                                            decode(t.quantity_ordered_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T03'),
                                                          NULL) || t.quantity_ordered_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T116') ||
                                            decode(t.quantity_ordered, NULL, l_msg_del, t.quantity_ordered) ||
                                            decode(t.quantity_ordered_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T03') ||
                                                   t.quantity_ordered_new)))) quantity_ordered,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.quantity_ordered,
                                     t.quantity_ordered_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.quantity_ordered)) quantity_ordered_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.perform_location,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T13'),
                                            NULL) || t.perform_location),
                              decode(t.perform_location,
                                     t.perform_location_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T102') || '§' ||
                                                   decode(t.perform_location, NULL, l_msg_del, t.perform_location),
                                                   NULL) ||
                                            decode(t.perform_location_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T13'),
                                                          NULL) || t.perform_location_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T102') || '§' ||
                                            decode(t.perform_location, NULL, l_msg_del, t.perform_location) ||
                                            decode(t.perform_location_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T13') ||
                                                   t.perform_location_new)))) perform_location,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.perform_location,
                                     t.perform_location_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.perform_location)) perform_location_new,
                       decode(t.dt_req,
                              NULL,
                              NULL,
                              decode(t.cnt,
                                     t.rn,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T59'),
                                            NULL) || t.dt_req,
                                     NULL)) dt_req,
                       decode(t.cnt,
                              t.rn,
                              decode(t.special_instr,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T01'),
                                            NULL) || t.special_instr),
                              decode(t.special_instr,
                                     t.special_instr_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T117') || '§' ||
                                                   decode(t.special_instr, NULL, l_msg_del, t.special_instr),
                                                   NULL) ||
                                            decode(t.special_instr_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T01'),
                                                          NULL) || t.special_instr_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T117') ||
                                            decode(t.special_instr, NULL, l_msg_del, t.special_instr) ||
                                            decode(t.special_instr_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T01') ||
                                                   t.special_instr_new)))) special_instr,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.special_instr, t.special_instr_new, NULL, NULL, l_msg_del, t.special_instr)) special_instr_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.tech_notes,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T04'),
                                            NULL) || t.tech_notes),
                              decode(t.tech_notes,
                                     t.tech_notes_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T118') || '§' ||
                                                   decode(t.tech_notes, NULL, l_msg_del, t.tech_notes),
                                                   NULL) ||
                                            decode(t.tech_notes_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T04'),
                                                          NULL) || t.tech_notes_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T118') ||
                                            decode(t.tech_notes, NULL, l_msg_del, t.tech_notes) ||
                                            decode(t.tech_notes_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T04') ||
                                                   t.tech_notes_new)))) tech_notes,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.tech_notes, t.tech_notes_new, NULL, NULL, l_msg_del, t.tech_notes)) tech_notes_new,
                       t.notes,
                       t.co_sign,
                       decode(t.cnt,
                              t.rn,
                              decode(t.prof_order,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T08') || t.prof_order),
                              decode(t.prof_order,
                                     t.prof_order_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T106') || '§' ||
                                            decode(t.prof_order, NULL, l_msg_del, t.prof_order) ||
                                            decode(t.prof_order_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T08') ||
                                                   t.prof_order_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T106') ||
                                            decode(t.prof_order, NULL, l_msg_del, t.prof_order) ||
                                            decode(t.prof_order_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T08') ||
                                                   t.prof_order_new)))) prof_order,
                       decode(t.cnt,
                              t.rn,
                              decode(t.dt_order,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T59') || t.dt_order),
                              decode(t.dt_order,
                                     t.dt_order_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T107') || '§' ||
                                            decode(t.dt_order, NULL, l_msg_del, t.dt_order) ||
                                            decode(t.dt_order_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                                   t.dt_order_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T107') ||
                                            decode(t.dt_order, NULL, l_msg_del, t.dt_order) ||
                                            decode(t.dt_order_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                                   t.dt_order_new)))) dt_order,
                       decode(t.cnt,
                              t.rn,
                              decode(t.order_type,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T60') || t.order_type),
                              decode(t.order_type,
                                     t.order_type_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T108') || '§' ||
                                            decode(t.order_type, NULL, l_msg_del, t.order_type) ||
                                            decode(t.order_type_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T60') ||
                                                   t.order_type_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T108') ||
                                            decode(t.order_type, NULL, l_msg_del, t.order_type) ||
                                            decode(t.order_type_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T60') ||
                                                   t.order_type_new)))) order_type,
                       t.health_insurance,
                       decode(t.cnt,
                              t.rn,
                              decode(t.financial_entity,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T66') || t.financial_entity),
                              decode(t.financial_entity,
                                     t.financial_entity_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T109') || '§' ||
                                            decode(t.financial_entity, NULL, l_msg_del, t.financial_entity) ||
                                            decode(t.financial_entity_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T66') ||
                                                   t.financial_entity_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T109') ||
                                            decode(t.financial_entity, NULL, l_msg_del, t.financial_entity) ||
                                            decode(t.financial_entity_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T66') ||
                                                   t.financial_entity_new)))) financial_entity,
                       decode(t.cnt,
                              t.rn,
                              decode(t.health_plan,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T67') || t.health_plan),
                              decode(t.health_plan,
                                     t.health_plan_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T114') || '§' ||
                                            decode(t.health_plan, NULL, l_msg_del, t.health_plan) ||
                                            decode(t.health_plan_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T67') ||
                                                   t.health_plan_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T114') ||
                                            decode(t.health_plan, NULL, l_msg_del, t.health_plan) ||
                                            decode(t.health_plan_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T67') ||
                                                   t.health_plan_new)))) health_plan,
                       decode(t.cnt,
                              t.rn,
                              decode(t.insurance_number,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T68') || t.insurance_number),
                              decode(t.insurance_number,
                                     t.insurance_number_new,
                                     NULL,
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T120') || '§' ||
                                            decode(t.insurance_number, NULL, l_msg_del, t.insurance_number) ||
                                            decode(t.insurance_number_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T68') ||
                                                   t.insurance_number_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T120') ||
                                            decode(t.insurance_number, NULL, l_msg_del, t.insurance_number) ||
                                            decode(t.insurance_number_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || l_ident || aa_code_messages('BLOOD_PRODUCTS_T68') ||
                                                   t.insurance_number_new)))) insurance_number,
                       dt_blood_product_det_hist,
                       NULL transfusion,
                       NULL quantity_received,
                       NULL barcode,
                       NULL blood_group,
                       NULL blood_group_rh,
                       NULL expiration_date,
                       NULL prof_perform,
                       NULL start_time,
                       NULL end_time,
                       NULL qty_given,
                       NULL desc_perform,
                       NULL exec_notes,
                       NULL action_reason,
                       NULL action_notes,
                       NULL id_prof_match,
                       NULL dt_match_tstz,
                       t.dt_req_tstz,
                       t.dt_last_update_tstz,
                       t.dt_blood_product_det_h,
                       t.dt_last_update_h,
                       t.id_professional,
                       t.id_prof_last_update,
                       t.id_professional_h,
                       t.id_prof_last_update_h,
                       t.desc_compatibility,
                       t.notes_compatibility,
                       t.condition,
                       t.blood_group_desc,
                       CASE
                            WHEN t.rn = t.cnt THEN
                             get_bp_lab_mother_desc(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_episode           => i_episode,
                                                    i_blood_product_det => t.id_blood_product_det,
                                                    i_flg_html_det      => i_flg_html_det)
                        
                            ELSE
                             NULL
                        END lab_test_mother,
                       NULL donation_code,
                       NULL duration,
                       NULL result_1,
                       NULL dt_result_1,
                       NULL result_sig_1,
                       NULL result_2,
                       NULL dt_result_2,
                       NULL result_sig_2,
                       decode(t.cnt,
                              t.rn,
                              decode(t.req_statement_without_crossmatch,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T162'),
                                            NULL) || t.req_statement_without_crossmatch),
                              decode(t.req_prof_without_crossmatch,
                                     t.req_prof_without_crossmatch_new,
                                     t.req_statement_without_crossmatch, --Must be shown even if the user remains the same
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T163') || '§' ||
                                                   decode(t.req_statement_without_crossmatch,
                                                          NULL,
                                                          l_msg_del,
                                                          t.req_statement_without_crossmatch),
                                                   NULL) ||
                                            decode(t.req_statement_without_crossmatch_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T162'),
                                                          NULL) || t.req_statement_without_crossmatch_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T163') || '§' ||
                                            decode(t.req_statement_without_crossmatch,
                                                   NULL,
                                                   l_msg_del,
                                                   t.req_statement_without_crossmatch) ||
                                            decode(t.req_statement_without_crossmatch_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T162') ||
                                                   t.req_statement_without_crossmatch_new)))) req_statement_without_crossmatch,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.req_prof_without_crossmatch,
                                     t.req_prof_without_crossmatch_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.req_statement_without_crossmatch)) req_statement_without_crossmatch_new,
                       decode(t.cnt,
                              t.rn,
                              decode(t.req_prof_without_crossmatch,
                                     NULL,
                                     NULL,
                                     decode(i_flg_html_det,
                                            pk_alert_constant.g_no,
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T165'),
                                            NULL) || t.req_prof_without_crossmatch),
                              decode(t.req_prof_without_crossmatch,
                                     t.req_prof_without_crossmatch_new,
                                     t.req_prof_without_crossmatch_new, --Must be shown even if the user remains the same
                                     decode(i_flg_report,
                                            pk_alert_constant.g_no,
                                            decode(i_flg_html_det,
                                                   pk_alert_constant.g_no,
                                                   l_ident || aa_code_messages('BLOOD_PRODUCTS_T166') || '§' ||
                                                   decode(t.req_prof_without_crossmatch,
                                                          NULL,
                                                          l_msg_del,
                                                          t.req_prof_without_crossmatch),
                                                   NULL) ||
                                            decode(t.req_prof_without_crossmatch_new,
                                                   NULL,
                                                   NULL,
                                                   decode(i_flg_html_det,
                                                          pk_alert_constant.g_no,
                                                          l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T165'),
                                                          NULL) || t.req_prof_without_crossmatch_new),
                                            l_ident || aa_code_messages('BLOOD_PRODUCTS_T166') || '§' ||
                                            decode(t.req_prof_without_crossmatch,
                                                   NULL,
                                                   l_msg_del,
                                                   t.req_prof_without_crossmatch) ||
                                            decode(t.req_prof_without_crossmatch_new,
                                                   NULL,
                                                   NULL,
                                                   l_formated_text || aa_code_messages('BLOOD_PRODUCTS_T165') ||
                                                   t.req_prof_without_crossmatch_new)))) req_prof_without_crossmatch,
                       decode(i_flg_html_det,
                              pk_alert_constant.g_no,
                              NULL,
                              decode(t.req_prof_without_crossmatch,
                                     t.req_prof_without_crossmatch_new,
                                     NULL,
                                     NULL,
                                     l_msg_del,
                                     t.req_prof_without_crossmatch)) req_prof_without_crossmatch_new,
                       t.screening,
                       t.nat_test,
                       t.send_unit
                  FROM (SELECT row_number() over(ORDER BY bp.dt_blood_product_det_hist DESC NULLS FIRST) rn,
                               MAX(rownum) over() cnt,
                               bp.dt_blood_product_det_hist,
                               bp.id_blood_product_det,
                               -- bp.id_blood_product_execution,
                               bp.action,
                               bp.desc_action,
                               bp.exec_number,
                               bp.desc_hemo_type,
                               CASE
                                    WHEN bp.desc_diagnosis IS NOT NULL
                                         OR bp.clinical_purpose IS NOT NULL THEN
                                     bp.clinical_indication
                                    ELSE
                                     NULL
                                END clinical_indication,
                               bp.desc_diagnosis,
                               first_value(bp.desc_diagnosis) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) desc_diagnosis_new,
                               bp.clinical_purpose,
                               first_value(bp.clinical_purpose) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) clinical_purpose_new,
                               bp.instructions,
                               bp.priority,
                               first_value(bp.priority) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) priority_new,
                               bp.special_type special_type,
                               first_value(bp.special_type) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) special_type_new,
                               bp.desc_time,
                               first_value(bp.desc_time) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) desc_time_new,
                               bp.order_recurrence,
                               NULL execution,
                               bp.perform_location,
                               first_value(bp.perform_location) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) perform_location_new,
                               bp.dt_req,
                               bp.not_order_reason,
                               bp.notes,
                               bp.co_sign,
                               bp.prof_order,
                               --first_value(bp.prof_order) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) prof_order_new,
                               NULL prof_order_new,
                               bp.dt_order,
                               first_value(bp.dt_order) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_order_new,
                               bp.order_type,
                               first_value(bp.order_type) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) order_type_new,
                               bp.health_insurance,
                               bp.financial_entity,
                               first_value(bp.financial_entity) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) financial_entity_new,
                               bp.health_plan,
                               first_value(bp.health_plan) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) health_plan_new,
                               bp.insurance_number,
                               first_value(bp.insurance_number) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) insurance_number_new,
                               bp.exemption,
                               first_value(bp.exemption) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) exemption_new,
                               CASE
                                    WHEN bp.quantity_received IS NOT NULL
                                         OR bp.barcode IS NOT NULL
                                         OR bp.blood_group IS NOT NULL
                                         OR bp.blood_group_rh IS NOT NULL
                                         OR bp.expiration_date IS NOT NULL THEN
                                     bp.transfusion
                                    ELSE
                                     NULL
                                END transfusion,
                               bp.transfusion_type_desc,
                               first_value(bp.transfusion_type_desc) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) transfusion_type_desc_new,
                               bp.quantity_received,
                               bp.quantity_ordered,
                               first_value(bp.quantity_ordered) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) quantity_ordered_new,
                               bp.barcode,
                               bp.blood_group,
                               bp.blood_group_rh,
                               bp.expiration_date,
                               bp.special_instr,
                               first_value(bp.special_instr) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) special_instr_new,
                               bp.tech_notes,
                               first_value(bp.tech_notes) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) tech_notes_new,
                               bp.prof_perform,
                               bp.start_time,
                               bp.end_time,
                               bp.qty_given,
                               bp.desc_perform,
                               bp.exec_notes,
                               bp.action_reason,
                               bp.action_notes,
                               bp.id_prof_match,
                               bp.dt_match_tstz,
                               bp.dt_req_tstz,
                               bp.dt_last_update_tstz,
                               bp.dt_blood_product_det_h,
                               bp.dt_last_update_h,
                               bp.id_professional,
                               bp.id_prof_last_update,
                               bp.id_professional_h,
                               bp.id_prof_last_update_h,
                               bp.desc_compatibility,
                               bp.notes_compatibility,
                               bp.condition,
                               bp.blood_group_desc,
                               bp.req_statement_without_crossmatch,
                               first_value(bp.req_statement_without_crossmatch) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) req_statement_without_crossmatch_new,
                               bp.req_prof_without_crossmatch,
                               first_value(bp.req_prof_without_crossmatch) over(ORDER BY dt_blood_product_det_hist rows BETWEEN 1 preceding AND CURRENT ROW) req_prof_without_crossmatch_new,
                               bp.screening,
                               bp.nat_test,
                               bp.send_unit
                          FROM (SELECT /*+ opt_estimate(table cso rows=2) opt_estimate(table csc rows=2) */
                                 NULL dt_blood_product_det_hist,
                                 bpd.id_blood_product_det,
                                 --NULL id_blood_product_execution,
                                 'ORDER' action,
                                 CASE
                                      WHEN bpd.update_time IS NULL THEN
                                       aa_code_messages('BLOOD_PRODUCTS_T37')
                                      ELSE
                                       aa_code_messages('BLOOD_PRODUCTS_T37') || aa_code_messages('BLOOD_PRODUCTS_T119')
                                  END desc_action,
                                 NULL exec_number,
                                 (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                       i_prof,
                                                                                       bpd.id_blood_product_det,
                                                                                       pk_blood_products_constant.g_no)
                                    FROM dual) desc_hemo_type,
                                 aa_code_messages('BLOOD_PRODUCTS_T51') clinical_indication,
                                 decode(pk_diagnosis.concat_diag(i_lang,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_prof,
                                                                 NULL,
                                                                 NULL,
                                                                 bpd.id_blood_product_det),
                                        NULL,
                                        NULL,
                                        pk_diagnosis.concat_diag(i_lang,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_prof,
                                                                 NULL,
                                                                 NULL,
                                                                 bpd.id_blood_product_det)) desc_diagnosis,
                                 decode(bpd.id_clinical_purpose,
                                        NULL,
                                        NULL,
                                        decode(bpd.id_clinical_purpose,
                                               0,
                                               bpd.clinical_purpose_notes,
                                               pk_translation.get_translation(i_lang,
                                                                              'MULTICHOICE_OPTION.CODE_MULTICHOICE_OPTION.' ||
                                                                              bpd.id_clinical_purpose))) clinical_purpose,
                                 aa_code_messages('BLOOD_PRODUCTS_T54') instructions,
                                 decode(bpd.flg_priority,
                                        NULL,
                                        NULL,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'BLOOD_PRODUCT_DET.FLG_PRIORITY',
                                                                bpd.flg_priority,
                                                                NULL)) priority,
                                 decode(bpd.id_special_type,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           bpd.id_special_type)
                                           FROM dual)) special_type,
                                 pk_sysdomain.get_domain(i_lang,
                                                         i_prof,
                                                         'INTERV_PRESCRIPTION.FLG_TIME',
                                                         bpr.flg_time,
                                                         NULL) || ' (' ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             bpd.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) || ') ' desc_time,
                                 decode(bpd.id_order_recurrence,
                                        NULL,
                                        pk_message.get_message(i_lang, i_prof, 'ORDER_RECURRENCE_M004'),
                                        pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                              i_prof,
                                                                                              bpd.id_order_recurrence)) order_recurrence,
                                 aa_code_messages('BLOOD_PRODUCTS_T58') execution,
                                 decode(bpd.id_exec_institution,
                                        NULL,
                                        NULL,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'BLOOD_PRODUCT_DET.ID_EXEC_INSTITUTION',
                                                                bpd.id_exec_institution,
                                                                NULL)) perform_location,
                                 decode(cso.dt_ordered_by,
                                        NULL,
                                        decode(bpr.dt_req_tstz,
                                               NULL,
                                               NULL,
                                               pk_date_utils.date_char_tsz(i_lang,
                                                                           bpr.dt_req_tstz,
                                                                           i_prof.institution,
                                                                           i_prof.software)),
                                        NULL) dt_req,
                                 decode(pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpd.id_not_order_reason),
                                        NULL,
                                        NULL,
                                        pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpd.id_not_order_reason)) not_order_reason,
                                 decode(bpd.notes, NULL, NULL, bpd.notes) notes,
                                 decode(cso.id_order_type, NULL, NULL, aa_code_messages('BLOOD_PRODUCTS_T09')) co_sign,
                                 decode(cso.desc_prof_ordered_by, NULL, NULL, cso.desc_prof_ordered_by) prof_order,
                                 decode(cso.dt_ordered_by,
                                        NULL,
                                        NULL,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    cso.dt_ordered_by,
                                                                    i_prof.institution,
                                                                    i_prof.software)) dt_order,
                                 decode(cso.id_order_type, NULL, NULL, cso.desc_order_type) order_type,
                                 CASE
                                      WHEN bpd.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                       aa_code_messages('BLOOD_PRODUCTS_T61')
                                      ELSE
                                       NULL
                                  END cancellation,
                                 CASE
                                      WHEN bpd.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                       decode(bpd.flg_status,
                                              pk_blood_products_constant.g_status_req_i,
                                              l_ident || aa_code_messages('BLOOD_PRODUCTS_T62'),
                                              l_ident || aa_code_messages('BLOOD_PRODUCTS_T63')) ||
                                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, bpd.id_cancel_reason)
                                      ELSE
                                       NULL
                                  END cancel_reason,
                                 CASE
                                      WHEN bpd.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                       decode(bpd.notes_cancel,
                                              NULL,
                                              NULL,
                                              l_ident || aa_code_messages('BLOOD_PRODUCTS_T64') || bpd.notes_cancel)
                                      ELSE
                                       NULL
                                  END cancel_notes,
                                 decode(csc.desc_prof_ordered_by, NULL, NULL, csc.desc_prof_ordered_by) cancel_prof_order,
                                 decode(csc.dt_ordered_by,
                                        NULL,
                                        NULL,
                                        l_ident || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    csc.dt_ordered_by,
                                                                    i_prof.institution,
                                                                    i_prof.software)) cancel_dt_order,
                                 decode(csc.id_order_type,
                                        NULL,
                                        NULL,
                                        aa_code_messages('BLOOD_PRODUCTS_T60') || csc.desc_order_type) cancel_order_type,
                                 CASE
                                      WHEN l_health_insurance = pk_blood_products_constant.g_no THEN
                                       NULL
                                      ELSE
                                       CASE
                                           WHEN bpd.id_pat_health_plan IS NOT NULL
                                                OR bpd.id_pat_health_plan IS NOT NULL
                                                OR bpd.id_pat_health_plan IS NOT NULL THEN
                                            aa_code_messages('BLOOD_PRODUCTS_T65')
                                       END
                                  END health_insurance,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpd.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'F'))) financial_entity,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpd.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'H'))) health_plan,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpd.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpd.id_pat_health_plan, 'N'))) insurance_number,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpd.id_pat_exemption,
                                               NULL,
                                               NULL,
                                               l_ident || aa_code_messages('BLOOD_PRODUCTS_T69') ||
                                               pk_adt.get_pat_exemption_detail(i_lang, i_prof, bpd.id_pat_exemption))) exemption,
                                 NULL transfusion,
                                 decode(bpd.transfusion_type,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           to_number(bpd.transfusion_type))
                                           FROM dual)) transfusion_type_desc,
                                 decode(bpd.qty_exec,
                                        NULL,
                                        NULL,
                                        (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                             i_prof,
                                                                                             (SELECT MAX(bpd_qty.qty_exec)
                                                                                                FROM blood_product_det bpd_qty
                                                                                               WHERE bpd_qty.id_blood_product_req IN
                                                                                                     (SELECT bpd_i.id_blood_product_req
                                                                                                        FROM blood_product_det bpd_i
                                                                                                       WHERE bpd_i.id_blood_product_det =
                                                                                                             bpd.id_blood_product_det)), --bpd.qty_exec,
                                                                                             bpd.id_unit_mea_qty_exec)
                                           FROM dual)) quantity_ordered,
                                 NULL quantity_received,
                                 NULL barcode,
                                 NULL blood_group,
                                 NULL blood_group_rh,
                                 NULL expiration_date,
                                 decode(bpd.special_instr,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           to_number(bpd.special_instr))
                                           FROM dual)) special_instr,
                                 decode(bpd.notes_tech, NULL, NULL, bpd.notes_tech) tech_notes,
                                 NULL prof_perform,
                                 NULL start_time,
                                 NULL end_time,
                                 NULL qty_given,
                                 NULL desc_perform,
                                 NULL exec_notes,
                                 NULL action_reason,
                                 NULL action_notes,
                                 NULL id_prof_match,
                                 NULL dt_match_tstz,
                                 bpr.dt_req_tstz,
                                 bpd.dt_last_update_tstz,
                                 NULL dt_blood_product_det_h,
                                 NULL dt_last_update_h,
                                 bpr.id_professional,
                                 bpd.id_prof_last_update,
                                 NULL id_professional_h,
                                 NULL id_prof_last_update_h,
                                 NULL desc_compatibility,
                                 NULL notes_compatibility,
                                 NULL condition,
                                 NULL blood_group_desc,
                                 decode(bpd.id_prof_crossmatch,
                                        NULL,
                                        NULL,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               aa_code_messages('BLOOD_PRODUCTS_T165') || ' ',
                                               NULL) ||
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, bpd.id_prof_crossmatch) ||
                                        decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                i_prof,
                                                                                bpd.id_prof_crossmatch,
                                                                                coalesce(bpd.dt_last_update_tstz,
                                                                                         bpr.dt_req_tstz),
                                                                                bpr.id_episode),
                                               NULL,
                                               '; ',
                                               ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                        i_prof,
                                                                                        bpd.id_prof_crossmatch,
                                                                                        coalesce(bpd.dt_last_update_tstz,
                                                                                                 bpr.dt_req_tstz),
                                                                                        bpr.id_episode) || ')')) req_prof_without_crossmatch,
                                 decode(bpd.flg_req_without_crossmatch,
                                        pk_alert_constant.g_yes,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               aa_code_messages('BLOOD_PRODUCTS_T162'),
                                               NULL) || (SELECT pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T153')
                                                           FROM dual)) req_statement_without_crossmatch,
                                 decode(bpd.flg_with_screening,
                                        NULL,
                                        NULL,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               l_ident || aa_code_messages('BLOOD_PRODUCTS_T169'),
                                               NULL) ||
                                        pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_with_screening, NULL)) screening,
                                 decode(bpd.flg_without_nat_test,
                                        NULL,
                                        NULL,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               l_ident || aa_code_messages('BLOOD_PRODUCTS_T170'),
                                               NULL) ||
                                        pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_without_nat_test, NULL)) nat_test,
                                 decode(bpd.flg_prepare_not_send,
                                        NULL,
                                        NULL,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               l_ident || aa_code_messages('BLOOD_PRODUCTS_T171'),
                                               NULL) ||
                                        pk_sysdomain.get_domain(i_lang, i_prof, 'YES_NO', bpd.flg_prepare_not_send, NULL)) send_unit
                                  FROM blood_product_det bpd
                                 INNER JOIN blood_product_req bpr
                                    ON bpr.id_blood_product_req = bpd.id_blood_product_req
                                  LEFT JOIN cso_table cso
                                    ON cso.id_co_sign = bpd.id_co_sign_order
                                  LEFT JOIN cso_table csc
                                    ON csc.id_co_sign_hist = bpd.id_co_sign_cancel
                                 WHERE bpd.id_blood_product_det = i_blood_product_det
                                UNION ALL
                                SELECT /*+ opt_estimate(table cso rows=2) opt_estimate(table csc rows=2) */
                                 bpdh.dt_blood_product_det_hist,
                                 bpdh.id_blood_product_det,
                                 -- NULL id_blood_product_execution,
                                 'ORDER' action,
                                 CASE
                                     WHEN MAX(rownum) over() != rownum THEN
                                      aa_code_messages('BLOOD_PRODUCTS_T37') || aa_code_messages('BLOOD_PRODUCTS_T119')
                                     ELSE
                                      aa_code_messages('BLOOD_PRODUCTS_T37')
                                 END desc_action,
                                 NULL exec_number,
                                 (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                       i_prof,
                                                                                       bpd.id_blood_product_det,
                                                                                       pk_blood_products_constant.g_no)
                                    FROM dual) desc_hemo_type,
                                 aa_code_messages('BLOOD_PRODUCTS_T51') clinical_indication,
                                 decode(pk_blood_products_utils.get_bp_diagnosis(i_lang, i_prof, bpdh.id_diagnosis_list),
                                        NULL,
                                        NULL,
                                        pk_blood_products_utils.get_bp_diagnosis(i_lang, i_prof, bpdh.id_diagnosis_list)) desc_diagnosis,
                                 decode(bpdh.id_clinical_purpose,
                                        NULL,
                                        NULL,
                                        decode(bpdh.id_clinical_purpose,
                                               0,
                                               bpdh.clinical_purpose_notes,
                                               pk_translation.get_translation(i_lang,
                                                                              'MULTICHOICE_OPTION.CODE_MULTICHOICE_OPTION.' ||
                                                                              bpdh.id_clinical_purpose))) clinical_purpose,
                                 aa_code_messages('BLOOD_PRODUCTS_T54') instructions,
                                 decode(bpdh.flg_priority,
                                        NULL,
                                        NULL,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'BLOOD_PRODUCT_DET.FLG_PRIORITY',
                                                                bpdh.flg_priority,
                                                                NULL)) priority,
                                 decode(bpdh.id_special_type,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           bpdh.id_special_type)
                                           FROM dual)) special_type,
                                 pk_sysdomain.get_domain(i_lang,
                                                         i_prof,
                                                         'INTERV_PRESCRIPTION.FLG_TIME',
                                                         bpr.flg_time,
                                                         NULL) || ' (' ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             bpdh.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) || ') ' desc_time,
                                 decode(bpdh.id_order_recurrence,
                                        NULL,
                                        pk_message.get_message(i_lang, i_prof, 'ORDER_RECURRENCE_M004'),
                                        pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang,
                                                                                              i_prof,
                                                                                              bpdh.id_order_recurrence)) order_recurrence,
                                 aa_code_messages('BLOOD_PRODUCTS_T58') execution,
                                 decode(bpdh.id_exec_institution,
                                        NULL,
                                        NULL,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'BLOOD_PRODUCT_DET.ID_EXEC_INSTITUTION',
                                                                bpdh.id_exec_institution,
                                                                NULL)) perform_location,
                                 decode(cso.dt_ordered_by,
                                        NULL,
                                        decode(bpr.dt_req_tstz,
                                               NULL,
                                               NULL,
                                               pk_date_utils.date_char_tsz(i_lang,
                                                                           bpr.dt_req_tstz,
                                                                           i_prof.institution,
                                                                           i_prof.software)),
                                        NULL) dt_req,
                                 decode(pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpdh.id_not_order_reason),
                                        NULL,
                                        NULL,
                                        l_ident || aa_code_messages('BLOOD_PRODUCTS_T05') ||
                                        pk_not_order_reason_db.get_not_order_reason_desc(i_lang, bpdh.id_not_order_reason)) not_order_reason,
                                 decode(bpdh.notes,
                                        NULL,
                                        NULL,
                                        l_ident || aa_code_messages('BLOOD_PRODUCTS_T43') || bpdh.notes) notes,
                                 decode(cso.id_order_type, NULL, NULL, aa_code_messages('BLOOD_PRODUCTS_T09')) co_sign,
                                 decode(cso.desc_prof_ordered_by, NULL, NULL, cso.desc_prof_ordered_by) prof_order,
                                 decode(cso.dt_ordered_by,
                                        NULL,
                                        NULL,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    cso.dt_ordered_by,
                                                                    i_prof.institution,
                                                                    i_prof.software)) dt_order,
                                 decode(cso.id_order_type, NULL, NULL, cso.desc_order_type) order_type,
                                 CASE
                                     WHEN bpdh.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                      aa_code_messages('BLOOD_PRODUCTS_T61')
                                     ELSE
                                      NULL
                                 END cancellation,
                                 CASE
                                     WHEN bpdh.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                      decode(bpd.flg_status,
                                             pk_blood_products_constant.g_status_req_i,
                                             l_ident || aa_code_messages('BLOOD_PRODUCTS_T62'),
                                             l_ident || aa_code_messages('BLOOD_PRODUCTS_T63')) ||
                                      pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, bpdh.id_cancel_reason)
                                     ELSE
                                      NULL
                                 END cancel_reason,
                                 CASE
                                     WHEN bpdh.flg_status IN (pk_blood_products_constant.g_status_det_c,
                                                              pk_blood_products_constant.g_status_det_d) THEN
                                      decode(bpd.notes_cancel,
                                             NULL,
                                             NULL,
                                             l_ident || aa_code_messages('BLOOD_PRODUCTS_T64') || bpdh.notes_cancel)
                                     ELSE
                                      NULL
                                 END cancel_notes,
                                 decode(csc.desc_prof_ordered_by,
                                        NULL,
                                        NULL,
                                        l_ident || aa_code_messages('BLOOD_PRODUCTS_T08') || csc.desc_prof_ordered_by) cancel_prof_order,
                                 decode(csc.dt_ordered_by,
                                        NULL,
                                        NULL,
                                        l_ident || aa_code_messages('BLOOD_PRODUCTS_T59') ||
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    csc.dt_ordered_by,
                                                                    i_prof.institution,
                                                                    i_prof.software)) cancel_dt_order,
                                 decode(csc.id_order_type,
                                        NULL,
                                        NULL,
                                        aa_code_messages('BLOOD_PRODUCTS_T60') || csc.desc_order_type) cancel_order_type,
                                 CASE
                                     WHEN l_health_insurance = pk_blood_products_constant.g_no THEN
                                      NULL
                                     ELSE
                                      CASE
                                          WHEN bpdh.id_pat_health_plan IS NOT NULL
                                               OR bpdh.id_pat_health_plan IS NOT NULL
                                               OR bpdh.id_pat_health_plan IS NOT NULL THEN
                                           aa_code_messages('BLOOD_PRODUCTS_T65')
                                      END
                                 END health_insurance,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpdh.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpdh.id_pat_health_plan, 'F'))) financial_entity,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpdh.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpdh.id_pat_health_plan, 'H'))) health_plan,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpdh.id_pat_health_plan,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_health_plan_info(i_lang, i_prof, bpdh.id_pat_health_plan, 'N'))) insurance_number,
                                 decode(l_health_insurance,
                                        pk_blood_products_constant.g_no,
                                        NULL,
                                        decode(bpdh.id_pat_exemption,
                                               NULL,
                                               NULL,
                                               pk_adt.get_pat_exemption_detail(i_lang, i_prof, bpdh.id_pat_exemption))) exemption,
                                 NULL transfusion,
                                 decode(bpdh.transfusion_type,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           to_number(bpdh.transfusion_type))
                                           FROM dual)) transfusion_type_desc,
                                 decode(bpdh.qty_exec,
                                        NULL,
                                        NULL,
                                        (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                             i_prof,
                                                                                             bpdh.qty_exec,
                                                                                             bpdh.id_unit_mea_qty_exec)
                                           FROM dual)) quantity_ordered,
                                 NULL quantity_received,
                                 NULL barcode,
                                 NULL blood_group,
                                 NULL blood_group_rh,
                                 NULL expiration_date,
                                 decode(bpdh.special_instr,
                                        NULL,
                                        NULL,
                                        (SELECT pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                           i_prof,
                                                                                           to_number(bpdh.special_instr))
                                           FROM dual)) special_instr,
                                 decode(bpdh.notes_tech, NULL, NULL, bpdh.notes_tech) tech_notes,
                                 NULL prof_perform,
                                 NULL start_time,
                                 NULL end_time,
                                 NULL qty_given,
                                 NULL desc_perform,
                                 NULL exec_notes,
                                 NULL action_reason,
                                 NULL action_notes,
                                 NULL id_prof_match,
                                 NULL dt_match_tstz,
                                 NULL dt_req_tstz,
                                 NULL dt_last_update_tstz,
                                 bpdh.dt_blood_product_det_hist dt_blood_product_det_h,
                                 bpdh.dt_last_update_tstz dt_last_update_h,
                                 NULL id_professional,
                                 NULL id_prof_last_update,
                                 bpdh.id_professional id_professional_h,
                                 bpdh.id_prof_last_update id_prof_last_update_h,
                                 NULL desc_compatibility,
                                 NULL notes_compatibility,
                                 NULL condition,
                                 NULL blood_group_desc,
                                 decode(bpdh.id_prof_crossmatch,
                                        NULL,
                                        NULL,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               aa_code_messages('BLOOD_PRODUCTS_T165') || ' ',
                                               NULL) ||
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, bpdh.id_prof_crossmatch) ||
                                        decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                i_prof,
                                                                                bpdh.id_prof_crossmatch,
                                                                                coalesce(bpdh.dt_last_update_tstz,
                                                                                         bpr.dt_req_tstz),
                                                                                bpr.id_episode),
                                               NULL,
                                               '; ',
                                               ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                        i_prof,
                                                                                        bpdh.id_prof_crossmatch,
                                                                                        coalesce(bpdh.dt_last_update_tstz,
                                                                                                 bpr.dt_req_tstz),
                                                                                        bpr.id_episode) || ')')) req_prof_without_crossmatch,
                                 decode(bpdh.flg_req_without_crossmatch,
                                        pk_alert_constant.g_yes,
                                        decode(i_flg_html_det,
                                               pk_alert_constant.g_no,
                                               aa_code_messages('BLOOD_PRODUCTS_T162'),
                                               NULL) || (SELECT pk_message.get_message(i_lang, 'BLOOD_PRODUCTS_T153')
                                                           FROM dual)) req_statement_without_crossmatch,
                                 NULL screening,
                                 NULL nat_test,
                                 NULL send_unit
                                  FROM blood_product_det_hist bpdh
                                 INNER JOIN blood_product_det bpd
                                    ON bpd.id_blood_product_det = bpdh.id_blood_product_det
                                 INNER JOIN blood_product_req bpr
                                    ON bpr.id_blood_product_req = bpdh.id_blood_product_req
                                  LEFT JOIN cso_table cso
                                    ON cso.id_co_sign = bpdh.id_co_sign_order
                                  LEFT JOIN cso_table csc
                                    ON csc.id_co_sign_hist = bpdh.id_co_sign_cancel
                                 WHERE bpdh.id_blood_product_det = i_blood_product_det) bp) t
                UNION ALL
                SELECT bp_comp.rn,
                       bp_comp.cnt,
                       --bp_comp.id_blood_product_det,
                       -- bp_other.id_blood_product_execution,
                       bp_comp.action,
                       bp_comp.desc_action,
                       decode(bp_comp.rn, bp_comp.cnt, bp_comp.exec_number, bp_comp.exec_number + 1) exec_number,
                       bp_comp.desc_hemo_type,
                       bp_comp.clinical_indication,
                       bp_comp.desc_diagnosis,
                       bp_comp.desc_diagnosis_new,
                       bp_comp.clinical_purpose,
                       bp_comp.clinical_purpose_new,
                       bp_comp.instructions,
                       bp_comp.priority,
                       NULL priority_new,
                       bp_comp.special_type,
                       NULL special_type_new,
                       bp_comp.desc_time,
                       NULL desc_time_new,
                       bp_comp.order_recurrence,
                       bp_comp.execution,
                       bp_comp.transfusion_type_desc,
                       NULL transfusion_type_desc_new,
                       bp_comp.quantity_ordered,
                       NULL quantity_ordered_new,
                       bp_comp.perform_location,
                       NULL perform_location_new,
                       bp_comp.dt_req,
                       bp_comp.special_instr,
                       NULL special_instr_new,
                       bp_comp.tech_notes,
                       NULL tech_notes_new,
                       bp_comp.notes,
                       bp_comp.co_sign,
                       bp_comp.prof_order,
                       bp_comp.dt_order,
                       bp_comp.order_type,
                       bp_comp.health_insurance,
                       bp_comp.financial_entity,
                       bp_comp.health_plan,
                       bp_comp.insurance_number,
                       bp_comp.dt_blood_product_det_hist,
                       bp_comp.transfusion,
                       bp_comp.quantity_received,
                       bp_comp.barcode,
                       bp_comp.blood_group,
                       bp_comp.blood_group_rh,
                       bp_comp.expiration_date,
                       bp_comp.prof_perform,
                       bp_comp.start_time,
                       bp_comp.end_time,
                       bp_comp.qty_given,
                       bp_comp.desc_perform,
                       bp_comp.exec_notes,
                       bp_comp.action_reason,
                       bp_comp.action_notes,
                       bp_comp.id_prof_match,
                       bp_comp.dt_match_tstz,
                       bp_comp.dt_req_tstz,
                       bp_comp.dt_last_update_tstz,
                       bp_comp.dt_blood_product_det_h,
                       bp_comp.dt_last_update_h,
                       bp_comp.id_professional,
                       bp_comp.id_prof_last_update,
                       bp_comp.id_professional_h,
                       bp_comp.id_prof_last_update_h,
                       decode(bp_comp.rn,
                              bp_comp.cnt,
                              decode(bp_comp.desc_compatibility,
                                     NULL,
                                     NULL,
                                     aa_code_messages('BLOOD_PRODUCTS_T128') ||
                                     pk_sysdomain.get_domain(i_lang,
                                                             i_prof,
                                                             'BLOOD_PRODUCT_EXECUTION.FLG_COMPATIBILITY',
                                                             bp_comp.desc_compatibility,
                                                             NULL)),
                              decode(bp_comp.desc_compatibility,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T130') || '§' ||
                                     pk_sysdomain.get_domain(i_lang,
                                                             i_prof,
                                                             'BLOOD_PRODUCT_EXECUTION.FLG_COMPATIBILITY',
                                                             bp_comp.desc_compatibility,
                                                             NULL)
                                     
                                     )) desc_compatibility,
                       decode(bp_comp.rn,
                              bp_comp.cnt,
                              decode(bp_comp.notes_compatibility,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T127') || bp_comp.notes_compatibility),
                              decode(bp_comp.notes_compatibility,
                                     NULL,
                                     NULL,
                                     l_ident || aa_code_messages('BLOOD_PRODUCTS_T131') || '§' ||
                                     bp_comp.notes_compatibility)) notes_compatibility,
                       bp_comp.condition,
                       bp_comp.blood_group_desc,
                       NULL lab_test_mother,
                       bp_comp.donation_code,
                       bp_comp.duration,
                       bp_comp.result_1,
                       bp_comp.dt_result_1,
                       bp_comp.result_sig_1,
                       bp_comp.result_2,
                       bp_comp.dt_result_2,
                       bp_comp.result_sig_2,
                       NULL req_statement_without_crossmatch,
                       NULL req_statement_without_crossmatch_new,
                       NULL req_prof_without_crossmatch,
                       NULL req_prof_without_crossmatch_new,
                       NULL screening,
                       NULL nat_test,
                       NULL send_unit
                  FROM (SELECT row_number() over(ORDER BY bp_other.id_blood_product_execution DESC NULLS FIRST) rn,
                               MAX(rownum) over() cnt,
                               --id_blood_product_det,
                               -- bp_other.id_blood_product_execution,
                               bp_other.action,
                               bp_other.desc_action,
                               bp_other.exec_number,
                               bp_other.desc_hemo_type,
                               NULL clinical_indication,
                               NULL desc_diagnosis,
                               NULL desc_diagnosis_new,
                               NULL clinical_purpose,
                               NULL clinical_purpose_new,
                               NULL instructions,
                               NULL priority,
                               NULL special_type,
                               NULL desc_time,
                               NULL order_recurrence,
                               NULL execution,
                               bp_other.transfusion_type_desc,
                               NULL quantity_ordered,
                               NULL perform_location,
                               NULL dt_req,
                               NULL special_instr,
                               NULL tech_notes,
                               bp_other.notes,
                               NULL co_sign,
                               NULL prof_order,
                               NULL dt_order,
                               NULL order_type,
                               NULL health_insurance,
                               NULL financial_entity,
                               NULL health_plan,
                               NULL insurance_number,
                               NULL dt_blood_product_det_hist,
                               CASE
                                    WHEN bp_other.quantity_received IS NOT NULL
                                         OR bp_other.barcode IS NOT NULL
                                         OR bp_other.blood_group IS NOT NULL
                                         OR bp_other.blood_group_rh IS NOT NULL
                                         OR bp_other.expiration_date IS NOT NULL THEN
                                     bp_other.transfusion
                                    ELSE
                                     NULL
                                END transfusion,
                               bp_other.quantity_received,
                               bp_other.barcode,
                               bp_other.blood_group,
                               bp_other.blood_group_rh,
                               bp_other.expiration_date,
                               bp_other.prof_perform,
                               bp_other.start_time,
                               bp_other.end_time,
                               bp_other.qty_given,
                               bp_other.desc_perform,
                               bp_other.exec_notes,
                               bp_other.action_reason,
                               bp_other.action_notes,
                               bp_other.id_prof_match,
                               bp_other.dt_match_tstz,
                               bp_other.dt_bp_execution_tstz dt_req_tstz,
                               NULL dt_last_update_tstz,
                               NULL dt_blood_product_det_h,
                               NULL dt_last_update_h,
                               bp_other.id_professional,
                               NULL id_prof_last_update,
                               NULL id_professional_h,
                               NULL id_prof_last_update_h,
                               bp_other.desc_compatibility,
                               bp_other.notes_compatibility,
                               bp_other.condition,
                               bp_other.blood_group_desc,
                               bp_other.donation_code,
                               bp_other.duration,
                               bp_other.result_1,
                               bp_other.dt_result_1,
                               bp_other.result_sig_1,
                               bp_other.result_2,
                               bp_other.dt_result_2,
                               bp_other.result_sig_2
                          FROM (SELECT t.*
                                  FROM TABLE(l_tbl_bp_hist_info_core) t) bp_other) bp_comp) b
         WHERE action IS NULL
            OR action != pk_blood_products_constant.g_bp_action_lab_collected
         ORDER BY exec_number DESC NULLS LAST, rn ASC;
    
        RETURN l_tbl_bp_hist_info;
    
    END tf_get_bp_detail_history;

    FUNCTION tf_get_bp_detail_history_core
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_aa_code_messages  IN t_code_messages,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail_hist_core IS
    
        l_tbl_bp_info t_tbl_bp_task_detail_hist_core := t_tbl_bp_task_detail_hist_core();
    
        --DOCUMENTED
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M107');
    
        l_notes CLOB;
    
        l_tbl_bp_notes t_tbl_blood_product_notes := t_tbl_blood_product_notes();
    
        l_cur_bp_doc_val pk_touch_option_out.t_cur_plain_text_entry;
        l_bp_doc_val     pk_touch_option_out.t_rec_plain_text_entry;
    
        l_count NUMBER(12) := 0;
    
        l_blood_group_desc VARCHAR2(4000);
    
        l_result_1     VARCHAR2(200);
        l_dt_result_1  VARCHAR2(200);
        l_result_sig_1 VARCHAR2(200);
    
        l_result_2     VARCHAR2(200);
        l_dt_result_2  VARCHAR2(200);
        l_result_sig_2 VARCHAR2(200);
    
        l_error t_error_out;
    
    BEGIN
        --Obtain templates
        SELECT COUNT(1)
          INTO l_count
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det
           AND bpe.id_epis_documentation IS NOT NULL;
    
        IF (l_count) > 0
        THEN
        
            SELECT t_blood_product_notes(t.id_blood_product_det,
                                         t.id_blood_product_execution,
                                         t.id_epis_documentation,
                                         NULL)
              BULK COLLECT
              INTO l_tbl_bp_notes
              FROM (SELECT bpe.id_blood_product_det, bpe.id_blood_product_execution, bpe.id_epis_documentation
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = i_blood_product_det
                       AND bpe.id_epis_documentation IS NOT NULL) t;
        
            g_error := 'CALL PK_TOUCH_OPTION_OUT.GET_PLAIN_TEXT_ENTRIES';
            FOR i IN l_tbl_bp_notes.first .. l_tbl_bp_notes.last
            LOOP
            
                pk_touch_option_out.get_plain_text_entries(i_lang                    => i_lang,
                                                           i_prof                    => i_prof,
                                                           i_epis_documentation_list => table_number(l_tbl_bp_notes(i).l_id_epis_documentation),
                                                           i_use_html_format         => CASE
                                                                                            WHEN i_flg_html_det = pk_alert_constant.g_no THEN
                                                                                             pk_blood_products_constant.g_yes
                                                                                            ELSE
                                                                                             pk_blood_products_constant.g_no
                                                                                        END,
                                                           o_entries                 => l_cur_bp_doc_val);
            
                FETCH l_cur_bp_doc_val
                    INTO l_bp_doc_val;
                CLOSE l_cur_bp_doc_val;
            
                l_notes := NULL;
                l_notes := REPLACE(l_bp_doc_val.plain_text_entry, chr(10));
                l_notes := REPLACE(l_notes, chr(10), chr(10) || chr(9));
            
                IF i_flg_report = pk_blood_products_constant.g_no
                THEN
                    l_notes := REPLACE(l_notes, '.<b>', '.<br><b>');
                END IF;
            
                IF i_flg_html_det = pk_alert_constant.g_yes
                THEN
                    l_notes := REPLACE(l_notes, substr(l_notes, 1, instr(l_notes, ': ') + 1), '');
                END IF;
            
                l_tbl_bp_notes(i).l_notes := l_notes;
            END LOOP;
        END IF;
    
        g_error := 'GET BLOOD GROUP INFORMATION';
        IF i_flg_html_det = pk_alert_constant.g_no
        THEN
            l_blood_group_desc := get_bp_blood_group_desc(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_episode           => i_episode,
                                                          i_blood_product_det => i_blood_product_det,
                                                          i_flg_report        => i_flg_report);
        ELSE
            IF NOT get_bp_blood_group_desc(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_episode           => i_episode,
                                           i_blood_product_det => i_blood_product_det,
                                           o_blood_group_desc  => l_blood_group_desc,
                                           o_result_1          => l_result_1,
                                           o_dt_result_1       => l_dt_result_1,
                                           o_result_sig_1      => l_result_sig_1,
                                           o_result_2          => l_result_2,
                                           o_dt_result_2       => l_dt_result_2,
                                           o_result_sig_2      => l_result_sig_2)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        SELECT t_bp_task_detail_hist_core(dt_blood_product_det_hist  => t.dt_blood_product_det_hist,
                                          id_blood_product_execution => t.id_blood_product_execution,
                                          action                     => t.action,
                                          desc_action                => t.desc_action,
                                          exec_number                => t.exec_number,
                                          desc_hemo_type             => t.desc_hemo_type,
                                          clinical_indication        => t.clinical_indication,
                                          desc_diagnosis             => t.desc_diagnosis,
                                          clinical_purpose           => t.clinical_purpose,
                                          instructions               => t.instructions,
                                          priority                   => t.priority,
                                          special_type               => t.special_type,
                                          desc_time                  => t.desc_time,
                                          order_recurrence           => t.order_recurrence,
                                          execution                  => t.execution,
                                          perform_location           => t.perform_location,
                                          dt_req                     => t.dt_req,
                                          not_order_reason           => t.not_order_reason,
                                          notes                      => t.notes,
                                          co_sign                    => t.co_sign,
                                          prof_order                 => t.prof_order,
                                          dt_order                   => t.dt_order,
                                          order_type                 => t.order_type,
                                          cancellation               => t.cancellation,
                                          cancel_reason              => t.cancel_reason,
                                          cancel_notes               => t.cancel_notes,
                                          cancel_prof_order          => t.cancel_prof_order,
                                          cancel_dt_order            => t.cancel_dt_order,
                                          cancel_order_type          => t.cancel_order_type,
                                          health_insurance           => t.health_insurance,
                                          financial_entity           => t.financial_entity,
                                          health_plan                => t.health_plan,
                                          insurance_number           => t.insurance_number,
                                          exemption                  => t.exemption,
                                          transfusion                => t.transfusion,
                                          transfusion_type_desc      => t.transfusion_type_desc,
                                          quantity_received          => t.quantity_received,
                                          barcode                    => t.barcode,
                                          blood_group                => t.blood_group,
                                          blood_group_rh             => t.blood_group_rh,
                                          expiration_date            => t.expiration_date,
                                          special_instr              => t.special_instr,
                                          tech_notes                 => t.tech_notes,
                                          prof_perform               => t.prof_perform,
                                          start_time                 => t.start_time,
                                          end_time                   => t.end_time,
                                          qty_given                  => t.qty_given,
                                          desc_perform               => t.desc_perform,
                                          exec_notes                 => t.exec_notes,
                                          action_reason              => t.action_reason,
                                          action_notes               => t.action_notes,
                                          id_prof_match              => t.id_prof_match,
                                          dt_match_tstz              => t.dt_match_tstz,
                                          id_professional            => t.id_professional,
                                          dt_bp_execution_tstz       => t.dt_bp_execution_tstz,
                                          desc_compatibility         => t.desc_compatibility,
                                          notes_compatibility        => t.notes_compatibility,
                                          condition                  => t.condition,
                                          blood_group_desc           => t.blood_group_desc,
                                          donation_code              => t.donation_code,
                                          duration                   => t.duration,
                                          result_1                   => t.result_1,
                                          dt_result_1                => t.dt_result_1,
                                          result_sig_1               => t.result_sig_1,
                                          result_2                   => t.result_2,
                                          dt_result_2                => t.dt_result_2,
                                          result_sig_2               => t.result_sig_2)
          BULK COLLECT
          INTO l_tbl_bp_info
          FROM (SELECT NULL dt_blood_product_det_hist,
                       --bpd.id_blood_product_det,
                       bpe.id_blood_product_execution,
                       decode(bpe.action,
                              pk_blood_products_constant.g_bp_action_compability,
                              pk_blood_products_constant.g_bp_action_lab_service,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     bpe.action,
                                     decode(bpe.action,
                                            pk_blood_products_constant.g_bp_action_cancel,
                                            decode(bpd.qty_given,
                                                   NULL,
                                                   pk_blood_products_constant.g_bp_action_cancel,
                                                   pk_blood_products_constant.g_bp_action_discontinue),
                                            bpe.action))) action,
                       decode(bpe.action,
                              pk_blood_products_constant.g_bp_action_administer,
                              i_aa_code_messages('BLOOD_PRODUCTS_T58'),
                              pk_blood_products_constant.g_bp_action_hold,
                              i_aa_code_messages('BLOOD_PRODUCTS_T80'),
                              pk_blood_products_constant.g_bp_action_resume,
                              i_aa_code_messages('BLOOD_PRODUCTS_T81'),
                              pk_blood_products_constant.g_bp_action_report,
                              i_aa_code_messages('BLOOD_PRODUCTS_T73'),
                              pk_blood_products_constant.g_bp_action_reevaluate,
                              i_aa_code_messages('BLOOD_PRODUCTS_T74'),
                              pk_blood_products_constant.g_bp_action_conclude,
                              i_aa_code_messages('BLOOD_PRODUCTS_T82'),
                              pk_blood_products_constant.g_bp_action_return,
                              i_aa_code_messages('BLOOD_PRODUCTS_T83'),
                              pk_blood_products_constant.g_bp_action_cancel,
                              decode(bpd.qty_given,
                                     NULL,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T84'),
                                     i_aa_code_messages('BLOOD_PRODUCTS_T152')),
                              pk_blood_products_constant.g_bp_action_begin_transp,
                              i_aa_code_messages('BLOOD_PRODUCTS_T90'),
                              pk_blood_products_constant.g_bp_action_end_transp,
                              i_aa_code_messages('BLOOD_PRODUCTS_T91'),
                              pk_blood_products_constant.g_bp_action_lab_service,
                              i_aa_code_messages('BLOOD_PRODUCTS_T77'),
                              pk_blood_products_constant.g_bp_action_compability,
                              i_aa_code_messages('BLOOD_PRODUCTS_T77'),
                              pk_blood_products_constant.g_bp_action_begin_return,
                              i_aa_code_messages('BLOOD_PRODUCTS_T150'),
                              pk_blood_products_constant.g_bp_action_end_return,
                              i_aa_code_messages('BLOOD_PRODUCTS_T151'),
                              'CONFIRM_TRANSFUSION',
                              i_aa_code_messages('BLOOD_PRODUCTS_T172'),
                              NULL) desc_action,
                       (bpe.exec_number * 10) exec_number, --multiplier used in order to allow for the blood group info to be inserted after transport end
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(i_flg_html_det, pk_alert_constant.g_no, i_aa_code_messages('BLOOD_PRODUCTS_T20'), NULL) ||
                             (SELECT pk_blood_products_utils.get_bp_desc_hemo_type(i_lang,
                                                                                   i_prof,
                                                                                   bpd.id_blood_product_det,
                                                                                   pk_blood_products_constant.g_yes)
                                FROM dual)
                            ELSE
                             NULL
                        END desc_hemo_type,
                       NULL clinical_indication,
                       NULL desc_diagnosis,
                       NULL clinical_purpose,
                       NULL instructions,
                       NULL priority,
                       NULL special_type,
                       NULL desc_time,
                       NULL order_recurrence,
                       NULL execution,
                       NULL perform_location,
                       NULL dt_req,
                       NULL not_order_reason,
                       CASE
                            WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                pk_blood_products_constant.g_bp_action_end_transp,
                                                pk_blood_products_constant.g_bp_action_administer,
                                                pk_blood_products_constant.g_bp_action_begin_return,
                                                pk_blood_products_constant.g_bp_action_end_return)
                                 AND i_flg_html_det = pk_alert_constant.g_yes THEN
                             pk_blood_products_core.get_bp_condition_detail(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_blood_product_det => bpe.id_blood_product_det,
                                                                            i_exec_number       => bpe.exec_number - 1,
                                                                            i_flg_report        => i_flg_report,
                                                                            i_flg_html          => i_flg_html_det,
                                                                            i_flg_html_mode     => CASE
                                                                                                       WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                                        pk_blood_products_constant.g_bp_condition_notes
                                                                                                       ELSE
                                                                                                        NULL
                                                                                                   END)
                            ELSE
                             NULL
                        END notes,
                       NULL co_sign,
                       NULL prof_order,
                       NULL dt_order,
                       NULL order_type,
                       NULL cancellation,
                       NULL cancel_reason,
                       NULL cancel_notes,
                       NULL cancel_prof_order,
                       NULL cancel_dt_order,
                       NULL cancel_order_type,
                       NULL health_insurance,
                       NULL financial_entity,
                       NULL health_plan,
                       NULL insurance_number,
                       NULL exemption,
                       NULL transfusion,
                       NULL transfusion_type_desc,
                       NULL quantity_ordered,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.qty_received,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T32'),
                                           NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                         i_prof,
                                                                                                         bpd.qty_received,
                                                                                                         bpd.id_unit_mea_qty_received)
                                                       FROM dual))
                            ELSE
                             NULL
                        END quantity_received,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.barcode_lab,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T24'),
                                           NULL) || bpd.barcode_lab)
                            ELSE
                             NULL
                        END barcode,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.blood_group,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T30'),
                                           NULL) || bpd.blood_group)
                            ELSE
                             NULL
                        END blood_group,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.blood_group_rh,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T86'),
                                           NULL) || pk_sysdomain.get_domain(i_lang,
                                                                            i_prof,
                                                                            'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS',
                                                                            bpd.blood_group_rh,
                                                                            NULL))
                            ELSE
                             NULL
                        END blood_group_rh,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.expiration_date,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T25'),
                                           NULL) || pk_date_utils.date_char_tsz(i_lang,
                                                                                bpd.expiration_date,
                                                                                i_prof.institution,
                                                                                i_prof.software))
                            ELSE
                             NULL
                        END expiration_date,
                       NULL special_instr,
                       NULL tech_notes,
                       CASE
                            WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_administer,
                                                pk_blood_products_constant.g_bp_action_reevaluate,
                                                pk_blood_products_constant.g_bp_action_conclude) THEN
                             decode(bpe.id_prof_performed,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T39'),
                                           NULL) || pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_performed))
                            ELSE
                             NULL
                        END prof_perform,
                       decode(bpe.dt_begin,
                              NULL,
                              NULL,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T40'),
                                     NULL) ||
                              pk_date_utils.date_char_tsz(i_lang, bpe.dt_begin, i_prof.institution, i_prof.software)) start_time,
                       decode(bpe.dt_end,
                              NULL,
                              NULL,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T42'),
                                     NULL) ||
                              pk_date_utils.date_char_tsz(i_lang, bpe.dt_end, i_prof.institution, i_prof.software)) end_time,
                       decode(bpe.dt_end,
                               NULL,
                               CASE
                                   WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_cancel)
                                        AND bpd.qty_given IS NOT NULL THEN
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T121'),
                                           NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                         i_prof,
                                                                                                         bpd.qty_given,
                                                                                                         bpd.id_unit_mea_qty_given)
                                                       FROM dual)
                                   ELSE
                                    NULL
                               END,
                               decode(i_flg_html_det,
                                      pk_alert_constant.g_no,
                                      i_aa_code_messages('BLOOD_PRODUCTS_T121'),
                                      NULL) || (SELECT pk_blood_products_utils.get_bp_quantity_desc(i_lang,
                                                                                                    i_prof,
                                                                                                    bpd.qty_given,
                                                                                                    bpd.id_unit_mea_qty_given)
                                                  FROM dual)) qty_given,
                       to_char(decode(dbms_lob.getlength(t.l_notes),
                                      NULL,
                                      to_clob(''),
                                      decode(instr(lower(decode(i_flg_report,
                                                                pk_blood_products_constant.g_no,
                                                                REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                                        chr(10),
                                                                        chr(10) || chr(9)),
                                                                REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                                   '<b>'),
                                             0,
                                             to_clob(decode(i_flg_html_det,
                                                            pk_alert_constant.g_no,
                                                            i_aa_code_messages('BLOOD_PRODUCTS_T43'),
                                                            NULL) ||
                                                     decode(i_flg_report,
                                                            pk_blood_products_constant.g_no,
                                                            REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                                    chr(10),
                                                                    chr(10) || chr(9)),
                                                            REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))),
                                             decode(i_flg_report,
                                                    pk_blood_products_constant.g_no,
                                                    REPLACE((REPLACE(t.l_notes, chr(10) || chr(10), chr(10))),
                                                            chr(10),
                                                            chr(10) || chr(9)),
                                                    REPLACE(t.l_notes, chr(10) || chr(10), chr(10)))))) desc_perform,
                       decode(bpe.description,
                              NULL,
                              NULL,
                              decode(i_flg_html_det, pk_alert_constant.g_no, i_aa_code_messages('COMMON_M044'), NULL) || ' ' ||
                              bpe.description) exec_notes,
                       CASE
                            WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                pk_blood_products_constant.g_bp_action_end_transp,
                                                pk_blood_products_constant.g_bp_action_administer,
                                                pk_blood_products_constant.g_bp_action_begin_return,
                                                pk_blood_products_constant.g_bp_action_end_return)
                                 AND i_flg_html_det = pk_alert_constant.g_yes THEN
                             pk_blood_products_core.get_bp_condition_detail(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_blood_product_det => bpe.id_blood_product_det,
                                                                            i_exec_number       => bpe.exec_number - 1,
                                                                            i_flg_report        => i_flg_report,
                                                                            i_flg_html          => i_flg_html_det,
                                                                            i_flg_html_mode     => CASE
                                                                                                       WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                                        pk_blood_products_constant.g_bp_condition_reason
                                                                                                       ELSE
                                                                                                        NULL
                                                                                                   END)
                            ELSE
                             decode(bpe.id_action_reason,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('CANCEL_SCREEN_LABELS_T003') || ' ',
                                           NULL) ||
                                    pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, bpe.id_action_reason))
                        END action_reason,
                       decode(bpe.notes_reason,
                              NULL,
                              NULL,
                              decode(i_flg_html_det, pk_alert_constant.g_no, i_aa_code_messages('COMMON_M044'), NULL) || ' ' ||
                              bpe.notes_reason) action_notes,
                       decode(bpe.id_prof_match,
                              NULL,
                              NULL,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T33'),
                                     NULL) || pk_prof_utils.get_name_signature(i_lang, i_prof, bpe.id_prof_match)) id_prof_match,
                       decode(bpe.dt_match_tstz,
                              NULL,
                              NULL,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T88'),
                                     NULL) ||
                              pk_date_utils.date_char_tsz(i_lang, bpe.dt_match_tstz, i_prof.institution, i_prof.software)) dt_match_tstz,
                       bpe.id_professional,
                       bpe.dt_bp_execution_tstz,
                       bpe.flg_compatibility desc_compatibility,
                       bpe.notes_compatibility notes_compatibility,
                       CASE
                            WHEN bpe.action IN (pk_blood_products_constant.g_bp_action_begin_transp,
                                                pk_blood_products_constant.g_bp_action_end_transp,
                                                pk_blood_products_constant.g_bp_action_administer,
                                                pk_blood_products_constant.g_bp_action_begin_return,
                                                pk_blood_products_constant.g_bp_action_end_return) THEN
                             pk_blood_products_core.get_bp_condition_detail(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_blood_product_det => bpe.id_blood_product_det,
                                                                            i_exec_number       => bpe.exec_number - 1,
                                                                            i_flg_report        => i_flg_report,
                                                                            i_flg_html          => i_flg_html_det,
                                                                            i_flg_html_mode     => CASE
                                                                                                       WHEN i_flg_html_det = pk_alert_constant.g_yes THEN
                                                                                                        'C'
                                                                                                       ELSE
                                                                                                        NULL
                                                                                                   END)
                            ELSE
                             NULL
                        END condition,
                       NULL blood_group_desc,
                       CASE
                            WHEN bpe.action = pk_blood_products_constant.g_bp_action_lab_service THEN
                             decode(bpd.donation_code,
                                    NULL,
                                    NULL,
                                    decode(i_flg_html_det,
                                           pk_alert_constant.g_no,
                                           i_aa_code_messages('BLOOD_PRODUCTS_T146'),
                                           NULL) || bpd.donation_code)
                            ELSE
                             NULL
                        END donation_code,
                       decode(bpe.duration,
                              NULL,
                              NULL,
                              decode(i_flg_html_det,
                                     pk_alert_constant.g_no,
                                     i_aa_code_messages('BLOOD_PRODUCTS_T41'),
                                     NULL) || bpe.duration || ' ' ||
                              pk_unit_measure.get_unit_measure_description(i_lang, i_prof, bpe.id_unit_mea_duration)) duration,
                       NULL result_1,
                       NULL dt_result_1,
                       NULL result_sig_1,
                       NULL result_2,
                       NULL dt_result_2,
                       NULL result_sig_2
                  FROM blood_product_execution bpe
                  JOIN blood_product_det bpd
                    ON bpd.id_blood_product_det = bpe.id_blood_product_det
                  LEFT JOIN TABLE(l_tbl_bp_notes) t
                    ON t.l_id_blood_product_det = bpe.id_blood_product_det
                   AND t.l_id_blod_product_execution = bpe.id_blood_product_execution
                 WHERE bpd.id_blood_product_det = i_blood_product_det
                   AND bpe.action NOT IN (pk_blood_products_constant.g_bp_action_condition,
                                          pk_blood_products_constant.g_bp_action_lab_mother,
                                          pk_blood_products_constant.g_bp_action_lab_mother_id)
                UNION
                SELECT NULL dt_blood_product_det_hist,
                       NULL id_blood_product_execution,
                       CASE
                           WHEN l_blood_group_desc IS NOT NULL THEN
                            pk_blood_products_constant.g_bp_action_blood_group
                           ELSE
                            NULL
                       END action,
                       CASE
                           WHEN l_blood_group_desc IS NOT NULL THEN
                            i_aa_code_messages('BLOOD_PRODUCTS_T143')
                           ELSE
                            NULL
                       END desc_action,
                       CASE
                           WHEN l_blood_group_desc IS NOT NULL THEN
                            get_bp_blood_group_rank(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_blood_product_det => i_blood_product_det)
                           ELSE
                            NULL
                       END exec_number,
                       --   NULL registry,
                       NULL desc_hemo_type,
                       NULL clinical_indication,
                       NULL desc_diagnosis,
                       NULL clinical_purpose,
                       NULL instructions,
                       NULL priority,
                       NULL special_type,
                       NULL desc_time,
                       NULL order_recurrence,
                       NULL execution,
                       NULL perform_location,
                       NULL dt_req,
                       NULL not_order_reason,
                       NULL notes,
                       NULL co_sign,
                       NULL prof_order,
                       NULL dt_order,
                       NULL order_type,
                       NULL cancellation,
                       NULL cancel_reason,
                       NULL cancel_notes,
                       NULL cancel_prof_order,
                       NULL cancel_dt_order,
                       NULL cancel_order_type,
                       NULL health_insurance,
                       NULL financial_entity,
                       NULL health_plan,
                       NULL insurance_number,
                       NULL exemption,
                       NULL transfusion,
                       NULL transfusion_type_desc,
                       NULL quantity_ordered,
                       NULL quantity_received,
                       NULL barcode,
                       NULL blood_group,
                       NULL blood_group_rh,
                       -- NULL desc_compatibility,
                       --  NULL notes_compatibility,
                       NULL expiration_date,
                       NULL special_instr,
                       NULL tech_notes,
                       NULL prof_perform,
                       NULL start_time,
                       NULL end_time,
                       NULL qty_given,
                       NULL desc_perform,
                       NULL exec_notes,
                       NULL action_reason,
                       NULL action_notes,
                       NULL id_prof_match,
                       NULL dt_match_tstz,
                       NULL id_professional,
                       NULL dt_bp_execution_tstz,
                       NULL desc_compatibility,
                       NULL notes_compatibility,
                       NULL condition,
                       l_blood_group_desc blood_group_desc,
                       NULL donation_code,
                       NULL duration,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_1) result_1,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_dt_result_1) dt_result_1,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_sig_1) result_sig_1,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_2) result_2,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_dt_result_2) dt_result_2,
                       decode(i_flg_html_det, pk_alert_constant.g_no, NULL, l_result_sig_2) result_sig_2
                  FROM dual
                 WHERE l_blood_group_desc IS NOT NULL) t;
    
        RETURN l_tbl_bp_info;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_BP_DETAIL_HISTORY_CORE',
                                              l_error);
            RETURN l_tbl_bp_info;
    END tf_get_bp_detail_history_core;

    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        o_error t_error_out;
    BEGIN
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_prof_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_prof_software' THEN
                o_vc2 := to_char(l_prof.software);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BLOOD_PRODUCTS_CORE',
                                              i_function => 'INIT_PARAMS',
                                              o_error    => o_error);
    END init_params;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_blood_products_core;
/
