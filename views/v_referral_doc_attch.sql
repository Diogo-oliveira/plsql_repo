CREATE OR REPLACE VIEW V_REFERRAL_DOC_ATTCH AS
SELECT d.id_external_request id_external_request,
       pk_api_ref_ws.get_first_doc_external(1, profissional(null,null,4), d.id_doc_external) id_doc_external, -- first id_doc_external			 
       di.id_doc_image,
       di.file_name,
       di.dt_img_tstz,
       di.doc_img,
       di.title
  FROM doc_external d
  JOIN doc_image di ON d.id_doc_external = di.id_doc_external
 WHERE d.id_external_request IS NOT NULL
 and d.flg_status='A'
 and di.flg_status='A';
 
COMMENT ON TABLE V_REFERRAL_DOC_ATTCH IS 'Referral attatchments info'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.ID_EXTERNAL_REQUEST IS 'Referral identifier'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.ID_DOC_EXTERNAL IS 'Referral document identifier (first id)'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.ID_DOC_IMAGE IS 'Referral attatchment identifier'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.FILE_NAME IS 'Attatchment file name'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.DT_IMG_TSTZ IS 'Attatchment creation date'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.DOC_IMG IS 'Attatchment file'
/

COMMENT ON COLUMN V_REFERRAL_DOC_ATTCH.TITLE IS 'Attatchment title'
/
