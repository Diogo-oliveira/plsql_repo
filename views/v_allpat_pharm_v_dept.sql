CREATE OR REPLACE VIEW V_ALLPAT_PHARM_V_DEPT AS
SELECT DISTINCT v.*
  FROM v_allpat_pharm_v v
  JOIN tbl_temp t
    ON (t.num_1 = v.id_department OR t.num_1 IS NULL OR t.num_2 = v.id_epis_type);