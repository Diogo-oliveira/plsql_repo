CREATE OR REPLACE VIEW V_LAB_TESTS_SELECTION AS
SELECT *
  FROM TABLE(pk_lab_tests_core.get_lab_test_selection_list(i_lang         => alert_context('i_lang'),
                                                           i_prof         => profissional(alert_context('i_prof_id'),
                                                                                          alert_context('i_prof_institution'),
                                                                                          alert_context('i_prof_software')),
                                                           i_patient      => alert_context('i_patient'),
                                                           i_episode      => alert_context('i_episode'),
                                                           i_flg_type     => alert_context('i_flg_type'),
                                                           i_codification => alert_context('i_codification'),
                                                           i_analysis_req => alert_context('i_analysis_req'),
                                                           i_harvest      => alert_context('i_harvest')));
