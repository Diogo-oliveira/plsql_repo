CREATE OR REPLACE VIEW V_EPIS_DIET_REQ AS
SELECT edr.id_epis_diet_req,
       edr.id_diet_type,
       dt.code_diet_type,       
       edr.id_episode,
       edr.id_patient,
       edr.id_professional,
       edr.desc_diet,
       edr.flg_status,
       edr.notes,
       edr.food_plan,
       edr.flg_help,
       edr.dt_creation,
       edr.dt_inicial,
       edr.dt_end,
       edr.id_prof_cancel,
       edr.notes_cancel,
       edr.id_cancel_reason,       
       cr.code_cancel_reason,
       edr.dt_cancel,
       edr.flg_institution,       
       edr.id_epis_diet_req_parent,
       edr.dt_initial_suspend,
       edr.dt_end_suspend,
       edr.resume_notes
  FROM epis_diet_req edr
  JOIN diet_type dt
    ON dt.id_diet_type = edr.id_diet_type
  LEFT JOIN cancel_reason cr
    ON cr.id_cancel_reason = edr.id_cancel_reason;
