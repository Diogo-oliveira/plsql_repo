create or replace view diagnosis_dep_clin_serv
select id_diagnosis_dep_clin_serv,
       id_dep_clin_serv,
       id_diagnosis,
       rank,
       adw_last_update,
       flg_type,
       id_institution,
       id_software,
       id_professional,
       id_alert_diagnosis,
       null id_diag_inst_owner,
       null id_adiag_inst_owner
  from mig_diagnosis_dep_clin_serv;