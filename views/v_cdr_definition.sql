CREATE OR REPLACE VIEW V_CDR_DEFINITION AS
SELECT cdrd.id_cdr_definition,
       cdrd.code_name,
       cdrd.id_institution,
       cdrd.flg_status,
       cdrd.flg_available,
       cdrt.id_cdr_type,
       cdrt.code_cdr_type,
       cdrt.icon,
       cdrd.code_description
  FROM cdr_definition cdrd
  JOIN cdr_type cdrt
    ON cdrd.id_cdr_type = cdrt.id_cdr_type;
