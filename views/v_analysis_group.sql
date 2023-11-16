CREATE OR REPLACE VIEW v_analysis_group AS
SELECT ag.id_analysis_group,
       ag.code_analysis_group,
       ag.rank,
       ag.gender,
       ag.age_min,
       ag.age_max,
       ag.id_content,
       ag.flg_available
  FROM analysis_group ag;
