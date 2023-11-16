-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 12/07/2010 11:38
-- CHANGE REASON: [ALERT-111035] 
grant select on PROFESSIONAL_TAKE_OVER to ALERT_VIEWER;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-08-02
-- CHANGE REASON: ADT-2918

grant select on professional_take_over to alert_adtcod, alert_adtcod_cfg;

-- CHANGE END: Bruno Martins


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.PROFESSIONAL_TAKE_OVER to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
