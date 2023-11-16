CREATE OR REPLACE VIEW v_analysis_parameter AS
SELECT ap.id_analysis_parameter, ap.code_analysis_parameter, ap.rank, ap.flg_type, ap.flg_available, ap.id_content
  FROM analysis_parameter ap;
