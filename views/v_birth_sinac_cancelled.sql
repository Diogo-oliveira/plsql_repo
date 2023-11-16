CREATE OR REPLACE VIEW v_birth_sinac_cancelled AS
SELECT preg.id_pat_pregnancy,
       edoc.child_number,
       echild.id_institution,
       ph.code_birth_certificate folio,
       pk_backoffice.get_inst_field(NULL, NULL, echild.id_institution, 'CLUES') clues,
       'SIN INFORMACION' motivo,
       ph.operation_time fecha, 
       preg.id_patient id_patient_mother
  FROM (SELECT row_number() over(PARTITION BY pp.id_patient ORDER BY pp.n_pregnancy DESC) pregnancy_rn,
               pp.id_pat_pregnancy, pp.id_patient
          FROM pat_pregnancy pp
         WHERE pp.flg_status NOT IN ('C', 'A')) preg
  JOIN (SELECT edoc.id_child_episode, edoc.child_number, edoc.id_pat_pregnancy
          FROM epis_doc_delivery edoc
         WHERE edoc.id_child_episode IS NOT NULL) edoc
    ON edoc.id_pat_pregnancy = preg.id_pat_pregnancy
  JOIN episode echild
    ON echild.id_episode = edoc.id_child_episode
  JOIN patient patchild
    ON patchild.id_patient = echild.id_patient
  JOIN patient_hist ph
    ON patchild.id_patient = ph.id_patient
   AND ph.code_birth_certificate <> patchild.code_birth_certificate;
