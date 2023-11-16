CREATE OR REPLACE VIEW SAEH_PROCEDIMENTOS
AS
SELECT e.id_episode folio,
       e.dt_end_tstz,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) code_clues,
       interv.cpt_code,
       pk_touch_option.get_template_value(i_lang               => 17,
                                          i_prof               => profissional(NULL, ia.id_institution, NULL),
                                          i_patient            => e.id_patient,
                                          i_episode            => e.id_episode,
                                          i_doc_area           => 1082,
                                          i_epis_documentation => interv.id_epis_documentation,
                                          i_doc_int_name       => 'ANEST_PROCED',
                                          i_show_internal      => 'Y',
                                          i_scope_type         => 'V') tipoanestesia,
       pk_touch_option.get_template_value(i_lang               => 17,
                                          i_prof               => profissional(NULL, ia.id_institution, NULL),
                                          i_patient            => e.id_patient,
                                          i_episode            => e.id_episode,
                                          i_doc_area           => 1082,
                                          i_epis_documentation => interv.id_epis_documentation,
                                          i_doc_int_name       => 'SERVICIO_PROCED',
                                          i_show_internal      => 'Y',
                                          i_scope_type         => 'V') usoquirofano,
       pk_touch_option.get_template_value(i_lang               => 17,
                                          i_prof               => profissional(NULL, ia.id_institution, NULL),
                                          i_patient            => e.id_patient,
                                          i_episode            => e.id_episode,
                                          i_doc_area           => 1082,
                                          i_epis_documentation => interv.id_epis_documentation,
                                          i_doc_int_name       => 'TIEMPO_PROCED',
                                          i_element_int_name   => 'QH',
                                          i_show_internal      => 'Y',
                                          i_scope_type         => 'V') hourquirofano,
       pk_touch_option.get_template_value(i_lang               => 17,
                                          i_prof               => profissional(NULL, ia.id_institution, NULL),
                                          i_patient            => e.id_patient,
                                          i_episode            => e.id_episode,
                                          i_doc_area           => 1082,
                                          i_epis_documentation => interv.id_epis_documentation,
                                          i_doc_int_name       => 'TIEMPO_PROCED',
                                          i_element_int_name   => 'QM',
                                          i_show_internal      => 'Y',
                                          i_scope_type         => 'V') minutequirofano,
       (SELECT p.num_order
          FROM professional p
         WHERE p.id_professional = interv.id_prof_performed) cedula_professional,
       e.id_institution
  FROM episode e
 INNER JOIN institution ia
    ON ia.id_institution = e.id_institution
  JOIN (SELECT ipp.id_epis_documentation, ei.id_visit, i.cpt_code, ipp.id_prof_performed
          FROM interv_presc_det ipd
         INNER JOIN interv_prescription ip
            ON ipd.id_interv_prescription = ip.id_interv_prescription
         INNER JOIN interv_presc_plan ipp
            ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
         INNER JOIN intervention i
            ON ipd.id_intervention = i.id_intervention
          JOIN episode ei
            ON ip.id_episode = ei.id_episode
         WHERE ipp.id_epis_documentation IS NOT NULL) interv
    ON interv.id_visit = e.id_visit
 WHERE e.id_epis_type = 5
   AND e.dt_end_tstz IS NOT NULL;
