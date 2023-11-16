CREATE OR REPLACE VIEW v_p1_reason_code AS
SELECT id_reason_code, code_reason, rank, flg_type, flg_available, flg_other
  FROM p1_reason_code;

