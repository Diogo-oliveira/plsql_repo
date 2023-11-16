/*-- Last Change Revision: $Rev: 2026684 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_interv IS

    FUNCTION create_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention_content    IN table_varchar, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number, --20
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_varchar, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'I',
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_intervention      table_number := table_number();
        l_clinical_question table_table_number := table_table_number();
        l_response          table_table_varchar := table_table_varchar();
    
        l_flg_show  VARCHAR2(10);
        l_msg_title VARCHAR2(10);
        l_msg_req   VARCHAR2(10);
    
    BEGIN
    
        FOR i IN 1 .. i_intervention_content.count
        LOOP
            l_intervention.extend;
        
            g_error := 'CALL GET_PROCEDURE_BY_ID_CONTENT';
            IF NOT pk_api_interv.get_procedure_by_id_content(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_content      => i_intervention_content(i),
                                                             o_intervention => l_intervention(i),
                                                             o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_clinical_question.extend;
            l_clinical_question(i) := table_number();
        
            l_response.extend;
            l_response(i) := table_varchar();
        
            FOR j IN 1 .. i_clinical_question(i).count
            LOOP
                IF i_clinical_question(i) (j) IS NOT NULL
                THEN
                    l_clinical_question(i).extend();
                    l_response(i).extend();
                
                    g_error := 'CALL GET_PROCEDURE_CQ_BY_ID_CONTENT - CQ';
                    IF NOT pk_api_interv.get_procedure_cq_by_id_content(i_lang     => i_lang,
                                                                        i_prof     => i_prof,
                                                                        i_content  => i_clinical_question(i) (j),
                                                                        i_flg_type => 'CQ',
                                                                        o_id       => l_clinical_question(i)
                                                                                      (l_clinical_question(i).count),
                                                                        o_error    => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF i_response(i) (j) IS NOT NULL
                    THEN
                        g_error := 'CALL GET_PROCEDURE_CQ_BY_ID_CONTENT - R';
                        IF NOT
                            pk_api_interv.get_procedure_cq_by_id_content(i_lang     => i_lang,
                                                                         i_prof     => i_prof,
                                                                         i_content  => i_response(i) (j),
                                                                         i_flg_type => 'R',
                                                                         o_id       => l_response(i) (l_response(i).count),
                                                                         o_error    => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    ELSE
                        l_response(i)(j) := i_response(i) (j);
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
    
        g_error := 'CALL PK_PROCEDURES_API_DB.CREATE_PROCEDURE_ORDER';
        IF NOT pk_procedures_api_db.create_procedure_order(i_lang                    => i_lang,
                                                           i_prof                    => i_prof,
                                                           i_patient                 => i_patient,
                                                           i_episode                 => i_episode,
                                                           i_intervention            => l_intervention,
                                                           i_flg_time                => i_flg_time,
                                                           i_dt_begin                => i_dt_begin,
                                                           i_episode_destination     => i_episode_destination,
                                                           i_order_recurrence        => i_order_recurrence,
                                                           i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                                  i_prof   => i_prof,
                                                                                                                  i_params => i_diagnosis),
                                                           i_clinical_purpose        => i_clinical_purpose,
                                                           i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                           i_laterality              => i_laterality,
                                                           i_priority                => i_priority,
                                                           i_flg_prn                 => i_flg_prn,
                                                           i_notes_prn               => i_notes_prn,
                                                           i_exec_institution        => i_exec_institution,
                                                           i_supply                  => i_supply,
                                                           i_supply_set              => i_supply_set,
                                                           i_supply_qty              => i_supply_qty,
                                                           i_dt_return               => i_dt_return,
                                                           i_not_order_reason        => i_not_order_reason,
                                                           i_notes                   => i_notes,
                                                           i_prof_order              => i_prof_order,
                                                           i_dt_order                => i_dt_order,
                                                           i_order_type              => i_order_type,
                                                           i_codification            => i_codification,
                                                           i_health_plan             => i_health_plan,
                                                           i_exemption               => i_exemption,
                                                           i_clinical_question       => l_clinical_question,
                                                           i_response                => l_response,
                                                           i_clinical_question_notes => i_clinical_question_notes,
                                                           i_clinical_decision_rule  => i_clinical_decision_rule,
                                                           i_flg_origin_req          => i_flg_origin_req,
                                                           i_test                    => pk_procedures_constant.g_no,
                                                           o_flg_show                => l_flg_show,
                                                           o_msg_title               => l_msg_title,
                                                           o_msg_req                 => l_msg_req,
                                                           o_interv_presc_array      => o_interv_presc_array,
                                                           o_interv_presc_det_array  => o_interv_presc_det_array,
                                                           o_error                   => o_error)
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
                                              'CREATE_PROCEDURE_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_procedure_order;

    FUNCTION set_procedure_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_interv_presc_det  IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_prof_performed    IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time        IN VARCHAR2,
        i_end_time          IN VARCHAR2,
        i_notes             IN interv_presc_plan.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_presc_plan interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_tbl_templ       t_coll_aux_interv_plan;
        l_aux_interv_plan pk_api_interv.t_rec_aux_interv_plan;
        l_interv          t_cur_aux_interv_plan;
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_API_DB.GET_PROCEDURE_FOR_EXECUTION';
        IF NOT pk_procedures_api_db.get_procedure_for_execution(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_interv_presc_det  => i_interv_presc_det,
                                                                i_interv_presc_plan => NULL,
                                                                o_interv            => l_interv,
                                                                o_error             => o_error)
        
        THEN
            RAISE g_other_exception;
        END IF;
    
        FETCH l_interv BULK COLLECT
            INTO l_tbl_templ;
    
        FOR i IN 1 .. l_tbl_templ.count
        LOOP
            l_aux_interv_plan.dt_plan := l_tbl_templ(i).dt_plan;
            EXIT WHEN l_interv%NOTFOUND;
        END LOOP;
    
        g_error := 'CALL PK_PROCEDURES_API_DB.SET_PROCEDURE_EXECUTION';
        RETURN pk_procedures_api_db.set_procedure_execution(i_lang                   => i_lang,
                                                            i_prof                   => i_prof,
                                                            i_episode                => i_episode,
                                                            i_interv_presc_det       => i_interv_presc_det,
                                                            i_interv_presc_plan      => i_interv_presc_plan,
                                                            i_dt_next                => l_aux_interv_plan.dt_plan,
                                                            i_prof_performed         => i_prof_performed,
                                                            i_start_time             => i_start_time,
                                                            i_end_time               => i_end_time,
                                                            i_flg_supplies           => pk_alert_constant.g_no,
                                                            i_notes                  => i_notes,
                                                            i_epis_documentation     => NULL,
                                                            i_clinical_decision_rule => NULL,
                                                            o_interv_presc_plan      => l_interv_presc_plan,
                                                            o_error                  => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROCEDURE_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_execution;

    FUNCTION cancel_procedure_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN interv_presc_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN interv_presc_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_API_DB.CANCEL_PROCEDURE_REQUEST';
        IF NOT pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => i_interv_presc_det,
                                                             i_dt_cancel        => i_dt_cancel,
                                                             i_cancel_reason    => i_cancel_reason,
                                                             i_cancel_notes     => i_cancel_notes,
                                                             i_prof_order       => i_prof_order,
                                                             i_dt_order         => i_dt_order,
                                                             i_order_type       => i_order_type,
                                                             o_error            => o_error)
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
                                              'CANCEL_PROCEDURE_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_request;

    FUNCTION cancel_procedure_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_presc_plan_task IN interv_presc_det.id_presc_plan_task%TYPE,
        i_dt_cancel       IN interv_presc_det.dt_cancel_tstz%TYPE DEFAULT current_timestamp,
        i_cancel_notes    IN interv_presc_det.notes_cancel%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_presc_det table_number;
        l_dt_cancel        VARCHAR2(100 CHAR);
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_presc_plan_task = ' || coalesce(to_char(i_presc_plan_task), '<null>');
        g_error := g_error || ' i_cancel_reason = ' || coalesce(to_char(i_cancel_reason), '<null>');
    
        l_dt_cancel := pk_date_utils.date_send_tsz(i_lang, coalesce(i_dt_cancel, current_timestamp), i_prof);
    
        SELECT ipp.id_interv_presc_det BULK COLLECT
          INTO l_interv_presc_det
          FROM interv_presc_plan ipp
         INNER JOIN interv_presc_det ipd
            ON ipd.id_interv_presc_det = ipp.id_interv_presc_det
         WHERE ipd.id_presc_plan_task = i_presc_plan_task
           AND ipp.flg_status != pk_procedures_constant.g_interv_cancel;
    
        FOR i IN 1 .. l_interv_presc_det.count
        LOOP
            g_error := 'CALL PK_PROCEDURES_CORE.CANCEL_PROCEDURE_REQUEST';
            IF NOT pk_procedures_core.cancel_procedure_request(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_interv_presc_det => table_number(l_interv_presc_det(i)),
                                                               i_dt_cancel        => l_dt_cancel,
                                                               i_cancel_reason    => i_cancel_reason,
                                                               i_cancel_notes     => i_cancel_notes,
                                                               i_prof_order       => NULL,
                                                               i_dt_order         => NULL,
                                                               i_order_type       => NULL,
                                                               o_error            => o_error)
            THEN
                RAISE g_other_exception;
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
                                              'CANCEL_PROCEDURE_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_request;

    FUNCTION get_procedure_by_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_content      IN VARCHAR2,
        o_intervention OUT intervention.id_intervention%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET ID_INTERV';
        SELECT i.id_intervention
          INTO o_intervention
          FROM intervention i
         WHERE i.id_content = i_content;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_procedure_by_id_content;

    FUNCTION get_procedure_cq_by_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_content  IN VARCHAR2,
        i_flg_type IN VARCHAR2,
        o_id       OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_content table_varchar2;
        l_id      NUMBER;
    
    BEGIN
    
        IF i_flg_type = 'CQ'
        THEN
            g_error := 'GET ID_QUESTIONNAIRE - ' || i_content;
            SELECT q.id_questionnaire
              INTO o_id
              FROM questionnaire q
             WHERE q.id_content = i_content;
        ELSE
            l_content := pk_utils.str_split(i_content, '|');
        
            FOR i IN 1 .. l_content.count
            LOOP
                g_error := 'GET ID_RESPONSE - ' || i_content;
                SELECT r.id_response
                  INTO l_id
                  FROM response r
                 WHERE r.id_content = l_content(i);
            
                IF i != l_content.last
                THEN
                    o_id := o_id || l_id || '|';
                ELSE
                    o_id := o_id || l_id;
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
                                              'GET_PROCEDURE_CQ_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_procedure_cq_by_id_content;

END pk_api_interv;
/
