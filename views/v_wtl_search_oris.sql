CREATE OR REPLACE VIEW V_WTL_SEARCH_ORIS AS
SELECT wtl.id_waiting_list,
schs.duration surg_exp_dur_min,
      wtl.id_patient, 
      wtl.flg_type, 
      wtl.flg_status, 
      wtl.min_inform_time, 
      wtl.id_wtl_urg_level, 
      wtl.id_external_request,
      (wtl.dt_dpa - current_timestamp) sk_relative_urgency,
      (wtl.dt_dpa - wtl.dt_placement) sk_absolute_urgency,
      (current_timestamp - wtl.dt_placement) sk_waiting_time,
      (wtl.func_eval_score * -1) sk_barthel,
      trunc(pk_date_utils.diff_timestamp(wtl.dt_dpa, current_timestamp)) relative_urgency,
pk_surgery_request.get_duration(sys_context('ALERT_CONTEXT', 'i_lang'), schs.duration) surg_exp_dur,
pk_wtl_pbl_core.get_pref_time_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list) pref_time,
pk_wtl_pbl_core.get_ptime_reason_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list) ptime_reason,
pk_wtl_pbl_core.get_surg_proc_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list) surg_proc,
pk_wtl_pbl_core.get_sr_proc_id_content_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list) surg_proc_id_content,
pk_wtl_pbl_core.get_prof_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list, NULL, sys_context('ALERT_CONTEXT', 'g_wtl_prof_type_adm_phys')) admiting_phys,
pk_wtl_pbl_core.get_danger_cont_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), NULL, wtl.id_waiting_list) danger_cont,
pk_wtl_pbl_core.get_clin_servs_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list, NULL, sys_context('ALERT_CONTEXT', 'g_wtl_dcs_type_specialty') ) clin_serv,
pk_wtl_pbl_core.get_clin_servs_string(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_waiting_list, NULL, sys_context('ALERT_CONTEXT', 'g_wtl_dcs_type_ext_disc') ) ext_disc,
pk_sysdomain.get_domain('SCHEDULE_SR.ICU', schs.icu, sys_context('ALERT_CONTEXT', 'i_lang')) icu,
pk_sysdomain.get_domain('YES_NO', schs.adm_needed, sys_context('ALERT_CONTEXT', 'i_lang')) admission_need,
pk_sysdomain.get_domain('SURGERY_NEEDED', schs.adm_needed, sys_context('ALERT_CONTEXT', 'i_lang')) surgery_need,
pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient, schs.id_episode, schs.id_schedule) pat_name,
pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'), (SELECT gender FROM patient p WHERE p.id_patient = wtl.id_patient)) pat_gender,
pk_sysdomain.get_domain('PATIENT.GENDER', (SELECT p.gender FROM patient p WHERE p.id_patient = wtl.id_patient), sys_context('ALERT_CONTEXT', 'i_lang')) pat_gender_desc,
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), wtl.dt_dpb, profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) dt_dpb,
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), wtl.dt_dpa, profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) dt_dpa,
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), wtl.dt_surgery, profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) dt_surgery,
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), wtl.dt_admission, profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) dt_admission,
pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient) pat_ndo,
pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient) pat_nd_icon,
(SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), cr.code_cancel_reason)
FROM sch_cancel_reason cr
WHERE cr.id_sch_cancel_reason = s.id_cancel_reason)
FROM schedule s
WHERE s.id_schedule = schs.id_schedule) cancel_reason,
(SELECT wul.duration
FROM wtl_urg_level wul
WHERE wul.id_wtl_urg_level = wtl.id_wtl_urg_level) sk_urgency_level,
nvl((SELECT g.rank
FROM patient p
    INNER JOIN(SELECT * 
                FROM TABLE(pk_wtl_prv_core.get_sort_keys_children(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), 
sys_context('ALERT_CONTEXT', 'l_inst'), sys_context('ALERT_CONTEXT', 'l_wtlsk_gender')))) g ON g.VALUE = p.gender
    WHERE p.id_patient = wtl.id_patient), 0) sk_gender,
pk_utils.query_to_string('select id_prof from wtl_prof wp where wp.id_waiting_list = ' || wtl.id_waiting_list || ' and wp.flg_type = ''S'' and wp.flg_status = ''A''', ',') ids_pref_surgeons
FROM waiting_list wtl
INNER JOIN schedule_sr schs ON schs.id_waiting_list = wtl.id_waiting_list;
