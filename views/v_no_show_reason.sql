CREATE OR REPLACE VIEW V_NO_SHOW_REASON AS
SELECT crsi.id_cancel_reason, crsi.id_institution, crsi.id_software, 
       crsi.id_profile_template, crsi.flg_available,
			 cr.code_cancel_reason, cr.id_content
FROM cancel_rea_soft_inst crsi, cancel_reason cr, cancel_rea_area cra
WHERE cr.id_cancel_reason = crsi.id_cancel_reason
  AND cr.id_cancel_rea_area = cra.id_cancel_rea_area
	AND cra.intern_name = 'PATIENT_NO_SHOW';


CREATE OR REPLACE VIEW V_NO_SHOW_REASON AS
SELECT cr.id_cancel_reason, cr.code_cancel_reason, cr.id_cancel_rea_area, cr.id_content
FROM cancel_reason cr, cancel_rea_area cra
WHERE cr.id_cancel_rea_area = cra.id_cancel_rea_area
  AND cra.intern_name = 'PATIENT_NO_SHOW';
  
-- CHANGED BY: Sergio Dias
-- CHANGE DATE: 29-04-2011
-- CHANGE REASON: ALERT-175337
DROP VIEW V_NO_SHOW_REASON;
-- CHANGE END
