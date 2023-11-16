CREATE OR REPLACE VIEW v_ref_comments AS
SELECT id_ref_comment,
       id_external_request,
       flg_type,
       id_professional,
       dt_comment,
       id_institution,
       id_software,
       flg_status,
       pk_translation.get_translation_trs(code_ref_comments) text_comment,
       dt_comment_canceled,
       id_institution_canceled,
       dt_comment_outdated,
       id_institution_outdated
  FROM ref_comments;
