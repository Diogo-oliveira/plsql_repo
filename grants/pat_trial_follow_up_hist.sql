-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 07/04/2011 14:14
-- CHANGE REASON: [ALERT-171724] Trials
grant select on PAT_TRIAL_FOLLOW_UP_HIST to ALERT_VIEWER;
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 26-APR-2011
-- CHANGE REASON: [ALERT-174719]
grant select, update, delete on ALERT.PAT_TRIAL_FOLLOW_UP_HIST to alert_reset;
-- CHANGE END: Ana Coelho