/*-- Last Change Revision: $Rev: 2047873 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-20 11:34:17 +0100 (qui, 20 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_disposition IS
    g_admin_admission CONSTANT sys_config.id_sys_config%TYPE := 'ADMIN_ADMISSION';
    e_call_exception EXCEPTION;
    g_syscfg_disch_diag_icd9 CONSTANT sys_config.id_sys_config%TYPE := 'DISCHARGE_DIAG_ICD9';
    g_not_applicable         CONSTANT VARCHAR2(2) := 'NA';
    g_can_edit_inact_epis    CONSTANT VARCHAR2(1) := 'Y';

    g_sa_client_registry_sys_id CONSTANT external_sys.id_external_sys%TYPE := 15101;

    PROCEDURE set_api_commit
    (
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_l_transaction_id IN VARCHAR2
    ) IS
    BEGIN
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(i_l_transaction_id, i_prof);
        END IF;
    
    END set_api_commit;

    PROCEDURE set_api_rollback
    (
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_l_transaction_id IN VARCHAR2
    ) IS
    BEGIN
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_rollback(i_l_transaction_id, i_prof);
        END IF;
    
    END set_api_rollback;

    FUNCTION set_disp_edis_to_inp_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_alert IS
            SELECT i_episode id_episode,
                   i_episode id_record,
                   e_edis.id_institution id_institution,
                   NULL id_professional,
                   e_inp.dt_begin_tstz dt_record,
                   decode(e_inp.flg_type,
                          'T',
                          '',
                          'D',
                          (SELECT dpt.code_department
                             FROM department dpt, discharge d, disch_reas_dest drd
                            WHERE d.id_episode = e_edis.id_episode
                              AND d.flg_status NOT IN ('C', 'R')
                              AND drd.id_disch_reas_dest = d.id_disch_reas_dest
                              AND dpt.id_department = drd.id_department)) replace1,
                   NULL id_schedule,
                   decode(e_inp.flg_type, 'T', 30, 'D', 31) id_sys_alert,
                   e_edis.id_episode id_reg_det,
                   NULL id_clinical_service,
                   NULL id_room
              FROM epis_type et_edis, episode e_edis, episode e_inp, epis_ext_sys ees, epis_info ei
             WHERE e_edis.flg_status IN ('A', 'P')
               AND e_inp.flg_type IN ('T', 'D')
               AND e_edis.id_episode = i_episode
               AND e_inp.id_prev_episode = e_edis.id_episode
               AND pk_alert_constant.g_soft_edis =
                   pk_episode.get_soft_by_epis_type(e_edis.id_epis_type, e_edis.id_institution)
               AND ei.id_episode = e_edis.id_episode
               AND ees.id_episode = e_inp.id_episode
               AND ees.id_institution = e_edis.id_institution
               AND ees.id_external_sys =
                   pk_sysconfig.get_config('ID_EXTERNAL_SYS', e_edis.id_institution, ei.id_software)
               AND ees.value IS NULL;
    
        l_alert c_alert%ROWTYPE;
        l_error VARCHAR2(4000);
        l_found BOOLEAN;
    BEGIN
    
        OPEN c_alert;
        FETCH c_alert
            INTO l_alert;
        l_found := c_alert%NOTFOUND;
        CLOSE c_alert;
        IF NOT l_found
        THEN
            IF NOT pk_alerts.insert_sys_alert_event(i_lang,
                                                    i_prof,
                                                    l_alert.id_sys_alert,
                                                    l_alert.id_episode,
                                                    l_alert.id_record,
                                                    l_alert.dt_record,
                                                    l_alert.id_professional,
                                                    l_alert.id_room,
                                                    l_alert.id_clinical_service,
                                                    NULL,
                                                    l_alert.replace1,
                                                    o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Gets the patient admitting to room (Inpatient discharge)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room_admit             admitting room ID
    * @param i_admit_to_room          admitting room (free text)
    *
    * @return                         admitting room (formatted text)
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2010/10/08
    **********************************************************************************************/
    FUNCTION get_room_admit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_room_admit    IN discharge_detail_hist.id_room_admit%TYPE,
        i_admit_to_room IN discharge_detail_hist.admit_to_room%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ROOM_ADMIT';
        l_ret   discharge_detail_hist.admit_to_room%TYPE;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET ROOM DESCRIPTION';
        IF i_room_admit IS NOT NULL
        THEN
            SELECT nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))
              INTO l_ret
              FROM room ro
             WHERE ro.id_room = i_room_admit;
        
        ELSE
            l_ret := i_admit_to_room;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_room_admit;
    --
    /***************************************************************************************************
    * Gets the discharge type description
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    * @param   i_disch                    discharge status ID
    * @param   i_flg_status               discharge status (flag value)
    * @param   o_desc                     description of the discharge type
    * @param   o_error                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 1.0
    * @since   19/02/2010
    *
    ***************************************************************************************************/
    FUNCTION get_disch_status_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_disch      IN discharge_status.id_discharge_status%TYPE,
        i_flg_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc  pk_translation.t_desc_translation;
        l_error t_error_out;
    
    BEGIN
    
        IF i_disch IS NOT NULL
        THEN
            g_error := 'GET DESCRIPTION 1';
            SELECT pk_translation.get_translation(i_lang, ds.code_discharge_status)
              INTO l_desc
              FROM discharge_status ds
             WHERE ds.id_discharge_status = i_disch;
        ELSE
            g_error := 'GET DESCRIPTION 2';
            l_desc  := pk_sysdomain.get_domain(g_disch_flg_status_domain, i_flg_status, i_lang);
        END IF;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCH_STATUS_DESC',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_disch_status_desc;
    --
    FUNCTION get_other_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_get_profile_template EXCEPTION;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       pk_translation.get_translation(i_lang, dd.code_discharge_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       ddh.flg_med_reconcile,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel
                  FROM discharge_hist        dh,
                       discharge             dsc,
                       discharge_detail_hist ddh,
                       disch_reas_dest       drd,
                       professional          prf_pp,
                       dep_clin_serv         dcs,
                       clinical_service      cli,
                       complaint             cmp,
                       discharge_reason      dr,
                       professional          prfa,
                       discharge_dest        dd
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                   AND dsc.id_discharge = dh.id_discharge
                   AND ddh.id_prof_admitting = prfa.id_professional(+)
                   AND ddh.id_complaint = cmp.id_complaint(+)
                   AND ddh.id_prof_assigned_to = prf_pp.id_professional(+)
                   AND ddh.id_dep_clin_serv_visit = dcs.id_dep_clin_serv(+)
                   AND dcs.id_clinical_service = cli.id_clinical_service(+)
                   AND dh.id_discharge_hist = ddh.id_discharge_hist
                   AND ddh.id_complaint = cmp.id_complaint(+)
                   AND dh.id_disch_reas_dest = drd.id_disch_reas_dest
                   AND drd.id_discharge_reason = dr.id_discharge_reason
                   AND drd.id_discharge_dest = dd.id_discharge_dest(+)
                 ORDER BY dh.dt_created_hist DESC;
        ELSE
        
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_OTHER_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_OTHER_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_other_disposition;

    /********************************************************************************************
     * Function that gets data from table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_id_discharge_hist   id de registo de alta se exisitir
     * @param O_sql           id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/15
    ********************************************************************************************/
    FUNCTION get_followup_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_get_profile_template EXCEPTION;
        l_disch_letter_list_exception VARCHAR2(0050);
        tit_sched_for                 sys_message.desc_message%TYPE;
        tit_prop_for                  sys_message.desc_message%TYPE;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
            tit_sched_for := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T019');
            tit_prop_for  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T020');
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       ddh.pat_instructions_provided,
                       pk_sysdomain.get_domain('YES_NO', ddh.pat_instructions_provided, i_lang) desc_pat_instructions_provided,
                       ddh.flg_med_reconcile,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) desc_med_reconcile,
                       ddh.flg_prescription_given_to,
                       decode(ddh.flg_prescription_given_to,
                              l_disch_letter_list_exception,
                              ddh.desc_prescription_given_to,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PRESCRIPTION_GIVEN_TO',
                                                      ddh.flg_prescription_given_to,
                                                      i_lang)) desc_prescription_given_to,
                       ddh.flg_instructions_discussed,
                       decode(ddh.flg_instructions_discussed,
                              l_disch_letter_list_exception,
                              ddh.instructions_discussed_notes,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                      ddh.flg_instructions_discussed,
                                                      i_lang)) desc_instructions_discussed,
                       ddh.id_prof_assigned_to id_professional,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_assigned_to)
                          FROM dual) name,
                       --ddh.next_visit_scheduled,
                       decode(ddh.id_schedule,
                              NULL,
                              decode(ddh.id_consult_req,
                                     NULL,
                                     ddh.next_visit_scheduled,
                                     decode(creq.dt_scheduled_tstz,
                                            NULL,
                                            ddh.next_visit_scheduled,
                                            tit_prop_for || pk_date_utils.dt_chr_tsz(i_lang,
                                                                                     creq.dt_scheduled_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software))),
                              tit_sched_for ||
                              pk_date_utils.dt_chr_tsz(i_lang, sch.dt_schedule_tstz, i_prof.institution, i_prof.software)) next_visit_scheduled, --ddh.next_visit_scheduled,
                       ddh.flg_instructions_next_visit,
                       decode(ddh.flg_instructions_next_visit,
                              l_disch_letter_list_exception,
                              ddh.desc_instructions_next_visit,
                              pk_sysdomain.get_domain('SCHEDULE.FLG_INSTRUCTIONS',
                                                      ddh.flg_instructions_next_visit,
                                                      i_lang)) desc_instructions_next_visit,
                       dcs.id_dep_clin_serv,
                       pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_clinical_service,
                       cmp.id_complaint,
                       pk_translation.get_translation(i_lang, cmp.code_complaint) desc_complaint,
                       ddh.notes notes_regitrar,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       dsc.id_cpt_code,
                       cc.medium_desc desc_cpt_code,
                       pk_schedule.has_permission(i_lang,
                                                  i_prof,
                                                  NULL,
                                                  g_sch_event_id_followup,
                                                  ddh.id_prof_assigned_to) permission,
                       decode(ddh.id_schedule, NULL, decode(ddh.id_consult_req, NULL, 'N', 'P'), 'S') flg_type,
                       pk_date_utils.date_send(i_lang, creq.dt_scheduled_tstz, i_prof) dt_next_visit_scheduled,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = ddh.id_dep_clin_serv_visit
                  LEFT JOIN clinical_service cli
                    ON cli.id_clinical_service = dcs.id_clinical_service
                  LEFT JOIN complaint cmp
                    ON cmp.id_complaint = ddh.id_complaint
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN discharge_dest dd
                    ON dd.id_discharge_dest = drd.id_discharge_dest
                  LEFT JOIN cpt_code cc
                    ON cc.id_cpt_code = dsc.id_cpt_code
                  LEFT JOIN consult_req creq
                    ON creq.id_consult_req = ddh.id_consult_req
                  LEFT JOIN schedule sch
                    ON sch.id_schedule = ddh.id_schedule
                  LEFT JOIN dep_clin_serv dcs2
                    ON dcs2.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                
                 ORDER BY dh.dt_created_hist DESC;
        ELSE
        
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_FOLLOWUP_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_FOLLOWUP_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_followup_disposition;

    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template profile_template.id_profile_template%TYPE;
        err_get_profile_template EXCEPTION;
        l_ret BOOLEAN;
    BEGIN
    
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_get_profile_template;
        END IF;
    
        g_error := 'OPEN CURSOR O_TYPE';
        OPEN o_sql FOR
            SELECT c.id_complaint, pk_translation.get_translation(i_lang, code_complaint) desc_complaint
              FROM complaint c,
                   (SELECT id_context
                      FROM doc_template_context dtc
                     WHERE dtc.id_institution IN (0, i_prof.institution)
                       AND dtc.id_software IN (0, i_prof.software)
                       AND dtc.id_dep_clin_serv = i_id_dep_clin_serv
                       AND dtc.id_profile_template = l_id_profile_template
                          --AND dtc.id_sch_event IN 0
                       AND instr(dtc.flg_type, 'C') > 0
                     GROUP BY id_context) xx
             WHERE xx.id_context = c.id_complaint
             ORDER BY desc_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'get_template',
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_REASON_OF_VISIT',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_REASON_OF_VISIT',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_reason_of_visit;

    FUNCTION get_type_of_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional professional.id_professional%TYPE,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR O_TYPE';
        OPEN o_sql FOR
        
            SELECT dcs.id_dep_clin_serv, pk_translation.get_translation(i_lang, cs.code_clinical_service) type_of_visit
              FROM prof_dep_clin_serv pdcs
             INNER JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
             INNER JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             INNER JOIN department d
                ON d.id_department = dcs.id_department
             WHERE pdcs.id_professional = nvl(i_id_professional, i_prof.id)
               AND pdcs.id_institution = i_prof.institution
               AND d.id_institution = i_prof.institution
               AND instr(d.flg_type, g_flg_type_consult) > 0
             ORDER BY type_of_visit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_TYPE_OF_VISIT',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_type_of_visit;

    /***************************************************************************************************
    * Gets the list of discharge types
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    * @param   i_id_disch_reas_dest       disch_reas_dest ID
    * @param   o_type                     discharge types
    * @param   o_error                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 1.0
    * @since   17/05/2009
    *
    * @author  José Silva
    * @version 2.0
    * @since   25/01/2010
    *
    ***************************************************************************************************/
    FUNCTION get_discharge_options
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_type               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_inst      institution.id_institution%TYPE;
        l_mrk       market.id_market%TYPE;
        l_soft      software.id_software%TYPE;
        l_id_market market.id_market%TYPE;
        --
        l_flg_def_disch_status disch_reas_dest.flg_def_disch_status%TYPE;
        l_id_def_disch_status  disch_reas_dest.id_def_disch_status%TYPE;
    BEGIN
    
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'GET L_ID_DEF_DISCH_STATUS AND L_FLG_DEF_DISCH_STATUS';
        SELECT drd.id_def_disch_status, drd.flg_def_disch_status
          INTO l_id_def_disch_status, l_flg_def_disch_status
          FROM disch_reas_dest drd
         WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest
           AND drd.flg_active = 'A';
    
        g_error := 'GET CONFIGURATION VALUES';
        SELECT id_institution, id_market, id_software
          INTO l_inst, l_mrk, l_soft
          FROM (SELECT dsi.id_institution,
                       dsi.id_market,
                       dsi.id_software,
                       row_number() over(ORDER BY decode(dsi.id_institution, i_prof.institution, 1, 2), decode(dsi.id_market, l_id_market, 1, 2), decode(dsi.id_software, i_prof.software, 1, 2)) line_number
                  FROM disch_status_soft_inst dsi
                  JOIN discharge_status ds
                    ON dsi.id_discharge_status = ds.id_discharge_status
                 WHERE ds.flg_available = pk_alert_constant.g_yes
                   AND dsi.id_institution IN (0, i_prof.institution)
                   AND dsi.id_software IN (0, i_prof.software)
                   AND dsi.id_market IN (0, l_id_market)
                   AND dsi.id_disch_reas_dest IN (-1, i_id_disch_reas_dest))
         WHERE line_number = 1;
    
        g_error := 'OPEN CURSOR O_TYPE';
        OPEN o_type FOR
            SELECT ds.id_discharge_status,
                   ds.flg_status val,
                   decode(ds.id_discharge_status,
                          l_id_def_disch_status,
                          pk_alert_constant.g_yes,
                          decode(ds.flg_status, l_flg_def_disch_status, pk_alert_constant.g_yes, dsi.flg_default)) flg_default,
                   pk_translation.get_translation(i_lang, ds.code_discharge_status) desc_val
              FROM disch_status_soft_inst dsi
              JOIN discharge_status ds
                ON dsi.id_discharge_status = ds.id_discharge_status
             WHERE ds.flg_available = pk_alert_constant.g_yes
               AND dsi.id_institution = l_inst
               AND dsi.id_software = l_soft
               AND dsi.id_market = l_mrk
                  -- Filter by discharge reason/destination
               AND dsi.id_disch_reas_dest IN (-1, i_id_disch_reas_dest)
             ORDER BY dsi.rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCHARGE_OPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_discharge_options;

    FUNCTION set_reopen_disposition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN set_reopen_disposition(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_id_episode => i_id_episode,
                                      i_flg_status => g_disch_reopen,
                                      o_error      => o_error);
    END;

    FUNCTION set_reopen_disposition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN discharge_hist.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret   BOOLEAN;
        dsc     discharge%ROWTYPE;
        l_dsc_h discharge_hist%ROWTYPE;
        l_dsd_h discharge_detail_hist%ROWTYPE;
        l_count NUMBER;
    
        l_internal_error EXCEPTION;
    
        l_flg_market discharge.flg_market%TYPE;
    
        err_for_all EXCEPTION;
    BEGIN
    
        g_error := 'set dsc';
        SELECT *
          INTO dsc
          FROM discharge
         WHERE id_episode = i_id_episode
              -- JB 11/07/2011 ALERT-183727
           AND flg_status IN (pk_discharge_core.g_disch_status_active, pk_discharge_core.g_disch_status_pend);
    
        g_error := 'GET DISCHARGE MARKET';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_discharge_core.get_flg_market(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_discharge  => dsc.id_discharge,
                                                o_flg_market => l_flg_market,
                                                o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_flg_market = pk_discharge_core.g_disch_type_us
        THEN
        
            g_error := 'select l_dsc_h';
            SELECT dh.*
              INTO l_dsc_h
              FROM discharge_hist dh
            -- this join is needed in order to exclude the history records made by the registrar (ALERT-222832)
              JOIN discharge_detail_hist ddh
                ON ddh.id_discharge_hist = dh.id_discharge_hist
             WHERE dh.id_discharge = dsc.id_discharge
               AND dh.flg_status_hist IN
                   (pk_discharge_core.g_disch_status_active, pk_discharge_core.g_disch_status_pend);
        
            g_error := 'select l_dsd_h';
            BEGIN
                SELECT *
                  INTO l_dsd_h
                  FROM discharge_detail_hist
                 WHERE id_discharge_hist = l_dsc_h.id_discharge_hist;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dsd_h.id_discharge_detail_hist := NULL;
            END;
        
            IF l_dsd_h.id_discharge_detail_hist IS NOT NULL
            THEN
                g_error := 'set outdated';
                l_ret   := set_outdated(i_lang, i_prof, i_id_episode, o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_for_all;
                END IF;
            
                g_error                 := 'set_disposition_dsc_h';
                l_dsc_h.flg_status      := i_flg_status;
                l_dsc_h.flg_status_hist := i_flg_status;
                l_ret                   := set_disposition_dsc_h(i_lang,
                                                                 i_prof,
                                                                 l_dsc_h,
                                                                 g_no,
                                                                 l_dsc_h.id_discharge_hist,
                                                                 o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_for_all;
                END IF;
            
                g_error                   := 'set_disposition_dsd_h';
                l_dsd_h.id_discharge      := l_dsc_h.id_discharge;
                l_dsd_h.id_discharge_hist := l_dsc_h.id_discharge_hist;
            
                l_ret := set_disposition_dsd_h(i_lang, i_prof, l_dsd_h, 'N', l_dsd_h.id_discharge_detail_hist, o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_for_all;
                END IF;
            END IF;
        ELSIF l_flg_market = pk_discharge_core.g_disch_type_pt
        THEN
            BEGIN
                g_error := 'select l_dsc_h';
                SELECT dh.*
                  INTO l_dsc_h
                  FROM discharge_hist dh
                 WHERE dh.id_discharge = dsc.id_discharge
                   AND dh.flg_status_hist IN
                       (pk_discharge_core.g_disch_status_active, pk_discharge_core.g_disch_status_pend);
            
                g_error := 'set outdated';
                l_ret   := set_outdated(i_lang, i_prof, i_id_episode, o_error);
            
                g_error                 := 'set_disposition_dsc_h';
                l_dsc_h.flg_status      := i_flg_status;
                l_dsc_h.flg_status_hist := i_flg_status;
                l_ret                   := set_disposition_dsc_h(i_lang,
                                                                 i_prof,
                                                                 l_dsc_h,
                                                                 g_no,
                                                                 l_dsc_h.id_discharge_hist,
                                                                 o_error);
            EXCEPTION
                WHEN OTHERS THEN
                    l_dsc_h.id_discharge_hist := NULL;
            END;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_REOPEN_DISPOSITION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_REOPEN_DISPOSITION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_reopen_disposition;

    FUNCTION set_end_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        -- denormalization variables
        l_rowids table_varchar;
    BEGIN
        ts_episode.upd(id_episode_in  => i_id_episode,
                       flg_status_in  => g_inactive,
                       dt_end_tstz_in => current_timestamp,
                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_END_EPISODE',
                                              o_error);
            RETURN FALSE;
    END set_end_episode;

    FUNCTION set_end_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count    NUMBER;
        l_id_visit visit.id_visit%TYPE;
        l_ret      BOOLEAN;
    
        l_prof_cat category.flg_type%TYPE;
    BEGIN
    
        SELECT id_visit
          INTO l_id_visit
          FROM episode
         WHERE id_episode = i_id_episode;
    
        SELECT COUNT(*)
          INTO l_count
          FROM episode
         WHERE id_visit = l_id_visit
           AND flg_status = g_active;
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        -- if no episode is active then close visit
        IF l_count = 0
        THEN
        
            l_ret := pk_visit.set_visit_end(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_prof_cat_type => l_prof_cat,
                                            i_id_visit      => l_id_visit,
                                            o_error         => o_error);
            IF l_ret = FALSE
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'PK_DIET.SET_DIET_INTERRUPT';
            IF NOT
                pk_diet.set_diet_interrupt(i_lang => i_lang, i_prof => i_prof, i_visit => l_id_visit, o_error => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_END_VISIT',
                                              o_error);
            RETURN FALSE;
    END set_end_visit;

    /***************************************************************************************************
    * AUXILLIARY method. Checks if discharge can be cancelled from the medical discharge list screen.
    *
    * @param   i_lang              Language ID
    * @param   i_prof              Professional info
    * @param   i_id_prof_med       Medical discharge professional
    * @param   i_id_prof_adm       Administrative discharge professional
    * @param   i_flg_status        Discharge status
    * @param   i_cancel_allowed    Value of 'CANCEL_ADMINISTRATIVE_DISCHARGE'
    * @param   i_cancel_allowed_pp Value of 'PRIV_CANCEL_DISPOSITION'
    * @param   i_end_epis_on_disch Value of 'END_EPISODE_ON_DISCHARGE'
    *
    * @RETURN  1 if can be cancelled, 0 otherwise
    *
    * @author  José Brito
    * @version 2.6.0.3
    * @since   24/09/2010
    *
    ***************************************************************************************************/
    FUNCTION can_cancel_us_discharge
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_med       IN discharge_hist.id_prof_med%TYPE,
        i_id_prof_adm       IN discharge_hist.id_prof_admin%TYPE,
        i_flg_status        IN discharge_hist.flg_status%TYPE,
        i_cancel_allowed    IN sys_config.value%TYPE,
        i_cancel_allowed_pp IN sys_config.value%TYPE,
        i_end_epis_on_disch IN sys_config.value%TYPE
    ) RETURN VARCHAR2 IS
        l_can_cancel_us_discharge VARCHAR2(1 CHAR) := 'N';
    BEGIN
    
        IF i_flg_status = g_pendente
        THEN
            -- Discharge records in PENDING status can be cancelled
            l_can_cancel_us_discharge := 'Y';
        
        ELSIF i_flg_status = g_active
              AND i_prof.software = pk_alert_constant.g_soft_private_practice
        THEN
            -- Discharge records, in ALERT® Private Practice, can be cancelled according to this configuration.
            l_can_cancel_us_discharge := i_cancel_allowed_pp;
        
        ELSIF i_id_prof_med = i_id_prof_adm
              OR (i_end_epis_on_disch = pk_alert_constant.g_no AND i_id_prof_med = i_prof.id)
        THEN
            -- Medical/administrative discharge records, in other softwares, 
            -- can be cancelled according to this configuration.
            l_can_cancel_us_discharge := i_cancel_allowed;
        END IF;
    
        RETURN l_can_cancel_us_discharge;
    END can_cancel_us_discharge;

    /*
    * Get summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_FLG_SHOW Show pop-up with error or warning message (Y/N)
    * @param   O_MSG_TITLE Message title
    * @param   O_MSG_TEXT Error or warning text
    * @param   O_BUTTON Button to display on the pop-up
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    * @Updated by Gisela Couto
    * @since   22-04-2014
    *
    */
    FUNCTION get_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        o_info                 OUT pk_types.cursor_type,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_text             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_newborn_reg          OUT pk_types.cursor_type,
        o_newborn              OUT pk_types.cursor_type,
        o_sync_client_registry OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_create VARCHAR2(1 CHAR);
    BEGIN
        RETURN pk_disposition.get_summary(i_lang                 => i_lang,
                                          i_prof                 => i_prof,
                                          i_id_episode           => i_id_episode,
                                          i_flg_type             => NULL,
                                          o_info                 => o_info,
                                          o_flg_show             => o_flg_show,
                                          o_msg_title            => o_msg_title,
                                          o_msg_text             => o_msg_text,
                                          o_button               => o_button,
                                          o_newborn_reg          => o_newborn_reg,
                                          o_newborn              => o_newborn,
                                          o_flg_create           => l_flg_create,
                                          o_sync_client_registry => o_sync_client_registry,
                                          o_error                => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_newborn_reg);
            pk_types.open_my_cursor(o_newborn);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary;

    FUNCTION get_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_flg_type             IN VARCHAR2,
        o_info                 OUT pk_types.cursor_type,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_text             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_newborn_reg          OUT pk_types.cursor_type,
        o_newborn              OUT pk_types.cursor_type,
        o_flg_create           OUT VARCHAR2,
        o_sync_client_registry OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sep VARCHAR2(0050);
        l_hif VARCHAR2(0050);
    
        tit_pat_condition       sys_message.desc_message%TYPE;
        tit_med_reconcile       sys_message.desc_message%TYPE;
        tit_prescription_given  sys_message.desc_message%TYPE;
        tit_discharge_date_time sys_message.desc_message%TYPE;
    
        tit_add_notes         sys_message.desc_message%TYPE;
        tit_flg_written_notes sys_message.desc_message%TYPE;
    
        tit_admiting_physician  sys_message.desc_message%TYPE;
        tit_admission_orders    sys_message.desc_message%TYPE;
        tit_admit_to_room       sys_message.desc_message%TYPE;
        tit_flg_check_valuables sys_message.desc_message%TYPE;
    
        tit_reason_of_transfer     sys_message.desc_message%TYPE;
        tit_trf_mode_transport     sys_message.desc_message%TYPE;
        tit_dt_trf_mode_transport  sys_message.desc_message%TYPE;
        tit_risk_of_transfer       sys_message.desc_message%TYPE;
        tit_benefits_of_transfer   sys_message.desc_message%TYPE;
        tit_accepting_physician    sys_message.desc_message%TYPE;
        tit_dt_accepting_physician sys_message.desc_message%TYPE;
        tit_en_route_orders        sys_message.desc_message%TYPE;
        tit_patient_consent        sys_message.desc_message%TYPE;
        tit_acceptance_facility    sys_message.desc_message%TYPE;
        tit_admitting_room         sys_message.desc_message%TYPE;
        tit_room_assigned_by       sys_message.desc_message%TYPE;
        tit_flg_items_sent_patient sys_message.desc_message%TYPE;
        tit_report_given           sys_message.desc_message%TYPE;
    
        tit_autopsy_consent            sys_message.desc_message%TYPE;
        tit_dt_death                   sys_message.desc_message%TYPE;
        tit_prf_declared_death         sys_message.desc_message%TYPE;
        tit_flg_orgn_donation_agency   sys_message.desc_message%TYPE;
        tit_flg_report_of_death        sys_message.desc_message%TYPE;
        tit_flg_coroner_contacted      sys_message.desc_message%TYPE;
        tit_coroner_name               sys_message.desc_message%TYPE;
        tit_flg_funeral_home_contacted sys_message.desc_message%TYPE;
        tit_funeral_home_name          sys_message.desc_message%TYPE;
        tit_dt_body_removed            sys_message.desc_message%TYPE;
        tit_death_characterization     sys_message.desc_message%TYPE;
        tit_death_process_registration sys_message.desc_message%TYPE;
    
        tit_risk_of_leaving         sys_message.desc_message%TYPE;
        tit_advised_risk_of_leaving sys_message.desc_message%TYPE;
        tit_dt_ama                  sys_message.desc_message%TYPE;
        tit_signed_ama_form         sys_message.desc_message%TYPE;
        tit_mse                     sys_message.desc_message%TYPE;
        --
        tit_flg_instructions_discussed sys_message.desc_message%TYPE;
        tit_instructions_understood    sys_message.desc_message%TYPE;
        tit_written_instructions       sys_message.desc_message%TYPE;
        tit_vs_taken                   sys_message.desc_message%TYPE;
        tit_intake_output              sys_message.desc_message%TYPE;
        tit_flg_patient_transport      sys_message.desc_message%TYPE;
        tit_flg_pat_escorted_by        sys_message.desc_message%TYPE;
    
        tit_instructions_provided   sys_message.desc_message%TYPE;
        tit_prescription_given_to   sys_message.desc_message%TYPE;
        tit_next_visit_with         sys_message.desc_message%TYPE;
        tit_next_visit              sys_message.desc_message%TYPE;
        tit_instructions_next_visit sys_message.desc_message%TYPE;
        tit_type_of_visit           sys_message.desc_message%TYPE;
        tit_reason_for_nxt_visit    sys_message.desc_message%TYPE;
        tit_notes_registrar         sys_message.desc_message%TYPE;
        tit_service_level           sys_message.desc_message%TYPE;
        tit_sched_for               sys_message.desc_message%TYPE;
        tit_prop_for                sys_message.desc_message%TYPE;
        tit_notes_cancellation      sys_message.desc_message%TYPE;
        tit_admitting_doctor        sys_message.desc_message%TYPE;
        tit_written_by              sys_message.desc_message%TYPE;
        tit_flg_compulsory          sys_message.desc_message%TYPE;
        tit_id_compulsory_reason    sys_message.desc_message%TYPE;
        tit_admission               sys_message.desc_message%TYPE;
        tit_admission_date          sys_message.desc_message%TYPE;
    
        tit_co_sign_type sys_message.desc_message%TYPE;
        tit_co_sign_by   sys_message.desc_message%TYPE;
        tit_co_sign_dt   sys_message.desc_message%TYPE;
    
        tit_reason_for_visit sys_message.desc_message%TYPE;
    
        tit_print_report pk_translation.t_desc_translation;
        err_report_label EXCEPTION;
    
        tit_flg_surgery sys_message.desc_message%TYPE;
        tit_dt_surgery  sys_message.desc_message%TYPE;
        tit_dcs_admit   sys_message.desc_message%TYPE;
        tit_disch_type  sys_message.desc_message%TYPE;
    
        l_disch_letter_list_exception VARCHAR2(0500);
        l_priv_cancel_disposition     VARCHAR2(0500);
        l_cosign_disp                 VARCHAR2(0500);
        l_cosign_count                NUMBER(6);
    
        l_prof_cat category.flg_type%TYPE;
        l_cur      pk_cpt_code.cpt_code_cur;
        l_rec      pk_cpt_code.cpt_code_rec;
        l_label_na sys_message.desc_message%TYPE;
    
        l_cancel_allowed           sys_config.value%TYPE;
        l_end_episode_on_discharge sys_config.value%TYPE;
        l_show_other_prof          sys_config.value%TYPE;
        l_show_written_by          sys_config.value%TYPE;
        l_show_flg_compulsory      sys_config.value%TYPE;
        l_print_config             v_print_list_cfg.flg_print_option_default%TYPE;
    
        l_active_disch     discharge.id_discharge%TYPE;
        l_sm_newborn_title sys_message.desc_message%TYPE;
        l_sm_newborn       sys_message.desc_message%TYPE;
        l_sc_newborn       sys_config.value%TYPE;
    
        tit_institution    sys_message.desc_message%TYPE;
        l_sc_clues         sys_config.value%TYPE;
        l_adm_separate     VARCHAR2(2 CHAR) := pk_sysconfig.get_config('DISCHARGE_ADMISSION_SEPARATE', i_prof);
        l_flg_type         VARCHAR2(1 CHAR);
        l_exists_discharge VARCHAR2(1 CHAR);
        l_type_disch       VARCHAR2(1 CHAR);
        l_epis_type        episode.id_epis_type%TYPE;
    
        l_sa_client_registry sys_config.value%TYPE;
        l_health_id_count    NUMBER(6);
        l_has_cpt            VARCHAR2(1 CHAR);
        l_area_access        ehr_access_area_def.area%TYPE := 'INP_EPIS';
        l_acess_permission   VARCHAR2(1 CHAR);
    
    BEGIN
    
        -- Check if dispostion without co-sign is allowed
        l_cosign_disp := pk_sysconfig.get_config('ALLOW_DISPOSITION_WITHOUT_COSIGN', i_prof);
        l_prof_cat    := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_cosign_disp = g_no
           AND l_prof_cat <> g_adm_cat
        THEN
            -- Check if there are tasks with pending co-sign
            SELECT COUNT(1)
              INTO l_cosign_count
              FROM TABLE(pk_co_sign_api.tf_pending_co_sign_tasks(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_id_episode)) c
             WHERE c.id_task_type NOT IN (pk_alert_constant.g_task_discharge_admission,
                                          pk_alert_constant.g_task_discharge_home,
                                          pk_alert_constant.g_task_discharge_transfer,
                                          pk_alert_constant.g_task_discharge_mse,
                                          pk_alert_constant.g_task_discharge_ama,
                                          pk_alert_constant.g_task_discharge_lwbs,
                                          pk_alert_constant.g_task_discharge_expired,
                                          pk_alert_constant.g_task_discharge_follow);
        
            IF l_cosign_count > 0
            THEN
                -- There are tasks with pending co-sign. Execution is stopped, so that
                -- the application returns to the co-sign screen.
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'DISPOSITION_NOCOSIGN_T001');
                IF i_flg_type IS NOT NULL
                THEN
                    o_msg_text := pk_message.get_message(i_lang, 'DISPOSITION_NOCOSIGN_M002');
                ELSE
                    o_msg_text := pk_message.get_message(i_lang, 'DISPOSITION_NOCOSIGN_M001');
                END IF;
                o_button := 'C';
                pk_types.open_my_cursor(o_info);
                RETURN TRUE;
            ELSE
                o_flg_show := 'N';
            END IF;
        END IF;
    
        g_error := 'CHECK CPT_CODE';
        IF NOT pk_cpt_code.get_cpt_code_list(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_cur        => l_cur,
                                             o_error      => o_error)
        THEN
            RAISE err_report_label;
        END IF;
    
        g_error := 'FETCH CPT_CODE';
        FETCH l_cur
            INTO l_rec;
    
        IF l_cur%NOTFOUND
        THEN
            l_label_na := pk_message.get_message(i_lang, i_prof, 'COMMON_M036');
        END IF;
    
        CLOSE l_cur;
    
        IF i_flg_type IS NOT NULL
           AND l_adm_separate = pk_alert_constant.g_yes
        THEN
            l_flg_type := i_flg_type;
        END IF;
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        l_priv_cancel_disposition := pk_sysconfig.get_config('PRIV_CANCEL_DISPOSITION', i_prof);
        l_show_other_prof         := pk_sysconfig.get_config('DISCHARGE_ADMISSION_OTHER_PROFESSIONAL', i_prof);
        l_show_written_by         := pk_sysconfig.get_config('DISCHARGE_ADMISSION_WRITTEN_BY', i_prof);
        l_show_flg_compulsory     := pk_sysconfig.get_config('ADMISSION_ORDER_COMPULSORY_ENABLED', i_prof);
    
        l_sep                   := ': ';
        l_hif                   := ' - ';
        tit_pat_condition       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T003');
        tit_med_reconcile       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T006');
        tit_prescription_given  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T007');
        tit_discharge_date_time := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T008');
    
        tit_instructions_provided   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T010');
        tit_prescription_given_to   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T011');
        tit_next_visit_with         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T012');
        tit_next_visit              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T013');
        tit_instructions_next_visit := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T014');
        tit_type_of_visit           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T015');
        tit_reason_for_nxt_visit    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T016');
        tit_notes_registrar         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T017');
        tit_service_level           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T018');
        tit_sched_for               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T019');
        tit_prop_for                := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T020');
    
        tit_add_notes         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T005');
        tit_flg_written_notes := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T008');
    
        tit_admiting_physician   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T003');
        tit_admission_orders     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T007');
        tit_admit_to_room        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T008');
        tit_flg_check_valuables  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T009');
        tit_admitting_doctor     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T013');
        tit_written_by           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T019');
        tit_flg_compulsory       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T021');
        tit_id_compulsory_reason := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T024');
        tit_admission            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T010');
        tit_admission_date       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T011');
    
        tit_reason_of_transfer     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T008');
        tit_trf_mode_transport     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T009');
        tit_dt_trf_mode_transport  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T010');
        tit_risk_of_transfer       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T011');
        tit_benefits_of_transfer   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T012');
        tit_accepting_physician    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T003');
        tit_dt_accepting_physician := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T013');
        tit_en_route_orders        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T014');
        tit_patient_consent        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T015');
        tit_acceptance_facility    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T016');
        tit_admitting_room         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T017');
        tit_room_assigned_by       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T018');
        tit_flg_items_sent_patient := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T019');
        tit_report_given           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T020');
    
        tit_autopsy_consent            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T001');
        tit_dt_death                   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T007');
        tit_prf_declared_death         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T008');
        tit_flg_orgn_donation_agency   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T009');
        tit_flg_report_of_death        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T010');
        tit_flg_coroner_contacted      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T011');
        tit_coroner_name               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T012');
        tit_flg_funeral_home_contacted := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T013');
        tit_funeral_home_name          := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T014');
        tit_dt_body_removed            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T015');
        tit_death_characterization     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T017');
        tit_death_process_registration := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T018');
    
        tit_risk_of_leaving         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T006');
        tit_advised_risk_of_leaving := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T007');
        tit_dt_ama                  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T008');
        tit_signed_ama_form         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T008');
        tit_mse                     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_MSE_T001');
        --
        tit_flg_instructions_discussed := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T006');
        tit_instructions_understood    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T007');
        tit_written_instructions       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T008');
        tit_vs_taken                   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T009');
        tit_intake_output              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T010');
        tit_flg_patient_transport      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T011');
        tit_flg_pat_escorted_by        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T012');
    
        tit_reason_for_visit := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_LWBS_T006');
    
        tit_notes_cancellation := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQ_T007');
    
        tit_flg_surgery := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T032');
        tit_dt_surgery  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T033');
        tit_dcs_admit   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T004');
        tit_disch_type  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T005');
    
        l_sm_newborn_title := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T169');
        l_sm_newborn       := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T176');
        l_sc_newborn       := pk_sysconfig.get_config('DISCHARGE_NEWBORN', i_prof);
    
        tit_institution := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T090');
        l_sc_clues      := pk_sysconfig.get_config('DISCHARGE_TRANSFER_CLUES', i_prof);
    
        -- DISCHARGE ADMISSION CO-SIGN    
        tit_co_sign_type := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_M023');
        tit_co_sign_by   := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_T003');
        tit_co_sign_dt   := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_M021');
    
        g_error := 'GET PRINT REPORT LABEL';
        IF NOT pk_discharge.get_report_label(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             o_label        => tit_print_report,
                                             o_print_config => l_print_config,
                                             o_error        => o_error)
        THEN
            RAISE err_report_label;
        END IF;
    
        -- Is it allowed to cancel the administrative discharge?
        l_cancel_allowed := pk_sysconfig.get_config('CANCEL_ADMINISTRATIVE_DISCHARGE',
                                                    i_prof.institution,
                                                    i_prof.software);
    
        -- Check if "2 in 1" discharge is active. 
        l_end_episode_on_discharge := pk_sysconfig.get_config('END_EPISODE_ON_DISCHARGE',
                                                              i_prof.institution,
                                                              i_prof.software);
    
        IF NOT pk_discharge.check_exists_disch_type(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_episode     => i_id_episode,
                                                    i_flg_type    => i_flg_type,
                                                    o_exist_disch => l_exists_discharge,
                                                    o_type        => l_type_disch,
                                                    o_error       => o_error)
        THEN
            RAISE err_report_label;
        END IF;
        l_has_cpt := pk_cpt_code.check_has_cpt_cfg(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_id_episode);
        g_error     := 'GET CURSOR';
        OPEN o_info FOR
            SELECT l_disch_letter_list_exception letter_list_exception,
                   can_cancel_us_discharge(i_lang,
                                           i_prof,
                                           dh.id_prof_med,
                                           dh.id_prof_admin,
                                           dh.flg_status,
                                           l_cancel_allowed,
                                           l_priv_cancel_disposition,
                                           l_end_episode_on_discharge) l_can_cancel_disposition,
                   -- José Brito 09/01/2009 ALERT-13049
                   -- Only nurses can edit disposition of type "Left without being seen" (LWBS).
                   --decode(dff.flg_type, g_disp_lwbs, decode(l_prof_cat, g_nurse, g_yes, g_no), g_yes) can_edit,
                   g_yes can_edit, -- After 2.5, physician can also edit LWBS disposition
                   --
                   
                   decode(dh.flg_status,
                          'A',
                          decode(nvl(dh.id_prof_pend_active, -999),
                                 -999,
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             dh.dt_created_hist,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             dh.dt_pend_active_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          'P',
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_pend_tstz, i_prof.institution, i_prof.software),
                          'C',
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_cancel_tstz, i_prof.institution, i_prof.software),
                          'R',
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_created_hist, i_prof.institution, i_prof.software)) rec_date,
                   
                   decode(dh.flg_status,
                          'A',
                          decode(nvl(dh.id_prof_pend_active, -999),
                                 -999,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_pend_active)),
                          'P',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist),
                          'C',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_cancel),
                          'R',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist)) rec_name,
                   
                   decode(dh.flg_status,
                          'A',
                          
                          decode(nvl(dh.id_prof_pend_active, -999),
                                 -999,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  dh.id_prof_created_hist,
                                                                  dh.dt_created_hist,
                                                                  dh.id_episode),
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  dh.id_prof_pend_active,
                                                                  dh.dt_pend_active_tstz,
                                                                  dh.id_episode)),
                          'P',
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           dh.id_prof_created_hist,
                                                           dh.dt_pend_tstz,
                                                           dh.id_episode),
                          'C',
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           dh.id_prof_cancel,
                                                           dh.dt_cancel_tstz,
                                                           dh.id_episode),
                          'R',
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           dh.id_prof_created_hist,
                                                           dh.dt_created_hist,
                                                           dh.id_episode)) spec_name,
                   dh.id_discharge id_discharge,
                   drd.id_disch_reas_dest id_disch_reas_dest,
                   drd.id_discharge_reason,
                   drd.id_department,
                   dh.flg_status flg_status,
                   dh.flg_status_hist flg_status_hist,
                   dh.id_discharge_hist id_discharge_hist,
                   nvl(dff.file_name,
                       decode(dh.flg_status,
                              'A',
                              'DispositionAdministrativeDischargeInactive.swf',
                              'C',
                              'DispositionAdministrativeDischargeInactive.swf',
                              dff.file_name)) file_to_execute,
                   nvl(dff2.file_name,
                       decode(dh.flg_status,
                              'A',
                              'DispositionAdministrativeDischargeInactive.swf',
                              'C',
                              'DispositionAdministrativeDischargeInactive.swf',
                              dff2.file_name)) file_to_execute_secondary,
                   dff.flg_type disposition_flg_type,
                   decode(sch.id_schedule, NULL, decode(creq.id_consult_req, NULL, 'N', 'P'), 'S') flg_date_type,
                   decode(dh.flg_status,
                          g_disch_act,
                          '',
                          -- José Brito 04/03/2009 ALERT-10317
                          -- If patient refused to be transfered, the disposition
                          -- must show 'REFUSED' instead of 'CANCELLED'.
                          g_disch_flg_cancel,
                          decode(dh.flg_cancel_type,
                                 pk_alert_constant.g_disch_flgcanceltype_r,
                                 upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_CANCEL_TYPE',
                                                               dh.flg_cancel_type,
                                                               i_lang)),
                                 upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang))),
                          --
                          upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang))) desc_flg_status,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          pk_translation.get_translation(i_lang, dr.code_discharge_reason) || l_sep ||
                          decode(dff.flg_type,
                                 g_disp_tran,
                                 nvl(ddh.acceptance_facility,
                                     pk_translation.get_translation(i_lang,
                                                                    nvl(ins.code_institution, dd.code_discharge_dest))),
                                 decode(nvl(drd.id_discharge_dest, 0),
                                        0,
                                        decode(nvl(drd.id_dep_clin_serv, 0),
                                               0,
                                               decode(nvl(drd.id_institution, 0),
                                                      0,
                                                      pk_translation.get_translation(i_lang, dpt.code_department),
                                                      pk_translation.get_translation(i_lang, ins.code_institution)),
                                               nvl2(drd.id_department,
                                                    pk_translation.get_translation(i_lang, dpt.code_department) || ' - ',
                                                    '') ||
                                               pk_translation.get_translation(i_lang,
                                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                              dcs3.id_clinical_service)),
                                        pk_translation.get_translation(i_lang, dd.code_discharge_dest)))) l_disposition,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          g_disp_tran,
                          nvl(ddh.acceptance_facility,
                              pk_translation.get_translation(i_lang, nvl(ins.code_institution, dd.code_discharge_dest))),
                          get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest)) l_to,
                   dh.id_discharge_status,
                   decode(dff.flg_type, g_disp_adms, tit_admission, tit_disch_type) || l_sep ||
                   get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          g_disp_expi,
                          NULL,
                          g_disp_foll,
                          NULL,
                          tit_pat_condition || l_sep ||
                          pk_discharge.get_patient_condition(i_lang,
                                                             i_prof,
                                                             dh.id_discharge,
                                                             dr.id_discharge_reason,
                                                             ddh.flg_pat_condition)) pat_condition,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang),
                          g_disp_ama,
                          tit_risk_of_leaving || l_sep || ddh.risk_of_leaving,
                          g_disp_expi,
                          tit_dt_death || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software),
                          -- José Brito 27/06/2008 Disposition workflow review
                          g_disp_tran,
                          tit_reason_of_transfer || l_sep ||
                          nvl(ddh.reason_of_transfer_desc,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.REASON_OF_TRANSFER',
                                                      ddh.reason_of_transfer,
                                                      i_lang)),
                          --
                          g_disp_mse,
                          tit_mse || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL.MSE_TYPE', ddh.mse_type, i_lang),
                          g_disp_foll,
                          tit_next_visit || l_sep ||
                          decode(ddh.id_schedule,
                                 NULL,
                                 decode(ddh.id_consult_req,
                                        NULL,
                                        ddh.next_visit_scheduled,
                                        decode(creq.dt_scheduled_tstz,
                                               NULL,
                                               ddh.next_visit_scheduled,
                                               tit_prop_for || l_sep ||
                                               pk_date_utils.dt_chr_tsz(i_lang,
                                                                        creq.dt_scheduled_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))),
                                 tit_sched_for || l_sep ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             sch.dt_schedule_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          g_disp_adms,
                          -- José Brito 27/06/2008 Disposition workflow review
                          tit_admiting_physician || l_sep ||
                          nvl((SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_admitting)
                                FROM dual),
                              ddh.prof_admitting_desc),
                          --
                          g_disp_lwbs,
                          tit_reason_for_visit || l_sep || ddh.reason_for_leaving) field01,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang),
                          g_disp_ama,
                          tit_advised_risk_of_leaving || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang),
                          g_disp_mse,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang),
                          g_disp_tran,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang),
                          g_disp_expi,
                          tit_prf_declared_death || l_sep || ddh.prf_declared_death,
                          g_disp_adms,
                          decode(dff.flg_type, g_disp_adms, tit_admission_date, tit_discharge_date_time) || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software),
                          g_disp_foll,
                          tit_next_visit_with || l_sep ||
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_assigned_to)
                             FROM dual),
                          g_disp_lwbs,
                          tit_advised_risk_of_leaving || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang)) field02,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_type_of_visit || l_sep ||
                          pk_translation.get_translation(i_lang, cli.code_clinical_service),
                          g_disp_home,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software),
                          g_disp_ama,
                          tit_dt_ama || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, ddh.dt_ama_tstz, i_prof.institution, i_prof.software),
                          g_disp_mse,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang),
                          g_disp_tran,
                          tit_trf_mode_transport || l_sep ||
                          decode(ddh.flg_transfer_transport,
                                 l_disch_letter_list_exception,
                                 ddh.desc_transfer_transport,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_TRANSFER_TRANSPORT',
                                                         ddh.flg_transfer_transport,
                                                         i_lang)),
                          g_disp_expi,
                          tit_autopsy_consent || l_sep || ddh.autopsy_consent_desc,
                          g_disp_adms,
                          tit_admit_to_room || l_sep ||
                          get_room_admit(i_lang, i_prof, ddh.id_room_admit, ddh.admit_to_room),
                          g_disp_lwbs,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang))) field03,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_reason_for_nxt_visit || l_sep ||
                          pk_translation.get_translation(i_lang, cmp.code_complaint),
                          g_disp_home,
                          tit_flg_instructions_discussed || l_sep ||
                          decode(ddh.flg_instructions_discussed,
                                 l_disch_letter_list_exception,
                                 ddh.instructions_discussed_notes,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                         ddh.flg_instructions_discussed,
                                                         i_lang)),
                          g_disp_ama,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang),
                          g_disp_tran,
                          tit_dt_trf_mode_transport || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_transfer_transport_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          g_disp_expi,
                          tit_flg_orgn_donation_agency || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_orgn_donation_agency, i_lang),
                          g_disp_mse,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software),
                          g_disp_adms,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang),
                          -- José Brito 27/06/2008 Disposition workflow review
                          g_disp_lwbs,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software)) field04,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_instructions_next_visit || l_sep ||
                          decode(ddh.flg_instructions_next_visit,
                                 l_disch_letter_list_exception,
                                 ddh.desc_instructions_next_visit,
                                 pk_sysdomain.get_domain('SCHEDULE.FLG_INSTRUCTIONS',
                                                         ddh.flg_instructions_next_visit,
                                                         i_lang)),
                          g_disp_home,
                          tit_instructions_understood || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang),
                          g_disp_ama,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang)),
                          g_disp_tran,
                          tit_risk_of_transfer || l_sep || ddh.risk_of_transfer,
                          g_disp_expi,
                          tit_flg_report_of_death || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_report_of_death, i_lang),
                          g_disp_mse,
                          tit_flg_instructions_discussed || l_sep ||
                          decode(ddh.flg_instructions_discussed,
                                 l_disch_letter_list_exception,
                                 ddh.instructions_discussed_notes,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                         ddh.flg_instructions_discussed,
                                                         i_lang)),
                          g_disp_adms,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang)) field05,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_instructions_provided || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.pat_instructions_provided, i_lang),
                          g_disp_home,
                          tit_flg_written_notes || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang),
                          g_disp_ama,
                          tit_signed_ama_form || l_sep ||
                          decode(ddh.flg_signed_ama_form,
                                 l_disch_letter_list_exception,
                                 ddh.desc_signed_ama_form,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_SIGNED_AMA_FORM',
                                                         ddh.flg_signed_ama_form,
                                                         i_lang)),
                          g_disp_tran,
                          tit_benefits_of_transfer || l_sep || ddh.benefits_of_transfer,
                          g_disp_expi,
                          tit_flg_coroner_contacted || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_coroner_contacted, i_lang),
                          g_disp_mse,
                          tit_instructions_understood || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang),
                          g_disp_adms,
                          tit_flg_check_valuables || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_check_valuables, i_lang)) field06,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang),
                          g_disp_home,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang),
                          g_disp_tran,
                          tit_accepting_physician || l_sep || ddh.prof_admitting_desc,
                          g_disp_expi,
                          tit_coroner_name || l_sep || ddh.coroner_name,
                          g_disp_adms,
                          tit_admission_orders || l_sep || ddh.admission_orders,
                          g_disp_mse,
                          tit_flg_written_notes || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang),
                          -- José Brito 27/06/2008 Disposition workflow review
                          g_disp_ama,
                          tit_reason_for_visit || l_sep || ddh.reason_for_leaving) field07,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_flg_compulsory,
                                 pk_alert_constant.g_yes,
                                 tit_flg_compulsory || l_sep ||
                                 pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                         i_val      => ddh.flg_compulsory,
                                                         i_lang     => i_lang),
                                 NULL),
                          NULL) field08,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_flg_compulsory,
                                 pk_alert_constant.g_yes,
                                 decode(ddh.id_compulsory_reason,
                                        -1,
                                        tit_id_compulsory_reason || l_sep || (pk_api_multichoice.get_multichoice_option_desc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             ddh.id_compulsory_reason) ||
                                        l_hif || ddh.compulsory_reason),
                                        tit_id_compulsory_reason || l_sep ||
                                        pk_api_multichoice.get_multichoice_option_desc(i_lang,
                                                                                       i_prof,
                                                                                       ddh.id_compulsory_reason)),
                                 NULL),
                          NULL) field09,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_prescription_given_to || l_sep ||
                          decode(ddh.flg_prescription_given_to,
                                 l_disch_letter_list_exception,
                                 ddh.desc_prescription_given_to,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PRESCRIPTION_GIVEN_TO',
                                                         ddh.flg_prescription_given_to,
                                                         i_lang)),
                          g_disp_home,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang),
                          g_disp_tran,
                          tit_dt_accepting_physician || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_prof_admiting_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          g_disp_expi,
                          tit_flg_funeral_home_contacted || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_funeral_home_contacted, i_lang),
                          g_disp_mse,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang),
                          -- José Brito 27/06/2008 Disposition workflow review
                          g_disp_adms,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang)) field10,
                   decode(dff.flg_type,
                          g_disp_foll,
                          tit_flg_instructions_discussed || l_sep || ddh.instructions_discussed_notes,
                          g_disp_home,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang),
                          g_disp_tran,
                          tit_en_route_orders || l_sep || ddh.en_route_orders,
                          g_disp_expi,
                          tit_funeral_home_name || l_sep || ddh.funeral_home_name,
                          g_disp_mse,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang)) field11,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 -- José Brito 27/06/2008 Disposition workflow review
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY_2',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang)),
                          g_disp_tran,
                          tit_patient_consent || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_CONSENT',
                                                  ddh.flg_patient_consent,
                                                  i_lang),
                          g_disp_expi,
                          tit_dt_body_removed || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_body_removed_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          g_disp_mse,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang)) field12,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_acceptance_facility || l_sep || ddh.acceptance_facility,
                          g_disp_expi,
                          tit_death_process_registration || l_sep || ddh.death_process_registration,
                          g_disp_mse,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 -- José Brito 27/06/2008 Disposition workflow review
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY_2',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang))) field13,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_admitting_room || l_sep || ddh.admitting_room,
                          g_disp_foll,
                          tit_notes_registrar || l_sep || ddh.notes) field14,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_room_assigned_by || l_sep || ddh.room_assigned_by,
                          g_disp_foll,
                          decode(dh.flg_status, g_cancel, tit_notes_cancellation || l_sep || dh.notes_cancel, '')) field15,
                   decode(dff.flg_type, g_disp_tran, tit_flg_items_sent_patient || l_sep || ddh.items_sent_with_patient) field16,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang)) field17,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang)) field18,
                   -- José Brito 27/06/2008 Disposition workflow review
                   decode(dff.flg_type, g_disp_tran, tit_report_given || l_sep || ddh.report_given_to) field19,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software)) field20,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          decode(l_has_cpt,
                                 pk_alert_constant.g_yes,
                                 tit_service_level || l_sep || nvl(cc.medium_desc, l_label_na))) level_of_service,
                   --
                   tit_add_notes || l_sep ||
                   decode(dh.flg_status_adm,
                          'A',
                          decode(dh.id_prof_med, dh.id_prof_admin, dh.notes_med, dh.notes_admin),
                          nvl(dh.notes_med, dh.notes_admin)) additional_notes,
                   -- AS 14-12-2009 (ALERT-62112)
                   tit_print_report report_label,
                   ddh.flg_print_report,
                   pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                   --
                   decode(dff.flg_type,
                          g_disp_adms,
                          tit_dcs_admit || l_sep ||
                          pk_translation.get_translation(i_lang,
                                                         'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                         dcs2.id_clinical_service),
                          NULL) desc_dcs_admit,
                   decode(dff.flg_type,
                          g_disp_adms,
                          tit_flg_surgery || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORIS', ddh.flg_surgery, i_lang),
                          NULL) desc_surgery,
                   decode(dff.flg_type,
                          g_disp_adms,
                          tit_dt_surgery || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, ddh.date_surgery_tstz, i_prof.institution, i_prof.software),
                          NULL) dt_surgery,
                   dh.flg_status_adm,
                   decode(dff.flg_type,
                          g_disp_expi,
                          tit_death_characterization || l_sep ||
                          pk_translation.get_translation_trs(i_code_mess => ddh.code_death_event),
                          NULL) death_characterization,
                   decode(dff.flg_type,
                          g_disp_tran,
                          decode(l_sc_clues,
                                 pk_alert_constant.g_yes,
                                 tit_institution || l_sep ||
                                 pk_translation.get_translation(i_lang, tinst.code_institution))) desc_inst_transfer,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_other_prof,
                                 pk_alert_constant.g_yes,
                                 tit_admitting_doctor || l_sep ||
                                 (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_admitting_doctor)
                                    FROM dual),
                                 NULL),
                          NULL) admitting_doctor,
                   CASE
                        WHEN ddh.id_co_sign IS NOT NULL THEN
                         tit_co_sign_type || l_sep || c.desc_order_type
                        ELSE
                         NULL
                    END order_type,
                   CASE
                        WHEN ddh.id_co_sign IS NOT NULL THEN
                         tit_co_sign_by || l_sep || c.desc_prof_ordered_by
                        ELSE
                         NULL
                    END order_by,
                   CASE
                        WHEN ddh.id_co_sign IS NOT NULL THEN
                         tit_co_sign_dt || l_sep ||
                         pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software)
                        ELSE
                         NULL
                    END order_dt,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_written_by,
                                 pk_alert_constant.g_yes,
                                 tit_written_by || l_sep ||
                                 (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_written_by)
                                    FROM dual),
                                 NULL),
                          NULL) written_by,
                   ddh.id_compulsory_reason,
                   decode(ddh.id_compulsory_reason,
                          NULL,
                          '',
                          -1,
                          ddh.compulsory_reason,
                          pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, ddh.id_compulsory_reason)) desc_id_compulsory_reason
            
            --
              FROM (SELECT dh.*
                      FROM discharge_hist dh
                     WHERE dh.flg_status = g_disch_reopen
                    UNION ALL
                    SELECT dh.*
                      FROM discharge_hist dh
                     WHERE dh.flg_status != g_disch_reopen
                       AND NOT EXISTS (SELECT 1
                              FROM discharge_hist dhr
                             WHERE dhr.id_discharge = dh.id_discharge
                               AND dhr.flg_status = 'R')) dh -- EMR-3004 (Avoid exibition of duplicated discharges when reopen)
              LEFT JOIN discharge_detail_hist ddh
                ON ddh.id_discharge_hist = dh.id_discharge_hist
              JOIN disch_reas_dest drd
                ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
              JOIN discharge_reason dr
                ON dr.id_discharge_reason = drd.id_discharge_reason
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ddh.id_dep_clin_serv_visit
              LEFT JOIN dep_clin_serv dcs2
                ON dcs2.id_dep_clin_serv = ddh.id_dep_clin_serv_admiting
              LEFT JOIN dep_clin_serv dcs3
                ON dcs3.id_dep_clin_serv = drd.id_dep_clin_serv
              LEFT JOIN clinical_service cli
                ON cli.id_clinical_service = dcs.id_clinical_service
              LEFT JOIN complaint cmp
                ON cmp.id_complaint = ddh.id_complaint
              LEFT JOIN discharge_dest dd
                ON dd.id_discharge_dest = drd.id_discharge_dest
              LEFT JOIN department dpt
                ON dpt.id_department = drd.id_department
              LEFT JOIN institution ins
                ON ins.id_institution = drd.id_institution
              LEFT JOIN cpt_code cc
                ON cc.id_cpt_code = dh.id_cpt_code
              LEFT JOIN schedule sch
                ON sch.id_schedule = ddh.id_schedule
              LEFT JOIN consult_req creq
                ON creq.id_consult_req = ddh.id_consult_req
            --A left join is made with discharge_flash_files to show all records even wrong ones
              LEFT JOIN discharge_flash_files dff
                ON dff.id_discharge_flash_files = dh.id_discharge_flash_files
              LEFT JOIN discharge_flash_files dff2
                ON dff2.id_discharge_flash_files = dff.id_dsch_flsh_files_assoc
              LEFT JOIN institution tinst
                ON tinst.id_institution = ddh.id_inst_transfer
              LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                ON c.id_co_sign = ddh.id_co_sign
             WHERE dh.id_episode = i_id_episode
               AND nvl(dff.flg_type, g_disp_other) = nvl(l_flg_type, nvl(dff.flg_type, g_disp_other))
               AND ((nvl(dff.flg_type, g_disp_other) <> g_disp_adms AND l_adm_separate = pk_alert_constant.g_yes AND
                   l_flg_type IS NULL) OR (l_adm_separate = pk_alert_constant.g_no) OR
                   (l_adm_separate = pk_alert_constant.g_yes AND l_flg_type = g_disp_adms))
             ORDER BY dh.dt_created_hist DESC;
    
        IF l_epis_type = pk_alert_constant.g_epis_type_inpatient
           AND l_flg_type = g_disp_adms
        THEN
            o_flg_create := pk_alert_constant.g_no;
        ELSE
            IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode,
                                                              i_area    => l_area_access,
                                                              o_val     => l_acess_permission,
                                                              o_error   => o_error)
            THEN
                RAISE err_report_label;
            END IF;
        
            IF l_acess_permission = pk_alert_constant.g_yes
            THEN
                IF l_exists_discharge = pk_alert_constant.g_yes
                THEN
                    IF (l_type_disch = l_flg_type AND l_flg_type IS NOT NULL)
                       OR (l_flg_type IS NULL AND l_type_disch <> g_disp_adms)
                    THEN
                        o_flg_create := pk_alert_constant.g_yes;
                    ELSE
                        o_flg_create := pk_alert_constant.g_no;
                        o_flg_show   := 'Y';
                        o_msg_title  := pk_message.get_message(i_lang, 'COMMON_M080');
                        IF l_type_disch = g_disp_adms
                        THEN
                            o_msg_text := pk_message.get_message(i_lang, 'DISCHARGE_ADMIT_T022');
                        
                        ELSE
                            o_msg_text := pk_message.get_message(i_lang, 'DISCHARGE_ADMIT_T023');
                        
                        END IF;
                        o_button := 'NC';
                    END IF;
                ELSE
                    o_flg_create := pk_alert_constant.g_yes;
                END IF;
            
            ELSE
                o_flg_create := pk_alert_constant.g_no;
            END IF;
        END IF;
        IF l_sc_newborn = pk_alert_constant.g_yes
        THEN
            g_error := 'GET ACTIVE DISCHARGE';
            BEGIN
                SELECT d.id_discharge
                  INTO l_active_disch
                  FROM discharge d
                 WHERE d.id_episode = i_id_episode
                   AND d.flg_status = pk_alert_constant.g_active;
            EXCEPTION
                WHEN no_data_found THEN
                    l_active_disch := NULL;
            END;
        
            g_error := 'GET O_NEWBORN_REG CURSOR';
            OPEN o_newborn_reg FOR
                SELECT pk_date_utils.date_char_tsz(i_lang, dnb.dt_create, i_prof.institution, i_prof.software) rec_date,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, dnb.id_prof_create) rec_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, dnb.id_prof_create, dnb.dt_create, i_id_episode) spec_name,
                       l_sm_newborn_title label
                  FROM discharge_newborn dnb
                 WHERE dnb.id_discharge = l_active_disch
                   AND dnb.flg_status = pk_alert_constant.g_active
                 GROUP BY dnb.id_discharge, dnb.dt_create, dnb.id_prof_create;
        
            g_error := 'GET O_NEWBORN CURSOR';
            OPEN o_newborn FOR
                SELECT l_sm_newborn || ' ' || rownum || ': ' || p.name || ': ' ||
                       (SELECT pk_sysdomain.get_domain(i_code_dom => 'PATIENT.GENDER',
                                                       i_val      => p.gender,
                                                       i_lang     => i_lang)
                          FROM dual) || '; ' || (SELECT pk_sysdomain.get_domain(i_code_dom => 'DISCHARGE_NEWBORN.FLG_CONDITION',
                                                                                i_val      => dnb.flg_condition,
                                                                                i_lang     => i_lang)
                                                   FROM dual) newborn_desc
                  FROM discharge_newborn dnb
                  JOIN episode e
                    ON e.id_episode = dnb.id_episode
                  JOIN patient p
                    ON p.id_patient = e.id_patient
                 WHERE dnb.id_discharge = l_active_disch
                   AND dnb.flg_status = pk_alert_constant.g_active;
        ELSE
            pk_types.open_my_cursor(o_newborn_reg);
            pk_types.open_my_cursor(o_newborn);
        END IF;
    
        -- Check if integration with saudi arabian client registry is active and patient info has been synchronized
        l_sa_client_registry := pk_sysconfig.get_config('INTEGRATE_SA_CLIENT_REGISTRY', i_prof);
    
        IF l_sa_client_registry = g_yes
           AND i_flg_type IS NULL
           AND l_exists_discharge = pk_alert_constant.g_no
        THEN
            -- Check if patient info has been synchronized
            SELECT COUNT(1)
              INTO l_health_id_count
              FROM pat_ext_sys pes
             WHERE pes.id_patient = (SELECT id_patient
                                       FROM episode e
                                      WHERE e.id_episode = i_id_episode)
               AND pes.id_external_sys = g_sa_client_registry_sys_id;
        
            IF l_health_id_count = 0
            THEN
                -- Data is not synchronized. Execution is stopped, so that
                -- the synchronization process can occur.
                o_flg_show             := 'Y';
                o_msg_title            := pk_message.get_message(i_lang, 'DISPOSITION_NO_CLIENT_REGISTRY_T001');
                o_msg_text             := pk_message.get_message(i_lang, 'DISPOSITION_NO_CLIENT_REGISTRY_M001');
                o_button               := 'C';
                o_sync_client_registry := 'Y';
                RETURN TRUE;
            ELSE
                o_flg_show := 'N';
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_newborn_reg);
            pk_types.open_my_cursor(o_newborn);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary;

    /*
    * Get summary to reports
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO result cursor
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   29-01-2010
    *
    */
    FUNCTION get_summary_to_reports
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_newborn    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sep VARCHAR2(0050);
        l_hif VARCHAR2(0050);
    
        tit_pat_condition       sys_message.desc_message%TYPE;
        tit_med_reconcile       sys_message.desc_message%TYPE;
        tit_prescription_given  sys_message.desc_message%TYPE;
        tit_discharge_date_time sys_message.desc_message%TYPE;
    
        tit_add_notes         sys_message.desc_message%TYPE;
        tit_flg_written_notes sys_message.desc_message%TYPE;
    
        tit_admiting_physician  sys_message.desc_message%TYPE;
        tit_admission_orders    sys_message.desc_message%TYPE;
        tit_admit_to_room       sys_message.desc_message%TYPE;
        tit_flg_check_valuables sys_message.desc_message%TYPE;
    
        tit_reason_of_transfer     sys_message.desc_message%TYPE;
        tit_trf_mode_transport     sys_message.desc_message%TYPE;
        tit_dt_trf_mode_transport  sys_message.desc_message%TYPE;
        tit_risk_of_transfer       sys_message.desc_message%TYPE;
        tit_benefits_of_transfer   sys_message.desc_message%TYPE;
        tit_accepting_physician    sys_message.desc_message%TYPE;
        tit_dt_accepting_physician sys_message.desc_message%TYPE;
        tit_en_route_orders        sys_message.desc_message%TYPE;
        tit_patient_consent        sys_message.desc_message%TYPE;
        tit_acceptance_facility    sys_message.desc_message%TYPE;
        tit_admitting_room         sys_message.desc_message%TYPE;
        tit_room_assigned_by       sys_message.desc_message%TYPE;
        tit_flg_items_sent_patient sys_message.desc_message%TYPE;
        tit_report_given           sys_message.desc_message%TYPE;
    
        tit_autopsy_consent            sys_message.desc_message%TYPE;
        tit_dt_death                   sys_message.desc_message%TYPE;
        tit_prf_declared_death         sys_message.desc_message%TYPE;
        tit_flg_orgn_donation_agency   sys_message.desc_message%TYPE;
        tit_flg_report_of_death        sys_message.desc_message%TYPE;
        tit_flg_coroner_contacted      sys_message.desc_message%TYPE;
        tit_coroner_name               sys_message.desc_message%TYPE;
        tit_flg_funeral_home_contacted sys_message.desc_message%TYPE;
        tit_funeral_home_name          sys_message.desc_message%TYPE;
        tit_dt_body_removed            sys_message.desc_message%TYPE;
        tit_death_characterization     sys_message.desc_message%TYPE;
        tit_death_process_registration sys_message.desc_message%TYPE;
    
        tit_risk_of_leaving         sys_message.desc_message%TYPE;
        tit_advised_risk_of_leaving sys_message.desc_message%TYPE;
        tit_signed_ama_form         sys_message.desc_message%TYPE;
        tit_mse                     sys_message.desc_message%TYPE;
        --
        tit_flg_instructions_discussed sys_message.desc_message%TYPE;
        tit_instructions_understood    sys_message.desc_message%TYPE;
        tit_written_instructions       sys_message.desc_message%TYPE;
        tit_vs_taken                   sys_message.desc_message%TYPE;
        tit_intake_output              sys_message.desc_message%TYPE;
        tit_flg_patient_transport      sys_message.desc_message%TYPE;
        tit_flg_pat_escorted_by        sys_message.desc_message%TYPE;
    
        tit_instructions_provided   sys_message.desc_message%TYPE;
        tit_prescription_given_to   sys_message.desc_message%TYPE;
        tit_next_visit_with         sys_message.desc_message%TYPE;
        tit_next_visit              sys_message.desc_message%TYPE;
        tit_instructions_next_visit sys_message.desc_message%TYPE;
        tit_type_of_visit           sys_message.desc_message%TYPE;
        tit_reason_for_nxt_visit    sys_message.desc_message%TYPE;
        tit_notes_registrar         sys_message.desc_message%TYPE;
        tit_service_level           sys_message.desc_message%TYPE;
        tit_sched_for               sys_message.desc_message%TYPE;
        tit_prop_for                sys_message.desc_message%TYPE;
        tit_flg_compulsory          sys_message.desc_message%TYPE;
        tit_id_compulsory_reason    sys_message.desc_message%TYPE;
    
        tit_date_cancellation  sys_message.desc_message%TYPE;
        tit_cancelled_by       sys_message.desc_message%TYPE;
        tit_notes_cancellation sys_message.desc_message%TYPE;
    
        tit_reason_for_visit sys_message.desc_message%TYPE;
    
        tit_print_report pk_translation.t_desc_translation;
        err_report_label EXCEPTION;
    
        tit_flg_surgery    sys_message.desc_message%TYPE;
        tit_dt_surgery     sys_message.desc_message%TYPE;
        tit_dcs_admit      sys_message.desc_message%TYPE;
        tit_disch_type     sys_message.desc_message%TYPE;
        tit_admission      sys_message.desc_message%TYPE;
        tit_admission_date sys_message.desc_message%TYPE;
    
        l_disch_letter_list_exception VARCHAR2(0500);
        l_priv_cancel_disposition     VARCHAR2(0500);
    
        l_cur      pk_cpt_code.cpt_code_cur;
        l_rec      pk_cpt_code.cpt_code_rec;
        l_label_na sys_message.desc_message%TYPE;
    
        l_print_config v_print_list_cfg.flg_print_option_default%TYPE;
    
        l_sm_newborn_title sys_message.desc_message%TYPE;
        l_sm_newborn       sys_message.desc_message%TYPE;
        l_sc_newborn       sys_config.value%TYPE;
    
        tit_institution      sys_message.desc_message%TYPE;
        l_sc_clues           sys_config.value%TYPE;
        tit_admitting_doctor sys_message.desc_message%TYPE;
        tit_written_by       sys_message.desc_message%TYPE;
    
        tit_co_sign_type  sys_message.desc_message%TYPE;
        tit_co_sign_by    sys_message.desc_message%TYPE;
        tit_co_sign_dt    sys_message.desc_message%TYPE;
        l_show_other_prof sys_config.value%TYPE;
        l_show_written_by sys_config.value%TYPE;
    
        l_has_lvl_cpt_code VARCHAR2(2 CHAR);
    
    BEGIN
        g_error := 'CHECK CPT_CODE';
        IF NOT pk_cpt_code.get_cpt_code_list(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_cur        => l_cur,
                                             o_error      => o_error)
        THEN
            RAISE err_report_label;
        END IF;
    
        g_error := 'FETCH CPT_CODE';
        FETCH l_cur
            INTO l_rec;
    
        IF l_cur%NOTFOUND
        THEN
            l_label_na := pk_message.get_message(i_lang, i_prof, 'COMMON_M036');
        END IF;
    
        CLOSE l_cur;
    
        l_has_lvl_cpt_code := pk_cpt_code.check_has_cpt_cfg(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode);
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        l_priv_cancel_disposition := pk_sysconfig.get_config('PRIV_CANCEL_DISPOSITION', i_prof);
    
        l_sep                   := ': ';
        l_hif                   := ' - ';
        tit_pat_condition       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T003');
        tit_med_reconcile       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T006');
        tit_prescription_given  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T007');
        tit_discharge_date_time := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T008');
    
        tit_instructions_provided   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T010');
        tit_prescription_given_to   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T011');
        tit_next_visit_with         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T012');
        tit_next_visit              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T013');
        tit_instructions_next_visit := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T014');
        tit_type_of_visit           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T015');
        tit_reason_for_nxt_visit    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T016');
        tit_notes_registrar         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T017');
        tit_service_level           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T018');
        tit_sched_for               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T019');
        tit_prop_for                := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T020');
    
        tit_add_notes         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T005');
        tit_flg_written_notes := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T008');
    
        tit_admiting_physician  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T003');
        tit_admission_orders    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T007');
        tit_admit_to_room       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T008');
        tit_flg_check_valuables := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T009');
        tit_admission           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T010');
        tit_admission_date      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T011');
    
        tit_reason_of_transfer     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T008');
        tit_trf_mode_transport     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T009');
        tit_dt_trf_mode_transport  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T010');
        tit_risk_of_transfer       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T011');
        tit_benefits_of_transfer   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T012');
        tit_accepting_physician    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T003');
        tit_dt_accepting_physician := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T013');
        tit_en_route_orders        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T014');
        tit_patient_consent        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T015');
        tit_acceptance_facility    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T016');
        tit_admitting_room         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T017');
        tit_room_assigned_by       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T018');
        tit_flg_items_sent_patient := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T019');
        tit_report_given           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T020');
    
        tit_autopsy_consent            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T001');
        tit_dt_death                   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T007');
        tit_prf_declared_death         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T008');
        tit_flg_orgn_donation_agency   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T009');
        tit_flg_report_of_death        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T010');
        tit_flg_coroner_contacted      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T011');
        tit_coroner_name               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T012');
        tit_flg_funeral_home_contacted := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T013');
        tit_funeral_home_name          := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T014');
        tit_dt_body_removed            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T015');
        tit_death_characterization     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T017');
        tit_death_process_registration := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T018');
    
        tit_risk_of_leaving         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T006');
        tit_advised_risk_of_leaving := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T007');
        tit_signed_ama_form         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T008');
        tit_mse                     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_MSE_T001');
        --
        tit_flg_instructions_discussed := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T006');
        tit_instructions_understood    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T007');
        tit_written_instructions       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T008');
        tit_vs_taken                   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T009');
        tit_intake_output              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T010');
        tit_flg_patient_transport      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T011');
        tit_flg_pat_escorted_by        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T012');
        tit_flg_compulsory             := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T021');
        tit_id_compulsory_reason       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T024');
    
        tit_reason_for_visit := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_LWBS_T006');
    
        tit_date_cancellation  := pk_message.get_message(i_lang, i_prof, 'TRANSFER_INSTITUTION_T016');
        tit_cancelled_by       := pk_message.get_message(i_lang, i_prof, 'REP_COMMON_002');
        tit_notes_cancellation := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQ_T007');
    
        tit_flg_surgery := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T032');
        tit_dt_surgery  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T033');
        tit_dcs_admit   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T004');
        tit_disch_type  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T005');
    
        l_sm_newborn_title := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T169');
        l_sm_newborn       := pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T176');
        l_sc_newborn       := pk_sysconfig.get_config('DISCHARGE_NEWBORN', i_prof);
    
        tit_institution := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T090');
        l_sc_clues      := pk_sysconfig.get_config('DISCHARGE_TRANSFER_CLUES', i_prof);
    
        tit_admitting_doctor := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T013');
        tit_written_by       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T019');
    
        -- DISCHARGE ADMISSION CO-SIGN    
        tit_co_sign_type  := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_M023');
        tit_co_sign_by    := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_T003');
        tit_co_sign_dt    := pk_message.get_message(i_lang, i_prof, 'CO_SIGN_M021');
        l_show_other_prof := pk_sysconfig.get_config('DISCHARGE_ADMISSION_OTHER_PROFESSIONAL', i_prof);
        l_show_written_by := pk_sysconfig.get_config('DISCHARGE_ADMISSION_WRITTEN_BY', i_prof);
    
        g_error := 'GET PRINT REPORT LABEL';
        IF NOT pk_discharge.get_report_label(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             o_label        => tit_print_report,
                                             o_print_config => l_print_config,
                                             o_error        => o_error)
        THEN
            RAISE err_report_label;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_info FOR
            SELECT l_disch_letter_list_exception letter_list_exception,
                   decode(dh.flg_status, g_pendente, g_yes, g_active, l_priv_cancel_disposition) l_can_cancel_disposition,
                   -- José Brito 09/01/2009 ALERT-13049
                   -- Only nurses can edit disposition of type "Left without being seen" (LWBS).
                   --decode(dff.flg_type, g_disp_lwbs, decode(l_prof_cat, g_nurse, g_yes, g_no), g_yes) can_edit,
                   g_yes can_edit, -- After 2.5, physician can also edit LWBS disposition
                   --
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_created_hist, i_prof.institution, i_prof.software) rec_date,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist)
                      FROM dual) rec_name,
                   (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            dh.id_prof_created_hist,
                                                            dh.dt_created_hist,
                                                            dh.id_episode)
                      FROM dual) spec_name,
                   dh.id_discharge id_discharge,
                   drd.id_disch_reas_dest id_disch_reas_dest,
                   drd.id_discharge_reason,
                   dh.flg_status flg_status,
                   dh.flg_status_hist flg_status_hist,
                   dh.id_discharge_hist id_discharge_hist,
                   dff.file_name file_to_execute,
                   dff2.file_name file_to_execute_secondary,
                   dff.flg_type disposition_flg_type,
                   decode(sch.id_schedule, NULL, decode(creq.id_consult_req, NULL, 'N', 'P'), 'S') flg_date_type,
                   decode(dh.flg_status,
                          g_disch_act,
                          '',
                          -- José Brito 04/03/2009 ALERT-10317
                          -- If patient refused to be transfered, the disposition
                          -- must show 'REFUSED' instead of 'CANCELLED'.
                          g_disch_flg_cancel,
                          decode(dh.flg_cancel_type,
                                 pk_alert_constant.g_disch_flgcanceltype_r,
                                 upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_CANCEL_TYPE',
                                                               dh.flg_cancel_type,
                                                               i_lang)),
                                 upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang))),
                          --
                          upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang))) desc_flg_status,
                   pk_translation.get_translation(i_lang, dr.code_discharge_reason) tit_l_disposition,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          decode(dff.flg_type,
                                 g_disp_tran,
                                 nvl(ddh.acceptance_facility,
                                     pk_translation.get_translation(i_lang,
                                                                    nvl(ins.code_institution, dd.code_discharge_dest))),
                                 decode(nvl(drd.id_discharge_dest, 0),
                                        0,
                                        decode(nvl(drd.id_dep_clin_serv, 0),
                                               0,
                                               decode(nvl(drd.id_institution, 0),
                                                      0,
                                                      pk_translation.get_translation(i_lang, dpt.code_department),
                                                      pk_translation.get_translation(i_lang, ins.code_institution)),
                                               nvl2(drd.id_department,
                                                    pk_translation.get_translation(i_lang, dpt.code_department) || ' - ',
                                                    '') ||
                                               pk_translation.get_translation(i_lang,
                                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                              dcs3.id_clinical_service)),
                                        pk_translation.get_translation(i_lang, dd.code_discharge_dest)))) l_disposition,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          g_disp_tran,
                          nvl(ddh.acceptance_facility,
                              pk_translation.get_translation(i_lang, nvl(ins.code_institution, dd.code_discharge_dest))),
                          get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest)) l_to,
                   dh.id_discharge_status,
                   decode(dff.flg_type, g_disp_adms, tit_admission, tit_disch_type) tit_desc_disch_status,
                   get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                   tit_pat_condition || l_sep tit_pat_condition,
                   decode(dff.flg_type,
                          g_disp_other,
                          NULL,
                          g_disp_expi,
                          NULL,
                          g_disp_foll,
                          NULL,
                          pk_discharge.get_patient_condition(i_lang,
                                                             i_prof,
                                                             dh.id_discharge,
                                                             dr.id_discharge_reason,
                                                             ddh.flg_pat_condition)) val_pat_condition,
                   --begin: field01
                   tit_med_reconcile || l_sep tit_med_reconcile,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) val_med_reconcile,
                   tit_risk_of_leaving || l_sep tit_risk_of_leaving,
                   ddh.risk_of_leaving val_risk_of_leaving,
                   tit_dt_death || l_sep tit_dt_death,
                   pk_date_utils.date_char_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software) val_dt_death,
                   -- José Brito 27/06/2008 Disposition workflow review
                   tit_reason_of_transfer || l_sep tit_reason_of_transfer,
                   nvl(ddh.reason_of_transfer_desc,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.REASON_OF_TRANSFER',
                                               ddh.reason_of_transfer,
                                               i_lang)) val_reason_of_transfer,
                   --
                   tit_mse || l_sep tit_mse,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.MSE_TYPE', ddh.mse_type, i_lang) val_mse,
                   tit_next_visit || l_sep tit_next_visit,
                   decode(ddh.id_schedule,
                          NULL,
                          decode(ddh.id_consult_req,
                                 NULL,
                                 ddh.next_visit_scheduled,
                                 decode(creq.dt_scheduled_tstz,
                                        NULL,
                                        ddh.next_visit_scheduled,
                                        tit_prop_for || l_sep ||
                                        pk_date_utils.dt_chr_tsz(i_lang,
                                                                 creq.dt_scheduled_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)))) val_next_visit,
                   tit_sched_for || l_sep tit_sched_for,
                   pk_date_utils.date_char_tsz(i_lang, sch.dt_schedule_tstz, i_prof.institution, i_prof.software) val_sched_for,
                   -- José Brito 27/06/2008 Disposition workflow review
                   tit_admiting_physician || l_sep tit_admiting_physician,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_admitting), ddh.prof_admitting_desc) val_admiting_physician,
                   --
                   tit_reason_for_visit || l_sep tit_reason_for_visit,
                   ddh.reason_for_leaving val_reason_for_visit,
                   --end: field01
                   --begin: field02
                   tit_prescription_given || l_sep tit_prescription_given,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang) val_prescription_given,
                   tit_advised_risk_of_leaving || l_sep tit_advised_risk_of_leaving,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang) val_advised_risk_of_leaving,
                   tit_prf_declared_death || l_sep tit_prf_declared_death,
                   ddh.prf_declared_death val_prf_declared_death,
                   decode(dff.flg_type, g_disp_adms, tit_admission_date, tit_discharge_date_time) || l_sep tit_discharge_date_time,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(dh.dt_med_tstz, ddh.dt_ama_tstz),
                                               i_prof.institution,
                                               i_prof.software) val_discharge_date_time,
                   tit_next_visit_with || l_sep tit_next_visit_with,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_assigned_to) val_next_visit_with,
                   --end: field02
                   --begin: field03
                   tit_type_of_visit || l_sep tit_type_of_visit,
                   pk_translation.get_translation(i_lang, cli.code_clinical_service) val_type_of_visit,
                   tit_trf_mode_transport || l_sep tit_trf_mode_transport,
                   decode(ddh.flg_transfer_transport,
                          l_disch_letter_list_exception,
                          ddh.desc_transfer_transport,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_TRANSFER_TRANSPORT',
                                                  ddh.flg_transfer_transport,
                                                  i_lang)) val_trf_mode_transport,
                   tit_autopsy_consent || l_sep tit_autopsy_consent,
                   ddh.autopsy_consent_desc val_autopsy_consent,
                   tit_admit_to_room || l_sep tit_admit_to_room,
                   get_room_admit(i_lang, i_prof, ddh.id_room_admit, ddh.admit_to_room) val_admit_to_room,
                   tit_flg_pat_escorted_by || l_sep tit_flg_pat_escorted_by,
                   decode(ddh.flg_pat_escorted_by,
                          l_disch_letter_list_exception,
                          ddh.desc_pat_escorted_by,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                  ddh.flg_pat_escorted_by,
                                                  i_lang)) val_flg_pat_escorted_by,
                   --end: field03
                   --begin: field04
                   tit_reason_for_nxt_visit || l_sep tit_reason_for_nxt_visit,
                   pk_translation.get_translation(i_lang, cmp.code_complaint) val_reason_for_nxt_visit,
                   tit_flg_instructions_discussed || l_sep tit_flg_instructions_discussed,
                   decode(ddh.flg_instructions_discussed,
                          l_disch_letter_list_exception,
                          ddh.instructions_discussed_notes,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                  ddh.flg_instructions_discussed,
                                                  i_lang)) val_flg_instructions_discussed,
                   tit_flg_patient_transport || l_sep tit_flg_patient_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                           ddh.flg_patient_transport,
                                           i_lang) val_flg_patient_transport,
                   tit_dt_trf_mode_transport || l_sep tit_dt_trf_mode_transport,
                   pk_date_utils.date_char_tsz(i_lang,
                                               ddh.dt_transfer_transport_tstz,
                                               i_prof.institution,
                                               i_prof.software) val_dt_trf_mode_transport,
                   tit_flg_orgn_donation_agency || l_sep tit_flg_orgn_donation_agency,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_orgn_donation_agency, i_lang) val_flg_orgn_donation_agency,
                   tit_vs_taken || l_sep tit_vs_taken,
                   pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang) val_vs_taken,
                   --end: field04
                   --begin: field05
                   tit_instructions_next_visit || l_sep tit_instructions_next_visit,
                   decode(ddh.flg_instructions_next_visit,
                          l_disch_letter_list_exception,
                          ddh.desc_instructions_next_visit,
                          pk_sysdomain.get_domain('SCHEDULE.FLG_INSTRUCTIONS', ddh.flg_instructions_next_visit, i_lang)) val_instructions_next_visit,
                   tit_instructions_understood || l_sep tit_instructions_understood,
                   pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang) val_instructions_understood,
                   tit_risk_of_transfer || l_sep tit_risk_of_transfer,
                   ddh.risk_of_transfer val_risk_of_transfer,
                   tit_flg_report_of_death || l_sep tit_flg_report_of_death,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_report_of_death, i_lang) val_flg_report_of_death,
                   tit_intake_output || l_sep tit_intake_output,
                   pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang) val_intake_output,
                   --end: field05
                   --begin: field06
                   tit_instructions_provided || l_sep tit_instructions_provided,
                   pk_sysdomain.get_domain('YES_NO', ddh.pat_instructions_provided, i_lang) val_instructions_provided,
                   tit_flg_written_notes || l_sep tit_flg_written_notes,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang) val_flg_written_notes,
                   tit_signed_ama_form || l_sep tit_signed_ama_form,
                   decode(ddh.flg_signed_ama_form,
                          l_disch_letter_list_exception,
                          ddh.desc_signed_ama_form,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_SIGNED_AMA_FORM',
                                                  ddh.flg_signed_ama_form,
                                                  i_lang)) val_signed_ama_form,
                   tit_benefits_of_transfer || l_sep tit_benefits_of_transfer,
                   ddh.benefits_of_transfer val_benefits_of_transfer,
                   tit_flg_coroner_contacted || l_sep tit_flg_coroner_contacted,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_coroner_contacted, i_lang) val_flg_coroner_contacted,
                   tit_flg_check_valuables || l_sep tit_flg_check_valuables,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_check_valuables, i_lang) val_flg_check_valuables,
                   --end: field06
                   --begin: field07
                   tit_accepting_physician || l_sep tit_accepting_physician,
                   ddh.prof_admitting_desc val_accepting_physician,
                   tit_coroner_name || l_sep tit_coroner_name,
                   ddh.coroner_name val_coroner_name,
                   tit_admission_orders || l_sep tit_admission_orders,
                   ddh.admission_orders val_admission_orders,
                   --end: field07
                   --begin: field08
                   tit_prescription_given_to || l_sep tit_prescription_given_to,
                   decode(ddh.flg_prescription_given_to,
                          l_disch_letter_list_exception,
                          ddh.desc_prescription_given_to,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PRESCRIPTION_GIVEN_TO',
                                                  ddh.flg_prescription_given_to,
                                                  i_lang)) val_prescription_given_to,
                   tit_dt_accepting_physician || l_sep tit_dt_accepting_physician,
                   pk_date_utils.date_char_tsz(i_lang, ddh.dt_prof_admiting_tstz, i_prof.institution, i_prof.software) val_dt_accepting_physician,
                   tit_flg_funeral_home_contacted || l_sep tit_flg_funeral_home_contacted,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_funeral_home_contacted, i_lang) val_flg_funeral_home_contacted,
                   --end: field08
                   --begin: field09
                   tit_en_route_orders || l_sep tit_en_route_orders,
                   ddh.en_route_orders val_en_route_orders,
                   tit_funeral_home_name || l_sep tit_funeral_home_name,
                   ddh.funeral_home_name val_funeral_home_name,
                   --end: field09
                   --begin: field10
                   tit_patient_consent || l_sep tit_patient_consent,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_CONSENT', ddh.flg_patient_consent, i_lang) val_patient_consent,
                   tit_dt_body_removed || l_sep tit_dt_body_removed,
                   pk_date_utils.date_char_tsz(i_lang, ddh.dt_body_removed_tstz, i_prof.institution, i_prof.software) val_dt_body_removed,
                   --end: field10
                   --begin: field11
                   tit_acceptance_facility || l_sep tit_acceptance_facility,
                   ddh.acceptance_facility val_acceptance_facility,
                   --end: field11
                   --begin: field12
                   tit_admitting_room || l_sep tit_admitting_room,
                   ddh.admitting_room val_admitting_room,
                   tit_notes_registrar || l_sep tit_notes_registrar,
                   ddh.notes val_notes_registrar,
                   --end: field12
                   --begin: field13
                   tit_room_assigned_by || l_sep tit_room_assigned_by,
                   ddh.room_assigned_by val_room_assigned_by,
                   tit_notes_cancellation || l_sep tit_notes_cancellation,
                   dh.notes_cancel val_notes_cancel,
                   tit_date_cancellation || l_sep tit_date_cancellation,
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_cancel_tstz, i_prof.institution, i_prof.software) val_dt_cancel,
                   tit_cancelled_by tit_cancelled_by,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_cancel) val_cancelled_by,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, dh.id_prof_cancel, dh.dt_cancel_tstz, dh.id_episode) val_cancelled_spec,
                   --end: field13
                   --begin: field14
                   tit_flg_items_sent_patient || l_sep tit_flg_items_sent_patient,
                   decode(dff.flg_type, g_disp_tran, ddh.items_sent_with_patient) val_flg_items_sent_patient,
                   --end: field14
                   --begin: field17
                   -- José Brito 27/06/2008 Disposition workflow review
                   tit_report_given || l_sep tit_report_given,
                   decode(dff.flg_type, g_disp_tran, ddh.report_given_to) val_report_given,
                   --end: field17
                   decode(l_has_lvl_cpt_code, pk_alert_constant.g_yes, tit_service_level || l_sep, NULL) tit_service_level,
                   decode(l_has_lvl_cpt_code,
                          pk_alert_constant.g_yes,
                          decode(dff.flg_type, g_disp_other, NULL, nvl(cc.medium_desc, l_label_na)),
                          NULL) level_of_service,
                   --
                   tit_add_notes || l_sep tit_add_notes,
                   dh.notes_med additional_notes,
                   -- AS 14-12-2009 (ALERT-62112)
                   tit_print_report report_label,
                   ddh.flg_print_report,
                   pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                   --
                   tit_dcs_admit || l_sep tit_desc_dcs_admit,
                   decode(dff.flg_type,
                          g_disp_adms,
                          pk_translation.get_translation(i_lang,
                                                         'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                         dcs2.id_clinical_service),
                          NULL) desc_dcs_admit,
                   tit_flg_surgery || l_sep tit_desc_surgery,
                   decode(dff.flg_type,
                          g_disp_adms,
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORIS', ddh.flg_surgery, i_lang),
                          NULL) desc_surgery,
                   tit_dt_surgery || l_sep tit_dt_surgery,
                   decode(dff.flg_type,
                          g_disp_adms,
                          pk_date_utils.date_char_tsz(i_lang, ddh.date_surgery_tstz, i_prof.institution, i_prof.software),
                          NULL) dt_surgery,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dh.dt_created_hist, i_prof) rec_date_send,
                   decode(dh.dt_created_hist,
                          (SELECT MAX(dh2.dt_created_hist)
                             FROM discharge_hist dh2
                             JOIN discharge_detail_hist ddh2
                               ON ddh2.id_discharge_hist = dh2.id_discharge_hist
                            WHERE dh2.id_episode = dh.id_episode),
                          'L',
                          'O') flg_last_rec,
                   tit_death_characterization || l_sep tit_death_characterization,
                   pk_translation.get_translation_trs(i_code_mess => ddh.code_death_event) val_death_characterization,
                   tit_death_process_registration || l_sep tit_death_process_registration,
                   ddh.death_process_registration val_death_process_registration,
                   decode(l_sc_clues, pk_alert_constant.g_yes, tit_institution || l_sep) tit_inst_transfer,
                   decode(l_sc_clues,
                          pk_alert_constant.g_yes,
                          pk_translation.get_translation(i_lang, tinst.code_institution)) desc_inst_transfer,
                   tit_admitting_doctor || l_sep tit_admitting_doctor,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_other_prof,
                                 pk_alert_constant.g_yes,
                                 (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_admitting_doctor)
                                    FROM dual),
                                 NULL),
                          NULL) admitting_doctor,
                   tit_co_sign_type || l_sep tit_co_sign_type,
                   c.desc_order_type co_sign_type,
                   tit_co_sign_by || l_sep tit_co_sign_by,
                   c.desc_prof_ordered_by co_sign_by,
                   tit_co_sign_dt || l_sep tit_co_sign_dt,
                   pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) co_sign_dt,
                   tit_written_by || l_sep tit_written_by,
                   decode(dff.flg_type,
                          g_disp_adms,
                          decode(l_show_written_by,
                                 pk_alert_constant.g_yes,
                                 (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_written_by)
                                    FROM dual),
                                 NULL),
                          NULL) written_by,
                   tit_flg_compulsory || l_sep tit_flg_compulsory,
                   pk_sysdomain.get_domain('YES_NO', ddh.flg_compulsory, i_lang) val_flg_compulsory,
                   tit_id_compulsory_reason || l_sep tit_id_compulsory_reason,
                   decode(ddh.id_compulsory_reason,
                          -1,
                          (pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, ddh.id_compulsory_reason) ||
                          l_hif || ddh.compulsory_reason),
                          pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, ddh.id_compulsory_reason)) val_compulsory_reason
              FROM discharge_hist dh
              JOIN discharge_detail_hist ddh
                ON ddh.id_discharge_hist = dh.id_discharge_hist
              JOIN disch_reas_dest drd
                ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
              JOIN discharge_reason dr
                ON dr.id_discharge_reason = drd.id_discharge_reason
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ddh.id_dep_clin_serv_visit
              LEFT JOIN dep_clin_serv dcs2
                ON dcs2.id_dep_clin_serv = ddh.id_dep_clin_serv_admiting
              LEFT JOIN dep_clin_serv dcs3
                ON dcs3.id_dep_clin_serv = drd.id_dep_clin_serv
              LEFT JOIN clinical_service cli
                ON cli.id_clinical_service = dcs.id_clinical_service
              LEFT JOIN complaint cmp
                ON cmp.id_complaint = ddh.id_complaint
              LEFT JOIN discharge_dest dd
                ON dd.id_discharge_dest = drd.id_discharge_dest
              LEFT JOIN department dpt
                ON dpt.id_department = drd.id_department
              LEFT JOIN institution ins
                ON ins.id_institution = drd.id_institution
              LEFT JOIN cpt_code cc
                ON cc.id_cpt_code = dh.id_cpt_code
              LEFT JOIN schedule sch
                ON sch.id_schedule = ddh.id_schedule
              LEFT JOIN consult_req creq
                ON creq.id_consult_req = ddh.id_consult_req
            --A left join is made with discharge_flash_files to show all records even wrong ones
              LEFT JOIN discharge_flash_files dff
                ON dff.id_discharge_flash_files = dh.id_discharge_flash_files
              LEFT JOIN discharge_flash_files dff2
                ON dff2.id_discharge_flash_files = dff.id_dsch_flsh_files_assoc
              LEFT JOIN institution tinst
                ON tinst.id_institution = ddh.id_inst_transfer
              LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                ON c.id_co_sign = ddh.id_co_sign
             WHERE dh.id_episode = i_id_episode
             ORDER BY dh.dt_created_hist DESC;
    
        IF l_sc_newborn = pk_alert_constant.g_yes
        THEN
            OPEN o_newborn FOR
                SELECT pk_date_utils.date_char_tsz(i_lang, dn.dt_create, i_prof.institution, i_prof.software) rec_date,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, dn.id_prof_create) rec_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, dn.id_prof_create, dn.dt_create, i_id_episode) spec_name,
                       pk_utils.concat_table(i_tab   => (CAST(MULTISET
                                                              (SELECT '<b>' || l_sm_newborn || ' ' || rownum || ': </b>' ||
                                                                      p.name || ': ' || (SELECT pk_sysdomain.get_domain(i_code_dom => 'PATIENT.GENDER',
                                                                                                                        i_val      => p.gender,
                                                                                                                        i_lang     => i_lang)
                                                                                           FROM dual) || '; ' ||
                                                                      (SELECT pk_sysdomain.get_domain(i_code_dom => 'DISCHARGE_NEWBORN.FLG_CONDITION',
                                                                                                      i_val      => dnb.flg_condition,
                                                                                                      i_lang     => i_lang)
                                                                         FROM dual) rec_newborn
                                                                 FROM discharge_newborn dnb
                                                                 JOIN episode e
                                                                   ON e.id_episode = dnb.id_episode
                                                                 JOIN patient p
                                                                   ON p.id_patient = e.id_patient
                                                                WHERE dnb.id_discharge = disch.id_discharge) AS
                                                              table_varchar)),
                                             i_delim => chr(10)) rec_newborn,
                       l_sm_newborn_title rec_title
                  FROM discharge disch
                  JOIN discharge_newborn dn
                    ON dn.id_discharge = disch.id_discharge
                 WHERE disch.id_episode = i_id_episode
                   AND disch.flg_status = pk_alert_constant.g_active
                 GROUP BY disch.id_discharge, dn.id_prof_create, dn.dt_create;
        ELSE
            pk_types.open_my_cursor(o_newborn);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_SUMMARY_TO_REPORTS',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary_to_reports;

    FUNCTION set_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        UPDATE discharge_hist
           SET dt_cancel_tstz  = current_timestamp,
               id_prof_cancel  = i_prof.id,
               notes_cancel    = i_notes_cancel,
               flg_status      = g_cancel,
               flg_status_hist = g_cancel,
               -- José Brito 04/03/2009 ALERT-10317
               flg_cancel_type = pk_alert_constant.g_disch_flgcanceltype_n,
               flg_status_adm  = g_cancel
         WHERE id_discharge_hist = i_id_discharge_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_CANCEL',
                                              o_error);
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_cancel;

    FUNCTION cancel_disposition_ux
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
        l_id_patient      patient.id_patient%TYPE;
        l_id_epis         episode.id_episode%TYPE;
        l_last_epis       episode.id_episode%TYPE;
        l_last_visit      visit.id_visit%TYPE;
        l_visit           visit.id_visit%TYPE;
        l_can_reopen_epis VARCHAR2(1);
    
        CURSOR c_discharge IS
            SELECT e.id_episode, e.id_patient, e.id_epis_type
              FROM discharge d
             INNER JOIN episode e
                ON d.id_episode = e.id_episode
             WHERE d.id_discharge = i_id_discharge
               AND d.flg_status != 'C';
    
        l_last_epis_type epis_type.id_epis_type%TYPE;
        l_epis_type      epis_type.id_epis_type%TYPE;
    BEGIN
        -- For INTER-ALERT
        g_error := 'OPEN C_PATIENT';
        pk_alertlog.log_debug(g_error);
        OPEN c_discharge;
        FETCH c_discharge
            INTO l_id_epis, l_id_patient, l_epis_type;
        CLOSE c_discharge;
    
        o_flg_show := 'N';
        o_button   := 'NCR';
    
        g_error := 'GET LAST EPISODE';
        IF NOT pk_episode.get_last_episode(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_patient       => l_id_patient,
                                           i_flg_discharge => pk_alert_constant.g_yes,
                                           o_last_episode  => l_last_epis,
                                           o_flg_reopen    => l_can_reopen_epis,
                                           o_epis_type     => l_last_epis_type,
                                           o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_last_epis <> l_id_epis
           AND (l_epis_type = l_last_epis_type OR
           (l_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient) AND
           l_last_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)))
        THEN
        
            l_last_visit := pk_visit.get_visit(i_episode => l_last_epis, o_error => o_error);
            l_visit      := pk_visit.get_visit(i_episode => l_id_epis, o_error => o_error);
        
            -- This is not the most recent episode of this patient
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T013');
        
            IF l_last_visit <> l_visit
            THEN
                o_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DISCHARGE_M052');
            ELSE
                o_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DISCHARGE_M044');
            END IF;
        
            o_button := 'R';
            RETURN TRUE;
        ELSIF l_can_reopen_epis != pk_alert_constant.g_yes
              AND
              (l_epis_type = l_last_epis_type OR
              (l_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient) AND
              l_last_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)))
        THEN
            -- Episode cannot be reopened so we cannot cancel the administrative discharge
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T013');
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_M030');
            o_button    := 'R';
            RETURN TRUE; --> Terminate if episode cant be reopened
        END IF;
    
        g_error := 'CALL TO CANCEL_DISPOSITION';
        IF NOT cancel_disposition(i_lang              => i_lang,
                                  i_id_discharge      => i_id_discharge,
                                  i_id_discharge_hist => i_id_discharge_hist,
                                  i_prof              => i_prof,
                                  i_notes_cancel      => i_notes_cancel,
                                  i_dt_cancel         => NULL,
                                  i_id_cancel_reason  => i_id_cancel_reason,
                                  o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'CANCEL_DISPOSITION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_disposition_ux;

    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_dt_cancel         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    
    BEGIN
    
        IF NOT cancel_disposition(i_lang              => i_lang,
                                  i_id_discharge      => i_id_discharge,
                                  i_id_discharge_hist => i_id_discharge_hist,
                                  i_prof              => i_prof,
                                  i_notes_cancel      => i_notes_cancel,
                                  i_dt_cancel         => i_dt_cancel,
                                  i_id_cancel_reason  => NULL,
                                  o_error             => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'CANCEL_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END cancel_disposition;

    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_dt_cancel         IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    
        r_dsd discharge_detail_hist%ROWTYPE;
        r_dsc discharge%ROWTYPE;
    
        l_button             VARCHAR2(0500);
        l_msg                VARCHAR2(0500);
        l_msg_title          VARCHAR2(0500);
        l_flg_show           VARCHAR2(0500);
        l_change             NUMBER;
        l_id_patient         patient.id_patient%TYPE;
        l_id_print_list_jobs table_number := table_number();
    
        l_cancel_print_jobs_excpt EXCEPTION;
        err_cancel_discharge      EXCEPTION;
        err_chk_schedule          EXCEPTION;
    
        l_sc_newborn sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_NEWBORN', i_prof);
    
        l_transaction_id  VARCHAR2(4000);
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT *
          INTO r_dsc
          FROM discharge
         WHERE id_discharge = i_id_discharge;
    
        SELECT *
          INTO r_dsd
          FROM discharge_detail_hist
         WHERE id_discharge_hist = i_id_discharge_hist;
    
        l_ret := pk_schedule_pp.check_disp_sched(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_consult_req => r_dsd.id_consult_req,
                                                 o_button         => l_button,
                                                 o_msg            => l_msg,
                                                 o_msg_title      => l_msg_title,
                                                 o_flg_show       => l_flg_show,
                                                 o_change         => l_change,
                                                 o_error          => o_error);
    
        IF l_change = 0
        THEN
            RAISE err_chk_schedule;
        END IF;
        IF l_ret = FALSE
        THEN
            RAISE err_chk_schedule;
        END IF;
    
        IF r_dsd.id_consult_req IS NOT NULL
        THEN
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
        
            l_ret := pk_schedule_pp.cancel_visit_sched(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_consult_req => r_dsd.id_consult_req,
                                                       i_id_episode     => r_dsc.id_episode,
                                                       i_id_schedule    => NULL,
                                                       i_cancel_request => g_yes,
                                                       i_transaction_id => l_transaction_id,
                                                       o_error          => o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_cancel_discharge;
            END IF;
        
        END IF;
    
        IF r_dsd.id_schedule IS NOT NULL
        THEN
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
        
            l_ret := pk_schedule.cancel_schedule(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_schedule      => r_dsd.id_schedule,
                                                 i_id_cancel_reason => NULL,
                                                 i_cancel_notes     => i_notes_cancel,
                                                 io_transaction_id  => l_transaction_id,
                                                 o_error            => o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_cancel_discharge;
            END IF;
        
        END IF;
    
        l_ret := set_cancel(i_lang, i_id_discharge, i_id_discharge_hist, i_prof, i_notes_cancel, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_cancel_discharge;
        END IF;
    
        l_ret := pk_discharge.cancel_discharge(i_lang,
                                               i_id_discharge,
                                               i_prof,
                                               i_notes_cancel,
                                               i_id_cancel_reason,
                                               NULL,
                                               i_dt_cancel,
                                               o_error);
        IF l_ret = FALSE
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --       l_ret := pk_patient_tracking.restore_care_stage_disposition(i_lang, i_prof, r_dsc.id_episode, o_error);
        --       IF l_ret = FALSE
        --      THEN
        --           RAISE err_cancel_discharge;
        --      END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        g_error := 'GET PATIENT ID FROM EPISODE';
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = r_dsc.id_episode;
    
        g_error := 'CALL TO REMOVE ALL EXISTING PRINT JOBS IN THE PRINTING LIST';
        IF NOT pk_discharge.cancel_disch_print_jobs(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_patient            => l_id_patient,
                                                    i_episode            => r_dsc.id_episode,
                                                    o_id_print_list_jobs => l_id_print_list_jobs,
                                                    o_error              => o_error)
        THEN
            RAISE l_cancel_print_jobs_excpt;
        END IF;
    
        IF l_sc_newborn = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL CANCEL_NEWBORN_DISCHARGE';
            IF NOT cancel_newborn_discharge(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_discharge => i_id_discharge,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF r_dsd.id_co_sign IS NOT NULL
        THEN
            g_error := 'CALL PK_CO_SIGN_API.SET_TASK_OUTDATED';
            IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => r_dsc.id_episode,
                                                    i_id_co_sign      => r_dsd.id_co_sign,
                                                    i_id_co_sign_hist => NULL,
                                                    i_dt_update       => g_sysdate_tstz,
                                                    o_id_co_sign_hist => l_id_co_sign_hist,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        --COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_cancel_discharge THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            --pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN err_chk_schedule THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   '',
                                   l_msg,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'CANCEL_DISPOSITION',
                                   l_msg_title,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                --pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN l_cancel_print_jobs_excpt THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'CANCEL_DISPOSITION',
                                              o_error);
            --pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_disposition;

    FUNCTION set_lwbs_disposition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_status            IN discharge_hist.flg_status%TYPE,
        i_discharge_status      IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest    IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist     IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition     IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_reason_for_leaving    IN discharge_detail_hist.reason_for_leaving%TYPE,
        i_flg_risk_of_leaving   IN discharge_detail_hist.flg_risk_of_leaving%TYPE,
        i_flg_pat_escorted_by   IN discharge_detail_hist.flg_pat_escorted_by%TYPE,
        i_desc_pat_escorted_by  IN discharge_detail_hist.desc_pat_escorted_by%TYPE,
        i_notes_med             IN discharge_hist.notes_med%TYPE,
        i_dt_med                IN VARCHAR2,
        i_flg_print_report      IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files IN discharge_hist.id_discharge_flash_files%TYPE,
        o_dsc                   OUT discharge_hist%ROWTYPE,
        o_dsd                   OUT discharge_detail_hist%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    
        l_dt_med    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL);
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest := i_id_disch_reas_dest;
        o_dsc.id_discharge       := r_dsc.id_discharge;
        o_dsc.id_discharge_hist  := i_id_discharge_hist;
        o_dsc.id_episode         := i_id_episode;
        o_dsc.id_prof_med        := i_prof.id;
        -- José Brito 30/05/2008 Novos campos no ecrã
        --o_dsc.dt_med             := nvl(r_dsc.dt_med, SYSDATE);
        --o_dsc.dt_med_tstz        := nvl(r_dsc.dt_med_tstz, current_timestamp);
        o_dsc.dt_med_tstz := least(l_dt_med, l_timestamp);
        --
        o_dsc.notes_med                := i_notes_med;
        o_dsc.flg_status               := g_active;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition    := i_flg_pat_condition;
        o_dsd.reason_for_leaving   := i_reason_for_leaving;
        o_dsd.flg_risk_of_leaving  := i_flg_risk_of_leaving;
        o_dsd.flg_pat_escorted_by  := i_flg_pat_escorted_by;
        o_dsd.desc_pat_escorted_by := i_desc_pat_escorted_by;
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_LWBS_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_lwbs_disposition;

    FUNCTION set_mse_disposition
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_flg_status                   IN discharge_hist.flg_status%TYPE,
        i_discharge_status             IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest           IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist            IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition            IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_mse_type                     IN discharge_detail_hist.mse_type%TYPE,
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_flg_prescription_given       IN discharge_detail_hist.flg_prescription_given%TYPE,
        i_flg_written_notes            IN discharge_detail_hist.flg_written_notes%TYPE,
        i_dt_med                       IN VARCHAR2,
        i_flg_instructions_discussed   IN discharge_detail_hist.flg_instructions_discussed%TYPE,
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE,
        i_instructions_understood      IN discharge_detail_hist.instructions_understood%TYPE,
        i_vs_taken                     IN discharge_detail_hist.vs_taken%TYPE,
        i_intake_output_done           IN discharge_detail_hist.intake_output_done%TYPE,
        i_flg_patient_transport        IN discharge_detail_hist.flg_patient_transport%TYPE,
        i_flg_pat_escorted_by          IN discharge_detail_hist.flg_pat_escorted_by%TYPE,
        i_desc_pat_escorted_by         IN discharge_detail_hist.desc_pat_escorted_by%TYPE,
        i_notes_med                    IN discharge_hist.notes_med%TYPE,
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report      IN discharge_detail_hist.flg_print_report%TYPE DEFAULT NULL,
        i_discharge_flash_files IN discharge_hist.id_discharge_flash_files%TYPE,
        o_dsc                   OUT discharge_hist%ROWTYPE,
        o_dsd                   OUT discharge_detail_hist%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    
        l_dt_med    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL);
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest       := i_id_disch_reas_dest;
        o_dsc.id_discharge             := r_dsc.id_discharge;
        o_dsc.id_discharge_hist        := i_id_discharge_hist;
        o_dsc.id_episode               := i_id_episode;
        o_dsc.id_prof_med              := i_prof.id;
        o_dsc.dt_med_tstz              := least(l_dt_med, l_timestamp);
        o_dsc.notes_med                := i_notes_med;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition := i_flg_pat_condition;
    
        o_dsd.mse_type                     := i_mse_type;
        o_dsd.flg_med_reconcile            := i_flg_med_reconcile;
        o_dsd.flg_prescription_given       := i_flg_prescription_given;
        o_dsd.flg_written_notes            := i_flg_written_notes;
        o_dsd.flg_instructions_discussed   := i_flg_instructions_discussed;
        o_dsd.instructions_discussed_notes := i_instructions_discussed_notes;
        o_dsd.instructions_understood      := i_instructions_understood;
        o_dsd.vs_taken                     := i_vs_taken;
        o_dsd.intake_output_done           := i_intake_output_done;
        o_dsd.flg_patient_transport        := i_flg_patient_transport;
        o_dsd.flg_pat_escorted_by          := i_flg_pat_escorted_by;
        o_dsd.desc_pat_escorted_by         := i_desc_pat_escorted_by;
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_MSE_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_mse_disposition;

    FUNCTION set_ama_disposition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_status            IN discharge_hist.flg_status%TYPE,
        i_discharge_status      IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest    IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist     IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition     IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_risk_of_leaving       IN discharge_detail_hist.risk_of_leaving%TYPE,
        i_flg_risk_of_leaving   IN discharge_detail_hist.flg_risk_of_leaving%TYPE,
        i_dt_ama                IN VARCHAR2,
        i_notes_med             IN discharge_hist.notes_med%TYPE,
        i_flg_signed_ama_form   IN discharge_detail_hist.flg_signed_ama_form%TYPE,
        i_signed_ama_form       IN discharge_detail_hist.desc_signed_ama_form%TYPE,
        i_flg_pat_escorted_by   IN discharge_detail_hist.flg_pat_escorted_by%TYPE,
        i_desc_pat_escorted_by  IN discharge_detail_hist.desc_pat_escorted_by%TYPE,
        i_flg_patient_transport IN discharge_detail_hist.flg_patient_transport%TYPE,
        i_reason_for_leaving    IN discharge_detail_hist.reason_for_leaving%TYPE,
        i_flg_print_report      IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files IN discharge_hist.id_discharge_flash_files%TYPE,
        o_dsc                   OUT discharge_hist%ROWTYPE,
        o_dsd                   OUT discharge_detail_hist%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest := i_id_disch_reas_dest;
        o_dsc.id_discharge       := r_dsc.id_discharge;
        o_dsc.id_discharge_hist  := i_id_discharge_hist;
        o_dsc.id_episode         := i_id_episode;
        o_dsc.id_prof_med        := i_prof.id;
        -- José Brito 30/05/2008 O campo DT_MET deve ser sincronizado com o DT_AMA
        --o_dsc.dt_med             := nvl(r_dsc.dt_med, SYSDATE);
        --o_dsc.dt_med_tstz        := nvl(r_dsc.dt_med_tstz, current_timestamp);
        o_dsc.dt_med_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_ama, NULL);
        --
        o_dsc.notes_med                := i_notes_med;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition     := i_flg_pat_condition;
        o_dsd.risk_of_leaving       := i_risk_of_leaving;
        o_dsd.flg_risk_of_leaving   := i_flg_risk_of_leaving;
        o_dsd.dt_ama_tstz           := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_ama, NULL);
        o_dsd.flg_signed_ama_form   := i_flg_signed_ama_form;
        o_dsd.desc_signed_ama_form  := i_signed_ama_form;
        o_dsd.flg_pat_escorted_by   := i_flg_pat_escorted_by;
        o_dsd.desc_pat_escorted_by  := i_desc_pat_escorted_by;
        o_dsd.flg_patient_transport := i_flg_patient_transport;
        -- José Brito 30/05/2008 Novos campos no ecrã
        o_dsd.reason_for_leaving := i_reason_for_leaving;
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_AMA_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_ama_disposition;

    FUNCTION set_expired_disposition
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_episode                 IN episode.id_episode%TYPE,
        i_flg_status                 IN discharge_hist.flg_status%TYPE,
        i_discharge_status           IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest         IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist          IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition          IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_dt_death                   IN VARCHAR2,
        i_prf_declared_death         IN discharge_detail_hist.prf_declared_death%TYPE,
        i_autopsy_consent_desc       IN discharge_detail_hist.autopsy_consent_desc%TYPE,
        i_flg_orgn_donation_agency   IN discharge_detail_hist.flg_orgn_donation_agency%TYPE,
        i_flg_report_of_death        IN discharge_detail_hist.flg_report_of_death%TYPE,
        i_flg_coroner_contacted      IN discharge_detail_hist.flg_coroner_contacted%TYPE,
        i_coroner_name               IN discharge_detail_hist.coroner_name%TYPE,
        i_flg_funeral_home_contacted IN discharge_detail_hist.flg_funeral_home_contacted%TYPE,
        i_funeral_home_name          IN discharge_detail_hist.funeral_home_name%TYPE,
        i_dt_body_removed            IN VARCHAR2,
        i_notes                      IN discharge_hist.notes_med%TYPE,
        i_flg_print_report           IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files      IN discharge_hist.id_discharge_flash_files%TYPE,
        i_death_characterization     IN discharge_detail_hist.id_death_characterization%TYPE DEFAULT NULL,
        i_death_process_registration IN discharge_detail.death_process_registration%TYPE DEFAULT NULL,
        i_dt_med                     IN VARCHAR2,
        i_oper_treatment_detail      IN discharge_detail.oper_treatment_detail%TYPE,
        i_status_before_death        IN discharge_detail.status_before_death%TYPE,
        o_dsc                        OUT discharge_hist%ROWTYPE,
        o_dsd                        OUT discharge_detail_hist%ROWTYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest       := i_id_disch_reas_dest;
        o_dsc.id_discharge             := r_dsc.id_discharge;
        o_dsc.id_discharge_hist        := i_id_discharge_hist;
        o_dsc.id_episode               := i_id_episode;
        o_dsc.id_prof_med              := i_prof.id;
        o_dsc.dt_med_tstz              := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL),
                                              nvl(r_dsc.dt_med_tstz, current_timestamp));
        o_dsc.notes_med                := i_notes;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition          := i_flg_pat_condition;
        o_dsd.dt_death_tstz              := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_death, NULL);
        o_dsd.prf_declared_death         := i_prf_declared_death;
        o_dsd.autopsy_consent_desc       := i_autopsy_consent_desc;
        o_dsd.flg_orgn_donation_agency   := i_flg_orgn_donation_agency;
        o_dsd.flg_report_of_death        := i_flg_report_of_death;
        o_dsd.flg_coroner_contacted      := i_flg_coroner_contacted;
        o_dsd.coroner_name               := i_coroner_name;
        o_dsd.flg_funeral_home_contacted := i_flg_funeral_home_contacted;
        o_dsd.funeral_home_name          := i_funeral_home_name;
        o_dsd.dt_body_removed_tstz       := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_body_removed, NULL);
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report           := i_flg_print_report;
        o_dsd.id_death_characterization  := i_death_characterization;
        o_dsd.death_process_registration := i_death_process_registration;
    
        -- CMF    
        o_dsd.oper_treatment_detail := i_oper_treatment_detail;
        o_dsd.status_before_death   := i_status_before_death;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_EXPIRED_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_expired_disposition;

    FUNCTION set_admission_disposition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_status          IN discharge_hist.flg_status%TYPE,
        i_discharge_status    IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest  IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist   IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition   IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_id_prof_admitting   IN discharge_detail_hist.id_prof_admitting%TYPE,
        i_dt_med              IN VARCHAR2,
        i_admission_orders    IN discharge_detail_hist.admission_orders%TYPE,
        i_notes_med           IN discharge_hist.notes_med%TYPE,
        i_admit_to_room       IN discharge_detail_hist.admit_to_room%TYPE,
        i_room_admit          IN discharge_detail_hist.id_room_admit%TYPE,
        i_vs_taken            IN discharge_detail_hist.vs_taken%TYPE,
        i_intake_output_done  IN discharge_detail_hist.intake_output_done%TYPE,
        i_flg_check_valuables IN discharge_detail_hist.flg_check_valuables%TYPE,
        i_prof_admitting_desc IN discharge_detail_hist.prof_admitting_desc%TYPE,
        i_flg_med_reconcile   IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_flg_print_report    IN discharge_detail_hist.flg_print_report%TYPE,
        --
        i_id_dep_clin_serv_admit IN discharge_detail.id_dep_clin_serv_admiting%TYPE,
        i_flg_surgery            IN VARCHAR2,
        i_dt_surgery_str         IN VARCHAR2,
        --
        i_discharge_flash_files IN discharge_hist.id_discharge_flash_files%TYPE,
        i_id_admitting_doctor   IN discharge_detail_hist.id_admitting_doctor%TYPE,
        i_id_written_by         IN discharge_detail_hist.id_written_by%TYPE,
        i_flg_compulsory        IN discharge_detail_hist.flg_compulsory%TYPE,
        i_id_compulsory_reason  IN discharge_detail_hist.id_compulsory_reason%TYPE,
        i_compulsory_reason     IN discharge_detail_hist.compulsory_reason%TYPE,
        o_dsc                   OUT discharge_hist%ROWTYPE,
        o_dsd                   OUT discharge_detail_hist%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    
        l_dt_med    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL);
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest       := i_id_disch_reas_dest;
        o_dsc.id_discharge             := r_dsc.id_discharge;
        o_dsc.id_discharge_hist        := i_id_discharge_hist;
        o_dsc.id_episode               := i_id_episode;
        o_dsc.id_prof_med              := i_prof.id;
        o_dsc.dt_med_tstz              := least(l_dt_med, l_timestamp);
        o_dsc.notes_med                := i_notes_med;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition   := i_flg_pat_condition;
        o_dsd.id_prof_admitting   := i_id_prof_admitting;
        o_dsd.admission_orders    := i_admission_orders;
        o_dsd.admit_to_room       := i_admit_to_room;
        o_dsd.id_room_admit       := i_room_admit;
        o_dsd.vs_taken            := i_vs_taken;
        o_dsd.intake_output_done  := i_intake_output_done;
        o_dsd.flg_check_valuables := i_flg_check_valuables;
        -- José Brito 30/05/2008 Adicionados novos campos ao ecrã
        o_dsd.prof_admitting_desc := i_prof_admitting_desc;
        o_dsd.flg_med_reconcile   := i_flg_med_reconcile;
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
        --
        o_dsd.flg_surgery               := i_flg_surgery;
        o_dsd.date_surgery_tstz         := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_surgery_str, NULL);
        o_dsd.id_dep_clin_serv_admiting := i_id_dep_clin_serv_admit;
        o_dsd.id_admitting_doctor       := i_id_admitting_doctor;
        o_dsd.id_written_by             := i_id_written_by;
        o_dsd.flg_compulsory            := i_flg_compulsory;
        o_dsd.id_compulsory_reason      := i_id_compulsory_reason;
        o_dsd.compulsory_reason         := i_compulsory_reason;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_ADMISSION_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_admission_disposition;

    FUNCTION get_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT category.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM category cat, professional prf, prof_cat prc
             WHERE prf.id_professional = i_prof.id
               AND prc.id_professional = prf.id_professional
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category;
    BEGIN
    
        FOR cat IN c_cat
        LOOP
            o_category := cat.flg_type;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_CATEGORY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_category;

    FUNCTION get_lwbs_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_disch_letter_list_exception VARCHAR2(0050);
        err_get_profile_template EXCEPTION;
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       -- José Brito 30/05/2008 "Reason for visit" não é usado neste tipo de alta
                       --                       e "Reason for leaving" não era devolvido. 
                       --ddh.reason_for_visit reason_for_visit,
                       ddh.reason_for_leaving reason_for_leaving,
                       --
                       ddh.flg_risk_of_leaving flg_risk_of_leaving,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang) desc_risk_of_leaving,
                       ddh.flg_pat_escorted_by flg_pat_escorted_by,
                       decode(ddh.flg_pat_escorted_by,
                              l_disch_letter_list_exception,
                              ddh.desc_pat_escorted_by,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                      ddh.flg_pat_escorted_by,
                                                      i_lang)) desc_pat_escorted_by,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- José Brito 30/05/2008 Novos campos no ecrã
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition,
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        
        ELSE
            pk_types.open_my_cursor(o_sql);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_LWBS_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_LWBS_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_lwbs_disposition;

    FUNCTION get_mse_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        err_get_profile_template EXCEPTION;
        l_disch_letter_list_exception VARCHAR2(0050);
    
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       ddh.mse_type mse_type,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL.MSE_TYPE', ddh.mse_type, i_lang) desc_mse_type,
                       ddh.flg_med_reconcile flg_med_reconcile,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) desc_flg_med_reconcile,
                       ddh.flg_prescription_given flg_prescription_given,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang) desc_prescription_given,
                       ddh.flg_written_notes flg_written_notes,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang) desc_flg_written_notes,
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_med_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_med,
                       ddh.flg_instructions_discussed,
                       decode(ddh.flg_instructions_discussed,
                              l_disch_letter_list_exception,
                              ddh.instructions_discussed_notes,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                      ddh.flg_instructions_discussed,
                                                      i_lang)) instructions_discussed_notes,
                       ddh.instructions_understood,
                       pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang) desc_instructions_understood,
                       ddh.vs_taken vs_taken,
                       pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang) desc_vs_taken,
                       ddh.intake_output_done intake_output_done,
                       pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang) desc_intake_output_done,
                       ddh.flg_patient_transport flg_patient_transport,
                       decode(ddh.flg_patient_transport,
                              l_disch_letter_list_exception,
                              ddh.desc_patient_transport,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                      ddh.flg_patient_transport,
                                                      i_lang)) desc_patient_transport,
                       ddh.flg_pat_escorted_by,
                       decode(ddh.flg_pat_escorted_by,
                              l_disch_letter_list_exception,
                              ddh.desc_pat_escorted_by,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                      ddh.flg_pat_escorted_by,
                                                      i_lang)) desc_flg_pat_escorted_by,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- José Brito 02/06/2008 Novos campos adicionados ao ecrã
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        
        ELSE
        
            pk_types.open_my_cursor(o_sql);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_MSE_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_MSE_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_mse_disposition;

    FUNCTION get_ama_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_disch_letter_list_exception VARCHAR2(0050);
    
        err_get_profile_template EXCEPTION;
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       ddh.risk_of_leaving,
                       ddh.flg_risk_of_leaving flg_risk_of_leaving,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang) desc_risk_of_leaving,
                       pk_date_utils.date_send_tsz(i_lang, ddh.dt_ama_tstz, i_prof.institution, i_prof.software) dt_ama_flash,
                       pk_date_utils.date_char_tsz(i_lang, ddh.dt_ama_tstz, i_prof.institution, i_prof.software) dt_ama,
                       dh.notes_med additional_notes,
                       ddh.flg_signed_ama_form flg_signed_ama_form,
                       
                       decode(ddh.flg_signed_ama_form,
                              l_disch_letter_list_exception,
                              ddh.desc_signed_ama_form,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_SIGNED_AMA_FORM',
                                                      ddh.flg_signed_ama_form,
                                                      i_lang)) desc_signed_ama_form,
                       ddh.flg_pat_escorted_by flg_pat_escorted_by,
                       decode(ddh.flg_pat_escorted_by,
                              l_disch_letter_list_exception,
                              ddh.desc_pat_escorted_by,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                      ddh.flg_pat_escorted_by,
                                                      i_lang)) desc_pat_escorted_by,
                       ddh.flg_patient_transport flg_patient_transport,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                               ddh.flg_patient_transport,
                                               i_lang) desc_patient_transport,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- José Brito 30/05/2008 Novos campos no ecrã
                       ddh.reason_for_leaving reason_for_leaving,
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_AMA_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_AMA_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_ama_disposition;

    FUNCTION get_expired_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        err_get_profile_template EXCEPTION;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       dh.id_discharge_hist,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       pk_date_utils.date_send_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software) dt_death_flash,
                       pk_date_utils.date_char_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software) dt_death,
                       ddh.prf_declared_death,
                       ddh.flg_autopsy_consent,
                       ddh.autopsy_consent_desc desc_autopsy_consent,
                       ddh.flg_orgn_donation_agency flg_orgn_donation_agency,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_orgn_donation_agency, i_lang) desc_flg_orgn_donation_agency,
                       ddh.flg_report_of_death flg_report_of_death,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_report_of_death, i_lang) desc_report_of_death,
                       ddh.flg_coroner_contacted flg_coroner_contacted,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_coroner_contacted, i_lang) desc_coroner_contacted,
                       ddh.coroner_name,
                       ddh.flg_funeral_home_contacted flg_funeral_home_contacted,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_funeral_home_contacted, i_lang) dsc_flg_funeral_home_contacted,
                       ddh.funeral_home_name,
                       pk_date_utils.date_send_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software) dt_death_flash,
                       pk_date_utils.date_char_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software) dt_death,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   ddh.dt_body_removed_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_body_removed_flash,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ddh.dt_body_removed_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_body_removed,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- José Brito 02/06/2008 Novos campos adicionados ao ecrã
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       ddh.id_death_characterization,
                       pk_translation.get_translation_trs(i_code_mess => ddh.code_death_event) death_characterization,
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition,
                       ddh.death_process_registration death_process_number,
                       ddh.death_process_registration death_process_number_flash,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_EXPIRED_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_EXPIRED_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_expired_disposition;

    FUNCTION get_transfer_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        err_get_profile_template EXCEPTION;
        l_disch_letter_list_exception VARCHAR2(0050);
        l_sc_clues                    sys_config.value%TYPE;
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
        l_sc_clues                    := pk_sysconfig.get_config('DISCHARGE_TRANSFER_CLUES', i_prof);
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       ddh.reason_of_transfer,
                       -- José Brito 30/05/2008 Campo "Reason of transfer" passa a aceitar texto livre
                       nvl(ddh.reason_of_transfer_desc,
                           pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.REASON_OF_TRANSFER',
                                                   ddh.reason_of_transfer,
                                                   i_lang)) desc_reason_of_transfer,
                       ddh.flg_transfer_transport,
                       decode(ddh.flg_transfer_transport,
                              l_disch_letter_list_exception,
                              ddh.desc_transfer_transport,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_TRANSFER_TRANSPORT',
                                                      ddh.flg_transfer_transport,
                                                      i_lang)) desc_transfer_transport,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   ddh.dt_transfer_transport_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_transfer_transport_flash,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ddh.dt_transfer_transport_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_transfer_transport,
                       ddh.risk_of_transfer,
                       ddh.benefits_of_transfer,
                       ddh.flg_med_reconcile,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) desc_flg_med_reconcile,
                       ddh.prof_admitting_desc prof_admitting,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   ddh.dt_prof_admiting_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_prof_admiting_flash,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ddh.dt_prof_admiting_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_prof_admiting,
                       ddh.en_route_orders en_route_orders,
                       ddh.flg_patient_consent,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_CONSENT',
                                               ddh.flg_patient_consent,
                                               i_lang) desc_patient_consent,
                       ddh.acceptance_facility,
                       ddh.admitting_room,
                       ddh.room_assigned_by,
                       ddh.items_sent_with_patient,
                       ddh.vs_taken vs_taken,
                       pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang) desc_vs_taken,
                       ddh.intake_output_done intake_output_done,
                       pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang) desc_intake_output_done,
                       dh.notes_med additional_notes,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- José Brito 30/05/2007 Novos campos
                       ddh.report_given_to,
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition,
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       ddh.id_inst_transfer,
                       decode(l_sc_clues,
                              pk_alert_constant.g_yes,
                              pk_translation.get_translation(i_lang, tinst.code_institution)) desc_inst_transfer,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  LEFT JOIN discharge_dest dst
                    ON dst.id_discharge_dest = drd.id_discharge_dest
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  LEFT JOIN institution dd
                    ON dd.id_institution = drd.id_institution
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN institution tinst
                    ON tinst.id_institution = ddh.id_inst_transfer
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_TRANSFER_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_TRANSFER_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_transfer_disposition;

    /*
    * set records outdated
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   i_id_discharge    id de alta
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   22-Oct-2007
    */
    FUNCTION set_outdated
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN discharge.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode discharge.id_episode%TYPE;
    BEGIN
    
        g_error := 'upd discharge_hist episode:' || l_id_episode;
        UPDATE discharge_hist
           SET flg_status_hist = g_outdated
         WHERE id_episode = i_id_episode
           AND flg_status_hist != g_outdated; --IN (g_active, g_pendente);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_OUTDATED',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_outdated;

    /********************************************************************************************
    * Get the discharge destination label.
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_disch_reas_dest      Discharge destination record ID
    *                        
    * @return  Discharge destination label
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          09-FEB-2011
    **********************************************************************************************/
    FUNCTION get_disch_dest_label
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DISCH_DEST_LABEL';
        l_discharge_dest  VARCHAR2(4000 CHAR);
        l_disch_reas_dest disch_reas_dest%ROWTYPE;
        l_error           t_error_out;
    BEGIN
    
        g_error := 'GET ROW DISCH_REAS_DEST';
        SELECT drd.*
          INTO l_disch_reas_dest
          FROM disch_reas_dest drd
         WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest;
    
        IF l_disch_reas_dest.id_discharge_dest IS NOT NULL
        THEN
            -- Discharge destination: predefined discharge (Home/A.M.A./L.W.B.S/etc.)
            g_error := 'GET LABEL - DISCHARGE_DEST';
            SELECT pk_translation.get_translation(i_lang, dd.code_discharge_dest)
              INTO l_discharge_dest
              FROM discharge_dest dd
             WHERE dd.id_discharge_dest = l_disch_reas_dest.id_discharge_dest;
        
        ELSIF l_disch_reas_dest.id_dep_clin_serv IS NOT NULL
        THEN
            -- Legacy support: DISCH_REAS_DEST.ID_DEP_CLIN_SERV is deprecated.
            g_error := 'GET LABEL - DEP_CLIN_SERV';
            SELECT nvl2(l_disch_reas_dest.id_department,
                        pk_translation.get_translation(i_lang, d.code_department) || ' - ',
                        '') || pk_translation.get_translation(i_lang, cs.code_clinical_service)
              INTO l_discharge_dest
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
              JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             WHERE dcs.id_dep_clin_serv = l_disch_reas_dest.id_dep_clin_serv;
        
        ELSIF l_disch_reas_dest.id_institution IS NOT NULL
        THEN
            -- Discharge destination: other institution
            g_error := 'GET LABEL - INSTITUTION';
            SELECT pk_translation.get_translation(i_lang, i.code_institution)
              INTO l_discharge_dest
              FROM institution i
             WHERE i.id_institution = l_disch_reas_dest.id_institution;
        
        ELSIF l_disch_reas_dest.id_department IS NOT NULL
        THEN
            -- Discharge destination: institution deparment
            g_error := 'GET LABEL - DEPARTMENT';
            SELECT pk_translation.get_translation(i_lang, d.code_department)
              INTO l_discharge_dest
              FROM department d
             WHERE d.id_department = l_disch_reas_dest.id_department;
        END IF;
    
        RETURN l_discharge_dest;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_disch_dest_label;

    /********************************************************************************************
     * Function that gets data from table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_id_discharge_hist   id de registo de alta se exisitir
     * @param O_sql           id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/15
    ********************************************************************************************/
    FUNCTION get_admission_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest,
                       drd.id_discharge_reason,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       -- Alexandre Santos 23-04-2009
                       -- Quando o id_professional é null significa que o campo é do tipo texto livre
                       nvl(to_char(ddh.id_prof_admitting), 'O') id_admitting_physician,
                       -- José Brito 30/05/2008 Adicionados novos campos ao ecrã
                       nvl(ddh.prof_admitting_desc,
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_admitting)
                              FROM dual)) prof_admitting,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) med_reconcile,
                       ddh.flg_med_reconcile,
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       --
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_admitting)
                          FROM dual) admitting_physician,
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition,
                       ddh.admission_orders admission_orders,
                       dh.notes_med additional_notes,
                       get_room_admit(i_lang, i_prof, ddh.id_room_admit, ddh.admit_to_room) admit_to_room,
                       nvl(ddh.id_room_admit, -1) id_room_admit,
                       ddh.vs_taken vs_taken,
                       pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang) desc_vs_taken,
                       ddh.intake_output_done intake_output_done,
                       pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang) desc_intake_output_done,
                       ddh.flg_check_valuables flg_check_valuables,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_check_valuables, i_lang) desc_flg_check_valuables,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof) date_cancel,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang) desc_flg_print_report,
                       -- José Brito 08/02/2011 ALERT-151982
                       ddh.id_dep_clin_serv_admiting id_dep_clin_serv,
                       nvl2(ddh.id_dep_clin_serv_admiting,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service),
                            '') desc_dep_clin_serv,
                       ddh.flg_surgery,
                       nvl2(ddh.flg_surgery,
                            pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORIS', ddh.flg_surgery, i_lang),
                            '') desc_surgery,
                       pk_date_utils.date_send_tsz(i_lang, ddh.date_surgery_tstz, i_prof.institution, i_prof.software) dt_surgery_flash,
                       pk_date_utils.date_char_tsz(i_lang, ddh.date_surgery_tstz, i_prof.institution, i_prof.software) dt_surgery,
                       ddh.id_admitting_doctor,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_admitting_doctor)
                          FROM dual) admitting_doctor,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by_flash,
                       pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by,
                       i_prof.id id_written_by,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id)
                          FROM dual) written_by,
                       ddh.flg_compulsory,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_compulsory, i_lang) desc_flg_compulsory,
                       ddh.id_compulsory_reason,
                       decode(ddh.id_compulsory_reason,
                              NULL,
                              '',
                              -1,
                              ddh.compulsory_reason,
                              pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, ddh.id_compulsory_reason)) desc_id_compulsory_reason
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON ddh.id_discharge_hist = dh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON dr.id_discharge_reason = drd.id_discharge_reason
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = ddh.id_dep_clin_serv_admiting
                  LEFT JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_ADMISSION_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_admission_disposition;

    /*
    * get list of destination for type of discharge
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF                        - professional, institution and software ids
    * @param   I_ID_DISCH_REASON             - ID motivo de alta
    * @param   O_DISCH_DEST_LIST             - array de destinos de alta
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   2007-10-17
    */
    FUNCTION get_discharge_dest_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_disch_reason IN discharge_reason.id_discharge_reason%TYPE,
        o_disch_dest_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_type               category.flg_type%TYPE;
        l_flg_type_disch     discharge_reason.flg_type%TYPE;
        l_flg_hhc_disch      VARCHAR2(0050 CHAR);
        l_id_disch_reas_dest disch_reas_dest.id_disch_reas_dest%TYPE;
        l_adm_separate       sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_ADMISSION_SEPARATE', i_prof);
        l_file_to_execute    discharge_reason.file_to_execute%TYPE;
    BEGIN
    
        SELECT dr.flg_type, flg_hhc_disch, file_to_execute
          INTO l_flg_type_disch, l_flg_hhc_disch, l_file_to_execute
          FROM discharge_reason dr
         WHERE dr.id_discharge_reason = i_id_disch_reason;
    
        IF l_flg_type_disch IS NULL
        THEN
            g_error := 'GET PROF CAT';
            l_type  := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'GET CURSOR';
            OPEN o_disch_dest_list FOR
                SELECT drd.id_disch_reas_dest,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) desc_discharge_dest,
                       dcs.id_dep_clin_serv,
                       dpt.id_department,
                       dpt.flg_type,
                       drd.id_epis_type,
                       CASE
                            WHEN l_file_to_execute = pk_discharge.g_disch_screen_disp_admit
                                 AND l_adm_separate = pk_alert_constant.g_yes THEN
                             pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T025')
                            ELSE
                             pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T002')
                        END dest_title,
                       drd.rank,
                       -- José Brito 03/03/2009 ALERT-10317
                       -- Indicates whether the discharge destination should be specified with free text.
                       -- Applicable only to the type of disposition "Transfer".
                       drd.flg_specify_dest,
                       CASE
                            WHEN l_flg_hhc_disch = pk_alert_constant.g_yes
                                 AND rownum = 1 THEN
                             'A'
                            ELSE
                             decode(drd.flg_default, pk_alert_constant.g_yes, 'A', 'I')
                        END selected_flg
                  FROM disch_reas_dest drd
                  LEFT JOIN discharge_dest dd
                    ON dd.id_discharge_dest = drd.id_discharge_dest
                   AND dd.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN department dpt
                    ON dpt.id_department = drd.id_department
                  LEFT JOIN institution i
                    ON i.id_institution = drd.id_institution
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                 WHERE drd.id_discharge_reason = i_id_disch_reason
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = i_prof.software
                   AND drd.flg_active = g_active
                   AND (drd.id_dep_clin_serv IS NULL OR drd.id_department IS NOT NULL)
                   AND (dd.id_discharge_dest = drd.id_discharge_dest OR drd.id_discharge_dest IS NULL)
                UNION ALL
                SELECT drd.id_disch_reas_dest,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_discharge_dest,
                       NULL id_dep_clin_serv,
                       NULL id_department,
                       NULL flg_type,
                       drd.id_epis_type,
                       pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T002') dest_title,
                       drd.rank,
                       -- José Brito 03/03/2009 ALERT-10317
                       -- Indicates whether the discharge destination should be specified with free text.
                       -- Applicable only to the type of disposition "Transfer".
                       drd.flg_specify_dest,
                       decode(drd.flg_default, pk_alert_constant.g_yes, 'A', 'I') selected_flg
                  FROM disch_reas_dest drd
                  JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  JOIN clinical_service cs
                    ON cs.id_clinical_service = dcs.id_clinical_service
                 WHERE drd.id_discharge_reason = i_id_disch_reason
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = i_prof.software
                   AND drd.flg_active = g_active
                   AND drd.id_department IS NULL
                 ORDER BY rank, desc_discharge_dest;
        
        ELSIF l_flg_type_disch = 'P'
        THEN
            -- neste caso só pode haver um registo em disch_reas_Dest com nenhum destino parametrizado
            -- este query retorna todos os medicos da institutição
            g_error := 'GET UNIQUE DISCH_RAS_DEST';
            SELECT drd.id_disch_reas_dest
              INTO l_id_disch_reas_dest
              FROM disch_reas_dest drd
             WHERE drd.id_discharge_reason = i_id_disch_reason
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = g_active;
        
            OPEN o_disch_dest_list FOR
                SELECT l_id_disch_reas_dest id_disch_reas_dest,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional)
                          FROM dual) desc_disch_reas_dest,
                       prf.id_professional id_professional,
                       pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T005') dest_title,
                       pk_schedule.has_permission(i_lang, i_prof, NULL, g_sch_event_id_followup, prf.id_professional) permission
                  FROM professional prf, prof_cat pct, category cat, prof_soft_inst psi, prof_institution pi
                 WHERE psi.id_institution = i_prof.institution
                   AND psi.id_software = i_prof.software
                   AND pct.id_institution = i_prof.institution
                   AND cat.flg_type = 'D'
                   AND prf.flg_state = g_active
                   AND prf.id_professional = pct.id_professional
                   AND prf.id_professional = psi.id_professional
                   AND pi.id_professional = prf.id_professional
                   AND pi.id_institution = psi.id_institution
                   AND pi.dt_end_tstz IS NULL
                   AND pi.flg_state = g_active
                   AND pct.id_category = cat.id_category
                 ORDER BY desc_disch_reas_dest;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCHARGE_DEST_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_disch_dest_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_dest_list;

    /*
    * get professional category
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_PROF_CATEGORY CATEGORIA DO PROFISSIONAL
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_profile_template
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_id_profile_template OUT profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tmp IS
            SELECT prt.id_profile_template
              FROM profile_template prt, prof_profile_template ppt
             WHERE ppt.id_profile_template = prt.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND prt.id_software = i_prof.software;
    
    BEGIN
    
        OPEN c_tmp;
        FETCH c_tmp
            INTO o_id_profile_template;
        CLOSE c_tmp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_PROFILE_TEMPLATE',
                                              o_error);
            RETURN FALSE;
    END get_profile_template;

    /*
    * get professional category
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_PROF_CATEGORY CATEGORIA DO PROFISSIONAL
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_prof_category
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_prof_category OUT category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cat IS
            SELECT flg_type
              FROM prof_cat pc, category ct
             WHERE pc.id_professional = i_prof.id
               AND pc.id_category = ct.id_category
               AND pc.id_institution = i_prof.institution
               AND ct.flg_available = g_yes;
    
    BEGIN
    
        OPEN c_cat;
        FETCH c_cat
            INTO o_prof_category;
        CLOSE c_cat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_PROF_CATEGORY',
                                              o_error);
            RETURN FALSE;
    END get_prof_category;
    -- ###########################################################

    /*
    * Get physician summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION get_physician_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                 BOOLEAN;
        l_sep                 VARCHAR2(0050);
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
        tit_pat_condition             sys_message.desc_message%TYPE;
        tit_med_reconcile             sys_message.desc_message%TYPE;
        tit_prescription_given        sys_message.desc_message%TYPE;
        tit_discharge_date_time       sys_message.desc_message%TYPE;
        tit_add_notes                 sys_message.desc_message%TYPE;
        tit_admiting_physician        sys_message.desc_message%TYPE;
        tit_admission_orders          sys_message.desc_message%TYPE;
        tit_reason_of_transfer        sys_message.desc_message%TYPE;
        tit_trf_mode_transport        sys_message.desc_message%TYPE;
        tit_dt_trf_mode_transport     sys_message.desc_message%TYPE;
        tit_risk_of_transfer          sys_message.desc_message%TYPE;
        tit_benefits_of_transfer      sys_message.desc_message%TYPE;
        tit_accepting_physician       sys_message.desc_message%TYPE;
        tit_dt_accepting_physician    sys_message.desc_message%TYPE;
        tit_en_route_orders           sys_message.desc_message%TYPE;
        tit_autopsy_consent           sys_message.desc_message%TYPE;
        tit_dt_death                  sys_message.desc_message%TYPE;
        tit_prf_declared_death        sys_message.desc_message%TYPE;
        tit_risk_of_leaving           sys_message.desc_message%TYPE;
        tit_advised_risk_of_leaving   sys_message.desc_message%TYPE;
        tit_mse                       sys_message.desc_message%TYPE;
        tit_dt_ama                    sys_message.desc_message%TYPE;
        l_disch_letter_list_exception VARCHAR2(0050);
        err_get_profile_template EXCEPTION;
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_get_profile_template;
        END IF;
    
        l_sep                       := ':';
        tit_pat_condition           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T003');
        tit_med_reconcile           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T006');
        tit_prescription_given      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T007');
        tit_discharge_date_time     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T008');
        tit_add_notes               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T005');
        tit_admiting_physician      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T003');
        tit_admission_orders        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T007');
        tit_reason_of_transfer      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T008');
        tit_trf_mode_transport      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T009');
        tit_dt_trf_mode_transport   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T010');
        tit_risk_of_transfer        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T011');
        tit_benefits_of_transfer    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T012');
        tit_accepting_physician     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T003');
        tit_dt_accepting_physician  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T013');
        tit_en_route_orders         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T014');
        tit_autopsy_consent         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T001');
        tit_dt_death                := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T007');
        tit_prf_declared_death      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T008');
        tit_risk_of_leaving         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T006');
        tit_advised_risk_of_leaving := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T007');
        tit_dt_ama                  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T009');
        tit_mse                     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_MSE_T001');
    
        g_error := 'GET CURSOR';
        OPEN o_info FOR
            SELECT l_disch_letter_list_exception letter_list_exception,
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_created_hist, i_prof.institution, i_prof.software) rec_date,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist)
                      FROM dual) rec_name,
                   drd.id_disch_reas_dest id_disch_reas_dest,
                   dh.flg_status flg_status,
                   dh.id_discharge_hist id_discharge_hist,
                   dff.file_name file_to_execute,
                   dff2.file_name file_to_execute_secondary,
                   dff.flg_type disposition_flg_type,
                   upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang)) desc_flg_status,
                   pk_translation.get_translation(i_lang, dr.code_discharge_reason) || l_sep ||
                   pk_translation.get_translation(i_lang,
                                                  decode(dff.flg_type,
                                                         g_disp_adms,
                                                         nvl(dpt.code_department, dd.code_discharge_dest),
                                                         g_disp_tran,
                                                         nvl(ins.code_institution, dd.code_discharge_dest),
                                                         dd.code_discharge_dest)) l_disposition,
                   pk_translation.get_translation(i_lang,
                                                  decode(dff.flg_type,
                                                         g_disp_adms,
                                                         nvl(dpt.code_department, dd.code_discharge_dest),
                                                         g_disp_tran,
                                                         nvl(ins.code_institution, dd.code_discharge_dest),
                                                         dd.code_discharge_dest)) l_to,
                   decode(dff.flg_type,
                          g_disp_expi,
                          NULL,
                          tit_pat_condition || l_sep ||
                          pk_discharge.get_patient_condition(i_lang,
                                                             i_prof,
                                                             dh.id_discharge,
                                                             dr.id_discharge_reason,
                                                             ddh.flg_pat_condition)) pat_condition,
                   NULL field03,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang),
                          g_disp_adms,
                          tit_admiting_physician || l_sep ||
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ddh.id_prof_admitting)
                             FROM dual),
                          g_disp_tran,
                          tit_reason_of_transfer || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.REASON_OF_TRANSFER',
                                                  ddh.reason_of_transfer,
                                                  i_lang),
                          g_disp_expi,
                          tit_dt_death || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, ddh.dt_death_tstz, i_prof.institution, i_prof.software),
                          g_disp_ama,
                          tit_risk_of_leaving || l_sep || ddh.risk_of_leaving,
                          g_disp_mse,
                          tit_mse || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL.MSE_TYPE', ddh.mse_type, i_lang)) field04,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang),
                          g_disp_adms,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software),
                          g_disp_tran,
                          tit_trf_mode_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_TRANSFER_TRANSPORT',
                                                  decode(l_disch_letter_list_exception,
                                                         ddh.desc_transfer_transport,
                                                         ddh.flg_transfer_transport),
                                                  i_lang),
                          g_disp_expi,
                          tit_prf_declared_death || l_sep || ddh.prf_declared_death,
                          g_disp_ama,
                          tit_advised_risk_of_leaving || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang),
                          g_disp_mse,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang)) field05,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software),
                          g_disp_adms,
                          tit_admission_orders || l_sep || ddh.admission_orders,
                          g_disp_tran,
                          tit_dt_trf_mode_transport || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_transfer_transport_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          g_disp_expi,
                          tit_autopsy_consent || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_autopsy_consent, i_lang),
                          g_disp_ama,
                          tit_dt_ama || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, ddh.dt_ama_tstz, i_prof.institution, i_prof.software),
                          g_disp_mse,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang)) field06,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_risk_of_transfer || l_sep || ddh.risk_of_transfer,
                          g_disp_mse,
                          tit_discharge_date_time || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software)) field07,
                   decode(dff.flg_type, g_disp_tran, tit_benefits_of_transfer || l_sep || ddh.benefits_of_transfer) field08,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_med_reconcile || l_sep || pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE',
                                                                                ddh.flg_med_reconcile,
                                                                                i_lang)) field09,
                   decode(dff.flg_type, g_disp_tran, tit_accepting_physician || l_sep || ddh.prof_admitting_desc) field10,
                   decode(dff.flg_type,
                          g_disp_tran,
                          tit_dt_accepting_physician || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_prof_admiting_tstz,
                                                      i_prof.institution,
                                                      i_prof.software)) field11,
                   decode(dff.flg_type, g_disp_tran, tit_en_route_orders || l_sep || ddh.en_route_orders) field12,
                   tit_add_notes || l_sep || dh.notes_med additional_notes
              FROM discharge_hist        dh,
                   discharge_detail_hist ddh,
                   disch_reas_dest       drd,
                   discharge_reason      dr,
                   discharge_flash_files dff,
                   discharge_flash_files dff2,
                   category              cat,
                   profile_template      prt,
                   discharge_dest        dd,
                   department            dpt,
                   institution           ins
             WHERE dh.id_episode = i_id_episode
               AND dh.id_discharge_hist = ddh.id_discharge_hist
               AND dh.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = dr.id_discharge_reason
               AND drd.id_discharge_dest = dd.id_discharge_dest(+)
               AND drd.id_department = dpt.id_department(+)
               AND drd.id_institution = ins.id_institution(+)
               AND dff.id_discharge_flash_files = dh.id_discharge_flash_files
               AND dh.id_profile_template = prt.id_profile_template
               AND prt.id_category = cat.id_category
               AND cat.flg_type = g_doctor
               AND dff.id_dsch_flsh_files_assoc = dff2.id_discharge_flash_files(+)
             ORDER BY dh.dt_created_hist DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_PHYSICIAN_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_PHYSICIAN_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_physician_summary;
    -- ###########################################################

    /*
    * Get nurse summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION get_nurse_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sep                          VARCHAR2(0500);
        tit_pat_condition              sys_message.desc_message%TYPE;
        tit_flg_instructions_discussed sys_message.desc_message%TYPE;
        tit_instructions_understood    sys_message.desc_message%TYPE;
        tit_prescription_given         sys_message.desc_message%TYPE;
        tit_written_instructions       sys_message.desc_message%TYPE;
        tit_vs_taken                   sys_message.desc_message%TYPE;
        tit_intake_output              sys_message.desc_message%TYPE;
        tit_flg_patient_transport      sys_message.desc_message%TYPE;
        tit_flg_pat_escorted_by        sys_message.desc_message%TYPE;
        tit_admit_to_room              sys_message.desc_message%TYPE;
        tit_flg_check_valuables        sys_message.desc_message%TYPE;
        tit_patient_consent            sys_message.desc_message%TYPE;
        tit_acceptance_facility        sys_message.desc_message%TYPE;
        tit_admitting_room             sys_message.desc_message%TYPE;
        tit_room_assigned_by           sys_message.desc_message%TYPE;
        tit_flg_items_sent_patient     sys_message.desc_message%TYPE;
        tit_flg_orgn_donation_agency   sys_message.desc_message%TYPE;
        tit_flg_report_of_death        sys_message.desc_message%TYPE;
        tit_flg_coroner_contacted      sys_message.desc_message%TYPE;
        tit_coroner_name               sys_message.desc_message%TYPE;
        tit_flg_funeral_home_contacted sys_message.desc_message%TYPE;
        tit_funeral_home_name          sys_message.desc_message%TYPE;
        tit_dt_body_removed            sys_message.desc_message%TYPE;
        tit_signed_ama_form            sys_message.desc_message%TYPE;
        tit_reason_for_visit           sys_message.desc_message%TYPE;
        tit_advised_risk_of_leaving    sys_message.desc_message%TYPE;
        tit_add_notes                  sys_message.desc_message%TYPE;
    
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_ret                 BOOLEAN;
    
        l_disch_letter_list_exception VARCHAR2(0050);
        err_get_profile_template EXCEPTION;
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_get_profile_template;
        END IF;
    
        l_sep                          := ':';
        tit_add_notes                  := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T005');
        tit_pat_condition              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T003');
        tit_flg_instructions_discussed := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T006');
        tit_instructions_understood    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T007');
        tit_prescription_given         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_COMMON_T007');
        tit_written_instructions       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T008');
        tit_vs_taken                   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T009');
        tit_intake_output              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T010');
        tit_flg_patient_transport      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T011');
        tit_flg_pat_escorted_by        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_DISCH_T012');
        tit_admit_to_room              := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T008');
        tit_flg_check_valuables        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_ADMIT_T009');
        tit_patient_consent            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T015');
        tit_acceptance_facility        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T016');
        tit_admitting_room             := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T017');
        tit_room_assigned_by           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T018');
        tit_flg_items_sent_patient     := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_TRANSFER_T019');
        tit_flg_orgn_donation_agency   := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T009');
        tit_flg_report_of_death        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T010');
        tit_flg_coroner_contacted      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T011');
        tit_coroner_name               := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T012');
        tit_flg_funeral_home_contacted := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T013');
        tit_funeral_home_name          := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T014');
        tit_dt_body_removed            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_EXPIRED_T015');
        tit_signed_ama_form            := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T008');
        tit_reason_for_visit           := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_LWBS_T006');
        tit_advised_risk_of_leaving    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_AMA_T007');
    
        g_error := 'GET CURSOR';
        OPEN o_info FOR
            SELECT l_disch_letter_list_exception letter_list_exception,
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_created_hist, i_prof.institution, i_prof.software) rec_date,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist)
                      FROM dual) rec_name,
                   drd.id_disch_reas_dest id_disch_reas_dest,
                   dh.flg_status flg_status,
                   --                   pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang) desc_flg_status,
                   dh.id_discharge_hist id_discharge_hist,
                   dff.file_name file_to_execute,
                   dff2.file_name file_to_execute_secondary,
                   dff.flg_type disposition_flg_type,
                   pk_translation.get_translation(i_lang, dr.code_discharge_reason) || l_sep ||
                   pk_translation.get_translation(i_lang,
                                                  decode(dff.flg_type,
                                                         g_disp_adms,
                                                         nvl(dpt.code_department, dd.code_discharge_dest),
                                                         g_disp_tran,
                                                         nvl(ins.code_institution, dd.code_discharge_dest),
                                                         dd.code_discharge_dest)) l_disposition,
                   --                   pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T008') || l_sep ||
                   pk_translation.get_translation(i_lang,
                                                  decode(dff.flg_type,
                                                         g_disp_adms,
                                                         nvl(dpt.code_department, dd.code_discharge_dest),
                                                         g_disp_tran,
                                                         nvl(ins.code_institution, dd.code_discharge_dest),
                                                         dd.code_discharge_dest)) l_to,
                   upper(pk_sysdomain.get_domain('DISCHARGE_HIST.FLG_STATUS', dh.flg_status, i_lang)) desc_flg_status,
                   decode(dff.flg_type,
                          g_disp_expi,
                          NULL,
                          tit_pat_condition || l_sep ||
                          pk_discharge.get_patient_condition(i_lang,
                                                             i_prof,
                                                             dh.id_discharge,
                                                             dr.id_discharge_reason,
                                                             ddh.flg_pat_condition)) pat_condition,
                   NULL field03,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_flg_instructions_discussed || l_sep ||
                          decode(ddh.flg_instructions_discussed,
                                 l_disch_letter_list_exception,
                                 ddh.instructions_discussed_notes,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                         ddh.flg_instructions_discussed,
                                                         i_lang)),
                          g_disp_adms,
                          tit_admit_to_room || l_sep ||
                          get_room_admit(i_lang, i_prof, ddh.id_room_admit, ddh.admit_to_room),
                          g_disp_tran,
                          tit_patient_consent || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_CONSENT',
                                                  ddh.flg_patient_consent,
                                                  i_lang),
                          g_disp_expi,
                          tit_flg_orgn_donation_agency || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_orgn_donation_agency, i_lang),
                          g_disp_ama,
                          tit_signed_ama_form || l_sep ||
                          decode(ddh.flg_signed_ama_form,
                                 l_disch_letter_list_exception,
                                 ddh.desc_signed_ama_form,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_SIGNED_AMA_FORM',
                                                         ddh.flg_signed_ama_form,
                                                         i_lang)),
                          g_disp_mse,
                          tit_flg_instructions_discussed || l_sep ||
                          decode(ddh.flg_instructions_discussed,
                                 l_disch_letter_list_exception,
                                 ddh.instructions_discussed_notes,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                         ddh.flg_instructions_discussed,
                                                         i_lang)),
                          g_disp_lwbs,
                          tit_reason_for_visit || l_sep || ddh.reason_for_visit) field04,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_instructions_understood || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang),
                          g_disp_adms,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang),
                          g_disp_tran,
                          tit_acceptance_facility || l_sep || ddh.acceptance_facility,
                          g_disp_expi,
                          tit_flg_report_of_death || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_report_of_death, i_lang),
                          g_disp_ama,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang)),
                          g_disp_mse,
                          tit_instructions_understood || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang),
                          g_disp_lwbs,
                          tit_advised_risk_of_leaving || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_risk_of_leaving, i_lang)) field05,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang),
                          g_disp_adms,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang),
                          g_disp_tran,
                          tit_admitting_room || l_sep || ddh.admitting_room,
                          g_disp_expi,
                          tit_flg_coroner_contacted || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_coroner_contacted, i_lang),
                          g_disp_ama,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang),
                          g_disp_mse,
                          tit_prescription_given || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang),
                          g_disp_lwbs,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang))) field06,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang),
                          g_disp_adms,
                          tit_flg_check_valuables || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_check_valuables, i_lang),
                          g_disp_tran,
                          tit_room_assigned_by || l_sep || ddh.room_assigned_by,
                          g_disp_expi,
                          tit_coroner_name || l_sep || ddh.coroner_name,
                          g_disp_mse,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang)) field07,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang),
                          g_disp_tran,
                          tit_flg_items_sent_patient || l_sep || ddh.items_sent_with_patient,
                          g_disp_expi,
                          tit_flg_funeral_home_contacted || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_funeral_home_contacted, i_lang),
                          g_disp_mse,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang)) field08,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang),
                          g_disp_tran,
                          tit_vs_taken || l_sep || pk_sysdomain.get_domain('YES_NO', ddh.vs_taken, i_lang),
                          g_disp_expi,
                          tit_funeral_home_name || l_sep || ddh.funeral_home_name,
                          g_disp_mse,
                          tit_flg_patient_transport || l_sep ||
                          pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                  ddh.flg_patient_transport,
                                                  i_lang)) field09,
                   decode(dff.flg_type,
                          g_disp_home,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang)),
                          g_disp_tran,
                          tit_intake_output || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.intake_output_done, i_lang),
                          g_disp_expi,
                          tit_dt_body_removed || l_sep ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      ddh.dt_body_removed_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          g_disp_mse,
                          tit_flg_pat_escorted_by || l_sep ||
                          decode(ddh.flg_pat_escorted_by,
                                 l_disch_letter_list_exception,
                                 ddh.desc_pat_escorted_by,
                                 pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                         ddh.flg_pat_escorted_by,
                                                         i_lang))) field10,
                   decode(dff.flg_type,
                          g_disp_mse,
                          tit_written_instructions || l_sep ||
                          pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang)) field11,
                   NULL field12,
                   tit_add_notes || l_sep || dh.notes_med additional_notes
              FROM discharge_hist        dh,
                   discharge_detail_hist ddh,
                   disch_reas_dest       drd,
                   discharge_flash_files dff,
                   discharge_flash_files dff2,
                   discharge_reason      dr,
                   professional          prfa,
                   category              cat,
                   profile_template      prt,
                   discharge_dest        dd,
                   department            dpt,
                   institution           ins
             WHERE dh.id_episode = i_id_episode
               AND ddh.id_prof_admitting = prfa.id_professional(+)
               AND dh.id_discharge_hist = ddh.id_discharge_hist
               AND dh.id_disch_reas_dest = drd.id_disch_reas_dest
               AND dff.id_discharge_flash_files = dh.id_discharge_flash_files
               AND drd.id_discharge_reason = dr.id_discharge_reason
               AND drd.id_discharge_dest = dd.id_discharge_dest(+)
               AND drd.id_department = dpt.id_department(+)
               AND drd.id_institution = ins.id_institution(+)
               AND dh.id_profile_template = prt.id_profile_template
               AND prt.id_category = cat.id_category
               AND cat.flg_type = g_nurse
               AND dff.id_dsch_flsh_files_assoc = dff2.id_discharge_flash_files(+)
             ORDER BY dh.dt_created_hist DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_NURSE_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nurse_summary;
    -- ###########################################################

    /*
    * Get types of reason for discharge
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_disposition.get_discharge_reason_list(i_lang     => i_lang,
                                                        i_prof     => i_prof,
                                                        i_prof_cat => i_prof_cat,
                                                        i_flg_type => NULL,
                                                        o_list     => o_list,
                                                        o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCHARGE_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_reason_list;

    /**********************************************************************************************
    * Gets all the rooms available in the inpatient department
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department          Destination department ID
    * @param o_room                   Room list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          08-10-2010
    **********************************************************************************************/
    FUNCTION get_admit_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_room          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_department        department.id_department%TYPE;
        l_filter_by_department sys_config.value%TYPE;
    
    BEGIN
    
        -- Configuration that allows the list of rooms to be filtered by the destination department.
        g_error                := 'GET CONFIGURATIONS';
        l_filter_by_department := pk_sysconfig.get_config(i_code_cf => 'DISCHARGE_ADMITTED_ROOM_BY_DEPARTMENT',
                                                          i_prof    => i_prof);
    
        IF nvl(l_filter_by_department, pk_alert_constant.g_no) = pk_alert_constant.g_no
        THEN
            -- If institution doesn't want to filter rooms by department, set ID_DEPARTMENT as null.
            l_id_department := NULL;
        ELSE
            l_id_department := i_id_department;
        END IF;
    
        g_error := 'CALL TO GET_ROOM_LIST';
        IF NOT pk_list.get_room_list(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_department => l_id_department,
                                     i_software   => pk_alert_constant.g_soft_inpatient,
                                     i_msg_other  => 'COMMON_T020',
                                     o_room       => o_room,
                                     o_error      => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_ADMIT_ROOM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END get_admit_room_list;
    -- ###########################################################

    FUNCTION check_death_registry
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_episode      IN NUMBER,
        o_flg_show_msg OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_return    BOOLEAN;
        l_msg       VARCHAR2(1000 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
    
        FUNCTION check_death_record(i_episode IN NUMBER) RETURN BOOLEAN IS
            l_count NUMBER;
        BEGIN
        
            SELECT COUNT(*)
              INTO l_count
              FROM death_registry dr
             WHERE dr.id_episode = i_episode
               AND dr.flg_type = 'P'
               AND dr.flg_status = 'A';
        
            RETURN(l_count > 0);
        
        END check_death_record;
    
    BEGIN
    
        IF check_death_record(i_episode => i_episode)
        THEN
        
            o_flg_show_msg := pk_alert_constant.g_no;
        
        ELSE
        
            o_flg_show_msg := pk_alert_constant.g_yes;
            o_msg_title    := pk_message.get_message(i_lang, 'COMMON_T059');
            o_msg          := pk_message.get_message(i_lang, 'DISCHARGE_REASON_VALIDATION_M001');
            o_button       := 'NC';
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END check_death_registry;

    /********************************************************************************************
     * Disposition validation
     *
     * @param   I_LANG               language associated to the professional executing the request
     * @param   I_PROF               professional, institution and software ids
     * @param   I_EPISODE            episode id
     * @param   i_id_disch_reas_dest tipo e destino de alta
     * @param   i_id_discharge_hist  id do registo de historico de alta
     * @param   o_epis_type_new_epis id do tipo de episodio a criar se aplicavel
     * @param   o_flg_type_new_epis  flag do tipo de episdio
     * @param   o_flg_new_epis       indica se destino implica criação de episodio
     * @param   o_screen             indica ecra a carregar para o flash
     * @param   o_flg_show_msg       indica se é necessario mensagem de aviso
     * @param   o_msg                conteudo da mensagem
     * @param   o_msg_title          titulo da mensagem
     * @param   o_button             botoes da mensagem
     * @param   O_ERROR warning/error message
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/10
    ********************************************************************************************/
    FUNCTION check_epis_disposition
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_episode                  IN episode.id_episode%TYPE,
        i_id_disch_reas_dest          IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist           IN discharge_hist.id_discharge_hist%TYPE,
        o_epis_type_new_epis          OUT episode.id_epis_type%TYPE,
        o_flg_type_new_epis           OUT episode.flg_type%TYPE,
        o_disch_letter_list_exception OUT VARCHAR2,
        o_flg_new_epis                OUT VARCHAR2,
        o_screen                      OUT VARCHAR2,
        o_flg_show_msg                OUT VARCHAR2,
        o_msg                         OUT VARCHAR2,
        o_msg_title                   OUT VARCHAR2,
        o_button                      OUT VARCHAR2,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_show_msg      VARCHAR2(1 CHAR);
        l_msg               sys_message.desc_message%TYPE;
        l_msg_title         sys_message.desc_message%TYPE;
        l_button            VARCHAR2(3 CHAR);
        l_prof_category     category.flg_type%TYPE;
        l_epis_diag         epis_diagnosis.id_diagnosis%TYPE;
        l_comm              VARCHAR2(4000);
        l_ret               BOOLEAN;
        g_found             BOOLEAN;
        l_count             NUMBER;
        l_notfound          BOOLEAN;
        l_id_death_registry death_registry.id_death_registry%TYPE;
    
        r_epi   episode%ROWTYPE;
        r_vis   visit%ROWTYPE;
        r_dsc   discharge%ROWTYPE;
        r_dsd   discharge_detail%ROWTYPE;
        r_dsc_h discharge_hist%ROWTYPE;
        r_dsd_h discharge_detail_hist%ROWTYPE;
        r_rea   disch_reas_dest%ROWTYPE;
        --
        l_disch_diag_icd9 sys_config.value%TYPE;
        l_total_mand_diag PLS_INTEGER;
        l_code_msg_mand_diag CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_M038';
        l_replace_str        CONSTANT VARCHAR2(2) := '@1';
        l_icd9_error_msg sys_message.desc_message%TYPE;
        l_diagnosis_icd9 diagnosis.id_diagnosis%TYPE;
        --    
        l_force_doc_discharge sys_config.value%TYPE;
        l_opinion_count       NUMBER;
        l_show_error_msg      VARCHAR2(1);
        l_error_title         sys_message.desc_message%TYPE;
        l_error_message       sys_message.desc_message%TYPE;
        l_count_diag          NUMBER;
        l_other_diagnosis     VARCHAR2(1 CHAR);
        -- Verifica se o episódio tem diagnósticos finais
        CURSOR c_epis_diag(i_discharge_diag_mandatory IN VARCHAR2) IS
            SELECT ed.id_epis_diagnosis
              FROM epis_diagnosis ed, diagnosis d
             WHERE ed.id_episode = i_id_episode
               AND ed.id_diagnosis = d.id_diagnosis
               AND (ed.flg_type IN (g_epis_diag_def, g_epis_diag_base) AND
                   ed.flg_status NOT IN (g_epis_diag_canc, g_epis_diag_decl) AND
                   ((l_other_diagnosis = pk_alert_constant.g_no AND
                   nvl(d.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes) OR
                   l_other_diagnosis = pk_alert_constant.g_yes));
    
        CURSOR c_opinion_approval_count IS
            SELECT COUNT(1)
              FROM opinion o, episode e, epis_info ei
             WHERE o.flg_state = pk_opinion.g_opinion_req
               AND o.id_opinion_type IS NOT NULL
               AND e.id_episode = i_id_episode
               AND o.id_patient = e.id_patient
               AND o.id_episode = e.id_episode
               AND o.id_episode = ei.id_episode
               AND e.id_institution = i_prof.institution
               AND pk_opinion.check_approval_need(profissional(o.id_prof_questions, i_prof.institution, ei.id_software),
                                                  o.id_opinion_type) = 'Y';
    
        CURSOR c_epis_death_rec IS
            SELECT dr.id_death_registry
              FROM death_registry dr
             WHERE dr.id_episode = i_id_episode
               AND dr.flg_status = 'A';
    
        CURSOR c_force_diag_abort_deliv IS
            SELECT pp.flg_preg_out_type
              FROM pat_pregnancy pp
             WHERE pp.id_episode = i_id_episode
               AND pp.flg_status != pk_alert_constant.g_cancelled
               AND pp.flg_extraction = g_yes;
    
        err_general_error          EXCEPTION;
        err_no_final_diag          EXCEPTION;
        err_no_final_diag_icd9     EXCEPTION;
        err_check_discharge        EXCEPTION;
        err_opinion_approval_error EXCEPTION;
        err_no_death_record        EXCEPTION;
        err_force_diag_abort_deliv EXCEPTION;
    
        l_err_overall_resp EXCEPTION;
    
        l_disch_death_rec_mandatory sys_config.value%TYPE;
        l_disch_flash_files         discharge_flash_files.id_discharge_flash_files%TYPE;
        l_disposition_flg_type      discharge_flash_files.flg_type%TYPE;
    
        l_disch_force_diag_abort_deliv sys_config.value%TYPE;
        l_flg_preg_out_type            pat_pregnancy.flg_preg_out_type%TYPE;
        l_exists                       VARCHAR2(1 CHAR);
        --
        l_id_death_validation  VARCHAR2(200 CHAR);
        l_flg_death_validation VARCHAR2(200 CHAR);
    BEGIN
        r_epi.flg_migration := 'A';
        r_vis.flg_migration := 'A';
    
        l_comm := 'GET CONFIGURATIONS';
        -- Se o motivo da alta obriga a criação de um episodio (Software/instituição)
        g_disch_reason := pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof);
    
        -- Se o motivo da alta obriga a criação de um episodio (Software/instituição)
        g_disch_reason_oris := pk_sysconfig.get_config('ID_DISCHARGE_ORIS', i_prof);
    
        -- Se é possivél efectuar alta administrativa sem alta médica(Software/instituição)
        g_disch_admin := pk_sysconfig.get_config('DOCTOR_DISCH_MANDATORY', i_prof); --'DISCHARGE_ADMIN', I_PROF);
    
        -- Se é possivél realizar a alta sobre o episódio com episódios sociais activos(Software/instituição)
        g_disch_social := pk_sysconfig.get_config('DISCHARGE_SOCIAL', i_prof);
    
        -- Software do EDIS
        g_soft_edis       := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
        l_other_diagnosis := pk_sysconfig.get_config('DISCHARGE_ALLOW_DIAG_OTHERS', i_prof);
        -- Software do UBU
        g_soft_ubu := pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof);
    
        -- Validar se existem MCDTs em atraso aquando alta médica
        g_discharge_mcdt := pk_sysconfig.get_config('DISCHARGE_MCDT', i_prof);
    
        -- Retirar valor de excepção das multichoice para texto livre
        o_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        -- Permite (Y) ou não (N) que o médico dê alta, mesmo que existam pedido de acompanhamento com estado requisitado
        l_force_doc_discharge := pk_sysconfig.get_config(g_cfg_force_doc_discharge, i_prof);
    
        g_discharge_diag_mandatory := pk_sysconfig.get_config('DISCHARGE_DIAG_MANDATORY', i_prof);
    
        l_disch_death_rec_mandatory := pk_sysconfig.get_config('DISCHARGE_DEATH_RECORD_MANDATORY', i_prof);
    
        l_disch_force_diag_abort_deliv := pk_sysconfig.get_config('DISCHARGE_FORCE_DIAG_ABORT_DELIV', i_prof);
    
        --l_id_death_validation := pk_sysconfig.get_config('ID_REASON_4_DISCHARGE_VALIDATION', i_prof);
        --l_flg_death_validation := pk_sysconfig.get_config('DEATH_VALIDATION_ON_DISCHARGE_ACTIVE', i_prof);
    
        l_comm := 'get category of professional';
        l_ret  := get_prof_category(i_lang, i_prof, l_prof_category, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_general_error;
        END IF;
    
        l_comm := 'GET EPISODE';
        SELECT *
          INTO r_epi
          FROM episode
         WHERE id_episode = i_id_episode;
    
        l_comm := 'GET VISIT';
        SELECT *
          INTO r_vis
          FROM visit
         WHERE id_visit = r_epi.id_visit;
    
        l_comm := 'GET DISCH_REAS_DEST';
        SELECT *
          INTO r_rea
          FROM disch_reas_dest
         WHERE id_disch_reas_dest = i_id_disch_reas_dest;
    
        -- Check if this discharge reason requires an overall responsible to be assigned to the patient
        IF nvl(r_rea.flg_needs_overall_resp, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
        THEN
            g_error := 'CHECK_OVERALL_RESP';
            alertlog.pk_alertlog.log_info(text => g_error);
            IF NOT pk_hand_off_api.check_overall_responsible(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode        => i_id_episode,
                                                             o_flg_show_error => l_show_error_msg,
                                                             o_error_title    => l_error_title,
                                                             o_error_message  => l_error_message,
                                                             o_error          => o_error)
            THEN
                RAISE err_general_error;
            END IF;
        
            IF l_show_error_msg = pk_alert_constant.g_yes
            THEN
                RAISE l_err_overall_resp;
            END IF;
        END IF;
    
        l_comm := 'GET DISCHARGE HIST:' || nvl(to_char(i_id_discharge_hist), 'NULL');
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            l_comm := 'GET discharge_hist';
            SELECT *
              INTO r_dsc_h
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            l_comm := 'GET discharge_detail_hist';
            SELECT *
              INTO r_dsd_h
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            l_comm := 'GET discharge';
            SELECT *
              INTO r_dsc
              FROM discharge
             WHERE id_discharge = r_dsc_h.id_discharge;
        
            l_comm := 'GET discharge_detail';
            SELECT *
              INTO r_dsd
              FROM discharge_detail
             WHERE id_discharge = r_dsc_h.id_discharge;
        
        END IF;
    
        l_comm := 'GET PROF CATEGORY:' || nvl(l_prof_category, 'NULL');
        IF l_prof_category IN (g_doctor, g_nurse)
        THEN
        
            l_comm := 'CHECK IF CLERK COMPLAINT EXISTS';
            SELECT COUNT(1)
              INTO l_count
              FROM epis_anamnesis
             WHERE id_episode = i_id_episode
               AND flg_type = g_anamnesis_type
               AND flg_class = g_admin_anamnesis;
        
            IF l_count = 0
            THEN
            
                l_comm := 'Check if diagnosis IS MANDATORY';
                IF r_rea.flg_diag = g_yes
                   AND g_discharge_diag_mandatory = g_yes
                THEN
                    l_disch_diag_icd9 := pk_sysconfig.get_config(g_syscfg_disch_diag_icd9, i_prof);
                
                    IF l_disch_diag_icd9 = g_not_applicable
                    THEN
                        -- Obrigatório apresentar diagnósticos finais
                        --Verifica se existem diagnósticos finais no episódio
                        l_comm := 'OPEN CURSOR C_EPIS_DIAG';
                        OPEN c_epis_diag(g_discharge_diag_mandatory);
                        FETCH c_epis_diag
                            INTO l_epis_diag;
                        g_found := c_epis_diag%NOTFOUND;
                        CLOSE c_epis_diag;
                        --
                        IF g_found
                        THEN
                            RAISE err_no_final_diag;
                        END IF;
                    ELSE
                        g_error := 'GET DIAGNOSIS ID';
                        BEGIN
                            SELECT id_diagnosis,
                                   pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_id_diagnosis => id_diagnosis,
                                                              i_code         => code_icd,
                                                              i_flg_other    => flg_other,
                                                              i_flg_std_diag => pk_alert_constant.g_yes)
                              INTO l_diagnosis_icd9, l_icd9_error_msg
                              FROM diagnosis_content
                             WHERE id_institution = i_prof.institution
                               AND id_software = i_prof.software
                               AND flg_type_dep_clin = pk_diagnosis.g_diag_pesq
                               AND code_icd = l_disch_diag_icd9
                               AND flg_type IN
                                   (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                                     column_value flg_terminology
                                      FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                                          i_prof      => i_prof,
                                                                                          i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_icd9_error_msg := REPLACE(pk_message.get_message(i_lang, i_prof, l_code_msg_mand_diag),
                                                            l_replace_str,
                                                            l_code_msg_mand_diag);
                        END;
                    
                        g_error := 'VALIDATE MANDATORY DIAG CATEGORY';
                        pk_alertlog.log_info(text => g_error);
                        SELECT COUNT(*)
                          INTO l_total_mand_diag
                          FROM epis_diagnosis ed
                          JOIN (SELECT d.id_diagnosis
                                  FROM (SELECT *
                                          FROM diagnosis_content
                                         WHERE id_institution = i_prof.institution
                                           AND id_software = i_prof.software
                                           AND flg_type_dep_clin = pk_diagnosis.g_diag_pesq
                                           AND flg_type IN
                                               (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                                                 column_value flg_terminology
                                                  FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
                                           AND rownum > 0) d
                                 START WITH d.id_diagnosis = l_diagnosis_icd9
                                CONNECT BY PRIOR d.id_diagnosis = d.id_diagnosis_parent) dd
                            ON dd.id_diagnosis = ed.id_diagnosis
                         WHERE ed.id_episode = i_id_episode
                           AND ed.flg_type IN (g_epis_diag_def, g_epis_diag_base)
                           AND ed.flg_status NOT IN (g_epis_diag_canc, g_epis_diag_decl);
                    
                        IF l_total_mand_diag = 0
                        THEN
                            -- if this ID is null its a wrong configuration and the error message was built previously
                            IF l_diagnosis_icd9 IS NOT NULL
                            THEN
                                l_icd9_error_msg := REPLACE(pk_message.get_message(i_lang, i_prof, l_code_msg_mand_diag),
                                                            l_replace_str,
                                                            l_icd9_error_msg);
                            END IF;
                        
                            RAISE err_no_final_diag_icd9;
                        END IF;
                    END IF;
                END IF;
            
            END IF; -- L_COUNT = 0
        
        END IF; -- L_PROF_CATEGORY = G_DOCTOR THEN
    
        IF l_prof_category IN (g_doctor, g_nurse)
           AND l_disch_death_rec_mandatory = 'Y'
        THEN
            g_error := 'CALL GET_DISCH_FLASH_FILE';
            pk_alertlog.log_info(text => g_error);
            l_disch_flash_files := pk_disposition.get_disch_flash_file(i_institution      => i_prof.institution,
                                                                       i_discharge_reason => r_rea.id_discharge_reason,
                                                                       i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof));
        
            BEGIN
                g_error := 'GET DISPOSITION FLG_TYPE';
                pk_alertlog.log_debug(g_error);
                SELECT dff.flg_type
                  INTO l_disposition_flg_type
                  FROM discharge_flash_files dff
                 WHERE dff.id_discharge_flash_files = l_disch_flash_files;
            EXCEPTION
                WHEN no_data_found THEN
                    l_disposition_flg_type := NULL;
            END;
        
            IF l_disposition_flg_type = g_disp_expi
            THEN
            
                IF l_disch_death_rec_mandatory = pk_alert_constant.g_yes
                THEN
                
                    --if r_rea.id_discharge_reason = l_id_death_validation then
                
                    l_ret := check_death_registry(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_id_episode,
                                                  o_flg_show_msg => l_show_error_msg,
                                                  o_msg          => l_error_message,
                                                  o_msg_title    => l_error_title,
                                                  o_button       => o_button,
                                                  o_error        => o_error);
                
                    IF NOT l_ret
                    THEN
                        RAISE err_general_error;
                    END IF;
                
                    IF l_show_error_msg = pk_alert_constant.g_yes
                    THEN
                        o_flg_show_msg := 'NO_DEATH_REC';
                        o_msg          := l_error_message;
                        o_msg_title    := l_error_title;
                        o_button       := o_button;
                    
                        RETURN l_ret;
                        --RAISE l_err_overall_resp;
                    END IF;
                
                END IF;
            
            END IF;
        
        END IF;
    
        -------------------------------------------------
        IF l_force_doc_discharge = 'N'
           AND l_prof_category IN (g_doctor, g_adm_cat)
        THEN
            g_error := 'OPEN CURSOR C_DISCH_REASON';
            OPEN c_opinion_approval_count;
            FETCH c_opinion_approval_count
                INTO l_opinion_count;
            CLOSE c_opinion_approval_count;
        
            IF l_opinion_count != 0
            THEN
                o_flg_show_msg := 'FOLLOW';
                o_button       := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_M051');
                o_msg          := pk_message.get_message(i_lang, i_prof, g_opinion_approval_needed);
                RETURN TRUE;
            END IF;
        END IF;
        -------------------------------------------------
    
        -- when discharge is administrative, check for ongoing social worker episodes
        IF l_prof_category = g_adm_cat
           AND g_disch_social = g_adm
        THEN
            g_error := 'CALL pk_discharge.check_sw_episode';
            pk_discharge.check_sw_episode(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_visit     => pk_episode.get_id_visit(i_id_episode),
                                          o_flg_show  => o_flg_show_msg,
                                          o_msg_title => o_msg_title,
                                          o_msg_text  => o_msg,
                                          o_button    => o_button);
        
            IF o_flg_show_msg = pk_alert_constant.g_yes
            THEN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => 'DISCHARGE_M027',
                                                  i_sqlerrm  => o_msg,
                                                  i_message  => g_error,
                                                  i_owner    => 'ALERT',
                                                  i_package  => g_package_name,
                                                  i_function => 'CHECK_EPIS_DISPOSITION',
                                                  o_error    => o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_disch_force_diag_abort_deliv = g_yes
        THEN
        
            BEGIN
                OPEN c_force_diag_abort_deliv;
                FETCH c_force_diag_abort_deliv
                    INTO l_flg_preg_out_type;
                CLOSE c_force_diag_abort_deliv;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_preg_out_type := NULL;
            END;
        
            IF l_flg_preg_out_type IS NOT NULL
            THEN
            
                IF NOT pk_diagnosis.get_final_diag_abort_deliv(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_epis          => i_id_episode,
                                                               i_preg_out_type => l_flg_preg_out_type,
                                                               i_diagnosis     => NULL,
                                                               o_exists        => l_exists,
                                                               o_count         => l_count_diag,
                                                               o_error         => o_error)
                THEN
                    RAISE err_force_diag_abort_deliv;
                ELSE
                
                    IF l_flg_preg_out_type = pk_diagnosis_core.g_preg_out_type_a
                       AND l_exists = pk_alert_constant.g_no
                    THEN
                        l_error_message := pk_message.get_message(i_lang, i_prof, g_force_diag_abort_deliv_a);
                        RAISE err_force_diag_abort_deliv;
                    END IF;
                
                    IF l_flg_preg_out_type = pk_diagnosis_core.g_preg_out_type_d
                       AND l_exists = pk_alert_constant.g_no
                    THEN
                        l_error_message := pk_message.get_message(i_lang, i_prof, g_force_diag_abort_deliv_d);
                        RAISE err_force_diag_abort_deliv;
                    END IF;
                
                END IF;
            
            END IF;
        
        END IF;
    
        -- Verificar se o MOTIVO da alta obriga a criação de um novo episódio
        IF g_yes = g_discharge_mcdt
        THEN
        
            l_comm := 'DO WE TRANSFER MCDT';
            IF r_rea.flg_mcdt IS NOT NULL
            THEN
            
                l_comm := 'CALL pk_discharge.check_discharge';
                l_ret  := pk_discharge.check_discharge(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => r_epi.id_episode,
                                                       i_flg_mcdt     => r_rea.flg_mcdt,
                                                       o_flg_show_msg => o_flg_show_msg,
                                                       o_msg          => o_msg,
                                                       o_msg_title    => o_msg_title,
                                                       o_button       => o_button,
                                                       o_error        => o_error);
                IF l_ret = FALSE
                THEN
                    RAISE err_check_discharge;
                END IF;
            END IF;
        
        END IF;
    
        -- Qual o tipo de episódio a ser gerado e o ecran a ser visualizado
        l_comm := '';
        IF r_rea.id_discharge_reason IN (g_disch_reason, g_disch_reason_oris)
        THEN
        
            -- Qual o tipo de episódio a ser gerado e o ecran a ser visualizado
            l_comm := 'create episode on discharge';
            IF r_rea.id_epis_type IS NOT NULL
               AND r_rea.type_screen IS NOT NULL
               AND r_rea.id_institution IS NULL
            THEN
                l_comm               := 'inicialize var for discharge episode created';
                o_flg_new_epis       := g_yes;
                o_epis_type_new_epis := r_rea.id_epis_type;
                o_flg_type_new_epis  := substr(r_rea.id_epis_type, 1, instr(r_rea.id_epis_type, '|') - 1);
                o_screen             := substr(r_rea.type_screen, instr(r_rea.type_screen, '|') + 1);
            ELSE
                o_flg_new_epis := g_no;
            END IF;
        
        ELSE
            o_flg_new_epis := g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_opinion_approval_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'CHECK_EPIS_DISPOSITION',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state();
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        WHEN err_check_discharge THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'CHECK_EPIS_DISPOSITION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN err_no_final_diag THEN
            o_flg_show_msg := 'NO_DIAG';
            o_msg          := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_WARNING_002');
            o_msg_title    := pk_message.get_message(i_lang, i_prof, 'COMMON_T059');
            RETURN TRUE;
        
        WHEN err_no_final_diag_icd9 THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   l_code_msg_mand_diag,
                                   l_icd9_error_msg,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'CHECK_EPIS_DISPOSITION',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN err_no_death_record THEN
            o_flg_show_msg := 'NO_DEATH_REC';
            o_msg          := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_WARNING_005');
            o_msg_title    := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_WARNING_001');
            RETURN TRUE;
        
        WHEN l_err_overall_resp THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'CHECK_EPIS_DISPOSITION',
                                   NULL,
                                   'U',
                                   l_error_title);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        WHEN err_force_diag_abort_deliv THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'CHECK_EPIS_DISPOSITION',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'CHECK_EPIS_DISPOSITION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_epis_disposition;
    -- ###########################################################

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dsc          IN discharge%ROWTYPE,
        i_do_commit    IN VARCHAR2,
        o_id_discharge OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ei        table_varchar;
        l_flg_status_adm discharge.flg_status_adm%TYPE;
    
    BEGIN
    
        -- get sequencial number
        SELECT seq_discharge.nextval
          INTO o_id_discharge
          FROM dual;
    
        IF i_dsc.dt_admin_tstz IS NOT NULL
        THEN
            l_flg_status_adm := pk_alert_constant.g_active;
        END IF;
    
        INSERT INTO discharge
            (id_discharge,
             id_disch_reas_dest,
             id_episode,
             id_prof_cancel,
             notes_cancel,
             id_prof_med,
             notes_med,
             id_prof_admin,
             notes_admin,
             flg_status,
             id_discharge_status,
             flg_type,
             id_transp_ent_adm,
             id_transp_ent_med,
             notes_justify,
             price,
             currency,
             flg_payment,
             id_prof_pend_active,
             dt_med_tstz,
             dt_admin_tstz,
             dt_cancel_tstz,
             dt_pend_active_tstz,
             dt_pend_tstz,
             id_cpt_code,
             flg_status_adm,
             flg_market,
             id_discharge_flash_files)
        VALUES
            (o_id_discharge,
             i_dsc.id_disch_reas_dest,
             i_dsc.id_episode,
             i_dsc.id_prof_cancel,
             i_dsc.notes_cancel,
             i_dsc.id_prof_med,
             i_dsc.notes_med,
             i_dsc.id_prof_admin,
             i_dsc.notes_admin,
             i_dsc.flg_status,
             i_dsc.id_discharge_status,
             i_dsc.flg_type,
             i_dsc.id_transp_ent_adm,
             i_dsc.id_transp_ent_med,
             i_dsc.notes_justify,
             i_dsc.price,
             i_dsc.currency,
             i_dsc.flg_payment,
             i_dsc.id_prof_pend_active,
             i_dsc.dt_med_tstz,
             i_dsc.dt_admin_tstz,
             i_dsc.dt_cancel_tstz,
             i_dsc.dt_pend_active_tstz,
             i_dsc.dt_pend_tstz,
             i_dsc.id_cpt_code,
             l_flg_status_adm,
             pk_discharge_core.g_disch_type_us,
             i_dsc.id_discharge_flash_files);
    
        g_error := 'CHECK_DISPOSITION (1)';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_discharge.check_discharge(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_episode            => i_dsc.id_episode,
                                            i_can_edt_inact_epis => g_can_edit_inact_epis,
                                            o_error              => o_error)
        THEN
            RAISE pk_discharge.e_check_discharge;
        END IF;
    
        ts_epis_info.upd(id_episode_in           => i_dsc.id_episode,
                         flg_dsch_status_in      => i_dsc.flg_status,
                         id_disch_reas_dest_in   => i_dsc.id_disch_reas_dest,
                         dt_med_tstz_in          => i_dsc.dt_med_tstz,
                         dt_med_tstz_nin         => FALSE,
                         dt_pend_active_tstz_in  => i_dsc.dt_pend_active_tstz,
                         dt_pend_active_tstz_nin => FALSE,
                         dt_admin_tstz_in        => i_dsc.dt_admin_tstz,
                         dt_admin_tstz_nin       => FALSE,
                         rows_out                => l_rows_ei);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_DSCH_STATUS',
                                                                      'ID_DISCH_REAS_DEST',
                                                                      'DT_MED_TSTZ',
                                                                      'DT_PEND_ACTIVE_TSTZ',
                                                                      'DT_ADMIN_TSTZ'));
        -- Valida necessidade de criação de alerta
        -- Válido para os alertas 30 e 31
        IF NOT set_disp_edis_to_inp_alert(i_lang, i_prof, i_dsc.id_episode, o_error)
        THEN
            RAISE e_call_exception;
        
        END IF;
    
        IF i_do_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_discharge.e_check_discharge THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_DSC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_disposition_dsc;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE_detail
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsd           structure with info to be saved  into discharge_detail
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_detail   id_discharge_detail generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsd
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dsd                 IN discharge_detail%ROWTYPE,
        i_do_commit           IN VARCHAR2,
        o_id_discharge_detail OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        SELECT seq_discharge_detail.nextval
          INTO o_id_discharge_detail
          FROM dual;
    
        INSERT INTO discharge_detail
            (id_discharge_detail,
             id_discharge,
             flg_pat_condition,
             id_transport_type,
             id_disch_rea_transp_ent_inst,
             flg_caretaker,
             caretaker_notes,
             flg_follow_up_by,
             follow_up_notes,
             flg_written_notes,
             flg_voluntary,
             flg_pat_report,
             flg_transfer_form,
             id_prof_admitting,
             id_dep_clin_serv_admiting,
             flg_summary_report,
             flg_autopsy_consent,
             autopsy_consent_desc,
             flg_orgn_dntn_info,
             orgn_dntn_info,
             flg_examiner_notified,
             examiner_notified_info,
             flg_orgn_dntn_form_complete,
             flg_ama_form_complete,
             flg_lwbs_form_complete,
             notes,
             prof_admitting_desc,
             dep_clin_serv_admiting_desc,
             mse_type,
             flg_print_report,
             flg_surgery,
             follow_up_date_tstz,
             date_surgery_tstz,
             death_process_registration,
             id_inst_transfer,
             id_admitting_doctor,
             id_written_by,
             flg_compulsory,
             id_compulsory_reason,
             compulsory_reason,
             oper_treatment_detail,
             status_before_death)
        VALUES
            (o_id_discharge_detail,
             i_dsd.id_discharge,
             i_dsd.flg_pat_condition,
             i_dsd.id_transport_type,
             i_dsd.id_disch_rea_transp_ent_inst,
             i_dsd.flg_caretaker,
             i_dsd.caretaker_notes,
             i_dsd.flg_follow_up_by,
             i_dsd.follow_up_notes,
             i_dsd.flg_written_notes,
             i_dsd.flg_voluntary,
             i_dsd.flg_pat_report,
             i_dsd.flg_transfer_form,
             i_dsd.id_prof_admitting,
             i_dsd.id_dep_clin_serv_admiting,
             i_dsd.flg_summary_report,
             i_dsd.flg_autopsy_consent,
             i_dsd.autopsy_consent_desc,
             i_dsd.flg_orgn_dntn_info,
             i_dsd.orgn_dntn_info,
             i_dsd.flg_examiner_notified,
             i_dsd.examiner_notified_info,
             i_dsd.flg_orgn_dntn_form_complete,
             i_dsd.flg_ama_form_complete,
             i_dsd.flg_lwbs_form_complete,
             i_dsd.notes,
             i_dsd.prof_admitting_desc,
             i_dsd.dep_clin_serv_admiting_desc,
             i_dsd.mse_type,
             i_dsd.flg_print_report,
             i_dsd.flg_surgery,
             i_dsd.follow_up_date_tstz,
             i_dsd.date_surgery_tstz,
             i_dsd.death_process_registration,
             i_dsd.id_inst_transfer,
             i_dsd.id_admitting_doctor,
             i_dsd.id_written_by,
             i_dsd.flg_compulsory,
             i_dsd.id_compulsory_reason,
             i_dsd.compulsory_reason,
             i_dsd.oper_treatment_detail,
             i_dsd.status_before_death);
    
        IF i_do_commit = g_yes
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
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_DSD',
                                              o_error);
            RETURN FALSE;
    END set_disposition_dsd;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE_hist
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc_h         structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_hist   id_discharge_hist generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsc_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_dsc_h             IN discharge_hist%ROWTYPE,
        i_do_commit         IN VARCHAR2,
        o_id_discharge_hist OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status discharge_hist.flg_status_adm%TYPE;
    BEGIN
    
        SELECT seq_discharge_hist.nextval
          INTO o_id_discharge_hist
          FROM dual;
    
        IF i_dsc_h.dt_admin_tstz IS NOT NULL
        THEN
            l_flg_status := pk_alert_constant.g_active;
        END IF;
        INSERT INTO discharge_hist
            (id_discharge_hist,
             id_discharge,
             id_disch_reas_dest,
             id_episode,
             id_prof_cancel,
             notes_cancel,
             id_prof_med,
             notes_med,
             id_prof_admin,
             notes_admin,
             flg_status,
             id_discharge_status,
             flg_type,
             id_transp_ent_adm,
             id_transp_ent_med,
             notes_justify,
             price,
             currency,
             flg_payment,
             id_prof_pend_active,
             dt_med_tstz,
             dt_admin_tstz,
             dt_cancel_tstz,
             dt_pend_active_tstz,
             flg_status_hist,
             id_profile_template,
             id_prof_created_hist,
             dt_created_hist,
             dt_pend_tstz,
             id_cpt_code,
             flg_cancel_type,
             flg_status_adm,
             id_discharge_flash_files)
        VALUES
            (o_id_discharge_hist,
             i_dsc_h.id_discharge,
             i_dsc_h.id_disch_reas_dest,
             i_dsc_h.id_episode,
             i_dsc_h.id_prof_cancel,
             i_dsc_h.notes_cancel,
             i_dsc_h.id_prof_med,
             i_dsc_h.notes_med,
             i_dsc_h.id_prof_admin,
             i_dsc_h.notes_admin,
             i_dsc_h.flg_status,
             i_dsc_h.id_discharge_status,
             i_dsc_h.flg_type,
             i_dsc_h.id_transp_ent_adm,
             i_dsc_h.id_transp_ent_med,
             i_dsc_h.notes_justify,
             i_dsc_h.price,
             i_dsc_h.currency,
             i_dsc_h.flg_payment,
             i_dsc_h.id_prof_pend_active,
             i_dsc_h.dt_med_tstz,
             i_dsc_h.dt_admin_tstz,
             i_dsc_h.dt_cancel_tstz,
             i_dsc_h.dt_pend_active_tstz,
             i_dsc_h.flg_status_hist,
             i_dsc_h.id_profile_template,
             --
             i_prof.id,
             current_timestamp,
             --
             i_dsc_h.dt_pend_tstz,
             i_dsc_h.id_cpt_code,
             i_dsc_h.flg_cancel_type,
             l_flg_status,
             i_dsc_h.id_discharge_flash_files);
    
        IF i_do_commit = g_yes
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
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_DSC_H',
                                              o_error);
            RETURN FALSE;
    END set_disposition_dsc_h;

    /********************************************************************************************
     * Function that inserts data into table discharge_detail_hist
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param I_DSD_H         structure with info to be saved  into discharge_detail_hist
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_detail_hist   id_discharge_detail_hist generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsd_h
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_dsd_h                 IN discharge_detail_hist%ROWTYPE,
        i_do_commit             IN VARCHAR2,
        o_discharge_detail_hist OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc translation.desc_lang_1%TYPE;
    BEGIN
    
        SELECT seq_discharge_detail_hist.nextval
          INTO o_discharge_detail_hist
          FROM dual;
    
        INSERT INTO discharge_detail_hist
            (id_discharge_detail_hist,
             id_discharge_hist,
             id_discharge,
             id_discharge_detail,
             flg_pat_condition,
             id_transport_type,
             id_disch_rea_transp_ent_inst,
             flg_caretaker,
             caretaker_notes,
             flg_follow_up_by,
             follow_up_notes,
             flg_written_notes,
             flg_voluntary,
             flg_pat_report,
             flg_transfer_form,
             id_prof_admitting,
             flg_summary_report,
             flg_autopsy_consent,
             autopsy_consent_desc,
             flg_orgn_dntn_info,
             orgn_dntn_info,
             flg_examiner_notified,
             examiner_notified_info,
             flg_orgn_dntn_form_complete,
             flg_ama_form_complete,
             flg_lwbs_form_complete,
             notes,
             prof_admitting_desc,
             dt_prof_admiting_tstz,
             dep_clin_serv_admiting_desc,
             mse_type,
             flg_med_reconcile,
             flg_instructions_discussed,
             instructions_discussed_notes,
             instructions_understood,
             pat_instructions_provided,
             flg_record_release,
             desc_record_release,
             id_prof_assigned_to,
             vs_taken,
             intake_output_done,
             admit_to_room,
             id_room_admit,
             flg_patient_consent,
             acceptance_facility,
             admitting_room,
             room_assigned_by,
             flg_items_sent_with_patient,
             items_sent_with_patient,
             procedure_text,
             flg_check_valuables,
             flg_patient_transport,
             flg_pat_escorted_by,
             desc_pat_escorted_by,
             admission_orders,
             reason_of_transfer,
             flg_transfer_transport,
             desc_transfer_transport,
             dt_transfer_transport_tstz,
             risk_of_transfer,
             benefits_of_transfer,
             en_route_orders,
             dt_death_tstz,
             prf_declared_death,
             flg_orgn_donation_agency,
             flg_report_of_death,
             flg_coroner_contacted,
             coroner_name,
             flg_funeral_home_contacted,
             dt_body_removed_tstz,
             flg_signed_ama_form,
             desc_signed_ama_form,
             funeral_home_name,
             risk_of_leaving,
             reason_for_visit,
             reason_for_leaving,
             flg_risk_of_leaving,
             dt_ama_tstz,
             flg_prescription_given,
             follow_up_date_tstz,
             flg_prescription_given_to,
             desc_prescription_given_to,
             desc_patient_transport,
             next_visit_scheduled,
             flg_instructions_next_visit,
             desc_instructions_next_visit,
             id_dep_clin_serv_visit,
             id_complaint,
             id_consult_req,
             id_prof_created_hist,
             dt_created_hist,
             id_schedule,
             report_given_to,
             reason_of_transfer_desc,
             flg_print_report,
             flg_surgery,
             date_surgery_tstz,
             id_dep_clin_serv_admiting,
             dt_fw_visit,
             id_dep_clin_serv_fw,
             id_prof_fw,
             sched_notes,
             id_consult_req_fw,
             id_complaint_fw,
             reason_for_visit_fw,
             id_death_characterization,
             death_process_registration,
             id_inst_transfer,
             id_admitting_doctor,
             id_written_by,
             flg_compulsory,
             id_compulsory_reason,
             compulsory_reason,
             oper_treatment_detail,
             status_before_death)
        VALUES
            (o_discharge_detail_hist,
             i_dsd_h.id_discharge_hist,
             i_dsd_h.id_discharge,
             i_dsd_h.id_discharge_detail,
             i_dsd_h.flg_pat_condition,
             i_dsd_h.id_transport_type,
             i_dsd_h.id_disch_rea_transp_ent_inst,
             i_dsd_h.flg_caretaker,
             i_dsd_h.caretaker_notes,
             i_dsd_h.flg_follow_up_by,
             i_dsd_h.follow_up_notes,
             i_dsd_h.flg_written_notes,
             i_dsd_h.flg_voluntary,
             i_dsd_h.flg_pat_report,
             i_dsd_h.flg_transfer_form,
             i_dsd_h.id_prof_admitting,
             i_dsd_h.flg_summary_report,
             i_dsd_h.flg_autopsy_consent,
             i_dsd_h.autopsy_consent_desc,
             i_dsd_h.flg_orgn_dntn_info,
             i_dsd_h.orgn_dntn_info,
             i_dsd_h.flg_examiner_notified,
             i_dsd_h.examiner_notified_info,
             i_dsd_h.flg_orgn_dntn_form_complete,
             i_dsd_h.flg_ama_form_complete,
             i_dsd_h.flg_lwbs_form_complete,
             i_dsd_h.notes,
             i_dsd_h.prof_admitting_desc,
             i_dsd_h.dt_prof_admiting_tstz,
             i_dsd_h.dep_clin_serv_admiting_desc,
             i_dsd_h.mse_type,
             i_dsd_h.flg_med_reconcile,
             i_dsd_h.flg_instructions_discussed,
             i_dsd_h.instructions_discussed_notes,
             i_dsd_h.instructions_understood,
             i_dsd_h.pat_instructions_provided,
             i_dsd_h.flg_record_release,
             i_dsd_h.desc_record_release,
             i_dsd_h.id_prof_assigned_to,
             i_dsd_h.vs_taken,
             i_dsd_h.intake_output_done,
             i_dsd_h.admit_to_room,
             i_dsd_h.id_room_admit,
             i_dsd_h.flg_patient_consent,
             i_dsd_h.acceptance_facility,
             i_dsd_h.admitting_room,
             i_dsd_h.room_assigned_by,
             i_dsd_h.flg_items_sent_with_patient,
             i_dsd_h.items_sent_with_patient,
             i_dsd_h.procedure_text,
             i_dsd_h.flg_check_valuables,
             i_dsd_h.flg_patient_transport,
             i_dsd_h.flg_pat_escorted_by,
             i_dsd_h.desc_pat_escorted_by,
             i_dsd_h.admission_orders,
             i_dsd_h.reason_of_transfer,
             i_dsd_h.flg_transfer_transport,
             i_dsd_h.desc_transfer_transport,
             i_dsd_h.dt_transfer_transport_tstz,
             i_dsd_h.risk_of_transfer,
             i_dsd_h.benefits_of_transfer,
             i_dsd_h.en_route_orders,
             i_dsd_h.dt_death_tstz,
             i_dsd_h.prf_declared_death,
             i_dsd_h.flg_orgn_donation_agency,
             i_dsd_h.flg_report_of_death,
             i_dsd_h.flg_coroner_contacted,
             i_dsd_h.coroner_name,
             i_dsd_h.flg_funeral_home_contacted,
             i_dsd_h.dt_body_removed_tstz,
             i_dsd_h.flg_signed_ama_form,
             i_dsd_h.desc_signed_ama_form,
             i_dsd_h.funeral_home_name,
             i_dsd_h.risk_of_leaving,
             i_dsd_h.reason_for_visit,
             i_dsd_h.reason_for_leaving,
             i_dsd_h.flg_risk_of_leaving,
             i_dsd_h.dt_ama_tstz,
             i_dsd_h.flg_prescription_given,
             i_dsd_h.follow_up_date_tstz,
             i_dsd_h.flg_prescription_given_to,
             i_dsd_h.desc_prescription_given_to,
             i_dsd_h.desc_patient_transport,
             i_dsd_h.next_visit_scheduled,
             i_dsd_h.flg_instructions_next_visit,
             i_dsd_h.desc_instructions_next_visit,
             i_dsd_h.id_dep_clin_serv_visit,
             i_dsd_h.id_complaint,
             i_dsd_h.id_consult_req,
             i_prof.id,
             current_timestamp,
             i_dsd_h.id_schedule,
             i_dsd_h.report_given_to,
             i_dsd_h.reason_of_transfer_desc,
             i_dsd_h.flg_print_report,
             i_dsd_h.flg_surgery,
             i_dsd_h.date_surgery_tstz,
             i_dsd_h.id_dep_clin_serv_admiting,
             i_dsd_h.dt_fw_visit,
             i_dsd_h.id_dep_clin_serv_fw,
             i_dsd_h.id_prof_fw,
             i_dsd_h.sched_notes,
             i_dsd_h.id_consult_req_fw,
             i_dsd_h.id_complaint_fw,
             i_dsd_h.reason_for_visit_fw,
             i_dsd_h.id_death_characterization,
             i_dsd_h.death_process_registration,
             i_dsd_h.id_inst_transfer,
             i_dsd_h.id_admitting_doctor,
             i_dsd_h.id_written_by,
             i_dsd_h.flg_compulsory,
             i_dsd_h.id_compulsory_reason,
             i_dsd_h.compulsory_reason,
             i_dsd_h.oper_treatment_detail,
             i_dsd_h.status_before_death);
    
        IF i_dsd_h.id_death_characterization IS NOT NULL
        THEN
        
            SELECT pk_translation.get_translation(i_lang      => decode(id_language, 0, i_lang, id_language),
                                                  i_code_mess => code_death_event)
              INTO l_desc
              FROM diagnosis_ea d
             WHERE id_concept_term = i_dsd_h.id_death_characterization
               AND d.concept_type_int_name = pk_diagnosis_form.g_death_event
               AND d.id_institution = i_prof.institution
               AND d.id_software = i_prof.software;
        
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => pk_disposition.g_trs_death_event ||
                                                              o_discharge_detail_hist,
                                                  i_desc   => l_desc,
                                                  i_module => 'DEATH_EVENT');
        END IF;
    
        IF i_do_commit = g_yes
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
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_DSD_H',
                                              o_error);
            RETURN FALSE;
    END set_disposition_dsd_h;

    /*
    * set disposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_dsc_h                    discharge_hist%type,
    * @param   i_dsd_h                    discharge_detail_type%type,
    * @param i_transaction_id             Scheduler 3.0 transaction ID
    * @param   o_id_discharge             id of discharge returned
    * @param   o_flg_show                 flag to show warning screen Y/N
    * @param   o_msg_title                title of warning screen
    * @param   o_msg_text                 text of warning screen
    * @param   o_button                   buttons for warning screen
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION set_disposition
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_dsc_h                    IN discharge_hist%ROWTYPE,
        i_dsd_h                    IN discharge_detail_hist%ROWTYPE,
        i_transaction_id           IN VARCHAR2,
        o_id_discharge             OUT discharge.id_discharge%TYPE,
        o_id_discharge_hist        OUT discharge_hist.id_discharge_hist%TYPE,
        o_id_discharge_detail      OUT discharge_detail.id_discharge_detail%TYPE,
        o_id_discharge_detail_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_flg_show                 OUT VARCHAR2,
        o_msg_title                OUT VARCHAR2,
        o_msg_text                 OUT VARCHAR2,
        o_button                   OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                      BOOLEAN;
        l_category                 category.flg_type%TYPE;
        l_id_profile_template      profile_template.id_profile_template%TYPE;
        l_end_episode_on_discharge sys_config.value%TYPE;
        l_timestamp                TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        r_epi         episode%ROWTYPE;
        r_vis         visit%ROWTYPE;
        r_dsc         discharge%ROWTYPE;
        t_dsc         discharge%ROWTYPE;
        r_dsd         discharge_detail%ROWTYPE;
        r_dsc_h       discharge_hist%ROWTYPE;
        r_dsd_h       discharge_detail_hist%ROWTYPE;
        info_flg_type epis_info.flg_status%TYPE;
    
        err_set_disposition_dsc  EXCEPTION;
        err_get_profile_template EXCEPTION;
        err_get_category         EXCEPTION;
        err_set_outdated         EXCEPTION;
        l_rowids_ei table_varchar;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_id_schedule    schedule.id_schedule%TYPE;
        l_func_exception EXCEPTION;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET SCHEDULE ID';
        BEGIN
            SELECT DISTINCT v.id_schedule
              INTO l_id_schedule
              FROM epis_info v
             WHERE v.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_schedule := NULL;
        END;
    
        r_epi.flg_migration := 'A';
        r_vis.flg_migration := 'A';
    
        l_end_episode_on_discharge := pk_sysconfig.get_config('END_EPISODE_ON_DISCHARGE', i_prof);
    
        info_flg_type := 'D';
    
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_get_profile_template;
        END IF;
    
        l_ret := get_category(i_lang, i_prof, l_category, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_get_category;
        END IF;
    
        SELECT *
          INTO r_epi
          FROM episode
         WHERE id_episode = i_id_episode;
        SELECT *
          INTO r_vis
          FROM visit
         WHERE id_visit = r_epi.id_visit;
    
        --        o_error                     := '***:' || i_dsc_h.id_discharge_hist;
        r_dsc_h                     := i_dsc_h;
        r_dsd_h                     := i_dsd_h;
        r_dsc_h.id_profile_template := l_id_profile_template;
        pk_alertlog.log_debug(' I**R_DSC_H.id_compulsory_reason: ' || r_dsd_h.id_compulsory_reason);
    
        -- fill discharge master table
        r_dsc.id_disch_reas_dest       := r_dsc_h.id_disch_reas_dest;
        r_dsc.id_episode               := r_epi.id_episode;
        r_dsc.id_prof_med              := r_dsc_h.id_prof_med;
        r_dsc.dt_med_tstz              := r_dsc_h.dt_med_tstz;
        r_dsc.notes_med                := r_dsc_h.notes_med;
        r_dsc.flg_status               := i_dsc_h.flg_status;
        r_dsc.id_discharge_status      := i_dsc_h.id_discharge_status;
        r_dsc.flg_type                 := g_episode_end;
        r_dsc.id_discharge             := i_dsc_h.id_discharge;
        r_dsc.id_cpt_code              := i_dsc_h.id_cpt_code;
        r_dsc.id_discharge_flash_files := i_dsc_h.id_discharge_flash_files;
    
        -- fill discharge detail table
        IF r_dsc.id_discharge IS NOT NULL
        THEN
            SELECT *
              INTO t_dsc
              FROM discharge
             WHERE id_discharge = r_dsc.id_discharge;
        END IF;
        r_dsd.id_discharge := r_dsc.id_discharge;
        -- r_dsc.flg_status        := i_dsc_h.flg_status;
        r_dsc_h.flg_status_hist          := i_dsc_h.flg_status;
        r_dsc_h.id_cpt_code              := i_dsc_h.id_cpt_code;
        r_dsd.flg_pat_condition          := r_dsd_h.flg_pat_condition;
        r_dsd.flg_surgery                := r_dsd_h.flg_surgery;
        r_dsd.date_surgery_tstz          := r_dsd_h.date_surgery_tstz;
        r_dsd.id_dep_clin_serv_admiting  := r_dsd_h.id_dep_clin_serv_admiting;
        r_dsd.death_process_registration := r_dsd_h.death_process_registration;
        r_dsd.id_inst_transfer           := r_dsd_h.id_inst_transfer;
        r_dsd.id_admitting_doctor        := r_dsd_h.id_admitting_doctor;
        r_dsd.id_written_by              := r_dsd_h.id_written_by;
        r_dsd.flg_compulsory             := r_dsd_h.flg_compulsory;
        r_dsd.id_compulsory_reason       := r_dsd_h.id_compulsory_reason;
        r_dsd.compulsory_reason          := r_dsd_h.compulsory_reason;
    
        -- if final discharge and dt_admin not filled , do it
    
        IF r_dsc.flg_status = g_active
           AND r_dsc.id_prof_admin IS NULL
           AND l_end_episode_on_discharge = g_yes
        THEN
        
            r_dsc.id_prof_admin := i_prof.id;
            r_dsc.dt_admin_tstz := nvl(r_dsc.dt_med_tstz, l_timestamp);
            info_flg_type       := 'T';
        
            r_dsc_h.id_prof_admin := r_dsc.id_prof_admin;
            r_dsc_h.dt_admin_tstz := r_dsc.dt_admin_tstz;
        
        END IF;
    
        IF r_dsc.flg_status = g_active
           AND t_dsc.flg_status = g_pendente
        THEN
        
            r_dsc.id_prof_pend_active := i_prof.id;
            r_dsc.dt_pend_active_tstz := l_timestamp;
        
            r_dsc_h.id_prof_pend_active := i_prof.id;
            r_dsc_h.dt_pend_active_tstz := l_timestamp;
        
        END IF;
    
        IF r_dsc.flg_status != g_active
           AND r_dsc.dt_pend_active_tstz IS NULL
        THEN
        
            r_dsc.dt_pend_tstz   := l_timestamp;
            r_dsc_h.dt_pend_tstz := l_timestamp;
        
        END IF;
    
        --
        pk_alertlog.log_debug(' I******: ' || r_dsc.id_discharge);
        g_error := 'Id discharge: ' || r_dsc.id_discharge;
        l_ret   := set_outdated(i_lang, i_prof, i_id_episode, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_set_outdated;
        END IF;
    
        IF i_dsc_h.id_discharge_hist IS NULL
        THEN
        
            --o_error := '***' || i_dsc_h.id_discharge_hist || '--**--' || r_dsc_h.id_discharge_hist;
            --RETURN FALSE;
        
            pk_alertlog.log_debug(' I**set_disposition_dsc: ' || r_dsc.id_disch_reas_dest);
            -- call inserting function for DISCHARGE
            l_ret := set_disposition_dsc(i_lang, i_prof, r_dsc, g_no, r_dsc.id_discharge, o_error);
            IF l_ret = FALSE
            THEN
                o_msg_text := pk_message.get_message(i_lang, i_prof, i_code_mess => 'DISCHARGE_M004');
                RAISE err_set_disposition_dsc;
            END IF;
        
            -- call inserting function for DISCHARGE_DETAIL
            r_dsd.id_discharge := r_dsc.id_discharge;
            l_ret              := set_disposition_dsd(i_lang, i_prof, r_dsd, g_no, r_dsd.id_discharge_detail, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_set_disposition_dsc;
            END IF;
        
            r_dsc_h.id_discharge        := r_dsc.id_discharge;
            r_dsd_h.id_discharge        := r_dsc.id_discharge;
            r_dsd_h.id_discharge_detail := r_dsd.id_discharge_detail;
        
        ELSE
        
            -- call updating function for DISCHARGE
            l_ret := upd_disposition_dsc(i_lang, i_prof, r_dsc, g_no, r_dsc.id_discharge, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_set_disposition_dsc;
            END IF;
        
            -- call updating function for DISCHARGE_DETAIL
            l_ret := upd_disposition_dsd(i_lang, i_prof, r_dsd, g_no, r_dsd.id_discharge_detail, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_set_disposition_dsc;
            END IF;
        
        END IF;
    
        -- call updating function for DISCHARGE_HIST
        l_ret := set_disposition_dsc_h(i_lang, i_prof, r_dsc_h, g_no, r_dsc_h.id_discharge_hist, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_set_disposition_dsc;
        END IF;
    
        -- call updating function for DISCHARGE_DETAIL_HIST
        r_dsd_h.id_discharge_hist := r_dsc_h.id_discharge_hist;
        l_ret                     := set_disposition_dsd_h(i_lang,
                                                           i_prof,
                                                           r_dsd_h,
                                                           g_no,
                                                           r_dsd_h.id_discharge_detail_hist,
                                                           o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_set_disposition_dsc;
        END IF;
    
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(flg_status_in  => info_flg_type,
                         flg_status_nin => FALSE,
                         where_in       => 'ID_EPISODE = ' || i_id_episode || ' AND FLG_STATUS != ''' || info_flg_type || '''',
                         rows_out       => l_rowids_ei);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids_ei, o_error, table_varchar('FLG_STATUS'));
    
        g_error := 'UPDATE SCHEDULE_OUTP';
        IF nvl(l_id_schedule, -1) <> -1
        THEN
            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_schedule    => l_id_schedule,
                                                                       i_flg_state      => info_flg_type,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error)
            THEN
            
                RAISE l_func_exception;
            END IF;
        END IF;
    
        o_id_discharge             := r_dsc.id_discharge;
        o_id_discharge_hist        := r_dsc_h.id_discharge_hist;
        o_id_discharge_detail      := r_dsd.id_discharge_detail;
        o_id_discharge_detail_hist := r_dsd_h.id_discharge_detail_hist;
    
        FOR r_exam IN (SELECT erd.id_exam_req_det, erd.id_exam_req, erd.id_exam, er.id_episode
                         FROM exam_req_det erd, exam_req er
                        WHERE er.id_episode = i_id_episode
                          AND erd.id_exam_req = er.id_exam_req)
        LOOP
            g_error := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
            IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_patient      => NULL,
                                                      i_episode      => i_id_episode,
                                                      i_exam_req     => r_exam.id_exam_req,
                                                      i_exam_req_det => r_exam.id_exam_req_det,
                                                      o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_set_outdated THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'set_outdated',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN err_get_category THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'get_category',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN err_set_disposition_dsc THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_disposition;
    --
    /*
    * set disposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_dsc_h                    discharge_hist%type,
    * @param   i_dsd_h                    discharge_detail_type%type,
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    * @param   o_id_discharge             id of discharge returned
    * @param   o_flg_show                 flag to show warning screen Y/N
    * @param   o_msg_title                title of warning screen
    * @param   o_msg_text                 text of warning screen
    * @param   o_button                   buttons for warning screen
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */

    FUNCTION set_disposition
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_dsc_h                    IN discharge_hist%ROWTYPE,
        i_dsd_h                    IN discharge_detail_hist%ROWTYPE,
        i_disposition_flg_type     IN discharge_flash_files.flg_type%TYPE,
        i_transaction_id           IN VARCHAR2,
        o_id_discharge             OUT discharge.id_discharge%TYPE,
        o_id_discharge_hist        OUT discharge_hist.id_discharge_hist%TYPE,
        o_id_discharge_detail      OUT discharge_detail.id_discharge_detail%TYPE,
        o_id_discharge_detail_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        i_sysdate_tstz             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_show                 OUT VARCHAR2,
        o_msg_title                OUT VARCHAR2,
        o_msg_text                 OUT VARCHAR2,
        o_button                   OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                      BOOLEAN;
        l_category                 category.flg_type%TYPE;
        l_id_profile_template      profile_template.id_profile_template%TYPE;
        l_end_episode_on_discharge sys_config.value%TYPE;
        l_admin_admission          sys_config.value%TYPE;
    
        r_epi         episode%ROWTYPE;
        r_vis         visit%ROWTYPE;
        r_dsc         discharge%ROWTYPE;
        t_dsc         discharge%ROWTYPE;
        r_dsd         discharge_detail%ROWTYPE;
        r_dsc_h       discharge_hist%ROWTYPE;
        r_dsd_h       discharge_detail_hist%ROWTYPE;
        info_flg_type epis_info.flg_status%TYPE;
        l_rowids_ei   table_varchar;
        err_set_disposition_dsc  EXCEPTION;
        err_get_profile_template EXCEPTION;
        err_get_category         EXCEPTION;
        err_set_outdated         EXCEPTION;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_id_schedule    schedule.id_schedule%TYPE;
        l_func_exception EXCEPTION;
    
        --****************************************************
        FUNCTION get_id_schedule(i_id_episode IN NUMBER) RETURN NUMBER IS
            tbl_id   table_number;
            l_return NUMBER;
        BEGIN
        
            SELECT DISTINCT v.id_schedule
              BULK COLLECT
              INTO tbl_id
              FROM epis_info v
             WHERE v.id_episode = i_id_episode;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
            RETURN l_return;
        
        END get_id_schedule;
    
        PROCEDURE go_raise
        (
            i_ret          IN BOOLEAN,
            my_exception   IN VARCHAR2,
            i_code_message IN VARCHAR2 DEFAULT NULL
        ) IS
        BEGIN
        
            IF NOT i_ret
            THEN
            
                IF i_code_message IS NOT NULL
                THEN
                    o_msg_text := pk_message.get_message(i_lang, i_prof, i_code_mess => i_code_message);
                END IF;
            
                CASE my_exception
                    WHEN 'err_set_disposition_dsc' THEN
                        RAISE err_set_disposition_dsc;
                    WHEN 'l_func_exception' THEN
                        RAISE l_func_exception;
                    WHEN 'err_get_profile_template' THEN
                        RAISE err_get_profile_template;
                    WHEN 'err_get_category' THEN
                        RAISE err_get_category;
                    WHEN 'err_set_outdated' THEN
                        RAISE err_set_outdated;
                    ELSE
                        NULL;
                END CASE;
            
            END IF;
        
        END go_raise;
    
        FUNCTION get_row_episode(i_id_episode IN NUMBER) RETURN episode%ROWTYPE IS
            r_epi episode%ROWTYPE;
        BEGIN
        
            SELECT *
              INTO r_epi
              FROM episode
             WHERE id_episode = i_id_episode;
        
            RETURN r_epi;
        
        END get_row_episode;
    
        FUNCTION get_row_visit(i_id_visit IN NUMBER) RETURN visit%ROWTYPE IS
            r_vis visit%ROWTYPE;
        BEGIN
        
            SELECT *
              INTO r_vis
              FROM visit
             WHERE id_visit = r_epi.id_visit;
        
            RETURN r_vis;
        
        END get_row_visit;
    
        FUNCTION get_row_discharge(i_id_discharge IN NUMBER) RETURN discharge%ROWTYPE IS
            t_dsc discharge%ROWTYPE;
        BEGIN
        
            SELECT *
              INTO t_dsc
              FROM discharge
             WHERE id_discharge = i_id_discharge;
        
            RETURN t_dsc;
        
        END get_row_discharge;
    
        --***********************************************
        PROCEDURE copy_dsd_h_to_dsd IS
        BEGIN
        
            r_dsd.id_discharge := r_dsc.id_discharge;
        
            r_dsd.flg_pat_condition            := r_dsd_h.flg_pat_condition;
            r_dsd.id_transport_type            := r_dsd_h.id_transport_type;
            r_dsd.id_disch_rea_transp_ent_inst := r_dsd_h.id_disch_rea_transp_ent_inst;
            r_dsd.flg_caretaker                := r_dsd_h.flg_caretaker;
            r_dsd.caretaker_notes              := r_dsd_h.caretaker_notes;
        
            r_dsd.flg_follow_up_by  := r_dsd_h.flg_follow_up_by;
            r_dsd.follow_up_notes   := r_dsd_h.follow_up_notes;
            r_dsd.flg_written_notes := r_dsd_h.flg_written_notes;
            r_dsd.flg_voluntary     := r_dsd_h.flg_voluntary;
            r_dsd.flg_pat_report    := r_dsd_h.flg_pat_report;
        
            r_dsd.flg_transfer_form         := r_dsd_h.flg_transfer_form;
            r_dsd.id_prof_admitting         := r_dsd_h.id_prof_admitting;
            r_dsd.id_dep_clin_serv_admiting := r_dsd_h.id_dep_clin_serv_admiting;
            r_dsd.flg_summary_report        := r_dsd_h.flg_summary_report;
            r_dsd.flg_autopsy_consent       := r_dsd_h.flg_autopsy_consent;
        
            r_dsd.autopsy_consent_desc   := r_dsd_h.autopsy_consent_desc;
            r_dsd.flg_orgn_dntn_info     := r_dsd_h.flg_orgn_dntn_info;
            r_dsd.orgn_dntn_info         := r_dsd_h.orgn_dntn_info;
            r_dsd.flg_examiner_notified  := r_dsd_h.flg_examiner_notified;
            r_dsd.examiner_notified_info := r_dsd_h.examiner_notified_info;
        
            r_dsd.flg_orgn_dntn_form_complete := r_dsd_h.flg_orgn_dntn_form_complete;
            r_dsd.flg_ama_form_complete       := r_dsd_h.flg_ama_form_complete;
            r_dsd.flg_lwbs_form_complete      := r_dsd_h.flg_lwbs_form_complete;
            r_dsd.notes                       := r_dsd_h.notes;
            r_dsd.prof_admitting_desc         := r_dsd_h.prof_admitting_desc;
        
            r_dsd.dep_clin_serv_admiting_desc := r_dsd_h.dep_clin_serv_admiting_desc;
            r_dsd.mse_type                    := r_dsd_h.mse_type;
            r_dsd.flg_surgery                 := r_dsd_h.flg_surgery;
            r_dsd.follow_up_date_tstz         := r_dsd_h.follow_up_date_tstz;
            r_dsd.date_surgery_tstz           := r_dsd_h.date_surgery_tstz;
        
            r_dsd.flg_print_report           := r_dsd_h.flg_print_report;
            r_dsd.followup_count             := r_dsd_h.followup_count;
            r_dsd.total_time_spent           := r_dsd_h.total_time_spent;
            r_dsd.id_unit_measure            := r_dsd_h.id_unit_measure;
            r_dsd.flg_autopsy                := r_dsd_h.flg_autopsy;
            r_dsd.death_process_registration := r_dsd_h.death_process_registration;
            r_dsd.id_inst_transfer           := r_dsd_h.id_inst_transfer;
            -- if final discharge and dt_admin not filled , do it
            r_dsd.id_admitting_doctor  := r_dsd_h.id_admitting_doctor;
            r_dsd.id_written_by        := r_dsd_h.id_written_by;
            r_dsd.flg_compulsory       := r_dsd_h.flg_compulsory;
            r_dsd.id_compulsory_reason := r_dsd_h.id_compulsory_reason;
            r_dsd.compulsory_reason    := r_dsd_h.compulsory_reason;
        
            -- CMF
            r_dsd.oper_treatment_detail := r_dsd_h.oper_treatment_detail;
            r_dsd.status_before_death   := r_dsd_h.status_before_death;
        
        END copy_dsd_h_to_dsd;
    
        PROCEDURE ins_upd_disposition IS
        BEGIN
        
            IF i_dsc_h.id_discharge_hist IS NULL
            THEN
                pk_alertlog.log_debug(' I**set_disposition_dsc: ' || r_dsc.id_disch_reas_dest);
                -- call inserting function for DISCHARGE
                l_ret := set_disposition_dsc(i_lang, i_prof, r_dsc, g_no, r_dsc.id_discharge, o_error);
                go_raise(l_ret, 'err_set_disposition_dsc', 'DISCHARGE_M004');
            
                -- call inserting function for DISCHARGE_DETAIL
                r_dsd.id_discharge := r_dsc.id_discharge;
                l_ret              := set_disposition_dsd(i_lang,
                                                          i_prof,
                                                          r_dsd,
                                                          g_no,
                                                          r_dsd.id_discharge_detail,
                                                          o_error);
                go_raise(l_ret, 'err_set_disposition_dsc');
            
                r_dsc_h.id_discharge        := r_dsc.id_discharge;
                r_dsd_h.id_discharge        := r_dsc.id_discharge;
                r_dsd_h.id_discharge_detail := r_dsd.id_discharge_detail;
            
            ELSE
            
                -- call updating function for DISCHARGE
                l_ret := upd_disposition_dsc(i_lang, i_prof, r_dsc, g_no, r_dsc.id_discharge, o_error);
                go_raise(l_ret, 'err_set_disposition_dsc');
            
                -- José Brito 05/05/2011 ALERT-173596
                -- Bug fix: ID_DISCHARGE_DETAIL was passed as NULL and DISCHARGE_DETAIL wasn't being updated.
                r_dsd.id_discharge_detail := r_dsd_h.id_discharge_detail;
            
                -- call updating function for DISCHARGE_DETAIL
                l_ret := upd_disposition_dsd(i_lang, i_prof, r_dsd, g_no, r_dsd.id_discharge_detail, o_error);
                go_raise(l_ret, 'err_set_disposition_dsc');
            
            END IF;
        
        END ins_upd_disposition;
    
        PROCEDURE set_schedule_consult_state IS
            l_ret BOOLEAN;
        BEGIN
        
            IF nvl(l_id_schedule, -1) <> -1
            THEN
                l_ret := pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                             i_prof           => i_prof,
                                                                             i_id_schedule    => l_id_schedule,
                                                                             i_flg_state      => info_flg_type,
                                                                             i_transaction_id => l_transaction_id,
                                                                             o_error          => o_error);
                go_raise(l_ret, 'l_func_exception');
            END IF;
        
        END set_schedule_consult_state;
    
        FUNCTION process_error
        (
            i_sql_code IN NUMBER,
            i_text     IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_sql_code,
                                              i_text,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
        END process_error;
    
    BEGIN
        g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error       := 'GET SCHEDULE ID';
        l_id_schedule := get_id_schedule(i_id_episode => i_id_episode);
    
        r_epi.flg_migration := 'A';
        r_vis.flg_migration := 'A';
    
        l_end_episode_on_discharge := pk_sysconfig.get_config('END_EPISODE_ON_DISCHARGE', i_prof);
        l_admin_admission          := nvl(pk_sysconfig.get_config(g_admin_admission, i_prof), g_no);
    
        info_flg_type := 'D';
    
        l_ret := get_profile_template(i_lang, i_prof, l_id_profile_template, o_error);
        go_raise(l_ret, 'err_get_profile_template');
    
        l_ret := get_category(i_lang, i_prof, l_category, o_error);
        go_raise(l_ret, 'err_get_category');
    
        r_epi := get_row_episode(i_id_episode);
        r_vis := get_row_visit(r_epi.id_visit);
    
        r_dsc_h                     := i_dsc_h;
        r_dsd_h                     := i_dsd_h;
        r_dsc_h.id_profile_template := l_id_profile_template;
    
        -- fill discharge master table
        r_dsc.id_disch_reas_dest       := r_dsc_h.id_disch_reas_dest;
        r_dsc.id_episode               := r_epi.id_episode;
        r_dsc.id_prof_med              := r_dsc_h.id_prof_med;
        r_dsc.dt_med_tstz              := r_dsc_h.dt_med_tstz;
        r_dsc.notes_med                := r_dsc_h.notes_med;
        r_dsc.flg_status               := i_dsc_h.flg_status;
        r_dsc.id_discharge_status      := i_dsc_h.id_discharge_status;
        r_dsc.flg_type                 := g_episode_end;
        r_dsc.id_discharge             := i_dsc_h.id_discharge;
        r_dsc.id_cpt_code              := i_dsc_h.id_cpt_code;
        r_dsc.id_discharge_flash_files := i_dsc_h.id_discharge_flash_files;
    
        -- fill discharge detail table
        IF r_dsc.id_discharge IS NOT NULL
        THEN
            t_dsc := get_row_discharge(r_dsc.id_discharge);
        END IF;
    
        r_dsc_h.flg_status_hist := i_dsc_h.flg_status;
        r_dsc_h.id_cpt_code     := i_dsc_h.id_cpt_code;
    
        copy_dsd_h_to_dsd();
    
        IF r_dsc.flg_status = g_active
           AND r_dsc.id_prof_admin IS NULL
           AND l_end_episode_on_discharge = g_yes
        THEN
        
            IF NOT (i_disposition_flg_type = g_disp_adms AND l_admin_admission = g_yes)
            THEN
            
                r_dsc.id_prof_admin := i_prof.id;
                r_dsc.dt_admin_tstz := nvl(r_dsc_h.dt_med_tstz, g_sysdate_tstz);
                info_flg_type       := 'T';
            
                r_dsc_h.id_prof_admin := r_dsc.id_prof_admin;
                r_dsc_h.dt_admin_tstz := r_dsc.dt_admin_tstz;
            END IF;
        
        END IF;
    
        IF r_dsc.flg_status = g_active
           AND t_dsc.flg_status = g_pendente
        THEN
        
            r_dsc.id_prof_pend_active := i_prof.id;
            r_dsc.dt_pend_active_tstz := g_sysdate_tstz;
        
            r_dsc_h.id_prof_pend_active := i_prof.id;
            r_dsc_h.dt_pend_active_tstz := g_sysdate_tstz;
        
        END IF;
    
        IF r_dsc.flg_status != g_active
           AND r_dsc.dt_pend_tstz IS NULL
        THEN
        
            r_dsc.dt_pend_tstz   := g_sysdate_tstz;
            r_dsc_h.dt_pend_tstz := g_sysdate_tstz;
        
        END IF;
    
        --
        pk_alertlog.log_debug(' I******: ' || r_dsc.id_discharge);
        g_error := 'Id discharge: ' || r_dsc.id_discharge;
        l_ret   := set_outdated(i_lang, i_prof, i_id_episode, o_error);
        go_raise(l_ret, 'err_set_outdated');
    
        ins_upd_disposition();
    
        -- call updating function for DISCHARGE_HIST
        l_ret := set_disposition_dsc_h(i_lang, i_prof, r_dsc_h, g_no, r_dsc_h.id_discharge_hist, o_error);
        go_raise(l_ret, 'err_set_disposition_dsc');
    
        -- call updating function for DISCHARGE_DETAIL_HIST
        r_dsd_h.id_discharge_hist := r_dsc_h.id_discharge_hist;
        l_ret                     := set_disposition_dsd_h(i_lang,
                                                           i_prof,
                                                           r_dsd_h,
                                                           g_no,
                                                           r_dsd_h.id_discharge_detail_hist,
                                                           o_error);
        go_raise(l_ret, 'err_set_disposition_dsc');
    
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(flg_status_in  => info_flg_type,
                         flg_status_nin => FALSE,
                         where_in       => 'ID_EPISODE = ' || i_id_episode || ' AND FLG_STATUS != ''' || info_flg_type || '''',
                         rows_out       => l_rowids_ei);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids_ei, o_error, table_varchar('FLG_STATUS'));
    
        g_error := 'UPDATE SCHEDULE_OUTP';
        set_schedule_consult_state();
    
        o_id_discharge             := r_dsc.id_discharge;
        o_id_discharge_hist        := r_dsc_h.id_discharge_hist;
        o_id_discharge_detail_hist := r_dsd_h.id_discharge_detail_hist;
        o_id_discharge_detail      := r_dsd.id_discharge_detail;
    
        set_api_commit(i_prof, i_transaction_id, l_transaction_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_set_outdated THEN
            RETURN process_error(i_sql_code => SQLCODE, i_text => 'set_outdated');
        
        WHEN err_get_category THEN
            RETURN process_error(i_sql_code => SQLCODE, i_text => 'get_category');
        
        WHEN err_get_profile_template THEN
            RETURN process_error(i_sql_code => SQLCODE, i_text => 'get_profile_template');
        
        WHEN OTHERS THEN
            RETURN process_error(i_sql_code => SQLCODE, i_text => SQLERRM);
        
    END set_disposition;
    -- ###########################################################

    /********************************************************************************************
     * Function that updates data into table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION upd_disposition_dsc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dsc          IN discharge%ROWTYPE,
        i_do_commit    IN VARCHAR2,
        o_id_discharge OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status_adm discharge.flg_status_adm%TYPE;
        l_rows_ei        table_varchar;
    BEGIN
        --o_error := '******:' || i_dsc.flg_status || '----' || i_dsc.id_discharge;
        --RETURN FALSE;
        -- save update
        IF i_dsc.dt_admin_tstz IS NOT NULL
        THEN
            l_flg_status_adm := pk_alert_constant.g_active;
        END IF;
    
        UPDATE discharge
           SET id_prof_cancel           = i_dsc.id_prof_cancel,
               notes_cancel             = i_dsc.notes_cancel,
               id_prof_med              = i_dsc.id_prof_med,
               notes_med                = i_dsc.notes_med,
               id_disch_reas_dest       = i_dsc.id_disch_reas_dest,
               id_prof_admin            = i_dsc.id_prof_admin,
               notes_admin              = i_dsc.notes_admin,
               flg_status               = i_dsc.flg_status,
               id_discharge_status      = i_dsc.id_discharge_status,
               flg_type                 = i_dsc.flg_type,
               id_transp_ent_adm        = i_dsc.id_transp_ent_adm,
               id_transp_ent_med        = i_dsc.id_transp_ent_med,
               notes_justify            = i_dsc.notes_justify,
               price                    = i_dsc.price,
               currency                 = i_dsc.currency,
               flg_payment              = i_dsc.flg_payment,
               id_prof_pend_active      = i_dsc.id_prof_pend_active,
               dt_med_tstz              = i_dsc.dt_med_tstz,
               dt_admin_tstz            = i_dsc.dt_admin_tstz,
               dt_cancel_tstz           = i_dsc.dt_cancel_tstz,
               dt_pend_active_tstz      = i_dsc.dt_pend_active_tstz,
               id_cpt_code              = i_dsc.id_cpt_code,
               flg_status_adm           = l_flg_status_adm,
               id_discharge_flash_files = i_dsc.id_discharge_flash_files
         WHERE id_discharge = i_dsc.id_discharge;
    
        ts_epis_info.upd(id_episode_in           => i_dsc.id_episode,
                         flg_dsch_status_in      => i_dsc.flg_status,
                         id_disch_reas_dest_in   => i_dsc.id_disch_reas_dest,
                         dt_med_tstz_in          => i_dsc.dt_med_tstz,
                         dt_med_tstz_nin         => FALSE,
                         dt_pend_active_tstz_in  => i_dsc.dt_pend_active_tstz,
                         dt_pend_active_tstz_nin => FALSE,
                         dt_admin_tstz_in        => i_dsc.dt_admin_tstz,
                         dt_admin_tstz_nin       => FALSE,
                         rows_out                => l_rows_ei);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_DSCH_STATUS',
                                                                      'ID_DISCH_REAS_DEST',
                                                                      'DT_MED_TSTZ',
                                                                      'DT_PEND_TSTZ',
                                                                      'DT_ADMIN_TSTZ'));
    
        o_id_discharge := i_dsc.id_discharge;
    
        IF i_do_commit = g_yes
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
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'UPD_DISPOSITION_DSC',
                                              o_error);
            RETURN FALSE;
    END upd_disposition_dsc;
    -- ###########################################################

    /********************************************************************************************
     * Function that updates data into table DISCHARGE_detail
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION upd_disposition_dsd
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dsd                 IN discharge_detail%ROWTYPE,
        i_do_commit           IN VARCHAR2,
        o_id_discharge_detail OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        UPDATE discharge_detail
           SET flg_pat_condition            = i_dsd.flg_pat_condition,
               id_transport_type            = i_dsd.id_transport_type,
               id_disch_rea_transp_ent_inst = i_dsd.id_disch_rea_transp_ent_inst,
               flg_caretaker                = i_dsd.flg_caretaker,
               caretaker_notes              = i_dsd.caretaker_notes,
               flg_follow_up_by             = i_dsd.flg_follow_up_by,
               follow_up_notes              = i_dsd.follow_up_notes,
               flg_written_notes            = i_dsd.flg_written_notes,
               flg_voluntary                = i_dsd.flg_voluntary,
               flg_pat_report               = i_dsd.flg_pat_report,
               flg_transfer_form            = i_dsd.flg_transfer_form,
               id_prof_admitting            = i_dsd.id_prof_admitting,
               id_dep_clin_serv_admiting    = i_dsd.id_dep_clin_serv_admiting,
               flg_summary_report           = i_dsd.flg_summary_report,
               flg_autopsy_consent          = i_dsd.flg_autopsy_consent,
               autopsy_consent_desc         = i_dsd.autopsy_consent_desc,
               flg_orgn_dntn_info           = i_dsd.flg_orgn_dntn_info,
               orgn_dntn_info               = i_dsd.orgn_dntn_info,
               flg_examiner_notified        = i_dsd.flg_examiner_notified,
               examiner_notified_info       = i_dsd.examiner_notified_info,
               flg_orgn_dntn_form_complete  = i_dsd.flg_orgn_dntn_form_complete,
               flg_ama_form_complete        = i_dsd.flg_ama_form_complete,
               flg_lwbs_form_complete       = i_dsd.flg_lwbs_form_complete,
               notes                        = i_dsd.notes,
               prof_admitting_desc          = i_dsd.prof_admitting_desc,
               dep_clin_serv_admiting_desc  = i_dsd.dep_clin_serv_admiting_desc,
               mse_type                     = i_dsd.mse_type,
               flg_surgery                  = i_dsd.flg_surgery,
               follow_up_date_tstz          = i_dsd.follow_up_date_tstz,
               date_surgery_tstz            = i_dsd.date_surgery_tstz,
               death_process_registration   = i_dsd.death_process_registration,
               id_admitting_doctor          = i_dsd.id_admitting_doctor,
               id_written_by                = i_dsd.id_written_by,
               flg_compulsory               = i_dsd.flg_compulsory,
               id_compulsory_reason         = i_dsd.id_compulsory_reason,
               compulsory_reason            = i_dsd.compulsory_reason,
               oper_treatment_detail        = i_dsd.oper_treatment_detail,
               status_before_death          = i_dsd.status_before_death
         WHERE id_discharge_detail = i_dsd.id_discharge_detail
           AND id_discharge = i_dsd.id_discharge;
    
        o_id_discharge_detail := i_dsd.id_discharge_detail;
    
        IF i_do_commit = g_yes
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
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'UPD_DISPOSITION_DSD',
                                              o_error);
            RETURN FALSE;
    END upd_disposition_dsd;
    -- ###########################################################

    /********************************************************************************************
     * Function that gets data from table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_id_discharge_hist   id de registo de alta se exisitir
     * @param O_sql           id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/15
    ********************************************************************************************/
    FUNCTION get_home_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_get_profile_template EXCEPTION;
        l_disch_letter_list_exception VARCHAR2(0050);
    
    BEGIN
    
        -- Retirar valor de excepção das multichoice para texto livre
        l_disch_letter_list_exception := pk_sysconfig.get_config('DISCH_LETTER_LIST_EXCEPTION', i_prof);
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            OPEN o_sql FOR
                SELECT dh.id_disch_reas_dest id_disch_reas_dest,
                       dh.id_discharge_hist,
                       dh.flg_status flg_status,
                       pk_sysdomain.get_domain(g_disch_flg_status_domain, dh.flg_status, i_lang) desc_flg_status,
                       dh.id_discharge_status,
                       get_disch_status_desc(i_lang, i_prof, dh.id_discharge_status, dh.flg_status) desc_disch_status,
                       pk_translation.get_translation(i_lang, dr.code_discharge_reason) l_disposition,
                       get_disch_dest_label(i_lang, i_prof, drd.id_disch_reas_dest) l_to,
                       ddh.flg_pat_condition flg_pat_condition,
                       pk_discharge.get_patient_condition(i_lang,
                                                          i_prof,
                                                          dsc.id_discharge,
                                                          dr.id_discharge_reason,
                                                          ddh.flg_pat_condition) pat_condition,
                       ddh.flg_med_reconcile flg_med_reconcile,
                       pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_MED_RECONCILE', ddh.flg_med_reconcile, i_lang) med_reconcile,
                       ddh.flg_prescription_given flg_prescription_given,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang) prescription_given,
                       ddh.flg_written_notes flg_written_notes,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_written_notes, i_lang) desc_flg_written_notes,
                       pk_date_utils.date_send_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition_flash,
                       pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) dt_disposition,
                       ddh.flg_instructions_discussed nur_flg_instructions_discussed,
                       decode(ddh.flg_instructions_discussed,
                              l_disch_letter_list_exception,
                              ddh.instructions_discussed_notes,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_INSTRUCTIONS_DISCUSSED',
                                                      ddh.flg_instructions_discussed,
                                                      i_lang)) desc_instructions_discussed,
                       ddh.instructions_understood nur_instructions_understood,
                       pk_sysdomain.get_domain('YES_NO', ddh.instructions_understood, i_lang) desc_instructions_understood,
                       ddh.flg_prescription_given flg_prescription_given,
                       pk_sysdomain.get_domain('YES_NO', ddh.flg_prescription_given, i_lang) desc_flg_prescription_given,
                       ddh.vs_taken vs_taken,
                       pk_sysdomain.get_domain('YES_NO_NEED', ddh.vs_taken, i_lang) desc_vs_taken,
                       ddh.intake_output_done intake_output_done,
                       pk_sysdomain.get_domain('YES_NO_NEED', ddh.intake_output_done, i_lang) desc_intake_output_done,
                       ddh.flg_patient_transport flg_patient_transport,
                       decode(ddh.flg_patient_transport,
                              l_disch_letter_list_exception,
                              ddh.desc_patient_transport,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PATIENT_TRANSPORT',
                                                      ddh.flg_patient_transport,
                                                      i_lang)) desc_patient_transport,
                       ddh.flg_pat_escorted_by nur_flg_pat_escorted_by,
                       decode(ddh.flg_pat_escorted_by,
                              l_disch_letter_list_exception,
                              ddh.desc_pat_escorted_by,
                              pk_sysdomain.get_domain('DISCHARGE_DETAIL_HIST.FLG_PAT_ESCORTED_BY',
                                                      ddh.flg_pat_escorted_by,
                                                      i_lang)) nur_desc_flg_pat_escorted_by,
                       dh.notes_med additional_notes,
                       (SELECT pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason)
                          FROM dual) desc_cancel_reason,
                       dsc.notes_cancel,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, dsc.id_prof_cancel)
                          FROM dual) prof_cancel,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                dsc.id_prof_cancel,
                                                                dsc.dt_cancel_tstz,
                                                                dsc.id_episode)
                          FROM dual) spec_cancel,
                       (SELECT pk_date_utils.dt_chr_tsz(i_lang, dsc.dt_cancel_tstz, i_prof)
                          FROM dual) date_cancel,
                       -- José Brito 02/06/2008 Novos campos adicionados ao ecrã
                       dh.id_cpt_code id_level_of_service,
                       (SELECT c.medium_desc
                          FROM cpt_code c
                         WHERE c.id_cpt_code = dh.id_cpt_code) level_of_service_desc,
                       -- AS 14-12-2009 (ALERT-62112)
                       ddh.flg_print_report,
                       (SELECT pk_sysdomain.get_domain(g_flg_print_report_domain, ddh.flg_print_report, i_lang)
                          FROM dual) desc_flg_print_report,
                       c.id_order_type,
                       c.id_prof_ordered_by,
                       (SELECT pk_date_utils.date_send_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software)
                          FROM dual) dt_ordered_by_flash,
                       (SELECT pk_date_utils.date_char_tsz(i_lang, c.dt_ordered_by, i_prof.institution, i_prof.software)
                          FROM dual) dt_ordered_by,
                       c.desc_order_type,
                       c.desc_prof_ordered_by
                  FROM discharge_hist dh
                  JOIN discharge dsc
                    ON dsc.id_discharge = dh.id_discharge
                  JOIN discharge_detail_hist ddh
                    ON dh.id_discharge_hist = ddh.id_discharge_hist
                  JOIN disch_reas_dest drd
                    ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
                  JOIN discharge_reason dr
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                  JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN professional prfa
                    ON prfa.id_professional = ddh.id_prof_admitting
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                  LEFT JOIN TABLE(pk_co_sign_api.tf_co_sign_task_info(i_lang => i_lang, i_prof => i_prof, i_episode => dh.id_episode, i_id_co_sign => ddh.id_co_sign)) c
                    ON c.id_co_sign = ddh.id_co_sign
                 WHERE dh.id_discharge_hist = i_id_discharge_hist
                 ORDER BY dh.dt_created_hist DESC;
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'err_get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_HOME_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_HOME_DISPOSITION',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
        
            RETURN FALSE;
    END get_home_disposition;

    FUNCTION set_transfer_disposition
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_flg_status              IN discharge_hist.flg_status%TYPE,
        i_discharge_status        IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest      IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist       IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition       IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_reason_of_transfer      IN discharge_detail_hist.reason_of_transfer%TYPE,
        i_flg_transfer_transport  IN discharge_detail_hist.flg_transfer_transport%TYPE,
        i_dt_transfer_transport   IN VARCHAR2,
        i_desc_transfer_transport IN discharge_detail_hist.desc_transfer_transport%TYPE,
        i_risk_of_transfer        IN discharge_detail_hist.risk_of_transfer%TYPE,
        i_benefits_of_transfer    IN discharge_detail_hist.benefits_of_transfer%TYPE,
        i_flg_med_reconcile       IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_prof_admitting_desc     IN discharge_detail_hist.prof_admitting_desc%TYPE,
        i_dt_prof_admiting        IN VARCHAR2,
        i_en_route_orders         IN discharge_detail_hist.en_route_orders%TYPE,
        i_flg_patient_consent     IN discharge_detail_hist.flg_patient_consent%TYPE,
        i_acceptance_facility     IN discharge_detail_hist.acceptance_facility%TYPE,
        i_admitting_room          IN discharge_detail_hist.admitting_room%TYPE,
        i_room_assigned_by        IN discharge_detail_hist.room_assigned_by%TYPE,
        i_items_sent_with_patient IN discharge_detail_hist.items_sent_with_patient%TYPE,
        i_vs_taken                IN discharge_detail_hist.vs_taken%TYPE,
        i_intake_output_done      IN discharge_detail_hist.intake_output_done%TYPE,
        i_notes                   IN discharge_hist.notes_med%TYPE,
        i_report_given_to         IN discharge_detail_hist.report_given_to%TYPE,
        i_dt_med                  IN VARCHAR2,
        i_reason_of_transfer_desc IN discharge_detail_hist.reason_of_transfer_desc%TYPE,
        i_flg_print_report        IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files   IN discharge_hist.id_discharge_flash_files%TYPE,
        i_id_inst_transfer        IN discharge_detail_hist.id_inst_transfer%TYPE,
        o_dsc                     OUT discharge_hist%ROWTYPE,
        o_dsd                     OUT discharge_detail_hist%ROWTYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    
        l_dt_med    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL);
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_sc_clues sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_TRANSFER_CLUES', i_prof);
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest := i_id_disch_reas_dest;
        o_dsc.id_discharge       := r_dsc.id_discharge;
        o_dsc.id_discharge_hist  := i_id_discharge_hist;
        o_dsc.id_episode         := i_id_episode;
        o_dsc.id_prof_med        := i_prof.id;
        -- José Brito 30/05/2008 Este ecrã passou a ter um novo campo "Discharge Time / Date"
        o_dsc.dt_med_tstz := least(l_dt_med, l_timestamp);
        --
        o_dsc.notes_med                := i_notes;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
    
        o_dsd.flg_pat_condition          := i_flg_pat_condition;
        o_dsd.reason_of_transfer         := i_reason_of_transfer;
        o_dsd.flg_transfer_transport     := i_flg_transfer_transport;
        o_dsd.dt_transfer_transport_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_transfer_transport, NULL);
        o_dsd.desc_transfer_transport    := i_desc_transfer_transport;
        o_dsd.risk_of_transfer           := i_risk_of_transfer;
        o_dsd.benefits_of_transfer       := i_benefits_of_transfer;
        o_dsd.flg_med_reconcile          := i_flg_med_reconcile;
        o_dsd.prof_admitting_desc        := i_prof_admitting_desc;
        o_dsd.dt_prof_admiting_tstz      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_prof_admiting, NULL);
        o_dsd.en_route_orders            := i_en_route_orders;
        o_dsd.flg_patient_consent        := i_flg_patient_consent;
        o_dsd.acceptance_facility        := i_acceptance_facility;
        o_dsd.admitting_room             := i_admitting_room;
        o_dsd.room_assigned_by           := i_room_assigned_by;
        o_dsd.items_sent_with_patient    := i_items_sent_with_patient;
        o_dsd.vs_taken                   := i_vs_taken;
        o_dsd.intake_output_done         := i_intake_output_done;
        -- José Brito 30/05/2008 Adicionados novos campos ao ecrã
        o_dsd.report_given_to         := i_report_given_to;
        o_dsd.reason_of_transfer_desc := i_reason_of_transfer_desc; -- 'Reason of transfer' suporta texto livre
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
        --
        o_dsd.id_inst_transfer := i_id_inst_transfer;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_TRANSFER_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_transfer_disposition;

    /*
    * set Home disposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_disch_reas_dest       id of discharge/destination
    * @param   i_id_discharge_hist        id of Dischage_hist  record
    * @param   i_flg_pat_condition        flg of patient condition
    * @param   i_med_reconciliation       content of medication reconciliation
    * @param   i_flg_prescription         prescription given to Y/N
    * @param   i_care_discussed           care and instructions discussed with people indicated
    * @param   i_instructions_understood  
    * @param   i_follow_up_by             follow_up by
    * @param   i_dt_follow_up             date for follow_up
    * @param   i_notes                    additional notes
    * @param   o_dsc                      discharge_hist record type
    * @param   o_dsd                      discharge_detail_hist record type
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION set_home_disposition
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_flg_status                   IN discharge_hist.flg_status%TYPE,
        i_discharge_status             IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest           IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist            IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition            IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_flg_prescription             IN discharge_detail_hist.flg_prescription_given%TYPE,
        i_flg_written_notes            IN discharge_detail_hist.flg_written_notes%TYPE,
        i_dt_med                       IN VARCHAR2,
        i_flg_instructions_discussed   IN discharge_detail_hist.flg_instructions_discussed%TYPE,
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE,
        i_intructions_understood       IN discharge_detail_hist.instructions_understood%TYPE,
        i_vs_taken                     IN discharge_detail_hist.vs_taken%TYPE,
        i_intake_output_done           IN discharge_detail_hist.intake_output_done%TYPE,
        i_flg_patient_transport        IN discharge_detail_hist.flg_patient_transport%TYPE,
        i_flg_pat_escorted_by          IN discharge_detail_hist.flg_pat_escorted_by%TYPE,
        i_desc_pat_escorted_by         IN discharge_detail_hist.desc_pat_escorted_by%TYPE,
        i_notes                        IN discharge_hist.notes_med%TYPE,
        i_flg_print_report             IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files        IN discharge_hist.id_discharge_flash_files%TYPE,
        o_dsc                          OUT discharge_hist%ROWTYPE,
        o_dsd                          OUT discharge_detail_hist%ROWTYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    
        l_dt_med    TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_med, NULL);
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest := i_id_disch_reas_dest;
    
        o_dsc.id_discharge             := r_dsc.id_discharge;
        o_dsc.id_discharge_hist        := i_id_discharge_hist;
        o_dsc.id_episode               := i_id_episode;
        o_dsc.id_prof_med              := i_prof.id;
        o_dsc.dt_med_tstz              := least(l_dt_med, l_timestamp);
        o_dsc.notes_med                := i_notes;
        o_dsc.flg_status               := i_flg_status;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail table
        o_dsd.id_discharge                 := r_dsc.id_discharge;
        o_dsd.id_discharge_hist            := i_id_discharge_hist;
        o_dsd.id_discharge_detail          := r_dsd.id_discharge_detail;
        o_dsd.flg_pat_condition            := i_flg_pat_condition;
        o_dsd.flg_med_reconcile            := i_flg_med_reconcile;
        o_dsd.flg_prescription_given       := i_flg_prescription;
        o_dsd.flg_written_notes            := i_flg_written_notes;
        o_dsd.flg_instructions_discussed   := i_flg_instructions_discussed;
        o_dsd.instructions_discussed_notes := i_instructions_discussed_notes;
        o_dsd.instructions_understood      := i_intructions_understood;
        o_dsd.vs_taken                     := i_vs_taken;
        o_dsd.intake_output_done           := i_intake_output_done;
        o_dsd.flg_patient_transport        := i_flg_patient_transport;
        o_dsd.flg_pat_escorted_by          := i_flg_pat_escorted_by;
        o_dsd.desc_pat_escorted_by         := i_desc_pat_escorted_by;
        --       o_dsd.follow_up_date               := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_follow_up, NULL);
        --        o_dsd.follow_up_date_tstz          := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_follow_up, NULL);
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
    
        pk_alertlog.log_debug(' i_id_disch_reas_dest: ' || i_id_disch_reas_dest || 'o_dsc.id_disch_reas_dest:' ||
                              o_dsc.id_disch_reas_dest);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_HOME_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_home_disposition;

    /*
    * set Home disposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_disch_reas_dest       id of discharge/destination
    * @param   i_id_discharge_hist        id of Dischage_hist  record
    * @param   i_flg_pat_condition        flg of patient condition
    * @param   i_med_reconciliation       content of medication reconciliation
    * @param   i_flg_prescription         prescription given to Y/N
    * @param   i_care_discussed           care and instructions discussed with people indicated
    * @param   i_instructions_understood  
    * @param   i_follow_up_by             follow_up by
    * @param   i_dt_follow_up             date for follow_up
    * @param   i_notes                    additional notes
    * @param   o_dsc                      discharge_hist record type
    * @param   o_dsd                      discharge_detail_hist record type
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION set_followup_disposition
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_flg_status                   IN discharge_hist.flg_status%TYPE,
        i_discharge_status             IN discharge_status.id_discharge_status%TYPE,
        i_id_disch_reas_dest           IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist            IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition            IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_flg_instructions_discussed   IN discharge_detail_hist.flg_instructions_discussed%TYPE,
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE,
        i_pat_instructions_provided    IN discharge_detail_hist.pat_instructions_provided%TYPE,
        i_flg_prescription_given_to    IN discharge_detail_hist.flg_prescription_given_to%TYPE,
        i_desc_prescription_given_to   IN discharge_detail_hist.desc_prescription_given_to%TYPE,
        i_id_prof_assigned_to          IN discharge_detail_hist.id_prof_assigned_to%TYPE,
        i_next_visit_scheduled         IN discharge_detail_hist.next_visit_scheduled%TYPE,
        i_flg_instructions_next_visit  IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_desc_instructions_next_visit IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_id_dep_clin_serv_visit       IN discharge_detail_hist.id_dep_clin_serv_visit%TYPE,
        i_id_complaint                 IN discharge_detail_hist.id_complaint%TYPE,
        i_notes_registrar              IN discharge_detail_hist.notes%TYPE,
        i_notes                        IN discharge_hist.notes_med%TYPE,
        i_flg_print_report             IN discharge_detail_hist.flg_print_report%TYPE,
        i_discharge_flash_files        IN discharge_hist.id_discharge_flash_files%TYPE,
        o_dsc                          OUT discharge_hist%ROWTYPE,
        o_dsd                          OUT discharge_detail_hist%ROWTYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        r_dsc discharge_hist%ROWTYPE;
        r_dsd discharge_detail_hist%ROWTYPE;
    BEGIN
    
        IF i_id_discharge_hist IS NOT NULL
        THEN
        
            SELECT *
              INTO r_dsc
              FROM discharge_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
            SELECT *
              INTO r_dsd
              FROM discharge_detail_hist
             WHERE id_discharge_hist = i_id_discharge_hist;
        
        END IF;
    
        -- fill discharge master table
        o_dsc.id_disch_reas_dest := i_id_disch_reas_dest;
    
        o_dsc.id_discharge             := r_dsc.id_discharge;
        o_dsc.id_discharge_hist        := i_id_discharge_hist;
        o_dsc.id_episode               := i_id_episode;
        o_dsc.id_prof_med              := i_prof.id;
        o_dsc.dt_med_tstz              := nvl(r_dsc.dt_med_tstz, current_timestamp);
        o_dsc.notes_med                := i_notes;
        o_dsc.flg_status               := g_active;
        o_dsc.id_discharge_status      := i_discharge_status;
        o_dsc.flg_type                 := g_episode_end;
        o_dsc.dt_pend_tstz             := r_dsc.dt_pend_tstz;
        o_dsc.id_cpt_code              := r_dsc.id_cpt_code;
        o_dsc.id_discharge_flash_files := i_discharge_flash_files;
    
        -- fill discharge detail tablec
        o_dsd.id_discharge        := r_dsc.id_discharge;
        o_dsd.id_discharge_hist   := i_id_discharge_hist;
        o_dsd.id_discharge_detail := r_dsd.id_discharge_detail;
        o_dsd.flg_pat_condition   := i_flg_pat_condition;
    
        o_dsd.id_consult_req               := r_dsd.id_consult_req;
        o_dsd.flg_med_reconcile            := i_flg_med_reconcile;
        o_dsd.flg_instructions_discussed   := i_flg_instructions_discussed;
        o_dsd.instructions_discussed_notes := i_instructions_discussed_notes;
        o_dsd.pat_instructions_provided    := i_pat_instructions_provided;
        o_dsd.flg_prescription_given_to    := i_flg_prescription_given_to;
        o_dsd.desc_prescription_given_to   := i_desc_prescription_given_to;
        o_dsd.id_prof_assigned_to          := i_id_prof_assigned_to;
        o_dsd.next_visit_scheduled         := i_next_visit_scheduled;
        o_dsd.flg_instructions_next_visit  := i_flg_instructions_next_visit;
        o_dsd.id_dep_clin_serv_visit       := i_id_dep_clin_serv_visit;
        o_dsd.id_complaint                 := i_id_complaint;
        o_dsd.notes                        := i_notes_registrar;
        o_dsd.id_consult_req               := r_dsd.id_consult_req;
        o_dsd.id_schedule                  := r_dsd.id_schedule;
        -- AS 14-12-2009 (ALERT-62112)
        o_dsd.flg_print_report := i_flg_print_report;
    
        pk_alertlog.log_debug(' i_id_disch_reas_dest: ' || i_id_disch_reas_dest || 'o_dsc.id_disch_reas_dest:' ||
                              o_dsc.id_disch_reas_dest);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_FOLLOWUP_DISPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_followup_disposition;
    /* set_status_episode
    *
    * @param i_lang          language associated to the professional executing the request
    * @param i_prof          professional, institution and software ids
    * @param i_id_episode    id of episode
    * @param i_epis_status   episode status to set
    * @param i_sysdate_tstz  date to set if is to finish the episode
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    * @param o_error 
    *
    * @author Fábio Oliveira
    * @date   06/02/2009
    *
    */

    FUNCTION set_status_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_epis_status    IN episode.flg_status%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_transaction_id VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- denormalization variables
        l_rowids table_varchar;
    
        l_dt_end_tstz episode.dt_end_tstz%TYPE;
        l_aux         VARCHAR2(2000);
    
        --Scheduler 3.0 transaction ID
        l_transaction_id    VARCHAR2(4000) := i_transaction_id;
        l_sei_flg_status    table_varchar;
        l_id_sr_epis_interv table_number;
        l_rowids2           table_varchar;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF i_prof.software IN
           (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_triage, pk_alert_constant.g_soft_ubu)
           OR i_epis_status <> g_pendente
        THEN
            g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
            -- no caso de já ter fim de episodio, nao deve sobrepor as datas ja gravadas.
            SELECT dt_end_tstz
              INTO l_dt_end_tstz
              FROM episode e
             WHERE e.id_episode = i_id_episode
               FOR UPDATE;
        
            ts_episode.upd(id_episode_in  => i_id_episode,
                           flg_status_in  => i_epis_status,
                           dt_end_tstz_in => CASE i_epis_status
                                                 WHEN g_inactive THEN
                                                  nvl(l_dt_end_tstz, g_sysdate_tstz)
                                                 ELSE
                                                  l_dt_end_tstz
                                             END,
                           rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF i_prof.software = pk_alert_constant.g_soft_oris
            THEN
                -- Actualiza o estado do paciente.
                g_error := 'CALL Pk_Sr_Grid.SET_PAT_STATUS';
                IF NOT pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_episode        => i_id_episode,
                                                      i_flg_status_new => 'O',
                                                      i_flg_status_old => NULL,
                                                      i_test           => 'N',
                                                      i_transaction_id => l_transaction_id,
                                                      o_flg_show       => l_aux,
                                                      o_msg_title      => l_aux,
                                                      o_msg_text       => l_aux,
                                                      o_button         => l_aux,
                                                      o_error          => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            
                -- all open surgical procedures are closed
                g_error := 'get l_id_sr_epis_interv, l_sei_flg_status';
                BEGIN
                    SELECT sei.id_sr_epis_interv, sei.flg_status
                      BULK COLLECT
                      INTO l_id_sr_epis_interv, l_sei_flg_status
                      FROM sr_epis_interv sei
                     WHERE sei.id_episode_context = i_id_episode
                       AND sei.flg_status != pk_alert_constant.g_interv_status_cancel;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_sei_flg_status    := table_varchar();
                        l_id_sr_epis_interv := table_number();
                END;
            
                FOR i IN 1 .. l_id_sr_epis_interv.count
                LOOP
                    IF l_sei_flg_status(i) IS NOT NULL
                    THEN
                        g_error := 'call ts_sr_epis_interv.upd';
                        ts_sr_epis_interv.upd(flg_status_in => CASE
                                                                   WHEN l_sei_flg_status(i) = pk_alert_constant.g_interv_status_requisition THEN
                                                                    pk_alert_constant.g_interv_status_finished
                                                                   WHEN l_sei_flg_status(i) = pk_alert_constant.g_interv_status_execution THEN
                                                                    pk_alert_constant.g_interv_status_finished
                                                                   ELSE
                                                                    l_sei_flg_status(i)
                                                               END,
                                              where_in      => 'id_sr_epis_interv = ' || l_id_sr_epis_interv(i),
                                              rows_out      => l_rowids2);
                    
                        g_error := 'call t_data_gov_mnt.process_update';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'SR_EPIS_INTERV',
                                                      i_rowids     => l_rowids2,
                                                      o_error      => o_error);
                    
                        g_error := 'call pk_sr_output.set_ia_event_prescription';
                        IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_flg_action        => 'U',
                                                                 i_id_sr_epis_interv => l_id_sr_epis_interv(i),
                                                                 i_flg_status_new    => CASE
                                                                                            WHEN l_sei_flg_status(i) =
                                                                                                 pk_alert_constant.g_interv_status_requisition THEN
                                                                                             pk_alert_constant.g_interv_status_finished
                                                                                            WHEN l_sei_flg_status(i) =
                                                                                                 pk_alert_constant.g_interv_status_execution THEN
                                                                                             pk_alert_constant.g_interv_status_finished
                                                                                            ELSE
                                                                                             l_sei_flg_status(i)
                                                                                        END,
                                                                 i_flg_status_old    => l_sei_flg_status(i),
                                                                 o_error             => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                    END IF;
                END LOOP;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_STATUS_EPISODE',
                                              o_error);
            RETURN FALSE;
    END set_status_episode;

    /*************************************************************************************************
    *
    * Set disposition, when patient refuses to be transfered to another institution.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_dsc_h                    discharge_hist%type,
    * @param   i_dsd_h                    discharge_detail_type%type,
    * @param   o_id_discharge             id of discharge returned
    * @param   o_flg_show                 flag to show warning screen Y/N
    * @param   o_msg_title                title of warning screen
    * @param   o_msg_text                 text of warning screen
    * @param   o_button                   buttons for warning screen
    * @param   O_ERROR                    warning/error message
    *
    * @return  TRUE if sucess, FALSE otherwise
    
    * @author  José Brito (based on SET_DISPOSITION, by Carlos Ferreira)
    * @version 1.0
    * @since   04-03-2009
    *
    **************************************************************************************************/
    FUNCTION set_disposition_refused
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_dsc_h                    IN discharge_hist%ROWTYPE,
        i_dsd_h                    IN discharge_detail_hist%ROWTYPE,
        i_disposition_flg_type     IN discharge_flash_files.flg_type%TYPE,
        i_sysdate_tstz             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_r_episode                IN episode%ROWTYPE,
        i_r_visit                  IN visit%ROWTYPE,
        i_flg_type_cat             IN category.flg_type%TYPE,
        o_id_discharge             OUT discharge.id_discharge%TYPE,
        o_id_discharge_hist        OUT discharge_hist.id_discharge_hist%TYPE,
        o_id_discharge_detail_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_category            category.flg_type%TYPE;
    
        r_epi episode%ROWTYPE;
        r_vis visit%ROWTYPE;
    
        r_dsc   discharge%ROWTYPE;
        r_dsd   discharge_detail%ROWTYPE;
        r_dsc_h discharge_hist%ROWTYPE;
        r_dsd_h discharge_detail_hist%ROWTYPE;
    
        l_err_set_disposition_dsc  EXCEPTION;
        l_err_get_profile_template EXCEPTION;
        l_err_get_category         EXCEPTION;
        l_err_set_outdated         EXCEPTION;
        l_err_updating             EXCEPTION;
    
    BEGIN
        g_error := 'GET DATE';
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
    
        g_error := 'INITIALIZE DATA';
        pk_alertlog.log_debug(g_error);
        r_epi      := i_r_episode;
        r_vis      := i_r_visit;
        r_dsc_h    := i_dsc_h;
        r_dsd_h    := i_dsd_h;
        l_category := i_flg_type_cat;
    
        r_epi.flg_migration := 'A';
        r_vis.flg_migration := 'A';
    
        g_error := 'GET PROFILE TEMPLATE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_profile_template(i_lang, i_prof, l_id_profile_template, o_error)
        THEN
            RAISE l_err_get_profile_template;
        END IF;
    
        g_error := 'COPY DATA';
        pk_alertlog.log_debug(g_error);
    
        -- DISCHARGE
        r_dsc.id_disch_reas_dest := r_dsc_h.id_disch_reas_dest;
        r_dsc.id_episode         := r_epi.id_episode;
        r_dsc.id_prof_med        := r_dsc_h.id_prof_med;
        r_dsc.dt_med_tstz        := r_dsc_h.dt_med_tstz;
        r_dsc.notes_med          := r_dsc_h.notes_med;
        r_dsc.flg_type           := g_episode_end;
        r_dsc.id_discharge       := i_dsc_h.id_discharge;
        r_dsc.id_cpt_code        := i_dsc_h.id_cpt_code;
        -- DISCHARGE: cancellation information
        r_dsc.dt_cancel_tstz := g_sysdate_tstz;
        r_dsc.id_prof_cancel := i_prof.id;
        --> Cancellation notes aren't filled in this particular case, so we use '-' just to avoid leaving it blank
        r_dsc.notes_cancel := '-';
        --
        r_dsc.flg_status          := i_dsc_h.flg_status;
        r_dsc.id_discharge_status := i_dsc_h.id_discharge_status;
        r_dsc.flg_cancel_type     := pk_alert_constant.g_disch_flgcanceltype_r; --> Cancelled by refusal ('R')
    
        r_dsc.id_discharge_flash_files := i_dsc_h.id_discharge_flash_files;
    
        -- DISCHARGE_DETAIL   
        r_dsd.id_discharge      := r_dsc.id_discharge;
        r_dsd.flg_pat_condition := r_dsd_h.flg_pat_condition;
    
        -- DISCHARGE_HIST
        r_dsc_h.flg_status_hist     := i_dsc_h.flg_status;
        r_dsc_h.id_cpt_code         := i_dsc_h.id_cpt_code;
        r_dsc_h.id_profile_template := l_id_profile_template;
        -- DISCHARGE_HIST: cancellation information
        r_dsc_h.dt_cancel_tstz := g_sysdate_tstz;
        r_dsc_h.id_prof_cancel := i_prof.id;
        --> Cancellation notes aren't filled in this particular case, so we use '-' just to avoid leaving it blank
        r_dsc_h.notes_cancel := '-';
        --
        r_dsc_h.flg_status      := i_dsc_h.flg_status;
        r_dsc_h.flg_status_hist := i_dsc_h.flg_status;
        r_dsc_h.flg_cancel_type := pk_alert_constant.g_disch_flgcanceltype_r; --> Cancelled by refusal ('R')
        --
    
        IF r_dsc.flg_status != g_active
           AND r_dsc.dt_pend_tstz IS NULL
        THEN
            r_dsc.dt_pend_tstz   := g_sysdate_tstz;
            r_dsc_h.dt_pend_tstz := g_sysdate_tstz;
        END IF;
    
        g_error := 'CALL TO SET_OUTDATED';
        pk_alertlog.log_debug(g_error);
        IF NOT set_outdated(i_lang, i_prof, i_id_episode, o_error)
        THEN
            RAISE l_err_set_outdated;
        END IF;
    
        IF i_dsc_h.id_discharge_hist IS NULL
        THEN
        
            g_error := 'INSERT - DISCHARGE';
            pk_alertlog.log_debug(g_error);
        
            SELECT seq_discharge.nextval
              INTO r_dsc.id_discharge
              FROM dual;
        
            INSERT INTO discharge
                (id_discharge,
                 id_disch_reas_dest,
                 id_episode,
                 id_prof_cancel,
                 notes_cancel,
                 id_prof_med,
                 notes_med,
                 id_prof_admin,
                 notes_admin,
                 flg_status,
                 id_discharge_status,
                 flg_type,
                 id_transp_ent_adm,
                 id_transp_ent_med,
                 notes_justify,
                 price,
                 currency,
                 flg_payment,
                 id_prof_pend_active,
                 dt_med_tstz,
                 dt_admin_tstz,
                 dt_cancel_tstz,
                 dt_pend_active_tstz,
                 dt_pend_tstz,
                 id_cpt_code,
                 flg_cancel_type,
                 flg_status_adm,
                 flg_market,
                 id_discharge_flash_files)
            VALUES
                (r_dsc.id_discharge,
                 r_dsc.id_disch_reas_dest,
                 r_dsc.id_episode,
                 r_dsc.id_prof_cancel,
                 r_dsc.notes_cancel,
                 r_dsc.id_prof_med,
                 r_dsc.notes_med,
                 r_dsc.id_prof_admin,
                 r_dsc.notes_admin,
                 r_dsc.flg_status,
                 r_dsc.id_discharge_status,
                 r_dsc.flg_type,
                 r_dsc.id_transp_ent_adm,
                 r_dsc.id_transp_ent_med,
                 r_dsc.notes_justify,
                 r_dsc.price,
                 r_dsc.currency,
                 r_dsc.flg_payment,
                 r_dsc.id_prof_pend_active,
                 r_dsc.dt_med_tstz,
                 r_dsc.dt_admin_tstz,
                 r_dsc.dt_cancel_tstz,
                 r_dsc.dt_pend_active_tstz,
                 r_dsc.dt_pend_tstz,
                 r_dsc.id_cpt_code,
                 r_dsc.flg_cancel_type,
                 decode(r_dsc.dt_admin_tstz, NULL, NULL, pk_alert_constant.g_active),
                 pk_discharge_core.g_disch_type_us,
                 r_dsc.id_discharge_flash_files);
        
            g_error := 'CHECK_DISPOSITION (2)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge.check_discharge(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_episode            => r_dsc.id_episode,
                                                i_can_edt_inact_epis => g_can_edit_inact_epis,
                                                o_error              => o_error)
            THEN
                RAISE pk_discharge.e_check_discharge;
            END IF;
        
            r_dsd.id_discharge := r_dsc.id_discharge;
        
            -- call inserting function for DISCHARGE_DETAIL
            g_error := 'CALL SET_DISPOSITION_DSD';
            pk_alertlog.log_debug(g_error);
            IF NOT set_disposition_dsd(i_lang, i_prof, r_dsd, g_no, r_dsd.id_discharge_detail, o_error)
            THEN
                RAISE l_err_set_disposition_dsc;
            END IF;
        
            r_dsc_h.id_discharge        := r_dsc.id_discharge;
            r_dsd_h.id_discharge        := r_dsc.id_discharge;
            r_dsd_h.id_discharge_detail := r_dsd.id_discharge_detail;
        
        ELSE
            -- When there's a refused disposition, that disposition must not be updated.
            g_error := 'UPDATING REFUSED DISPOSITION';
            pk_alertlog.log_debug(g_error);
            RAISE l_err_updating;
        END IF;
    
        -- call updating function for DISCHARGE_HIST
        g_error := 'CALL SET_DISPOSITION_DSC_H';
        pk_alertlog.log_debug(g_error);
        IF NOT set_disposition_dsc_h(i_lang, i_prof, r_dsc_h, g_no, r_dsc_h.id_discharge_hist, o_error)
        THEN
            RAISE l_err_set_disposition_dsc;
        END IF;
    
        r_dsd_h.id_discharge_hist := r_dsc_h.id_discharge_hist;
    
        -- call updating function for DISCHARGE_DETAIL_HIST
        g_error := 'CALL SET_DISPOSITION_DSD_H';
        pk_alertlog.log_debug(g_error);
        IF NOT set_disposition_dsd_h(i_lang, i_prof, r_dsd_h, g_no, r_dsd_h.id_discharge_detail_hist, o_error)
        THEN
            RAISE l_err_set_disposition_dsc;
        END IF;
    
        o_id_discharge             := r_dsc.id_discharge;
        o_id_discharge_hist        := r_dsc_h.id_discharge_hist;
        o_id_discharge_detail_hist := r_dsd_h.id_discharge_detail_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_discharge.e_check_discharge THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_err_set_outdated THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'set_outdated',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_REFUSED',
                                              o_error);
            RETURN FALSE;
        WHEN l_err_get_category THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'get_category',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_REFUSED',
                                              o_error);
            RETURN FALSE;
        
        WHEN l_err_get_profile_template THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'get_profile_template',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_REFUSED',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_DISPOSITION_REFUSED',
                                              o_error);
            RETURN FALSE;
    END set_disposition_refused;

    FUNCTION set_end_visit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_sysdate      IN DATE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count    NUMBER;
        l_id_visit visit.id_visit%TYPE;
        l_ret      BOOLEAN;
    
        l_prof_cat category.flg_type%TYPE;
    BEGIN
        g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
    
        SELECT id_visit
          INTO l_id_visit
          FROM episode
         WHERE id_episode = i_id_episode;
    
        SELECT COUNT(*)
          INTO l_count
          FROM episode
         WHERE id_visit = l_id_visit
           AND flg_status = g_active;
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        -- if no episode is active then close visit
        IF l_count = 0
        THEN
        
            l_ret := pk_visit.set_visit_end(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_prof_cat_type => l_prof_cat,
                                            i_id_visit      => l_id_visit,
                                            i_sysdate       => g_sysdate,
                                            i_sysdate_tstz  => g_sysdate_tstz,
                                            o_error         => o_error);
            IF l_ret = FALSE
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'PK_DIET.SET_DIET_INTERRUPT';
            IF NOT
                pk_diet.set_diet_interrupt(i_lang => i_lang, i_prof => i_prof, i_visit => l_id_visit, o_error => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_END_VISIT',
                                              o_error);
            RETURN FALSE;
    END set_end_visit;

    FUNCTION set_end_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_sysdate      IN DATE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        -- denormalization variables
        l_rowids table_varchar;
    
        l_dt_end_tstz episode.dt_end_tstz%TYPE;
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF NOT set_status_episode(i_lang, i_prof, i_id_episode, g_inactive, i_sysdate_tstz, l_transaction_id, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_END_EPISODE',
                                              o_error);
            RETURN FALSE;
    END set_end_episode;

    FUNCTION set_discharge_co_sign
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_discharge_admission,
        i_order_type   IN co_sign.id_order_type%TYPE DEFAULT NULL,
        i_prof_order   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_dt_order     IN VARCHAR2 DEFAULT NULL,
        i_id_co_sign   IN discharge_detail.id_co_sign%TYPE DEFAULT NULL
        
    ) RETURN NUMBER IS
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
        l_error           t_error_out;
    BEGIN
        IF i_id_co_sign IS NOT NULL
        THEN
            g_error := 'CALL PK_CO_SIGN_API.SET_TASK_OUTDATED';
            IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => i_id_episode,
                                                    i_id_co_sign      => i_id_co_sign,
                                                    i_id_co_sign_hist => NULL,
                                                    i_dt_update       => g_sysdate_tstz,
                                                    o_id_co_sign_hist => l_id_co_sign_hist,
                                                    o_error           => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        l_id_co_sign_hist := NULL;
        IF i_order_type IS NOT NULL
        THEN
        
            g_error := 'CALL PK_CO_SIGN_API.SET_PENDING_CO_SIGN_TASK';
            IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_id_episode,
                                                           i_id_task_type           => i_id_task_type, --pk_alert_constant.g_task_discharge_admission,
                                                           i_cosign_def_action_type => pk_co_sign_api.g_cosign_action_def_add,
                                                           i_id_task                => i_id_discharge,
                                                           i_id_task_group          => i_id_discharge,
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
                                                           o_error                  => l_error)
            THEN
                RAISE e_call_exception;
            END IF;
            RETURN l_id_co_sign;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END set_discharge_co_sign;

    /*
    * set Homedisposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_disch_reas_dest       id of discharge/destination
    * @param   i_id_discharge_hist        id of Dischage_hist  record
    * @param   i_flg_pat_condition        flg of patient condition
    * @param   i_med_reconciliation       content of medication reconciliation
    * @param   i_flg_prescription         prescription given to Y/N
    * @param   i_care_discussed           care and instructions discussed with people indicated
    * @param   i_instructions_understood  
    * @param   i_follow_up_by             follow_up by
    * @param   i_dt_follow_up             date for follow_up
    * @param   i_notes                    additional notes
    * @param   i_report_given_to          person who gets the report on transfer dispositions
    * @param   i_flg_print_report         flg print report
    * @param   i_flg_letter               type of discharge letter: P - print discharge letter; S - send discharge letter message
    * @param   i_flg_task                 list of tasks associated with the discharge letter
    * @param   i_transaction_id           Scheduler 3.0 transaction ID
    * @param   o_flg_show                 flag to show warning screen Y/N
    * @param   o_msg_title                title of warning screen
    * @param   o_msg_text                 text of warning screen
    * @param   o_button                   buttons for warning screen
    * @param   o_id_episode               episode ID that was created after the discharge
    * @param   o_id_discharge             discharge ID
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */

    FUNCTION set_main_disposition
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_discharge_status     IN discharge_status.id_discharge_status%TYPE,
        i_disposition_flg_type IN discharge_flash_files.flg_type%TYPE,
        i_id_disch_reas_dest   IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist    IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition    IN discharge_detail_hist.flg_pat_condition%TYPE, --8
        
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE DEFAULT NULL,
        i_flg_prescription_given       IN discharge_detail_hist.flg_prescription_given%TYPE DEFAULT NULL,
        i_flg_written_notes            IN discharge_detail_hist.flg_written_notes%TYPE DEFAULT NULL,
        i_dt_med                       IN VARCHAR2 DEFAULT NULL,
        i_flg_instructions_discussed   IN discharge_detail_hist.flg_instructions_discussed%TYPE DEFAULT NULL, -- 14
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE DEFAULT NULL,
        i_instructions_understood      IN discharge_detail_hist.instructions_understood%TYPE DEFAULT NULL,
        i_vs_taken                     IN discharge_detail_hist.vs_taken%TYPE DEFAULT NULL, -- 13
        i_intake_output_done           IN discharge_detail_hist.intake_output_done%TYPE DEFAULT NULL,
        i_flg_patient_transport        IN discharge_detail_hist.flg_patient_transport%TYPE DEFAULT NULL,
        i_flg_pat_escorted_by          IN discharge_detail_hist.flg_pat_escorted_by%TYPE DEFAULT NULL,
        i_desc_pat_escorted_by         IN discharge_detail_hist.desc_pat_escorted_by%TYPE DEFAULT NULL,
        i_notes                        IN discharge_hist.notes_med%TYPE DEFAULT NULL, -- 18
        --
        i_id_prof_admitting   IN discharge_detail_hist.id_prof_admitting%TYPE DEFAULT NULL,
        i_admission_orders    IN discharge_detail_hist.admission_orders%TYPE DEFAULT NULL,
        i_admit_to_room       IN discharge_detail_hist.admit_to_room%TYPE DEFAULT NULL,
        i_room_admit          IN discharge_detail_hist.id_room_admit%TYPE DEFAULT NULL,
        i_flg_check_valuables IN discharge_detail_hist.flg_check_valuables%TYPE DEFAULT NULL, -- 22
        --
        i_reason_of_transfer      IN discharge_detail_hist.reason_of_transfer%TYPE DEFAULT NULL,
        i_flg_transfer_transport  IN discharge_detail_hist.flg_transfer_transport%TYPE DEFAULT NULL,
        i_dt_transfer_transport   IN VARCHAR2 DEFAULT NULL,
        i_desc_transfer_transport IN discharge_detail_hist.desc_transfer_transport%TYPE DEFAULT NULL,
        i_risk_of_transfer        IN discharge_detail_hist.risk_of_transfer%TYPE DEFAULT NULL,
        i_benefits_of_transfer    IN discharge_detail_hist.benefits_of_transfer%TYPE DEFAULT NULL,
        i_prof_admitting_desc     IN discharge_detail_hist.prof_admitting_desc%TYPE DEFAULT NULL, --27
        i_dt_prof_admiting        IN VARCHAR2 DEFAULT NULL,
        i_en_route_orders         IN discharge_detail_hist.en_route_orders%TYPE DEFAULT NULL,
        i_flg_patient_consent     IN discharge_detail_hist.flg_patient_consent%TYPE DEFAULT NULL,
        i_acceptance_facility     IN discharge_detail_hist.acceptance_facility%TYPE DEFAULT NULL,
        i_admitting_room          IN discharge_detail_hist.admitting_room%TYPE DEFAULT NULL,
        i_room_assigned_by        IN discharge_detail_hist.room_assigned_by%TYPE DEFAULT NULL,
        i_items_sent_with_patient IN discharge_detail_hist.items_sent_with_patient%TYPE DEFAULT NULL, -- 34
        --
        i_dt_death                   IN VARCHAR2 DEFAULT NULL,
        i_prf_declared_death         IN discharge_detail_hist.prf_declared_death%TYPE DEFAULT NULL,
        i_autopsy_consent_desc       IN discharge_detail_hist.autopsy_consent_desc%TYPE DEFAULT NULL, -- 37
        i_flg_orgn_donation_agency   IN discharge_detail_hist.flg_orgn_donation_agency%TYPE DEFAULT NULL,
        i_flg_report_of_death        IN discharge_detail_hist.flg_report_of_death%TYPE DEFAULT NULL,
        i_flg_coroner_contacted      IN discharge_detail_hist.flg_coroner_contacted%TYPE DEFAULT NULL,
        i_coroner_name               IN discharge_detail_hist.coroner_name%TYPE DEFAULT NULL,
        i_flg_funeral_home_contacted IN discharge_detail_hist.flg_funeral_home_contacted%TYPE DEFAULT NULL,
        i_funeral_home_name          IN discharge_detail_hist.funeral_home_name%TYPE DEFAULT NULL, --43
        i_dt_body_removed            IN VARCHAR2 DEFAULT NULL,
        --
        i_risk_of_leaving     IN discharge_detail_hist.risk_of_leaving%TYPE DEFAULT NULL, -- 45
        i_flg_risk_of_leaving IN discharge_detail_hist.flg_risk_of_leaving%TYPE DEFAULT NULL,
        i_dt_ama              IN VARCHAR2 DEFAULT NULL,
        i_flg_signed_ama_form IN discharge_detail_hist.flg_signed_ama_form%TYPE DEFAULT NULL,
        i_signed_ama_form     IN discharge_detail_hist.desc_signed_ama_form%TYPE DEFAULT NULL, --49
        --
        i_mse_type IN discharge_detail_hist.mse_type%TYPE DEFAULT NULL,
        --
        i_reason_for_leaving IN discharge_detail_hist.reason_for_leaving%TYPE DEFAULT NULL, --51
        
        i_pat_instructions_provided    IN discharge_detail_hist.pat_instructions_provided%TYPE DEFAULT NULL,
        i_flg_prescription_given_to    IN discharge_detail_hist.flg_prescription_given_to%TYPE DEFAULT NULL,
        i_desc_prescription_given_to   IN discharge_detail_hist.desc_prescription_given_to%TYPE DEFAULT NULL,
        i_id_prof_assigned_to          IN discharge_detail_hist.id_prof_assigned_to%TYPE DEFAULT NULL,
        i_next_visit_scheduled         IN discharge_detail_hist.next_visit_scheduled%TYPE DEFAULT NULL,
        i_flg_instructions_next_visit  IN discharge_detail_hist.flg_instructions_next_visit%TYPE DEFAULT NULL,
        i_desc_instructions_next_visit IN discharge_detail_hist.desc_instructions_next_visit%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_visit       IN discharge_detail_hist.id_dep_clin_serv_visit%TYPE DEFAULT NULL,
        i_id_complaint                 IN discharge_detail_hist.id_complaint%TYPE DEFAULT NULL,
        i_notes_registrar              IN discharge_detail_hist.notes%TYPE DEFAULT NULL,
        i_id_cpt_code                  IN discharge.id_cpt_code%TYPE DEFAULT NULL,
        i_dt_proposed                  IN VARCHAR2 DEFAULT NULL,
        i_id_schedule                  IN schedule.id_schedule%TYPE DEFAULT NULL,
        --
        i_report_given_to         IN discharge_detail_hist.report_given_to%TYPE DEFAULT NULL,
        i_reason_of_transfer_desc IN discharge_detail_hist.reason_of_transfer_desc%TYPE DEFAULT NULL,
        --        i_commit_at_end                IN VARCHAR2 DEFAULT 'Y',
        i_transaction_id IN VARCHAR2,
        --
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report IN discharge_detail_hist.flg_print_report%TYPE DEFAULT NULL,
        --
        i_flg_letter IN discharge_rep_notes.flg_type%TYPE DEFAULT NULL,
        i_flg_task   IN discharge_rep_notes.flg_task%TYPE DEFAULT NULL,
        --
        i_id_dep_clin_serv_admit     IN discharge_detail.id_dep_clin_serv_admiting%TYPE DEFAULT NULL,
        i_flg_surgery                IN VARCHAR2 DEFAULT NULL,
        i_dt_surgery_str             IN VARCHAR2 DEFAULT NULL,
        i_death_characterization     IN discharge_detail_hist.id_death_characterization%TYPE DEFAULT NULL,
        i_death_process_registration IN discharge_detail.death_process_registration%TYPE DEFAULT NULL,
        --
        i_id_inst_transfer      IN discharge_detail_hist.id_inst_transfer%TYPE DEFAULT NULL,
        i_id_admitting_doctor   IN discharge_detail_hist.id_admitting_doctor%TYPE DEFAULT NULL,
        i_order_type            IN co_sign.id_order_type%TYPE DEFAULT NULL,
        i_prof_order            IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_dt_order              IN VARCHAR2 DEFAULT NULL,
        i_id_written_by         IN discharge_detail_hist.id_written_by%TYPE DEFAULT NULL,
        i_flg_compulsory        IN VARCHAR2 DEFAULT 'N',
        i_id_compulsory_reason  IN NUMBER DEFAULT NULL,
        i_compulsory_reason     IN VARCHAR2 DEFAULT NULL,
        i_oper_treatment_detail IN CLOB DEFAULT NULL,
        i_status_before_death   IN CLOB DEFAULT NULL,
        --
        o_shortcut     OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_reports      OUT reports.id_reports%TYPE,
        o_reports_pat  OUT reports.id_reports%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_id_episode   OUT episode.id_episode%TYPE,
        o_id_discharge OUT discharge.id_discharge%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret                      BOOLEAN;
        l_dt_med                   VARCHAR2(50);
        l_end_episode_on_discharge sys_config.value%TYPE;
        l_admin_admission          sys_config.value%TYPE;
        r_epi                      episode%ROWTYPE;
        r_vis                      visit%ROWTYPE;
        r_dsc_h                    discharge_hist%ROWTYPE;
        r_dsd_h                    discharge_detail_hist%ROWTYPE;
    
        l_id_discharge NUMBER;
    
        l_id_consult_req consult_req.id_consult_req%TYPE;
        l_button         VARCHAR2(0500);
        l_msg            VARCHAR2(0500);
        l_msg_title      VARCHAR2(0500);
        l_flg_show       VARCHAR2(0500);
        l_change         NUMBER;
        l_error          VARCHAR2(0500);
    
        l_category                 category.flg_type%TYPE;
        l_id_discharge_hist        discharge_hist.id_discharge_hist%TYPE;
        l_id_discharge_detail      discharge_detail.id_discharge_detail%TYPE;
        l_id_discharge_detail_hist discharge_detail_hist.id_discharge_detail_hist%TYPE;
        ---
        l_short_pend sys_shortcut.id_sys_shortcut%TYPE;
        --
        l_flg_type_date consult_req.flg_type_date%TYPE;
    
        l_status_cancel discharge.flg_status%TYPE;
    
        l_can_refresh_mviews VARCHAR2(1);
    
        l_err_set_misc_disposition EXCEPTION;
        l_err_set_disposition      EXCEPTION;
        l_err_chk_schedule         EXCEPTION;
        l_err_date_begin           EXCEPTION;
        l_err_shortcut             EXCEPTION;
        l_exception                EXCEPTION;
        l_cancel_print_jobs_excpt  EXCEPTION;
        l_transaction_id VARCHAR2(4000);
        l_label          pk_translation.t_desc_translation;
        l_print_config   sys_list_group_rel.flg_context%TYPE;
    
        l_flg_status           discharge.flg_status%TYPE;
        l_disch_status         discharge_status.id_discharge_status%TYPE;
        l_disch_flash_files    discharge_flash_files.id_discharge_flash_files%TYPE;
        l_disposition_flg_type discharge_flash_files.flg_type%TYPE;
        l_disch_reason         disch_reas_dest.id_discharge_reason%TYPE;
    
        l_disch_status_act CONSTANT discharge_status.id_discharge_status%TYPE := 1;
    
        l_rec_disch_rep_cfg   pk_discharge_crm.t_rec_disch_rep_cfg;
        l_table_disch_rep_cfg pk_discharge_crm.t_table_disch_rep_cfg;
        l_disch_rep_rowids    table_varchar := table_varchar();
    
        l_id_print_list_jobs table_number := table_number();
        l_print_jobs         table_number := table_number();
    
        -- cmf
        l_bool  BOOLEAN;
        l_error VARCHAR2(4000);
    
        ---- Discharge reports generation configs    
        CURSOR c_discharge_report_cfg(i_id_discharge discharge.id_discharge%TYPE) IS
            SELECT t.id_report, t.flg_send, t.flg_send_to_crm, t.generation_rank
              FROM TABLE(pk_discharge_crm.tf_discharge_report_cfg(i_lang => i_lang, i_prof => i_prof)) t
             WHERE NOT EXISTS (SELECT 1
                      FROM discharge_report dr
                     WHERE dr.id_report = t.id_report
                       AND dr.id_discharge = i_id_discharge)
             ORDER BY t.generation_rank;
        --
        --l_grid_task grid_task%ROWTYPE;
        l_status_string VARCHAR2(200);
        l_status_str    VARCHAR2(200);
        l_dummy         VARCHAR2(200);
    
        l_dt_epis_begin         episode.dt_begin_tstz%TYPE;
        l_check_intake_time_cfg sys_config.desc_sys_config%TYPE;
        l_auto_presc_cancel     VARCHAR2(1char);
        l_auto_cancel_msg       sys_message.desc_message%TYPE;
        l_prof_id               professional.id_professional%TYPE;
        l_bed_mandatory         VARCHAR2(1 CHAR);
        l_no_bed EXCEPTION;
        l_bed_allocated   VARCHAR2(1 CHAR);
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_disch_task_type task_type.id_task_type%TYPE;
    
        l_id_schedule  schedule.id_schedule%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_epis_exist EXCEPTION;
    
        --**************************************
        FUNCTION end_exception
        (
            i_prof           IN profissional,
            i_transaction_id IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
            pk_schedule_api_upstream.do_rollback(i_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END end_exception;
    
        FUNCTION process_error_msg
        (
            i_prof           IN profissional,
            i_transaction_id IN VARCHAR2,
            i_code           IN VARCHAR2,
            i_msg            IN VARCHAR2
        ) RETURN BOOLEAN IS
            l_error_in t_error_in := t_error_in();
            l_ret      BOOLEAN;
        BEGIN
            IF i_msg IS NOT NULL
            THEN
                l_error_in.set_all(i_lang,
                                   i_code,
                                   i_msg,
                                   g_error,
                                   'ALERT',
                                   'PK_DISPOSITION',
                                   'SET_MAIN_DISPOSITION',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END IF;
        
            RETURN end_exception(i_prof, i_transaction_id);
        
        END process_error_msg;
    
        FUNCTION process_error
        (
            i_prof           IN profissional,
            i_transaction_id IN VARCHAR2,
            i_code           IN VARCHAR2,
            i_msg            IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_code,
                                              i_msg,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_MAIN_DISPOSITION',
                                              o_error);
        
            RETURN end_exception(i_prof, i_transaction_id);
        END process_error;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_id_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_id_episode);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        r_epi.flg_migration := 'A';
        r_vis.flg_migration := 'A';
        pk_alertlog.log_debug('SET MAIN DISPOSITION: i_order_type' || i_order_type || ' i_prof_order:' || i_prof_order ||
                              'i_dt_order:' || i_dt_order || ' i_id_admitting_doctor:' || i_id_admitting_doctor,
                              ' i_id_written_by:' || i_id_written_by || ' i_id_compulsory_reason :' ||
                              i_id_compulsory_reason);
        l_dt_med := nvl(i_dt_med, i_dt_ama);
    
        g_error := 'GET CONFIGURATIONS i_id_compulsory_reason' || i_id_compulsory_reason;
        pk_alertlog.log_debug(g_error);
        l_end_episode_on_discharge := pk_sysconfig.get_config('END_EPISODE_ON_DISCHARGE', i_prof);
        l_admin_admission          := nvl(pk_sysconfig.get_config(g_admin_admission, i_prof), g_no);
        l_check_intake_time_cfg    := pk_sysconfig.get_config('USE_INTAKE_TIME_TO_CALCULATE_LOS', i_prof);
    
        l_auto_cancel_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T033');
    
        g_error := 'GET FLG_STATUS';
        IF NOT pk_discharge.get_disch_flg_status(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_flg_status   => NULL,
                                                 i_disch_status => nvl(i_discharge_status, l_disch_status_act),
                                                 o_flg_status   => l_flg_status,
                                                 o_disch_status => l_disch_status,
                                                 o_error        => o_error)
        THEN
            pk_alertlog.log_error('ERROR CALLING - PK_DISCHARGE.GET_DISCH_FLG_STATUS');
            RAISE l_exception;
        END IF;
    
        g_error        := 'GET DISCHARGE STATUS';
        l_disch_status := nvl(i_discharge_status, l_disch_status_act);
    
        g_error := 'GET CATEGORY';
        pk_alertlog.log_debug(g_error);
        IF NOT get_category(i_lang, i_prof, l_category, o_error)
        THEN
            RAISE l_err_set_misc_disposition;
        END IF;
    
        g_error := 'GET EPISODE AND VISIT DATA';
        pk_alertlog.log_debug(g_error);
        SELECT *
          INTO r_epi
          FROM episode
         WHERE id_episode = i_id_episode;
        SELECT *
          INTO r_vis
          FROM visit
         WHERE id_visit = r_epi.id_visit;
    
        IF l_check_intake_time_cfg = g_yes
        THEN
            BEGIN
                SELECT dt_intake_time
                  INTO l_dt_epis_begin
                  FROM (SELECT eit.dt_intake_time
                          FROM epis_intake_time eit
                         WHERE eit.id_episode = i_id_episode
                         ORDER BY eit.dt_register DESC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_epis_begin := r_epi.dt_begin_tstz;
            END;
        ELSE
            l_dt_epis_begin := r_epi.dt_begin_tstz;
        END IF;
    
        -- discharge date can't be prior to episode begin date    
        IF l_dt_med IS NOT NULL
           AND l_dt_epis_begin > pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL)
        THEN
            RAISE l_err_date_begin;
        END IF;
    
        g_error := 'GET DISCHARGE_REASON';
        pk_alertlog.log_debug(g_error);
        SELECT drd.id_discharge_reason
          INTO l_disch_reason
          FROM disch_reas_dest drd
         WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest;
    
        g_error := 'CALL GET_DISCH_FLASH_FILE';
        pk_alertlog.log_debug(g_error);
        l_disch_flash_files := pk_disposition.get_disch_flash_file(i_institution      => i_prof.institution,
                                                                   i_discharge_reason => l_disch_reason,
                                                                   i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof));
    
        IF i_disposition_flg_type IS NULL
        THEN
            BEGIN
                g_error := 'GET DISPOSITION FLG_TYPE';
                pk_alertlog.log_debug(g_error);
                SELECT dff.flg_type
                  INTO l_disposition_flg_type
                  FROM discharge_flash_files dff
                 WHERE dff.id_discharge_flash_files = l_disch_flash_files;
            EXCEPTION
                WHEN no_data_found THEN
                    l_disposition_flg_type := NULL;
            END;
        ELSE
            BEGIN
                SELECT dff.flg_type
                  INTO l_disposition_flg_type
                  FROM discharge_flash_files dff
                 WHERE dff.id_discharge_flash_files = l_disch_flash_files
                   AND dff.flg_type = i_disposition_flg_type;
            EXCEPTION
                WHEN no_data_found THEN
                    --This should never happens, it means that the input parameter i_disposition_flg_type don't match with the l_disch_flash_files
                    l_disposition_flg_type := NULL;
            END;
        END IF;
        -- José Brito 04/03/2009 ALERT-10317
        -- If patient refuses to be transfered, disposition is cancelled.        
        IF l_disposition_flg_type = g_disp_tran
           AND i_flg_patient_consent = 'R'
        THEN
        
            -- When refused, disposition is cancelled with FLG_CANCEL_TYPE = 'R' (Refusal).
            l_status_cancel   := g_disch_flg_cancel;
            l_disch_task_type := pk_alert_constant.g_task_discharge_transfer;
        
            g_error := 'SET TRANSFER DISPOSITION';
            pk_alertlog.log_debug(g_error);
            IF NOT set_transfer_disposition(i_lang                    => i_lang,
                                            i_prof                    => i_prof,
                                            i_id_episode              => i_id_episode,
                                            i_flg_status              => l_status_cancel, --> Refused transfer
                                            i_discharge_status        => l_disch_status,
                                            i_id_disch_reas_dest      => i_id_disch_reas_dest,
                                            i_id_discharge_hist       => i_id_discharge_hist,
                                            i_flg_pat_condition       => i_flg_pat_condition,
                                            i_reason_of_transfer      => i_reason_of_transfer,
                                            i_flg_transfer_transport  => i_flg_transfer_transport,
                                            i_dt_transfer_transport   => i_dt_transfer_transport,
                                            i_desc_transfer_transport => i_desc_transfer_transport,
                                            i_risk_of_transfer        => i_risk_of_transfer,
                                            i_benefits_of_transfer    => i_benefits_of_transfer,
                                            i_flg_med_reconcile       => i_flg_med_reconcile,
                                            i_prof_admitting_desc     => i_prof_admitting_desc,
                                            i_dt_prof_admiting        => i_dt_prof_admiting,
                                            i_en_route_orders         => i_en_route_orders,
                                            i_flg_patient_consent     => i_flg_patient_consent,
                                            i_acceptance_facility     => i_acceptance_facility,
                                            i_admitting_room          => i_admitting_room,
                                            i_room_assigned_by        => i_room_assigned_by,
                                            i_items_sent_with_patient => i_items_sent_with_patient,
                                            i_vs_taken                => i_vs_taken,
                                            i_intake_output_done      => i_intake_output_done,
                                            i_notes                   => i_notes,
                                            i_report_given_to         => i_report_given_to,
                                            i_dt_med                  => i_dt_med,
                                            i_reason_of_transfer_desc => i_reason_of_transfer_desc,
                                            i_flg_print_report        => i_flg_print_report,
                                            i_discharge_flash_files   => l_disch_flash_files,
                                            i_id_inst_transfer        => i_id_inst_transfer,
                                            o_dsc                     => r_dsc_h,
                                            o_dsd                     => r_dsd_h,
                                            o_error                   => o_error)
            THEN
                RAISE l_err_set_misc_disposition;
            END IF;
        
            IF i_id_cpt_code IS NOT NULL
            THEN
                r_dsc_h.id_cpt_code := i_id_cpt_code;
            END IF;
        
            g_error := 'SET REFUSED DISPOSITION';
            pk_alertlog.log_debug(g_error);
            IF NOT set_disposition_refused(i_lang,
                                           i_prof,
                                           i_id_episode,
                                           r_dsc_h,
                                           r_dsd_h,
                                           l_disposition_flg_type,
                                           g_sysdate_tstz,
                                           r_epi,
                                           r_vis,
                                           l_category,
                                           l_id_discharge,
                                           l_id_discharge_hist,
                                           l_id_discharge_detail_hist,
                                           o_error)
            THEN
                RAISE l_err_set_disposition;
            END IF;
        
            g_error := 'SET DISCHARGE NOTES REPORT';
            IF NOT pk_discharge.set_discharge_rep_notes(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_episode   => i_id_episode,
                                                        i_patient   => r_epi.id_patient,
                                                        i_discharge => l_id_discharge,
                                                        i_flg_type  => i_flg_letter,
                                                        i_flg_task  => i_flg_task,
                                                        o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            BEGIN
                -- redirect to the disposition summary screen
                g_error := 'GET SHORTCUT TO DISPOSITION SUMMARY';
                pk_alertlog.log_debug(g_error);
                o_shortcut := pk_disposition.get_discharge_shortcut(i_lang => i_lang, i_prof => i_prof);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE l_err_shortcut;
            END;
        
            RETURN TRUE;
        
        END IF;
    
        IF i_dt_proposed IS NOT NULL
        THEN
            l_flg_type_date := g_flg_type_date_day;
        ELSE
            l_flg_type_date := NULL;
        END IF;
    
        -- odete monteiro 14/11/2007 altas clinicas pendentes, actulizacao da epis_grid
        --l_grid_task.id_episode := i_id_episode;
    
        g_error := 'OPEN C_SHORT_IMAGE';
        pk_alertlog.log_debug(g_error);
        l_short_pend := pk_disposition.get_discharge_shortcut(i_lang => i_lang, i_prof => i_prof);
    
        -- AS 14-12-2009 (ALERT-62112)
        o_reports_pat := NULL;
        IF (i_flg_print_report = pk_alert_constant.g_yes)
        THEN
            o_reports_pat := pk_sysconfig.get_config(i_code_cf => 'PRINT_DISPOSITION_REPORT', i_prof => i_prof);
        END IF;
    
        IF l_flg_status = g_disch_flg_pend
        THEN
            g_error := 'UPDATE DISCHARGE_PEND GRID TASK';
            pk_alertlog.log_debug(g_error);
        
            pk_utils.build_status_string(i_display_type => pk_alert_constant.g_display_type_date,
                                         i_value_date   => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                              g_sysdate_tstz,
                                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                         i_shortcut     => l_short_pend,
                                         o_status_str   => l_status_str,
                                         o_status_msg   => l_dummy,
                                         o_status_icon  => l_dummy,
                                         o_status_flg   => l_dummy);
        
            l_status_string := REPLACE(l_status_str,
                                       pk_alert_constant.g_status_rpl_chr_dt_server,
                                       pk_date_utils.to_char_insttimezone(i_prof,
                                                                          g_sysdate_tstz,
                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)) || '|';
        
            IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_episode          => i_id_episode,
                                            discharge_pend_in  => l_status_string,
                                            discharge_pend_nin => FALSE,
                                            o_error            => o_error)
            
            THEN
                RAISE e_call_exception;
            END IF;
        
        ELSE
            g_error := 'GET REPORTS';
            -- José Brito 05/03/2009 ALERT-10137
            -- Return the ID report
            BEGIN
                SELECT d.id_reports
                  INTO o_reports
                  FROM disch_reas_dest d
                 WHERE d.id_disch_reas_dest = i_id_disch_reas_dest;
            EXCEPTION
                WHEN no_data_found THEN
                    o_reports := NULL;
            END;
        
            g_error := 'REMOVE DISCHARGE_PEND GRID TASK';
            pk_alertlog.log_debug(g_error);
        
            -- Remove from grid task
            IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_episode          => i_id_episode,
                                            discharge_pend_in  => NULL,
                                            discharge_pend_nin => FALSE,
                                            o_error            => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'REMOVE EPIS REGISTER DISCHARGE_PEND GRID TASK';
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => i_id_episode, o_error => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'SET BED STATUS VACANT';
            IF NOT pk_bmng_pbl.set_episode_bed_status_vacant(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_id_episode            => i_id_episode,
                                                             i_transaction_id        => l_transaction_id,
                                                             i_dt_discharge_schedule => nvl(l_dt_med,
                                                                                            pk_date_utils.date_send_tsz(i_lang,
                                                                                                                        current_timestamp,
                                                                                                                        i_prof)),
                                                             o_error                 => o_error)
            THEN
                RAISE l_err_set_misc_disposition;
            END IF;
        
            ---- in inp episodes with an associated activity therapy episode
            -- if there is loaned suplies when discharging the patient an alert is sent to the activity therapist.
            g_error := 'CALL pk_activity_therapist.set_discharge_phy';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_activity_therapist.set_discharge_phy(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_episode => i_id_episode,
                                                           o_error      => o_error)
            THEN
                RAISE l_err_set_misc_disposition;
            END IF;
        
            -- Turn off alerts for this episode
            IF NOT pk_alerts.delete_sys_alert_event_episode(i_lang, i_prof, i_id_episode, 'N', o_error)
            THEN
                RAISE l_err_set_misc_disposition;
            END IF;
        END IF;
    
        g_error      := 'CALL PK_PRINT_LIST_DB.GET_PRINT_LIST_JOBS';
        l_print_jobs := pk_print_list_db.get_print_list_jobs(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_patient         => r_epi.id_patient,
                                                             i_episode         => i_id_episode,
                                                             i_print_list_area => NULL);
    
        IF NOT pk_discharge.get_report_label(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_reas_dest    => i_id_disch_reas_dest,
                                             o_label        => l_label,
                                             o_print_config => l_print_config,
                                             o_error        => o_error)
        THEN
            RAISE l_err_set_misc_disposition;
        END IF;
    
        IF l_print_jobs.exists(1)
           OR (i_flg_print_report = pk_alert_constant.g_yes AND l_flg_status <> g_disch_flg_pend)
           OR (l_print_config = pk_discharge.g_sys_list_save_add_print_list AND o_reports IS NOT NULL)
        THEN
            o_shortcut := pk_print_list_db.g_print_list_id_shortcut_pat;
        ELSE
            IF pk_tools.get_prof_cat(i_prof) = pk_alert_constant.g_cat_type_doc
            THEN
                o_shortcut := nvl(pk_sysconfig.get_config('DISPOSITION_SHORTCUT', i_prof), 38);
            ELSE
                o_shortcut := nvl(pk_sysconfig.get_config('DISPOSITION_SHORTCUT_NURSE', i_prof), 38);
            END IF;
        END IF;
    
        IF l_disposition_flg_type = g_disp_adms
        THEN
        
            l_disch_task_type := pk_alert_constant.g_task_discharge_admission;
            g_error           := 'SET ADMISSION DISPOSITION';
            l_ret             := set_admission_disposition(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_episode          => i_id_episode,
                                                           i_flg_status          => l_flg_status,
                                                           i_discharge_status    => l_disch_status,
                                                           i_id_disch_reas_dest  => i_id_disch_reas_dest,
                                                           i_id_discharge_hist   => i_id_discharge_hist,
                                                           i_flg_pat_condition   => i_flg_pat_condition,
                                                           i_id_prof_admitting   => i_id_prof_admitting,
                                                           i_dt_med              => i_dt_med,
                                                           i_admission_orders    => i_admission_orders,
                                                           i_notes_med           => i_notes,
                                                           i_admit_to_room       => i_admit_to_room,
                                                           i_room_admit          => i_room_admit,
                                                           i_vs_taken            => i_vs_taken,
                                                           i_intake_output_done  => i_intake_output_done,
                                                           i_flg_check_valuables => i_flg_check_valuables,
                                                           -- José Brito 30/05/2008 Novos campos no ecrã
                                                           -- Profissional pode passar a ser indicado através de campo de texto livre
                                                           i_prof_admitting_desc => i_prof_admitting_desc,
                                                           i_flg_med_reconcile   => i_flg_med_reconcile,
                                                           i_flg_print_report    => i_flg_print_report,
                                                           --
                                                           i_id_dep_clin_serv_admit => i_id_dep_clin_serv_admit,
                                                           i_flg_surgery            => i_flg_surgery,
                                                           i_dt_surgery_str         => i_dt_surgery_str,
                                                           --
                                                           i_discharge_flash_files => l_disch_flash_files,
                                                           i_id_admitting_doctor   => i_id_admitting_doctor,
                                                           i_id_written_by         => i_id_written_by,
                                                           i_flg_compulsory        => i_flg_compulsory,
                                                           i_id_compulsory_reason  => i_id_compulsory_reason,
                                                           i_compulsory_reason     => i_compulsory_reason,
                                                           o_dsc                   => r_dsc_h,
                                                           o_dsd                   => r_dsd_h,
                                                           o_error                 => o_error);
        
        ELSIF l_disposition_flg_type IN (g_disp_home, g_disp_other)
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_home;
            g_error           := 'SET HOME DISPOSITION';
            l_ret             := set_home_disposition(i_lang                         => i_lang,
                                                      i_prof                         => i_prof,
                                                      i_id_episode                   => i_id_episode,
                                                      i_flg_status                   => l_flg_status,
                                                      i_discharge_status             => l_disch_status,
                                                      i_id_disch_reas_dest           => i_id_disch_reas_dest,
                                                      i_id_discharge_hist            => i_id_discharge_hist,
                                                      i_flg_pat_condition            => i_flg_pat_condition,
                                                      i_flg_med_reconcile            => i_flg_med_reconcile,
                                                      i_flg_prescription             => i_flg_prescription_given,
                                                      i_flg_written_notes            => i_flg_written_notes,
                                                      i_dt_med                       => i_dt_med,
                                                      i_flg_instructions_discussed   => i_flg_instructions_discussed,
                                                      i_instructions_discussed_notes => i_instructions_discussed_notes,
                                                      i_intructions_understood       => i_instructions_understood,
                                                      i_vs_taken                     => i_vs_taken,
                                                      i_intake_output_done           => i_intake_output_done,
                                                      i_flg_patient_transport        => i_flg_patient_transport,
                                                      i_flg_pat_escorted_by          => i_flg_pat_escorted_by,
                                                      i_desc_pat_escorted_by         => i_desc_pat_escorted_by,
                                                      i_notes                        => i_notes,
                                                      i_flg_print_report             => i_flg_print_report,
                                                      i_discharge_flash_files        => l_disch_flash_files,
                                                      o_dsc                          => r_dsc_h,
                                                      o_dsd                          => r_dsd_h,
                                                      o_error                        => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_foll
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_follow;
            g_error           := 'SET FOLLOW-UP DISPOSITION';
            l_ret             := set_followup_disposition(i_lang                         => i_lang,
                                                          i_prof                         => i_prof,
                                                          i_id_episode                   => i_id_episode,
                                                          i_flg_status                   => l_flg_status,
                                                          i_discharge_status             => l_disch_status,
                                                          i_id_disch_reas_dest           => i_id_disch_reas_dest,
                                                          i_id_discharge_hist            => i_id_discharge_hist,
                                                          i_flg_pat_condition            => i_flg_pat_condition,
                                                          i_flg_med_reconcile            => i_flg_med_reconcile,
                                                          i_flg_instructions_discussed   => i_flg_instructions_discussed,
                                                          i_instructions_discussed_notes => i_instructions_discussed_notes,
                                                          i_pat_instructions_provided    => i_pat_instructions_provided,
                                                          i_flg_prescription_given_to    => i_flg_prescription_given_to,
                                                          i_desc_prescription_given_to   => i_desc_prescription_given_to,
                                                          i_id_prof_assigned_to          => i_id_prof_assigned_to,
                                                          i_next_visit_scheduled         => i_next_visit_scheduled,
                                                          i_flg_instructions_next_visit  => i_flg_instructions_next_visit,
                                                          i_desc_instructions_next_visit => i_desc_instructions_next_visit,
                                                          i_id_dep_clin_serv_visit       => i_id_dep_clin_serv_visit,
                                                          i_id_complaint                 => i_id_complaint,
                                                          i_notes_registrar              => i_notes_registrar,
                                                          i_notes                        => i_notes,
                                                          i_flg_print_report             => i_flg_print_report,
                                                          i_discharge_flash_files        => l_disch_flash_files,
                                                          o_dsc                          => r_dsc_h,
                                                          o_dsd                          => r_dsd_h,
                                                          o_error                        => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_tran
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_transfer;
            g_error           := 'SET TRANSFER DISPOSITION';
            l_ret             := set_transfer_disposition(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_episode              => i_id_episode,
                                                          i_flg_status              => l_flg_status,
                                                          i_discharge_status        => l_disch_status,
                                                          i_id_disch_reas_dest      => i_id_disch_reas_dest,
                                                          i_id_discharge_hist       => i_id_discharge_hist,
                                                          i_flg_pat_condition       => i_flg_pat_condition,
                                                          i_reason_of_transfer      => i_reason_of_transfer,
                                                          i_flg_transfer_transport  => i_flg_transfer_transport,
                                                          i_dt_transfer_transport   => i_dt_transfer_transport,
                                                          i_desc_transfer_transport => i_desc_transfer_transport,
                                                          i_risk_of_transfer        => i_risk_of_transfer,
                                                          i_benefits_of_transfer    => i_benefits_of_transfer,
                                                          i_flg_med_reconcile       => i_flg_med_reconcile,
                                                          i_prof_admitting_desc     => i_prof_admitting_desc,
                                                          i_dt_prof_admiting        => i_dt_prof_admiting,
                                                          i_en_route_orders         => i_en_route_orders,
                                                          i_flg_patient_consent     => i_flg_patient_consent,
                                                          i_acceptance_facility     => i_acceptance_facility,
                                                          i_admitting_room          => i_admitting_room,
                                                          i_room_assigned_by        => i_room_assigned_by,
                                                          i_items_sent_with_patient => i_items_sent_with_patient,
                                                          i_vs_taken                => i_vs_taken,
                                                          i_intake_output_done      => i_intake_output_done,
                                                          i_notes                   => i_notes,
                                                          i_report_given_to         => i_report_given_to,
                                                          i_dt_med                  => i_dt_med,
                                                          i_reason_of_transfer_desc => i_reason_of_transfer_desc,
                                                          i_flg_print_report        => i_flg_print_report,
                                                          i_discharge_flash_files   => l_disch_flash_files,
                                                          i_id_inst_transfer        => i_id_inst_transfer,
                                                          o_dsc                     => r_dsc_h,
                                                          o_dsd                     => r_dsd_h,
                                                          o_error                   => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_expi
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_expired;
            g_error           := 'SET EXPIRED DISPOSITION';
            l_ret             := set_expired_disposition(i_lang                       => i_lang,
                                                         i_prof                       => i_prof,
                                                         i_id_episode                 => i_id_episode,
                                                         i_flg_status                 => l_flg_status,
                                                         i_discharge_status           => l_disch_status,
                                                         i_id_disch_reas_dest         => i_id_disch_reas_dest,
                                                         i_id_discharge_hist          => i_id_discharge_hist,
                                                         i_flg_pat_condition          => i_flg_pat_condition,
                                                         i_dt_death                   => i_dt_death,
                                                         i_prf_declared_death         => i_prf_declared_death,
                                                         i_autopsy_consent_desc       => i_autopsy_consent_desc,
                                                         i_flg_orgn_donation_agency   => i_flg_orgn_donation_agency,
                                                         i_flg_report_of_death        => i_flg_report_of_death,
                                                         i_flg_coroner_contacted      => i_flg_coroner_contacted,
                                                         i_coroner_name               => i_coroner_name,
                                                         i_flg_funeral_home_contacted => i_flg_funeral_home_contacted,
                                                         i_funeral_home_name          => i_funeral_home_name,
                                                         i_dt_body_removed            => i_dt_body_removed,
                                                         i_notes                      => i_notes,
                                                         i_flg_print_report           => i_flg_print_report,
                                                         i_discharge_flash_files      => l_disch_flash_files,
                                                         i_death_characterization     => i_death_characterization,
                                                         i_death_process_registration => i_death_process_registration,
                                                         i_dt_med                     => i_dt_med,
                                                         i_oper_treatment_detail      => i_oper_treatment_detail,
                                                         i_status_before_death        => i_status_before_death,
                                                         o_dsc                        => r_dsc_h,
                                                         o_dsd                        => r_dsd_h,
                                                         o_error                      => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_ama
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_ama;
            g_error           := 'SET AMA DISPOSITION';
            l_ret             := set_ama_disposition(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_id_episode            => i_id_episode,
                                                     i_flg_status            => l_flg_status,
                                                     i_discharge_status      => l_disch_status,
                                                     i_id_disch_reas_dest    => i_id_disch_reas_dest,
                                                     i_id_discharge_hist     => i_id_discharge_hist,
                                                     i_flg_pat_condition     => i_flg_pat_condition,
                                                     i_risk_of_leaving       => i_risk_of_leaving,
                                                     i_flg_risk_of_leaving   => i_flg_risk_of_leaving,
                                                     i_dt_ama                => i_dt_ama,
                                                     i_notes_med             => i_notes,
                                                     i_flg_signed_ama_form   => i_flg_signed_ama_form,
                                                     i_signed_ama_form       => i_signed_ama_form,
                                                     i_flg_pat_escorted_by   => i_flg_pat_escorted_by,
                                                     i_desc_pat_escorted_by  => i_desc_pat_escorted_by,
                                                     i_flg_patient_transport => i_flg_patient_transport,
                                                     i_reason_for_leaving    => i_reason_for_leaving,
                                                     i_flg_print_report      => i_flg_print_report,
                                                     i_discharge_flash_files => l_disch_flash_files,
                                                     o_dsc                   => r_dsc_h,
                                                     o_dsd                   => r_dsd_h,
                                                     o_error                 => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_mse
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_mse;
            g_error           := 'SET MSE DISPOSITION';
            l_ret             := set_mse_disposition(i_lang                         => i_lang,
                                                     i_prof                         => i_prof,
                                                     i_id_episode                   => i_id_episode,
                                                     i_flg_status                   => l_flg_status,
                                                     i_discharge_status             => l_disch_status,
                                                     i_id_disch_reas_dest           => i_id_disch_reas_dest,
                                                     i_id_discharge_hist            => i_id_discharge_hist,
                                                     i_flg_pat_condition            => i_flg_pat_condition,
                                                     i_mse_type                     => i_mse_type,
                                                     i_flg_med_reconcile            => i_flg_med_reconcile,
                                                     i_flg_prescription_given       => i_flg_prescription_given,
                                                     i_flg_written_notes            => i_flg_written_notes,
                                                     i_dt_med                       => i_dt_med,
                                                     i_flg_instructions_discussed   => i_flg_instructions_discussed,
                                                     i_instructions_discussed_notes => i_instructions_discussed_notes,
                                                     i_instructions_understood      => i_instructions_understood,
                                                     i_vs_taken                     => i_vs_taken,
                                                     i_intake_output_done           => i_intake_output_done,
                                                     i_flg_patient_transport        => i_flg_patient_transport,
                                                     i_flg_pat_escorted_by          => i_flg_pat_escorted_by,
                                                     i_desc_pat_escorted_by         => i_desc_pat_escorted_by,
                                                     i_notes_med                    => i_notes,
                                                     i_flg_print_report             => i_flg_print_report,
                                                     i_discharge_flash_files        => l_disch_flash_files,
                                                     o_dsc                          => r_dsc_h,
                                                     o_dsd                          => r_dsd_h,
                                                     o_error                        => o_error);
        
        ELSIF l_disposition_flg_type = g_disp_lwbs
        THEN
            l_disch_task_type := pk_alert_constant.g_task_discharge_lwbs;
            g_error           := 'SET LWBS DISPOSITION';
            l_ret             := set_lwbs_disposition(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_episode            => i_id_episode,
                                                      i_flg_status            => l_flg_status,
                                                      i_discharge_status      => l_disch_status,
                                                      i_id_disch_reas_dest    => i_id_disch_reas_dest,
                                                      i_id_discharge_hist     => i_id_discharge_hist,
                                                      i_flg_pat_condition     => i_flg_pat_condition,
                                                      i_reason_for_leaving    => i_reason_for_leaving,
                                                      i_flg_risk_of_leaving   => i_flg_risk_of_leaving,
                                                      i_flg_pat_escorted_by   => i_flg_pat_escorted_by,
                                                      i_desc_pat_escorted_by  => i_desc_pat_escorted_by,
                                                      i_notes_med             => i_notes,
                                                      i_dt_med                => i_dt_med,
                                                      i_discharge_flash_files => l_disch_flash_files,
                                                      i_flg_print_report      => i_flg_print_report,
                                                      o_dsc                   => r_dsc_h,
                                                      o_dsd                   => r_dsd_h,
                                                      o_error                 => o_error);
        
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE l_err_set_misc_disposition;
        END IF;
    
        IF i_id_cpt_code IS NOT NULL
        THEN
            r_dsc_h.id_cpt_code := i_id_cpt_code;
        END IF;
    
        IF i_id_schedule IS NOT NULL
        THEN
            r_dsd_h.id_schedule := i_id_schedule;
        END IF;
    
        g_error := 'SET DISPOSITION';
        IF NOT set_disposition(i_lang                     => i_lang,
                               i_prof                     => i_prof,
                               i_id_episode               => i_id_episode,
                               i_dsc_h                    => r_dsc_h,
                               i_dsd_h                    => r_dsd_h,
                               i_disposition_flg_type     => l_disposition_flg_type,
                               i_transaction_id           => l_transaction_id,
                               o_id_discharge             => l_id_discharge,
                               o_id_discharge_hist        => l_id_discharge_hist,
                               o_id_discharge_detail      => l_id_discharge_detail,
                               o_id_discharge_detail_hist => l_id_discharge_detail_hist,
                               i_sysdate_tstz             => g_sysdate_tstz,
                               o_flg_show                 => o_flg_show,
                               o_msg_title                => o_msg_title,
                               o_msg_text                 => o_msg_text,
                               o_button                   => o_button,
                               o_error                    => o_error)
        THEN
            RAISE l_err_set_disposition;
        END IF;
        --Nuno Neves 24/12/2010 (ALERT-151966) 
        g_error := 'CHECK REQUEST PRINT REPORT';
        IF NOT pk_api_discharge.check_request_print_report(i_lang,
                                                           i_id_episode,
                                                           l_id_discharge,
                                                           i_prof,
                                                           r_dsc_h.currency,
                                                           o_error)
        
        THEN
            pk_alertlog.log_error('ERROR CALLING - PK_API_DISCHARGE.CHECK_REQUEST_PRINT_REPORT');
            RAISE l_exception;
        END IF;
        --END (ALERT-151966)
    
        g_error := 'SET DISCHARGE NOTES REPORT';
        IF NOT pk_discharge.set_discharge_rep_notes(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_id_episode,
                                                    i_patient   => r_epi.id_patient,
                                                    i_discharge => l_id_discharge,
                                                    i_flg_type  => i_flg_letter,
                                                    i_flg_task  => i_flg_task,
                                                    o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- IF l_disposition_flg_type = g_disp_adms
        --          AND i_order_type IS NOT NULL
        -- THEN
        l_id_co_sign := set_discharge_co_sign(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_episode   => i_id_episode,
                                              i_id_discharge => l_id_discharge,
                                              i_id_task_type => l_disch_task_type,
                                              i_order_type   => i_order_type,
                                              i_prof_order   => i_prof_order,
                                              i_dt_order     => i_dt_order,
                                              i_id_co_sign   => r_dsd_h.id_co_sign);
    
        g_error := 'UPDATE DISCHARGE_DETAIL_HIST';
        UPDATE discharge_detail
           SET id_co_sign = l_id_co_sign
         WHERE id_discharge = l_id_discharge;
    
        g_error := 'UPDATE DISCHARGE_DETAIL_HIST';
        UPDATE discharge_detail_hist
           SET id_co_sign = l_id_co_sign
         WHERE id_discharge_detail_hist = l_id_discharge_detail_hist;
        --   END IF;
        IF l_disposition_flg_type = g_disp_foll
        THEN
        
            IF l_flg_status = g_active
               AND i_id_schedule IS NULL
            THEN
            
                l_id_consult_req := r_dsd_h.id_consult_req;
            
                g_error := 'CALL TO CHECK_DISP_SCHED';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_pp.check_disp_sched(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_consult_req => l_id_consult_req,
                                                       o_button         => l_button,
                                                       o_msg            => l_msg,
                                                       o_msg_title      => l_msg_title,
                                                       o_flg_show       => l_flg_show,
                                                       o_change         => l_change,
                                                       o_error          => o_error)
                THEN
                    RAISE l_err_set_misc_disposition;
                END IF;
            
                IF l_change = 0
                THEN
                    RAISE l_err_chk_schedule;
                END IF;
            
                g_error := 'CALL TO SET_DISP_CONS_REQ';
                IF NOT pk_schedule_pp.set_disp_cons_req(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_consult_req    => l_id_consult_req,
                                                        i_id_patient        => r_vis.id_patient,
                                                        i_id_dep_clin_serv  => i_id_dep_clin_serv_visit,
                                                        i_id_episode        => i_id_episode,
                                                        i_notes_admin       => i_notes_registrar,
                                                        i_id_prof_requested => i_id_prof_assigned_to,
                                                        i_reason_visit      => i_id_complaint,
                                                        i_flg_instructions  => i_flg_instructions_next_visit,
                                                        i_next_visit_in     => i_next_visit_scheduled,
                                                        i_dt_proposed       => i_dt_proposed,
                                                        i_flg_type_date     => l_flg_type_date,
                                                        o_id_consult_req    => l_id_consult_req,
                                                        o_button            => l_button,
                                                        o_msg               => l_msg,
                                                        o_msg_title         => l_msg_title,
                                                        o_flg_show          => l_flg_show,
                                                        o_error             => o_error)
                THEN
                    RAISE l_err_set_misc_disposition;
                END IF;
            
                g_error := 'UPDATE DISCHARGE_DETAIL_HIST';
                UPDATE discharge_detail_hist
                   SET id_consult_req = l_id_consult_req
                 WHERE id_discharge_detail_hist = l_id_discharge_detail_hist;
            
            END IF;
        
        END IF;
        -- 
    
        IF l_flg_status = g_active
        THEN
            IF NOT pk_patient_tracking.set_care_stage_disposition(i_lang, i_prof, i_id_episode, o_error)
            THEN
                RAISE l_err_set_misc_disposition;
            END IF;
        
            g_error := 'SET INPATIENT EPISODE';
        
            IF l_disposition_flg_type = g_disp_adms
            THEN
                IF NOT pk_discharge.set_inp_episode(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_patient              => r_vis.id_patient,
                                                    i_episode              => i_id_episode,
                                                    i_prof_cat_type        => l_category,
                                                    i_flg_status           => l_flg_status,
                                                    i_flg_new_epis         => NULL,
                                                    i_new_epis_type        => NULL,
                                                    i_id_prof_admitting    => i_id_prof_admitting,
                                                    i_dep_clin_serv        => NULL,
                                                    i_transaction_id       => l_transaction_id,
                                                    i_flg_compulsory       => i_flg_compulsory,
                                                    i_id_compulsory_reason => i_id_compulsory_reason,
                                                    i_compulsory_reason    => i_compulsory_reason,
                                                    o_can_refresh_mviews   => l_can_refresh_mviews,
                                                    o_id_episode           => o_id_episode,
                                                    o_error                => o_error)
                THEN
                
                    RAISE l_err_set_misc_disposition;
                
                END IF;
            
                IF o_id_episode = -1000
                THEN
                    RAISE l_epis_exist;
                END IF;
            
            END IF;
        
            IF i_id_discharge_hist IS NOT NULL
            THEN
                BEGIN
                    SELECT dh.id_prof_med
                      INTO l_prof_id
                      FROM discharge_hist dh
                     WHERE dh.id_discharge_hist = i_id_discharge_hist;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_prof_id := NULL;
                END;
            END IF;
        
            BEGIN
                g_error := 'GET auto_presc_cancel';
                SELECT drd.flg_auto_presc_cancel
                  INTO l_auto_presc_cancel
                  FROM disch_reas_dest drd
                 WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest
                
                ;
            EXCEPTION
                WHEN OTHERS THEN
                    l_auto_presc_cancel := pk_alert_constant.g_no;
            END;
        
            -- if configuration for cancel prescription
            --is active.
            IF (l_auto_presc_cancel = pk_alert_constant.g_yes /*AND nvl(i_flg_type, l_flg_type) = g_doctor*/
               )
            THEN
                g_error := 'CALL pk_medication_api.set_interrupt_medication';
                IF NOT pk_api_pfh_in.set_cancel_presc(i_lang       => i_lang,
                                                      i_prof       => profissional(nvl(l_prof_id, i_prof.id),
                                                                                   i_prof.institution,
                                                                                   i_prof.software),
                                                      i_id_episode => i_id_episode,
                                                      i_notes      => l_auto_cancel_msg,
                                                      o_error      => o_error)
                THEN
                    RAISE l_err_set_misc_disposition;
                END IF;
            END IF;
        
            g_error := 'OPEN c_discharge_report_cfg';
            OPEN c_discharge_report_cfg(l_id_discharge);
            FETCH c_discharge_report_cfg BULK COLLECT
                INTO l_table_disch_rep_cfg;
            CLOSE c_discharge_report_cfg;
        
            FOR i IN 1 .. l_table_disch_rep_cfg.count
            LOOP
                l_rec_disch_rep_cfg := l_table_disch_rep_cfg(i);
                IF (l_rec_disch_rep_cfg.flg_send = pk_alert_constant.g_yes OR
                   l_rec_disch_rep_cfg.flg_send_to_crm = pk_alert_constant.g_yes)
                   AND l_rec_disch_rep_cfg.id_report IS NOT NULL
                THEN
                    l_ret := pk_print_tool.request_gen_report(i_id_episode         => i_id_episode,
                                                              i_id_patient         => r_epi.id_patient,
                                                              i_id_institution     => i_prof.institution,
                                                              i_id_language        => i_lang,
                                                              i_id_report_type     => l_rec_disch_rep_cfg.id_report,
                                                              i_id_sections        => 'null',
                                                              i_id_professional    => i_prof.id,
                                                              i_id_software        => i_prof.software,
                                                              i_flag_report_origin => 'null');
                
                    g_error := 'ts_discharge_report.ins: id_discharge: ' || l_id_discharge || ', id_report: ' ||
                               l_rec_disch_rep_cfg.id_report;
                    ts_discharge_report.ins(id_discharge_in => l_id_discharge,
                                            id_report_in    => l_rec_disch_rep_cfg.id_report,
                                            flg_status_in   => pk_discharge_crm.g_flg_status_crm_req,
                                            rows_out        => l_disch_rep_rowids);
                END IF;
            END LOOP;
        
            IF l_end_episode_on_discharge = g_yes
            THEN
            
                IF l_disposition_flg_type = g_disp_adms
                   AND l_admin_admission = g_yes
                THEN
                
                    g_error := 'CALL TO SET_STATUS_EPISODE';
                    IF NOT set_status_episode(i_lang,
                                              i_prof,
                                              i_id_episode,
                                              g_pendente,
                                              pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                              l_transaction_id,
                                              o_error)
                    THEN
                        RAISE l_err_set_misc_disposition;
                    END IF;
                ELSE
                
                    l_dt_med := nvl(l_dt_med, pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof));
                
                    g_error := 'CALL TO SET_END_EPISODE';
                    IF NOT set_end_episode(i_lang,
                                           i_prof,
                                           i_id_episode,
                                           pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                           pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                           o_error)
                    THEN
                        RAISE l_err_set_misc_disposition;
                    END IF;
                
                    g_error := 'CALL TO SET_END_VISIT';
                    IF NOT set_end_visit(i_lang,
                                         i_prof,
                                         i_id_episode,
                                         pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                         pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                         o_error)
                    THEN
                        RAISE l_err_set_misc_disposition;
                    END IF;
                
                    g_error := 'DELETE EPIS WAITING ALERT';
                    IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                                           i_prof,
                                                           i_id_episode,
                                                           pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                                           pk_edis_triage.g_alert_waiting,
                                                           pk_edis_triage.g_type_rem,
                                                           o_error)
                    THEN
                        RAISE l_err_set_misc_disposition;
                    END IF;
                
                    g_error := 'CALL pk_activity_therapist.set_discharge_adm with id_episode: ' || i_id_episode;
                    IF NOT pk_activity_therapist.set_discharge_adm(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_episode => i_id_episode,
                                                                   o_error      => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END IF;
            ELSE
                g_error := 'CALL TO SET_STATUS_EPISODE';
                pk_alertlog.log_debug(g_error);
                IF NOT set_status_episode(i_lang,
                                          i_prof,
                                          i_id_episode,
                                          g_pendente,
                                          pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_med, NULL),
                                          l_transaction_id,
                                          o_error)
                THEN
                    RAISE l_err_set_misc_disposition;
                END IF;
            END IF;
        
        ELSIF l_flg_status = g_disch_flg_pend
        THEN
            -- José Brito 30/07/2009 ALERT-25306 Set automatic status of patient tracking after disposition
            g_error := 'SET DISPOSITION AUTOMATIC PATIENT TRACKING STATUS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_patient_tracking.set_auto_disposition_status(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_episode            => i_id_episode,
                                                                   i_id_disch_reas_dest => i_id_disch_reas_dest,
                                                                   o_error              => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            -- Pending discharge to inpatient may create a new episode
            g_error := 'SET INPATIENT EPISODE (2)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge.set_inp_episode(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_patient              => r_vis.id_patient,
                                                i_episode              => i_id_episode,
                                                i_prof_cat_type        => l_category,
                                                i_flg_status           => l_flg_status,
                                                i_flg_new_epis         => NULL,
                                                i_new_epis_type        => NULL,
                                                i_id_prof_admitting    => i_id_prof_admitting,
                                                i_dep_clin_serv        => NULL,
                                                i_transaction_id       => l_transaction_id,
                                                i_flg_compulsory       => i_flg_compulsory,
                                                i_id_compulsory_reason => i_id_compulsory_reason,
                                                i_compulsory_reason    => i_compulsory_reason,
                                                o_can_refresh_mviews   => l_can_refresh_mviews,
                                                o_id_episode           => o_id_episode,
                                                o_error                => o_error)
            THEN
            
                RAISE l_err_set_misc_disposition;
            
            END IF;
        
            IF o_id_episode = -1000
            THEN
                RAISE l_epis_exist;
            END IF;
        END IF;
    
        IF l_id_epis_type = pk_alert_constant.g_epis_type_outpatient
        THEN
        
            g_error := 'GET SCHEDULE ID';
            BEGIN
                SELECT DISTINCT v.id_schedule
                  INTO l_id_schedule
                  FROM epis_info v
                 WHERE v.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_schedule := NULL;
            END;
        
            g_error := 'UPDATE SCHEDULE_OUTP';
            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_schedule    => l_id_schedule,
                                                                       i_flg_state      => pk_discharge.g_adm,
                                                                       i_id_patient     => r_vis.id_patient,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error)
            THEN
            
                RAISE e_call_exception;
            END IF;
        END IF;
        -- POS PROCESSAMENTO
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => r_vis.id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_category,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        --pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL TO REMOVE ALL EXISTING PRINT JOBS IN THE PRINTING LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_discharge.cancel_disch_print_jobs(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_patient            => r_vis.id_patient,
                                                    i_episode            => i_id_episode,
                                                    o_id_print_list_jobs => l_id_print_list_jobs,
                                                    o_error              => o_error)
        THEN
            pk_alertlog.log_error('ERROR CALLING - PK_DISCHARGE.CANCEL_DISCH_PRINT_JOBS');
            RAISE l_cancel_print_jobs_excpt;
        END IF;
    
        set_api_commit(i_prof, i_transaction_id, l_transaction_id);
        o_id_discharge := l_id_discharge;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_epis_exist THEN
            l_bool := process_error(i_prof           => i_prof,
                                    i_transaction_id => l_transaction_id,
                                    i_code           => 'CHECK_INPATIENTS_M003',
                                    i_msg            => pk_message.get_message(i_lang, 'CHECK_INPATIENTS_M003'));
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        WHEN l_err_date_begin THEN
            l_bool := process_error_msg(i_prof           => i_prof,
                                        i_transaction_id => l_transaction_id,
                                        i_code           => 'DISCHARGE_M020',
                                        i_msg            => pk_message.get_message(i_lang, 'DISCHARGE_M020'));
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
        WHEN l_err_set_disposition THEN
            l_bool := process_error_msg(i_prof           => i_prof,
                                        i_transaction_id => l_transaction_id,
                                        i_code           => 'DISCHARGE_M004',
                                        i_msg            => o_msg_text);
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
        WHEN l_err_chk_schedule THEN
            l_bool := process_error_msg(i_prof           => i_prof,
                                        i_transaction_id => l_transaction_id,
                                        i_code           => SQLCODE,
                                        i_msg            => l_msg);
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
        WHEN l_err_set_misc_disposition THEN
        
            l_bool := process_error(i_prof           => i_prof,
                                    i_transaction_id => l_transaction_id,
                                    i_code           => SQLCODE,
                                    i_msg            => 'Ib');
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
        WHEN l_cancel_print_jobs_excpt THEN
        
            l_bool := end_exception(i_prof => i_prof, i_transaction_id => l_transaction_id);
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
        WHEN OTHERS THEN
            l_bool := process_error(i_prof           => i_prof,
                                    i_transaction_id => l_transaction_id,
                                    i_code           => SQLCODE,
                                    i_msg            => SQLERRM);
            set_api_rollback(i_prof, i_transaction_id, l_transaction_id);
            RETURN l_bool;
        
    END set_main_disposition;

    /*******************************************************************************************************************************************
    * Nome : GET_FOLLOWUP_DEFAULT_VALUES                                                                                                       *
    * Descrição: Returns the default values when accessing the Follow-up disposition button                                                    *
    *                                                                                                                                          *
    * @param I_LANG                   Language ID                                                                                              *
    * @param I_PROF                   Professional                                                                                             *
    * @param I_ID_EPISODE             Episode identification                                                                                   *
    * @param O_CUR                    The cursor with the default values                                                                       *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Eduardo Lourenço                                                                                         *
    * @version                        2.4.3                                                                                                    *
    * @since                          2008/04/30                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_followup_default_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_discharge_reason profile_disch_reason.id_profile_disch_reason%TYPE;
        l_id_disch_reas_dest  disch_reas_dest.id_disch_reas_dest%TYPE;
    BEGIN
    
        SELECT pdr.id_discharge_reason, drd.id_disch_reas_dest
          INTO l_id_discharge_reason, l_id_disch_reas_dest
          FROM profile_disch_reason  pdr,
               prof_profile_template ppt,
               profile_template      prt,
               discharge_flash_files dff,
               disch_reas_dest       drd
         WHERE ppt.id_professional = i_prof.id
           AND dff.id_discharge_flash_files = pdr.id_discharge_flash_files
           AND ppt.id_profile_template = prt.id_profile_template
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND pdr.id_profile_template = prt.id_profile_template
           AND pdr.id_institution IN (0, i_prof.institution)
           AND instr(pdr.flg_access, pk_prof_utils.get_category(i_lang, i_prof)) > 0
           AND pdr.flg_available = g_yes
           AND dff.flg_type = g_disp_foll
           AND drd.id_discharge_reason = pdr.id_discharge_reason
           AND drd.id_instit_param = i_prof.institution
           AND drd.id_software_param = i_prof.software
           AND drd.flg_active != g_disch_reas_dest_inactive
           AND rownum <= 1;
    
        OPEN o_cur FOR
            SELECT a.id_professional,
                   a.nickname,
                   b.id_dep_clin_serv,
                   b.desc_clin_serv,
                   b.id_complaint,
                   b.desc_complaint,
                   g_disp_foll flg_type,
                   l_id_discharge_reason id_discharge_reason,
                   l_id_disch_reas_dest id_disch_reas_dest,
                   pk_schedule.has_permission(i_lang, i_prof, NULL, g_sch_event_id_followup, a.id_professional) permission
              FROM (SELECT rownum AS a,
                           i_prof.id id_professional,
                           pk_prof_utils.get_nickname(i_lang, i_prof.id) nickname
                      FROM dual) a,
                   (SELECT rownum AS b,
                           nvl(dcs1.id_dep_clin_serv, dcs2.id_dep_clin_serv) id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                           c.id_complaint,
                           pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM episode e
                    --                     INNER JOIN visit v ON v.id_visit = e.id_visit
                     INNER JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      LEFT OUTER JOIN epis_complaint ec
                        ON ec.id_episode = e.id_episode
                      LEFT OUTER JOIN dep_clin_serv dcs1
                        ON (dcs1.id_dep_clin_serv = ei.id_first_dep_clin_serv)
                      LEFT OUTER JOIN dep_clin_serv dcs2
                        ON (dcs2.id_dep_clin_serv = ei.id_dcs_requested)
                      LEFT JOIN clinical_service cs
                        ON nvl(dcs1.id_clinical_service, dcs2.id_clinical_service) = cs.id_clinical_service
                      LEFT JOIN complaint c
                        ON ec.id_complaint = c.id_complaint
                     WHERE e.id_episode = i_id_episode
                       AND (ec.flg_status IS NULL OR ec.flg_status = g_active)) b
             WHERE a.a = b.b(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_FOLLOWUP_DEFAULT_VALUES',
                                              o_error);
            pk_types.open_my_cursor(o_cur);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_followup_default_values;

    /*******************************************************************************************************************************************
    * Nome : SET_SCHEDULE_AND_DISPOSITION                                                                                                      *
    * Descrição: Makes a schedule and integrates it with the Follow-up disposition                                                             *
    *                                                                                                                                          *
    * @param I_LANG                   Language ID                                                                                              *
    * @param I_PROF                   Professional                                                                                             *
    * @param I_ID_EPISODE             Episode identification                                                                                   *
    * @param O_CUR                    The cursor with the default values                                                                       *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Eduardo Lourenço                                                                                         *
    * @version                        2.4.3                                                                                                    *
    * @since                          2008/05/08                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION set_schedule_and_disposition
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        -- schedule
        i_id_patient             IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv       IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event           IN schedule.id_sch_event%TYPE,
        i_id_prof                IN sch_resource.id_professional%TYPE,
        i_dt_begin               IN VARCHAR2,
        i_dt_end                 IN VARCHAR2,
        i_flg_vacancy            IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes         IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator     IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred      IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason              IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin              IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room                IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_sch_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes           IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_sched_request_type IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via       IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap             IN VARCHAR2,
        i_id_consult_vac         IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option             IN VARCHAR2,
        -- disposition
        i_id_episode                   IN episode.id_episode%TYPE,
        i_flg_status                   IN discharge_hist.flg_status%TYPE,
        i_disposition_flg_type         IN discharge_flash_files.flg_type%TYPE,
        i_id_disch_reas_dest           IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist            IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition            IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE,
        i_notes                        IN discharge_hist.notes_med%TYPE,
        i_pat_instructions_provided    IN discharge_detail_hist.pat_instructions_provided%TYPE,
        i_flg_prescription_given_to    IN discharge_detail_hist.flg_prescription_given_to%TYPE,
        i_desc_prescription_given_to   IN discharge_detail_hist.desc_prescription_given_to%TYPE,
        i_id_prof_assigned_to          IN discharge_detail_hist.id_prof_assigned_to%TYPE,
        i_next_visit_scheduled         IN discharge_detail_hist.next_visit_scheduled%TYPE,
        i_flg_instructions_next_visit  IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_desc_instructions_next_visit IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_id_dep_clin_serv_visit       IN discharge_detail_hist.id_dep_clin_serv_visit%TYPE,
        i_id_complaint                 IN discharge_detail_hist.id_complaint%TYPE,
        i_notes_registrar              IN discharge_detail_hist.notes%TYPE,
        i_id_cpt_code                  IN discharge.id_cpt_code%TYPE DEFAULT NULL,
        i_order_type                   IN co_sign.id_order_type%TYPE DEFAULT NULL,
        i_prof_order                   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_dt_order                     IN VARCHAR2 DEFAULT NULL,
        o_flg_show                     OUT VARCHAR2,
        o_flg_proceed                  OUT VARCHAR2,
        o_msg_title                    OUT VARCHAR2,
        o_msg_text                     OUT VARCHAR2,
        o_button                       OUT VARCHAR2,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_schedule    schedule.id_schedule%TYPE;
        l_shortcut       sys_shortcut.id_sys_shortcut%TYPE;
        l_id_reports     reports.id_reports%TYPE;
        l_id_reports_pat reports.id_reports%TYPE;
        l_id_episode     episode.id_episode%TYPE;
        l_id_discharge   discharge.id_discharge%TYPE;
        l_id_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
    
        l_flg_status   discharge.flg_status%TYPE;
        l_disch_status discharge_status.id_discharge_status%TYPE;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        l_ret BOOLEAN;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF NOT pk_schedule_outp.create_schedule(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_patient         => table_number(i_id_patient),
                                                i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                                i_id_sch_event       => i_id_sch_event,
                                                i_id_prof            => i_id_prof,
                                                i_dt_begin           => i_dt_begin,
                                                i_dt_end             => i_dt_end,
                                                i_flg_vacancy        => i_flg_vacancy,
                                                i_schedule_notes     => i_schedule_notes,
                                                i_id_lang_translator => i_id_lang_translator,
                                                i_id_lang_preferred  => i_id_lang_preferred,
                                                i_id_reason          => i_id_reason,
                                                i_id_origin          => i_id_origin,
                                                i_id_room            => i_id_room,
                                                i_id_schedule_ref    => i_id_schedule_ref,
                                                i_id_episode         => i_id_sch_episode,
                                                i_reason_notes       => i_reason_notes,
                                                i_flg_request_type   => i_flg_sched_request_type,
                                                i_flg_schedule_via   => i_flg_schedule_via,
                                                i_do_overlap         => i_do_overlap,
                                                i_id_consult_vac     => i_id_consult_vac,
                                                i_sch_option         => i_sch_option,
                                                o_id_schedule        => l_id_schedule,
                                                o_flg_proceed        => o_flg_proceed,
                                                o_flg_show           => o_flg_show,
                                                o_msg_title          => o_msg_title,
                                                o_msg                => o_msg_text,
                                                o_button             => o_button,
                                                o_error              => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'GET FLG_STATUS';
        IF NOT pk_discharge.get_disch_flg_status(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_flg_status   => i_flg_status,
                                                 i_disch_status => NULL,
                                                 o_flg_status   => l_flg_status,
                                                 o_disch_status => l_disch_status,
                                                 o_error        => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        IF NOT set_main_disposition(i_lang                         => i_lang,
                                    i_prof                         => i_prof,
                                    i_id_episode                   => i_id_episode,
                                    i_discharge_status             => l_disch_status,
                                    i_disposition_flg_type         => i_disposition_flg_type,
                                    i_id_disch_reas_dest           => i_id_disch_reas_dest,
                                    i_id_discharge_hist            => i_id_discharge_hist,
                                    i_flg_pat_condition            => i_flg_pat_condition,
                                    i_flg_med_reconcile            => i_flg_med_reconcile,
                                    i_instructions_discussed_notes => i_instructions_discussed_notes,
                                    i_notes                        => i_notes,
                                    i_pat_instructions_provided    => i_pat_instructions_provided,
                                    i_flg_prescription_given_to    => i_flg_prescription_given_to,
                                    i_desc_prescription_given_to   => i_desc_prescription_given_to,
                                    i_id_prof_assigned_to          => i_id_prof_assigned_to,
                                    i_next_visit_scheduled         => i_next_visit_scheduled,
                                    i_flg_instructions_next_visit  => i_flg_instructions_next_visit,
                                    i_desc_instructions_next_visit => i_desc_instructions_next_visit,
                                    i_id_dep_clin_serv_visit       => i_id_dep_clin_serv_visit,
                                    i_id_complaint                 => i_id_complaint,
                                    i_notes_registrar              => i_notes_registrar,
                                    i_id_cpt_code                  => i_id_cpt_code,
                                    i_id_schedule                  => l_id_schedule,
                                    -- José Brito 30/05/2008 Este campo não é necessário no Private Practice
                                    i_report_given_to         => NULL,
                                    i_reason_of_transfer_desc => NULL,
                                    i_transaction_id          => l_transaction_id,
                                    i_id_inst_transfer        => NULL,
                                    i_order_type              => i_order_type,
                                    i_prof_order              => i_prof_order,
                                    i_dt_order                => i_dt_order,
                                    --
                                    o_shortcut     => l_shortcut,
                                    o_reports      => l_id_reports,
                                    o_reports_pat  => l_id_reports_pat,
                                    o_flg_show     => o_flg_show,
                                    o_msg_title    => o_msg_title,
                                    o_msg_text     => o_msg_text,
                                    o_button       => o_button,
                                    o_id_episode   => l_id_episode,
                                    o_id_discharge => l_id_discharge,
                                    o_error        => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'SET_SCHEDULE_AND_DISPOSITION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_schedule_and_disposition;

    /**********************************************************************************************
    * Retorna os motivo da consulta 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_id_dep_clin_serv    ID 
    * @param i_patient             ID of patient
    * @param i_episode             ID of episode
    *
    * @param o_type                Type of returned information ( S - Sample of of area QUEIXA, 
    *                              C - Data form table COMPLAINT
    * @param o_sql                 Cursor with the reason for visit
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/23
    **********************************************************************************************/
    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_type             OUT VARCHAR2,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sys_reason_codification VARCHAR2(1);
        l_exception EXCEPTION;
        l_gender      patient.gender%TYPE;
        l_age         NUMBER(3);
        l_id_dcs      table_number;
        l_id_schedule epis_info.id_schedule%TYPE;
        l_reason      VARCHAR2(4000);
    
        l_cat      prof_cat.id_category%TYPE;
        l_cat_type category.flg_type%TYPE;
    
        CURSOR c_cat IS
            SELECT pc.id_category, c.flg_type
              FROM prof_cat pc, category c
             WHERE id_professional = i_prof.id
               AND id_institution = i_prof.institution
               AND pc.id_category = c.id_category;
    BEGIN
        g_error := 'GET CONFIG REASON_FOR_VISIT_CODIFICATION';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat, l_cat_type;
        CLOSE c_cat;
    
        IF l_cat_type = g_doctor
        THEN
            l_sys_reason_codification := pk_sysconfig.get_config('VISIT_REASON_DOCTOR_CODIFICATION', i_prof);
        ELSIF l_cat_type = g_nurse
        THEN
            l_sys_reason_codification := pk_sysconfig.get_config('VISIT_REASON_NURSE_ORIGIN', i_prof);
        END IF;
    
        IF l_sys_reason_codification IN (g_no, g_reason_origin_sample_text)
        THEN
            BEGIN
                g_error := 'GET PATIENT AGE AND GENDER';
                -- Get patient age and gender
                SELECT gender, months_between(current_timestamp, dt_birth) / 12 age
                  INTO l_gender, l_age
                  FROM patient
                 WHERE id_patient = i_patient;
            EXCEPTION
                WHEN no_data_found THEN
                    l_age    := NULL;
                    l_gender := NULL;
            END;
            g_error := 'OPEN C_CAT';
        
            SELECT id_schedule
              INTO l_id_schedule
              FROM epis_info
             WHERE id_episode = i_episode;
        
            g_error  := 'GET PK_CLINICAL_INFO.GET_EPIS_REASON_FOR_VISIT';
            l_reason := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                    i_prof        => i_prof,
                                                                                                    i_id_episode  => i_episode,
                                                                                                    i_id_schedule => l_id_schedule),
                                                         4000);
            g_error  := 'CREATE TABLE DCS';
    --        l_id_dcs := pk_schedule.get_list_number_csv(i_id_dep_clin_serv);
        
            g_error := 'CALL PK_SAMPLE_TEXT.GET_SAMPLE_TEXT_EPIS';
        
            OPEN o_sql FOR
                SELECT title, text, flg_default
                  FROM (SELECT l_reason title, l_reason text, g_yes flg_default
                          FROM dual
                         WHERE l_reason IS NOT NULL
                        UNION
                        SELECT DISTINCT pk_translation.get_translation(i_lang, st.code_desc_sample_text) title,
                                        pk_translation.get_translation(i_lang, st.code_desc_sample_text) text,
                                        decode(pk_translation.get_translation(i_lang, st.code_desc_sample_text),
                                               l_reason,
                                               g_yes,
                                               g_no) flg_default
                          FROM sample_text_type     stt,
                               sample_text_type_cat sttc,
                               sample_text          st,
                               sample_text_soft_inst     stsi
                         WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
                           AND stt.id_software = i_prof.software
                           AND stsi.id_sample_text_type = stt.id_sample_text_type
                           AND st.flg_available = g_available
                           AND stt.flg_available = g_available
                           AND sttc.id_sample_text_type = stt.id_sample_text_type
                           AND sttc.id_category = l_cat
                           AND sttc.id_institution IN (0, i_prof.institution)
                           AND stsi.id_institution = i_prof.institution
                           AND stsi.id_software = i_prof.software
                           AND pk_translation.get_translation(i_lang, st.code_desc_sample_text) IS NOT NULL
                           AND ((l_gender IS NOT NULL AND nvl(st.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                                l_gender = 'I')
                           AND (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND nvl(st.age_max, nvl(l_age, 0)) OR
                                nvl(l_age, 0) = 0)
                        UNION
                        SELECT DISTINCT pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof) title,
                                        pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof) text,
                                        decode(pk_string_utils.clob_to_sqlvarchar2(desc_sample_text_prof),
                                               l_reason,
                                               g_yes,
                                               g_no) flg_default
                          FROM sample_text_type stt, sample_text_type_cat sttc, sample_text_prof stf
                         WHERE upper(stt.intern_name_sample_text_type) = upper(g_complaint_sample_text_type)
                           AND stf.id_software = i_prof.software
                           AND sttc.id_sample_text_type = stt.id_sample_text_type
                           AND sttc.id_category = l_cat
                           AND sttc.id_institution IN (0, i_prof.institution)
                           AND stf.id_sample_text_type = stt.id_sample_text_type
                           AND stf.id_professional = i_prof.id
                           AND stf.id_institution = i_prof.institution)
                 ORDER BY title, text;
        
            --                   IF NOT pk_sample_text.get_sample_text_epis(i_lang             => i_lang,
            --                                                     i_sample_text_type => 'QUEIXA',
            --                                                     i_patient          => i_patient,
            --                                                    i_episode          => i_episode,
            --                                                     i_prof             => i_prof,
            --                                                    o_sample_text      => o_sql,
            --                                                     o_error            => o_error)
            --          THEN
            --              RAISE l_exception;
            --          END IF;
            o_type := 'S';
        
        ELSE
            g_error := 'CALL GET_REASON_OF_VISIT';
            IF NOT get_reason_of_visit(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_dep_clin_serv => i_id_dep_clin_serv,
                                       o_sql              => o_sql,
                                       o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
            o_type := 'C';
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_REASON_OF_VISIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        
    END get_reason_of_visit;

    /**********************************************************************************************
    * Return the configured flash file id for the given parameters
    *
    * @param i_institution         Institution
    * @param i_discharge_reason    Discharge reason ID
    * @param i_profile_template    Profile template ID 
    *
    * @return                      Discharge flash file ID
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.2
    * @since                       2012/09/24
    **********************************************************************************************/
    FUNCTION get_disch_flash_file
    (
        i_institution      IN institution.id_institution%TYPE,
        i_discharge_reason IN discharge_reason.id_discharge_reason%TYPE,
        i_profile_template IN discharge_hist.id_profile_template%TYPE
    ) RETURN discharge_flash_files.id_discharge_flash_files%TYPE IS
        l_ret discharge_flash_files.id_discharge_flash_files%TYPE := NULL;
    BEGIN
        SELECT a.id_discharge_flash_files
          INTO l_ret
          FROM (SELECT pdr.id_discharge_flash_files,
                       row_number() over(ORDER BY pdr.flg_available DESC, --
                       decode(pdr.id_institution, i_institution, 1, 2), --
                       pdr.rank) line_number
                  FROM profile_disch_reason pdr
                 WHERE pdr.id_discharge_reason = i_discharge_reason
                   AND pdr.id_institution IN (i_institution, pk_alert_constant.g_inst_all)
                   AND pdr.id_profile_template = i_profile_template) a
         WHERE a.line_number = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_disch_flash_file;

    /**********************************************************************************************
    * Gets discharge status (ALERT-280978)
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_episode             ID of episode
    *
    * @param o_discharge_status    Discharge status
    *                              1 - ROUTINE DISCHARGE HOME
    *                              2 - LEFT AGAINST MEDICAL ADVICE
    *                              3 - TRANSFERRED TO OTHER HOSPITAL
    *                              4 - DIED WITHIN 48 HOURS
    *                              5 - DIED AFTER 48 HOURS
    *                              6 - OTHER
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       2014/05/06
    **********************************************************************************************/
    FUNCTION get_discharge_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_discharge_status OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_DISCHARGE_STATUS';
        --
        l_home            CONSTANT NUMBER(1) := 1;
        l_left_ama        CONSTANT NUMBER(1) := 2;
        l_tranferred      CONSTANT NUMBER(1) := 3;
        l_died_within_48h CONSTANT NUMBER(1) := 4;
        l_died_after_48h  CONSTANT NUMBER(1) := 5;
        l_other           CONSTANT NUMBER(1) := 6;
    BEGIN
        g_error := 'GET DISCHARGE_STATUS';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        BEGIN
            SELECT decode(a.flg_type,
                          pk_disposition.g_disp_home,
                          l_home,
                          pk_disposition.g_disp_ama,
                          l_left_ama,
                          pk_disposition.g_disp_tran,
                          l_tranferred,
                          pk_disposition.g_disp_expi,
                          decode(a.flg_disch_less_48h, pk_alert_constant.g_yes, l_died_within_48h, l_died_after_48h),
                          l_other) discharge_status
              INTO o_discharge_status
              FROM (SELECT CASE
                                WHEN pk_date_utils.diff_timestamp(dh.dt_created_hist, epis.dt_begin_tstz) <= 2 THEN
                                 pk_alert_constant.g_yes
                                ELSE
                                 pk_alert_constant.g_no
                            END flg_disch_less_48h,
                           nvl(dff.flg_type,
                               decode(dr.file_to_execute,
                                      'DispositionCreateStep2Admit.swf', --Admited - Inpatient
                                      pk_disposition.g_disp_adms,
                                      'DispositionCreateStep2Transfer.swf', --Transfer to other facilitie
                                      pk_disposition.g_disp_tran,
                                      'DispositionCreateStep2Expire.swf', --Patient expired
                                      pk_disposition.g_disp_expi,
                                      'DispositionCreateStep2AMA.swf', --Against Medical Advice
                                      pk_disposition.g_disp_ama,
                                      'DispositionCreateStep2LWBS.swf', --Left without being seen
                                      pk_disposition.g_disp_lwbs,
                                      'DispositionCreateStep2Mse.swf', --Medical screening evaluation
                                      pk_disposition.g_disp_mse)) flg_type,
                           row_number() over(ORDER BY dh.dt_created_hist DESC) rn
                      FROM discharge_hist dh
                      JOIN episode epis
                        ON epis.id_episode = dh.id_episode
                      JOIN discharge_detail_hist ddh
                        ON ddh.id_discharge_hist = dh.id_discharge_hist
                      JOIN disch_reas_dest drd
                        ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
                      JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                      LEFT JOIN discharge_flash_files dff
                        ON dff.id_discharge_flash_files = dh.id_discharge_flash_files
                     WHERE dh.id_episode = i_episode
                       AND dh.flg_status IN (pk_disposition.g_disch_act, pk_disposition.g_disch_flg_pend)) a
             WHERE a.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_discharge_status := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_status;

    /**********************************************************************************************
    * Returns death event characterization data
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @param o_death_evet          Content cursor
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sergio Dias
    * @version                     2.6.3.15
    * @since                       Apr-3-2014
    **********************************************************************************************/
    FUNCTION get_death_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_death_event OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DEATH_EVENT';
    BEGIN
        g_error := 'OPEN O_DEATH_EVENT';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_death_event FOR
            SELECT t.id_death_event, t.desc_death_event, t.code_death_event, t.rank
              FROM (SELECT id_concept_term id_death_event,
                           pk_translation.get_translation(i_lang      => decode(id_language, 0, i_lang, id_language),
                                                          i_code_mess => code_death_event) desc_death_event,
                           concept_code code_death_event,
                           rank
                      FROM (SELECT DISTINCT d.id_concept_term,
                                            d.id_concept_version,
                                            d.code_death_event,
                                            d.id_language,
                                            d.concept_code,
                                            d.flg_other,
                                            d.flg_icd9,
                                            d.rank
                              FROM diagnosis_ea d
                             WHERE d.concept_type_int_name = pk_diagnosis_form.g_death_event
                               AND d.id_institution = i_prof.institution
                               AND d.id_software = i_prof.software
                               AND d.code_death_event IS NOT NULL)) t
             ORDER BY t.rank, t.desc_death_event;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_death_event);
            RETURN FALSE;
    END get_death_event;
    -- ###########################################################    
    /**********************************************************************************************
    * Returns discharge shortcut
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @return                      Discharge shortcut
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       Dec-15-2014
    **********************************************************************************************/
    FUNCTION get_discharge_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_shortcut.id_sys_shortcut%TYPE IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_DISCHARGE_SHORTCUT';
        --
        l_cfg_medical_discharge CONSTANT sys_shortcut.intern_name%TYPE := 'MEDICAL_DISCHARGE';
        --
        l_ret sys_shortcut.id_sys_shortcut%TYPE;
    BEGIN
        g_error := 'OPEN O_DEATH_EVENT';
        pk_alertlog.log_debug(g_error);
        SELECT t.id_sys_shortcut
          INTO l_ret
          FROM (SELECT ss.id_sys_shortcut,
                       row_number() over(ORDER BY decode(ss.id_sys_button_prop, NULL, 1, 2) ASC) row_number
                  FROM sys_shortcut ss
                 WHERE ss.intern_name = l_cfg_medical_discharge
                   AND ss.id_software = i_prof.software
                   AND ss.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                 ORDER BY ss.id_institution DESC) t
         WHERE t.row_number = 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_discharge_shortcut;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    * @param i_episode             ID of episode
    * @param i_pat_pregnancy       ID of pat_pregnancy
    * @param i_flg_condition       Flag of newborn condition
    *
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION set_newborn_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge     IN discharge.id_discharge%TYPE,
        i_episode       IN table_number,
        i_pat_pregnancy IN table_number,
        i_flg_condition IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_NEWBORN_DISCHARGE';
    
        l_cnt_rows    NUMBER;
        l_cnt_preg    NUMBER;
        l_is_creation NUMBER;
    
        l_rowids               table_varchar;
        l_discharge_newborn_tc ts_discharge_newborn.discharge_newborn_tc;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        BEGIN
            l_cnt_preg := i_pat_pregnancy.count;
        
            g_error := 'GET DISCHARGE_NEWBORN TOTAL ROWS';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(1)
              INTO l_cnt_rows
              FROM discharge_newborn dn
             WHERE dn.id_discharge = i_discharge;
        EXCEPTION
            WHEN no_data_found THEN
                l_cnt_rows := 0;
        END;
    
        IF l_cnt_rows > 0
        THEN
            l_is_creation := 0;
        
            --If there is more
            IF l_cnt_rows <> l_cnt_preg
            THEN
                l_rowids := table_varchar();
                ts_discharge_newborn.del_dnb_disch_fk(id_discharge_in => i_discharge,
                                                      handle_error_in => TRUE,
                                                      rows_out        => l_rowids);
                l_is_creation := 1;
            END IF;
        
        ELSE
            l_is_creation := 1;
        END IF;
    
        g_error := 'GET L_DISCHARGE_NEWBORN_TC';
        pk_alertlog.log_debug(g_error);
        SELECT i_discharge id_discharge,
               preg.column_value id_pat_pregnancy,
               epis.column_value id_episode,
               nvl(cond.column_value, g_newborn_condition_u) flg_condition,
               pk_alert_constant.g_active flg_status,
               decode(l_is_creation, 1, i_prof.id, NULL) id_prof_create,
               decode(l_is_creation, 1, g_sysdate_tstz, NULL) dt_create,
               decode(l_is_creation, 1, NULL, i_prof.id) id_prof_last_update,
               decode(l_is_creation, 1, NULL, g_sysdate_tstz) dt_last_update,
               NULL id_prof_cancel,
               NULL dt_cancel,
               NULL create_user,
               NULL create_time,
               NULL create_institution,
               NULL update_user,
               NULL update_time,
               NULL update_institution
          BULK COLLECT
          INTO l_discharge_newborn_tc
          FROM (SELECT rownum rn, column_value /*+opt_estimate (table t rows=1)*/
                  FROM TABLE(i_episode)) epis,
               (SELECT rownum rn, column_value /*+opt_estimate (table t rows=1)*/
                  FROM TABLE(i_pat_pregnancy)) preg,
               (SELECT rownum rn, column_value /*+opt_estimate (table t rows=1)*/
                  FROM TABLE(i_flg_condition)) cond
         WHERE epis.rn = preg.rn
           AND cond.rn = preg.rn;
    
        l_rowids := table_varchar();
        IF l_is_creation = 1
        THEN
            g_error := 'INSERT DISCHARGE_NEWBORN ROW';
            pk_alertlog.log_debug(g_error);
            ts_discharge_newborn.ins(rows_in => l_discharge_newborn_tc, handle_error_in => TRUE, rows_out => l_rowids);
        ELSE
            --TODO: set history...
            g_error := 'UPDATE DISCHARGE_NEWBORN ROW';
            pk_alertlog.log_debug(g_error);
            ts_discharge_newborn.upd(col_in            => l_discharge_newborn_tc,
                                     ignore_if_null_in => TRUE,
                                     handle_error_in   => TRUE,
                                     rows_out          => l_rowids);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_newborn_discharge;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    *
    * @param o_
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION cancel_newborn_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_NEWBORN_DISCHARGE';
    
        l_exist_nb_disch       VARCHAR2(1 CHAR);
        l_rowids               table_varchar;
        l_discharge_newborn_tc ts_discharge_newborn.discharge_newborn_tc;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_exist_nb_disch
          FROM discharge_newborn dn
         WHERE dn.id_discharge = i_discharge
           AND dn.flg_status <> pk_alert_constant.g_cancelled;
    
        IF l_exist_nb_disch = pk_alert_constant.g_yes
        THEN
            g_error := 'GET L_DISCHARGE_NEWBORN_TC';
            pk_alertlog.log_debug(g_error);
            SELECT dn.id_discharge,
                   dn.id_pat_pregnancy,
                   dn.id_episode,
                   NULL,
                   pk_alert_constant.g_cancelled,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   i_prof.id,
                   g_sysdate_tstz,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL
              BULK COLLECT
              INTO l_discharge_newborn_tc
              FROM discharge_newborn dn
             WHERE dn.id_discharge = i_discharge;
        
            --TODO: set history...
            g_error := 'CANCEL DISCHARGE_NEWBORN';
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_discharge_newborn.upd(col_in            => l_discharge_newborn_tc,
                                     ignore_if_null_in => TRUE,
                                     handle_error_in   => TRUE,
                                     rows_out          => l_rowids);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_newborn_discharge;

    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_category       category.flg_type%TYPE;
        l_count          NUMBER;
        l_id_institution institution.id_institution%TYPE;
        l_ret            BOOLEAN;
    
        err_set_misc_disposition EXCEPTION;
        l_adm_separate VARCHAR2(2 CHAR) := pk_sysconfig.get_config('DISCHARGE_ADMISSION_SEPARATE', i_prof);
        l_flg_type     VARCHAR2(1 CHAR);
    BEGIN
    
        l_ret := get_category(i_lang, i_prof, l_category, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_set_misc_disposition;
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM profile_disch_reason
         WHERE id_institution = i_prof.institution;
    
        l_id_institution := i_prof.institution;
        IF l_count = 0
        THEN
            l_id_institution := 0;
        END IF;
        IF i_flg_type IS NOT NULL
           AND l_adm_separate = pk_alert_constant.g_yes
        THEN
            l_flg_type := i_flg_type;
        END IF;
        g_error := 'RETURN RESULTS';
        OPEN o_list FOR
            SELECT DISTINCT pdr.id_discharge_reason id_discharge_reason,
                            dff.file_name file_to_execute,
                            pk_translation.get_translation(i_lang, code_discharge_reason) desc_reason,
                            dsr.flg_admin_medic flg_admin_medic,
                            dff.flg_type disposition_flg_type,
                            pdr.flg_default flg_default,
                            nvl(pdr.rank, dsr.rank) rank
              FROM profile_disch_reason  pdr,
                   discharge_reason      dsr,
                   prof_profile_template ppt,
                   profile_template      prt,
                   discharge_flash_files dff,
                   disch_reas_dest       drd
             WHERE ppt.id_professional = i_prof.id
               AND dff.id_discharge_flash_files = pdr.id_discharge_flash_files
               AND ppt.id_profile_template = prt.id_profile_template
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pdr.id_profile_template = prt.id_profile_template
               AND pdr.id_discharge_reason = dsr.id_discharge_reason
               AND pdr.id_institution = l_id_institution
               AND instr(pdr.flg_access, l_category) > 0
               AND pdr.flg_available = g_yes
               AND dsr.flg_available = pk_alert_constant.g_yes
               AND drd.id_discharge_reason = dsr.id_discharge_reason
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = pk_alert_constant.g_active
               AND dff.flg_type = nvl(l_flg_type, dff.flg_type)
               AND ((dff.flg_type <> g_disp_adms AND l_adm_separate = pk_alert_constant.g_yes AND l_flg_type IS NULL) OR
                   (l_adm_separate = pk_alert_constant.g_no) OR
                   (l_adm_separate = pk_alert_constant.g_yes AND l_flg_type = g_disp_adms))
             ORDER BY nvl(pdr.rank, dsr.rank), desc_reason;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_set_misc_disposition THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'misc',
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCHARGE_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              'GET_DISCHARGE_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_reason_list;

    FUNCTION check_dsc_reason_selected
    (
        i_episode        IN NUMBER,
        i_id_hhc_episode IN NUMBER,
        i_flg_hhc_disch  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR) := g_no;
    BEGIN
    
        IF i_flg_hhc_disch = g_yes
        THEN
        
            IF i_episode = i_id_hhc_episode
            THEN
                l_return := g_yes;
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END check_dsc_reason_selected;

    --***********************************************************************
    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_category       category.flg_type%TYPE;
        l_count          NUMBER;
        l_id_institution institution.id_institution%TYPE;
        l_ret            BOOLEAN;
    
        l_id_patient     NUMBER;
        l_id_hhc_episode NUMBER;
        l_id_hhc_req     NUMBER;
    
        err_set_misc_disposition EXCEPTION;
        l_adm_separate VARCHAR2(2 CHAR) := pk_sysconfig.get_config('DISCHARGE_ADMISSION_SEPARATE', i_prof);
        l_flg_type     VARCHAR2(1 CHAR);
    
        FUNCTION get_id_patient(i_episode IN NUMBER) RETURN NUMBER IS
            tbl_pat  table_number;
            l_return NUMBER;
        BEGIN
        
            SELECT v.id_patient
              BULK COLLECT
              INTO tbl_pat
              FROM episode e
              JOIN visit v
                ON e.id_visit = v.id_visit
             WHERE e.id_episode = i_episode;
        
            IF tbl_pat.count > 0
            THEN
                l_return := tbl_pat(1);
            ELSE
                RAISE no_data_found;
            END IF;
        
            RETURN l_return;
        
        END get_id_patient;
    
        --****************************************
        PROCEDURE process_error
        (
            i_code IN NUMBER,
            i_errm IN VARCHAR2,
            i_func IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_code,
                                              i_errm,
                                              g_error,
                                              'ALERT',
                                              'PK_DISPOSITION',
                                              i_func,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
        
        END process_error;
    
    BEGIN
    
        l_ret := get_category(i_lang, i_prof, l_category, o_error);
        IF l_ret = FALSE
        THEN
            RAISE err_set_misc_disposition;
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM profile_disch_reason
         WHERE id_institution = i_prof.institution;
    
        l_id_institution := i_prof.institution;
        IF l_count = 0
        THEN
            l_id_institution := 0;
        END IF;
        IF i_flg_type IS NOT NULL
           AND l_adm_separate = pk_alert_constant.g_yes
        THEN
            l_flg_type := i_flg_type;
        END IF;
    
        l_id_patient := get_id_patient(i_episode);
    
        l_id_hhc_req := pk_hhc_core.get_id_epis_hhc_req_by_pat(i_id_patient => l_id_patient);
        IF l_id_hhc_req IS NOT NULL
        THEN
            l_id_hhc_episode := pk_hhc_core.get_id_episode_by_hhc_req(i_id_epis_hhc_req => l_id_hhc_req);
        END IF;
    
        g_error := 'RETURN RESULTS';
        OPEN o_list FOR
            SELECT DISTINCT pdr.id_discharge_reason id_discharge_reason,
                            dff.file_name file_to_execute,
                            pk_translation.get_translation(i_lang, code_discharge_reason) desc_reason,
                            dsr.flg_admin_medic flg_admin_medic,
                            dff.flg_type disposition_flg_type,
                            pdr.flg_default flg_default,
                            nvl(pdr.rank, dsr.rank) rank,
                            pk_disposition.check_dsc_reason_selected(i_episode, l_id_hhc_episode, dsr.flg_hhc_disch) flg_hhc_selected
              FROM profile_disch_reason pdr
              JOIN discharge_reason dsr
                ON dsr.id_discharge_reason = pdr.id_discharge_reason
              JOIN profile_template prt
                ON prt.id_profile_template = pdr.id_profile_template
              JOIN prof_profile_template ppt
                ON ppt.id_profile_template = prt.id_profile_template
              JOIN discharge_flash_files dff
                ON dff.id_discharge_flash_files = pdr.id_discharge_flash_files
              JOIN disch_reas_dest drd
                ON drd.id_discharge_reason = dsr.id_discharge_reason
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND pdr.id_institution = l_id_institution
               AND instr(pdr.flg_access, l_category) > 0
               AND pdr.flg_available = g_yes
               AND dsr.flg_available = g_yes
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = pk_alert_constant.g_active
               AND dff.flg_type = nvl(l_flg_type, dff.flg_type)
               AND ((dff.flg_type <> g_disp_adms AND l_adm_separate = g_yes AND l_flg_type IS NULL) OR
                   (l_adm_separate = g_no) OR (l_adm_separate = g_yes AND l_flg_type = g_disp_adms))
             ORDER BY nvl(pdr.rank, dsr.rank), desc_reason;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_set_misc_disposition THEN
            process_error(SQLCODE, 'misc', 'GET_DISCHARGE_REASON_LIST 01');
            RETURN FALSE;
        WHEN OTHERS THEN
            process_error(SQLCODE, SQLERRM, 'GET_DISCHARGE_REASON_LIST 02');
            RETURN FALSE;
    END get_discharge_reason_list;

-- ###########################################################    
-- ##################################################################################
-- GLOBALS
-- ##################################################################################
BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_disposition;
/
