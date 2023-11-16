CREATE OR REPLACE view v_ref_orig_inst AS
-- external referrals
SELECT 1 rank,
       i.id_institution id_inst_orig,
       i.ext_code orig_ext_code,
       i.code_institution orig_code_institution,
       'T' desc_type,
       v.id_speciality,
       v.id_external_sys,
       v.flg_type,
       v.id_institution
  FROM v_ref_hosp_entrance v
  JOIN institution i
    ON i.id_institution = v.id_inst_orig
 WHERE v.id_dep_clin_serv = sys_context('ALERT_CONTEXT', 'i_id_dep_clin_serv')
   AND v.id_external_sys IN (nvl(sys_context('ALERT_CONTEXT', 'i_id_external_sys'), 0), 0)
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution') -- professional is in dest institution! (WF=4)
   AND v.id_speciality = sys_context('ALERT_CONTEXT', 'i_id_speciality')
   AND v.flg_type = sys_context('ALERT_CONTEXT', 'i_flg_type')
   AND v.id_inst_orig != 0
UNION ALL
-- other
SELECT 0 rank,
       i.id_institution id_inst_orig,
       i.code_institution orig_ext_code,
       sys_context('ALERT_CONTEXT', 'g_sm_ref_grid_t032') orig_code_institution,
       'M' desc_type,
       to_number(sys_context('ALERT_CONTEXT', 'i_id_speciality')) id_speciality,
       NULL id_external_sys,
       sys_context('ALERT_CONTEXT', 'i_flg_type') flg_type,
       to_number(sys_context('ALERT_CONTEXT', 'i_id_institution')) id_institution
  FROM institution i
 WHERE i.id_institution = to_number(sys_context('ALERT_CONTEXT', 'g_id_ref_external_inst'));