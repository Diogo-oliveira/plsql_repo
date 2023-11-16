/*-- Last Change Revision: $Rev: 2027071 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_vs_patient IS

    --
    -- PRIVATE SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    --
    -- PRIVATE CONSTANTS
    -- 

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    --
    -- PRIVATE FUNCTIONS
    -- 

    /**********************************************************************************************
    * Get row from easy_access table take into consideration composed primary key values
    *
    * @param        i_patient                Patient id
    * @param        i_vital_sign             Vital sign id
    * @value        i_unit_measure           Unit measure id
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.5.1
    * @since        27-Jul-2010
    **********************************************************************************************/
    FUNCTION get_vpea_row
    (
        i_patient      vs_patient_ea.id_patient%TYPE,
        i_vital_sign   vs_patient_ea.id_vital_sign%TYPE,
        i_unit_measure vs_patient_ea.id_unit_measure%TYPE
    ) RETURN vs_patient_ea%ROWTYPE IS
        c_function_name CONSTANT obj_name := 'GET_VPEA_ROW';
        l_dbg_msg debug_msg;
    
        l_vpea_row vs_patient_ea%ROWTYPE;
    
    BEGIN
        IF i_patient IS NULL
           OR i_vital_sign IS NULL
        THEN
            RETURN l_vpea_row;
        END IF;
    
        l_dbg_msg := 'get vs_patient_ea record';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT vsp.*
              INTO l_vpea_row
              FROM vs_patient_ea vsp
             WHERE vsp.id_patient = i_patient
               AND vsp.id_vital_sign = i_vital_sign
               AND ((vsp.id_unit_measure = i_unit_measure) OR (vsp.id_unit_measure IS NULL AND i_unit_measure IS NULL));
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_vpea_row;
    
    END get_vpea_row;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        i_visit                  Visit id
    * @value        i_schedule               Schedule id (not used)
    * @param        i_external_request       External request id (not used)
    * @param        i_institution            Institution id (not used)
    * @param        i_start_dt               Date from which start processing records
    * @param        i_end_dt                 Date by which to end processing records
    * @param        i_validate_table         If it is necessary to validate the data
    * @param        i_output_invalid_records If it is necessary to save invalid records
    * @param        i_recreate_table         If it is necessary to recreate the entire EA table
    * @param        i_commit_step            Number of records to process between commits
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.5.1
    * @since        27-Jul-2010
    **********************************************************************************************/
    FUNCTION admin
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN vital_sign_read.id_patient%TYPE,
        i_commit_step IN PLS_INTEGER DEFAULT c_def_commit_steps,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'ADMIN';
        l_dbg_msg debug_msg;
    
        l_cont PLS_INTEGER;
    
        CURSOR vsr_p_cur(i_pat IN vital_sign_read.id_patient%TYPE) IS
            SELECT DISTINCT vsr.id_patient,
                            nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) AS id_vital_sign,
                            pk_vital_sign.get_vsr_inst_um(vsr.id_institution_read,
                                                          vsr.id_vital_sign,
                                                          vsr.id_unit_measure,
                                                          vsr.id_vs_scales_element,
                                                          vsr.id_software_read) AS id_unit_measure,
                            pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element) AS vs_scale
              FROM vital_sign_read vsr
              LEFT OUTER JOIN vital_sign_relation vrel
                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
               AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
             WHERE (i_pat IS NULL OR i_pat = vsr.id_patient)
               AND vsr.flg_state = pk_alert_constant.g_active
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
             ORDER BY vsr.id_patient, nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign), id_unit_measure;
    
        l_vs_pat_ea vs_patient_ea%ROWTYPE;
    
    BEGIN
        DELETE vs_patient_ea vpea
         WHERE i_patient IS NULL
            OR i_patient = vpea.id_patient;
    
        COMMIT;
    
        l_cont := 0;
        FOR vc IN vsr_p_cur(i_pat => i_patient)
        LOOP
            l_cont := l_cont + 1;
        
            l_vs_pat_ea.id_patient      := vc.id_patient;
            l_vs_pat_ea.id_vital_sign   := vc.id_vital_sign;
            l_vs_pat_ea.id_unit_measure := nvl(vc.id_unit_measure, pk_vital_sign.c_without_um);
            l_vs_pat_ea.n_records       := pk_vital_sign_pbl.get_vs_n_records(i_vital_sign => vc.id_vital_sign,
                                                                              i_patient    => vc.id_patient);
        
            l_vs_pat_ea.id_first_vsr := pk_vital_sign.get_fst_vsr(i_vital_sign   => vc.id_vital_sign,
                                                                  i_unit_measure => vc.id_unit_measure,
                                                                  i_patient      => vc.id_patient);
        
            pk_vital_sign.get_min_max_vsr(i_vital_sign   => vc.id_vital_sign,
                                          i_unit_measure => vc.id_unit_measure,
                                          i_patient      => vc.id_patient,
                                          o_min_vsr      => l_vs_pat_ea.id_min_vsr,
                                          o_max_vsr      => l_vs_pat_ea.id_max_vsr);
        
            pk_vital_sign.get_lst_vsr(i_vital_sign   => vc.id_vital_sign,
                                      i_unit_measure => vc.id_unit_measure,
                                      i_patient      => vc.id_patient,
                                      o_lst3_vsr     => l_vs_pat_ea.id_last_3_vsr,
                                      o_lst2_vsr     => l_vs_pat_ea.id_last_2_vsr,
                                      o_lst1_vsr     => l_vs_pat_ea.id_last_1_vsr);
        
            l_dbg_msg := 'insert a new record in vs_patient_ea';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            ts_vs_patient_ea.ins(rec_in => l_vs_pat_ea);
        
            IF l_cont = i_commit_step
            THEN
                COMMIT;
                l_cont := 0;
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END admin;

    /**********************************************************************************************
    * Updates Vital Signs by Patient Easy Access table
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_event_type             Event type (UPDATE, INSERT or DELETE)
    * @param        i_rowids                 List of changed records ROWIDs
    * @param        i_list_columns           List of changed columns 
    * @param        i_source_table_name      Changed table name
    * @param        i_dg_table_name          Data Governance table name
    *
    * @author       Paulo Fonseca
    * @version      2.5.1
    * @since        26-Jul-2010
    **********************************************************************************************/
    PROCEDURE process_event
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        c_proc_name CONSTANT obj_name := 'PROCESS_EVENT';
        l_dbg_msg debug_msg;
        l_update_event_excp EXCEPTION;
        l_delete_event_excp EXCEPTION;
    
        c_expected_table_name    CONSTANT obj_name := 'VITAL_SIGN_READ';
        c_expected_dg_table_name CONSTANT obj_name := 'VS_PATIENT_EA';
    
        l_affected_records ts_vital_sign_read.vital_sign_read_tc;
        n_records          PLS_INTEGER;
    
        l_vs_pat_ea vs_patient_ea%ROWTYPE;
    
        l_def_um  unit_measure.id_unit_measure%TYPE;
        l_new_vs  vital_sign_read.id_vital_sign%TYPE;
        l_new_val vital_sign_read.value%TYPE;
        l_new_um  unit_measure.id_unit_measure%TYPE;
    
        l_vs_parent           vital_sign_relation.id_vital_sign_parent%TYPE;
        l_relation_domain     vital_sign_relation.relation_domain%TYPE;
        l_vs_pat_ea_old       vs_visit_ea%ROWTYPE;
        l_composed_vs         VARCHAR2(1char);
        l_id_vital_sign       vital_sign_read.id_vital_sign%TYPE;
        l_id_unit_measure     unit_measure.id_unit_measure%TYPE;
        l_pat_old             vs_patient_ea.id_patient%TYPE;
        l_id_vital_sign_old   vital_sign_read.id_vital_sign%TYPE;
        l_id_unit_measure_old unit_measure.id_unit_measure%TYPE;
    
    BEGIN
        l_dbg_msg := 'validate arguments';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => c_expected_table_name,
                                                 i_expected_dg_table_name => c_expected_dg_table_name,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        
        END IF;
    
        l_dbg_msg := 'get affected records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
        l_affected_records := ts_vital_sign_read.get_data_rowid(rows_in => i_rowids);
    
        n_records := l_affected_records.count();
        IF n_records = 0
        THEN
            l_dbg_msg := 'return - zero affected records';
            pk_alertlog.log_warn(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
            RETURN;
        
        END IF;
    
        CASE i_event_type
        
            WHEN t_data_gov_mnt.g_event_insert THEN
                l_dbg_msg := 'process insert event';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
            
                FOR idx IN 1 .. n_records
                LOOP
                    -- only inserts active records in vs_patient_ea and not belonging to a fetus
                    IF l_affected_records(idx)
                     .flg_state = pk_alert_constant.g_active
                        AND
                        pk_delivery.check_vs_read_from_fetus(i_vs_read => l_affected_records(idx).id_vital_sign_read) = 0
                    THEN
                        l_dbg_msg := 'CALL pk_vital_sign.get_vs_parent id_vital_sign: ' || l_affected_records(idx)
                                    .id_vital_sign;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        l_vs_parent := pk_vital_sign.get_vs_parent(i_vital_sign => l_affected_records(idx).id_vital_sign);
                    
                        l_dbg_msg := 'CALL pk_vital_sign.get_vs_relation_domain l_vs_parent: ' || l_vs_parent;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        l_relation_domain := pk_vital_sign.get_vs_relation_domain(i_vital_sign => l_vs_parent);
                    
                        l_new_vs  := l_affected_records(idx).id_vital_sign;
                        l_new_val := NULL;
                        l_new_um  := pk_vital_sign.c_without_um;
                    
                        CASE
                            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_sum THEN
                                -- glasgow coma scale
                                l_new_vs  := l_vs_parent;
                                l_dbg_msg := 'CALL  pk_vital_sign.get_glasgowtotal_value i_vital_sign: ' || l_new_vs;
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_new_val := pk_vital_sign.get_glasgowtotal_value(i_vital_sign         => l_new_vs,
                                                                                  i_patient            => l_affected_records(idx)
                                                                                                          .id_patient,
                                                                                  i_episode            => l_affected_records(idx)
                                                                                                          .id_episode,
                                                                                  i_dt_vital_sign_read => l_affected_records(idx)
                                                                                                          .dt_vital_sign_read_tstz);
                                l_new_um  := pk_vital_sign.c_without_um;
                            
                            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_conc THEN
                                -- blood pressures
                                l_dbg_msg := 'blood pressures';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_new_vs  := l_vs_parent;
                                l_new_val := NULL;
                                l_new_um  := l_affected_records(idx).id_unit_measure;
                            
                            WHEN l_affected_records(idx).id_vs_scales_element IS NOT NULL THEN
                                -- vital signs scales
                                l_dbg_msg := 'get vital sign scale value';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_new_val := pk_vital_sign.get_vsse_value(i_vs_scales_element => l_affected_records(idx)
                                                                                                 .id_vs_scales_element);
                                l_new_um  := pk_vital_sign.get_vsse_um(i_vs_scales_element => l_affected_records(idx)
                                                                                              .id_vs_scales_element,
                                                                       i_without_um_no_id  => pk_alert_constant.g_no);
                            
                            WHEN l_affected_records(idx).id_vital_sign_desc IS NOT NULL THEN
                                -- multichoices
                                l_dbg_msg := 'get vital sign multichoice value';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_new_val := pk_vital_sign.get_vsd_order_val(i_vital_sign_desc => l_affected_records(idx)
                                                                                                  .id_vital_sign_desc);
                                l_new_um  := pk_vital_sign.c_without_um;
                            
                            ELSE
                                -- numeric vital signs
                                l_dbg_msg := 'get vital sign unit measure for this institution';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_def_um := pk_vital_sign.get_vs_um_inst(i_vital_sign  => l_affected_records(idx)
                                                                                          .id_vital_sign,
                                                                         i_institution => i_prof.institution,
                                                                         i_software    => i_prof.software);
                            
                                l_affected_records(idx).id_unit_measure := nvl(n1 => l_affected_records(idx)
                                                                                     .id_unit_measure,
                                                                               n2 => pk_vital_sign.c_without_um);
                            
                                l_dbg_msg := 'check is the current unit measure is convertible';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                IF pk_unit_measure.are_convertible(i_unit_meas     => l_affected_records(idx)
                                                                                      .id_unit_measure,
                                                                   i_unit_meas_def => l_def_um)
                                THEN
                                    l_dbg_msg := 'convert the vital sign value to the institution unit measure';
                                    pk_alertlog.log_info(text            => l_dbg_msg,
                                                         object_name     => c_package_name,
                                                         sub_object_name => c_proc_name);
                                    l_new_val := pk_unit_measure.get_unit_mea_conversion(i_value         => l_affected_records(idx)
                                                                                                            .value,
                                                                                         i_unit_meas     => l_affected_records(idx)
                                                                                                            .id_unit_measure,
                                                                                         i_unit_meas_def => l_def_um);
                                    l_new_um  := l_def_um;
                                
                                ELSE
                                    l_new_val := l_affected_records(idx).value;
                                    l_new_um  := l_affected_records(idx).id_unit_measure;
                                
                                END IF;
                            
                        END CASE;
                    
                        l_dbg_msg := 'get vs_patient_ea row for this vital sign/unit measure';
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        l_vs_pat_ea := get_vpea_row(i_patient      => l_affected_records(idx).id_patient,
                                                    i_vital_sign   => l_new_vs,
                                                    i_unit_measure => nvl(l_new_um, pk_vital_sign.c_without_um));
                    
                        IF l_vs_pat_ea.id_patient IS NULL
                        THEN
                            -- insert new vs in ea
                            l_vs_pat_ea.id_patient      := l_affected_records(idx).id_patient;
                            l_vs_pat_ea.id_vital_sign   := l_new_vs;
                            l_vs_pat_ea.id_unit_measure := nvl(l_new_um, pk_vital_sign.c_without_um);
                            l_vs_pat_ea.n_records       := 1;
                            l_vs_pat_ea.id_first_vsr    := l_affected_records(idx).id_vital_sign_read;
                            IF l_new_val IS NOT NULL
                            THEN
                                l_vs_pat_ea.id_min_vsr := l_affected_records(idx).id_vital_sign_read;
                                l_vs_pat_ea.id_max_vsr := l_affected_records(idx).id_vital_sign_read;
                            END IF;
                            l_vs_pat_ea.id_last_1_vsr := l_affected_records(idx).id_vital_sign_read;
                        
                            l_dbg_msg := 'insert a new record in vs_patient_ea';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            ts_vs_patient_ea.ins(rec_in => l_vs_pat_ea);
                        
                        ELSE
                            -- update vs value in ea
                            l_dbg_msg := 'check if the current record is the oldest';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            IF NOT pk_vital_sign.has_same_date(i_vital_sign_read => l_vs_pat_ea.id_first_vsr,
                                                               i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                               i_new_dt_read     => l_affected_records(idx)
                                                                                    .dt_vital_sign_read_tstz)
                            THEN
                                IF NOT pk_vital_sign.is_older(i_vital_sign_read => l_vs_pat_ea.id_first_vsr,
                                                              i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                              i_new_dt_read     => l_affected_records(idx)
                                                                                   .dt_vital_sign_read_tstz)
                                THEN
                                    l_vs_pat_ea.id_first_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                END IF;
                            
                            END IF;
                        
                            IF l_new_val IS NOT NULL
                            THEN
                                l_dbg_msg := 'check if the current value is the minimum value';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                IF pk_vital_sign.is_lower(i_vital_sign_read => l_vs_pat_ea.id_min_vsr,
                                                          i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                          i_new_value       => l_new_val,
                                                          i_new_dt_read     => l_affected_records(idx)
                                                                               .dt_vital_sign_read_tstz)
                                THEN
                                    l_vs_pat_ea.id_min_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                END IF;
                            
                                l_dbg_msg := 'check if the current value is the maximum value';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                IF pk_vital_sign.is_greater(i_vital_sign_read => l_vs_pat_ea.id_max_vsr,
                                                            i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                            i_new_value       => l_new_val,
                                                            i_new_dt_read     => l_affected_records(idx)
                                                                                 .dt_vital_sign_read_tstz)
                                THEN
                                    l_vs_pat_ea.id_max_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                END IF;
                            
                            END IF;
                        
                            l_dbg_msg := 'check if the current record is one of the most recent';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            IF NOT pk_vital_sign.has_same_date(i_vital_sign_read => l_vs_pat_ea.id_last_1_vsr,
                                                               i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                               i_new_dt_read     => l_affected_records(idx)
                                                                                    .dt_vital_sign_read_tstz)
                               AND NOT pk_vital_sign.has_same_date(i_vital_sign_read => l_vs_pat_ea.id_last_2_vsr,
                                                                   i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                                   i_new_dt_read     => l_affected_records(idx)
                                                                                        .dt_vital_sign_read_tstz)
                               AND NOT pk_vital_sign.has_same_date(i_vital_sign_read => l_vs_pat_ea.id_last_3_vsr,
                                                                   i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                                   i_new_dt_read     => l_affected_records(idx)
                                                                                        .dt_vital_sign_read_tstz)
                            THEN
                                IF pk_vital_sign.is_older(i_vital_sign_read => l_vs_pat_ea.id_last_1_vsr,
                                                          i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                          i_new_dt_read     => l_affected_records(idx)
                                                                               .dt_vital_sign_read_tstz)
                                THEN
                                    -- ultimate
                                    l_vs_pat_ea.id_last_3_vsr := l_vs_pat_ea.id_last_2_vsr;
                                    l_vs_pat_ea.id_last_2_vsr := l_vs_pat_ea.id_last_1_vsr;
                                    l_vs_pat_ea.id_last_1_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                ELSIF pk_vital_sign.is_older(i_vital_sign_read => l_vs_pat_ea.id_last_2_vsr,
                                                             i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                             i_new_dt_read     => l_affected_records(idx)
                                                                                  .dt_vital_sign_read_tstz)
                                      OR l_vs_pat_ea.id_last_2_vsr IS NULL
                                THEN
                                    -- penultimate
                                    l_vs_pat_ea.id_last_3_vsr := l_vs_pat_ea.id_last_2_vsr;
                                    l_vs_pat_ea.id_last_2_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                ELSIF pk_vital_sign.is_older(i_vital_sign_read => l_vs_pat_ea.id_last_3_vsr,
                                                             i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                             i_new_dt_read     => l_affected_records(idx)
                                                                                  .dt_vital_sign_read_tstz)
                                      OR l_vs_pat_ea.id_last_3_vsr IS NULL
                                THEN
                                    -- antepenultimate
                                    l_vs_pat_ea.id_last_3_vsr := l_affected_records(idx).id_vital_sign_read;
                                
                                END IF;
                            END IF;
                        
                            -- increment the number of records
                            l_vs_pat_ea.n_records := pk_vital_sign_pbl.get_vs_n_records(i_vital_sign => l_vs_pat_ea.id_vital_sign,
                                                                                        i_patient    => l_vs_pat_ea.id_patient);
                        
                            l_dbg_msg := 'update the existing record in vs_patient_ea';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            ts_vs_patient_ea.upd(rec_in => l_vs_pat_ea);
                        
                        END IF;
                    
                    END IF;
                
                END LOOP;
            
            WHEN t_data_gov_mnt.g_event_update THEN
                l_dbg_msg := 'process update event';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
            
                FOR idx IN 1 .. n_records
                LOOP
                    IF pk_delivery.check_vs_read_from_fetus(i_vs_read => l_affected_records(idx).id_vital_sign_read) = 0
                    THEN
                        l_vs_parent       := pk_vital_sign.get_vs_parent(i_vital_sign => l_affected_records(idx)
                                                                                         .id_vital_sign);
                        l_relation_domain := pk_vital_sign.get_vs_relation_domain(i_vital_sign => l_vs_parent);
                        l_new_vs          := l_affected_records(idx).id_vital_sign;
                        l_new_um          := pk_vital_sign.c_without_um;
                        l_composed_vs     := pk_alert_constant.g_no;
                    
                        CASE
                            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_sum THEN
                                -- glasgow coma scale
                                l_new_vs      := l_vs_parent;
                                l_new_um      := pk_vital_sign.c_without_um;
                                l_composed_vs := pk_alert_constant.g_yes;
                            
                            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_conc THEN
                                -- blood pressures
                                l_new_vs      := l_vs_parent;
                                l_new_um      := l_affected_records(idx).id_unit_measure;
                                l_composed_vs := pk_alert_constant.g_yes;
                            
                            WHEN l_affected_records(idx).id_vs_scales_element IS NOT NULL THEN
                                -- vital signs scales
                                l_new_um := pk_vital_sign.get_vsse_um(i_vs_scales_element => l_affected_records(idx)
                                                                                             .id_vs_scales_element,
                                                                      i_without_um_no_id  => pk_alert_constant.g_no);
                            
                            WHEN l_affected_records(idx).id_vital_sign_desc IS NOT NULL THEN
                                -- multichoices
                                l_new_um := pk_vital_sign.c_without_um;
                            
                            ELSE
                                -- numeric vital signs
                                l_dbg_msg := 'get vital sign unit measure for this institution';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                l_def_um := pk_vital_sign.get_vs_um_inst(i_vital_sign  => l_affected_records(idx)
                                                                                          .id_vital_sign,
                                                                         i_institution => i_prof.institution,
                                                                         i_software    => i_prof.software);
                            
                                l_affected_records(idx).id_unit_measure := nvl(n1 => l_affected_records(idx)
                                                                                     .id_unit_measure,
                                                                               n2 => pk_vital_sign.c_without_um);
                            
                                IF pk_unit_measure.are_convertible(i_unit_meas     => l_affected_records(idx)
                                                                                      .id_unit_measure,
                                                                   i_unit_meas_def => l_def_um)
                                THEN
                                    l_new_um := l_def_um;
                                
                                ELSE
                                    l_new_um := l_affected_records(idx).id_unit_measure;
                                
                                END IF;
                            
                        END CASE;
                    
                        BEGIN
                            IF l_composed_vs = pk_alert_constant.g_yes
                            THEN
                                l_id_vital_sign   := l_new_vs;
                                l_id_unit_measure := l_new_um;
                            ELSE
                                l_id_vital_sign   := l_affected_records(idx).id_vital_sign;
                                l_id_unit_measure := l_new_um;
                            END IF;
                        
                            SELECT t.id_patient, t.id_vital_sign, t.id_unit_measure
                              INTO l_pat_old, l_id_vital_sign_old, l_id_unit_measure_old
                              FROM (SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                                      FROM vs_patient_ea vpa
                                     WHERE vpa.id_vital_sign = l_id_vital_sign
                                       AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_last_1_vsr = l_affected_records(idx).id_vital_sign_read
                                    UNION
                                    SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                                      FROM vs_patient_ea vpa
                                     WHERE vpa.id_vital_sign = l_id_vital_sign
                                       AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_last_2_vsr = l_affected_records(idx).id_vital_sign_read
                                    UNION
                                    SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                                      FROM vs_patient_ea vpa
                                     WHERE vpa.id_vital_sign = l_id_vital_sign
                                       AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_last_3_vsr = l_affected_records(idx).id_vital_sign_read
                                    UNION
                                    SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                                      FROM vs_patient_ea vpa
                                     WHERE vpa.id_vital_sign = l_id_vital_sign
                                       AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_first_vsr = l_affected_records(idx).id_vital_sign_read
                                    UNION
                                    SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                                      FROM vs_patient_ea vpa
                                     WHERE vpa.id_vital_sign = l_id_vital_sign
                                       AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_min_vsr = l_affected_records(idx).id_vital_sign_read
                                    UNION
                            SELECT vpa.id_patient, vpa.id_vital_sign, vpa.id_unit_measure
                              FROM vs_patient_ea vpa
                             WHERE vpa.id_vital_sign = l_id_vital_sign
                               AND vpa.id_unit_measure = l_id_unit_measure
                                       AND vpa.id_max_vsr = l_affected_records(idx).id_vital_sign_read) t;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_pat_old             := NULL;
                                l_id_vital_sign_old   := NULL;
                                l_id_unit_measure_old := NULL;
                        END;
                    
                        IF l_pat_old IS NOT NULL
                        THEN
                            l_dbg_msg := 'get vs_pat_ea row for this vital sign/unit measure: OLD LINE l_pat_old: ' ||
                                         l_pat_old;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            l_vs_pat_ea_old := get_vpea_row(i_patient      => l_pat_old,
                                                            i_vital_sign   => l_new_vs,
                                                            i_unit_measure => nvl(l_new_um, pk_vital_sign.c_without_um));
                        ELSE
                            l_vs_pat_ea_old := NULL;
                        END IF;
                    
                        l_dbg_msg := 'get vs_patient_ea row for this vital sign/unit measure. l_new_vs: ' || l_new_vs ||
                                     ' l_new_um: ' || l_new_um || ' id_patient: ' || l_affected_records(idx).id_patient;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        l_vs_pat_ea := get_vpea_row(i_patient      => l_affected_records(idx).id_patient,
                                                    i_vital_sign   => l_new_vs,
                                                    i_unit_measure => nvl(l_new_um, pk_vital_sign.c_without_um));
                    
                        l_dbg_msg := 'l_vs_pat_ea.id_first_vsr: ' || l_vs_pat_ea.id_first_vsr;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                    
                        IF ((l_affected_records(idx).id_vital_sign_read = l_vs_pat_ea_old.id_first_vsr) OR
                           (l_composed_vs = pk_alert_constant.get_yes))
                        THEN
                            IF NOT pk_vital_sign.has_same_date(i_vital_sign_read => l_vs_pat_ea.id_first_vsr,
                                                               i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                               i_new_dt_read     => l_affected_records(idx)
                                                                                    .dt_vital_sign_read_tstz)
                            THEN
                                IF NOT pk_vital_sign.is_older(i_vital_sign_read => l_vs_pat_ea.id_first_vsr,
                                                              i_inst_um         => l_vs_pat_ea.id_unit_measure,
                                                              i_new_dt_read     => l_affected_records(idx)
                                                                                   .dt_vital_sign_read_tstz)
                                THEN
                                    l_vs_pat_ea.id_first_vsr := pk_vital_sign.get_fst_vsr(i_vital_sign   => l_new_vs,
                                                                                          i_unit_measure => l_new_um,
                                                                                          i_patient      => l_affected_records(idx)
                                                                                                            .id_patient);
                                END IF;
                            
                            END IF;
                        
                        END IF;
                    
                        IF ((l_affected_records(idx)
                           .id_vital_sign_read IN (l_vs_pat_ea_old.id_min_vsr, l_vs_pat_ea_old.id_max_vsr)) OR
                           (l_composed_vs = pk_alert_constant.get_yes))
                        THEN
                            pk_vital_sign.get_min_max_vsr(i_vital_sign   => l_new_vs,
                                                          i_unit_measure => l_new_um,
                                                          i_patient      => l_affected_records(idx).id_patient,
                                                          o_min_vsr      => l_vs_pat_ea.id_min_vsr,
                                                          o_max_vsr      => l_vs_pat_ea.id_max_vsr);
                        END IF;
                    
                        IF ((l_affected_records(idx)
                           .id_vital_sign_read IN (l_vs_pat_ea_old.id_last_3_vsr,
                                                    l_vs_pat_ea_old.id_last_2_vsr,
                                                    l_vs_pat_ea_old.id_last_1_vsr)) OR
                           (l_composed_vs = pk_alert_constant.get_yes))
                        THEN
                            pk_vital_sign.get_lst_vsr(i_vital_sign   => l_new_vs,
                                                      i_unit_measure => l_new_um,
                                                      i_patient      => l_affected_records(idx).id_patient,
                                                      o_lst3_vsr     => l_vs_pat_ea.id_last_3_vsr,
                                                      o_lst2_vsr     => l_vs_pat_ea.id_last_2_vsr,
                                                      o_lst1_vsr     => l_vs_pat_ea.id_last_1_vsr);
                        END IF;
                        --
                        IF (l_vs_pat_ea.id_last_1_vsr IS NOT NULL)
                           AND (l_vs_pat_ea.id_patient IS NOT NULL OR l_vs_pat_ea_old.id_vital_sign IS NOT NULL)
                        THEN
                            IF l_vs_pat_ea.id_patient IS NULL
                            THEN
                                l_dbg_msg := 'insert l_vs_vis_ea. l_vs_pat_ea_old.id_vital_sign: ' ||
                                             l_vs_pat_ea_old.id_vital_sign;
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                            
                                ts_vs_patient_ea.ins(id_patient_in      => l_affected_records(idx).id_patient,
                                                     id_vital_sign_in   => l_vs_pat_ea_old.id_vital_sign,
                                                     id_unit_measure_in => l_vs_pat_ea_old.id_unit_measure,
                                                     n_records_in       => l_vs_pat_ea_old.n_records,
                                                     id_first_vsr_in    => l_vs_pat_ea_old.id_first_vsr,
                                                     id_min_vsr_in      => l_vs_pat_ea_old.id_min_vsr,
                                                     id_max_vsr_in      => l_vs_pat_ea_old.id_max_vsr,
                                                     id_last_1_vsr_in   => l_vs_pat_ea_old.id_last_1_vsr,
                                                     id_last_2_vsr_in   => l_vs_pat_ea_old.id_last_2_vsr,
                                                     id_last_3_vsr_in   => l_vs_pat_ea_old.id_last_3_vsr);
                            ELSE
                            
                                l_dbg_msg := 'update the existing record in vs_patient_ea';
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                                ts_vs_patient_ea.upd(id_patient_in      => l_vs_pat_ea.id_patient,
                                                     id_vital_sign_in   => l_vs_pat_ea.id_vital_sign,
                                                     id_unit_measure_in => l_vs_pat_ea.id_unit_measure,
                                                     n_records_in       => l_vs_pat_ea.n_records,
                                                     id_first_vsr_in    => l_vs_pat_ea.id_first_vsr,
                                                     id_min_vsr_in      => l_vs_pat_ea.id_min_vsr,
                                                     id_max_vsr_in      => l_vs_pat_ea.id_max_vsr,
                                                     id_last_1_vsr_in   => l_vs_pat_ea.id_last_1_vsr,
                                                     id_last_2_vsr_in   => l_vs_pat_ea.id_last_2_vsr,
                                                     id_last_2_vsr_nin  => FALSE,
                                                     id_last_3_vsr_in   => l_vs_pat_ea.id_last_3_vsr,
                                                     id_last_3_vsr_nin  => FALSE);
                            END IF;
                        ELSE
                            l_dbg_msg := 'delete the existing record in vs_patient_ea';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            ts_vs_patient_ea.del(id_patient_in      => l_vs_pat_ea.id_patient,
                                                 id_vital_sign_in   => l_vs_pat_ea.id_vital_sign,
                                                 id_unit_measure_in => l_vs_pat_ea.id_unit_measure);
                        END IF;
                    
                        -- It should remove previuse visit vital sign from easy_access table
                        l_dbg_msg := 'Validate visits: l_pat_old = ' || l_pat_old || ' AND l_patt = ' || l_affected_records(idx)
                                    .id_patient;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        IF l_pat_old <> l_affected_records(idx).id_patient
                           AND l_pat_old IS NOT NULL
                        THEN
                            l_dbg_msg := 'delete the existing record in vs_visit_ea. l_composed_vs: ' || l_composed_vs ||
                                         ' l_pat_old: ' || l_pat_old || ' l_id_vital_sign_old: ' || l_id_vital_sign_old ||
                                         ' l_id_unit_measure_old: ' || l_id_unit_measure_old;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            ts_vs_patient_ea.del(id_patient_in      => l_pat_old,
                                                 id_vital_sign_in   => l_id_vital_sign_old,
                                                 id_unit_measure_in => l_id_unit_measure_old);
                        END IF;
                    
                    END IF;
                
                END LOOP;
            
            WHEN t_data_gov_mnt.g_event_delete THEN
                l_dbg_msg := 'process delete event';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
            
                RAISE l_delete_event_excp;
            
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            
        END CASE;
    
        pk_ea_logic_viewer.set_pat_vs(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_event_type        => i_event_type,
                                      i_rowids            => i_rowids,
                                      i_source_table_name => i_source_table_name,
                                      i_list_columns      => i_list_columns,
                                      i_dg_table_name     => i_dg_table_name);
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Invalid arguments');
        
        WHEN l_update_event_excp THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Update events are supported only when canceling a vital sign');
        
        WHEN l_delete_event_excp THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Delete events aren''t supported');
        
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
        
    END process_event;

--
-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);

END pk_ea_logic_vs_patient;
/
