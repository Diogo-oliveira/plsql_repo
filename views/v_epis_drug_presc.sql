-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EPIS_DRUG_PRESC AS
SELECT dp.id_drug_prescription,
       dp.id_episode,
       dp.id_prev_episode,
       dp.id_patient,
       dp.id_protocols,
       dp.id_professional,
       dp.flg_time,
       dp.flg_type,
       dp.flg_status,
       dp.dt_begin_tstz,
       dp.id_episode_origin,
       dp.id_episode_destination,
       dp.dt_drug_prescription_tstz,
       dp.dt_cancel_tstz,
       dp.id_prof_cancel,
       dp.num_days_expire,
       dp.barcode,
       dp.notes_cancel,
       ------------------------
       dpd.id_drug_presc_det,
       dpd.flg_status flg_status_det,
       dpd.notes_justif notes_justif_det,
       dpd.notes notes_det,
       dpd.notes_cancel notes_cancel_det,
       dpd.id_prof_order id_prof_order_det,
       dpd.dt_last_change dt_last_change_det,
       dpd.dt_begin_tstz dt_begin_tstz_det,
       dpd.flg_modified,
       dpd.value_drip,
       dpd.id_unit_measure_drip,
       dpd.value_bolus,
       dpd.id_unit_measure_bolus,
       dpd.flg_take_type,
       dpd.interval,
       dpd.takes,
       dpd.dosage,
       dpd.id_drug,
       dpd.vers
  FROM drug_prescription dp
 INNER JOIN drug_presc_det dpd
    ON (dpd.id_drug_prescription = dp.id_drug_prescription);
-- CHANGE END: Pedro Teixeira