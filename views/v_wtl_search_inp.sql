CREATE OR REPLACE VIEW V_WTL_SEARCH_INP AS
SELECT wtl.id_waiting_list, wtl.flg_type, we.id_schedule, trunc(pk_date_utils.diff_timestamp(wtl.dt_dpa, current_timestamp)) relative_urgency,
ar.expected_duration adm_exp_dur_hours, 
(SELECT nl.VALUE 
 FROM nch_level nl 
 WHERE nl.id_nch_level IN (SELECT ai.id_nch_level
                            FROM adm_indication ai
                            WHERE ai.id_adm_indication IN (ar.id_adm_indication))) nch_first,
(SELECT nl.duration
 FROM nch_level nl
 WHERE nl.id_nch_level IN (SELECT ai.id_nch_level
                            FROM adm_indication ai
                            WHERE ai.id_adm_indication IN (ar.id_adm_indication))) nch_change,
(SELECT nl.VALUE
 FROM nch_level nl
 WHERE nl.id_previous IN (SELECT ai.id_nch_level
                            FROM adm_indication ai
                            WHERE ai.id_adm_indication IN (ar.id_adm_indication))) nch_second,
decode((SELECT wep.flg_status 
        FROM wtl_epis wep
        WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery') 
        AND wep.id_waiting_list = we.id_waiting_list), 
        'S',  
        decode((SELECT scr.flg_temporary
                FROM schedule_sr scr
                WHERE scr.id_schedule = (SELECT wep.id_schedule
                                          FROM wtl_epis wep
                                          WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery') 
                                          AND wep.id_waiting_list = we.id_waiting_list)),
        'Y', 'T', 'S'),'N') flg_status, 
decode((SELECT wep.flg_status 
        FROM wtl_epis wep
        WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')
        AND wep.id_waiting_list = we.id_waiting_list),
        'S',
        decode((SELECT scr.flg_temporary 
                FROM schedule_sr scr 
                WHERE scr.id_schedule = (SELECT wep.id_schedule  
                                          FROM wtl_epis wep 
                                          WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')
                                          AND wep.id_waiting_list = we.id_waiting_list)), 
        'Y',
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS', 'T', sys_context('ALERT_CONTEXT', 'i_lang')),
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS', 'S', sys_context('ALERT_CONTEXT', 'i_lang'))),
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS', 'N', sys_context('ALERT_CONTEXT', 'i_lang'))) surg_status_desc,
decode((SELECT wep.flg_status 
        FROM wtl_epis wep
        WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')
          AND wep.id_waiting_list = we.id_waiting_list), 
        'S',
        decode((SELECT scr.flg_temporary
                FROM schedule_sr scr
                WHERE scr.id_schedule = (SELECT wep.id_schedule
                                          FROM wtl_epis wep
                                          WHERE wep.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')
                                          AND wep.id_waiting_list = we.id_waiting_list)), 
        'Y',
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS_SUMMARY', 'T', sys_context('ALERT_CONTEXT', 'i_lang')),
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS_SUMMARY', 'S', sys_context('ALERT_CONTEXT', 'i_lang'))),
        pk_sysdomain.get_domain('SR_SCHEDULE_STATUS_SUMMARY', 'N', sys_context('ALERT_CONTEXT', 'i_lang'))) surg_status_detail_desc,
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), 
                            (SELECT sr.dt_target_tstz
                            FROM schedule_sr sr
                            WHERE sr.id_schedule IN (SELECT wte.id_schedule
                                                      FROM wtl_epis wte
                                                      WHERE wte.id_waiting_list = we.id_waiting_list
                                                      AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery'))),
                            profissional(sys_context('ALERT_CONTEXT', 'i_prof'), 
                            sys_context('ALERT_CONTEXT', 'i_institution'), 
                            sys_context('ALERT_CONTEXT', 'i_software'))) surg_date,
(SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), i.code_institution)
  FROM institution i
  WHERE i.id_institution = (SELECT sr.id_institution
                            FROM schedule_sr sr
                            WHERE sr.id_schedule IN (SELECT wte.id_schedule
                                                      FROM wtl_epis wte
                                                      WHERE wte.id_waiting_list = we.id_waiting_list
                                                      AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')))) surg_location,
(SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room)
  FROM room r 
  WHERE r.id_room = (SELECT s.id_room 
                      FROM schedule s  
                      WHERE s.id_schedule = (SELECT wte.id_schedule 
                                              FROM wtl_epis wte 
                                              WHERE wte.id_waiting_list = we.id_waiting_list
                                              AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_surgery')))) surg_room,
ar.flg_mixed_nursing, 
decode(ar.flg_mixed_nursing, 
        'Y',
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ADM_REQUEST_T035'),
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ADM_REQUEST_T070')) mixed_nursing_desc,
decode(ar.flg_mixed_nursing, 
        'Y',
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'COMMON_M022'),
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'COMMON_M023')) mixed_nursing_detail_desc,
(SELECT s.flg_status 
  FROM schedule s 
  WHERE s.flg_status = 'C' 
    AND s.id_schedule IN ((SELECT wte.id_schedule 
                            FROM wtl_epis wte 
                            WHERE wte.id_waiting_list = we.id_waiting_list
                              AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_inpatient')))) flg_canceled, 
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), (SELECT (SELECT s.dt_cancel_tstz
                                                                              FROM sch_cancel_reason cr
                                                                              WHERE cr.id_sch_cancel_reason = s.id_cancel_reason)
                                                                      FROM schedule s
                                                                      WHERE s.flg_status = 'C'
                                                                        AND s.id_schedule IN ((SELECT wte.id_schedule
                                                                                                FROM wtl_epis wte
                                                                                                WHERE wte.id_waiting_list = we.id_waiting_list
                                                                                                AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_inpatient')))),
profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) cancel_date,
(SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), cr.code_cancel_reason) FROM sch_cancel_reason cr
WHERE cr.id_sch_cancel_reason = s.id_cancel_reason) FROM schedule s WHERE s.flg_status = 'C' AND s.id_schedule IN ((SELECT wte.id_schedule
FROM wtl_epis wte WHERE wte.id_waiting_list = we.id_waiting_list
AND wte.id_epis_type = sys_context('ALERT_CONTEXT', 'g_id_epis_type_inpatient')))) cancel_reason_desc, ar.id_dest_inst location_id,
(SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), i.code_institution) FROM institution i
WHERE i.id_institution = ar.id_dest_inst) location_name,
(SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), d.code_department)
FROM department d WHERE d.id_department = ar.id_department) ward_name, wtl.id_patient,
pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient, we.id_episode, we.id_schedule) pat_name,
pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'),
(SELECT p.gender
FROM patient p
WHERE p.id_patient = wtl.id_patient)) pat_gender,
pk_sysdomain.get_domain('PATIENT.GENDER',
(SELECT p.gender
FROM patient p
WHERE p.id_patient = wtl.id_patient),
sys_context('ALERT_CONTEXT', 'i_lang')) pat_gender_desc,
(SELECT p.age FROM patient p WHERE p.id_patient = wtl.id_patient) pat_age,                   
ar.id_adm_indication id_adm_indication, 
(SELECT 
pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ai.code_adm_indication) desc_adm_indication
FROM adm_indication ai
WHERE ai.id_adm_indication = ar.id_adm_indication) adm_indication_desc,                  
decode((SELECT ai.flg_escape
FROM adm_indication ai
WHERE ai.id_adm_indication = ar.id_adm_indication), 'A', 'Y',
/*pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'COMMON_M014'),*/
decode((SELECT ai.flg_escape
FROM adm_indication ai
WHERE ai.id_adm_indication = ar.id_adm_indication), 'N', 'N',
/*pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'COMMON_M023'),*/
pk_utils.concat_table(CAST(MULTISET
(SELECT d.id_department /*pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), d.code_department)*/
FROM department d
WHERE d.id_department IN
(SELECT ed.id_department
FROM escape_department ed
WHERE ed.id_adm_indication = ar.id_adm_indication)) AS
table_varchar),
', '))) ward_list,                   
pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), wtl.dt_dpa, profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software'))) dt_dpa,
wtl.id_external_request,                 
(wtl.dt_dpa - current_timestamp) sk_relative_urgency,
(wtl.dt_dpa - wtl.dt_placement) sk_absolute_urgency,
(current_timestamp - wtl.dt_placement) sk_waiting_time,
(SELECT wul.duration
FROM wtl_urg_level wul
WHERE wul.id_wtl_urg_level = wtl.id_wtl_urg_level) sk_urgency_level,
(wtl.func_eval_score * -1) sk_barthel,
nvl((SELECT g.rank
FROM patient p
INNER JOIN(sELECT * FROM TABLE(pk_wtl_prv_core.get_sort_keys_children(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), 
sys_context('ALERT_CONTEXT', 'l_inst'), sys_context('ALERT_CONTEXT', 'l_wtlsk_gender')))) g ON g.VALUE = p.gender
WHERE p.id_patient = wtl.id_patient), 0) sk_gender,
pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient) pat_ndo,
pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof'), sys_context('ALERT_CONTEXT', 'i_institution'), sys_context('ALERT_CONTEXT', 'i_software')), wtl.id_patient) pat_nd_icon,
(SELECT id_prof FROM wtl_prof wtlp WHERE wtlp.id_waiting_list = wtl.id_waiting_list AND wtlp.flg_type = 'A' AND wtlp.flg_status = 'A' AND rownum = 1) id_prof_admission
FROM waiting_list wtl
INNER JOIN wtl_epis we ON wtl.id_waiting_list = we.id_waiting_list
INNER JOIN adm_request ar ON we.id_episode = ar.id_dest_episode;
