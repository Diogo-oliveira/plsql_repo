CREATE OR REPLACE VIEW V_EPISODE_SO_LAST_8 AS -- SO Episode
SELECT id_episode id_episode_alert_so,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_begin_tstz, profissional(0, id_institution, 0))
          FROM dual) dt_entrance_so,
       dt_begin_tstz,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(id_last_nurse_resp, id_institution, 0))
          FROM dual) num_mecan_last_nur_so,
       ext_episode ext_episode_so,
       id_episode_urg id_episode_alert_urg,
       num_order med_order_number_discharge_so,
       (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id, profissional(id_prof_med_discharge, id_institution, 0))
          FROM dual) med_num_mecan_discharge_so,
       id_first_dep_clin_serv,
       id_clinical_service id_clinical_service_so,
       (SELECT pk_translation.get_translation(language_id,
                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || id_clinical_service)
          FROM dual) AS clinical_service_so,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_med_tstz, profissional(0, id_institution, 0))
          FROM dual) dt_med_disch_so,
       (SELECT pk_date_utils.date_yearmonthday_tsz(language_id, dt_med_tstz, id_institution, 0)
          FROM dual) day_med_disch_so,
       (SELECT pk_date_utils.date_yearmonth_tsz(language_id, dt_med_tstz, id_institution, 0)
             FROM dual) month_med_disch_so,
       (SELECT pk_date_utils.date_send_tsz(language_id, dt_admin_tstz, profissional(0, id_institution, 0))
          FROM dual) dt_admin_disch_so,
       (SELECT pk_date_utils.date_yearmonthday_tsz(language_id, dt_admin_tstz, id_institution, 0)
          FROM dual) day_admin_disch_so,
       (SELECT pk_date_utils.date_yearmonth_tsz(language_id, dt_admin_tstz, id_institution, 0)
          FROM dual) month_admin_disch_so,
       initial_institution,
       contact_name,
       county          
  FROM (WITH epis AS (SELECT /*+ materialized*/
                       id_episode,
                       id_institution,
                       id_prev_episode,
                       id_epis_type,
                       flg_status,
                       id_clinical_service,
                       dt_begin_tstz
                        FROM alert.episode
                       WHERE flg_status != 'C'
                         AND id_epis_type = 5
                         AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY'))
           SELECT eo.dt_begin_tstz,
                  eo.id_episode,
                  eo.id_institution,
                  eo.id_clinical_service,
                  eio.id_room,
                  eio.id_professional,
                  eio.id_first_dep_clin_serv,
                  eio.id_dep_clin_serv,
                  eio.dt_med_tstz,
                  eio.dt_admin_tstz,
                  eio.dt_first_obs_tstz,
                  eio.dt_first_nurse_obs_tstz,
                  eo.id_prev_episode id_episode_urg,
                  epr_last_nur.id_prof_comp id_last_nurse_resp,
                  ees.value ext_episode,
                  pk_sysconfig.get_config('LANGUAGE', eo.id_institution, 0) language_id,
                  disch.id_prof_med id_prof_med_discharge,
                  pk_adt.get_patient_address_colony(in_inst.id_person) as county, -- EMR-805
                  pk_patient.get_patient_name(1,in_inst.id_patient) as contact_name , -- emr-806
                  in_inst.initial_institution,  -- EMR-806
                  pro.num_order
             FROM epis eo
             JOIN epis_info eio
               ON eo.id_episode = eio.id_episode
            INNER JOIN dep_clin_serv dcs
               ON eio.id_dep_clin_serv = dcs.id_dep_clin_serv
            INNER JOIN department dpt
               ON dcs.id_department = dpt.id_department
              AND dpt.id_institution = eo.id_institution
              AND instr(dpt.flg_type, 'I') > 0
              AND instr(dpt.flg_type, 'O') > 0
             JOIN alert.epis_ext_sys ees
               ON (ees.id_episode = eo.id_episode AND ees.id_institution = eo.id_institution AND ees.VALUE is NOT null)
           --primeira instituicao -- EMR-806
             LEFT OUTER JOIN (SELECT e.id_patient ,e.id_episode, i.id_institution , pk_utils.get_institution_name(1,i.id_institution) Initial_Institution, p.id_person
                                FROM epis_info ei, episode e, dep_clin_serv dc, department d, institution i, patient p
                               WHERE e.id_episode        = ei.id_episode
                                 AND dc.id_dep_clin_serv = ei.id_first_dep_clin_serv
                                 AND d.id_department     = dc.id_department
                                 AND p.id_patient        = e.id_patient) in_inst 
                          ON (In_Inst.id_episode     = eo.id_episode
                         AND  in_inst.id_institution = dpt.id_institution) 
           -- Profissional associado
             LEFT OUTER JOIN (SELECT id_professional, num_order 
                                from professional po ) pro
                          on (pro.id_professional = eio.id_professional)
           -- ultima responsabilidade de enfermagem
             LEFT OUTER JOIN (SELECT a.*, rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz DESC) AS rank1
                                FROM alert.epis_prof_resp a
                               WHERE a.flg_status = 'F'
                                 AND a.flg_type = 'N') epr_last_nur
               ON (epr_last_nur.id_episode = eo.id_episode)
             LEFT OUTER JOIN (SELECT d.*,
                                     rank() over(PARTITION BY d.id_episode ORDER BY d.dt_med_tstz DESC, d.dt_admin_tstz DESC) AS rn
                                FROM alert.discharge d
                               WHERE d.flg_status IN ('A', 'P')) disch
               ON (disch.id_episode = eo.id_episode)
            WHERE eo.flg_status != 'C'
              AND eo.id_epis_type = 5
              AND eo.id_prev_episode IS NOT NULL
              AND (epr_last_nur.rank1 = 1 OR epr_last_nur.rank1 IS NULL)
              AND (disch.rn = 1 OR disch.rn IS NULL));
