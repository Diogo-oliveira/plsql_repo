/*-- Last Change Revision: $Rev: 2027610 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_external_api_db IS

    g_exception EXCEPTION;

    FUNCTION get_rehab_list_to_be_scheduled
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_REHAB.GET_PENDING_SHC_NEEDS_GRID';
    
        IF NOT
            pk_rehab.get_pending_sch_needs_grid(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
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
                                              'GET_REHAB_LIST_TO_BE_SCHEDULED',
                                              o_error);
        
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
        
    END get_rehab_list_to_be_scheduled;

    /**************************************************************************
    * gets all rehab episodes for a specific time interval elegible in        *
    * crisis machine generation                                               *
    *                                                                         *
    * @param  i_lang                preferred language id                     *
    * @param  i_prof                Professional struture                     *
    * @param  i_dt_begin            Begin date interval                       *
    * @param  i_dt_end              End date interval                         *
    *                                                                         *
    * @return t_tbl_cm_episodes     collection                                *
    *                                                                         *
    * @author                       Gustavo Serrano                           *
    * @version                      v2.6.1                                    *
    * @since                        2012/05/21                                *
    **************************************************************************/
    FUNCTION tf_cm_rehab_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
        l_func_name VARCHAR2(30) := 't_tbl_cm_episodes';
        l_tbl       t_tbl_cm_episodes;
    
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
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
          FROM (SELECT DISTINCT nvl(re.id_episode_rehab, e.id_episode) id_episode,
                                e.id_patient,
                                rs.id_schedule,
                                s.dt_begin_tstz dt_target,
                                ei.dt_last_interaction_tstz,
                                pk_alert_constant.g_soft_rehab id_software
                  FROM rehab_schedule rs
                 INNER JOIN schedule s
                    ON s.id_schedule = rs.id_schedule
                 INNER JOIN rehab_sch_need rsn
                    ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
                 INNER JOIN rehab_session_type rst
                    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                 INNER JOIN rehab_plan rp
                    ON rp.id_episode_origin = rsn.id_episode_origin
                 INNER JOIN episode e
                    ON e.id_episode = rsn.id_episode_origin
                 INNER JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                  LEFT JOIN bed bd
                    ON bd.id_bed = ei.id_bed
                  LEFT JOIN room ro
                    ON ro.id_room = bd.id_room
                  LEFT JOIN department dpt
                    ON dpt.id_department = ro.id_department
                  LEFT JOIN rehab_epis_encounter re
                    ON (re.id_episode_origin = e.id_episode AND re.id_rehab_sch_need = rsn.id_rehab_sch_need)
                 WHERE s.dt_begin_tstz BETWEEN trunc(g_sysdate_tstz) AND g_sysdate_tstz + i_search_interval
                   AND s.id_instit_requested = i_prof.institution
                   AND rs.flg_status = pk_rehab.g_rehab_schedule_scheduled
                   AND s.flg_status != pk_schedule.g_sched_status_temporary
                   AND s.flg_status != pk_schedule.g_sched_status_cache
                UNION ALL
                -- pacientes com tratamentos sem agendamento
                SELECT DISTINCT e.id_episode,
                                e.id_patient,
                                NULL                           id_schedule,
                                NULL                           dt_target,
                                ei.dt_last_interaction_tstz,
                                pk_alert_constant.g_soft_rehab id_software
                  FROM rehab_presc rp
                 INNER JOIN rehab_sch_need rsn
                    ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                 INNER JOIN rehab_session_type rst
                    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                 INNER JOIN rehab_plan rbp
                    ON rbp.id_episode_origin = rsn.id_episode_origin
                 INNER JOIN episode e
                    ON e.id_episode = rsn.id_episode_origin -- falta este episódio
                 INNER JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                  LEFT JOIN rehab_epis_encounter re
                    ON (re.id_episode_origin = e.id_episode AND re.id_rehab_sch_need = rsn.id_rehab_sch_need)
                  LEFT JOIN bed bd
                    ON bd.id_bed = ei.id_bed
                  LEFT JOIN room ro
                    ON ro.id_room = bd.id_room
                  LEFT JOIN department dpt
                    ON dpt.id_department = ro.id_department
                  JOIN rehab_area_interv rai
                    ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
                 WHERE rsn.flg_status = pk_rehab.g_rehab_sch_need_no_sched
                   AND rp.flg_status <> pk_rehab.g_rehab_presc_referral
                   AND rp.id_institution = i_prof.institution
                   AND ei.dt_last_interaction_tstz BETWEEN g_sysdate_tstz - i_search_interval AND g_sysdate_tstz
                --Rehab_appointments scheduled
                UNION ALL
                SELECT DISTINCT e.id_episode                   id_episode,
                                e.id_patient,
                                s.id_schedule                  id_schedule,
                                sp.dt_target_tstz              dt_target,
                                ei.dt_last_interaction_tstz,
                                pk_alert_constant.g_soft_rehab id_software
                  FROM schedule_outp sp
                 INNER JOIN schedule s
                    ON s.id_schedule = sp.id_schedule
                 INNER JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                 INNER JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                 INNER JOIN epis_type et
                    ON sp.id_epis_type = et.id_epis_type
                 INNER JOIN episode e
                    ON ei.id_episode = e.id_episode
                 WHERE s.flg_sch_type = 'CR'
                   AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                   AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != pk_grid_amb.g_sched_adm_disch
                   AND s.flg_status != pk_alert_constant.g_flg_status_c
                   AND s.id_instit_requested = i_prof.institution
                   AND sp.id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment
                   AND sp.dt_target_tstz BETWEEN trunc(g_sysdate_tstz) AND g_sysdate_tstz + i_search_interval
                   AND NOT EXISTS (SELECT 1
                          FROM rehab_epis_encounter re
                         WHERE re.id_episode_origin = e.id_episode)
                --Rehab_appointments effectivated
                UNION ALL
                SELECT DISTINCT e.id_episode                   id_episode,
                                e.id_patient,
                                s.id_schedule                  id_schedule,
                                sp.dt_target_tstz              dt_target,
                                ei.dt_last_interaction_tstz,
                                pk_alert_constant.g_soft_rehab id_software
                  FROM schedule_outp sp
                 INNER JOIN schedule s
                    ON s.id_schedule = sp.id_schedule
                 INNER JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                 INNER JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                 INNER JOIN epis_type et
                    ON sp.id_epis_type = et.id_epis_type
                 INNER JOIN episode e
                    ON ei.id_episode = e.id_episode
                 WHERE s.flg_sch_type = 'CR'
                   AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                   AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != pk_grid_amb.g_sched_adm_disch
                   AND s.flg_status != pk_alert_constant.g_flg_status_c
                   AND s.id_instit_requested = i_prof.institution
                   AND sp.id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment
                   AND ei.dt_last_interaction_tstz BETWEEN g_sysdate_tstz - i_search_interval AND g_sysdate_tstz
                   AND EXISTS (SELECT 1
                          FROM rehab_epis_encounter re
                         WHERE re.id_episode_origin = e.id_episode)
                UNION ALL
                -- planos de reabilitacao
                SELECT DISTINCT nvl(re.id_episode_rehab, e.id_episode) id_episode,
                                e.id_patient,
                                NULL id_schedule,
                                NULL dt_target,
                                ei.dt_last_interaction_tstz,
                                pk_alert_constant.g_soft_rehab id_software
                  FROM rehab_epis_plan rep
                 INNER JOIN episode e
                    ON (e.id_episode = nvl((SELECT DISTINCT ree.id_episode_origin
                                             FROM rehab_epis_encounter ree
                                            WHERE ree.id_episode_rehab = rep.id_episode),
                                           rep.id_episode) AND e.id_institution = i_prof.institution)
                 INNER JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                  LEFT JOIN bed bd
                    ON bd.id_bed = ei.id_bed
                  LEFT JOIN room ro
                    ON ro.id_room = bd.id_room
                  LEFT JOIN department dpt
                    ON dpt.id_department = ro.id_department
                  LEFT JOIN rehab_epis_encounter re
                    ON (re.id_episode_origin = e.id_episode)
                 WHERE e.id_episode NOT IN (SELECT rsn.id_episode_origin
                                              FROM rehab_sch_need rsn)
                   AND rep.flg_status = 'O') t;
    
        RETURN l_tbl;
    END tf_cm_rehab_episodes;

    /**************************************************************************
    * gets all rehab episodes for a specific time interval elegible in        *
    * crisis machine generation                                               *
    *                                                                         *
    * @param  i_lang                preferred language id                     *
    * @param  i_prof                Professional struture                     *
    * @param  i_episode             Episode identifier                        *
    *                                                                         *
    * @return t_tbl_rehab_episodes  collection                                *
    *                                                                         *
    * @author                       Gustavo Serrano                           *
    * @version                      v2.6.1                                    *
    * @since                        2012/05/21                                *
    **************************************************************************/
    FUNCTION tf_cm_rehab_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_rehab_episodes IS
    
        l_func_name VARCHAR2(30) := 'tf_cm_rehab_episode_detail';
        l_tbl       t_tbl_rehab_episodes;
    
        l_session_with_schedule    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'REHAB_T146');
        l_session_without_schedule sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'REHAB_T147');
        l_appointment              sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'REHAB_T148');
    
        l_prof_resp NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CM_FLG_SHOW_VIPS', i_prof => i_prof);
    
    BEGIN
        g_error        := 'Set g_sysdate';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Fill t_tbl_rehab_episodes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t_rec_rehab_episodes(t.id_episode,
                                    t.id_schedule,
                                    t.origin,
                                    t.pat_name,
                                    t.pat_name_sort,
                                    t.pat_age,
                                    t.pat_gender,
                                    t.photo,
                                    t.num_clin_record,
                                    t.name_prof,
                                    t.desc_session_type,
                                    t.desc_schedule_type,
                                    t.servico,
                                    t.desc_room,
                                    t.bed_name,
                                    t.dt_target,
                                    t.dt_target_tstz)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT r.id_episode,
                       r.id_schedule,
                       pk_sysdomain.get_domain('EPIS_EXT_SYS.EPIS_INFO_SOFT_DESC',
                                               pk_episode.get_soft_by_epis_type(i_epis_type   => pk_episode.get_epis_type(i_lang    => i_lang,
                                                                                                                          i_id_epis => nvl(r.id_episode_origin,
                                                                                                                                           r.id_episode)),
                                                                                i_institution => r.id_institution),
                                               i_lang) origin,
                       pk_adt.get_patient_name(i_lang, i_prof, r.id_patient, l_prof_resp) pat_name,
                       pk_adt.get_patient_name_to_sort(i_lang, i_prof, r.id_patient, l_prof_resp) pat_name_sort,
                       pk_patient.get_pat_age(i_lang, r.id_patient, i_prof) pat_age,
                       pk_patient.get_pat_gender(r.id_patient) pat_gender,
                       NULL photo,
                       (SELECT cr.num_clin_record
                          FROM clin_record cr
                         WHERE cr.id_patient = r.id_patient
                           AND cr.id_institution = r.id_institution
                           AND rownum < 2) num_clin_record,
                       pk_prof_utils.get_nickname(i_lang, r.id_professional) name_prof,
                       CASE r.id_epis_type
                           WHEN pk_alert_constant.g_epis_type_rehab_appointment THEN
                            l_appointment
                           WHEN pk_alert_constant.g_epis_type_rehab_session THEN
                            CASE r.flg_status
                                WHEN 'S' THEN
                                 l_session_with_schedule
                                ELSE
                                 l_session_without_schedule
                            END
                           WHEN pk_alert_constant.g_epis_type_inpatient THEN
                            l_session_without_schedule
                           WHEN pk_alert_constant.g_epis_type_outpatient THEN
                            l_session_with_schedule
                           ELSE
                            NULL
                       END desc_session_type,
                       CASE r.id_epis_type
                            WHEN pk_alert_constant.g_epis_type_rehab_appointment THEN
                             NULL
                            WHEN pk_alert_constant.g_epis_type_rehab_session THEN
                             CASE r.flg_status
                                 WHEN 'S' THEN
                                  pk_translation.get_translation(i_lang, r.code_rehab_session_type)
                                 ELSE
                                  CASE
                                      WHEN (r.id_rehab_epis_plan IS NOT NULL) THEN
                                       pk_message.get_message(i_lang, 'REHAB_M050')
                                      ELSE
                                       pk_translation.get_translation(i_lang, r.code_rehab_session_type)
                                  END
                             END
                            WHEN pk_alert_constant.g_epis_type_inpatient THEN
                             pk_translation.get_translation(i_lang, r.code_rehab_session_type)
                            WHEN pk_alert_constant.g_epis_type_outpatient THEN
                             pk_translation.get_translation(i_lang, r.code_rehab_session_type)
                            ELSE
                             NULL
                        END desc_schedule_type,
                       decode(r.code_bed,
                              NULL,
                              NULL,
                              nvl(r.abbreviation, pk_translation.get_translation(i_lang, r.code_department))) servico,
                       nvl(nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)),
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))) desc_room,
                       nvl(r.desc_bed, pk_translation.get_translation(i_lang, r.code_bed)) bed_name,
                       pk_date_utils.date_time_chr_tsz(i_lang, r.dt_begin_tstz, i_prof) dt_target,
                       pk_date_utils.date_send_tsz(i_lang, r.dt_begin_tstz, i_prof) dt_target_tstz
                  FROM (
                        -- pacientes com tratamentos com agendamento
                        SELECT DISTINCT nvl(re.id_episode_rehab, epis.id_episode) id_episode,
                                         s.id_schedule,
                                         rsn.id_episode_origin,
                                         epis.id_institution,
                                         epis.id_patient,
                                         ei.id_professional,
                                         epis.id_epis_type,
                                         rsn.flg_status,
                                         rst.code_rehab_session_type,
                                         bd.code_bed,
                                         dpt.abbreviation,
                                         dpt.code_department,
                                         ro.desc_room_abbreviation,
                                         ro.code_abbreviation,
                                         ro.desc_room,
                                         ro.code_room,
                                         bd.desc_bed,
                                         s.dt_begin_tstz,
                                         NULL id_rehab_epis_plan
                          FROM rehab_schedule rs
                         INNER JOIN schedule s
                            ON s.id_schedule = rs.id_schedule
                         INNER JOIN rehab_sch_need rsn
                            ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
                         INNER JOIN rehab_session_type rst
                            ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                         INNER JOIN rehab_plan rp
                            ON rp.id_episode_origin = rsn.id_episode_origin
                         INNER JOIN episode epis
                            ON epis.id_episode = rsn.id_episode_origin
                         INNER JOIN epis_info ei
                            ON ei.id_episode = epis.id_episode
                          LEFT JOIN bed bd
                            ON bd.id_bed = ei.id_bed
                          LEFT JOIN room ro
                            ON ro.id_room = bd.id_room
                          LEFT JOIN department dpt
                            ON dpt.id_department = ro.id_department
                          LEFT JOIN rehab_epis_encounter re
                            ON (re.id_episode_origin = epis.id_episode AND re.id_rehab_sch_need = rsn.id_rehab_sch_need)
                         WHERE s.id_instit_requested = i_prof.institution
                           AND rs.flg_status = pk_rehab.g_rehab_schedule_scheduled
                           AND s.flg_status != pk_schedule.g_sched_status_temporary
                           AND s.flg_status != pk_schedule.g_sched_status_cache
                           AND s.id_schedule = i_schedule
                        UNION ALL
                        -- pacientes com tratamentos sem agendamento
                        SELECT DISTINCT epis.id_episode,
                                         ei.id_schedule,
                                         rsn.id_episode_origin,
                                         epis.id_institution,
                                         epis.id_patient,
                                         ei.id_professional,
                                         epis.id_epis_type,
                                         rsn.flg_status,
                                         rst.code_rehab_session_type,
                                         bd.code_bed,
                                         dpt.abbreviation,
                                         dpt.code_department,
                                         ro.desc_room_abbreviation,
                                         ro.code_abbreviation,
                                         ro.desc_room,
                                         ro.code_room,
                                         bd.desc_bed,
                                         NULL                        dt_begin_tstz,
                                         NULL                        id_rehab_epis_plan
                          FROM rehab_presc rp
                          JOIN rehab_sch_need rsn
                            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                          JOIN rehab_session_type rst
                            ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                          JOIN rehab_plan rbp
                            ON rbp.id_episode_origin = rsn.id_episode_origin
                          JOIN episode epis
                            ON epis.id_episode = rsn.id_episode_origin -- falta este episódio
                          JOIN epis_info ei
                            ON ei.id_episode = epis.id_episode
                          LEFT JOIN rehab_epis_encounter re
                            ON (re.id_episode_origin = epis.id_episode AND re.id_rehab_sch_need = rsn.id_rehab_sch_need)
                          LEFT JOIN bed bd
                            ON bd.id_bed = ei.id_bed
                          LEFT JOIN room ro
                            ON ro.id_room = bd.id_room
                          LEFT JOIN department dpt
                            ON dpt.id_department = ro.id_department
                          JOIN rehab_area_interv rai
                            ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
                         WHERE rsn.flg_status = pk_rehab.g_rehab_sch_need_no_sched
                           AND rp.flg_status <> pk_rehab.g_rehab_presc_referral
                              --epis_origin activo
                              --AND epis.flg_status = pk_alert_constant.g_active
                           AND rp.id_institution = i_prof.institution
                           AND epis.id_episode = i_episode
                        UNION ALL
                        --Consultas de fisioterapia
                        SELECT DISTINCT t.id_episode,
                                         t.id_schedule,
                                         NULL              id_episode_origin,
                                         t.id_institution,
                                         t.id_patient,
                                         t.id_professional,
                                         t.id_epis_type,
                                         NULL              flg_status,
                                         NULL              code_rehab_session_type,
                                         NULL              code_bed,
                                         NULL              abbreviation,
                                         NULL              code_department,
                                         NULL              desc_room_abbreviation,
                                         NULL              code_abbreviation,
                                         NULL              desc_room,
                                         NULL              code_room,
                                         NULL              desc_bed,
                                         t.dt_begin_tstz,
                                         NULL              id_rehab_epis_plan
                          FROM (SELECT epis.id_episode,
                                        s.id_schedule,
                                        epis.id_institution,
                                        epis.id_patient,
                                        ei.id_professional,
                                        epis.id_epis_type,
                                        s.dt_begin_tstz,
                                        sp.flg_state,
                                        epis.flg_ehr
                                   FROM schedule_outp sp
                                  INNER JOIN schedule s
                                     ON s.id_schedule = sp.id_schedule
                                  INNER JOIN sch_group sg
                                     ON sg.id_schedule = s.id_schedule
                                  INNER JOIN epis_info ei
                                     ON s.id_schedule = ei.id_schedule
                                  INNER JOIN episode epis
                                     ON ei.id_episode = epis.id_episode
                                  WHERE s.id_schedule = i_schedule
                                    AND epis.id_institution = i_prof.institution
                                    AND s.flg_sch_type = 'CR'
                                    AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                                    AND s.flg_status != pk_alert_constant.g_flg_status_c
                                    AND s.id_instit_requested = i_prof.institution
                                    AND sp.id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment
                                    AND rownum > 0) t
                         WHERE pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) != pk_grid_amb.g_sched_adm_disch
                        UNION ALL
                        SELECT DISTINCT e.id_episode,
                                         NULL id_schedule,
                                         e.id_episode id_episode_origin,
                                         e.id_institution,
                                         e.id_patient,
                                         ei.id_professional,
                                         e.id_epis_type,
                                         nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_e) AS flg_status,
                                         NULL code_rehab_session_type,
                                         bd.code_bed,
                                         dpt.abbreviation,
                                         dpt.code_department,
                                         ro.desc_room_abbreviation,
                                         ro.code_abbreviation,
                                         ro.desc_room,
                                         ro.code_room,
                                         bd.desc_bed,
                                         NULL dt_begin_tstz,
                                         rep.id_rehab_epis_plan
                          FROM rehab_epis_plan rep
                          JOIN episode e
                            ON (e.id_episode = nvl((SELECT DISTINCT ree.id_episode_origin
                                                     FROM rehab_epis_encounter ree
                                                    WHERE ree.id_episode_rehab = rep.id_episode),
                                                   rep.id_episode) AND e.id_institution = i_prof.institution)
                          LEFT JOIN epis_info ei
                            ON ei.id_episode = e.id_episode
                          LEFT JOIN bed bd
                            ON bd.id_bed = ei.id_bed
                          LEFT JOIN room ro
                            ON ro.id_room = bd.id_room
                          LEFT JOIN department dpt
                            ON dpt.id_department = ro.id_department
                          LEFT JOIN rehab_epis_encounter re
                            ON re.id_episode_origin = e.id_episode
                         WHERE e.id_episode NOT IN (SELECT rsn.id_episode_origin
                                                      FROM rehab_sch_need rsn)
                           AND rep.flg_status = 'O'
                           AND e.id_episode = i_episode) r) t;
    
        RETURN l_tbl;
    END tf_cm_rehab_episode_detail;

    FUNCTION inactivate_rehab_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
    
        IF NOT pk_rehab.inactivate_rehab_tasks(i_lang        => i_lang,
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INACTIVATE_REHAB_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END inactivate_rehab_tasks;

    -- para viewer
    FUNCTION get_ordered_list
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN NUMBER,
        i_episode      IN NUMBER,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_count      NUMBER;
    
        l_id_episode_origin NUMBER;
        l_id_schedule       NUMBER;
        l_id_epis_type      NUMBER;
    
        k_icon_mark CONSTANT VARCHAR2(0010 CHAR) := '#ICON#';
        k_text_mark CONSTANT VARCHAR2(0010 CHAR) := '#TEXT#';
        l_status_string VARCHAR2(1000 CHAR) := '|TI||' || k_text_mark || '|' || k_icon_mark || '||||||| ';
    
        FUNCTION get_episodes(i_episode IN NUMBER) RETURN table_number IS
            l_id_visit   NUMBER;
            tbl_episodes table_number;
        BEGIN
        
            l_id_visit := pk_episode.get_id_visit(i_episode);
        
            SELECT e.id_episode
              BULK COLLECT
              INTO tbl_episodes
              FROM episode e
             WHERE e.id_visit = l_id_visit;
        
            RETURN tbl_episodes;
        
        END get_episodes;
    
    BEGIN
    
        --tbl_episodes := get_episodes(i_episode => i_episode);
        --l_count      := tbl_episodes.count;
    
        IF NOT pk_rehab.get_origin_episode(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_episode        => i_episode,
                                           i_id_schedule       => NULL,
                                           o_id_episode_origin => l_id_episode_origin,
                                           o_id_schedule       => l_id_schedule,
                                           o_id_epis_type      => l_id_epis_type,
                                           o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
    
        OPEN o_ordered_list FOR
            SELECT t.id_rehab_presc id,
                   CAST('DESC1' AS VARCHAR2(4000)) code_description,
                   CAST(t.desc_interv AS VARCHAR2(4000)) description,
                   current_timestamp dt_req_tstz,
                   CAST(t.instructions AS VARCHAR2(50)) dt_req,
                   CAST('DESC2' AS VARCHAR2(4000)) flg_status,
                   CAST(REPLACE(REPLACE(l_status_string, k_icon_mark, t.icon), k_text_mark, t.icon_label) AS
                        VARCHAR2(4000)) desc_status,
                   CAST(pk_alert_constant.g_viewer_filter_rehab AS VARCHAR2(4000)) flg_type,
                   --CAST(t.icon_label AS VARCHAR2(4000)) desc_status,
                   --CAST('2 times per week....' AS VARCHAR2(4000)) instructions_desc,
                   CAST(t.instructions AS VARCHAR2(4000)) instructions_desc,
                   0 rank,
                   0 rank_order,
                   0 num_count
              FROM (SELECT xsql.*, pk_rehab.order_by_treat(i_flg_status => xsql.flg_status) order_by_treat
                      FROM TABLE(pk_rehab.get_rehab_treat_plan_all(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_patient        => i_patient,
                                                                   i_id_episode        => table_number(i_episode),
                                                                   i_id_episode_origin => l_id_episode_origin)) xsql) t
             ORDER BY t.order_by_treat DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'REHAB-GET_ORDERED_LIST',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_ordered_list;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_rehab_external_api_db;
/
