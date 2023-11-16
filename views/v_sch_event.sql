create or replace view V_SCH_EVENT as
SELECT se.id_sch_event, se.code_sch_event, se.intern_name, se.flg_available, se.dep_type, se.flg_img, se.flg_target_professional, 
      se.flg_target_dep_clin_serv, se.flg_occurrence, se.num_max_patients, se.num_min_profs, se.num_max_profs
  FROM sch_event se;
