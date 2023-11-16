CREATE OR REPLACE VIEW v_outpgridpatients AS
SELECT t.id_schedule id_schedule,
       t.id_patient id_patient,
       t.num_clin_record num_clin_record,
       t.id_episode id_episode,
       t.flg_ehr flg_ehr,
       t.dt_efectiv dt_efectiv,
       t.name name,
       t.name_to_sort name_to_sort,
       t.pat_ndo pat_ndo,
       t.pat_nd_icon pat_nd_icon,
       t.gender gender,
       t.pat_age pat_age,
       t.photo photo,
       t.flg_contact flg_contact,
       t.cons_type cons_type,
       t.dt_target dt_target,
       t.dt_schedule_begin dt_schedule_begin,
       t.flg_state flg_state,
       t.flg_sched flg_sched,
       t.img_state img_state,
       t.img_sched img_sched,
       t.flg_temp flg_temp,
       t.dt_server dt_server,
       t.desc_temp desc_temp,
       t.desc_drug_presc desc_drug_presc,
       t.desc_interv_presc desc_interv_presc,
       t.desc_analysis_req desc_analysis_req,
       t.desc_exam_req desc_exam_req,
       t.rank rank,
       pk_grid_amb.wr_call(i_lang, i_prof, t.wr_call, pk_gridfilter.get_strings('i_dt', i_lang, i_prof)) wr_call,
       t.doctor_name doctor_name,
       nvl(t.reason, t.visit_reason) reason,
       t.dt_begin dt_begin,
       t.visit_reason visit_reason,
       t.dt dt,
       t.therapeutic_doctor therapeutic_doctor,
       t.patient_presence patient_presence,
       t.resp_icon resp_icon,
       t.desc_room desc_room,
       pk_patient.get_designated_provider(i_lang, i_prof, t.id_patient, t.id_episode) designated_provider,
       t.flg_contact_type flg_contact_type,
       CASE
            WHEN t.flg_group_header = pk_alert_constant.get_yes() THEN
             pk_grid_amb.get_group_presence_icon(i_lang, i_prof, t.id_group, pk_alert_constant.get_no())
            ELSE
             pk_sysdomain.get_img(i_lang, pk_gridfilter.get_strings('g_domain_sch_presence'), t.flg_contact_type)
        END icon_contact_type,
       pk_sysdomain.get_domain(pk_gridfilter.get_strings('g_domain_sch_presence'), t.flg_contact_type, i_lang) presence_desc,
       t.name_prof name_prof,
       t.name_nurse name_nurse,
       t.prof_team prof_team,
       t.name_prof_tooltip name_prof_tooltip,
       t.name_nurse_tooltip name_nurse_tooltip,
       t.prof_team_tooltip prof_team_tooltip,
       t.desc_ana_exam_req desc_ana_exam_req,
       t.id_group id_group,
       t.flg_group_header flg_group_header,
       t.extend_icon extend_icon,
       t.prof_follow_add prof_follow_add,
       t.prof_follow_remove prof_follow_remove,
       t.sch_event_desc sch_event_desc,
       pk_gridfilter.get_strings('l_type_appoint_edition') flg_type_appoint_edition,
       t.i_lang i_lang,
       t.i_prof i_prof,
       t.id_professional id_professional,
       t.flg_status epis_status,
       t.epis_id_room epis_id_room,
       t.id_dep_clin_serv id_dep_clin_serv,
       id_dcs_requested id_dcs_requested,
       id_epis_type id_epis_type,
       t.software software,
       t.institution institution,
       t.prof_id prof_id
  FROM (
    SELECT  /*+ use_nl(sp s sg) index(ei(id_schedule)) index(e(id_episode)) index(sp(dt_target_tstz)) */
            sp.id_epis_type,
               s.id_schedule,
               sg.id_patient,
               (SELECT cr.num_clin_record
                  FROM clin_record cr
                 WHERE cr.id_patient = sg.id_patient
                   AND cr.id_institution = l_prof.institution
                   AND rownum < 2) num_clin_record,
               ei.id_episode id_episode,
               e.flg_ehr,
               CASE
                    WHEN ei.id_episode IS NOT NULL THEN
                     decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                            pk_gridfilter.get_strings('g_sched_scheduled'),
                            '',
                            pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, l_prof.institution, l_prof.software))
                    ELSE
                     NULL
                END dt_efectiv,
               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
               pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
               pk_patient.get_pat_gender(i_id_patient => sg.id_patient) gender,
               --(SELECT pk_sysdomain.get_domain(pk_gridfilter.get_strings('g_domain_pat_gender_abbr'), pat.gender, i_lang) gender           FROM patient pat          WHERE sg.id_patient = pat.id_patient) gender,
               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
               pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, l_prof.institution, l_prof.software) dt_schedule_begin,
               CASE pk_gridfilter.get_strings('g_type_appointment') -- i_type
                   WHEN 'D' THEN
                    decode(s.flg_status,
                           pk_gridfilter.get_strings('g_sched_canc'),
                           pk_gridfilter.get_strings('g_sched_canc'),
                           pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))
                   ELSE
                    pk_grid.get_pre_nurse_appointment(i_lang,
                                                      i_prof,
                                                      ei.id_dep_clin_serv,
                                                      e.flg_ehr,
                                                      pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))
               END flg_state,
               sp.flg_sched,
               decode(s.flg_status,
                      pk_gridfilter.get_strings('g_sched_canc'),
                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                      pk_sysdomain.get_ranked_img(pk_gridfilter.get_strings('g_schdl_outp_state_domain'),
                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_dep_clin_serv,
                                                                                    e.flg_ehr,
                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                    e.flg_ehr)),
                                                  i_lang)) img_state,
               pk_sysdomain.get_ranked_img(pk_gridfilter.get_strings('g_schdl_outp_sched_domain'), sp.flg_sched, i_lang) img_sched,
               'N' flg_temp,
               pk_gridfilter.get_strings('g_sysdate_char') dt_server,
               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                      pk_gridfilter.get_strings('g_sched_scheduled'),
                      '',
                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
               CASE
                    WHEN gt.id_episode IS NOT NULL THEN
                     pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                    ELSE
                     NULL
                END desc_drug_presc,
               CASE
                    WHEN gt.id_episode IS NOT NULL THEN
                     pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                            i_prof,
                                                            pk_grid.get_prioritary_task(i_lang,
                                                                                        i_prof,
                                                                                        gt.icnp_intervention,
                                                                                        pk_grid.get_prioritary_task(i_lang,
                                                                                                                    i_prof,
                                                                                                                    gt.nurse_activity,
                                                                                                                    pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                i_prof,
                                                                                                                                                pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                            i_prof,
                                                                                                                                                                            gt.intervention,
                                                                                                                                                                            gt.monitorization,
                                                                                                                                                                            NULL,
                                                                                                                                                                            pk_gridfilter.get_strings('g_flg_doctor')),
                                                                                                                                                gt.teach_req,
                                                                                                                                                NULL,
                                                                                                                                                pk_gridfilter.get_strings('g_flg_doctor')),
                                                                                                                    NULL,
                                                                                                                    pk_gridfilter.get_strings('g_flg_doctor')),
                                                                                        NULL,
                                                                                        pk_gridfilter.get_strings('g_flg_doctor')))
                    ELSE
                     NULL
                END desc_interv_presc,
               CASE
                    WHEN gt.id_episode IS NOT NULL THEN
                     pk_grid.visit_grid_task_str(i_lang,
                                                 i_prof,
                                                 e.id_visit,
                                                 pk_gridfilter.get_strings('g_task_analysis'),
                                                 pk_gridfilter.get_strings('i_prof_cat_type'))
                    ELSE
                     NULL
                END desc_analysis_req,
               CASE
                    WHEN gt.id_episode IS NOT NULL THEN
                     pk_grid.visit_grid_task_str(i_lang,
                                                 i_prof,
                                                 e.id_visit,
                                                 pk_gridfilter.get_strings('g_task_exam'),
                                                 pk_gridfilter.get_strings('i_prof_cat_type'))
                    ELSE
                     NULL
                END desc_exam_req,
               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                      i_prof,
                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                  i_prof,
                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                 i_prof,
                                                                                                                 e.id_visit,
                                                                                                                 pk_gridfilter.get_strings('g_task_analysis'),
                                                                                                                 pk_gridfilter.get_strings('i_prof_cat_type')),
                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                 i_prof,
                                                                                                                 e.id_visit,
                                                                                                                 pk_gridfilter.get_strings('g_task_exam'),
                                                                                                                 pk_gridfilter.get_strings('i_prof_cat_type')),
                                                                                  pk_gridfilter.get_strings('g_analysis_exam_icon_grid_rank'),
                                                                                  pk_gridfilter.get_strings('g_flg_doctor'))) desc_ana_exam_req,
               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                      pk_gridfilter.get_strings('g_sched_adm_disch'),
                      3,
                      pk_gridfilter.get_strings('g_sched_med_disch'),
                      2,
                      1) rank,
               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                       i_prof                      => i_prof,
                                       i_waiting_room_available    => pk_gridfilter.get_strings('l_waiting_room_available',
                                                                                                i_lang,
                                                                                                i_prof),
                                       i_waiting_room_sys_external => pk_gridfilter.get_strings('l_waiting_room_sys_external',
                                                                                                i_lang,
                                                                                                i_prof),
                                       i_id_episode                => ei.id_episode,
                                       i_flg_state                 => sp.flg_state,
                                       i_flg_ehr                   => e.flg_ehr,
                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
               pk_prof_utils.get_name(i_lang, ei.id_professional) doctor_name,
               pk_grid_amb.get_reason(i_lang => i_lang, i_id_schedule => s.id_schedule) reason,
               CASE
                    WHEN ei.id_episode IS NOT NULL THEN
                     pk_date_utils.date_send_tsz(i_lang,
                                                 decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                        pk_gridfilter.get_strings('g_sched_scheduled'),
                                                        NULL,
                                                        e.dt_begin_tstz),
                                                 l_prof.institution,
                                                 l_prof.software)
                    ELSE
                     NULL
                END dt_begin,
               CASE s.id_sch_event
                   WHEN to_number(pk_gridfilter.get_strings('g_sch_event_therap_decision')) THEN
                    pk_gridfilter.get_strings('l_therap_decision_consult')
                   ELSE
                    decode(pk_gridfilter.get_strings('l_reasongrid', i_lang, i_prof),
                           pk_alert_constant.get_yes(),
                           pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_episode,
                                                                                                       s.id_schedule),
                                                            4000))
               END visit_reason,
               sp.dt_target_tstz dt,
               CASE pk_gridfilter.get_strings('g_type_appointment') -- i_type
                   WHEN 'D' THEN
                    CASE s.id_sch_event
                        WHEN to_number(pk_gridfilter.get_strings('g_sch_event_therap_decision')) THEN
                         pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')'                    
                        ELSE
                         NULL
                    END
                   ELSE
                    decode(s.id_sch_event,
                           pk_gridfilter.get_strings('g_sch_event_therap_decision'),
                           '(' || pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')')
               END therapeutic_doctor,
               decode(s.flg_present, 'N', pk_gridfilter.get_strings('l_no_present_patient')) patient_presence,
               pk_hand_off_api.get_resp_icons(i_lang,
                                              i_prof,
                                              ei.id_episode,
                                              pk_gridfilter.get_strings('l_handoff_type', i_lang, i_prof)) resp_icon,
               CASE se.flg_is_group
                   WHEN 'N' THEN
                    decode(e.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room))
                   ELSE
                    NULL
               END desc_room,
               sg.flg_contact_type,
               pk_grid_amb.get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_gridfilter.get_strings('g_cat_type_doc'),
                                                ei.id_episode,
                                                nvl(ei.id_professional, spo.id_professional),
                                                pk_gridfilter.get_strings('l_handoff_type', i_lang, i_prof),
                                                'G') name_prof,
               CASE s.id_sch_event
                    WHEN to_number(pk_gridfilter.get_strings('g_sch_event_therap_decision')) THEN
                    -- Nurse name from resource
                     CASE
                         WHEN e.id_episode IS NULL
                              OR e.flg_ehr = pk_gridfilter.get_strings('g_flg_ehr_s') THEN
                          (SELECT pk_prof_utils.get_nickname(i_lang,
                                                             (SELECT sr.id_professional
                                                                FROM sch_resource sr
                                                               WHERE sr.id_schedule = s.id_schedule
                                                                 AND rownum = 1))
                             FROM dual)
                         ELSE
                          pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp)
                     END
                    ELSE
                    -- nurse name from sch_prof_outp
                     CASE
                         WHEN e.id_episode IS NULL
                              OR e.flg_ehr = pk_gridfilter.get_strings('g_flg_ehr_s') THEN
                          pk_prof_utils.get_nickname(i_lang, spo.id_professional)
                         ELSE
                          pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp)
                     END
                END name_nurse,
               -- Team name or Resident physician(s)
               decode(pk_gridfilter.get_strings('l_show_resident_physician', i_lang, i_prof),
                      pk_alert_constant.get_yes(),
                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                 i_prof,
                                                                 ei.id_episode,
                                                                 pk_gridfilter.get_strings('l_handoff_type',
                                                                                           i_lang,
                                                                                           i_prof),
                                                                 pk_gridfilter.get_strings('g_resident'),
                                                                 'G'),
                      pk_prof_teams.get_prof_current_team(i_lang,
                                                          i_prof,
                                                          e.id_department,
                                                          ei.id_software,
                                                          nvl(ei.id_professional, spo.id_professional),
                                                          ei.id_first_nurse_resp)) prof_team,               
               -- Display text in tooltips
               -- 1) Responsible physician(s)
               pk_grid_amb.get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_gridfilter.get_strings('g_cat_type_doc'),
                                                ei.id_episode,
                                                nvl(ei.id_professional, spo.id_professional),
                                                pk_gridfilter.get_strings('l_handoff_type', i_lang, i_prof),
                                                'T') name_prof_tooltip,
               -- 2) Responsible nurse
               pk_grid_amb.get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_gridfilter.get_strings('g_cat_type_nurse'),
                                                ei.id_episode,
                                                ei.id_first_nurse_resp,
                                                pk_gridfilter.get_strings('l_handoff_type', i_lang, i_prof),
                                                'T') name_nurse_tooltip,
               -- 3) Responsible team 
               pk_hand_off_core.get_team_str(i_lang,
                                             i_prof,
                                             e.id_department,
                                             ei.id_software,
                                             ei.id_professional,
                                             ei.id_first_nurse_resp,
                                             pk_gridfilter.get_strings('l_handoff_type', i_lang, i_prof),
                                             NULL) prof_team_tooltip,
               CASE se.flg_is_group
                   WHEN 'N' THEN
                    NULL
                   ELSE
                    s.id_group
               END id_group,
               CASE se.flg_is_group
                   WHEN 'N' THEN
                    pk_alert_constant.get_no()
                   ELSE
                    pk_alert_constant.get_yes()
               END flg_group_header,
               CASE se.flg_is_group
                   WHEN 'N' THEN
                    NULL
                   ELSE
                    'ExtendIcon'
               END extend_icon,
               CASE pk_gridfilter.get_strings('g_type_appointment') -- i_type
                   WHEN 'D' THEN
                    pk_alert_constant.get_no()
                   ELSE
                    decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                           pk_alert_constant.get_no(),
                           decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                   i_prof,
                                                                                                   ei.id_episode,
                                                                                                   pk_gridfilter.get_strings('i_prof_cat_type'),
                                                                                                   pk_gridfilter.get_strings('l_handoff_type',
                                                                                                                             i_lang,
                                                                                                                             i_prof),
                                                                                                   pk_alert_constant.get_yes()),
                                                               l_prof.id),
                                  -1,
                                  pk_alert_constant.get_yes(),
                                  pk_alert_constant.get_no()),
                           pk_alert_constant.get_no())
               END prof_follow_add,
               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
               pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc,
               l_prof.i_lang,
               l_prof.software,
               l_prof.institution,
               l_prof.id prof_id,
               l_prof.i_prof,
               spo.id_professional,
               e.flg_status,
               ei.id_room epis_id_room,
               ei.id_dep_clin_serv,
               s.id_dcs_requested,
               se.flg_is_group
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
           AND ei.id_patient = sg.id_patient
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
           AND e.flg_ehr != pk_gridfilter.get_strings('g_flg_ehr')
          LEFT JOIN sch_prof_outp spo
            ON spo.id_schedule_outp = sp.id_schedule_outp
          LEFT JOIN grid_task gt
            ON gt.id_episode = ei.id_episode
          JOIN (SELECT (sys_context('ALERT_CONTEXT', 'i_lang')) i_lang,
                      profissional((sys_context('ALERT_CONTEXT', 'i_prof_id')),
                                   (sys_context('ALERT_CONTEXT', 'i_institution')),
                                   (sys_context('ALERT_CONTEXT', 'i_software'))) i_prof,
                      (sys_context('ALERT_CONTEXT', 'i_institution')) institution,
                      (sys_context('ALERT_CONTEXT', 'i_software')) software,
                      (sys_context('ALERT_CONTEXT', 'i_prof_id')) id
                 FROM dual) l_prof
            ON ei.id_software = l_prof.software
           AND e.id_institution = l_prof.institution
         WHERE sp.id_software = l_prof.software
           AND sp.id_software = pk_gridfilter.get_strings('g_soft_outpatient')
           AND ((se.flg_is_group = 'N' AND
               decode(pk_gridfilter.get_strings('g_type_appointment'), 'D', s.id_sch_event, 0) !=
               pk_gridfilter.get_strings('g_sch_event_therap_decision')) OR
               (se.flg_is_group = 'Y' AND
               s.id_schedule IN
               (SELECT column_value
                    FROM TABLE(pk_grid_amb.get_sch_ids(l_prof.i_lang,
                                                       l_prof.i_prof,
                                                       pk_gridfilter.get_strings('g_type_appointment'))))))) t
 WHERE (pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) !=
       decode(t.id_epis_type,
               pk_gridfilter.get_strings('g_epis_type_nurse', i_lang, i_prof),
               pk_gridfilter.get_strings('g_sched_nurse_disch'),
               pk_gridfilter.get_strings('g_sched_adm_disch')) OR
       pk_gridfilter.get_strings('l_show_nurse_disch', i_lang, i_prof) = pk_alert_constant.get_yes())
   AND (pk_gridfilter.get_strings('l_show_med_disch', i_lang, i_prof) = pk_alert_constant.get_yes() OR
       (pk_gridfilter.get_strings('l_show_med_disch', i_lang, i_prof) = pk_alert_constant.get_no() AND
       pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) != pk_gridfilter.get_strings('g_sched_med_disch')));
/
       
