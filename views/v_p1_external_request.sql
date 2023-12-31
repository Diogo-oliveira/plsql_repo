CREATE OR REPLACE VIEW V_P1_EXTERNAL_REQUEST AS
SELECT id_external_request,
       id_patient,
       id_dep_clin_serv,
       id_schedule,
       id_prof_requested,
       num_req,
       flg_status,
       flg_digital_doc,
       flg_mail,
       flg_paper_doc,
       flg_priority,
       flg_type,
       id_inst_dest,
       id_inst_orig,
       req_type,
       flg_home,
       decision_urg_level,
       id_prof_status,
       id_speciality,
       flg_import,
       dt_last_interaction_tstz,
       NULL dt_probl_begin_tstz, -- to be removed
       dt_status_tstz,
       dt_requested,
       flg_interface,
       id_episode,
       flg_forward_dcs,
       id_workflow,
       id_prof_redirected,
       ext_reference,
       id_external_sys,
       flg_migrated,
       year_begin,
       month_begin,
       day_begin,
			 print_nr
  FROM p1_external_request;
