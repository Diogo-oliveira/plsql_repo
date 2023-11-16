CREATE OR REPLACE VIEW v_procedures_cod_list AS
SELECT DISTINCT i.id_intervention,
                iis.flg_execute,
                iq.id_intervention iq_id_intervention,
                iq.flg_mandatory,
                iis.flg_timeout,
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
  JOIN (SELECT ic.id_intervention
          FROM codification_instit_soft cis, interv_codification ic
         WHERE cis.id_codification = alert_context('i_codification')
           AND cis.id_institution = alert_context('i_prof_institution')
           AND cis.id_software = alert_context('i_prof_software')
           AND cis.id_codification = ic.id_codification
           AND ic.flg_available = 'Y') ic
    ON ic.id_intervention = i.id_intervention
  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
               FROM (SELECT DISTINCT id_intervention, flg_mandatory
                       FROM interv_questionnaire
                      WHERE flg_time = 'O'
                        AND id_institution = alert_context('i_prof_institution')
                        AND flg_available = 'Y')
              GROUP BY id_intervention) iq
    ON iq.id_intervention = i.id_intervention;
