CREATE OR REPLACE VIEW V_SCH_INSTITUTION AS
SELECT i.id_parent id_parent_institution, i.id_institution, decode(i.flg_available, 'Y', 'A', 'I') flg_available
  FROM institution i;