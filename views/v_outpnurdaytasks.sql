CREATE OR REPLACE VIEW v_outpnurdaytasks as 
            SELECT dt.id_schedule,
                   dt.id_patient,
                   dt.id_episode,
                   (SELECT cr.num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = dt.id_patient
                       AND cr.id_institution = i_prof_institution
                       AND rownum < 2) num_proc,
                   pk_patient.get_pat_name(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                   dt.gender,
                   pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                   (SELECT pk_episode.get_cs_desc(i_lang, i_prof, dt.id_episode)
                      FROM dual) cons_type,
                   (SELECT pk_sysdomain.get_domain( pk_gridfilter.get_strings('g_epis_flg_appointment_type'),
                                                   nvl(dt.flg_appointment_type, pk_gridfilter.get_strings('g_null_appointment_type')),
                                                   i_lang)
                      FROM dual) cont_type,
                   dt_begin_tstz dt_last_contact,
                   dt.flg_state,
                   dt.flg_sched,
                   decode(dt.id_epis_type,
                          pk_gridfilter.get_strings('g_epis_type_nurse',i_lang,i_prof),
                          pk_sysdomain.get_ranked_img(pk_gridfilter.get_strings('g_schdl_nurse_state_domain'), dt.flg_state, i_lang),
                          pk_sysdomain.get_ranked_img(pk_gridfilter.get_strings('g_schdl_outp_state_domain'),
                                                      pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                        i_prof,
                                                                                        dt.id_dep_clin_serv,
                                                                                        dt.flg_ehr,
                                                                                        dt.flg_state),
                                                      i_lang)) img_state,
                   decode(dt.drug_presc,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_drug_presc)) drug_presc,
                   decode(dt.interv_presc,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_interv_presc)) interv_presc,
                   decode(dt.monit, NULL, NULL, pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_monit)) monit,
                   decode(dt.nurse_act,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_nurse_act)) nurse_act,
                   NULL icnp_interv_presc,
                   pk_date_utils.date_send_tsz(i_date => current_timestamp,i_lang => i_lang,i_prof =>i_prof) dt_server,
                   pk_grid_amb.get_room_desc(i_lang, dt.id_room) room,
                   dt.wr_call,
                   decode(dt.id_epis_type, pk_gridfilter.get_strings('g_epis_type_nurse'), pk_alert_constant.get_yes(), pk_alert_constant.get_no()) flg_nurse,
                   pk_alert_constant.get_yes() flg_button_ok,
                   pk_alert_constant.get_no() flg_button_cancel,
                   pk_alert_constant.get_no() flg_button_detail,
                   pk_alert_constant.get_no() flg_cancel,
                   dt.flg_contact_type,
                   (SELECT pk_sysdomain.get_img(i_lang, pk_gridfilter.get_strings('g_domain_sch_presence'), dt.flg_contact_type)
                      FROM dual) icon_contact_type,
                   epis_dt
              FROM ( -- tasks to execute on episode of request
                     SELECT s.id_schedule,
                            sg.id_patient,
                            e.id_episode,
                            p.gender,
                            sp.id_epis_type,
                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                            sp.flg_sched,
                            --s.id_dcs_requested,
                            ei.id_dep_clin_serv,
                            e.flg_ehr,
                            pk_date_utils.date_send_tsz(i_date => e.dt_begin_tstz,i_lang => i_lang,i_prof =>i_prof) dt_begin_tstz,
                            e.flg_appointment_type,
                            nvl(ei.id_room, s.id_room) id_room,
                            sg.flg_contact_type,
                            decode(gtb.flg_drug, pk_alert_constant.get_yes(), pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'D')) drug_presc,
                            gt.drug_presc gt_drug_presc,
                            --NULL interv_presc,
                            --NULL gt_interv_presc,
                            decode(gtb.flg_interv, pk_alert_constant.get_yes(), pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'I')) interv_presc,
                            gt.intervention gt_interv_presc,
                            decode(gtb.flg_monitor, pk_alert_constant.get_yes(), pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'M')) monit,
                            gt.monitorization gt_monit,
                            decode(gtb.flg_nurse_act, pk_alert_constant.get_yes(), pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'N')) nurse_act,
                            gt.nurse_activity gt_nurse_act,
                            pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_waiting_room_available    => pk_gridfilter.get_strings('l_waiting_room_available',i_lang, i_prof),
                                                    i_waiting_room_sys_external => pk_gridfilter.get_strings('l_waiting_room_sys_external',i_lang, i_prof),
                                                    i_id_episode                => ei.id_episode,
                                                    i_flg_state                 => sp.flg_state,
                                                    i_flg_ehr                   => e.flg_ehr,
                                                    i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           i_lang,
                           i_prof,
                           l_prof.id i_prof_id,
                           l_prof.software i_prof_software,
                           l_prof.institution i_prof_institution,
                           e.dt_begin_tstz epis_dt
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON sp.id_schedule = s.id_schedule
                      JOIN sch_group sg
                        ON sp.id_schedule = sg.id_schedule
                      JOIN epis_info ei
                        ON sp.id_schedule = ei.id_schedule
                      JOIN sch_prof_outp ps
                        ON sp.id_schedule_outp = ps.id_schedule_outp
                      JOIN prof_dep_clin_serv pdcs
                        ON ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
                       AND s.id_instit_requested = pdcs.id_institution
                      JOIN patient p
                        ON sg.id_patient = p.id_patient
                      JOIN episode e
                        ON ei.id_episode = e.id_episode
                      JOIN grid_task_between gtb
                        ON ei.id_episode = gtb.id_episode
                      JOIN grid_task gt
                        ON ei.id_episode = gt.id_episode
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
                       AND s.flg_status != pk_gridfilter.get_strings('g_sched_status_cache') -- agendamentos temporários (SCH 3.0)
                       AND s.id_instit_requested = l_prof.institution
                       AND sp.id_epis_type IN (pk_sysconfig.get_config('EPIS_TYPE', i_prof), pk_gridfilter.get_strings('g_epis_type_nurse'))
                       AND pdcs.id_professional = l_prof.id
                       AND pdcs.flg_status = pk_gridfilter.get_strings('g_selected')
                       AND e.flg_ehr IN (pk_gridfilter.get_strings('g_flg_ehr_normal'), pk_gridfilter.get_strings('g_flg_ehr_s'))
                       AND e.flg_status IN
                           (pk_gridfilter.get_strings('g_epis_status_active'), pk_gridfilter.get_strings('g_epis_status_inactive'))
                       AND (pk_sysconfig.get_config('ENABLE_TEAM_FILTER_GRID', i_prof) = pk_alert_constant.get_no() OR
                           ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                                    k.column_value
                                                     FROM TABLE(pk_grid_amb.get_prof_team_det(i_prof)) k))
                    UNION ALL
                    -- tasks to execute on intervention episodes
                    SELECT ei.id_schedule,
                            p.id_patient,
                            e.id_episode,
                            p.gender,
                            e.id_epis_type,
                            NULL flg_state,
                            NULL flg_sched,
                            ei.id_dcs_requested,
                            e.flg_ehr,
                            --e.dt_begin_tstz,
                            pk_date_utils.date_send_tsz(i_date => e.dt_begin_tstz,i_lang => i_lang,i_prof =>i_prof) dt_begin_tstz,
                            e.flg_appointment_type,
                            ei.id_room,
                            NULL flg_contact_type,
                            NULL drug_presc,
                            NULL gt_drug_presc,
                            decode(gtb.flg_interv, pk_alert_constant.get_yes(), pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'I')) interv_presc,
                            gt.intervention gt_interv_presc,
                            NULL monit,
                            NULL gt_monit,
                            NULL nurse_act,
                            NULL gt_nurse_act,
                            pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_waiting_room_available    => pk_gridfilter.get_strings('l_waiting_room_available',i_lang, i_prof),
                                                    i_waiting_room_sys_external => pk_gridfilter.get_strings('l_waiting_room_sys_external',i_lang, i_prof),
                                                    i_id_episode                => ei.id_episode,
                                                    i_flg_state                 => sp.flg_state,
                                                    i_flg_ehr                   => e.flg_ehr,
                                                    i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           i_lang,
                           i_prof,
                           l_prof.id i_prof_id,
                           l_prof.software i_prof_software,
                           l_prof.institution i_prof_institution,
                           e.dt_begin_tstz epis_dt
                      FROM episode e
                      JOIN epis_info ei
                        ON e.id_episode = ei.id_episode
                      JOIN patient p
                        ON e.id_patient = p.id_patient
                      JOIN grid_task_between gtb
                        ON e.id_episode = gtb.id_episode
                      JOIN grid_task gt
                        ON e.id_episode = gt.id_episode
                      LEFT JOIN schedule s
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN schedule_outp sp
                        ON sp.id_schedule = s.id_schedule
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
                     WHERE e.id_epis_type = pk_gridfilter.get_strings('g_episode_type_interv')
                       AND e.flg_ehr IN (pk_gridfilter.get_strings('g_flg_ehr_normal'), pk_gridfilter.get_strings('g_flg_ehr_s'))
                       AND e.flg_status = pk_gridfilter.get_strings('g_epis_status_active')
                       AND e.id_institution = l_prof.institution
                       AND ei.id_software = l_prof.software) dt
             WHERE dt.drug_presc IS NOT NULL
                OR dt.interv_presc IS NOT NULL
                OR dt.monit IS NOT NULL
                OR dt.nurse_act IS NOT NULL
             ORDER BY pk_grid.min_dt_treatment(i_lang, 
                                               i_prof, 
                                               dt.id_episode);
