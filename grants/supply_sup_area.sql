-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 02/12/2010 16:48
-- CHANGE REASON: [ALERT-146441] Associate a surgical procedure to supplies
GRANT SELECT ON SUPPLY_SUP_AREA TO ALERT_VIEWER;
-- CHANGE END: Filipe Silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SUPPLY_SUP_AREA to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-25
-- CHANGED REASON: CEMR-1415

GRANT SELECT, INSERT, UPDATE, DELETE ON ALERT.SUPPLY_SUP_AREA TO ALERT_CORE_CNT WITH GRANT OPTION;

-- CHANGE END: Ana Moita
