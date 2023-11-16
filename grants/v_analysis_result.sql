-- CHANGED BY: Joao Marques
-- CHANGE DATE: 23/06/2010
-- CHANGE REASON: [ALERT-101292] PK_IA_LAB - API lab migration from INTER_ALERT_V2 (PK_IA_ANALYSIS)
grant select on v_analysis_result to intf_alert;
-- CHANGE END

-- CHANGED BY: Ana Rita Martins 
-- CHANGE REASON: 19/04/2011
-- CHANGE DATE:ALERT-173965 
grant select on V_ANALYSIS_RESULT to ALERT_ADTCOD;
-- CHANGED END: Ana Rita Martins 
