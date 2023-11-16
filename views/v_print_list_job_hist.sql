CREATE OR REPLACE VIEW V_PRINT_LIST_JOB_HIST AS
SELECT id_print_list_job_hist,
       id_print_list_job,
       id_print_list_area,
       print_arguments,
       id_workflow,
       id_status,
       dt_status,
       id_prof_status,
       id_patient,
       id_episode,
       id_prof_req,
       id_inst_req,
       dt_req,
       context_data
  FROM print_list_job_hist;
