CREATE OR REPLACE VIEW V_SCH_DEPT AS
SELECT d.id_institution, d.id_dept, d.code_dept code_translation, decode(d.flg_available, 'Y', 'A', 'I') flg_available
  FROM dept d;
-- Diamantino Campos
-- APS-1657
CREATE OR REPLACE VIEW V_SCH_DEPT AS
SELECT d.id_institution, d.id_dept, d.code_dept code_translation, decode(d.flg_available, 'Y', 'A', 'I') flg_available,
       (SELECT pk_translation.get_translation(il.id_language, d.code_dept)
          FROM institution_language il
         WHERE il.id_institution = d.id_institution) name
  FROM dept d;
-- end APS-1657