/*-- Last Change Revision: $Rev: 2026974 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:36 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_discharge_core IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    g_disch_active_status VARCHAR2(1 CHAR) := 'A';
    g_disch_pend_status   VARCHAR2(1 CHAR) := 'P';
    g_disch_canc_status   VARCHAR2(1 CHAR) := 'C';
    g_disch_repoen_status VARCHAR2(1 CHAR) := 'R';

    /*
    * Build discharge history record.
    *
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    *
    * @returns                discharge_hist record
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION row_discharge_hist
    (
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE
    ) RETURN discharge_hist%ROWTYPE IS
        l_disch_hist discharge_hist%ROWTYPE;
    BEGIN
        SELECT seq_discharge_hist.nextval id_discharge_hist,
               d.id_discharge,
               d.id_disch_reas_dest,
               d.id_episode,
               d.id_prof_cancel,
               d.notes_cancel,
               d.id_prof_med,
               d.notes_med,
               d.id_prof_admin,
               d.notes_admin,
               d.flg_status,
               d.flg_type,
               d.id_transp_ent_adm,
               d.id_transp_ent_med,
               d.notes_justify,
               d.price,
               d.currency,
               d.flg_payment,
               d.id_prof_pend_active,
               d.dt_med_tstz,
               d.dt_admin_tstz,
               d.dt_cancel_tstz,
               d.dt_pend_active_tstz,
               d.dt_pend_tstz,
               d.id_cpt_code,
               d.flg_cancel_type,
               d.id_discharge_status,
               d.flg_status_adm,
               pk_alert_constant.g_active flg_status_hist,
               pk_prof_utils.get_prof_profile_template(i_prof) id_profile_template,
               i_prof.id id_prof_created_hist,
               current_timestamp dt_created_hist,
               id_concept_term,
               id_cncpt_trm_inst_owner,
               id_terminology_version
          INTO l_disch_hist.id_discharge_hist,
               l_disch_hist.id_discharge,
               l_disch_hist.id_disch_reas_dest,
               l_disch_hist.id_episode,
               l_disch_hist.id_prof_cancel,
               l_disch_hist.notes_cancel,
               l_disch_hist.id_prof_med,
               l_disch_hist.notes_med,
               l_disch_hist.id_prof_admin,
               l_disch_hist.notes_admin,
               l_disch_hist.flg_status,
               l_disch_hist.flg_type,
               l_disch_hist.id_transp_ent_adm,
               l_disch_hist.id_transp_ent_med,
               l_disch_hist.notes_justify,
               l_disch_hist.price,
               l_disch_hist.currency,
               l_disch_hist.flg_payment,
               l_disch_hist.id_prof_pend_active,
               l_disch_hist.dt_med_tstz,
               l_disch_hist.dt_admin_tstz,
               l_disch_hist.dt_cancel_tstz,
               l_disch_hist.dt_pend_active_tstz,
               l_disch_hist.dt_pend_tstz,
               l_disch_hist.id_cpt_code,
               l_disch_hist.flg_cancel_type,
               l_disch_hist.id_discharge_status,
               l_disch_hist.flg_status_adm,
               l_disch_hist.flg_status_hist,
               l_disch_hist.id_profile_template,
               l_disch_hist.id_prof_created_hist,
               l_disch_hist.dt_created_hist,
               l_disch_hist.id_concept_term,
               l_disch_hist.id_cncpt_trm_inst_owner,
               l_disch_hist.id_terminology_version
          FROM discharge d
         WHERE d.id_discharge = i_discharge;
    
        RETURN l_disch_hist;
    END row_discharge_hist;

    /*
    * Build discharge detail history record.
    *
    * @param i_prof           logged professional structure
    * @param i_disch_detail   discharge detail identifier
    * @param i_disch_hist     discharge history identifier
    *
    * @returns                discharge_detail_hist record
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION row_discharge_detail_hist
    (
        i_prof         IN profissional,
        i_disch_detail IN discharge_detail.id_discharge_detail%TYPE,
        i_disch_hist   IN discharge_hist.id_discharge_hist%TYPE
    ) RETURN discharge_detail_hist%ROWTYPE IS
        l_disch_detail discharge_detail_hist%ROWTYPE;
    BEGIN
        SELECT seq_discharge_detail_hist.nextval id_discharge_detail_hist,
               dd.id_discharge_detail,
               i_disch_hist                      id_discharge_hist,
               dd.id_discharge,
               dd.flg_pat_condition,
               dd.id_transport_type,
               dd.id_disch_rea_transp_ent_inst,
               dd.flg_caretaker,
               dd.caretaker_notes,
               dd.flg_follow_up_by,
               dd.follow_up_notes,
               dd.flg_written_notes,
               dd.flg_voluntary,
               dd.flg_pat_report,
               dd.flg_transfer_form,
               dd.id_prof_admitting,
               dd.id_dep_clin_serv_admiting,
               dd.flg_summary_report,
               dd.flg_autopsy_consent,
               dd.autopsy_consent_desc,
               dd.flg_orgn_dntn_info,
               dd.orgn_dntn_info,
               dd.flg_examiner_notified,
               dd.examiner_notified_info,
               dd.flg_orgn_dntn_form_complete,
               dd.flg_ama_form_complete,
               dd.flg_lwbs_form_complete,
               dd.notes,
               dd.prof_admitting_desc,
               dd.dep_clin_serv_admiting_desc,
               dd.mse_type,
               dd.flg_surgery,
               dd.follow_up_date_tstz,
               dd.date_surgery_tstz,
               dd.flg_print_report,
               dd.followup_count,
               dd.total_time_spent,
               dd.id_unit_measure,
               i_prof.id                         id_prof_created_hist,
               current_timestamp                 dt_created_hist,
               dd.flg_autopsy,
               dd.dt_fw_visit,
               dd.id_dep_clin_serv_fw,
               dd.id_prof_fw,
               dd.sched_notes,
               dd.id_consult_req_fw,
               dd.id_complaint_fw,
               dd.reason_for_visit_fw,
               dd.death_process_registration,
               dd.flg_type_closure
          INTO l_disch_detail.id_discharge_detail_hist,
               l_disch_detail.id_discharge_detail,
               l_disch_detail.id_discharge_hist,
               l_disch_detail.id_discharge,
               l_disch_detail.flg_pat_condition,
               l_disch_detail.id_transport_type,
               l_disch_detail.id_disch_rea_transp_ent_inst,
               l_disch_detail.flg_caretaker,
               l_disch_detail.caretaker_notes,
               l_disch_detail.flg_follow_up_by,
               l_disch_detail.follow_up_notes,
               l_disch_detail.flg_written_notes,
               l_disch_detail.flg_voluntary,
               l_disch_detail.flg_pat_report,
               l_disch_detail.flg_transfer_form,
               l_disch_detail.id_prof_admitting,
               l_disch_detail.id_dep_clin_serv_admiting,
               l_disch_detail.flg_summary_report,
               l_disch_detail.flg_autopsy_consent,
               l_disch_detail.autopsy_consent_desc,
               l_disch_detail.flg_orgn_dntn_info,
               l_disch_detail.orgn_dntn_info,
               l_disch_detail.flg_examiner_notified,
               l_disch_detail.examiner_notified_info,
               l_disch_detail.flg_orgn_dntn_form_complete,
               l_disch_detail.flg_ama_form_complete,
               l_disch_detail.flg_lwbs_form_complete,
               l_disch_detail.notes,
               l_disch_detail.prof_admitting_desc,
               l_disch_detail.dep_clin_serv_admiting_desc,
               l_disch_detail.mse_type,
               l_disch_detail.flg_surgery,
               l_disch_detail.follow_up_date_tstz,
               l_disch_detail.date_surgery_tstz,
               l_disch_detail.flg_print_report,
               l_disch_detail.followup_count,
               l_disch_detail.total_time_spent,
               l_disch_detail.id_unit_measure,
               l_disch_detail.id_prof_created_hist,
               l_disch_detail.dt_created_hist,
               l_disch_detail.flg_autopsy,
               l_disch_detail.dt_fw_visit,
               l_disch_detail.id_dep_clin_serv_fw,
               l_disch_detail.id_prof_fw,
               l_disch_detail.sched_notes,
               l_disch_detail.id_consult_req_fw,
               l_disch_detail.id_complaint_fw,
               l_disch_detail.reason_for_visit_fw,
               l_disch_detail.death_process_registration,
               l_disch_detail.flg_type_closure
          FROM discharge_detail dd
         WHERE dd.id_discharge_detail = i_disch_detail;
    
        RETURN l_disch_detail;
    END row_discharge_detail_hist;

    /*
    * Outdate a discharge's history records.
    *
    * @param i_discharge      discharge identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE set_discharge_hist_outd(i_discharge IN discharge.id_discharge%TYPE) IS
    BEGIN
        g_error := 'UPDATE discharge_hist';
        UPDATE discharge_hist dh
           SET dh.flg_status_hist = pk_alert_constant.g_outdated
         WHERE dh.id_discharge = i_discharge
           AND (dh.flg_status_hist IS NULL OR dh.flg_status_hist != pk_alert_constant.g_outdated);
    END set_discharge_hist_outd;

    /*
    * Set discharge history.
    *
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_outd_prev      outdate previous history record: Y - yes, N - No
    * @param o_disch_hist     created discharge_hist identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/09
    */
    PROCEDURE set_discharge_hist
    (
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        i_outd_prev  IN VARCHAR2 DEFAULT 'Y',
        o_disch_hist OUT discharge_hist.id_discharge_hist%TYPE
    ) IS
        l_disch_hist discharge_hist%ROWTYPE;
    BEGIN
        -- build history record
        g_error      := 'CALL row_discharge_hist';
        l_disch_hist := row_discharge_hist(i_prof => i_prof, i_discharge => i_discharge);
    
        -- when setting a new discharge history record, outdate previous ones
        IF i_outd_prev = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL set_discharge_hist_outd';
            set_discharge_hist_outd(i_discharge => i_discharge);
        END IF;
    
        g_error := 'INSERT INTO discharge_hist';
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
             id_discharge_status,
             flg_status_adm,
             id_concept_term,
             id_cncpt_trm_inst_owner,
             id_terminology_version)
        VALUES
            (l_disch_hist.id_discharge_hist,
             l_disch_hist.id_discharge,
             l_disch_hist.id_disch_reas_dest,
             l_disch_hist.id_episode,
             l_disch_hist.id_prof_cancel,
             l_disch_hist.notes_cancel,
             l_disch_hist.id_prof_med,
             l_disch_hist.notes_med,
             l_disch_hist.id_prof_admin,
             l_disch_hist.notes_admin,
             l_disch_hist.flg_status,
             l_disch_hist.flg_type,
             l_disch_hist.id_transp_ent_adm,
             l_disch_hist.id_transp_ent_med,
             l_disch_hist.notes_justify,
             l_disch_hist.price,
             l_disch_hist.currency,
             l_disch_hist.flg_payment,
             l_disch_hist.id_prof_pend_active,
             l_disch_hist.dt_med_tstz,
             l_disch_hist.dt_admin_tstz,
             l_disch_hist.dt_cancel_tstz,
             l_disch_hist.dt_pend_active_tstz,
             l_disch_hist.flg_status_hist,
             nvl(l_disch_hist.id_profile_template, 0),
             l_disch_hist.id_prof_created_hist,
             l_disch_hist.dt_created_hist,
             l_disch_hist.dt_pend_tstz,
             l_disch_hist.id_cpt_code,
             l_disch_hist.flg_cancel_type,
             l_disch_hist.id_discharge_status,
             l_disch_hist.flg_status_adm,
             l_disch_hist.id_concept_term,
             l_disch_hist.id_cncpt_trm_inst_owner,
             l_disch_hist.id_terminology_version)
        RETURNING id_discharge_hist INTO o_disch_hist;
    END set_discharge_hist;

    /*
    * Set discharge detail history.
    *
    * @param i_prof           logged professional structure
    * @param i_disch_detail   discharge detail identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE set_discharge_detail_hist
    (
        i_prof           IN profissional,
        i_disch_detail   IN discharge_detail.id_discharge_detail%TYPE,
        i_disch_hist     IN discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE
    ) IS
        l_disch_det_hist discharge_detail_hist%ROWTYPE;
    BEGIN
        -- build history record
        g_error          := 'CALL row_discharge_detail_hist';
        l_disch_det_hist := row_discharge_detail_hist(i_prof         => i_prof,
                                                      i_disch_detail => i_disch_detail,
                                                      i_disch_hist   => i_disch_hist);
    
        g_error := 'INSERT INTO discharge_hist';
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
             flg_risk_of_leaving,
             dt_ama_tstz,
             flg_surgery,
             flg_prescription_given,
             follow_up_date_tstz,
             date_surgery_tstz,
             id_prof_created_hist,
             dt_created_hist,
             reason_for_leaving,
             flg_prescription_given_to,
             desc_prescription_given_to,
             desc_patient_transport,
             flg_instructions_next_visit,
             desc_instructions_next_visit,
             id_dep_clin_serv_visit,
             id_complaint,
             next_visit_scheduled,
             id_consult_req,
             id_schedule,
             report_given_to,
             reason_of_transfer_desc,
             flg_print_report,
             followup_count,
             total_time_spent,
             id_unit_measure,
             flg_autopsy,
             dt_fw_visit,
             id_dep_clin_serv_fw,
             id_prof_fw,
             sched_notes,
             id_consult_req_fw,
             id_complaint_fw,
             reason_for_visit_fw,
             death_process_registration,
             flg_type_closure)
        VALUES
            (l_disch_det_hist.id_discharge_detail_hist,
             l_disch_det_hist.id_discharge_hist,
             l_disch_det_hist.id_discharge,
             l_disch_det_hist.id_discharge_detail,
             l_disch_det_hist.flg_pat_condition,
             l_disch_det_hist.id_transport_type,
             l_disch_det_hist.id_disch_rea_transp_ent_inst,
             l_disch_det_hist.flg_caretaker,
             l_disch_det_hist.caretaker_notes,
             l_disch_det_hist.flg_follow_up_by,
             l_disch_det_hist.follow_up_notes,
             l_disch_det_hist.flg_written_notes,
             l_disch_det_hist.flg_voluntary,
             l_disch_det_hist.flg_pat_report,
             l_disch_det_hist.flg_transfer_form,
             l_disch_det_hist.id_prof_admitting,
             l_disch_det_hist.id_dep_clin_serv_admiting,
             l_disch_det_hist.flg_summary_report,
             l_disch_det_hist.flg_autopsy_consent,
             l_disch_det_hist.autopsy_consent_desc,
             l_disch_det_hist.flg_orgn_dntn_info,
             l_disch_det_hist.orgn_dntn_info,
             l_disch_det_hist.flg_examiner_notified,
             l_disch_det_hist.examiner_notified_info,
             l_disch_det_hist.flg_orgn_dntn_form_complete,
             l_disch_det_hist.flg_ama_form_complete,
             l_disch_det_hist.flg_lwbs_form_complete,
             l_disch_det_hist.notes,
             l_disch_det_hist.prof_admitting_desc,
             l_disch_det_hist.dt_prof_admiting_tstz,
             l_disch_det_hist.dep_clin_serv_admiting_desc,
             l_disch_det_hist.mse_type,
             l_disch_det_hist.flg_med_reconcile,
             l_disch_det_hist.flg_instructions_discussed,
             l_disch_det_hist.instructions_discussed_notes,
             l_disch_det_hist.instructions_understood,
             l_disch_det_hist.pat_instructions_provided,
             l_disch_det_hist.flg_record_release,
             l_disch_det_hist.desc_record_release,
             l_disch_det_hist.id_prof_assigned_to,
             l_disch_det_hist.vs_taken,
             l_disch_det_hist.intake_output_done,
             l_disch_det_hist.admit_to_room,
             l_disch_det_hist.flg_patient_consent,
             l_disch_det_hist.acceptance_facility,
             l_disch_det_hist.admitting_room,
             l_disch_det_hist.room_assigned_by,
             l_disch_det_hist.flg_items_sent_with_patient,
             l_disch_det_hist.items_sent_with_patient,
             l_disch_det_hist.procedure_text,
             l_disch_det_hist.flg_check_valuables,
             l_disch_det_hist.flg_patient_transport,
             l_disch_det_hist.flg_pat_escorted_by,
             l_disch_det_hist.desc_pat_escorted_by,
             l_disch_det_hist.admission_orders,
             l_disch_det_hist.reason_of_transfer,
             l_disch_det_hist.flg_transfer_transport,
             l_disch_det_hist.desc_transfer_transport,
             l_disch_det_hist.dt_transfer_transport_tstz,
             l_disch_det_hist.risk_of_transfer,
             l_disch_det_hist.benefits_of_transfer,
             l_disch_det_hist.en_route_orders,
             l_disch_det_hist.dt_death_tstz,
             l_disch_det_hist.prf_declared_death,
             l_disch_det_hist.flg_orgn_donation_agency,
             l_disch_det_hist.flg_report_of_death,
             l_disch_det_hist.flg_coroner_contacted,
             l_disch_det_hist.coroner_name,
             l_disch_det_hist.flg_funeral_home_contacted,
             l_disch_det_hist.dt_body_removed_tstz,
             l_disch_det_hist.flg_signed_ama_form,
             l_disch_det_hist.desc_signed_ama_form,
             l_disch_det_hist.funeral_home_name,
             l_disch_det_hist.risk_of_leaving,
             l_disch_det_hist.reason_for_visit,
             l_disch_det_hist.flg_risk_of_leaving,
             l_disch_det_hist.dt_ama_tstz,
             l_disch_det_hist.flg_surgery,
             l_disch_det_hist.flg_prescription_given,
             l_disch_det_hist.follow_up_date_tstz,
             l_disch_det_hist.date_surgery_tstz,
             l_disch_det_hist.id_prof_created_hist,
             l_disch_det_hist.dt_created_hist,
             l_disch_det_hist.reason_for_leaving,
             l_disch_det_hist.flg_prescription_given_to,
             l_disch_det_hist.desc_prescription_given_to,
             l_disch_det_hist.desc_patient_transport,
             l_disch_det_hist.flg_instructions_next_visit,
             l_disch_det_hist.desc_instructions_next_visit,
             l_disch_det_hist.id_dep_clin_serv_visit,
             l_disch_det_hist.id_complaint,
             l_disch_det_hist.next_visit_scheduled,
             l_disch_det_hist.id_consult_req,
             l_disch_det_hist.id_schedule,
             l_disch_det_hist.report_given_to,
             l_disch_det_hist.reason_of_transfer_desc,
             l_disch_det_hist.flg_print_report,
             l_disch_det_hist.followup_count,
             l_disch_det_hist.total_time_spent,
             l_disch_det_hist.id_unit_measure,
             l_disch_det_hist.flg_autopsy,
             l_disch_det_hist.dt_fw_visit,
             l_disch_det_hist.id_dep_clin_serv_fw,
             l_disch_det_hist.id_prof_fw,
             l_disch_det_hist.sched_notes,
             l_disch_det_hist.id_consult_req_fw,
             l_disch_det_hist.id_complaint_fw,
             l_disch_det_hist.reason_for_visit_fw,
             l_disch_det_hist.death_process_registration,
             l_disch_det_hist.flg_type_closure)
        RETURNING id_discharge_detail_hist INTO o_disch_det_hist;
    END set_discharge_detail_hist;

    /**********************************************************************************************
    * Gets the discharge type: PT - PT discharge
    *                          US - US discharge (also used in NL and UK)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param o_flg_market             discharge type
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION get_flg_market
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_flg_market OUT discharge.flg_market%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_FLG_MARKET';
    
    BEGIN
    
        g_error := 'GET FLG_MARKET';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT d.flg_market
          INTO o_flg_market
          FROM discharge d
         WHERE d.id_discharge = i_discharge;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_flg_market;

    /**********************************************************************************************
    * Gets the discharge status
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param o_flg_status             discharge status
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/01/13
    **********************************************************************************************/
    FUNCTION get_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_flg_status OUT discharge.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_FLG_STATUS';
    
    BEGIN
    
        g_error := 'GET FLG_STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT d.flg_status
          INTO o_flg_status
          FROM discharge d
         WHERE d.id_discharge = i_discharge;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_flg_status;

    /**********************************************************************************************
    * Gets the administrative discharge date (only when the administrative discharge is active)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param i_flg_status_adm         administrative discharge status
    * @param i_dt_admin               administrative discharge date
    *
    * @return                         administrative discharge date
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION get_dt_admin
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_flg_status_adm IN discharge.flg_status_adm%TYPE DEFAULT NULL,
        i_dt_admin       IN discharge.dt_admin_tstz%TYPE DEFAULT NULL
    ) RETURN discharge.dt_admin_tstz%TYPE IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DT_ADMIN';
    
        l_flg_status_adm discharge.flg_status_adm%TYPE;
        l_dt_admin       discharge.dt_admin_tstz%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET FLG_STATUS AND DT_ADMIN';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_discharge IS NOT NULL
        THEN
            SELECT d.flg_status_adm, d.dt_admin_tstz
              INTO l_flg_status_adm, l_dt_admin
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
        ELSE
            l_flg_status_adm := i_flg_status_adm;
            l_dt_admin       := i_dt_admin;
        END IF;
    
        g_error := 'GET DT_ADMIN';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF nvl(l_flg_status_adm, pk_alert_constant.g_inactive) <> pk_alert_constant.g_active
        THEN
            l_dt_admin := NULL;
        END IF;
    
        RETURN l_dt_admin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_dt_admin;

    /**********************************************************************************************
    * Checks if the episode already have administrative discharge
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param i_flg_status_adm         administrative discharge status
    *
    * @return                         Has administrative discharge: Y - Yes, N - No
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION check_admin_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_flg_status_adm IN discharge.flg_status_adm%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_ADMIN_DISCHARGE';
    
        l_flg_status_adm discharge.flg_status_adm%TYPE;
        l_ret            VARCHAR2(1 CHAR);
        l_error          t_error_out;
    
    BEGIN
    
        --g_error := 'GET FLG_STATUS AND DT_ADMIN';
        --alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_discharge IS NOT NULL
        THEN
            SELECT d.flg_status_adm
              INTO l_flg_status_adm
              FROM discharge d
             WHERE d.id_discharge = i_discharge;
        ELSE
            l_flg_status_adm := i_flg_status_adm;
        END IF;
    
        IF l_flg_status_adm = pk_alert_constant.g_active
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END check_admin_discharge;

    /**********************************************************************************************
    * Gets the discharge type description
    *
    * @param i_lang      the id language
    * @param i_prof      professional ID, SOFTWARE and INSTITUTION
    * @param i_episode   episode ID
    * @param i_flg_type  discharge type
    *
    * @return            Discharge type description
    *
    * @author            José Silva
    * @version           1.0
    * @since             2010/05/25
    **********************************************************************************************/
    FUNCTION get_disch_dest_type
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN discharge.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_software software.id_software%TYPE;
        l_desc_type   sys_domain.desc_val%TYPE;
    
    BEGIN
    
        SELECT nvl(e.id_software, i_prof.software)
          INTO l_id_software
          FROM epis_info e
         WHERE e.id_episode = i_episode;
    
        IF l_id_software IN
           (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_inpatient, pk_alert_constant.g_soft_ubu)
        THEN
            l_desc_type := '';
        ELSE
            l_desc_type := pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE', i_flg_type, i_lang);
        END IF;
        --
        RETURN l_desc_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_disch_dest_type;

    /********************************************************************************************
    * Checks if the current discharge record shows the MyAlert purchase form
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            episode ID
    * @param o_flg_has_trans_model   has transactional model: Y - yes, N - No
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        José Silva
    * @version                       2.6.0.5
    * @since                         13-01-2011
    ********************************************************************************************/
    FUNCTION check_transactional_model
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_flg_has_trans_model OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_TRANSACTIONAL_MODEL';
    
        l_id_discharge discharge.id_discharge%TYPE;
        l_flg_status   discharge.flg_status%TYPE;
        l_prof_med     discharge.id_prof_med%TYPE;
        l_prof_admin   discharge.id_prof_admin%TYPE;
        l_flg_admin    VARCHAR2(1 CHAR);
    
        l_config_trans_model CONSTANT sys_config.id_sys_config%TYPE := 'TRANSACTIONAL_MODEL_DOC';
        l_doc_trans_model VARCHAR2(1 CHAR);
    
        l_screen_disch table_varchar;
        l_screen_name  discharge_reason.file_to_execute%TYPE;
    
        CURSOR c_disch_screen IS
            SELECT screen_name
              FROM (SELECT nvl(dff.file_name, dr.file_to_execute) screen_name
                      FROM discharge d
                      LEFT JOIN discharge_hist dh
                        ON dh.id_discharge = d.id_discharge
                      JOIN disch_reas_dest drd
                        ON drd.id_disch_reas_dest = nvl(dh.id_disch_reas_dest, d.id_disch_reas_dest)
                      JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                      LEFT JOIN profile_disch_reason pdr
                        ON pdr.id_discharge_reason = drd.id_discharge_reason
                       AND pdr.id_institution = i_prof.institution
                      LEFT JOIN discharge_flash_files dff
                        ON dff.id_discharge_flash_files = pdr.id_discharge_flash_files
                     WHERE d.id_discharge = l_id_discharge
                       AND (pdr.id_profile_template = dh.id_profile_template OR pdr.id_profile_template IS NULL)
                     ORDER BY dh.dt_created_hist DESC) disch
              JOIN TABLE(l_screen_disch)
                ON column_value = disch.screen_name;
    
    BEGIN
    
        g_error           := 'GET CONFIG';
        l_doc_trans_model := pk_sysconfig.get_config(l_config_trans_model, i_prof);
    
        l_screen_disch := table_varchar('ExpiredAllDisposition.swf',
                                        'LWBSAllDisposition.swf',
                                        'DispositionCreateStep2Expire.swf',
                                        'DispositionCreateStep2LWBS.swf');
    
        g_error := 'GET ID_DISCHARGE';
        BEGIN
            SELECT d.id_discharge
              INTO l_id_discharge
              FROM discharge d
             WHERE d.id_episode = i_id_episode
               AND d.flg_status = g_disch_status_active;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_has_trans_model := pk_alert_constant.g_no;
        END;
    
        IF l_id_discharge IS NOT NULL
        THEN
            g_error     := 'CHECK_ADMIN_DISCHARGE';
            l_flg_admin := check_admin_discharge(i_lang, i_prof, l_id_discharge);
        
            g_error := 'GET FLG STATUS';
            IF NOT get_flg_status(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_discharge  => l_id_discharge,
                                  o_flg_status => l_flg_status,
                                  o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'GET DISCHARGE SCREEN';
            OPEN c_disch_screen;
            FETCH c_disch_screen
                INTO l_screen_name;
            CLOSE c_disch_screen;
        
            g_error := 'GET DISCHARGE PROFS';
            SELECT d.id_prof_med, d.id_prof_admin
              INTO l_prof_med, l_prof_admin
              FROM discharge d
             WHERE d.id_discharge = l_id_discharge;
        
            IF l_screen_name IS NOT NULL -- LWBS and expired discharge types shouldn't have this feature
            THEN
                o_flg_has_trans_model := pk_alert_constant.g_no;
            ELSIF l_flg_admin = pk_alert_constant.g_yes
                  AND (l_doc_trans_model = pk_alert_constant.g_no OR l_prof_med = l_prof_admin) -- administrative discharge
            THEN
                o_flg_has_trans_model := pk_alert_constant.g_yes;
            ELSIF l_flg_admin = pk_alert_constant.g_no
                  AND l_doc_trans_model = pk_alert_constant.g_yes -- physician discharge
            THEN
                o_flg_has_trans_model := pk_alert_constant.g_yes;
            ELSE
                o_flg_has_trans_model := pk_alert_constant.g_no;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_transactional_model;

    /**********************************************************************************************
    * Gets discharge screen name for a given discharge reason and profile template
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    *
    * @return                         discharge screen name
    *
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2011/01/21
    **********************************************************************************************/
    FUNCTION get_disch_screen_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DISCH_SCREEN_NAME';
        --
        l_first_ln CONSTANT PLS_INTEGER := 1;
        --
        l_screen_name VARCHAR2(1000 CHAR) := NULL;
    BEGIN
        g_error := 'GET SCREEN NAME';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        SELECT t.screen_name
          INTO l_screen_name
          FROM (SELECT nvl(dff.file_name, dr.file_to_execute) screen_name,
                       row_number() over(ORDER BY dh.dt_created_hist DESC) line_number
                  FROM discharge d
                  LEFT JOIN discharge_hist dh
                    ON dh.id_discharge = d.id_discharge
                  JOIN disch_reas_dest drd
                    ON drd.id_disch_reas_dest = nvl(dh.id_disch_reas_dest, d.id_disch_reas_dest)
                  JOIN discharge_reason dr
                    ON dr.id_discharge_reason = drd.id_discharge_reason
                  LEFT JOIN profile_disch_reason pdr
                    ON pdr.id_discharge_reason = drd.id_discharge_reason
                   AND pdr.id_institution = i_prof.institution
                   AND pdr.id_profile_template = dh.id_profile_template
                  LEFT JOIN discharge_flash_files dff
                    ON dff.id_discharge_flash_files = pdr.id_discharge_flash_files
                 WHERE d.id_discharge = i_discharge) t
        -- This is only to prevent the TOO_MANY_ROWS exception that happens if configuration are wrong, if they are right then it will always have only one record
         WHERE t.line_number = l_first_ln;
    
        RETURN l_screen_name;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            RETURN NULL;
    END get_disch_screen_name;

    /********************************************************************************************
    * Get the administrative discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
    
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   13-12-2005
    *
    ********************************************************************************************/
    FUNCTION get_admin_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_disch FOR
            SELECT d.id_discharge,
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_admin_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, d.dt_admin_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_admin_tstz, i_prof.institution, i_prof.software) dt_admin,
                   d.notes_admin,
                   -- José Brito 09/02/09 ALERT-9546
                   decode((SELECT COUNT(*)
                            FROM disch_prof_notes dpn
                           WHERE dpn.id_discharge = d.id_discharge),
                          0,
                          decode(d.notes_admin, -- Only for old records
                                 NULL,
                                 NULL,
                                 pk_message.get_message(i_lang, i_prof, 'COMMON_M008')),
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M008')) title_notes,
                   --
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_admin,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) desc_transp,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_med,
                   v.desc_discharge_reason desc_disch_reason,
                   v.desc_discharge_dest desc_disch_dest,
                   --lg 2007-03-02
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M028'),
                          pk_discharge.g_disch_flg_reopen,
                          ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M037'),
                          decode(d.flg_status_adm,
                                 pk_discharge.g_disch_flg_cancel,
                                 ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M028'),
                                 NULL)) desc_status_dest,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', d.flg_status, NULL) desc_status,
                   d.flg_status,
                   get_disch_dest_type(i_lang, i_prof, d.id_episode, d.flg_type) desc_type,
                   decode(d.flg_status, pk_discharge.g_disch_flg_cancel, 'Y', 'N') flg_cancel,
                   d.price,
                   d.currency,
                   d.flg_payment,
                   decode(flg_payment,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(g_domain_disch_flg_pay, d.flg_payment, i_lang)) flg_payment_desc,
                   d.flg_status_adm -- ALERT-115681 Cancel administrative discharge
              FROM discharge         d,
                   discharge_reason  dre,
                   disch_reas_dest   drd,
                   v_disch_reas_dest v,
                   transp_entity     te,
                   professional      p,
                   professional      p1,
                   professional      p2
             WHERE d.id_episode = i_episode
               AND p.id_professional = d.id_prof_admin
               AND te.id_transp_entity(+) = d.id_transp_ent_adm
               AND dre.id_discharge_reason = drd.id_discharge_reason
               AND drd.id_disch_reas_dest = d.id_disch_reas_dest
               AND p2.id_professional(+) = d.id_prof_cancel
               AND p1.id_professional(+) = d.id_prof_med
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND ((v.id_disch_dest = drd.id_discharge_dest AND drd.id_discharge_dest IS NOT NULL) OR
                   (drd.id_discharge_dest IS NULL))
               AND v.id_language = i_lang
               AND nvl(v.flg_available, pk_alert_constant.g_available) = pk_alert_constant.g_available
               AND d.dt_admin_tstz >= nvl(i_fltr_start_date, d.dt_admin_tstz)
               AND d.dt_admin_tstz <= nvl(i_fltr_end_date, d.dt_admin_tstz)
             ORDER BY d.dt_admin_tstz DESC;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADMIN_DISCHARGE',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_admin_discharge;

    /**********************************************************************************************
    * Get all discharge notes (medical or administrative).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_notes              The notes
    * @param o_error              Error message
    *
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0
    * @since             2009/02/10
    **********************************************************************************************/
    FUNCTION get_disch_prof_notes
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_discharge    IN discharge.id_discharge%TYPE,
        i_flg_type        IN VARCHAR2,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_notes           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notes_type_c CONSTANT VARCHAR2(1 CHAR) := 'C'; -- cancellation notes
        l_notes_type_n CONSTANT VARCHAR2(1 CHAR) := 'N'; -- discharge notes
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN O_NOTES';
        pk_alertlog.log_debug(g_error);
        OPEN o_notes FOR
            SELECT dpe.id_discharge,
                   pk_date_utils.dt_chr_tsz(i_lang, dpe.dt_creation, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, dpe.dt_creation, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, dpe.dt_creation, i_prof.institution, i_prof.software) dt_creation,
                   dpe.id_prof_create,
                   dpe.dt_creation dt_ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   dpe.notes,
                   decode(dpe.id_cancel_reason, NULL, l_notes_type_n, l_notes_type_c) flg_notes_type,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dpe.id_cancel_reason) desc_cancel_reason
              FROM disch_prof_notes dpe, professional p
             WHERE dpe.id_prof_create = p.id_professional
               AND dpe.id_discharge = i_id_discharge
               AND dpe.flg_type = i_flg_type
               AND dpe.dt_creation >= nvl(i_fltr_start_date, dpe.dt_creation)
               AND dpe.dt_creation <= nvl(i_fltr_end_date, dpe.dt_creation)
            
            UNION ALL -- José Brito 01/04/2009 Support for old data
            
            SELECT d.id_discharge,
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_admin_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, d.dt_admin_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_admin_tstz, i_prof.institution, i_prof.software) dt_creation,
                   d.id_prof_admin id_prof_create,
                   d.dt_admin_tstz dt_ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   d.notes_admin notes,
                   l_notes_type_n flg_notes_type,
                   NULL desc_cancel_reason
              FROM discharge d, professional p
             WHERE d.id_discharge = i_id_discharge
               AND d.id_prof_admin = p.id_professional
               AND i_flg_type = 'A' -- administrative notes
               AND notes_admin IS NOT NULL
               AND d.dt_admin_tstz >= nvl(i_fltr_start_date, d.dt_admin_tstz)
               AND d.dt_admin_tstz <= nvl(i_fltr_end_date, d.dt_admin_tstz)
               AND NOT EXISTS (SELECT 0
                      FROM disch_prof_notes d1
                     WHERE d1.id_discharge = d.id_discharge
                       AND d1.flg_type = 'A')
            
             ORDER BY dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_PROF_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_prof_notes;

    /********************************************************************************************
    * Retrieves a discharge record history of operations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_disch_hist_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch           IN discharge.id_discharge%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_hist            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_br    CONSTANT VARCHAR2(4) := '<br>';
        l_empty CONSTANT VARCHAR2(2) := '--';
        l_end_hour       sys_message.desc_message%TYPE;
        l_pat_destiny    sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_created        sys_message.desc_message%TYPE;
        l_edited         sys_message.desc_message%TYPE;
        l_cancelled      sys_message.desc_message%TYPE;
        l_cancel_reas    sys_message.desc_message%TYPE;
        l_cancel_notes   sys_message.desc_message%TYPE;
        l_epis_type      epis_type.id_epis_type%TYPE;
        l_epis_type_desc pk_translation.t_desc_translation;
        l_cs_desc        pk_translation.t_desc_translation;
        l_episode        discharge.id_episode%TYPE;
        CURSOR c_disch IS
            SELECT d.id_episode
              FROM discharge d
             WHERE d.id_discharge = i_disch;
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        l_end_hour       := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T063') || ' </b>';
        l_pat_destiny    := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T044') || ' </b>';
        l_notes          := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T045') || ' </b>';
        l_created        := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T060');
        l_edited         := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T058');
        l_cancelled      := pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T059');
        l_cancel_reas    := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T061') || ' </b>';
        l_cancel_notes   := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T062') || ' </b>';
        l_epis_type      := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        l_epis_type_desc := nvl(pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || l_epis_type), ' ');
    
        -- TODO have UI layer send id_episode
        g_error := 'OPEN c_disch';
        OPEN c_disch;
        FETCH c_disch
            INTO l_episode;
        CLOSE c_disch;
    
        l_cs_desc := pk_episode.get_cs_desc(i_lang => i_lang, i_prof => i_prof, i_episode => l_episode);
    
        g_error := 'OPEN o_hist';
        OPEN o_hist FOR
            SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, dh.dt_created_hist, i_prof) dt_begin,
                   l_cs_desc clinical_service,
                   l_epis_type_desc episode_type,
                   pk_tools.get_prof_description(i_lang, i_prof, dh.id_prof_med, dh.dt_created_hist, l_episode) prof,
                   decode(dh.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          pk_discharge.g_disch_flg_cancel,
                          pk_discharge.g_disch_flg_active) flg_status,
                   decode(rownum,
                          1,
                          l_created,
                          decode(dh.flg_status, pk_discharge.g_disch_flg_cancel, l_cancelled, l_edited)) desc_status,
                   l_end_hour || pk_date_utils.dt_chr_hour_tsz(i_lang, dh.dt_med_tstz, i_prof) || l_br || l_pat_destiny ||
                   pk_translation.get_translation(i_lang, dd.code_discharge_dest) || l_br ||
                   decode(dh.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          l_cancel_reas ||
                          pk_translation.get_translation(i_lang,
                                                         'CANCEL_REASON.CODE_CANCEL_REASON.' || d.id_cancel_reason) || l_br ||
                          l_cancel_notes || nvl(dh.notes_cancel, l_empty),
                          l_notes || nvl(dh.notes_med, l_empty)) desc_discharge
              FROM (SELECT dh.id_discharge,
                           dh.id_disch_reas_dest,
                           dh.id_episode,
                           dh.id_prof_cancel,
                           dh.notes_cancel,
                           dh.id_prof_med,
                           dh.notes_med,
                           dh.flg_status,
                           dh.dt_med_tstz,
                           dh.dt_cancel_tstz,
                           dh.dt_created_hist
                      FROM discharge_hist dh
                     WHERE dh.id_discharge = i_disch
                       AND dh.dt_created_hist >= nvl(i_fltr_start_date, dh.dt_created_hist)
                       AND dh.dt_created_hist <= nvl(i_fltr_end_date, dh.dt_created_hist)
                     ORDER BY dh.dt_created_hist) dh
              LEFT JOIN (SELECT id_discharge, id_cancel_reason
                           FROM discharge) d
             USING (id_discharge)
              LEFT JOIN disch_reas_dest drd
             USING (id_disch_reas_dest)
              LEFT JOIN discharge_dest dd
             USING (id_discharge_dest)
             ORDER BY dh.dt_created_hist DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_HIST_AMB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_disch_hist_amb;

    /********************************************************************************************
    * Retrieve discharges, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharges_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_end_hour       sys_message.desc_message%TYPE;
        l_pat_destiny    sys_message.desc_message%TYPE;
        l_epis_type      epis_type.id_epis_type%TYPE;
        l_epis_type_desc pk_translation.t_desc_translation;
        l_cs_desc        pk_translation.t_desc_translation;
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        l_end_hour       := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T063') || ' </b>';
        l_pat_destiny    := '<b>' || pk_message.get_message(i_lang, i_prof, 'DISCHARGE_T044') || ' </b>';
        l_epis_type      := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        l_epis_type_desc := nvl(pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || l_epis_type), ' ');
        l_cs_desc        := pk_episode.get_cs_desc(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        g_error := 'OPEN o_disch';
        OPEN o_disch FOR
            SELECT t.id_discharge,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_disch_tstz, i_prof) dt_begin,
                   l_cs_desc clinical_service,
                   l_epis_type_desc episode_type,
                   pk_tools.get_prof_description(i_lang, i_prof, t.id_prof_med, t.dt_disch_tstz, i_episode) prof,
                   decode(t.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          pk_discharge.g_disch_flg_cancel,
                          pk_discharge.g_disch_flg_active) flg_status,
                   l_end_hour || pk_date_utils.dt_chr_hour_tsz(i_lang, t.dt_med_tstz, i_prof) || l_br || l_pat_destiny ||
                   pk_translation.get_translation(i_lang, t.code_discharge_dest) desc_discharge
              FROM (SELECT d.id_discharge,
                           nvl((SELECT MAX(dh.dt_created_hist)
                                 FROM discharge_hist dh
                                WHERE dh.id_discharge = d.id_discharge),
                               d.dt_med_tstz) dt_disch_tstz,
                           d.id_prof_med,
                           d.flg_status,
                           d.dt_med_tstz,
                           dd.code_discharge_dest
                      FROM episode e
                      JOIN discharge d
                     USING (id_episode)
                      LEFT JOIN disch_reas_dest drd
                     USING (id_disch_reas_dest)
                      LEFT JOIN discharge_dest dd
                     USING (id_discharge_dest)
                     WHERE id_episode = i_episode
                       AND e.id_epis_type = l_epis_type) t
             WHERE t.dt_disch_tstz >= nvl(i_fltr_start_date, t.dt_disch_tstz)
               AND t.dt_disch_tstz <= nvl(i_fltr_end_date, t.dt_disch_tstz)
               AND t.id_prof_med IS NOT NULL
             ORDER BY t.dt_med_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGES_AMB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_disch);
            RETURN FALSE;
    END get_discharges_amb;

    /********************************************************************************************
    * Returns discharge detail (admission)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_admit
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        OPEN o_sql FOR
            SELECT pk_translation.get_translation(i_lang, rea.code_discharge_reason) o_disposition,
                   v.desc_discharge_dest o_to,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      v.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_translation.get_translation(i_lang, tra.code_transp_entity) o_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_REPORT_ADMIT', flg_pat_report, i_lang) o_flg_pat_report,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_VOLUNTARY', flg_voluntary, i_lang) o_flg_voluntary,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) o_prof_admitting,
                   pk_translation.get_translation(i_lang, cli.code_clinical_service) o_service,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_discharge.get_disch_det_mse_type_desc(i_lang, dtl.mse_type) desc_mse_type,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORIS', dtl.flg_surgery, i_lang) desc_flg_surgery,
                   pk_date_utils.dt_chr_tsz(i_lang, dtl.date_surgery_tstz, i_prof) date_surgery,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail          dtl,
                   discharge                 dsc,
                   disch_reas_dest           drd,
                   discharge_dest            des,
                   discharge_reason          rea,
                   disch_rea_transp_ent_inst dei,
                   transp_ent_inst           tei,
                   professional              prf,
                   professional              prf2,
                   dep_clin_serv             dcs,
                   clinical_service          cli,
                   transp_entity             tra,
                   v_disch_reas_dest         v
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND dsc.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = rea.id_discharge_reason
               AND drd.id_discharge_dest = des.id_discharge_dest(+)
               AND dtl.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
               AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
               AND tei.id_transp_entity = tra.id_transp_entity(+)
               AND tei.id_institution(+) = i_prof.institution
               AND dtl.id_prof_admitting = prf.id_professional(+)
               AND dtl.id_dep_clin_serv_admiting = dcs.id_dep_clin_serv(+)
               AND dcs.id_clinical_service = cli.id_clinical_service(+)
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND ((v.id_disch_dest = drd.id_discharge_dest AND drd.id_discharge_dest IS NOT NULL) OR
                   (drd.id_discharge_dest IS NULL))
               AND v.id_language = i_lang
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_ADMIT',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_admit;

    /********************************************************************************************
    * Returns discharge detail (transfer)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_transf
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_suggested_institutions VARCHAR(2000 CHAR);
        l_suggested_array        table_varchar := table_varchar();
        l_flg_inst_transfer      discharge_detail.flg_inst_transfer%TYPE;
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        SELECT decode(ie.id_institution_ext, NULL, dti.free_text_inst, ie.institution_name) || ' (' || dti.rank || ')'
          BULK COLLECT
          INTO l_suggested_array
          FROM disch_transf_inst dti, disch_dest_inst ddi, institution_ext ie
         WHERE dti.id_discharge = i_id_discharge -- dicharge
           AND dti.id_disch_dest_inst = ddi.id_disch_dest_inst(+)
           AND ddi.id_institution_ext = ie.id_institution_ext(+);
    
        IF l_suggested_array.count != 0
        THEN
            FOR indx IN l_suggested_array.first .. l_suggested_array.last
            LOOP
                l_suggested_institutions := l_suggested_institutions || l_suggested_array(indx) || '; ';
            END LOOP;
            l_suggested_institutions := rtrim(l_suggested_institutions, '; ');
        ELSE
            BEGIN
                SELECT dd.flg_inst_transfer
                  INTO l_flg_inst_transfer
                  FROM discharge_detail dd
                 WHERE dd.id_discharge = i_id_discharge;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_inst_transfer := NULL;
            END;
        
            IF l_flg_inst_transfer = pk_alert_constant.g_yes
            THEN
                l_suggested_institutions := pk_message.get_message(i_lang, 'DISCHARGE_T099');
            END IF;
        END IF;
    
        OPEN o_sql FOR
            SELECT v.desc_discharge_reason o_disposition,
                   v.desc_discharge_dest o_to,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      v.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_translation.get_translation(i_lang, tra.code_transp_entity) o_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_REPORT_TRANSFER', flg_pat_report, i_lang) o_flg_pat_report,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_VOLUNTARY', flg_voluntary, i_lang) o_flg_voluntary,
                   dtl.prof_admitting_desc o_prof_admitting,
                   dtl.dep_clin_serv_admiting_desc o_service,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_transfer_form, i_lang) o_flg_transfer_form,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => di.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => di.code_icd,
                                              i_flg_other           => di.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) transfer_reasons,
                   l_suggested_institutions suggested_institutions,
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail          dtl,
                   discharge                 dsc,
                   v_disch_reas_dest         v,
                   disch_reas_dest           drd,
                   disch_rea_transp_ent_inst dei,
                   transp_ent_inst           tei,
                   transp_entity             tra,
                   professional              prf2,
                   diagnosis                 di,
                   epis_diagnosis            ed
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND drd.id_disch_reas_dest = dsc.id_disch_reas_dest
               AND dtl.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
               AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
               AND tei.id_transp_entity = tra.id_transp_entity(+)
               AND tei.id_institution(+) = i_prof.institution
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND ((v.id_disch_dest = drd.id_discharge_dest AND drd.id_discharge_dest IS NOT NULL) OR
                   (drd.id_discharge_dest IS NULL))
               AND v.id_language = i_lang
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND dtl.id_transfer_diagnosis = di.id_diagnosis(+)
               AND dtl.id_epis_diagnosis = ed.id_epis_diagnosis(+)
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_TRANSF',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_transf;

    /********************************************************************************************
    * Returns discharge detail (expired)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_expir
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        OPEN o_sql FOR
            SELECT pk_translation.get_translation(i_lang, rea.code_discharge_reason) o_disposition,
                   pk_translation.get_translation(i_lang, des.code_discharge_dest) o_to,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_autopsy_consent, i_lang) o_flg_autopsy_consent,
                   dtl.autopsy_consent_desc o_autopsy_consent_desc,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORGN_DNTN_INFO', flg_orgn_dntn_info, i_lang) o_flg_orgn_dntn_info,
                   dtl.orgn_dntn_info o_orgn_dntn_info,
                   pk_sysdomain.get_domain('YES_NO_NA', dtl.flg_examiner_notified, i_lang) o_flg_examiner_notified,
                   dtl.examiner_notified_info o_examiner_notified_info,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_orgn_dntn_form_complete, i_lang) o_flg_orgn_dntn_form_complete,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   -- AS 19-03-2011 (ALERT-65836)
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_autopsy, i_lang) o_flg_autopsy,
                   dtl.death_process_registration o_death_process_registration,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      rea.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail dtl,
                   discharge        dsc,
                   disch_reas_dest  drd,
                   discharge_dest   des,
                   discharge_reason rea,
                   professional     prf2
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND dsc.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = rea.id_discharge_reason
               AND drd.id_discharge_dest = des.id_discharge_dest
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_EXPIR',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_expir;

    /********************************************************************************************
    * Returns discharge detail (against medical advice)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_ama
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        OPEN o_sql FOR
            SELECT pk_translation.get_translation(i_lang, rea.code_discharge_reason) o_disposition,
                   pk_translation.get_translation(i_lang, des.code_discharge_dest) o_to,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      rea.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_translation.get_translation(i_lang, tra.code_transp_entity) o_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_CARETAKER_AMA', flg_caretaker, i_lang) o_caretaker,
                   dtl.caretaker_notes o_caretaker_notes,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_FOLLOW_UP_BY_AMA', flg_follow_up_by, i_lang) o_flg_follow_up_by,
                   dtl.follow_up_notes o_follow_up_notes,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_ama_form_complete, i_lang) o_flg_ama_form_complete,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail          dtl,
                   discharge                 dsc,
                   disch_reas_dest           drd,
                   discharge_dest            des,
                   discharge_reason          rea,
                   disch_rea_transp_ent_inst dei,
                   transp_ent_inst           tei,
                   transp_entity             tra,
                   professional              prf2
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND dsc.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = rea.id_discharge_reason
               AND drd.id_discharge_dest = des.id_discharge_dest
               AND dtl.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
               AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
               AND tei.id_transp_entity = tra.id_transp_entity(+)
               AND tei.id_institution(+) = i_prof.institution
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_AMA',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_ama;
    --
    /**********************************************************************************************
    * Devolve o detalhe da alta
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author
    * @version                        1.0
    * @changed                        Emília Taborda
    * @since                          2007/06/18
    **********************************************************************************************/
    FUNCTION get_disch_detail_disch
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        OPEN o_sql FOR
            SELECT rea.id_discharge_reason,
                   pk_translation.get_translation(i_lang, rea.code_discharge_reason) o_disposition,
                   v.id_disch_dest id_discharge_dest,
                   v.desc_discharge_dest o_to,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      v.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_translation.get_translation(i_lang, tra.code_transp_entity) o_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_CARETAKER_DISCH', flg_caretaker, i_lang) o_caretaker,
                   dtl.caretaker_notes o_caretaker_notes,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_FOLLOW_UP_BY_DISCH', flg_follow_up_by, i_lang) o_flg_follow_up_by,
                   dtl.follow_up_notes o_follow_up_notes,
                   pk_date_utils.date_char_tsz(i_lang, dtl.follow_up_date_tstz, i_prof.institution, i_prof.software) o_follow_up_date,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_discharge.get_disch_det_mse_type_desc(i_lang, dtl.mse_type) desc_mse_type,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_ORIS', dtl.flg_surgery, i_lang) desc_flg_surgery,
                   pk_date_utils.dt_chr_tsz(i_lang, dtl.date_surgery_tstz, i_prof) date_surgery,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail          dtl,
                   discharge                 dsc,
                   disch_reas_dest           drd,
                   discharge_dest            des,
                   discharge_reason          rea,
                   disch_rea_transp_ent_inst dei,
                   transp_ent_inst           tei,
                   transp_entity             tra,
                   v_disch_reas_dest         v,
                   professional              prf2
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND dsc.id_disch_reas_dest(+) = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = rea.id_discharge_reason(+)
               AND drd.id_discharge_dest = des.id_discharge_dest(+)
               AND dtl.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
               AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
               AND tei.id_transp_entity = tra.id_transp_entity(+)
               AND tei.id_institution(+) = i_prof.institution
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND v.id_language = i_lang
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_DISCH',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_disch;
    /********************************************************************************************
    * Returns discharge detail (left without being seen)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_lwbs
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        OPEN o_sql FOR
            SELECT pk_translation.get_translation(i_lang, rea.code_discharge_reason) o_disposition,
                   pk_translation.get_translation(i_lang, des.code_discharge_dest) o_to,
                   pk_discharge.get_patient_condition(i_lang,
                                                      i_prof,
                                                      dsc.id_discharge,
                                                      rea.id_discharge_reason,
                                                      dtl.flg_pat_condition) o_pat_condition,
                   pk_translation.get_translation(i_lang, tra.code_transp_entity) o_transport,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_CARETAKER_LWBS', flg_caretaker, i_lang) o_caretaker,
                   dtl.caretaker_notes o_caretaker_notes,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_FOLLOW_UP_BY_LWBS', flg_follow_up_by, i_lang) o_flg_follow_up_by,
                   dtl.follow_up_notes o_follow_up_notes,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_lwbs_form_complete, i_lang) o_flg_ama_form_complete,
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_summary_report, i_lang) o_flg_summary_report,
                   -- José Brito 04/07/2008 Mostrar valor de FLG_PRINT_REPORT no detalhe
                   pk_sysdomain.get_domain('YES_NO', dtl.flg_print_report, i_lang) o_flg_print_report,
                   --
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', dsc.flg_status, NULL) desc_status,
                   nvl(dsc.notes_med, nvl(dsc.notes_admin, dtl.notes)) o_add_notes,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, dsc.id_cancel_reason) cancel_reason,
                   dsc.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prf2.id_professional) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prf2.id_professional,
                                                    dsc.dt_cancel_tstz,
                                                    dsc.id_episode) spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_cancel_tstz, i_prof.institution, i_prof.software) date_cancel,
                   -- AS 28-01-2010 (ALERT-71126)
                   pk_date_utils.date_send_tsz(i_lang, dsc.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, dsc.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date
              FROM discharge_detail          dtl,
                   discharge                 dsc,
                   disch_reas_dest           drd,
                   discharge_dest            des,
                   discharge_reason          rea,
                   disch_rea_transp_ent_inst dei,
                   transp_ent_inst           tei,
                   transp_entity             tra,
                   professional              prf2
             WHERE dsc.id_discharge = i_id_discharge
               AND dsc.id_discharge = dtl.id_discharge(+)
               AND dsc.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.id_discharge_reason = rea.id_discharge_reason
               AND drd.id_discharge_dest = des.id_discharge_dest
               AND dtl.id_disch_rea_transp_ent_inst = dei.id_disch_rea_transp_ent_inst(+)
               AND dei.id_transp_ent_inst = tei.id_transp_ent_inst(+)
               AND tei.id_transp_entity = tra.id_transp_entity(+)
               AND tei.id_institution(+) = i_prof.institution
               AND prf2.id_professional(+) = dsc.id_prof_cancel
               AND (dsc.dt_med_tstz >= nvl(i_fltr_start_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL)
               AND (dsc.dt_med_tstz <= nvl(i_fltr_end_date, dsc.dt_med_tstz) OR dsc.dt_med_tstz IS NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_LWBS',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_lwbs;
    --
    /********************************************************************************************
    * Returns discharge detail
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_file_to_execute discharge_reason.file_to_execute%TYPE;
        l_general_error EXCEPTION;
    
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        g_error := 'GET FILE_TO_EXECUTE';
        BEGIN
            SELECT dr.file_to_execute
              INTO l_file_to_execute
              FROM discharge d
              JOIN disch_reas_dest drd
                ON drd.id_disch_reas_dest = d.id_disch_reas_dest
              JOIN discharge_reason dr
                ON dr.id_discharge_reason = drd.id_discharge_reason
             WHERE d.id_discharge = i_id_discharge;
        EXCEPTION
            WHEN no_data_found THEN
                l_file_to_execute := NULL;
        END;
    
        CASE lower(l_file_to_execute)
            WHEN lower(pk_discharge.g_disch_screen_disp_admit) THEN
                g_error := 'CALL GET_DISCH_DETAIL_ADMIT';
                IF NOT pk_discharge.get_disch_detail_admit(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_discharge => i_id_discharge,
                                                           o_sql          => o_sql,
                                                           o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_ama) THEN
                g_error := 'CALL GET_DISCH_DETAIL_AMA';
                IF NOT pk_discharge.get_disch_detail_ama(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_discharge => i_id_discharge,
                                                         o_sql          => o_sql,
                                                         o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_disch) THEN
                g_error := 'CALL GET_DISCH_DETAIL_DISCH';
                IF NOT pk_discharge.get_disch_detail_disch(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_discharge => i_id_discharge,
                                                           o_sql          => o_sql,
                                                           o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_exp) THEN
                g_error := 'CALL GET_DISCH_DETAIL_EXPIR';
                IF NOT pk_discharge.get_disch_detail_expir(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_discharge => i_id_discharge,
                                                           o_sql          => o_sql,
                                                           o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_lwbs) THEN
                g_error := 'CALL GET_DISCH_DETAIL_LWBS';
                IF NOT pk_discharge.get_disch_detail_lwbs(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_discharge => i_id_discharge,
                                                          o_sql          => o_sql,
                                                          o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_mse) THEN
                g_error := 'CALL GET_DISCH_DETAIL_DISCH';
                IF NOT pk_discharge.get_disch_detail_disch(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_discharge => i_id_discharge,
                                                           o_sql          => o_sql,
                                                           o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            WHEN lower(pk_discharge.g_disch_screen_disp_transf) THEN
                g_error := 'CALL GET_DISCH_DETAIL_TRANSF';
                IF NOT pk_discharge.get_disch_detail_transf(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_discharge => i_id_discharge,
                                                            o_sql          => o_sql,
                                                            o_error        => o_error)
                THEN
                    RAISE l_general_error;
                END IF;
            ELSE
                g_error := 'Function not mapped for FILE_TO_EXECUTE: "' || l_file_to_execute || '";';
                RAISE l_general_error;
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail;

    FUNCTION get_discharge_destination_spec
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_disch_type                IN v_disch_reas_dest.tipo%TYPE,
        i_file_to_execute           IN discharge_reason.file_to_execute%TYPE,
        i_file                      IN discharge_reason.file_to_execute%TYPE,
        i_id_dep_clin_serv_admiting IN discharge_detail.id_dep_clin_serv_admiting%TYPE
    ) RETURN VARCHAR2 IS
        l_admission_speciality VARCHAR2(200 CHAR);
    BEGIN
        IF i_disch_type in ( 'Destinations','Department')
           AND i_file_to_execute = i_file
        THEN
            IF i_id_dep_clin_serv_admiting IS NOT NULL
            THEN
                SELECT ' - ' || pk_translation.get_translation(i_lang, cs.code_clinical_service)
                  INTO  l_admission_speciality
                  FROM dep_clin_serv dcs
                  JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_admiting;
            END IF;
        END IF;
        RETURN l_admission_speciality;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_discharge_destination_spec;
    /********************************************************************************************
    * Get the episode discharge records
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_category_type       Professional category/discharge type
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
    
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   11-04-2005
    ********************************************************************************************/
    FUNCTION get_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_category_type   IN category.flg_type%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2 DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_disch_admin_pend discharge.flg_status%TYPE;
        l_file_discharge_inp   discharge_reason.file_to_execute%TYPE;
        l_get_prof_last_med    professional.id_professional%TYPE;
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        l_flg_disch_admin_pend := pk_sysconfig.get_config('DISCHARGE_ADM_PEND', i_prof);
        l_file_discharge_inp   := pk_sysconfig.get_config('FILE_DISCHARGE_INP', i_prof);
    
        l_get_prof_last_med := get_prof_last_med(i_lang, i_prof, i_episode);
    
        g_error := 'GET CURSOR';
        OPEN o_disch FOR
            SELECT d.id_discharge,
                   d.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   d.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            nvl(d.dt_med_tstz,
                                                pk_discharge_core.get_dt_admin(i_lang,
                                                                               i_prof,
                                                                               NULL,
                                                                               d.flg_status_adm,
                                                                               d.dt_admin_tstz)),
                                            i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    nvl(d.dt_med_tstz,
                                                        pk_discharge_core.get_dt_admin(i_lang,
                                                                                       i_prof,
                                                                                       NULL,
                                                                                       d.flg_status_adm,
                                                                                       d.dt_admin_tstz)),
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   d.notes_med,
                   d.notes_admin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_med,
                   v.desc_discharge_reason desc_disch_reason,
                   v.desc_discharge_dest  ||
                   get_discharge_destination_spec(i_lang,
                                                  i_prof,
                                                  v.tipo,
                                                  dre.file_to_execute,
                                                  l_file_discharge_inp,
                                                  dd.id_dep_clin_serv_admiting)
                                                   ||
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M028'),
                          pk_discharge.g_disch_flg_reopen,
                          ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M037'),
                          pk_discharge.g_disch_flg_pend,
                          ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M040'),
                          NULL) desc_disch_dest,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', d.flg_status, NULL) desc_status,
                   pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE', d.flg_type, i_lang) desc_type,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) desc_transp,
                   te.id_transp_entity id_transp_entity,
                   decode(d.notes_med,
                          '',
                          decode(d.notes_admin,
                                 '',
                                 decode(d.notes_cancel, '', '', pk_message.get_message(i_lang, i_prof, 'COMMON_M008')),
                                 pk_message.get_message(i_lang, i_prof, 'COMMON_M008')),
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M008')) title_notes,
                   decode(d.flg_status, pk_discharge.g_disch_flg_cancel, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, d.dt_med_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   dre.file_to_execute,
                   d.price,
                   d.currency,
                   d.flg_payment,
                   decode(flg_payment,
                          NULL,
                          NULL,
                          pk_sysdomain.get_domain(g_domain_disch_flg_pay, d.flg_payment, i_lang)) flg_payment_desc,
                   drd.id_disch_reas_dest id_discharge_dest,
                   d.id_transp_ent_med,
                   decode(dre.file_to_execute, l_file_discharge_inp, 'Y', 'N') flg_edis_to_inp, -- jsilva 18-05-2007
                   decode(d.flg_status, pk_discharge.g_disch_flg_pend, l_flg_disch_admin_pend, pk_alert_constant.g_yes) flg_adm_perm,
                   -- José Brito ALERT-9546 12/02/2009
                   -- New notes can only be created if the discharge is active
                   decode(pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz),
                          NULL,
                          'N',
                          decode(d.flg_status, 'A', 'Y', 'N')) flg_create_notes,
                   -- AS 14-12-2009 (ALERT-62112)
                   drd.id_epis_type,
                   dd.flg_inst_transfer_status,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        pk_alert_constant.g_display_type_icon,
                                                        dd.flg_inst_transfer_status,
                                                        NULL,
                                                        NULL,
                                                        pk_discharge_inst.g_domain_dd_flg_transf_status,
                                                        NULL,
                                                        decode(pk_sysdomain.get_img(i_lang,
                                                                                    pk_discharge_inst.g_domain_dd_flg_transf_status,
                                                                                    dd.flg_inst_transfer_status),
                                                               pk_discharge_inst.g_transf_pending_icon,
                                                               pk_alert_constant.g_color_red,
                                                               pk_discharge_inst.g_transf_suggested_icon,
                                                               pk_alert_constant.g_color_red,
                                                               pk_alert_constant.g_color_null)) icon_status,
                   -- AS 31-03-2010 (ALERT-85440)
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    p1.id_professional,
                                                    nvl(d.dt_med_tstz,
                                                        pk_discharge_core.get_dt_admin(i_lang,
                                                                                       i_prof,
                                                                                       NULL,
                                                                                       d.flg_status_adm,
                                                                                       d.dt_admin_tstz)),
                                                    d.id_episode) prof_spec,
                   decode(d.flg_status,
                          g_disch_active_status,
                          decode(nvl(d.id_prof_pend_active, -999),
                                 -999,
                                 pk_date_utils.date_char_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             d.dt_pend_active_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          g_disch_pend_status,
                          pk_date_utils.date_char_tsz(i_lang, d.dt_pend_tstz, i_prof.institution, i_prof.software),
                          g_disch_canc_status,
                          pk_date_utils.date_char_tsz(i_lang, d.dt_cancel_tstz, i_prof.institution, i_prof.software),
                          g_disch_repoen_status,
                          pk_date_utils.date_char_tsz(i_lang,
                                                      (SELECT MAX(dh.dt_created_hist)
                                                         FROM discharge_hist dh
                                                        WHERE dh.id_discharge = d.id_discharge
                                                          AND dh.flg_status = g_disch_repoen_status),
                                                      i_prof.institution,
                                                      i_prof.software)) dt_reg,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_discharge_core.get_dt_admin(i_lang,
                                                                           i_prof,
                                                                           NULL,
                                                                           d.flg_status_adm,
                                                                           d.dt_admin_tstz),
                                            i_prof) date_admin,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   d.flg_status_adm,
                                                                                   d.dt_admin_tstz),
                                                    i_prof.institution,
                                                    i_prof.software) hour_admin,
                   d.flg_status_adm,
                   dd.notes end_notes,
                   dd.sched_notes,
                   CASE
                        WHEN dd.id_prof_fw = -1 THEN
                         pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T017')
                        ELSE
                         pk_prof_utils.get_name_signature(i_lang, i_prof, dd.id_prof_fw)
                    END name_prof_fw,
                   CASE
                        WHEN dd.id_prof_fw = -1 THEN
                         NULL
                        ELSE
                         pk_prof_utils.get_spec_signature(i_lang, i_prof, dd.id_prof_fw, NULL, NULL)
                    END spec_prof_fw,
                   (SELECT pk_translation.get_translation(i_lang, cs_fw.code_clinical_service)
                      FROM dep_clin_serv dcs_fw
                      JOIN clinical_service cs_fw
                        ON cs_fw.id_clinical_service = dcs_fw.id_clinical_service
                     WHERE dcs_fw.id_dep_clin_serv = dd.id_dep_clin_serv_fw) name_dep_clin_serv_fw,
                   pk_date_utils.dt_chr_tsz(i_lang, dd.dt_fw_visit, i_prof.institution, i_prof.software) dt_fw_visit,
                   dd.id_complaint_fw,
                   CASE
                        WHEN dd.id_complaint_fw IS NOT NULL THEN
                         (SELECT to_clob(pk_translation.get_translation(i_lang, c.code_complaint))
                            FROM complaint c
                           WHERE c.id_complaint = dd.id_complaint_fw)
                        ELSE
                         dd.reason_for_visit_fw
                    END reason_for_visit,
                   pk_discharge.check_disposition_fe_aux(i_lang, i_prof, drd.id_disch_reas_dest) flg_is_iac,
                   dd.death_process_registration,
                   decode(d.flg_status,
                          g_disch_status_active,
                          1,
                          g_disch_status_pend,
                          2,
                          g_disch_status_reopen,
                          3,
                          g_disch_status_cancel,
                          4) order_by_status, 
                          v.tipo
              FROM discharge_reason  dre, -- CMF 10-10-2006 0900
                   discharge         d,
                   disch_reas_dest   drd,
                   v_disch_reas_dest v,
                   professional      p,
                   professional      p1,
                   transp_entity     te,
                   discharge_detail  dd -- PST 17-03-2010
             WHERE d.id_episode = i_episode
               AND d.id_discharge = dd.id_discharge(+)
               AND ((d.flg_status != decode(i_category_type,
                                            pk_alert_constant.g_cat_type_registrar,
                                            pk_discharge.g_disch_flg_cancel,
                                            'XXX')) AND
                   (d.flg_status != decode(i_category_type,
                                            pk_alert_constant.g_cat_type_registrar,
                                            pk_discharge.g_disch_flg_reopen,
                                            'XXX')))
               AND dre.id_discharge_reason = drd.id_discharge_reason
               AND drd.id_disch_reas_dest = d.id_disch_reas_dest
               AND p.id_professional(+) = d.id_prof_cancel
               AND p1.id_professional = coalesce(d.id_prof_med, d.id_prof_admin, l_get_prof_last_med)
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND ((v.id_disch_dest = drd.id_discharge_dest AND drd.id_discharge_dest IS NOT NULL) OR
                   (drd.id_discharge_dest IS NULL))
               AND v.id_language = i_lang
               AND nvl(v.flg_available, pk_alert_constant.g_available) = pk_alert_constant.g_available
               AND te.id_transp_entity(+) = decode(i_category_type,
                                                   pk_alert_constant.g_cat_type_registrar,
                                                   d.id_transp_ent_adm,
                                                   d.id_transp_ent_med)
               AND (nvl(d.dt_med_tstz,
                        pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz)) >=
                   nvl(i_fltr_start_date,
                        nvl(d.dt_med_tstz,
                            pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz))) OR
                   (d.dt_med_tstz IS NULL AND
                   pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz) IS NULL))
               AND (nvl(d.dt_med_tstz,
                        pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz)) <=
                   nvl(i_fltr_end_date,
                        nvl(d.dt_med_tstz,
                            pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz))) OR
                   (d.dt_med_tstz IS NULL AND
                   pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz) IS NULL))
               AND (((d.flg_market <> pk_discharge_core.g_disch_type_us AND
                   nvl(dre.file_to_execute, 'swf') <> l_file_discharge_inp) AND i_flg_type = 'D') OR
                   ((d.id_discharge_flash_files IS NOT NULL OR dre.file_to_execute = l_file_discharge_inp) AND
                   i_flg_type = 'A') OR i_flg_type IS NULL)
            -- REMOVE ADMISSION ORDER 
             ORDER BY order_by_status, d.dt_med_tstz DESC;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_discharge;

    /********************************************************************************************
    * Get the detail of a discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_disch               discharge ID
    * @param   i_prof                professional, institution and software ids
    * @param   i_type                type of detail: F - full detail, S - simplified detail
    *
    * @param   o_disch               Discharge record
    * @param   o_error               error message
    
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   16-07-2005
    ********************************************************************************************/
    FUNCTION get_discharge_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_disch           IN discharge.id_discharge%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_currency_unit_format VARCHAR2(2000);
        l_rep_label            pk_translation.t_desc_translation;
    
        l_print_config       v_print_list_cfg.flg_print_option_default%TYPE;
        l_file_discharge_inp discharge_reason.file_to_execute%TYPE;
    BEGIN
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE g_exception;
        END IF;
    
        g_error := 'GET REPORT LABEL';
        IF NOT pk_discharge.get_report_label(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             o_label        => l_rep_label,
                                             o_print_config => l_print_config,
                                             o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        l_file_discharge_inp := pk_sysconfig.get_config('FILE_DISCHARGE_INP', i_prof);
    
        l_currency_unit_format := pk_sysconfig.get_config(g_currency_unit_format_db, i_prof);
        g_error                := 'GET CURSOR';
        OPEN o_disch FOR
            SELECT d.flg_status,
                   d.notes_justify,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   d.notes_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    nvl(d.dt_med_tstz,
                                                        pk_discharge_core.get_dt_admin(i_lang,
                                                                                       i_prof,
                                                                                       NULL,
                                                                                       d.flg_status_adm,
                                                                                       d.dt_admin_tstz)),
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   d.notes_med notes_med,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_med,
                   pk_translation.get_translation(i_lang, s1.code_speciality) desc_speciality,
                   v.desc_discharge_reason desc_disch_reason,
                   v.desc_discharge_dest desc_disch_dest,
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_cancel,
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M017'),
                          '') title_cancel,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'DISCHARGE.FLG_STATUS', d.flg_status, NULL) desc_status,
                   pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE', d.flg_type, i_lang) desc_type,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) desc_transp,
                   decode(d.price, NULL, NULL, to_char(d.price, l_currency_unit_format) || ' ' || d.currency) price_currency,
                   -- lg 2007-Mar-05
                   decode(flg_payment,
                          NULL,
                          NULL,
                          decode(d.flg_bill_type,
                                 g_flg_bill_type_normal,
                                 pk_sysdomain.get_domain(g_domain_disch_flg_pay, d.flg_payment, i_lang),
                                 NULL)) flg_payment_desc,
                   pk_sysdomain.get_domain(g_domain_bill_type, d.flg_bill_type, i_lang) desc_bill_type,
                   -- AS 14-12-2009 (ALERT-62112)
                   decode(drd.id_epis_type,
                          pk_alert_constant.g_epis_type_inpatient,
                          nvl(pk_translation.get_translation(i_lang,
                                                             'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                             dc.id_clinical_service),
                              (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                 FROM episode e
                                 JOIN epis_info ei
                                   ON ei.id_episode = e.id_episode
                                 JOIN dep_clin_serv dcs
                                   ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                 JOIN clinical_service cs
                                   ON cs.id_clinical_service = dcs.id_clinical_service
                                WHERE e.id_prev_episode = d.id_episode
                                  AND rownum = 1)),
                          NULL) desc_clinical_service,
                   decode(drd.id_epis_type,
                          pk_alert_constant.g_epis_type_inpatient,
                          pk_sysdomain.get_domain('YES_NO',
                                                  nvl(dd.flg_surgery, pk_discharge.get_flg_surgery(d.id_discharge)),
                                                  i_lang),
                          NULL) desc_flg_surgery,
                   pk_sysdomain.get_domain(g_flg_print_report_domain, dd.flg_print_report, i_lang) desc_flg_print_report,
                   l_rep_label desc_report,
                   pk_date_utils.date_char_tsz(i_lang, dd.date_surgery_tstz, i_prof.institution, i_prof.software) dt_surgery,
                   dd.notes end_notes,
                   dd.sched_notes,
                   CASE
                        WHEN dd.id_prof_fw = -1 THEN
                         pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T017')
                        ELSE
                         pk_prof_utils.get_name_signature(i_lang, i_prof, dd.id_prof_fw)
                    END name_prof_fw,
                   CASE
                        WHEN dd.id_prof_fw = -1 THEN
                         NULL
                        ELSE
                         pk_prof_utils.get_spec_signature(i_lang, i_prof, dd.id_prof_fw, NULL, NULL)
                    END spec_prof_fw,
                   (SELECT pk_translation.get_translation(i_lang, cs_fw.code_clinical_service)
                      FROM dep_clin_serv dcs_fw
                      JOIN clinical_service cs_fw
                        ON cs_fw.id_clinical_service = dcs_fw.id_clinical_service
                     WHERE dcs_fw.id_dep_clin_serv = dd.id_dep_clin_serv_fw) name_dep_clin_serv_fw,
                   pk_date_utils.dt_chr_tsz(i_lang, dd.dt_fw_visit, i_prof.institution, i_prof.software) dt_fw_visit,
                   dd.id_complaint_fw,
                   CASE
                        WHEN dd.id_complaint_fw IS NOT NULL THEN
                         (SELECT to_clob(pk_translation.get_translation(i_lang, c.code_complaint))
                            FROM complaint c
                           WHERE c.id_complaint = dd.id_complaint_fw)
                        ELSE
                         dd.reason_for_visit_fw
                    END reason_for_visit,
                   pk_discharge.check_disposition_fe_aux(i_lang, i_prof, drd.id_disch_reas_dest) flg_is_iac,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof) dt_med_tstz_send,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) o_discharge_date,
                   --FALTA TASK TYPE
                   pk_discharge.get_level_of_service_desc(i_lang,
                                                          i_prof,
                                                          pk_alert_constant.g_task_discharge_los,
                                                          id_concept_term,
                                                          d.id_cncpt_trm_inst_owner,
                                                          id_terminology_version) level_of_service_desc,
                   decode(dre.file_to_execute, l_file_discharge_inp, 'Y', 'N') flg_edis_to_inp,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_TYPE_CLOSURE', dd.flg_type_closure, i_lang) desc_type_of_closure,
                   pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_CONDITION', dd.flg_pat_condition, i_lang) desc_pat_condition
              FROM discharge         d,
                   disch_reas_dest   drd,
                   v_disch_reas_dest v,
                   professional      p,
                   professional      p1,
                   speciality        s1,
                   transp_entity     te,
                   discharge_detail  dd,
                   dep_clin_serv     dc,
                   discharge_reason  dre
             WHERE d.id_discharge = i_disch
               AND drd.id_disch_reas_dest = d.id_disch_reas_dest
               AND drd.id_discharge_reason = dre.id_discharge_reason
               AND p.id_professional(+) = d.id_prof_cancel
               AND p1.id_professional = d.id_prof_med
               AND s1.id_speciality(+) = p1.id_speciality
               AND v.id_disch_reas_dest = drd.id_disch_reas_dest
               AND ((v.id_disch_dest = drd.id_discharge_dest AND drd.id_discharge_dest IS NOT NULL) OR
                   (drd.id_discharge_dest IS NULL))
               AND v.id_language = i_lang
               AND nvl(v.flg_available, pk_alert_constant.g_available) = pk_alert_constant.g_available
               AND te.id_transp_entity(+) = d.id_transp_ent_med
               AND dd.id_discharge(+) = d.id_discharge
               AND dd.id_dep_clin_serv_admiting = dc.id_dep_clin_serv(+)
               AND (nvl(d.dt_med_tstz,
                        pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz)) >=
                   nvl(i_fltr_start_date,
                        nvl(d.dt_med_tstz,
                            pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz))) OR
                   (d.dt_med_tstz IS NULL AND
                   pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz) IS NULL))
               AND (nvl(d.dt_med_tstz,
                        pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz)) <=
                   nvl(i_fltr_end_date,
                        nvl(d.dt_med_tstz,
                            pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz))) OR
                   (d.dt_med_tstz IS NULL AND
                   pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz) IS NULL));
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_discharge_detail;
    /********************************************************************************************
    * get_prof_last_med
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional, institution and software ids
    * @param   i_id_episode          episode identifier
    *             
    * @RETURN  get_prof_last_med
    *
    * @version 1.0
    * @since   20160225
    ********************************************************************************************/
    FUNCTION get_prof_last_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN professional.id_professional%TYPE IS
        l_ret professional.id_professional%TYPE;
    BEGIN
        SELECT aux.id_prof_med
          INTO l_ret
          FROM (SELECT row_number() over(ORDER BY a.dt_created_hist DESC) rn, a.id_prof_med
                  FROM discharge_hist a
                  JOIN episode e
                    ON a.id_episode = e.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE a.id_episode = i_id_episode
                   AND pk_prof_utils.get_category(i_lang => i_lang,
                                                  i_prof => profissional(a.id_prof_med,
                                                                         nvl(e.id_institution, i_prof.institution),
                                                                         nvl(ei.id_software, i_prof.software))) =
                       pk_alert_constant.g_cat_type_doc) aux
         WHERE rn = 1;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_ret;
    END get_prof_last_med;

    FUNCTION get_prof_cat_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN category.flg_type%TYPE IS
        l_ret category.flg_type%TYPE;
    BEGIN
        SELECT pk_prof_utils.get_category(i_lang,
                                          profissional(aux.id_professional, aux.id_institution, aux.id_software))
          INTO l_ret
          FROM (SELECT nvl(a.id_prof_nurse, a.id_prof_med) id_professional, ei.id_software, e.id_institution
                  FROM discharge a
                  JOIN episode e
                    ON a.id_episode = e.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE a.id_episode = i_id_episode
                /*AND pk_prof_utils.get_category(i_lang => i_lang,
                                           i_prof => profissional(a.id_prof_med,
                                                                  nvl(e.id_institution, i_prof.institution),
                                                                  nvl(ei.id_software, i_prof.software))) =
                pk_alert_constant.g_cat_type_doc*/
                ) aux;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_ret;
    END get_prof_cat_discharge;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_discharge_core;
/
