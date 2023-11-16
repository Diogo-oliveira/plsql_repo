CREATE OR REPLACE VIEW v_procedures_selection AS
SELECT *
  FROM TABLE(pk_procedures_core.get_procedure_selection_list(i_lang              => alert_context('i_lang'),
                                                             i_prof              => profissional(alert_context('i_prof_id'),
                                                                                                 alert_context('i_prof_institution'),
                                                                                                 alert_context('i_prof_software')),
                                                             i_patient           => alert_context('i_patient'),
                                                             i_episode           => alert_context('i_episode'),
                                                             i_flg_type          => alert_context('i_flg_type'),
                                                             i_flg_filter        => alert_context('i_flg_filter'),
                                                             i_codification      => alert_context('i_codification')));
