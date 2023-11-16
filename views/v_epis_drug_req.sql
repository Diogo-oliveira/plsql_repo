-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EPIS_DRUG_REQ AS
SELECT dr.id_drug_req,
       dr.id_episode,
       dr.id_patient,
       dr.flg_status,
       dr.dt_drug_req_tstz,
       dr.dt_begin_tstz,
       dr.id_prof_req,
       dr.flg_type,
       dr.dt_print_tstz,
       ------------------------
       drd.id_drug_req_det,
       drd.id_drug,
       drd.flg_status flg_status_det,
       drd.order_modified,
       drd.patient_notified,
       drd.dt_start_presc_tstz,
			 drd.vers,
       ------------------------
       drd.duration,
       drd.id_unit_measure_dur,
       drd.frequency,
       drd.id_unit_measure_freq
  FROM drug_req dr
  JOIN drug_req_det drd
    ON (drd.id_drug_req = dr.id_drug_req);
-- CHANGE END: Pedro Teixeira