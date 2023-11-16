CREATE OR REPLACE VIEW V_SCH_DEPARTMENT AS
SELECT s.id_institution,
       s.id_department,
	   s.id_dept,
       s.code_department code_translation,
       decode(s.flg_available, 'Y', 'A', 'I') flg_available,
       s.flg_type
  FROM department s;
  
-- Diamantino Campos
-- APS-1657  
CREATE OR REPLACE VIEW V_SCH_DEPARTMENT AS
SELECT s.id_institution,
       s.id_department,
       s.id_dept,
       s.code_department code_translation,
       decode(s.flg_available, 'Y', 'A', 'I') flg_available,
       (SELECT pk_translation.get_translation(il.id_language, s.code_department)
          FROM institution_language il
         WHERE il.id_institution = s.id_institution) name,       
       s.flg_type
  FROM alert.department s;
-- end APS-1657  