CREATE OR REPLACE VIEW V_MYPAT_PHARM_DISP_DEPT AS -- FV: FOLLOW + VAL
SELECT v.*
  FROM v_mypat_pharm_disp v
  JOIN tbl_temp t
    ON t.num_1 = v.id_department;
