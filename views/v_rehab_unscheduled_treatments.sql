CREATE OR REPLACE VIEW v_rehab_unscheduled_treatments AS
SELECT DISTINCT NULL                        s_id_group,
                NULL                        flg_contact_type,
                t.id_schedule,
                t.id_patient,
                t.id_episode,
                t.id_episode_rehab,
                t.id_visit,
                t.id_epis_type,
                t.id_resp_professional,
                t.id_resp_rehab_group,
                t.dt_creation,
                t.dt_begin_tstz,
                t.flg_status,
                t.shortcut,
                t.id_schedule_type,
                t.dt_schedule_tstz,
                t.code_rehab_session_type,
                t.abbreviation,
                t.code_department,
                t.id_room,
                t.desc_room_abbreviation,
                t.code_abbreviation,
                t.code_room,
                t.desc_room,
                t.code_bed,
                t.desc_bed,
                t.id_rehab_epis_encounter,
                t.id_rehab_sch_need,
                t.id_rehab_schedule,
                t.id_software,
                t.id_professional,
                t.e_flg_status,
                t.id_lock_uq_value,
                t.lock_func,
                t.grid_workflow_icon,
                t.grid_workflow_icon_status,
                t.flg_type,
                t.desc_schedule_type
  FROM (WITH aux AS (SELECT x1.sys_lang sys_lang,
                            x1.sys_prof_id sys_prof_id,
                            x1.sys_prof_institution sys_prof_institution,
                            x1.sys_prof_software sys_prof_software,
                            x1.sys_lprof sys_lprof,
                            alert_context('l_flg_sch_type_cr') sys_flg_sch_type_cr,
                            alert_context('l_scfg_rehab_needs_sch') sys_scfg_rehab_needs_sch,
                            alert_context('l_show_med_disch') sys_show_med_disch,
                            alert_context('l_epis_type_rehab_ap') sys_epis_type_rehab_ap,
                            CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof,
                                                                  pk_date_utils.get_string_tstz(x1.sys_lang,
                                                                                                x1.sys_lprof,
                                                                                                alert_context('l_dt_begin'),
                                                                                                '')) AS TIMESTAMP WITH
                                 LOCAL TIME ZONE) sys_dt_begin,
                            CAST(pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(x1.sys_lprof,
                                                                                                 pk_date_utils.get_string_tstz(x1.sys_lang,
                                                                                                                               x1.sys_lprof,
                                                                                                                               alert_context('l_dt_end'),
                                                                                                                               '')),
                                                                1) AS TIMESTAMP WITH LOCAL TIME ZONE) sys_dt_end,
                            CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof, current_timestamp) AS TIMESTAMP WITH
                                 LOCAL TIME ZONE) sys_today1,
                            CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof, current_timestamp) AS TIMESTAMP WITH
                                 LOCAL TIME ZONE) + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND') sys_today9
                       FROM (SELECT alert_context('l_lang') sys_lang,
                                    profissional(alert_context('l_prof_id'),
                                                 alert_context('l_prof_institution'),
                                                 alert_context('l_prof_software')) sys_lprof,
                                    alert_context('l_prof_id') sys_prof_id,
                                    alert_context('l_prof_institution') sys_prof_institution,
                                    alert_context('l_prof_software') sys_prof_software
                               FROM dual) x1)
           SELECT /*+ use_nl(rsn rp rai) */
            NULL id_schedule,
            rbp.id_patient,
            e.id_episode,
            re.id_episode_rehab,
            e.id_visit,
            e.id_epis_type,
            rsn.id_resp_professional,
            rsn.id_resp_rehab_group,
            re.dt_creation,
            NULL dt_begin_tstz,
            nvl(re.flg_status, 'E') flg_status,
            1442 shortcut,
            1 id_schedule_type,
            NULL dt_schedule_tstz,
            rst.code_rehab_session_type,
            bd.code_bed,
            bd.desc_bed,
            dpt.abbreviation,
            dpt.code_department,
            ro.id_room,
            ro.desc_room_abbreviation,
            ro.code_abbreviation,
            ro.code_room,
            ro.desc_room,
            re.id_rehab_epis_encounter,
            rsn.id_rehab_sch_need,
            NULL id_rehab_schedule,
            ei.id_software,
            ei.id_professional,
            nvl(ree.flg_status, e.flg_status) e_flg_status,
            rank() over(PARTITION BY e.id_patient, rst.id_rehab_session_type ORDER BY rp.id_rehab_presc DESC) precedence_level,
            rp.id_rehab_presc id_lock_uq_value,
            'REHAB_GRID_PRESC' lock_func,
            'W' grid_workflow_icon,
            'E' grid_workflow_icon_status,
            'W' flg_type,
            (SELECT pk_message.get_message(aux.sys_lang, aux.sys_lprof, 'REHAB_T147')
               FROM dual) desc_schedule_type
             FROM (SELECT /*+ index(rsn RSND_SEARCH02_IDX) */
                    *
                     FROM rehab_sch_need rsn
                    WHERE rsn.flg_status = 'N'
                      AND rsn.dt_begin IS NULL
                   UNION
                   SELECT /*+ index(rsn RSND_SEARCH02_IDX) */
                    *
                     FROM rehab_sch_need rsn
                    WHERE rsn.flg_status = 'N'
                      AND rsn.dt_begin <= CAST(current_timestamp AS TIMESTAMP WITH LOCAL TIME ZONE)
                   UNION
                   SELECT *
                     FROM (SELECT /*+ index(rsn RSND_SEARCH02_IDX) */
                            *
                             FROM rehab_sch_need rsn
                            WHERE rsn.flg_status = 'N'
                              AND rsn.dt_begin >= CAST(current_timestamp AS TIMESTAMP WITH LOCAL TIME ZONE)
                              AND rownum > 0) t
                    WHERE extract(DAY FROM(current_timestamp)) >= extract(DAY FROM(t.dt_begin))) rsn
             JOIN rehab_presc rp
               ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
             JOIN rehab_area_interv rai
               ON rai.id_rehab_area_interv = rp.id_rehab_area_interv
             JOIN rehab_area ra
               ON ra.id_rehab_area = rai.id_rehab_area
             JOIN rehab_area_inst raii
               ON raii.id_rehab_area = ra.id_rehab_area
              AND raii.id_institution = alert_context('l_prof_institution')
             JOIN aux
               ON aux.sys_prof_institution = raii.id_institution
             JOIN rehab_area_inst_prof raip
               ON raip.id_rehab_area_inst = raii.id_rehab_area_inst
              AND raip.id_professional = aux.sys_prof_id
             JOIN rehab_session_type rst
               ON rst.id_rehab_session_type = rsn.id_rehab_session_type
             JOIN rehab_plan rbp
               ON rbp.id_episode_origin = rsn.id_episode_origin
             JOIN episode e
               ON e.id_episode = rsn.id_episode_origin -- falta este episódio
             JOIN rehab_environment r
               ON r.id_epis_type = e.id_epis_type
              AND r.id_institution IN (0, aux.sys_prof_institution)
              AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                               FROM rehab_environment_prof rep
                                              WHERE rep.id_professional = aux.sys_prof_id)
             LEFT JOIN epis_info ei
               ON ei.id_episode = e.id_episode
             LEFT JOIN rehab_epis_encounter re
               ON (re.id_episode_origin = e.id_episode AND re.dt_creation BETWEEN aux.sys_dt_begin AND aux.sys_dt_end AND
                  re.id_rehab_sch_need = rsn.id_rehab_sch_need)
             LEFT JOIN episode ree
               ON ree.id_episode = re.id_episode_rehab
             LEFT JOIN bed bd
               ON bd.id_bed = ei.id_bed
             LEFT JOIN room ro
               ON ro.id_room = bd.id_room
             LEFT JOIN department dpt
               ON dpt.id_department = ro.id_department
            WHERE rp.flg_status NOT IN ('X', 'N', 'C', 'D')
              AND (re.flg_status IS NULL OR re.flg_status NOT IN ('C', 'F'))
              AND e.flg_status NOT IN ('I', 'C')
              AND rp.id_institution = aux.sys_prof_institution
                 --For non scheduled sessions it is necessary to stop showing on the grid
                 --requests that have a total of concluded sessions (or sessions started, but no concluded, over 24 hours ago)
                 --equal to the number of requested sessions
              AND (rsn.sessions >
                  (SELECT COUNT(1)
                      FROM rehab_epis_encounter ree_c
                     WHERE ree_c.id_episode_origin = rsn.id_episode_origin
                       AND ree_c.id_rehab_sch_need = rsn.id_rehab_sch_need
                       AND (ree_c.flg_status = 'O' OR
                           (ree_c.flg_status = 'S' AND
                           ree_c.dt_creation <
                           CAST(pk_date_utils.add_days_to_tstz(aux.sys_dt_begin, -1) AS TIMESTAMP WITH LOCAL TIME ZONE)) OR
                           (ree_c.flg_status = 'F' AND ree_c.flg_rehab_workflow_type = 'S'))))
                 --Non scheduled tratments should only appear on the Today grid
              AND aux.sys_dt_begin BETWEEN aux.sys_today1 AND aux.sys_today9) t
            WHERE t.precedence_level = 1
              AND rownum > 0;
