CREATE OR REPLACE VIEW V_REFERRAL_DOC AS
SELECT id_external_request,
       pk_api_ref_ws.get_first_doc_external(1, profissional(null,null,4), id_doc_external) id_doc_external, -- first id_doc_external			 
       id_doc_type,
       nvl(pk_translation.get_translation(1, code_doc_type), code_doc_type) desc_doc_type,
       flg_sent_by,
       nvl(pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_SENT_BY', flg_sent_by, 1), flg_sent_by) desc_sent_by,
       flg_received,
       nvl(pk_sysdomain.get_domain('DOC_EXTERNAL.FLG_RECEIVED', flg_received, 1), flg_received) desc_received,
       title,
       num_attatch,
       decode(num_attatch, 0, 'N', 'Y') flg_doc_attatch,
       dt_inserted
  FROM (SELECT d.id_external_request id_external_request,
               d.id_doc_external id_doc_external,
               dt.id_doc_type id_doc_type,
               dt.code_doc_type,
               d.flg_sent_by flg_sent_by,
               d.flg_received flg_received,
               d.title title,
               (SELECT COUNT(1)
                  FROM doc_image di
                 WHERE di.id_doc_external = d.id_doc_external
                   AND di.flg_status = 'A') num_attatch, -- number of attatchments
               d.dt_inserted dt_inserted
          FROM doc_external d
          JOIN doc_type dt ON d.id_doc_type = dt.id_doc_type
         WHERE d.id_external_request IS NOT NULL
         and d.flg_status = 'A');
				 
COMMENT ON TABLE V_REFERRAL_DOC IS 'Referral clinical documents'
/

COMMENT ON COLUMN V_REFERRAL_DOC.ID_EXTERNAL_REQUEST IS 'Referral identifier'
/

COMMENT ON COLUMN V_REFERRAL_DOC.ID_DOC_EXTERNAL IS 'Referral document identifier (first id)'
/

COMMENT ON COLUMN V_REFERRAL_DOC.ID_DOC_TYPE IS 'Referral document type identifier'
/

COMMENT ON COLUMN V_REFERRAL_DOC.DESC_DOC_TYPE IS 'Referral document type description'
/

COMMENT ON COLUMN V_REFERRAL_DOC.FLG_SENT_BY IS 'Document sent by (E)mail; (F)ax; (M)ail'
/

COMMENT ON COLUMN V_REFERRAL_DOC.DESC_SENT_BY IS 'Document sent by description'
/

COMMENT ON COLUMN V_REFERRAL_DOC.FLG_RECEIVED IS 'Document received: (Y)es; (N)o.'
/

COMMENT ON COLUMN V_REFERRAL_DOC.DESC_RECEIVED IS 'Document received description'
/

COMMENT ON COLUMN V_REFERRAL_DOC.TITLE IS 'Document title'
/

COMMENT ON COLUMN V_REFERRAL_DOC.NUM_ATTATCH IS 'Number of attatchments associated to the document'
/

COMMENT ON COLUMN V_REFERRAL_DOC.DT_INSERTED IS 'Document creation date'
/

