CREATE OR REPLACE VIEW V_DIAGNOSIS_CONTENT AS
SELECT a.id_diagnosis,
       a.id_diagnosis_parent,
       a.id_alert_diagnosis,
       a.code_icd,
       a.id_language,
       a.code_translation,
       a.flg_other,
       a.flg_icd9,
       a.flg_select,
       a.id_dep_clin_serv,
       a.flg_terminology,
       a.rank
  FROM (SELECT d.id_concept_version id_diagnosis,
               CAST((SELECT id_concept_version_2
                       FROM diagnosis_relations_ea dr
                      WHERE dr.cncpt_rel_type_int_name = 'IS_A'
                        AND dr.concept_type_int_name1 = dr.concept_type_int_name2
                        AND dr.id_concept_version_1 = d.id_concept_version
                        AND dr.id_institution = d.id_institution
                        AND dr.id_software = d.id_software) AS NUMBER(24)) id_diagnosis_parent,
               d.id_concept_term id_alert_diagnosis,
               d.concept_code code_icd,
               d.id_language,
               decode(sys_context('ALERT_CONTEXT', 'TERM_TASK_TYPE'),
                      60,
                      d.code_problems,
                      62,
                      d.code_medical,
                      61,
                      d.code_surgical,
                      64,
                      d.code_cong_anomalies,
                      d.code_diagnosis) code_translation,
               d.flg_other,
               d.flg_icd9,
               d.flg_select,
               d.id_dep_clin_serv,
               d.flg_terminology,
               d.gender,
               d.age_min,
               d.age_max,
               d.rank
          FROM diagnosis_ea d
         WHERE rownum > 0 --DUMMY CONDITION IN ORDER TO PREVENT PERFORMANCE ISSUES
           AND d.flg_is_diagnosis = 'Y'
              --Content for the current inst., soft. and area
           AND d.id_institution = sys_context('ALERT_CONTEXT', 'INSTITUTION')
           AND d.id_software = sys_context('ALERT_CONTEXT', 'SOFTWARE')
           AND d.flg_terminology IN (SELECT *
                                       FROM TABLE(:tbl_flg_terminologies)) --('U', 'S')--                               
           AND d.flg_diag_type = sys_context('ALERT_CONTEXT', 'FLG_TYPE_ALERT_DIAGNOSIS')
           AND d.flg_msi_concept_term = sys_context('ALERT_CONTEXT', 'FLG_TYPE_DEP_CLIN')) a
 WHERE ((nvl(sys_context('ALERT_CONTEXT', 'ONLY_DIAG_FILTER_BY_PRT'), 'N') = 'N' AND a.flg_select = 'Y') OR
       (sys_context('ALERT_CONTEXT', 'ONLY_DIAG_FILTER_BY_PRT') = 'Y'))
   AND (sys_context('ALERT_CONTEXT', 'SYNONYM_LIST_ENABLE') = 'Y' OR a.flg_icd9 = 'Y')
   AND ((sys_context('ALERT_CONTEXT', 'INCLUDE_OTHER_DIAGNOSIS') = 'Y') OR
       (sys_context('ALERT_CONTEXT', 'INCLUDE_OTHER_DIAGNOSIS') = 'N' AND a.flg_other != 'Y'))
   AND (sys_context('ALERT_CONTEXT', 'ONLY_OTHER_DIAGS') = 'N' OR
       (sys_context('ALERT_CONTEXT', 'ONLY_OTHER_DIAGS') = 'Y' AND a.flg_other = 'Y'))
      --DIAGNOSES AGE AND GENDER FILTERS
   AND ((sys_context('ALERT_CONTEXT', 'PAT_GENDER') IS NOT NULL AND
       nvl(a.gender, 'I') IN ('I', sys_context('ALERT_CONTEXT', 'PAT_GENDER'))) OR
       sys_context('ALERT_CONTEXT', 'PAT_GENDER') IS NULL OR
       sys_context('ALERT_CONTEXT', 'PAT_GENDER') IN ('I', 'U', 'N'))
   AND ((sys_context('ALERT_CONTEXT', 'VALIDATE_MAX_AGE') = 'Y' AND
       nvl(sys_context('ALERT_CONTEXT', 'PAT_AGE'), 0) BETWEEN nvl(a.age_min, 0) AND
       nvl(a.age_max, nvl(sys_context('ALERT_CONTEXT', 'PAT_AGE'), 0))) OR
       (sys_context('ALERT_CONTEXT', 'VALIDATE_MAX_AGE') = 'N' AND
       nvl(sys_context('ALERT_CONTEXT', 'PAT_AGE'), 0) >= nvl(a.age_min, 0)) OR
       nvl(sys_context('ALERT_CONTEXT', 'PAT_AGE'), 0) = 0)
      --AVAILABLITITY OF THE DESCRIPTION FILTER
   AND a.code_translation IS NOT NULL
      --
   AND ((nvl(sys_context('ALERT_CONTEXT', 'ONLY_DIAG_FILTER_BY_PRT'), 'N') = 'N' AND
       nvl(a.id_diagnosis_parent, 0) =
       nvl(sys_context('ALERT_CONTEXT', 'PARENT_DIAGNOSIS'), nvl(a.id_diagnosis_parent, 0))) --
       OR (sys_context('ALERT_CONTEXT', 'ONLY_DIAG_FILTER_BY_PRT') = 'Y' AND
       nvl(a.id_diagnosis_parent, 0) = nvl(sys_context('ALERT_CONTEXT', 'PARENT_DIAGNOSIS'), 0)))
