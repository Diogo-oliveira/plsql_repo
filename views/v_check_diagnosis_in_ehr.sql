CREATE OR REPLACE VIEW v_check_diagnosis_in_ehr AS
    SELECT phd.id_pat_history_diagnosis id_problem,
           decode(phd.id_alert_diagnosis, NULL, 'PP', 'RD') flg_source,
           phd.dt_pat_history_diagnosis_tstz dt_problem,
           phd.id_diagnosis,
           phd.id_patient,
           phd.id_institution,
					 phd.id_alert_diagnosis,
					 d.id_concept,
					 d.code_icd,
					 d.flg_other
      FROM pat_history_diagnosis phd
      JOIN diagnosis d
        ON phd.id_diagnosis = d.id_diagnosis
     WHERE phd.flg_type = 'M'
  		  AND phd.id_pat_history_diagnosis_new IS NULL
       AND phd.flg_status IN ('A', 'P')
       AND phd.id_pat_history_diagnosis = pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
       AND NOT EXISTS (SELECT 1
              FROM pat_problem pp
              LEFT JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
              LEFT JOIN diagnosis d1
                ON pp.id_diagnosis = d1.id_diagnosis
             WHERE pp.flg_status IN ('A', 'P')
               AND pp.id_diagnosis = phd.id_diagnosis
               AND pp.id_patient = phd.id_patient
               AND pp.id_habit IS NULL
               AND ( --final diagnosis
                    (ed.flg_type = 'D') --
                    OR -- differencial diagnosis only
                    (ed.flg_type = 'P' AND
                    ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                               FROM epis_diagnosis ed3
                                              WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                AND ed3.id_patient = pp.id_patient
                                                AND ed3.flg_type = 'D')) --
                    OR -- não é um diagnóstico
                    (pp.id_habit IS NOT NULL))
               AND pp.flg_status <> 'E'
               AND pp.dt_pat_problem_tstz > phd.dt_pat_history_diagnosis_tstz
               AND rownum = 1)
    UNION ALL
    -- PAT_PROBLEM SECTION
    SELECT pp.id_pat_problem id_problem,
           decode(pp.desc_pat_problem,
                  '',
                  decode(pp.id_habit, '', decode(nvl(ed.id_epis_diagnosis, 0), 0, 'RD', 'D'), 'H'),
                  decode(pp.id_diagnosis, NULL, 'PP', 'RD')) flg_source,
           pp.dt_pat_problem_tstz dt_problem,
           pp.id_diagnosis,
           pp.id_patient,
           pp.id_institution,
					 pp.id_alert_diagnosis,
					 d.id_concept,
					 d.code_icd,
					 d.flg_other					
      FROM pat_problem pp
      JOIN diagnosis d
        ON pp.id_diagnosis = d.id_diagnosis
      LEFT JOIN epis_diagnosis ed
        ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
     WHERE pp.flg_status IN ('A', 'P')
       AND pp.id_habit IS NULL
       AND ed.id_epis_diagnosis = pp.id_epis_diagnosis
       AND ( --final diagnosis
            (ed.flg_type = 'D') --
            OR -- differencial diagnosis only
            (ed.flg_type = 'P' AND
            ed.id_diagnosis NOT IN (SELECT ed3.id_diagnosis
                                       FROM epis_diagnosis ed3
                                      WHERE ed3.id_diagnosis = ed.id_diagnosis
                                        AND ed3.id_patient = pp.id_patient
                                        AND ed3.flg_type = 'D')))
       AND pp.flg_status <> 'E'
       AND NOT EXISTS
     (SELECT 1
              FROM pat_history_diagnosis phd
             WHERE phd.id_patient = pp.id_patient
               AND phd.flg_type = 'M'
               AND phd.flg_status IN ('A', 'P')
               AND phd.id_diagnosis = pp.id_diagnosis
               AND phd.id_pat_history_diagnosis = pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
               AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
               AND rownum = 1);

