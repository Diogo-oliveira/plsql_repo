CREATE OR REPLACE VIEW v_procedures_search AS
SELECT *
  FROM TABLE(pk_procedures_core.get_procedure_search(i_lang           => alert_context('i_lang'),
                                                     i_prof           => profissional(alert_context('i_prof_id'),
                                                                                      alert_context('i_prof_institution'),
                                                                                      alert_context('i_prof_software')),
                                                     i_patient        => alert_context('i_patient'),
                                                     i_procedure_type => alert_context('i_procedure_type'),
                                                     i_flg_type       => alert_context('i_flg_type'),
                                                     i_codification   => alert_context('i_codification'),
                                                     i_dep_clin_serv  => alert_context('i_dep_clin_serv'),
                                                     i_value          => alert_context('i_value')));
