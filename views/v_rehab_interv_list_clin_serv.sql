CREATE OR REPLACE VIEW v_rehab_interv_list_clin_serv AS
SELECT DISTINCT i.id_rehab_area_interv,
                i.id_intervention,
                i.id_intervention_parent,
                i.id_rehab_area,
                i.code_intervention,
                NULL id_codification,
                NULL flg_show_codification,
                i.flg_has_children,
                i.id_rehab_session_type,
                i.code_rehab_session_type,
                decode(iq.id_intervention, NULL, 'N', 'Y') flg_clinical_question,
                alert_context('i_lang') l_lang,
                alert_context('i_prof_id') l_prof_id,
                alert_context('i_prof_institution') l_prof_institution,
                alert_context('i_prof_software') l_prof_software
  FROM (pk_rehab.find_rehab_interv(alert_context('i_prof_institution'), alert_context('i_prof_software'))) i
 INNER JOIN interv_dep_clin_serv idcs
    ON idcs.id_intervention = i.id_intervention
   AND idcs.id_institution = alert_context('i_prof_institution')
   AND idcs.id_software = alert_context('i_prof_software')
  LEFT JOIN (SELECT id_intervention
               FROM (SELECT DISTINCT id_intervention, flg_mandatory
                       FROM interv_questionnaire
                      WHERE flg_time = 'O'
                        AND id_institution = alert_context('i_prof_institution')
                        AND flg_available = 'Y')
              GROUP BY id_intervention) iq
    ON iq.id_intervention = i.id_intervention
 WHERE EXISTS (SELECT 1
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = alert_context('i_prof_id')
           AND pdcs.id_institution = alert_context('i_prof_institution')
           AND pdcs.flg_status = 'S'
           AND pdcs.id_dep_clin_serv = idcs.id_dep_clin_serv);
