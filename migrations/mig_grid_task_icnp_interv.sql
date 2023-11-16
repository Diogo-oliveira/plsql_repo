-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.icnp_intervention IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task         grid_task%ROWTYPE;
    l_grid_task_between grid_task_between%ROWTYPE;

    l_shortcut sys_shortcut.id_sys_shortcut%TYPE := 27;

BEGIN

    FOR r_cur IN c_grid_task
    LOOP
    
        l_grid_task := NULL;
    
        FOR rec IN (SELECT REPLACE(decode(substr(t.status_string, 2, 1),
                                          'D',
                                          REPLACE(t.status_string,
                                                  substr(t.status_string,
                                                         instr(t.status_string, '|', 1, 2) + 1,
                                                         instr(substr(t.status_string,
                                                                      instr(t.status_string, '|', 1, 2) + 1),
                                                               '|') - 1),
                                                  pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                                  r_cur.id_institution,
                                                                                                  r_cur.id_software),
                                                                                     pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                                   profissional(NULL,
                                                                                                                                r_cur.id_institution,
                                                                                                                                r_cur.id_software),
                                                                                                                   decode(substr(t.status_string,
                                                                                                                                 2,
                                                                                                                                 1),
                                                                                                                          'D',
                                                                                                                          substr(t.status_string,
                                                                                                                                 instr(t.status_string,
                                                                                                                                       '|',
                                                                                                                                       1,
                                                                                                                                       2) + 1,
                                                                                                                                 instr(substr(t.status_string,
                                                                                                                                              instr(t.status_string,
                                                                                                                                                    '|',
                                                                                                                                                    1,
                                                                                                                                                    2) + 1),
                                                                                                                                       '|') - 1),
                                                                                                                          t.status_string),
                                                                                                                   NULL),
                                                                                     'YYYYMMDDHH24MISS TZR')),
                                          t.status_string),
                                   substr(t.status_string,
                                          instr(t.status_string, '|', 1, 9) + 1,
                                          instr(substr(t.status_string, instr(t.status_string, '|', 1, 9) + 1), '|') - 1),
                                   pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                   r_cur.id_institution,
                                                                                   r_cur.id_software),
                                                                      pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                    profissional(NULL,
                                                                                                                 r_cur.id_institution,
                                                                                                                 r_cur.id_software),
                                                                                                    substr(t.status_string,
                                                                                                           instr(t.status_string,
                                                                                                                 '|',
                                                                                                                 1,
                                                                                                                 9) + 1,
                                                                                                           instr(substr(t.status_string,
                                                                                                                        instr(t.status_string,
                                                                                                                              '|',
                                                                                                                              1,
                                                                                                                              9) + 1),
                                                                                                                 '|') - 1),
                                                                                                    NULL),
                                                                      'YYYYMMDDHH24MISS TZR')) status_string,
                           flg_icnp_interv
                      FROM (SELECT MAX(status_string) status_string, MAX(flg_icnp_interv) flg_icnp_interv
                              FROM (SELECT decode(rank,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_interv_icnp.get_icnp_interv_status_str(profissional(NULL,
                                                                                                                                             r_cur.id_institution,
                                                                                                                                             r_cur.id_software),
                                                                                                                                flg_status,
                                                                                                                                flg_type,
                                                                                                                                flg_time,
                                                                                                                                dt_next_tstz,
                                                                                                                                dt_plan_tstz,
                                                                                                                                flg_prn,
																																																																NULL),
                                                                             pk_ea_logic_interv_icnp.get_icnp_interv_status_msg(profissional(NULL,
                                                                                                                                             r_cur.id_institution,
                                                                                                                                             r_cur.id_software),
                                                                                                                                flg_status,
                                                                                                                                flg_type,
                                                                                                                                flg_time,
                                                                                                                                dt_next_tstz,
                                                                                                                                dt_plan_tstz,
                                                                                                                                flg_prn,
																																																																NULL),
                                                                             pk_ea_logic_interv_icnp.get_icnp_interv_status_icon(profissional(NULL,
                                                                                                                                              r_cur.id_institution,
                                                                                                                                              r_cur.id_software),
                                                                                                                                 flg_status,
                                                                                                                                 flg_type,
                                                                                                                                 flg_time,
                                                                                                                                 dt_next_tstz,
                                                                                                                                 dt_plan_tstz,
                                                                                                                                 flg_prn,
																																																																 NULL),
                                                                             pk_ea_logic_interv_icnp.get_icnp_interv_status_flg(profissional(NULL,
                                                                                                                                             r_cur.id_institution,
                                                                                                                                             r_cur.id_software),
                                                                                                                                flg_status,
                                                                                                                                flg_type,
                                                                                                                                flg_time,
                                                                                                                                dt_next_tstz,
                                                                                                                                dt_plan_tstz,
                                                                                                                                flg_prn,
																																																																NULL)),
                                                  NULL) status_string,
                                           decode(rank,
                                                  1,
                                                  decode(flg_time, 'B', 'Y'),
                                                  NULL) flg_icnp_interv
                                      FROM (SELECT t.id_icnp_epis_interv,
                                                   t.id_episode,
                                                   t.flg_type,
                                                   t.flg_time,
                                                   t.flg_status,
                                                   t.flg_prn,
                                                   t.dt_plan_tstz,
                                                   t.dt_next_tstz,
                                                   row_number() over(ORDER BY t.rank) rank
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status,
                                                                  'R',
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                                             t.flg_status),
                                                                       coalesce(t.dt_next_tstz, t.dt_plan_tstz)),
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                                             t.flg_status),
                                                                       coalesce(t.dt_next_tstz, t.dt_plan_tstz) DESC) + 20000) rank
                                                      FROM (SELECT iei.id_icnp_epis_interv,
                                                                   iei.id_episode,
                                                                   iei.flg_type,
                                                                   iei.flg_time,
                                                                   iei.flg_status,
                                                                   iei.flg_prn,
                                                                   decode(iip.dt_plan_tstz,
                                                                          NULL,
                                                                          iei.dt_icnp_epis_interv_tstz,
                                                                          iip.dt_plan_tstz) dt_plan_tstz,
                                                                   iei.dt_next_tstz
                                                              FROM icnp_epis_intervention iei,
                                                                   (SELECT *
                                                                      FROM (SELECT iip.id_icnp_epis_interv,
                                                                                   iip.flg_status,
                                                                                   iip.dt_plan_tstz,
                                                                                   row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.dt_plan_tstz) rn
                                                                              FROM icnp_interv_plan iip
                                                                             WHERE iip.flg_status IN ('D', 'R'))
                                                                     WHERE rn = 1) iip,
                                                                   episode e
                                                             WHERE iei.id_episode = r_cur.id_episode
                                                               AND iei.flg_status IN ('A', 'E')
                                                               AND iei.flg_prn != 'Y'
                                                               AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                                               AND iei.id_episode = e.id_episode
                                                            UNION
                                                            SELECT iei.id_icnp_epis_interv,
                                                                   iei.id_episode,
                                                                   iei.flg_type,
                                                                   iei.flg_time,
                                                                   iei.flg_status,
                                                                   iei.flg_prn,
                                                                   decode(iip.dt_plan_tstz,
                                                                          NULL,
                                                                          iei.dt_icnp_epis_interv_tstz,
                                                                          iip.dt_plan_tstz) dt_plan_tstz,
                                                                   iei.dt_next_tstz
                                                              FROM icnp_epis_intervention iei,
                                                                   (SELECT *
                                                                      FROM (SELECT iip.id_icnp_epis_interv,
                                                                                   iip.flg_status,
                                                                                   iip.dt_plan_tstz,
                                                                                   row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.dt_plan_tstz) rn
                                                                              FROM icnp_interv_plan iip
                                                                             WHERE iip.flg_status IN ('D', 'R'))
                                                                     WHERE rn = 1) iip,
                                                                   episode e
                                                             WHERE iei.id_episode = r_cur.id_episode
                                                               AND iei.flg_status IN ('A', 'E')
                                                               AND iei.flg_prn = 'Y'
                                                               AND iei.flg_time = 'E'
                                                               AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                                               AND iei.id_episode = e.id_episode) t) t)
                                     WHERE rank = 1) t) t)
        LOOP
        
            IF rec.status_string IS NOT NULL
            THEN
                l_grid_task.icnp_intervention := l_shortcut || rec.status_string;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.icnp_intervention = l_grid_task.icnp_intervention
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        
            IF rec.flg_icnp_interv = 'Y'
            THEN
                l_grid_task_between.id_episode := r_cur.id_episode;

                UPDATE grid_task_between gtb
                   SET gtb.flg_icnp_interv = 'Y'
                 WHERE gtb.id_episode = l_grid_task_between.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos