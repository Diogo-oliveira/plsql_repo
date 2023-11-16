CREATE OR REPLACE VIEW v_rehab_interv_search AS
SELECT id_rehab_area_interv,
       id_intervention,
       id_intervention_parent,
       id_rehab_area,
       desc_rehab_area,
       desc_interv,
       flg_has_children,
       id_rehab_session_type,
       desc_rehab_session_type,
       flg_laterality_mcdt,
       id_codification
  FROM TABLE(pk_rehab.tf_get_rehab_interv_search(i_lang            => alert_context('i_lang'),
                                                 i_prof            => profissional(alert_context('i_prof_id'),
                                                                                   alert_context('i_prof_institution'),
                                                                                   alert_context('i_prof_software')),
                                                 i_keyword         => alert_context('i_keyword'),
                                                 i_id_codification => alert_context('i_codification')));
/