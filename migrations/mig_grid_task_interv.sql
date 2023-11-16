-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.intervention IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;
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
                           flg_interv
                      FROM (SELECT MAX(status_string) status_string, MAX(flg_interv) flg_interv
                              FROM (SELECT decode(rank,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_procedures.get_procedure_status_str(r_cur.id_language,
                                                                                                                             profissional(NULL,
                                                                                                                                          r_cur.id_institution,
                                                                                                                                          r_cur.id_software),
                                                                                                                             --flg_mfr,
																																																														 id_episode,
																																																														 flg_time,
																																																														 flg_status_det,
																																																														 NULL, --flg_prn
                                                                                                                             flg_referral,
																																																														 dt_req_tstz,
                                                                                                                             dt_begin_tstz,
                                                                                                                             dt_plan_tstz, 
																																																														 --flg_interv_type,
                                                                                                                             --flg_status_req,
                                                                                                                             NULL),
                                                                             pk_ea_logic_procedures.get_procedure_status_msg(r_cur.id_language,
                                                                                                                             profissional(NULL,
                                                                                                                                          r_cur.id_institution,
                                                                                                                                          r_cur.id_software),
                                                                                                                             id_episode,
                                                                                                                             flg_time,
                                                                                                                             flg_status_det,
                                                                                                                             NULL, --flg_prn
                                                                                                                             flg_referral,
                                                                                                                             dt_req_tstz,
                                                                                                                             dt_begin_tstz,
                                                                                                                             dt_plan_tstz, 
                                                                                                                             --flg_interv_type,
                                                                                                                             --flg_status_req,
                                                                                                                             NULL),
                                                                             pk_ea_logic_procedures.get_procedure_status_icon(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                             flg_time,
                                                                                                                             flg_status_det,
                                                                                                                             NULL, --flg_prn
                                                                                                                             flg_referral,
                                                                                                                             dt_req_tstz,
                                                                                                                             dt_begin_tstz,
                                                                                                                             dt_plan_tstz, 
                                                                                                                             --flg_interv_type,
                                                                                                                             --flg_status_req,
                                                                                                                             NULL),
                                                                             pk_ea_logic_procedures.get_procedure_status_flg(r_cur.id_language,
                                                                                                                             profissional(NULL,
                                                                                                                                          r_cur.id_institution,
                                                                                                                                          r_cur.id_software),
                                                                                                                             id_episode,
                                                                                                                             flg_time,
                                                                                                                             flg_status_det,
                                                                                                                             NULL, --flg_prn
                                                                                                                             flg_referral,
                                                                                                                             dt_req_tstz,
                                                                                                                             dt_begin_tstz,
                                                                                                                             dt_plan_tstz, 
                                                                                                                             --flg_interv_type,
                                                                                                                             --flg_status_req,
                                                                                                                             NULL)),
                                                  NULL) status_string,
                                           decode(rank, 1, decode(flg_time, 'B', 'Y'), NULL) flg_interv
                                      FROM (SELECT t.id_interv_presc_det,
                                                   t.id_episode,
                                                   t.flg_time,
                                                   t.flg_interv_type,
                                                   t.flg_status_req,
                                                   t.flg_status_det,
                                                   t.flg_referral,
                                                   t.flg_mfr,
                                                   t.dt_req_tstz,
                                                   t.dt_begin_tstz,
                                                   t.dt_plan_tstz,
                                                   row_number() over(ORDER BY t.rank) rank
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status_det,
                                                                  'R',
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                                             t.flg_status_det),
                                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)),
                                                                  row_number()
                                                                  over(ORDER BY pk_sysdomain.get_rank(r_cur.id_language,
                                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                                             t.flg_status_det),
                                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz) DESC) +
                                                                  20000) rank
                                                      FROM (SELECT ipd.id_interv_presc_det,
                                                                   ip.id_episode,
                                                                   ip.flg_time,
                                                                   ipd.flg_interv_type,
                                                                   ip.flg_status                  flg_status_req,
                                                                   ipd.flg_status                 flg_status_det,
                                                                   ipd.flg_referral,
                                                                   NULL flg_mfr,
                                                                   ip.dt_interv_prescription_tstz dt_req_tstz,
                                                                   ip.dt_begin_tstz,
                                                                   ipp.dt_plan_tstz
                                                              FROM interv_prescription ip,
                                                                   interv_presc_det    ipd,
                                                                   interv_presc_plan   ipp,
                                                                   episode             e
                                                             WHERE (ip.id_episode = r_cur.id_episode OR
                                                                   ip.id_prev_episode = r_cur.id_episode OR
                                                                   ip.id_episode_origin = r_cur.id_episode)
                                                               AND ip.id_interv_prescription = ipd.id_interv_prescription
                                                               AND ipd.flg_interv_type !=
                                                                   'C'
                                                               AND ipd.flg_status IN ('S', 'X', 'PA', 'D', 'R', 'E', 'P')
                                                               AND (ipd.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                   ipd.flg_referral IS NULL)
                                                               AND ipd.id_interv_presc_det = ipp.id_interv_presc_det
                                                               AND ipp.flg_status IN ('D', 'R')
                                                               AND (ip.id_episode = e.id_episode OR
                                                                   ip.id_prev_episode = e.id_episode OR
                                                                   ip.id_episode_origin = e.id_episode)) t) t)
                                     WHERE rank = 1) t) t)
        LOOP
        
            IF rec.status_string IS NOT NULL
            THEN
                l_grid_task.intervention := l_shortcut || rec.status_string;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.intervention = l_grid_task.intervention
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        
            IF rec.flg_interv = 'Y'
            THEN
                l_grid_task_between.id_episode := r_cur.id_episode;
            
                UPDATE grid_task_between gtb
                   SET gtb.flg_interv = 'Y'
                 WHERE gtb.id_episode = l_grid_task_between.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos