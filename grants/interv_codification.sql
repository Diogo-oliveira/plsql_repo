-- CHANGED BY: Jo�o Martins
-- CHANGE DATE: 08/07/2009 14:40
-- CHANGE REASON: [ALERT-35138] Workflow diferenciado entre an�lises, exames e procedimentos feitos na institui��o e os requisitados para o exterior. Integra��o com pedidos de P1.
grant select on alert.interv_codification to alert_viewer;
-- CHANGE END: Jo�o Martins


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.INTERV_CODIFICATION to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Andr� Silva
-- CHANGE DATE: 05/09/2017
-- CHANGE REASON: ALERT-331994
GRANT SELECT ON interv_codification TO alert_inter;
-- CHANGE END: Andr� Silva