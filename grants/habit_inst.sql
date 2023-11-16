-- CHANGED BY: Filipe Machado
-- CHANGE DATE: 07/12/2010 15:05
-- CHANGE REASON: [ALERT-147592] Issue Replication v2605 : [Habits] - habits aren't configurable by institution (v2.6.0.5)
GRANT SELECT ON HABIT_INST TO alert_viewer;
-- CHANGE END: Filipe Machado


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.HABIT_INST to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
