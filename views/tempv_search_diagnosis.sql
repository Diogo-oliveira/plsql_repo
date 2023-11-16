create or replace view search_diagnosis
select null id_diagnosis,
       null id_diagnosis_parent,
       null code_diagnosis,
       null code_icd,
       null flg_select,
       null flg_job,
       null flg_available,
       null adw_last_update,
       null flg_type,
       null flg_other,
       null gender,
       null age_min,
       null age_max,
       null mdm_coding,
       null flg_family,
       null flg_pos_birth,
       null flg_subtype,
       null id_content,
       null concept_type_int_name
  from dual;