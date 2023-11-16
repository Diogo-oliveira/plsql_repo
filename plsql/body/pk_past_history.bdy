/*-- Last Change Revision: $Rev: 2012697 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-04-14 14:51:46 +0100 (qui, 14 abr 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_past_history IS

    /****************************************************************************************************************************************************************************************
    * PRIVATE UTILITY FUNCTIONS USED IN PK
    *****************************************************************************************************************************************************************************************/
    /**
    * NEXTVAL in pat_past_hist_ft_hist sequence
    * @param   i_doc_area               Doc area ID
    *
    * @return  VARCHAR2                 returns converted flag 
    *
    * @author  rui.duarte
    * @version 2.6.0.4
    * @since   2011-JAN-17
    */
    FUNCTION prv_get_free_text_nextval RETURN pat_past_hist_free_text.id_pat_ph_ft%TYPE IS
        l_free_text_seq_nextval pat_past_hist_free_text.id_pat_ph_ft%TYPE;
    BEGIN
        SELECT seq_pat_past_hist_free_text.nextval
          INTO l_free_text_seq_nextval
          FROM dual;
    
        RETURN l_free_text_seq_nextval;
    END prv_get_free_text_nextval;
    --

    /**
    * NEXTVAL in pat_past_hist_ft_hist sequence
    *
    * @param   i_doc_area               Doc area ID
    *
    * @return  VARCHAR2                 returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.0.4
    * @since   2011-JAN-17
    */
    FUNCTION prv_get_free_text_hist_nextval RETURN pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE IS
        l_free_text_hist_seq_nextval pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
    BEGIN
        SELECT seq_pat_past_hist_ft_hist.nextval
          INTO l_free_text_hist_seq_nextval
          FROM dual;
    
        RETURN l_free_text_hist_seq_nextval;
    END prv_get_free_text_hist_nextval;
    --

    /**
    * Converts doc area_id to flg_type in past history types
    *
    * @param   i_doc_area               Doc area ID
    *
    * @return  VARCHAR2                 returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.0.4
    * @since   2010-DEC-13
    */
    FUNCTION prv_conv_doc_area_to_flg_type
    (
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_past_hist_ft IN VARCHAR2 DEFAULT NULL
    ) RETURN pat_history_diagnosis.flg_type%TYPE IS
        l_past_hist_type pat_history_diagnosis.flg_type%TYPE;
    BEGIN
        CASE i_doc_area
            WHEN g_doc_area_past_med THEN
                l_past_hist_type := g_alert_diag_type_med;
            WHEN g_doc_area_past_surg THEN
                l_past_hist_type := g_alert_diag_type_surg;
            WHEN g_doc_area_cong_anom THEN
                l_past_hist_type := g_alert_diag_type_cong_anom;
            WHEN g_doc_area_past_fam THEN
                IF i_past_hist_ft IS NULL
                THEN
                    l_past_hist_type := g_alert_diag_type_family;
                ELSE
                    l_past_hist_type := g_alert_diag_type_others;
                END IF;
            WHEN g_doc_area_gyn_hist THEN
                l_past_hist_type := g_alert_diag_type_gyneco;
            WHEN g_doc_area_treatments THEN
                l_past_hist_type := g_alert_type_treatments;
            ELSE
                l_past_hist_type := g_alert_diag_type_others;
        END CASE;
    
        RETURN l_past_hist_type;
    END prv_conv_doc_area_to_flg_type;
    --
    /**
    * Converts flg_type to doc_area_id in past history types
    *
    * @param   i_flg_type               Type of past history area
    *
    * @return  VARCHAR2                 returns associated doc area id
    *
    * @author  José Silva
    * @version 2.6.2
    * @since   06-Oct-2011
    */
    FUNCTION prv_conv_flg_type_to_doc_area(i_flg_type IN pat_history_diagnosis.flg_type%TYPE)
        RETURN doc_area.id_doc_area%TYPE IS
        l_doc_area doc_area.id_doc_area%TYPE;
    BEGIN
    
        CASE i_flg_type
            WHEN g_alert_diag_type_med THEN
                l_doc_area := g_doc_area_past_med;
            WHEN g_alert_diag_type_surg THEN
                l_doc_area := g_doc_area_past_surg;
            WHEN g_alert_diag_type_cong_anom THEN
                l_doc_area := g_doc_area_cong_anom;
            WHEN g_alert_diag_type_family THEN
                l_doc_area := g_doc_area_past_fam;
            WHEN g_alert_type_treatments THEN
                l_doc_area := g_doc_area_treatments;
            WHEN g_alert_diag_type_gyneco THEN
                l_doc_area := g_doc_area_gyn_hist;
            ELSE
                l_doc_area := NULL;
        END CASE;
    
        RETURN l_doc_area;
    END prv_conv_flg_type_to_doc_area;
    --
    /**
    * Converts doc_area_id to id_task_type in past history areas
    *
    * @param   i_doc_area               doc_area of past history
    *
    * @return  VARCHAR2                 returns associated id_task_type
    *
    * @author  Sergio Dias
    * @version 2.6.3.2.1
    * @since   25-Feb-2013
    */
    FUNCTION prv_conv_doc_area_to_task_type(i_doc_area IN doc_area.id_doc_area%TYPE) RETURN NUMBER IS
        l_past_hist_type task_type.id_task_type%TYPE;
    BEGIN
        CASE i_doc_area
            WHEN g_doc_area_past_med THEN
                l_past_hist_type := pk_alert_constant.g_task_medical_history;
            WHEN g_doc_area_past_surg THEN
                l_past_hist_type := pk_alert_constant.g_task_surgical_history;
            WHEN g_doc_area_cong_anom THEN
                l_past_hist_type := pk_alert_constant.g_task_congenital_anomalies;
            WHEN g_doc_area_gyn_hist THEN
                l_past_hist_type := pk_alert_constant.g_task_gynecology_history;
            WHEN g_doc_area_past_fam THEN
                l_past_hist_type := pk_alert_constant.g_task_family_history;
            ELSE
                l_past_hist_type := pk_alert_constant.g_task_diagnosis;
        END CASE;
    
        RETURN l_past_hist_type;
    END prv_conv_doc_area_to_task_type;
    --
    /********************************************************************************************
    * Gets episode visit id
    *
    * @param   i_episode         episode ID
    *
    * @return  VARCHAR2          returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.0.5
    * @since   2011-JAN-25
    ********************************************************************************************/
    FUNCTION prv_get_epis_visit_id(i_episode IN episode.id_episode%TYPE) RETURN episode.id_visit%TYPE IS
        l_visit visit.id_visit%TYPE;
    BEGIN
    
        BEGIN
            SELECT e.id_visit
              INTO l_visit
              FROM episode e
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_visit := NULL;
        END;
    
        RETURN l_visit;
    END prv_get_epis_visit_id;
    --

    /********************************************************************************************
    * This function returns the episodes that belongs to a visit
    *
    * @param    IN  i_lang               Language ID
    * @param    IN  i_prof               Professional structure
    * @param    IN  i_episode            Episode ID
    *
    * @return   BOOLEAN
    *
    * @version  2.5.1.2
    * @since    26-Nov-2010
    * @alter    Filipe Machado
    **********************************************************************************************/

    FUNCTION prv_get_visit_episodes(i_episode IN episode.id_episode%TYPE) RETURN table_number IS
        l_epis_visit table_number := table_number();
        l_visit      visit.id_visit%TYPE;
    BEGIN
        l_visit := prv_get_epis_visit_id(i_episode);
    
        SELECT a.id_episode
          BULK COLLECT
          INTO l_epis_visit
          FROM episode a
         WHERE a.id_visit = l_visit
         ORDER BY a.dt_creation DESC;
    
        RETURN l_epis_visit;
    
    END prv_get_visit_episodes;
    --

    /**
    * Returns dates and id's os past history values diagnosis type
    *
    * @param   i_doc_area               Doc area ID
    *
    * @return  BOOLEAN                 returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.0.4
    * @since   2010-DEC-21
    */
    FUNCTION prv_get_past_hist_diagnosis
    (
        i_flg_type       IN pat_history_diagnosis.flg_type%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_visit          IN visit.id_visit%TYPE,
        i_scope_type     IN VARCHAR2,
        i_episodes_visit IN table_number,
        i_id_task_type   IN task_type.id_task_type%TYPE,
        i_flg_diag_call  IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_past_hist_id   OUT table_number,
        o_past_hist_dt   OUT table_timestamp_tstz
    ) RETURN BOOLEAN IS
        l_past_hist_type pat_history_diagnosis.flg_type%TYPE;
        --
        l_const_null CONSTANT VARCHAR2(4) := 'NULL';
        --
        l_id_alert_diag pat_history_diagnosis.id_alert_diagnosis%TYPE := NULL;
        l_desc_phd      pat_history_diagnosis.desc_pat_history_diagnosis%TYPE := NULL;
    BEGIN
        --Get flag type
        IF i_flg_type IS NOT NULL
        THEN
            l_past_hist_type := i_flg_type;
        ELSE
            --If no type is provided return FALSE
            l_past_hist_type := NULL;
            RETURN FALSE;
        END IF;
    
        --Set the parameter id_task_type to be used on the view alert_diagnosis_type
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, i_id_task_type);
    
        IF i_flg_diag_call = pk_alert_constant.get_yes
        THEN
            --Fetch into table number and date values
            FOR rec_phd IN (SELECT phd.id_pat_history_diagnosis,
                                   phd.dt_pat_history_diagnosis_tstz,
                                   phd.id_alert_diagnosis,
                                   phd.desc_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                              LEFT JOIN episode e
                                ON e.id_episode = phd.id_episode
                              LEFT JOIN alert_diagnosis_type adt
                                ON phd.id_alert_diagnosis = adt.id_alert_diagnosis
                              LEFT JOIN diagnosis d
                                ON adt.id_diagnosis = d.id_diagnosis
                             WHERE phd.id_patient = i_patient
                               AND (e.id_visit = i_visit OR i_visit IS NULL OR
                                   (EXISTS (SELECT 1
                                               FROM review_detail rd
                                              WHERE rd.id_episode IN (SELECT *
                                                                        FROM TABLE(i_episodes_visit))
                                                AND rd.id_record_area = phd.id_pat_history_diagnosis)) AND
                                   i_scope_type = pk_alert_constant.g_scope_type_visit)
                               AND (e.id_episode = i_episode OR i_episode IS NULL OR
                                   (EXISTS (SELECT 1
                                               FROM review_detail rd
                                              WHERE rd.id_episode = i_episode
                                                AND rd.id_record_area = phd.id_pat_history_diagnosis)))
                               AND (adt.flg_type = decode(l_past_hist_type,
                                                          g_alert_diag_type_family,
                                                          g_alert_diag_type_med,
                                                          l_past_hist_type) OR
                                   phd.id_alert_diagnosis IN (g_diag_unknown, g_diag_none, g_diag_non_remark))
                               AND phd.flg_type = l_past_hist_type
                            --    AND adt.id_task_type = i_id_task_type
                            --When filling the output vars I'm counting that records come in this order, 
                            --if you need to change it you must also change the code inside loop
                             ORDER BY phd.id_alert_diagnosis,
                                      phd.desc_pat_history_diagnosis,
                                      phd.dt_pat_history_diagnosis_tstz DESC)
            LOOP
                --o_past_hist_id, o_past_hist_dt
                IF l_id_alert_diag IS NULL
                THEN
                    l_id_alert_diag := rec_phd.id_alert_diagnosis;
                    l_desc_phd      := rec_phd.desc_pat_history_diagnosis;
                
                    o_past_hist_id := table_number(rec_phd.id_pat_history_diagnosis);
                    o_past_hist_dt := table_timestamp_tstz(rec_phd.dt_pat_history_diagnosis_tstz);
                ELSIF (l_id_alert_diag != rec_phd.id_alert_diagnosis OR
                      (l_id_alert_diag = rec_phd.id_alert_diagnosis AND
                      nvl(l_desc_phd, l_const_null) != nvl(rec_phd.desc_pat_history_diagnosis, l_const_null)))
                THEN
                    l_id_alert_diag := rec_phd.id_alert_diagnosis;
                    l_desc_phd      := rec_phd.desc_pat_history_diagnosis;
                
                    o_past_hist_id.extend;
                    o_past_hist_id(o_past_hist_id.count) := rec_phd.id_pat_history_diagnosis;
                    o_past_hist_dt.extend;
                    o_past_hist_dt(o_past_hist_dt.count) := rec_phd.dt_pat_history_diagnosis_tstz;
                END IF;
            END LOOP;
        ELSE
            --Fetch into table number and date values
            SELECT id_out, dt_tstz_out
              BULK COLLECT
              INTO o_past_hist_id, o_past_hist_dt
              FROM (SELECT phd.id_pat_history_diagnosis id_out, phd.dt_pat_history_diagnosis_tstz dt_tstz_out
                      FROM pat_history_diagnosis phd
                      LEFT JOIN episode e
                        ON e.id_episode = phd.id_episode
                      LEFT JOIN alert_diagnosis_type adt
                        ON phd.id_alert_diagnosis = adt.id_alert_diagnosis
                      LEFT JOIN diagnosis d
                        ON adt.id_diagnosis = d.id_diagnosis
                     WHERE phd.id_patient = i_patient
                       AND (e.id_visit = i_visit OR i_visit IS NULL OR
                           (EXISTS (SELECT 1
                                       FROM review_detail rd
                                      WHERE rd.id_episode IN (SELECT *
                                                                FROM TABLE(i_episodes_visit))
                                        AND rd.id_record_area = phd.id_pat_history_diagnosis)) AND
                           i_scope_type = pk_alert_constant.g_scope_type_visit)
                       AND (e.id_episode = i_episode OR i_episode IS NULL OR
                           (EXISTS (SELECT 1
                                       FROM review_detail rd
                                      WHERE rd.id_episode = i_episode
                                        AND rd.id_record_area = phd.id_pat_history_diagnosis)))
                       AND phd.flg_type = l_past_hist_type
                    --                       AND (adt.id_task_type = i_id_task_type OR                            phd.id_alert_diagnosis IN (g_diag_unknown, g_diag_none, g_diag_non_remark))
                    );
        END IF;
        RETURN TRUE;
    
    END prv_get_past_hist_diagnosis;

    /**
    * Returns dates and id's os past history values diagnosis type
    *
    * @param   i_doc_area               Doc area ID
    *
    * @return  BOOLEAN                 returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.0.4
    * @since   2010-DEC-21
    */
    FUNCTION prv_get_past_hist_det_ids
    (
        i_id_past_history          IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_ft                   IN VARCHAR2,
        o_id_ph_free_text          OUT pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        o_id_ph_ft_hist            OUT pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE,
        o_max_dt_pat_his_diag_tstz OUT pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_min_dt_pat_his_diag_tstz OUT pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN BOOLEAN IS
        l_return        BOOLEAN;
        l_id_patient    pat_history_diagnosis.id_patient%TYPE;
        l_record_status pat_history_diagnosis.flg_status%TYPE;
    BEGIN
    
        IF i_flg_ft = pk_alert_constant.get_no
        THEN
        
            --Get max date for diagnosis type
            BEGIN
                SELECT dt_pat_history_diagnosis_tstz, phd.id_patient, phd.flg_status
                  INTO o_max_dt_pat_his_diag_tstz, l_id_patient, l_record_status
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_pat_history_diagnosis = i_id_past_history;
            EXCEPTION
                WHEN no_data_found THEN
                    o_max_dt_pat_his_diag_tstz := NULL;
            END;
        
            --Get free text type
            BEGIN
                SELECT pphfth.id_pat_ph_ft_hist, pphfth.id_pat_ph_ft
                  INTO o_id_ph_ft_hist, o_id_ph_free_text
                  FROM pat_past_hist_ft_hist pphfth
                 WHERE pphfth.dt_register = o_max_dt_pat_his_diag_tstz
                   AND pphfth.id_patient = l_id_patient
                   AND pphfth.flg_status = decode(l_record_status,
                                                  pk_alert_constant.g_cancelled,
                                                  pk_alert_constant.g_cancelled,
                                                  pphfth.flg_status);
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_ph_ft_hist   := NULL;
                    o_id_ph_free_text := NULL;
            END;
        
            l_return := TRUE;
        ELSE
        
            --Get free text type
            o_id_ph_ft_hist := i_id_past_history;
        
            BEGIN
                SELECT pphfth.dt_register, pphfth.id_pat_ph_ft
                  INTO o_max_dt_pat_his_diag_tstz, o_id_ph_free_text
                  FROM pat_past_hist_ft_hist pphfth
                 WHERE pphfth.id_pat_ph_ft_hist = o_id_ph_ft_hist;
                l_return := TRUE;
            EXCEPTION
                WHEN no_data_found THEN
                    l_return                   := FALSE;
                    o_max_dt_pat_his_diag_tstz := NULL;
            END;
        
            --Get min data for free text(created label)
            BEGIN
                SELECT MIN(pphfth.dt_register)
                  INTO o_min_dt_pat_his_diag_tstz
                  FROM pat_past_hist_ft_hist pphfth
                 WHERE pphfth.id_pat_ph_ft_hist = o_id_ph_ft_hist;
                l_return := TRUE;
            EXCEPTION
                WHEN no_data_found THEN
                    o_min_dt_pat_his_diag_tstz := NULL;
                    l_return                   := FALSE;
            END;
        
        END IF;
    
        RETURN l_return;
    
    END prv_get_past_hist_det_ids;

    /********************************************************************************************
    * Cancels records for past history
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_phd                    Pat History Diagnosis/Pat notes ID
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2010/01/20
    **********************************************************************************************/
    FUNCTION prv_cancel_past_hist_diagnosis
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_pat                      IN patient.id_patient%TYPE,
        i_id_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_id_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes             IN pat_problem_hist.cancel_notes%TYPE,
        i_date                     IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    
        CURSOR c_current_records IS
            SELECT *
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_id_pat_history_diagnosis
             ORDER BY phd.id_pat_history_diagnosis;
    
        r_current_record c_current_records%ROWTYPE;
        l_seq_phd        pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    BEGIN
        FOR r_current_record IN c_current_records
        LOOP
            g_error := 'INSERT NEW CANCELLED RECORD';
            pk_alertlog.log_debug(text => g_error);
        
            l_seq_phd := ts_pat_history_diagnosis.next_key();
            ts_pat_history_diagnosis.ins(id_pat_history_diagnosis_in   => l_seq_phd,
                                         id_professional_in            => r_current_record.id_professional,
                                         flg_status_in                 => g_pat_hist_diag_canceled,
                                         flg_nature_in                 => r_current_record.flg_nature,
                                         id_diagnosis_in               => r_current_record.id_diagnosis,
                                         id_epis_complaint_in          => r_current_record.id_epis_complaint,
                                         flg_compl_in                  => r_current_record.flg_compl,
                                         id_alert_diagnosis_in         => r_current_record.id_alert_diagnosis,
                                         flg_recent_diag_in            => pk_alert_constant.get_yes,
                                         flg_type_in                   => r_current_record.flg_type,
                                         id_patient_in                 => r_current_record.id_patient,
                                         id_episode_in                 => r_current_record.id_episode,
                                         id_institution_in             => r_current_record.id_institution,
                                         dt_pat_history_diag_tstz_in   => nvl(i_date, current_timestamp),
                                         notes_in                      => r_current_record.notes,
                                         id_pat_problem_mig_in         => r_current_record.id_pat_problem_hist_mig,
                                         flg_aproved_mig_in            => r_current_record.flg_aproved_mig,
                                         desc_pat_history_diagnosis_in => r_current_record.desc_pat_history_diagnosis,
                                         id_pat_problem_hist_mig_in    => r_current_record.id_pat_problem_hist_mig,
                                         id_cancel_reason_in           => i_id_cancel_reason,
                                         cancel_notes_in               => i_cancel_notes,
                                         flg_warning_in                => r_current_record.flg_warning,
                                         id_cdr_call_in                => r_current_record.id_cdr_call,
                                         id_prof_cancel_in             => i_prof.id,
                                         dt_cancel_in                  => nvl(i_date, current_timestamp),
                                         dt_execution_precision_in     => r_current_record.dt_execution_precision,
                                         dt_diagnosis_in               => r_current_record.dt_diagnosis,
                                         id_intervention_in            => r_current_record.id_intervention,
                                         id_exam_in                    => r_current_record.id_exam,
                                         dt_execution_in               => r_current_record.dt_execution,
                                         id_adiag_inst_owner_in        => r_current_record.id_adiag_inst_owner,
                                         id_diag_inst_owner_in         => r_current_record.id_diag_inst_owner,
                                         flg_area_in                   => r_current_record.flg_area,
                                         flg_cda_reconciliation_in     => r_current_record.flg_cda_reconciliation,
                                         dt_diagnosed_in               => r_current_record.dt_diagnosed,
                                         dt_diagnosed_precision_in     => r_current_record.dt_diagnosed_precision,
                                         dt_resolved_in                => r_current_record.dt_resolved,
                                         dt_resolved_precision_in      => r_current_record.dt_resolved_precision,
                                         rows_out                      => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'CANCEL OUTDATED RECORD';
            pk_alertlog.log_debug(text => g_error);
        
            ts_pat_history_diagnosis.upd(id_pat_history_diag_new_in  => l_seq_phd,
                                         id_pat_history_diag_new_nin => FALSE,
                                         flg_recent_diag_in          => pk_alert_constant.get_no,
                                         flg_recent_diag_nin         => FALSE,
                                         where_in                    => 'id_pat_history_diagnosis = ' ||
                                                                        i_id_pat_history_diagnosis,
                                         rows_out                    => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'PAT_HISTORY_DIAGNOSIS',
                                          i_list_columns => table_varchar('ID_PAT_HISTORY_DIAG_NEW_IN',
                                                                          'FLG_RECENT_DIAG'),
                                          i_rowids       => l_rowids,
                                          o_error        => o_error);
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRV_CANCEL_PAST_HIST_DIAGNOSIS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END prv_cancel_past_hist_diagnosis;
    --

    /********************************************************************************************
    * Cancels records for past history
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_episode                Episode ID
    * @param i_past_hist_ft_id        Free text id
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param i_date_cancel            Cancel date
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2010/01/20
    **********************************************************************************************/
    FUNCTION prv_cancel_past_hist_free_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_pat              IN patient.id_patient%TYPE,
        i_past_hist_ft_id  IN pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_cancel_date      IN pat_past_hist_free_text.dt_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ph_ft_id       pat_past_hist_ft_hist.id_pat_ph_ft%TYPE;
        l_pat_ph_ft_hist pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
    
    BEGIN
        IF NOT pk_past_history.set_past_hist_free_text(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_pat              => i_pat,
                                                       i_episode          => i_episode,
                                                       i_doc_area         => i_doc_area,
                                                       i_ph_ft_id         => i_past_hist_ft_id,
                                                       i_ph_ft_text       => NULL,
                                                       i_id_cancel_reason => i_id_cancel_reason,
                                                       i_cancel_notes     => i_cancel_notes,
                                                       i_dt_register      => i_cancel_date,
                                                       i_dt_review        => NULL,
                                                       o_ph_ft_id         => l_ph_ft_id,
                                                       o_pat_ph_ft_hist   => l_pat_ph_ft_hist,
                                                       o_error            => o_error)
        
        THEN
            g_error := 'PRV_CANCEL_PAST_HIST_FREE_TEXT has failed';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING CANCEL_PAST_HIST FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'PRV_CANCEL_PAST_HIST_FREE_TEXT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRV_CANCEL_PAST_HIST_FREE_TEXT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END prv_cancel_past_hist_free_text;
    --

    /**
    * prv_get_review_notel_label returns notes label considering value and config
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_notes                  Notes
    *
    * @return  VARCHAR2                returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.1.3
    * @since   2011-SET-29
    */
    FUNCTION prv_get_review_note_label
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN VARCHAR2
    ) RETURN sys_message.desc_message%TYPE IS
        l_review_notes_config sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'PAST_HISTORY_REVIEW',
                                                                               i_prof    => i_prof);
    
        l_label_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PATIENT_HABITS_T007'); --a new label should be created
    
    BEGIN
        IF l_review_notes_config = pk_alert_constant.g_yes
        THEN
            RETURN l_label_notes;
        ELSE
            IF i_notes IS NULL
            THEN
                RETURN NULL;
            ELSE
                RETURN l_label_notes;
            END IF;
        END IF;
    
    END prv_get_review_note_label;
    --
    /********************************************************************************************
    * Returns the unclassified diagnosis translation(ex: 'None' and 'Unknown')
    *
    * @param i_lang                   Language ID
    * @param i_id_diagnosis           Input diagnosis
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2011/10/24
    **********************************************************************************************/
    FUNCTION prv_ph_diag_not_class_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_id_diagnosis IN pat_history_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
    
        l_domain_no_class sys_domain.code_domain%TYPE := 'PAT_PROBLEM.FLG_STATUS_NO_DIAG';
    
    BEGIN
    
        IF i_id_diagnosis = g_diag_none
        THEN
            RETURN pk_sysdomain.get_domain(l_domain_no_class, g_pat_hist_diag_none, i_lang);
        ELSIF i_id_diagnosis = g_diag_non_remark
        THEN
            RETURN pk_sysdomain.get_domain(l_domain_no_class, g_pat_hist_diag_non_remark, i_lang);
        ELSIF i_id_diagnosis = g_diag_unknown
        THEN
            RETURN pk_sysdomain.get_domain(l_domain_no_class, g_pat_hist_diag_unknown, i_lang);
        ELSE
            RETURN NULL;
        END IF;
    
    END prv_ph_diag_not_class_desc;

    /****************************************************************************************************************************************************************************************
    * PUBLIC/PRIVATE FUNCTIONS USED IN PK
    *****************************************************************************************************************************************************************************************/

    /********************************************************************************************
    * Returns the unclassified diagnosis (ex: 'None' and 'Unknown')
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param o_diag_not_class         Cursor containing the not classified diagnosis info                                      
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION prv_past_hist_diag_not_class
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_pat            IN patient.id_patient%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_diag_not_class OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis_count      NUMBER;
        l_free_text_count      NUMBER;
        l_documentation_count  NUMBER;
        l_flg_doc_are_type     VARCHAR2(1);
        l_doc_area_table       table_number;
        l_doc_area_has_records VARCHAR2(1);
        l_active_records       VARCHAR2(1);
        l_not_class_active     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('DIAG_NOT_CLASS_CONSIDER_OTHER_AREAS',
                                                                                        i_prof);
    BEGIN
        --Count diagnosis saved active records
        l_flg_doc_are_type := prv_conv_doc_area_to_flg_type(i_doc_area);
    
        SELECT COUNT(phd.id_pat_history_diagnosis)
          INTO l_diagnosis_count
          FROM pat_history_diagnosis phd
         WHERE phd.id_patient = i_pat
           AND phd.flg_type = l_flg_doc_are_type
           AND nvl(phd.flg_status, g_dummy_status) NOT IN
               (pk_past_history.g_pat_hist_diag_canceled,
                pk_past_history.g_pat_hist_diag_unknown,
                pk_past_history.g_pat_hist_diag_none,
                pk_past_history.g_pat_hist_diag_non_remark)
           AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                pk_alert_constant.g_diag_area_surgical_hist,
                                pk_alert_constant.g_diag_area_family_hist,
                                pk_alert_constant.g_diag_area_not_defined);
    
        --Count free text  saved active records
        SELECT COUNT(pphft.id_pat_ph_ft)
          INTO l_free_text_count
          FROM pat_past_hist_free_text pphft
         WHERE pphft.id_patient = i_pat
           AND pphft.id_doc_area = i_doc_area
           AND pphft.flg_status = pk_past_history.g_flg_status_active_free_text;
    
        --Check for documentation records
        l_doc_area_table      := table_number(i_doc_area);
        l_documentation_count := 0;
    
        --Call touch option function
        g_error := 'Call  pk_touch_option.get_doc_area_exists';
        IF NOT pk_touch_option.get_doc_area_exists(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_doc_area_list => l_doc_area_table,
                                                   i_scope         => i_pat,
                                                   i_scope_type    => 'P',
                                                   o_flg_data      => l_doc_area_has_records,
                                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Cover to number
        IF l_doc_area_has_records = pk_alert_constant.g_yes
        THEN
            l_documentation_count := 1;
        ELSE
            l_documentation_count := 0;
        END IF;
    
        --Get status var
        IF ((l_diagnosis_count + l_free_text_count + l_documentation_count) > 0 AND
           l_not_class_active = pk_alert_constant.g_yes OR
           (l_not_class_active = pk_alert_constant.g_no AND l_diagnosis_count > 0))
        THEN
            l_active_records := pk_alert_constant.g_no;
        ELSE
            l_active_records := pk_alert_constant.g_yes;
        END IF;
    
        -- TODO: remove i_doc_area from the function's parameters
        g_error := 'OPEN o_diag_not_class';
        OPEN o_diag_not_class FOR
            SELECT /*+opt_estimate(table t rows=2)*/
             CASE t.val
                 WHEN g_pat_hist_diag_none THEN
                  g_diag_none
                 WHEN g_pat_hist_diag_non_remark THEN
                  g_diag_non_remark
                 WHEN g_pat_hist_diag_unknown THEN
                  g_diag_unknown
             END id_diagnosis,
             CASE t.val
                 WHEN g_pat_hist_diag_none THEN
                  '<b>' || prv_ph_diag_not_class_desc(i_lang, g_diag_none) || '<\b>'
                 WHEN g_pat_hist_diag_non_remark THEN
                  '<b>' || prv_ph_diag_not_class_desc(i_lang, g_diag_non_remark) || '<\b>'
                 WHEN g_pat_hist_diag_unknown THEN
                  '<b>' || prv_ph_diag_not_class_desc(i_lang, g_diag_unknown) || '<\b>'
             END desc_diagnosis,
             t.val flg_status,
             l_active_records flg_available
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_code_dom      => 'PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  i_dep_clin_serv => 0,
                                                                  i_domain_owner  => 'ALERT')) t
             ORDER BY id_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_diag_not_class',
                                              o_error);
            pk_types.open_my_cursor(o_diag_not_class);
            RETURN FALSE;
    END prv_past_hist_diag_not_class;
    --
    /********************************************************************************************
    * Returns the query for the past history grid
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_phd                    Pat History Diagnosis/Pat notes ID
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0       
    * @since                          2007/06/11
    **********************************************************************************************/
    FUNCTION prv_get_ph_all_grid_diag
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_past_hist_id IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        o_doc_area_val OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diag_count             NUMBER;
        l_none_unkown_count      NUMBER;
        l_doc_area_flg_type      VARCHAR2(1);
        l_none_unknown_table     table_number := table_number(g_diag_unknown, g_diag_none, g_diag_non_remark);
        l_dummy_exclude          table_number := table_number(-3);
        l_exclude_id             table_number;
        l_tbl_id_alert_diagnosis table_number;
        l_tbl_id_diagnosis       table_number;
    
        l_birth_hist_mechanism sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_birth_hist_search_mechanism,
                                                                                i_prof);
        l_surg_hist_mechanism  sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism,
                                                                                i_prof);
        l_med_hist_mechanism   sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism,
                                                                                i_prof);
    
        PROCEDURE get_previous_diagnosis
        (
            i_flg_type         IN pat_history_diagnosis.flg_type%TYPE,
            i_task_type        IN task_type.id_task_type%TYPE,
            o_doc_area_val_aux OUT pk_types.cursor_type
        ) AS
        
        BEGIN
            --Obtain the diagnoses ids, already registered for the patient, to be used in o_doc_area_val
            SELECT DISTINCT phd.id_alert_diagnosis, phd.id_diagnosis
              BULK COLLECT
              INTO l_tbl_id_alert_diagnosis, l_tbl_id_diagnosis
              FROM pat_history_diagnosis phd
             WHERE phd.id_patient = i_id_patient
               AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
               AND phd.flg_type = i_flg_type
               AND phd.id_pat_history_diagnosis_new IS NULL
               AND phd.id_alert_diagnosis NOT IN (SELECT /*+ opt_estimate(table l rows=1)*/
                                                   *
                                                    FROM TABLE(l_exclude_id) l);
        
            OPEN o_doc_area_val_aux FOR
                SELECT phd.id_episode,
                       pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                       pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                  i_id_diagnosis       => d.id_diagnosis,
                                                  i_id_task_type       => pk_alert_constant.g_task_family_history,
                                                  i_code               => d.code_icd,
                                                  i_flg_other          => d.flg_other,
                                                  i_flg_std_diag       => adt.flg_icd9) desc_past_hist,
                       -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                       get_desc_past_hist_all(i_lang,
                                              i_prof,
                                              phd.id_alert_diagnosis,
                                              phd.desc_pat_history_diagnosis,
                                              d.code_icd,
                                              d.flg_other,
                                              adt.flg_icd9,
                                              phd.flg_status,
                                              phd.flg_compl,
                                              phd.flg_nature,
                                              phd.dt_diagnosed,
                                              phd.dt_diagnosed_precision,
                                              i_doc_area,
                                              phd.id_family_relationship) desc_past_hist_all,
                       phd.flg_status,
                       pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                       phd.flg_nature,
                       pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                       -- check if it is the current episode
                       decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                       -- check if the diagnosis was registered by the current professional
                       decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                       phd.id_alert_diagnosis id_diagnosis,
                       decode(phd.id_pat_history_diagnosis_new,
                              NULL,
                              pk_alert_constant.get_no,
                              pk_alert_constant.get_yes) flg_outdated,
                       decode(phd.flg_status,
                              g_pat_hist_diag_canceled,
                              pk_alert_constant.get_yes,
                              pk_alert_constant.get_no) flg_canceled,
                       decode(phd.dt_diagnosed_precision,
                              pk_problems.g_unknown,
                              pk_problems.g_unknown,
                              pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                       phd.dt_diagnosed_precision dt_diagnosed_precision,
                       pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_date      => phd.dt_diagnosed,
                                                               i_precision => phd.dt_diagnosed_precision) dt_problem,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   phd.dt_pat_history_diagnosis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_register_chr,
                       decode(phd.flg_status,
                              g_pat_hist_diag_canceled,
                              pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                              decode(phd.id_pat_history_diagnosis_new,
                                     NULL,
                                     NULL,
                                     pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                       phd.notes,
                       d.flg_other,
                       NULL precision_flag,
                       phd.id_diagnosis id_concept_version
                  FROM pat_history_diagnosis phd
                  JOIN alert_diagnosis_type adt
                    ON adt.id_alert_diagnosis = phd.id_alert_diagnosis
                 RIGHT OUTER JOIN diagnosis d
                    ON adt.id_diagnosis = d.id_diagnosis
                  JOIN (SELECT /*+ opt_estimate(table t rows=5)*/
                         t.id_alert_diagnosis
                          FROM TABLE(pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                              i_prof                     => i_prof,
                                                                              i_patient                  => i_id_patient,
                                                                              i_terminologies_task_types => table_number(pk_alert_constant.g_task_family_history),
                                                                              i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_family_history),
                                                                              i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis)) t) tf
                    ON tf.id_alert_diagnosis = phd.id_alert_diagnosis
                 WHERE flg_recent_diag = pk_alert_constant.get_yes
                   AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                   AND phd.flg_type = i_flg_type --g_alert_diag_type_family
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_patient = i_id_patient
                   AND adt.id_task_type = i_task_type --pk_alert_constant.g_task_family_history
                 ORDER BY flg_status ASC,
                          flg_nature ASC,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => adt.flg_icd9) ASC;
        END get_previous_diagnosis;
    
    BEGIN
        l_doc_area_flg_type := prv_conv_doc_area_to_flg_type(i_doc_area);
    
        --Check number of records
        SELECT COUNT(phd.id_pat_history_diagnosis)
          INTO l_diag_count
          FROM pat_history_diagnosis phd
         WHERE phd.id_patient = i_id_patient
           AND nvl(phd.flg_status, g_active) != g_pat_hist_diag_canceled
           AND phd.flg_type = l_doc_area_flg_type;
    
        --Check number none and unknown records
        SELECT COUNT(phd.id_pat_history_diagnosis)
          INTO l_none_unkown_count
          FROM pat_history_diagnosis phd
         WHERE phd.id_patient = i_id_patient
           AND nvl(phd.flg_status, g_active) != g_pat_hist_diag_canceled
           AND phd.flg_type = l_doc_area_flg_type
           AND phd.id_alert_diagnosis IN (SELECT *
                                            FROM TABLE(l_none_unknown_table));
        --Check if has exactly none ou unknown
        IF (l_diag_count = 1 AND l_none_unkown_count = 1)
        THEN
            l_exclude_id := l_dummy_exclude;
        ELSE
            l_exclude_id := l_none_unknown_table;
        END IF;
    
        IF i_doc_area = g_doc_area_past_med
        THEN
            -- Past medical
            --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
            pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_medical_history);
        
            g_error := 'OPEN o_doc_area_val(1)';
            IF l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
            
                --Obtain the diagnoses ids, already registered for the patient, to be used in o_doc_area_val
                SELECT DISTINCT phd.id_alert_diagnosis, phd.id_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_alert_diagnosis, l_tbl_id_diagnosis
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_patient = i_id_patient
                   AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                   AND phd.flg_type = g_alert_diag_type_med
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_alert_diagnosis NOT IN (SELECT /*+ opt_estimate(table l rows=1)*/
                                                       *
                                                        FROM TABLE(l_exclude_id) l);
            
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           decode(phd.desc_pat_history_diagnosis, NULL, '', phd.desc_pat_history_diagnosis || ' - ') ||
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_medical_history,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => adt.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           -- TODO: remove this reference. On the PAT_PROBLEM table, there is never need to filter None or Unknown
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  adt.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_nature,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           d.flg_other,
                           phd.desc_pat_history_diagnosis,
                           phd.notes,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd
                      JOIN alert_diagnosis_type adt
                        ON adt.id_alert_diagnosis = phd.id_alert_diagnosis
                     RIGHT OUTER JOIN diagnosis d
                        ON adt.id_diagnosis = d.id_diagnosis
                      JOIN (SELECT /*+ opt_estimate(table t rows=5)*/
                             t.id_diagnosis, t.id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                                  i_prof                     => i_prof,
                                                                                  i_patient                  => i_id_patient,
                                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                                  i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_medical_history),
                                                                                  i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis)) t) tf
                        ON tf.id_alert_diagnosis = phd.id_alert_diagnosis
                     WHERE decode(nvl(phd.flg_status, g_dummy_status),
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.g_cancelled,
                                  decode(phd.flg_recent_diag, pk_alert_constant.get_no, g_outdated, g_active)) NOT IN
                           (g_pat_hist_diag_canceled, g_outdated)
                       AND (phd.id_pat_history_diagnosis =
                            pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                 phd.id_alert_diagnosis,
                                                                 phd.desc_pat_history_diagnosis,
                                                                 i_id_patient,
                                                                 i_prof,
                                                                 pk_alert_constant.get_no))
                       AND phd.id_patient = i_id_patient
                       AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                            pk_alert_constant.g_diag_area_surgical_hist,
                                            pk_alert_constant.g_diag_area_not_defined)
                       AND phd.id_alert_diagnosis NOT IN (SELECT *
                                                            FROM TABLE(l_exclude_id))
                       AND adt.id_task_type = pk_alert_constant.g_task_medical_history
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => adt.flg_icd9) ASC;
            ELSE
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           decode(phd.desc_pat_history_diagnosis, NULL, '', phd.desc_pat_history_diagnosis || ' - ') ||
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_medical_history,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           -- TODO: remove this reference. On the PAT_PROBLEM table, there is never need to filter None or Unknown
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  ad.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_nature,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           d.flg_other,
                           phd.desc_pat_history_diagnosis,
                           phd.notes,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
                       AND ad.id_diagnosis = d.id_diagnosis(+)
                       AND decode(nvl(phd.flg_status, g_dummy_status),
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.g_cancelled,
                                  decode(phd.flg_recent_diag, pk_alert_constant.get_no, g_outdated, g_active)) NOT IN
                           (g_pat_hist_diag_canceled, g_outdated)
                       AND (phd.id_pat_history_diagnosis =
                           pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                 phd.id_alert_diagnosis,
                                                                 phd.desc_pat_history_diagnosis,
                                                                 i_id_patient,
                                                                 i_prof,
                                                                 pk_alert_constant.get_no))
                       AND phd.id_patient = i_id_patient
                       AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                            pk_alert_constant.g_diag_area_surgical_hist,
                                            pk_alert_constant.g_diag_area_not_defined)
                       AND phd.id_alert_diagnosis NOT IN (SELECT *
                                                            FROM TABLE(l_exclude_id))
                       AND (phd.id_diagnosis, phd.id_alert_diagnosis) IN
                           (SELECT /*+ opt_estimate(table t rows=1)*/
                             phd.id_diagnosis, id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.tf_get_valid_past_medical_hist(i_lang                  => i_lang,
                                                                                              i_prof                  => i_prof,
                                                                                              i_tbl_transaccional_ids => table_number(phd.id_pat_history_diagnosis))) t)
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => ad.flg_icd9) ASC;
            END IF;
        
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            -- Past Surgical
            --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
            pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_surgical_history);
        
            g_error := 'OPEN o_doc_area_val(2)';
            IF l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                --Obtain the diagnoses ids, already registered for the patient, to be used in o_doc_area_val
                SELECT DISTINCT phd.id_alert_diagnosis, phd.id_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_alert_diagnosis, l_tbl_id_diagnosis
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_patient = i_id_patient
                   AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                   AND phd.flg_type = g_alert_diag_type_surg
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_alert_diagnosis NOT IN (SELECT /*+ opt_estimate(table l rows=1)*/
                                                       *
                                                        FROM TABLE(l_exclude_id) l);
            
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => adt.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  adt.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_compl flg_nature,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) desc_nature,
                           -- check if it is the current episode
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           -- check if the diagnosis was registered by the current professional
                           decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.id_pat_history_diagnosis_new,
                                  NULL,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  decode(phd.id_pat_history_diagnosis_new,
                                         NULL,
                                         NULL,
                                         pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                           phd.notes,
                           d.flg_other,
                           phd.desc_pat_history_diagnosis,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd
                      JOIN alert_diagnosis_type adt
                        ON adt.id_alert_diagnosis = phd.id_alert_diagnosis
                     RIGHT OUTER JOIN diagnosis d
                        ON adt.id_diagnosis = d.id_diagnosis
                      JOIN (SELECT /*+ opt_estimate(table t rows=5)*/
                             t.id_diagnosis, t.id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                                  i_prof                     => i_prof,
                                                                                  i_patient                  => i_id_patient,
                                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_surgical_history),
                                                                                  i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_surgical_history),
                                                                                  i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis)) t) tf
                        ON tf.id_alert_diagnosis = phd.id_alert_diagnosis
                     WHERE flg_recent_diag = pk_alert_constant.get_yes
                       AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                       AND phd.flg_type = g_alert_diag_type_surg
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND phd.id_patient = i_id_patient
                       AND adt.id_task_type = pk_alert_constant.g_task_surgical_history
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                         i_id_diagnosis       => d.id_diagnosis,
                                                         i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => adt.flg_icd9) ASC;
            
            ELSE
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  ad.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_compl flg_nature,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) desc_nature,
                           -- check if it is the current episode
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           -- check if the diagnosis was registered by the current professional
                           decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.id_pat_history_diagnosis_new,
                                  NULL,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  decode(phd.id_pat_history_diagnosis_new,
                                         NULL,
                                         NULL,
                                         pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                           phd.notes,
                           d.flg_other,
                           phd.desc_pat_history_diagnosis,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd, professional p, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_professional = p.id_professional
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis
                       AND ad.id_diagnosis = d.id_diagnosis(+)
                       AND flg_recent_diag = pk_alert_constant.get_yes
                       AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                       AND phd.flg_type = g_alert_diag_type_surg
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND phd.id_patient = i_id_patient
                       AND phd.id_alert_diagnosis NOT IN (SELECT *
                                                            FROM TABLE(l_exclude_id))
                       AND (phd.id_diagnosis, phd.id_alert_diagnosis) IN
                           (SELECT /*+ opt_estimate(table t rows=1)*/
                             phd.id_diagnosis, id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.tf_get_valid_past_surgic_hist(i_lang                  => i_lang,
                                                                                             i_prof                  => i_prof,
                                                                                             i_tbl_transaccional_ids => table_number(phd.id_pat_history_diagnosis))) t)
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                         i_id_diagnosis       => d.id_diagnosis,
                                                         i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => ad.flg_icd9) ASC;
            END IF;
        
        ELSIF i_doc_area = g_doc_area_cong_anom
        THEN
            -- Congenital anomalies
            --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
            pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type,
                                         pk_alert_constant.g_task_congenital_anomalies);
        
            g_error := 'OPEN o_doc_area_val(3)';
            IF l_birth_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                --Obtain the diagnoses ids, already registered for the patient, to be used in o_doc_area_val
                SELECT DISTINCT phd.id_alert_diagnosis, phd.id_diagnosis
                  BULK COLLECT
                  INTO l_tbl_id_alert_diagnosis, l_tbl_id_diagnosis
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_patient = i_id_patient
                   AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                   AND phd.flg_type = g_alert_diag_type_cong_anom
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_alert_diagnosis NOT IN (SELECT /*+ opt_estimate(table l rows=1)*/
                                                       *
                                                        FROM TABLE(l_exclude_id) l);
            
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_congenital_anomalies,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => adt.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  adt.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_nature,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                           -- check if it is the current episode
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           -- check if the diagnosis was registered by the current professional
                           decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.id_pat_history_diagnosis_new,
                                  NULL,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  decode(phd.id_pat_history_diagnosis_new,
                                         NULL,
                                         NULL,
                                         pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                           phd.notes,
                           d.flg_other,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd
                      JOIN alert_diagnosis_type adt
                        ON adt.id_alert_diagnosis = phd.id_alert_diagnosis
                     RIGHT OUTER JOIN diagnosis d
                        ON adt.id_diagnosis = d.id_diagnosis
                      JOIN (SELECT /*+ opt_estimate(table t rows=5)*/
                             t.id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                                  i_prof                     => i_prof,
                                                                                  i_patient                  => i_id_patient,
                                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_congenital_anomalies),
                                                                                  i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_congenital_anomalies),
                                                                                  i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis)) t) tf
                        ON tf.id_alert_diagnosis = phd.id_alert_diagnosis
                     WHERE flg_recent_diag = pk_alert_constant.get_yes
                       AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                       AND phd.flg_type = g_alert_diag_type_cong_anom
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND phd.id_patient = i_id_patient
                       AND adt.id_task_type = pk_alert_constant.g_task_congenital_anomalies
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => adt.id_alert_diagnosis,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => adt.flg_icd9) ASC;
            
            ELSE
                OPEN o_doc_area_val FOR
                    SELECT phd.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_id_task_type       => pk_alert_constant.g_task_congenital_anomalies,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                           -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                           get_desc_past_hist_all(i_lang,
                                                  i_prof,
                                                  phd.id_alert_diagnosis,
                                                  phd.desc_pat_history_diagnosis,
                                                  d.code_icd,
                                                  d.flg_other,
                                                  ad.flg_icd9,
                                                  phd.flg_status,
                                                  phd.flg_compl,
                                                  phd.flg_nature,
                                                  phd.dt_diagnosed,
                                                  phd.dt_diagnosed_precision,
                                                  i_doc_area,
                                                  phd.id_family_relationship) desc_past_hist_all,
                           phd.flg_status,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                           phd.flg_nature,
                           pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                           -- check if it is the current episode
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           -- check if the diagnosis was registered by the current professional
                           decode(p.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           phd.id_alert_diagnosis id_diagnosis,
                           decode(phd.id_pat_history_diagnosis_new,
                                  NULL,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           decode(phd.dt_diagnosed_precision,
                                  pk_problems.g_unknown,
                                  pk_problems.g_unknown,
                                  pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                           phd.dt_diagnosed_precision dt_diagnosed_precision,
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision) dt_problem,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  decode(phd.id_pat_history_diagnosis_new,
                                         NULL,
                                         NULL,
                                         pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                           phd.notes,
                           d.flg_other,
                           NULL precision_flag,
                           phd.id_diagnosis id_concept_version
                      FROM pat_history_diagnosis phd, professional p, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_professional = p.id_professional
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis
                       AND ad.id_diagnosis = d.id_diagnosis(+)
                       AND flg_recent_diag = pk_alert_constant.get_yes
                       AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                       AND phd.flg_type = g_alert_diag_type_cong_anom
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND phd.id_patient = i_id_patient
                       AND phd.id_alert_diagnosis NOT IN (SELECT *
                                                            FROM TABLE(l_exclude_id))
                       AND (phd.id_diagnosis, phd.id_alert_diagnosis) IN
                           (SELECT /*+ opt_estimate(table t rows=1)*/
                             phd.id_diagnosis, id_alert_diagnosis
                              FROM TABLE(pk_terminology_search.tf_get_valid_cong_anomalies(i_lang                  => i_lang,
                                                                                           i_prof                  => i_prof,
                                                                                           i_tbl_transaccional_ids => table_number(phd.id_pat_history_diagnosis))) t)
                    
                     ORDER BY flg_status ASC,
                              flg_nature ASC,
                              pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                         i_code               => d.code_icd,
                                                         i_flg_other          => d.flg_other,
                                                         i_flg_std_diag       => ad.flg_icd9) ASC;
            END IF;
        
        ELSIF i_doc_area = g_doc_area_gyn_hist
        THEN
            -- gynecologic
            --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
            pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type,
                                         pk_alert_constant.g_task_gynecology_history);
        
            g_error := 'OPEN o_doc_area_val(3)';
            get_previous_diagnosis(i_flg_type         => g_alert_diag_type_gyneco,
                                   i_task_type        => pk_alert_constant.g_task_gynecology_history,
                                   o_doc_area_val_aux => o_doc_area_val);
        
        ELSIF i_doc_area = g_doc_area_treatments
        THEN
            g_error := 'OPEN O_DOC_AREA_VAL';
            OPEN o_doc_area_val FOR
                SELECT phd.id_episode,
                       pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                       phd.flg_status,
                       pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                       phd.flg_compl flg_nature,
                       pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) desc_nature,
                       -- check if it is the current episode
                       decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                       -- check if the diagnosis was registered by the current professional
                       decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                       phd.id_alert_diagnosis id_diagnosis,
                       decode(phd.id_pat_history_diagnosis_new,
                              NULL,
                              pk_alert_constant.get_no,
                              pk_alert_constant.get_yes) flg_outdated,
                       decode(phd.flg_status,
                              g_pat_hist_diag_canceled,
                              pk_alert_constant.get_yes,
                              pk_alert_constant.get_no) flg_canceled,
                       decode(phd.dt_diagnosed_precision,
                              pk_problems.g_unknown,
                              pk_problems.g_unknown,
                              pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)) onset,
                       phd.dt_diagnosed_precision dt_diagnosed_precision,
                       pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_date      => phd.dt_diagnosed,
                                                               i_precision => phd.dt_diagnosed_precision) dt_problem,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   phd.dt_pat_history_diagnosis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_register_chr,
                       decode(phd.flg_status,
                              g_pat_hist_diag_canceled,
                              pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                              decode(phd.id_pat_history_diagnosis_new,
                                     NULL,
                                     NULL,
                                     pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                       phd.notes,
                       pk_alert_constant.get_no flg_free_text,
                       nvl(phd.id_exam, phd.id_intervention) id_treatment,
                       nvl(prv_ph_diag_not_class_desc(i_lang, phd.id_alert_diagnosis),
                           (nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                                pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL)))) desc_past_hist,
                       nvl(prv_ph_diag_not_class_desc(i_lang, phd.id_alert_diagnosis),
                           (nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                                pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL)))) desc_past_hist_all,
                       phd.id_exam,
                       phd.id_intervention,
                       get_partial_date_format(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_date      => phd.dt_execution,
                                               i_precision => phd.dt_execution_precision) dt_execution_string,
                       pk_date_utils.date_send_tsz(i_lang, phd.dt_execution, i_prof) dt_execution,
                       nvl2(phd.id_exam, exm.flg_type, pk_past_history.g_flg_treatments_proc_search) exam_type,
                       decode(exm.flg_type, 'I', 'ImageExameIcon', 'E', 'TechnicianInContact', 'InterventionsIcon') exam_type_icon,
                       phd.dt_execution_precision execution_precision,
                       phd.id_diagnosis id_concept_version
                  FROM pat_history_diagnosis phd
                  LEFT JOIN exam exm
                    ON exm.id_exam = phd.id_exam
                  LEFT JOIN intervention intrv
                    ON intrv.id_intervention = phd.id_intervention
                 WHERE flg_recent_diag = pk_alert_constant.get_yes
                   AND nvl(phd.flg_status, g_dummy_status) != g_pat_hist_diag_canceled
                   AND phd.flg_type = g_alert_type_treatments
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.id_patient = i_id_patient
                   AND (phd.id_alert_diagnosis NOT IN (SELECT *
                                                         FROM TABLE(l_exclude_id)) OR phd.id_alert_diagnosis IS NULL)
                 ORDER BY flg_status ASC, flg_nature ASC, desc_past_hist ASC;
        
        ELSIF i_doc_area = g_doc_area_past_fam
        THEN
            -- Family History
            --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
            pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_family_history);
        
            IF i_past_hist_id IS NULL -- creation mode
            THEN
                pk_types.open_my_cursor(o_doc_area_val);
            ELSE
                get_previous_diagnosis(i_flg_type         => g_alert_diag_type_family,
                                       i_task_type        => pk_alert_constant.g_task_family_history,
                                       o_doc_area_val_aux => o_doc_area_val);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_all_grid',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END prv_get_ph_all_grid_diag;

    /********************************************************************************************
    * Returns the query for the past history grid
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_phd                    Pat History Diagnosis/Pat notes ID
    
    * @param o_doc_area_val           Documentation data for the patient's episodes   
    * @param o_ph_ft                  Patient past history free text                                      
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2010-Dec-09
    **********************************************************************************************/
    FUNCTION get_past_hist_all_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_past_hist_id IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_past_hist_ft IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_val OUT pk_types.cursor_type,
        o_ph_ft_text   OUT pat_past_hist_free_text.text%TYPE,
        o_ph_ft_id     OUT pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return   BOOLEAN;
        l_flg_type pat_past_hist_free_text.flg_type%TYPE;
        l_date     pat_past_hist_free_text.dt_register%TYPE;
    
    BEGIN
        g_error := 'CALL TO get_past_hist_all_grid';
    
        l_return := prv_get_ph_all_grid_diag(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_id_episode   => i_id_episode,
                                             i_id_patient   => i_id_patient,
                                             i_doc_area     => i_doc_area,
                                             i_past_hist_id => i_past_hist_id,
                                             o_doc_area_val => o_doc_area_val,
                                             o_error        => o_error);
    
        IF l_return = FALSE
        THEN
            RAISE g_exception;
        ELSIF i_past_hist_id IS NULL
        THEN
            o_ph_ft_text := NULL;
            o_ph_ft_id   := NULL;
        
            pk_types.open_cursor_if_closed(o_doc_area_val);
            RETURN TRUE;
        ELSE
            l_flg_type := prv_conv_doc_area_to_flg_type(i_doc_area);
        
            IF i_past_hist_ft = pk_alert_constant.get_no
            THEN
                SELECT phd.dt_pat_history_diagnosis_tstz
                  INTO l_date
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_pat_history_diagnosis = i_past_hist_id;
                BEGIN
                    SELECT pphft.text, pphft.id_pat_ph_ft
                      INTO o_ph_ft_text, o_ph_ft_id
                      FROM pat_past_hist_free_text pphft
                     WHERE pphft.id_patient = i_id_patient
                       AND pphft.flg_type = l_flg_type
                       AND pphft.flg_status IN (g_flg_status_active_free_text, g_flg_status_outdtd_free_text)
                       AND pphft.dt_register = l_date;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_ph_ft_text := NULL;
                        o_ph_ft_id   := NULL;
                END;
            ELSE
                BEGIN
                
                    SELECT pphft.text, pphft.id_pat_ph_ft
                      INTO o_ph_ft_text, o_ph_ft_id
                      FROM pat_past_hist_free_text pphft
                     WHERE pphft.id_patient = i_id_patient
                       AND pphft.flg_type = l_flg_type
                       AND pphft.flg_status IN (g_flg_status_active_free_text, g_flg_status_outdtd_free_text)
                       AND pphft.id_pat_ph_ft = (SELECT pphfth.id_pat_ph_ft
                                                   FROM pat_past_hist_ft_hist pphfth
                                                  WHERE pphfth.id_pat_ph_ft_hist = i_past_hist_id);
                EXCEPTION
                    WHEN no_data_found THEN
                        o_ph_ft_text := NULL;
                        o_ph_ft_id   := NULL;
                END;
            END IF;
        
            pk_types.open_cursor_if_closed(o_doc_area_val);
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_all_grid',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END get_past_hist_all_grid;
    --

    /********************************************************************************************
    * Returns most recent ID for that alert_diagnosis / desc_pat_history_diagnosis
    * Similar to PK_PROBLEMS.get_pat_hist_diag_recent but for cong. anom. and surg hx
    *
    * @param i_lang                   Language ID
    * @param i_alert_diag             Alert Diagnosis ID
    * @param i_desc_phd               Description for the PHD
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_canceled           Flg cancel (if canceled are to be returned or not - Y/N)
    *
    * @return                         PHD ID wanted
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/10/18
    **********************************************************************************************/

    FUNCTION prv_get_ph_diag_recent_all
    (
        i_lang       IN language.id_language%TYPE,
        i_alert_diag IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd   IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_flg_type   IN pat_history_diagnosis.flg_type%TYPE,
        i_pat        IN patient.id_patient%TYPE
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE IS
    
        --l_problem pk_types.cursor_type;
        l_id_phd pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    
        CURSOR c_alert_diag IS
            SELECT x.id_pat_history_diagnosis
              FROM (SELECT *
                      FROM (SELECT MAX(phd.id_pat_history_diagnosis) AS id_pat_history_diagnosis, phd.flg_status
                              FROM pat_history_diagnosis phd
                             WHERE phd.flg_type = i_flg_type
                                  --AND phd.flg_status NOT IN (g_pat_hist_diag_unknown, g_pat_hist_diag_none)
                               AND phd.id_pat_history_diagnosis_new IS NULL
                               AND phd.id_patient = i_pat
                               AND phd.id_alert_diagnosis = i_alert_diag
                             GROUP BY id_pat_history_diagnosis, phd.flg_status
                             ORDER BY id_pat_history_diagnosis DESC)
                     WHERE rownum = 1) x;
        --WHERE x.flg_status <> decode(i_flg_canceled, g_available, 'DUMMY', g_flg_cancel);
    
        CURSOR c_desc_phd IS
            SELECT x.id_pat_history_diagnosis
              FROM (SELECT *
                      FROM (SELECT MAX(phd.id_pat_history_diagnosis) AS id_pat_history_diagnosis, phd.flg_status
                              FROM pat_history_diagnosis phd
                             WHERE phd.flg_type = i_flg_type
                                  --AND phd.flg_status NOT IN (g_pat_hist_diag_unknown, g_pat_hist_diag_none)
                               AND phd.id_pat_history_diagnosis_new IS NULL
                               AND phd.id_patient = i_pat
                               AND phd.desc_pat_history_diagnosis = i_desc_phd
                             GROUP BY id_pat_history_diagnosis, phd.flg_status
                             ORDER BY id_pat_history_diagnosis DESC)
                     WHERE rownum = 1) x;
        --WHERE x.flg_status <> decode(i_flg_canceled, g_available, 'DUMMY', g_flg_cancel);
    
    BEGIN
    
        IF i_alert_diag IS NOT NULL
        THEN
        
            OPEN c_alert_diag;
            FETCH c_alert_diag
                INTO l_id_phd;
            CLOSE c_alert_diag;
        
        ELSIF i_desc_phd IS NOT NULL
        THEN
        
            OPEN c_desc_phd;
            FETCH c_desc_phd
                INTO l_id_phd;
            CLOSE c_desc_phd;
        
        END IF;
    
        RETURN l_id_phd;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'get_pat_hist_diag_recent_all',
                                                  
                                                  l_error);
                RETURN - 1;
            END;
        
    END prv_get_ph_diag_recent_all;
    --

    /********************************************************************************************
    * Returns the query for the past medical history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_flg_diag_call          Function is called by diagnosis deepnaves. Y - Yes; N - Otherwise
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_medical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_diag_call     IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_register OUT NOCOPY pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_med_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_med_history sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUMMARY_M031');
        l_surgery sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUMMARY_M033');
        --
        l_code_dom_ed_flg_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS';
    
        l_patient  patient.id_patient%TYPE;
        l_visit    visit.id_visit%TYPE;
        l_episode  episode.id_episode%TYPE;
        l_doc_area doc_area.id_doc_area%TYPE;
    
        l_config_transfer_status sys_config.value%TYPE;
        l_episodes_visit         table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt table_timestamp_tstz;
        l_past_hist_id table_number;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    BEGIN
    
        l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_med);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_diagnosis(g_alert_diag_type_med,
                                           l_patient,
                                           l_episode,
                                           l_visit,
                                           i_scope_type,
                                           l_episodes_visit,
                                           pk_alert_constant.g_task_medical_history,
                                           i_flg_diag_call,
                                           l_past_hist_id,
                                           l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_medical_history);
    
        IF i_flg_diag_call = pk_alert_constant.get_no
        THEN
            g_error := 'OPEN O_DOC_AREA_REGISTER';
            ---
            -- per episode / patient
            ---   
            OPEN o_doc_area_register FOR
                SELECT /*+opt_estimate(table tab rows=10)*/
                DISTINCT phd.id_episode,
                         decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                         pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                         pk_prof_utils.get_spec_signature(i_lang,
                                                          i_prof,
                                                          phd.id_professional,
                                                          phd.dt_pat_history_diagnosis_tstz,
                                                          phd.id_episode) desc_speciality,
                         pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                         g_doc_area_past_med id_doc_area,
                         decode(phd.flg_status,
                                pk_alert_constant.g_cancelled,
                                pk_alert_constant.g_cancelled,
                                nvl2(phd.id_pat_history_diagnosis_new, pk_alert_constant.g_outdated, g_active)) flg_status,
                         pk_date_utils.date_char_tsz(i_lang,
                                                     phd.dt_pat_history_diagnosis_tstz,
                                                     i_prof.institution,
                                                     i_prof.software) dt_register_chr,
                         phd.id_professional,
                         -- when there are notes, there is only one phd at a time (migration from the RD's)
                         -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                         --   the need to group according to different timezones                           
                         --RD not used anymore because of multiple notes/edit notes, only available on the detail  
                         NULL notes,
                         -- one phd is enough, since they all have similar dates.
                         -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                         --   the need to group according to different timezones
                         
                         (SELECT phd1.id_pat_history_diagnosis
                             FROM pat_history_diagnosis phd1
                            WHERE -- it is necessary to use pk_date_utils.date_char_tsz to group different requests on the same date (inserts and edits)
                            phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = g_alert_diag_type_med
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis,
                         
                         pk_alert_constant.get_yes flg_detail,
                         pk_alert_constant.get_no flg_external,
                         pk_alert_constant.get_no flg_free_text,
                         get_review_info(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => phd.id_episode,
                                         i_id_record_area => phd.id_pat_history_diagnosis,
                                         i_flg_context    => pk_review.get_past_history_context,
                                         i_id_institution => phd.id_institution) flg_reviewed,
                         e.id_visit
                  FROM pat_history_diagnosis phd
                  JOIN TABLE(l_past_hist_id) tab
                    ON tab.column_value = phd.id_pat_history_diagnosis
                  LEFT JOIN episode e
                    ON e.id_episode = phd.id_episode
                  LEFT JOIN alert_diagnosis_type ad
                    ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                  LEFT JOIN diagnosis d
                    ON ad.id_diagnosis = d.id_diagnosis
                 WHERE phd.flg_area IN
                       (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)
                   AND isphd_outbycancel(i_lang, 'CP', phd.id_pat_history_diagnosis) = 0
                UNION ALL
                SELECT DISTINCT e.id_episode,
                                decode(e.id_episode,
                                       i_current_episode,
                                       pk_alert_constant.get_yes,
                                       pk_alert_constant.get_no) flg_current_episode,
                                pk_prof_utils.get_name_signature(i_lang,
                                                                 i_prof,
                                                                 (SELECT td.id_professional
                                                                    FROM sr_prof_team_det td
                                                                   WHERE td.id_episode = e.id_episode
                                                                     AND td.id_professional = td.id_prof_team_leader
                                                                     AND td.flg_status = g_active
                                                                     AND rownum < 2)) nick_name,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 (SELECT td.id_professional
                                                                    FROM sr_prof_team_det td
                                                                   WHERE td.id_episode = e.id_episode
                                                                     AND td.id_professional = td.id_prof_team_leader
                                                                     AND td.flg_status = g_active
                                                                     AND rownum < 2),
                                                                 e.dt_begin_tstz,
                                                                 e.id_episode) desc_speciality,
                                pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_register,
                                g_doc_area_past_med id_doc_area,
                                g_active flg_status,
                                pk_date_utils.date_char_tsz(i_lang,
                                                            ssr.dt_room_entry_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) dt_register_chr,
                                (SELECT td.id_professional
                                   FROM sr_prof_team_det td
                                  WHERE td.id_episode = e.id_episode
                                    AND td.id_professional = td.id_prof_team_leader
                                    AND td.flg_status = g_active
                                    AND rownum < 2) id_professional,
                                NULL notes,
                                NULL id_pat_history_diagnosis,
                                pk_alert_constant.get_no flg_detail,
                                pk_alert_constant.get_yes flg_external,
                                pk_alert_constant.get_no flg_free_text,
                                '' flg_reviewed,
                                e.id_visit
                  FROM sr_surgery_record ssr
                 INNER JOIN schedule_sr ss
                    ON (ssr.id_schedule_sr = ss.id_schedule_sr)
                 INNER JOIN episode e
                    ON (ss.id_episode = e.id_episode)
                 WHERE ssr.id_patient = l_patient
                   AND (e.id_visit = l_visit OR l_visit IS NULL)
                   AND (e.id_episode = l_episode OR l_episode IS NULL)
                   AND ssr.flg_state IN ('O', 'R', 'F')
                UNION
                SELECT pphfth.id_episode,
                       decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        decode(pphfth.flg_status,
                                                               g_flg_status_cancel_free_text,
                                                               pphfth.id_prof_canceled,
                                                               pphfth.id_professional),
                                                        decode(pphfth.flg_status,
                                                               g_flg_status_cancel_free_text,
                                                               pphfth.dt_cancel,
                                                               pphfth.dt_register),
                                                        pphfth.id_episode) desc_speciality,
                       pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                       g_doc_area_past_med id_doc_area,
                       pphfth.flg_status flg_status,
                       pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                       decode(pphfth.flg_status,
                              g_flg_status_cancel_free_text,
                              pphfth.id_prof_canceled,
                              pphfth.id_professional) id_professional,
                       NULL notes,
                       pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                       pk_alert_constant.get_yes flg_detail,
                       pk_alert_constant.get_no flg_external,
                       pk_alert_constant.get_yes flg_free_text,
                       get_review_info(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_episode        => pphfth.id_episode,
                                       i_id_record_area => pphfth.id_pat_ph_ft,
                                       i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                       pphfth.id_visit
                  FROM pat_past_hist_ft_hist pphfth
                  LEFT JOIN review_detail rd
                    ON pphfth.id_pat_ph_ft_hist = rd.id_record_area
                   AND rd.flg_context = pk_review.get_past_history_ft_context
                   AND pphfth.id_episode = rd.id_episode
                 WHERE pphfth.id_patient = l_patient
                   AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                   AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                   AND pphfth.flg_type = g_alert_diag_type_med
                   AND pphfth.dt_register NOT IN (SELECT *
                                                    FROM TABLE(l_past_hist_dt))
                   AND isphd_outbycancel(i_lang, 'FT', pphfth.id_pat_ph_ft_hist) = 0
                 ORDER BY dt_register DESC;
        
        ELSE
            l_config_transfer_status := pk_sysconfig.get_config('TRANSFER_PMH_TO_FINAL_DIAG', i_prof);
        END IF;
    
        ---
        -- per episode/patient
        ---
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.dt_pat_history_diagnosis_tstz,
                   aux.flg_external,
                   aux.id_pat_history_diagnosis,
                   aux.desc_past_hist_short,
                   aux.id_professional,
                   aux.code_icd,
                   aux.flg_other,
                   aux.rank,
                   aux.status_diagnosis,
                   aux.icon_status,
                   aux.avail_for_select,
                   aux.default_new_status,
                   aux.default_new_status_desc,
                   aux.id_alert_diagnosis,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_free_text
              FROM (SELECT /*+ opt_estimate(table tab rows=10) push_pred(d) */
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     decode(phd.id_alert_diagnosis,
                            g_diag_none,
                            pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_none, i_lang),
                            decode(phd.id_alert_diagnosis,
                                   g_diag_unknown,
                                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                           g_pat_hist_diag_unknown,
                                                           i_lang),
                                   decode(phd.id_alert_diagnosis,
                                          g_diag_non_remark,
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  g_pat_hist_diag_non_remark,
                                                                  i_lang),
                                          
                                          decode(phd.desc_pat_history_diagnosis,
                                                 NULL,
                                                 decode(i_flg_diag_call,
                                                        pk_alert_constant.g_yes,
                                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                   i_prof               => i_prof,
                                                                                   i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                                   i_id_diagnosis       => d.id_diagnosis,
                                                                                   i_id_task_type       => pk_alert_constant.g_task_medical_history,
                                                                                   i_code               => d.code_icd,
                                                                                   i_flg_other          => d.flg_other,
                                                                                   i_flg_std_diag       => ad.flg_icd9),
                                                        ''),
                                                 phd.desc_pat_history_diagnosis)))) desc_past_hist,
                     -- desc
                     -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                     get_desc_past_hist_all(i_lang,
                                            i_prof,
                                            phd.id_alert_diagnosis,
                                            phd.desc_pat_history_diagnosis,
                                            d.code_icd,
                                            d.flg_other,
                                            ad.flg_icd9,
                                            phd.flg_status,
                                            phd.flg_compl,
                                            phd.flg_nature,
                                            phd.dt_diagnosed,
                                            phd.dt_diagnosed_precision,
                                            l_doc_area,
                                            phd.id_family_relationship) ||
                     nvl2(phd.notes,
                          ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                          nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '')) desc_past_hist_all,
                     nvl2(phd.id_pat_history_diagnosis_new, pk_alert_constant.g_cancelled, phd.flg_status) flg_status,
                     phd.id_pat_history_diagnosis_new,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                     -- check if it is the current episode
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     -- when importing from the final diagnosis, return the id_diagnosis
                     decode(i_flg_diag_call, pk_alert_constant.get_yes, phd.id_diagnosis, phd.id_alert_diagnosis) id_diagnosis,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     --decode(phd.id_pat_history_diagnosis_new, NULL, pk_alert_constant.get_no, pk_alert_constant.get_yes) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.dt_pat_history_diagnosis_tstz,
                     pk_alert_constant.get_no flg_external,
                     phd.id_pat_history_diagnosis,
                     NULL desc_past_hist_short,
                     phd.id_professional,
                     d.code_icd,
                     d.flg_other,
                     NULL rank,
                     NULL status_diagnosis,
                     NULL icon_status,
                     pk_alert_constant.get_yes avail_for_select,
                     NULL default_new_status,
                     NULL default_new_status_desc,
                     ad.id_alert_diagnosis,
                     phd.dt_pat_history_diagnosis_tstz AS dt_pat_history_diagnosis_rep,
                     pk_alert_constant.get_no flg_free_text
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis_type ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                      LEFT JOIN diagnosis d
                        ON ad.id_diagnosis = d.id_diagnosis
                      LEFT JOIN episode e
                        ON e.id_episode = phd.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max,
                     (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient
                               AND phd.id_professional = i_prof.id) phd_max_prof
                     WHERE phd.flg_area IN
                           (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)
                    UNION ALL
                    
                    SELECT e.id_episode,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                       i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang,
                                                            i_prof,
                                                            nvl(ed.id_prof_confirmed, ed.id_professional_diag)) nick_name,
                           decode(ed.desc_epis_diagnosis, NULL, '', ed.desc_epis_diagnosis || ' - ') ||
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_id_task_type        => pk_alert_constant.g_task_medical_history,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_past_hist,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_id_task_type        => pk_alert_constant.g_task_medical_history,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_past_hist_all,
                           NULL flg_status,
                           NULL id_pat_history_diagnosis_new,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(ed.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           decode(nvl(ed.id_prof_confirmed, ed.id_professional_diag),
                                  i_prof.id,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_professional,
                           'Y' flg_last_record,
                           'Y' flg_last_record_prof,
                           d.id_diagnosis,
                           'N' flg_outdated,
                           'N' flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           NULL desc_flg_status,
                           NULL dt_register_order,
                           nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz) dt_pat_history_diagnosis_tstz,
                           pk_alert_constant.get_yes flg_external,
                           NULL id_pat_history_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_id_task_type        => pk_alert_constant.g_task_medical_history,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis,
                                                      i_flg_past_hist       => pk_alert_constant.g_yes) desc_past_hist_short,
                           nvl(ed.id_prof_confirmed, ed.id_professional_diag) id_professional,
                           d.code_icd,
                           d.flg_other,
                           pk_sysdomain.get_rank(i_lang, l_code_dom_ed_flg_status, ed.flg_status) rank,
                           ed.flg_status status_diagnosis,
                           pk_sysdomain.get_img(i_lang, l_code_dom_ed_flg_status, ed.flg_status) icon_status,
                           pk_alert_constant.get_yes avail_for_select,
                           ed.flg_status default_new_status,
                           pk_sysdomain.get_domain(l_code_dom_ed_flg_status, ed.flg_status, i_lang) default_new_status_desc,
                           ed.id_alert_diagnosis,
                           NULL dt_pat_history_diagnosis_rep,
                           pk_alert_constant.get_no flg_free_text
                      FROM diagnosis d
                     INNER JOIN epis_diagnosis ed
                        ON (d.id_diagnosis = ed.id_diagnosis)
                     INNER JOIN episode e
                        ON (e.id_episode = ed.id_episode)
                      LEFT OUTER JOIN alert_diagnosis_type ad
                        ON (ed.id_alert_diagnosis = ad.id_alert_diagnosis)
                     WHERE e.id_patient = l_patient
                       AND (e.id_visit = l_visit OR l_visit IS NULL)
                       AND (e.id_episode = l_episode OR l_episode IS NULL)
                       AND ed.flg_type IN (pk_diagnosis.g_flg_type_disch)
                       AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_d)
                          --ALERT-75000: A final diagnosis in current episode cannot be considered at same time a medical history of same episode
                       AND (ed.id_episode != i_current_episode OR i_current_episode IS NULL)
                       AND i_flg_diag_call = pk_alert_constant.g_yes
                    
                    UNION ALL
                    
                    SELECT e.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang,
                                                            i_prof,
                                                            (SELECT td.id_professional
                                                               FROM sr_prof_team_det td
                                                              WHERE td.id_episode = e.id_episode
                                                                AND td.id_professional = td.id_prof_team_leader
                                                                AND td.flg_status = g_active
                                                                AND rownum < 2)) nick_name,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                    e.id_episode,
                                                                    i_prof,
                                                                    pk_alert_constant.get_no) desc_past_hist,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                    e.id_episode,
                                                                    i_prof,
                                                                    pk_alert_constant.get_no) || ' (' || l_surgery || ', ' ||
                           pk_date_utils.dt_chr_tsz(i_lang, ssr.dt_room_entry_tstz, i_prof.institution, i_prof.software) || ')' desc_past_hist_all,
                           NULL flg_status,
                           NULL id_pat_history_diagnosis_new,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(e.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           decode(i_prof.id, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           'Y' flg_last_record,
                           'Y' flg_last_record_prof,
                           NULL id_diagnosis,
                           'N' flg_outdated,
                           'N' flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ssr.dt_room_entry_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           NULL desc_flg_status,
                           NULL dt_register_order,
                           ssr.dt_room_entry_tstz dt_pat_history_diagnosis_tstz,
                           pk_alert_constant.get_yes flg_external,
                           NULL id_pat_history_diagnosis,
                           NULL desc_past_hist_short,
                           (SELECT td.id_professional
                              FROM sr_prof_team_det td
                             WHERE td.id_episode = e.id_episode
                               AND td.id_professional = td.id_prof_team_leader
                               AND td.flg_status = g_active
                               AND rownum < 2) id_professional,
                           NULL code_icd,
                           NULL flg_other,
                           NULL rank,
                           NULL status_diagnosis,
                           NULL icon_status,
                           NULL avail_for_select,
                           NULL default_new_status,
                           NULL default_new_status_desc,
                           NULL id_alert_diagnosis,
                           NULL dt_pat_history_diagnosis_rep,
                           pk_alert_constant.get_no flg_free_text
                      FROM sr_surgery_record ssr
                     INNER JOIN schedule_sr ss
                        ON (ssr.id_schedule_sr = ss.id_schedule_sr)
                     INNER JOIN episode e
                        ON (ss.id_episode = e.id_episode)
                     WHERE e.id_patient = l_patient
                       AND (e.id_visit = l_visit OR l_visit IS NULL)
                       AND (e.id_episode = l_episode OR l_episode IS NULL)
                       AND ssr.flg_state IN ('O', 'R', 'F')
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL id_pat_history_diagnosis_new,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           NULL dt_pat_history_diagnosis_tstz,
                           pk_alert_constant.get_no flg_external,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_short,
                           pphfth.id_professional,
                           NULL code_icd,
                           NULL flg_other,
                           NULL rank,
                           NULL status_diagnosis,
                           NULL icon_status,
                           pk_alert_constant.get_yes avail_for_select,
                           NULL default_new_status,
                           NULL default_new_status_desc,
                           NULL id_alert_diagnosis,
                           pphfth.dt_register AS dt_pat_history_diagnosis_rep,
                           pk_alert_constant.get_yes flg_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = g_alert_diag_type_med
                       AND i_flg_diag_call = pk_alert_constant.get_no) aux
             WHERE i_flg_diag_call = pk_alert_constant.get_no --
                OR (i_flg_diag_call = pk_alert_constant.g_yes AND aux.id_diagnosis IS NOT NULL AND
                   instr(l_config_transfer_status, flg_status) > 0 AND NOT EXISTS
                    (SELECT 1
                       FROM epis_diagnosis ed
                      WHERE ed.id_episode = i_current_episode
                        AND ed.id_diagnosis = aux.id_diagnosis
                        AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_d)))
             ORDER BY flg_current_episode DESC, dt_register_order DESC, flg_status ASC, desc_past_hist ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_MEDICAL',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_medical;

    FUNCTION get_past_hist_surgical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_patient         patient.id_patient%TYPE;
        l_visit           visit.id_visit%TYPE;
        l_episode         episode.id_episode%TYPE;
        l_doc_area        doc_area.id_doc_area%TYPE;
    
        l_episodes_visit table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt         table_timestamp_tstz;
        l_past_hist_id         table_number;
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    BEGIN
        l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_surg);
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_surgical_history);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_diagnosis(g_alert_diag_type_surg,
                                           l_patient,
                                           l_episode,
                                           l_visit,
                                           i_scope_type,
                                           l_episodes_visit,
                                           pk_alert_constant.g_task_surgical_history,
                                           pk_alert_constant.g_no,
                                           l_past_hist_id,
                                           l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT /*+opt_estimate(table tab rows=10)*/
            DISTINCT phd.id_episode,
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode) desc_speciality,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     g_doc_area_past_surg id_doc_area,
                     -- jsilva 14-01-2008 flg_status to be used in the integrated history
                     decode(phd.flg_status,
                            pk_alert_constant.g_cancelled,
                            pk_alert_constant.g_cancelled,
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)) flg_status,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     phd.id_professional,
                     -- when there are notes, there is only one phd at a time (migration from the RD's)
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     --RD not used anymore because of multiple notes/edit notes, only available on the detail        
                     NULL notes,
                     -- one phd is enough, since they all have similar dates
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     (SELECT phd1.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd1
                       WHERE phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = g_alert_diag_type_surg
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                             decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis,
                     pk_alert_constant.get_yes flg_detail,
                     pk_alert_constant.get_no flg_external,
                     pk_alert_constant.get_no flg_free_text,
                     get_review_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => phd.id_episode,
                                     i_id_record_area => phd.id_pat_history_diagnosis,
                                     i_flg_context    => pk_review.get_past_history_context,
                                     i_id_institution => phd.id_institution) flg_reviewed,
                     e.id_visit
              FROM pat_history_diagnosis phd
              JOIN TABLE(l_past_hist_id) tab
                ON tab.column_value = phd.id_pat_history_diagnosis
              LEFT JOIN alert_diagnosis_type ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON ad.id_diagnosis = d.id_diagnosis
              LEFT JOIN episode e
                ON phd.id_episode = e.id_episode
              LEFT JOIN review_detail rd
                ON phd.id_pat_history_diagnosis = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_context
               AND phd.id_episode = rd.id_episode
               AND ad.id_task_type = pk_alert_constant.g_task_surgical_history
               AND isphd_outbycancel(i_lang, 'CP', phd.id_pat_history_diagnosis) = 0
            UNION
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(pphfth.flg_status,
                                                           g_flg_status_cancel_free_text,
                                                           pphfth.id_prof_canceled,
                                                           pphfth.id_professional),
                                                    decode(pphfth.flg_status,
                                                           g_flg_status_cancel_free_text,
                                                           pphfth.dt_cancel,
                                                           pphfth.dt_register),
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   g_doc_area_past_med id_doc_area,
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   decode(pphfth.flg_status,
                          g_flg_status_cancel_free_text,
                          pphfth.id_prof_canceled,
                          pphfth.id_professional) id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   get_review_info(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => pphfth.id_episode,
                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
              LEFT JOIN review_detail rd
                ON pphfth.id_pat_ph_ft_hist = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND pphfth.id_episode = rd.id_episode
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.flg_type = g_alert_diag_type_surg
               AND pphfth.dt_register NOT IN (SELECT *
                                                FROM TABLE(l_past_hist_dt))
               AND isphd_outbycancel(i_lang               => i_lang,
                                     i_enter_mode         => 'FT',
                                     i_pat_hist_diagnosis => pphfth.id_pat_ph_ft_hist) = 0
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text
              FROM (SELECT /*+ opt_estimate(table tab rows=10) push_pred(d) */
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ') ||
                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                i_id_diagnosis       => d.id_diagnosis,
                                                i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                i_code               => d.code_icd,
                                                i_flg_other          => d.flg_other,
                                                i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                     -- desc
                     -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                     get_desc_past_hist_all(i_lang,
                                            i_prof,
                                            phd.id_alert_diagnosis,
                                            phd.desc_pat_history_diagnosis,
                                            d.code_icd,
                                            d.flg_other,
                                            ad.flg_icd9,
                                            phd.flg_status,
                                            phd.flg_compl,
                                            phd.flg_nature,
                                            phd.dt_diagnosed,
                                            phd.dt_diagnosed_precision,
                                            l_doc_area,
                                            phd.id_family_relationship) ||
                     nvl2(phd.notes,
                          ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                          nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '')) desc_past_hist_all,
                     phd.flg_status,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_compl flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) desc_nature,
                     -- check if it is the current episode
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     phd.id_alert_diagnosis id_diagnosis,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang /*)*/)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.id_pat_history_diagnosis,
                     phd.id_professional,
                     phd.dt_pat_history_diagnosis_tstz,
                     phd.dt_pat_history_diagnosis_tstz AS dt_pat_history_diagnosis_rep,
                     d.flg_other,
                     pk_alert_constant.get_no flg_free_text
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis_type ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                      LEFT JOIN diagnosis d
                        ON ad.id_diagnosis = d.id_diagnosis
                      LEFT JOIN episode e
                        ON phd.id_episode = e.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_professional = i_prof.id
                               AND phd.id_patient = l_patient) phd_max_prof
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           decode(pphfth.flg_status, g_flg_status_cancel_free_text, pphfth.dt_cancel, pphfth.dt_register) dt_pat_history_diagnosis_tstz,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = g_alert_diag_type_surg) aux
             ORDER BY decode(aux.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) DESC,
                      dt_register_order DESC,
                      flg_status ASC,
                      desc_past_hist ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_surgical',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_surgical;
    --

    /********************************************************************************************
    * Get Past History Surgical procedures
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_id_context        Identifier of the Episode/Patient/Visit based on the i_flg_type_context
    * @param i_flg_type_context  Flag to filter by Episode (E), by Visit (V) or by Patient (P)
    * @param o_doc_area          Data cursor
    * @param o_error             Error Message
    *
    * @return                    TRUE/FALSE
    *     
    * @author                    António Neto
    * @version                   2.6.1
    * @since                     2011-05-04
    *
    *********************************************************************************************/
    FUNCTION get_past_hist_surgical_api
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_context       IN NUMBER,
        i_flg_type_context IN VARCHAR2,
        o_doc_area         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_patient         patient.id_patient%TYPE;
        l_visit           visit.id_visit%TYPE;
        l_episode         episode.id_episode%TYPE;
        l_doc_area        doc_area.id_doc_area%TYPE;
    
        l_episodes_visit table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt table_timestamp_tstz;
        l_past_hist_id table_number;
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    BEGIN
    
        l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_surg);
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_surgical_history);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_context,
                                              i_scope_type => i_flg_type_context,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_diagnosis(g_alert_diag_type_surg,
                                           l_patient,
                                           l_episode,
                                           l_visit,
                                           i_flg_type_context,
                                           l_episodes_visit,
                                           pk_alert_constant.g_task_surgical_history,
                                           pk_alert_constant.g_no,
                                           l_past_hist_id,
                                           l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA';
        OPEN o_doc_area FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_speciality,
                   aux.id_doc_area,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.flg_status_new,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_pat_history_diagnosis_new,
                   aux.id_professional,
                   aux.id_professional_new,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text,
                   aux.flg_detail,
                   aux.flg_external,
                   aux.epis_flg_status,
                   aux.code_icd,
                   aux.flg_coding,
                   aux.sr_epis_flg_status,
                   aux.dt_sr_start_date,
                   NULL dt_sr_end_date,
                   aux.sr_start_date,
                   aux.sr_start_date_str,
                   NULL sr_end_date,
                   NULL sr_end_date_str,
                   nvl(aux.sr_surg_desc, aux.desc_past_hist) sr_surg_desc,
                   aux.sr_epis_flg_status_str,
                   id_content id_content
              FROM (SELECT /*+opt_estimate(table tab rows=10)*/
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode) desc_speciality,
                     g_doc_area_past_surg id_doc_area,
                     decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ') ||
                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                i_id_diagnosis       => d.id_diagnosis,
                                                i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                i_code               => d.code_icd,
                                                i_flg_other          => d.flg_other,
                                                i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                     -- desc
                     -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                     get_desc_past_hist_all(i_lang,
                                            i_prof,
                                            phd.id_alert_diagnosis,
                                            phd.desc_pat_history_diagnosis,
                                            d.code_icd,
                                            d.flg_other,
                                            ad.flg_icd9,
                                            phd.flg_status,
                                            phd.flg_compl,
                                            phd.flg_nature,
                                            phd.dt_diagnosed,
                                            phd.dt_diagnosed_precision,
                                            l_doc_area,
                                            phd.id_family_relationship) ||
                     nvl2(phd.notes,
                          ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                          nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '')) desc_past_hist_all,
                     phd.flg_status,
                     decode(phd.flg_status,
                            pk_alert_constant.g_cancelled,
                            pk_alert_constant.g_cancelled,
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)) flg_status_new,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_compl flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang) desc_nature,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     phd.id_alert_diagnosis id_diagnosis,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang /*)*/)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.id_pat_history_diagnosis,
                     (SELECT phd1.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd1
                       WHERE phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = g_alert_diag_type_surg
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                             decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis_new,
                     phd.id_professional,
                     NULL id_professional_new,
                     phd.dt_pat_history_diagnosis_tstz,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) AS dt_pat_history_diagnosis_rep,
                     d.flg_other,
                     pk_alert_constant.get_yes flg_detail,
                     pk_alert_constant.get_no flg_external,
                     pk_alert_constant.get_no flg_free_text,
                     e.flg_status epis_flg_status,
                     d.code_icd code_icd,
                     d.flg_type flg_coding,
                     phd.flg_status sr_epis_flg_status,
                     CASE
                          WHEN phd.dt_resolved_precision IS NOT NULL
                               AND phd.dt_resolved_precision <> pk_problems.g_unknown THEN
                           phd.dt_diagnosed
                          ELSE
                           NULL
                      END dt_sr_start_date,
                     CASE
                          WHEN phd.dt_resolved_precision IS NOT NULL
                               AND phd.dt_resolved_precision <> pk_problems.g_unknown THEN
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_diagnosed, i_prof)
                          ELSE
                           NULL
                      END sr_start_date_str,
                     CASE
                          WHEN phd.dt_resolved_precision IS NOT NULL
                               AND phd.dt_resolved_precision <> pk_problems.g_unknown THEN
                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_date      => phd.dt_diagnosed,
                                                                   i_precision => phd.dt_diagnosed_precision)
                          ELSE
                           NULL
                      END sr_start_date,
                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                i_id_diagnosis       => d.id_diagnosis,
                                                i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                                i_code               => d.code_icd,
                                                i_flg_other          => d.flg_other,
                                                i_flg_std_diag       => ad.flg_icd9) sr_surg_desc,
                     pk_sysdomain.get_domain(g_phd_flg_status, phd.flg_status, i_lang) sr_epis_flg_status_str,
                     coalesce(d.id_content, ad.id_content) id_content
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis_type ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                      LEFT JOIN diagnosis d
                        ON ad.id_diagnosis = d.id_diagnosis
                      LEFT JOIN episode e
                        ON phd.id_episode = e.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_professional = i_prof.id
                               AND phd.id_patient = l_patient) phd_max_prof
                     WHERE phd.flg_status <> pk_alert_constant.g_cancelled
                       AND phd.id_pat_history_diagnosis_new IS NULL
                       AND ad.id_task_type = pk_alert_constant.g_task_surgical_history
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            decode(pphfth.flg_status,
                                                                   g_flg_status_cancel_free_text,
                                                                   pphfth.id_prof_canceled,
                                                                   pphfth.id_professional),
                                                            decode(pphfth.flg_status,
                                                                   g_flg_status_cancel_free_text,
                                                                   pphfth.dt_cancel,
                                                                   pphfth.dt_register),
                                                            pphfth.id_episode) desc_speciality,
                           g_doc_area_past_med id_doc_area,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           pphfth.flg_status flg_status_new,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           NULL id_pat_history_diagnosis_new,
                           pphfth.id_professional,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pphfth.id_prof_canceled,
                                  pphfth.id_professional) id_professional_new,
                           decode(pphfth.flg_status, g_flg_status_cancel_free_text, pphfth.dt_cancel, pphfth.dt_register) dt_pat_history_diagnosis_tstz,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_detail,
                           pk_alert_constant.get_no flg_external,
                           pk_alert_constant.get_yes flg_free_text,
                           epis.flg_status epis_flg_status,
                           NULL code_icd,
                           NULL flg_coding,
                           pphfth.flg_status sr_epis_flg_status,
                           pphfth.dt_register dt_sr_start_date,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software),
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) sr_start_date_str,
                           NULL sr_surg_desc,
                           pk_sysdomain.get_domain(g_phd_flg_status, pphfth.flg_status, i_lang) sr_epis_flg_status_str,
                           NULL id_content
                      FROM pat_past_hist_ft_hist pphfth
                     INNER JOIN episode epis
                        ON pphfth.id_episode = epis.id_episode
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = g_alert_diag_type_surg
                       AND pphfth.flg_status = pk_alert_constant.g_active) aux
            
             ORDER BY dt_register_order DESC, flg_status ASC, desc_past_hist ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SURGICAL_API',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area);
            RETURN FALSE;
    END get_past_hist_surgical_api;

    FUNCTION get_past_hist_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_diag_type         IN VARCHAR2,
        i_task_type         IN NUMBER,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_patient         patient.id_patient%TYPE;
        l_visit           visit.id_visit%TYPE;
        l_episode         episode.id_episode%TYPE;
        l_doc_area        doc_area.id_doc_area%TYPE;
    
        l_episodes_visit table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt table_timestamp_tstz;
        l_past_hist_id table_number;
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    
    BEGIN
    
        l_doc_area := prv_conv_flg_type_to_doc_area(i_diag_type);
        --   pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_congenital_anomalies);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_diagnosis(i_diag_type,
                                           l_patient,
                                           l_episode,
                                           l_visit,
                                           i_scope_type,
                                           l_episodes_visit,
                                           i_task_type,
                                           pk_alert_constant.g_no,
                                           l_past_hist_id,
                                           l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT /*+opt_estimate(table tab rows=10)*/
            DISTINCT phd.id_episode,
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode) desc_speciality,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     g_doc_area_cong_anom id_doc_area,
                     -- jsilva 14-01-2008 flg_status to be used in the integrated history
                     decode(phd.flg_status,
                            pk_alert_constant.g_cancelled,
                            pk_alert_constant.g_cancelled,
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)) flg_status,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     phd.id_professional,
                     -- when there are notes, there is only one phd at a time (migration from the RD's)
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     --RD not used anymore because of multiple notes/edit notes, only available on the detail        
                     NULL notes,
                     -- one phd is enough, since they all have similar dates
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     (SELECT phd1.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd1
                       WHERE phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = i_diag_type
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                             decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis,
                     pk_alert_constant.get_yes flg_detail,
                     pk_alert_constant.get_no flg_external,
                     pk_alert_constant.get_no flg_free_text,
                     get_review_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => phd.id_episode,
                                     i_id_record_area => phd.id_pat_history_diagnosis,
                                     i_flg_context    => pk_review.get_past_history_context,
                                     i_id_institution => phd.id_institution) flg_reviewed,
                     e.id_visit
              FROM pat_history_diagnosis phd
              JOIN TABLE(l_past_hist_id) tab
                ON tab.column_value = phd.id_pat_history_diagnosis
              LEFT JOIN alert_diagnosis_type ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND ad.id_task_type = i_task_type --pk_alert_constant.g_task_congenital_anomalies
              LEFT JOIN diagnosis d
                ON ad.id_diagnosis = d.id_diagnosis
              LEFT JOIN episode e
                ON phd.id_episode = e.id_episode
              LEFT JOIN review_detail rd
                ON phd.id_pat_history_diagnosis = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_context
               AND phd.id_episode = rd.id_episode
               AND isphd_outbycancel(i_lang, 'CP', phd.id_pat_history_diagnosis) = 0
            UNION
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pphfth.id_professional,
                                                    pphfth.dt_register,
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   g_doc_area_past_med id_doc_area,
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   pphfth.id_professional id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   get_review_info(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => pphfth.id_episode,
                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
              LEFT JOIN review_detail rd
                ON pphfth.id_pat_ph_ft_hist = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND pphfth.id_episode = rd.id_episode
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.flg_type = i_diag_type --g_alert_diag_type_cong_anom
               AND pphfth.dt_register NOT IN (SELECT *
                                                FROM TABLE(l_past_hist_dt))
               AND isphd_outbycancel(i_lang, 'FT', pphfth.id_pat_ph_ft_hist) = 0
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text
              FROM (SELECT /*+ opt_estimate(table tab rows=10) push_pred(d) */
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                i_id_diagnosis       => d.id_diagnosis,
                                                i_id_task_type       => pk_alert_constant.g_task_congenital_anomalies,
                                                i_code               => d.code_icd,
                                                i_flg_other          => d.flg_other,
                                                i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                     -- desc
                     -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                     get_desc_past_hist_all(i_lang,
                                            i_prof,
                                            phd.id_alert_diagnosis,
                                            phd.desc_pat_history_diagnosis,
                                            d.code_icd,
                                            d.flg_other,
                                            ad.flg_icd9,
                                            phd.flg_status,
                                            phd.flg_compl,
                                            phd.flg_nature,
                                            phd.dt_diagnosed,
                                            phd.dt_diagnosed_precision,
                                            l_doc_area,
                                            phd.id_family_relationship) ||
                     nvl2(phd.notes,
                          ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                          nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '')) desc_past_hist_all,
                     phd.flg_status,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                     -- check if it is the current episode
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     phd.id_alert_diagnosis id_diagnosis,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.id_pat_history_diagnosis,
                     phd.id_professional,
                     phd.dt_pat_history_diagnosis_tstz AS dt_pat_history_diagnosis_rep,
                     d.flg_other,
                     pk_alert_constant.get_no flg_free_text
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis_type ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                       AND ad.id_task_type = i_task_type --pk_alert_constant.g_task_congenital_anomalies
                      LEFT JOIN diagnosis d
                        ON ad.id_diagnosis = d.id_diagnosis
                      LEFT JOIN episode e
                        ON phd.id_episode = e.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max,
                     (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient
                               AND phd.id_professional = i_prof.id) phd_max_prof
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = i_diag_type --g_alert_diag_type_cong_anom
                    ) aux
             ORDER BY decode(aux.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) DESC,
                      dt_register_order DESC,
                      flg_status ASC,
                      desc_past_hist ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_diag',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_diag;

    FUNCTION get_past_hist_cong_anom
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
    
    BEGIN
    
        --  l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_cong_anom);
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_congenital_anomalies);
        IF NOT get_past_hist_diag(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_current_episode   => i_current_episode,
                                  i_scope             => i_scope,
                                  i_scope_type        => i_scope_type,
                                  i_diag_type         => g_alert_diag_type_cong_anom,
                                  i_task_type         => pk_alert_constant.g_task_congenital_anomalies,
                                  o_doc_area_register => o_doc_area_register,
                                  o_doc_area_val      => o_doc_area_val,
                                  o_error             => o_error)
        THEN
        
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_cong_anom',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_cong_anom;

    FUNCTION get_past_hist_gyn
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
    
    BEGIN
    
        --  l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_cong_anom);
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_gynecology_history);
        IF NOT get_past_hist_diag(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_current_episode   => i_current_episode,
                                  i_scope             => i_scope,
                                  i_scope_type        => i_scope_type,
                                  i_diag_type         => g_alert_diag_type_gyneco,
                                  i_task_type         => pk_alert_constant.g_task_gynecology_history,
                                  o_doc_area_register => o_doc_area_register,
                                  o_doc_area_val      => o_doc_area_val,
                                  o_error             => o_error)
        THEN
        
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_GYN',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_gyn;

    FUNCTION get_past_hist_family
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_fam_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_patient         patient.id_patient%TYPE;
        l_visit           visit.id_visit%TYPE;
        l_episode         episode.id_episode%TYPE;
        l_doc_area        doc_area.id_doc_area%TYPE;
    
        l_episodes_visit table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt table_timestamp_tstz;
        l_past_hist_id table_number;
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    
    BEGIN
    
        l_doc_area := prv_conv_flg_type_to_doc_area(g_alert_diag_type_family);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_diagnosis(g_alert_diag_type_family,
                                           l_patient,
                                           l_episode,
                                           l_visit,
                                           i_scope_type,
                                           l_episodes_visit,
                                           pk_alert_constant.g_task_medical_history,
                                           pk_alert_constant.g_no,
                                           l_past_hist_id,
                                           l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA_REGISTER';
    
        --Set the parameter id_task_type to be used in the view alert_diagnosis_type     
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, pk_alert_constant.g_task_medical_history);
    
        OPEN o_doc_area_register FOR
            SELECT /*+opt_estimate(table tab rows=10)*/
            DISTINCT phd.id_episode,
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode) desc_speciality,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     g_doc_area_past_fam id_doc_area,
                     -- jsilva 14-01-2008 flg_status to be used in the integrated history
                     decode(phd.flg_status,
                            pk_alert_constant.g_cancelled,
                            pk_alert_constant.g_cancelled,
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)) flg_status,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     phd.id_professional,
                     -- when there are notes, there is only one phd at a time (migration from the RD's)
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     --RD not used anymore because of multiple notes/edit notes, only available on the detail        
                     NULL notes,
                     -- one phd is enough, since they all have similar dates
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     (SELECT phd1.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd1
                       WHERE phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = g_alert_diag_type_family
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                             decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis,
                     pk_alert_constant.get_yes flg_detail,
                     pk_alert_constant.get_no flg_external,
                     pk_alert_constant.get_no flg_free_text,
                     get_review_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => phd.id_episode,
                                     i_id_record_area => phd.id_pat_history_diagnosis,
                                     i_flg_context    => pk_review.get_past_history_context,
                                     i_id_institution => phd.id_institution) flg_reviewed,
                     e.id_visit
              FROM pat_history_diagnosis phd
              JOIN TABLE(l_past_hist_id) tab
                ON tab.column_value = phd.id_pat_history_diagnosis
              LEFT JOIN alert_diagnosis_type ad
                ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON ad.id_diagnosis = d.id_diagnosis
              LEFT JOIN episode e
                ON phd.id_episode = e.id_episode
              LEFT JOIN review_detail rd
                ON phd.id_pat_history_diagnosis = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_context
               AND phd.id_episode = rd.id_episode
               AND isphd_outbycancel(i_lang, 'CP', phd.id_pat_history_diagnosis) = 0
            UNION
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pphfth.id_professional,
                                                    pphfth.dt_register,
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   pphfth.id_doc_area id_doc_area, -- EMR-266
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   pphfth.id_professional id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   get_review_info(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => pphfth.id_episode,
                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
              LEFT JOIN review_detail rd
                ON pphfth.id_pat_ph_ft_hist = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND pphfth.id_episode = rd.id_episode
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.flg_type = g_alert_diag_type_others
               AND pphfth.id_doc_area = g_doc_area_past_fam -- EMR-266
               AND pphfth.dt_register NOT IN (SELECT *
                                                FROM TABLE(l_past_hist_dt))
               AND isphd_outbycancel(i_lang, 'FT', pphfth.id_pat_ph_ft_hist) = 0
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text,
                   aux.id_family_relationship,
                   aux.desc_family_relationship,
                   aux.flg_death_cause,
                   aux.desc_death_cause,
                   aux.familiar_age,
                   aux.desc_familiar_age
              FROM (SELECT /*+ opt_estimate(table tab rows=10) push_pred(d) */
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                i_id_diagnosis       => d.id_diagnosis,
                                                i_id_task_type       => pk_alert_constant.g_task_medical_history,
                                                i_code               => d.code_icd,
                                                i_flg_other          => d.flg_other,
                                                i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                     -- desc
                     -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                     get_desc_past_hist_all(i_lang,
                                            i_prof,
                                            phd.id_alert_diagnosis,
                                            phd.desc_pat_history_diagnosis,
                                            d.code_icd,
                                            d.flg_other,
                                            ad.flg_icd9,
                                            phd.flg_status,
                                            phd.flg_compl,
                                            phd.flg_nature,
                                            phd.dt_diagnosed,
                                            phd.dt_diagnosed_precision,
                                            l_doc_area,
                                            phd.id_family_relationship) ||
                     
                     nvl2(phd.notes,
                          ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                          nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '')) desc_past_hist_all,
                     phd.flg_status,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                     -- check if it is the current episode
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     phd.id_alert_diagnosis id_diagnosis,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang /*)*/)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.id_pat_history_diagnosis,
                     phd.id_professional,
                     phd.dt_pat_history_diagnosis_tstz AS dt_pat_history_diagnosis_rep,
                     d.flg_other,
                     pk_alert_constant.get_no flg_free_text,
                     id_family_relationship,
                     pk_family.get_family_relationship_desc(i_lang, phd.id_family_relationship) desc_family_relationship,
                     phd.flg_death_cause,
                     pk_sysdomain.get_domain(g_phd_flg_death_cause, phd.flg_nature, i_lang) desc_death_cause,
                     phd.familiar_age,
                     phd.familiar_age desc_familiar_age
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis_type ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                      LEFT JOIN diagnosis d
                        ON ad.id_diagnosis = d.id_diagnosis
                      LEFT JOIN episode e
                        ON phd.id_episode = e.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max,
                     (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient
                               AND phd.id_professional = i_prof.id) phd_max_prof
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_free_text,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = g_alert_diag_type_others) aux
             ORDER BY decode(aux.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) DESC,
                      dt_register_order DESC,
                      flg_status ASC,
                      desc_past_hist ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_FAMMILY',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_family;

    --

    /**
    * 
    *
    * @param   
    *
    * @return  BOOLEAN                 returns converted flag
    *
    * @author  Filipe Machado
    * @version 2.6.1
    * @since   19-Apr-2011
    */
    FUNCTION prv_get_past_hist_treatments
    (
        i_flg_type       IN pat_history_diagnosis.flg_type%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_visit          IN visit.id_visit%TYPE,
        i_scope_type     IN VARCHAR2,
        i_episodes_visit IN table_number,
        o_past_hist_id   OUT table_number,
        o_past_hist_dt   OUT table_timestamp_tstz
    ) RETURN BOOLEAN IS
        l_past_hist_type pat_history_diagnosis.flg_type%TYPE;
    BEGIN
        --Get flag type
        IF i_flg_type IS NOT NULL
        THEN
            l_past_hist_type := i_flg_type;
        ELSE
            --If no type is provided return FALSE
            l_past_hist_type := NULL;
            RETURN FALSE;
        END IF;
    
        --Fetch into table number and date values
        SELECT id_out, dt_tstz_out
          BULK COLLECT
          INTO o_past_hist_id, o_past_hist_dt
          FROM (SELECT phd.id_pat_history_diagnosis id_out, phd.dt_pat_history_diagnosis_tstz dt_tstz_out
                  FROM pat_history_diagnosis phd
                  LEFT JOIN episode e
                    ON e.id_episode = phd.id_episode
                  LEFT JOIN exam exm
                    ON exm.id_exam = phd.id_exam
                  LEFT JOIN intervention itv
                    ON itv.id_intervention = phd.id_intervention
                 WHERE phd.id_patient = i_patient
                   AND (e.id_visit = i_visit OR i_visit IS NULL OR
                       (EXISTS (SELECT 1
                                   FROM review_detail rd
                                  WHERE rd.id_episode IN (SELECT *
                                                            FROM TABLE(i_episodes_visit))
                                    AND rd.id_record_area = phd.id_pat_history_diagnosis)) AND
                       i_scope_type = pk_alert_constant.g_scope_type_visit)
                   AND (e.id_episode = i_episode OR i_episode IS NULL OR
                       (EXISTS (SELECT 1
                                   FROM review_detail rd
                                  WHERE rd.id_episode = i_episode
                                    AND rd.id_record_area = phd.id_pat_history_diagnosis)))
                      
                   AND phd.flg_type = l_past_hist_type);
    
        RETURN TRUE;
    
    END prv_get_past_hist_treatments;

    FUNCTION get_past_hist_treatments
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    
        l_episodes_visit table_number := table_number();
    
        --Past hist diagnosis id and dates
        l_past_hist_dt table_timestamp_tstz;
        l_past_hist_id table_number;
    
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
        e_invalid_argument        EXCEPTION;
    
    BEGIN
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        l_episodes_visit := prv_get_visit_episodes(i_episode => l_episode);
    
        --If prv_get_past_hist_diagnosis fails stop                                               
        IF NOT prv_get_past_hist_treatments(g_alert_type_treatments,
                                            l_patient,
                                            l_episode,
                                            l_visit,
                                            i_scope_type,
                                            l_episodes_visit,
                                            l_past_hist_id,
                                            l_past_hist_dt)
        THEN
            g_error := 'Failed in private function prv_get_past_hist_diagnosis';
            RAISE e_get_past_hist_diagnosis;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA_REGISTER';
    
        OPEN o_doc_area_register FOR
            SELECT /*+opt_estimate(table tab rows=10)*/
            DISTINCT phd.id_episode,
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      phd.id_professional,
                                                      phd.dt_pat_history_diagnosis_tstz,
                                                      phd.id_episode) desc_speciality,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     g_doc_area_treatments id_doc_area,
                     -- jsilva 14-01-2008 flg_status to be used in the integrated history
                     decode(phd.flg_status,
                            pk_alert_constant.g_cancelled,
                            pk_alert_constant.g_cancelled,
                            decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)) flg_status,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     phd.id_professional,
                     -- when there are notes, there is only one phd at a time (migration from the RD's)
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     --RD not used anymore because of multiple notes/edit notes, only available on the detail        
                     NULL notes,
                     -- one phd is enough, since they all have similar dates
                     -- it doesn't need the use of pk_date_utils.trunc_insttimezone, since there is never  
                     --   the need to group according to different timezones
                     (SELECT phd1.id_pat_history_diagnosis
                        FROM pat_history_diagnosis phd1
                       WHERE phd1.dt_pat_history_diagnosis_tstz = phd.dt_pat_history_diagnosis_tstz
                         AND phd1.flg_type = g_alert_type_treatments
                         AND phd1.id_patient = l_patient
                         AND phd1.id_professional = phd.id_professional
                         AND decode(phd1.id_pat_history_diagnosis_new, NULL, g_active, g_outdated) =
                             decode(phd.id_pat_history_diagnosis_new, NULL, g_active, g_outdated)
                         AND rownum = 1) id_pat_history_diagnosis,
                     pk_alert_constant.get_yes flg_detail,
                     pk_alert_constant.get_no flg_external,
                     pk_alert_constant.get_no flg_free_text,
                     get_review_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => phd.id_episode,
                                     i_id_record_area => phd.id_pat_history_diagnosis,
                                     i_flg_context    => pk_review.get_past_history_context,
                                     i_id_institution => phd.id_institution) flg_reviewed,
                     e.id_visit
              FROM pat_history_diagnosis phd
              JOIN TABLE(l_past_hist_id) tab
                ON tab.column_value = phd.id_pat_history_diagnosis
              LEFT JOIN exam exm
                ON exm.id_exam = phd.id_exam
              LEFT JOIN intervention intrv
                ON intrv.id_intervention = phd.id_intervention
              LEFT JOIN episode e
                ON phd.id_episode = e.id_episode
             WHERE isphd_outbycancel(i_lang, 'CP', phd.id_pat_history_diagnosis) = 0
            UNION
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pphfth.id_professional,
                                                    pphfth.dt_register,
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   g_doc_area_past_med id_doc_area,
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   pphfth.id_professional id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   get_review_info(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => pphfth.id_episode,
                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
              LEFT JOIN review_detail rd
                ON pphfth.id_pat_ph_ft_hist = rd.id_record_area
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND pphfth.id_episode = rd.id_episode
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.flg_type = g_alert_type_treatments
               AND pphfth.dt_register NOT IN (SELECT *
                                                FROM TABLE(l_past_hist_dt))
               AND isphd_outbycancel(i_lang, 'FT', pphfth.id_pat_ph_ft_hist) = 0
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_free_text,
                   aux.id_treatment,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.dt_execution,
                   aux.flg_type
              FROM (SELECT /*+opt_estimate(table tab rows=10)*/
                     phd.id_episode,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                     phd.flg_status,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                     phd.flg_nature,
                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang) desc_nature,
                     -- check if it is the current episode
                     decode(phd.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                     -- check if the diagnosis was registered by the current professional
                     decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                     -- check if it is the last record
                     decode(phd_max.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record,
                     -- check if it is the last record by that professional
                     decode(phd_max_prof.max_dt_pat_history_diagnosis,
                            phd.dt_pat_history_diagnosis_tstz,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_last_record_prof,
                     decode(phd.id_pat_history_diagnosis_new,
                            NULL,
                            pk_alert_constant.get_no,
                            (decode(prv_get_ph_diag_recent_all(i_lang,
                                                               phd.id_alert_diagnosis,
                                                               phd.desc_pat_history_diagnosis,
                                                               g_alert_diag_type_surg,
                                                               phd.id_patient),
                                    phd.id_pat_history_diagnosis,
                                    pk_alert_constant.get_no,
                                    pk_alert_constant.get_yes))) flg_outdated,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_alert_constant.get_yes,
                            pk_alert_constant.get_no) flg_canceled,
                     NULL day_begin,
                     NULL month_begin,
                     NULL year_begin,
                     pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_date      => phd.dt_diagnosed,
                                                             i_precision => phd.dt_diagnosed_precision) onset,
                     pk_date_utils.date_char_tsz(i_lang,
                                                 phd.dt_pat_history_diagnosis_tstz,
                                                 i_prof.institution,
                                                 i_prof.software) dt_register_chr,
                     decode(phd.flg_status,
                            g_pat_hist_diag_canceled,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                     pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
                     phd.id_pat_history_diagnosis,
                     phd.id_professional,
                     pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_pat_history_diagnosis_rep,
                     pk_alert_constant.get_no flg_free_text,
                     nvl(phd.id_exam, nvl(phd.id_intervention, phd.id_alert_diagnosis)) id_treatment,
                     nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                         nvl(pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL),
                             prv_ph_diag_not_class_desc(i_lang, phd.id_alert_diagnosis))) desc_past_hist,
                     nvl(prv_ph_diag_not_class_desc(i_lang, phd.id_alert_diagnosis),
                         nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                             pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL)) || ' (' ||
                         pk_sysdomain.get_domain(g_past_hist_treat_type_config,
                                                 nvl(exm.flg_type, g_flg_treatments_proc_search),
                                                 i_lang) ||
                         nvl2(phd.dt_execution,
                              ', ' || get_partial_date_format(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_date      => phd.dt_execution,
                                                              i_precision => phd.dt_execution_precision),
                              '') || ')' || nvl2(nvl(phd.notes, phd.cancel_notes),
                                                 ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                                                 '')) desc_past_hist_all,
                     phd.dt_execution dt_execution,
                     nvl(exm.flg_type, g_flg_treatments_proc_search) flg_type
                      FROM pat_history_diagnosis phd
                      JOIN TABLE(l_past_hist_id) tab
                        ON tab.column_value = phd.id_pat_history_diagnosis
                      LEFT JOIN exam exm
                        ON exm.id_exam = phd.id_exam
                      LEFT JOIN intervention intrv
                        ON intrv.id_intervention = phd.id_intervention
                      LEFT JOIN episode e
                        ON phd.id_episode = e.id_episode, (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient) phd_max,
                     (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = l_patient
                               AND phd.id_professional = i_prof.id) phd_max_prof
                    UNION ALL
                    SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           NULL dt_pat_history_diagnosis_rep,
                           pk_alert_constant.get_yes flg_free_text,
                           NULL id_treatment,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL dt_execution,
                           NULL flg_type
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.flg_type = g_alert_type_treatments) aux
             ORDER BY decode(aux.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) DESC,
                      dt_register_order DESC,
                      flg_status ASC,
                      desc_past_hist_all ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_cong_anom',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_treatments;
    --
    /********************************************************************************************
    * Returns the relevant notes info
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object (professional ID, institution ID, software ID)
    * @param i_current_episode        Current episode ID
    * @param i_scope                  Scope
    * @param i_scope_type             Scope type
    * @param i_doc_area               Documentation area
    * @param o_doc_area_register      Documentation register cursor
    * @param o_doc_area_val           Documentation values cursor
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.2
    * @since                          30-08-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_relev_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient          patient.id_patient%TYPE;
        l_visit            visit.id_visit%TYPE;
        l_episode          episode.id_episode%TYPE;
        e_invalid_argument EXCEPTION;
    BEGIN
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        OPEN o_doc_area_register FOR
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(pphfth.flg_status,
                                                           pk_past_history.g_flg_status_cancel_free_text,
                                                           pphfth.id_prof_canceled,
                                                           pphfth.id_professional),
                                                    decode(pphfth.flg_status,
                                                           pk_past_history.g_flg_status_cancel_free_text,
                                                           pphfth.dt_cancel,
                                                           pphfth.dt_register),
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   g_doc_area_past_med id_doc_area,
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   decode(pphfth.flg_status,
                          pk_past_history.g_flg_status_cancel_free_text,
                          pphfth.id_prof_canceled,
                          pphfth.id_professional) id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   pk_past_history.get_review_info(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => pphfth.id_episode,
                                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.id_doc_area = i_doc_area
               AND (pphfth.id_pat_ph_ft, pphfth.dt_register, pphfth.flg_status) NOT IN
                   (SELECT pphfth.id_pat_ph_ft, pphfth.dt_register, g_flg_status_outdtd_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND pphfth.flg_status = g_flg_status_cancel_free_text
                       AND pphfth.id_doc_area = i_doc_area)
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text
              FROM (SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  pk_past_history.g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     pk_past_history.g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           decode(pphfth.flg_status,
                                  pk_past_history.g_flg_status_cancel_free_text,
                                  pphfth.dt_cancel,
                                  pphfth.dt_register) dt_pat_history_diagnosis_tstz,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.id_doc_area = i_doc_area
                       AND (pphfth.id_pat_ph_ft, pphfth.dt_register, pphfth.flg_status) NOT IN
                           (SELECT pphfth.id_pat_ph_ft, pphfth.dt_register, g_flg_status_outdtd_free_text
                              FROM pat_past_hist_ft_hist pphfth
                             WHERE pphfth.id_patient = l_patient
                               AND pphfth.flg_status = g_flg_status_cancel_free_text
                               AND pphfth.id_doc_area = i_doc_area)) aux
             ORDER BY decode(aux.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) DESC,
                      dt_register_order DESC,
                      flg_status ASC,
                      desc_past_hist ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'get_past_hist_relev_notes_int',
                                                     o_error);
            --pk_types.open_my_cursor(o_doc_area_register);
            --pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END get_past_hist_relev_notes;
    --
    /********************************************************************************************
    * Return past histtory formated desc for detail
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_flg_ft                 Free text flag
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2011/10/18
    **********************************************************************************************/
    FUNCTION prv_get_past_hist_det_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_flg_ft   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN VARCHAR2 IS
        l_return_desc      sys_message.desc_message%TYPE;
        l_sys_message_code sys_message.code_message%TYPE := 'PAST_HISTORY_M118';
        l_doc_area_name    pk_translation.t_desc_translation;
    
    BEGIN
        l_doc_area_name := pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_doc_area => i_doc_area);
        IF i_flg_ft = pk_alert_constant.g_yes
        THEN
            l_return_desc := l_doc_area_name || ' (' || pk_message.get_message(i_lang, l_sys_message_code) || '): ';
        ELSE
            l_return_desc := l_doc_area_name || ': ';
        END IF;
    
        RETURN l_return_desc;
    END prv_get_past_hist_det_desc;
    --
    /********************************************************************************************
    * Returns the details for the past history summary page (medical and surgical history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param i_pat_hist_diag          Past History Diagnosis ID   
    * @param i_all                    True (All), False (Only Create)
    * @param i_flg_ft                 If provided id is from a free text or a diagnosis ID - Yes (Y) No (N) 
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/09/13
    **********************************************************************************************/
    FUNCTION prv_get_past_hist_det_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_pat_hist_diag     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_all               IN BOOLEAN DEFAULT FALSE,
        i_flg_ft            IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_free_text             pat_past_hist_free_text.id_pat_ph_ft%TYPE;
        l_id_free_text_hist        pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
        l_max_dt_pat_his_diag_tstz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_min_dt_pat_his_diag_tstz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
    
        l_label_review      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'DETAIL_COMMON_M005');
        l_label_review_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'DETAIL_COMMON_M004');
        l_message_unknown   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    
        l_all PLS_INTEGER;
    
        l_task_type NUMBER := prv_conv_doc_area_to_task_type(i_doc_area);
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
    
        CURSOR c_epis_doc IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
            CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
             START WITH ed.id_epis_documentation = i_epis_document
            UNION ALL
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation <> i_epis_document
            CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
             START WITH ed.id_epis_documentation = i_epis_document;
    
        l_epis_doc table_number := table_number();
    BEGIN
    
        l_all := sys.diutil.bool_to_int(i_all);
    
        IF NOT prv_get_past_hist_det_ids(i_pat_hist_diag,
                                         i_flg_ft,
                                         l_id_free_text,
                                         l_id_free_text_hist,
                                         l_max_dt_pat_his_diag_tstz,
                                         l_min_dt_pat_his_diag_tstz)
        THEN
            g_error := 'set_past_hist_ft has failed';
            RAISE g_exception;
        END IF;
    
        IF i_epis_document IS NOT NULL
        THEN
            OPEN c_epis_doc;
            FETCH c_epis_doc BULK COLLECT
                INTO l_epis_doc;
            CLOSE c_epis_doc;
        END IF;
    
        ---
        -- per episode
        ---   
        g_error := 'OPEN O_DOC_AREA_REGISTER';
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, NULL);
        OPEN o_doc_area_register FOR
            SELECT doc_area_reg.id_episode,
                   doc_area_reg.flg_current_episode,
                   doc_area_reg.nick_name,
                   doc_area_reg.dt_register,
                   doc_area_reg.prof_spec_reg,
                   doc_area_reg.id_doc_area,
                   doc_area_reg.dt_register_chr,
                   doc_area_reg.id_professional,
                   --doc_area_reg.notes,
                   decode(COUNT(DISTINCT doc_area_reg.desc_detail)
                          over(PARTITION BY doc_area_reg.dt_pat_history_diagnosis_tstz),
                          1,
                          doc_area_reg.desc_detail,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M065')) AS desc_detail,
                   doc_area_reg.flg_status,
                   NULL review_notes,
                   id_visit,
                   id_epis_documentation,
                   detail_type,
                   flg_review,
                   unique_id -- used BY reports TO GROUP entries IN forensic report
              FROM (SELECT phd.id_episode,
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            phd.id_professional,
                                                            phd.dt_pat_history_diagnosis_tstz,
                                                            phd.id_episode) prof_spec_reg,
                           i_doc_area id_doc_area,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           phd.dt_pat_history_diagnosis_tstz,
                           phd.id_professional,
                           --phd.notes,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                                  decode(connect_by_isleaf,
                                         1,
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                           phd.flg_status,
                           NULL review_notes,
                           phd.id_visit,
                           NULL id_epis_documentation,
                           decode(connect_by_isleaf, 1, g_detail_type_create, g_detail_type_edit) detail_type,
                           pk_alert_constant.g_no flg_review,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) unique_id
                      FROM (SELECT *
                              FROM (SELECT phd.*, e.id_visit
                                      FROM pat_history_diagnosis phd, episode e
                                     WHERE phd.flg_type IN decode(i_doc_area,
                                                                  g_doc_area_past_med,
                                                                  g_alert_diag_type_med,
                                                                  g_doc_area_past_surg,
                                                                  g_alert_diag_type_surg,
                                                                  g_doc_area_past_fam,
                                                                  g_alert_diag_type_family,
                                                                  g_doc_area_gyn_hist,
                                                                  g_alert_diag_type_gyneco,
                                                                  
                                                                  g_alert_diag_type_cong_anom)
                                       AND phd.flg_area <> pk_alert_constant.g_diag_area_problems
                                       AND e.id_episode = phd.id_episode
                                       AND phd.id_patient = i_id_patient)) phd
                     START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                    CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new) doc_area_reg
            UNION
            
            SELECT doc_area_reg.id_episode,
                   doc_area_reg.flg_current_episode,
                   doc_area_reg.nick_name,
                   doc_area_reg.dt_register,
                   doc_area_reg.prof_spec_reg,
                   doc_area_reg.id_doc_area,
                   doc_area_reg.dt_register_chr,
                   doc_area_reg.id_professional,
                   --doc_area_reg.notes,
                   decode(COUNT(DISTINCT doc_area_reg.desc_detail)
                          over(PARTITION BY doc_area_reg.dt_pat_history_diagnosis_tstz),
                          1,
                          doc_area_reg.desc_detail,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M065')) AS desc_detail,
                   doc_area_reg.flg_status,
                   NULL review_notes,
                   id_visit,
                   id_epis_documentation,
                   detail_type,
                   flg_review,
                   unique_id -- used BY reports TO GROUP entries IN forensic report
              FROM (SELECT phd.id_episode,
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            phd.id_professional,
                                                            phd.dt_pat_history_diagnosis_tstz,
                                                            phd.id_episode) prof_spec_reg,
                           i_doc_area id_doc_area,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           phd.dt_pat_history_diagnosis_tstz,
                           phd.id_professional,
                           --phd.notes,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                                  decode(connect_by_isleaf,
                                         1,
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                           phd.flg_status,
                           NULL review_notes,
                           phd.id_visit,
                           NULL id_epis_documentation,
                           decode(connect_by_isleaf, 1, g_detail_type_create, g_detail_type_edit) detail_type,
                           pk_alert_constant.g_no flg_review,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) unique_id
                      FROM (SELECT *
                              FROM (SELECT phd.*, e.id_visit
                                      FROM pat_history_diagnosis phd, episode e
                                     WHERE phd.flg_type IN decode(i_doc_area,
                                                                  g_doc_area_past_med,
                                                                  g_alert_diag_type_med,
                                                                  g_doc_area_past_surg,
                                                                  g_alert_diag_type_surg,
                                                                  g_doc_area_past_fam,
                                                                  g_alert_diag_type_family,
                                                                  g_doc_area_gyn_hist,
                                                                  g_alert_diag_type_gyneco,
                                                                  
                                                                  g_alert_diag_type_cong_anom)
                                       AND phd.flg_area <> pk_alert_constant.g_diag_area_problems
                                       AND e.id_episode = phd.id_episode
                                       AND phd.id_patient = i_id_patient
                                       AND phd.id_alert_diagnosis = 0
                                       AND phd.id_diagnosis = -2)) phd
                     START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                    CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new) doc_area_reg
            
            UNION
            
            SELECT doc_area_reg.id_episode,
                   doc_area_reg.flg_current_episode,
                   doc_area_reg.nick_name,
                   doc_area_reg.dt_register,
                   doc_area_reg.prof_spec_reg,
                   doc_area_reg.id_doc_area,
                   doc_area_reg.dt_register_chr,
                   doc_area_reg.id_professional,
                   --doc_area_reg.notes,
                   decode(COUNT(DISTINCT doc_area_reg.desc_detail)
                          over(PARTITION BY doc_area_reg.dt_pat_history_diagnosis_tstz),
                          1,
                          doc_area_reg.desc_detail,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M065')) AS desc_detail,
                   doc_area_reg.flg_status,
                   NULL review_notes,
                   id_visit,
                   id_epis_documentation,
                   detail_type,
                   flg_review,
                   unique_id -- used BY reports TO GROUP entries IN forensic report
              FROM (SELECT phd.id_episode,
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            phd.id_professional,
                                                            phd.dt_pat_history_diagnosis_tstz,
                                                            phd.id_episode) prof_spec_reg,
                           i_doc_area id_doc_area,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           phd.dt_pat_history_diagnosis_tstz,
                           phd.id_professional,
                           --phd.notes,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                                  decode(connect_by_isleaf,
                                         1,
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                           phd.flg_status,
                           NULL review_notes,
                           phd.id_visit,
                           NULL id_epis_documentation,
                           decode(connect_by_isleaf, 1, g_detail_type_create, g_detail_type_edit) detail_type,
                           pk_alert_constant.g_no flg_review,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) unique_id
                      FROM (SELECT *
                              FROM (SELECT phd.*, e.id_visit
                                      FROM pat_history_diagnosis phd, episode e
                                     WHERE phd.flg_type IN decode(i_doc_area,
                                                                  g_doc_area_past_med,
                                                                  g_alert_diag_type_med,
                                                                  g_doc_area_past_surg,
                                                                  g_alert_diag_type_surg,
                                                                  g_doc_area_past_fam,
                                                                  g_alert_diag_type_family,
                                                                  g_doc_area_gyn_hist,
                                                                  g_alert_diag_type_gyneco,
                                                                  
                                                                  g_alert_diag_type_cong_anom)
                                       AND phd.flg_area <> pk_alert_constant.g_diag_area_problems
                                       AND e.id_episode = phd.id_episode
                                       AND phd.id_alert_diagnosis = -1
                                       AND phd.id_patient = i_id_patient
                                       AND phd.id_diagnosis = -2)) phd
                     START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                    CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new) doc_area_reg
            UNION
            
            SELECT phd.id_episode id_episode,
                   decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, phd.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   rd.id_professional id_professional,
                   l_label_review_desc desc_detail,
                   phd.flg_status flg_status,
                   rd.review_notes review_notes,
                   e.id_visit,
                   NULL id_epis_documentation,
                   g_detail_type_review detail_type,
                   pk_alert_constant.g_yes flg_review,
                   pk_date_utils.date_send_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) unique_id
              FROM review_detail rd, pat_history_diagnosis phd
             INNER JOIN episode e
                ON e.id_episode = phd.id_episode
             WHERE rd.id_record_area = i_pat_hist_diag
               AND rd.id_record_area = phd.id_pat_history_diagnosis
               AND rd.flg_context IN (pk_review.get_past_history_context, pk_review.get_past_history_ft_context)
               AND nvl(phd.flg_status, g_pat_hist_diag_unknown) != g_pat_hist_diag_canceled
               AND l_all > 0
            UNION
            SELECT pphft.id_episode id_episode,
                   decode(pphft.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, pphft.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   rd.id_professional id_professional,
                   l_label_review_desc desc_detail,
                   pphft.flg_status flg_status,
                   rd.review_notes review_notes,
                   pphft.id_visit,
                   NULL id_epis_documentation,
                   g_detail_type_review detail_type,
                   pk_alert_constant.g_yes flg_review,
                   pk_date_utils.date_send_tsz(i_lang, pphft.dt_register, i_prof.institution, i_prof.software) unique_id
              FROM review_detail rd
              JOIN pat_past_hist_free_text pphft
                ON pphft.id_pat_ph_ft = rd.id_record_area
             WHERE rd.id_record_area = l_id_free_text
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND l_all > 0
            UNION
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pphfth.id_professional,
                                                    pphfth.dt_register,
                                                    pphfth.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   pphfth.id_professional id_professional,
                   decode(pphfth.flg_status,
                          g_flg_status_cancel_free_text,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                          decode(pphfth.dt_register,
                                 l_min_dt_pat_his_diag_tstz,
                                 pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                 pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                   pphfth.flg_status,
                   NULL review_notes,
                   pphfth.id_visit,
                   NULL id_epis_documentation,
                   decode(pphfth.dt_register, l_min_dt_pat_his_diag_tstz, g_detail_type_create, g_detail_type_edit) detail_type,
                   pk_alert_constant.g_no flg_review,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) unique_id
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_pat_ph_ft_hist = l_id_free_text_hist
               AND i_flg_ft = pk_alert_constant.get_yes
            UNION
            -- template history info
            SELECT ed.id_episode,
                   decode(ed.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_register_chr,
                   ed.id_professional id_professional,
                   decode(ed.flg_status,
                          g_flg_status_cancel_free_text,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                          nvl2(ed.id_epis_documentation_parent,
                               pk_message.get_message(i_lang, 'PAST_HISTORY_M065'),
                               pk_message.get_message(i_lang, 'PAST_HISTORY_M067'))) desc_detail,
                   ed.flg_status,
                   NULL review_notes,
                   e.id_visit,
                   ed.id_epis_documentation,
                   decode(connect_by_isleaf, 1, g_detail_type_create, g_detail_type_edit) detail_type,
                   pk_alert_constant.g_no flg_review,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) unique_id
              FROM epis_documentation ed
              JOIN episode e
                ON e.id_episode = ed.id_episode
             WHERE e.id_patient = i_id_patient
               AND ed.id_doc_area = i_doc_area
            CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
             START WITH ed.id_epis_documentation = i_epis_document
            UNION
            -- template history info
            SELECT ed.id_episode,
                   decode(ed.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_register_chr,
                   ed.id_professional id_professional,
                   decode(ed.flg_status,
                          g_flg_status_cancel_free_text,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                          nvl2(ed.id_epis_documentation_parent,
                               pk_message.get_message(i_lang, 'PAST_HISTORY_M065'),
                               pk_message.get_message(i_lang, 'PAST_HISTORY_M067'))) desc_detail,
                   ed.flg_status,
                   NULL review_notes,
                   e.id_visit,
                   ed.id_epis_documentation,
                   decode(connect_by_isleaf, 1, g_detail_type_create, g_detail_type_edit) detail_type,
                   pk_alert_constant.g_no flg_review,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) unique_id
              FROM epis_documentation ed
              JOIN episode e
                ON e.id_episode = ed.id_episode
             WHERE e.id_patient = i_id_patient
               AND ed.id_doc_area = i_doc_area
            CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
             START WITH ed.id_epis_documentation = i_epis_document
            UNION
            -- template reviews info
            SELECT ed.id_episode id_episode,
                   decode(ed.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, ed.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   rd.id_professional id_professional,
                   l_label_review_desc desc_detail,
                   NULL flg_status,
                   rd.review_notes review_notes,
                   e.id_visit,
                   ed.id_epis_documentation,
                   g_detail_type_review detail_type,
                   pk_alert_constant.g_yes flg_review,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) unique_id
              FROM review_detail rd
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = rd.id_record_area
              JOIN episode e
                ON e.id_episode = ed.id_episode
             WHERE rd.id_record_area = i_epis_document
               AND rd.flg_context = pk_review.get_template_context
               AND l_all > 0
             ORDER BY flg_current_episode DESC, dt_register DESC, flg_status DESC;
    
        ---
        -- per patient
        ---       
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT /*+ first_rows*/
             t.id_episode,
             pk_date_utils.date_send_tsz(i_lang, t.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
             pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) nick_name,
             prv_get_past_hist_det_desc(i_lang, i_prof, i_doc_area, pk_alert_constant.get_no) label_past_hist,
             decode(t.phd_id_alert_diagnosis,
                    g_diag_none,
                    pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_none, i_lang),
                    decode(t.phd_id_alert_diagnosis,
                           g_diag_unknown,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_unknown, i_lang),
                           decode(t.phd_id_alert_diagnosis,
                                  g_diag_non_remark,
                                  pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                          g_pat_hist_diag_non_remark,
                                                          i_lang),
                                  decode(t.desc_pat_history_diagnosis, NULL, '', t.desc_pat_history_diagnosis || ' - ') ||
                                  pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_id_alert_diagnosis => t.ad_id_alert_diagnosis,
                                                             i_id_diagnosis       => t.id_diagnosis,
                                                             i_id_task_type       => decode(i_doc_area,
                                                                                            pk_past_history.g_doc_area_past_med,
                                                                                            pk_alert_constant.g_task_medical_history,
                                                                                            pk_past_history.g_doc_area_past_surg,
                                                                                            pk_alert_constant.g_task_surgical_history,
                                                                                            pk_past_history.g_doc_area_cong_anom,
                                                                                            pk_alert_constant.g_task_congenital_anomalies,
                                                                                            pk_past_history.g_doc_area_past_fam,
                                                                                            pk_alert_constant.g_task_family_history,
                                                                                            pk_past_history.g_doc_area_gyn_hist,
                                                                                            pk_alert_constant.g_task_gynecology_history,
                                                                                            pk_alert_constant.g_task_diagnosis),
                                                             i_code               => t.code_icd,
                                                             i_flg_other          => t.flg_other,
                                                             i_flg_std_diag       => t.flg_icd9)))) desc_past_hist,
             -- desc
             -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
             get_desc_past_hist_all(i_lang,
                                    i_prof,
                                    t.phd_id_alert_diagnosis,
                                    t.desc_pat_history_diagnosis,
                                    t.code_icd,
                                    t.flg_other,
                                    t.flg_icd9,
                                    t.flg_status,
                                    t.flg_compl,
                                    t.flg_nature,
                                    t.dt_diagnosed,
                                    t.dt_diagnosed_precision,
                                    i_doc_area,
                                    t.id_family_relationship) desc_past_hist_all,
             -- onset
             decode(i_doc_area,
                    g_doc_area_past_fam,
                    '',
                    g_doc_area_past_surg,
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M138'),
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M137')) label_onset,
             pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_date      => t.dt_diagnosed,
                                                     i_precision => t.dt_diagnosed_precision) AS desc_onset,
             pk_message.get_message(i_lang, 'PAST_HISTORY_M061') label_status,
             t.flg_status,
             pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', t.flg_status, i_lang) desc_status,
             decode(i_doc_area,
                    g_doc_area_past_surg,
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M070'),
                    g_doc_area_past_fam,
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M127'),
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M060')) label_nature,
             decode(i_doc_area,
                    g_doc_area_past_surg,
                    t.flg_compl,
                    g_doc_area_past_fam,
                    t.id_family_relationship,
                    t.flg_nature) AS flg_nature,
             decode(i_doc_area,
                    g_doc_area_past_fam,
                    pk_family.get_family_relationship_desc(i_lang, t.id_family_relationship),
                    pk_sysdomain.get_domain(decode(i_doc_area,
                                                   g_doc_area_past_surg,
                                                   'PAT_PROBLEM.FLG_COMPL_DESC',
                                                   'PAT_PROBLEM.FLG_NATURE'),
                                            decode(g_doc_area_past_surg, i_doc_area, t.flg_compl, t.flg_nature),
                                            i_lang)) desc_nature,
             pk_message.get_message(i_lang, 'PAST_HISTORY_M062') label_notes,
             t.notes,
             -- check if it is the current episode
             decode(t.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
             -- check if the diagnosis was registered by the current professional
             decode(t.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
             -- check if it is the last record
             decode((SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_id_episode
                       AND epis.id_patient = e.id_patient),
                    t.dt_pat_history_diagnosis_tstz,
                    pk_alert_constant.get_yes,
                    pk_alert_constant.get_no) flg_last_record,
             -- check if it is the last record by that professional
             decode((SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_id_episode
                          
                       AND e.id_patient = epis.id_patient
                       AND phd.id_professional = i_prof.id),
                    t.dt_pat_history_diagnosis_tstz,
                    pk_alert_constant.get_yes,
                    pk_alert_constant.get_no) flg_last_record_prof,
             t.phd_id_alert_diagnosis id_diagnosis,
             decode(t.id_pat_history_diagnosis_new, NULL, pk_alert_constant.get_no, pk_alert_constant.get_yes) flg_outdated,
             decode(t.flg_status, g_pat_hist_diag_canceled, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_canceled,
             pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_date      => t.dt_diagnosed,
                                                     i_precision => t.dt_diagnosed_precision) onset,
             pk_date_utils.date_char_tsz(i_lang, t.dt_pat_history_diagnosis_tstz, i_prof.institution, i_prof.software) dt_register_chr,
             decode(t.flg_status,
                    g_pat_hist_diag_canceled,
                    pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                    decode(t.id_pat_history_diagnosis_new,
                           NULL,
                           NULL,
                           pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
             pk_date_utils.to_char_insttimezone(i_prof, t.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order,
             t.dt_pat_history_diagnosis_tstz,
             -- cancelation data
             decode(t.flg_status, g_pat_hist_diag_canceled, pk_message.get_message(i_lang, 'PAST_HISTORY_M063'), NULL) label_cancel_reason,
             pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || t.id_cancel_reason) cancel_reason,
             decode(t.flg_status, g_pat_hist_diag_canceled, pk_message.get_message(i_lang, 'PAST_HISTORY_M064'), NULL) label_cancel_notes,
             decode(t.flg_status, g_pat_hist_diag_canceled, t.cancel_notes, NULL) cancel_notes,
             NULL label_review_notes,
             NULL review_notes,
             pk_alert_constant.get_no flg_review,
             t.id_visit,
             decode(t.flg_status,
                    g_outdated,
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M090'),
                    g_pat_hist_diag_canceled,
                    pk_message.get_message(i_lang, 'PAST_HISTORY_M090'),
                    NULL) label_prof_cancel,
             decode(t.flg_status, g_pat_hist_diag_canceled, pk_message.get_message(i_lang, 'PAST_HISTORY_M091'), NULL) label_date_cancel,
             pk_date_utils.date_char_tsz(i_lang, t.dt_cancel, i_prof.institution, i_prof.software) date_cancel,
             pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_cancel) prof_cancel_desc,
             pk_alert_constant.g_no flg_free_text,
             decode(t.familiar_age, NULL, '', pk_message.get_message(i_lang, 'PAST_HISTORY_M126')) label_familiar_age,
             to_char(t.familiar_age) desc_familiar_age,
             decode(t.flg_death_cause, NULL, '', pk_message.get_message(i_lang, 'PAST_HISTORY_M128')) label_death_cause,
             pk_sysdomain.get_domain(g_phd_flg_death_cause, t.flg_death_cause, i_lang) desc_death_cause
              FROM (SELECT /*+ opt_estimate(table phd rows=1) push_pred(d) */
                     phd.id_episode,
                     phd.dt_pat_history_diagnosis_tstz,
                     phd.id_professional,
                     phd.id_alert_diagnosis            phd_id_alert_diagnosis,
                     phd.desc_pat_history_diagnosis,
                     ad.id_alert_diagnosis             ad_id_alert_diagnosis,
                     ad.id_diagnosis,
                     ad.code_icd,
                     ad.flg_other,
                     ad.flg_icd9,
                     phd.flg_status,
                     phd.flg_compl,
                     phd.flg_nature,
                     phd.notes,
                     phd.id_pat_history_diagnosis_new,
                     phd.id_cancel_reason,
                     phd.dt_cancel,
                     phd.cancel_notes,
                     e.id_visit,
                     phd.id_prof_cancel,
                     phd.dt_diagnosed,
                     phd.dt_diagnosed_precision,
                     phd.id_family_relationship,
                     phd.flg_death_cause,
                     phd.familiar_age
                      FROM (SELECT *
                              FROM pat_history_diagnosis phd
                             WHERE phd.id_patient = i_id_patient
                               AND phd.flg_area <> pk_alert_constant.g_diag_area_problems
                               AND phd.flg_type = decode(i_doc_area,
                                                         g_doc_area_past_med,
                                                         g_alert_diag_type_med,
                                                         g_doc_area_past_surg,
                                                         g_alert_diag_type_surg,
                                                         g_doc_area_past_fam,
                                                         g_alert_diag_type_family,
                                                         g_doc_area_gyn_hist,
                                                         g_alert_diag_type_gyneco,
                                                         g_alert_diag_type_cong_anom)
                             START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                            CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new) phd
                      JOIN episode e
                        ON phd.id_episode = e.id_episode
                      LEFT JOIN (SELECT ct.id_concept_term id_alert_diagnosis,
                                       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_type(ct.id_concept_term,
                                                                                            ctt.id_task_type) AS
                                            VARCHAR2(2 CHAR)) flg_type,
                                       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_icd9(ct.id_concept_term) AS
                                            VARCHAR2(2 CHAR)) flg_icd9,
                                       CAST(pk_api_pfh_diagnosis_in.get_diag_flg_other(tv.id_terminology, cv.id_concept) AS
                                            VARCHAR2(1 CHAR)) flg_other,
                                       c.code code_icd,
                                       cv.id_concept_version id_diagnosis
                                  FROM concept_term ct
                                  JOIN concept_term_task_type ctt
                                    ON ctt.id_concept_term = ct.id_concept_term
                                  JOIN concept_version cv
                                    ON ct.id_concept_vers_start = cv.id_concept_version
                                  JOIN terminology_version tv
                                    ON cv.id_terminology_version = tv.id_terminology_version
                                  JOIN concept c
                                    ON cv.id_concept = c.id_concept
                                 WHERE ctt.id_task_type =
                                       decode(i_doc_area,
                                              g_doc_area_past_med,
                                              pk_alert_constant.g_task_medical_history,
                                              g_doc_area_past_surg,
                                              pk_alert_constant.g_task_surgical_history,
                                              g_doc_area_past_fam,
                                              pk_alert_constant.g_task_family_history,
                                              g_doc_area_gyn_hist,
                                              pk_alert_constant.g_task_gynecology_history,
                                              pk_alert_constant.g_task_congenital_anomalies)) ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                     WHERE (ad.flg_type = decode(i_doc_area,
                                                 g_doc_area_past_med,
                                                 g_alert_diag_type_med,
                                                 g_doc_area_past_surg,
                                                 g_alert_diag_type_surg,
                                                 g_doc_area_past_fam,
                                                 g_alert_diag_type_med,
                                                 g_doc_area_gyn_hist,
                                                 g_alert_diag_type_gyneco,
                                                 g_alert_diag_type_cong_anom) OR
                           phd.id_alert_diagnosis IN (g_diag_unknown, g_diag_none, g_diag_non_remark))) t
            UNION ALL
            SELECT notes_review_aux.id_episode id_episode,
                   pk_date_utils.date_send_tsz(i_lang, notes_review_aux.dt_review, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, notes_review_aux.id_professional) nick_name,
                   NULL label_past_hist,
                   NULL desc_past_hist,
                   NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   NULL flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   l_label_review label_notes,
                   NULL notes,
                   decode(notes_review_aux.id_episode,
                          i_id_episode,
                          pk_alert_constant.get_yes,
                          pk_alert_constant.get_no) flg_current_episode,
                   decode(notes_review_aux.id_professional,
                          i_prof.id,
                          pk_alert_constant.get_yes,
                          pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, notes_review_aux.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, notes_review_aux.dt_review, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL label_cancel_reason,
                   NULL cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_notes,
                   prv_get_review_note_label(i_lang, i_prof, notes_review_aux.review_notes) label_review_notes,
                   notes_review_aux.review_notes review_notes,
                   pk_alert_constant.g_yes flg_review,
                   e.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   pk_alert_constant.g_yes flg_free_text,
                   NULL,
                   NULL,
                   NULL,
                   NULL
              FROM (SELECT rd.dt_review, rd.id_professional, phd.id_episode, rd.review_notes
                      FROM review_detail rd, pat_history_diagnosis phd
                     WHERE rd.id_record_area = i_pat_hist_diag
                       AND rd.id_record_area = phd.id_pat_history_diagnosis
                    UNION -- when there are more than one past history "at the same time"
                    SELECT rd.dt_review, rd.id_professional, phd.id_episode, rd.review_notes
                      FROM review_detail rd, pat_history_diagnosis phd
                     INNER JOIN episode e
                        ON e.id_episode = phd.id_episode
                     WHERE rd.id_record_area = phd.id_pat_history_diagnosis
                       AND phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                       AND phd.flg_area <> pk_alert_constant.g_diag_area_problems) notes_review_aux
             INNER JOIN episode e
                ON e.id_episode = notes_review_aux.id_episode
             WHERE l_all > 0
            UNION ALL
            SELECT rd.id_episode id_episode,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   NULL label_past_hist,
                   NULL desc_past_hist,
                   NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   NULL flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   l_label_review label_notes,
                   NULL notes,
                   decode(rd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   decode(rd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, rd.dt_review, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL label_cancel_reason,
                   NULL cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_notes,
                   prv_get_review_note_label(i_lang, i_prof, rd.review_notes) label_review_notes,
                   rd.review_notes review_notes,
                   pk_alert_constant.g_yes flg_review,
                   pphft.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   pk_alert_constant.g_no flg_free_text,
                   NULL,
                   NULL,
                   NULL,
                   NULL
              FROM review_detail rd
              JOIN pat_past_hist_free_text pphft
                ON pphft.id_pat_ph_ft = rd.id_record_area
             WHERE rd.id_record_area = l_id_free_text
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND l_all > 0
            UNION ALL
            SELECT rd.id_episode id_episode,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   NULL label_past_hist,
                   NULL desc_past_hist,
                   NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   NULL flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   l_label_review label_notes,
                   NULL notes,
                   decode(rd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   decode(rd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, rd.dt_review, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL label_cancel_reason,
                   NULL cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_notes,
                   prv_get_review_note_label(i_lang, i_prof, rd.review_notes) label_review_notes,
                   rd.review_notes review_notes,
                   pk_alert_constant.g_yes flg_review,
                   pk_episode.get_id_visit(rd.id_episode) id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   pk_alert_constant.g_no flg_free_text,
                   NULL,
                   NULL,
                   NULL,
                   NULL
              FROM review_detail rd
             WHERE rd.id_record_area IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(l_epis_doc) t)
               AND rd.flg_context = pk_review.get_template_context
               AND l_all > 0
            UNION ALL
            SELECT pphfth.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   prv_get_past_hist_det_desc(i_lang, i_prof, i_doc_area, pk_alert_constant.get_yes) label_past_hist,
                   pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                   NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   pphfth.flg_status flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   NULL label_notes,
                   NULL notes,
                   decode(pphfth.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, pphfth.dt_register, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   -- cancelation data
                   pk_message.get_message(i_lang, 'PAST_HISTORY_M063') label_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = pphfth.id_cancel_reason) cancel_reason,
                   pk_message.get_message(i_lang, 'PAST_HISTORY_M064') label_cancel_notes,
                   decode(pphfth.flg_status, g_flg_status_cancel_free_text, pphfth.cancel_notes, NULL) cancel_notes,
                   NULL label_review_notes,
                   NULL review_notes,
                   pk_alert_constant.get_no flg_review,
                   pphfth.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   pk_alert_constant.g_yes flg_free_text,
                   NULL,
                   NULL,
                   NULL,
                   NULL
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_pat_ph_ft_hist = l_id_free_text_hist
             ORDER BY flg_current_episode DESC, dt_pat_history_diagnosis_tstz DESC, flg_status ASC, desc_past_hist ASC;
    
        --load template data
        g_error := 'GET ASSOCIATED TEMPLATE DATA';
        IF i_epis_document IS NOT NULL
        THEN
            IF NOT pk_touch_option.get_epis_documentation_det(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_epis_document     => i_epis_document,
                                                              o_epis_doc_register => o_epis_doc_register,
                                                              o_epis_document_val => o_epis_document_val,
                                                              o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING GET_PAST_HIST_DET FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_det',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END prv_get_past_hist_det_diag;

    /**
    * Returns the number of previous medications.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of previous medications
    *
    * @author   Rui Duarte
    * @version  2.6.0.5
    * @since    2011-Jan-06
    */
    FUNCTION get_past_hist_header_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_prev_med_hist    NUMBER;
        l_prev_ft_med_hist NUMBER;
    BEGIN
    
        --Past History diagnosys type
        BEGIN
            SELECT COUNT(*)
              INTO l_prev_med_hist
              FROM pat_history_diagnosis phd
             WHERE id_patient = i_id_patient
               AND id_alert_diagnosis IS NOT NULL
               AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                    pk_alert_constant.g_diag_area_surgical_hist,
                                    pk_alert_constant.g_diag_area_not_defined)
               AND id_pat_history_diagnosis =
                   pk_problems.get_pat_hist_diag_recent(i_lang,
                                                        id_alert_diagnosis,
                                                        desc_pat_history_diagnosis, --NULL,
                                                        i_id_patient,
                                                        i_prof,
                                                        pk_episode.g_pat_history_diagnosis_n)
               AND nvl(phd.flg_status, g_active) != g_past_history_flg_resolved;
        EXCEPTION
            WHEN no_data_found THEN
                l_prev_med_hist := 0;
        END;
    
        --Past History free text type
        BEGIN
        
            SELECT COUNT(*)
              INTO l_prev_ft_med_hist
              FROM pat_past_hist_free_text pphft
             WHERE pphft.flg_status != g_flg_status_cancel_free_text
               AND pphft.id_patient = i_id_patient
               AND pphft.flg_type = g_alert_diag_type_med;
        EXCEPTION
            WHEN no_data_found THEN
                l_prev_ft_med_hist := 0;
        END;
        --return values  
        RETURN(l_prev_med_hist + l_prev_ft_med_hist);
    
    END get_past_hist_header_count;
    --

    /********************************************************************************************
    * Returns Relevant Notes
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_pat_note                  Patient note ID
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version v2.6.0.1
    * @since   06-May-2010
    * @reason  ALERT-95625
    **********************************************************************************************/

    FUNCTION get_relevant_note
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_dt_note IN VARCHAR2,
        o_note    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_note';
        OPEN o_note FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pn.id_prof_writes) nick_name_writes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pn.id_prof_cancel) nick_name_cancel,
                   pk_date_utils.date_send_tsz(i_lang, pn.dt_note_tstz, i_prof) dt_register,
                   pk_date_utils.date_char_tsz(i_lang, pn.dt_note_tstz, i_prof.institution, i_prof.software) dt_register_chr,
                   pk_date_utils.date_send_tsz(i_lang, pn.dt_cancel_tstz, i_prof) dt_cancel,
                   pk_date_utils.date_char_tsz(i_lang, pn.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel_chr,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pn.id_prof_writes, pn.dt_note_tstz, pn.id_episode) prof_spec_writes,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pn.id_prof_cancel, pn.dt_cancel_tstz, pn.id_episode) prof_spec_cancel,
                   pk_string_utils.clob_to_sqlvarchar2(pn.notes) notes,
                   pn.note_cancel,
                   decode(pn.flg_status, g_pat_hist_diag_canceled, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_canceled,
                   pn.id_cancel_reason id_cancel_reason,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pn.id_cancel_reason) cancel_reason_desc
              FROM v_pat_notes pn
             WHERE pn.id_patient = i_patient
               AND pn.id_episode = i_episode
               AND pk_date_utils.date_send_tsz(i_lang, pn.dt_note_tstz, i_prof) = i_dt_note;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RELEVANT_NOTE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_note);
            RETURN FALSE;
    END get_relevant_note;
    --

    /********************************************************************************************
    * Set past history in free text values
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param o_ph_ft_id               pat_past_hist_free_text id
    * @param o_pat_ph_ft_hist         pat_past_hist_ft_hist id
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2010-Dec-14
    **********************************************************************************************/
    FUNCTION set_past_hist_free_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_ph_ft_id         IN pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        i_ph_ft_text       IN pat_past_hist_free_text.text%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_dt_register      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_review        IN review_detail.dt_review%TYPE,
        o_ph_ft_id         OUT pat_past_hist_ft_hist.id_pat_ph_ft%TYPE,
        o_pat_ph_ft_hist   OUT pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --Previous values  
        l_prev_pphfth_id          pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
        l_prev_pphfth_dt_register pat_past_hist_ft_hist.dt_register%TYPE;
        l_prev_pphft_text         pat_past_hist_free_text.text%TYPE;
        l_prev_pphft_professional pat_past_hist_free_text.id_professional%TYPE;
    
        --Set vars
        l_set_pphft_id      pat_past_hist_free_text.id_pat_ph_ft%TYPE;
        l_set_visit_id      pat_past_hist_free_text.id_visit%TYPE;
        l_set_flg_type      pat_past_hist_free_text.flg_type%TYPE;
        l_set_flg_status    pat_past_hist_free_text.flg_status%TYPE;
        l_set_text          pat_past_hist_free_text.text%TYPE;
        l_set_prof_register pat_past_hist_free_text.id_professional%TYPE;
        l_set_dt_register   pat_past_hist_free_text.dt_register%TYPE;
        l_set_prof_canceled pat_past_hist_free_text.id_prof_canceled%TYPE;
        l_set_dt_canceled   pat_past_hist_free_text.dt_cancel%TYPE;
    
        --Datagov ids
        l_rowids table_varchar;
    
        l_new_review_id review_detail.id_record_area%TYPE;
    BEGIN
        l_new_review_id := prv_get_free_text_hist_nextval();
        -- Get flg_type of doc area ID 
        l_set_flg_type := prv_conv_doc_area_to_flg_type(i_doc_area, pk_alert_constant.g_yes);
        -- Get visit ID
        l_set_visit_id := prv_get_epis_visit_id(i_episode);
    
        IF i_ph_ft_id IS NULL
        THEN
            l_set_flg_status    := g_flg_status_active_free_text;
            l_set_text          := i_ph_ft_text;
            l_set_prof_register := i_prof.id;
            l_set_dt_register   := i_dt_register;
            l_set_prof_canceled := NULL;
            l_set_dt_canceled   := NULL;
        ELSE
        
            -- Get previous value to update main table
            BEGIN
                SELECT pphft.text, pphft.id_professional, pphft.dt_register
                  INTO l_prev_pphft_text, l_prev_pphft_professional, l_prev_pphfth_dt_register
                  FROM pat_past_hist_free_text pphft
                 WHERE pphft.id_pat_ph_ft = i_ph_ft_id;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'set_past_hist_ft: Editing/Canceling previous value but no previous record was found in main table';
                    RAISE g_exception;
            END;
        
            -- Get previous value to update history table
            BEGIN
                SELECT pphfth.id_pat_ph_ft_hist
                  INTO l_prev_pphfth_id
                  FROM pat_past_hist_ft_hist pphfth
                 WHERE pphfth.id_pat_ph_ft = i_ph_ft_id
                   AND pphfth.flg_status = g_flg_status_active_free_text;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'set_past_hist_ft: Editing/Canceling previous value but no previous record was found in history table';
                    RAISE g_exception;
            END;
        
            IF i_id_cancel_reason IS NULL
            THEN
                l_set_flg_status    := g_flg_status_active_free_text;
                l_set_text          := i_ph_ft_text;
                l_set_prof_register := i_prof.id;
                l_set_dt_register   := i_dt_register;
                l_set_prof_canceled := NULL;
                l_set_dt_canceled   := NULL;
            ELSE
                l_set_flg_status    := g_flg_status_cancel_free_text;
                l_set_text          := l_prev_pphft_text;
                l_set_prof_register := l_prev_pphft_professional;
                l_set_prof_canceled := i_prof.id;
                l_set_dt_canceled   := i_dt_register;
                l_set_dt_register   := l_prev_pphfth_dt_register;
            END IF;
        END IF;
    
        -- New value
        IF i_ph_ft_id IS NULL
        THEN
        
            l_set_pphft_id := prv_get_free_text_nextval();
            l_rowids       := table_varchar();
        
            ts_pat_past_hist_free_text.ins(id_pat_ph_ft_in    => l_set_pphft_id,
                                           text_in            => l_set_text,
                                           id_patient_in      => i_pat,
                                           id_episode_in      => i_episode,
                                           id_visit_in        => l_set_visit_id,
                                           id_professional_in => l_set_prof_register,
                                           dt_register_in     => l_set_dt_register,
                                           flg_status_in      => l_set_flg_status,
                                           id_doc_area_in     => i_doc_area,
                                           flg_type_in        => l_set_flg_type,
                                           
                                           rows_out => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAST_HIST_FREE_TEXT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_rowids := table_varchar();
        
            ts_pat_past_hist_ft_hist.ins(id_pat_ph_ft_hist_in => l_new_review_id,
                                         id_pat_ph_ft_in      => l_set_pphft_id,
                                         text_in              => l_set_text,
                                         id_patient_in        => i_pat,
                                         id_episode_in        => i_episode,
                                         id_visit_in          => l_set_visit_id,
                                         id_professional_in   => l_set_prof_register,
                                         dt_register_in       => l_set_dt_register,
                                         flg_status_in        => l_set_flg_status,
                                         flg_type_in          => l_set_flg_type,
                                         id_doc_area_in       => i_doc_area,
                                         rows_out             => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PAST_HIST_FT_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
        
            -- Update history previous history table
            l_rowids := table_varchar();
            ts_pat_past_hist_ft_hist.upd(id_pat_ph_ft_hist_in => l_prev_pphfth_id,
                                         flg_status_in        => g_flg_status_outdtd_free_text,
                                         rows_out             => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'PAT_PAST_HIST_FT_HIST',
                                          i_list_columns => table_varchar('FLG_STATUS'),
                                          i_rowids       => l_rowids,
                                          o_error        => o_error);
        
            -- Update main table
            l_rowids := table_varchar();
            ts_pat_past_hist_free_text.upd(id_pat_ph_ft_in     => i_ph_ft_id,
                                           text_in             => l_set_text,
                                           id_patient_in       => i_pat,
                                           id_episode_in       => i_episode,
                                           id_visit_in         => l_set_visit_id,
                                           id_professional_in  => l_set_prof_register,
                                           dt_register_in      => l_set_dt_register,
                                           flg_status_in       => l_set_flg_status,
                                           flg_type_in         => l_set_flg_type,
                                           id_cancel_reason_in => i_id_cancel_reason,
                                           cancel_notes_in     => i_cancel_notes,
                                           id_prof_canceled_in => l_set_prof_canceled,
                                           dt_cancel_in        => l_set_dt_canceled,
                                           id_doc_area_in      => i_doc_area,
                                           rows_out            => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAST_HIST_FREE_TEXT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- Insert new backup value
            l_rowids := table_varchar();
            ts_pat_past_hist_ft_hist.ins(id_pat_ph_ft_hist_in => l_new_review_id,
                                         id_pat_ph_ft_in      => i_ph_ft_id,
                                         text_in              => l_set_text,
                                         id_patient_in        => i_pat,
                                         id_episode_in        => i_episode,
                                         id_visit_in          => l_set_visit_id,
                                         id_professional_in   => l_set_prof_register,
                                         dt_register_in       => l_set_dt_register,
                                         flg_status_in        => l_set_flg_status,
                                         flg_type_in          => l_set_flg_type,
                                         id_cancel_reason_in  => i_id_cancel_reason,
                                         cancel_notes_in      => i_cancel_notes,
                                         id_prof_canceled_in  => l_set_prof_canceled,
                                         dt_cancel_in         => l_set_dt_canceled,
                                         id_doc_area_in       => i_doc_area,
                                         rows_out             => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PAST_HIST_FT_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        o_ph_ft_id       := nvl(i_ph_ft_id, l_set_pphft_id);
        o_pat_ph_ft_hist := l_new_review_id;
    
        IF NOT pk_review.set_review(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_record_area => nvl(i_ph_ft_id, l_set_pphft_id),
                                    i_flg_context    => pk_review.get_past_history_ft_context,
                                    i_dt_review      => nvl(i_dt_review, current_timestamp),
                                    i_review_notes   => NULL,
                                    i_episode        => i_episode,
                                    i_flg_auto       => pk_alert_constant.g_yes,
                                    i_revision       => NULL,
                                    o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING SET_PAST_HIST_FREE_TEXT FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAST_HIST_FREE_TEXT',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_PAST_HIST_FREE_TEXT',
                                                     o_error);
            RETURN FALSE;
    END set_past_hist_free_text;
    --
    FUNCTION parse_date
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_precision IN VARCHAR2,
        o_date      OUT pat_history_diagnosis.dt_diagnosed%TYPE,
        o_precision OUT pat_history_diagnosis.dt_diagnosed_precision%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'PARSE_DATE';
        l_temp   VARCHAR2(14 CHAR);
        l_length NUMBER;
    BEGIN
        g_error := 'PARSE DATE';
        pk_alertlog.log_debug(g_error);
        IF i_date IS NOT NULL
        THEN
            l_length := length(i_date);
        
            g_error := 'TEST DATE LENGTH';
            pk_alertlog.log_debug(g_error);
            IF l_length NOT IN (4, 6, 8, 12, 14)
            THEN
                -- partial date must match formats YYYY, YYYYMM or YYYYMMDD so it can be completed here
                RAISE g_exception;
            END IF;
        
            g_error := 'COMPLETE PARTIAL DATE';
            pk_alertlog.log_debug(g_error);
            l_temp := i_date;
            -- if it receives an incomplete date like 2014, complete the serialized date to format YYYYMMDDHHMMSS
            IF l_length < 6
            THEN
                -- completes months
                l_temp := rpad(l_temp, 6, '01');
            END IF;
        
            IF l_length < 8
            THEN
                -- completes days
                l_temp := rpad(l_temp, 8, '01');
            END IF;
        
            IF l_length < 14
            THEN
                -- completes hours
                l_temp := rpad(l_temp, 14, '0');
            END IF;
            o_date := pk_date_utils.get_string_tstz(i_lang, i_prof, l_temp, NULL);
        ELSE
            o_date := NULL;
        END IF;
    
        g_error := 'PARSE DATE PRECISION';
        pk_alertlog.log_debug(g_error);
        IF i_precision IS NOT NULL
        THEN
            o_precision := i_precision;
        ELSE
            IF i_date IS NOT NULL
            THEN
                SELECT decode(length(i_date), 4, 'Y', 6, 'M', 8, 'D', 14, 'H', 1, 'U', 2, 'U', NULL)
                  INTO o_precision
                  FROM dual;
            ELSE
                o_precision := NULL;
            END IF;
        END IF;
        IF i_precision IS NOT NULL
           AND i_precision <> 'U'
           AND i_date IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END parse_date;

    /********************************************************************************************
    * Records new diagnosis on the past medical and surgical history for this episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode when this/these problems were registered    
    * @param i_pat                    Patient ID 
    * @param i_doc_area               Doc Area ID
    * @param i_flg_status             Array of problem status
    * @param i_flg_nature             Array of problem nature
    * @param i_diagnosis              Array of relevant diseases' ID (in case of a past medical history record). alert diagnosis ID
    * @param i_phd_outdated           Pat History Diagnosis/Pat notes ID fot the edited record (outdated)
    * @param i_desc_pat_history_diagnosis  Descriptions (when it's not based on an alert_diagnosis)
    * @param i_notes                  Notes if it was created through the problem screen  
    * @param i_id_cancel_reason       Cancelation reason ID
    * @param i_cancel_notes           Cancelation notes  
    * @param o_msg                    Message to show
    * @param o_msg_title              Message title to show
    * @param o_flg_show               If it should show message or not
    * @param o_button                 Button type
    * @param i_precaution_measure     list of arrays with precuation measures   
    * @param i_flg_warning            list of flag warning,
    * @param i_cdr_call               clinical decision rule corresponding id
    * @param i_flg_complications      Complications info for recording
    * @param i_flg_screen             Indicates from where the function was called. H - Past history screen (default), P - Problems screen
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/06/01
    **********************************************************************************************/

    FUNCTION set_past_hist_diagnosis
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar,
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_dt_register                IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_dt_review                  IN review_detail.dt_review%TYPE,
        i_flg_area                   IN table_varchar,
        i_flg_complications          IN table_varchar,
        i_flg_screen                 IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        i_flg_cda_reconciliation     IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_dt_resolved                IN table_varchar,
        i_dt_resolved_precision      IN table_varchar,
        i_location                   IN table_number,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        o_seq_phd                    OUT table_number,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_seq_phd      pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
        l_epis_comp    epis_complaint.id_epis_complaint%TYPE;
        l_flg_status   pat_history_diagnosis.flg_status%TYPE;
        l_flg_med_surg alert_diagnosis_type.flg_type%TYPE;
        --
        l_phd_exists NUMBER;
        l_dt_sysdate pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_diag       NUMBER;
        --
    
        CURSOR c_epis_complaint IS
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec, episode e
             WHERE ec.id_episode = e.id_episode
               AND ec.id_episode = i_episode
               AND ec.flg_status = g_epis_complaint_active;
    
        CURSOR c_phd_ex
        (
            c_id_prof      NUMBER,
            c_pat          NUMBER,
            c_flg_med_surg VARCHAR
        ) IS
            SELECT 0
              FROM pat_history_diagnosis phd, alert_diagnosis ad
             WHERE phd.id_professional = c_id_prof
               AND phd.id_patient = c_pat
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ad.flg_type = c_flg_med_surg
               AND phd.flg_status NOT IN
                   (g_pat_hist_diag_canceled, g_pat_hist_diag_none, g_pat_hist_diag_non_remark, g_pat_hist_diag_unknown);
    
        CURSOR c_diagnosis(c_id_diagnosis NUMBER) IS
            SELECT d.id_diagnosis, d.flg_other
              FROM diagnosis d
              JOIN alert_diagnosis ad
                ON ad.id_diagnosis = d.id_diagnosis
             WHERE ad.id_alert_diagnosis = c_id_diagnosis;
    
        CURSOR c_existing_problem
        (
            i_lang      IN language.id_language%TYPE,
            i_prof      IN profissional,
            i_episode   IN episode.id_episode%TYPE,
            i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
            i_flg_type  IN epis_diagnosis.flg_type%TYPE
        ) IS
            SELECT phd.id_pat_history_diagnosis, phd.dt_pat_history_diagnosis_tstz, phd.flg_status
              FROM pat_history_diagnosis phd
             WHERE phd.id_episode = i_episode
               AND phd.id_diagnosis = i_diagnosis
               AND phd.flg_type = i_flg_type
               AND (phd.flg_status != pk_diagnosis.g_ed_flg_status_ca OR phd.flg_status IS NULL)
               AND phd.id_pat_history_diagnosis_new IS NULL
               AND phd.flg_recent_diag = pk_alert_constant.g_yes;
    
        r_existing_problem      c_existing_problem%ROWTYPE;
        l_count_alert_diagnoses NUMBER := 0;
    
        l_diag_found   BOOLEAN;
        l_diagnosis    table_number;
        l_cnt_desc_phd NUMBER;
        l_cnt_status   NUMBER;
        l_flg_other    diagnosis.flg_other%TYPE;
        l_next         VARCHAR2(1000 CHAR);
        l_curr_session notes_config.notes_code%TYPE; -- temporary var to store kind of session for medical notes
    
        -- *********************************
        -- PT 19/09/2008 2.4.3.d
        l_id_location        pat_history_diagnosis.id_location%TYPE;
        l_flg_nature         VARCHAR2(2 CHAR);
        l_flg_compl          VARCHAR2(2 CHAR);
        l_flg_type           VARCHAR2(2 CHAR);
        l_flg_area           table_varchar;
        l_doc_area           table_number;
        l_flg_status_ins     VARCHAR2(2 CHAR);
        l_id_cancel_reason   pat_history_diagnosis.id_cancel_reason%TYPE;
        l_cancel_notes       pat_history_diagnosis.cancel_notes%TYPE;
        l_desc_pat_hist_diag pat_history_diagnosis.desc_pat_history_diagnosis%TYPE;
        l_notes              pat_history_diagnosis.notes%TYPE;
        l_rowids_1           table_varchar;
        l_rowids_2           table_varchar;
        l_rowids_upd         table_varchar;
        -- *********************************
        data_aux DATE;
    
        l_dt_execution           pat_history_diagnosis.dt_execution%TYPE;
        l_dt_execution_precision pat_history_diagnosis.dt_execution_precision%TYPE;
        l_exam                   pat_history_diagnosis.id_exam%TYPE;
        l_intervention           pat_history_diagnosis.id_intervention%TYPE;
    
        l_epis_ges_msg               epis_ges_msg.id_epis_ges_msg%TYPE;
        l_other_diags                table_number;
        l_performed_by_doctor        BOOLEAN;
        l_desc_pat_history_diagnosis table_varchar;
    
        l_dt_diagnosed           pat_history_diagnosis.dt_diagnosed%TYPE;
        l_dt_diagnosed_precision pat_history_diagnosis.dt_diagnosed_precision%TYPE;
        l_dt_resolved            pat_history_diagnosis.dt_resolved%TYPE;
        l_dt_resolved_precision  pat_history_diagnosis.dt_resolved_precision%TYPE;
    
        l_dt_temp_diag_precision pat_history_diagnosis.dt_diagnosed_precision%TYPE;
        l_dt_temp_reso_precision pat_history_diagnosis.dt_diagnosed_precision%TYPE;
    
        l_flg_warning VARCHAR2(1 CHAR);
        --save information about family history        
        l_family_relationship pat_history_diagnosis.id_family_relationship%TYPE;
        l_flg_death_cause     pat_history_diagnosis.flg_death_cause%TYPE;
        l_familiar_age        pat_history_diagnosis.familiar_age%TYPE;
    
        l_allow_problems_same_icd    sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PROBLEMS_SAME_ICD', i_prof);
        l_allow_ph_same_icd          sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PH_SAME_ICD', i_prof);
        l_flg_insert_new_record      VARCHAR2(1) := pk_alert_constant.g_no;
        l_terminology_allow_same_icd VARCHAR2(1) := NULL;
    
        PROCEDURE load_doc_and_flg_area
        (
            i_temp_doc_area IN doc_area.id_doc_area%TYPE,
            i_temp_flg_area IN table_varchar,
            o_doc_area      OUT table_number,
            o_flg_area      OUT table_varchar
        ) IS
            l_ret table_varchar;
        BEGIN
            o_doc_area := table_number();
            o_flg_area := table_varchar();
        
            -- i_temp_doc_area: dos problemas vem a NULL, nos antecedentes só vem uma doc_area mesmo que sejam vários registos
            -- i_temp_flg_area: dos problemas vem a flg_area pronta a usar, dos antecedentes não vem nada
            IF i_temp_doc_area IS NULL
            THEN
                -- registo vem dos problemas,
                IF i_temp_flg_area IS NOT NULL
                THEN
                    o_flg_area := i_temp_flg_area;
                ELSE
                    FOR i IN 1 .. i_flg_status.count --usar a flg_status que vem sempre para ficar com o mesmo numero de registos
                    LOOP
                        -- se a flg_area vier dos problemas vazia é porque veio de uma API, assume que é um problema
                        o_flg_area.extend;
                        o_flg_area(o_flg_area.count) := pk_alert_constant.g_diag_area_problems;
                    END LOOP;
                END IF;
            
                -- é necessário preencher array das doc_areas
                FOR i IN 1 .. i_temp_flg_area.count
                LOOP
                    o_doc_area.extend;
                    o_doc_area(o_doc_area.count) := CASE i_temp_flg_area(i)
                                                        WHEN pk_alert_constant.g_diag_area_surgical_hist THEN
                                                         pk_past_history.g_doc_area_past_surg
                                                        WHEN pk_alert_constant.g_diag_area_family_hist THEN
                                                         pk_past_history.g_doc_area_past_fam
                                                        ELSE
                                                         pk_past_history.g_doc_area_past_med
                                                    END;
                END LOOP;
            ELSE
                -- registo vem dos antecedentes, é necessário preencher array das doc_areas (a partir do valor que se recebe) 
                --    e é necessário preencher array das flg_areas (que também são todas iguais)
            
                FOR i IN 1 .. i_flg_status.count --usar a flg_status que vem sempre para ficar com o mesmo numero de registos
                LOOP
                    -- a doc_area é igual, apenas se replica para ficar com o mesmo numero dos outros arrays
                    o_doc_area.extend;
                    o_doc_area(o_doc_area.count) := i_temp_doc_area;
                
                    -- a flg_area é construida a partir da doc_area, é sempre H excepto para surgical history que é S
                    o_flg_area.extend;
                    o_flg_area(o_flg_area.count) := CASE
                                                        WHEN i_temp_flg_area.exists(i) THEN
                                                         i_temp_flg_area(i)
                                                        ELSE
                                                         CASE i_temp_doc_area
                                                             WHEN g_doc_area_past_surg THEN
                                                              pk_alert_constant.g_diag_area_surgical_hist
                                                             WHEN g_doc_area_past_fam THEN
                                                              pk_alert_constant.g_diag_area_family_hist
                                                             ELSE
                                                              pk_alert_constant.g_diag_area_past_history
                                                         END
                                                    END;
                END LOOP;
            END IF;
        
        END load_doc_and_flg_area;
    
        FUNCTION get_total_alert_diagnoses
        (
            i_lang            IN language.id_language%TYPE,
            i_prof            IN profissional,
            i_episode         IN episode.id_episode%TYPE,
            i_diagnosis       IN epis_diagnosis.id_diagnosis%TYPE,
            i_alert_diagnosis IN epis_diagnosis.id_alert_diagnosis%TYPE,
            i_flg_type        IN epis_diagnosis.flg_type%TYPE,
            i_flg_area        IN pat_history_diagnosis.flg_area%TYPE
        ) RETURN NUMBER IS
            l_count NUMBER;
        BEGIN
            SELECT COUNT(*)
              INTO l_count
              FROM pat_history_diagnosis phd
             WHERE phd.id_episode = i_episode
               AND phd.id_diagnosis = i_diagnosis
               AND phd.id_alert_diagnosis = i_alert_diagnosis
               AND phd.flg_type = i_flg_type
               AND (phd.flg_status != pk_diagnosis.g_ed_flg_status_ca OR phd.flg_status IS NULL)
               AND phd.id_pat_history_diagnosis_new IS NULL;
        
            RETURN l_count;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0;
        END get_total_alert_diagnoses;
    
    BEGIN
        o_seq_phd      := table_number();
        g_sysdate_tstz := i_dt_register;
        --
        g_error               := 'GET USER CATEGORY';
        l_performed_by_doctor := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof) =
                                 pk_alert_constant.g_cat_type_doc;
        --
        g_error := 'OPEN c_epis_complaint';
        OPEN c_epis_complaint;
        FETCH c_epis_complaint
            INTO l_epis_comp;
        g_found := c_epis_complaint%NOTFOUND;
        CLOSE c_epis_complaint;
        --
        -- user is unable to register a none or unknown diagnosis following another diagnosis
        g_error := 'IF i_diagnosis.COUNT';
        IF NOT i_diagnosis.exists(1) --i_flg_past_hist = 'N'
        THEN
            l_diagnosis := table_number();
            l_diagnosis.extend;
            l_diagnosis(1) := -500; -- when it comes from the problem list, the diagnosis is not filled 
        ELSE
            l_diagnosis := i_diagnosis;
        END IF;
        --
        g_error := 'IF I_DIAGNOSIS';
        IF l_diagnosis(1) IN (g_diag_unknown, g_diag_none, g_diag_non_remark)
        THEN
            g_error := 'GET CURSOR PHD EXISTS';
            IF i_doc_area = g_doc_area_past_med
            THEN
                l_flg_med_surg := g_alert_diag_type_med;
            ELSIF i_doc_area = g_doc_area_past_surg
            THEN
                l_flg_med_surg := g_alert_diag_type_surg;
            ELSIF i_doc_area = g_doc_area_past_fam
            THEN
                l_flg_med_surg := g_alert_diag_type_family;
            ELSIF i_doc_area = g_doc_area_gyn_hist
            THEN
                l_flg_med_surg := g_alert_diag_type_gyneco;
            ELSE
                l_flg_med_surg := g_alert_diag_type_cong_anom;
            END IF;
            --        
            g_error := 'OPEN c_phd_ex';
            OPEN c_phd_ex(i_prof.id, i_pat, l_flg_med_surg);
            FETCH c_phd_ex
                INTO l_phd_exists;
            g_found := c_phd_ex%NOTFOUND;
            CLOSE c_phd_ex;
        END IF;
    
        --
        load_doc_and_flg_area(i_temp_doc_area => i_doc_area,
                              i_temp_flg_area => i_flg_area,
                              o_doc_area      => l_doc_area,
                              o_flg_area      => l_flg_area);
        --
        g_error      := 'GET SYSDATE';
        l_dt_sysdate := i_dt_register;
        --    
        g_error := 'LOOP PAT_HISTORY_DIAGNOSIS';
        FOR i IN 1 .. i_flg_status.count
        LOOP
            g_error := 'PARSE DATE EXECUTION';
            pk_alertlog.log_debug(g_error);
            IF NOT dt_execution.exists(i)
            THEN
                l_dt_execution := NULL;
            ELSE
                l_dt_execution := pk_date_utils.get_string_tstz(i_lang, i_prof, dt_execution(i), NULL);
            END IF;
            IF NOT i_dt_execution_precision.exists(i)
            THEN
                l_dt_execution_precision := NULL;
            ELSE
                IF dt_execution.exists(i)
                THEN
                    l_dt_execution_precision := i_dt_execution_precision(i);
                END IF;
            END IF;
            IF NOT i_exam.exists(i)
            THEN
                l_exam := NULL;
            ELSE
                l_exam := i_exam(i);
            END IF;
            IF NOT i_intervention.exists(i)
            THEN
                l_intervention := NULL;
            ELSE
                l_intervention := i_intervention(i);
            END IF;
        
            g_error := 'PARSE DATE DIAGNOSED';
            pk_alertlog.log_debug(g_error);
            IF i_dt_diagnosed_precision.exists(i)
            THEN
                l_dt_temp_diag_precision := i_dt_diagnosed_precision(i);
            END IF;
            IF i_dt_diagnosed.exists(i)
            THEN
                IF NOT parse_date(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_date      => i_dt_diagnosed(i),
                                  i_precision => l_dt_temp_diag_precision,
                                  o_date      => l_dt_diagnosed,
                                  o_precision => l_dt_diagnosed_precision,
                                  o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            g_error := 'PARSE DATE RESOLVED';
            pk_alertlog.log_debug(g_error);
            IF i_dt_resolved_precision.exists(i)
            THEN
                l_dt_temp_reso_precision := i_dt_resolved_precision(i);
            END IF;
            IF i_dt_resolved.exists(i)
            THEN
                IF NOT parse_date(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_date      => i_dt_resolved(i),
                                  i_precision => l_dt_temp_reso_precision,
                                  o_date      => l_dt_resolved,
                                  o_precision => l_dt_resolved_precision,
                                  o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
            --
            -- in the cases of Unknown or None, the id_diagnosis parameter corresponds to 0 and -1 
            -- (see get_past_hist_diag_not_class) and the flg_status must be different
            IF l_diagnosis(1) = g_diag_unknown
            THEN
                l_flg_status := g_pat_hist_diag_unknown;
            ELSIF l_diagnosis(1) = g_diag_none
            THEN
                l_flg_status := g_pat_hist_diag_none;
            ELSIF l_diagnosis(1) = g_diag_non_remark
            THEN
                l_flg_status := g_pat_hist_diag_non_remark;
            ELSE
                l_flg_status := i_flg_status(i);
            END IF;
        
            -- the id_diagnosis is NULL if it is not a coded diagnosis
            -- in this case, we use the desc_pat_history_diagnosis and the entry is a 'Problem' and not a 'Relevant Disease'
            g_error := 'GET DIAGNOSIS FOR THE CURRENT ALERT_DIAGNOSIS';
            OPEN c_diagnosis(l_diagnosis(i));
            FETCH c_diagnosis
                INTO l_diag, l_flg_other; -- RdSN Added flg_other on c_diagnosis on 2008/03/23
            l_diag_found := c_diagnosis%NOTFOUND;
            CLOSE c_diagnosis;
        
            -- only the first position interests, since None is sent without any other diagnosis
            -- checks g_found since a none/unknown diagnosis can only be inserted if there's no previous diagnosis      
            IF g_found
               OR l_diagnosis(1) NOT IN (g_diag_unknown, g_diag_none, g_diag_non_remark)
               OR (l_diag IS NULL AND i_desc_pat_history_diagnosis IS NOT NULL)
               OR l_flg_other = pk_alert_constant.get_no
               OR (l_exam IS NOT NULL OR l_intervention IS NOT NULL)
            THEN
                -- *********************************
                -- PT 19/09/2008 2.4.3.d
                l_seq_phd := ts_pat_history_diagnosis.next_key();
                o_seq_phd.extend(1);
                o_seq_phd(o_seq_phd.count) := l_seq_phd;
                -- *********************************
                -- calculate flg_type to use in records updates
                -- if doc_area is not null, this is a past history record, uses the doc_area to calculate flg_type                       
                l_flg_type := CASE l_doc_area(i)
                                  WHEN g_doc_area_past_med THEN
                                   g_alert_diag_type_med
                                  WHEN g_doc_area_past_surg THEN
                                   g_alert_diag_type_surg
                                  WHEN g_doc_area_treatments THEN
                                   g_alert_type_treatments
                                  WHEN g_doc_area_past_fam THEN
                                   g_alert_diag_type_family
                                  WHEN g_doc_area_gyn_hist THEN
                                   g_alert_diag_type_gyneco
                                  ELSE
                                   g_alert_diag_type_cong_anom
                              END;
            
                g_error := 'ts_pat_history_diagnosis.upd the NONE, UNKNOWN and NON-REMARKABLE records to OUTDATED';
                ts_pat_history_diagnosis.upd(flg_recent_diag_in         => pk_alert_constant.g_no,
                                             id_pat_history_diag_new_in => l_seq_phd,
                                             rows_out                   => l_rowids_2,
                                             where_in                   => ' flg_status IN (''' ||
                                                                           g_pat_hist_diag_unknown || ''', ''' ||
                                                                           g_pat_hist_diag_none || ''', ''' ||
                                                                           g_pat_hist_diag_non_remark ||
                                                                           ''') AND id_patient = ' || i_pat ||
                                                                           ' AND flg_recent_diag = ''' ||
                                                                           pk_alert_constant.g_yes ||
                                                                           ''' AND flg_type = ''' || l_flg_type || '''');
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                              i_rowids     => l_rowids_2,
                                              o_error      => o_error);
            
                g_error := 'GET NEXT PAT HISTORY DIAGNOSIS';
                IF l_diagnosis(1) <> -500
                THEN
                    IF i_desc_pat_history_diagnosis.exists(1)
                    THEN
                        l_cnt_desc_phd := i_desc_pat_history_diagnosis.count; --RdSN 2007/10/28
                    ELSE
                        l_cnt_desc_phd := NULL;
                    END IF;
                
                    --                             
                    --Check if it possible to document severall Problems/PH with same ICD
                    --If it isn't => Check if there is already a documented record with current ICD
                    --(For PH it is necessary to check if the current record had already been registered, because
                    --when editing a PH record a new one is created)
                    r_existing_problem      := NULL;
                    l_count_alert_diagnoses := NULL;
                    l_flg_insert_new_record := pk_alert_constant.g_no;
                
                    l_terminology_allow_same_icd := pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                                                   i_id_concept_term    => l_diagnosis(i),
                                                                                   i_id_concept_version => l_diag,
                                                                                   i_id_task_type       => CASE
                                                                                                               WHEN i_flg_screen = pk_alert_constant.g_diag_area_problems THEN
                                                                                                                pk_alert_constant.g_task_problems
                                                                                                               WHEN l_flg_type = g_alert_diag_type_med THEN
                                                                                                                pk_alert_constant.g_task_medical_history
                                                                                                               WHEN l_flg_type = g_alert_diag_type_surg THEN
                                                                                                                pk_alert_constant.g_task_surgical_history
                                                                                                               WHEN l_flg_type = g_alert_diag_type_cong_anom THEN
                                                                                                                pk_alert_constant.g_task_congenital_anomalies
                                                                                                               ELSE
                                                                                                                NULL
                                                                                                           END,
                                                                                   i_id_institution     => i_prof.institution,
                                                                                   i_id_software        => i_prof.software);
                
                    IF (((i_flg_screen = pk_alert_constant.g_diag_area_past_history AND
                       (l_allow_ph_same_icd = pk_alert_constant.g_no OR
                       l_terminology_allow_same_icd = pk_alert_constant.g_no)) OR
                       (i_flg_screen = pk_alert_constant.g_diag_area_problems AND
                       (l_allow_problems_same_icd = pk_alert_constant.g_no OR
                       l_terminology_allow_same_icd = pk_alert_constant.g_no))) AND
                       l_flg_other <> pk_alert_constant.g_yes)
                    THEN
                        OPEN c_existing_problem(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_episode   => i_episode,
                                                i_diagnosis => l_diag,
                                                i_flg_type  => l_flg_type);
                    
                        FETCH c_existing_problem
                            INTO r_existing_problem;
                        CLOSE c_existing_problem;
                    
                        l_count_alert_diagnoses := get_total_alert_diagnoses(i_lang            => i_lang,
                                                                             i_prof            => i_prof,
                                                                             i_episode         => i_episode,
                                                                             i_diagnosis       => l_diag,
                                                                             i_alert_diagnosis => l_diagnosis(i),
                                                                             i_flg_type        => l_flg_type,
                                                                             i_flg_area        => l_flg_area(i));
                    
                    END IF;
                
                    IF (i_flg_screen = pk_alert_constant.g_diag_area_past_history AND
                       (((l_allow_ph_same_icd = pk_alert_constant.g_no OR
                       nvl(l_terminology_allow_same_icd, pk_alert_constant.g_yes) = pk_alert_constant.g_no) AND
                       r_existing_problem.id_pat_history_diagnosis IS NULL) OR
                       ((l_allow_ph_same_icd = pk_alert_constant.g_yes AND
                       nvl(l_terminology_allow_same_icd, pk_alert_constant.g_yes) = pk_alert_constant.g_yes)) OR
                       (l_count_alert_diagnoses > 0)))
                       OR (i_flg_screen = pk_alert_constant.g_diag_area_problems AND
                       (((l_allow_problems_same_icd = pk_alert_constant.g_no OR
                       nvl(l_terminology_allow_same_icd, pk_alert_constant.g_yes) = pk_alert_constant.g_no) AND
                       r_existing_problem.id_pat_history_diagnosis IS NULL) OR
                       ((l_allow_problems_same_icd = pk_alert_constant.g_yes AND
                       nvl(l_terminology_allow_same_icd, pk_alert_constant.g_yes) = pk_alert_constant.g_yes)) OR
                       (l_count_alert_diagnoses > 0)))
                       OR (i_flg_screen NOT IN
                       (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_problems))
                    THEN
                        l_flg_insert_new_record := pk_alert_constant.g_yes;
                    END IF;
                    --
                    g_error := 'UPDATE FLG_RECENT_DIAG FOR SURGICAL';
                    -- *********************************
                    IF l_flg_other = pk_alert_constant.g_yes
                    THEN
                    
                        SELECT phd.id_pat_history_diagnosis
                          BULK COLLECT
                          INTO l_other_diags
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_alert_diagnosis = l_diagnosis(i)
                           AND id_patient = i_pat
                           AND desc_pat_history_diagnosis = i_desc_pat_history_diagnosis(i)
                           AND phd.id_pat_history_diagnosis_new IS NULL
                           AND nvl(flg_status, pk_alert_constant.g_active) != pk_alert_constant.g_cancelled;
                    
                        IF l_other_diags.exists(1)
                        THEN
                            FOR j IN l_other_diags.first .. l_other_diags.last
                            LOOP
                                ts_pat_history_diagnosis.upd(where_in                   => 'id_pat_history_diagnosis=' ||
                                                                                           l_other_diags(j),
                                                             id_pat_history_diag_new_in => l_seq_phd,
                                                             flg_recent_diag_in         => pk_alert_constant.g_no,
                                                             rows_out                   => l_rowids_2);
                            
                                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                              i_rowids     => l_rowids_2,
                                                              o_error      => o_error);
                            END LOOP;
                        END IF;
                    ELSIF l_flg_insert_new_record = pk_alert_constant.g_yes
                    THEN
                        IF i_doc_area = g_doc_area_past_fam
                        THEN
                            IF i_phd_diagnosis(i) IS NOT NULL
                            THEN
                                ts_pat_history_diagnosis.upd(where_in                   => 'id_pat_history_diagnosis=' ||
                                                                                           i_phd_diagnosis(i) ||
                                                                                           ' and nvl(flg_status, pk_alert_constant.g_active) != ''' ||
                                                                                           pk_alert_constant.g_cancelled ||
                                                                                           ''' and id_pat_history_diagnosis_new is null',
                                                             id_pat_history_diag_new_in => l_seq_phd,
                                                             flg_recent_diag_in         => pk_alert_constant.get_no,
                                                             rows_out                   => l_rowids_2);
                            END IF;
                            ts_pat_history_diagnosis.upd(where_in                   => 'id_alert_diagnosis=' || l_diagnosis(i) ||
                                                                                       ' and id_patient=' || i_pat || ' and flg_type= ''' ||
                                                                                       l_flg_type || '''' || CASE
                                                                                           WHEN i_id_family_relationship(i) IS NOT NULL THEN
                                                                                            ' and id_family_relationship= ' ||
                                                                                            i_id_family_relationship(i)
                                                                                           ELSE
                                                                                            ''
                                                                                       END ||
                                                                                       ' and nvl(flg_status, pk_alert_constant.g_active) != ''' ||
                                                                                       pk_alert_constant.g_cancelled ||
                                                                                       ''' and id_pat_history_diagnosis_new is null',
                                                         id_pat_history_diag_new_in => l_seq_phd,
                                                         flg_recent_diag_in         => pk_alert_constant.get_no,
                                                         rows_out                   => l_rowids_2);
                        ELSE
                            ts_pat_history_diagnosis.upd(where_in                   => 'id_alert_diagnosis=' ||
                                                                                       l_diagnosis(i) ||
                                                                                       ' and id_patient=' || i_pat ||
                                                                                       ' and flg_type= ''' ||
                                                                                       l_flg_type || '''' ||
                                                                                       ' and nvl(flg_status, pk_alert_constant.g_active) != ''' ||
                                                                                       pk_alert_constant.g_cancelled ||
                                                                                       ''' and id_pat_history_diagnosis_new is null',
                                                         id_pat_history_diag_new_in => l_seq_phd,
                                                         flg_recent_diag_in         => pk_alert_constant.get_no,
                                                         rows_out                   => l_rowids_2);
                        END IF;
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                      i_rowids     => l_rowids_2,
                                                      o_error      => o_error);
                    END IF;
                    -- *********************************
                    -- inserts new relevant disease/surgery on the past history table
                    -- PT 19/09/2008 2.4.3.d
                    g_error := 'PROC DECODE PAT_HISTORY_DIAGNOSIS';
                    IF (l_flg_insert_new_record = pk_alert_constant.g_yes OR l_flg_other = pk_alert_constant.g_yes)
                    THEN
                        IF i_flg_nature.exists(i)
                        THEN
                            l_flg_nature := i_flg_nature(i);
                        ELSE
                            l_flg_nature := NULL;
                        END IF;
                    
                        IF i_location.exists(i)
                        THEN
                            l_id_location := i_location(i);
                        ELSE
                            l_id_location := NULL;
                        END IF;
                    
                        IF i_flg_complications.exists(i)
                        THEN
                            l_flg_compl := i_flg_complications(i);
                        ELSE
                            l_flg_compl := NULL;
                        END IF;
                        l_desc_pat_hist_diag := CASE ((l_cnt_desc_phd - i) - abs(l_cnt_desc_phd - i))
                                                    WHEN 0 THEN
                                                     i_desc_pat_history_diagnosis(i)
                                                    ELSE
                                                     NULL
                                                END;
                    
                        IF i_notes.exists(i)
                        THEN
                            l_notes := i_notes(i);
                        END IF;
                    
                        IF i_id_cancel_reason.exists(1)
                        THEN
                            l_id_cancel_reason := i_id_cancel_reason(1);
                        ELSE
                            l_id_cancel_reason := NULL;
                        END IF;
                    
                        IF i_cancel_notes.exists(1)
                        THEN
                            l_cancel_notes := i_cancel_notes(1);
                        ELSE
                            l_cancel_notes := NULL;
                        END IF;
                    
                        IF NOT i_flg_warning.exists(i)
                        THEN
                            l_flg_warning := pk_alert_constant.g_no;
                        ELSE
                            l_flg_warning := nvl(i_flg_warning(i), pk_alert_constant.g_no);
                        END IF;
                    
                        IF i_id_family_relationship.exists(i)
                        THEN
                            l_family_relationship := i_id_family_relationship(i);
                        ELSE
                            l_family_relationship := NULL;
                        END IF;
                    
                        IF i_flg_death_cause.exists(i)
                        THEN
                            l_flg_death_cause := i_flg_death_cause(i);
                        ELSE
                            l_flg_death_cause := NULL;
                        END IF;
                        IF i_familiar_age.exists(i)
                        THEN
                            l_familiar_age := i_familiar_age(i);
                        ELSE
                            l_familiar_age := NULL;
                        END IF;
                        --l_flg_warning        := CASE i_flg_warning.COUNT WHEN 0 THEN NULL ELSE i_flg_warning(1) END;
                        g_error := 'INSERT PAT_HISTORY_DIAGNOSIS';
                    
                        ts_pat_history_diagnosis.ins(id_pat_history_diagnosis_in   => l_seq_phd,
                                                     dt_pat_history_diag_tstz_in   => l_dt_sysdate,
                                                     id_professional_in            => i_prof.id,
                                                     id_institution_in             => i_prof.institution,
                                                     id_patient_in                 => i_pat,
                                                     id_episode_in                 => i_episode,
                                                     flg_status_in                 => i_flg_status(i),
                                                     flg_nature_in                 => l_flg_nature,
                                                     flg_compl_in                  => l_flg_compl,
                                                     id_alert_diagnosis_in         => l_diagnosis(i),
                                                     id_diagnosis_in               => l_diag,
                                                     id_epis_complaint_in          => l_epis_comp,
                                                     flg_recent_diag_in            => pk_alert_constant.get_yes,
                                                     flg_type_in                   => l_flg_type,
                                                     desc_pat_history_diagnosis_in => l_desc_pat_hist_diag,
                                                     notes_in                      => l_notes,
                                                     id_cancel_reason_in           => l_id_cancel_reason,
                                                     cancel_notes_in               => l_cancel_notes,
                                                     flg_warning_in                => l_flg_warning,
                                                     id_cdr_call_in                => i_cdr_call,
                                                     id_intervention_in            => l_intervention,
                                                     dt_execution_in               => l_dt_execution,
                                                     dt_execution_precision_in     => l_dt_execution_precision,
                                                     id_exam_in                    => l_exam,
                                                     flg_area_in                   => l_flg_area(i),
                                                     flg_cda_reconciliation_in     => i_flg_cda_reconciliation,
                                                     dt_diagnosed_in               => l_dt_diagnosed,
                                                     dt_diagnosed_precision_in     => l_dt_diagnosed_precision,
                                                     dt_resolved_in                => l_dt_resolved,
                                                     dt_resolved_precision_in      => l_dt_resolved_precision,
                                                     id_location_in                => l_id_location,
                                                     id_location_inst_owner_in     => CASE
                                                                                          WHEN l_id_location IS NOT NULL THEN
                                                                                           pk_alert_constant.g_inst_all
                                                                                          ELSE
                                                                                           NULL
                                                                                      END,
                                                     id_family_relationship_in     => l_family_relationship,
                                                     flg_death_cause_in            => l_flg_death_cause,
                                                     familiar_age_in               => l_familiar_age,
                                                     rows_out                      => l_rowids_1);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                      i_rowids     => l_rowids_1,
                                                      o_error      => o_error);
                        -- *********************************
                    
                        g_error := 'call set_pat_hist_diag_precau_nc';
                        IF i_precaution_measure.exists(1)
                        THEN
                            IF NOT pk_problems.set_pat_hist_diag_precau_nc(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_id_episode            => i_episode,
                                                                           i_pat                   => i_pat,
                                                                           i_pat_history_diagnosis => l_seq_phd,
                                                                           i_precaution            => i_precaution_measure(i),
                                                                           o_error                 => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        END IF;
                    
                        -- Call the function set_register_by_me_nc
                        g_error := 'call set_register_by_me_nc';
                        IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_episode  => i_episode,
                                                                 i_pat         => i_pat,
                                                                 i_id_problem  => l_seq_phd,
                                                                 i_flg_type    => 'D',
                                                                 i_flag_active => pk_alert_constant.g_yes,
                                                                 o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        IF l_flg_area(i) IN (pk_alert_constant.g_diag_area_past_history,
                                             pk_alert_constant.g_diag_area_surgical_hist,
                                             pk_alert_constant.g_diag_area_family_hist)
                           AND (i_flg_screen = pk_alert_constant.g_diag_area_past_history OR l_performed_by_doctor)
                        THEN
                            g_error := 'call set_pat_problem_review';
                            IF NOT pk_review.set_review(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_record_area => l_seq_phd,
                                                        i_flg_context    => pk_review.get_past_history_context,
                                                        i_dt_review      => nvl(i_dt_review, current_timestamp),
                                                        i_review_notes   => NULL,
                                                        i_episode        => i_episode,
                                                        i_flg_auto       => pk_alert_constant.g_yes,
                                                        i_revision       => NULL,
                                                        o_error          => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        END IF;
                        -- integration of medical notes ****************
                        -- verify if we are processing medical history
                    
                        IF l_doc_area(i) = g_doc_area_past_med
                        THEN
                            -- find which section is being saved
                            l_curr_session := g_rds_session;
                            l_next         := l_seq_phd;
                            IF l_diag IS NULL
                            THEN
                                l_curr_session := g_pbm_session;
                            END IF;
                        
                        END IF;
                        -- ***************************************           
                    END IF;
                ELSE
                
                    IF i_desc_pat_history_diagnosis.exists(1)
                    THEN
                        l_cnt_desc_phd := i_desc_pat_history_diagnosis.count;
                    ELSE
                        l_cnt_desc_phd := 0;
                    END IF;
                
                    IF i_flg_status.exists(1)
                    THEN
                        l_cnt_status := i_flg_status.count;
                    ELSE
                        l_cnt_status := 0;
                    END IF;
                
                    -- *********************************
                    -- inserts new relevant disease/surgery on the past history table
                    -- PT 19/09/2008 2.4.3.d
                    g_error := 'PROC DECODE PAT_HISTORY_DIAGNOSIS (2)';
                
                    IF i_location.exists(i)
                    THEN
                        l_id_location := i_location(i);
                    ELSE
                        l_id_location := NULL;
                    END IF;
                
                    IF i_flg_nature.exists(i)
                    THEN
                        l_flg_nature := i_flg_nature(i);
                    ELSE
                        l_flg_nature := NULL;
                    END IF;
                
                    IF i_flg_complications.exists(i)
                    THEN
                        l_flg_compl := i_flg_complications(i);
                    ELSE
                        l_flg_compl := NULL;
                    END IF;
                
                    IF i_id_family_relationship.exists(i)
                    THEN
                        l_family_relationship := i_id_family_relationship(i);
                    ELSE
                        l_family_relationship := NULL;
                    END IF;
                
                    IF i_flg_death_cause.exists(i)
                    THEN
                        l_flg_death_cause := i_flg_death_cause(i);
                    ELSE
                        l_flg_death_cause := NULL;
                    END IF;
                    IF i_familiar_age.exists(i)
                    THEN
                        l_familiar_age := i_familiar_age(i);
                    ELSE
                        l_familiar_age := NULL;
                    END IF;
                
                    l_desc_pat_hist_diag := CASE ((l_cnt_desc_phd - i) - abs(l_cnt_desc_phd - i))
                                                WHEN 0 THEN
                                                 i_desc_pat_history_diagnosis(i)
                                                ELSE
                                                 NULL
                                            END;
                
                    IF i_notes.exists(i)
                    THEN
                        l_notes := i_notes(i);
                    END IF;
                
                    l_flg_status_ins := CASE l_cnt_status
                                            WHEN 0 THEN
                                             NULL
                                            ELSE
                                             i_flg_status(1)
                                        END;
                
                    IF i_id_cancel_reason.exists(1)
                    THEN
                        l_id_cancel_reason := i_id_cancel_reason(1);
                    ELSE
                        l_id_cancel_reason := NULL;
                    END IF;
                
                    IF i_cancel_notes.exists(1)
                    THEN
                        l_cancel_notes := i_cancel_notes(1);
                    ELSE
                        l_cancel_notes := NULL;
                    END IF;
                
                    IF NOT i_flg_warning.exists(i)
                    THEN
                        l_flg_warning := pk_alert_constant.g_no;
                    ELSE
                        l_flg_warning := nvl(i_flg_warning(i), pk_alert_constant.g_no);
                    END IF;
                
                    --l_flg_warning        := CASE i_flg_warning.COUNT WHEN 0 THEN NULL ELSE i_flg_warning(1) END;
                    g_error := 'INSERT PAT_HISTORY_DIAGNOSIS (2)';
                    ts_pat_history_diagnosis.ins(id_pat_history_diagnosis_in   => l_seq_phd,
                                                 dt_pat_history_diag_tstz_in   => l_dt_sysdate,
                                                 id_professional_in            => i_prof.id,
                                                 id_institution_in             => i_prof.institution,
                                                 id_patient_in                 => i_pat,
                                                 id_episode_in                 => i_episode,
                                                 flg_status_in                 => l_flg_status_ins,
                                                 flg_nature_in                 => l_flg_nature,
                                                 flg_compl_in                  => l_flg_compl,
                                                 id_epis_complaint_in          => l_epis_comp,
                                                 flg_recent_diag_in            => pk_alert_constant.get_yes,
                                                 flg_type_in                   => l_flg_type,
                                                 desc_pat_history_diagnosis_in => l_desc_pat_hist_diag,
                                                 notes_in                      => l_notes,
                                                 id_cancel_reason_in           => l_id_cancel_reason,
                                                 cancel_notes_in               => l_cancel_notes,
                                                 flg_warning_in                => l_flg_warning,
                                                 id_cdr_call_in                => i_cdr_call,
                                                 id_intervention_in            => l_intervention,
                                                 dt_execution_in               => l_dt_execution,
                                                 dt_execution_precision_in     => l_dt_execution_precision,
                                                 id_exam_in                    => l_exam,
                                                 flg_area_in                   => l_flg_area(i),
                                                 flg_cda_reconciliation_in     => i_flg_cda_reconciliation,
                                                 dt_diagnosed_in               => l_dt_diagnosed,
                                                 dt_diagnosed_precision_in     => l_dt_diagnosed_precision,
                                                 dt_resolved_in                => l_dt_resolved,
                                                 dt_resolved_precision_in      => l_dt_resolved_precision,
                                                 id_location_in                => l_id_location,
                                                 id_location_inst_owner_in     => CASE
                                                                                      WHEN l_id_location IS NOT NULL THEN
                                                                                       pk_alert_constant.g_inst_all
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                 id_family_relationship_in     => l_family_relationship,
                                                 flg_death_cause_in            => l_flg_death_cause,
                                                 familiar_age_in               => l_familiar_age,
                                                 rows_out                      => l_rowids_1);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                  i_rowids     => l_rowids_1,
                                                  o_error      => o_error);
                    -- *********************************
                    g_error := 'call set_pat_hist_diag_precau_nc';
                    IF i_precaution_measure.exists(1)
                    THEN
                        IF NOT pk_problems.set_pat_hist_diag_precau_nc(i_lang                  => i_lang,
                                                                       i_prof                  => i_prof,
                                                                       i_id_episode            => i_episode,
                                                                       i_pat                   => i_pat,
                                                                       i_pat_history_diagnosis => l_seq_phd,
                                                                       i_precaution            => i_precaution_measure(i),
                                                                       o_error                 => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                
                    g_error := 'call set_register_by_me_nc';
                    IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_episode,
                                                             i_pat         => i_pat,
                                                             i_id_problem  => l_seq_phd,
                                                             i_flg_type    => 'D',
                                                             i_flag_active => pk_alert_constant.g_yes,
                                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'call set_pat_problem_review';
                    IF l_flg_area(i) IN (pk_alert_constant.g_diag_area_past_history,
                                         pk_alert_constant.g_diag_area_surgical_hist,
                                         pk_alert_constant.g_diag_area_family_hist)
                       AND (i_flg_screen = pk_alert_constant.g_diag_area_past_history OR l_performed_by_doctor)
                    THEN
                        IF NOT pk_review.set_review(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_record_area => l_seq_phd,
                                                    i_flg_context    => pk_review.get_past_history_context,
                                                    i_dt_review      => nvl(i_dt_review, current_timestamp),
                                                    i_review_notes   => NULL,
                                                    i_episode        => i_episode,
                                                    i_flg_auto       => pk_alert_constant.g_yes,
                                                    i_revision       => NULL,
                                                    o_error          => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                    -- integration of medical notes ****************
                    -- verify if we are processing medical history
                
                    IF l_doc_area(i) = g_doc_area_past_med
                    THEN
                    
                        -- find which section is being saved
                        l_curr_session := g_rds_session;
                        l_next         := l_seq_phd;
                    
                        IF l_diag IS NULL
                        THEN
                            l_curr_session := g_pbm_session;
                        END IF;
                    
                    END IF;
                    -- ***************************************                         
                    g_error                      := 'IF G_FOUND';
                    l_desc_pat_history_diagnosis := i_desc_pat_history_diagnosis;
                    IF NOT l_desc_pat_history_diagnosis.exists(1)
                    THEN
                        l_desc_pat_history_diagnosis := table_varchar(NULL);
                    END IF;
                    IF NOT l_diagnosis.exists(1)
                    THEN
                        l_diagnosis := table_number(NULL);
                    END IF;
                
                    IF g_found
                       OR l_diagnosis(1) NOT IN (g_diag_unknown, g_diag_none, g_diag_non_remark)
                       OR (l_desc_pat_history_diagnosis(1) IS NOT NULL AND i_diagnosis(1) IS NULL) -- free text problem registration
                    --OR l_diagnosis(1) <> -500
                    THEN
                        -- if record is based on a previous record, then previous record(s) must be marked as outdated
                        g_error := 'CHECK OUTDATED';
                        IF i_phd_outdated IS NOT NULL
                           AND i_episode IS NOT NULL
                        THEN
                            -- current ID invalidates the previous entry (the outdated record)
                            g_error := 'UPDATE pat_history_diagnosis';
                            ts_pat_history_diagnosis.upd(id_pat_history_diag_new_in => l_seq_phd,
                                                         flg_recent_diag_in         => pk_alert_constant.get_no,
                                                         where_in                   => 'id_patient = ' || i_pat ||
                                                                                       ' AND id_pat_history_diagnosis = ' ||
                                                                                       i_phd_outdated,
                                                         rows_out                   => l_rowids_upd);
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                                          i_rowids     => l_rowids_upd,
                                                          o_error      => o_error);
                        END IF;
                    END IF;
                END IF;
                --         
            
            END IF;
        END LOOP;
        --
    
        --ASantos 21-11-20011
        --ALERT-195554 - Chile | Ability to interface information regarding management of GES
        IF o_seq_phd IS NOT NULL
           AND o_seq_phd.count > 0
           AND l_flg_type IN (g_alert_diag_type_med, g_alert_diag_type_surg)
           AND i_doc_area <> g_doc_area_past_fam
        THEN
            FOR r_phd IN (SELECT column_value id_pat_history_diagnosis
                            FROM TABLE(o_seq_phd))
            LOOP
                IF NOT pk_epis_er_law_api.create_epis_ges_msg(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_episode               => i_episode,
                                                              i_pat_history_diagnosis => r_phd.id_pat_history_diagnosis,
                                                              i_epis_diagnosis        => NULL,
                                                              i_flg_origin            => l_flg_type,
                                                              o_epis_ges_msg          => l_epis_ges_msg,
                                                              o_error                 => o_error)
                THEN
                    RAISE pk_epis_er_law_core.g_ges_exception;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_epis_er_law_core.g_ges_exception THEN
            pk_utils.undo_changes;
            RAISE pk_epis_er_law_core.g_ges_exception;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_past_hist_diagnosis',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_past_hist_diagnosis;
    --

    /********************************************************************************************
    * Records new diagnosis on the past medical and surgical history for this episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode when this/these problems were registered    
    * @param i_pat                    Patient ID 
    * @param i_doc_area               Doc Area ID
    * @param i_flg_status             Array of problem status
    * @param i_flg_nature             Array of problem nature
    * @param i_diagnosis              Array of relevant diseases' ID (in case of a past medical history record)
    * @param i_phd_outdated           Pat History Diagnosis/Pat notes ID fot the edited record (outdated)
    * @param i_desc_pat_history_diagnosis  Descriptions (when it's not based on an alert_diagnosis)
    * @param i_notes                  Notes if it was created through the problem screen  
    * @param i_id_cancel_reason       Cancelation reason ID
    * @param i_cancel_notes           Cancelation notes  
    * @param o_msg                    Message to show
    * @param o_msg_title              Message title to show
    * @param o_flg_show               If it should show message or not
    * @param o_button                 Button type
    * @param i_precaution_measure     list of arrays with precuation measures   
    * @param i_flg_warning            list of flag warning,
    * @param i_ph_ft_id               Patient past history free text ID
    * @param i_ph_ft_text             Patient past history free text    
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2010-Dec-09
    **********************************************************************************************/
    FUNCTION set_past_hist_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar,
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_ph_ft_id                   IN pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        i_ph_ft_text                 IN pat_past_hist_free_text.text%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_dt_register                IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_review                  IN review_detail.dt_review%TYPE,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        o_seq_phd                    OUT table_number,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ph_ft_id       pat_past_hist_ft_hist.id_pat_ph_ft%TYPE;
        l_pat_ph_ft_hist pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
        l_flg_nature     table_varchar;
        l_flg_compl      table_varchar;
        l_flg_area       table_varchar;
    BEGIN
    
        -- Check if any diagnosis is available to add
        IF i_diagnosis.exists(1)
           OR (NOT i_diagnosis.exists(1) AND (i_exam.exists(1) OR i_intervention.exists(1)))
        THEN
            IF i_doc_area = pk_past_history.g_doc_area_past_fam
            THEN
                l_flg_area := table_varchar(pk_alert_constant.g_diag_area_family_hist);
            
            ELSE
                l_flg_area := table_varchar(pk_alert_constant.g_diag_area_past_history);
                IF i_doc_area = 46
                THEN
                    l_flg_compl  := i_flg_nature;
                    l_flg_nature := NULL;
                ELSE
                    l_flg_compl  := NULL;
                    l_flg_nature := i_flg_nature;
                END IF;
            END IF;
            -- Save past history not in free text
            IF NOT set_past_hist_diagnosis(i_lang                       => i_lang,
                                           i_prof                       => i_prof,
                                           i_episode                    => i_episode,
                                           i_pat                        => i_pat,
                                           i_doc_area                   => i_doc_area,
                                           i_flg_status                 => i_flg_status,
                                           i_flg_nature                 => l_flg_nature,
                                           i_diagnosis                  => i_diagnosis,
                                           i_phd_outdated               => i_phd_outdated,
                                           i_desc_pat_history_diagnosis => i_desc_pat_history_diagnosis,
                                           i_notes                      => i_notes,
                                           i_id_cancel_reason           => i_id_cancel_reason,
                                           i_cancel_notes               => i_cancel_notes,
                                           i_precaution_measure         => i_precaution_measure,
                                           i_flg_warning                => i_flg_warning,
                                           i_dt_register                => i_dt_register,
                                           i_exam                       => i_exam,
                                           i_intervention               => i_intervention,
                                           dt_execution                 => dt_execution,
                                           i_dt_execution_precision     => i_dt_execution_precision,
                                           i_cdr_call                   => i_cdr_call,
                                           i_dt_review                  => i_dt_review,
                                           i_flg_area                   => l_flg_area,
                                           i_flg_complications          => l_flg_compl,
                                           i_dt_diagnosed               => i_dt_diagnosed,
                                           i_dt_diagnosed_precision     => i_dt_diagnosed_precision,
                                           i_dt_resolved                => NULL,
                                           i_dt_resolved_precision      => NULL,
                                           i_location                   => NULL,
                                           i_id_family_relationship     => i_id_family_relationship,
                                           i_flg_death_cause            => i_flg_death_cause,
                                           i_familiar_age               => i_familiar_age,
                                           i_phd_diagnosis              => i_phd_diagnosis,
                                           o_seq_phd                    => o_seq_phd,
                                           o_error                      => o_error)
            THEN
                g_error := 'set_past_hist_diagnosis has failed';
                RAISE g_exception;
            END IF;
        
        END IF;
    
        --Check i there is any text to add
        IF i_ph_ft_text IS NOT NULL
        THEN
            -- Save past history in free text
            IF NOT pk_past_history.set_past_hist_free_text(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_pat              => i_pat,
                                                           i_episode          => i_episode,
                                                           i_doc_area         => i_doc_area,
                                                           i_ph_ft_id         => i_ph_ft_id,
                                                           i_ph_ft_text       => i_ph_ft_text,
                                                           i_id_cancel_reason => NULL,
                                                           i_cancel_notes     => NULL,
                                                           i_dt_register      => i_dt_register,
                                                           i_dt_review        => i_dt_review,
                                                           o_ph_ft_id         => l_ph_ft_id,
                                                           o_pat_ph_ft_hist   => l_pat_ph_ft_hist,
                                                           o_error            => o_error)
            THEN
                g_error := 'set_past_hist_free_text has failed';
                RAISE g_exception;
            END IF;
        END IF;
    
        -- Execute set_first_obs
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_dt_register,
                                      i_dt_first_obs        => i_dt_register,
                                      o_error               => o_error)
        THEN
            g_error := 'set_first_obs has failed';
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_epis_er_law_core.g_ges_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING SET_PAST_HIST_ALL FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'set_past_hist_all',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_past_hist_all',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_past_hist_all;
    --

    /**
     * This functions sets a past history as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
     * @reason   ALERT-52344
    */
    FUNCTION set_past_history_review
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_past_history       IN table_number,
        i_review_notes          IN review_detail.review_notes%TYPE,
        i_ft_flg                IN table_varchar,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_review review_detail.dt_review%TYPE;
        l_review_id   pat_past_hist_free_text.id_pat_ph_ft%TYPE;
    
    BEGIN
    
        g_error := 'SET_PAT_HISTORY_REVIEW';
    
        l_date_review := current_timestamp;
    
        FOR i IN 1 .. i_id_past_history.count
        LOOP
            IF i_ft_flg(i) = pk_alert_constant.get_no
            THEN
                g_past_hist_review_area := pk_review.get_past_history_context;
                l_review_id             := i_id_past_history(i);
            ELSE
                g_past_hist_review_area := pk_review.get_past_history_ft_context;
            
                SELECT pphfth.id_pat_ph_ft
                  INTO l_review_id
                  FROM pat_past_hist_ft_hist pphfth
                 WHERE pphfth.id_pat_ph_ft_hist = i_id_past_history(i);
            
            END IF;
        
            IF NOT pk_review.set_review(i_lang,
                                        i_prof,
                                        l_review_id,
                                        g_past_hist_review_area,
                                        l_date_review,
                                        i_review_notes,
                                        i_episode,
                                        pk_alert_constant.g_no,
                                        NULL,
                                        o_error)
            THEN
                g_error := 'set_review has failed';
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        IF i_id_epis_documentation IS NOT NULL
        THEN
            IF NOT set_template_review(i_lang                  => i_lang,
                                       i_prof                  => i_prof,
                                       i_episode               => i_episode,
                                       i_id_epis_documentation => i_id_epis_documentation,
                                       i_review_notes          => i_review_notes,
                                       i_dt_review             => l_date_review,
                                       o_error                 => o_error)
            THEN
                g_error := 'set_template_review has failed';
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING SET_PAT_HISTORY_REVIEW FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HISTORY_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PAST_HISTORY',
                                              'SET_PAST_HISTORY_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_past_history_review;
    --

    /**
    * This functions used in patient match functionality
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return BOOLEAN
    *
    * @version  2.6.0.5
    * @since    2011-JAN-26
    * @author   Rui Duarte
    * @reason   ALERT-28215
    */
    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where         VARCHAR2(200 CHAR);
        l_table_name    VARCHAR2(200 CHAR);
        l_column_name   VARCHAR2(200 CHAR);
        l_error_message VARCHAR2(200 CHAR);
        l_rowids        table_varchar;
    BEGIN
        /***************************************
        Init common vars
        ***************************************/
        --Where condition used in ts pk's          
        l_where := ' id_patient = ' || i_patient_temp;
        --Update column
        l_column_name := 'ID_PATIENT';
        --Error message
        l_error_message := 'Failed updating table: ';
    
        /****************************************************
        Update diagnosis Past History records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_HISTORY_DIAGNOSIS';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_history_diagnosis.upd(where_in => l_where, id_patient_in => i_patient, rows_out => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column_name));
    
        /****************************************************
        Update free text Past History main table records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_PAST_HIST_FREE_TEXT';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_past_hist_free_text.upd(where_in => l_where, id_patient_in => i_patient, rows_out => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column_name));
    
        /****************************************************
        Update free text Past History history table records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_PAST_HIST_FT_HIST';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_past_hist_ft_hist.upd(where_in => l_where, id_patient_in => i_patient, rows_out => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column_name));
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PAST_HISTORY',
                                              'SET_MATCH_PATIENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_patient;
    --

    /**
     * This functions used in episode match functionality
     *
     * @param i_lang                          Language ID
     * @param i_prof                          Profissional array
     * @param i_episode                       Episode identifier
     * @param i_episode_temp                  Temporary episode 
     * @param o_error error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.0.5
     * @since    2011-JAN-26
     * @author   Rui Duarte
     * @reason   ALERT-28215
    */
    FUNCTION set_match_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where         VARCHAR2(200 CHAR);
        l_table_name    VARCHAR2(200 CHAR);
        l_column1_name  VARCHAR2(200 CHAR);
        l_column2_name  VARCHAR2(200 CHAR);
        l_error_message VARCHAR2(200 CHAR);
        l_new_visit     visit.id_visit%TYPE;
        l_rowids        table_varchar;
    BEGIN
        /***************************************
        Init common vars
        ***************************************/
        --Where condition used in ts pk's          
        l_where := ' id_episode = ' || i_episode_temp;
        --Update columns
        l_column1_name := 'ID_EPISODE';
        l_column2_name := 'ID_VISIT';
        --Error message
        l_error_message := 'Failed updating table: ';
    
        -- Get new visit ID
        l_new_visit := prv_get_epis_visit_id(i_episode);
    
        /****************************************************
        Update diagnosis Past History records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_HISTORY_DIAGNOSIS';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_history_diagnosis.upd(where_in => l_where, id_episode_in => i_episode, rows_out => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column1_name, l_column2_name));
    
        /****************************************************
        Update free text Past History main table records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_PAST_HIST_FREE_TEXT';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_past_hist_free_text.upd(where_in      => l_where,
                                       id_episode_in => i_episode,
                                       id_visit_in   => l_new_visit,
                                       rows_out      => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column1_name, l_column2_name));
    
        /****************************************************
        Update free text Past History history table records
        ****************************************************/
        --Init vars
        l_table_name := 'PAT_PAST_HIST_FT_HIST';
        g_error      := l_error_message || l_table_name;
        l_rowids     := table_varchar();
        --Update table
        ts_pat_past_hist_ft_hist.upd(where_in      => l_where,
                                     id_episode_in => i_episode,
                                     id_visit_in   => l_new_visit,
                                     rows_out      => l_rowids);
        --Data gov update
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => l_table_name,
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar(l_column1_name, l_column2_name));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PAST_HISTORY',
                                              'SET_MATCH_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_episode;
    --

    /********************************************************************************************
    * Cancels records for past history
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_record_id              Pat History Diagnosis ID or Free Text ID
    * @param i_ph_free_text           Value that indicates if "i_record_id" is a past_history_diagnosis_id or a free_text_id
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param i_id_epis_documentation  Template info ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/05
    *
    * @reviewed                       Sergio Dias
    * @version                        2.6.1.2
    * @since                          Jun-30-2011
    **********************************************************************************************/
    FUNCTION cancel_past_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_record_id             IN NUMBER,
        i_ph_free_text          IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_id_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes          IN pat_problem_hist.cancel_notes%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_screen                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_pat_history_diagnosis pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_past_hist_ft_id          pat_past_hist_free_text.id_visit%TYPE;
        l_date_cancel              pat_past_hist_free_text.dt_register%TYPE;
    
        l_flg_show      sys_message.desc_message%TYPE;
        l_msg_title     sys_message.desc_message%TYPE;
        l_msg_text      sys_message.desc_message%TYPE;
        l_button        sys_message.desc_message%TYPE;
        l_ids_to_delete table_number;
        l_ph_episode    episode.id_episode%TYPE; -- EMR-030
    
    BEGIN
        --Set cancel date to be the same in all formats
        l_date_cancel := current_timestamp;
    
        IF i_ph_free_text = pk_alert_constant.g_no
           AND i_record_id IS NOT NULL
        THEN
            --Get pat_history_diagnosis date to get free text records and other records that are grouped with this one
            SELECT dt_pat_history_diagnosis_tstz, phd.id_episode
              INTO l_dt_pat_history_diagnosis, l_ph_episode
              FROM pat_history_diagnosis phd
             WHERE phd.id_pat_history_diagnosis = i_record_id;
        
            IF i_screen <> pk_alert_constant.g_diag_area_problems
            THEN
                -- get records that were created at the same time to cancel them all (they appear grouped in the PH screens)
                SELECT phd.id_pat_history_diagnosis
                  BULK COLLECT
                  INTO l_ids_to_delete
                  FROM pat_history_diagnosis phd
                 WHERE phd.dt_pat_history_diagnosis_tstz = l_dt_pat_history_diagnosis
                   AND phd.id_patient = i_id_patient
                   AND phd.id_episode = l_ph_episode -- EMR-030
                   AND id_pat_history_diagnosis_new IS NULL;
            END IF;
        
            --Get pat_history_diagnosis date to get free text records(if they exist) 
            BEGIN
                SELECT pphft.id_pat_ph_ft
                  INTO l_past_hist_ft_id
                  FROM pat_past_hist_free_text pphft
                 WHERE pphft.dt_register = l_dt_pat_history_diagnosis;
            EXCEPTION
                WHEN no_data_found THEN
                    l_past_hist_ft_id := NULL;
            END;
            --Free text id was provided
        ELSIF i_record_id IS NOT NULL
        THEN
            l_past_hist_ft_id := i_record_id;
            --Get pat_history_diagnosis records
            BEGIN
                SELECT pphft.id_pat_ph_ft
                  INTO l_past_hist_ft_id
                  FROM pat_past_hist_free_text pphft
                 WHERE pphft.id_pat_ph_ft = (SELECT pphfth.id_pat_ph_ft
                                               FROM pat_past_hist_ft_hist pphfth
                                              WHERE pphfth.id_pat_ph_ft_hist = i_record_id);
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        END IF;
    
        IF i_screen = pk_alert_constant.g_diag_area_problems
        THEN
            -- if this cancel action came from the problems screen, ignores the related records and only deletes the one selected in the problems screen
            l_ids_to_delete := table_number(i_record_id);
        END IF;
    
        IF l_ids_to_delete.exists(1)
           AND i_ph_free_text = pk_alert_constant.g_no
        THEN
            FOR i IN l_ids_to_delete.first .. l_ids_to_delete.last
            LOOP
                --Cancel diagnosis records
                IF NOT prv_cancel_past_hist_diagnosis(i_lang                     => i_lang,
                                                      i_prof                     => i_prof,
                                                      i_pat                      => i_id_patient,
                                                      i_id_pat_history_diagnosis => l_ids_to_delete(i),
                                                      i_id_cancel_reason         => i_id_cancel_reason,
                                                      i_cancel_notes             => i_cancel_notes,
                                                      i_date                     => l_date_cancel,
                                                      o_error                    => o_error)
                THEN
                    g_error := 'prv_cancel_past_hist_diagnosis has failed';
                    RAISE g_exception;
                END IF;
            END LOOP;
        END IF;
    
        --Cancel free text
        IF l_past_hist_ft_id IS NOT NULL
        THEN
            IF NOT prv_cancel_past_hist_free_text(i_lang,
                                                  i_prof,
                                                  i_doc_area,
                                                  i_id_episode,
                                                  i_id_patient,
                                                  l_past_hist_ft_id,
                                                  i_id_cancel_reason,
                                                  i_cancel_notes,
                                                  l_date_cancel,
                                                  o_error)
            THEN
                g_error := 'prv_cancel_past_hist_free_text has failed';
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -- cancel template info   
        IF i_id_epis_documentation IS NOT NULL
        THEN
            IF NOT pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_epis_doc   => i_id_epis_documentation,
                                                             i_notes         => i_cancel_notes,
                                                             i_test          => pk_alert_constant.g_no,
                                                             i_cancel_reason => i_id_cancel_reason,
                                                             o_flg_show      => l_flg_show,
                                                             o_msg_title     => l_msg_title,
                                                             o_msg_text      => l_msg_text,
                                                             o_button        => l_button,
                                                             o_error         => o_error)
            THEN
                g_error := 'cancel template info has failed';
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -- Execute set_first_obs
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_date_cancel,
                                      i_dt_first_obs        => l_date_cancel,
                                      o_error               => o_error)
        THEN
            g_error := 'set_first_obs has failed';
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING CANCEL_PAST_HIST FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAST_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAST_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_past_history;

    FUNCTION check_birth_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_doc_template        IN doc_template.id_doc_template%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        o_show_msg            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age           patient.age%TYPE;
        l_msg           VARCHAR2(32767);
        l_internal_name doc_element.internal_name%TYPE;
        l_show_msg      VARCHAR2(1 CHAR);
        l_cong_anom1    VARCHAR2(2000 CHAR);
        l_cong_anom2    VARCHAR2(2000 CHAR);
        l_code_msg      VARCHAR2(0100 CHAR) := 'PAST_HISTORY_M121';
        --  l_num
    BEGIN
        l_msg := pk_message.get_message(i_lang, 'COMMON_M080');
    
        FOR i IN i_id_doc_element.first .. i_id_doc_element.last
        LOOP
            SELECT internal_name
              INTO l_internal_name
              FROM doc_element d
             WHERE d.id_doc_element = i_id_doc_element(i);
        
            IF l_internal_name = g_int_name_cong_anom1
            THEN
                l_cong_anom1 := i_value(i);
            ELSIF l_internal_name = g_int_name_cong_anom2
            THEN
                l_cong_anom2 := i_value(i);
            END IF;
        END LOOP;
    
        IF length(l_cong_anom1) > 40
           OR length(l_cong_anom2) > 40
        THEN
            l_msg      := l_msg || chr(10) || pk_message.get_message(i_lang, l_code_msg);
            l_show_msg := pk_alert_constant.g_yes;
        END IF;
        o_show_msg := l_show_msg;
        o_msg      := l_msg;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BIRTH_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_birth_history;
    --
    /**
    * @author  Sergio Dias
    * @version 2.6.1.1
    * @since   May-30-2011
    */
    FUNCTION set_past_hist_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar, --13
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_ph_ft_id                   IN pat_past_hist_free_text.id_pat_ph_ft%TYPE, --18
        i_ph_ft_text                 IN pat_past_hist_free_text.text%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        --
        i_prof_cat_type         IN category.flg_type%TYPE, --28
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number, --34
        i_value                 IN table_varchar,
        i_notes_template        IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL, --40
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number, --46
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number, --49
        o_seq_phd               OUT table_number,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30 CHAR) := 'SET_PAST_HIST_ALL';
        l_date        TIMESTAMP := current_timestamp;
        l_review_date TIMESTAMP := current_timestamp;
        l_validations sys_config.id_sys_config%TYPE;
        l_msg         VARCHAR2(32767);
        l_show_msg    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_error_in    t_error_in := t_error_in();
        l_warning     EXCEPTION;
        l_ret         BOOLEAN;
    
    BEGIN
        -- store template info 
        IF i_id_documentation IS NOT NULL
           OR i_notes_template IS NOT NULL
        THEN
            IF i_id_documentation.count > 0
               OR i_notes_template IS NOT NULL
            THEN
                l_validations := pk_sysconfig.get_config(g_birth_hist_validation_config, i_prof);
                IF i_doc_area = g_doc_area_cong_anom
                   AND l_validations = pk_alert_constant.g_yes
                THEN
                    IF NOT check_birth_history(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_doc_area            => i_doc_area,
                                               i_doc_template        => i_doc_template,
                                               i_epis_documentation  => i_epis_documentation,
                                               i_id_documentation    => i_id_documentation,
                                               i_id_doc_element      => i_id_doc_element,
                                               i_id_doc_element_crit => i_id_doc_element_crit,
                                               i_value               => i_value,
                                               o_show_msg            => l_show_msg,
                                               o_msg                 => l_msg,
                                               o_error               => o_error)
                    
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_show_msg = pk_alert_constant.g_yes
                    THEN
                        RAISE l_warning;
                    END IF;
                END IF;
            
                IF NOT pk_touch_option.set_epis_documentation(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => i_prof_cat_type,
                                                              i_epis                  => i_episode,
                                                              i_doc_area              => i_doc_area,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => i_epis_documentation,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => i_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_notes_template,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_epis_context,
                                                              i_summary_and_notes     => i_summary_and_notes,
                                                              i_episode_context       => i_episode_context,
                                                              i_flg_table_origin      => i_flg_table_origin,
                                                              i_vs_element_list       => i_vs_element_list,
                                                              i_vs_save_mode_list     => i_vs_save_mode_list,
                                                              i_vs_list               => i_vs_list,
                                                              i_vs_value_list         => i_vs_value_list,
                                                              i_vs_uom_list           => i_vs_uom_list,
                                                              i_vs_scales_list        => i_vs_scales_list,
                                                              i_vs_date_list          => i_vs_date_list,
                                                              i_vs_read_list          => i_vs_read_list,
                                                              o_epis_documentation    => o_epis_documentation,
                                                              o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                SELECT ed.dt_creation_tstz
                  INTO l_date
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation = o_epis_documentation;
            
                --updated the review date, otherwise the review date is lower than the template registration date
                l_review_date := current_timestamp;
            
                IF NOT pk_review.set_review(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_record_area => o_epis_documentation,
                                            i_flg_context    => pk_review.get_template_context,
                                            i_dt_review      => l_review_date,
                                            i_review_notes   => NULL,
                                            i_episode        => i_episode,
                                            i_flg_auto       => pk_alert_constant.g_no,
                                            o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END IF;
    
        -- store coded and free text info (the function checks if there is anything to store)
        IF NOT pk_past_history.set_past_hist_all(i_lang                       => i_lang,
                                                 i_prof                       => i_prof,
                                                 i_episode                    => i_episode,
                                                 i_pat                        => i_pat,
                                                 i_doc_area                   => i_doc_area,
                                                 i_dt_diagnosed               => i_dt_diagnosed,
                                                 i_dt_diagnosed_precision     => i_dt_diagnosed_precision,
                                                 i_flg_status                 => i_flg_status,
                                                 i_flg_nature                 => i_flg_nature,
                                                 i_diagnosis                  => i_diagnosis,
                                                 i_phd_outdated               => i_phd_outdated,
                                                 i_desc_pat_history_diagnosis => i_desc_pat_history_diagnosis,
                                                 i_notes                      => i_notes,
                                                 i_id_cancel_reason           => i_id_cancel_reason,
                                                 i_cancel_notes               => i_cancel_notes,
                                                 i_precaution_measure         => i_precaution_measure,
                                                 i_flg_warning                => i_flg_warning,
                                                 i_ph_ft_id                   => i_ph_ft_id,
                                                 i_ph_ft_text                 => i_ph_ft_text,
                                                 i_exam                       => i_exam,
                                                 i_intervention               => i_intervention,
                                                 dt_execution                 => dt_execution,
                                                 i_dt_execution_precision     => i_dt_execution_precision,
                                                 i_cdr_call                   => i_cdr_call,
                                                 i_dt_register                => l_date,
                                                 i_dt_review                  => l_review_date,
                                                 i_id_family_relationship     => i_id_family_relationship,
                                                 i_flg_death_cause            => i_flg_death_cause,
                                                 i_familiar_age               => i_familiar_age,
                                                 i_phd_diagnosis              => i_phd_diagnosis,
                                                 o_seq_phd                    => o_seq_phd,
                                                 o_error                      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_warning THEN
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => NULL,
                                              i_sqlerrm     => l_msg,
                                              i_message     => l_msg,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_action_type => 'U',
                                              i_function    => l_func_name,
                                              o_error       => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_past_hist_all;
    --
    /********************************************************************************************
    * Creates a review for a template record
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_episode                   Episode ID
    * @param i_id_epis_documentation     Episode documentation ID
    * @param i_review_notes              Review notes
    * @param i_dt_review                 Review Date
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION set_template_review
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_review_notes          IN review_detail.review_notes%TYPE,
        i_dt_review             IN review_detail.dt_review%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'SET_TEMPLATE_REVIEW';
    BEGIN
    
        g_error := 'CALL TO PK_REVIEW.SET_REVIEW';
        pk_alertlog.log_debug(text => g_error);
    
        IF NOT pk_review.set_review(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_record_area => i_id_epis_documentation,
                                    i_flg_context    => pk_review.get_template_context,
                                    i_dt_review      => nvl(i_dt_review, current_timestamp),
                                    i_review_notes   => i_review_notes,
                                    i_episode        => i_episode,
                                    i_flg_auto       => pk_alert_constant.g_no,
                                    i_revision       => NULL,
                                    o_error          => o_error)
        THEN
            g_error := 'set_review has failed';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_template_review;
    --
    /********************************************************************************************
    * Gets free text record for a specific documentation area
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_current_episode           Episode ID
    * @param i_scope                     Scope ID
    * @param i_scope_type                Scope type
    * @param i_doc_area                  Doc_Area ID
    * @param o_doc_area_register         Register Cursor (left side on screen)
    * @param o_doc_area_val              Values Cursor (right side on screen)
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_free_text
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT NOCOPY pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    
        l_func_name VARCHAR2(30 CHAR) := 'GET_PAST_HIST_FREE_TEXT';
    BEGIN
    
        g_error := 'CALL TO PK_TOUCH_OPTION.GET_SCOPE_VARS';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN O_DOC_AREA_REGISTER';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_doc_area_register FOR
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_current_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(pphfth.flg_status,
                                                           pk_past_history.g_flg_status_cancel_free_text,
                                                           pphfth.id_prof_canceled,
                                                           pphfth.id_professional),
                                                    decode(pphfth.flg_status,
                                                           pk_past_history.g_flg_status_cancel_free_text,
                                                           pphfth.dt_cancel,
                                                           pphfth.dt_register),
                                                    pphfth.id_episode) desc_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   g_doc_area_past_med id_doc_area,
                   pphfth.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   decode(pphfth.flg_status,
                          pk_past_history.g_flg_status_cancel_free_text,
                          pphfth.id_prof_canceled,
                          pphfth.id_professional) id_professional,
                   NULL notes,
                   pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                   pk_alert_constant.get_yes flg_detail,
                   pk_alert_constant.get_no flg_external,
                   pk_alert_constant.get_yes flg_free_text,
                   get_review_info(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => pphfth.id_episode,
                                   i_id_record_area => pphfth.id_pat_ph_ft,
                                   i_flg_context    => pk_review.get_past_history_ft_context) flg_reviewed,
                   
                   pphfth.id_visit
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_patient = l_patient
               AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
               AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
               AND pphfth.id_doc_area = i_doc_area
               AND isphd_outbycancel(i_lang, 'FT', pphfth.id_pat_ph_ft_hist) = 0
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN O_DOC_AREA_VAL';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_doc_area_val FOR
            SELECT aux.id_episode,
                   aux.dt_register,
                   aux.nick_name,
                   aux.desc_past_hist,
                   aux.desc_past_hist_all,
                   aux.flg_status,
                   aux.desc_status,
                   aux.flg_nature,
                   aux.desc_nature,
                   aux.flg_current_episode,
                   aux.flg_current_professional,
                   aux.flg_last_record,
                   aux.flg_last_record_prof,
                   aux.id_diagnosis,
                   aux.flg_outdated,
                   aux.flg_canceled,
                   aux.day_begin,
                   aux.month_begin,
                   aux.year_begin,
                   aux.onset,
                   aux.dt_register_chr,
                   aux.desc_flg_status,
                   aux.dt_register_order,
                   aux.id_pat_history_diagnosis,
                   aux.id_professional,
                   aux.dt_pat_history_diagnosis_rep,
                   aux.flg_other,
                   aux.flg_free_text
              FROM (SELECT pphfth.id_episode,
                           pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                           pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist_all,
                           NULL flg_status,
                           NULL desc_status,
                           NULL flg_nature,
                           NULL desc_nature,
                           decode(pphfth.id_episode,
                                  i_current_episode,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_current_episode,
                           decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                           NULL flg_last_record,
                           NULL flg_last_record_prof,
                           NULL id_diagnosis,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_outdated,
                           decode(pphfth.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  pk_alert_constant.get_yes,
                                  pk_alert_constant.get_no) flg_canceled,
                           NULL day_begin,
                           NULL month_begin,
                           NULL year_begin,
                           NULL onset,
                           pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                           decode(pphfth.flg_status,
                                  pk_past_history.g_flg_status_cancel_free_text,
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang)) desc_flg_status,
                           pk_date_utils.to_char_insttimezone(i_prof,
                                                              decode(pphfth.flg_status,
                                                                     pk_past_history.g_flg_status_cancel_free_text,
                                                                     pphfth.dt_cancel,
                                                                     pphfth.dt_register),
                                                              'YYYYMMDDHH24MISS') dt_register_order,
                           pphfth.id_pat_ph_ft_hist id_pat_history_diagnosis,
                           pphfth.id_professional,
                           decode(pphfth.flg_status,
                                  pk_past_history.g_flg_status_cancel_free_text,
                                  pphfth.dt_cancel,
                                  pphfth.dt_register) dt_pat_history_diagnosis_tstz,
                           NULL dt_pat_history_diagnosis_rep,
                           NULL flg_other,
                           pk_alert_constant.get_yes flg_free_text
                      FROM pat_past_hist_ft_hist pphfth
                     WHERE pphfth.id_patient = l_patient
                       AND (pphfth.id_visit = l_visit OR l_visit IS NULL)
                       AND (pphfth.id_episode = l_episode OR l_episode IS NULL)
                       AND pphfth.id_doc_area = i_doc_area
                     ORDER BY dt_register DESC) aux;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_past_hist_free_text;
    --
    /********************************************************************************************
    * Gets number of reviews by category
    *
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_episode                Episode ID
    * @param i_cat                       Category
    *                        
    * @return                         NUMBER
    * 
    * @author                         Rui Duarte
    * @version                        2.6.1.5
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION prv_count_past_hist_review
    (
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_cat              IN category.flg_type%TYPE,
        i_areas_configured IN NUMBER
    ) RETURN NUMBER IS
        l_return               NUMBER;
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    BEGIN
        g_error := 'SELECT INTO l_doc_review_count';
        pk_alertlog.log_debug(text => g_error);
        --Get Number of reviewd recorde by category
        SELECT COUNT(*)
          INTO l_return
          FROM (SELECT DISTINCT (rd.id_record_area)
                  FROM review_detail rd
                  JOIN prof_cat pc
                    ON pc.id_professional = rd.id_professional
                  JOIN category c
                    ON c.id_category = pc.id_category
                  JOIN pat_history_diagnosis phd
                    ON phd.id_pat_history_diagnosis = rd.id_record_area
                 WHERE rd.id_episode = i_id_episode
                   AND rd.flg_context = pk_review.get_past_history_context
                   AND c.flg_type = i_cat
                   AND pc.id_institution = i_prof.institution
                   AND (phd.flg_status IS NULL OR phd.flg_status != g_pat_hist_diag_canceled)
                   AND phd.flg_recent_diag = pk_alert_constant.g_yes
                   AND phd.id_patient = i_id_patient
                   AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                        pk_alert_constant.g_diag_area_surgical_hist,
                                        pk_alert_constant.g_diag_area_not_defined,
                                        pk_alert_constant.g_diag_area_family_hist)
                   AND (i_areas_configured > 0 OR phd.flg_type NOT IN (g_alert_diag_type_med, g_alert_diag_type_surg))
                
                UNION ALL
                SELECT DISTINCT (rd.id_record_area)
                  FROM review_detail rd
                  JOIN prof_cat pc
                    ON pc.id_professional = rd.id_professional
                  JOIN category c
                    ON c.id_category = pc.id_category
                  JOIN pat_past_hist_free_text pphft
                    ON pphft.id_pat_ph_ft = rd.id_record_area
                 WHERE rd.id_episode = i_id_episode
                   AND rd.flg_context = pk_review.get_past_history_ft_context
                   AND c.flg_type = i_cat
                   AND pc.id_institution = i_prof.institution
                   AND pphft.flg_status != g_flg_status_cancel_free_text
                   AND pphft.id_patient = i_id_patient
                UNION ALL
                SELECT DISTINCT (rd.id_record_area)
                  FROM review_detail rd
                  JOIN prof_cat pc
                    ON pc.id_professional = rd.id_professional
                  JOIN category c
                    ON c.id_category = pc.id_category
                  JOIN epis_documentation ed
                    ON ed.id_epis_documentation = rd.id_record_area
                 WHERE rd.id_episode = i_id_episode
                   AND rd.flg_context = pk_review.get_template_context
                   AND c.flg_type = i_cat
                   AND pc.id_institution = i_prof.institution
                   AND ed.flg_status = pk_alert_constant.g_active);
    
        RETURN l_return;
    
    END prv_count_past_hist_review;
    --
    /********************************************************************************************
    * Gets the last review made in an episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_episode                Episode ID
    * @param o_last_review               Last review result
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN NUMBER,
        o_last_review   OUT VARCHAR2,
        o_review_status OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PAST_HIST_LAST_REVIEW';
    
        l_doc_review_count    NUMBER;
        l_nurse_review_count  NUMBER;
        l_past_hist_rec_count NUMBER;
        l_patient             patient.id_patient%TYPE;
        l_summ_page_past_hist CONSTANT summary_page.id_summary_page%TYPE := 2;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
        l_areas_configured     NUMBER;
    BEGIN
        --Get Patient ID
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'CHECK SUMMARY PAGE ACCESS';
        pk_alertlog.log_debug(text => g_error);
        SELECT COUNT(1)
          INTO l_areas_configured
          FROM summary_page_access a
         WHERE a.id_summary_page_section IN
               (SELECT a.id_summary_page_section
                  FROM summary_page_section a
                 WHERE a.id_summary_page = 2
                   AND a.id_doc_area IN (g_doc_area_past_med, g_doc_area_past_surg))
           AND a.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof);
    
        --Gets last review date and professional reviewing
        g_error := 'SELECT INTO o_last_review';
        pk_alertlog.log_debug(text => g_error);
    
        SELECT pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M098') || ': ' ||
               pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) || ', ' ||
               pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software)
          INTO o_last_review
          FROM (SELECT rd.id_professional id_prof, rd.dt_review dt_review
                  FROM review_detail rd
                  LEFT JOIN pat_history_diagnosis phd
                    ON phd.id_pat_history_diagnosis = rd.id_record_area
                 WHERE rd.flg_context IN (pk_review.get_past_history_context,
                                          pk_review.get_past_history_ft_context,
                                          pk_review.get_template_context)
                   AND rd.id_episode = i_id_episode
                   AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                        pk_alert_constant.g_diag_area_surgical_hist,
                                        pk_alert_constant.g_diag_area_not_defined)
                 ORDER BY rd.dt_review DESC, rd.id_record_area DESC)
         WHERE rownum = 1;
    
        --Get Number of reviewed records by doctor
        l_doc_review_count := prv_count_past_hist_review(i_prof             => i_prof,
                                                         i_id_patient       => l_patient,
                                                         i_id_episode       => i_id_episode,
                                                         i_cat              => pk_alert_constant.g_cat_type_doc,
                                                         i_areas_configured => l_areas_configured);
    
        --Get Number of reviewed records by nurse
        l_nurse_review_count := prv_count_past_hist_review(i_prof             => i_prof,
                                                           i_id_patient       => l_patient,
                                                           i_id_episode       => i_id_episode,
                                                           i_cat              => pk_alert_constant.g_cat_type_nurse,
                                                           i_areas_configured => l_areas_configured);
    
        g_error := 'SELECT INTO l_past_hist_rec_count';
        pk_alertlog.log_debug(text => g_error);
        SELECT COUNT(*)
          INTO l_past_hist_rec_count
          FROM (SELECT phd.id_pat_history_diagnosis id
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode = i_id_episode
                   AND (phd.flg_status IS NULL OR phd.flg_status != g_pat_hist_diag_canceled)
                   AND phd.flg_recent_diag = pk_alert_constant.g_yes
                   AND coalesce(phd.id_diagnosis, phd.id_intervention, phd.id_exam) IS NOT NULL
                   AND phd.id_patient = l_patient
                   AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                        pk_alert_constant.g_diag_area_surgical_hist,
                                        pk_alert_constant.g_diag_area_family_hist,
                                        pk_alert_constant.g_diag_area_not_defined)
                   AND (l_areas_configured > 0 OR phd.flg_type NOT IN (g_alert_diag_type_med, g_alert_diag_type_surg))
                UNION ALL
                SELECT phd.id_pat_history_diagnosis id
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode = i_id_episode
                   AND phd.flg_recent_diag = pk_alert_constant.g_yes
                   AND phd.flg_status IN (g_pat_hist_diag_unknown, g_pat_hist_diag_none, g_pat_hist_diag_non_remark)
                   AND phd.id_patient = l_patient
                   AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                        pk_alert_constant.g_diag_area_surgical_hist,
                                        pk_alert_constant.g_diag_area_family_hist,
                                        pk_alert_constant.g_diag_area_not_defined)
                   AND (l_areas_configured > 0 OR phd.flg_type NOT IN (g_alert_diag_type_med, g_alert_diag_type_surg))
                UNION ALL
                SELECT pphft.id_pat_ph_ft id
                  FROM pat_past_hist_free_text pphft
                 WHERE pphft.id_episode = i_id_episode
                   AND pphft.flg_status != g_flg_status_cancel_free_text
                   AND pphft.id_patient = l_patient
                UNION ALL
                SELECT ed.id_epis_documentation
                  FROM epis_documentation ed
                 WHERE ed.id_episode = i_id_episode
                   AND ed.flg_status = pk_alert_constant.g_active
                   AND ed.id_doc_area IN (SELECT sps.id_doc_area
                                            FROM summary_page_section sps
                                           WHERE sps.id_summary_page = l_summ_page_past_hist));
    
        IF l_doc_review_count = l_past_hist_rec_count
        THEN
            -- Reviewed in this visit
            o_review_status := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M096');
        ELSIF (l_doc_review_count = 0 AND l_nurse_review_count = 0)
        THEN
            -- Not reviewed in this visit
            o_last_review   := '';
            o_review_status := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M097');
        ELSE
            -- Partialy reviewed in this visit 
            o_review_status := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M095');
        END IF;
    
        -- Add Reviewd by nurse
        IF l_nurse_review_count > 0
        THEN
            o_review_status := o_review_status || ' (' ||
                               pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M105') || ')';
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_last_review   := '';
            o_review_status := '';
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_past_hist_review;
    --
    /********************************************************************************************
    * Returns the details for the past history summary page (medical and surgical history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param i_pat_hist_diag          Past History Diagnosis ID   
    * @param i_all                    True (All), False (Only Create)
    * @param i_flg_ft                 If provided id is from a free text or a diagnosis ID - Yes (Y) No (N) 
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/09/13
    **********************************************************************************************/
    FUNCTION prv_get_past_hist_det_treat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_pat_hist_diag     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_all               IN BOOLEAN DEFAULT FALSE,
        i_flg_ft            IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_free_text             pat_past_hist_free_text.id_pat_ph_ft%TYPE;
        l_id_free_text_hist        pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
        l_max_dt_pat_his_diag_tstz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
        l_min_dt_pat_his_diag_tstz pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
    
        l_label_review      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'DETAIL_COMMON_M005');
        l_label_review_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'DETAIL_COMMON_M004');
        l_message_unknown   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    
        l_all PLS_INTEGER;
    
        l_doc_area_type pat_history_diagnosis.flg_type%TYPE;
    
        --Exceptions
        e_get_past_hist_diagnosis EXCEPTION; -- prv_get_past_hist_diagnosis fail
    BEGIN
        l_all := sys.diutil.bool_to_int(i_all);
    
        IF NOT prv_get_past_hist_det_ids(i_pat_hist_diag,
                                         i_flg_ft,
                                         l_id_free_text,
                                         l_id_free_text_hist,
                                         l_max_dt_pat_his_diag_tstz,
                                         l_min_dt_pat_his_diag_tstz)
        THEN
            g_error := 'set_past_hist_ft has failed';
            RAISE g_exception;
        END IF;
    
        --Get doc area type flag
        l_doc_area_type := prv_conv_doc_area_to_flg_type(i_doc_area);
    
        ---
        -- per episode
        ---   
        g_error := 'OPEN O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT DISTINCT doc_area_reg.id_episode,
                            doc_area_reg.flg_current_episode,
                            doc_area_reg.nick_name,
                            doc_area_reg.dt_register,
                            doc_area_reg.prof_spec_reg,
                            doc_area_reg.id_doc_area,
                            doc_area_reg.dt_register_chr,
                            doc_area_reg.id_professional,
                            --doc_area_reg.notes,
                            decode(COUNT(DISTINCT doc_area_reg.desc_detail)
                                   over(PARTITION BY doc_area_reg.dt_pat_history_diagnosis_tstz),
                                   1,
                                   doc_area_reg.desc_detail,
                                   pk_message.get_message(i_lang, 'PAST_HISTORY_M065')) AS desc_detail,
                            doc_area_reg.flg_status,
                            NULL review_notes,
                            id_visit,
                            flg_review,
                            id_pat_history_diagnosis
              FROM (SELECT phd.id_episode,
                           decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            phd.id_professional,
                                                            phd.dt_pat_history_diagnosis_tstz,
                                                            phd.id_episode) prof_spec_reg,
                           i_doc_area id_doc_area,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       phd.dt_pat_history_diagnosis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register_chr,
                           phd.dt_pat_history_diagnosis_tstz,
                           phd.id_professional,
                           --phd.notes,
                           decode(phd.flg_status,
                                  g_pat_hist_diag_canceled,
                                  pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                                  decode(connect_by_isleaf,
                                         1,
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                         pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                           phd.flg_status,
                           NULL review_notes,
                           e.id_visit,
                           pk_alert_constant.g_no flg_review,
                           phd.id_pat_history_diagnosis
                      FROM pat_history_diagnosis phd
                      LEFT OUTER JOIN alert_diagnosis ad
                        ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                      JOIN episode e
                        ON e.id_episode = phd.id_episode
                      LEFT OUTER JOIN exam exm
                        ON phd.id_exam = exm.id_exam
                      LEFT OUTER JOIN intervention intrv
                        ON intrv.id_intervention = phd.id_intervention
                     WHERE phd.flg_type = g_alert_type_treatments
                    --AND rownum = 1
                     START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
                    CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new) doc_area_reg
            UNION
            
            SELECT phd.id_episode id_episode,
                   decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, phd.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   rd.id_professional id_professional,
                   l_label_review_desc desc_detail,
                   NULL flg_status,
                   rd.review_notes review_notes,
                   e.id_visit,
                   pk_alert_constant.g_yes flg_review,
                   phd.id_pat_history_diagnosis
              FROM review_detail rd, pat_history_diagnosis phd
             INNER JOIN episode e
                ON e.id_episode = phd.id_episode
             WHERE rd.id_record_area = i_pat_hist_diag
               AND rd.id_record_area = phd.id_pat_history_diagnosis
               AND rd.flg_context IN (pk_review.get_past_history_context, pk_review.get_past_history_ft_context)
               AND nvl(phd.flg_status, g_pat_hist_diag_unknown) != g_pat_hist_diag_canceled
               AND l_all > 0
            
            UNION
            
            SELECT pphft.id_episode id_episode,
                   decode(pphft.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, pphft.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   rd.id_professional id_professional,
                   l_label_review_desc desc_detail,
                   NULL flg_status,
                   rd.review_notes review_notes,
                   pphft.id_visit,
                   pk_alert_constant.g_yes flg_review,
                   rd.id_record_area id_pat_history_diagnosis
              FROM review_detail rd
              JOIN pat_past_hist_free_text pphft
                ON pphft.id_pat_ph_ft = rd.id_record_area
             WHERE rd.id_record_area = l_id_free_text
               AND rd.id_episode = pphft.id_episode
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND l_all > 0
            
            UNION
            
            SELECT pphfth.id_episode,
                   decode(pphfth.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pphfth.id_professional,
                                                    pphfth.dt_register,
                                                    pphfth.id_episode) prof_spec_reg,
                   i_doc_area id_doc_area,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   pphfth.id_professional id_professional,
                   decode(pphfth.flg_status,
                          g_flg_status_cancel_free_text,
                          pk_message.get_message(i_lang, 'PAST_HISTORY_M066'),
                          decode(pphfth.dt_register,
                                 l_min_dt_pat_his_diag_tstz,
                                 pk_message.get_message(i_lang, 'PAST_HISTORY_M067'),
                                 pk_message.get_message(i_lang, 'PAST_HISTORY_M065'))) desc_detail,
                   pphfth.flg_status,
                   NULL review_notes,
                   pphfth.id_visit,
                   pk_alert_constant.g_no flg_review,
                   pphfth.id_pat_ph_ft id_pat_history_diagnosis
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_pat_ph_ft_hist = l_id_free_text_hist
               AND pphfth.flg_type = l_doc_area_type
               AND i_flg_ft = pk_alert_constant.get_yes
             ORDER BY flg_current_episode DESC, dt_register DESC, flg_review DESC;
    
        ---
        -- per patient
        ---       
        g_error := 'OPEN O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT DISTINCT phd.id_episode,
                            pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                            prv_get_past_hist_det_desc(i_lang, i_prof, i_doc_area, pk_alert_constant.get_no) label_past_hist,
                            nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                                pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL)) || ' (' ||
                            pk_sysdomain.get_domain(g_past_hist_treat_type_config,
                                                    nvl(exm.flg_type, g_flg_treatments_proc_search),
                                                    i_lang) ||
                            nvl2(phd.dt_execution,
                                 ', ' || get_partial_date_format(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_date      => phd.dt_execution,
                                                                 i_precision => phd.dt_execution_precision),
                                 '') || ')' ||
                            nvl2(phd.cancel_notes, ' (' || pk_message.get_message(i_lang, 'COMMON_M008') || ')', '') desc_past_hist,
                            -- onset
                            NULL label_onset,
                            NULL desc_onset,
                            pk_message.get_message(i_lang, 'PAST_HISTORY_M061') label_status,
                            phd.flg_status,
                            pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                            NULL label_nature,
                            NULL AS flg_nature,
                            pk_sysdomain.get_domain(decode(g_doc_area_past_surg,
                                                           i_doc_area,
                                                           'PAT_PROBLEM.FLG_COMPL_DESC',
                                                           'PAT_PROBLEM.FLG_NATURE'),
                                                    decode(g_doc_area_past_surg,
                                                           i_doc_area,
                                                           phd.flg_compl,
                                                           phd.flg_nature),
                                                    i_lang) desc_nature,
                            pk_message.get_message(i_lang, 'PAST_HISTORY_M140') label_notes,
                            phd.notes,
                            -- check if it is the current episode
                            decode(phd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                            -- check if the diagnosis was registered by the current professional
                            decode(phd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                            -- check if it is the last record
                            decode(phd_max.max_dt_pat_history_diagnosis,
                                   phd.dt_pat_history_diagnosis_tstz,
                                   pk_alert_constant.get_yes,
                                   pk_alert_constant.get_no) flg_last_record,
                            -- check if it is the last record by that professional
                            decode(phd_max_prof.max_dt_pat_history_diagnosis,
                                   phd.dt_pat_history_diagnosis_tstz,
                                   pk_alert_constant.get_yes,
                                   pk_alert_constant.get_no) flg_last_record_prof,
                            phd.id_alert_diagnosis id_diagnosis,
                            decode(phd.id_pat_history_diagnosis_new,
                                   NULL,
                                   pk_alert_constant.get_no,
                                   pk_alert_constant.get_yes) flg_outdated,
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_alert_constant.get_yes,
                                   pk_alert_constant.get_no) flg_canceled,
                            NULL day_begin,
                            NULL month_begin,
                            NULL year_begin,
                            pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_date      => phd.dt_diagnosed,
                                                                    i_precision => phd.dt_diagnosed_precision) onset,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        phd.dt_pat_history_diagnosis_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_register_chr,
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                                   decode(phd.id_pat_history_diagnosis_new,
                                          NULL,
                                          NULL,
                                          pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                            pk_date_utils.to_char_insttimezone(i_prof,
                                                               phd.dt_pat_history_diagnosis_tstz,
                                                               'YYYYMMDDHH24MISS') dt_register_order,
                            phd.dt_pat_history_diagnosis_tstz,
                            -- cancelation data
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_message.get_message(i_lang, 'PAST_HISTORY_M063'),
                                   NULL) label_cancel_reason,
                            (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                               FROM cancel_reason cr
                              WHERE cr.id_cancel_reason = phd.id_cancel_reason) cancel_reason,
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_message.get_message(i_lang, 'PAST_HISTORY_M064'),
                                   NULL) label_cancel_notes,
                            decode(phd.flg_status, g_pat_hist_diag_canceled, phd.cancel_notes, NULL) cancel_notes,
                            NULL label_review_notes,
                            NULL review_notes,
                            pk_alert_constant.get_no flg_review,
                            e.id_visit,
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_message.get_message(i_lang, 'PAST_HISTORY_M090'),
                                   NULL) label_prof_cancel,
                            decode(phd.flg_status,
                                   g_pat_hist_diag_canceled,
                                   pk_message.get_message(i_lang, 'PAST_HISTORY_M091'),
                                   NULL) label_date_cancel,
                            pk_date_utils.date_char_tsz(i_lang, phd.dt_cancel, i_prof.institution, i_prof.software) date_cancel,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_prof_cancel) prof_cancel_desc,
                            phd.id_professional id_professional,
                            pk_alert_constant.get_no flg_free_text
              FROM pat_history_diagnosis phd,
                   exam exm,
                   intervention intrv,
                   (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, /*visit v, visit vis,*/ episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_id_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND e.id_visit = v.id_visit
                          --AND vis.id_visit = epis.id_visit
                          --AND v.id_patient = vis.id_patient) phd_max,
                       AND epis.id_patient = e.id_patient) phd_max,
                   (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, /*visit v, visit vis,*/ episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_id_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND e.id_visit = v.id_visit
                          --AND vis.id_visit = epis.id_visit
                          --AND v.id_patient = vis.id_patient
                       AND e.id_patient = epis.id_patient
                       AND phd.id_professional = i_prof.id) phd_max_prof,
                   episode e
             WHERE phd.id_exam = exm.id_exam(+)
               AND phd.id_intervention = intrv.id_intervention(+)
               AND phd.flg_type = g_alert_type_treatments
               AND phd.id_patient = i_id_patient
               AND e.id_episode = phd.id_episode
             START WITH phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz
            CONNECT BY nocycle PRIOR phd.id_pat_history_diagnosis = phd.id_pat_history_diagnosis_new
            
            UNION ALL
            
            SELECT notes_review_aux.id_episode id_episode,
                   pk_date_utils.date_send_tsz(i_lang, notes_review_aux.dt_review, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, notes_review_aux.id_professional) nick_name,
                   NULL label_past_hist,
                   NULL desc_past_hist,
                   --NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   NULL flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   l_label_review label_notes,
                   NULL notes,
                   decode(notes_review_aux.id_episode,
                          i_id_episode,
                          pk_alert_constant.get_yes,
                          pk_alert_constant.get_no) flg_current_episode,
                   decode(notes_review_aux.id_professional,
                          i_prof.id,
                          pk_alert_constant.get_yes,
                          pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL day_begin,
                   NULL month_begin,
                   NULL year_begin,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, notes_review_aux.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, notes_review_aux.dt_review, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL label_cancel_reason,
                   NULL cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_notes,
                   prv_get_review_note_label(i_lang, i_prof, notes_review_aux.review_notes) label_review_notes,
                   notes_review_aux.review_notes review_notes,
                   pk_alert_constant.g_yes flg_review,
                   e.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   notes_review_aux.id_professional id_professional,
                   pk_alert_constant.g_no flg_free_text
              FROM (SELECT rd.dt_review, rd.id_professional, phd.id_episode, rd.review_notes
                      FROM review_detail rd, pat_history_diagnosis phd
                     WHERE rd.id_record_area = i_pat_hist_diag
                       AND rd.id_record_area = phd.id_pat_history_diagnosis
                    UNION -- when there are more than one past history "at the same time"
                    SELECT rd.dt_review, rd.id_professional, phd.id_episode, rd.review_notes
                      FROM review_detail rd, pat_history_diagnosis phd
                     INNER JOIN episode e
                        ON e.id_episode = phd.id_episode
                     WHERE rd.id_record_area = phd.id_pat_history_diagnosis
                       AND phd.dt_pat_history_diagnosis_tstz = l_max_dt_pat_his_diag_tstz) notes_review_aux
             INNER JOIN episode e
                ON e.id_episode = notes_review_aux.id_episode
             WHERE l_all > 0
            
            UNION ALL
            
            SELECT rd.id_episode id_episode,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) nick_name,
                   NULL label_past_hist,
                   NULL desc_past_hist,
                   --NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   NULL flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   l_label_review label_notes,
                   NULL notes,
                   decode(rd.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   decode(rd.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL day_begin,
                   NULL month_begin,
                   NULL year_begin,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, rd.dt_review, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL label_cancel_reason,
                   NULL cancel_reason,
                   NULL label_cancel_notes,
                   NULL cancel_notes,
                   prv_get_review_note_label(i_lang, i_prof, rd.review_notes) label_review_notes,
                   rd.review_notes review_notes,
                   pk_alert_constant.g_yes flg_review,
                   pphft.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   rd.id_professional id_professional,
                   pk_alert_constant.g_no flg_free_text
              FROM review_detail rd
              JOIN pat_past_hist_free_text pphft
                ON pphft.id_pat_ph_ft = rd.id_record_area
             WHERE rd.id_record_area = l_id_free_text
               AND rd.flg_context = pk_review.get_past_history_ft_context
               AND l_all > 0
            
            UNION ALL
            
            SELECT pphfth.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, pphfth.dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pphfth.id_professional) nick_name,
                   prv_get_past_hist_det_desc(i_lang, i_prof, i_doc_area, pk_alert_constant.get_yes) label_past_hist,
                   pk_string_utils.clob_to_sqlvarchar2(pphfth.text) desc_past_hist,
                   --NULL desc_past_hist_all,
                   NULL label_onset,
                   NULL desc_onset,
                   NULL label_status,
                   pphfth.flg_status flg_status,
                   NULL desc_status,
                   NULL label_nature,
                   NULL flg_nature,
                   NULL desc_nature,
                   NULL label_notes,
                   NULL notes,
                   decode(pphfth.id_episode, i_id_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
                   decode(pphfth.id_professional, i_prof.id, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL day_begin,
                   NULL month_begin,
                   NULL year_begin,
                   NULL onset,
                   pk_date_utils.date_char_tsz(i_lang, pphfth.dt_register, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, pphfth.dt_register, 'YYYYMMDDHH24MISS') dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   -- cancelation data
                   pk_message.get_message(i_lang, 'PAST_HISTORY_M063') label_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = pphfth.id_cancel_reason) cancel_reason,
                   pk_message.get_message(i_lang, 'PAST_HISTORY_M064') label_cancel_notes,
                   decode(pphfth.flg_status, g_flg_status_cancel_free_text, pphfth.cancel_notes, NULL) cancel_notes,
                   NULL label_review_notes,
                   NULL review_notes,
                   pk_alert_constant.get_no flg_review,
                   pphfth.id_visit,
                   NULL label_prof_cancel,
                   NULL label_date_cancel,
                   NULL date_cancel,
                   NULL prof_cancel_desc,
                   pphfth.id_professional id_professional,
                   pk_alert_constant.g_yes flg_free_text
              FROM pat_past_hist_ft_hist pphfth
             WHERE pphfth.id_pat_ph_ft_hist = l_id_free_text_hist
               AND pphfth.flg_type = l_doc_area_type
             ORDER BY flg_current_episode DESC, dt_pat_history_diagnosis_tstz DESC, flg_status ASC, desc_past_hist ASC;
    
        --load template data
        g_error := 'GET ASSOCIATED TEMPLATE DATA';
        pk_alertlog.log_info(text => g_error);
    
        IF i_epis_document IS NOT NULL
        THEN
            IF NOT pk_touch_option.get_epis_documentation_det(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_epis_document     => i_epis_document,
                                                              o_epis_doc_register => o_epis_doc_register,
                                                              o_epis_document_val => o_epis_document_val,
                                                              o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING GET_PAST_HIST_DET FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'prv_get_ph_treatmnt_detail',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'prv_get_ph_treatmnt_detail',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END prv_get_past_hist_det_treat;
    /********************************************************************************************
    * Returns all diagnosis (Both standards diagnosis - like ICD9 - and ALERT diagnosis)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_format_text            Formats the output occurrences
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado (code-refactoring)
    * @version                        2.6.0.x       
    * @since                          2010/05/11
    **********************************************************************************************/
    FUNCTION get_search_treatments
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        i_pat       IN patient.id_patient%TYPE,
        i_flg_type  IN table_varchar,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
    BEGIN
    
        --Open final cursor
        OPEN o_diagnosis FOR
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_exam id_diagnosis,
             t.desc_exam desc_diagnosis,
             pk_exam_constant.g_type_img flg_type,
             'ImageExameIcon' exam_type_icon
              FROM TABLE(pk_exams_api_db.get_exam_search(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_patient       => i_pat,
                                                         i_exam_type     => pk_exam_constant.g_type_img,
                                                         i_codification  => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_flg_type      => g_flg_treatments_search,
                                                         i_value         => i_search)) t
             WHERE rownum <= l_limit
            UNION ALL
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_exam id_diagnosis,
             t.desc_exam desc_diagnosis,
             pk_exam_constant.g_type_exm flg_type,
             'TechnicianInContact' exam_type_icon
              FROM TABLE(pk_exams_api_db.get_exam_search(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_patient       => i_pat,
                                                         i_exam_type     => pk_exam_constant.g_type_exm,
                                                         i_codification  => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_flg_type      => g_flg_treatments_search,
                                                         i_value         => i_search)) t
             WHERE rownum <= l_limit
            UNION ALL
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_intervention id_diagnosis,
             t.desc_intervention desc_diagnosis,
             g_interv_type flg_type,
             'InterventionsIcon' exam_type_icon
              FROM TABLE(pk_procedures_api_db.get_procedure_search(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_patient      => i_pat,
                                                                   i_flg_type     => g_flg_treatments_search,
                                                                   i_codification => NULL,
                                                                   i_value        => i_search)) t
             WHERE rownum <= l_limit
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRV_GET_SEARCH_TREATMENTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_search_treatments;

    FUNCTION prv_get_category_reviews
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_flg_cat        IN category.flg_type%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN BOOLEAN IS
        l_patient patient.id_patient%TYPE;
        l_res     NUMBER;
    
    BEGIN
        -- check reviews for this record and category
        g_error := 'CHECK REVIEW CATEGORY - ' || i_flg_cat;
        pk_alertlog.log_info(text => g_error);
    
        l_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
    
        SELECT COUNT(1)
          INTO l_res
          FROM review_detail rd
         INNER JOIN prof_cat pc
            ON pc.id_professional = rd.id_professional
         INNER JOIN category cat
            ON cat.id_category = pc.id_category
         WHERE rd.id_episode IN
               (SELECT *
                  FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_patient    => l_patient,
                                                  i_episode    => i_id_episode,
                                                  i_flg_filter => pk_alert_constant.g_scope_type_episode)))
           AND rd.id_record_area = i_id_record_area
           AND cat.flg_type = i_flg_cat
           AND rd.flg_context = i_flg_context
           AND pc.id_institution = i_id_institution;
    
        IF l_res > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END prv_get_category_reviews;
    --
    FUNCTION get_review_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_id_institution institution.id_institution%TYPE;
    BEGIN
        --Chek if institution is null, if not provided from parameters get it from episode
        IF (i_id_institution IS NULL)
        THEN
            SELECT e.id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = i_episode;
        ELSE
            l_id_institution := i_id_institution;
        END IF;
    
        --Check reviews
        IF NOT prv_get_category_reviews(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_id_episode     => i_episode,
                                        i_id_record_area => i_id_record_area,
                                        i_flg_context    => i_flg_context,
                                        i_flg_cat        => pk_alert_constant.g_cat_type_doc,
                                        i_id_institution => l_id_institution)
        THEN
            IF NOT prv_get_category_reviews(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_episode     => i_episode,
                                            i_id_record_area => i_id_record_area,
                                            i_flg_context    => i_flg_context,
                                            i_flg_cat        => pk_alert_constant.g_cat_type_nurse,
                                            i_id_institution => l_id_institution)
            THEN
                RETURN g_past_history_not_reviewed;
            ELSE
                RETURN pk_alert_constant.g_cat_type_nurse;
            END IF;
        ELSE
            RETURN pk_alert_constant.g_cat_type_doc;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_past_history_not_reviewed;
    END;
    --

    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_prof                   Professional info
    * @param i_date                   Date value
    * @param i_precision              Precision value. D-Day, M-Month, Y-Year                   
    *
    * @return                         Formatted date
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.1.2
    * @since                          07-14-2011
    **********************************************************************************************/
    FUNCTION get_partial_date_format
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN pat_history_diagnosis.dt_execution%TYPE,
        i_precision IN pat_history_diagnosis.dt_execution_precision%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_precision = g_date_unknown
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        
        ELSIF i_precision = g_date_precision_hour
        THEN
            RETURN pk_date_utils.date_char_tsz(i_lang => NULL,
                                               i_date => i_date,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software);
        ELSIF i_precision = g_date_precision_day
        THEN
            RETURN to_char(pk_date_utils.trunc_insttimezone(i_inst      => i_prof.institution,
                                                            i_soft      => i_prof.software,
                                                            i_timestamp => i_date),
                           pk_sysconfig.get_config('DATE_FORMAT_SHORT_READ', i_prof.institution, i_prof.software));
        ELSIF i_precision = g_date_precision_month
        THEN
            RETURN to_char(pk_date_utils.trunc_insttimezone(i_inst      => i_prof.institution,
                                                            i_soft      => i_prof.software,
                                                            i_timestamp => i_date),
                           pk_sysconfig.get_config('DATE_MONTH_YEAR_FORMAT', i_prof.institution, i_prof.software));
        ELSIF i_precision = g_date_precision_year
        THEN
            RETURN to_char(pk_date_utils.trunc_insttimezone(i_inst      => i_prof.institution,
                                                            i_soft      => i_prof.software,
                                                            i_timestamp => i_date),
                           pk_sysconfig.get_config('DATE_YEAR', i_prof.institution, i_prof.software));
        ELSE
            RETURN to_char(pk_date_utils.trunc_insttimezone(i_inst      => i_prof.institution,
                                                            i_soft      => i_prof.software,
                                                            i_timestamp => i_date),
                           pk_sysconfig.get_config('DATE_FORMAT_SHORT_READ', i_prof.institution, i_prof.software));
        END IF;
    END;

    FUNCTION get_partial_date_format_serial
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN pat_history_diagnosis.dt_execution%TYPE,
        i_precision IN pat_history_diagnosis.dt_execution_precision%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_precision = g_date_unknown
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        
        ELSIF i_precision = g_date_precision_hour
        THEN
            RETURN to_char(i_date, 'YYYYMMDDHH24MISS');
        ELSIF i_precision = g_date_precision_day
        THEN
            RETURN to_char(i_date, 'YYYYMMDD');
        ELSIF i_precision = g_date_precision_month
        THEN
            RETURN to_char(i_date, 'YYYYMM');
        ELSIF i_precision = g_date_precision_year
        THEN
            RETURN to_char(i_date, 'YYYY');
        ELSE
            RETURN to_char(i_date, 'YYYYMMDDHH24MISS');
        END IF;
    
    END get_partial_date_format_serial;

    /**************************************************************************
    * return list of documentation for the patient for a specific doc_area    *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_episode                the episode id                          *
    * @param i_doc_area               the doc_area id                         *
    *                                                                         *
    * @return                         return list of documentation for the    *
    *                                 patient for a specific doc_area         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_doc_area_register
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_register
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_doc_area_register';
        l_patient       patient.id_patient%TYPE;
        l_coll_register pk_touch_option.t_coll_doc_area_register;
        l_cur_register  pk_touch_option.t_cur_doc_area_register;
        l_cur_val       pk_touch_option.t_cur_doc_area_val;
        l_cur_layout    pk_types.cursor_type;
        l_cur_component pk_types.cursor_type;
        l_count         NUMBER(24);
        l_error         t_error_out;
    BEGIN
    
        g_error := 'GET PATIENT';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        g_error := 'DOCUMENTATION AREAS';
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_episode,
                                                  i_scope              => l_patient,
                                                  i_scope_type         => pk_alert_constant.g_scope_type_patient,
                                                  o_doc_area_register  => l_cur_register,
                                                  o_doc_area_val       => l_cur_val,
                                                  o_template_layouts   => l_cur_layout,
                                                  o_doc_area_component => l_cur_component,
                                                  o_record_count       => l_count,
                                                  o_error              => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CLOSING UNUSED CURSORS';
        CLOSE l_cur_val;
        CLOSE l_cur_layout;
        CLOSE l_cur_component;
    
        g_error := 'FECH TO PIPE ROW';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        LOOP
            FETCH l_cur_register BULK COLLECT
                INTO l_coll_register LIMIT 500;
            FOR i IN 1 .. l_coll_register.count
            LOOP
                PIPE ROW(l_coll_register(i));
            END LOOP;
            EXIT WHEN l_cur_register%NOTFOUND;
        END LOOP;
        CLOSE l_cur_register;
        RETURN;
    END tf_doc_area_register;

    /**************************************************************************
    * return list of documentation values for the patient for a specific      *
    * doc_area.                                                               *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_episode                the episode id                          *
    * @param i_doc_area               the doc_area id                         *
    *                                                                         *
    * @return                         return list of documentation for the    *
    *                                 patient for a specific doc_area         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_doc_area_val_documentation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_val
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_doc_area_val_documentation';
        l_patient       patient.id_patient%TYPE;
        l_cur_register  pk_touch_option.t_cur_doc_area_register;
        l_cur_val       pk_touch_option.t_cur_doc_area_val;
        l_coll_val      pk_touch_option.t_coll_doc_area_val;
        l_cur_layout    pk_types.cursor_type;
        l_cur_component pk_types.cursor_type;
        l_count         NUMBER(24);
        l_error         t_error_out;
    BEGIN
    
        g_error := 'GET PATIENT';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        g_error := 'DOCUMENTATION AREAS';
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_episode,
                                                  i_scope              => l_patient,
                                                  i_scope_type         => pk_alert_constant.g_scope_type_patient,
                                                  o_doc_area_register  => l_cur_register,
                                                  o_doc_area_val       => l_cur_val,
                                                  o_template_layouts   => l_cur_layout,
                                                  o_doc_area_component => l_cur_component,
                                                  o_record_count       => l_count,
                                                  o_error              => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CLOSING UNUSED CURSORS';
        CLOSE l_cur_register;
        CLOSE l_cur_layout;
        CLOSE l_cur_component;
    
        g_error := 'FECH TO PIPE ROW';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        LOOP
            FETCH l_cur_val BULK COLLECT
                INTO l_coll_val LIMIT 500;
            FOR i IN 1 .. l_coll_val.count
            LOOP
                PIPE ROW(l_coll_val(i));
            END LOOP;
            EXIT WHEN l_cur_val%NOTFOUND;
        END LOOP;
        CLOSE l_cur_val;
        RETURN;
    END tf_doc_area_val_documentation;
    --
    /**********************************************************************************************
    * Internal function to retrieve most frequent diagnoses for past history screens
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_episode               Episode ID
    * @param i_patient               Patient ID
    * @param i_doc_area              Doc Area ID
    * @param i_text_search           Text input to use as filter
    * @param i_flg_screen            Indicates from where the function was called. H - Past history screen (default), P - Problems screen
    *
    * @param o_diagnosis             Diagnoses information
    * @param o_error                 Error information
    *
    * @return                        True/False
    *                        
    * @author                        Sergio Dias
    * @version                       2.6.3.14
    * @since                         25-03-2014
    ***********************************************************************************************/
    FUNCTION get_past_hist_diagnoses
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_text_search       IN VARCHAR2 DEFAULT NULL,
        i_flg_screen        IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        i_tbl_terminologies IN table_varchar DEFAULT NULL,
        o_diagnosis         OUT t_coll_diagnosis_config,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PAST_HIST_DIAGNOSES';
    
        l_term_task_type    task_type.id_task_type%TYPE;
        l_clinical_services table_number := table_number();
        l_dep_clin_serv     table_number := table_number();
        l_complaints        table_number;
        l_profile_template  profile_template.id_profile_template%TYPE;
        l_context_flg_type  doc_area_inst_soft.flg_type%TYPE;
    
        l_diagnoses_context doc_area_inst_soft.flg_type%TYPE;
        l_diagnoses_count   NUMBER(24);
    
        l_birth_hist_mechanism sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_birth_hist_search_mechanism,
                                                                                i_prof);
        l_surg_hist_mechanism  sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism,
                                                                                i_prof);
        l_med_hist_mechanism   sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism,
                                                                                i_prof);
    
        function_call_excep EXCEPTION;
        --
        CURSOR c_epis_complaint IS
            SELECT c.id_complaint
              FROM complaint c, epis_complaint ec
             WHERE c.id_complaint = ec.id_complaint
               AND ec.id_episode = i_episode
               AND ec.flg_status = g_active;
        --
        CURSOR c_service IS
            SELECT dcs.id_clinical_service
              FROM epis_info epo, dep_clin_serv dcs
             WHERE epo.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND epo.id_episode = i_episode;
    
        --    
        CURSOR c_sched_service IS
            SELECT dcs.id_clinical_service
              FROM epis_info epo, dep_clin_serv dcs
             WHERE epo.id_dcs_requested = dcs.id_dep_clin_serv
               AND epo.id_episode = i_episode;
    
        --
        CURSOR c_context_flg_type IS
            SELECT flg_type
              FROM doc_area_inst_soft
             WHERE id_doc_area = i_doc_area
               AND id_software IN (i_prof.software, 0)
               AND id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC, id_software DESC;
        --   
        CURSOR c_epis_clin_serv IS
            SELECT e.id_clinical_service
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        -- Clinical services selected by profissional in current institution and software          
        CURSOR c_prof_clin_serv IS
            SELECT DISTINCT cs.id_clinical_service
              FROM prof_dep_clin_serv pdcs
             INNER JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
             INNER JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             INNER JOIN department d
                ON d.id_department = dcs.id_department
             WHERE pdcs.id_professional = i_prof.id
               AND pdcs.id_institution = i_prof.institution
               AND nvl(d.id_software, 0) IN (0, i_prof.software)
               AND pdcs.flg_status = pk_alert_constant.g_status_selected
               AND dcs.flg_available = pk_alert_constant.g_available
               AND cs.flg_available = pk_alert_constant.g_available
               AND d.flg_available = pk_alert_constant.g_available;
    
        -- Inner function to retrieves all diagnoses
        FUNCTION inner_get_all_diagnoses
        (
            o_diagnoses OUT t_coll_diagnosis_config,
            o_error     OUT t_error_out
        ) RETURN BOOLEAN IS
            l_limit NUMBER;
        BEGIN
            pk_alertlog.log_debug(sub_object_name => 'inner_get_all_diagnoses',
                                  text            => 'All past-history diagnoses. Bringing them back.');
        
            --We need impose a limit because flash can't handle a list with all diagnoses.
            --If the required diagnosis is not returned then they can use the search button.
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        
            IF (l_term_task_type = pk_alert_constant.g_task_congenital_anomalies AND
               l_birth_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_surgical_history AND
               l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_medical_history AND
               l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR l_term_task_type IN
               (pk_alert_constant.g_task_family_history, pk_alert_constant.g_task_gynecology_history)
            THEN
                o_diagnoses := pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                        i_prof                     => i_prof,
                                                                        i_patient                  => i_patient,
                                                                        i_terminologies_task_types => table_number(l_term_task_type),
                                                                        i_tbl_term_task_type       => table_number(l_term_task_type),
                                                                        i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                        i_text_search              => i_text_search,
                                                                        i_tbl_terminologies        => i_tbl_terminologies,
                                                                        i_row_limit                => l_limit,
                                                                        i_diag_area                => pk_alert_constant.g_diag_area_past_history);
            
            ELSE
                o_diagnoses := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                       i_prof                     => i_prof,
                                                                       i_patient                  => i_patient,
                                                                       i_terminologies_task_types => table_number(l_term_task_type),
                                                                       i_term_task_type           => l_term_task_type,
                                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                       i_text_search              => i_text_search,
                                                                       i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                       i_tbl_terminologies        => i_tbl_terminologies,
                                                                       i_row_limit                => l_limit);
            END IF;
        
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'inner_get_all_diagnoses');
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_get_all_diagnoses;
    
        -- Inner function to retrieves associated diagnoses to complaints
        FUNCTION inner_get_complaint_diagnoses
        (
            i_complaints       IN table_number,
            i_profile_template IN profile_template.id_profile_template%TYPE,
            o_diagnoses        OUT t_coll_diagnosis_config,
            o_diagnoses_count  OUT NUMBER,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN IS
            l_tbl_complaint_adiags table_number;
        BEGIN
            --Table complaint_alert_diagnosis is to be dropped when the new search model is fully implemented
            --Terminology Server will be responsible to check which diagnosis are configured for the given complaints               
            IF (l_term_task_type <> pk_alert_constant.g_task_congenital_anomalies OR
               l_birth_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
               AND (l_term_task_type <> pk_alert_constant.g_task_surgical_history OR
               l_surg_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
               AND (l_term_task_type <> pk_alert_constant.g_task_medical_history OR
               l_med_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
            THEN
                g_error := 'GET COMPLAINT DIAGS';
                SELECT DISTINCT cad.id_alert_diagnosis
                  BULK COLLECT
                  INTO l_tbl_complaint_adiags
                  FROM complaint_alert_diagnosis cad
                 WHERE cad.id_complaint IN (SELECT /*+ cardinality(c 10) */
                                             c.column_value
                                              FROM TABLE(i_complaints) c)
                   AND cad.flg_available = pk_alert_constant.g_available
                   AND cad.id_software IN (i_prof.software, 0)
                   AND cad.id_institution IN (i_prof.institution, 0)
                   AND cad.id_profile_template IN (i_profile_template, 0);
            END IF;
        
            o_diagnoses := t_coll_diagnosis_config();
        
            IF (l_term_task_type = pk_alert_constant.g_task_congenital_anomalies AND
               l_birth_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_surgical_history AND
               l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_medical_history AND
               l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR l_term_task_type IN
               (pk_alert_constant.g_task_family_history, pk_alert_constant.g_task_gynecology_history)
            THEN
                g_error     := 'GET DIAGNOSIS(by complaint)';
                o_diagnoses := pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                        i_prof                     => i_prof,
                                                                        i_patient                  => i_patient,
                                                                        i_terminologies_task_types => table_number(l_term_task_type),
                                                                        i_tbl_term_task_type       => table_number(l_term_task_type),
                                                                        i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                        i_text_search              => i_text_search,
                                                                        i_tbl_complaint            => i_complaints,
                                                                        i_context_type             => pk_ts_logic.k_ctx_type_c_complaint,
                                                                        i_diag_area                => pk_alert_constant.g_diag_area_past_history);
            
            ELSIF l_tbl_complaint_adiags.exists(1)
            THEN
                g_error     := 'GET DIAGNOSIS(by complaint)';
                o_diagnoses := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                       i_prof                     => i_prof,
                                                                       i_patient                  => i_patient,
                                                                       i_terminologies_task_types => table_number(l_term_task_type),
                                                                       i_term_task_type           => l_term_task_type,
                                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                       i_text_search              => i_text_search,
                                                                       i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                       i_tbl_alert_diagnosis      => l_tbl_complaint_adiags);
            END IF;
        
            o_diagnoses_count := o_diagnoses.count;
        
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'inner_get_complaint_diagnoses');
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_get_complaint_diagnoses;
    
        -- Inner function to retrieves associated diagnoses to clinical services
        FUNCTION inner_get_clin_serv_diagnoses
        (
            i_clin_servs       IN table_number,
            i_profile_template IN profile_template.id_profile_template%TYPE,
            o_diagnoses        OUT t_coll_diagnosis_config,
            o_diagnoses_count  OUT NUMBER,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN IS
            l_tbl_cs_adiags table_number;
        BEGIN
            --Table clin_serv_alert_diagnosis is to be dropped when the new search model is fully implemented
            --Terminology Server will be responsible to check which diagnosis are configured for the given clinical services and also dep_clin_serv           
            IF (l_term_task_type <> pk_alert_constant.g_task_congenital_anomalies OR
               l_birth_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
               AND (l_term_task_type <> pk_alert_constant.g_task_surgical_history OR
               l_surg_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
               AND (l_term_task_type <> pk_alert_constant.g_task_medical_history OR
               l_med_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
            THEN
                g_error := 'GET COMPLAINT DIAGS';
                SELECT DISTINCT csd.id_alert_diagnosis
                  BULK COLLECT
                  INTO l_tbl_cs_adiags
                  FROM clin_serv_alert_diagnosis csd
                 WHERE csd.id_clinical_service IN (SELECT /*+ cardinality(c 10) */
                                                    c.column_value
                                                     FROM TABLE(i_clin_servs) c)
                   AND csd.flg_available = pk_alert_constant.g_available
                   AND csd.id_software IN (i_prof.software, 0)
                   AND csd.id_institution IN (i_prof.institution, 0)
                   AND csd.id_profile_template IN (i_profile_template, 0);
            END IF;
        
            o_diagnoses := t_coll_diagnosis_config();
        
            IF (l_term_task_type = pk_alert_constant.g_task_congenital_anomalies AND
               l_birth_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_surgical_history AND
               l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR (l_term_task_type = pk_alert_constant.g_task_medical_history AND
               l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
               OR l_term_task_type IN
               (pk_alert_constant.g_task_family_history, pk_alert_constant.g_task_gynecology_history)
            THEN
                g_error     := 'GET DIAGNOSIS(by dep_clin_serv)';
                o_diagnoses := pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                        i_prof                     => i_prof,
                                                                        i_patient                  => i_patient,
                                                                        i_terminologies_task_types => table_number(l_term_task_type),
                                                                        i_tbl_term_task_type       => table_number(l_term_task_type),
                                                                        i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                        i_text_search              => i_text_search,
                                                                        i_tbl_clin_serv            => i_clin_servs,
                                                                        i_context_type             => pk_ts_logic.k_ctx_type_s_clin_serv,
                                                                        i_diag_area                => pk_alert_constant.g_diag_area_past_history);
            ELSIF l_tbl_cs_adiags.exists(1)
            THEN
                g_error     := 'GET DIAGNOSIS(by clin servs)';
                o_diagnoses := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                       i_prof                     => i_prof,
                                                                       i_patient                  => i_patient,
                                                                       i_terminologies_task_types => table_number(l_term_task_type),
                                                                       i_term_task_type           => l_term_task_type,
                                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                       i_text_search              => i_text_search,
                                                                       i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                       i_tbl_alert_diagnosis      => l_tbl_cs_adiags);
            END IF;
        
            o_diagnoses_count := o_diagnoses.count;
        
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'inner_get_clin_serv_diagnoses');
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_get_clin_serv_diagnoses;
    
    BEGIN
        g_error := 'GET ALERT DIAGNOSIS TYPE';
        IF i_doc_area IN (g_doc_area_past_med)
        THEN
            l_term_task_type := pk_alert_constant.g_task_medical_history;
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            l_term_task_type := pk_alert_constant.g_task_surgical_history;
        ELSIF i_doc_area = g_doc_area_past_fam
        THEN
            l_term_task_type := pk_alert_constant.g_task_family_history;
        ELSIF i_doc_area = g_doc_area_gyn_hist
        THEN
            l_term_task_type := pk_alert_constant.g_task_gynecology_history;
        ELSE
            l_term_task_type := pk_alert_constant.g_task_congenital_anomalies;
        END IF;
    
        -- gets professional's profile_template
        g_error            := 'GET PROFILE_TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        -- check flg_type to select the context 
        g_error := 'OPEN c_context_flg_type';
        OPEN c_context_flg_type;
        FETCH c_context_flg_type
            INTO l_context_flg_type;
        CLOSE c_context_flg_type;
        --
    
        pk_alertlog.log_debug(sub_object_name => 'GET_CONTEXT_ALERT_DIAGNOSIS',
                              text            => 'Context "' || l_context_flg_type || '" for area:' || i_doc_area ||
                                                 ' institution:' || i_prof.institution || ' software:' ||
                                                 i_prof.software);
    
        CASE l_context_flg_type
        --Diagnoses by Complaint
            WHEN g_context_flg_type_compl THEN
            
                -- gets complaint for the current episode
                g_error := 'OPEN c_epis_complaint';
                OPEN c_epis_complaint;
                FETCH c_epis_complaint BULK COLLECT
                    INTO l_complaints;
                CLOSE c_epis_complaint;
            
                IF l_complaints.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_compl;
                ELSE
                    --If no complaints then by episode's clinical service
                    OPEN c_service;
                    FETCH c_service BULK COLLECT
                        INTO l_clinical_services;
                    CLOSE c_service;
                
                    IF l_clinical_services.count > 0
                    THEN
                        l_diagnoses_context := g_context_flg_type_srv;
                    END IF;
                END IF;
            
        --Diagnoses by episode's clinical service
            WHEN g_context_flg_type_srv THEN
            
                g_error := 'OPEN c_service';
                OPEN c_service;
                FETCH c_service BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_service;
            
                IF l_clinical_services.count > 0
                   OR l_dep_clin_serv.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_srv;
                END IF;
            
        --Diagnoses by scheduled clinical service
            WHEN g_context_flg_type_sch_cln_srv THEN
            
                g_error := 'OPEN c_sched_service';
                OPEN c_sched_service;
                FETCH c_sched_service BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_sched_service;
            
                IF l_clinical_services.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_srv;
                END IF;
            
        --Diagnoses by Appointment
            WHEN g_context_flg_type_app THEN
            
                -- gets clinical service for the current episode
                g_error := 'OPEN c_epis_clin_serv';
                OPEN c_epis_clin_serv;
                FETCH c_epis_clin_serv BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_epis_clin_serv;
            
                IF l_clinical_services.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_srv;
                END IF;
            
        --Diagnoses by Area + Complaint
            WHEN pk_touch_option.g_flg_type_doc_area_complaint THEN
            
                -- gets complaint for the current episode
                g_error := 'OPEN c_epis_complaint';
                OPEN c_epis_complaint;
                FETCH c_epis_complaint BULK COLLECT
                    INTO l_complaints;
                CLOSE c_epis_complaint;
            
                IF l_complaints.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_compl;
                ELSE
                    --If no complaints then by episode's clinical service
                    OPEN c_service;
                    FETCH c_service BULK COLLECT
                        INTO l_clinical_services;
                    CLOSE c_service;
                    IF l_clinical_services.count > 0
                    THEN
                        l_diagnoses_context := g_context_flg_type_srv;
                    END IF;
                END IF;
            
        --Diagnoses by episode's clinical service
            WHEN pk_touch_option.g_flg_type_doc_area_service THEN
                g_error := 'OPEN c_service';
                OPEN c_service;
                FETCH c_service BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_service;
            
                IF l_clinical_services.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_srv;
                END IF;
            
        --Diagnoses by Area + Appointment
            WHEN pk_touch_option.g_flg_type_doc_area_appointmt THEN
                -- gets clinical service for the current episode
                g_error := 'OPEN c_epis_clin_serv';
                OPEN c_epis_clin_serv;
                FETCH c_epis_clin_serv BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_epis_clin_serv;
            
                IF l_clinical_services.count > 0
                THEN
                    l_diagnoses_context := g_context_flg_type_srv;
                END IF;
                --Case else by professional's clinical service
            ELSE
                l_diagnoses_context := g_context_flg_type_doc;
            
        END CASE;
    
        l_diagnoses_count := 0;
    
        --ALERT-280874 - AHP - PH/Problems functional area - search improvements
        IF (i_flg_screen = pk_alert_constant.g_diag_area_problems AND
           nvl(length(i_text_search), 0) < pk_problems.g_search_number_char)
           OR i_flg_screen = pk_alert_constant.g_diag_area_past_history
        THEN
            --Retrieves diagnoses by context 
            CASE l_diagnoses_context
            
            --By complaint
                WHEN g_context_flg_type_compl THEN
                    pk_alertlog.log_debug(sub_object_name => 'GET_CONTEXT_ALERT_DIAGNOSIS',
                                          text            => 'Returning past history diagnoses by complaint for area:' ||
                                                             i_doc_area || ' institution:' || i_prof.institution ||
                                                             ' software:' || i_prof.software || ' profile_template:' ||
                                                             l_profile_template || ' complaints:(' ||
                                                             pk_utils.concat_table(l_complaints, ',') || ')');
                
                    g_error := 'inner_get_complaint_diagnoses';
                    IF NOT inner_get_complaint_diagnoses(i_complaints       => l_complaints,
                                                         i_profile_template => l_profile_template,
                                                         o_diagnoses        => o_diagnosis,
                                                         o_diagnoses_count  => l_diagnoses_count,
                                                         o_error            => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            --By (scheduled/episode) clinical service            
                WHEN g_context_flg_type_srv THEN
                    pk_alertlog.log_debug(sub_object_name => 'GET_CONTEXT_ALERT_DIAGNOSIS',
                                          text            => 'Returning past history diagnoses by clinical service for area:' ||
                                                             i_doc_area || ' institution:' || i_prof.institution ||
                                                             ' software:' || i_prof.software);
                
                    g_error := 'inner_get_clin_serv_diagnoses';
                    IF NOT inner_get_clin_serv_diagnoses(i_clin_servs       => l_clinical_services,
                                                         i_profile_template => l_profile_template,
                                                         o_diagnoses        => o_diagnosis,
                                                         o_diagnoses_count  => l_diagnoses_count,
                                                         o_error            => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            --By other context...
                ELSE
                    -- No specific handling code (we use default approach: professional's clinical service)
                    NULL;
            END CASE;
        
            --If no diagnoses by a specific context found then we try to show associated diagnoses to professional's clinical services 
            IF l_diagnoses_count = 0
            THEN
            
                OPEN c_prof_clin_serv;
                FETCH c_prof_clin_serv BULK COLLECT
                    INTO l_clinical_services;
                CLOSE c_prof_clin_serv;
            
                IF l_clinical_services.count > 0
                THEN
                
                    pk_alertlog.log_debug(sub_object_name => 'GET_CONTEXT_ALERT_DIAGNOSIS',
                                          text            => 'Returning past history diagnoses by professional''s clinical service for area:' ||
                                                             i_doc_area || ' institution:' || i_prof.institution ||
                                                             ' software:' || i_prof.software);
                
                    g_error := 'inner_get_clin_serv_diagnoses';
                    IF NOT inner_get_clin_serv_diagnoses(i_clin_servs       => l_clinical_services,
                                                         i_profile_template => l_profile_template,
                                                         o_diagnoses        => o_diagnosis,
                                                         o_diagnoses_count  => l_diagnoses_count,
                                                         o_error            => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --If no diagnoses found for professional's clinical service.
        --Last chance is show diagnoses without a specific context
        IF l_diagnoses_count = 0
           AND nvl(length(TRIM(i_text_search)), 0) != 0 --ALERT-286655 - Documentation button > Past History deepnav > Past Medical History > Add button > is taking too long to load the screen
        THEN
            pk_alertlog.log_debug(sub_object_name => 'GET_CONTEXT_ALERT_DIAGNOSIS',
                                  text            => 'Returning past history diagnoses without context for area:' ||
                                                     i_doc_area || ' institution:' || i_prof.institution || ' software:' ||
                                                     i_prof.software);
            g_error := 'inner_get_all_diagnoses';
            IF NOT inner_get_all_diagnoses(o_diagnoses => o_diagnosis, o_error => o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_past_hist_diagnoses;
    --
    /********************************************************************************************
    * Returns the diagnoses for the current complaint/type of appointment (Both standards diagnoses - like ICD9 - and ALERT diagnoses)
    
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_diagnosis              Cursor containing the diagnoses info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado 
    * @version                        v2.5.0.7       
    * @since                          2009/10/21 (code-refactoring)
    *
    **********************************************************************************************/
    FUNCTION get_context_alert_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_pat            IN patient.id_patient%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_diag_not_class OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_CONTEXT_ALERT_DIAGNOSIS';
    
        function_call_excep EXCEPTION;
        l_tbl_diagnosis     t_coll_diagnosis_config := t_coll_diagnosis_config();
        --
    BEGIN
    
        g_error := 'CALL get_past_hist_diag_not_class';
        IF NOT prv_past_hist_diag_not_class(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_pat            => i_pat,
                                            i_doc_area       => i_doc_area,
                                            o_diag_not_class => o_diag_not_class,
                                            o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_past_hist_diag_not_class';
        IF NOT get_past_hist_diagnoses(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_episode    => i_episode,
                                       i_patient    => i_pat,
                                       i_doc_area   => i_doc_area,
                                       i_flg_screen => pk_alert_constant.g_diag_area_past_history,
                                       o_diagnosis  => l_tbl_diagnosis,
                                       o_error      => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        g_error := 'OPENING O_DIAGNOSIS(by complaint)';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        OPEN o_diagnosis FOR
            SELECT dc.id_alert_diagnosis id_diagnosis,
                   dc.desc_diagnosis,
                   dc.id_diagnosis id_concept_version,
                   pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                   i_id_concept_term    => dc.id_alert_diagnosis,
                                                   i_id_concept_version => dc.id_diagnosis,
                                                   i_id_task_type       => CASE
                                                                               WHEN i_doc_area = g_doc_area_past_med THEN
                                                                                pk_alert_constant.g_task_medical_history
                                                                               WHEN i_doc_area = g_doc_area_past_surg THEN
                                                                                pk_alert_constant.g_task_surgical_history
                                                                               WHEN i_doc_area = g_doc_area_cong_anom THEN
                                                                                pk_alert_constant.g_task_congenital_anomalies
                                                                               ELSE
                                                                                NULL
                                                                           END,
                                                   i_id_institution     => i_prof.institution,
                                                   i_id_software        => i_prof.software) flg_allow_same_icd
              FROM TABLE(l_tbl_diagnosis) dc
             ORDER BY dc.desc_diagnosis ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_CONTEXT_ALERT_DIAGNOSIS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_diagnosis);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONTEXT_ALERT_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
        
    END get_context_alert_diagnosis;
    --

    /********************************************************************************************
    * Returns the procedures and exams (Treatments)
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param o_treatments             Cursor containing the treatments info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Machado 
    * @version                        v2.6.1       
    * @since                          16-Apr-2011
    *
    **********************************************************************************************/
    FUNCTION get_context_treatments
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat             IN patient.id_patient%TYPE,
        o_treatments      OUT pk_types.cursor_type,
        o_treat_not_class OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL get_past_hist_diag_not_class';
        IF NOT prv_past_hist_diag_not_class(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_pat            => i_pat,
                                            i_doc_area       => g_doc_area_treatments,
                                            o_diag_not_class => o_treat_not_class,
                                            o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --Open final cursor
        OPEN o_treatments FOR
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_exam id,
             t.desc_exam description,
             pk_exam_constant.g_type_img exam_type,
             'ImageExameIcon' exam_type_icon
              FROM TABLE(pk_exams_api_db.get_exam_selection_list(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_patient   => i_pat,
                                                                 i_episode   => NULL,
                                                                 i_exam_type => pk_exam_constant.g_type_img,
                                                                 i_flg_type  => pk_past_history.g_flg_treatments_freq)) t
            UNION ALL
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_exam id,
             t.desc_exam description,
             pk_exam_constant.g_type_exm exam_type,
             'TechnicianInContact' exam_type_icon
              FROM TABLE(pk_exams_api_db.get_exam_selection_list(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_patient   => i_pat,
                                                                 i_episode   => NULL,
                                                                 i_exam_type => pk_exam_constant.g_type_exm,
                                                                 i_flg_type  => pk_past_history.g_flg_treatments_freq)) t
            UNION ALL
            SELECT /*+ opt_estimate(table t rows = 1)*/
             t.id_intervention id,
             t.desc_intervention description,
             g_interv_type exam_type,
             'InterventionsIcon' exam_type_icon
              FROM TABLE(pk_procedures_api_db.get_procedure_selection_list(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_patient      => i_pat,
                                                                           i_episode      => NULL,
                                                                           i_flg_type     => pk_past_history.g_flg_treatments_freq,
                                                                           i_codification => NULL)) t
             ORDER BY description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONTEXT_TREATMENTS',
                                              o_error);
            pk_types.open_my_cursor(o_treatments);
        
            RETURN FALSE;
    END get_context_treatments;

    /********************************************************************************************
    * Gets the past history record description
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         Past history description
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/06
    **********************************************************************************************/
    FUNCTION get_desc_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_alert_diagnosis        IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_pat_hist_diag     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_code_icd               IN diagnosis.code_icd%TYPE,
        i_flg_other              IN diagnosis.flg_other%TYPE,
        i_flg_icd9               IN alert_diagnosis_type.flg_icd9%TYPE,
        i_flg_status             IN pat_history_diagnosis.flg_status%TYPE,
        i_flg_compl              IN pat_history_diagnosis.flg_compl%TYPE,
        i_flg_nature             IN pat_history_diagnosis.flg_nature%TYPE,
        i_dt_diagnosed           IN pat_history_diagnosis.dt_diagnosed%TYPE,
        i_dt_diagnosed_precision IN pat_history_diagnosis.dt_diagnosed_precision%TYPE,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        i_family_relationship    IN pat_history_diagnosis.id_family_relationship%TYPE,
        i_flg_description        IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation IS
    
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_ret             pk_translation.t_desc_translation;
        l_error           t_error_out;
        l_status_desc     sys_domain.desc_val%TYPE;
        l_task_type       task_type.id_task_type%TYPE;
    
        l_description_condition table_varchar;
        l_count                 NUMBER;
        --l_phd_desc sys_message.desc_message%TYPE;
        l_phd_info       table_varchar := table_varchar();
        l_task_type_desc VARCHAR2(100);
    BEGIN
    
        IF i_doc_area IN (g_doc_area_past_med, g_doc_area_past_fam)
        THEN
            l_task_type := pk_alert_constant.g_task_medical_history;
        
            SELECT pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_AREA', pk_problems.g_ph_medical_hist, i_lang)
              INTO l_task_type_desc
              FROM dual;
        
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            l_task_type := pk_alert_constant.g_task_surgical_history;
        
            SELECT pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_AREA', pk_problems.g_ph_surgical_hist, i_lang)
              INTO l_task_type_desc
              FROM dual;
        
        ELSIF i_doc_area = g_doc_area_cong_anom
        THEN
            l_task_type := pk_alert_constant.g_task_congenital_anomalies;
        
            SELECT pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_TYPE', g_alert_diag_type_gyneco, i_lang)
              INTO l_task_type_desc
              FROM dual;
        ELSIF i_doc_area = g_doc_area_gyn_hist
        THEN
            l_task_type := pk_alert_constant.g_task_problems;
        
            SELECT pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_TYPE', g_alert_diag_type_cong_anom, i_lang)
              INTO l_task_type_desc
              FROM dual;
        ELSE
            l_task_type := pk_alert_constant.g_task_problems;
        
            SELECT pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_AREA', pk_problems.g_prob, i_lang)
              INTO l_task_type_desc
              FROM dual;
        END IF;
    
        l_phd_info.extend(1);
        --Maidn Description of past history diagnosis iyem
        SELECT decode(i_alert_diagnosis,
                      g_diag_none,
                      pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_none, i_lang),
                      decode(i_alert_diagnosis,
                             g_diag_unknown,
                             pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_unknown, i_lang),
                             decode(i_alert_diagnosis,
                                    g_diag_non_remark,
                                    pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                            g_pat_hist_diag_non_remark,
                                                            i_lang),
                                    decode(i_desc_pat_hist_diag, NULL, '', i_desc_pat_hist_diag || ' - ') ||
                                    pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_alert_diagnosis => i_alert_diagnosis,
                                                               i_id_task_type       => l_task_type,
                                                               i_code               => i_code_icd,
                                                               i_flg_other          => i_flg_other,
                                                               i_flg_std_diag       => i_flg_icd9))))
          INTO l_phd_info(l_phd_info.count)
          FROM dual;
    
        --Check status
        IF (i_flg_status IS NOT NULL)
        THEN
            SELECT pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', i_flg_status, i_lang)
              INTO l_status_desc
              FROM dual;
        
            IF l_status_desc IS NOT NULL
            THEN
                l_phd_info.extend(1);
                l_phd_info(l_phd_info.count) := l_status_desc;
            END IF;
        
        END IF;
    
        --Check complaint
        IF (i_flg_compl IS NOT NULL)
        THEN
            l_phd_info.extend(1);
            SELECT pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', i_flg_compl, i_lang)
              INTO l_phd_info(l_phd_info.count)
              FROM dual;
        END IF;
    
        --Check Nature
        IF (i_flg_nature IS NOT NULL)
        THEN
            l_phd_info.extend(1);
            SELECT pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', i_flg_nature, i_lang)
              INTO l_phd_info(l_phd_info.count)
              FROM dual;
        END IF;
    
        --Check Date
        IF (i_dt_diagnosed IS NOT NULL)
        THEN
            l_phd_info.extend(1);
            SELECT pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => i_dt_diagnosed,
                                                           i_precision => i_dt_diagnosed_precision)
              INTO l_phd_info(l_phd_info.count)
              FROM dual;
        END IF;
        -- family history
        IF i_family_relationship IS NOT NULL
        THEN
            l_phd_info.extend(1);
            SELECT pk_family.get_family_relationship_desc(i_lang, i_family_relationship)
              INTO l_phd_info(l_phd_info.count)
              FROM dual;
        END IF;
    
        --Main descrition
        l_ret := l_phd_info(1);
        l_ret := REPLACE(REPLACE(l_ret, '<b>'), '</b>');
    
        --If phd has more items insert tem in the format (a, b, c..)
        IF (l_phd_info.count > 1 AND l_ret IS NOT NULL)
        THEN
            IF i_flg_description IS NULL
               OR i_flg_description != 'C'
            THEN
                l_ret := l_ret || ' (' || l_phd_info(2);
            
                FOR i IN 3 .. l_phd_info.last
                LOOP
                    l_ret := l_ret || ', ' || l_phd_info(i);
                END LOOP;
            
                l_ret := l_ret || ')';
            
            ELSE
                l_description_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
                IF l_phd_info.count > 1
                THEN
                    l_ret := l_ret || ' (';
                    <<lup_thru_cond>>
                    FOR i IN 1 .. l_description_condition.count
                    LOOP
                        IF l_description_condition(i) = 'CHRONICITY'
                        THEN
                            IF l_phd_info.exists(3)
                            THEN
                                l_ret := l_ret || l_phd_info(3);
                            END IF;
                            NULL;
                        ELSIF l_description_condition(i) = 'STATUS'
                        THEN
                            IF l_phd_info.exists(2)
                            THEN
                                l_ret := l_ret || l_phd_info(2);
                            END IF;
                        
                        ELSIF l_description_condition(i) = 'TYPE'
                        THEN
                            l_ret := l_ret || l_task_type_desc;
                        END IF;
                    
                        -- initial select needs to be changed to optimize this algorithm
                        IF i != l_description_condition.count
                           AND l_ret != l_phd_info(1) || ' ('
                        THEN
                            l_ret := l_ret || ', ';
                        END IF;
                    END LOOP lup_thru_cond;
                
                    l_count := l_description_condition.count + 2;
                    <<lup_thru_others>>
                    FOR i IN l_count .. l_phd_info.count
                    LOOP
                        l_ret := l_ret || ', ' || l_phd_info(i);
                    END LOOP lup_thru_others;
                    l_ret := l_ret || ') ';
                END IF;
            END IF;
        ELSIF l_task_type_desc IS NOT NULL
              AND l_ret IS NOT NULL
              AND i_flg_description = 'C'
        THEN
            l_description_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            l_ret                   := l_ret || ' (';
            FOR i IN 1 .. l_description_condition.count
            LOOP
                IF l_description_condition(i) = 'TYPE'
                THEN
                    l_ret := l_ret || l_task_type_desc;
                END IF;
            END LOOP;
            l_ret := l_ret || ') ';
        
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SECTION_DESC',
                                              l_error);
            RETURN NULL;
    END get_desc_past_hist_all;
    --
    /********************************************************************************************
    * Gets the past history section title associated with a patient record (H and P API)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_hist_diag          Past history diagnosis ID
    * @param i_pat_ph_ft_hist         Past history ID of a free text record
    *                        
    * @return                         Section title
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/04
    **********************************************************************************************/
    FUNCTION get_past_hist_section_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_hist_diag IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_pat_ph_ft     IN pat_past_hist_ft_hist.id_pat_ph_ft%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_ret   pk_translation.t_desc_translation;
        l_error t_error_out;
    
        l_flg_type         pat_history_diagnosis.flg_type%TYPE;
        l_doc_area         doc_area.id_doc_area%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_summ_page_past_hist CONSTANT summary_page.id_summary_page%TYPE := 2;
    
    BEGIN
    
        IF i_pat_hist_diag IS NOT NULL
        THEN
        
            SELECT flg_type
              INTO l_flg_type
              FROM pat_history_diagnosis ph
             WHERE ph.id_pat_history_diagnosis = i_pat_hist_diag;
        
            l_doc_area := prv_conv_flg_type_to_doc_area(l_flg_type);
        
        ELSIF i_pat_ph_ft IS NOT NULL
        THEN
        
            SELECT pf.id_doc_area
              INTO l_doc_area
              FROM pat_past_hist_ft_hist pf
             WHERE pf.id_pat_ph_ft = i_pat_ph_ft
               AND rownum = 1;
        END IF;
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code
          INTO l_ret
          FROM summary_page sp
         INNER JOIN summary_page_section sps
            ON sp.id_summary_page = sps.id_summary_page
         INNER JOIN summary_page_access spa
            ON sps.id_summary_page_section = spa.id_summary_page_section
         WHERE sp.id_summary_page = l_summ_page_past_hist
           AND spa.id_profile_template = l_profile_template
           AND sps.id_doc_area = l_doc_area;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SECTION_DESC',
                                              l_error);
            RETURN NULL;
    END get_past_hist_section_desc;

    /********************************************************************************************
    * Gets the past history record description (H and P API)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_hist_diag          Past history diagnosis ID
    * @param i_pat_ph_ft_hist         Past history ID of a free text record
    *                        
    * @return                         Section title
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/07
    **********************************************************************************************/
    FUNCTION get_past_hist_rec_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pat_hist_diag         IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_pat_ph_ft_hist        IN pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_ret   pk_translation.t_desc_translation;
        l_error t_error_out;
    
    BEGIN
    
        IF i_pat_hist_diag IS NOT NULL
        THEN
        
            SELECT coalesce(get_desc_past_hist_all(i_lang,
                                                   i_prof,
                                                   phd.id_alert_diagnosis,
                                                   phd.desc_pat_history_diagnosis,
                                                   d.code_icd,
                                                   d.flg_other,
                                                   ad.flg_icd9,
                                                   phd.flg_status,
                                                   phd.flg_compl,
                                                   phd.flg_nature,
                                                   phd.dt_diagnosed,
                                                   phd.dt_diagnosed_precision,
                                                   prv_conv_flg_type_to_doc_area(phd.flg_type),
                                                   phd.id_family_relationship,
                                                   i_flg_description,
                                                   i_description_condition),
                            pk_exams_api_db.get_alias_translation(i_lang, i_prof, exm.code_exam, NULL),
                            pk_procedures_api_db.get_alias_translation(i_lang, i_prof, intrv.code_intervention, NULL))
              INTO l_ret
              FROM pat_history_diagnosis phd
              LEFT JOIN alert_diagnosis ad
                ON ad.id_alert_diagnosis = phd.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON d.id_diagnosis = ad.id_diagnosis
              LEFT JOIN exam exm
                ON exm.id_exam = phd.id_exam
              LEFT JOIN intervention intrv
                ON intrv.id_intervention = phd.id_intervention
             WHERE phd.id_pat_history_diagnosis = i_pat_hist_diag;
        
        ELSIF i_pat_ph_ft_hist IS NOT NULL
        THEN
        
            SELECT pk_string_utils.clob_to_sqlvarchar2(pf.text)
              INTO l_ret
              FROM pat_past_hist_free_text pf
             WHERE pf.id_pat_ph_ft = i_pat_ph_ft_hist;
        
        END IF;
    
        -- remove HTML tags
        RETURN REPLACE(REPLACE(l_ret, '<b>'), '</b>');
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_REC_DESC',
                                              l_error);
            RETURN NULL;
    END get_past_hist_rec_desc;

    /********************************************************************************************
    * Returns the information from past medical that was imported from external areas (H and P API)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Current episode ID
    * @param i_patient                   Patient ID
    * @param i_start_date                Start date 
    * @param i_end_date                  End date    
    * @param o_past_med                  External past medical history
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  José Silva
    * @version 2.6.2
    * @since   10-10-2011
    **********************************************************************************************/
    FUNCTION get_past_med_others
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_past_med   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_surgery sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUMMARY_M033');
    
    BEGIN
    
        g_error := 'OPEN o_note';
        OPEN o_past_med FOR
            SELECT /*+ opt_estimate(table tf rows=1) */
             tf.id_episode,
             tf.id_epis_diagnosis,
             NULL id_surgery_record,
             pk_date_utils.date_send_tsz(i_lang, nvl(tf.dt_confirmed_tstz, tf.dt_epis_diagnosis_tstz), i_prof) dt_register,
             pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(tf.id_prof_confirmed, tf.id_professional_diag)) nick_name,
             pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                        i_id_diagnosis        => d.id_diagnosis,
                                        i_id_task_type        => pk_alert_constant.g_task_medical_history,
                                        i_desc_epis_diagnosis => tf.desc_epis_diagnosis,
                                        i_code                => d.code_icd,
                                        i_flg_other           => d.flg_other,
                                        i_flg_std_diag        => ad.flg_icd9,
                                        i_epis_diag           => tf.id_epis_diagnosis) desc_past_hist_all,
             decode(tf.id_episode, i_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
             pk_date_utils.date_char_tsz(i_lang,
                                         nvl(tf.dt_confirmed_tstz, tf.dt_epis_diagnosis_tstz),
                                         i_prof.institution,
                                         i_prof.software) dt_register_chr,
             nvl(tf.dt_confirmed_tstz, tf.dt_epis_diagnosis_tstz) dt_pat_history_diagnosis_tstz,
             nvl(tf.id_prof_confirmed, tf.id_professional_diag) id_professional,
             tf.flg_status status_diagnosis
              FROM diagnosis d
             INNER JOIN TABLE(pk_past_history.tf_epis_diagnosis(i_lang, i_prof, i_patient, i_episode, i_start_date, i_end_date)) tf
                ON (d.id_diagnosis = tf.id_diagnosis)
              LEFT OUTER JOIN alert_diagnosis ad
                ON (tf.id_alert_diagnosis = ad.id_alert_diagnosis)
            UNION ALL
            SELECT /*+ opt_estimate(table t rows=1) */
             t.id_episode,
             NULL id_epis_diagnosis,
             ssr.id_surgery_record,
             pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz, i_prof) dt_register,
             pk_prof_utils.get_name_signature(i_lang,
                                              i_prof,
                                              (SELECT td.id_professional
                                                 FROM sr_prof_team_det td
                                                WHERE td.id_episode = t.id_episode
                                                  AND td.id_professional = td.id_prof_team_leader
                                                  AND td.flg_status = g_active
                                                  AND rownum < 2)) nick_name,
             pk_sr_clinical_info.get_proposed_surgery(i_lang, t.id_episode, i_prof, pk_alert_constant.get_no) || ' (' ||
             l_surgery || ', ' ||
             pk_date_utils.dt_chr_tsz(i_lang, ssr.dt_room_entry_tstz, i_prof.institution, i_prof.software) || ')' desc_past_hist_all,
             decode(t.id_episode, i_episode, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_current_episode,
             pk_date_utils.date_char_tsz(i_lang, ssr.dt_room_entry_tstz, i_prof.institution, i_prof.software) dt_register_chr,
             ei.dt_last_interaction_tstz dt_pat_history_diagnosis_tstz,
             (SELECT td.id_professional
                FROM sr_prof_team_det td
               WHERE td.id_episode = t.id_episode
                 AND td.id_professional = td.id_prof_team_leader
                 AND td.flg_status = g_active
                 AND rownum < 2) id_professional,
             NULL status_diagnosis
              FROM sr_surgery_record ssr
             INNER JOIN schedule_sr ss
                ON (ssr.id_schedule_sr = ss.id_schedule_sr)
             INNER JOIN TABLE(pk_past_history.tf_pat_episode(i_lang, i_prof, i_patient, i_start_date, i_end_date)) t
                ON (ss.id_episode = t.id_episode)
             INNER JOIN epis_info ei
                ON t.id_episode = ei.id_episode
             WHERE ssr.flg_state IN ('O', 'R', 'F')
             ORDER BY flg_current_episode DESC, desc_past_hist_all ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_MED_OTHERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_past_med);
            RETURN FALSE;
    END get_past_med_others;
    --
    /**
     * get the past history mode(s) of documenting data
     *
     * @param i_lang                          Language ID
     * @param i_prof                          Profissional array
     * @param i_doc_area                      ID doc area   
     * @param o_modes                         Cursor with the values of the flags
     * @param o_error                         error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.1
     * @since    12-Apr-2011
     * @author   Filipe Machado
     * @reason   ALERT-65577
    */
    FUNCTION get_ph_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN episode.id_episode%TYPE,
        o_modes    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'get_ph_mode';
        l_dbg_msg   VARCHAR2(200 CHAR);
    BEGIN
    
        l_dbg_msg := 'get the modes for current institution and software';
        OPEN o_modes FOR
            SELECT aux.flg_codified, aux.flg_template, aux.flg_free_text, flg_default
              FROM (SELECT phm.flg_codified, phm.flg_template, phm.flg_free_text, phm.flg_default
                      FROM past_history_mode phm
                     WHERE phm.id_doc_area = i_doc_area
                       AND phm.flg_available = pk_alert_constant.get_yes()
                       AND phm.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND phm.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                     ORDER BY phm.id_institution DESC, phm.id_software DESC) aux
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_ph_mode;
    --

    /********************************************************************************************
    * Returns all diagnosis (Both standards diagnosis - like ICD9 - and ALERT diagnosis)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_format_text            Formats the output occurrences
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado (code-refactoring)
    * @version                        2.6.0.x       
    * @since                          2010/05/11
    **********************************************************************************************/
    FUNCTION prv_get_search_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_search      IN VARCHAR2,
        i_pat         IN patient.id_patient%TYPE,
        i_flg_type    IN table_varchar,
        i_format_text IN VARCHAR2,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_term_task_type    task_type.id_task_type%TYPE;
        l_other_diagnosis   sys_config.value%TYPE;
        l_limit             NUMBER;
        overlimit_exception EXCEPTION;
    
        l_tbl_diags t_coll_diagnosis_config;
    
        l_birth_hist_mechanism sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_birth_hist_search_mechanism,
                                                                                i_prof);
        l_surg_hist_mechanism  sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism,
                                                                                i_prof);
        l_med_hist_mechanism   sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism,
                                                                                i_prof);
    
    BEGIN
    
        pk_alertlog.log_debug(sub_object_name => 'get_alert_diagnosis',
                              text            => 'Type of diagnoses to search - (M)edical; (S)urgical; Congenital (A)nomalies : ' ||
                                                 i_search);
    
        -- permission to use "Other diagnosis" option
        l_other_diagnosis := pk_sysconfig.get_config(pk_summary_page.g_other_diagnosis_config, i_prof);
    
        pk_alertlog.log_info(sub_object_name => 'get_alert_diagnosis',
                             text            => 'Permission to use "Other diagnosis" option (SYS_CONFIG=' ||
                                                pk_summary_page.g_other_diagnosis_config || '): ' || l_other_diagnosis);
    
        g_error := 'IF DOC_AREA';
        IF i_doc_area IN (g_doc_area_past_med)
        THEN
            l_term_task_type := pk_alert_constant.g_task_medical_history;
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            l_term_task_type := pk_alert_constant.g_task_surgical_history;
        ELSIF i_doc_area = g_doc_area_past_fam
        THEN
            l_term_task_type := pk_alert_constant.g_task_family_history;
        ELSIF i_doc_area = g_doc_area_gyn_hist
        THEN
            l_term_task_type := pk_alert_constant.g_task_gynecology_history;
        ELSE
            l_term_task_type := pk_alert_constant.g_task_congenital_anomalies;
        END IF;
    
        pk_alertlog.log_debug(sub_object_name => 'get_alert_diagnosis',
                              text            => 'Type of diagnoses to search - (M)edical; (S)urgical; Congenital (A)nomalies : ' ||
                                                 l_term_task_type);
    
        --We need impose a limit because flash can't handle a list with all diagnoses.
        --If the required diagnosis is not returned then they can use the search button.
        l_limit := to_number(pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof));
    
        pk_alertlog.log_debug(sub_object_name => 'get_alert_diagnosis',
                              text            => 'CALL PK_DIAGNOSIS_CORE.TF_DIAGNOSES_LIST');
        IF (l_term_task_type = pk_alert_constant.g_task_congenital_anomalies AND
           l_birth_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (l_term_task_type = pk_alert_constant.g_task_surgical_history AND
           l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (l_term_task_type = pk_alert_constant.g_task_medical_history AND
           l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR
           l_term_task_type IN (pk_alert_constant.g_task_family_history, pk_alert_constant.g_task_gynecology_history)
        THEN
            l_tbl_diags := pk_terminology_search.get_diagnoses_list(i_lang                     => i_lang,
                                                                    i_prof                     => i_prof,
                                                                    i_patient                  => i_pat,
                                                                    i_text_search              => i_search,
                                                                    i_format_text              => i_format_text,
                                                                    i_terminologies_task_types => table_number(l_term_task_type),
                                                                    i_tbl_term_task_type       => table_number(l_term_task_type),
                                                                    i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                    i_tbl_terminologies        => i_flg_type,
                                                                    i_row_limit                => l_limit,
                                                                    i_diag_area                => pk_alert_constant.g_diag_area_past_history);
        ELSE
            l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                   i_prof                     => i_prof,
                                                                   i_patient                  => i_pat,
                                                                   i_text_search              => i_search,
                                                                   i_format_text              => i_format_text,
                                                                   i_terminologies_task_types => table_number(l_term_task_type),
                                                                   i_term_task_type           => l_term_task_type,
                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                   i_include_other_diagnosis  => l_other_diagnosis,
                                                                   i_tbl_terminologies        => i_flg_type,
                                                                   i_row_limit                => l_limit);
        END IF;
    
        -- cursor with diagnosis (Both standards diagnosis like ICD9 and ALERT diagnosis)
        g_error := 'OPEN c_diagnosis';
        OPEN o_diagnosis FOR
        -- diagnosis according to the search
            SELECT d.id_alert_diagnosis id_diagnosis,
                   d.desc_diagnosis,
                   d.flg_other,
                   d.flg_terminology flg_type,
                   d.id_diagnosis id_concept_version,
                   rownum diag_type_rank,
                   pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                  i_id_concept_term    => d.id_alert_diagnosis,
                                                  i_id_concept_version => d.id_diagnosis,
                                                  i_id_task_type       => l_term_task_type,
                                                  i_id_institution     => i_prof.institution,
                                                  i_id_software        => i_prof.software) flg_allow_same_icd,
                   d.id_tvr_msi
              FROM TABLE(l_tbl_diags) d;
    
        --Display message but returns results restricted to limit 
        IF l_tbl_diags.count > l_limit
        THEN
            RAISE overlimit_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN overlimit_exception THEN
            DECLARE
                l_warn_message VARCHAR2(1000 CHAR);
                l_warn_title   VARCHAR2(1000 CHAR);
            BEGIN
                l_warn_title   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SEARCH_CRITERIA_T001');
                l_warn_message := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_flg_has_action => pk_alert_constant.g_no,
                                                                  i_limit          => l_limit);
            
                pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                    i_sqlcode     => NULL,
                                                    i_sqlerrm     => NULL,
                                                    i_message     => NULL,
                                                    i_owner       => g_package_owner,
                                                    i_package     => g_package_name,
                                                    i_function    => 'GET_ALERT_DIAGNOSIS',
                                                    i_action_type => 'U',
                                                    i_action_msg  => l_warn_message,
                                                    i_msg_title   => l_warn_title,
                                                    o_error       => o_error);
            
                pk_alert_exceptions.reset_error_state();
            
                RETURN TRUE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALERT_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END prv_get_search_diagnosis;
    --

    /********************************************************************************************
    * Returns configured standards(ICD9,ICPC,etc.) that can be used in Past-History diagnoses(advanced search)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_domains                   Available past history diagnoses to search
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 
    * @since   10-Nov-09
    **********************************************************************************************/
    FUNCTION prv_get_diag_search_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_domains  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_term_task_type task_type.id_task_type%TYPE;
    BEGIN
        g_error := 'IF DOC_AREA';
        IF i_doc_area = g_doc_area_past_med
        THEN
            l_term_task_type := pk_alert_constant.g_task_medical_history;
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            l_term_task_type := pk_alert_constant.g_task_surgical_history;
        ELSE
            l_term_task_type := pk_alert_constant.g_task_congenital_anomalies;
        END IF;
    
        g_error := 'OPEN o_domains';
        OPEN o_domains FOR
            SELECT t.flg_terminology       val,
                   t.desc_terminology      desc_val,
                   t.rank                  rank,
                   NULL                    img_name,
                   pk_alert_constant.g_yes flg_select
              FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_tbl_task_type => table_number(l_term_task_type))) t
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALERT_DIAGNOSES_TYPES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END prv_get_diag_search_types;
    --

    /********************************************************************************************
    * Returns configured standards(ICD9,ICPC,etc.) that can be used in Past-History diagnoses(advanced search)
    * or treatment types (Image Exams, Other Exams, Procedures...etc)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_domains                   Available past history diagnoses to search
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Duarte
    * @version 
    * @since   10-Nov-09
    **********************************************************************************************/
    FUNCTION get_past_hist_search_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_domains  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_doc_area = pk_summary_page.g_doc_area_treatments
        THEN
            RETURN pk_sysdomain.get_domains(i_lang        => i_lang,
                                            i_code_domain => g_past_hist_diag_type_treat,
                                            i_prof        => i_prof,
                                            o_domains     => o_domains,
                                            o_error       => o_error);
        ELSE
            RETURN prv_get_diag_search_types(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_doc_area => i_doc_area,
                                             o_domains  => o_domains,
                                             o_error    => o_error);
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SEARCH_TYPES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_past_hist_search_types;
    --
    /********************************************************************************************
    * Returns all diagnosis and treatments
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        2.6.1    
    * @since                          2010/06/13
    **********************************************************************************************/
    FUNCTION get_search_past_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_search    IN VARCHAR2,
        i_pat       IN patient.id_patient%TYPE,
        i_flg_type  IN table_varchar,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_doc_area = pk_summary_page.g_doc_area_treatments
        THEN
            RETURN pk_past_history.get_search_treatments(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_search    => i_search,
                                                         i_pat       => i_pat,
                                                         i_flg_type  => i_flg_type,
                                                         o_diagnosis => o_diagnosis,
                                                         o_error     => o_error);
        ELSE
            RETURN prv_get_search_diagnosis(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_doc_area    => i_doc_area,
                                            i_search      => i_search,
                                            i_pat         => i_pat,
                                            i_flg_type    => i_flg_type,
                                            i_format_text => pk_alert_constant.get_yes,
                                            o_diagnosis   => o_diagnosis,
                                            o_error       => o_error);
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_PAST_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_search_past_hist;
    --   

    /**
    * Returns the lastest update information for the past history summary page
    *
    * @param i_lang        Language ID
    * @param i_prof        Current professional
    * @param i_pat         Patient ID
    * @param i_episode     Episode ID
    * @param o_sections    Cursor containing the sections info
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10 (code-refactoring)
    */
    FUNCTION get_past_hist_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SECTIONS';
        OPEN o_last_update FOR
            SELECT pk_message.get_message(i_lang, 'DOCUMENTATION_T001') title,
                   dt_last_update,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   date_hour_target
              FROM (SELECT row_number() over(ORDER BY date_time DESC) rn, t.*
                      FROM (
                            --Past medical history, Past surgical history, Congenital anomalies
                            SELECT dt_last_update,
                                    nick_name,
                                    desc_speciality,
                                    date_target,
                                    hour_target,
                                    date_time,
                                    date_hour_target
                              FROM (SELECT row_number() over(ORDER BY phd.dt_pat_history_diagnosis_tstz DESC) rn,
                                            dt_pat_history_diagnosis_tstz date_time,
                                            pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_last_update,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, phd.id_professional) nick_name,
                                            pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             phd.id_professional,
                                                                             phd.dt_pat_history_diagnosis_tstz,
                                                                             phd.id_episode) desc_speciality,
                                            pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                  phd.dt_pat_history_diagnosis_tstz,
                                                                                  i_prof) date_target,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             phd.dt_pat_history_diagnosis_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software) hour_target,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        phd.dt_pat_history_diagnosis_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) date_hour_target
                                       FROM pat_history_diagnosis phd
                                      WHERE phd.id_patient = i_pat) t
                             WHERE t.rn = 1
                            
                            UNION ALL
                            --Records done using touch-option templates framework
                            --(Gynecological history, Prenatal,perinatal and neonatal history, Nutritional history, Permanent disabilities, Past social history, Past family history)
                            SELECT dt_last_update,
                                    nick_name,
                                    desc_speciality,
                                    date_target,
                                    hour_target,
                                    date_time,
                                    date_hour_target
                              FROM (SELECT row_number() over(ORDER BY ed.dt_last_update_tstz DESC) rn,
                                            ed.dt_last_update_tstz date_time,
                                            pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_last_update) nick_name,
                                            pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             ed.id_prof_last_update,
                                                                             ed.dt_last_update_tstz,
                                                                             ed.id_episode) desc_speciality,
                                            pk_date_utils.date_chr_short_read_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             ed.dt_last_update_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software) hour_target,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        ed.dt_last_update_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) date_hour_target
                                       FROM epis_documentation ed
                                      INNER JOIN episode e
                                         ON e.id_episode = ed.id_episode
                                      WHERE e.id_patient = i_pat
                                        AND ed.id_doc_area IN (g_doc_area_past_fam,
                                                               g_doc_area_past_soc,
                                                               g_doc_area_food_hist,
                                                               g_doc_area_gyn_hist,
                                                               g_doc_area_natal_hist,
                                                               g_doc_area_perm_incap,
                                                               g_doc_area_occup_hist,
                                                               g_doc_area_abuse_hist)) t
                             WHERE t.rn = 1
                            
                            UNION ALL
                            --Obstetric history
                            SELECT dt_last_update,
                                    nick_name,
                                    desc_speciality,
                                    date_target,
                                    hour_target,
                                    date_time,
                                    date_hour_target
                              FROM (SELECT row_number() over(ORDER BY pp.dt_pat_pregnancy_tstz DESC) rn,
                                            pp.dt_pat_pregnancy_tstz date_time,
                                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional) nick_name,
                                            pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             pp.id_professional,
                                                                             pp.dt_pat_pregnancy_tstz,
                                                                             pp.id_episode) desc_speciality,
                                            pk_date_utils.date_chr_short_read_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) date_target,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             pp.dt_pat_pregnancy_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software) hour_target,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        pp.dt_pat_pregnancy_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) date_hour_target
                                       FROM pat_pregnancy pp
                                      WHERE pp.id_patient = i_pat) t
                             WHERE t.rn = 1
                            
                            -- Relevant notes
                            UNION ALL
                            SELECT dt_last_update,
                                    nick_name,
                                    desc_speciality,
                                    date_target,
                                    hour_target,
                                    date_time,
                                    date_hour_target
                              FROM (SELECT row_number() over(ORDER BY pn.dt_note_tstz DESC) rn,
                                            pn.dt_note_tstz date_time,
                                            pk_date_utils.date_send_tsz(i_lang, pn.dt_note_tstz, i_prof) dt_last_update,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, pn.id_prof_writes) nick_name,
                                            pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             pn.id_prof_writes,
                                                                             pn.dt_note_tstz,
                                                                             pn.id_episode) desc_speciality,
                                            pk_date_utils.date_chr_short_read_tsz(i_lang, pn.dt_note_tstz, i_prof) date_target,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             pn.dt_note_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software) hour_target,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        pn.dt_note_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) date_hour_target
                                     
                                       FROM v_pat_notes pn
                                      WHERE pn.id_patient = i_pat) t
                             WHERE t.rn = 1
                            
                            --Final diagnosis at discharge time that are considered as past medical history
                            UNION ALL
                            SELECT dt_last_update,
                                    nick_name,
                                    desc_speciality,
                                    date_target,
                                    hour_target,
                                    date_time,
                                    date_hour_target
                              FROM (SELECT row_number() over(ORDER BY nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz) DESC) rn,
                                            nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz) date_time,
                                            pk_date_utils.date_send_tsz(i_lang,
                                                                        nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                                        i_prof) dt_last_update,
                                            pk_prof_utils.get_name_signature(i_lang,
                                                                             i_prof,
                                                                             nvl(ed.id_prof_confirmed,
                                                                                 ed.id_professional_diag)) nick_name,
                                            pk_prof_utils.get_spec_signature(i_lang,
                                                                             i_prof,
                                                                             nvl(ed.id_prof_confirmed,
                                                                                 ed.id_professional_diag),
                                                                             nvl(ed.dt_confirmed_tstz,
                                                                                 ed.dt_epis_diagnosis_tstz),
                                                                             ed.id_episode) desc_speciality,
                                            pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                  nvl(ed.dt_confirmed_tstz,
                                                                                      ed.dt_epis_diagnosis_tstz),
                                                                                  i_prof) date_target,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             nvl(ed.dt_confirmed_tstz,
                                                                                 ed.dt_epis_diagnosis_tstz),
                                                                             i_prof.institution,
                                                                             i_prof.software) hour_target,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                                        i_prof.institution,
                                                                        i_prof.software) date_hour_target
                                       FROM epis_diagnosis ed
                                      INNER JOIN episode e
                                         ON e.id_episode = ed.id_episode
                                      WHERE e.id_patient = i_pat
                                        AND ed.flg_type = pk_diagnosis.g_flg_type_disch
                                        AND ed.flg_status IN
                                            (pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_d)
                                           --ALERT-75000: A final diagnosis in current episode cannot be considered at same time a medical history of same episode
                                        AND (ed.id_episode != i_episode OR i_episode IS NULL)) t
                             WHERE t.rn = 1
                            
                            ) t) t
             WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_LAST_UPDATE',
                                              o_error);
            pk_types.open_my_cursor(o_last_update);
            RETURN FALSE;
    END get_past_hist_last_update;
    -- 

    /********************************************************************************************
    * Returns the possible values for complications for a past surgical history.
    *
    * @param i_lang              language id
    * @param i_prof              professional type
    * @param o_problem_compl     Cursor with possible options for the complications
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rui de Sousa Neves
    * @version                   1.0
    * @since                     30-09-2007
    **********************************************************************************************/

    FUNCTION get_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_problem_compl OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --'PAT_PROBLEM.FLG_COMPL_DESC'
        g_error := 'GET CURSOR';
        IF NOT pk_sysdomain.get_domains(i_lang        => i_lang,
                                        i_code_domain => 'PAT_PROBLEM.FLG_COMPL_DESC',
                                        i_prof        => i_prof,
                                        o_domains     => o_problem_compl,
                                        o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_problem_complications',
                                              o_error);
            pk_types.open_my_cursor(o_problem_compl);
            RETURN FALSE;
    END get_complications;
    --

    /********************************************************************************************
    * Returns the details for the past history summary page (medical and surgical history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param i_pat_hist_diag          Past History Diagnosis ID   
    * @param i_all                    True (All), False (Only Create)
    * @param i_flg_ft                 If provided id is from a free text or a diagnosis ID - Yes (Y) No (N) 
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/09/13
    **********************************************************************************************/
    FUNCTION get_past_hist_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_pat_hist_diag     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_all               IN BOOLEAN DEFAULT FALSE,
        i_flg_ft            IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_doc_area = pk_summary_page.g_doc_area_treatments
        THEN
            g_error := 'CALL pk_past_history.get_ph_treatmnt_detail';
            IF NOT prv_get_past_hist_det_treat(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_episode        => i_id_episode,
                                               i_id_patient        => i_id_patient,
                                               i_doc_area          => i_doc_area,
                                               i_pat_hist_diag     => i_pat_hist_diag,
                                               i_all               => i_all,
                                               i_flg_ft            => i_flg_ft,
                                               i_epis_document     => i_epis_document,
                                               o_doc_area_register => o_doc_area_register,
                                               o_doc_area_val      => o_doc_area_val,
                                               o_epis_doc_register => o_epis_doc_register,
                                               o_epis_document_val => o_epis_document_val,
                                               o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
        
            g_error := 'CALL pk_past_history.get_past_hist_det';
            IF NOT prv_get_past_hist_det_diag(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_episode        => i_id_episode,
                                              i_id_patient        => i_id_patient,
                                              i_doc_area          => i_doc_area,
                                              i_pat_hist_diag     => i_pat_hist_diag,
                                              i_all               => i_all,
                                              i_flg_ft            => i_flg_ft,
                                              i_epis_document     => i_epis_document,
                                              o_doc_area_register => o_doc_area_register,
                                              o_doc_area_val      => o_doc_area_val,
                                              o_epis_doc_register => o_epis_doc_register,
                                              o_epis_document_val => o_epis_document_val,
                                              o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        pk_types.open_cursor_if_closed(o_epis_doc_register);
        pk_types.open_cursor_if_closed(o_epis_document_val);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_det',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_past_hist_det;
    --

    /********************************************************************************************
    * Returns info for past history areas based on a scope orientation (Patient,Episode, Visit)
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_doc_area           Documentation area ID
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info
    * @param   o_doc_area           Doc area ID                                     
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_error              Error message
    * 
    * @author  ARIEL.MACHADO
    * @version 2.5.1.2
    * @since   11/04/2010
    **********************************************************************************************/
    FUNCTION get_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_current_episode        IN episode.id_episode%TYPE,
        i_scope                  IN NUMBER,
        i_scope_type             IN VARCHAR2,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        o_doc_area_register      OUT pk_types.cursor_type,
        o_doc_area_val           OUT pk_types.cursor_type,
        o_doc_area_register_tmpl OUT pk_types.cursor_type,
        o_doc_area_val_tmpl      OUT pk_types.cursor_type,
        o_doc_area               OUT doc_area.id_doc_area%TYPE,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_past_hist_all';
        l_patient          patient.id_patient%TYPE;
        l_visit            visit.id_visit%TYPE;
        l_episode          episode.id_episode%TYPE;
        e_invalid_argument EXCEPTION;
        l_count            NUMBER;
        l_template_loaded  BOOLEAN := FALSE;
    BEGIN
    
        -- Past Medical History (relevant diseases included)
        IF i_doc_area = g_doc_area_past_med
        THEN
            g_error := 'CALL TO pk_summary_page.get_past_medical_hist';
            IF NOT get_past_hist_medical(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_current_episode   => i_current_episode,
                                         i_scope             => i_scope,
                                         i_scope_type        => i_scope_type,
                                         o_doc_area_register => o_doc_area_register,
                                         o_doc_area_val      => o_doc_area_val,
                                         o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Past Surgical History
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            g_error := 'CALL TO pk_summary_page.get_past_surgical_hist';
            IF NOT get_past_hist_surgical(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_current_episode   => i_current_episode,
                                          i_scope             => i_scope,
                                          i_scope_type        => i_scope_type,
                                          o_doc_area_register => o_doc_area_register,
                                          o_doc_area_val      => o_doc_area_val,
                                          o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Congenital Anomalies --> Bith History (Pre-Natal, Natal and Congenital Anomalies)
        ELSIF i_doc_area = g_doc_area_cong_anom
        THEN
            g_error := 'CALL TO pk_summary_page.get_cong_anom';
        
            IF NOT get_past_hist_cong_anom(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_current_episode   => i_current_episode,
                                           i_scope             => i_scope,
                                           i_scope_type        => i_scope_type,
                                           o_doc_area_register => o_doc_area_register,
                                           o_doc_area_val      => o_doc_area_val,
                                           o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_doc_area = g_doc_area_gyn_hist
        THEN
            g_error := 'CALL TO pk_summary_page.get_cong_anom';
        
            IF NOT get_past_hist_gyn(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_current_episode   => i_current_episode,
                                     i_scope             => i_scope,
                                     i_scope_type        => i_scope_type,
                                     o_doc_area_register => o_doc_area_register,
                                     o_doc_area_val      => o_doc_area_val,
                                     o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
            -- Treatments
        ELSIF i_doc_area = g_doc_area_treatments
        THEN
            g_error := 'CALL TO pk_summary_page.get_past_hist_treat_intern';
            IF NOT get_past_hist_treatments(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_current_episode   => i_current_episode,
                                            i_scope             => i_scope,
                                            i_scope_type        => i_scope_type,
                                            o_doc_area_register => o_doc_area_register,
                                            o_doc_area_val      => o_doc_area_val,
                                            o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_doc_area = g_doc_area_past_fam
        THEN
            g_error := 'CALL TO pk_summary_page.get_past_hist_family';
        
            IF NOT get_past_hist_family(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_current_episode   => i_current_episode,
                                        i_scope             => i_scope,
                                        i_scope_type        => i_scope_type,
                                        o_doc_area_register => o_doc_area_register,
                                        o_doc_area_val      => o_doc_area_val,
                                        o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Relevant Notes
        ELSIF i_doc_area = g_doc_area_relev_notes
        THEN
            g_error := 'CALL TO pk_summary_page.get_past_hist_relev_notes';
            IF NOT get_past_hist_relev_notes(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_current_episode   => i_current_episode,
                                             i_scope             => i_scope,
                                             i_scope_type        => i_scope_type,
                                             i_doc_area          => i_doc_area,
                                             o_doc_area_register => o_doc_area_register,
                                             o_doc_area_val      => o_doc_area_val,
                                             o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Obstetric history
        ELSIF i_doc_area = g_doc_area_obs_hist
        THEN
            --TODO: get_summ_page_doc_area_pregn doesn't support scope type yet. Returns info using patient scope
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_patient,
                                                  o_visit      => l_visit,
                                                  o_episode    => l_episode,
                                                  o_error      => o_error)
            THEN
                RAISE e_invalid_argument;
            END IF;
        
            g_error := 'CALL TO pk_pregnancy.get_summ_page_doc_area_pregn';
            IF NOT pk_pregnancy.get_summ_page_doc_area_pregn(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_episode           => i_current_episode,
                                                             i_pat               => l_patient,
                                                             i_doc_area          => i_doc_area,
                                                             o_doc_area_register => o_doc_area_register,
                                                             o_doc_area_val      => o_doc_area_val,
                                                             o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            -- Documentation mode like Past Family History / Past Social History / Occupational History (g_doc_area_past_fam, g_doc_area_past_soc, g_doc_area_occup_hist)
            g_error := 'DOCUMENTATION AREAS';
            IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => i_doc_area,
                                                      i_current_episode    => i_current_episode,
                                                      i_scope              => i_scope,
                                                      i_scope_type         => i_scope_type,
                                                      o_doc_area_register  => o_doc_area_register_tmpl,
                                                      o_doc_area_val       => o_doc_area_val_tmpl,
                                                      o_template_layouts   => o_template_layouts,
                                                      o_doc_area_component => o_doc_area_component,
                                                      o_record_count       => l_count,
                                                      o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_template_loaded := TRUE;
        
            g_error := 'CALL TO pk_summary_page.get_past_hist_relev_notes';
            IF NOT pk_past_history.get_past_hist_free_text(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_current_episode   => i_current_episode,
                                                           i_scope             => i_scope,
                                                           i_scope_type        => i_scope_type,
                                                           i_doc_area          => i_doc_area,
                                                           o_doc_area_register => o_doc_area_register,
                                                           o_doc_area_val      => o_doc_area_val,
                                                           o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        IF NOT l_template_loaded
        THEN
            IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => i_doc_area, -- tests purpose 1051
                                                      i_current_episode    => i_current_episode,
                                                      i_scope              => i_scope,
                                                      i_scope_type         => i_scope_type,
                                                      o_doc_area_register  => o_doc_area_register_tmpl,
                                                      o_doc_area_val       => o_doc_area_val_tmpl,
                                                      o_template_layouts   => o_template_layouts,
                                                      o_doc_area_component => o_doc_area_component,
                                                      o_record_count       => l_count,
                                                      o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        o_doc_area := i_doc_area;
    
        pk_types.open_cursor_if_closed(o_template_layouts);
        pk_types.open_cursor_if_closed(o_doc_area_component);
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        pk_types.open_cursor_if_closed(o_doc_area_register_tmpl);
        pk_types.open_cursor_if_closed(o_doc_area_val_tmpl);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_past_hist_all;
    --
    /********************************************************************************************
    * Returns last activa past history records for dashboards
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   o_past_med_hist      Cursor containing active past history records
    * @param   o_error              Error message
    * 
    * @author  Rui Duarte
    * @version 2.6.1.5
    * @since   11/11/2011
    **********************************************************************************************/
    FUNCTION prv_get_ph_summary_list_diag
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diag_flg_type  pat_history_diagnosis.flg_type%TYPE;
        l_diag_task_type task_type.id_task_type%TYPE;
        l_scope_type     VARCHAR2(1);
        l_scope_episode  table_number;
        l_max_date       pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE;
    BEGIN
        g_error          := 'Call prv_conv_doc_area_to_flg_type';
        l_diag_flg_type  := prv_conv_doc_area_to_flg_type(i_doc_area);
        l_diag_task_type := prv_conv_doc_area_to_task_type(i_doc_area);
    
        -- Get scope type filter depending on software type
        IF i_prof.software = pk_alert_constant.g_soft_inpatient
           OR i_prof.software = pk_alert_constant.g_soft_nutritionist
        THEN
            l_scope_type := pk_alert_constant.g_scope_type_patient;
        ELSE
            l_scope_type := pk_alert_constant.g_scope_type_episode;
        END IF;
    
        -- Get scope episodes
        l_scope_episode := pk_episode.get_scope(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_patient    => i_patient,
                                                i_episode    => i_episode,
                                                i_flg_filter => l_scope_type);
    
        --Get latest date codified
        SELECT MAX(dt_out)
          INTO l_max_date
          FROM (SELECT MAX(p2.dt_pat_history_diagnosis_tstz) dt_out
                  FROM pat_history_diagnosis p2
                 WHERE p2.id_episode IN (SELECT *
                                           FROM TABLE(l_scope_episode))
                   AND nvl(p2.flg_status, g_active) != g_pat_hist_diag_canceled
                   AND p2.flg_type = l_diag_flg_type
                   AND p2.id_diagnosis IS NOT NULL
                UNION
                SELECT pphft.dt_register dt_out
                  FROM pat_past_hist_free_text pphft
                 WHERE pphft.id_episode IN (SELECT *
                                              FROM TABLE(l_scope_episode))
                   AND pphft.flg_status != g_pat_hist_diag_canceled
                   AND pphft.flg_type = l_diag_flg_type);
    
        g_error := 'OPEN O_PAST_MED_HIST';
        -- only show records from the emergency episode
        OPEN o_past_history FOR
            SELECT REPLACE(REPLACE(decode(phd.id_alert_diagnosis,
                                          pk_summary_page.g_diag_none,
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  pk_summary_page.g_pat_hist_diag_none,
                                                                  i_lang),
                                          decode(phd.id_alert_diagnosis,
                                                 pk_summary_page.g_diag_unknown,
                                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                         pk_summary_page.g_pat_hist_diag_unknown,
                                                                         i_lang),
                                                 decode(phd.id_alert_diagnosis,
                                                        g_diag_non_remark,
                                                        pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                                g_pat_hist_diag_non_remark,
                                                                                i_lang),
                                                        decode(phd.desc_pat_history_diagnosis,
                                                               NULL,
                                                               '',
                                                               phd.desc_pat_history_diagnosis || ' - ') ||
                                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                   i_prof               => i_prof,
                                                                                   i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                                   i_id_diagnosis       => d.id_diagnosis,
                                                                                   i_id_task_type       => l_diag_task_type,
                                                                                   i_code               => d.code_icd,
                                                                                   i_flg_other          => d.flg_other,
                                                                                   i_flg_std_diag       => ad.flg_icd9)))),
                                   '<b>',
                                   ''),
                           '</b>',
                           '') desc_element
              FROM pat_history_diagnosis phd, alert_diagnosis_type ad, diagnosis d
             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND nvl(phd.flg_status, g_active) != g_pat_hist_diag_canceled
               AND phd.id_episode IN (SELECT *
                                        FROM TABLE(l_scope_episode))
               AND phd.flg_type = l_diag_flg_type
               AND phd.flg_area <> pk_alert_constant.g_diag_area_problems
               AND (phd.id_alert_diagnosis NOT IN
                   (pk_summary_page.g_diag_none, pk_summary_page.g_diag_unknown, g_diag_non_remark) OR
                   phd.id_pat_history_diagnosis_new IS NULL)
               AND phd.dt_pat_history_diagnosis_tstz = l_max_date
            UNION ALL
            SELECT REPLACE(REPLACE(decode(phd.id_alert_diagnosis,
                                          pk_past_history.g_diag_none,
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  pk_past_history.g_pat_hist_diag_none,
                                                                  i_lang),
                                          pk_past_history.g_diag_unknown,
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  pk_past_history.g_pat_hist_diag_unknown,
                                                                  i_lang),
                                          g_diag_non_remark,
                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                  pk_past_history.g_pat_hist_diag_non_remark,
                                                                  i_lang)),
                                   '<b>'),
                           '</b>')
              FROM pat_history_diagnosis phd
             WHERE nvl(phd.flg_status, g_active) != g_pat_hist_diag_canceled
               AND phd.id_episode IN (SELECT *
                                        FROM TABLE(l_scope_episode))
               AND phd.flg_type = l_diag_flg_type
               AND (phd.id_alert_diagnosis IN (g_diag_none, g_diag_unknown, g_diag_non_remark) AND
                    phd.id_pat_history_diagnosis_new IS NULL)
            UNION ALL
            SELECT pk_string_utils.clob_to_sqlvarchar2(pphft.text) desc_element
              FROM pat_past_hist_free_text pphft
             WHERE pphft.id_episode IN (SELECT *
                                          FROM TABLE(l_scope_episode))
               AND pphft.flg_type = l_diag_flg_type
               AND pphft.dt_register = l_max_date;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_ph_summary_list',
                                              o_error);
            pk_types.open_my_cursor(o_past_history);
            RETURN FALSE;
    END prv_get_ph_summary_list_diag;
    --    
    /********************************************************************************************
    * Returns last activa past history records for dashboards
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   o_past_med_hist      Cursor containing active past history records
    * @param   o_error              Error message
    * 
    * @author  Rui Duarte
    * @version 2.6.1.5
    * @since   11/11/2011
    **********************************************************************************************/
    FUNCTION get_ph_summary_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        g_error := 'CALL get_past_hist_relev_notes_int';
        IF (i_doc_area = g_doc_area_past_med OR i_doc_area = g_doc_area_past_surg)
        THEN
        
            IF NOT prv_get_ph_summary_list_diag(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_patient      => i_patient,
                                                i_episode      => i_episode,
                                                i_doc_area     => i_doc_area,
                                                o_past_history => o_past_history,
                                                o_error        => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        ELSE
        
            --
            BEGIN
                g_error := 'FIND LAST EPIS_OBSERVATION - TOUCH OPTION';
                SELECT id_epis_documentation
                  INTO l_last_epis_touch_option
                  FROM (SELECT ed.id_epis_documentation
                          FROM epis_documentation ed
                         WHERE ed.id_episode IN (SELECT e.id_episode
                                                   FROM episode e
                                                  WHERE e.id_patient = i_patient)
                           AND ed.id_doc_area = i_doc_area
                           AND ed.flg_status != pk_alert_constant.g_cancelled
                         ORDER BY ed.dt_creation_tstz DESC)
                 WHERE rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_epis_documentation => l_last_epis_touch_option,
                                                          i_doc_area           => i_doc_area,
                                                          o_documentation      => o_past_history,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_ph_summary_list',
                                              o_error);
            pk_types.open_my_cursor(o_past_history);
            RETURN FALSE;
    END get_ph_summary_list;

    FUNCTION convert_to_tstz
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  VARCHAR2,
        i_value VARCHAR2
    ) RETURN VARCHAR2 IS
        l_value_parts table_varchar2;
        l_dt_str      VARCHAR2(14 CHAR);
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN NULL;
        ELSE
            CASE i_type
            -- Element type: compound element for dates
                WHEN pk_touch_option.g_elem_flg_type_comp_date THEN
                
                    -- <date_value>|<date_type>
                    l_value_parts := pk_utils.str_split(i_value, '|');
                    IF l_value_parts.count != 2
                    THEN
                        l_dt_str := NULL;
                    ELSE
                    
                        IF l_value_parts(2) = 'YYYY'
                        THEN
                            l_dt_str := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                    i_date => pk_date_utils.convert_dt_tsz(i_lang,
                                                                                                           i_prof,
                                                                                                           to_date('01' ||
                                                                                                                   l_value_parts(1),
                                                                                                                   'MMYYYY')),
                                                                    i_prof => i_prof);
                        ELSE
                            l_dt_str := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                    i_date => pk_date_utils.convert_dt_tsz(i_lang,
                                                                                                           i_prof,
                                                                                                           to_date(l_value_parts(1),
                                                                                                                   l_value_parts(2))),
                                                                    i_prof => i_prof);
                        
                        END IF;
                    END IF;
                ELSE
                    l_dt_str := NULL;
            END CASE;
        
        END IF;
        RETURN l_dt_str;
    END convert_to_tstz;

    FUNCTION tf_past_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_area      IN NUMBER,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED IS
        l_error                t_error_out;
        l_id_patient           patient.id_patient%TYPE;
        l_id_episode           episode.id_episode%TYPE;
        l_id_visit             visit.id_visit%TYPE;
        l_rec_past_history_cda t_rec_past_history_cda;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'TF_PAST_HISTORY_CDA';
    
    BEGIN
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_has_error := TRUE;
            g_error     := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            g_has_error := TRUE;
            RAISE g_exception;
        END IF;
    
        FOR l_rec_past_history_cda IN (SELECT d.id_epis_documentation_det,
                                              d.flg_status,
                                              d.desc_status,
                                              d.id_content_doc_component,
                                              d.id_doc_component,
                                              d.desc_doc_component,
                                              d.id_content_doc_element_crit,
                                              d.desc_doc_element,
                                              d.element_domain_value,
                                              d.dt_reg_str,
                                              d.dt_reg_tstz,
                                              d.dt_reg_formatted,
                                              d.internal_name,
                                              d.id_epis_documentation,
                                              d.reg_date,
                                              d.reg_date_str
                                         FROM (SELECT edd.id_epis_documentation_det,
                                                      ed.flg_status,
                                                      pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS',
                                                                              ed.flg_status,
                                                                              i_lang) desc_status,
                                                      pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg_str,
                                                      ed.dt_creation_tstz dt_reg_tstz,
                                                      pk_date_utils.date_char_tsz(i_lang,
                                                                                  ed.dt_creation_tstz,
                                                                                  i_prof.institution,
                                                                                  i_prof.software) dt_reg_formatted,
                                                      dc.id_content id_content_doc_component,
                                                      dc.id_doc_component,
                                                      pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                                                      ec.id_content id_content_doc_element_crit,
                                                      pk_touch_option.get_epis_formatted_element(i_lang,
                                                                                                 i_prof,
                                                                                                 edd.id_epis_documentation_det,
                                                                                                 pk_alert_constant.get_no) desc_doc_element,
                                                      edd.value element_domain_value,
                                                      (SELECT doce.internal_name
                                                         FROM doc_element doce
                                                        WHERE doce.id_doc_element = ec.id_doc_element) internal_name,
                                                      ed.id_epis_documentation,
                                                      pk_touch_option_core.get_unformatted_value(i_lang               => i_lang,
                                                                                                 i_prof               => i_prof,
                                                                                                 i_doc_element_crit   => ec.id_doc_element_crit,
                                                                                                 i_epis_documentation => ed.id_epis_documentation) reg_date,
                                                      --convert_to_tstz(i_lang, i_prof,de.flg_type,edd.value) reg_date_str 
                                                      NULL reg_date_str
                                                 FROM epis_documentation ed
                                                INNER JOIN epis_documentation_det edd
                                                   ON ed.id_epis_documentation = edd.id_epis_documentation
                                                INNER JOIN documentation d
                                                   ON d.id_documentation = edd.id_documentation
                                                INNER JOIN doc_component dc
                                                   ON dc.id_doc_component = d.id_doc_component
                                                INNER JOIN doc_element de
                                                   ON edd.id_doc_element = de.id_doc_element
                                                INNER JOIN doc_element_crit ec
                                                   ON ec.id_doc_element_crit = edd.id_doc_element_crit
                                                INNER JOIN (SELECT e.id_episode
                                                             FROM episode e
                                                            WHERE e.id_patient = l_id_patient
                                                              AND i_scope_type = pk_alert_constant.g_scope_type_patient) epi
                                                   ON epi.id_episode = ed.id_episode
                                                WHERE ed.id_doc_area = i_id_doc_area
                                                  AND ed.flg_status = pk_alert_constant.g_active
                                                  AND (dc.id_content IN
                                                      (SELECT /*+ opt_estimate(table t rows=3) */
                                                         column_value
                                                          FROM TABLE(i_id_doc_component) t) OR
                                                      i_id_doc_component IS NULL)
                                                  AND ed.id_epis_documentation =
                                                      (SELECT id_epis_documentation
                                                         FROM epis_documentation ed2
                                                        WHERE ed2.id_doc_area = i_id_doc_area
                                                          AND dt_creation_tstz =
                                                              (SELECT MAX(ed.dt_creation_tstz)
                                                                 FROM epis_documentation ed1
                                                                WHERE ed1.id_episode = epi.id_episode
                                                                  AND ed1.id_doc_area = i_id_doc_area
                                                                  AND ed1.flg_status = pk_alert_constant.g_active))
                                                ORDER BY ed.id_epis_documentation, d.rank) d)
        LOOP
            PIPE ROW(l_rec_past_history_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_past_history_cda;

    /**********************************************************************************************
    * List of social history for CDA section: Social history
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    *
    * @return                        Table with social history records
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2014/01/02 
    * @Updated By                    Gisela Couto - 2014/05/05
    ***********************************************************************************************/
    FUNCTION tf_social_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED IS
        l_error               t_error_out;
        l_rec_social_hist_cda t_rec_past_history_cda;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'TF_SOCIAL_HISTORY_CDA';
    BEGIN
    
        FOR l_rec_social_hist_cda IN (SELECT t.*
                                        FROM TABLE(pk_past_history.tf_past_history_cda(i_lang             => i_lang,
                                                                                       i_prof             => i_prof,
                                                                                       i_scope            => i_scope,
                                                                                       i_scope_type       => i_scope_type,
                                                                                       i_id_doc_area      => g_doc_area_past_soc,
                                                                                       i_id_doc_component => i_id_doc_component)) t)
        LOOP
            PIPE ROW(l_rec_social_hist_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_social_history_cda;

    FUNCTION tf_family_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED IS
        l_error                  t_error_out;
        l_rec_family_history_cda t_rec_past_history_cda;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'TF_FAMILY_HISTORY_CDA';
    BEGIN
    
        FOR l_rec_family_history_cda IN (SELECT t.*
                                           FROM TABLE(pk_past_history.tf_past_history_cda(i_lang             => i_lang,
                                                                                          i_prof             => i_prof,
                                                                                          i_scope            => i_scope,
                                                                                          i_scope_type       => i_scope_type,
                                                                                          i_id_doc_area      => g_doc_area_past_fam,
                                                                                          i_id_doc_component => i_id_doc_component)) t)
        LOOP
            PIPE ROW(l_rec_family_history_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_family_history_cda;

    FUNCTION tf_past_illness_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_code_icd   IN table_varchar
    ) RETURN t_coll_past_illness_cda
        PIPELINED IS
        l_error                t_error_out;
        l_id_patient           patient.id_patient%TYPE;
        l_id_episode           episode.id_episode%TYPE;
        l_id_visit             visit.id_visit%TYPE;
        l_rec_past_illness_cda t_rec_past_illness_cda;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'TF_PAST_ILLNESS_CDA';
    BEGIN
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_has_error := TRUE;
            g_error     := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            g_has_error := TRUE;
            RAISE g_exception;
        END IF;
    
        FOR l_rec_past_illness_cda IN (SELECT i.code_icd,
                                              i.desc_illness,
                                              i.id_content,
                                              i.flg_status,
                                              i.desc_status,
                                              i.flg_area,
                                              i.dt_illness_to_print,
                                              i.dt_illness,
                                              i.dt_illness_serial,
                                              i.resolution_date_str,
                                              i.resolution_date,
                                              i.dt_diagnosed_str,
                                              i.dt_diagnosed_serial,
                                              i.id_terminology_version,
                                              i.notes
                                         FROM (SELECT d.code_icd,
                                                      pk_past_history.get_desc_past_hist_all(i_lang,
                                                                                             i_prof,
                                                                                             phd.id_alert_diagnosis,
                                                                                             phd.desc_pat_history_diagnosis,
                                                                                             d.code_icd,
                                                                                             d.flg_other,
                                                                                             ad.flg_icd9,
                                                                                             phd.flg_status,
                                                                                             phd.flg_compl,
                                                                                             phd.flg_nature,
                                                                                             phd.dt_diagnosed,
                                                                                             phd.dt_diagnosed_precision,
                                                                                             g_doc_area_past_med,
                                                                                             phd.id_family_relationship) desc_illness,
                                                      d.id_content,
                                                      decode(phd.flg_status,
                                                             pk_alert_constant.g_cancelled,
                                                             pk_alert_constant.g_cancelled,
                                                             nvl2(phd.id_pat_history_diagnosis_new,
                                                                  pk_alert_constant.g_outdated,
                                                                  g_active)) flg_status,
                                                      pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                              phd.flg_status,
                                                                              i_lang) desc_status,
                                                      phd.flg_area,
                                                      dt_diagnosed,
                                                      pk_date_utils.date_send_tsz(i_lang,
                                                                                  phd.dt_pat_history_diagnosis_tstz,
                                                                                  i_prof) dt_illness_serial,
                                                      phd.dt_pat_history_diagnosis_tstz dt_illness,
                                                      pk_date_utils.date_char_tsz(i_lang,
                                                                                  phd.dt_pat_history_diagnosis_tstz,
                                                                                  i_prof.institution,
                                                                                  i_prof.software) dt_illness_to_print,
                                                      pk_date_utils.date_send_tsz(i_lang, phd.dt_resolved, i_prof) resolution_date_str,
                                                      phd.dt_resolved resolution_date,
                                                      get_partial_date_format(i_lang,
                                                                              i_prof,
                                                                              phd.dt_diagnosed,
                                                                              phd.dt_diagnosed_precision) dt_diagnosed_str,
                                                      get_partial_date_format_serial(i_lang,
                                                                                     i_prof,
                                                                                     phd.dt_diagnosed,
                                                                                     phd.dt_diagnosed_precision) dt_diagnosed_serial,
                                                      d.id_terminology_version,
                                                      phd.notes
                                                 FROM pat_history_diagnosis phd
                                                 LEFT JOIN alert_diagnosis ad
                                                   ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                                                 LEFT JOIN diagnosis d
                                                   ON ad.id_diagnosis = d.id_diagnosis
                                                INNER JOIN (SELECT e.id_episode
                                                             FROM episode e
                                                            WHERE e.id_patient = l_id_patient
                                                              AND i_scope_type = pk_alert_constant.g_scope_type_patient) epi
                                                   ON phd.id_episode = epi.id_episode
                                                WHERE phd.flg_area IN
                                                      (pk_alert_constant.g_diag_area_past_history,
                                                       pk_alert_constant.g_diag_area_problems,
                                                       pk_alert_constant.g_diag_area_not_defined)
                                                  AND nvl(phd.flg_status, pk_past_history.g_active) !=
                                                      pk_past_history.g_pat_hist_diag_canceled
                                                  AND id_pat_history_diagnosis =
                                                      pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                                           phd.id_alert_diagnosis,
                                                                                           phd.desc_pat_history_diagnosis,
                                                                                           l_id_patient,
                                                                                           i_prof,
                                                                                           pk_alert_constant.g_no,
                                                                                           phd.flg_type)) i)
        LOOP
            PIPE ROW(l_rec_past_illness_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_past_illness_cda;

    FUNCTION get_past_hist_ids_review
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN table_number,
        i_flg_context IN review_detail.flg_context%TYPE,
        i_flg_area    IN table_varchar,
        i_doc_area    IN doc_area.id_doc_area%TYPE
    ) RETURN table_number IS
        l_ids table_number;
    BEGIN
        IF i_flg_context = pk_review.get_past_history_context
        THEN
            SELECT phd.id_pat_history_diagnosis
              BULK COLLECT
              INTO l_ids
              FROM review_detail rd
              LEFT JOIN pat_history_diagnosis phd
                ON phd.id_pat_history_diagnosis = rd.id_record_area
             WHERE rd.flg_context = i_flg_context
               AND rd.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_episode) t)
               AND phd.flg_area IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     t.column_value flg_area
                                      FROM TABLE(i_flg_area) t)
               AND rd.flg_auto = pk_alert_constant.g_no
               AND nvl(phd.flg_status, pk_past_history.g_active) != pk_past_history.g_pat_hist_diag_canceled
             ORDER BY rd.dt_review DESC, rd.id_record_area DESC;
        ELSIF i_flg_context = pk_review.get_template_context
        THEN
            SELECT ed.id_epis_documentation
              BULK COLLECT
              INTO l_ids
              FROM review_detail rd
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = rd.id_record_area
             WHERE rd.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_episode) t)
               AND rd.flg_context = i_flg_context
               AND ed.id_doc_area = i_doc_area
               AND rd.flg_auto = pk_alert_constant.g_no
               AND ed.flg_status = pk_touch_option.g_active;
        ELSIF i_flg_context = pk_review.get_past_history_ft_context
        THEN
            SELECT phft.id_pat_ph_ft_hist
              BULK COLLECT
              INTO l_ids
              FROM pat_past_hist_ft_hist phft
              JOIN review_detail rd
                ON phft.id_pat_ph_ft_hist = rd.id_record_area
             WHERE rd.flg_context = pk_review.get_past_history_ft_context
               AND phft.id_doc_area = i_doc_area
               AND rd.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_episode) t)
               AND phft.flg_status = pk_alert_constant.g_active
               AND rd.flg_auto = pk_alert_constant.g_no;
        END IF;
        RETURN l_ids;
    END get_past_hist_ids_review;

    FUNCTION get_last_past_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_past_hist_ft        pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
        l_dt_register_ft         pat_past_hist_ft_hist.dt_register%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
        g_error := 'GET LAST FREE TEXT RECORD';
        BEGIN
            SELECT id_past_hist_ft, dt_register
              INTO l_id_past_hist_ft, l_dt_register_ft
              FROM (SELECT id_past_hist_ft, dt_register
                      FROM (SELECT phft.id_pat_ph_ft_hist id_past_hist_ft, phft.dt_register dt_register
                              FROM pat_past_hist_ft_hist phft
                             WHERE phft.id_patient = i_patient
                               AND phft.id_episode = i_episode
                               AND phft.id_doc_area = i_doc_area
                               AND phft.flg_status = pk_alert_constant.g_active
                            UNION
                            SELECT phft.id_pat_ph_ft_hist, rd.dt_review dt_register
                              FROM pat_past_hist_ft_hist phft
                              JOIN review_detail rd
                                ON phft.id_pat_ph_ft = rd.id_record_area
                             WHERE phft.id_patient = i_patient
                               AND rd.flg_context = pk_review.get_past_history_ft_context
                               AND phft.id_doc_area = i_doc_area
                               AND rd.id_episode = i_episode
                               AND phft.flg_status = pk_alert_constant.g_active
                               AND rd.flg_auto = pk_alert_constant.g_no) t
                     ORDER BY dt_register DESC)
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        g_error := 'GET LAST DOCUMENTATION _RECORD';
        BEGIN
            SELECT id_epis_documentation, dt_creation
              INTO l_last_epis_touch_option, l_last_date_touch_option
              FROM (SELECT id_epis_documentation, dt_creation, row_number() over(ORDER BY dt_creation DESC) rn
                      FROM (SELECT ed.id_epis_documentation id_epis_documentation, ed.dt_creation_tstz dt_creation
                              FROM epis_documentation ed
                             INNER JOIN episode e
                                ON e.id_episode = ed.id_episode
                             WHERE ed.id_doc_area = i_doc_area
                               AND (e.id_episode = i_episode OR ed.id_episode_context = i_episode)
                               AND ed.flg_status = pk_touch_option.g_epis_doc_active
                            UNION
                            SELECT ed.id_epis_documentation, rd.dt_review
                              FROM epis_documentation ed
                             INNER JOIN episode e
                                ON e.id_episode = ed.id_episode
                              JOIN review_detail rd
                                ON ed.id_epis_documentation = rd.id_record_area
                             WHERE ed.id_doc_area = i_doc_area
                               AND (rd.id_episode = i_episode)
                               AND ed.flg_status = pk_touch_option.g_epis_doc_active
                               AND rd.flg_context = pk_review.get_template_context
                               AND rd.flg_auto = pk_alert_constant.g_no))
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        IF l_dt_register_ft > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            OPEN o_past_history FOR
                SELECT i_episode id_episode, ppft.text desc_info
                  FROM pat_past_hist_ft_hist ppft
                 WHERE ppft.id_pat_ph_ft_hist = l_id_past_hist_ft;
        ELSIF l_last_date_touch_option > l_dt_register_ft
              OR l_dt_register_ft IS NULL
        THEN
            IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_epis_documentation => l_last_epis_touch_option,
                                                          i_doc_area           => i_doc_area,
                                                          o_documentation      => o_past_history,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_PAST_HIST',
                                              o_error);
            pk_types.open_my_cursor(o_past_history);
            RETURN FALSE;
    END get_last_past_hist;

    FUNCTION get_past_history_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN table_number,
        i_pat          IN patient.id_patient%TYPE,
        i_flg_type     IN VARCHAR2,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_flg_ft       IN VARCHAR2 DEFAULT NULL,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PAST_HISTORY_M062');
    BEGIN
        IF i_doc_area = pk_past_history.g_doc_area_relev_notes
        THEN
            OPEN o_past_history FOR
                SELECT pn.notes desc_info,
                       pn.id_episode,
                       pn.dt_note_tstz dt_register,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          pn.id_episode,
                                                          pn.dt_note_tstz,
                                                          pn.id_prof_writes) signature
                  FROM v_pat_notes pn
                 WHERE pn.id_episode IN (SELECT *
                                           FROM TABLE(i_epis))
                   AND pn.flg_status != pk_alert_constant.g_cancelled
                UNION ALL
                SELECT phft.text,
                       rd.id_episode,
                       rd.dt_review,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          phft.id_episode,
                                                          phft.dt_register,
                                                          phft.id_professional) signature
                  FROM pat_past_hist_ft_hist phft
                  JOIN review_detail rd
                    ON phft.id_pat_ph_ft = rd.id_record_area
                 WHERE rd.flg_context = pk_review.get_past_history_ft_context
                   AND phft.id_doc_area = i_doc_area
                   AND rd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                          *
                                           FROM TABLE(i_epis) t)
                   AND phft.flg_status = pk_alert_constant.g_active
                   AND phft.id_pat_ph_ft_hist NOT IN
                       (SELECT pfh.id_pat_ph_ft_hist
                          FROM pat_past_hist_ft_hist pfh
                         WHERE pfh.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_epis) t)
                           AND pfh.id_doc_area = i_doc_area
                           AND pfh.flg_status = pk_alert_constant.g_active)
                 ORDER BY dt_register;
        ELSIF i_flg_ft = 'FT'
        THEN
            OPEN o_past_history FOR
                SELECT phft.text desc_info,
                       phft.id_episode,
                       phft.id_doc_area,
                       phft.dt_register,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          phft.id_episode,
                                                          phft.dt_register,
                                                          phft.id_professional) signature
                  FROM pat_past_hist_ft_hist phft
                 WHERE phft.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(i_epis) t)
                   AND phft.id_doc_area IN (pk_past_history.g_doc_area_past_fam, pk_past_history.g_doc_area_past_soc)
                   AND phft.flg_status = pk_alert_constant.g_active
                UNION ALL
                SELECT phft.text desc_info,
                       rd.id_episode,
                       phft.id_doc_area,
                       rd.dt_review,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          phft.id_episode,
                                                          rd.dt_review,
                                                          rd.id_professional) signature
                  FROM pat_past_hist_ft_hist phft
                  JOIN review_detail rd
                    ON phft.id_pat_ph_ft = rd.id_record_area
                 WHERE rd.flg_context = pk_review.get_past_history_ft_context
                   AND phft.id_doc_area IN (pk_past_history.g_doc_area_past_fam, pk_past_history.g_doc_area_past_soc)
                   AND rd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                          *
                                           FROM TABLE(i_epis) t)
                   AND phft.flg_status = pk_alert_constant.g_active
                   AND phft.id_pat_ph_ft_hist NOT IN
                       (SELECT pfh.id_pat_ph_ft_hist
                          FROM pat_past_hist_ft_hist pfh
                         WHERE pfh.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_epis) t)
                           AND pfh.id_doc_area IN
                               (pk_past_history.g_doc_area_past_fam, pk_past_history.g_doc_area_past_soc)
                           AND pfh.flg_status = pk_alert_constant.g_active)
                 ORDER BY id_doc_area, 4 DESC;
        ELSE
            OPEN o_past_history FOR
                SELECT pk_past_history.get_desc_past_hist_all(i_lang                   => i_lang,
                                                              i_prof                   => i_prof,
                                                              i_alert_diagnosis        => t.id_alert_diagnosis,
                                                              i_desc_pat_hist_diag     => t.desc_pat_history_diagnosis,
                                                              i_code_icd               => t.code_icd,
                                                              i_flg_other              => t.flg_other,
                                                              i_flg_icd9               => t.flg_icd9,
                                                              i_flg_status             => t.flg_status,
                                                              i_flg_compl              => t.flg_compl,
                                                              i_flg_nature             => NULL,
                                                              i_dt_diagnosed           => t.dt_diagnosed,
                                                              i_dt_diagnosed_precision => t.dt_diagnosed_precision,
                                                              i_doc_area               => i_doc_area,
                                                              i_family_relationship    => t.id_family_relationship) ||
                       nvl2(t.notes, ' ' || l_notes || ' ' || t.notes, '') desc_info,
                       t.id_episode,
                       pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', flg_status) rank,
                       1 flg_type,
                       t.dt_pat_history_diagnosis_tstz dt_register,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          t.id_episode,
                                                          t.dt_pat_history_diagnosis_tstz,
                                                          t.id_professional) signature
                  FROM (SELECT ad.id_alert_diagnosis,
                               phd.desc_pat_history_diagnosis,
                               d.code_icd,
                               d.flg_other,
                               ad.flg_icd9,
                               phd.flg_status,
                               phd.flg_compl,
                               phd.dt_diagnosed,
                               phd.dt_diagnosed_precision,
                               phd.notes,
                               phd.id_episode,
                               phd.dt_pat_history_diagnosis_tstz,
                               phd.id_family_relationship,
                               phd.flg_death_cause,
                               phd.familiar_age,
                               phd.id_professional
                          FROM pat_history_diagnosis phd, alert_diagnosis_type ad, diagnosis d
                         WHERE phd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_epis) t)
                           AND id_pat_history_diagnosis =
                               pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                    phd.id_alert_diagnosis,
                                                                    phd.desc_pat_history_diagnosis,
                                                                    i_pat,
                                                                    i_prof,
                                                                    pk_alert_constant.g_no,
                                                                    i_flg_type)
                           AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                           AND phd.id_diagnosis = d.id_diagnosis(+)
                           AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                                pk_alert_constant.g_diag_area_not_defined,
                                                pk_alert_constant.g_diag_area_surgical_hist)
                           AND phd.flg_type = i_flg_type
                           AND nvl(phd.flg_status, pk_past_history.g_active) != pk_past_history.g_pat_hist_diag_canceled
                        UNION
                        SELECT t1.id_alert_diagnosis,
                               t1.desc_pat_history_diagnosis,
                               t1.code_icd,
                               t1.flg_other,
                               t1.flg_icd9,
                               t1.flg_status,
                               t1.flg_compl,
                               t1.dt_diagnosed,
                               t1.dt_diagnosed_precision,
                               t1.notes,
                               t1.id_episode,
                               t1.dt_pat_history_diagnosis_tstz,
                               t1.id_family_relationship,
                               t1.flg_death_cause,
                               t1.familiar_age,
                               t1.id_professional
                          FROM (SELECT /*+ push_pred(d) */
                                 ad.id_alert_diagnosis,
                                 phd.desc_pat_history_diagnosis,
                                 d.code_icd,
                                 d.flg_other,
                                 ad.flg_icd9,
                                 phd.flg_status,
                                 phd.flg_compl,
                                 phd.dt_diagnosed,
                                 phd.dt_diagnosed_precision,
                                 phd.notes,
                                 phd.id_episode,
                                 phd.dt_pat_history_diagnosis_tstz,
                                 phd.id_pat_history_diagnosis,
                                 phd.id_family_relationship,
                                 phd.flg_death_cause,
                                 phd.familiar_age,
                                 phd.id_professional
                                  FROM pat_history_diagnosis phd, alert_diagnosis_type ad, diagnosis d
                                 WHERE phd.id_pat_history_diagnosis IN
                                       (SELECT /*+ opt_estimate(table t rows=1)*/
                                         *
                                          FROM TABLE(pk_past_history.get_past_hist_ids_review(i_lang        => i_lang,
                                                                                              i_prof        => i_prof,
                                                                                              i_episode     => i_epis,
                                                                                              i_flg_context => pk_review.get_past_history_context,
                                                                                              i_flg_area    => table_varchar(pk_alert_constant.g_diag_area_past_history,
                                                                                                                             pk_alert_constant.g_diag_area_not_defined,
                                                                                                                             pk_alert_constant.g_diag_area_surgical_hist),
                                                                                              i_doc_area    => i_doc_area)) t)
                                   AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                                   AND phd.id_diagnosis = d.id_diagnosis(+)
                                   AND phd.flg_area IN (pk_alert_constant.g_diag_area_past_history,
                                                        pk_alert_constant.g_diag_area_not_defined,
                                                        pk_alert_constant.g_diag_area_family_hist,
                                                        pk_alert_constant.g_diag_area_surgical_hist)
                                   AND phd.flg_type = i_flg_type
                                   AND nvl(phd.flg_status, pk_past_history.g_active) !=
                                       pk_past_history.g_pat_hist_diag_canceled
                                   AND rownum > 0) t1
                         WHERE ((t1.id_pat_history_diagnosis =
                               pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                      t1.id_alert_diagnosis,
                                                                      t1.desc_pat_history_diagnosis,
                                                                      i_pat,
                                                                      i_prof,
                                                                      pk_alert_constant.g_no,
                                                                      i_flg_type) AND
                               i_flg_type = pk_past_history.g_alert_diag_type_med) OR
                               i_flg_type <> pk_past_history.g_alert_diag_type_med)) t
                UNION
                SELECT pk_string_utils.clob_to_sqlvarchar2(phft.text) desc_info,
                       id_episode,
                       1000 rank,
                       2 flg_type,
                       phft.dt_register,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          id_episode,
                                                          phft.dt_register,
                                                          phft.id_professional) signature
                  FROM pat_past_hist_ft_hist phft
                 WHERE phft.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                            *
                                             FROM TABLE(i_epis) t)
                   AND phft.id_doc_area = i_doc_area
                   AND phft.flg_status = pk_alert_constant.g_active
                UNION
                SELECT pk_string_utils.clob_to_sqlvarchar2(phft.text) desc_info,
                       rd.id_episode,
                       1000 rank,
                       2 flg_type,
                       phft.dt_register,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          rd.id_episode,
                                                          phft.dt_register,
                                                          phft.id_professional) signature
                  FROM pat_past_hist_ft_hist phft
                  JOIN review_detail rd
                    ON phft.id_pat_ph_ft = rd.id_record_area
                 WHERE rd.flg_context = pk_review.get_past_history_ft_context
                   AND phft.id_doc_area = i_doc_area
                   AND rd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                          *
                                           FROM TABLE(i_epis) t)
                   AND phft.flg_status = pk_alert_constant.g_active
                   AND phft.id_pat_ph_ft_hist NOT IN
                       (SELECT pfh.id_pat_ph_ft_hist
                          FROM pat_past_hist_ft_hist pfh
                         WHERE pfh.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   *
                                                    FROM TABLE(i_epis) t)
                           AND pfh.id_doc_area = i_doc_area
                           AND pfh.flg_status = pk_alert_constant.g_active)
                 ORDER BY flg_type ASC, rank ASC, dt_register DESC;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EPIS_DEPARTMENT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_past_history);
            RETURN FALSE;
    END get_past_history_info;
    FUNCTION get_episode_reviewed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2 IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_record_area = i_epis_documentation
           AND rd.flg_context = pk_review.get_template_context
           AND rd.id_episode = i_episode
           AND rd.flg_auto = pk_alert_constant.g_no;
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_episode_reviewed;

    /* *******************************************************************************************
    *  Get current state of Past Medical history for viewer checklist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_med_past_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_count               NUMBER;
        l_status              VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes            table_number := table_number();
        k_flg_status_canceled VARCHAR2(0001 CHAR) := 'C';
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT DISTINCT id_episode
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx1 ROWS=1) */
                                           column_value
                                            FROM TABLE(l_episodes) tblx1)
                   AND phd.flg_status NOT IN (k_flg_status_canceled)
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.flg_area IN
                       (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)
                UNION
                SELECT DISTINCT phd.id_episode
                  FROM pat_history_diagnosis phd
                  JOIN review_detail ed
                    ON ed.id_record_area = phd.id_pat_history_diagnosis
                 WHERE ed.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx1 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx1)
                   AND phd.flg_status NOT IN (k_flg_status_canceled)
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.flg_area IN
                       (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)
                UNION
                SELECT DISTINCT pp.id_episode
                  FROM pat_past_hist_ft_hist pp
                 WHERE pp.flg_type = g_alert_diag_type_med
                   AND pp.flg_status != k_flg_status_canceled
                   AND pp.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx2 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx2)
                UNION
                SELECT DISTINCT pp.id_episode
                  FROM pat_past_hist_ft_hist pp
                  JOIN review_detail ed
                    ON ed.id_record_area = pp.id_pat_ph_ft_hist
                   AND ed.flg_context = pk_review.get_past_history_ft_context
                 WHERE pp.flg_type = g_alert_diag_type_med
                   AND pp.flg_status != k_flg_status_canceled
                   AND ed.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx2 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx2)) xx;
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_vwr_med_past_hist;
    --    
    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_family.get_group_relationships(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_relationship_type => g_family_hist_relationship,
                                                 o_relationship      => o_relationship,
                                                 o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_FAMILY_relationships',
                                              o_error);
            pk_types.open_my_cursor(o_relationship);
            RETURN FALSE;
    END get_family_relationships;

    FUNCTION get_death_cause
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        IF NOT pk_sysdomain.get_domains(i_lang        => i_lang,
                                        i_code_domain => g_phd_flg_death_cause,
                                        i_prof        => i_prof,
                                        o_domains     => o_domains,
                                        o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_death_cause',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_death_cause;

    FUNCTION tf_past_family_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) RETURN t_coll_past_family_cda
        PIPELINED IS
        l_error               t_error_out;
        l_id_patient          patient.id_patient%TYPE;
        l_id_episode          episode.id_episode%TYPE;
        l_id_visit            visit.id_visit%TYPE;
        l_rec_past_family_cda t_rec_past_family_cda;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'tf_past_family_cda';
    BEGIN
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_has_error := TRUE;
            g_error     := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            g_has_error := TRUE;
            RAISE g_exception;
        END IF;
    
        FOR l_rec_past_family_cda IN (SELECT i.code_icd,
                                             i.desc_illness,
                                             i.id_content,
                                             i.flg_status,
                                             i.desc_status,
                                             i.dt_illness_to_print,
                                             i.dt_illness,
                                             i.dt_illness_serial,
                                             i.id_terminology_version,
                                             i.notes,
                                             i.id_family_relationship,
                                             i.desc_family_relationship,
                                             i.family_relationship_content,
                                             i.flg_death_cause,
                                             i.desc_death_cause,
                                             i.familiar_age
                                        FROM (SELECT d.code_icd,
                                                     pk_past_history.get_desc_past_hist_all(i_lang,
                                                                                            i_prof,
                                                                                            phd.id_alert_diagnosis,
                                                                                            phd.desc_pat_history_diagnosis,
                                                                                            d.code_icd,
                                                                                            d.flg_other,
                                                                                            ad.flg_icd9,
                                                                                            phd.flg_status,
                                                                                            phd.flg_compl,
                                                                                            phd.flg_nature,
                                                                                            phd.dt_diagnosed,
                                                                                            phd.dt_diagnosed_precision,
                                                                                            g_doc_area_past_fam,
                                                                                            phd.id_family_relationship) desc_illness,
                                                     d.id_content,
                                                     decode(phd.flg_status,
                                                            pk_alert_constant.g_cancelled,
                                                            pk_alert_constant.g_cancelled,
                                                            nvl2(phd.id_pat_history_diagnosis_new,
                                                                 pk_alert_constant.g_outdated,
                                                                 g_active)) flg_status,
                                                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                             phd.flg_status,
                                                                             i_lang) desc_status,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 phd.dt_pat_history_diagnosis_tstz,
                                                                                 i_prof) dt_illness_serial,
                                                     pk_date_utils.date_char_tsz(i_lang,
                                                                                 phd.dt_pat_history_diagnosis_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software) dt_illness_to_print,
                                                     phd.dt_pat_history_diagnosis_tstz dt_illness,
                                                     d.id_terminology_version,
                                                     phd.notes,
                                                     phd.id_family_relationship,
                                                     pk_family.get_family_relationship_desc(i_lang,
                                                                                            phd.id_family_relationship) desc_family_relationship,
                                                     pk_family.get_family_relationship_id(i_lang,
                                                                                          phd.id_family_relationship) family_relationship_content,
                                                     
                                                     phd.flg_death_cause,
                                                     pk_sysdomain.get_domain(g_phd_flg_death_cause,
                                                                             phd.flg_death_cause,
                                                                             i_lang) desc_death_cause,
                                                     phd.familiar_age
                                                FROM pat_history_diagnosis phd
                                                LEFT JOIN alert_diagnosis ad
                                                  ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                                                LEFT JOIN diagnosis d
                                                  ON ad.id_diagnosis = d.id_diagnosis
                                               INNER JOIN (SELECT e.id_episode
                                                            FROM episode e
                                                           WHERE e.id_patient = l_id_patient
                                                             AND i_scope_type = pk_alert_constant.g_scope_type_patient) epi
                                                  ON phd.id_episode = epi.id_episode
                                               WHERE phd.flg_area = pk_alert_constant.g_diag_area_family_hist
                                                 AND nvl(phd.flg_status, pk_past_history.g_active) !=
                                                     pk_past_history.g_pat_hist_diag_canceled
                                                 AND id_pat_history_diagnosis =
                                                     pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                                          phd.id_alert_diagnosis,
                                                                                          phd.desc_pat_history_diagnosis,
                                                                                          l_id_patient,
                                                                                          i_prof,
                                                                                          pk_alert_constant.g_no,
                                                                                          phd.flg_type)) i)
        LOOP
            PIPE ROW(l_rec_past_family_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_past_family_cda;

    FUNCTION get_desc_past_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_alert_diagnosis    IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_pat_hist_diag IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_code_icd           IN diagnosis.code_icd%TYPE,
        i_flg_other          IN diagnosis.flg_other%TYPE,
        i_flg_icd9           IN alert_diagnosis_type.flg_icd9%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2 IS
    
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        l_ret             pk_translation.t_desc_translation;
        l_error           t_error_out;
        l_status_desc     sys_domain.desc_val%TYPE;
        l_task_type       task_type.id_task_type%TYPE;
    
        --l_phd_desc sys_message.desc_message%TYPE;
        l_description VARCHAR2(2000 CHAR);
    
    BEGIN
    
        IF i_doc_area IN (g_doc_area_past_med, g_doc_area_past_fam)
        THEN
            l_task_type := pk_alert_constant.g_task_medical_history;
        ELSIF i_doc_area = g_doc_area_past_surg
        THEN
            l_task_type := pk_alert_constant.g_task_surgical_history;
        
        ELSIF i_doc_area = g_doc_area_cong_anom
        THEN
            l_task_type := pk_alert_constant.g_task_congenital_anomalies;
        ELSE
            l_task_type := pk_alert_constant.g_task_problems;
        END IF;
    
        --Maidn Description of past history diagnosis iyem
        SELECT decode(i_alert_diagnosis,
                      g_diag_none,
                      pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_none, i_lang),
                      decode(i_alert_diagnosis,
                             g_diag_unknown,
                             pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_unknown, i_lang),
                             decode(i_alert_diagnosis,
                                    g_diag_non_remark,
                                    pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                            g_pat_hist_diag_non_remark,
                                                            i_lang),
                                    decode(i_desc_pat_hist_diag, NULL, '', i_desc_pat_hist_diag || ' - ') ||
                                    pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_alert_diagnosis => i_alert_diagnosis,
                                                               i_id_task_type       => l_task_type,
                                                               i_code               => i_code_icd,
                                                               i_flg_other          => i_flg_other,
                                                               i_flg_std_diag       => i_flg_icd9))))
          INTO l_description
          FROM dual;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SECTION_DESC',
                                              l_error);
            RETURN NULL;
    END get_desc_past_hist;
    --

    FUNCTION get_past_history_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_hist_diag IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        o_description   OUT VARCHAR2,
        o_status        OUT VARCHAR2,
        o_complications OUT VARCHAR2,
        o_nature        OUT VARCHAR2,
        o_dt_diagnosis  OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_ret   pk_translation.t_desc_translation;
        l_error t_error_out;
    
    BEGIN
    
        IF i_pat_hist_diag IS NOT NULL
        THEN
        
            SELECT get_desc_past_hist(i_lang,
                                      i_prof,
                                      phd.id_alert_diagnosis,
                                      phd.desc_pat_history_diagnosis,
                                      d.code_icd,
                                      d.flg_other,
                                      ad.flg_icd9,
                                      prv_conv_flg_type_to_doc_area(phd.flg_type)),
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang),
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_COMPL_DESC', phd.flg_compl, i_lang),
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', phd.flg_nature, i_lang),
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision)
              INTO o_description, o_status, o_complications, o_nature, o_dt_diagnosis
              FROM pat_history_diagnosis phd
              LEFT JOIN alert_diagnosis ad
                ON ad.id_alert_diagnosis = phd.id_alert_diagnosis
              LEFT JOIN diagnosis d
                ON d.id_diagnosis = ad.id_diagnosis
             WHERE phd.id_pat_history_diagnosis = i_pat_hist_diag;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HISTORY_DESC',
                                              l_error);
            RETURN FALSE;
    END get_past_history_desc;

    /* *******************************************************************************************
    *  Identify if patient history diagnosis is outdated because of a cancel 
    *             
    * @param    i_lang                Language ID
    * @param    i_enter_mode          Enter Mode (FT - Free Text, TP - Template, CP - Current Problem) 
    * @param    i_pat_hist_diagnosis  Patient History Diagnosis ID
    *
    * @return   Number   (1-True for outdated because of a cancel, 0-False for other)
    * 
    * @author    Alexander Camilo                 
    * @version   1                 
    * @since     27-fev-2018                         
    **********************************************************************************************/
    FUNCTION isphd_outbycancel
    (
        i_lang               IN language.id_language%TYPE,
        i_enter_mode         IN VARCHAR2,
        i_pat_hist_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN NUMBER IS
    
        l_son_diag   pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
        l_episode    pat_history_diagnosis.id_episode%TYPE;
        l_diagnosis  pat_history_diagnosis.id_diagnosis%TYPE;
        l_patient    pat_history_diagnosis.id_patient%TYPE;
        l_flg_status pat_history_diagnosis.flg_status%TYPE;
        --l_flg_type       pat_past_hist_ft_hist.flg_type%TYPE;
        l_doc_area       pat_past_hist_ft_hist.id_doc_area%TYPE;
        l_son_flg_status pat_history_diagnosis.flg_status%TYPE;
        l_count          NUMBER;
        l_error          t_error_out;
        TYPE r_status_qty IS RECORD(
            status   VARCHAR2(2),
            quantity NUMBER);
        TYPE t_status_qty IS TABLE OF r_status_qty INDEX BY BINARY_INTEGER;
        lr_status_qty r_status_qty;
        lt_status_qty t_status_qty;
        l_canceled    BOOLEAN := FALSE;
    
    BEGIN
        CASE i_enter_mode
            WHEN 'CP' THEN
                g_error := 'IsPHD_OutByCancel.Get PHD detail';
                -- Check if there is son
                SELECT phd.id_pat_history_diagnosis_new,
                       phd.id_episode,
                       phd.id_diagnosis,
                       phd.id_patient,
                       phd.flg_status
                  INTO l_son_diag, l_episode, l_diagnosis, l_patient, l_flg_status
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_pat_history_diagnosis = i_pat_hist_diagnosis;
            
                -- If no, return false
                IF l_son_diag IS NULL
                THEN
                    RETURN 0;
                ELSE
                    g_error := 'IsPHD_OutByCancel.Count PHD of relatives';
                    -- If yes, count the relatives
                    SELECT COUNT(1)
                      INTO l_count
                      FROM pat_history_diagnosis phd
                     WHERE phd.id_episode = l_episode
                       AND phd.id_patient = l_patient
                       AND phd.id_diagnosis = l_diagnosis;
                    IF l_count > 2
                    THEN
                        -- If There are many diags it means was changed, return false
                        RETURN 0;
                    ELSE
                        -- Get the son info, if canceled return true
                        g_error := 'IsPHD_OutByCancel.Get son`s PHD Status';
                        IF l_flg_status = 'A'
                        THEN
                        
                            SELECT phd_son.flg_status
                              INTO l_son_flg_status
                              FROM pat_history_diagnosis phd_son
                             WHERE phd_son.id_pat_history_diagnosis = l_son_diag;
                        
                            IF l_son_flg_status = 'C'
                            THEN
                                RETURN 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            
            WHEN 'FT' THEN
                l_count := 0;
            
                g_error := 'IsPHD_OutByCancel.FreeText.Get data';
                SELECT id_patient, id_episode, flg_status, id_doc_area
                  INTO l_patient, l_episode, l_flg_status, l_doc_area
                  FROM pat_past_hist_ft_hist pp
                 WHERE pp.id_pat_ph_ft_hist = i_pat_hist_diagnosis;
            
                g_error := 'IsPHD_OutByCancel.FreeText.Count';
                --Collect data
                SELECT ph.flg_status, COUNT(1) qty
                  BULK COLLECT
                  INTO lt_status_qty
                  FROM pat_past_hist_free_text pp, pat_past_hist_ft_hist ph
                 WHERE ph.id_pat_ph_ft = pp.id_pat_ph_ft
                   AND ph.id_patient = l_patient
                   AND ph.id_episode = l_episode
                   AND ph.id_doc_area = l_doc_area
                 GROUP BY ph.flg_status;
            
                --Check the total of record and if there is a canceled
                FOR i IN lt_status_qty.first .. lt_status_qty.last
                LOOP
                    lr_status_qty := lt_status_qty(i);
                    l_count       := l_count + lr_status_qty.quantity;
                    IF lr_status_qty.status = 'C'
                    THEN
                        l_canceled := TRUE;
                    END IF;
                END LOOP;
            
                IF l_count = 2
                THEN
                    --Check if there is a canceled line
                    IF l_canceled
                       AND l_flg_status != 'C'
                    THEN
                        RETURN 1;
                    END IF;
                END IF;
            
            ELSE
                RETURN 0;
            
        END CASE enter_mode;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLCODE || ' . ' || SQLERRM);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'isphd_outbycancel',
                                              l_error);
            RETURN 0;
    END isphd_outbycancel;

    FUNCTION check_dup_icd_ph
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count             NUMBER := 0;
        l_count_aux         NUMBER := 0;
        l_allow_ph_same_icd sys_config.value%TYPE := pk_sysconfig.get_config('ALLOW_PH_SAME_ICD', i_prof);
        l_flg_type          pat_history_diagnosis.flg_type%TYPE;
        l_task_type         task_type.id_task_type%TYPE;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
        o_msg      := NULL;
    
        l_flg_type := CASE i_doc_area
                          WHEN g_doc_area_past_med THEN
                           g_alert_diag_type_med
                          WHEN g_doc_area_past_surg THEN
                           g_alert_diag_type_surg
                          WHEN g_doc_area_treatments THEN
                           g_alert_type_treatments
                          WHEN g_doc_area_past_fam THEN
                           g_alert_diag_type_family
                          WHEN g_doc_area_cong_anom THEN
                           g_alert_diag_type_cong_anom
                          ELSE
                           NULL
                      END;
    
        l_task_type := CASE i_doc_area
                           WHEN g_doc_area_cong_anom THEN
                            pk_alert_constant.g_task_congenital_anomalies
                           WHEN g_doc_area_past_surg THEN
                            pk_alert_constant.g_task_surgical_history
                           WHEN g_doc_area_treatments THEN
                            pk_alert_constant.g_task_procedure
                           WHEN g_doc_area_past_med THEN
                            pk_alert_constant.g_task_medical_history
                           ELSE
                            NULL
                       END;
    
        IF l_flg_type IS NOT NULL
           AND l_task_type IS NOT NULL
           AND i_id_diagnosis_list.exists(1)
        THEN
            FOR i IN i_id_diagnosis_list.first .. i_id_diagnosis_list.last
            LOOP
                SELECT COUNT(*)
                  INTO l_count_aux
                  FROM (SELECT phd.id_diagnosis, phd.id_alert_diagnosis, phd.flg_status
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_episode = i_episode
                           AND phd.id_diagnosis = i_id_diagnosis_list(i)
                           AND phd.id_alert_diagnosis <> i_id_alert_diag_list(i)
                           AND phd.flg_type = l_flg_type
                           AND (phd.flg_status != pk_diagnosis.g_ed_flg_status_ca OR phd.flg_status IS NULL)
                           AND phd.id_pat_history_diagnosis_new IS NULL
                           AND ((l_allow_ph_same_icd = pk_alert_constant.g_no OR
                               nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                                    i_id_concept_term    => phd.id_alert_diagnosis,
                                                                    i_id_concept_version => phd.id_diagnosis,
                                                                    i_id_task_type       => l_task_type,
                                                                    i_id_institution     => i_prof.institution,
                                                                    i_id_software        => i_prof.software),
                                     pk_alert_constant.g_yes) = pk_alert_constant.g_no))
                           AND (SELECT COUNT(1)
                                  FROM pat_history_diagnosis phd
                                 WHERE phd.id_episode = i_episode
                                   AND phd.id_diagnosis = i_id_diagnosis_list(i)
                                   AND phd.id_alert_diagnosis = i_id_alert_diag_list(i)
                                   AND phd.flg_type = l_flg_type
                                   AND (phd.flg_status != pk_diagnosis.g_ed_flg_status_ca OR phd.flg_status IS NULL)
                                   AND phd.id_pat_history_diagnosis_new IS NULL) = 0);
                l_count := l_count + l_count_aux;
            END LOOP;
        END IF;
    
        IF l_count > 0
        THEN
            o_flg_show := 'YW';
            o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M121');
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PAST_HISTORY',
                                              'CHECK_DUP_ICD_PH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_dup_icd_ph;

    /* *******************************************************************************************
    *  Get current state of Past Surgical history for viewer checklist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author      Elisabete Bugalho               
    * @version       2.8.4.0             
    * @since        20/01/2022                      
    **********************************************************************************************/
    FUNCTION get_vwr_sug_past_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_count               NUMBER;
        l_status              VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes            table_number := table_number();
        k_flg_status_canceled VARCHAR2(0001 CHAR) := 'C';
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT DISTINCT id_episode
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx1 ROWS=1) */
                                           column_value
                                            FROM TABLE(l_episodes) tblx1)
                   AND nvl(phd.flg_status, g_active) NOT IN (k_flg_status_canceled)
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.flg_type = g_alert_diag_type_surg
                /*   AND phd.flg_area IN
                (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)*/
                UNION
                SELECT DISTINCT phd.id_episode
                  FROM pat_history_diagnosis phd
                  JOIN review_detail ed
                    ON ed.id_record_area = phd.id_pat_history_diagnosis
                 WHERE ed.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx1 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx1)
                   AND nvl(phd.flg_status, g_active) NOT IN (k_flg_status_canceled)
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.flg_type = g_alert_diag_type_surg
                /* AND phd.flg_area IN
                (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)*/
                UNION
                SELECT DISTINCT pp.id_episode
                  FROM pat_past_hist_ft_hist pp
                 WHERE pp.flg_type = g_alert_diag_type_surg
                   AND pp.flg_status != k_flg_status_canceled
                   AND pp.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx2 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx2)
                UNION
                SELECT DISTINCT pp.id_episode
                  FROM pat_past_hist_ft_hist pp
                  JOIN review_detail ed
                    ON ed.id_record_area = pp.id_pat_ph_ft_hist
                   AND ed.flg_context = pk_review.get_past_history_ft_context
                 WHERE pp.flg_type = g_alert_diag_type_surg
                   AND pp.flg_status != k_flg_status_canceled
                   AND ed.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tblx2 ROWS=1) */
                                          column_value
                                           FROM TABLE(l_episodes) tblx2)) xx;
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_vwr_sug_past_hist;

    FUNCTION tf_epis_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       profissional,
        i_id_patient episode.id_patient%TYPE,
        i_id_episode episode.id_episode%TYPE DEFAULT NULL,
        i_start_date episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_end_date   episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN t_tbl_epis_diagnosis IS
    
        l_out_rec        t_tbl_epis_diagnosis := t_tbl_epis_diagnosis(NULL);
        l_sql_header     VARCHAR2(32767);
        l_sql_inner      VARCHAR2(32767);
        l_sql_footer     VARCHAR2(32767);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_EPIS_DIAGNOSIS';
    BEGIN
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_header := 'SELECT t_epis_diagnosis(id_episode, id_alert_diagnosis,id_diagnosis,id_epis_diagnosis,dt_confirmed_tstz,dt_epis_diagnosis_tstz,
id_prof_confirmed,id_professional_diag,desc_epis_diagnosis,flg_status)
FROM (SELECT e.id_episode, ed.id_alert_diagnosis, ed.id_diagnosis,ed.id_epis_diagnosis,ed.dt_confirmed_tstz,ed.dt_epis_diagnosis_tstz,
ed.id_prof_confirmed,ed.id_professional_diag,ed.desc_epis_diagnosis,ed.flg_status
FROM epis_diagnosis ed
JOIN episode e
ON e.id_episode = ed.id_episode
WHERE 1 = 1';
    
        IF i_id_patient IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND e.id_patient = :i_id_patient';
        END IF;
    
        IF i_id_episode IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND ed.id_episode != :i_id_episode';
        
        END IF;
    
        IF i_start_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND ed.dt_epis_diagnosis_tstz >= CAST(:i_start_date AS TIMESTAMP WITH LOCAL TIME ZONE)';
        END IF;
    
        IF i_end_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND ed.dt_epis_diagnosis_tstz <= CAST(:i_end_date AS TIMESTAMP WITH LOCAL TIME ZONE)';
        END IF;
    
        l_sql_footer := l_sql_footer || ' AND ed.flg_type = :g_flg_type_disch';
    
        l_sql_footer := l_sql_footer || ' AND ed.flg_status in (:g_ed_flg_status_co,:g_ed_flg_status_d)';
    
        l_sql_footer := l_sql_footer || ' )';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
    
        pk_alertlog.log_debug(owner           => g_package_owner,
                              object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        --dbms_output.put_line(dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'g_flg_type_disch', pk_diagnosis.g_flg_type_disch);
        dbms_sql.bind_variable(l_curid, 'g_ed_flg_status_co', pk_diagnosis.g_ed_flg_status_co);
        dbms_sql.bind_variable(l_curid, 'g_ed_flg_status_d', pk_diagnosis.g_ed_flg_status_d);
    
        IF i_id_patient IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_patient', i_id_patient);
        END IF;
    
        IF i_id_episode IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_episode', i_id_episode);
        END IF;
    
        IF i_start_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
        END IF;
    
        IF i_end_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_epis_diagnosis;

    FUNCTION tf_pat_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       profissional,
        i_id_patient episode.id_patient%TYPE,
        i_start_date episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_end_date   episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN t_tbl_pat_episode IS
    
        l_out_rec        t_tbl_pat_episode := t_tbl_pat_episode(NULL);
        l_sql_header     VARCHAR2(32767);
        l_sql_inner      VARCHAR2(32767);
        l_sql_footer     VARCHAR2(32767);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_PAT_EPISODE';
    BEGIN
    
        l_curid := dbms_sql.open_cursor;
    
        l_sql_header := 'SELECT t_pat_episode(id_episode, dt_begin_tstz)
FROM (SELECT e.id_episode, e.dt_begin_tstz
FROM episode e
WHERE 1 = 1';
    
        IF i_id_patient IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND e.id_patient = :i_id_patient';
        END IF;
    
        IF i_start_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND e.dt_begin_tstz >= CAST(:i_start_date AS TIMESTAMP WITH LOCAL TIME ZONE)';
        END IF;
    
        IF i_end_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND e.dt_begin_tstz <= CAST(:i_end_date AS TIMESTAMP WITH LOCAL TIME ZONE)';
        END IF;
    
        l_sql_footer := l_sql_footer || ' )';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
    
        pk_alertlog.log_debug(owner           => g_package_owner,
                              object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        --dbms_output.put_line(dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_id_patient IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_patient', i_id_patient);
        END IF;
    
        IF i_start_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
        END IF;
    
        IF i_end_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    
    END tf_pat_episode;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_past_history;
/
