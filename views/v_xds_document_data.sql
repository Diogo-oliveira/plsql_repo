-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 27/11/2009 21:12
-- CHANGE REASON: [PIX-341] HIE XDS Content Creator module in Alert
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT e.id_institution,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       pk_utils.get_institution_name(il.id_language, e.id_institution) doc_author_institution,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_auth.title, il.id_language) doc_author_suffix,

       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(er.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       er.id_professional,
                                       e.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(er.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        er.id_professional,
                                        er.dt_creation_tstz,
                                        e.id_episode) doc_author_speciality,
       de.id_doc_ori_type class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.'||de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       r.id_content type_code,
       pk_translation.get_translation(il.id_language, r.code_reports) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       xdf.document_format format_code,
       pk_translation.get_translation(il.id_language, xdf.code_document_format) format_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) format_code_coding_scheme,
       xcl.id_content conf_code,
       pk_translation.get_translation(il.id_language, xcl.code_confidentiality_level) conf_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) conf_code_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       er.dt_creation_tstz creation_time,
       '' comments,
       (SELECT REPLACE(l.locale, '_', '-')
          FROM LANGUAGE l
         WHERE l.id_language = il.id_language) language_code,
       r.mime_type mime_type,
       e.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       e.id_patient source_patient_id,
       pk_translation.get_translation(il.id_language, r.code_reports) title,
       pk_sysconfig.get_config('ALERT_OID_HIE_EPIS_REPORT', 0, 0) || '.' || er.id_epis_report unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || er.id_epis_report submission_set_unique_id,
       er.id_epis_report id_epis_report,
       er.rep_binary_file document,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_subm.title, il.id_language) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       xds.id_professional,
                                       e.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        e.id_episode) subm_author_speciality,
       de.id_doc_external cont_type_code,
       pk_translation.get_translation(il.id_language, r.code_reports) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || e.id_institution subm_source_id,
       --Extra information no handled by Inter-Alert event
       e.id_episode,
       e.id_epis_type,
       de.id_doc_type id_reports,
       xds.id_xds_confidentiality_level,
       il.id_language,
       pk_prof_utils.get_name_signature(il.id_language,
                                        profissional(er.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        er.id_professional) doc_author_person,
       pk_prof_utils.get_name_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        xds.id_professional) subm_author_person,
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time

  FROM epis_report er
 INNER JOIN reports r ON r.id_reports = er.id_reports
 INNER JOIN professional p_auth ON p_auth.id_professional = er.id_professional
 INNER JOIN episode e ON e.id_episode = er.id_episode
 INNER JOIN patient p ON p.id_patient = e.id_patient
 INNER JOIN clinical_service cs ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN xds_document_class xdc ON xdc.id_xds_document_class = r.id_xds_document_class
 INNER JOIN xds_document_format xdf ON xdf.id_xds_document_format = r.id_xds_document_format
 INNER JOIN institution i ON i.id_institution = e.id_institution
 INNER JOIN institution_language il ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft ON xft.flg_type = i.flg_type
  LEFT JOIN xds_document_submission xds ON er.id_epis_report = xds.id_epis_report
  LEFT JOIN xds_confidentiality_level xcl ON xcl.id_xds_confidentiality_level = xds.id_xds_confidentiality_level
  LEFT JOIN professional p_subm ON p_subm.id_professional = xds.id_professional
 WHERE r.flg_xds_publishable = 'Y';
-- CHANGE END: Ariel Machado

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 04/12/2009 14:45
-- CHANGE REASON: [PIX-341] New fields: doc_author_name and subm_author_name
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT e.id_institution,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       pk_utils.get_institution_name(il.id_language, e.id_institution) doc_author_institution,
       p_auth.name doc_author_name,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_auth.title, il.id_language) doc_author_suffix,

       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(er.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       er.id_professional,
                                       e.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(er.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        er.id_professional,
                                        er.dt_creation_tstz,
                                        e.id_episode) doc_author_speciality,
       de.id_doc_ori_type class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.'||de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       de.id_doc_type type_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_TYPE.'||de.id_doc_type) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       xdf.document_format format_code,
       pk_translation.get_translation(il.id_language, xdf.code_document_format) format_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) format_code_coding_scheme,
       xcl.id_content conf_code,
       pk_translation.get_translation(il.id_language, xcl.code_confidentiality_level) conf_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) conf_code_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       er.dt_creation_tstz creation_time,
       '' comments,
       (SELECT REPLACE(l.locale, '_', '-')
          FROM LANGUAGE l
         WHERE l.id_language = il.id_language) language_code,
       r.mime_type mime_type,
       e.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       e.id_patient source_patient_id,
       pk_translation.get_translation(il.id_language, r.code_reports) title,
       pk_sysconfig.get_config('ALERT_OID_HIE_EPIS_REPORT', 0, 0) || '.' || er.id_epis_report unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || er.id_epis_report submission_set_unique_id,
       er.id_epis_report id_epis_report,
       er.rep_binary_file document,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.name subm_author_name,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_subm.title, il.id_language) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       xds.id_professional,
                                       e.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        e.id_episode) subm_author_speciality,
       r.id_content cont_type_code,
       pk_translation.get_translation(il.id_language, r.code_reports) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || e.id_institution subm_source_id,
       --Extra information no handled by Inter-Alert event
       e.id_episode,
       e.id_epis_type,
       r.id_reports,
       xds.id_xds_confidentiality_level,
       il.id_language,
       pk_prof_utils.get_name_signature(il.id_language,
                                        profissional(er.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        er.id_professional) doc_author_person,
       pk_prof_utils.get_name_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        xds.id_professional) subm_author_person,
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time

  FROM epis_report er
 INNER JOIN reports r ON r.id_reports = er.id_reports
 INNER JOIN professional p_auth ON p_auth.id_professional = er.id_professional
 INNER JOIN episode e ON e.id_episode = er.id_episode
 INNER JOIN patient p ON p.id_patient = e.id_patient
 INNER JOIN clinical_service cs ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN xds_document_class xdc ON xdc.id_xds_document_class = r.id_xds_document_class
 INNER JOIN xds_document_format xdf ON xdf.id_xds_document_format = r.id_xds_document_format
 INNER JOIN institution i ON i.id_institution = e.id_institution
 INNER JOIN institution_language il ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft ON xft.flg_type = i.flg_type
  LEFT JOIN xds_document_submission xds ON er.id_epis_report = xds.id_epis_report
  LEFT JOIN xds_confidentiality_level xcl ON xcl.id_xds_confidentiality_level = xds.id_xds_confidentiality_level
  LEFT JOIN professional p_subm ON p_subm.id_professional = xds.id_professional
 WHERE r.flg_xds_publishable = 'Y';
-- CHANGE END: Ariel Machado


-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 28/10/2010
-- CHANGE REASON: [ALERT-72584] DOCUMENTS ARCHIVE
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT nvl(de.id_grupo, de.id_doc_external) id_folder,
       de.id_doc_external,
       de.id_grupo,
       e.id_institution,
       e.id_episode,
       e.id_epis_type,
       il.id_language,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       pk_utils.get_institution_name(il.id_language, e.id_institution) doc_author_institution,
       p_auth.name doc_author_name,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_auth.title, il.id_language) doc_author_suffix,
       xds.id_xds_document_submission,
       
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(de.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       de.id_professional,
                                       e.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(de.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        de.id_professional,
                                        de.dt_inserted,
                                        e.id_episode) doc_author_speciality,
       dot.id_content class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' || de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       dt.id_content type_code,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       dt.id_content code_list,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) code_list_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) code_list_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       de.dt_inserted creation_time,
       decode(dc.desc_comment,
              NULL,
              NULL,
              p_subm.name || chr(13) ||
              pk_date_utils.date_char_tsz(il.id_language,
                                          dc.dt_comment,
                                          e.id_institution,
                                          pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)) || chr(13) ||
              chr(13) || dc.desc_comment || chr(13) || chr(13) || '---' || chr(13) || chr(13)) comments,
       (SELECT REPLACE(l.locale, '_', '-')
          FROM LANGUAGE l
         WHERE l.id_language = il.id_language) language_code,
       e.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       e.id_patient source_patient_id,
       de.title title,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.name subm_author_name,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_subm.title, il.id_language) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    e.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                       xds.id_professional,
                                       e.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     e.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        e.id_episode) subm_author_speciality,
       de.id_doc_type cont_type_code, --
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || e.id_institution subm_source_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || xds.id_xds_document_submission submission_set_unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', 0, 0) || '.' || nvl(de.id_grupo, de.id_doc_external) folder_unique_id,
       --Extra information no handled by Inter-Alert event
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time,
       xds.flg_submission_status,
       xds.value,
       xds.id_currency,
       pk_translation.get_translation(il.id_language, 'CURRENCY.CODE_CURRENCY.' || xds.id_currency) desc_currency,
       xds.desc_item
  FROM doc_external de
 INNER JOIN professional p_auth
    ON p_auth.id_professional = de.id_professional
 INNER JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN patient p
    ON p.id_patient = e.id_patient
 INNER JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN institution i
    ON i.id_institution = e.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft
    ON xft.flg_type = i.flg_type
 INNER JOIN doc_type dt
    ON dt.id_doc_type = de.id_doc_type
  LEFT JOIN doc_comments dc
    ON dc.id_doc_external = de.id_doc_external
 INNER JOIN doc_ori_type dot
    ON dot.id_doc_ori_type = de.id_doc_ori_type
 INNER JOIN xds_document_submission xds
    ON de.id_doc_external = xds.id_doc_external
  LEFT JOIN professional p_subm
    ON p_subm.id_professional = xds.id_professional
 WHERE de.flg_status = 'A';
-- CHANGE END: Rui Spratley


-- CHANGED BY: Carlos Guilherme
-- CHANGE DATE: 3/12/2010
-- CHANGE REASON: [ALERT-72584] DOCUMENTS ARCHIVE
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT nvl(de.id_grupo, de.id_doc_external) id_folder,
       de.id_doc_external,
       de.id_grupo,
       de.id_institution,
       de.id_episode,
       e.id_epis_type,
       il.id_language,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       pk_utils.get_institution_name(il.id_language, de.id_institution) doc_author_institution,
       p_auth.name doc_author_name,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_auth.title, il.id_language) doc_author_suffix,
       xds.id_xds_document_submission,

       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(de.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       de.id_professional,
                                       de.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(de.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        de.id_professional,
                                        de.dt_inserted,
                                        de.id_episode) doc_author_speciality,
       dot.id_doc_ori_type class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' || de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       dt.id_doc_type type_code,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       dt.id_doc_type code_list,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) code_list_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) code_list_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       de.dt_inserted creation_time,
       /*decode(dc.desc_comment,
              NULL,
              NULL,
              p_subm.name || chr(13) ||
              pk_date_utils.date_char_tsz(il.id_language,
                                          dc.dt_comment,
                                          e.id_institution,
                                          pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)) || chr(13) ||
              chr(13) || dc.desc_comment || chr(13) || chr(13) || '---' || chr(13) || chr(13)) comments,*/

       il.id_language language_code,
       de.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       de.id_patient source_patient_id,
       de.title title,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.name subm_author_name,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_subm.title, il.id_language) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       xds.id_professional,
                                       de.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        de.id_episode) subm_author_speciality,
       de.id_doc_type cont_type_code, --
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || de.id_institution subm_source_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || xds.id_xds_document_submission submission_set_unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', 0, 0) || '.' || nvl(de.id_grupo, de.id_doc_external) folder_unique_id,
       --Extra information no handled by Inter-Alert event
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time,
       xds.flg_submission_status,
       xds.value,
       xds.id_currency,
       pk_translation.get_translation(il.id_language, 'CURRENCY.CODE_CURRENCY.' || xds.id_currency) desc_currency,
       xds.desc_item
  FROM doc_external de
 INNER JOIN professional p_auth
    ON p_auth.id_professional = de.id_professional
 LEFT JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN patient p
    ON p.id_patient = de.id_patient
 LEFT JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN institution i
    ON i.id_institution = de.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft
    ON xft.flg_type = i.flg_type
 INNER JOIN doc_type dt
    ON dt.id_doc_type = de.id_doc_type
/*  LEFT JOIN doc_comments dc
    ON dc.id_doc_external = de.id_doc_external
*/ INNER JOIN doc_ori_type dot
    ON dot.id_doc_ori_type = de.id_doc_ori_type
 INNER JOIN xds_document_submission xds
    ON nvl(de.Id_Grupo, de.id_doc_external) = xds.id_doc_external
  LEFT JOIN professional p_subm
    ON p_subm.id_professional = xds.id_professional
 WHERE de.flg_status = 'A' and
       xds.flg_status = 'A';
-- CHANGE END: Carlos Guilherme

-- CHANGED BY: Daniel Silva
-- CHANGE DATE: 2012-03-13
-- CHANGE REASON: [ALERT-222791]
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT nvl(de.id_grupo, de.id_doc_external) id_folder,
       de.id_doc_external,
       de.id_grupo,
       de.id_institution,
       de.id_episode,
       e.id_epis_type,
       il.id_language,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       de.id_institution doc_author_institution_id,
       pk_utils.get_institution_name(il.id_language, de.id_institution) doc_author_institution,
       p_auth.id_professional doc_author_id,
       p_auth.name doc_author_name,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_auth.title, il.id_language) doc_author_suffix,
       xds.id_xds_document_submission,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(de.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       de.id_professional,
                                       de.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(de.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        de.id_professional,
                                        de.dt_inserted,
                                        de.id_episode) doc_author_speciality,
       dot.id_doc_ori_type class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' || de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       dt.id_doc_type type_code,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       dt.id_doc_type code_list,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) code_list_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) code_list_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       de.dt_inserted creation_time,
       /*decode(dc.desc_comment,
              NULL,
              NULL,
              p_subm.name || chr(13) ||
              pk_date_utils.date_char_tsz(il.id_language,
                                          dc.dt_comment,
                                          e.id_institution,
                                          pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)) || chr(13) ||
              chr(13) || dc.desc_comment || chr(13) || chr(13) || '---' || chr(13) || chr(13)) comments,*/
       il.id_language language_code,
       de.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       de.id_patient source_patient_id,
       de.title title,
       xds.id_institution subm_author_institution_id,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.id_professional subm_author_id,
       p_subm.name subm_author_name,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p_subm.title, il.id_language) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       xds.id_professional,
                                       de.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        de.id_episode) subm_author_speciality,
       de.id_doc_type cont_type_code, --
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || de.id_institution subm_source_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || xds.id_xds_document_submission submission_set_unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', 0, 0) || '.' || nvl(de.id_grupo, de.id_doc_external) folder_unique_id,
       --Extra information no handled by Inter-Alert event
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time,
       xds.flg_submission_status,
       xds.value,
       xds.id_currency,
       pk_translation.get_translation(il.id_language, 'CURRENCY.CODE_CURRENCY.' || xds.id_currency) desc_currency,
       xds.desc_item
  FROM doc_external de
 INNER JOIN professional p_auth
    ON p_auth.id_professional = de.id_professional
 LEFT JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN patient p
    ON p.id_patient = de.id_patient
 LEFT JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN institution i
    ON i.id_institution = de.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft
    ON xft.flg_type = i.flg_type
 INNER JOIN doc_type dt
    ON dt.id_doc_type = de.id_doc_type
/*  LEFT JOIN doc_comments dc
    ON dc.id_doc_external = de.id_doc_external
*/ INNER JOIN doc_ori_type dot
    ON dot.id_doc_ori_type = de.id_doc_ori_type
 INNER JOIN xds_document_submission xds
    ON nvl(de.Id_Grupo, de.id_doc_external) = xds.id_doc_external
  LEFT JOIN professional p_subm
    ON p_subm.id_professional = xds.id_professional
 WHERE de.flg_status = 'A' and
       xds.flg_status = 'A';
-- CHANGE END: Daniel Silva


CREATE OR REPLACE VIEW V_XDS_DOCUMENT_DATA AS
SELECT nvl(de.id_grupo, de.id_doc_external) id_folder,
       de.id_doc_external,
       de.id_grupo,
       de.id_institution,
       de.id_episode,
       e.id_epis_type,
       il.id_language,
       p.name pat_name,
       p.first_name pat_first_name,
       p.middle_name pat_middle_name,
       p.last_name pat_last_name,
       de.id_institution doc_author_institution_id,
       pk_utils.get_institution_name(il.id_language, de.id_institution) doc_author_institution,
       p_auth.id_professional doc_author_id,
       p_auth.name doc_author_name,
       p_auth.first_name doc_author_first_name,
       p_auth.middle_name doc_author_middle_name,
       p_auth.last_name doc_author_last_name,
       pk_backoffice.get_prof_title_desc(il.id_language, p_auth.title) doc_author_suffix,
       xds.id_xds_document_submission,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(de.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       de.id_professional,
                                       de.id_institution) doc_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(de.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        de.id_professional,
                                        de.dt_inserted,
                                        de.id_episode) doc_author_speciality,
       dot.id_doc_ori_type class_code,
       pk_translation.get_translation(il.id_language, 'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' || de.id_doc_ori_type) class_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) class_code_coding_scheme,
       dt.id_doc_type type_code,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) type_code_coding_scheme,
       dt.id_doc_type code_list,
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) code_list_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) code_list_coding_scheme,
       xft.id_content health_fac_code,
       pk_translation.get_translation(il.id_language, xft.code_healthcare_facility_type) health_fac_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) health_fac_code_coding_scheme,
       cs.id_content pract_set_code,
       pk_translation.get_translation(il.id_language, cs.code_clinical_service) pract_set_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) pract_set_code_coding_scheme,
       de.dt_inserted creation_time,
       /*decode(dc.desc_comment,
              NULL,
              NULL,
              p_subm.name || chr(13) ||
              pk_date_utils.date_char_tsz(il.id_language,
                                          dc.dt_comment,
                                          e.id_institution,
                                          pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)) || chr(13) ||
              chr(13) || dc.desc_comment || chr(13) || chr(13) || '---' || chr(13) || chr(13)) comments,*/
       il.id_language language_code,
       de.id_patient patient_id,
       e.dt_begin_tstz service_start_time,
       e.dt_end_tstz service_stop_time,
       de.id_patient source_patient_id,
       de.title title,
       xds.id_institution subm_author_institution_id,
       pk_utils.get_institution_name(il.id_language, xds.id_institution) subm_author_institution,
       p_subm.id_professional subm_author_id,
       p_subm.name subm_author_name,
       p_subm.first_name subm_author_first_name,
       p_subm.middle_name subm_author_middle_name,
       p_subm.last_name subm_author_last_name,
       pk_backoffice.get_prof_title_desc(il.id_language, p_subm.title) subm_author_suffix,
       pk_prof_utils.get_desc_category(il.id_language,
                                       profissional(xds.id_professional,
                                                    de.id_institution,
                                                    pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                       xds.id_professional,
                                       de.id_institution) subm_author_role,
       pk_prof_utils.get_spec_signature(il.id_language,
                                        profissional(xds.id_professional,
                                                     de.id_institution,
                                                     pk_episode.get_soft_by_epis_type(e.id_epis_type, de.id_institution)),
                                        xds.id_professional,
                                        xds.dt_submission_time,
                                        de.id_episode) subm_author_speciality,
       de.id_doc_type cont_type_code, --
       pk_translation.get_translation(il.id_language, 'DOC_TYPE.CODE_DOC_TYPE.' || de.id_doc_type) cont_type_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) cont_type_code_coding_scheme,
       xds.dt_submission_time submission_time,
       pk_sysconfig.get_config('ALERT_OID_HIE_INSTITUTION', 0, 0) || '.' || de.id_institution subm_source_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_XDS_SUBMISSION_SET', 0, 0) || '.' || xds.id_xds_document_submission submission_set_unique_id,
       pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', 0, 0) || '.' || nvl(de.id_grupo, de.id_doc_external) folder_unique_id,
       --Extra information no handled by Inter-Alert event
       (SELECT d.dt_med_tstz
          FROM discharge d
         WHERE d.id_episode = e.id_episode
           AND d.flg_status = 'A'
           AND rownum = 1) med_discharge_time,
       xds.flg_submission_status,
       xds.value,
       xds.id_currency,
       pk_translation.get_translation(il.id_language, 'CURRENCY.CODE_CURRENCY.' || xds.id_currency) desc_currency,
       xds.desc_item
  FROM doc_external de
 INNER JOIN professional p_auth
    ON p_auth.id_professional = de.id_professional
 LEFT JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN patient p
    ON p.id_patient = de.id_patient
 LEFT JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_clinical_service
 INNER JOIN institution i
    ON i.id_institution = de.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 INNER JOIN xds_healthcare_facility_type xft
    ON xft.flg_type = i.flg_type
 INNER JOIN doc_type dt
    ON dt.id_doc_type = de.id_doc_type
/*  LEFT JOIN doc_comments dc
    ON dc.id_doc_external = de.id_doc_external
*/ INNER JOIN doc_ori_type dot
    ON dot.id_doc_ori_type = de.id_doc_ori_type
 INNER JOIN xds_document_submission xds
    ON nvl(de.Id_Grupo, de.id_doc_external) = xds.id_doc_external
  LEFT JOIN professional p_subm
    ON p_subm.id_professional = xds.id_professional
 WHERE de.flg_status = 'A' and
       xds.flg_status = 'A';
