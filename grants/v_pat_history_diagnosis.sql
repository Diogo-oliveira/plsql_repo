-- CHANGED BY: Ana Rita Martins
-- CHANGED DATE: 28/09/2009
-- CHANGING REASON: CODING-879 
grant select, references on v_pat_history_diagnosis to ALERT_ADTCOD;
-- CHANGE END:  Ana Rita Martins	


-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 27/02/2012 09:40
-- CHANGE REASON: [ALERT-220425 ] 
grant select on v_pat_history_diagnosis to alert_viewer;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 03/04/2012 14:38
-- CHANGE REASON: [ALERT-226108 ] 
grant select on v_pat_history_diagnosis to alert_inter;
-- CHANGE END: Sérgio Santos

-- CHANGED BY:  Joel Lopes
-- CHANGE DATE: 06/03/2014 09:45
-- CHANGE REASON: [ALERT-278171] 
GRANT SELECT ON V_PAT_HISTORY_DIAGNOSIS TO ALERT_INTER;
-- CHANGE END:  Joel Lopes