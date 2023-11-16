-- CHANGED BY: Luís Maia
-- CHANGE DATE: 27/03/2009 10:12
-- CHANGE REASON: [ALERT-21438] Criação dos grant's para as tabelas criadas.
GRANT SELECT ON tl_task TO ALERT_VIEWER;
-- CHANGE END

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT, INSERT, UPDATE, DELETE ON tl_task to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.TL_TASK to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
