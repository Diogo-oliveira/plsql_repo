-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 26/03/2014 16:29
-- CHANGE REASON: [ALERT-279399 ] 
grant select on icnp_composition_term to alert_core_Data;
-- CHANGE END: cristina.oliveira

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 26/03/2014 16:44
-- CHANGE REASON: [ALERT-279399 ] 
revoke select on icnp_composition_term FROM alert_core_Data;
-- CHANGE END: cristina.oliveira


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ICNP_COMPOSITION_TERM to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
