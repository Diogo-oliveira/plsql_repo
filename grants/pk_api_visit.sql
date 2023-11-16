-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2009-10-02
-- CHANGE REASON: ALERT-47389
grant execute on pk_api_visit to alert_adtcod;
-- CHANGED END: Bruno Martins

-- CHANGED BY: Paulo Fonseca
-- CHANGED DATE: 25-Feb-2010
-- CHANGE REASON: ALERT-77347
GRANT EXECUTE ON ALERT.PK_API_VISIT TO INTER_ALERT_V2;
-- CHANGED END: Paulo Fonseca

-- CHANGED BY: Paulo Fonseca
-- CHANGED DATE: 10-Mar-2010
-- CHANGE REASON: ALERT-80202
GRANT EXECUTE ON PK_API_VISIT TO alert_adtcod, intf_alert, inter_alert_v2;
-- CHANGED END: Paulo Fonseca