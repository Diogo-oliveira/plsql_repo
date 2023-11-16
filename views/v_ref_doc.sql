CREATE OR REPLACE VIEW V_REF_DOC AS
SELECT d.id_external_request,
       dt.id_doc_type,
       pk_translation.get_translation(1, dt.code_doc_type) desc_doc_type,
       d.flg_sent_by,
       pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', d.flg_sent_by, 1) desc_sent_by,
       d.title
  FROM doc_external d
  JOIN doc_type dt ON d.id_doc_type = dt.id_doc_type
 WHERE d.id_external_request IS NOT NULL;