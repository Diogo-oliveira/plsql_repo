-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 08:20
-- CHANGE REASON: [ALERT-266574] 
UPDATE exam_question_response erq
   SET flg_time   = 'O',
       id_episode =
       (SELECT id_episode
          FROM exam_req_det erd, exam_req er
         WHERE erd.id_exam_req_det = erq.id_exam_req_det
           AND erd.id_exam_req = er.id_exam_req);
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 10:45
-- CHANGE REASON: [ALERT-266574] 
UPDATE exam_question_response erq
   SET flg_time   = 'O',
       id_episode =
       (SELECT nvl(er.id_episode, er.id_episode_origin)
          FROM exam_req_det erd, exam_req er
         WHERE erd.id_exam_req_det = erq.id_exam_req_det
           AND erd.id_exam_req = er.id_exam_req);
-- CHANGE END: Ana Matos