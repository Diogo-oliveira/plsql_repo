-- CREATE BY: Telmo
-- CREATE DATE: 29-03-2011
-- CREATE REASON: APS-1486
grant select on appointment to alert_apsschdlr_mt;
-- CHANGE END: Telmo

BEGIN
    pk_versioning.run(i_sql => 'grant select on appointment to alert_reset');
END;
/



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.APPOINTMENT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
