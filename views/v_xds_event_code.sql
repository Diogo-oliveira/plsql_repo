-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 27/11/2009 21:12
-- CHANGE REASON: [PIX-341] HIE XDS Content Creator module in Alert
CREATE OR REPLACE VIEW V_XDS_EVENT_CODE AS 
SELECT DISTINCT er.id_epis_report,
                rs.id_content event_code,
                rs.id_rep_section,
                pk_translation.get_translation(il.id_language, rs.code_rep_section) event_code_display_name,
                pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) event_code_coding_scheme
  FROM epis_report er
 INNER JOIN reports r ON r.id_reports = er.id_reports
 INNER JOIN epis_report_section ers ON er.id_epis_report = ers.id_epis_report
 INNER JOIN rep_section rs ON rs.id_rep_section = ers.id_rep_section_det --I have talked with Report Team to confirm this: id_rep_section_det column saves rep_section values
 INNER JOIN episode e ON e.id_episode = er.id_episode
 INNER JOIN institution i ON i.id_institution = e.id_institution
 INNER JOIN institution_language il ON i.id_institution = il.id_institution
 WHERE r.flg_xds_publishable = 'Y'
   AND rs.flg_xds_clinical_act = 'Y';
-- CHANGE END: Ariel Machado

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 23/09/2010
-- CHANGE REASON: [ALERT-126939]
CREATE OR REPLACE VIEW V_XDS_EVENT_CODE AS 
SELECT DISTINCT de.id_doc_external,
                rs.id_content event_code,
                rs.id_rep_section,
                pk_translation.get_translation(il.id_language, rs.code_rep_section) event_code_display_name,
                pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) event_code_coding_scheme
  FROM doc_external de
  LEFT OUTER JOIN epis_report erep
    ON erep.id_doc_external = de.id_doc_external
 INNER JOIN reports r
    ON r.id_reports = erep.id_reports
 INNER JOIN epis_report_section ers
    ON erep.id_epis_report = ers.id_epis_report
 INNER JOIN rep_section rs
    ON rs.id_rep_section = ers.id_rep_section_det --I have talked with Report Team to confirm this: id_rep_section_det column saves rep_section values
 INNER JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN institution i
    ON i.id_institution = e.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 WHERE r.flg_xds_publishable = 'Y'
   AND rs.flg_xds_clinical_act = 'Y'
UNION
SELECT DISTINCT de.id_doc_external,
                rs.id_content event_code,
                rs.id_rep_section,
                pk_translation.get_translation(il.id_language, rs.code_rep_section) event_code_display_name,
                pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) event_code_coding_scheme
  FROM doc_external de
  LEFT OUTER JOIN doc_image di
    ON di.id_doc_external = de.id_doc_external
 INNER JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN institution i
    ON i.id_institution = e.id_institution
 INNER JOIN institution_language il
    ON i.id_institution = il.id_institution
 INNER JOIN doc_types_config dtc ON dtc.id_doc_type = de.id_doc_type
 WHERE (dtc.id_doc_ori_type = de.id_doc_ori_type OR dtc.id_doc_ori_type_parent = de.id_doc_ori_type)
   AND dtc.flg_publishable = 'Y';
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 06/10/2010
-- CHANGE REASON: [ALERT-126939]
drop VIEW V_XDS_EVENT_CODE;
-- CHANGE END: Rui Spratley
