-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EPIS_PRESCRIPTION_PHARM AS
SELECT p.id_prescription,
       p.flg_status,
       p.flg_type,
       p.id_patient,
       p.id_episode,
       p.dt_prof_print_tstz,
       ------------------------
       pp.id_prescription_pharm,
       pp.dt_prescription_pharm_tstz,
       pp.emb_id,
       pp.desc_manip,
       pp.order_modified,
       pp.patient_notified,
       ------------------------
       pp.qty_inst,
       pp.qty,
       pp.unit_measure_inst,
       pp.frequency,
       pp.id_unit_measure_freq,
       pp.duration,
       pp.id_unit_measure_dur,
       pp.id_unit_measure,
       pp.flg_chronic_medication,
       pp.id_presc_directions,
       pp.refill,
       pp.package_number,
       pp.notes,
       pp.regulation_id,
       pp.generico,
       pp.first_dose,
        pp.id_other_product,  pp.route_id, pp.dosage, pp.flg_attention
  FROM prescription p
  JOIN prescription_pharm pp
    ON (pp.id_prescription = p.id_prescription);
-- CHANGE END: Pedro Teixeira