CREATE OR REPLACE VIEW PGS_UPD_PATIENT
AS
SELECT DISTINCT curp,
                folioprograma,
                tipobeneficiario,
                clave_programa,
                clave_dependencia,
                institution,
                create_time,
                tipo_operacion,
                flg_status1,
                flg_status2
  FROM (SELECT res1.curp,
               res1.folioprograma,
               res1.tipobeneficiario,
               res1.clave_programa,
               res1.clave_dependencia,
               res1.institution,
               res2.create_time,
               CASE
                    WHEN res1.flg_status = 'A'
                         AND res2.flg_status = 'I' THEN
                     'T'
                    WHEN res1.flg_status = 'I'
                         AND res2.flg_status = 'A' THEN
                     'R'
                    ELSE
                     NULL
                END AS tipo_operacion,
               res1.flg_status AS flg_status1,
               res2.flg_status AS flg_status2
          FROM (SELECT DISTINCT php.id_pat_health_plan,
                                phph.num_health_plan folioprograma,
                                ps.social_security_number curp,
                                phph.benefeciary_type tipobeneficiario,
                                pk_translation.get_translation(17, hp.code_health_plan) clave_programa,
                                phph.dependency clave_dependencia,
                                p.institution_key institution,
                                phph.create_time,
                                phph.flg_status,
                                row_number() over(PARTITION BY php.id_pat_health_plan ORDER BY php.id_health_plan, php.affiliation_number, php.affiliation_number_compl, phph.create_time) AS num_row
                  FROM patient p
                 INNER JOIN person ps
                    ON p.id_person = ps.id_person
                  LEFT JOIN person_hist psh
                    ON psh.id_person = ps.id_person
                  LEFT JOIN pat_health_plan php
                    ON php.id_patient = p.id_patient
                  LEFT JOIN health_plan hp
                    ON php.id_health_plan = hp.id_health_plan
                  LEFT JOIN alert_adtcod.pat_health_plan_hist phph
                    ON phph.id_pat_health_plan = php.id_pat_health_plan
                 WHERE phph.operation_type != 'C'
                 ORDER BY num_row) res1,
               (SELECT DISTINCT php.id_pat_health_plan,
                                php.num_health_plan folioprograma,
                                ps.social_security_number curp,
                                php.benefeciary_type tipobeneficiario,
                                hp.id_content clave_programa,
                                php.dependency clave_dependencia,
                                p.institution_key institution,
                                phph.create_time,
                                phph.flg_status,
                                row_number() over(PARTITION BY php.id_pat_health_plan ORDER BY php.id_health_plan, php.affiliation_number, php.affiliation_number_compl, phph.create_time) AS num_row
                  FROM patient p
                 INNER JOIN person ps
                    ON p.id_person = ps.id_person
                  LEFT JOIN person_hist psh
                    ON psh.id_person = ps.id_person
                  LEFT JOIN pat_health_plan php
                    ON php.id_patient = p.id_patient
                  LEFT JOIN health_plan hp
                    ON php.id_health_plan = hp.id_health_plan
                  LEFT JOIN alert_adtcod.pat_health_plan_hist phph
                    ON phph.id_pat_health_plan = php.id_pat_health_plan
                 WHERE phph.operation_type != 'C'
                 ORDER BY num_row) res2
         WHERE res1.id_pat_health_plan = res2.id_pat_health_plan AND res1.num_row + 1 = res2.num_row 
         ORDER BY create_time DESC)
 ORDER BY create_time DESC;
