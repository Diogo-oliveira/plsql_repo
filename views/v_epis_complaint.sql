CREATE OR REPLACE VIEW V_EPIS_COMPLAINT AS
SELECT ID_EPIS_COMPLAINT,
       ID_EPISODE,
       ID_PROFESSIONAL,
       ID_COMPLAINT,
       PATIENT_COMPLAINT,	
       FLG_STATUS,
       ID_EPIS_COMPLAINT_PARENT,	
       FLG_REPORTED_BY,	
       ID_EPIS_COMPLAINT_ROOT,	
       ID_DEP_CLIN_SERV,	
       FLG_EDITION_TYPE
FROM epis_complaint;
 
