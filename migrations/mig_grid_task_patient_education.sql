-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.teach_req IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;

    l_shortcut sys_shortcut.id_sys_shortcut%TYPE := 15;

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
                                                                      'YYYYMMDDHH24MISS TZR')) status_string
                      FROM (SELECT MAX(status_string) status_string
                              FROM (SELECT decode(rank,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_logic_nurse_tea_req.get_nurse_tea_req_status_str(profissional(NULL,
                                                                                                                                              r_cur.id_institution,
                                                                                                                                              r_cur.id_software),
                                                                                                                                 flg_time,
                                                                                                                                 flg_status,
                                                                                                                                 dt_begin_tstz),
                                                                             pk_logic_nurse_tea_req.get_nurse_tea_req_status_msg(profissional(NULL,
                                                                                                                                              r_cur.id_institution,
                                                                                                                                              r_cur.id_software),
                                                                                                                                 flg_time,
                                                                                                                                 flg_status,
                                                                                                                                 dt_begin_tstz),
                                                                             pk_logic_nurse_tea_req.get_nurse_tea_req_status_icon(profissional(NULL,
                                                                                                                                               r_cur.id_institution,
                                                                                                                                               r_cur.id_software),
                                                                                                                                  flg_time,
                                                                                                                                  flg_status,
                                                                                                                                  dt_begin_tstz),
                                                                             pk_logic_nurse_tea_req.get_nurse_tea_req_status_flg(profissional(NULL,
                                                                                                                                              r_cur.id_institution,
                                                                                                                                              r_cur.id_software),
                                                                                                                                 flg_time,
                                                                                                                                 flg_status,
                                                                                                                                 dt_begin_tstz)),
                                                  NULL) status_string
                                      FROM (SELECT t.id_nurse_tea_req,
                                                   t.id_episode,
                                                   t.flg_time,
                                                   t.flg_status,
                                                   t.dt_req_tstz,
                                                   t.dt_begin_tstz,
                                                   row_number() over(ORDER BY t.rank) rank
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status,
                                                                  pk_patient_education_db.g_nurse_tea_req_pend,
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'NURSE_TEA_REQ.FLG_STATUS',
                                                                                             t.flg_status),
                                                                       coalesce(t.dt_begin_tstz, t.dt_req_tstz)),
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'NURSE_TEA_REQ.FLG_STATUS',
                                                                                             t.flg_status),
                                                                       coalesce(t.dt_begin_tstz, t.dt_req_tstz) DESC) + 20000) rank
                                                      FROM (SELECT ntr.id_nurse_tea_req,
                                                                   ntr.id_episode,
                                                                   ntr.flg_time,
                                                                   ntr.flg_status,
                                                                   ntr.dt_nurse_tea_req_tstz dt_req_tstz,
                                                                   ntr.dt_begin_tstz
                                                              FROM nurse_tea_req ntr
                                                             WHERE (ntr.id_episode = r_cur.id_episode OR
                                                                   ntr.id_prev_episode = r_cur.id_episode)
                                                               AND ntr.flg_status IN ('D', 'A')) t) t)
                                     WHERE rank = 1) t) t)
        LOOP
        
            IF rec.status_string IS NOT NULL
            THEN
                l_grid_task.teach_req := l_shortcut || rec.status_string;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.teach_req = l_grid_task.teach_req
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos