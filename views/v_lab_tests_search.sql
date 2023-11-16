CREATE OR REPLACE VIEW V_LAB_TESTS_SEARCH AS
SELECT *
  FROM TABLE(pk_lab_tests_core.get_lab_test_search(i_lang         => alert_context('i_lang'),
                                                    i_prof         => profissional(alert_context('i_prof_id'),
                                                                                   alert_context('i_prof_institution'),
                                                                                   alert_context('i_prof_software')),
                                                    i_patient      => alert_context('i_patient'),
                                                    i_codification => alert_context('i_codification'),
                                                    i_analysis_req => alert_context('i_analysis_req'),
                                                    i_harvest      => alert_context('i_harvest'),
                                                    i_value        => alert_context('i_value')));
