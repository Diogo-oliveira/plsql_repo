CREATE OR REPLACE VIEW DPD_MI_MED_COMPARE AS
SELECT dpd.ROWID AS "rowid",
       mm.vers,
       dpd.id_drug,
       mm.med_descr,
       mm.id_drug_brand,
       mm.dci_id,
       mm.dci_descr,
       mm.form_farm_id,
       mm.form_farm_descr,
       mm.dosagem,
       mm.flg_type,
       dpd.id_drug_presc_det,
       dpd.id_drug_prescription,
       mm.route_id
  FROM drug_presc_det dpd
  JOIN mi_med mm ON dpd.id_drug = mm.id_drug
                AND mm.flg_available = 'Y'
 WHERE dpd.flg_status IN ('X', 'SOS', 'SOSH', 'H', 'R', 'E') WITH READ ONLY;
