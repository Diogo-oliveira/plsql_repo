-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2014-06-27
-- CHANGE REASON: ADT-6591

grant select, references on OTHER_RECM to ALERT_ADTCOD;

-- CHANGE END: Bruno Martins


-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 
-- CHANGE REASON:
grant select, references on OTHER_RECM to ALERT_VIEWER;
--CHANGE END: filipe.f.pereira 

-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 23/09/2020 
-- CHANGE REASON: EMR-36085 
grant select on other_recm to alert_adtcod with grant option;
-- CHANGE END: filipe.f.pereira