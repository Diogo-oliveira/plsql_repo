/*-- Last Change Revision: $Rev: 2027612 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_pbl IS

    /********************************************************************************************
    * Get intervention description
    *
    * %param i_lang         language id
    * %param i_id_patient   patient id
    *
    * @return               rehab intervention description
    *
    ********************************************************************************************/
    FUNCTION get_rehab_interv_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE
    ) RETURN VARCHAR2 IS
        l_interv_desc pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL)
          INTO l_interv_desc
          FROM intervention i
          JOIN interv_presc_det ipd
            ON ipd.id_intervention = i.id_intervention
         WHERE ipd.id_interv_presc_det = i_id_rehab_presc;
    
        RETURN l_interv_desc;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_interv_desc := '';
            RETURN l_interv_desc;
    END get_rehab_interv_desc;

    /********************************************************************************************
    * Retrieve all patient rehabilitation procedures ongoing
    *
    * %param i_lang         language id
    * %param i_prof         profissional
    * %param i_id_patient   patient id
    *
    * @return               list of tasks
    *
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_rehab
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
        l_tasks_list tf_tasks_list;
        o_error      t_error_out;
    
    BEGIN
        g_error := 'get_ongoing_tasks_rehab for id_patient=' || i_id_patient;
    
        SELECT tr_tasks_list(pea.id_interv_presc_det,
                             pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL),
                             pk_translation.get_translation(i_lang, et.code_epis_type),
                             pk_date_utils.dt_chr_date_hour_tsz(i_lang, pea.dt_interv_prescription, i_prof))
          BULK COLLECT
          INTO l_tasks_list
          FROM procedures_ea pea
          JOIN intervention i
            ON i.id_intervention = pea.id_intervention
          JOIN episode e
            ON e.id_episode = pea.id_episode
          JOIN epis_type et
            ON et.id_epis_type = e.id_epis_type
         WHERE pea.id_patient = i_id_patient
           AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_interrupted,
                                          pk_procedures_constant.g_interv_finished,
                                          pk_procedures_constant.g_interv_cancel)
         ORDER BY pea.dt_interv_prescription DESC;
    
        RETURN l_tasks_list;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tasks_list;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ONGOING_TASKS_REHAB',
                                              o_error);
            RAISE g_exception;
        
    END get_ongoing_tasks_rehab;

    /********************************************************************************************
    * Suspend a rehabilitation procedure
    *
    * %param i_lang                   language id
    * %param i_prof                   profissional
    * %param i_id_rehab_presc         rehab id to suspend
    * %param o_msg_error              error message when cancel wasn't possible
    * %param o_error                  error object in case of exception
    *
    * @return    TRUE on success, FALSE otherwise
    ********************************************************************************************/
    FUNCTION suspend_task_rehab
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_reason     IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error        := 'suspend_task_procedures for id_interv_presc_det=' || i_id_rehab_presc;
        g_sysdate_tstz := current_timestamp;
    
        IF NOT pk_procedures_core.cancel_procedure_request(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_interv_presc_det => table_number(i_id_rehab_presc),
                                                           i_dt_cancel        => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                                 i_prof,
                                                                                                                 g_sysdate_tstz,
                                                                                                                 NULL),
                                                           i_cancel_reason    => NULL,
                                                           i_cancel_notes     => pk_message.get_message(i_lang,
                                                                                                        i_prof,
                                                                                                        'PATIENT_DEATH_M002'),
                                                           i_prof_order       => NULL,
                                                           i_dt_order         => NULL,
                                                           i_order_type       => NULL,
                                                           o_error            => o_error)
        THEN
            -- Não foi possível suspender o procedimento de rehabilitação
            g_error := 'get intervention description';
        
            o_msg_error := REPLACE(pk_message.get_message(i_lang, 'REHAB_M002'),
                                   '@1',
                                   get_rehab_interv_desc(i_lang, i_prof, i_id_rehab_presc));
            RETURN FALSE;
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
                                              'SUSPEND_TASK_REHAB',
                                              o_error);
            RETURN FALSE;
    END suspend_task_rehab;

    /********************************************************************************************
    * Reactivate a supended rehabilitation procedure
    *
    * %param i_lang                   language id
    * %param i_prof                   profissional
    * %param i_id_rehab_presc         rehab id to reactivate
    * %param o_msg_error              error message when cancel wasn't possible
    * %param o_error                  error object in case of exception
    *
    * @return    TRUE on success, FALSE otherwise
    ********************************************************************************************/
    FUNCTION reactivate_task_rehab
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'NOT IMPLEMENTED';
        -- Não foi possível reactivar o procedimento de rehabilitação
        o_msg_error := REPLACE(pk_message.get_message(i_lang, 'REHAB_M001'),
                               '@1',
                               get_rehab_interv_desc(i_lang, i_prof, i_id_rehab_presc));
    
        RETURN FALSE;
    END reactivate_task_rehab;

    FUNCTION get_rehb_diag_viewer_checklit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM rehab_diagnosis rd
         WHERE rd.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  *
                                   FROM TABLE(l_episode) t)
           AND rd.flg_status != pk_rehab.g_rehab_diag_flg_status_c;
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM rehab_diagnosis rd
             WHERE rd.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      *
                                       FROM TABLE(l_episode) t)
               AND rd.flg_status NOT IN (pk_rehab.g_rehab_diag_flg_status_r, pk_rehab.g_rehab_diag_flg_status_t);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            RETURN pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_rehb_diag_viewer_checklit;

    FUNCTION get_rehb_sess_viewer_checklit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM rehab_presc rp
         INNER JOIN rehab_session rs
            ON rs.id_rehab_presc = rp.id_rehab_presc
         WHERE rs.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  *
                                   FROM TABLE(l_episode) t)
           AND rs.flg_status != pk_rehab.g_rehab_presc_cancel;
    
        IF l_count > 0
        THEN
            RETURN pk_viewer_checklist.g_checklist_completed;
        ELSE
            RETURN pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_rehb_sess_viewer_checklit;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_rehab_pbl;
/
