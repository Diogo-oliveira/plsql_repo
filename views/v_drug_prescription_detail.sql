CREATE OR REPLACE VIEW v_drug_prescription_detail AS
SELECT id_drug_presc_det,
       id_drug_prescription,
       dpd.notes,
       flg_take_type,
       qty,
       rate,
       flg_status,
       id_prof_cancel,
       notes_cancel,
       notes_justif,
       INTERVAL,
       takes,
       dosage,
       value_bolus,
       value_drip,
       dosage_description,
       id_unit_measure_bolus,
       id_unit_measure_drip,
       dpd.id_unit_measure,
       dt_begin_tstz,
       dt_end_tstz,
       dt_cancel_tstz,
       dt_end_presc_tstz,
       dt_end_bottle_tstz,
       dt_order,
       id_prof_order,
       id_order_type,
       flg_co_sign,
       dt_co_sign,
       id_prof_co_sign,
       frequency,
       id_unit_measure_freq,
       duration,
       dt_start_presc_tstz,
       dpd.route_id,
       dpd.id_drug,
       dispense,
       unit_measure_dispense,
       dt_hold_begin,
       dt_hold_end,
       med_descr_formated,
       med_descr,
       short_med_descr,
       flg_type,
       dci_id,
       dci_descr,
       mdm_coding,
       chnm_id,
       mm.id_content,
       mr.route_descr,
       mr.route_abrv,
       id_unit_measure_dur,
       dpd.id_vacc_manufacturer,
       dpd.code_mvx,
       vd.id_vacc,
       mm.code_cvx
  FROM drug_presc_det dpd
  LEFT JOIN mi_med mm
    ON dpd.id_drug = mm.id_drug
   AND dpd.vers = mm.vers
  LEFT JOIN mi_route mr
    ON dpd.route_id = mr.route_id
   AND dpd.vers = mr.vers
  LEFT JOIN vacc_dci vd
    ON vd.id_dci = mm.dci_id
  JOIN vacc_group vg
    ON vg.id_vacc = vd.id_vacc
   AND vg.id_vacc_group = 5000;
