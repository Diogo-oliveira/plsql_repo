CREATE OR REPLACE VIEW v_interv_prescription_detail AS
SELECT ipd.id_interv_presc_det,
       ipd.id_interv_prescription,
       ipd.id_intervention,
       i.code_intervention,
       ipd.code_intervention_alias,
       i.id_content,
       i.flg_type,
       i.barcode,
       ipd.flg_status,
       ipd.flg_referral,
       ipd.dt_interv_presc_det,
       ipd.dt_pend_req_tstz,
       ipd.dt_order_tstz,
       ipd.dt_begin_tstz,
       ipd.dt_end_tstz,
       ipd.id_order_recurrence,
       ipd.flg_prty,
       ipd.flg_prn,
       ipd.prn_notes,
       ipd.flg_fasting,
       ipd.id_clinical_purpose,
       ipd.clinical_purpose_notes,
       ipd.flg_laterality,
       ipd.id_exec_institution,
       ipd.id_movement,
       ipd.notes,
       ipd.id_not_order_reason,
       ipd.id_interv_codification,
       ipd.id_pat_health_plan,
       ipd.id_pat_exemption,
       ipd.id_cdr_event,
       ipd.id_co_sign_order,
       ipd.id_nurse_actv_req_det,
       ipd.id_presc_plan_task,
       ipd.id_prof_cancel,
       ipd.dt_cancel_tstz,
       ipd.id_cancel_reason,
       ipd.notes_cancel,
       cr.code_cancel_reason,
       ipd.id_co_sign_cancel,
       ipd.flg_req_origin_module,
       ipd.id_prof_last_update,
       ipd.dt_last_update_tstz,
       'P' flg_context
  FROM interv_presc_det ipd
  JOIN intervention i
    ON ipd.id_intervention = i.id_intervention
  LEFT JOIN cancel_reason cr
    ON ipd.id_cancel_reason = cr.id_cancel_reason;
