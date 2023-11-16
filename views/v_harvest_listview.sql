CREATE OR REPLACE VIEW V_HARVEST_LISTVIEW AS
SELECT id_harvest,
       id_analysis_harvest,
       id_analysis_req_det,
       id_analysis_req,
       id_analysis,
       id_sample_type,
       flg_status,
       harvest_num,
       flg_priority,
       id_sample_recipient,
       num_recipient,
       notes,
       id_body_location,
       flg_laterality,
       id_collection_location,
       flg_type_lab,
       id_laboratory,
       flg_clinical_question,
       min_dt_target,
       max_dt_target,
       avail_button_ok,
       avail_button_cancel,
       rank,
       analysis_rank,
       harvest_rank,
       dt_req,
       dt_pend_req,
       dt_begin_harvest,
       flg_time_harvest,
       dt_target
  FROM TABLE(pk_lab_tests_harvest_core.tf_harvest_listview(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                        sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                        sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                           sys_context('ALERT_CONTEXT', 'i_episode')));