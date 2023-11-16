CREATE OR REPLACE VIEW v_p1_detail AS
SELECT id_detail,
       id_external_request,
       text,
       flg_type,
       id_professional,
       id_institution,
       id_tracking,
       flg_status,
       dt_insert_tstz,
       id_group
  FROM p1_detail;