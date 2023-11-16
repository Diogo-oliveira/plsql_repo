CREATE OR REPLACE VIEW V_XDS_DOCUMENT_FILES AS
SELECT 'DOC_IMAGE' img_type,
       'DI'||di.id_doc_image  id_xds_document_files,
       de.id_doc_external,
       de.id_grupo,
       nvl(de.id_grupo, de.id_doc_external) id_folder,
       di.id_doc_image id_doc,
       di.doc_img document,
       nvl(di.title, di.file_name) doc_name,
       pk_sysconfig.get_config('ALERT_OID_HIE_DOC_IMAGE', 0, 0) || '.' || di.id_doc_image unique_id,
       pk_doc.get_doc_image_mime_type(di.id_doc_image) mime_type,
       di.dt_img_tstz creation_time,
       xdf.document_format format_code,
       pk_translation.get_translation(il.id_language, xdf.code_document_format) format_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) format_code_coding_scheme
  FROM doc_external de
 INNER JOIN doc_image di
    ON di.id_doc_external = de.id_doc_external
 INNER JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN institution_language il
    ON e.id_institution = il.id_institution
 INNER JOIN xds_document_format xdf
    ON xdf.id_xds_document_format IN
       (SELECT dft.id_xds_document_format
          FROM doc_file_type dft
         WHERE dft.extension = lower(pk_doc.get_doc_image_extension(il.id_language,
                                                                    profissional(de.id_professional, e.id_institution, 0),
                                                                    di.id_doc_image)))
 WHERE di.flg_status = 'A'
   AND de.flg_status = 'A'
UNION ALL
SELECT 'EPIS_REPORT' img_type,
       'ER'||erep.id_epis_report  id_xds_document_files,
       de.id_doc_external id_doc_external,
       de.id_grupo,
       nvl(de.id_grupo, de.id_doc_external) id_folder,
       erep.id_epis_report id_doc,
       erep.rep_binary_file document,
       pk_translation.get_translation(il.id_language, 'REPORTS.CODE_REPORTS.' || erep.id_reports) doc_name,
       pk_sysconfig.get_config('ALERT_OID_HIE_EPIS_REPORT', 0, 0) || '.' || erep.id_epis_report unique_id,
       r.mime_type mime_type,
       erep.dt_creation_tstz creation_time,
       xdf.document_format format_code,
       pk_translation.get_translation(il.id_language, xdf.code_document_format) format_code_display_name,
       pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) format_code_coding_scheme
  FROM doc_external de
 INNER JOIN epis_report erep
    ON erep.id_doc_external = de.id_doc_external
 INNER JOIN reports r
    ON r.id_reports = erep.id_reports
 INNER JOIN episode e
    ON e.id_episode = de.id_episode
 INNER JOIN institution_language il
    ON e.id_institution = il.id_institution
 INNER JOIN xds_document_format xdf
    ON xdf.id_xds_document_format = 1
 WHERE
   (erep.flg_status != 'N' OR erep.flg_report_origin='D') AND
   de.flg_status = 'A'
;
