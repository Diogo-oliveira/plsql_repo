CREATE OR REPLACE VIEW V_MYPAT_PHARM_VAL_DEPT AS -- FV: FOLLOW + VAL
SELECT v.*
  FROM v_mypat_pharm_val v
  JOIN tbl_temp t
    ON t.num_1 = v.id_department;
