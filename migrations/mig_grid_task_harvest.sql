-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.harvest IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;

    l_shortcut sys_shortcut.id_sys_shortcut%TYPE := 19;

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
                                                                             pk_ea_logic_analysis.get_harvest_status_str(profissional(NULL,
                                                                                                                                      r_cur.id_institution,
                                                                                                                                      r_cur.id_software),
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_req_tstz,
                                                                                                                         dt_pend_req_tstz,
                                                                                                                         dt_begin_tstz,
                                                                                                                         'T'),
                                                                             pk_ea_logic_analysis.get_harvest_status_msg(profissional(NULL,
                                                                                                                                      r_cur.id_institution,
                                                                                                                                      r_cur.id_software),
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_req_tstz,
                                                                                                                         dt_pend_req_tstz,
                                                                                                                         dt_begin_tstz,
                                                                                                                         'T'),
                                                                             pk_ea_logic_analysis.get_harvest_status_icon(profissional(NULL,
                                                                                                                                       r_cur.id_institution,
                                                                                                                                       r_cur.id_software),
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz,
                                                                                                                          'T'),
                                                                             pk_ea_logic_analysis.get_harvest_status_flg(profissional(NULL,
                                                                                                                                      r_cur.id_institution,
                                                                                                                                      r_cur.id_software),
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_req_tstz,
                                                                                                                         dt_pend_req_tstz,
                                                                                                                         dt_begin_tstz,
                                                                                                                         'T')),
                                                  NULL) status_string
                                      FROM (SELECT t.*,
                                                   row_number() over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language, 'HARVEST.FLG_STATUS', t.flg_status), coalesce(t.dt_pend_req_tstz, t.dt_begin_tstz, t.dt_req_tstz)) rank
                                              FROM (SELECT h.id_harvest,
                                                           h.id_episode,
                                                           ard.flg_time_harvest flg_time,
                                                           h.flg_status,
                                                           ar.dt_req_tstz,
                                                           ard.dt_pend_req_tstz,
                                                           ard.dt_target_tstz   dt_begin_tstz
                                                      FROM harvest          h,
                                                           analysis_harvest ah,
                                                           analysis_req_det ard,
                                                           analysis_req     ar
                                                     WHERE h.id_episode = r_cur.id_episode
                                                       AND h.flg_status = 'H'
                                                       AND h.id_harvest = ah.id_harvest
                                                       AND ah.flg_status != 'I'
                                                       AND ah.id_analysis_req_det = ard.id_analysis_req_det
                                                       AND ard.flg_status != 'X'
                                                       AND ard.id_analysis_req = ar.id_analysis_req
                                                       AND ar.id_episode = r_cur.id_episode) t)
                                     WHERE rank = 1) t) t)
        LOOP
        
            IF rec.status_string IS NOT NULL
            THEN
                l_grid_task.harvest := l_shortcut || rec.status_string;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.harvest = l_grid_task.harvest
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos