-- CHANGED BY: Susana Silva
-- CHANGE DATE: 26/11/2009 09:12
-- CHANGE REASON: [ALERT-12334] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete, references, alter, index on SUPPLY_TYPE to ALERT_VIEWER;
-- CHANGE END: Susana Silva

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 14/11/2011 10:46
-- CHANGE REASON: [ALERT-204517] 
grant
    SELECT ON supply_type TO alert_default;
-- CHANGE END:  Rui Gomes


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SUPPLY_TYPE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-25
-- CHANGED REASON: CEMR-1415

GRANT SELECT, INSERT, UPDATE ON ALERT.SUPPLY_TYPE TO ALERT_CORE_CNT WITH GRANT OPTION;

-- CHANGE END: Ana Moita
