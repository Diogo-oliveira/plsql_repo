BEGIN
    --Migration of content not needed to be in NZD
    INSERT INTO diagnosis_conf_ea
        SELECT pk_api_diagnosis_func.get_ea_flg_terminology(mtv.id_terminology) flg_terminology,
               mtv.id_language,
               mtv.id_task_type,
               decode(mtv.id_task_type,
                      60,
                      'Problems',
                      61,
                      'SurgicalHistory',
                      62,
                      'Medicalhistory',
                      63,
                      'Diagnoses',
                      64,
                      'CongenitalAnomalies') task_type_internal_name,
               mtv.id_institution,
               mtv.id_software
          FROM (SELECT /*+ opt_estimate (table a rows=5)*/
                DISTINCT a.id_terminology,
                         a.version,
                         a.id_terminology_mkt,
                         a.id_language,
                         a.id_institution,
                         io.id_software,
                         a.id_task_type
                  FROM (SELECT b.id_institution, b.id_software
                          FROM (SELECT DISTINCT d.id_institution, d.id_software
                                  FROM alert.diagnosis_ea d
                                 WHERE d.id_institution != 0
                                   AND d.id_software != 0
                                UNION ALL
                                SELECT DISTINCT d.id_institution, d.id_software
                                  FROM alert.diagnosis_relations_ea d
                                 WHERE d.id_institution != 0
                                   AND d.id_software != 0) b) io
                 CROSS JOIN TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => io.id_institution, i_soft => io.id_software)) a
                 WHERE a.flg_active = 'Y'
                   AND a.id_task_type BETWEEN 60 AND 64) mtv
         WHERE mtv.id_software != 0
           AND mtv.id_institution != 0
           AND EXISTS
         (SELECT 1
                  FROM terminology_version tv
                  JOIN concept_version cv
                    ON cv.id_terminology_version = tv.id_terminology_version
                 WHERE tv.id_terminology = mtv.id_terminology
                   AND tv.version = mtv.version
                   AND tv.id_terminology_mkt = mtv.id_terminology_mkt
                   AND tv.id_language = mtv.id_language
                   AND pk_api_diagnosis_func.is_diagnosis(i_concept_version      => cv.id_concept_version,
                                                          i_cncpt_vrs_inst_owner => cv.id_inst_owner) = 'Y')
         ORDER BY id_task_type, flg_terminology, id_language, id_institution, id_software;

    COMMIT;
EXCEPTION
    WHEN dup_val_on_index THEN
        ROLLBACK;
        dbms_output.put_line('Already run!');
END;
/
