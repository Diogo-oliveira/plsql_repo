-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 26/01/2011 11:49
-- CHANGE REASON: [ALERT-157923] 
grant references on EXAM_GROUP to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 04/07/2011 16:59
-- CHANGE REASON: [ALERT-157923] grants needed to FK references
grant references on EXAM_GROUP to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 20/09/2011 18:02
-- CHANGE REASON: [ALERT-157923] grants
grant references on EXAM_GROUP to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 27/01/2012 17:16
-- CHANGE REASON: [ALERT-216286] 
grant references on EXAM_GROUP to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Daniel Ferreira
-- CHANGE DATE: 20/06/2014
-- CHANGE REASON: [CODING-1296] 
grant select on EXAM_GROUP to ALERT_CODING_TR;
-- CHANGE END:  Daniel Ferreira


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-23
-- CHANGED REASON: CEMR-1835

-- CHANGED BY: Lillian Lu
-- CHANGE DATE: 2018-05-29
-- CHANGE REASON: [CEMR-1590] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_exam and alert_core_cnt.pk_cnt_exam
GRANT SELECT, INSERT, UPDATE ON ALERT.EXAM_GROUP TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Lillian Lu
-- CHANGE END: Ana Moita
