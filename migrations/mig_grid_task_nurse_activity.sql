-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.nurse_activity IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task         grid_task%ROWTYPE;
    l_grid_task_between grid_task_between%ROWTYPE;

    l_shortcut sys_shortcut.id_sys_shortcut%TYPE := 7;

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
                           flg_nurse_act
                      FROM (SELECT MAX(status_string) status_string, MAX(flg_nurse_act) flg_nurse_act
                              FROM (SELECT decode(rank,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_wounds.get_wound_status_str(profissional(NULL,
                                                                                                                                  r_cur.id_institution,
                                                                                                                                  r_cur.id_software),
                                                                                                                     id_episode_origin,
                                                                                                                     flg_status_det,
                                                                                                                     flg_time,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz),
                                                                             pk_ea_logic_wounds.get_wound_status_msg(profissional(NULL,
                                                                                                                                  r_cur.id_institution,
                                                                                                                                  r_cur.id_software),
                                                                                                                     id_episode_origin,
                                                                                                                     flg_status_det,
                                                                                                                     flg_time,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz),
                                                                             pk_ea_logic_wounds.get_wound_status_icon(profissional(NULL,
                                                                                                                                   r_cur.id_institution,
                                                                                                                                   r_cur.id_software),
                                                                                                                      id_episode_origin,
                                                                                                                      flg_status_det,
                                                                                                                      flg_time,
                                                                                                                      dt_begin_tstz,
                                                                                                                      dt_plan_tstz),
                                                                             pk_ea_logic_wounds.get_wound_status_flg(profissional(NULL,
                                                                                                                                  r_cur.id_institution,
                                                                                                                                  r_cur.id_software),
                                                                                                                     id_episode_origin,
                                                                                                                     flg_status_det,
                                                                                                                     flg_time,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz)),
                                                  NULL) status_string,
                                           decode(rank, 1, decode(flg_time, 'B', 'Y'), NULL) flg_nurse_act
                                      FROM (SELECT t.id_nurse_activity_req,
                                                   t.id_episode_origin,
                                                   t.flg_time,
                                                   t.flg_status_det,
                                                   t.dt_begin_tstz,
                                                   t.dt_plan_tstz,
                                                   row_number() over(ORDER BY t.rank) rank
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status_det,
                                                                  'R',
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'NURSE_ACTIVITY_REQ.FLG_STATUS',
                                                                                             t.flg_status_det),
                                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz)),
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'NURSE_ACTIVITY_REQ.FLG_STATUS',
                                                                                             t.flg_status_det),
                                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz) DESC) +
                                                                  20000) rank
                                                      FROM (SELECT nar.id_nurse_activity_req,
                                                                   nar.id_episode_origin,
                                                                   nar.flg_time,
                                                                   nard.flg_status flg_status_det,
                                                                   nar.dt_begin_tstz,
                                                                   wt.dt_plan_tstz
                                                              FROM nurse_activity_req nar,
                                                                   nurse_actv_req_det nard,
                                                                   wound_evaluation   we,
                                                                   wound_treat        wt,
                                                                   episode            e
                                                             WHERE (nar.id_episode = r_cur.id_episode OR
                                                                   nar.id_prev_episode = r_cur.id_episode)
                                                               AND nar.flg_status IN ('D', 'R', 'E')
                                                               AND nar.id_nurse_activity_req = nard.id_nurse_activity_req
                                                               AND nard.flg_status IN ('R', 'D', 'E')
                                                               AND nard.id_nurse_actv_req_det = we.id_nurse_actv_req_det(+)
                                                               AND we.id_wound_evaluation = wt.id_wound_evaluation(+)
                                                               AND (nar.id_episode = e.id_episode OR
                                                                   nar.id_prev_episode = e.id_episode)
                                                            UNION ALL
                                                            SELECT nar.id_nurse_activity_req,
                                                                   nar.id_episode_origin,
                                                                   nar.flg_time,
                                                                   nard.flg_status flg_status_det,
                                                                   nar.dt_begin_tstz,
                                                                   wt.dt_plan_tstz
                                                              FROM nurse_activity_req nar,
                                                                   nurse_actv_req_det nard,
                                                                   wound_evaluation   we,
                                                                   wound_treat        wt,
                                                                   episode            e
                                                             WHERE (nar.id_episode = r_cur.id_episode OR
                                                                   nar.id_prev_episode = r_cur.id_episode)
                                                               AND nar.flg_status = 'P'
                                                               AND nar.id_nurse_activity_req = nard.id_nurse_activity_req
                                                               AND nard.flg_status IN
                                                                   ('R', 'D', 'E')
                                                               AND nard.id_nurse_actv_req_det = we.id_nurse_actv_req_det(+)
                                                               AND we.id_wound_evaluation = wt.id_wound_evaluation(+)
                                                               AND wt.flg_status = 'N'
                                                               AND (nar.id_episode = e.id_episode OR
                                                                   nar.id_prev_episode = e.id_episode)) t) t)
                                     WHERE rank = 1) t) t)
        LOOP
        
            IF rec.status_string IS NOT NULL
            THEN
                l_grid_task.nurse_activity := l_shortcut || rec.status_string;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.nurse_activity = l_grid_task.nurse_activity
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        
            IF rec.flg_nurse_act = 'Y'
            THEN
                l_grid_task_between.id_episode := r_cur.id_episode;
            
                UPDATE grid_task_between gtb
                   SET gtb.flg_nurse_act = 'Y'
                 WHERE gtb.id_episode = l_grid_task_between.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos