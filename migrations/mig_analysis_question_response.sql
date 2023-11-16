-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 08:20
-- CHANGE REASON: [ALERT-266574] 
UPDATE analysis_question_response arq
   SET id_episode =
       (SELECT id_episode
          FROM analysis_req_det ard, analysis_req ar
         WHERE ard.id_analysis_req_det = arq.id_analysis_req_det
           AND ard.id_analysis_req = ar.id_analysis_req);
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 10:45
-- CHANGE REASON: [ALERT-266574] 
UPDATE analysis_question_response arq
   SET id_episode =
       (SELECT nvl(ar.id_episode, ar.id_episode_origin)
          FROM analysis_req_det ard, analysis_req ar
         WHERE ard.id_analysis_req_det = arq.id_analysis_req_det
           AND ard.id_analysis_req = ar.id_analysis_req);
-- CHANGE END: Ana Matos