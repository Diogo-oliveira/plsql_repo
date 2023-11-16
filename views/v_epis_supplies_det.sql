CREATE OR REPLACE VIEW V_EPIS_SUPPLIES_DET
AS
SELECT es.id_epis_supplies, 
       es.id_episode, 
       es.id_epis_context, 
       es.flg_type, 
       es.flg_status, 
       es.dt_creation, 
       es.id_professional, 
       es.dt_cancel, 
       es.id_prof_cancel,
       esd.id_epis_supplies_det, 
       esd.id_supplies, 
       esd.qty, 
       esd.notes,
			 s.code_supplies,
			 s.flg_available,
			 s.id_content
FROM SUPPLIES s, EPIS_SUPPLIES es, EPIS_SUPPLIES_DET esd
WHERE es.id_epis_supplies = esd.id_epis_supplies
AND esd.id_supplies = s.id_supplies;
