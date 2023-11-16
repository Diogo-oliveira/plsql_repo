-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 16/12/2014 18:20
-- CHANGE REASON: [ALERT-304404] 
BEGIN
    pk_versioning.run(i_sql => 'GRANT SELECT on FUNC_HELP_ICON_SCREEN to ALERT_VIEWER');
END;
/
-- CHANGE END: Gustavo Serrano