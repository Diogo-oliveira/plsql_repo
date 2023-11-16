CREATE OR REPLACE VIEW v_procedures_mednur_list AS
SELECT DISTINCT i.id_intervention,
                idcs.flg_execute,
                iq.id_intervention iq_id_intervention,
                iq.flg_mandatory,
                idcs.flg_timeout,
                i.flg_type,
                i.flg_status,
                i.gender,
                i.age_min,
                i.age_max,
                i.code_intervention,
                NULL rank,
                alert_context('i_lang') l_lang,
                alert_context('i_prof_id') l_prof_id,
                alert_context('i_prof_institution') l_prof_institution,
                alert_context('i_prof_software') l_prof_software
  FROM intervention i
  JOIN (SELECT id_intervention, flg_execute, flg_timeout
          FROM interv_dep_clin_serv
         WHERE flg_type = 'P'
           AND id_software = alert_context('i_prof_software')
           AND id_institution = alert_context('i_prof_institution')) iis
    ON i.id_intervention = iis.id_intervention
  JOIN interv_dep_clin_serv idcs
    ON i.id_intervention = idcs.id_intervention
   AND idcs.flg_type = alert_context('i_flg_type')
   AND idcs.id_software = alert_context('i_prof_software')
   AND idcs.id_institution = alert_context('i_prof_institution')
  JOIN interv_dcs_most_freq_except idmfe
    ON idcs.id_interv_dep_clin_serv = idmfe.id_interv_dep_clin_serv
   AND idmfe.flg_available = 'Y'
   AND idmfe.flg_status = 'A'
  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
               FROM (SELECT DISTINCT id_intervention, flg_mandatory
                       FROM interv_questionnaire
                      WHERE flg_time = 'O'
                        AND id_institution = alert_context('i_prof_institution')
                        AND flg_available = 'Y')
              GROUP BY id_intervention) iq
    ON iq.id_intervention = i.id_intervention
 WHERE idmfe.flg_cat_prof = alert_context('i_flg_filter');
