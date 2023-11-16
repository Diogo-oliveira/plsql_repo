CREATE OR REPLACE VIEW V_EPIS_DOC_SUMMARY 
AS
SELECT E.ID_PATIENT,
ed.id_epis_documentation,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   dc.code_doc_component desc_doc_component,
                   PK_TOUCH_OPTION.get_element_description(pk_episode.get_language_by_epis(ed.id_episode),
                                           profissional(NULL, pk_episode.get_institution_by_epis(ed.id_episode),NULL),
                                           de.flg_type,
                                           edd.value,
                                           edd.value_properties,
                                           decr.id_doc_element_crit,
                                           de.id_unit_measure_reference,
                                           de.id_master_item,
                                           decr.code_element_close) desc_element,
                   PK_TOUCH_OPTION.get_formatted_value(pk_episode.get_language_by_epis(ed.id_episode),
                                       profissional(NULL, pk_episode.get_institution_by_epis(ed.id_episode), NULL),
                                       de.flg_type,
                                       edd.value,
                                       edd.value_properties,
                                       de.input_mask,
                                       de.flg_optional_value,
                                       de.flg_element_domain_type,
                                       de.code_element_domain,
                                       edd.dt_creation_tstz) VALUE,
                   ed.id_doc_area, 
                   DE.INTERNAL_NAME, 
                   edd.value VALUE_id
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
               JOIN EPISODE E ON E.ID_EPISODE = ED.ID_EPISODE;
