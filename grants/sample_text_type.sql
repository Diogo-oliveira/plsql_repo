GRANT REFERENCES ON sample_text_type TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON sample_text_type TO alert_default;
-- CHANGE END: Tércio Soares

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 09/09/2013 12:03
-- CHANGE REASON: [ALERT-264706] 
grant select, references on ALERT.SAMPLE_TEXT_TYPE to ALERT_DEFAULT; 
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 16/09/2013 09:50
-- CHANGE REASON: [ALERT-264706] 
grant select, references on ALERT.SAMPLE_TEXT_TYPE to ALERT_DEFAULT; 
-- CHANGE END:  Rui Gomes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1891

GRANT SELECT ON sample_text_type TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Ana Moita
