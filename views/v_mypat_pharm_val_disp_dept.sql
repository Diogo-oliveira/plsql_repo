CREATE OR REPLACE VIEW V_MYPAT_PHARM_VAL_DISP_DEPT AS -- FV: FOLLOW + DISP + VAL
SELECT v.*
  FROM v_mypat_pharm_val_disp v
  JOIN tbl_temp t
    ON t.num_1 = v.id_department;
