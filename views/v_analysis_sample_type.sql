CREATE OR REPLACE VIEW v_analysis_sample_type AS
SELECT ast.id_analysis,
       'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis code_analysis,
       ast.id_sample_type,
       'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type code_sample_type,
       ast.id_content,
       ast.id_content_analysis,
       ast.id_content_sample_type,
       ast.flg_available,
       ast.gender,
       ast.age_min,
       ast.age_max
  FROM analysis_sample_type ast;


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1892

CREATE OR REPLACE VIEW v_analysis_sample_type AS
SELECT ast.id_analysis,
       'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis code_analysis,
       ast.id_sample_type,
       'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type code_sample_type,
       ast.id_content,
       ast.id_content_analysis,
       ast.id_content_sample_type,
       ast.flg_available,
       ast.gender,
       ast.age_min,
       ast.age_max,
       ast.code_analysis_sample_type  --CEMR-1462
  FROM analysis_sample_type ast;

-- CHANGE END: Ana Moita



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-8-20
-- CHANGED REASON: CEMR-1728

CREATE OR REPLACE VIEW v_analysis_sample_type AS
SELECT ast.id_analysis,
       'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis code_analysis,
       ast.id_sample_type,
       'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ast.id_sample_type code_sample_type,
       ast.id_content,
       ast.id_content_analysis,
       ast.id_content_sample_type,
       ast.flg_available,
       ast.gender,
       ast.age_min,
       ast.age_max,
       ast.code_analysis_sample_type  --CEMR-1462
  FROM analysis_sample_type ast;

-- CHANGE END: Ana Moita
