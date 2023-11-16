/*-- Last Change Revision: $Rev: 2027357 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_medication_current IS

    -- ***************************************************************************************
    -- PRIVATE PACKAGE VARIABLES
    -- ***************************************************************************************
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

    /********************************************************************************************
     * Get iv dose executed
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_drug_presc_plan        ID                
     *
     * @return                         Dosage executed
     *
     * @author                         Nuno Antunes
     * @version                        0.1
     * @since                          2010/10/20
    **********************************************************************************************/
    FUNCTION get_iv_dose_executed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_drug_presc_plan IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_drip_change  IN VARCHAR2 DEFAULT NULL
    ) RETURN drug_presc_plan.dosage_exec%TYPE IS
        l_dose_executed drug_presc_plan.dosage_exec%TYPE;
    
        l_dt_drip_change TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        g_error := 'GET_IV_DOSE_EXECUTED';
    
        IF i_dt_drip_change IS NOT NULL
        THEN
            l_dt_drip_change := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_drip_change, NULL);
        
            BEGIN
                SELECT round((((pk_date_utils.get_timestamp_diff(l_dt_drip_change,
                                                                 nvl(dpp.dt_value_drip_change, dpp.dt_take_tstz)) * 24 * 60) /*time_elapsed_last_drip_change*/
                             * pk_medication_core.convert2mlhr(dpp.rate, dpp.rate_unit_measure) /*dosage_administered_mlh*/
                             ) / 60),
                             3) + dpp.dosage_exec AS dosage_executed
                  INTO l_dose_executed
                  FROM drug_presc_plan dpp
                 WHERE dpp.id_drug_presc_plan = i_drug_presc_plan;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'no data found for ad_eternum GET_IV_DOSE_EXECUTED';
                    raise_application_error(-20001, g_error);
            END;
        ELSE
            BEGIN
                SELECT round((((pk_date_utils.get_timestamp_diff(current_timestamp,
                                                                 nvl(dpp.dt_value_drip_change, dpp.dt_take_tstz)) * 24 * 60) /*time_elapsed_last_drip_change*/
                             * pk_medication_core.convert2mlhr(dpp.rate, dpp.rate_unit_measure) /*dosage_administered_mlh*/
                             ) / 60),
                             3) + dpp.dosage_exec AS dosage_executed
                  INTO l_dose_executed
                  FROM drug_presc_plan dpp
                 WHERE dpp.id_drug_presc_plan = i_drug_presc_plan;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'no data found for ad_eternum GET_IV_DOSE_EXECUTED';
                    raise_application_error(-20001, g_error);
            END;
        END IF;
    
        IF l_dose_executed < 0
        THEN
            l_dose_executed := 0;
        END IF;
    
        RETURN l_dose_executed;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, g_error);
            /*            pk_alert_exceptions.process_error(i_lang     => i_lang,
            i_sqlcode  => SQLCODE,
            i_sqlerrm  => SQLERRM,
            i_message  => g_error,
            i_owner    => g_package_owner,
            i_package  => g_package_name,
            i_function => 'GET_IV_DOSE_EXECUTED',
            o_error    => o_error);*/
            RETURN NULL;
        
    END get_iv_dose_executed;

    /*-------------------------------------
    *  PRIVATE FUNCTIONS - 2.4.3          *
    -------------------------------------*/
    FUNCTION create_presc_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_notes        IN VARCHAR2 DEFAULT NULL,
        i_flg_change   IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT create_presc_hist(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_episode       => i_id_episode,
                                 i_type             => i_type,
                                 i_begin_status     => i_begin_status,
                                 i_end_status       => i_end_status,
                                 i_id_presc         => i_id_presc,
                                 i_notes            => i_notes,
                                 i_flg_change       => i_flg_change,
                                 i_cancel_reason    => NULL,
                                 i_id_cancel_reason => NULL,
                                 o_error            => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CREATE_PRESC_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc_hist;

    FUNCTION create_presc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_type             IN VARCHAR2,
        i_begin_status     IN VARCHAR2,
        i_end_status       IN VARCHAR2,
        i_id_presc         IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_notes            IN VARCHAR2 DEFAULT NULL,
        i_flg_change       IN VARCHAR2 DEFAULT NULL,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
    
        CURSOR c_old_info IS
            SELECT dpd.frequency,
                   dpd.id_unit_measure_freq,
                   dpd.duration,
                   dpd.id_unit_measure_dur,
                   dpd.qty_inst,
                   dpd.unit_measure_inst,
                   dpd.dt_last_change,
                   dp.id_episode,
                   dp.id_patient,
                   dpd.dosage,
                   dpd.flg_take_type,
                   dpd.qty,
                   dpd.id_unit_measure,
                   dpd.flg_status,
                   nvl(dpd.id_drug, dpd.id_other_product) id_drug,
                   dpd.dt_hold_begin,
                   dpd.dt_hold_end,
                   dpd.id_presc_directions
              FROM drug_presc_det dpd, drug_prescription dp
             WHERE dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug_presc_det = i_id_presc
               AND (i_type = g_local OR i_type = g_soro OR i_type = g_outros_prod OR i_type = g_compound);
    
        rec_old_info c_old_info%ROWTYPE;
    
    BEGIN
    
        OPEN c_old_info;
        FETCH c_old_info
            INTO rec_old_info;
        IF c_old_info%NOTFOUND
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-1002';
            CLOSE c_old_info;
            raise_application_error(-20001, g_error);
        END IF;
        CLOSE c_old_info;
    
        --Guarda histórico
        INSERT INTO prescription_instr_hist
            (id_prescription_instr_hist,
             id_presc,
             flg_type_presc,
             flg_change,
             flg_subtype_presc,
             qty,
             id_unit_measure_qty,
             frequency,
             id_unit_measure_freq,
             duration,
             id_unit_measure_dur,
             date_start,
             date_end,
             id_professional,
             id_institution,
             id_software,
             last_update_tstz,
             prescription_table,
             flg_status_old,
             flg_status_new,
             i_med,
             id_episode,
             id_patient,
             dosage,
             notes,
             dt_hold_begin,
             dt_hold_end,
             cancel_reason,
             id_cancel_reason,
             id_presc_directions)
        VALUES
            (seq_prescription_instr_hist.nextval,
             i_id_presc,
             g_flg_type_presc,
             decode(i_flg_change, NULL, 'S', i_flg_change),
             NULL,
             decode(rec_old_info.qty_inst, NULL, rec_old_info.qty, rec_old_info.qty_inst),
             decode(rec_old_info.unit_measure_inst, NULL, rec_old_info.id_unit_measure, rec_old_info.unit_measure_inst),
             rec_old_info.frequency,
             rec_old_info.id_unit_measure_freq,
             rec_old_info.duration,
             rec_old_info.id_unit_measure_dur,
             NULL,
             NULL,
             i_prof.id,
             i_prof.institution,
             i_prof.software,
             g_sysdate_tstz,
             'DRUG_PRESC_DET',
             i_begin_status,
             i_end_status,
             rec_old_info.id_drug,
             rec_old_info.id_episode,
             rec_old_info.id_patient,
             rec_old_info.dosage,
             i_notes,
             rec_old_info.dt_hold_begin,
             rec_old_info.dt_hold_end,
             i_cancel_reason,
             i_id_cancel_reason,
             rec_old_info.id_presc_directions);
    
        -- !!! Don't COMMIT
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CREATE_PRESC_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc_hist;
    --

    FUNCTION create_presc_hosp_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
    
        CURSOR c_drug_req_det IS
            SELECT dr.id_episode, dr.id_patient, drd.*
              FROM drug_req_det drd, drug_req dr
             WHERE drd.id_drug_req = dr.id_drug_req
               AND id_drug_req_det = i_id_presc;
    
        r_drug_req_det c_drug_req_det%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN c_drug_req_det';
        OPEN c_drug_req_det;
        FETCH c_drug_req_det
            INTO r_drug_req_det;
        g_found := c_drug_req_det%FOUND;
        CLOSE c_drug_req_det;
    
        --Guarda histórico
    
        g_error := 'INSERT INTO prescription_instr_hist IV';
        INSERT INTO prescription_instr_hist
            (id_prescription_instr_hist,
             id_presc,
             flg_type_presc,
             flg_subtype_presc,
             qty,
             id_unit_measure_qty,
             frequency,
             id_unit_measure_freq,
             duration,
             id_unit_measure_dur,
             date_start,
             date_end,
             id_professional,
             id_institution,
             id_software,
             last_update_tstz,
             prescription_table,
             flg_status_old,
             flg_status_new,
             flg_change,
             refill,
             prof_notes,
             order_modified_id_issue,
             order_modified_message,
             patient_notified,
             dosage,
             id_episode,
             id_patient,
             i_med)
        VALUES
            (seq_prescription_instr_hist.nextval,
             i_id_presc,
             g_flg_int,
             NULL,
             r_drug_req_det.qty_inst,
             r_drug_req_det.unit_measure_inst,
             r_drug_req_det.frequency,
             r_drug_req_det.id_unit_measure_freq,
             r_drug_req_det.duration,
             r_drug_req_det.id_unit_measure_dur,
             r_drug_req_det.dt_start_presc_tstz,
             r_drug_req_det.dt_end_presc_tstz,
             i_prof.id, --r_drug_req_det.id_prof_last_change,
             r_drug_req_det.id_inst_last_change,
             r_drug_req_det.id_sw_last_change,
             g_sysdate_tstz, --r_drug_req_det.dt_last_change,
             g_drug_req_det_table,
             r_drug_req_det.flg_status,
             r_drug_req_det.flg_status,
             g_flg_change_sta,
             r_drug_req_det.refill,
             r_drug_req_det.notes,
             r_drug_req_det.order_modified_id_issue,
             r_drug_req_det.order_modified_message,
             r_drug_req_det.patient_notified,
             r_drug_req_det.dosage,
             r_drug_req_det.id_episode,
             r_drug_req_det.id_patient,
             r_drug_req_det.id_drug);
    
        -- !!! Don't COMMIT
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'create_presc_hosp_hist',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc_hosp_hist;
    --

    FUNCTION create_presc_pharm_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_type              IN VARCHAR2,
        i_begin_status      IN VARCHAR2,
        i_end_status        IN VARCHAR2,
        i_id_presc          IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_flg_type_presc    IN pk_medication_types.pih_flg_type_presc_t,
        i_flg_subtype_presc IN pk_medication_types.pih_flg_subtype_presc_t,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
    
        CURSOR c_presc_pharm IS
            SELECT p.id_episode, p.id_patient, pp.*
              FROM prescription_pharm pp, prescription p
             WHERE p.id_prescription = pp.id_prescription
               AND pp.id_prescription_pharm = i_id_presc;
    
        r_presc_pharm c_presc_pharm%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN c_presc_pharm';
        OPEN c_presc_pharm;
        FETCH c_presc_pharm
            INTO r_presc_pharm;
        g_found := c_presc_pharm%FOUND;
        CLOSE c_presc_pharm;
    
        pk_alertlog.log_debug(r_presc_pharm.qty_manip);
        pk_alertlog.log_debug(r_presc_pharm.unit_manip);
    
        g_error := 'INSERT INTO prescription_instr_hist V';
        INSERT INTO prescription_instr_hist
            (id_prescription_instr_hist,
             id_presc,
             flg_type_presc,
             flg_subtype_presc,
             qty,
             id_unit_measure_qty,
             frequency,
             id_unit_measure_freq,
             duration,
             id_unit_measure_dur,
             date_start,
             date_end,
             id_professional,
             id_institution,
             id_software,
             last_update_tstz,
             prescription_table,
             flg_status_old,
             flg_status_new,
             flg_change,
             refill,
             prof_notes,
             order_modified_id_issue,
             order_modified_message,
             patient_notified,
             dosage,
             id_episode,
             id_patient,
             i_med,
             qty_manip,
             unit_manip)
        VALUES
            (seq_prescription_instr_hist.nextval,
             i_id_presc,
             i_flg_type_presc,
             i_flg_subtype_presc,
             r_presc_pharm.qty_inst,
             r_presc_pharm.unit_measure_inst,
             r_presc_pharm.frequency,
             r_presc_pharm.id_unit_measure_freq,
             r_presc_pharm.duration,
             r_presc_pharm.id_unit_measure_dur,
             r_presc_pharm.dt_start_presc_tstz,
             r_presc_pharm.dt_end_presc_tstz,
             i_prof.id, --r_presc_pharm.id_prof_last_change,
             r_presc_pharm.id_inst_last_change,
             r_presc_pharm.id_sw_last_change,
             current_timestamp,
             g_presc_pharm_table,
             i_begin_status,
             i_end_status,
             g_flg_change_sta,
             r_presc_pharm.refill,
             r_presc_pharm.notes,
             r_presc_pharm.order_modified_id_issue,
             r_presc_pharm.order_modified_message,
             r_presc_pharm.patient_notified,
             r_presc_pharm.dosage,
             r_presc_pharm.id_episode,
             r_presc_pharm.id_patient,
             r_presc_pharm.id_dietary_drug,
             r_presc_pharm.qty_manip,
             r_presc_pharm.unit_manip);
        -- !!! Don't COMMIT
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CREATE_PRESC_PHARM_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc_pharm_hist;
    --

    FUNCTION create_reported_drug_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_begin_status IN VARCHAR2,
        i_end_status   IN VARCHAR2,
        i_id_presc     IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'call create_reported_drug_hist';
        IF NOT create_reported_drug_hist(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_episode       => NULL,
                                         i_type             => i_type,
                                         i_begin_status     => i_begin_status,
                                         i_end_status       => i_end_status,
                                         i_id_presc         => i_id_presc,
                                         i_id_cancel_reason => NULL,
                                         i_cancel_reason    => NULL,
                                         i_notes            => NULL,
                                         o_error            => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CREATE_REPORTED_DRUG_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_reported_drug_hist;

    FUNCTION create_reported_drug_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_type             IN VARCHAR2,
        i_begin_status     IN VARCHAR2,
        i_end_status       IN VARCHAR2,
        i_id_presc         IN pk_medication_types.dpd_dpd_id_drug_presc_det_t,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
    
        CURSOR c_pat_med IS
            SELECT *
              FROM pat_medication_list pml
             WHERE pml.id_pat_medication_list = i_id_presc;
    
        r_pat_med c_pat_med%ROWTYPE;
    
    BEGIN
        g_error := 'FETCH c_pat_med';
        OPEN c_pat_med;
        FETCH c_pat_med
            INTO r_pat_med;
        g_found := c_pat_med%FOUND;
        CLOSE c_pat_med;
    
        g_error := 'INSERT INTO prescription_instr_hist VIII';
        pk_alertlog.log_debug(g_error);
        INSERT INTO prescription_instr_hist
            (id_prescription_instr_hist,
             id_presc,
             flg_type_presc,
             flg_change,
             flg_subtype_presc,
             qty,
             id_unit_measure_qty,
             frequency,
             id_unit_measure_freq,
             duration,
             id_unit_measure_dur,
             date_start,
             date_end,
             id_professional,
             id_institution,
             id_software,
             last_update_tstz,
             prescription_table,
             id_patient,
             id_episode,
             flg_status_old,
             flg_status_new,
             i_med,
             cancel_reason,
             id_cancel_reason,
             notes)
        VALUES
            (seq_prescription_instr_hist.nextval,
             i_id_presc,
             g_flg_type_reported,
             g_flg_change_sta,
             decode(i_type, g_outros, g_flg_relat_outros, g_relatos_int, g_flg_relat_int, g_flg_relat_ext),
             r_pat_med.quantity,
             r_pat_med.id_unit_measure_qty,
             r_pat_med.freq,
             r_pat_med.id_unit_measure_freq,
             r_pat_med.duration,
             r_pat_med.id_unit_measure_dur,
             r_pat_med.dt_start_pat_med_tstz,
             r_pat_med.dt_end_pat_med_tstz,
             r_pat_med.id_professional,
             r_pat_med.id_institution,
             r_pat_med.id_software,
             r_pat_med.dt_pat_medication_list_tstz,
             'PAT_MEDICATION_LIST',
             r_pat_med.id_patient,
             r_pat_med.id_episode,
             i_end_status, -----
             nvl(r_pat_med.continue, r_pat_med.flg_status),
             decode(i_type, g_outros, r_pat_med.id_prod_med, g_relatos_int, r_pat_med.id_drug, r_pat_med.med_id),
             i_cancel_reason,
             i_id_cancel_reason,
             i_notes);
    
        g_error := 'INSERT INTO PAT_MEDICATION_HIST_LIST';
        pk_alertlog.log_debug(g_error);
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
             CONTINUE,
             vers,
             id_drug,
             med_id,
             dosage,
             cancel_reason,
             id_cancel_reason)
        VALUES
            (seq_pat_medication_hist_list.nextval,
             r_pat_med.id_pat_medication_list,
             r_pat_med.id_episode,
             r_pat_med.id_patient,
             r_pat_med.id_institution,
             r_pat_med.id_software,
             r_pat_med.year_begin,
             r_pat_med.month_begin,
             r_pat_med.day_begin,
             r_pat_med.qty,
             r_pat_med.frequency,
             i_end_status, ---------------
             r_pat_med.id_professional,
             i_notes,
             r_pat_med.flg_presc,
             r_pat_med.id_prescription_pharm,
             r_pat_med.dt_pat_medication_list_tstz,
             r_pat_med.id_unit_measure_qty,
             r_pat_med.id_unit_measure_freq,
             r_pat_med.freq,
             r_pat_med.duration,
             r_pat_med.id_unit_measure_dur,
             r_pat_med.dt_start_pat_med_tstz,
             r_pat_med.dt_end_pat_med_tstz,
             r_pat_med.emb_id,
             r_pat_med.id_prod_med,
             r_pat_med.prod_med_decr,
             r_pat_med.id_drug_req_det,
             r_pat_med.id_drug_presc_det,
             r_pat_med.quantity,
             r_pat_med.id_epis_documentation,
             r_pat_med.med_id_type,
             r_pat_med.continue,
             r_pat_med.vers,
             r_pat_med.id_drug,
             r_pat_med.med_id,
             r_pat_med.dosage,
             i_cancel_reason,
             i_id_cancel_reason);
        -- !!! Don't COMMIT
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CREATE_REPORTED_DRUG_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_reported_drug_hist;

    /*-------------------------------------
    *  END OF PRIVATE FUNCTIONS - 2.4.3    *
    --------------------------------------*/
    
    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2 IS
        CURSOR c_get_cat_type IS
            SELECT c.flg_type
              FROM category c, professional p, prof_cat pc
             WHERE pc.id_professional = p.id_professional
               AND pc.id_category = c.id_category
               AND p.id_professional = i_prof.id;
        l_prof_cat_type category.flg_type%TYPE;
    BEGIN
        OPEN c_get_cat_type;
        FETCH c_get_cat_type
            INTO l_prof_cat_type;
        CLOSE c_get_cat_type;
        RETURN l_prof_cat_type;
    END;

    /*Cancel with commit parameter*/
    FUNCTION cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type         IN VARCHAR2,
        i_id_presc     IN NUMBER,
        i_notes_cancel IN VARCHAR2,
        i_commit       IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error VARCHAR2(2000);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        IF i_type = g_local --Administrar neste local
        THEN
            DECLARE
                l_prof_cat_type category.flg_type%TYPE;
            BEGIN
                l_prof_cat_type := get_prof_cat(i_prof);
                --                IF c_get_cat_type%NOTFOUND
                IF l_prof_cat_type IS NULL
                THEN
                    --                  CLOSE c_get_cat_type;
                    l_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-2000';
                    raise_application_error(-20001, l_error);
                    --RETURN FALSE;
                END IF;
                --                CLOSE c_get_cat_type;
                IF NOT pk_prescription_int.cancel_presc(i_lang, i_id_presc, i_prof, i_notes_cancel, i_commit, o_error)
                THEN
                    l_error := pk_message.get_message(i_lang, 'COMMON_M001') || l_error || 'ERR-2001';
                    raise_application_error(-20001, l_error);
                    -- RETURN FALSE;
                
                END IF;
                NULL;
            END;
        ELSIF i_type IN (g_exterior, g_manipulados, g_dietetico, g_hospital, g_exterior_chronic)
        THEN
            DECLARE
                l_episode       episode.id_episode%TYPE;
                l_emb           me_med.emb_id%TYPE;
                l_flg_type      VARCHAR2(2);
                l_prof_cat_type category.flg_type%TYPE;
                CURSOR c_get_info IS
                    SELECT p.id_episode, pp.emb_id
                      FROM prescription p, prescription_pharm pp
                     WHERE p.id_prescription = pp.id_prescription
                       AND pp.id_prescription_pharm = i_id_presc;
            
                CURSOR c_get_info_hospital IS
                    SELECT dr.id_episode, drd.id_drug
                      FROM drug_req dr, drug_req_det drd
                     WHERE dr.id_drug_req = drd.id_drug_req
                       AND drd.id_drug_req_det = i_id_presc;
            
                CURSOR c_get_cat_type IS
                    SELECT c.flg_type
                      FROM category c, professional p, prof_cat pc
                     WHERE pc.id_professional = p.id_professional
                       AND pc.id_category = c.id_category;
            BEGIN
                IF i_type IN (g_exterior, g_exterior_chronic)
                THEN
                    l_flg_type := g_flg_ext;
                ELSIF i_type = g_manipulados
                THEN
                    l_flg_type := g_flg_manip_ext;
                ELSIF i_type = g_dietetico
                THEN
                    l_flg_type := g_flg_dietary_ext;
                ELSIF i_type = g_hospital
                THEN
                    l_flg_type := g_flg_int;
                END IF;
                OPEN c_get_cat_type;
                FETCH c_get_cat_type
                    INTO l_prof_cat_type;
                IF c_get_cat_type%NOTFOUND
                THEN
                    CLOSE c_get_cat_type;
                    l_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-2008';
                    raise_application_error(-20001, l_error);
                    -- RETURN FALSE;
                END IF;
                CLOSE c_get_cat_type;
                IF i_type = g_hospital
                THEN
                
                    OPEN c_get_info_hospital;
                    FETCH c_get_info_hospital
                        INTO l_episode, l_emb;
                    IF c_get_info_hospital%NOTFOUND
                    THEN
                        CLOSE c_get_info_hospital;
                        l_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-2009';
                        raise_application_error(-20001, l_error);
                        --RETURN FALSE;
                    END IF;
                    CLOSE c_get_info_hospital;
                ELSE
                
                    OPEN c_get_info;
                    FETCH c_get_info
                        INTO l_episode, l_emb;
                    IF c_get_info%NOTFOUND
                    THEN
                        CLOSE c_get_info;
                        l_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-2009';
                        raise_application_error(-20001, l_error);
                        --  RETURN FALSE;
                    END IF;
                    CLOSE c_get_info;
                END IF;
                IF NOT pk_prescription.cancel_pharm_prescr(i_lang,
                                                           l_episode,
                                                           i_id_presc,
                                                           l_emb,
                                                           l_flg_type,
                                                           i_prof,
                                                           l_prof_cat_type,
                                                           i_commit,
                                                           o_error)
                THEN
                    l_error := pk_message.get_message(i_lang, 'COMMON_M001') || l_error || 'ERR-2010';
                    raise_application_error(-20001, l_error);
                    -- RETURN FALSE;
                END IF;
            END;
        ELSIF i_type = g_outros
              OR i_type = g_relatos_int
              OR i_type = g_relatos_ext
        THEN
            IF NOT update_status_with_commit(i_lang, NULL, i_prof, i_type, NULL, 'C', i_id_presc, i_commit, o_error)
            THEN
                l_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-2010';
                raise_application_error(-20001, l_error);
                --RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CANCEL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel;

    /********************************************************************************************
    * Update the status of prescriptions.
    *
    * @ param i_lang
    * @ param i_prof                   professional identification
    * @ param i_type                   prescrition type
    * @ param begin_status             prescription current status (before the update)
    * @ param end_status               prescription next status (after the update)
    * @ param i_id_presc               prescription id
    * @ param o_error                  Error message
    
    * @return                         true or false on success or error
    *
    * @author
    * @version                        0.1
    * @since
    **********************************************************************************************/

    FUNCTION update_status_with_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        begin_status       IN prescription.flg_status%TYPE,
        end_status         IN prescription.flg_status%TYPE,
        i_id_presc         IN NUMBER,
        i_commit           IN VARCHAR,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        CURSOR c_check_all_det_status IS
            SELECT flg_status
              FROM drug_presc_det dpd
             WHERE dpd.id_drug_prescription IN (SELECT id_drug_prescription
                                                  FROM drug_presc_det dpd1
                                                 WHERE dpd1.id_drug_presc_det = i_id_presc)
               AND dpd.flg_status != end_status
             GROUP BY flg_status;
        rec_check_all_det_status c_check_all_det_status%ROWTYPE;
    
        CURSOR c_old_info IS
            SELECT dp.id_drug_prescription,
                   dpd.id_drug_presc_det,
                   dpd.flg_take_type,
                   --NA ALERT-839
                   dp.flg_status
            --NA ALERT-839              
              FROM drug_presc_det dpd, drug_prescription dp
             WHERE dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug_presc_det = i_id_presc
               AND (i_type = g_local OR i_type = g_soro OR i_type = g_outros_prod OR i_type = g_compound);
    
        rec_old_info c_old_info%ROWTYPE;
    
        CURSOR c_first_change IS
            SELECT qty,
                   id_unit_measure_qty,
                   frequency,
                   id_unit_measure_freq,
                   duration,
                   id_unit_measure_dur,
                   flg_status_old
              FROM prescription_instr_hist pih, drug_presc_plan dpp
             WHERE prescription_table = 'DRUG_PRESC_DET'
               AND i_type = g_local
               AND pih.id_presc = i_id_presc
               AND pih.id_prescription_instr_hist IN (SELECT MAX(id_prescription_instr_hist)
                                                        FROM prescription_instr_hist pih_aux
                                                       WHERE pih_aux.id_presc = i_id_presc
                                                         AND prescription_table = 'DRUG_PRESC_DET'
                                                         AND i_type = g_local)
            UNION
            SELECT qty,
                   id_unit_measure_qty,
                   frequency,
                   id_unit_measure_freq,
                   duration,
                   id_unit_measure_dur,
                   flg_status_old
              FROM prescription_instr_hist pih
             WHERE prescription_table = 'DRUG_PRESC_DET'
               AND i_type = g_soro
               AND id_presc = i_id_presc
               AND pih.id_prescription_instr_hist IN (SELECT MAX(id_prescription_instr_hist)
                                                        FROM prescription_instr_hist pih_aux
                                                       WHERE pih_aux.id_presc = i_id_presc
                                                         AND prescription_table = 'DRUG_PRESC_DET'
                                                         AND i_type = g_soro);
        rec_first_change c_first_change%ROWTYPE;
    
        CURSOR c_pat_med IS
            SELECT *
              FROM pat_medication_list pml
             WHERE pml.id_pat_medication_list = i_id_presc;
    
        r_pat_med c_pat_med%ROWTYPE;
    
        CURSOR c_presc_pharm IS
            SELECT p.id_episode, p.id_patient, pp.*
              FROM prescription_pharm pp, prescription p
             WHERE p.id_prescription = pp.id_prescription
               AND pp.id_prescription_pharm = i_id_presc;
    
        r_presc_pharm c_presc_pharm%ROWTYPE;
    
        CURSOR c_drug_req_det IS
            SELECT dr.id_episode, dr.id_patient, drd.*
              FROM drug_req_det drd, drug_req dr
             WHERE drd.id_drug_req = dr.id_drug_req
               AND id_drug_req_det = i_id_presc;
    
        r_drug_req_det c_drug_req_det%ROWTYPE;
    
        --get do episodio associado à prescrição
        CURSOR c_episode IS
            SELECT dp.id_episode
              FROM drug_prescription dp, drug_presc_det dpd
             WHERE dpd.id_drug_presc_det = i_id_presc
               AND dp.id_drug_prescription = dpd.id_drug_prescription;
    
        --id do episode associado à prescrição
        l_id_episode episode.id_episode%TYPE;
    
        max_idpp drug_presc_plan.id_drug_presc_plan%TYPE;
        --logging
        l_log_str VARCHAR2(250) := '';
    
        l_flg_status VARCHAR2(1) := '';
    
        -- denormalization variables
        l_rowids table_varchar;
    
        l_dt_cancel_aux   drug_presc_det.dt_cancel_tstz%TYPE;
        l_prof_cancel_aux drug_presc_det.id_prof_cancel%TYPE;
    BEGIN
    
        g_prescription_version := pk_sysconfig.get_config(g_presc_type, i_prof);
        g_sysdate_tstz         := current_timestamp; --
    
        l_log_str := 'UPDATE_STATUS:(i_type = ' || i_type || ', i_id_presc = ' || i_id_presc || ', begin_status = ' ||
                     begin_status || ', end_status = ' || end_status || ')';
        pk_alertlog.log_debug(l_log_str);
    
        --Update Administrar neste local ou soros
        IF i_type = g_local
           OR i_type = g_soro --Administrar neste local ou soros
           OR i_type = g_outros_prod --outros produtos
           OR i_type = g_compound --Compounds
        THEN
            --Informação anterior
            OPEN c_old_info;
            FETCH c_old_info
                INTO rec_old_info;
            IF c_old_info%NOTFOUND
            THEN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-1002';
                CLOSE c_old_info;
                raise_application_error(-20001, g_error);
                --RETURN FALSE;
            END IF;
            CLOSE c_old_info;
        
            --Regra fantática!
            /*
            (R,D -> S,C) OR (S -> I) OR (R -> I) OR (F-> I,S) OR (P -> I,S) OR (B -> S,I)
            */
            IF (begin_status IN (pk_medication_current.g_flg_d, pk_medication_current.g_flg_r) AND
               end_status IN (pk_medication_current.g_flg_s, pk_medication_current.g_flg_c) OR
               (begin_status = pk_medication_current.g_flg_s AND end_status = pk_medication_current.g_flg_i) OR
               (begin_status = pk_medication_current.g_flg_r AND end_status = pk_medication_current.g_flg_i) OR
               (begin_status = pk_medication_current.g_flg_f AND
               end_status IN (pk_medication_current.g_flg_i, pk_medication_current.g_flg_s)) OR
               (begin_status = pk_medication_current.g_flg_p AND
               end_status IN (pk_medication_current.g_flg_i, pk_medication_current.g_flg_s)) OR
               (begin_status = pk_medication_current.g_flg_m AND
               end_status IN (pk_medication_current.g_flg_i, pk_medication_current.g_flg_s)) OR
               (begin_status = pk_medication_current.g_flg_o AND
               end_status IN (pk_medication_current.g_flg_i, pk_medication_current.g_flg_s)) OR
               (begin_status = pk_medication_current.g_flg_d AND
               end_status IN (pk_medication_current.g_flg_i, pk_medication_current.g_flg_s)) OR
               (begin_status IN (pk_medication_current.g_flg_b, 'H') AND
               end_status IN (pk_medication_current.g_flg_s, pk_medication_current.g_flg_i)))
            
            THEN
                --Guarda histórico
                IF NOT create_presc_hist(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_episode       => i_epis,
                                         i_type             => i_type,
                                         i_begin_status     => begin_status,
                                         i_end_status       => end_status,
                                         i_id_presc         => i_id_presc,
                                         i_cancel_reason    => i_cancel_reason,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_notes            => i_notes,
                                         o_error            => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
                --Altera estado
                g_error           := 'UPDATE DRUG_PRESC_DET';
                l_dt_cancel_aux   := CASE end_status
                                         WHEN g_flg_c THEN
                                          current_timestamp
                                         ELSE
                                          NULL
                                     END;
                l_prof_cancel_aux := CASE end_status
                                         WHEN g_flg_c THEN
                                          i_prof.id
                                         ELSE
                                          NULL
                                     END;
            
                ts_drug_presc_det.upd(id_drug_presc_det_in => i_id_presc,
                                      flg_status_in        => end_status,
                                      dt_cancel_tstz_in    => l_dt_cancel_aux,
                                      dt_cancel_tstz_nin   => FALSE,
                                      id_prof_cancel_in    => l_prof_cancel_aux,
                                      id_prof_cancel_nin   => FALSE,
                                      dt_last_change_in    => g_sysdate_tstz,
                                      dt_last_change_nin   => FALSE,
                                      flg_modified_in      => NULL,
                                      flg_modified_nin     => FALSE,
                                      rows_out             => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DRUG_PRESC_DET',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                SELECT MAX(id_drug_presc_plan)
                  INTO max_idpp
                  FROM drug_presc_plan
                 WHERE id_drug_presc_det = i_id_presc
                   AND flg_status = 'Z';
            
                --Para medicamentos contínuos (dpd.flg_take_type = C):
                -- Caso se suspenda ou descontinue,
                -- o que deve tomar esse estado é a ultima toma dada e não todas as tomas dadas.
                IF rec_old_info.flg_take_type = g_flg_take_type_cont
                   AND end_status IN (g_flg_s, g_flg_i)
                THEN
                
                    SELECT MAX(id_drug_presc_plan)
                      INTO max_idpp
                      FROM drug_presc_plan
                     WHERE id_drug_presc_det = i_id_presc;
                
                    /* <DENORM Fábio> */
                    l_rowids := table_varchar();
                    ts_drug_presc_plan.upd(id_drug_presc_plan_in => max_idpp,
                                           flg_status_in         => end_status,
                                           rows_out              => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'DRUG_PRESC_PLAN',
                                                  l_rowids,
                                                  o_error,
                                                  table_varchar('FLG_STATUS'));
                    --NA ALERT-839
                ELSIF max_idpp IS NOT NULL --If it is ongoing
                      AND rec_old_info.flg_take_type = 'U'
                THEN
                
                    --Na dpp fica com o estado administrado e o interrompido fica na tabela de historico!!
                    l_rowids := table_varchar();
                    ts_drug_presc_plan.upd(id_drug_presc_plan_in => max_idpp,
                                           flg_status_in         => g_presc_plan_stat_adm, --end_status
                                           dosage_exec_in        => get_iv_dose_executed(i_lang, i_prof, max_idpp),
                                           rows_out              => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'DRUG_PRESC_PLAN',
                                                  l_rowids,
                                                  o_error,
                                                  table_varchar('FLG_STATUS'));
                    --NA ALERT-839
                END IF;
            
                --Se esta em curso , pode suspender, interromper ou então pode cancelar
                /*
                (E -> S,I) OR (end = C)
                */
            ELSIF (begin_status IN (g_flg_e, g_flg_m, g_flg_o) AND end_status IN (g_flg_s, g_flg_i))
                  OR (end_status = g_flg_c)
            THEN
                pk_alertlog.log_debug('Se esta em curso , pode suspender, interromper ou então pode cancelar');
                --Guarda histórico
                IF NOT create_presc_hist(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_episode       => i_epis,
                                         i_type             => i_type,
                                         i_begin_status     => begin_status,
                                         i_end_status       => end_status,
                                         i_id_presc         => i_id_presc,
                                         i_cancel_reason    => i_cancel_reason,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_notes            => i_notes,
                                         o_error            => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            
                pk_alertlog.log_debug('create_presc_hist returned TRUE!!!!!!!!');
            
                --Altera estado
                IF end_status = g_flg_c
                THEN
                    g_error           := 'UPDATE DRUG_PRESC_DET';
                    l_dt_cancel_aux   := CASE end_status
                                             WHEN g_flg_c THEN
                                              current_timestamp
                                             ELSE
                                              NULL
                                         END;
                    l_prof_cancel_aux := CASE end_status
                                             WHEN g_flg_c THEN
                                              i_prof.id
                                             ELSE
                                              NULL
                                         END;
                
                    l_rowids := table_varchar();
                    ts_drug_presc_det.upd(id_drug_presc_det_in => i_id_presc,
                                          flg_status_in        => end_status,
                                          dt_cancel_tstz_in    => l_dt_cancel_aux,
                                          dt_cancel_tstz_nin   => FALSE,
                                          id_prof_cancel_in    => l_prof_cancel_aux,
                                          id_prof_cancel_nin   => FALSE,
                                          dt_last_change_in    => g_sysdate_tstz,
                                          dt_last_change_nin   => FALSE,
                                          rows_out             => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'DRUG_PRESC_DET',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                    --
                
                ELSE
                    g_error := 'UPDATE DRUG_PRESC_DET';
                    ts_drug_presc_det.upd(id_drug_presc_det_in => i_id_presc,
                                          flg_status_in        => end_status,
                                          dt_last_change_in    => g_sysdate_tstz,
                                          dt_last_change_nin   => FALSE,
                                          flg_modified_in      => NULL,
                                          flg_modified_nin     => FALSE,
                                          rows_out             => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'DRUG_PRESC_DET',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                    --
                
                    -- Caso se suspenda ou descontinue,
                    -- o que deve tomar esse estado é a ultima toma dada e nãotodas as tomas dadas.
                    IF end_status IN (g_flg_s, g_flg_i)
                       AND rec_old_info.flg_take_type != 'S'
                    THEN
                    
                        --NA ALERT-839
                        IF rec_old_info.flg_status = 'Z'
                        THEN
                            UPDATE drug_presc_plan dpp
                               SET dpp.flg_status = g_presc_plan_stat_adm
                             WHERE dpp.id_drug_presc_det = i_id_presc
                               AND dpp.flg_status = 'Z';
                        
                            l_rowids := table_varchar();
                            ts_drug_presc_plan.upd(flg_status_in => end_status,
                                                   where_in      => 'id_drug_presc_det = ' || i_id_presc ||
                                                                    ' AND flg_status != ''' || g_presc_plan_stat_adm || '''',
                                                   rows_out      => l_rowids);
                        ELSE
                        
                            SELECT MAX(id_drug_presc_plan)
                              INTO max_idpp
                              FROM drug_presc_plan
                             WHERE id_drug_presc_det = i_id_presc;
                        
                            l_rowids := table_varchar();
                            ts_drug_presc_plan.upd(id_drug_presc_plan_in => max_idpp,
                                                   flg_status_in         => end_status,
                                                   rows_out              => l_rowids);
                        END IF;
                        --NA ALERT-839
                    
                        t_data_gov_mnt.process_update(i_lang,
                                                      i_prof,
                                                      'DRUG_PRESC_PLAN',
                                                      l_rowids,
                                                      o_error,
                                                      table_varchar('FLG_STATUS'));
                    
                        IF end_status = g_flg_i
                        THEN
                        
                            -- Remoção do alerta no caso de uma toma descontinuada
                            pk_medication_core.print_medication_logs('delete_medication_alerts 10',
                                                                     pk_medication_core.c_log_debug);
                            pk_alertlog.log_debug('DELETED  - Parameters for Alert id :' || 10 || '.' ||
                                                  ' i_id_episode: ' || i_epis || ' i_id_record: ' || max_idpp);
                            IF NOT pk_medication_core.delete_medication_alerts(i_lang           => i_lang,
                                                                               i_prof           => i_prof,
                                                                               i_id_episode     => i_epis,
                                                                               i_id_record      => max_idpp,
                                                                               i_dpd_flg_status => end_status,
                                                                               i_dpp_flg_status => end_status,
                                                                               i_med_type       => CASE i_type
                                                                                                       WHEN g_soro THEN
                                                                                                        'F'
                                                                                                       ELSE
                                                                                                        g_drug
                                                                                                   END,
                                                                               o_error          => o_error)
                            THEN
                                ROLLBACK;
                                RETURN FALSE;
                            END IF;
                        
                        END IF; -- end_status = g_flg_i
                    
                    END IF;
                
                END IF;
            
                --Transferência de informação entre episódios da mesma visita
                g_error := ('information transfer error 1. --->' || end_status);
                pk_alertlog.log_debug(g_error);
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        i_epis,
                                        end_status,
                                        i_id_presc,
                                        pk_medication_core.g_ti_log_ml,
                                        o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                --Se esta suspenso, pode retomar
                /*
                (S -> Z)
                */
            ELSIF (begin_status = g_flg_s AND end_status = g_flg_continue)
            THEN
                --Primeira posologia
                OPEN c_first_change;
                FETCH c_first_change
                    INTO rec_first_change;
                IF c_first_change%NOTFOUND
                THEN
                    g_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-1001';
                    CLOSE c_first_change;
                    raise_application_error(-20001, g_error);
                    --RETURN FALSE;
                END IF;
                CLOSE c_first_change;
            
                --Guarda histórico
                IF NOT create_presc_hist(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_episode       => i_epis,
                                         i_type             => i_type,
                                         i_begin_status     => begin_status,
                                         i_end_status       => rec_first_change.flg_status_old,
                                         i_id_presc         => i_id_presc,
                                         i_cancel_reason    => i_cancel_reason,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_notes            => i_notes,
                                         o_error            => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            
                --Altera estado
                g_error  := 'UPDATE DRUG_PRESC_DET';
                l_rowids := table_varchar();
                ts_drug_presc_det.upd(id_drug_presc_det_in     => i_id_presc,
                                      flg_status_in            => rec_first_change.flg_status_old,
                                      frequency_in             => rec_first_change.frequency,
                                      frequency_nin            => FALSE,
                                      id_unit_measure_freq_in  => rec_first_change.id_unit_measure_freq,
                                      id_unit_measure_freq_nin => FALSE,
                                      duration_in              => rec_first_change.duration,
                                      duration_nin             => FALSE,
                                      id_unit_measure_dur_in   => rec_first_change.id_unit_measure_dur,
                                      id_unit_measure_dur_nin  => FALSE,
                                      qty_inst_in              => rec_first_change.qty,
                                      qty_inst_nin             => FALSE,
                                      unit_measure_inst_in     => rec_first_change.id_unit_measure_qty,
                                      unit_measure_inst_nin    => FALSE,
                                      dt_last_change_in        => g_sysdate_tstz,
                                      rows_out                 => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DRUG_PRESC_DET',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                --
            
                -- VERIFICAR OS IMPACTOS DESTA ALTERAÇÃO:
                -- PN
                IF rec_old_info.flg_take_type != 'S'
                THEN
                
                    SELECT MAX(id_drug_presc_plan)
                      INTO max_idpp
                      FROM drug_presc_plan
                     WHERE id_drug_presc_det = i_id_presc;
                
                    /* <DENORM Fábio> */
                    l_rowids := table_varchar();
                    ts_drug_presc_plan.upd(id_drug_presc_plan_in => max_idpp,
                                           flg_status_in         => CASE rec_first_change.flg_status_old
                                                                        WHEN 'E' THEN
                                                                         CASE rec_old_info.flg_take_type
                                                                             WHEN 'N' THEN
                                                                              'D'
                                                                             WHEN 'A' THEN
                                                                              'D'
                                                                             ELSE
                                                                              'A'
                                                                         END
                                                                        ELSE
                                                                         rec_first_change.flg_status_old
                                                                    END,
                                           rows_out              => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'DRUG_PRESC_PLAN',
                                                  l_rowids,
                                                  o_error,
                                                  table_varchar('FLG_STATUS'));
                END IF;
            
            END IF;
        
            --update grid_task
            OPEN c_episode;
            FETCH c_episode
                INTO l_id_episode;
            IF c_episode%NOTFOUND
            THEN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || 'ERR-1003';
                CLOSE c_episode;
                raise_application_error(-20001, g_error);
                --RETURN FALSE;
            END IF;
            CLOSE c_episode;
        
            --Em qq dos casos é necessário actualizar a grelha
            g_error := 'CALL TO pk_medication_core.UPDATE_DRUG_PRESC_TASK';
            IF NOT pk_medication_core.update_drug_presc_task(i_lang          => i_lang,
                                                             i_episode       => l_id_episode,
                                                             i_prof          => i_prof,
                                                             i_prof_cat_type => get_prof_cat(i_prof),
                                                             o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            --Transferência de informação entre episódios da mesma visita
            g_error := ('information transfer error 2. --->' || rec_first_change.qty);
            pk_alertlog.log_debug(g_error);
            IF NOT
                t_ti_log.ins_log(i_lang, i_prof, i_epis, end_status, i_id_presc, pk_medication_core.g_ti_log_ml, o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            --UPDATE Precrição para a farmácia do hospital
        ELSIF i_type = g_hospital
        THEN
        
            --Apenas podemos interromper
            IF end_status = g_flg_status_int
            THEN
            
                g_error := 'OPEN c_drug_req_det';
                OPEN c_drug_req_det;
                FETCH c_drug_req_det
                    INTO r_drug_req_det;
                g_found := c_drug_req_det%FOUND;
                CLOSE c_drug_req_det;
            
                IF g_found
                THEN
                
                    --Guarda histórico
                    IF NOT create_presc_hosp_hist(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_episode   => NULL,
                                                  i_type         => i_type,
                                                  i_begin_status => begin_status,
                                                  i_end_status   => end_status,
                                                  i_id_presc     => i_id_presc,
                                                  o_error        => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := ('information transfer error 3. --->' || end_status);
                    pk_alertlog.log_debug(g_error);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_epis,
                                            g_flg_status_int,
                                            i_id_presc,
                                            pk_medication_core.g_ti_log_mh,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF;
            END IF;
        
            --[OA] Onde estás o ELSE???? O que acontece se não entra no IF????
        
            --UPDATE DIETETICO
        ELSIF i_type = g_dietetico
        THEN
        
            --Apenas podemos interromper
            IF end_status = g_flg_status_int
            THEN
                g_error := 'OPEN c_presc_pharm';
                OPEN c_presc_pharm;
                FETCH c_presc_pharm
                    INTO r_presc_pharm;
                g_found := c_presc_pharm%FOUND;
                CLOSE c_presc_pharm;
            
                IF g_found
                THEN
                    g_error := 'INSERT INTO prescription_instr_hist V';
                
                    --Guarda histórico
                    IF NOT create_presc_pharm_hist(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_episode        => NULL,
                                                   i_type              => i_type,
                                                   i_begin_status      => begin_status,
                                                   i_end_status        => end_status,
                                                   i_id_presc          => i_id_presc,
                                                   i_flg_type_presc    => g_flg_p,
                                                   i_flg_subtype_presc => g_flg_dietary_ext,
                                                   o_error             => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'UPDATE PRESCRIPTION_PHARM';
                    ts_prescription_pharm.upd(id_prescription_pharm_in      => i_id_presc,
                                              flg_status_in                 => g_flg_status_int,
                                              dt_prescription_pharm_tstz_in => g_sysdate_tstz,
                                              id_prof_last_change_in        => i_prof.id,
                                              id_sw_last_change_in          => i_prof.software,
                                              id_inst_last_change_in        => i_prof.institution,
                                              order_modified_in             => NULL,
                                              order_modified_nin            => FALSE,
                                              dt_order_modified_in          => NULL,
                                              dt_order_modified_nin         => FALSE,
                                              rows_out                      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION_PHARM',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END IF;
            
                --Transferência de informação entre episódios da mesma visita
                g_error := ('information transfer error 4. --->' || end_status);
                pk_alertlog.log_debug(g_error);
                IF NOT t_ti_log.ins_log(i_lang,
                                        i_prof,
                                        i_epis,
                                        g_flg_status_int,
                                        i_id_presc,
                                        pk_medication_core.g_ti_log_me,
                                        o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
            END IF;
        
            --UPDATE MANIPULADO
        ELSIF i_type = g_manipulados
        THEN
        
            --Apenas podemos interromper
            IF end_status = g_flg_status_int
            THEN
                g_error := 'OPEN c_presc_pharm I';
                OPEN c_presc_pharm;
                FETCH c_presc_pharm
                    INTO r_presc_pharm;
                g_found := c_presc_pharm%FOUND;
                CLOSE c_presc_pharm;
            
                IF g_found
                THEN
                
                    g_error := 'INSERT INTO prescription_instr_hist VI';
                    --Guarda histórico
                    IF NOT create_presc_pharm_hist(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_episode        => NULL,
                                                   i_type              => i_type,
                                                   i_begin_status      => begin_status,
                                                   i_end_status        => end_status,
                                                   i_id_presc          => i_id_presc,
                                                   i_flg_type_presc    => g_flg_p,
                                                   i_flg_subtype_presc => g_flg_manip_ext,
                                                   o_error             => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'UPDATE PRESCRIPTION_PHARM II';
                    ts_prescription_pharm.upd(id_prescription_pharm_in      => i_id_presc,
                                              flg_status_in                 => g_flg_status_int,
                                              dt_prescription_pharm_tstz_in => g_sysdate_tstz,
                                              id_prof_last_change_in        => i_prof.id,
                                              id_sw_last_change_in          => i_prof.software,
                                              id_inst_last_change_in        => i_prof.institution,
                                              order_modified_in             => NULL,
                                              order_modified_nin            => FALSE,
                                              dt_order_modified_in          => NULL,
                                              dt_order_modified_nin         => FALSE,
                                              rows_out                      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION_PHARM',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := ('information transfer error 5. --->' || end_status);
                    pk_alertlog.log_debug(g_error);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_epis,
                                            g_flg_status_int,
                                            i_id_presc,
                                            pk_medication_core.g_ti_log_me,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF;
            END IF;
        
            --UPDATE prescrição para o exterior
        ELSIF i_type = g_exterior
        THEN
        
            --Apenas podemos interromper
            IF end_status = g_flg_status_int
            THEN
                g_error := 'OPEN c_presc_pharm III';
                OPEN c_presc_pharm;
                FETCH c_presc_pharm
                    INTO r_presc_pharm;
                g_found := c_presc_pharm%FOUND;
                CLOSE c_presc_pharm;
            
                IF g_found
                THEN
                
                    g_error := 'INSERT INTO prescription_instr_hist VII';
                    --Guarda histórico
                    IF NOT create_presc_pharm_hist(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_episode        => NULL,
                                                   i_type              => i_type,
                                                   i_begin_status      => begin_status,
                                                   i_end_status        => end_status,
                                                   i_id_presc          => i_id_presc,
                                                   i_flg_type_presc    => g_flg_ext,
                                                   i_flg_subtype_presc => NULL,
                                                   o_error             => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'UPDATE PRESCRIPTION_PHARM IV';
                    ts_prescription_pharm.upd(id_prescription_pharm_in      => i_id_presc,
                                              flg_status_in                 => g_flg_status_int,
                                              dt_prescription_pharm_tstz_in => g_sysdate_tstz,
                                              id_prof_last_change_in        => i_prof.id,
                                              id_sw_last_change_in          => i_prof.software,
                                              id_inst_last_change_in        => i_prof.institution,
                                              order_modified_in             => NULL,
                                              order_modified_nin            => FALSE,
                                              dt_order_modified_in          => NULL,
                                              dt_order_modified_nin         => FALSE,
                                              rows_out                      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PRESCRIPTION_PHARM',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := ('information transfer error 6. --->' || end_status);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_epis,
                                            g_flg_status_int,
                                            i_id_presc,
                                            pk_medication_core.g_ti_log_me,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF;
            END IF;
        
            --UPDATE relatos ou outros
        ELSIF i_type = g_outros
              OR i_type = g_relatos_int
              OR i_type = g_relatos_ext
        THEN
        
            OPEN c_pat_med;
            FETCH c_pat_med
                INTO r_pat_med;
            g_found := c_pat_med%FOUND;
            CLOSE c_pat_med;
        
            IF g_found
            THEN
            
                g_error := 'INSERT INTO prescription_instr_hist VIII';
            
                --Podemos Continuar ou Interromper
                IF end_status IN (g_pat_med_list_con, g_pat_med_list_int)
                THEN
                
                    g_error := 'UPDATE PAT_MEDICATION_LIST -> UPDATE PML.CONTINUE';
                    UPDATE pat_medication_list pml
                       SET pml.continue = end_status, dt_pat_medication_list_tstz = g_sysdate_tstz, id_episode = i_epis
                     WHERE pml.id_pat_medication_list = i_id_presc;
                    g_error := 'create_reported_drug_hist';
                
                    --Guarda histórico
                    IF NOT create_reported_drug_hist(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_id_episode       => NULL,
                                                     i_type             => i_type,
                                                     i_begin_status     => begin_status,
                                                     i_end_status       => end_status,
                                                     i_id_presc         => i_id_presc,
                                                     i_cancel_reason    => i_cancel_reason,
                                                     i_id_cancel_reason => i_id_cancel_reason,
                                                     i_notes            => i_notes,
                                                     o_error            => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    SELECT end_status
                      INTO l_flg_status
                      FROM dual;
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := ('information transfer error 7. --->' || end_status);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_epis,
                                            l_flg_status,
                                            i_id_presc,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                    --ou podemos tornar activo ou passivo
                ELSIF end_status IN (g_pat_med_list_act, g_pat_med_list_pas, 'X')
                THEN
                
                    g_error := 'UPDATE PAT_MEDICATION_LIST -> UPDATE PML.FLG_STATUS AND SET NULL TO PML.CONTINUE';
                    UPDATE pat_medication_list pml
                       SET pml.flg_status              = decode(end_status, 'X', 'C', end_status),
                           pml.continue                = NULL,
                           dt_pat_medication_list_tstz = g_sysdate_tstz,
                           id_episode                  = i_epis
                     WHERE pml.id_pat_medication_list = i_id_presc;
                
                    --Guarda histórico
                    IF NOT create_reported_drug_hist(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_id_episode       => NULL,
                                                     i_type             => i_type,
                                                     i_begin_status     => begin_status,
                                                     i_end_status       => end_status,
                                                     i_id_presc         => i_id_presc,
                                                     i_cancel_reason    => i_cancel_reason,
                                                     i_id_cancel_reason => i_id_cancel_reason,
                                                     i_notes            => i_notes,
                                                     o_error            => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                
                    --Transferência de informação entre episódios da mesma visita
                    g_error := ('information transfer error 8. --->' || end_status);
                    IF NOT t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            i_epis,
                                            end_status,
                                            i_id_presc,
                                            pk_medication_core.g_ti_log_mr,
                                            o_error)
                    THEN
                        raise_application_error(-20001, o_error.ora_sqlerrm);
                    END IF;
                
                END IF;
            
            END IF;
        
            --ALERT-169123 - Sets the review information. When creating report, the review status will go always to Partially reviewed
            IF NOT pk_medication_previous.set_review_detail(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_episode      => i_epis,
                                                            i_action       => pk_medication_previous.g_set_part_reviewed, --Set as Partially reviewed
                                                            i_review_notes => NULL,
                                                            i_dt_review    => NULL, --will be actual time
                                                            o_error        => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
        END IF;
    
        --ALERT-169123 - Sets the reconcile information. When creating/changing medication, the reconcile status will go always to Partially reconciled
        --The set_review_detail of the reported medication also changes the status of the reconciliation.
        --This is needed for all of the other cases. Since there is no insertion repetitions, this causes no problems.
        IF NOT pk_prescription.set_reconcile_detail(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => i_epis,
                                                    i_action          => pk_prescription.g_set_part_reconciled,
                                                    i_reconcile_notes => NULL,
                                                    i_dt_reconcile    => NULL,
                                                    o_error           => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        IF i_commit = 'Y'
        THEN
            COMMIT;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'UPDATE_STATUS_WITH_COMMIT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_status_with_commit;

    FUNCTION update_status_with_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        begin_status IN prescription.flg_status%TYPE,
        end_status   IN prescription.flg_status%TYPE,
        i_id_presc   IN NUMBER,
        i_commit     IN VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT update_status_with_commit(i_lang             => i_lang,
                                         i_epis             => i_epis,
                                         i_prof             => i_prof,
                                         i_type             => i_type,
                                         begin_status       => begin_status,
                                         end_status         => end_status,
                                         i_id_presc         => i_id_presc,
                                         i_commit           => i_commit,
                                         i_cancel_reason    => NULL,
                                         i_id_cancel_reason => NULL,
                                         i_notes            => NULL,
                                         o_error            => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'UPDATE_STATUS_WITH_COMMIT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
        
    END update_status_with_commit;

    
    /** @headcom
    * Public Function. Altera esta da prescrição prescrição :
    * Completed
    * Inactived
    * Discontinue
    * Note: Esta é a função chamada pelo Flash.
    *
    * @param    i_lang            língua registada como preferência do profissional.
    * @param    i_drug_presc_det  ID da prescrição
    * @param    i_prof            object (ID do profissional, ID da instituição, ID do software).
    * @param    i_notes           Notas
    * @param    o_error           erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     CJV
    * @version    0.1
    * @since      2007/10/23
    */
    FUNCTION change_local_presc_status
    (
        i_lang              IN language.id_language%TYPE,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_from_status       IN drug_prescription.id_drug_prescription%TYPE,
        i_to_status         IN drug_prescription.id_drug_prescription%TYPE,
        i_prof              IN profissional,
        i_notes             IN drug_presc_det.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids            table_varchar;
        l_rowids_upd        table_varchar;
        l_id_drug_presc_det drug_presc_det.id_drug_presc_det%TYPE;
    
    BEGIN
        g_prescription_version := pk_sysconfig.get_config(g_presc_type, i_prof);
        g_error                := 'pk_medication_current.CHANGE_LOCAL_PRESC_STATUS';
        IF i_from_status IN (g_inactive, g_discontinue)
        THEN
            -- *********************************
            -- PT 06/10/2008 2.4.3.d
            SELECT id_drug_presc_det
              INTO l_id_drug_presc_det
              FROM drug_presc_det dpd
             WHERE dpd.id_drug_prescription = i_drug_prescription
               FOR UPDATE;
        
            ts_drug_req.upd(flg_status_in => g_drug_req_cancel,
                            where_in      => 'id_drug_presc_det = ' || l_id_drug_presc_det,
                            rows_out      => l_rowids_upd);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DRUG_REQ',
                                          i_rowids     => l_rowids_upd,
                                          o_error      => o_error);
            -- *********************************
            /*UPDATE drug_req dr
              SET dr.flg_status = g_drug_req_cancel
            WHERE dr.id_drug_presc_det IN
                  (SELECT id_drug_presc_det
                     FROM drug_presc_det dpd
                    WHERE dpd.id_drug_prescription = i_drug_prescription);*/
        
            -- *********************************
            -- PT 02/10/2008 2.4.3.d
            ts_drug_prescription.upd(id_drug_prescription_in => i_drug_prescription,
                                     flg_type_in             => i_to_status,
                                     rows_out                => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DRUG_PRESCRIPTION',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            -- *********************************
        
            /*UPDATE drug_prescription dp
              SET dp.flg_type = i_to_status
            WHERE dp.id_drug_prescription = i_drug_prescription;*/
        
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CHANGE_LOCAL_PRESC_STATUS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END change_local_presc_status;

    FUNCTION set_presc_det_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_presc_pharm    IN table_number,
        i_emb_drug       IN table_number,
        i_via            IN table_varchar,
        i_qty            IN table_number,
        i_qty_unit       IN table_number,
        i_dosage         IN table_varchar,
        i_generico       IN table_varchar,
        i_first_dose     IN table_varchar,
        i_package_number IN table_varchar,
        dt_expire_tstz   IN table_varchar,
        i_diploma        IN table_number,
        i_notes          IN table_varchar,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_test           IN VARCHAR2,
        i_refill         IN table_number,
        i_chronic_med    IN table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_presc_det_ext(i_lang           => i_lang,
                                 i_episode        => i_episode,
                                 i_presc_pharm    => i_presc_pharm,
                                 i_emb_drug       => i_emb_drug,
                                 i_via            => i_via,
                                 i_qty            => i_qty,
                                 i_qty_unit       => i_qty_unit,
                                 i_dosage         => i_dosage,
                                 i_generico       => i_generico,
                                 i_first_dose     => i_first_dose,
                                 i_package_number => i_package_number,
                                 dt_expire_tstz   => dt_expire_tstz,
                                 i_diploma        => i_diploma,
                                 i_notes          => i_notes,
                                 i_prof           => i_prof,
                                 i_prof_cat_type  => i_prof_cat_type,
                                 i_test           => i_test,
                                 i_refill         => i_refill,
                                 i_chronic_med    => i_chronic_med,
                                 i_commit         => NULL,
                                 o_flg_show       => o_flg_show,
                                 o_msg            => o_msg,
                                 o_msg_title      => o_msg_title,
                                 o_button         => o_button,
                                 o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'SET_PRESC_DET_EXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_presc_det_ext;
    --

    FUNCTION set_presc_det_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_presc_pharm    IN table_number,
        i_emb_drug       IN table_number,
        i_via            IN table_varchar,
        i_qty            IN table_number,
        i_qty_unit       IN table_number,
        i_dosage         IN table_varchar,
        i_generico       IN table_varchar,
        i_first_dose     IN table_varchar,
        i_package_number IN table_varchar,
        dt_expire_tstz   IN table_varchar,
        i_diploma        IN table_number,
        i_notes          IN table_varchar,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_test           IN VARCHAR2,
        i_refill         IN table_number,
        i_chronic_med    IN table_varchar,
        i_commit         IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_qty    NUMBER;
        l_dosage VARCHAR2(1000);
    
        l_desc_unit VARCHAR2(4000);
    
        CURSOR c_diploma(l_diploma IN inf_diploma.diploma_id%TYPE) IS
            SELECT pp.id_prescription_pharm
              FROM inf_patol_dip_lnk ipdl, inf_patol_esp_lnk ipel, prescription_pharm pp, prescription p
             WHERE ipdl.diploma_id = l_diploma
               AND ipel.patol_dip_lnk_id = ipdl.patol_dip_lnk_id
               AND pp.emb_id = ipel.emb_id
               AND p.id_prescription = pp.id_prescription
               AND p.id_episode = i_episode
               AND p.flg_status = g_flg_temp
               AND p.flg_type = g_flg_ext;
    
        CURSOR c_diploma_null(l_presc_ph IN prescription_pharm.id_prescription_pharm%TYPE) IS
            SELECT id_prescription_pharm
              FROM prescription p, prescription_pharm pp
             WHERE p.id_episode = i_episode
               AND p.flg_status = g_flg_temp
               AND p.flg_type = g_flg_ext
               AND pp.id_prescription = p.id_prescription
               AND regulation_id IN (SELECT pp1.regulation_id
                                       FROM prescription_pharm pp1
                                      WHERE pp1.id_prescription_pharm = l_presc_ph);
    
        CURSOR c_qty
        (
            l_presc_ph IN prescription_pharm.id_prescription_pharm%TYPE,
            in_dosage  IN prescription_pharm.dosage%TYPE
        ) IS
            SELECT pp.qty,
                   nvl(in_dosage,
                       pk_medication_previous.get_dosage_format(i_lang,
                                                                pp.qty_inst,
                                                                pp.unit_measure_inst,
                                                                pp.frequency,
                                                                pp.id_unit_measure_freq,
                                                                pp.duration,
                                                                pp.id_unit_measure_dur,
                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_prof,
                                                                                              pp.dt_start_presc_tstz,
                                                                                              NULL),
                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_prof,
                                                                                              pp.dt_end_presc_tstz,
                                                                                              NULL),
                                                                i_prof)) l_dosage
              FROM prescription_pharm pp
             WHERE pp.id_prescription_pharm = l_presc_ph;
    
        -- denormalization variables
        l_rowids       table_varchar;
        l_generico_aux prescription_pharm.generico%TYPE;
    
        l_qty_max      NUMBER(24) := pk_sysconfig.get_config('PRESCRIPTION_MAX_NUMBER_PACKAGES', i_prof);
        l_qty_max_warn NUMBER(24) := pk_sysconfig.get_config('PRESCRIPTION_MAX_NUMBER_PACKAGES_WARNING', i_prof);
    
    BEGIN
        g_prescription_version := pk_sysconfig.get_config(g_presc_type, i_prof);
        g_error                := 'LOOP I_PRESC_PHARM.COUNT';
        FOR i IN 1 .. i_presc_pharm.count
        LOOP
        
            OPEN c_qty(i_presc_pharm(i), i_dosage(i));
            FETCH c_qty
                INTO l_qty, l_dosage;
            CLOSE c_qty;
        
            IF l_qty != i_qty(i)
            THEN
                IF i_qty(i) > l_qty_max
                   AND g_prescription_version NOT IN (pk_medication_core.g_usa, pk_medication_core.g_usa_ms)
                THEN
                    l_desc_unit := pk_unit_measure.get_uom_abbreviation(i_lang, i_prof, i_qty_unit(i));
                    --não é permitido prescrever mais de 99 embalagens
                    g_error := REPLACE(REPLACE(pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M048'),
                                               '@1',
                                               l_desc_unit),
                                       '@2',
                                       l_qty_max);
                    -- RETURN FALSE;
                    raise_application_error(-20002, g_error);
                END IF;
            
                IF i_test = 'Y'
                   AND i_qty(i) > l_qty_max_warn
                   AND g_prescription_version NOT IN (pk_medication_core.g_usa, pk_medication_core.g_usa_ms)
                THEN
                    --perguntar ao utilizador se tem a certeza de que quer prescrever mais de 4 embalagens
                    o_flg_show  := 'Y';
                    o_button    := 'NC';
                    o_msg       := REPLACE(pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M009'), '@1', i_qty(i));
                    l_desc_unit := pk_unit_measure.get_uom_abbreviation(i_lang, i_prof, i_qty_unit(i));
                    o_msg       := REPLACE(o_msg, '@2', l_desc_unit);
                    o_msg_title := REPLACE(pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M011'), '@1', l_desc_unit);
                    RETURN TRUE;
                END IF;
            END IF; --L_QTY
        
            IF i_diploma(i) IS NOT NULL
            THEN
                FOR r_diploma IN c_diploma(i_diploma(i))
                LOOP
                
                    g_error := 'UPDATE PRESCRIPTION_PHARM - DIPLOMA';
                    UPDATE prescription_pharm
                       SET regulation_id = i_diploma(i)
                     WHERE id_prescription_pharm = r_diploma.id_prescription_pharm;
                
                END LOOP; --R_DIPLOMA
            
            ELSE
                FOR r_diploma_null IN c_diploma_null(i_presc_pharm(i))
                LOOP
                
                    g_error := 'UPDATE PRESCRIPTION_PHARM - DIPLOMA = NULL';
                    UPDATE prescription_pharm
                       SET regulation_id = NULL
                     WHERE id_prescription_pharm = r_diploma_null.id_prescription_pharm;
                
                END LOOP; --C_DIPLOMA_NULL
            END IF; --I_DIPLOMA(I) IS NOT NULL
        
            g_error := 'UPDATE PRESCRIPTION_PHARM';
            SELECT p.generico
              INTO l_generico_aux
              FROM prescription_pharm p
             WHERE p.id_prescription_pharm = i_presc_pharm(i)
               FOR UPDATE;
        
            ts_prescription_pharm.upd(id_prescription_pharm_in   => i_presc_pharm(i),
                                      route_id_in                => i_via(i),
                                      route_id_nin               => FALSE,
                                      qty_in                     => i_qty(i),
                                      qty_nin                    => FALSE,
                                      id_unit_measure_in         => i_qty_unit(i),
                                      id_unit_measure_nin        => FALSE,
                                      generico_in                => nvl(i_generico(i), l_generico_aux),
                                      generico_nin               => FALSE,
                                      dt_expire_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  dt_expire_tstz(i),
                                                                                                  NULL),
                                      first_dose_in              => i_first_dose(i),
                                      first_dose_nin             => FALSE,
                                      package_number_in          => i_package_number(i),
                                      package_number_nin         => FALSE,
                                      dosage_in                  => l_dosage,
                                      dosage_nin                 => FALSE,
                                      regulation_id_in           => i_diploma(i),
                                      regulation_id_nin          => FALSE,
                                      notes_in                   => i_notes(i),
                                      notes_nin                  => FALSE,
                                      refill_in                  => i_refill(i),
                                      refill_nin                 => FALSE,
                                      flg_chronic_medication_in  => i_chronic_med(i),
                                      flg_chronic_medication_nin => FALSE,
                                      rows_out                   => l_rowids);
        
        END LOOP; --I_PRESC_PHARM.COUNT
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRESCRIPTION_PHARM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'SET_PRESC_DET_EXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Update the status of prescriptions.
    *
    * @ param i_lang
    * @ param i_prof                   professional identification
    * @ param i_epis                   episode id
    * @ param i_type                   prescrition type
    * @ param begin_status             prescription current status (before the update)
    * @ param end_status               prescription next status (after the update)
    * @ param i_id_presc               prescription id
    * @ param o_error                  Error message
    
    * @return                         true or false on success or error
    *
    * @author
    * @version                        0.1
    * @since
    **********************************************************************************************/
    FUNCTION update_status_all
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN table_varchar,
        begin_status IN table_varchar,
        end_status   IN table_varchar,
        i_id_presc   IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --itera pelos vários registos:
        FOR i IN 1 .. i_id_presc.count
        LOOP
        
            IF NOT update_status_with_commit(i_lang       => i_lang,
                                             i_epis       => i_epis,
                                             i_prof       => i_prof,
                                             i_type       => i_type(i),
                                             begin_status => begin_status(i),
                                             end_status   => end_status(i),
                                             i_id_presc   => i_id_presc(i),
                                             i_commit     => 'N',
                                             o_error      => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'UPDATE_STATUS_ALL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_status_all;

    FUNCTION update_status_all
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN table_varchar,
        begin_status       IN table_varchar,
        end_status         IN table_varchar,
        i_id_presc         IN table_number,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --itera pelos vários registos:
        FOR i IN 1 .. i_id_presc.count
        LOOP
        
            IF NOT update_status_with_commit(i_lang             => i_lang,
                                             i_epis             => i_epis,
                                             i_prof             => i_prof,
                                             i_type             => i_type(i),
                                             begin_status       => begin_status(i),
                                             end_status         => end_status(i),
                                             i_id_presc         => i_id_presc(i),
                                             i_commit           => 'N',
                                             i_cancel_reason    => i_cancel_reason,
                                             i_id_cancel_reason => i_id_cancel_reason,
                                             i_notes            => i_notes,
                                             o_error            => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'UPDATE_STATUS_ALL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_status_all;

    /********************************************************************************************
    * Update the status of prescriptions.
    *
    * @ param i_lang
    * @ param i_prof                   professional identification
    * @ param i_type                   prescrition type
    * @ param begin_status             prescription current status (before the update)
    * @ param end_status               prescription next status (after the update)
    * @ param i_id_presc               prescription id
    * @ param o_error                  Error message
    
    * @return                         true or false on success or error
    *
    * @author
    * @version                        0.1
    * @since
    **********************************************************************************************/
    FUNCTION update_status
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        begin_status IN prescription.flg_status%TYPE,
        end_status   IN prescription.flg_status%TYPE,
        i_id_presc   IN NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT update_status(i_lang             => i_lang,
                             i_epis             => i_epis,
                             i_prof             => i_prof,
                             i_type             => i_type,
                             begin_status       => begin_status,
                             end_status         => end_status,
                             i_id_presc         => i_id_presc,
                             i_cancel_reason    => NULL,
                             i_id_cancel_reason => NULL,
                             i_notes            => NULL,
                             o_error            => o_error)
        
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'update_status',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_status;

    /********************************************************************************************
      * Update the status of prescriptions.
      *
      * @ param i_lang
      * @ param i_prof                   professional identification
      * @ param i_type                   prescrition type
      * @ param begin_status             prescription current status (before the update)
      * @ param end_status               prescription next status (after the update)
      * @ param i_id_presc               prescription id
    * @ param i_id_cancel_reason     id cancel reason
      * @ param o_error                  Error message
    
      * @return                         true or false on success or error
      *
      * @author
      * @version                        0.1
      * @since
      **********************************************************************************************/
    FUNCTION update_status
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        begin_status       IN prescription.flg_status%TYPE,
        end_status         IN prescription.flg_status%TYPE,
        i_id_presc         IN NUMBER,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT update_status_with_commit(i_lang             => i_lang,
                                         i_epis             => i_epis,
                                         i_prof             => i_prof,
                                         i_type             => i_type,
                                         begin_status       => begin_status,
                                         end_status         => end_status,
                                         i_id_presc         => i_id_presc,
                                         i_commit           => 'Y',
                                         i_cancel_reason    => i_cancel_reason,
                                         i_id_cancel_reason => i_id_cancel_reason,
                                         i_notes            => i_notes,
                                         o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'update_status',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_status;

    /*Cancel function that calls the cancel function with commit='Y'*/
    FUNCTION cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type         IN VARCHAR2,
        i_id_presc     IN NUMBER,
        i_notes_cancel IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT cancel(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_type         => i_type,
                      i_id_presc     => i_id_presc,
                      i_notes_cancel => i_notes_cancel,
                      i_commit       => g_yes,
                      o_error        => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CURRENT',
                                              i_function => 'CANCEL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);
    -- Log startup
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_presc_type_desc_int := 'I';
    g_presc_fin           := 'F';

    g_presc_req  := 'R';
    g_presc_pend := 'D';
    g_presc_fin  := 'F';
    g_presc_can  := 'C';
    g_presc_par  := 'P';
    g_presc_intr := 'P';
    g_presc_exe  := 'E';

    g_presc_det_req  := 'R';
    g_presc_det_pend := 'D';
    g_presc_det_exe  := 'E';
    g_presc_det_fin  := 'F';
    g_presc_det_can  := 'C';
    g_presc_det_intr := 'I';
    g_presc_det_sus  := 'S';

    g_flg_time_epis := 'E';
    g_flg_time_next := 'N';
    g_flg_time_betw := 'B';

    g_presc_take_sos  := 'S';
    g_presc_take_nor  := 'N';
    g_presc_take_uni  := 'U';
    g_presc_take_cont := 'C';
    g_presc_take_eter := 'A';

    g_presc_plan_stat_adm  := 'A';
    g_presc_plan_stat_nadm := 'N';
    g_presc_plan_stat_pend := 'D';
    g_presc_plan_stat_req  := 'R';
    g_presc_plan_stat_can  := 'C';

    g_domain_take := 'DRUG_PRESC_DET.FLG_TAKE_TYPE';
    g_domain_time := 'DRUG_PRESCRIPTION.FLG_TIME';

    g_drug_justif := 'Y';
    g_drug_interv := 'M';
    g_flg_doctor  := 'D';
    g_flg_phys    := 'F';
    g_flg_tec     := 'T';

    g_drug_det_status := 'DRUG_PRESC_DET.FLG_STATUS';

    -- NOVAS VARIÁVEIS GLOBAIS PARA A FERRAMENTA DE PRESCRIÇÃO

    g_flg_freq := 'M';
    g_flg_pesq := 'P';
    g_no       := 'N';
    g_yes      := 'Y';

    g_flg_ext      := 'E';
    g_descr_ext    := 'OFICINA';
    g_flg_int      := 'I';
    g_descr_int    := 'HOSPITAL';
    g_flg_other    := 'P';
    g_flg_reported := 'R';
    g_flg_adm      := 'A';

    g_flg_manip_ext   := 'ME';
    g_flg_manip_int   := 'MI';
    g_flg_dietary_ext := 'DE';
    g_flg_dietary_int := 'DI';

    g_pharma_class_avail := 'Y';
    g_drug_available     := 'Y';

    g_descr_otc := 'OTC';

    g_flg_temp  := 'T';
    g_flg_print := 'P';

    g_flg_first  := 'P';
    g_flg_second := 'S';

    g_domain_print_type   := 'PRESC_PRINT.FLG_TYPE';
    g_domain_reprint_type := 'PRESC_REPRINT.FLG_TYPE';
    g_inst_type_cs        := 'C';
    g_inst_type_hs        := 'H';

    g_pharma_avail := 'Y';

    g_flg_req     := 'R';
    g_flg_pend    := 'D';
    g_flg_rejeita := 'J';

    g_att_yes  := 'Y';
    g_att_no   := 'N';
    g_att_read := 'R';

    g_price_pvp := 0;
    g_price_pr  := 1;
    g_price_prp := 2;

    g_flg_cancel   := 'C';
    g_flg_active   := 'A';
    g_flg_inactive := 'I';

    g_flg_ci              := 'CI';
    g_flg_cheaper         := 'B';
    g_flg_justif          := 'J';
    g_flg_interac_med     := 'IM';
    g_flg_interac_allergy := 'IA';

    g_flg_generico := 'G';

    g_problem_ci    := 'C';
    g_problem_assoc := 'A';
    g_drug_req      := 'R';

    --VALORES DA BD INFARMED
    g_mnsrm     := 1;
    g_msrm_e    := 4;
    g_msrm_ra   := 10;
    g_msrm_rb   := 11; --já não é utilizado
    g_msrm_rc   := -1; --12 já não é utilizado
    g_msrm_r_ea := 13;
    g_msrm_r_ec := 15;
    g_emb_hosp  := 20;
    g_disp_in_v := 100;

    g_prod_diabetes := 13;
    g_grupo_0       := 'GH0000';

    g_drug := 'M';

    g_selected := 'S';

    --Fluids
    g_stat_pend         := 'D';
    g_stat_req          := 'R';
    g_stat_intr         := 'I';
    g_stat_canc         := 'C';
    g_presc_det_bolus   := 'B';
    g_stat_fin          := 'F';
    g_flg_new_fluid     := 'N';
    g_stat_exec         := 'E';
    g_flg_take_type_sos := 'S';
    g_flg_co_sign       := 'N';
    g_stat_adm          := 'A';

    -- drug_req
    g_drug_req_req           := 'R';
    g_drug_req_pend          := 'D';
    g_drug_req_exe           := 'E';
    g_drug_req_rejeita       := 'J';
    g_drug_req_parc          := 'P';
    g_local_prescription     := 'A';
    g_hosp_farm_prescription := 'I';
    g_hosp_farm_ext          := 'E';
    g_reported_med           := 'R';
    g_green_color            := '0x829664';
    g_red_color              := '0xC86464';
    g_pat_med_list_domain    := 'PAT_MEDICATION_LIST.FLG_STATUS';
    g_flg_relat_ext          := 'RE';
    g_flg_relat_int          := 'RI';
    g_flg_relat_outros       := 'RO';
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    g_log_object_name             := 'PK_GUIDELINES';
    g_active                      := 'A';
    g_inactive                    := 'I';
    g_discontinue                 := 'X';
    g_drug_req_cancel             := 'C';
    g_local                       := 'LOCAL';
    g_hospital                    := 'HOSPITAL';
    g_dietetico                   := 'DIETETICOS';
    g_manipulados                 := 'MANIPULADO';
    g_exterior                    := 'EXTERIOR';
    g_relatos_ext                 := 'RELATOS_EXT';
    g_outros                      := 'OUTROS';
    g_outros_prod                 := 'OUTROS_PROD';
    g_relatos_int                 := 'RELATOS_INT';
    g_soro                        := 'SORO';
    g_compound                    := 'COMPOUND';
    g_flg_d                       := 'D';
    g_flg_a                       := 'A';
    g_flg_p                       := 'P'; -- PAT_MEDICATION_LIST, FLG_STATUS = 'P' - Não
    g_flg_r                       := 'R';
    g_flg_s                       := 'S';
    g_flg_z                       := 'Z';
    g_flg_i                       := 'I';
    g_flg_c                       := 'C';
    g_flg_f                       := 'F';
    g_flg_e                       := 'E';
    pk_medication_current.g_flg_b := 'B';
    g_flg_m                       := 'M';
    g_flg_o                       := 'O';
    g_flg_continue                := 'Z';
    g_flg_type_presc              := 'I';
    g_presc_type                  := 'PRESCRIPTION_TYPE';

    g_det_temp           := 'T';
    g_det_req            := 'R';
    g_det_pend           := 'D';
    g_det_exe            := 'E';
    g_det_fin            := 'F';
    g_det_can            := 'C';
    g_det_sus            := 'S';
    g_det_intr           := 'I';
    g_det_reject         := 'J';
    g_drug_pend          := 'D';
    g_drug_req           := 'R';
    g_drug_canc          := 'C';
    g_drug_exec          := 'E';
    g_drug_res           := 'F';
    g_drug_part          := 'P';
    g_drug_rejeita       := 'J';
    g_presc_det_req_hosp := 'H';
    g_directions_str     := 'Directions for use:';

    g_flg_qty_for_24_hours := 'D';
    g_flg_total_qty        := 'T';

    g_viewer_hp               := 'HP';
    g_viewer_ts               := 'TS';
    g_viewer_ex               := 'EX';
    g_viewer_ps               := 'PS';
    g_viewer_patient_notified := 'PATIENT_NOTIFIED';
    g_date_format_str         := 'YYYYMMDDHH24MISS';
    g_debug_on                := pk_sysconfig.get_config('G_DEBUG_TURN_ON', profissional(0, 0, 0));
    g_presc_det_par           := 'P';
    g_presc_type_int          := 'I';

    g_doc_type_sns := 1033;

    g_exterior_chronic       := 'EXTERIOR_CHRONIC';
    g_flg_chronic_medication := 'CM';

END pk_medication_current;
/
