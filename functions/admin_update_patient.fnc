CREATE OR REPLACE FUNCTION admin_update_patient
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
    l_epis t_episode_tab;
    l_pat  t_patient_tab;

    l_count             NUMBER := 0;
    l_current_timestamp TIMESTAMP WITH TIME ZONE := current_timestamp;
    l_validation_type   data_gov_invalid_recs.validation_type%TYPE;
    l_no_errors_found   BOOLEAN := TRUE;
    ins_invalid_record_error EXCEPTION;

    -- create an exception handler for ORA-24381
    l_errors NUMBER;
    l_error  VARCHAR2(4000);
    l_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(l_dml_errors, -24381);

    CURSOR c_episode IS
        SELECT ep.id_episode, ep.id_patient
          FROM episode ep
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL);

    CURSOR c_discharge_notes IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, dn.id_patient
          FROM episode ep, discharge_notes dn
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = dn.id_episode
           AND ep.id_patient != dn.id_patient;

    CURSOR c_epis_diagnosis IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, ed.id_patient
          FROM episode ep, epis_diagnosis ed
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = ed.id_episode
           AND ep.id_patient != ed.id_patient;

    CURSOR c_epis_diagram IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, ed.id_patient
          FROM episode ep, epis_diagram ed
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = ed.id_episode
           AND ep.id_patient != ed.id_patient;

    CURSOR c_epis_recomend IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, er.id_patient
          FROM episode ep, epis_recomend er
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = er.id_episode
           AND ep.id_patient != er.id_patient;

    CURSOR c_nurse_activity_req IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, nar.id_patient
          FROM episode ep, nurse_activity_req nar
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = nar.id_episode
           AND ep.id_patient != nar.id_patient;

    CURSOR c_monitorization IS
        SELECT ep.id_episode, ep.id_patient val_id_patient, mon.id_patient
          FROM episode ep, monitorization mon
         WHERE (ep.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL)
           AND ep.id_episode = mon.id_episode
           AND ep.id_patient != mon.id_patient;

BEGIN

    --Se for para validar os registos
    IF i_validate_table
    THEN
        FOR c_master_discharge_notes IN c_discharge_notes
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'DISCHARGE_NOTES',
                                                        i_id_pk_1_value       => c_master_discharge_notes.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_discharge_notes.id_episode,
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
        FOR c_master_epis_diagnosis IN c_epis_diagnosis
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'EPIS_DIAGNOSIS',
                                                        i_id_pk_1_value       => c_master_epis_diagnosis.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_epis_diagnosis.id_episode,
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
        FOR c_master_epis_diagram IN c_epis_diagram
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'EPIS_DIAGRAM',
                                                        i_id_pk_1_value       => c_master_epis_diagram.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_epis_diagram.id_episode,
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
        FOR c_master_epis_recomend IN c_epis_recomend
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'EPIS_RECOMEND',
                                                        i_id_pk_1_value       => c_master_epis_recomend.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_epis_recomend.id_episode,
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
        FOR c_master_nurse_activity_req IN c_nurse_activity_req
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'NURSE_ACTIVITY_REQ',
                                                        i_id_pk_1_value       => c_master_nurse_activity_req.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_nurse_activity_req.id_episode,
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
        FOR c_master_monitorization IN c_monitorization
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'MONITORIZATION',
                                                        i_id_pk_1_value       => c_master_monitorization.id_patient,
                                                        i_id_pk_1_col_name    => 'ID_PATIENT',
                                                        i_id_pk_2_value       => c_master_monitorization.id_episode,
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
    
    END IF;

    --Se for para actualizar/recriar as novas colunas
    IF i_recreate_table
    THEN
        l_error := 'UPDATE EPISODE';
        OPEN c_episode;
        LOOP
            --Actualiza/recria as novas colunas   
            FETCH c_episode BULK COLLECT
                INTO l_epis, l_pat LIMIT i_commit_step;
        
            l_error := 'UPDATE discharge_notes';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE discharge_notes dn
                   SET dn.id_patient = l_pat(i)
                 WHERE dn.id_episode = l_epis(i)
                   AND dn.id_patient IS NULL;
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE epis_diagnosis';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE epis_diagnosis ed
                   SET ed.id_patient = l_pat(i)
                 WHERE ed.id_episode = l_epis(i)
                   AND ed.id_patient IS NULL;
        
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE epis_diagram';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE epis_diagram edg
                   SET edg.id_patient = l_pat(i)
                 WHERE edg.id_episode = l_epis(i)
                   AND edg.id_patient IS NULL;
        
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE epis_recomend';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE epis_recomend er
                   SET er.id_patient = l_pat(i)
                 WHERE er.id_episode = l_epis(i)
                   AND er.id_patient IS NULL;
        
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE nurse_activity_req';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE nurse_activity_req nar
                   SET nar.id_patient = l_pat(i)
                 WHERE nar.id_episode = l_epis(i)
                   AND nar.id_patient IS NULL;
        
            dbms_output.put_line(l_error || ' - ' || SQL%ROWCOUNT || ' rows updated.');
            COMMIT;
        
            l_error := 'UPDATE monitorization';
            FORALL i IN l_epis.FIRST .. l_epis.LAST SAVE EXCEPTIONS
                UPDATE monitorization mon
                   SET mon.id_patient = l_pat(i)
                 WHERE mon.id_episode = l_epis(i)
                   AND mon.id_patient IS NULL;
        
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
END admin_update_patient;
/
