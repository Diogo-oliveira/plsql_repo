-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant execute on pk_message  to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ]
grant execute on pk_message  to alert_inter;
-- CHANGE END: Pedro Quinteiro

grant execute on alert.pk_message to public;


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant EXECUTE on ALERT.PK_MESSAGE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
