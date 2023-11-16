-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on exam_dep_clin_serv to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant DELETE on ALERT.EXAM_DEP_CLIN_SERV to ALERT_APEX_TOOLS;
grant INSERT on ALERT.EXAM_DEP_CLIN_SERV to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.EXAM_DEP_CLIN_SERV to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-23
-- CHANGED REASON: CEMR-1835

-- CHANGED BY: Howard Cheng
-- CHANGE DATE: 2018-05-28
-- CHANGE REASON: CEMR-1590 [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api.exam and alert_core_cnt.pk_cnt_exam
GRANT SELECT, INSERT, DELETE, UPDATE ON ALERT.EXAM_DEP_CLIN_SERV TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Howard Cheng
-- CHANGE END: Ana Moita