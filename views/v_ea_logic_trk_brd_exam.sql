CREATE OR REPLACE VIEW V_EA_LOGIC_TRK_BRD_EXAM AS
SELECT id_episode,
flg_type,
       to_char(exam.exam_pend, 'YYYYMMDDHH24MISS TZR') exam_pend,
       to_char(exam.exam_req, 'YYYYMMDDHH24MISS TZR') exam_req,
       to_char(exam.exam_transp, 'YYYYMMDDHH24MISS TZR') exam_transp,
       to_char(exam.exam_exec, 'YYYYMMDDHH24MISS TZR') exam_exec,
       to_char(exam.exam_result, 'YYYYMMDDHH24MISS TZR') exam_result,
       to_char(exam.exam_result_read, 'YYYYMMDDHH24MISS TZR') exam_result_read,
       to_char(exam.exam_ext, 'YYYYMMDDHH24MISS TZR') exam_ext,
       to_char(exam.exam_perf, 'YYYYMMDDHH24MISS TZR') exam_perf,
       to_char(exam.exam_wtg, 'YYYYMMDDHH24MISS TZR') exam_wtg,
       to_char(exam.exam_sos, 'YYYYMMDDHH24MISS TZR') exam_sos
  FROM (SELECT epis.id_visit id_visit,
               epis.id_episode id_episode,
               ex.flg_type,
               MIN(ex.exam_pend) exam_pend,
               MIN(ex.exam_req) exam_req,
               MIN(ex.exam_transp) exam_transp,
               MIN(ex.exam_exec) exam_exec,
               MIN(ex.exam_result) exam_result,
               MIN(ex.exam_result_read) exam_result_read,
               MIN(ex.exam_ext) exam_ext,
               MIN(ex.exam_perf) exam_perf,
               MIN(ex.exam_wtg) exam_wtg,
               MIN(ex.exam_sos) exam_sos
          FROM (SELECT /*+opt_estimate(table,erq,scale_rows=0.0000001)*/
                 (SELECT e1.id_visit
                    FROM episode e1
                   WHERE e1.id_episode = erq.id_episode) id_visit,
                 erq.id_episode,
                 e.flg_type,
                 MIN(decode(erd.flg_status, 'D', coalesce(erq.dt_pend_req_tstz, erq.dt_begin_tstz, erq.dt_req_tstz), NULL)) exam_pend,
                 MIN(decode(erd.flg_status, 'R', coalesce(erq.dt_pend_req_tstz, erq.dt_begin_tstz, erq.dt_req_tstz), NULL)) exam_req,
                 MIN(decode(erd.flg_status, 'T', coalesce(erq.dt_pend_req_tstz, erq.dt_begin_tstz, erq.dt_req_tstz), NULL)) exam_transp,
                 MIN(decode(erd.flg_status,
                            'E',
                            nvl((SELECT MAX(t.dt_creation_tstz)
                                  FROM ti_log t
                                 WHERE t.id_record = erd.id_exam_req_det
                                   AND t.flg_type = 'ED'),
                                erq.dt_begin_tstz),
                            NULL)) exam_exec,
                 MIN(decode(erd.flg_status, 'F', exr.dt_exam_result_tstz, NULL)) exam_result,
                 MIN(decode(erd.flg_status, 'L', exr.dt_exam_result_tstz, NULL)) exam_result_read,
                 MIN(decode(erd.flg_referral,
                            -- José Brito 20/11/2009 ALERT-57349
                            'S',
                            CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                            decode(erd.flg_status,
                                   'X',
                                   coalesce(erq.dt_pend_req_tstz, erq.dt_begin_tstz, erq.dt_req_tstz),
                                   NULL))) exam_ext,
                 MIN(decode(erd.flg_status, 'EX', erd.start_time, NULL)) exam_perf,
                 MIN(decode(erd.flg_status, 'W', erq.dt_req_tstz, NULL)) exam_wtg,
                 MIN(decode(erd.flg_status, 'S', erq.dt_req_tstz, NULL)) exam_sos
                  FROM exam_req erq
                  JOIN tbl_temp ttt
                    ON ttt.num_1 = erq.id_episode
                  JOIN exam_req_det erd ON erd.id_exam_req = erq.id_exam_req
                  join exam e on erd.id_exam = e.id_exam
                  LEFT JOIN (SELECT MAX(exr.dt_exam_result_tstz) dt_exam_result_tstz, exr.id_exam_req_det
                              FROM exam_result exr
                             WHERE exr.flg_status != 'C'
                             GROUP BY id_exam_req_det) exr ON exr.id_exam_req_det = erd.id_exam_req_det
                 WHERE erq.id_episode IS NOT NULL
                   AND erq.flg_time = 'E'
                 GROUP BY erq.id_episode, e.flg_type) ex
          JOIN episode epis ON epis.id_visit = ex.id_visit
         GROUP BY epis.id_visit, epis.id_episode, ex.flg_type) exam;
