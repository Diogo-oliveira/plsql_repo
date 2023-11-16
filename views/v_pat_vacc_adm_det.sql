CREATE OR REPLACE VIEW V_PAT_VACC_ADM_DET  AS
SELECT id_pat_vacc_adm_det,
       id_pat_vacc_adm,
       dt_take,
       id_episode,
       flg_status,
       dt_cancel,
       notes_cancel,
       desc_vaccine,
       lot_number,
       dt_expiration,
       flg_advers_react,
       notes_advers_react,
       application_spot,
       report_orig,
       pvad.notes,
       emb_id,
       pvad.id_unit_measure,
       id_prof_writes,
       dt_reg,
       dt_next_take,
       id_vacc_manufacturer,
       flg_reported,
       id_information_source,
       id_vacc_funding_cat,
       id_vacc_funding_source,
       id_vacc_doc_vis,
       doc_vis_desc,
       id_vacc_origin,
       origin_desc,
       vacc_route_data,
       id_administred,
       administred_desc,
       dt_doc_delivery_tstz,
       id_vacc_adv_reaction,
       application_spot_code,
       id_cancel_reason,
       suspended_notes,
       id_reason_sus,
       dt_suspended,
       mm.code_cvx
  FROM pat_vacc_adm_det pvad
  left join mi_med mm on mm.id_drug = pvad.emb_id and mm.vers = pvad.vers;
