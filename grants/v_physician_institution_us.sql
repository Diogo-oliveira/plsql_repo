-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 16:50
-- CHANGE REASON: [ALERT-109173] 
grant select, references on V_PHYSICIAN_INSTITUTION_US to ALERT_ADTCOD;
-- CHANGE END: Tércio Soares

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 14/09/2012 12:26
-- CHANGE REASON: [ALERT-240143] 
grant
    SELECT , references ON v_physician_institution_us TO alert_adtcod, alert_inter;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 14/09/2012 12:27
-- CHANGE REASON: [ALERT-240154] 
grant
    SELECT , references ON v_physician_institution_us TO alert_adtcod, alert_inter;
-- CHANGE END:  Rui Gomes