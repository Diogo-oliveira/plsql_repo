-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 19-Jul-2010
-- CHANGE REASON: ALERT-112811
GRANT SELECT ON organ_tissue_donation TO alert_viewer;
-- CHANGE END: Paulo Fonseca

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.ORGAN_TISSUE_DONATION to alert_reset;
-- CHANGE END: Ana Coelho