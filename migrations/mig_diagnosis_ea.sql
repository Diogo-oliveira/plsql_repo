-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 30/08/2013 19:10
-- CHANGE REASON: [ALERT-264223] DB Versioning - Migration DIAGNOSIS_EA (ALERT_251640)
UPDATE diagnosis_ea d
   SET d.flg_is_diagnosis = pk_api_diagnosis_func.is_diagnosis(i_concept_version      => d.id_concept_version,
                                                               i_cncpt_vrs_inst_owner => d.id_cncpt_vrs_inst_owner);
-- CHANGE END: Alexandre Santos
