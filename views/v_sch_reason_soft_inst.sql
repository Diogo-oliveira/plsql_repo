-- CHANGED BY: Miguel Monteiro
-- CHANGE DATE: 2020-03-03
-- CHANGE REASON: [Subtask] New Home Health Care Approve and Undo Reasons
CREATE OR REPLACE VIEW V_SCH_REASON_SOFT_INST AS
SELECT crsi.id_cancel_reason, crsi.id_institution, crsi.id_software,
       crsi.id_profile_template, crsi.id_cancel_rea_area, crsi.flg_available,
       cr.code_cancel_reason, cr.id_content, cra.intern_name
FROM cancel_rea_soft_inst crsi, cancel_reason cr, cancel_rea_area cra
WHERE cr.id_cancel_reason = crsi.id_cancel_reason
  AND crsi.id_cancel_rea_area = cra.id_cancel_rea_area
  AND cra.intern_name IN ('PATIENT_NO_SHOW','HHC_VISITS_REA_APPROVAL','HHC_VISITS_REA_UNDO');
-- CHANGE END: Miguel Monteiro