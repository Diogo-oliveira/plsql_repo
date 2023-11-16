CREATE OR REPLACE VIEW V_CLINICAL_SERVICE AS
select cs.id_clinical_service, 
       cs.id_clinical_service_parent, 
       cs.code_clinical_service, 
       cs.image_name, 
       cs.flg_available, 
       cs.id_content, 
       cs.abbreviation,
	   cs.rank
  from clinical_service cs;