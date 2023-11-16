CREATE OR REPLACE VIEW SAEH_EGRESOS AS
SELECT e.id_patient,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) clues,
       e.id_episode,
       e_post.id_episode post_epis , --CG
       (SELECT id_content
          FROM episode epi
          JOIN clinical_service cs
            ON epi.id_clinical_service= cs.id_clinical_service
         WHERE epi.id_episode = e_post.id_episode) AS post_servicio02, --CG2
       e.id_institution,
       e.dt_end_tstz,
       e.dt_begin_tstz,
       extract(DAY FROM(e.dt_end_tstz - e.dt_begin_tstz)) AS dias,
       dcs.id_department department,
       dcs.id_clinical_service cli_serv_cont,
       dcs.id_clinical_service cli_serv_part,
       p.last_name apellido_paterno,
       p.middle_name apellido_materno,
       p.first_name first_name,
       pk_patient.get_pat_age_type(i_lang    => NULL,
                                   i_prof    => profissional(NULL, e.id_institution, NULL),
                                   i_patient => p.id_patient,
                                   i_date    => e.dt_end_tstz) typeage,
       pk_patient.get_pat_age_num(i_lang    => 17,
                                  i_prof    => profissional(NULL, e.id_institution, NULL),
                                  i_patient => p.id_patient,
                                  i_type    => NULL,
                                  i_date    => e.dt_end_tstz) age,
       CASE
            WHEN trunc(months_between(e.dt_end_tstz, p.dt_birth)) < 3 THEN
             CASE bp.id_occurrence_site
                 WHEN 26 THEN
                  'S'
                 WHEN 94 THEN
                  'S'
                 ELSE
                  CASE bp.id_institution
                      WHEN e.id_institution THEN
                       'Y'
                      ELSE
                       'N'
                  END
             END
            ELSE
             NULL
        END born_in,
       p.gender,
       pk_vital_sign.get_vs_read_value(i_lang       => NULL,
                                       i_prof       => profissional(NULL, e.id_institution, NULL),
                                       i_patient    => p.id_patient,
                                       i_episode    => NULL,
                                       i_vital_sign => 29) peso,
       pk_vital_sign.get_vs_read_value(i_lang       => NULL,
                                       i_prof       => profissional(NULL, e.id_institution, NULL),
                                       i_patient    => p.id_patient,
                                       i_episode    => NULL,
                                       i_vital_sign => 30) altura,
       pk_adt.get_health_plan_field_mx(i_episode => e.id_episode, i_flg_main => 'Y', i_field_to_show => 'ID_CONTENT') derhab,
       pk_adt.get_health_plan_field_mx(i_episode       => e.id_episode,
                                       i_flg_main      => 'Y',
                                       i_field_to_show => 'AFFILIATION_NUMBER') aff_number,
       pk_adt.get_health_plan_field_mx(i_episode       => e.id_episode,
                                       i_flg_main      => 'Y',
                                       i_field_to_show => 'AFFILIATION_NUMBER_COMPL') add_number_comp,
       pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 5) entity,
       pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 10) municip,
       pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 15) localidad,
       (SELECT cr.num_clin_record
          FROM clin_record cr
         WHERE cr.id_patient = p.id_patient
           AND cr.id_institution = e.id_institution
           AND cr.flg_status = 'A') expediente,
       pk_patient.get_patient_ssn(17, profissional(NULL, e.id_institution, NULL), i_patient => p.id_patient) social_security_number,
       p.flg_native_group,
       CASE
            WHEN p.pat_native_lang = 2 THEN
             'N'
            WHEN p.pat_native_lang = 3 THEN
             'DA'
            WHEN p.pat_native_lang = 4 THEN
             'DK'
            WHEN p.pat_native_lang = 8 THEN
             NULL
            WHEN p.pat_native_lang IS NULL THEN
             NULL
            ELSE
             'Y'
        END AS habla_lengua,
       p.pat_native_lang,
       p.flg_spanish_speaker,
       CASE
            WHEN (extract(DAY FROM(e.dt_end_tstz - e.dt_begin_tstz))) <= 1 THEN
             2
            ELSE
             1
        END tipserv,
       (SELECT cs.id_content
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
         WHERE dcs.id_dep_clin_serv = ei.id_first_dep_clin_serv) AS servicioingre,
       (SELECT id_content
          FROM episode epi
          JOIN (SELECT id_epis_prof_resp,
                      id_episode,
                      id_clinical_service_dest,
                      row_number() over(PARTITION BY id_episode ORDER BY dt_request_tstz) rn
                 FROM epis_prof_resp epr
                WHERE epr.flg_transf_type = 'S') v
            ON v.id_episode = epi.id_episode
           AND rn = 1
          JOIN clinical_service cs
            ON v.id_clinical_service_dest = cs.id_clinical_service
         WHERE epi.id_episode = e.id_episode) AS servicio02,
       (SELECT cs.id_content
          FROM episode epi
          JOIN (SELECT id_epis_prof_resp,
                      id_episode,
                      id_clinical_service_dest,
                      row_number() over(PARTITION BY id_episode ORDER BY dt_request_tstz) rn
                 FROM epis_prof_resp epr
                WHERE epr.flg_transf_type = 'S') v
            ON v.id_episode = epi.id_episode
           AND rn = 2
          JOIN clinical_service cs
            ON v.id_clinical_service_dest = cs.id_clinical_service
         WHERE epi.id_episode = e.id_episode) AS servicio03,
       (SELECT cs.id_content
          FROM episode epi
          JOIN (SELECT id_epis_prof_resp,
                      id_episode,
                      id_clinical_service_dest,
                      row_number() over(PARTITION BY id_episode ORDER BY dt_request_tstz DESC) rn
                 FROM epis_prof_resp epr
                WHERE epr.flg_transf_type = 'S') v
            ON v.id_episode = epi.id_episode
           AND rn = 1
          JOIN clinical_service cs
            ON v.id_clinical_service_dest = cs.id_clinical_service
         WHERE epi.id_episode = e.id_episode) servicioegre,
       (SELECT pk_adt.get_origin_id_cnt(v.id_origin)
          FROM dual) proced,
       decode((SELECT pk_adt.get_origin_id_cnt(v.id_origin)
                FROM dual),
              'TMP53.2747',
              pk_adt.get_clues_code(i_id_clues       => NULL,
                                    i_id_institution => pk_adt.get_admission_institution_id(e.id_episode)),
              NULL) AS proced_clues,
       dr.id_content motegre,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => dd.id_inst_transfer) clues_referido,
       (SELECT d.code_icd
          FROM epis_diagnosis ed
          JOIN diagnosis d
            ON ed.id_diagnosis = d.id_diagnosis
         WHERE ed.id_episode = e.id_episode
           AND ed.flg_type = 'P'
           AND ed.flg_status NOT IN ('C', 'R')
           AND rownum = 1) diag_ini,
       (SELECT a.code_icd
          FROM diagnosis a
         WHERE a.id_diagnosis = diag_d.id_diagnosis) afec_princ,
       CASE
            WHEN diag_d.flg_recurrence = 'Y' THEN
             'S'
            WHEN diag_d.flg_recurrence = 'N' THEN
             'P'
            ELSE
             NULL
        END vez,
       CASE
            WHEN diag_infec.id_location = 11000009946 THEN
             'Y'
            WHEN diag_infec.id_location = 11000009947 THEN
             'N'
            ELSE
             'SI'
        END infec,
       (SELECT exc.standard_code
          FROM external_cause ex
          JOIN ext_cause_codification exc
            ON ex.id_external_cause = exc.id_external_cause
         WHERE ex.id_external_cause = v.id_external_cause) causaext,
       (SELECT c.code
          FROM alert_core_data.concept_term ct
         INNER JOIN alert.concept c
            ON c.id_concept = ct.id_concept_term
         WHERE ct.id_concept_term = diag_t.id_lesion_type) AS traumat,
       (SELECT c.code
          FROM alert_core_data.concept_term ct
         INNER JOIN alert.concept c
            ON c.id_concept = ct.id_concept_term
         WHERE ct.id_concept_term = diag_t.id_lesion_location) AS lugar,
       (SELECT p.num_order
          FROM professional p
         WHERE p.id_professional = d.id_prof_med) cedularesp,
       CASE
            WHEN d.flg_status = 'A' THEN
             d.create_time
            ELSE
             NULL
        END fec_crea,
       CASE
            WHEN d.flg_status = 'A' THEN
             d.update_time
            ELSE
             NULL
        END fec_actu,
       pk_adt.get_clues_field(i_id_clues => ia.id_clues, i_field => 'CODE_STATE') cedocve,
       pk_adt.get_clues_jurisdiction(i_id_clues => ia.id_clues) cjurcve,
       pk_adt.get_clues_field(i_id_clues => ia.id_clues, i_field => 'CODE_MUNICIPALITY') cmpocve,
       pk_adt.get_clues_field(i_id_clues => ia.id_clues, i_field => 'CODE_CITY') cloccve,
       pk_adt.get_clues_field(i_id_clues => ia.id_clues, i_field => 'ID_TIPOLOGY') ctuncve,
       (SELECT c.id_content
          FROM country c
         WHERE c.id_country = bp.id_country) country_id_content
  FROM episode e
INNER JOIN epis_info ei
    ON ei.id_episode = e.id_episode
INNER JOIN visit v
    ON e.id_visit = v.id_visit
INNER JOIN institution ia
    ON ia.id_institution = v.id_institution
INNER JOIN dep_clin_serv dcs
    ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
INNER JOIN patient p
    ON p.id_patient = e.id_patient
  LEFT JOIN person ps
    ON p.id_person = ps.id_person
  LEFT OUTER JOIN (SELECT ed.*, rank() over(PARTITION BY ed.id_episode ORDER BY ed.dt_epis_diagnosis_tstz DESC) AS rn
                     FROM epis_diagnosis ed
                    WHERE ed.flg_type = 'D'
                      AND ed.flg_status NOT IN ('C', 'R')
                      AND ed.flg_final_type = 'P') diag_d
    ON (diag_d.id_episode = e.id_episode)
  LEFT OUTER JOIN (SELECT ed.*, rank() over(PARTITION BY ed.id_episode ORDER BY ed.dt_epis_diagnosis_tstz DESC) AS rn
                     FROM epis_diagnosis ed
                    WHERE ed.flg_type = 'D'
                      AND ed.flg_status NOT IN ('C', 'R')
                      AND pk_diagnosis_core.check_diag_trauma(i_lang      => NULL,
                                                              i_prof      => NULL,
                                                              i_diagnosis => ed.id_diagnosis) = 'Y') diag_t
    ON (diag_t.id_episode = e.id_episode)
  LEFT OUTER JOIN (SELECT phd.*, rank() over(PARTITION BY phd.id_episode ORDER BY phd.id_location ASC) AS rn
                     FROM pat_history_diagnosis phd
                    WHERE phd.flg_recent_diag = 'Y'
                      AND phd.flg_status = 'A'
                      AND phd.flg_area = 'P'
                      AND phd.id_location IS NOT NULL) diag_infec
    ON (diag_infec.id_episode = e.id_episode)
  LEFT JOIN discharge d
    ON d.id_episode = e.id_episode
  LEFT JOIN episode e_post --CG
    ON e_post.id_prev_episode = e.id_episode and e_post.id_epis_type = 4 --CG
  LEFT JOIN discharge_detail dd
    ON d.id_discharge = dd.id_discharge
  LEFT JOIN disch_reas_dest drd
    ON d.id_disch_reas_dest = drd.id_disch_reas_dest
  LEFT JOIN discharge_reason dr
    ON drd.id_discharge_reason = dr.id_discharge_reason
  LEFT JOIN v_birthplace_address_mx bp
    ON bp.id_patient = p.id_patient
WHERE e.dt_end_tstz IS NOT NULL
   AND (diag_d.rn = 1 OR diag_d.rn IS NULL)
   AND (diag_t.rn = 1 OR diag_t.rn IS NULL)
   AND d.flg_status IN ('A', 'P')
   AND e.id_epis_type = 5
;
