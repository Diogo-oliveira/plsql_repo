CREATE OR REPLACE VIEW v_family_relationship AS
SELECT id_family_relationship,
       code_family_relationship,
       adw_last_update,
       gender,
       flg_available,
       id_content
  FROM family_relationship;
