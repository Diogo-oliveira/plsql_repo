BEGIN
    EXECUTE IMMEDIATE 'GRANT REFERENCES ON INSTITUTION_GROUP TO alert_default';
EXCEPTION
WHEN others THEN
    NULL;
END;
/	

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 07/07/2009
-- CHANGE REASON: ALERT-31353
grant select on institution_group to alert_adtcod;
-- CHANGE END: Bruno Martins


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.INSTITUTION_GROUP to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
