-- CHANGED BY:  Tiago Silva
-- CHANGE DATE: 07/11/2013
-- CHANGE REASON: [ALERT-269058]
grant execute on t_rec_mapping_conc to alert_inter with grant option;
-- CHANGE END:  Tiago Silva

-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 16/06/2014 18:21
-- CHANGE REASON: [ALERT-286096] Dev DB - CDA Section: Medication allergies
begin
pk_versioning.run('GRANT EXECUTE ON t_rec_mapping_conc TO alert_inter');
end;
/
-- CHANGE END:  Gisela Couto