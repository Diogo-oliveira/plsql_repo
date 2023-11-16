CREATE OR REPLACE VIEW v_sr_intervention AS
SELECT i.id_intervention    id_sr_intervention,
       NULL                 id_interv_parent,
       i.code_intervention  code_sr_intervention,
       i.flg_status,
       i.flg_type,
       i.duration,
       i.prev_recovery_time,
       NULL                 gdh,
       ic.standard_code     icd,
       i.gender,
       i.age_min,
       i.age_max,
       i.cost,
       i.price,
       i.id_system_organ,
       NULL                 id_speciality,
       i.adw_last_update,
       NULL                 flg_coding,
       i.id_content
  FROM intervention i
  LEFT JOIN interv_codification ic
    ON i.id_intervention = ic.id_intervention
 WHERE instr(i.flg_type, 'S') > 0;
