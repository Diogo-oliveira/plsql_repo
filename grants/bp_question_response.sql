-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:07
-- CHANGE REASON: [EMR-6418] 
grant select, insert, delete on BP_QUESTION_RESPONSE to ALERT_APEX_TOOLS;
grant select, insert, update, delete on BP_QUESTION_RESPONSE to ALERT_CONFIG;
grant select, update, delete on BP_QUESTION_RESPONSE to ALERT_RESET;
grant select on BP_QUESTION_RESPONSE to DSV;
grant select on BP_QUESTION_RESPONSE to INTER_ALERT_V2;
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 14/06/2019 09:29
-- CHANGE REASON: [EMR-16972]
grant all on bp_question_response to alert_inter;
-- CHANGE END: Pedro Henriques