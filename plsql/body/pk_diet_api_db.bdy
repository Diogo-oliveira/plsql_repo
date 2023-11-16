/*-- Last Change Revision: $Rev: 2026964 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_diet_api_db IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_domain_pat_gender_abbr CONSTANT sys_domain.code_domain%TYPE := 'PATIENT.GENDER.ABBR';

    /*
    * Returns a list of diets for the crisis machine
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_search_interval   Search interval
    
    * @author    Jorge Silva
    * @version   2.6.1
    * @since     2013/02/26
    */

    FUNCTION tf_cm_diet_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
        l_func_name VARCHAR2(30) := 't_tbl_cm_episodes';
        l_tbl       t_tbl_cm_episodes;
    
        l_dt_begin_forward TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_forward   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_back    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_back      TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin_forward := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) - i_search_interval;
        l_dt_end_forward   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) + i_search_interval;
    
        l_dt_end_back   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) + i_search_interval;
        l_dt_begin_back := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) - i_search_interval;
    
        g_error := 'FILL t_tbl_cm_episodes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT t_rec_cm_episodes(t.id_episode,
                                 t.id_patient,
                                 t.id_schedule,
                                 t.dt_target,
                                 t.dt_last_interaction_tstz,
                                 t.id_software)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT o.id_episode_answer                   id_episode,
                       eo.id_patient                         id_patient,
                       ei.id_schedule                        id_schedule,
                       o.dt_last_update                      dt_target,
                       ei.dt_last_interaction_tstz           dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_nutritionist id_software
                  FROM opinion o
                  JOIN episode eo
                    ON o.id_episode = eo.id_episode
                  JOIN epis_info ei
                    ON eo.id_episode = ei.id_episode
                  LEFT JOIN opinion_prof op
                    ON o.id_opinion = op.id_opinion
                   AND op.flg_type IN (pk_opinion.g_opinion_prof_accept)
                  LEFT JOIN bed b
                    ON ei.id_bed = b.id_bed
                   AND b.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN room r
                    ON r.id_room = b.id_room
                   AND r.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN department dep
                    ON dep.id_department = r.id_department
                   AND dep.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN episode e
                    ON o.id_episode_answer = e.id_episode
                  LEFT JOIN discharge d
                    ON e.id_episode = d.id_episode
                   AND d.flg_status = pk_alert_constant.g_active
                 WHERE eo.id_institution = i_prof.institution
                   AND ((o.flg_state = pk_opinion.g_opinion_over AND d.dt_med_tstz BETWEEN l_dt_begin_forward AND
                       l_dt_end_forward) OR o.flg_state <> pk_opinion.g_opinion_over)
                   AND o.id_opinion_type = 1
                   AND (o.flg_state IN (pk_opinion.g_opinion_accepted))
                UNION ALL
                SELECT ei.id_episode,
                       ei.id_patient,
                       sp.id_schedule,
                       sp.dt_target_tstz                     dt_target,
                       ei.dt_last_interaction_tstz           dt_last_interaction_tstz,
                       pk_alert_constant.g_soft_nutritionist id_software
                  FROM schedule_outp sp, schedule s, sch_group sg, epis_info ei, epis_type et, episode e
                 WHERE ((sp.dt_target_tstz BETWEEN l_dt_begin_back AND l_dt_end_back AND
                       sp.flg_state <> pk_grid_amb.g_sched_scheduled) OR
                       (sp.dt_target_tstz BETWEEN l_dt_begin_forward AND l_dt_end_forward AND
                       sp.flg_state = pk_grid_amb.g_sched_scheduled))
                   AND ei.id_episode = e.id_episode(+)
                   AND sp.id_software = i_prof.software
                   AND s.id_schedule = sp.id_schedule
                   AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, pk_grid_amb.g_sched_canc)
                   AND s.id_instit_requested = i_prof.institution
                   AND sg.id_schedule = s.id_schedule
                   AND ei.id_schedule(+) = s.id_schedule
                   AND sp.id_epis_type = et.id_epis_type) t;
    
        RETURN l_tbl;
    
    END tf_cm_diet_episodes;

    /*
    * Returns a list of details diets for the crisis machine
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_episode    Episode id
    * @param     i_schedule   Schedule id
    
    * @author    Jorge Silva
    * @version   2.6.1
    * @since     2013/02/26
    */
    FUNCTION tf_cm_diet_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_diet_episodes IS
        l_tbl_diet_episodes t_tbl_diet_episodes;
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        SELECT t_rec_diet_episodes(id_episode,
                                   id_schedule,
                                   id_patient,
                                   origin,
                                   origin_desc,
                                   pat_name,
                                   pat_name_sort,
                                   pat_age,
                                   pat_gender,
                                   photo,
                                   num_clin_record,
                                   diagnosis_desc,
                                   service_desc,
                                   room_desc,
                                   bed_desc,
                                   name_prof_resp,
                                   name_prof_req,
                                   reason_req,
                                   dt_target,
                                   dt_target_tstz,
                                   dt_next_followup,
                                   dt_next_followup_tstz,
                                   flg_request_type,
                                   flg_status,
                                   flg_status_desc,
                                   flg_status_icon,
                                   desc_status,
                                   id_type_appointment,
                                   flg_type_appointment_desc,
                                   rank_acuity,
                                   acuity)
          BULK COLLECT
          INTO l_tbl_diet_episodes
          FROM (SELECT o.id_episode_answer id_episode,
                       ei.id_schedule id_schedule,
                       p.id_patient,
                       et.id_epis_type origin,
                       decode(o.flg_auto_follow_up,
                              pk_alert_constant.get_yes,
                              pk_message.get_message(i_lang, 'COMMON_M036'),
                              pk_message.get_message(i_lang,
                                                     profissional(i_prof.id, i_prof.institution, ei.id_software),
                                                     'IMAGE_T009')) origin_desc,
                       pk_patient.get_pat_name(i_lang, i_prof, eo.id_patient, e.id_episode, NULL) pat_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, eo.id_patient, e.id_episode, NULL) pat_name_sort,
                       pk_patient.get_pat_age(i_lang, eo.id_patient, i_prof) pat_age,
                       (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang)
                          FROM dual) pat_gender,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, eo.id_patient, e.id_episode, NULL) photo,
                       (SELECT cr.num_clin_record
                          FROM clin_record cr
                         WHERE cr.id_patient = eo.id_patient
                           AND cr.id_institution = i_prof.institution
                           AND rownum < 2) num_clin_record,
                       pk_diagnosis.get_epis_diagnosis(i_lang, o.id_episode) diagnosis_desc,
                       pk_translation.get_translation(i_lang, dep.code_department) service_desc,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc,
                       nvl(decode(b.flg_type, pk_bmng_constant.g_bmng_bed_flg_type_t, b.desc_bed),
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))) bed_desc,
                       decode(eid.id_professional,
                              NULL,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                              pk_prof_utils.get_name_signature(i_lang, i_prof, eid.id_professional)) name_prof_resp,
                       decode(o.flg_auto_follow_up,
                              pk_alert_constant.get_yes,
                              '',
                              pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions)) name_prof_req,
                       decode(o.flg_auto_follow_up,
                              pk_alert_constant.get_yes,
                              pk_message.get_message(i_lang, 'COMMON_M036'),
                              o.desc_problem) reason_req,
                       '' dt_target,
                       NULL dt_target_tstz,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   pk_paramedical_prof_core.get_dt_next_enc(e.id_episode),
                                                   i_prof) dt_next_followup_tstz,
                       pk_date_utils.date_time_chr_tsz(i_lang,
                                                       pk_paramedical_prof_core.get_dt_next_enc(e.id_episode),
                                                       i_prof) dt_next_followup,
                       'F' flg_request_type,
                       o.flg_state flg_status,
                       (SELECT pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang)
                          FROM dual) flg_status_desc,
                       '' flg_status_icon,
                       pk_paramedical_prof_core.get_req_status_str(i_lang, i_prof, o.flg_state, o.dt_last_update) desc_status,
                       NULL id_type_appointment,
                       '' flg_type_appointment_desc,
                       decode(decode(eo.id_epis_type,
                                     pk_alert_constant.g_epis_type_emergency,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_yes,
                              ei.triage_rank_acuity) rank_acuity,
                       decode(decode(eo.id_epis_type,
                                     pk_alert_constant.g_epis_type_emergency,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_yes,
                              ei.triage_acuity) acuity
                  FROM opinion o
                  JOIN episode eo
                    ON o.id_episode = eo.id_episode
                  JOIN patient p
                    ON eo.id_patient = p.id_patient
                  JOIN epis_type et
                    ON eo.id_epis_type = et.id_epis_type
                  JOIN epis_info ei
                    ON eo.id_episode = ei.id_episode
                  LEFT JOIN opinion_prof op
                    ON o.id_opinion = op.id_opinion
                   AND op.flg_type IN (pk_opinion.g_opinion_prof_accept, pk_opinion.g_opinion_prof_reject)
                  LEFT JOIN episode e
                    ON o.id_episode_answer = e.id_episode
                  LEFT JOIN epis_info eid
                    ON e.id_episode = eid.id_episode
                  LEFT JOIN bed b
                    ON ei.id_bed = b.id_bed
                   AND b.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN room r
                    ON r.id_room = b.id_room
                   AND r.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN department dep
                    ON dep.id_department = r.id_department
                   AND dep.flg_available = pk_alert_constant.g_yes
                  LEFT JOIN discharge d
                    ON e.id_episode = d.id_episode
                   AND d.flg_status = pk_alert_constant.g_active
                 WHERE eo.id_institution = i_prof.institution
                   AND o.id_opinion_type = 1
                   AND e.id_episode = nvl(i_episode,
                                          (SELECT MAX(id_episode)
                                             FROM epis_info ei2
                                            WHERE ei2.id_schedule = i_schedule))
                UNION ALL
                SELECT ei.id_episode,
                       sp.id_schedule,
                       sg.id_patient,
                       et.id_epis_type origin,
                       pk_message.get_message(i_lang,
                                              profissional(i_prof.id, i_prof.institution, ei.id_software),
                                              'IMAGE_T009') origin_desc,
                       pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) pat_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) pat_name_sort,
                       pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                       (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                          FROM patient pat
                         WHERE sg.id_patient = pat.id_patient) pat_gender,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                       (SELECT cr.num_clin_record
                          FROM clin_record cr
                         WHERE cr.id_patient = sg.id_patient
                           AND cr.id_institution = i_prof.institution
                           AND rownum < 2) num_clin_record,
                       '' diagnosis_desc,
                       '' service_desc,
                       '' room_desc,
                       '' bed_desc,
                       nvl((SELECT nvl(p.nick_name, p.name)
                             FROM professional p
                            WHERE p.id_professional = ei.id_professional),
                           (SELECT nvl(p.nick_name, p.name)
                              FROM sch_prof_outp ps, professional p
                             WHERE ps.id_schedule_outp = sp.id_schedule_outp
                               AND p.id_professional = ps.id_professional
                               AND rownum < 2)) name_prof_resp,
                       (SELECT nvl(p.nick_name, p.name)
                          FROM professional p
                         WHERE p.id_professional = s.id_prof_schedules) name_prof_req,
                       s.reason_notes reason_req,
                       pk_date_utils.date_time_chr_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                       pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target_tstz,
                       '' dt_next_followup,
                       NULL dt_next_followup_tstz,
                       'S' flg_request_type,
                       decode(s.flg_status,
                              pk_grid_amb.g_sched_canc,
                              pk_grid_amb.g_sched_canc,
                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_status,
                       '' flg_status_desc,
                       pk_sysdomain.get_img(i_lang,
                                            pk_grid_amb.g_schdl_outp_state_domain,
                                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_status_icon,
                       '' desc_status,
                       s.id_dcs_requested id_type_appointment,
                       pk_hea_prv_aux.get_clin_service(i_lang, i_prof, s.id_dcs_requested) flg_type_appointment_desc, --
                       '' acuity,
                       '' rank_auity
                  FROM schedule_outp sp, schedule s, sch_group sg, epis_info ei, epis_type et, episode e
                 WHERE ei.id_episode = e.id_episode(+)
                   AND sp.id_software = i_prof.software
                   AND s.id_schedule = sp.id_schedule
                   AND s.id_instit_requested = i_prof.institution
                   AND sg.id_schedule = s.id_schedule
                   AND ei.id_schedule(+) = s.id_schedule
                   AND sp.id_epis_type = et.id_epis_type
                   AND e.id_episode = nvl(i_episode,
                                          (SELECT MAX(id_episode)
                                             FROM epis_info ei2
                                            WHERE ei2.id_schedule = i_schedule)));
        RETURN l_tbl_diet_episodes;
    END tf_cm_diet_episode_detail;

    FUNCTION inactivate_diet_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
        IF NOT pk_diet.inactivate_diet_tasks(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_inst        => i_inst,
                                             i_ids_exclude => l_tbl_ids,
                                             o_has_error   => o_has_error,
                                             o_error       => o_error)
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
                                              'INACTIVATE_DIET_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_diet_tasks;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_diet_api_db;
/
