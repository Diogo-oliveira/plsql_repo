CREATE OR REPLACE VIEW V_MYPAT_PHARM_VD AS
SELECT *
  FROM (SELECT *
          FROM v_mypat_pharm_disp
        UNION
        SELECT *
          FROM v_mypat_pharm_val) v;
