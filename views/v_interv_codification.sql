CREATE OR REPLACE VIEW v_interv_codification AS
SELECT ic.id_interv_codification,
       ic.id_codification,
       ic.id_intervention,
       ic.flg_available,
       ic.standard_code,
       ic.standard_desc,
       ic.dt_standard_begin,
       ic.dt_standard_end
  FROM interv_codification ic;
