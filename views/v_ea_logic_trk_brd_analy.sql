CREATE OR REPLACE VIEW v_ea_logic_trk_brd_analy AS 
SELECT analy.id_episode,
       to_char(analy.lab_pend, 'YYYYMMDDHH24MISS TZR') lab_pend,
       to_char(analy.lab_req, 'YYYYMMDDHH24MISS TZR') lab_req,
       to_char(analy.lab_harv, 'YYYYMMDDHH24MISS TZR') lab_harv,
       to_char(analy.lab_transp, 'YYYYMMDDHH24MISS TZR') lab_transp,
       to_char(analy.lab_fin, 'YYYYMMDDHH24MISS TZR') lab_fin,
       to_char(analy.lab_result, 'YYYYMMDDHH24MISS TZR') lab_result,
       to_char(analy.lab_result_read, 'YYYYMMDDHH24MISS TZR') lab_result_read,
       to_char(analy.lab_ext, 'YYYYMMDDHH24MISS TZR') lab_ext,
       to_char(analy.lab_wtg, 'YYYYMMDDHH24MISS TZR') lab_wtg,
       to_char(analy.lab_cc, 'YYYYMMDDHH24MISS TZR') lab_cc,
       to_char(analy.lab_sos, 'YYYYMMDDHH24MISS TZR') lab_sos
  FROM (SELECT epis.id_visit id_visit,
               epis.id_episode id_episode,
               MIN(an.lab_pend) lab_pend,
               MIN(an.lab_req) lab_req,
               MIN(an.lab_harv) lab_harv,
               MIN(an.lab_transp) lab_transp,
               MIN(an.lab_fin) lab_fin,
               MIN(an.lab_result) lab_result,
               MIN(an.lab_result_read) lab_result_read,
               MIN(an.lab_ext) lab_ext,
               MIN(an.lab_wtg) lab_wtg,
               MIN(an.lab_cc) lab_cc,
               MIN(an.lab_sos) lab_sos
          FROM (SELECT /*+opt_estimate(table,ar,scale_rows=0.0000001)*/
                 ar.id_episode,
                 ar.id_visit,
                 MIN(decode(ard.flg_status, 'D', coalesce(ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz), NULL)) lab_pend,
                 MIN(decode(ard.flg_status, 'R', coalesce(ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz), NULL)) lab_req,
                 MIN(decode(ard.flg_status,
                            'E',
                            decode(h.flg_status,
                                   'H',
                                   coalesce(h.dt_harvest_tstz, ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz),
                                   NULL),
                            NULL)) lab_harv,
                 MIN(decode(ard.flg_status,
                            'E',
                            decode(h.flg_status,
                                   'T',
                                   coalesce(h.dt_mov_begin_tstz, ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz),
                                   NULL),
                            NULL)) lab_transp,
                 MIN(decode(ard.flg_status,
                            'E',
                            decode(h.flg_status,
                                   'F',
                                   coalesce(nvl((SELECT m.dt_end_tstz
                                                  FROM movement m
                                                 WHERE m.id_movement = ard.id_movement),
                                                h.dt_harvest_tstz),
                                            ard.dt_pend_req_tstz,
                                            ard.dt_target_tstz,
                                            ar.dt_req_tstz),
                                   NULL),
                            NULL)) lab_fin,
                 MIN(decode(ard.flg_status,
                            'F',
                            coalesce(coalesce(art.dt_analysis_result_tstz, ard.dt_final_result_tstz),
                                     ard.dt_pend_req_tstz,
                                     ard.dt_target_tstz,
                                     ar.dt_req_tstz),
                            NULL)) lab_result,
                 MIN(decode(ard.flg_status,
                            'L',
                            coalesce(coalesce(art.dt_analysis_result_tstz, ard.dt_final_result_tstz),
                                     ard.dt_pend_req_tstz,
                                     ard.dt_target_tstz,
                                     ar.dt_req_tstz),
                            NULL)) lab_result_read,
                 MIN(decode(ard.flg_referral,
                            -- José Brito 20/11/2009 ALERT-57349
                            'S',
                            CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                            decode(ard.flg_status,
                                   'X',
                                   coalesce(ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz),
                                   NULL))) lab_ext,
                 MIN(decode(ard.flg_status, 'W', coalesce(ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz), NULL)) lab_wtg,
                 MIN(decode(ard.flg_status, 'CC', ard.dt_last_update_tstz, NULL)) lab_cc,
                 MIN(decode(ard.flg_status, 'S', coalesce(ard.dt_pend_req_tstz, ard.dt_target_tstz, ar.dt_req_tstz), NULL)) lab_sos
                  FROM analysis_req ar
                     JOIN tbl_temp ttt
                     ON ttt.num_1 = ar.id_episode

                  JOIN analysis_req_det ard ON ard.id_analysis_req = ar.id_analysis_req
                  LEFT JOIN analysis_harvest ah ON ah.id_analysis_req_det = ard.id_analysis_req_det
                  LEFT JOIN (SELECT *
                              FROM harvest h
                             WHERE h.flg_status IN ('H', 'T', 'F')) h ON h.id_harvest = ah.id_harvest
                  LEFT JOIN (SELECT id_analysis_req_det, MAX(art.dt_analysis_result_tstz) dt_analysis_result_tstz
                              FROM analysis_result art
                             GROUP BY id_analysis_req_det) art ON art.id_analysis_req_det = ard.id_analysis_req_det
                 WHERE ar.id_episode IS NOT NULL
                   AND ar.flg_time = 'E'
                 GROUP BY ar.id_episode, ar.id_visit) an
          JOIN episode epis ON epis.id_visit = an.id_visit
         GROUP BY epis.id_visit, epis.id_episode)analy;
