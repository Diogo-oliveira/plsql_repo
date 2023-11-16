CREATE OR REPLACE VIEW V_EXAMS_SELECTION AS
SELECT *
  FROM TABLE(pk_exam_core.get_exam_selection_list(i_lang          => alert_context('i_lang'),
                                                  i_prof          => profissional(alert_context('i_prof_id'),
                                                                                  alert_context('i_prof_institution'),
                                                                                  alert_context('i_prof_software')),
                                                  i_patient       => alert_context('i_patient'),
                                                  i_episode       => alert_context('i_episode'),
                                                  i_exam_type     => alert_context('i_exam_type'),
                                                  i_flg_type      => alert_context('i_flg_type'),
                                                  i_codification  => alert_context('i_codification'),
                                                  i_dep_clin_serv => alert_context('i_dep_clin_serv')));
