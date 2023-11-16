CREATE OR REPLACE FUNCTION admin_update_episode
(
    i_patient                IN NUMBER DEFAULT NULL,
    i_episode                IN NUMBER DEFAULT NULL,
    i_schedule               IN NUMBER DEFAULT NULL,
    i_external_request       IN NUMBER DEFAULT NULL,
    i_institution            IN NUMBER DEFAULT NULL,
    i_start_dt               IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    i_end_dt                 IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    i_validate_table         IN BOOLEAN DEFAULT TRUE,
    i_output_invalid_records IN BOOLEAN DEFAULT FALSE,
    i_recreate_table         IN BOOLEAN DEFAULT FALSE,
    i_commit_step            IN NUMBER DEFAULT 1000
) RETURN BOOLEAN IS

    -- Migration script for update_episode
    TYPE t_episode_tab IS TABLE OF episode.id_episode%TYPE;
    TYPE t_patient_tab IS TABLE OF visit.id_patient%TYPE;
    l_count NUMBER := 0;
    l_epis  t_episode_tab;
    l_pat   t_patient_tab;

    -- create an exception handler for ORA-24381
    l_validation_type   data_gov_invalid_recs.validation_type%TYPE;
    l_current_timestamp TIMESTAMP WITH TIME ZONE := current_timestamp;
    l_errors            NUMBER;
    l_error             VARCHAR2(4000);
    l_dml_errors EXCEPTION;
    ins_invalid_record_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(l_dml_errors, -24381);

    CURSOR c_episode IS
        SELECT ep.id_episode, ep.id_patient
          FROM episode ep
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL);

    CURSOR c_care_plan IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, care_plan cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_clin_record IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, clin_record cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_event_most_freq IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, event_most_freq cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_p1_external_request IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, p1_external_request cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_p1_match IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, p1_match cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_child_feed_dev IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_child_feed_dev cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_cli_attributes IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_cli_attributes cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_dmgr_hist IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_dmgr_hist cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_family_member IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_family_member cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_family_prof IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_family_prof cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_graffar_crit IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_graffar_crit cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_health_plan IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_health_plan cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_history IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_history cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_job IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_job cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_medication_det IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_medication_det cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_necessity IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_necessity cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_soc_attributes IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_soc_attributes cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_vacc IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_vacc cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_pat_vaccine IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, pat_vaccine cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_sr_surgery_record IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, sr_surgery_record cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_unidose_car_patient IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, unidose_car_patient cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_unidose_car_patient_hist IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, unidose_car_patient_hist cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

    CURSOR c_vaccine_det IS
        SELECT ep.id_episode, cp.id_episode val_id_episode, ep.id_patient
          FROM episode ep, vaccine_det cp
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode != cp.id_episode
           AND ep.id_patient = cp.id_patient;

BEGIN
    --Se for para validar os registos
    IF i_validate_table
    THEN
        FOR c_master_care_plan IN c_care_plan
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'CARE_PLAN',
                                                        i_id_pk_1_value       => c_master_care_plan.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_care_plan.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        FOR c_master_clin_record IN c_clin_record
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'CLIN_RECORD',
                                                        i_id_pk_1_value       => c_master_clin_record.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_clin_record.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_event_most_freq IN c_event_most_freq
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'EVENT_MOST_FREQ',
                                                        i_id_pk_1_value       => c_master_event_most_freq.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_event_most_freq.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_p1_external_request IN c_p1_external_request
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'P1_EXTERNAL_REQUEST',
                                                        i_id_pk_1_value       => c_master_p1_external_request.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_p1_external_request.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_p1_match IN c_p1_match
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'P1_MATCH',
                                                        i_id_pk_1_value       => c_master_p1_match.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_p1_match.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_child_feed_dev IN c_pat_child_feed_dev
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_CHILD_FEED_DEV',
                                                        i_id_pk_1_value       => c_master_pat_child_feed_dev.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_child_feed_dev.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_cli_attributes IN c_pat_cli_attributes
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_CLI_ATTRIBUTES',
                                                        i_id_pk_1_value       => c_master_pat_cli_attributes.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_cli_attributes.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_dmgr_hist IN c_pat_dmgr_hist
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_DMGR_HIST',
                                                        i_id_pk_1_value       => c_master_pat_dmgr_hist.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_dmgr_hist.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_family_member IN c_pat_family_member
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_FAMILY_MEMBER',
                                                        i_id_pk_1_value       => c_master_pat_family_member.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_family_member.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_family_prof IN c_pat_family_prof
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_FAMILY_PROF',
                                                        i_id_pk_1_value       => c_master_pat_family_prof.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_family_prof.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_graffar_crit IN c_pat_graffar_crit
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_GRAFFAR_CRIT',
                                                        i_id_pk_1_value       => c_master_pat_graffar_crit.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_graffar_crit.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_health_plan IN c_pat_health_plan
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_HEALTH_PLAN',
                                                        i_id_pk_1_value       => c_master_pat_health_plan.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_health_plan.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_history IN c_pat_history
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_HISTORY',
                                                        i_id_pk_1_value       => c_master_pat_history.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_history.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_job IN c_pat_job
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_JOB',
                                                        i_id_pk_1_value       => c_master_pat_job.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_job.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_medication_det IN c_pat_medication_det
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_MEDICATION_DET',
                                                        i_id_pk_1_value       => c_master_pat_medication_det.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_medication_det.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_necessity IN c_pat_necessity
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_NECESSITY',
                                                        i_id_pk_1_value       => c_master_pat_necessity.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_necessity.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_vacc IN c_pat_vacc
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_VACC',
                                                        i_id_pk_1_value       => c_master_pat_vacc.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_vacc.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_pat_vaccine IN c_pat_vaccine
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'PAT_VACCINE',
                                                        i_id_pk_1_value       => c_master_pat_vaccine.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_pat_vaccine.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_sr_surgery_record IN c_sr_surgery_record
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'SR_SURGERY_RECORD',
                                                        i_id_pk_1_value       => c_master_sr_surgery_record.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_sr_surgery_record.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_unidose_car_patient IN c_unidose_car_patient
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'UNIDOSE_CAR_PATIENT',
                                                        i_id_pk_1_value       => c_master_unidose_car_patient.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_unidose_car_patient.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        FOR c_master_unidose_car_patient_h IN c_unidose_car_patient_hist
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'UNIDOSE_CAR_PATIENT_HIST',
                                                        i_id_pk_1_value       => c_master_unidose_car_patient_h.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_unidose_car_patient_h.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        --
        FOR c_master_vaccine_det IN c_vaccine_det
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'VACCINE_DET',
                                                        i_id_pk_1_value       => c_master_vaccine_det.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_vaccine_det.val_id_episode,
                                                        i_id_pk_2_col_name    => 'ID_EPISODE',
                                                        i_id_pk_3_value       => NULL,
                                                        i_id_pk_3_col_name    => NULL,
                                                        i_id_pk_4_value       => NULL,
                                                        i_id_pk_4_col_name    => NULL,
                                                        i_dt_validation       => l_current_timestamp,
                                                        i_validation_type     => l_validation_type,
                                                        i_in_patient          => i_patient,
                                                        i_in_episode          => i_episode,
                                                        i_in_schedule         => i_schedule,
                                                        i_in_external_request => i_external_request,
                                                        i_in_institution      => i_institution,
                                                        i_in_start_dt         => i_start_dt,
                                                        i_in_end_dt           => i_end_dt)
            THEN
                --Em caso de erro ao inserir registos inválidos, sai
                RAISE ins_invalid_record_error;
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;

    --Se for para actualizar/recriar as novas colunas
    IF i_recreate_table
    THEN
    
        l_error := 'UPDATE EPISODE';
        OPEN c_episode;
        LOOP
            FETCH c_episode BULK COLLECT
                INTO l_epis, l_pat LIMIT i_commit_step;
        
            l_error := 'UPDATE CARE_PLAN';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE care_plan cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE CLIN_RECORD';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE clin_record cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE EVENT_MOST_FREQ';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE event_most_freq cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE P1_EXTERNAL_REQUEST';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE p1_external_request cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE P1_MATCH';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE p1_match cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_CHILD_FEED_DEV';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_child_feed_dev cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_CLI_ATTRIBUTES';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_cli_attributes cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_DMGR_HIST';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_dmgr_hist cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_FAMILY_MEMBER';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_family_member cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_FAMILY_PROF';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_family_prof cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_GRAFFAR_CRIT';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_graffar_crit cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_HEALTH_PLAN';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_health_plan cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_HISTORY';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_history cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_JOB';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_job cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_MEDICATION_DET';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_medication_det cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_NECESSITY';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_necessity cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_SOC_ATTRIBUTES';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_soc_attributes cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_VACC';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_vacc cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE PAT_VACCINE';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE pat_vaccine cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE SR_SURGERY_RECORD';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE sr_surgery_record cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE UNIDOSE_CAR_PATIENT';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE unidose_car_patient cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE UNIDOSE_CAR_PATIENT_HIST';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE unidose_car_patient_hist cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE VACCINE_DET';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE vaccine_det cp
                   SET cp.id_episode = l_epis(i)
                 WHERE cp.id_patient = l_pat(i)
                   AND cp.id_episode IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            EXIT WHEN l_epis.COUNT = 0;
        
        END LOOP;
        CLOSE c_episode;
    
        dbms_output.put_line('OK: ' || l_count || ' linhas inseridas');
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN l_dml_errors THEN
        -- Now we figure out what failed and why.
        l_errors := SQL%BULK_EXCEPTIONS.COUNT;
        dbms_output.put_line('Number of statements that failed: ' || l_errors);
        FOR i IN 1 .. l_errors
        LOOP
            dbms_output.put_line('Error #' || i || ' occurred during ' || 'iteration #' || SQL%BULK_EXCEPTIONS(i)
                                 .ERROR_INDEX);
            dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).ERROR_CODE));
        END LOOP;
        ROLLBACK;
        RETURN FALSE;
    
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
        ROLLBACK;
        RETURN FALSE;
END admin_update_episode;
/
