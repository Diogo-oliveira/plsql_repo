-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 29/10/2009 04:38
-- CHANGE REASON: [ALERT-51207] 
grant select on CPOE_TASK_SOFT_INST to alert_viewer;
-- CHANGE END: Tiago Silva

-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 20/01/2010 17:31
-- CHANGE REASON: [ALERT-64591] CPOE core DB versioning
grant select on CPOE_TASK_SOFT_INST to ALERT_VIEWER;
-- CHANGE END: Carlos Loureiro