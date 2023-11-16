-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:07
-- CHANGE REASON: [EMR-6418] 
grant select, insert, delete on BP_QUESTION_RESPONSE_HIST to ALERT_APEX_TOOLS;
grant select, insert, update, delete on BP_QUESTION_RESPONSE_HIST to ALERT_CONFIG;
grant select on BP_QUESTION_RESPONSE_HIST to DSV;
-- CHANGE END: Pedro Henriques