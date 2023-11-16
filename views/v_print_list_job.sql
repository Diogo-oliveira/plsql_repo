CREATE OR REPLACE VIEW V_PRINT_LIST_JOB AS
SELECT id_print_list_job,
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
       dt_req
  FROM print_list_job p
 WHERE p.id_print_list_area <> 10
    OR ((SELECT pk_lab_tests_external.get_lab_test_infect_pl(0,
                                                             profissional(sys_context('ALERT_CONTEXT', 'PROF_ID'),
                                                                          sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                          sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                             p.context_data)
           FROM dual) = 'Y');