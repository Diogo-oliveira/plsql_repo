CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CANCEL_REA_AREA AS
SELECT desc_cancel_area, id_cancel_rea_area
  FROM (SELECT intern_name || ' [' || id_cancel_rea_area || ']' AS desc_cancel_area, id_cancel_rea_area
          FROM alert.cancel_rea_area a)
 ORDER BY 1;

