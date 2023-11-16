-->V_PAT_ALLERGY
CREATE OR REPLACE VIEW ALERT.V_PAT_ALLERGY AS
SELECT pa.id_pat_allergy,
       pa.id_patient,
       pa.id_institution,
       pa.id_drug_pharma,
       pa.flg_status,
       pa.flg_type,
       pa.flg_aproved,
       pa.dt_pat_allergy_tstz,
       pa.dt_first_time_tstz,
       pa.id_allergy,
       A.ID_CONTENT AS ID_CONTENT_ALLERGY,
       pa.year_begin,
       pa.month_begin,
       pa.day_begin,
       a.code_allergy,
       a.flg_without,
       a.flg_other,
       a.id_allergy_parent,
       pa.desc_allergy,
       pa.notes,
       sev.id_allergy_severity,
       sev.id_content as ID_CONTENT_SEVERITY,
       pa.flg_edit,
       pa.desc_edit as EDIT_REASON,
       pa.id_cancel_reason,
       pa.cancel_notes       
  FROM pat_allergy pa
  LEFT JOIN allergy a on a.id_allergy = pa.id_allergy
  LEFT JOIN allergy_severity sev
    ON sev.id_allergy_severity = pa.id_allergy_severity;
