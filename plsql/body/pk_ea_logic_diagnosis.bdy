/*-- Last Change Revision: $Rev: 1864424 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2018-09-10 16:09:25 +0100 (seg, 10 set 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_diagnosis IS

    /********************************************************************************************
    * Get all distinct diagnosis_ea terminologies.
    * Excludes id_inst = 0 and flg_msi_concept_term = H; -- i.e. Excludes Past History Terminologies
    *
    * @param i_institution        Institution id
    *
    * @author                     Alexandre Santos
    * @version                    2.6.2.1
    * @since                      05-Jun-2012
    *
    **********************************************************************************************/
    FUNCTION tf_diag_ea_terminologies(i_institution IN institution.id_institution%TYPE) RETURN t_diag_ea_terminologies
        PIPELINED IS
        l_func_proc_name VARCHAR2(30 CHAR) := 'TF_DIAG_EA_TERMINOLOGIES';
        --
        r_term r_diag_ea_terminology;
    BEGIN
        pk_alertlog.log_debug('LOOP THROUGH INST TERMINOLOGIES', g_package_name, l_func_proc_name);
        FOR r_term IN (SELECT pk_api_diagnosis_func.get_id_terminology(i_flg_type => t.flg_terminology) id_terminology,
                              t.flg_terminology
                         FROM (SELECT DISTINCT d.flg_terminology
                                 FROM diagnosis_ea d
                                WHERE d.flg_msi_concept_term != pk_ea_logic_diagnosis.g_past_hist_diag_type
                                  AND d.id_institution != pk_alert_constant.g_inst_all
                                  AND d.id_institution = nvl(i_institution, d.id_institution)) t)
        LOOP
            PIPE ROW(r_term);
        END LOOP;
    
        RETURN;
    END tf_diag_ea_terminologies;

    /********************************************************************************************
    * Inserts or Updates records in DIAGNOSIS_EA table.
    *
    * @param i_r_diagnosis_ea     DIAGNOSIS_EA row
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_diagnosis_ea(i_r_diagnosis_ea IN pk_api_pfh_diagnosis_in.g_rec_diagnosis_ea%TYPE) IS
        l_func_proc_name VARCHAR2(30 CHAR) := 'INS_DIAGNOSIS_EA';
        l_rec            pk_api_pfh_diagnosis_in.g_rec_diagnosis_ea%TYPE;
        l_rows           table_varchar;
    BEGIN
        l_rec := i_r_diagnosis_ea;
    
        pk_alertlog.log_debug('DIAGNOSIS_EA: Updating', g_package_name, l_func_proc_name);
        ts_diagnosis_ea.upd(id_concept_version_in      => l_rec.id_concept_version,
                            id_cncpt_vrs_inst_owner_in => l_rec.id_cncpt_vrs_inst_owner,
                            id_concept_term_in         => l_rec.id_concept_term,
                            id_cncpt_trm_inst_owner_in => l_rec.id_cncpt_trm_inst_owner,
                            id_language_in             => l_rec.id_language,
                            code_diagnosis_in          => l_rec.code_diagnosis,
                            code_medical_in            => l_rec.code_medical,
                            code_surgical_in           => l_rec.code_surgical,
                            code_problems_in           => l_rec.code_problems,
                            code_cong_anomalies_in     => l_rec.code_cong_anomalies,
                            concept_code_in            => l_rec.concept_code,
                            mdm_coding_in              => l_rec.mdm_coding,
                            flg_terminology_in         => l_rec.flg_terminology,
                            flg_subtype_in             => l_rec.flg_subtype,
                            flg_diag_type_in           => l_rec.flg_diag_type,
                            flg_family_in              => l_rec.flg_family,
                            flg_icd9_in                => l_rec.flg_icd9,
                            flg_job_in                 => l_rec.flg_job,
                            flg_msi_concept_term_in    => l_rec.flg_msi_concept_term,
                            flg_other_in               => l_rec.flg_other,
                            flg_pos_birth_in           => l_rec.flg_pos_birth,
                            flg_select_in              => l_rec.flg_select,
                            concept_type_int_name_in   => l_rec.concept_type_int_name,
                            age_min_in                 => l_rec.age_min,
                            age_max_in                 => l_rec.age_max,
                            gender_in                  => l_rec.gender,
                            rank_in                    => l_rec.rank,
                            id_institution_in          => l_rec.id_institution,
                            id_software_in             => l_rec.id_software,
                            id_dep_clin_serv_in        => l_rec.id_dep_clin_serv,
                            id_professional_in         => l_rec.id_professional,
                            code_diagnosis_partial_in  => l_rec.code_diagnosis_partial,
                            diagnosis_path_in          => l_rec.diagnosis_path,
                            flg_is_diagnosis_in        => l_rec.flg_is_diagnosis,
                            code_death_event_in        => l_rec.code_death_event,
                            code_diagnosis_nin         => FALSE,
                            code_medical_nin           => FALSE,
                            code_surgical_nin          => FALSE,
                            code_problems_nin          => FALSE,
                            code_cong_anomalies_nin    => FALSE,
                            concept_code_nin           => FALSE,
                            mdm_coding_nin             => FALSE,
                            flg_terminology_nin        => FALSE,
                            flg_subtype_nin            => FALSE,
                            flg_diag_type_nin          => FALSE,
                            flg_family_nin             => FALSE,
                            flg_icd9_nin               => FALSE,
                            flg_job_nin                => FALSE,
                            flg_msi_concept_term_nin   => FALSE,
                            flg_other_nin              => FALSE,
                            flg_pos_birth_nin          => FALSE,
                            flg_select_nin             => FALSE,
                            concept_type_int_name_nin  => FALSE,
                            age_min_nin                => FALSE,
                            age_max_nin                => FALSE,
                            gender_nin                 => FALSE,
                            rank_nin                   => FALSE,
                            code_diagnosis_partial_nin => FALSE,
                            diagnosis_path_nin         => FALSE,
                            flg_is_diagnosis_nin       => FALSE,
                            code_death_event_nin       => FALSE,
                            rows_out                   => l_rows);
    
        IF (NOT l_rows.exists(1))
           OR (l_rows.count = 0)
        THEN
            pk_alertlog.log_debug('DIAGNOSIS_EA: Inserting', g_package_name, l_func_proc_name);
            ts_diagnosis_ea.ins(id_concept_version_in      => l_rec.id_concept_version,
                                id_cncpt_vrs_inst_owner_in => l_rec.id_cncpt_vrs_inst_owner,
                                id_concept_term_in         => l_rec.id_concept_term,
                                id_cncpt_trm_inst_owner_in => l_rec.id_cncpt_trm_inst_owner,
                                id_language_in             => l_rec.id_language,
                                code_diagnosis_in          => l_rec.code_diagnosis,
                                code_medical_in            => l_rec.code_medical,
                                code_surgical_in           => l_rec.code_surgical,
                                code_problems_in           => l_rec.code_problems,
                                code_cong_anomalies_in     => l_rec.code_cong_anomalies,
                                concept_code_in            => l_rec.concept_code,
                                mdm_coding_in              => l_rec.mdm_coding,
                                flg_terminology_in         => l_rec.flg_terminology,
                                flg_subtype_in             => l_rec.flg_subtype,
                                flg_diag_type_in           => l_rec.flg_diag_type,
                                flg_family_in              => l_rec.flg_family,
                                flg_icd9_in                => l_rec.flg_icd9,
                                flg_job_in                 => l_rec.flg_job,
                                flg_msi_concept_term_in    => l_rec.flg_msi_concept_term,
                                flg_other_in               => l_rec.flg_other,
                                flg_pos_birth_in           => l_rec.flg_pos_birth,
                                flg_select_in              => l_rec.flg_select,
                                concept_type_int_name_in   => l_rec.concept_type_int_name,
                                age_min_in                 => l_rec.age_min,
                                age_max_in                 => l_rec.age_max,
                                gender_in                  => l_rec.gender,
                                rank_in                    => l_rec.rank,
                                id_institution_in          => l_rec.id_institution,
                                id_software_in             => l_rec.id_software,
                                id_dep_clin_serv_in        => l_rec.id_dep_clin_serv,
                                id_professional_in         => l_rec.id_professional,
                                code_diagnosis_partial_in  => l_rec.code_diagnosis_partial,
                                diagnosis_path_in          => l_rec.diagnosis_path,
                                flg_is_diagnosis_in        => l_rec.flg_is_diagnosis,
                                code_death_event_in        => l_rec.code_death_event);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END ins_diagnosis_ea;

    /********************************************************************************************
    * Inserts or Updates MSI_CONCEPT_TERM related fields in the DIAGNOSIS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_concept_term
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name   VARCHAR2(30 CHAR) := 'SET_MSI_CONCEPT_TERM';
        l_tab_diagnosis_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_ea;
    BEGIN
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => g_diagnosis_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF upper(i_source_table_name) = 'MSI_CONCEPT_TERM'
        THEN
            IF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                -- Process event
                pk_alertlog.log_debug('MSI_CONCEPT_TERM: GET_EA_DATA_BY_MCT (Y)', g_package_name, l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mct(i_rowids     => i_rowids,
                                                                                 i_flg_active => g_flg_active_y);
            
                -- Insert/update active records in DIAGNOSIS_EA
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR i IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ins_diagnosis_ea(l_tab_diagnosis_ea(i));
                    END LOOP;
                END IF;
            
                l_tab_diagnosis_ea.delete;
            
                pk_alertlog.log_debug('MSI_CONCEPT_TERM: GET_EA_DATA_BY_MCT (N)', g_package_name, l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mct(i_rowids     => i_rowids,
                                                                                 i_flg_active => g_flg_active_n);
            
                -- Remove inactive records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                pk_alertlog.log_debug('MSI_CONCEPT_TERM: GET_EA_DATA_BY_MCT (DELETE)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mct(i_rowids     => i_rowids,
                                                                                 i_flg_active => NULL);
            
                -- Remove records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            END IF;
        ELSE
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_msi_concept_term;

    /********************************************************************************************
    * Inserts or Updates MSI_TERMIN_VERSION related fields in the DIAGNOSIS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_termin_version
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name   VARCHAR2(30 CHAR) := 'SET_MSI_TERMIN_VERSION';
        l_tab_diagnosis_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_ea;
    BEGIN
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => g_diagnosis_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF upper(i_source_table_name) = 'MSI_TERMIN_VERSION'
        THEN
            IF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                -- Process event
                pk_alertlog.log_debug('MSI_TERMIN_VERSION: GET_EA_DATA_BY_MTV (Y)', g_package_name, l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mtv(i_rowids     => i_rowids,
                                                                                 i_flg_active => g_flg_active_y);
            
                -- Insert/update active records in DIAGNOSIS_EA
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR i IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ins_diagnosis_ea(l_tab_diagnosis_ea(i));
                    END LOOP;
                END IF;
            
                l_tab_diagnosis_ea.delete;
            
                pk_alertlog.log_debug('MSI_TERMIN_VERSION: GET_EA_DATA_BY_MTV (N)', g_package_name, l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mtv(i_rowids     => i_rowids,
                                                                                 i_flg_active => g_flg_active_n);
            
                -- Remove inactive records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                pk_alertlog.log_debug('MSI_TERMIN_VERSION: GET_EA_DATA_BY_MTV (DELETE)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mtv(i_rowids     => i_rowids,
                                                                                 i_flg_active => NULL);
            
                -- Remove records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            END IF;
        ELSE
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_msi_termin_version;

    /********************************************************************************************
    * Inserts or Updates msi_cncpt_vers_attrib related fields in the DIAGNOSIS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      29-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_cncpt_vers_attrib
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name   VARCHAR2(30 CHAR) := 'SET_msi_cncpt_vers_attrib';
        l_tab_diagnosis_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_ea;
    BEGIN
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => g_diagnosis_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF upper(i_source_table_name) = 'MSI_CNCPT_VERS_ATTRIB'
        THEN
            IF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                -- Process event
                pk_alertlog.log_debug('msi_cncpt_vers_attrib: GET_EA_DATA_BY_MCVA (Y)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mcva(i_rowids     => i_rowids,
                                                                                  i_flg_active => g_flg_active_y);
            
                -- Insert/update active records in DIAGNOSIS_EA
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR i IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ins_diagnosis_ea(l_tab_diagnosis_ea(i));
                    END LOOP;
                END IF;
            
                l_tab_diagnosis_ea.delete;
            
                pk_alertlog.log_debug('msi_cncpt_vers_attrib: GET_EA_DATA_BY_MCVA (N)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mcva(i_rowids     => i_rowids,
                                                                                  i_flg_active => g_flg_active_n);
            
                -- Remove inactive records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                pk_alertlog.log_debug('msi_cncpt_vers_attrib: GET_EA_DATA_BY_MCVA (DELETE)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_by_mcva(i_rowids     => i_rowids,
                                                                                  i_flg_active => NULL);
            
                -- Remove records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                    LOOP
                        ts_diagnosis_ea.del(id_concept_version_in      => l_tab_diagnosis_ea(j).id_concept_version,
                                            id_cncpt_vrs_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_vrs_inst_owner,
                                            id_concept_term_in         => l_tab_diagnosis_ea(j).id_concept_term,
                                            id_cncpt_trm_inst_owner_in => l_tab_diagnosis_ea(j).id_cncpt_trm_inst_owner,
                                            id_language_in             => l_tab_diagnosis_ea(j).id_language,
                                            id_institution_in          => l_tab_diagnosis_ea(j).id_institution,
                                            id_software_in             => l_tab_diagnosis_ea(j).id_software,
                                            id_dep_clin_serv_in        => l_tab_diagnosis_ea(j).id_dep_clin_serv,
                                            id_professional_in         => l_tab_diagnosis_ea(j).id_professional);
                    END LOOP;
                END IF;
            
            END IF;
        ELSE
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_msi_cncpt_vers_attrib;

    /********************************************************************************************
    * Inserts or Updates records in DIAGNOSIS_RELATIONS_EA table.
    *
    * @param i_r_diagnosis_rel_ea     DIAGNOSIS_RELATIONS_EA row
    *
    * @author                         José Brito
    * @version                        2.6.2
    * @since                          16-Mar-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_diagnosis_relations_ea(i_r_diagnosis_rel_ea IN alert_core_func.pk_api_diagnosis_func.g_rec_diagnosis_rel_ea) IS
        l_func_proc_name VARCHAR2(30 CHAR) := 'INS_DIAGNOSIS_RELATIONS_EA';
        l_rec            alert_core_func.pk_api_diagnosis_func.g_rec_diagnosis_rel_ea;
        l_rows           table_varchar;
    BEGIN
        l_rec := i_r_diagnosis_rel_ea;
    
        pk_alertlog.log_debug('DIAGNOSIS_RELATIONS_EA: Updating', g_package_name, l_func_proc_name);
        ts_diagnosis_relations_ea.upd(id_concept_version_1_in    => l_rec.id_concept_version_1,
                                      id_cncpt_vrs_inst_own1_in  => l_rec.id_cncpt_vrs_inst_own1,
                                      concept_type_int_name1_in  => l_rec.concept_type_int_name1,
                                      id_concept_version_2_in    => l_rec.id_concept_version_2,
                                      id_cncpt_vrs_inst_own2_in  => l_rec.id_cncpt_vrs_inst_own2,
                                      concept_type_int_name2_in  => l_rec.concept_type_int_name2,
                                      cncpt_rel_type_int_name_in => l_rec.cncpt_rel_type_int_name,
                                      rank_in                    => l_rec.rank,
                                      flg_default_in             => l_rec.flg_default,
                                      id_institution_in          => l_rec.id_institution,
                                      id_software_in             => l_rec.id_software,
                                      rank_nin                   => FALSE,
                                      flg_default_nin            => FALSE,
                                      rows_out                   => l_rows);
    
        IF (NOT l_rows.exists(1))
           OR (l_rows.count = 0)
        THEN
            pk_alertlog.log_debug('DIAGNOSIS_RELATIONS_EA: Inserting', g_package_name, l_func_proc_name);
            ts_diagnosis_relations_ea.ins(id_concept_version_1_in    => l_rec.id_concept_version_1,
                                          id_cncpt_vrs_inst_own1_in  => l_rec.id_cncpt_vrs_inst_own1,
                                          concept_type_int_name1_in  => l_rec.concept_type_int_name1,
                                          id_concept_version_2_in    => l_rec.id_concept_version_2,
                                          id_cncpt_vrs_inst_own2_in  => l_rec.id_cncpt_vrs_inst_own2,
                                          concept_type_int_name2_in  => l_rec.concept_type_int_name2,
                                          cncpt_rel_type_int_name_in => l_rec.cncpt_rel_type_int_name,
                                          rank_in                    => l_rec.rank,
                                          flg_default_in             => l_rec.flg_default,
                                          id_institution_in          => l_rec.id_institution,
                                          id_software_in             => l_rec.id_software);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END ins_diagnosis_relations_ea;

    /********************************************************************************************
    * Inserts or Updates MSI_CONCEPT_RELATION related fields in the DIAGNOSIS_RELATIONS_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author                     José Brito
    * @version                    2.6.2
    * @since                      20-Mar-2012
    *
    **********************************************************************************************/
    PROCEDURE set_msi_concept_relation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name       VARCHAR2(30 CHAR) := 'SET_MSI_CONCEPT_RELATION';
        l_tab_diagnosis_rel_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_rel_ea;
    BEGIN
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => g_diagnosis_relations_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF upper(i_source_table_name) = 'MSI_CONCEPT_RELATION'
        THEN
            IF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                -- Process event
                pk_alertlog.log_debug('MSI_CONCEPT_RELATION: GET_RELATIONS_EA_DATA_BY_MCR (Y)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_rel_ea := pk_api_pfh_diagnosis_in.get_relations_ea_data_by_mcr(i_rowids     => i_rowids,
                                                                                               i_flg_active => g_flg_active_y);
            
                -- Insert/update active records in DIAGNOSIS_RELATIONS_EA
                IF l_tab_diagnosis_rel_ea.exists(1)
                THEN
                    FOR i IN l_tab_diagnosis_rel_ea.first .. l_tab_diagnosis_rel_ea.last
                    LOOP
                        ins_diagnosis_relations_ea(l_tab_diagnosis_rel_ea(i));
                    END LOOP;
                END IF;
            
                l_tab_diagnosis_rel_ea.delete;
            
                pk_alertlog.log_debug('MSI_CONCEPT_RELATION: GET_RELATIONS_EA_DATA_BY_MCR (N)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_rel_ea := pk_api_pfh_diagnosis_in.get_relations_ea_data_by_mcr(i_rowids     => i_rowids,
                                                                                               i_flg_active => g_flg_active_n);
            
                -- Remove inactive records from DIAGNOSIS_RELATIONS_EA                                                          
                IF l_tab_diagnosis_rel_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_rel_ea.first .. l_tab_diagnosis_rel_ea.last
                    LOOP
                        ts_diagnosis_relations_ea.del(id_concept_version_1_in    => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_concept_version_1,
                                                      id_cncpt_vrs_inst_own1_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_cncpt_vrs_inst_own1,
                                                      concept_type_int_name1_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .concept_type_int_name1,
                                                      id_concept_version_2_in    => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_concept_version_2,
                                                      id_cncpt_vrs_inst_own2_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_cncpt_vrs_inst_own2,
                                                      concept_type_int_name2_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .concept_type_int_name2,
                                                      cncpt_rel_type_int_name_in => l_tab_diagnosis_rel_ea(j)
                                                                                    .cncpt_rel_type_int_name,
                                                      id_institution_in          => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_institution,
                                                      id_software_in             => l_tab_diagnosis_rel_ea(j).id_software);
                    END LOOP;
                END IF;
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                pk_alertlog.log_debug('MSI_CONCEPT_RELATION: GET_RELATIONS_EA_DATA_BY_MCR (DELETE)',
                                      g_package_name,
                                      l_func_proc_name);
                l_tab_diagnosis_rel_ea := pk_api_pfh_diagnosis_in.get_relations_ea_data_by_mcr(i_rowids     => i_rowids,
                                                                                               i_flg_active => NULL);
            
                -- Remove records from DIAGNOSIS_EA                                                          
                IF l_tab_diagnosis_rel_ea.exists(1)
                THEN
                    FOR j IN l_tab_diagnosis_rel_ea.first .. l_tab_diagnosis_rel_ea.last
                    LOOP
                        ts_diagnosis_relations_ea.del(id_concept_version_1_in    => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_concept_version_1,
                                                      id_cncpt_vrs_inst_own1_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_cncpt_vrs_inst_own1,
                                                      concept_type_int_name1_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .concept_type_int_name1,
                                                      id_concept_version_2_in    => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_concept_version_2,
                                                      id_cncpt_vrs_inst_own2_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_cncpt_vrs_inst_own2,
                                                      concept_type_int_name2_in  => l_tab_diagnosis_rel_ea(j)
                                                                                    .concept_type_int_name2,
                                                      cncpt_rel_type_int_name_in => l_tab_diagnosis_rel_ea(j)
                                                                                    .cncpt_rel_type_int_name,
                                                      id_institution_in          => l_tab_diagnosis_rel_ea(j)
                                                                                    .id_institution,
                                                      id_software_in             => l_tab_diagnosis_rel_ea(j).id_software);
                    END LOOP;
                END IF;
            
            END IF;
        ELSE
            RETURN;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_msi_concept_relation;

    /**
    * Updates Diagnosis information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_list_columns           List of columns that were changed
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          22-Mar-2012
    */
    PROCEDURE set_task_timeline_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_DIAG';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_id_tl_task_diag_dif     CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_diagnosis;
        l_id_tl_task_diag_fin     CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_final_diag;
        l_epis_status_cancel      CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_status_cancel;
        l_tl_table_name_diagnosis CONSTANT VARCHAR2(1000 CHAR) := pk_alert_constant.g_tl_table_name_diagnosis;
        l_tl_oriented_episode     CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_tl_oriented_episode;
    
        l_flg_diag_final CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_diag_flg_type_d;
        l_flg_diag_dif   CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_diag_flg_type_p;
    
        l_flg_not_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_not_outdated;
    
        e_excp_invalid_event_type EXCEPTION;
    
        o_rowids    table_varchar;
        l_error_out t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                FOR r_cur IN (SELECT t.id_task_refid,
                                     t.id_patient,
                                     t.id_episode,
                                     t.id_visit,
                                     t.id_institution,
                                     CASE
                                          WHEN ((t.dt_hist > t.dt_req_diag) OR t.dt_req_diag IS NULL) THEN
                                           t.dt_hist
                                          ELSE
                                           t.dt_req_diag
                                      END dt_req,
                                     
                                     t.id_prof_req,
                                     t.flg_status_req,
                                     t.id_tl_task,
                                     t.flg_status_epis,
                                     t.id_professional_cancel,
                                     t.flg_ongoing,
                                     t.rank,
                                     t.flg_final_type
                                FROM (SELECT ed.id_epis_diagnosis id_task_refid,
                                             epis.id_patient,
                                             epis.id_episode,
                                             epis.id_visit,
                                             epis.id_institution,
                                             pk_diagnosis.get_diag_hist_creation_dt(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_id_epis_diagnosis => ed.id_epis_diagnosis) dt_hist,
                                             pk_diagnosis_core.get_dt_diagnosis(i_lang              => il.id_language,
                                                                                i_prof              => profissional(0,
                                                                                                                    ei.id_software,
                                                                                                                    epis.id_institution),
                                                                                i_flg_status        => ed.flg_status,
                                                                                i_dt_epis_diagnosis => ed.dt_epis_diagnosis_tstz,
                                                                                i_dt_confirmed      => ed.dt_confirmed_tstz,
                                                                                i_dt_cancel         => ed.dt_cancel_tstz,
                                                                                i_dt_base           => ed.dt_base_tstz,
                                                                                i_dt_rulled_out     => ed.dt_rulled_out_tstz) dt_req_diag,
                                             nvl(ed.id_professional_diag,
                                                 nvl(ed.id_prof_confirmed, ed.id_prof_rulled_out)) id_prof_req,
                                             ed.flg_status flg_status_req,
                                             decode(ed.flg_type,
                                                    l_flg_diag_final,
                                                    l_id_tl_task_diag_fin,
                                                    l_id_tl_task_diag_dif) id_tl_task,
                                             epis.flg_status flg_status_epis,
                                             ed.id_professional_cancel,
                                             CASE
                                                  WHEN ed.flg_status IN
                                                       (pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_r) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             decode(ed.flg_final_type,
                                                    pk_diagnosis.g_flg_final_type_p,
                                                    -1,
                                                    pk_sysdomain.get_rank(i_lang,
                                                                          'EPIS_DIAGNOSIS.FLG_STATUS',
                                                                          ed.flg_status)) rank,
                                             ed.flg_final_type
                                        FROM epis_diagnosis ed
                                       INNER JOIN diagnosis d
                                          ON ed.id_diagnosis = d.id_diagnosis
                                       INNER JOIN episode epis
                                          ON ed.id_episode = epis.id_episode
                                       INNER JOIN epis_info ei
                                          ON epis.id_episode = ei.id_episode
                                       INNER JOIN institution_language il
                                          ON epis.id_institution = il.id_institution
                                       WHERE ed.rowid IN (SELECT vc_1
                                                            FROM tbl_temp)
                                         AND ed.flg_type IN (l_flg_diag_final, l_flg_diag_dif)
                                         AND (ed.flg_is_complication = pk_alert_constant.g_no OR
                                             ed.flg_is_complication IS NULL)) t)
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := r_cur.id_tl_task;
                    l_new_rec_row.table_name        := l_tl_table_name_diagnosis;
                    l_new_rec_row.flg_show_method   := l_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid    := r_cur.id_task_refid;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status_req;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_req;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := l_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := pk_alert_constant.g_yes;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_req;
                    l_new_rec_row.rank             := r_cur.rank;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    l_new_rec_row.flg_type         := r_cur.flg_final_type;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req IN ('A' /*Activo*/,
                                                        'D' /*Despiste*/,
                                                        'F' /*Confirmado*/,
                                                        'B' /*Base*/,
                                                        'R' /*ruled out*/,
                                                        'P' /*Presumptivo*/)
                       AND r_cur.flg_status_epis <> l_epis_status_cancel
                       AND r_cur.id_professional_cancel IS NULL
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name_diagnosis
                           AND tte.id_tl_task IN (l_id_tl_task_diag_fin, l_id_tl_task_diag_dif);
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSE
                        IF l_new_rec_row.flg_status_req NOT IN
                           ('A' /*Activo*/,
                            'D' /*Despiste*/,
                            'F' /*Confirmado*/,
                            'B' /*Base*/,
                            'R' /*ruled out*/,
                            'P' /*Presumptivo*/) -- Not Active
                           OR r_cur.flg_status_epis = l_epis_status_cancel
                           OR r_cur.id_professional_cancel IS NOT NULL
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        END IF;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderão ocorrer DELETE's na tabela EPIS_COMPLAINT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin         => TRUE,
                                                flg_outdated_in          => l_new_rec_row.flg_outdated,
                                                id_parent_task_refid_nin => TRUE,
                                                id_parent_task_refid_in  => l_new_rec_row.id_parent_task_refid,
                                                flg_ongoing_nin          => TRUE,
                                                flg_ongoing_in           => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin           => TRUE,
                                                flg_normal_in            => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin         => TRUE,
                                                id_prof_exec_in          => l_new_rec_row.id_prof_exec,
                                                rank_nin                 => FALSE,
                                                rank_in                  => l_new_rec_row.rank,
                                                flg_has_comments_nin     => TRUE,
                                                flg_has_comments_in      => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in        => l_new_rec_row.dt_last_update,
                                                rows_out                 => o_rowids);
                    
                    ELSE
                        RAISE e_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN e_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_diag;

    /**
    * Updates Diagnosis Notes information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_list_columns           List of columns that were changed
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          22-Mar-2012
    */
    PROCEDURE set_task_timeline_diag_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_DIAG_NOTES';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_id_tl_task_diag_notes    CONSTANT PLS_INTEGER := pk_prog_notes_constants.g_task_diag_notes;
        l_epis_status_cancel       CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_epis_status_cancel;
        l_note_active              CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_active;
        l_tl_table_name_diag_notes CONSTANT VARCHAR2(1000 CHAR) := pk_alert_constant.g_tl_table_name_diag_notes;
        l_tl_oriented_episode      CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_tl_oriented_episode;
    
        l_flg_not_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := pk_ea_logic_tasktimeline.g_flg_not_outdated;
    
        e_excp_invalid_event_type EXCEPTION;
    
        o_rowids    table_varchar;
        l_error_out t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                FOR r_cur IN (SELECT en.id_epis_diagnosis_notes id_task_refid,
                                     epis.id_patient,
                                     epis.id_episode,
                                     epis.id_visit,
                                     epis.id_institution,
                                     en.id_prof_create          id_prof_req,
                                     en.dt_epis_diagnosis_notes dt_req,
                                     en.notes                   universal_desc_clob,
                                     epis.flg_status            flg_status_epis,
                                     en.dt_create               dt_execution,
                                     en.id_cancel_reason
                                FROM epis_diagnosis_notes en
                               INNER JOIN episode epis
                                  ON en.id_episode = epis.id_episode
                               WHERE en.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := l_id_tl_task_diag_notes;
                    l_new_rec_row.table_name        := l_tl_table_name_diag_notes;
                    l_new_rec_row.flg_show_method   := l_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid       := r_cur.id_task_refid;
                    l_new_rec_row.flg_status_req      := l_note_active;
                    l_new_rec_row.id_prof_req         := r_cur.id_prof_req;
                    l_new_rec_row.dt_req              := r_cur.dt_req;
                    l_new_rec_row.id_patient          := r_cur.id_patient;
                    l_new_rec_row.id_episode          := r_cur.id_episode;
                    l_new_rec_row.id_visit            := r_cur.id_visit;
                    l_new_rec_row.id_institution      := r_cur.id_institution;
                    l_new_rec_row.flg_outdated        := l_flg_not_outdated;
                    l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                    l_new_rec_row.dt_execution        := r_cur.dt_execution;
                    l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing         := pk_prog_notes_constants.g_task_ongoing_o;
                    l_new_rec_row.flg_normal          := pk_alert_constant.g_yes;
                    l_new_rec_row.id_prof_exec        := r_cur.id_prof_req;
                    l_new_rec_row.flg_has_comments    := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update      := r_cur.dt_req;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status_epis <> l_epis_status_cancel
                       AND r_cur.id_cancel_reason IS NULL
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_tl_table_name_diag_notes
                           AND tte.id_tl_task = l_id_tl_task_diag_notes;
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSE
                        IF r_cur.flg_status_epis = l_epis_status_cancel
                           OR r_cur.id_cancel_reason IS NOT NULL
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        END IF;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderão ocorrer DELETE's na tabela EPIS_COMPLAINT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin        => TRUE,
                                                flg_outdated_in         => l_new_rec_row.flg_outdated,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                                dt_execution_nin        => TRUE,
                                                dt_execution_in         => l_new_rec_row.dt_execution,
                                                flg_ongoing_nin         => TRUE,
                                                flg_ongoing_in          => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin          => TRUE,
                                                flg_normal_in           => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin        => TRUE,
                                                id_prof_exec_in         => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin    => TRUE,
                                                flg_has_comments_in     => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in       => l_new_rec_row.dt_last_update,
                                                rows_out                => o_rowids);
                    
                    ELSE
                        RAISE e_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN e_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_diag_notes;

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_EA
    *
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Apr-2012
    *
    **********************************************************************************************/
    FUNCTION rebuild_diagnosis_ea
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'REBUILD_DIAGNOSIS_EA';
        l_internal_error EXCEPTION;
        l_query             VARCHAR2(1000);
        l_tbl_terminologies table_varchar;
    BEGIN
        -- Remove content from DIAGNOSIS_EA
        g_error := 'DELETE ALL';
        pk_alertlog.log_debug(text => g_error);
        l_query := 'DELETE FROM diagnosis_ea';
    
        IF i_institution IS NOT NULL
        THEN
            l_query := l_query || ' WHERE id_institution = ' || i_institution;
        
            g_error := 'GET INST TERMINOLOGIES';
            pk_alertlog.log_debug(text => g_error);
            SELECT flg_terminology
              BULK COLLECT
              INTO l_tbl_terminologies
              FROM TABLE(pk_ea_logic_diagnosis.tf_diag_ea_terminologies(i_institution => decode(i_institution,
                                                                                                0,
                                                                                                NULL,
                                                                                                i_institution)));
        
            g_error := 'DELETE INST TERM USED BY PAST HIST';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM diagnosis_ea d
             WHERE d.flg_msi_concept_term = pk_ea_logic_diagnosis.g_past_hist_diag_type
               AND d.id_institution = pk_alert_constant.g_inst_all
               AND d.flg_terminology IN (SELECT column_value flg_terminology
                                           FROM TABLE(l_tbl_terminologies));
        END IF;
    
        EXECUTE IMMEDIATE l_query;
    
        -- Call mig_diagnosis_ea
        g_error := 'CALL MIG_DIAGNOSIS_EA';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_mig_diagnosis.mig_diagnosis_ea(i_institution => i_institution, i_commit => 0, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        dbms_stats.gather_table_stats(ownname          => 'ALERT',
                                      tabname          => 'DIAGNOSIS_EA',
                                      estimate_percent => 100,
                                      method_opt       => 'for all columns size 1 for all indexed columns size auto',
                                      no_invalidate    => FALSE,
                                      degree           => 4);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END rebuild_diagnosis_ea;

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_RELATIONS_EA
    *
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Apr-2012
    *
    **********************************************************************************************/
    FUNCTION rebuild_diagnosis_relations_ea(o_error OUT t_error_out) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'REBUILD_DIAGNOSIS_RELATIONS_EA';
        l_internal_error EXCEPTION;
    BEGIN
        -- Remove content from DIAGNOSIS_RELATIONS_EA
        g_error := 'DELETE ALL';
        pk_alertlog.log_debug(text => g_error);
        EXECUTE IMMEDIATE 'DELETE FROM diagnosis_relations_ea';
    
        -- Call mig_diagnosis_relations_ea
        g_error := 'CALL MIG_DIAGNOSIS_RELATIONS_EA';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_mig_diagnosis.mig_diagnosis_relations_ea(i_commit => 0, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        dbms_stats.gather_table_stats(ownname          => 'ALERT',
                                      tabname          => 'DIAGNOSIS_RELATIONS_EA',
                                      estimate_percent => 100,
                                      method_opt       => 'for all columns size 1 for all indexed columns size auto',
                                      no_invalidate    => FALSE,
                                      degree           => 4);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END rebuild_diagnosis_relations_ea;

    /********************************************************************************************
    * Rebuils content of DIAGNOSIS_EA
    *
    * @param i_institution             Institution id
    * @param i_software                Software id
    * @param i_commit                  Is to commit the transaction?
    * 
    * @author                          Alexandre Santos
    * @version                         2.6.3
    * @since                           13-Aug-2013
    *
    **********************************************************************************************/
    PROCEDURE rebuild_diagnosis_ea
    (
        i_institution  IN institution.id_institution%TYPE,
        i_tbl_software IN table_number,
        i_commit       IN BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'REBUILD_DIAGNOSIS_EA';
        --
        l_tbl_past_hist_flg_terms table_varchar;
        l_tbl_past_hist_id_terms  table_varchar;
        --
        l_tbl_diag_ea_rows      table_varchar;
        l_tbl_diag_conf_ea_rows table_varchar;
        l_tbl_diag_rel_ea_rows  table_varchar;
        l_tbl_aux1_rows         table_varchar;
        l_tbl_aux2_rows         table_varchar;
        --
        l_tbl_software table_number;
        --  
        PROCEDURE delete_diag_ea_rows IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'DELETE_DIAG_EA_ROWS';
        BEGIN
            -- Remove content from DIAGNOSIS_EA
            g_error := 'DELETE DIAGNOSIS_EA ROWS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            DELETE FROM diagnosis_ea d
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(l_tbl_diag_ea_rows));
        END delete_diag_ea_rows;
    
        PROCEDURE delete_diag_rel_ea_rows IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'DELETE_DIAG_REL_EA_ROWS';
        BEGIN
            -- Remove content from DIAGNOSIS_RELATIONS_EA
            g_error := 'DELETE DIAGNOSIS_RELATIONS_EA ROWS FOR INST: ' || i_institution || '; SOFT: ' ||
                       pk_utils.concat_table(i_tbl_software);
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            DELETE FROM diagnosis_relations_ea d
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(l_tbl_diag_rel_ea_rows));
        END delete_diag_rel_ea_rows;
    
        PROCEDURE delete_diag_conf_ea_rows IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'DELETE_DIAG_CONF_EA_ROWS';
        BEGIN
            -- Remove content from DIAGNOSIS_RELATIONS_EA
            g_error := 'DELETE DIAGNOSIS_RELATIONS_EA ROWS FOR INST: ' || i_institution || '; SOFT: ' ||
                       pk_utils.concat_table(i_tbl_software);
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            DELETE FROM diagnosis_conf_ea d
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(l_tbl_diag_conf_ea_rows));
        END delete_diag_conf_ea_rows;
    
        PROCEDURE reset_exceptions_table IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'RESET_EXCEPTIONS_TABLE';
        BEGIN
            g_error := 'RESET EXCEPTIONS TABLE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            DELETE FROM exceptions_cons ec
             WHERE ec.owner = g_package_owner
               AND ec.table_name IN (g_diagnosis_ea, g_diagnosis_relations_ea, g_diagnosis_conf_ea);
        END reset_exceptions_table;
    
        PROCEDURE enable_index_bulk
        (
            i_table_name   IN table_varchar,
            i_enable_fk    IN BOOLEAN DEFAULT TRUE,
            i_enable_pk    IN BOOLEAN DEFAULT TRUE,
            i_enable_uk    IN BOOLEAN DEFAULT TRUE,
            i_disable_trig IN BOOLEAN DEFAULT TRUE,
            i_owner        IN VARCHAR2
        ) IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'ENABLE_INDEX_BULK';
        BEGIN
            g_error := 'CALL RESET_EXCEPTIONS_TABLE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            reset_exceptions_table;
        
            BEGIN
                g_error := 'CALL PK_FRMW.ENABLE_INDEX_BULK';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
                pk_frmw.enable_index_bulk(i_table_name   => i_table_name,
                                          i_enable_fk    => i_enable_fk,
                                          i_enable_pk    => i_enable_pk,
                                          i_enable_uk    => i_enable_uk,
                                          i_disable_trig => i_disable_trig,
                                          i_owner        => i_owner);
            EXCEPTION
                WHEN OTHERS THEN
                    g_error := 'DELETE INVALID ROWS FROM DIAGNOSIS_EA TABLE';
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_inner_func);
                    DELETE FROM diagnosis_ea d
                     WHERE ROWID IN (SELECT ec.row_id
                                       FROM exceptions_cons ec
                                      WHERE ec.owner = i_owner
                                        AND ec.table_name = g_diagnosis_ea);
                
                    g_error := 'DELETE INVALID ROWS FROM DIAGNOSIS_RELATIONS_EA TABLE';
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_inner_func);
                    DELETE FROM diagnosis_relations_ea d
                     WHERE ROWID IN (SELECT ec.row_id
                                       FROM exceptions_cons ec
                                      WHERE ec.owner = i_owner
                                        AND ec.table_name = g_diagnosis_relations_ea);
                
                    g_error := 'DELETE INVALID ROWS FROM DIAGNOSIS_CONF_EA TABLE';
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_inner_func);
                    DELETE FROM diagnosis_conf_ea d
                     WHERE ROWID IN (SELECT ec.row_id
                                       FROM exceptions_cons ec
                                      WHERE ec.owner = i_owner
                                        AND ec.table_name = g_diagnosis_conf_ea);
                
                    g_error := 'TRY TO ENABLE AGAIN - CALL PK_FRMW.ENABLE_INDEX_BULK';
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_inner_func);
                    pk_frmw.enable_index_bulk(i_table_name   => i_table_name,
                                              i_enable_fk    => i_enable_fk,
                                              i_enable_pk    => i_enable_pk,
                                              i_enable_uk    => i_enable_uk,
                                              i_disable_trig => i_disable_trig,
                                              i_owner        => i_owner);
            END;
        END enable_index_bulk;
    
        PROCEDURE insert_data_in_diag_ea IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'INSERT_DATA_IN_DIAG_EA';
            --
            l_tbl_diag_ea ts_diagnosis_ea.diagnosis_ea_tc;
        BEGIN
            g_error := 'GET DIAG DATA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            SELECT data.id_concept_version,
                   data.id_cncpt_vrs_inst_owner,
                   data.id_concept_term,
                   data.id_cncpt_trm_inst_owner,
                   data.id_language,
                   data.id_institution,
                   data.id_software,
                   data.id_dep_clin_serv,
                   data.id_professional,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_dg,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_diagnosis,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_mh,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_medical,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_sh,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_surgical,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_pl,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_problems,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_ca,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_cong_anomalies,
                   (SELECT pk_api_diagnosis_func.get_ea_partial_desc_code(data.id_concept_term,
                                                                          data.id_cncpt_trm_inst_owner)
                      FROM dual) code_diagnosis_partial,
                   data.code concept_code,
                   data.num_attribute_01 mdm_coding,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_terminology(data.id_terminology)
                      FROM dual) flg_terminology,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_subtype(data.id_terminology,
                                                                    data.id_concept,
                                                                    data.id_concept_inst_owner,
                                                                    data.id_mct_inst_owner)
                      FROM dual) flg_subtype,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_diag_type(data.id_concept_term,
                                                                      data.id_cncpt_trm_inst_owner,
                                                                      data.id_mct_inst_owner)
                      FROM dual) flg_diag_type,
                   data.txt_attribute_01 flg_family,
                   decode(data.internal_name,
                          pk_api_diagnosis_func.g_ctt_int_name_pref,
                          pk_api_diagnosis_func.g_flg_preferred,
                          pk_api_diagnosis_func.g_ctt_int_name_syn,
                          pk_api_diagnosis_func.g_flg_synonym,
                          pk_api_diagnosis_func.g_ctt_int_name_rep,
                          pk_api_diagnosis_func.g_flg_reportable,
                          pk_api_diagnosis_func.g_empty_string) flg_icd9,
                   data.txt_attribute_02 flg_job,
                   data.flg_type flg_msi_concept_term,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_other(data.id_terminology,
                                                                  data.id_concept,
                                                                  data.id_concept_inst_owner,
                                                                  data.id_mct_inst_owner)
                      FROM dual) flg_other,
                   data.txt_attribute_03 flg_pos_birth,
                   data.txt_attribute_04 flg_select,
                   (SELECT pk_api_diagnosis_func.get_ea_concept_type_int_name(data.id_terminology,
                                                                              data.id_concept,
                                                                              data.id_concept_inst_owner,
                                                                              data.id_mct_inst_owner)
                      FROM dual) concept_type_int_name,
                   data.age_min,
                   data.age_max,
                   data.gender,
                   data.rank,
                   (SELECT pk_api_diagnosis_func.get_concept_path(data.id_concept,
                                                                  pk_api_diagnosis_func.g_id_concept_type_diag)
                      FROM dual) diagnosis_path,
                   (SELECT pk_api_diagnosis_func.is_diagnosis(i_concept_version      => data.id_concept_version,
                                                              i_cncpt_vrs_inst_owner => data.id_cncpt_vrs_inst_owner) flg_is_diagnosis
                      FROM dual),
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_de,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_death_event,
                   NULL migration_status
              BULK COLLECT
              INTO l_tbl_diag_ea
              FROM (SELECT /*+ no_merge */
                     a.id_concept_version,
                     a.id_cncpt_vrs_inst_owner,
                     a.id_concept_term,
                     a.id_cncpt_trm_inst_owner,
                     a.id_language,
                     a.id_institution,
                     a.id_software,
                     a.id_dep_clin_serv,
                     a.id_professional,
                     a.id_concept,
                     a.code,
                     a.id_concept_inst_owner,
                     a.id_terminology,
                     a.internal_name,
                     mcva.txt_attribute_01,
                     mcva.txt_attribute_02,
                     mcva.txt_attribute_03,
                     mcva.txt_attribute_04,
                     mcva.num_attribute_01,
                     nvl(a.age_min, mcva.age_min) age_min,
                     nvl(a.age_max, mcva.age_max) age_max,
                     nvl(a.gender, mcva.gender) gender,
                     a.id_mct_inst_owner,
                     a.flg_type,
                     a.rank,
                     -- Fields to check configured version
                     a.id_terminology_version,
                     a.version,
                     a.id_terminology_mkt
                      FROM (SELECT /*+ USE_NL(T TV) USE_NL(TV NCVA) INDEX(C CNCPT_SRCH1_IDX)*/
                             mct.id_concept_version,
                             mct.id_cncpt_vrs_inst_owner,
                             mct.id_concept_term,
                             mct.id_cncpt_trm_inst_owner,
                             tv.id_language,
                             c.id_concept,
                             c.code,
                             c.id_inst_owner             id_concept_inst_owner,
                             t.id_terminology,
                             ctt.internal_name,
                             mct.age_min,
                             mct.age_max,
                             mct.gender,
                             mct.id_inst_owner           id_mct_inst_owner,
                             mct.flg_type,
                             mct.rank,
                             mct.id_institution,
                             mct.id_software,
                             mct.id_dep_clin_serv,
                             mct.id_professional,
                             -- Fields to check configured version
                             tv.id_terminology_version,
                             tv.version,
                             tv.id_terminology_mkt
                              FROM (SELECT /*+ opt_estimate (table a rows=5)*/
                                    DISTINCT a.id_terminology,
                                             a.version,
                                             a.id_terminology_mkt,
                                             a.id_language,
                                             i_institution id_institution,
                                             t.id_software
                                      FROM (SELECT /*+ opt_estimate (table b rows=5)*/
                                             column_value id_software
                                              FROM TABLE(i_tbl_software) b) t
                                     CROSS JOIN TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => i_institution, i_soft => t.id_software)) a
                                     WHERE a.flg_active = pk_alert_constant.g_yes
                                       AND a.id_task_type IN (pk_mig_diagnosis.g_id_task_type_dg,
                                                              pk_mig_diagnosis.g_id_task_type_pl,
                                                              pk_mig_diagnosis.g_id_task_type_ca,
                                                              pk_mig_diagnosis.g_id_task_type_de)) mtv
                            --TERMINOLOGY_VERSION
                              JOIN terminology_version tv
                                ON tv.id_terminology = mtv.id_terminology
                               AND tv.version = mtv.version
                               AND tv.id_terminology_mkt = mtv.id_terminology_mkt
                               AND tv.id_language = mtv.id_language
                            --TERMINOLOGY
                              JOIN terminology t
                                ON t.id_terminology = tv.id_terminology
                            --CONCEPT_VERSION
                              JOIN concept_version cv
                                ON cv.id_terminology_version = tv.id_terminology_version
                            --CONCEPT
                              JOIN concept c
                                ON c.id_concept = cv.id_concept
                               AND c.id_inst_owner = cv.id_concept_inst_owner
                               AND c.id_terminology = t.id_terminology
                            --MSI_CONCEPT_TERM
                              JOIN msi_concept_term mct
                                ON mct.id_concept_version = cv.id_concept_version
                               AND mct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                               AND mct.id_institution = mtv.id_institution
                               AND mct.id_software = mtv.id_software
                               AND mct.flg_active = pk_alert_constant.g_yes
                            --CONCEPT_TERM
                              JOIN concept_term ct
                                ON ct.id_concept_vers_start = cv.id_concept_version
                               AND ct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                               AND ct.id_concept_term = mct.id_concept_term
                               AND ct.id_inst_owner = mct.id_cncpt_trm_inst_owner
                               AND ct.id_concept_vers_start = mct.id_concept_version
                               AND ct.id_concept_vers_end = mct.id_concept_version
                               AND ct.id_cncpt_vrs_inst_owner = mct.id_cncpt_vrs_inst_owner
                               AND ct.flg_available = pk_alert_constant.g_yes
                            --CONCEPT_TERM_TYPE
                              JOIN concept_term_type ctt
                                ON ctt.id_concept_term_type = ct.id_concept_term_type
                               AND ctt.internal_name IN (pk_api_diagnosis_func.g_ctt_int_name_pref,
                                                         pk_api_diagnosis_func.g_ctt_int_name_syn,
                                                         pk_api_diagnosis_func.g_ctt_int_name_rep)) a
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = a.id_dep_clin_serv
                      LEFT JOIN department d
                        ON d.id_department = dcs.id_department
                    -- [msi_cncpt_vers_attrib]
                      JOIN msi_cncpt_vers_attrib mcva
                        ON mcva.id_terminology_version = a.id_terminology_version
                       AND mcva.id_concept = a.id_concept
                       AND mcva.id_concept_inst_owner = a.id_concept_inst_owner
                          -- Joins with MSI_CONCEPT_TERM required to match configurations
                       AND mcva.id_institution = a.id_institution
                       AND mcva.id_software = a.id_software
                       AND mcva.flg_active = pk_alert_constant.g_yes) data;
        
            g_error := 'INSERT DIAG DATA INTO DIAGNOSIS_EA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            ts_diagnosis_ea.ins(rows_in => l_tbl_diag_ea);
        END insert_data_in_diag_ea;
    
        PROCEDURE ins_past_hist_in_diag_ea IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'INSERT_DATA_IN_DIAG_EA';
            --
            l_cat_all    CONSTANT category.id_category%TYPE := -1;
            l_cat_doctor CONSTANT category.id_category%TYPE := 1;
            --            
            l_tbl_diag_ea ts_diagnosis_ea.diagnosis_ea_tc;
        BEGIN
            g_error := 'GET PAST_HIST DATA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            SELECT data.id_concept_version id_concept_version,
                   data.id_cncpt_vrs_inst_owner id_cncpt_vrs_inst_owner,
                   data.id_concept_term id_concept_term,
                   data.id_cncpt_trm_inst_owner id_cncpt_trm_inst_owner,
                   data.id_language,
                   pk_alert_constant.g_inst_all id_institution,
                   pk_alert_constant.g_soft_all id_software,
                   data.id_dep_clin_serv id_dep_clin_serv,
                   data.id_professional id_professional,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_dg,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_diagnosis,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_mh,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_medical,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_sh,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_surgical,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_pl,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_problems,
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_ca,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_cong_anomalies,
                   (SELECT pk_api_diagnosis_func.get_ea_partial_desc_code(data.id_concept_term,
                                                                          data.id_cncpt_trm_inst_owner)
                      FROM dual) code_diagnosis_partial,
                   data.code concept_code,
                   data.num_attribute_01 mdm_coding,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_terminology(data.id_terminology)
                      FROM dual) flg_terminology,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_subtype(data.id_terminology,
                                                                    data.id_concept,
                                                                    data.id_concept_inst_owner,
                                                                    data.id_mct_inst_owner)
                      FROM dual) flg_subtype,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_diag_type(data.id_concept_term,
                                                                      data.id_cncpt_trm_inst_owner,
                                                                      data.id_mct_inst_owner)
                      FROM dual) flg_diag_type,
                   data.txt_attribute_01 flg_family,
                   decode(data.internal_name,
                          pk_api_diagnosis_func.g_ctt_int_name_pref,
                          pk_api_diagnosis_func.g_flg_preferred,
                          pk_api_diagnosis_func.g_ctt_int_name_syn,
                          pk_api_diagnosis_func.g_flg_synonym,
                          pk_api_diagnosis_func.g_ctt_int_name_rep,
                          pk_api_diagnosis_func.g_flg_reportable,
                          pk_api_diagnosis_func.g_empty_string) flg_icd9,
                   data.txt_attribute_02 flg_job,
                   data.flg_type flg_msi_concept_term,
                   (SELECT pk_api_diagnosis_func.get_ea_flg_other(data.id_terminology,
                                                                  data.id_concept,
                                                                  data.id_concept_inst_owner,
                                                                  data.id_mct_inst_owner)
                      FROM dual) flg_other,
                   data.txt_attribute_03 flg_pos_birth,
                   data.txt_attribute_04 flg_select,
                   (SELECT pk_api_diagnosis_func.get_ea_concept_type_int_name(data.id_terminology,
                                                                              data.id_concept,
                                                                              data.id_concept_inst_owner,
                                                                              data.id_mct_inst_owner)
                      FROM dual) concept_type_int_name,
                   data.age_min age_min,
                   data.age_max age_max,
                   data.gender gender,
                   data.rank rank,
                   (SELECT pk_api_diagnosis_func.get_concept_path(data.id_concept,
                                                                  pk_api_diagnosis_func.g_id_concept_type_diag)
                      FROM dual) diagnosis_path,
                   (SELECT pk_api_diagnosis_func.is_diagnosis(i_concept_version      => data.id_concept_version,
                                                              i_cncpt_vrs_inst_owner => data.id_cncpt_vrs_inst_owner) flg_is_diagnosis
                      FROM dual),
                   (SELECT pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                data.id_cncpt_trm_inst_owner,
                                                                                pk_api_diagnosis_func.g_id_task_type_de,
                                                                                data.id_mct_inst_owner)
                      FROM dual) code_death_event,
                   NULL migration_status
              BULK COLLECT
              INTO l_tbl_diag_ea
              FROM (SELECT /*+ no_merge*/
                     mct.id_concept_version,
                     mct.id_cncpt_vrs_inst_owner,
                     mct.id_concept_term,
                     mct.id_cncpt_trm_inst_owner,
                     tv.id_language,
                     c.id_concept,
                     c.code,
                     c.id_inst_owner id_concept_inst_owner,
                     t.id_terminology,
                     ctt.internal_name,
                     mcva.txt_attribute_01,
                     mcva.txt_attribute_02,
                     mcva.txt_attribute_03,
                     mcva.txt_attribute_04,
                     mcva.num_attribute_01,
                     nvl(mct.age_min, mcva.age_min) age_min,
                     nvl(mct.age_max, mcva.age_max) age_max,
                     nvl(mct.gender, mcva.gender) gender,
                     mct.id_inst_owner id_mct_inst_owner,
                     mct.flg_type,
                     mct.rank,
                     mct.id_institution,
                     mct.id_software,
                     mct.id_dep_clin_serv,
                     mct.id_professional,
                     -- Fields to check configured version
                     tv.id_terminology_version,
                     tv.version,
                     tv.id_terminology_mkt
                      FROM msi_concept_term mct -- [MSI_CONCEPT_TERM]
                    -- [CONCEPT_TERM]
                      JOIN concept_term ct
                        ON ct.id_concept_term = mct.id_concept_term
                       AND ct.id_inst_owner = mct.id_cncpt_trm_inst_owner
                       AND ct.id_concept_vers_start = mct.id_concept_version
                       AND ct.id_concept_vers_end = mct.id_concept_version
                       AND ct.id_cncpt_vrs_inst_owner = mct.id_cncpt_vrs_inst_owner
                       AND ct.flg_available = pk_alert_constant.g_yes
                    -- [CONCEPT_TERM_TYPE]
                      JOIN concept_term_type ctt
                        ON ctt.id_concept_term_type = ct.id_concept_term_type
                       AND ctt.internal_name IN (pk_api_diagnosis_func.g_ctt_int_name_pref,
                                                 pk_api_diagnosis_func.g_ctt_int_name_syn,
                                                 pk_api_diagnosis_func.g_ctt_int_name_rep)
                    -- [CONCEPT_VERSION]
                      JOIN concept_version cv
                        ON cv.id_concept_version = ct.id_concept_vers_start
                       AND cv.id_concept_version = ct.id_concept_vers_end
                       AND cv.id_inst_owner = ct.id_cncpt_vrs_inst_owner
                    -- [TERMINOLOGY_VERSION]
                      JOIN terminology_version tv
                        ON tv.id_terminology_version = cv.id_terminology_version
                    -- [TERMINOLOGY]
                      JOIN terminology t
                        ON t.id_terminology = tv.id_terminology
                    -- [CONCEPT]
                      JOIN concept c
                        ON c.id_concept = cv.id_concept
                       AND c.id_inst_owner = cv.id_concept_inst_owner
                       AND c.id_terminology = t.id_terminology
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = mct.id_dep_clin_serv
                      LEFT JOIN department d
                        ON d.id_department = dcs.id_department
                    -- [msi_cncpt_vers_attrib]
                      JOIN msi_cncpt_vers_attrib mcva
                        ON mcva.id_terminology_version = cv.id_terminology_version
                       AND mcva.id_concept = cv.id_concept
                       AND mcva.id_concept_inst_owner = cv.id_concept_inst_owner
                          -- Joins with MSI_CONCEPT_TERM required to match configurations
                       AND mcva.id_institution = mct.id_institution
                       AND mcva.id_software = mct.id_software
                       AND mcva.flg_active = pk_alert_constant.g_yes
                     WHERE mct.flg_type = pk_ea_logic_diagnosis.g_past_hist_diag_type
                       AND mct.flg_active = pk_alert_constant.g_yes
                       AND mct.id_institution = pk_alert_constant.g_inst_all
                          --category filter
                          --AND mcva.id_category IN (l_cat_all, l_cat_doctor)
                          --AND mct.id_category IN (l_cat_all, l_cat_doctor)
                          -- Only insert diagnosis of terminologies in use
                       AND t.id_terminology IN (SELECT /*+opt_estimate (table a rows=10)*/
                                                 column_value id_terminology
                                                  FROM TABLE(l_tbl_past_hist_id_terms) a)) data;
        
            g_error := 'INSERT PAST_HIST DATA INTO DIAGNOSIS_EA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            ts_diagnosis_ea.ins(rows_in => l_tbl_diag_ea);
        END ins_past_hist_in_diag_ea;
    
        PROCEDURE ins_data_in_diag_rel_ea IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'INS_DATA_IN_DIAG_REL_EA';
            --            
            l_tbl_diag_rel_ea ts_diagnosis_relations_ea.diagnosis_relations_ea_tc;
        BEGIN
            g_error := 'GET DIAG_REL DATA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            SELECT cv_start1.id_concept_version id_concept_version_1,
                   cv_start1.id_inst_owner      id_cncpt_vrs_inst_own1,
                   ct1.internal_name            concept_type_int_name1,
                   cv_start2.id_concept_version id_concept_version_2,
                   cv_start2.id_inst_owner      id_cncpt_vrs_inst_own2,
                   ct2.internal_name            concept_type_int_name2,
                   crt.internal_name            cncpt_rel_type_int_name,
                   mcr.id_institution           id_institution,
                   mcr.id_software              id_software,
                   mcr.rank                     rank,
                   mcr.flg_default              flg_default
              BULK COLLECT
              INTO l_tbl_diag_rel_ea
              FROM msi_concept_relation mcr -- [ MSI_CONCEPT_RELATION ]            
              JOIN concept_relation cr -- [ CONCEPT_RELATION ]
                ON cr.id_term_vers_start1 = mcr.id_term_vers_start1
               AND cr.id_concept1 = mcr.id_concept1
               AND cr.id_concept_inst_owner1 = mcr.id_concept_inst_owner1
               AND cr.id_term_vers_start2 = mcr.id_term_vers_start2
               AND cr.id_concept2 = mcr.id_concept2
               AND cr.id_concept_inst_owner2 = mcr.id_concept_inst_owner2
               AND cr.id_concept_rel_type = mcr.id_concept_rel_type
               AND cr.flg_available = pk_alert_constant.g_yes
              JOIN concept_rel_type crt -- [ CONCEPT_REL_TYPE ]
                ON crt.id_concept_rel_type = cr.id_concept_rel_type
            -- CONCEPT 1 --
              JOIN concept_version cv_start1 -- [ CONCEPT_VERSION 1 ]
                ON cv_start1.id_terminology_version = cr.id_term_vers_start1
               AND cv_start1.id_concept = cr.id_concept1
               AND cv_start1.id_concept_inst_owner = cr.id_concept_inst_owner1
              JOIN concept c1 -- [ CONCEPT 1 ]
                ON c1.id_concept = cv_start1.id_concept
               AND c1.id_inst_owner = cv_start1.id_inst_owner
              JOIN concept_type_rel ctr1 -- [ CONCEPT_TYPE_REL 1 ]
                ON ctr1.id_concept = c1.id_concept
               AND ctr1.id_concept_inst_owner = c1.id_inst_owner
               AND ctr1.flg_main_concept_type = pk_alert_constant.g_yes -- Return only main concept types
              JOIN termin_concept_type tct1 -- [ TERMIN_CONCEPT_TYPE 1 ]
                ON tct1.id_terminology = ctr1.id_terminology
               AND tct1.id_concept_type = ctr1.id_concept_type
              JOIN concept_type ct1 -- [ CONCEPT_TYPE 1 ]
                ON ct1.id_concept_type = tct1.id_concept_type
            -- CONCEPT 2 --
              JOIN concept_version cv_start2 -- [ CONCEPT_VERSION 2 ]
                ON cv_start2.id_terminology_version = cr.id_term_vers_start2
               AND cv_start2.id_concept = cr.id_concept2
               AND cv_start2.id_concept_inst_owner = cr.id_concept_inst_owner2
              JOIN concept c2 -- [ CONCEPT 2 ]
                ON c2.id_concept = cv_start2.id_concept
               AND c2.id_inst_owner = cv_start2.id_inst_owner
              JOIN concept_type_rel ctr2 -- [ CONCEPT_TYPE_REL 2 ]
                ON ctr2.id_concept = c2.id_concept
               AND ctr2.id_concept_inst_owner = c2.id_inst_owner
               AND ctr2.flg_main_concept_type = pk_alert_constant.g_yes -- Return only main concept types
              JOIN termin_concept_type tct2 -- [ TERMIN_CONCEPT_TYPE 2 ]
                ON tct2.id_terminology = ctr2.id_terminology
               AND tct2.id_concept_type = ctr2.id_concept_type
              JOIN concept_type ct2 -- [ CONCEPT_TYPE 2 ]
                ON ct2.id_concept_type = tct2.id_concept_type
             WHERE mcr.flg_active = pk_alert_constant.g_yes
               AND (mcr.id_term_vers_start1, mcr.id_institution, mcr.id_software) IN
                   (SELECT tv.id_terminology_version, aux.id_institution, aux.id_software
                      FROM (SELECT /*+ opt_estimate (table a rows=5)*/
                            DISTINCT a.id_terminology,
                                     a.version,
                                     a.id_terminology_mkt,
                                     a.id_language,
                                     i_institution id_institution,
                                     t.id_software
                              FROM (SELECT /*+ opt_estimate (table b rows=5)*/
                                     column_value id_software
                                      FROM TABLE(i_tbl_software) b) t
                             CROSS JOIN TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => i_institution, i_soft => t.id_software)) a
                             WHERE a.flg_active = pk_alert_constant.g_yes) aux
                      JOIN terminology_version tv
                        ON tv.id_terminology = aux.id_terminology
                       AND tv.version = aux.version
                       AND tv.id_terminology_mkt = aux.id_terminology_mkt
                       AND tv.id_language = aux.id_language)
               AND (mcr.id_term_vers_start2, mcr.id_institution, mcr.id_software) IN
                   (SELECT tv.id_terminology_version, aux.id_institution, aux.id_software
                      FROM (SELECT /*+ opt_estimate (table a rows=5)*/
                            DISTINCT a.id_terminology,
                                     a.version,
                                     a.id_terminology_mkt,
                                     a.id_language,
                                     i_institution id_institution,
                                     t.id_software
                              FROM (SELECT /*+ opt_estimate (table b rows=5)*/
                                     column_value id_software
                                      FROM TABLE(i_tbl_software) b) t
                             CROSS JOIN TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => i_institution, i_soft => t.id_software)) a
                             WHERE a.flg_active = pk_alert_constant.g_yes) aux
                      JOIN terminology_version tv
                        ON tv.id_terminology = aux.id_terminology
                       AND tv.version = aux.version
                       AND tv.id_terminology_mkt = aux.id_terminology_mkt
                       AND tv.id_language = aux.id_language)
             ORDER BY mcr.id_concept1, mcr.id_concept_inst_owner1, mcr.id_term_vers_start1;
        
            g_error := 'INSERT DIAG_REL DATA INTO DIAGNOSIS_RELATIONS_EA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            ts_diagnosis_relations_ea.ins(rows_in => l_tbl_diag_rel_ea);
        END ins_data_in_diag_rel_ea;
    
        PROCEDURE insert_data_in_diag_cfg_ea IS
            l_inner_func CONSTANT VARCHAR2(200 CHAR) := 'INSERT_DATA_IN_DIAG_CFG_EA';
            --
            c_tt_int_name_problems CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'Problems';
            c_tt_int_name_surghist CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'SurgicalHistory';
            c_tt_int_name_medhist  CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'Medicalhistory';
            c_tt_int_name_diag     CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'Diagnoses';
            c_tt_int_name_conganom CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'CongenitalAnomalies';
            c_tt_int_name_death_ev CONSTANT diagnosis_conf_ea.task_type_internal_name%TYPE := 'DeathEvent';
            --
            l_tbl_diag_conf_ea ts_diagnosis_conf_ea.diagnosis_conf_ea_tc;
        BEGIN
            g_error := 'GET DIAG DATA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            SELECT pk_api_diagnosis_func.get_ea_flg_terminology(c.id_terminology) flg_terminology,
                   c.id_language,
                   c.id_task_type,
                   decode(c.id_task_type,
                          pk_mig_diagnosis.g_id_task_type_pl,
                          c_tt_int_name_problems,
                          pk_mig_diagnosis.g_id_task_type_sh,
                          c_tt_int_name_surghist,
                          pk_mig_diagnosis.g_id_task_type_mh,
                          c_tt_int_name_medhist,
                          pk_mig_diagnosis.g_id_task_type_dg,
                          c_tt_int_name_diag,
                          pk_mig_diagnosis.g_id_task_type_ca,
                          c_tt_int_name_conganom,
                          pk_mig_diagnosis.g_id_task_type_de,
                          c_tt_int_name_death_ev) task_type_internal_name,
                   c.id_institution,
                   c.id_software
              BULK COLLECT
              INTO l_tbl_diag_conf_ea
              FROM (SELECT DISTINCT a.id_terminology,
                                    a.version,
                                    a.id_terminology_mkt,
                                    a.id_language,
                                    a.id_task_type,
                                    i_institution id_institution,
                                    t.id_software
                      FROM ((SELECT /*+ opt_estimate (table b rows=5)*/
                              column_value id_software
                               FROM TABLE(i_tbl_software) b)) t
                     CROSS JOIN TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => i_institution, i_soft => t.id_software)) a
                     WHERE a.flg_active = pk_alert_constant.g_yes
                       AND a.id_task_type IN (pk_mig_diagnosis.g_id_task_type_dg,
                                              pk_mig_diagnosis.g_id_task_type_pl,
                                              pk_mig_diagnosis.g_id_task_type_ca,
                                              pk_mig_diagnosis.g_id_task_type_mh,
                                              pk_mig_diagnosis.g_id_task_type_sh,
                                              pk_mig_diagnosis.g_id_task_type_de)) c
             WHERE EXISTS (SELECT 1
                      FROM terminology_version tv
                      JOIN concept_version cv
                        ON cv.id_terminology_version = tv.id_terminology_version
                     WHERE tv.id_terminology = c.id_terminology
                       AND tv.version = c.version
                       AND tv.id_terminology_mkt = c.id_terminology_mkt
                       AND tv.id_language = c.id_language
                       AND pk_api_diagnosis_func.is_diagnosis(i_concept_version      => cv.id_concept_version,
                                                              i_cncpt_vrs_inst_owner => cv.id_inst_owner) =
                           pk_alert_constant.g_yes)
             ORDER BY id_task_type, flg_terminology, id_language, id_institution, id_software;
        
            g_error := 'INSERT DIAG DATA INTO DIAGNOSIS_CONF_EA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_inner_func);
            ts_diagnosis_conf_ea.ins(rows_in => l_tbl_diag_conf_ea);
        END insert_data_in_diag_cfg_ea;
    BEGIN
        g_error := 'GET PAST HIST TERMINOLOGIES';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT mtv.id_terminology, pk_api_diagnosis_func.get_ea_flg_terminology(mtv.id_terminology) flg_terminology
          BULK COLLECT
          INTO l_tbl_past_hist_id_terms, l_tbl_past_hist_flg_terms
          FROM (SELECT /*+ opt_estimate (table a rows=10)*/
                DISTINCT a.id_terminology,
                         a.version,
                         a.id_terminology_mkt,
                         a.id_language,
                         i_institution                id_institution,
                         pk_alert_constant.g_soft_all id_software
                  FROM TABLE(pk_api_diagnosis_func.tf_msi_concept_version(i_inst => i_institution,
                                                                          i_soft => pk_alert_constant.g_soft_all)) a
                 WHERE a.flg_active = pk_alert_constant.g_yes
                   AND a.id_task_type IN (pk_mig_diagnosis.g_id_task_type_sh, pk_mig_diagnosis.g_id_task_type_mh)) mtv;
    
        g_error := 'SELECT DIAGNOSIS_EA ROWS THAT WILL BE DELETED FOR INST: ' || i_institution || '; SOFT: ' ||
                   pk_utils.concat_table(i_tbl_software);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ROWID
          BULK COLLECT
          INTO l_tbl_aux1_rows
          FROM diagnosis_ea d
         WHERE d.id_institution = i_institution
           AND d.id_software IN (SELECT column_value id_software
                                   FROM TABLE(i_tbl_software));
    
        g_error := 'SELECT DIAGNOSIS_EA ROWS THAT WILL BE DELETED - USED IN PAST HIST';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ROWID
          BULK COLLECT
          INTO l_tbl_aux2_rows
          FROM diagnosis_ea d
         WHERE d.flg_msi_concept_term = pk_ea_logic_diagnosis.g_past_hist_diag_type
           AND d.id_institution = pk_alert_constant.g_inst_all
           AND d.flg_terminology IN (SELECT column_value flg_terminology
                                       FROM TABLE(l_tbl_past_hist_flg_terms));
    
        g_error := 'L_TBL_DIAG_EA_ROWS - MULTISET UNION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_tbl_diag_ea_rows := l_tbl_aux1_rows MULTISET UNION l_tbl_aux2_rows;
    
        g_error := 'SELECT DIAGNOSIS_RELATION_EA ROWS THAT WILL BE DELETED FOR INST: ' || i_institution || '; SOFT: ' ||
                   pk_utils.concat_table(i_tbl_software);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ROWID
          BULK COLLECT
          INTO l_tbl_diag_rel_ea_rows
          FROM diagnosis_relations_ea d
         WHERE d.id_institution = i_institution
           AND d.id_software IN (SELECT column_value id_software
                                   FROM TABLE(i_tbl_software));
    
        l_tbl_software := i_tbl_software;
        l_tbl_software.extend;
        l_tbl_software(l_tbl_software.count) := pk_alert_constant.g_soft_all;
    
        g_error := 'SELECT DIAGNOSIS_CONF_EA ROWS THAT WILL BE DELETED FOR INST: ' || i_institution || '; SOFT: ' ||
                   pk_utils.concat_table(i_tbl_software);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ROWID
          BULK COLLECT
          INTO l_tbl_diag_conf_ea_rows
          FROM diagnosis_conf_ea d
         WHERE d.id_institution = i_institution
           AND d.id_software IN (SELECT column_value id_software
                                   FROM TABLE(l_tbl_software));
    
        --reset var
        l_tbl_software := i_tbl_software;
    
        IF i_commit
        THEN
            g_error := 'DISABLE DIAGNOSIS_EA PK, FKs AND INDEXs';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            pk_frmw.disable_index_bulk(i_table_name   => table_varchar(g_diagnosis_ea,
                                                                       g_diagnosis_relations_ea,
                                                                       g_diagnosis_conf_ea),
                                       i_disable_fk   => TRUE,
                                       i_disable_pk   => TRUE,
                                       i_disable_uk   => TRUE,
                                       i_disable_trig => TRUE,
                                       i_owner        => g_package_owner);
        END IF;
    
        g_error := 'CALL DELETE_DIAG_EA_ROWS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        delete_diag_ea_rows;
    
        g_error := 'CALL DELETE_DIAG_REL_EA_ROWS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        delete_diag_rel_ea_rows;
    
        g_error := 'CALL DELETE_DIAG_CONF_EA_ROWS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        delete_diag_conf_ea_rows;
    
        g_error := 'CALL INSERT_DATA_IN_DIAG_EA';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        insert_data_in_diag_ea;
    
        g_error := 'CALL INS_PAST_HIST_IN_DIAG_EA';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ins_past_hist_in_diag_ea;
    
        g_error := 'CALL INS_DATA_IN_DIAG_REL_EA';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ins_data_in_diag_rel_ea;
    
        g_error := 'CALL INSERT_DATA_IN_DIAG_CFG_EA';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        insert_data_in_diag_cfg_ea;
    
        IF i_commit
        THEN
            g_error := 'ENABLE DIAGNOSIS_EA PK, FKs AND INDEXs';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            enable_index_bulk(i_table_name   => table_varchar(g_diagnosis_ea,
                                                              g_diagnosis_relations_ea,
                                                              g_diagnosis_conf_ea),
                              i_enable_fk    => TRUE,
                              i_enable_pk    => TRUE,
                              i_enable_uk    => TRUE,
                              i_disable_trig => TRUE,
                              i_owner        => g_package_owner);
        END IF;
    
        dbms_stats.gather_table_stats(ownname          => 'ALERT',
                                      tabname          => 'DIAGNOSIS_EA',
                                      estimate_percent => 100,
                                      method_opt       => 'for all columns size 1 for all indexed columns size auto',
                                      no_invalidate    => FALSE,
                                      degree           => 4);
    
        dbms_stats.gather_table_stats(ownname          => 'ALERT',
                                      tabname          => 'DIAGNOSIS_RELATIONS_EA',
                                      estimate_percent => 100,
                                      method_opt       => 'for all columns size 1 for all indexed columns size auto',
                                      no_invalidate    => FALSE,
                                      degree           => 4);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END rebuild_diagnosis_ea;
BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ea_logic_diagnosis;
/
