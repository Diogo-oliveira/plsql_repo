-->V_VITAL_SIGN_READ
CREATE OR REPLACE VIEW V_VITAL_SIGN_READ AS
SELECT id_vital_sign_read,
       id_episode,
       VALUE,
       flg_state,
       id_epis_triage,
       id_prof_read,
       dt_vital_sign_read_tstz,
       id_prof_cancel,
       dt_cancel_tstz,
       vsr.id_vital_sign,
       code_vital_sign,
       um.id_unit_measure,
       code_unit_measure,
       code_unit_measure_abrv
  FROM vital_sign_read vsr,vital_sign vs,unit_measure um
 WHERE vsr.id_vital_sign = vs.id_vital_sign
   AND vsr.id_unit_measure = um.id_unit_measure;

CREATE OR REPLACE VIEW V_VITAL_SIGN_READ AS
SELECT id_vital_sign_read,
       vsr.id_episode,
       VALUE,
       flg_state,
       id_epis_triage,
       id_prof_read,
       dt_vital_sign_read_tstz,
       id_prof_cancel,
       dt_cancel_tstz,
       vsr.id_cancel_reason,
       vsr.notes_cancel,
       vsr.id_vital_sign,
       code_vital_sign,
       um.id_unit_measure,
       code_unit_measure,
       code_unit_measure_abrv,
       vsr.id_vs_scales_element,
       vsr.id_vital_sign_notes,
       vsm.notes   
  FROM vital_sign_read vsr,vital_sign vs,unit_measure um, vital_sign_notes vsm
 WHERE vsr.id_vital_sign = vs.id_vital_sign
   AND vsr.id_unit_measure = um.id_unit_measure
   and vsr.id_vital_sign_notes = vsm.id_vital_sign_notes(+);   
