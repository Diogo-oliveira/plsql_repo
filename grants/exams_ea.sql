grant select on exams_ea             to alert_viewer;


-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2009-JUL-28
-- CHANGED REASON: ALERT-16811

GRANT SELECT ON EXAMS_EA TO ALERT_VIEWER;

-- CHANGED END: Ana Matos




-- CHANGED BY: Ana Matos
-- CHANGE DATE: 16/02/2011 15:03
-- CHANGE REASON: [ALERT-41171] 
grant select, update, delete on exams_ea to alert_reset;
grant select on exams_ea to alert_viewer;
-- CHANGE END: Ana Matos

-- CHANGED BY: Pedro Miranda
-- CHANGE DATE: 09/05/2014 05:31
-- CHANGE REASON: [ALERT-284224]
grant all on exams_ea to alert_inter;
-- CHANGE END: Pedro Miranda