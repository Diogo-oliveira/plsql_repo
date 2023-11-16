CREATE OR REPLACE VIEW v_exam_codification AS
SELECT ec.id_exam_codification,
       ec.id_codification,
       ec.id_exam,
       ec.flg_available,
       ec.standard_code,
       ec.standard_desc,
       ec.dt_standard_begin,
       ec.dt_standard_end
  FROM exam_codification ec;
