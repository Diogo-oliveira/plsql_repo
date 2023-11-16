create or replace view v_print_list_context_data as
SELECT id_print_list_job, id_print_list_area, context_data, id_patient, id_episode
  FROM print_list_job;
