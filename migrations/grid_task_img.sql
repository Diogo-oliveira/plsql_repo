-- CHANGED BY: Ana Matos
-- CHANGE DATE: 08/04/2016 11:06
-- CHANGE REASON: [ALERT-320194] 
DECLARE

    CURSOR c_exam_req IS
        SELECT erd.id_exam_req_det,
               gti.id_institution,
               gti.id_software,
               er.id_prof_req id_professional,
               er.id_episode,
               gti.flg_time_req,
               erd.flg_status flg_status_erd,
               erd.flg_referral,
               er.dt_req_tstz,
               er.dt_begin_tstz,
               er.dt_pend_req_tstz,
               gti.flg_status_mov,
               gti.dt_req_mov_tstz,
               gti.dt_end_mov_tstz,
               CASE
                    WHEN erd.flg_status = 'F' THEN
                     CASE
                         WHEN erd.flg_priority != 'N' THEN
                          rs.value || 'U'
                         ELSE
                          CASE
                              WHEN eres.id_abnormality IS NOT NULL
                                   AND eres.id_abnormality != 7 THEN
                               rs.value || 'U'
                              ELSE
                               rs.value
                          END
                     END
                    ELSE
                     rs.value
                END flg_status_r
          FROM grid_task_img gti,
               exam_req er,
               exam_req_det erd,
               (SELECT *
                  FROM exam_result er
                 WHERE er.flg_status != 'C') eres,
               result_status rs
         WHERE gti.id_exam_req = er.id_exam_req
           AND er.id_exam_req NOT IN (SELECT id_exam_req
                                        FROM exam_req
                                       WHERE id_episode_origin IS NOT NULL
                                         AND dt_pend_req_tstz IS NULL
                                         AND flg_time = 'E')
           AND gti.id_exam_req_det = erd.id_exam_req_det
           AND erd.id_exam_req_det = eres.id_exam_req_det(+)
           AND eres.id_result_status = rs.id_result_status(+);

    l_grid_task_img grid_task_img%ROWTYPE;

BEGIN

    FOR rec IN c_exam_req
    LOOP
        IF rec.flg_status_erd IN ('R', 'W', 'P', 'EF')
           AND rec.flg_status_mov != 'T'
        THEN
            l_grid_task_img.request := '0' ||
                                       pk_utils.get_status_string(NULL,
                                                                  profissional(rec.id_professional,
                                                                               rec.id_institution,
                                                                               rec.id_software),
                                                                  pk_ea_logic_exams.get_exam_status_str_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             rec.flg_status_erd,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             rec.dt_req_tstz,
                                                                                                             rec.dt_pend_req_tstz,
                                                                                                             rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz));
        ELSE
            IF rec.flg_status_mov = 'T'
            THEN
                l_grid_task_img.transport := '0' ||
                                             pk_utils.get_status_string(NULL,
                                                                        profissional(rec.id_professional,
                                                                                     rec.id_institution,
                                                                                     rec.id_software),
                                                                        pk_ea_logic_exams.get_exam_status_str_det(NULL,
                                                                                                                  profissional(rec.id_professional,
                                                                                                                               rec.id_institution,
                                                                                                                               rec.id_software),
                                                                                                                  rec.id_episode,
                                                                                                                  rec.flg_time_req,
                                                                                                                  rec.flg_status_erd,
                                                                                                                  rec.flg_referral,
                                                                                                                  rec.flg_status_r,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_msg_det(NULL,
                                                                                                                  profissional(rec.id_professional,
                                                                                                                               rec.id_institution,
                                                                                                                               rec.id_software),
                                                                                                                  rec.id_episode,
                                                                                                                  rec.flg_time_req,
                                                                                                                  rec.flg_status_erd,
                                                                                                                  rec.flg_referral,
                                                                                                                  rec.flg_status_r,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_icon_det(NULL,
                                                                                                                   profissional(rec.id_professional,
                                                                                                                                rec.id_institution,
                                                                                                                                rec.id_software),
                                                                                                                   rec.id_episode,
                                                                                                                   rec.flg_time_req,
                                                                                                                   rec.flg_status_erd,
                                                                                                                   rec.flg_referral,
                                                                                                                   rec.flg_status_r,
                                                                                                                   rec.dt_req_mov_tstz,
                                                                                                                   rec.dt_req_mov_tstz,
                                                                                                                   rec.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_flg_det(NULL,
                                                                                                                  profissional(rec.id_professional,
                                                                                                                               rec.id_institution,
                                                                                                                               rec.id_software),
                                                                                                                  rec.id_episode,
                                                                                                                  rec.flg_time_req,
                                                                                                                  rec.flg_status_erd,
                                                                                                                  rec.flg_referral,
                                                                                                                  rec.flg_status_r,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz,
                                                                                                                  rec.dt_req_mov_tstz));
            
            ELSE
                l_grid_task_img.request := NULL;
            END IF;
        END IF;
    
        IF rec.flg_status_erd = 'E'
        THEN
            l_grid_task_img.execute := '0' ||
                                       pk_utils.get_status_string(NULL,
                                                                  profissional(rec.id_professional,
                                                                               rec.id_institution,
                                                                               rec.id_software),
                                                                  pk_ea_logic_exams.get_exam_status_str_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             pk_exam_constant.g_exam_req,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                          rec.dt_req_tstz),
                                                                                                                      rec.dt_req_tstz),
                                                                                                             greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                          rec.dt_req_tstz),
                                                                                                                      rec.dt_req_tstz),
                                                                                                             greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                          rec.dt_req_tstz),
                                                                                                                      rec.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz),
                                                                                                            greatest(nvl(rec.dt_end_mov_tstz,
                                                                                                                         rec.dt_req_tstz),
                                                                                                                     rec.dt_req_tstz)));
        
        ELSIF rec.flg_status_erd = 'EX'
        THEN
            l_grid_task_img.execute := '0' ||
                                       pk_utils.get_status_string(NULL,
                                                                  profissional(rec.id_professional,
                                                                               rec.id_institution,
                                                                               rec.id_software),
                                                                  pk_ea_logic_exams.get_exam_status_str_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             rec.flg_status_erd,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             rec.dt_req_tstz,
                                                                                                             rec.dt_pend_req_tstz,
                                                                                                             rec.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(NULL,
                                                                                                            profissional(rec.id_professional,
                                                                                                                         rec.id_institution,
                                                                                                                         rec.id_software),
                                                                                                            rec.id_episode,
                                                                                                            rec.flg_time_req,
                                                                                                            rec.flg_status_erd,
                                                                                                            rec.flg_referral,
                                                                                                            rec.flg_status_r,
                                                                                                            rec.dt_req_tstz,
                                                                                                            rec.dt_pend_req_tstz,
                                                                                                            rec.dt_begin_tstz));
        END IF;
    
        IF rec.flg_status_erd = 'F'
        THEN
            l_grid_task_img.complete := '0' ||
                                        pk_utils.get_status_string(NULL,
                                                                   profissional(rec.id_professional,
                                                                                rec.id_institution,
                                                                                rec.id_software),
                                                                   pk_ea_logic_exams.get_exam_status_str_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             rec.flg_status_erd,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             rec.dt_req_tstz,
                                                                                                             rec.dt_pend_req_tstz,
                                                                                                             rec.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_msg_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             rec.flg_status_erd,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             rec.dt_req_tstz,
                                                                                                             rec.dt_pend_req_tstz,
                                                                                                             rec.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_icon_det(NULL,
                                                                                                              profissional(rec.id_professional,
                                                                                                                           rec.id_institution,
                                                                                                                           rec.id_software),
                                                                                                              rec.id_episode,
                                                                                                              rec.flg_time_req,
                                                                                                              rec.flg_status_erd,
                                                                                                              rec.flg_referral,
                                                                                                              rec.flg_status_r,
                                                                                                              rec.dt_req_tstz,
                                                                                                              rec.dt_pend_req_tstz,
                                                                                                              rec.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_flg_det(NULL,
                                                                                                             profissional(rec.id_professional,
                                                                                                                          rec.id_institution,
                                                                                                                          rec.id_software),
                                                                                                             rec.id_episode,
                                                                                                             rec.flg_time_req,
                                                                                                             rec.flg_status_erd,
                                                                                                             rec.flg_referral,
                                                                                                             rec.flg_status_r,
                                                                                                             rec.dt_req_tstz,
                                                                                                             rec.dt_pend_req_tstz,
                                                                                                             rec.dt_begin_tstz));
        END IF;
    
        UPDATE grid_task_img gti
           SET gti.request   = l_grid_task_img.request,
               gti.transport = l_grid_task_img.transport,
               gti.execute   = l_grid_task_img.execute,
               gti.complete  = l_grid_task_img.complete
         WHERE gti.id_exam_req_det = rec.id_exam_req_det;
    
        l_grid_task_img.request   := NULL;
        l_grid_task_img.transport := NULL;
        l_grid_task_img.execute   := NULL;
        l_grid_task_img.complete  := NULL;
    
    END LOOP;
END;
/
-- CHANGE END: Ana Matos