CREATE OR REPLACE VIEW v_doc_comments AS 
SELECT id_doc_comment,
       id_doc_external,
       id_doc_image,
       desc_comment,
       flg_type,
       dt_comment,
       id_professional,
       flg_cancel,
       dt_cancel,
       id_prof_cancel
  FROM doc_comments;