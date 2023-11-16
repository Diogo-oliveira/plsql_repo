-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 02/07/2010 08:22
-- CHANGE REASON: [ALERT-108937] 
grant select on HEALTH_PLAN_TAKE_OVER to ALERT_VIEWER;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-08-02
-- CHANGE REASON: ADT-2918

grant select on health_plan_take_over to alert_adtcod, alert_adtcod_cfg;

-- CHANGE END: Bruno Martins