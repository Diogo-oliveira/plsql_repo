create or replace view V_AIH_EXTCAUSES_DIAGNOSES as
SELECT t.id_concept_term        id_alert_diagnosis,
       t.code                   code_icd,
       t.desc_translation,
       t.term_type,
       t.rank,
       t.code_translation       code_diagnosis,
       t.relevance,
       t.position_rank,
       t.id_concept_version     id_diagnosis,
       t.id_terminology_version
  FROM alert_core_data.v_ts1_terms_ea t
 WHERE alert_core_func.pk_ts1_api.set_ts_context(i_lang            => sys_context('ALERT_CONTEXT',
                                                                                  'PK_TERM_SEARCH.LANG'),
                                                 i_concept_type    => 'DIAGNOSIS',
                                                 i_id_task_type    => 63,
                                                 i_id_institution  => sys_context('ALERT_CONTEXT',
                                                                                  'PK_TERM_SEARCH.INSTITUTION'),
                                                 i_id_software     => sys_context('ALERT_CONTEXT',
                                                                                  'PK_TERM_SEARCH.SOFTWARE'),
                                                 i_id_professional => -1,
                                                 i_id_category     => -1,
                                                 i_text_search     => sys_context('ALERT_CONTEXT',
                                                                                  'PK_TERM_SEARCH.TEXT_SEARCH'),
                                                 i_format_text     => 'Y',
                                                 i_id_patient => sys_context('ALERT_CONTEXT',
                                                                                  'PK_TERM_SEARCH.PATIENT')) = 1;
