-- CHANGED BY:  Pedro Morais
-- CHANGE DATE: 12/05/2011 16:55
-- CHANGE REASON: [ALERT-178353] Missing information in the detail screen (previous medication)
BEGIN
    INSERT INTO pat_medication_hist_list
        (id_pat_medication_hist_list,
         id_pat_medication_list,
         id_episode,
         id_patient,
         id_institution,
         id_software,
         year_begin,
         month_begin,
         day_begin,
         qty,
         frequency,
         flg_status,
         id_professional,
         notes,
         flg_presc,
         id_prescription_pharm,
         dt_pat_medication_list_tstz,
         id_unit_measure_qty,
         id_unit_measure_freq,
         freq,
         duration,
         id_unit_measure_dur,
         dt_start_pat_med_tstz,
         dt_end_pat_med_tstz,
         emb_id,
         id_prod_med,
         prod_med_decr,
         id_drug_req_det,
         id_drug_presc_det,
         quantity,
         id_epis_documentation,
         med_id_type,
         continue,
         vers,
         id_drug,
         med_id,
         dosage,
         --id_cancel_reason,
         --cancel_reason,
         flg_take_type,
         id_presc_directions)
        SELECT seq_pat_medication_hist_list.NEXTVAL,
               id_pat_medication_list,
               id_episode,
               id_patient,
               id_institution,
               id_software,
               year_begin,
               month_begin,
               day_begin,
               qty,
               frequency,
               flg_status,
               id_professional,
               notes,
               flg_presc,
               id_prescription_pharm,
               dt_pat_medication_list_tstz,
               id_unit_measure_qty,
               id_unit_measure_freq,
               freq,
               duration,
               id_unit_measure_dur,
               dt_start_pat_med_tstz,
               dt_end_pat_med_tstz,
               emb_id,
               id_prod_med,
               prod_med_decr,
               id_drug_req_det,
               id_drug_presc_det,
               quantity,
               id_epis_documentation,
               med_id_type,
               continue,
               vers,
               id_drug,
               med_id,
               dosage,
               --id_cancel_reason,
               --cancel_reason,
               flg_take_type,
               id_presc_directions
          FROM pat_medication_list
         WHERE id_pat_medication_list NOT IN (SELECT id_pat_medication_list
                                                FROM pat_medication_hist_list)
           AND (((id_drug, vers) IN (SELECT id_drug, vers
                                       FROM mi_med)) OR id_drug IS NULL)
           AND (vers IN (SELECT DISTINCT vers
                           FROM mi_med) OR vers IS NULL);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
END;
/
-- CHANGE END:  Pedro Morais