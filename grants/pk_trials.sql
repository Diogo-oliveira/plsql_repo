-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2011-04-08
-- CHANGE REASON: ADT-4277

grant execute on PK_TRIALS to alert_adtcod;
grant execute on PK_TRIALS to intf_alert;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2011-04-12
-- CHANGE REASON: ADT-4277

grant execute on PK_TRIALS to alert_adtcod;
grant execute on PK_TRIALS to alert_inter;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2011-04-12
-- CHANGE REASON: ADT-4277

grant execute on PK_TRIALS to alert_adtcod with grant option;
grant execute on PK_TRIALS to alert_inter with grant option;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 09/06/2011 14:48
-- CHANGE REASON: [ALERT-184322 ] Trials
grant execute on pk_trials to ALERT_INTER;
-- CHANGE END: Elisabete Bugalho

grant execute on pk_trials to ALERT_RESET;