

-- CHANGED BY: Pedro Miranda
-- CHANGE DATE: 09/05/2014 05:31
-- CHANGE REASON: [ALERT-284224]
grant all on exam to alert_inter;
-- CHANGE END: Pedro Miranda





-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on exam to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Kátia Marques
-- CHANGE DATE: 13-10-2014
-- CHANGE REASON: APS-437 (Codes) Problem with migration of event codes and standards.
grant select on exam to ALERT_APSSCHDLR_TR;
-- CHANGE END: Kátia Marques


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant DELETE on ALERT.EXAM to ALERT_APEX_TOOLS;
grant INSERT on ALERT.EXAM to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.EXAM to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-23
-- CHANGED REASON: CEMR-1835

-- CHANGED BY: Howard Cheng
-- CHANGE DATE: 2018-05-28
-- CHANGE REASON: CEMR-1590 [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api.exam and alert_core_cnt.pk_cnt_exam
GRANT SELECT, INSERT, UPDATE ON ALERT.EXAM TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Howard Cheng
-- CHANGE END: Ana Moita
