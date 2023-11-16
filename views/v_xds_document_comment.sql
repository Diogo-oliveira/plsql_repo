-- CREATED BY: Carlos Guilherme
-- CREATED DATE: 7/12/2010
-- CREATED REASON: [ALERT-72584] DOCUMENTS ARCHIVE
CREATE OR REPLACE VIEW V_XDS_DOCUMENT_COMMENT AS
SELECT id_doc_comment,
       de.id_doc_external,
       de.id_grupo,
       nvl(de.id_grupo, de.id_doc_external) id_folder,
       id_doc_image,
       desc_comment,
       flg_type,
       dt_comment,
       dc.id_professional,
       dc.create_time
  FROM doc_comments dc, doc_external de
 WHERE de.flg_status = 'A'
   and dc.id_doc_external = de.id_doc_external
   and dc.flg_cancel = 'N';
 
 
create public synonym V_XDS_DOCUMENT_COMMENT for V_XDS_DOCUMENT_COMMENT;

grant select on V_XDS_DOCUMENT_COMMENT to intf_alert;
-- CREATED END: Carlos Guilherme
