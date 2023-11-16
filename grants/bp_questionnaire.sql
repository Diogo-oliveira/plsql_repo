-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:07
-- CHANGE REASON: [EMR-6418] 
grant select, insert, delete on BP_QUESTIONNAIRE to ALERT_APEX_TOOLS;
grant select, insert, update, delete on BP_QUESTIONNAIRE to ALERT_CONFIG;
grant select on BP_QUESTIONNAIRE to APEX_ALERT_DEFAULT;
grant select on BP_QUESTIONNAIRE to DSV;
grant select on BP_QUESTIONNAIRE to INTER_ALERT_V2;
-- CHANGE END: Pedro Henriques