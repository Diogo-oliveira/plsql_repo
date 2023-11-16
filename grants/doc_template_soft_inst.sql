-- CHANGED BY Joao Martins
-- CHANGE DATE 2009/07/03
-- CHANGE REASON ALERT-874 Procedures Time Out
grant select on alert.doc_template_soft_inst to alert_viewer;
-- CHANGE END

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select,insert,update,delete on doc_template_soft_inst to alert_apex_tools;
-- CHANGE END:  luis.r.silva