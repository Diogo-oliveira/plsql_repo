CREATE OR REPLACE VIEW v_analysis_codification AS
SELECT ac.id_analysis_codification,
       ac.id_codification,
       ac.id_analysis,
       ac.id_sample_type,
       ac.flg_available,
       ac.standard_code,
       ac.standard_desc,
       ac.dt_standard_begin,
       ac.dt_standard_end
  FROM analysis_codification ac;
