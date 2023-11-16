
-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-07-13
-- CHANGE REASON: [CEMR-1829] Missing requirements for InterAlert development
CREATE OR REPLACE VIEW ALERT.V_DEPARTMENT AS
SELECT d.id_department,
       d.id_institution,
       d.code_department,
       d.abbreviation,
       d.flg_type,
       d.id_dept,
       d.flg_default,
       d.flg_available,
       d.flg_unidose,
       d.phone_number,
       d.fax_number,
       d.id_software,
	   d.flg_priority,
	   d.flg_collection_by,
	   d.id_admission_type,
	   d.admission_time
  FROM department d;
-- CHANGE END: Amanda Lee