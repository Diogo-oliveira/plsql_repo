CREATE OR REPLACE VIEW v_analysis_param AS
SELECT ap.id_analysis_param,
       ap.id_analysis,
       ap.flg_available,
       ap.id_institution,
       ap.id_software,
       ap.id_analysis_parameter,
       ap.rank,
       ap.color_graph,
       ap.flg_fill_type,
       ap.id_sample_type
  FROM analysis_param ap;
