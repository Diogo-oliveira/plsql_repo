-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 26/05/2010 12:27
-- CHANGE REASON: [ALERT-100335] 
GRANT REFERENCES ON diet_type TO alert_default ;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY:  Diogo Oliveira
GRANT SELECT ON diet_type TO ALERT_INTER;
-- CHANGE END:  Diogo Oliveira


-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-6-13
-- CHANGED REASON: EMR-1425

grant select on alert.diet_type to alert_core_cnt with grant option;
-- CHANGE END: Ricardo Meira
