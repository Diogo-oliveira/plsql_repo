-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 16/03/2010 11:37
-- CHANGE REASON: [ALERT-81575] 
grant insert on protocol_context_image to alert_viewer;
grant update on protocol_context_image to alert_viewer;
grant delete on protocol_context_image to alert_viewer;
-- CHANGE END: Carlos Loureiro


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.PROTOCOL_CONTEXT_IMAGE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
