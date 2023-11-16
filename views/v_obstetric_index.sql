

CREATE OR REPLACE VIEW v_obstetric_index AS
SELECT *
  FROM (SELECT patient0_.id_patient AS id_patient,
               SUM(CASE
                        WHEN patpregnan1_.flg_status = 'P'
                             AND (patpregnan1_.dt_intervention IS NOT NULL)
                             AND (patpregnan1_.dt_init_pregnancy IS NOT NULL)
                             AND nvl(patpregnan1_.flg_dt_interv_precision, 'H') IN ('D', 'H')
                             AND patpregnan1_.dt_intervention - patpregnan1_.dt_init_pregnancy >=
                             numtodsinterval(37 * 7, 'DAY') THEN
                         1
                        WHEN patpregnan1_.flg_status = 'P'
                             AND (patpregnan1_.num_gest_weeks IS NOT NULL)
                             AND patpregnan1_.num_gest_weeks >= 37 THEN
                         1
                        ELSE
                         0
                    END) AS term,
               SUM(CASE
                        WHEN patpregnan1_.flg_status = 'P'
                             AND (patpregnan1_.dt_intervention IS NOT NULL)
                             AND (patpregnan1_.dt_init_pregnancy IS NOT NULL)
                             AND nvl(patpregnan1_.flg_dt_interv_precision, 'H') IN ('D', 'H')
                             AND
                             patpregnan1_.dt_intervention - patpregnan1_.dt_init_pregnancy < numtodsinterval(37 * 7, 'DAY') THEN
                         1
                        WHEN patpregnan1_.flg_status = 'P'
                             AND (patpregnan1_.num_gest_weeks IS NOT NULL)
                             AND patpregnan1_.num_gest_weeks < 37 THEN
                         1
                        ELSE
                         0
                    END) AS preterm,
               SUM(CASE
                        WHEN patpregnan1_.flg_status NOT IN ('A', 'C', 'P','AC') THEN
                         1
                        ELSE
                         0
                    END) AS abortions,
               (SELECT COUNT(patpregnfe2_.id_pat_pregnancy)
                  FROM pat_pregn_fetus patpregnfe2_
                 INNER JOIN pat_pregnancy patpregnan3_ ON patpregnfe2_.id_pat_pregnancy = patpregnan3_.id_pat_pregnancy
                 WHERE patpregnan3_.id_patient = patient0_.id_patient
                   AND patpregnan3_.flg_status <> 'C'
                   AND patpregnfe2_.flg_status IN ('A', 'AN')) AS live_children,
               SUM(CASE
                        WHEN instr(pk_sysconfig.get_config('PREGNANCY_INDUCED_ABORTIONS', profissional(0, 0, 0)),
                                   '|' || patpregnan1_.flg_status || '|') != 0 THEN
                         1
                        ELSE
                         0
                    END) AS induced_abortions,
               SUM(CASE
                        WHEN instr(pk_sysconfig.get_config('PREGNANCY_SPONTANEOUS_ABORTIONS', profissional(0, 0, 0)),
                                   '|' || patpregnan1_.flg_status || '|') != 0 THEN
                         1
                        ELSE
                         0
                    END) AS spontaneous_abortions,
               SUM(CASE
                        WHEN patpregnan1_.flg_status <> 'C' THEN
                         1
                        ELSE
                         0
                    END) AS gravida,
               SUM(CASE
                        WHEN patpregnan1_.flg_status = 'P' THEN
                         1
                        ELSE
                         0
                    END) AS para
          FROM patient patient0_
          LEFT OUTER JOIN pat_pregnancy patpregnan1_ ON patient0_.id_patient = patpregnan1_.id_patient
         GROUP BY patient0_.id_patient);
/

