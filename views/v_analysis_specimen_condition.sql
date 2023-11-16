CREATE OR REPLACE VIEW v_analysis_specimen_condition AS
SELECT id_specimen_condition, VALUE, code_specimen_condition, id_content, flg_available
  FROM analysis_specimen_condition;
