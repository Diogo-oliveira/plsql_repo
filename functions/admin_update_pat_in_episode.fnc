CREATE OR REPLACE FUNCTION admin_update_pat_in_episode
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
    l_count             NUMBER := 0;
    l_current_timestamp TIMESTAMP WITH TIME ZONE := current_timestamp;
    l_validation_type   data_gov_invalid_recs.validation_type%TYPE;
    l_error             VARCHAR2(4000);
    l_no_errors_found   BOOLEAN := TRUE;
    ins_invalid_record_error EXCEPTION;

    CURSOR c_episode IS
        SELECT ep.id_episode, v.id_patient, nvl(ep.id_patient, -1) val_id_patient
          FROM episode ep, visit v
         WHERE ep.id_visit = v.id_visit
           AND (v.id_patient = i_patient OR i_patient IS NULL)
           AND (ep.id_episode = i_episode OR i_episode IS NULL)
           AND (ep.dt_begin_tstz >= i_start_dt OR i_start_dt IS NULL)
           AND (ep.dt_end_tstz <= i_end_dt OR i_end_dt IS NULL);

BEGIN

    l_error := 'UPDATE EPISODE';
    FOR c_master_episode IN c_episode
    LOOP
        --Se for para validar os registos
        IF i_validate_table --
           AND (c_master_episode.id_patient != c_master_episode.val_id_patient)
        THEN
            l_no_errors_found := FALSE;
            --Se for dada indicação da necessidade de guardar informação sobre registos inválidos,
            -- guarda-os na tabela criada para o efeito          
            IF i_output_invalid_records
            THEN
                l_validation_type := 2;
            
                IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'EPISODE',
                                                            i_id_pk_1_value       => c_master_episode.id_patient,
                                                            i_id_pk_1_col_name    => 'ID_PATIENT',
                                                            i_id_pk_2_value       => c_master_episode.id_episode,
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
            
            END IF;
        END IF;
    
        --Se for para actualizar/recriar as novas colunas
        IF i_recreate_table
        THEN
            --Actualiza/recria as novas colunas   
            UPDATE episode ep
               SET ep.id_patient = c_master_episode.id_patient
             WHERE ep.id_episode = c_master_episode.id_episode;
        END IF;
    
        --Commit
        l_count := l_count + 1;
        IF l_count >= i_commit_step
        THEN
            COMMIT;
            l_count := 0;
        END IF;
    
    END LOOP;

    dbms_output.put_line('OK: ' || l_count || ' linhas inseridas');
    RETURN TRUE;
EXCEPTION
    WHEN ins_invalid_record_error THEN
        dbms_output.put_line('Error while saving invalid records');
        ROLLBACK;
        RETURN FALSE;
    WHEN OTHERS THEN
        dbms_output.put_line(l_error || '-' || SQLERRM);
        ROLLBACK;
        RETURN FALSE;
END admin_update_pat_in_episode;
/
