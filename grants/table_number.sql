GRANT EXECUTE ON TABLE_NUMBER TO INTF_ALERT;

-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-07-29
-- CHANGE REASON: ADT-2923

grant execute on table_number to alert_adtcod;
grant execute on table_varchar to alert_adtcod;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Diamantino Campos
-- CHANGE DATE: 2010-12-10
-- CHANGE REASON: SCH-3434
grant execute on TABLE_NUMBER to ALERT_APSSCHDLR_TR;
-- CHANGE END: Diamantino Campos



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant EXECUTE on ALERT.TABLE_NUMBER to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
