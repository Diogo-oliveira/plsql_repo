-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 11/01/2012 12:31
-- CHANGE REASON: [ADT-6123] CH configs
grant
    SELECT , references ON v_physician_institution_ch TO alert_adtcod, alert_viewer, alert_inter;
-- CHANGE END:  Rui Gomes