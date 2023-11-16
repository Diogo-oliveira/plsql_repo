create or replace view v_ab_prof_soft_inst as
select ab.id_ab_soft_inst_user_info id_prof_soft_inst,
       ab.id_ab_user_info           id_professional,
       ab.id_ab_software            id_software,
       ab.id_ab_institution         id_institution,
       flg_log,
       id_department,
       dt_log_tstz
  from alert_core_data.ab_soft_inst_user_info ab
  where ab.record_status = 'A';
