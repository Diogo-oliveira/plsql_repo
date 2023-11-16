CREATE OR REPLACE VIEW v_rehab_interv_list_frequent_dept AS
SELECT DISTINCT i.id_rehab_area_interv,
                i.id_intervention,
                i.id_intervention_parent,
                i.id_rehab_area,
                i.code_intervention,
                tc.id_codification,
                tc.flg_show_codification,
                i.flg_has_children,
                i.id_rehab_session_type,
                i.code_rehab_session_type,
                decode(iq.id_intervention, NULL, 'N', 'Y') flg_clinical_question,
                alert_context('i_lang') l_lang,
                alert_context('i_prof_id') l_prof_id,
                alert_context('i_prof_institution') l_prof_institution,
                alert_context('i_prof_software') l_prof_software
  FROM (pk_rehab.find_rehab_interv(alert_context('i_prof_institution'), alert_context('i_prof_software'))) i
 INNER JOIN rehab_most_frequent rif
    ON rif.id_rehab_area_interv = i.id_rehab_area_interv
  LEFT JOIN (SELECT ic.id_intervention, ic.id_codification, ic.id_interv_codification, ic.flg_show_codification
               FROM codification c, codification_instit_soft cis, interv_codification ic
              WHERE c.id_codification = cis.id_codification
                AND cis.id_institution = alert_context('i_prof_institution')
                AND cis.id_software = alert_context('i_prof_software')
                AND c.id_codification = ic.id_codification
                AND ic.flg_available = 'Y') tc
    ON tc.id_intervention = i.id_intervention
  LEFT JOIN (SELECT id_intervention
               FROM (SELECT DISTINCT id_intervention, flg_mandatory
                       FROM interv_questionnaire
                      WHERE flg_time = 'O'
                        AND id_institution = alert_context('i_prof_institution')
                        AND flg_available = 'Y')
              GROUP BY id_intervention) iq
    ON iq.id_intervention = i.id_intervention
 WHERE rif.id_universe = 10
   AND rif.id_value = alert_context('i_department');
