CREATE OR REPLACE VIEW v_intervention AS
SELECT i.id_intervention,
       i.id_intervention_parent,
       i.code_intervention,
       i.flg_status,
       i.cost,
       i.price,
       i.code_help_interv,
       i.rank,
       i.adw_last_update,
       i.id_body_part,
       i.flg_mov_pat,
       i.gender,
       i.age_min,
       i.age_max,
       i.mdm_coding,
       i.cpt_code,
       i.id_spec_sys_appar,
       i.ref_form_code,
       i.flg_type,
       i.id_content,
       i.barcode,
       i.flg_category_type,
       i.flg_technical,
       i.prev_recovery_time,
       i.id_system_organ
  FROM intervention i;