-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 
-- CHANGE REASON:
grant select, references on RECM to ALERT_VIEWER;
--CHANGE END: filipe.f.pereira 

-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 23/09/2020 
-- CHANGE REASON: EMR-36085 
grant select on recm to alert_adtcod with grant option;
-- CHANGE END: filipe.f.pereira
