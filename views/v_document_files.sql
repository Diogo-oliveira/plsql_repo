CREATE OR REPLACE VIEW V_DOCUMENT_FILES AS
SELECT decode(di.id_doc_image, NULL, er.id_epis_report, di.id_doc_image) file_id,
       decode(di.id_doc_image, NULL,
              pk_utils.create_oid(profissional(NULL, de.id_institution, NULL), 'ALERT_OID_HIE_EPIS_REPORT', er.id_epis_report),
              pk_doc_attach.get_attachment_oid(profissional(NULL, de.id_institution, NULL), di.id_doc_image)) file_oid,
       decode(di.id_doc_image, NULL, 'EPIS_REPORT', 'DOC_IMAGE') file_source,
       decode(di.id_doc_image, NULL,
              pk_doc_attach.get_file_name(pk_translation.get_translation(il.id_language, r.code_reports), r.mime_type),
              di.file_name) file_name,
       decode(di.id_doc_image, NULL, er.dt_creation_tstz, di.dt_img_tstz) file_creation_time,
       decode(di.id_doc_image, NULL, r.mime_type, pk_doc.get_doc_image_mime_type(di.id_doc_image)) file_mime_type,
       decode(di.id_doc_image, NULL, er.rep_binary_file, di.doc_img) file_blob,
       decode(di.id_doc_image, NULL, dbms_lob.getlength(er.rep_binary_file), di.img_size) file_size,
       de.id_doc_external doc_id,
       pk_doc.get_doc_oid(profissional(NULL, de.id_institution, NULL), de.id_doc_external) doc_oid
  FROM doc_external de
 LEFT JOIN doc_image di
    ON di.id_doc_external = de.id_doc_external
 LEFT JOIN epis_report er
    ON er.id_doc_external = de.id_doc_external
 LEFT JOIN reports r
    ON r.id_reports = er.id_reports
 INNER JOIN institution_language il
    ON il.id_institution = de.id_institution
 WHERE (di.flg_status = 'A' OR er.flg_status != 'N')
   AND de.flg_status = 'A';
