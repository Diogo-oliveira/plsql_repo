-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 21/03/2009 16:34
-- CHANGE REASON: [ALERT-19860] Interface views
grant select on V_EPISODE to alert_adtcod, intf_alert;
-- CHANGE END

-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 26-Feb-2010
-- CHANGE REASON: ALERT-77799
grant select on V_EPISODE to alert_adtcod, intf_alert, inter_alert_v2;
-- CHANGE END: Paulo Fonseca

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-11-05
-- CHANGE REASON: ADT-3437

grant select on v_episode to intf_alert;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Joana Madureira Barroso
-- CHANGE DATE: 07/11/2014 17:22
-- CHANGE REASON: [ALERT-301015] 
grant select on v_episode to alert_pharmacy_func;
-- CHANGE END: Joana Madureira Barroso