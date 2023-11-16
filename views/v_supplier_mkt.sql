--ALERT-311265 (begin) vitor.reis
CREATE OR REPLACE VIEW V_SUPPLIER_MKT AS
SELECT sm.id_supplier,
       sm.id_market
  FROM alert_product_mt.supplier_mkt sm
 WHERE sm.flg_available = 'Y';
--ALERT-311265 (end) vitor.reis 

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 08/06/2016
-- CHANGE REASON: [ALERT-321361] Code update according to the new DM
BEGIN
    pk_versioning.run('DROP VIEW v_supplier_mkt');
END;
/
-- CHANGE END: rui.mendonca
