CREATE OR REPLACE FUNCTION admin_vital_signs_ea
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
    i_commit_step            IN NUMBER DEFAULT 10000
) RETURN BOOLEAN IS

    -- Migration script for vital_signs_ea
    l_count                     NUMBER := 0;
    l_count_invalid             NUMBER := 0;
    l_id_monitorization_vs_plan monitorization_vs_plan.id_monitorization_vs_plan%TYPE;
    l_flg_status_plan           monitorization_vs_plan.flg_status%TYPE;
    l_dt_plan_tstz              monitorization_vs_plan.dt_plan_tstz%TYPE;
    l_aux                       VARCHAR2(4000);
    l_current_timestamp         TIMESTAMP WITH TIME ZONE := current_timestamp;
    l_validation_type           data_gov_invalid_recs.validation_type%TYPE;

    g_error VARCHAR2(4000);

    function_error EXCEPTION;
    ins_invalid_record_error EXCEPTION;
    invoking_external_prc_error EXCEPTION;

BEGIN
    -- Validate initial parameters
    IF NOT i_validate_table
       AND NOT i_recreate_table
    THEN
        RAISE function_error;
        -- IF NOT i_validate_table AND NOT i_recreate_table
    END IF;

    -- Se é para carregar os dados
    IF i_recreate_table
       AND NOT i_validate_table
    THEN
        -- cria tabela de backup
        -- rs ver se vale a pena fazer desta tabela!!!!!
    
        /*
        
        l_aux := 'CREATE TABLE vital_sign_' || to_char(l_current_timestamp, 'YYYYMMDD') ||
                 ' AS SELECT * FROM vital_sign';
        
        g_error := 'CREATE BACKUP TABLE VITAL_SIGN';
        dbms_output.put_line(g_error);
        EXECUTE IMMEDIATE l_aux;
        
        -- cria tabela de backup
        l_aux := 'CREATE TABLE vital_sign_read_' || to_char(l_current_timestamp, 'YYYYMMDD') ||
                 ' AS SELECT * FROM vital_sign_read ' || ' WHERE (id_patient = ' || i_patient || ' OR ' || i_patient ||
                 ' IS NULL) ' || ' AND (id_episode = ' || i_episode || ' OR ' || i_episode || ' IS NULL)';
        
        g_error := 'CREATE BACKUP TABLE VITAL_SIGN_READ';
        dbms_output.put_line(g_error);
        EXECUTE IMMEDIATE l_aux;
        
        -- cria tabela de backup
        -- rs ver se vale a pena fazer desta tabela!!!!!
        l_aux := 'CREATE TABLE vital_sign_relation_' || to_char(l_current_timestamp, 'YYYYMMDD') ||
                 ' AS SELECT * FROM vital_sign_relation';
        
        g_error := 'CREATE BACKUP TABLE VITAL_SIGN_RELATION';
        dbms_output.put_line(g_error);
        EXECUTE IMMEDIATE l_aux;
        
        */
    
        DELETE FROM vital_signs_ea
         WHERE (id_patient = i_patient OR i_patient IS NULL)
           AND (id_episode = i_episode OR i_episode IS NULL)
           AND (dt_dg_last_update >= i_start_dt OR i_start_dt IS NULL)
           AND (dt_dg_last_update <= i_end_dt OR i_end_dt IS NULL);
    
        COMMIT;
    
        --IF i_recreate_table AND NOT i_validate_table
    END IF;

    FOR rec IN (SELECT vsr.id_vital_sign      id_vital_sign,
                       vsr.id_vital_sign_read id_vital_sign_read,
                       vsr.id_vital_sign_desc id_vital_sign_desc,
                       --28 Blood Pressure
                       decode(vsr.id_vital_sign,
                              28,
                              pk_vital_sign.get_vital_sign_val_bp(vsr.id_vital_sign, vsr.id_episode),
                              vsr.VALUE) VALUE,
                       vsr.id_unit_measure id_unit_measure,
                       vsr.dt_vital_sign_read_tstz dt_vital_sign_read,
                       vsr.flg_pain flg_pain,
                       vsr.id_prof_read id_prof_read,
                       vsr.id_prof_cancel id_prof_cancel,
                       vsr.notes_cancel notes_cancel,
                       vsr.flg_state flg_state,
                       vsr.dt_cancel_tstz dt_cancel,
                       (SELECT vs.flg_available
                          FROM vital_sign vs
                         WHERE vs.id_vital_sign = vsr.id_vital_sign) flg_available,
                       vsr.id_institution_read id_institution_read,
                       (SELECT e.flg_status
                          FROM episode e
                         WHERE e.id_episode = vsr.id_episode) flg_status_epis,
                       (SELECT e.id_visit
                          FROM episode e
                         WHERE e.id_episode = vsr.id_episode) id_visit,
                       vsr.id_episode id_episode,
                       vsr.id_patient id_patient,
                       (SELECT vsrel.relation_domain
                          FROM vital_sign_relation vsrel
                        --Tem de ser o detail pois senão dá o erro do subquery retornar elementos a mais
                         WHERE vsrel.id_vital_sign_detail = vsr.id_vital_sign) relation_domain,
                       vsr.id_epis_triage id_epis_triage
                  FROM vital_sign_read vsr
                 WHERE (vsr.id_patient = i_patient OR i_patient IS NULL)
                   AND (vsr.id_episode = i_episode OR i_episode IS NULL)
                   AND (vsr.dt_vital_sign_read_tstz >= i_start_dt OR i_start_dt IS NULL)
                   AND (vsr.dt_vital_sign_read_tstz <= i_end_dt OR i_end_dt IS NULL)
                   AND vsr.dt_vital_sign_read_tstz =
                       (SELECT MAX(vsr1.dt_vital_sign_read_tstz)
                          FROM vital_sign_read vsr1
                         WHERE vsr1.id_vital_sign = vsr.id_vital_sign
                           AND vsr1.id_episode = vsr.id_episode))
    LOOP
    
        IF i_validate_table
        THEN
            -- insert into temporary table
            dbms_output.put_line('insert into temporary table:' || rec.id_vital_sign_read);
            INSERT INTO vital_signs_ea_tmp
                (id_vital_sign,
                 id_vital_sign_read,
                 id_vital_sign_desc,
                 VALUE,
                 id_unit_measure,
                 dt_vital_sign_read,
                 flg_pain,
                 id_prof_read,
                 id_prof_cancel,
                 notes_cancel,
                 flg_state,
                 dt_cancel,
                 flg_available,
                 id_institution_read,
                 flg_status_epis,
                 id_visit,
                 id_episode,
                 id_patient,
                 relation_domain,
                 id_epis_triage)
            VALUES
                (rec.id_vital_sign,
                 rec.id_vital_sign_read,
                 rec.id_vital_sign_desc,
                 rec.VALUE,
                 rec.id_unit_measure,
                 rec.dt_vital_sign_read,
                 rec.flg_pain,
                 rec.id_prof_read,
                 rec.id_prof_cancel,
                 rec.notes_cancel,
                 rec.flg_state,
                 rec.dt_cancel,
                 rec.flg_available,
                 rec.id_institution_read,
                 rec.flg_status_epis,
                 rec.id_visit,
                 rec.id_episode,
                 rec.id_patient,
                 rec.relation_domain,
                 rec.id_epis_triage);
        
            -- IF i_validate_table
        END IF;
    
        IF i_recreate_table
           AND NOT i_validate_table
        THEN
            dbms_output.put_line('insert into table:' || rec.id_vital_sign_read);
            INSERT INTO vital_signs_ea
                (id_vital_sign,
                 id_vital_sign_read,
                 id_vital_sign_desc,
                 VALUE,
                 id_unit_measure,
                 dt_vital_sign_read,
                 flg_pain,
                 id_prof_read,
                 id_prof_cancel,
                 notes_cancel,
                 flg_state,
                 dt_cancel,
                 flg_available,
                 id_institution_read,
                 flg_status_epis,
                 id_visit,
                 id_episode,
                 id_patient,
                 relation_domain,
                 id_epis_triage,
                 dt_dg_last_update)
            VALUES
                (rec.id_vital_sign,
                 rec.id_vital_sign_read,
                 rec.id_vital_sign_desc,
                 rec.VALUE,
                 rec.id_unit_measure,
                 rec.dt_vital_sign_read,
                 rec.flg_pain,
                 rec.id_prof_read,
                 rec.id_prof_cancel,
                 rec.notes_cancel,
                 rec.flg_state,
                 rec.dt_cancel,
                 rec.flg_available,
                 rec.id_institution_read,
                 rec.flg_status_epis,
                 rec.id_visit,
                 rec.id_episode,
                 rec.id_patient,
                 rec.relation_domain,
                 rec.id_epis_triage,
                 l_current_timestamp);
        
            -- IF i_recreate_table AND NOT i_validate_table
        END IF;
    
        IF MOD(l_count, i_commit_step) = 0
        THEN
            COMMIT;
        END IF;
    
        l_count := l_count + 1;
    
    END LOOP;
    COMMIT;

    -- dbms_output.put_line('OK: ' || l_count || ' inserted records');

    IF i_validate_table
    THEN
        -- compares and saves on table DATA_GOV_INVALID_RECS
    
        -- the ones that are diferent
        FOR rec1 IN (SELECT b.id_vital_sign_read id_vs_tmp
                       FROM vital_signs_ea a, vital_signs_ea_tmp b
                      WHERE a.id_vital_sign_read = b.id_vital_sign_read
                        AND ((a.id_vital_sign <> b.id_vital_sign OR
                            (a.id_vital_sign IS NULL AND b.id_vital_sign IS NOT NULL) OR
                            (a.id_vital_sign IS NOT NULL AND b.id_vital_sign IS NULL)) OR
                            (a.id_vital_sign_desc <> b.id_vital_sign_desc OR
                            (a.id_vital_sign_desc IS NULL AND b.id_vital_sign_desc IS NOT NULL) OR
                            (a.id_vital_sign_desc IS NOT NULL AND b.id_vital_sign_desc IS NULL)) OR
                            (a.VALUE <> b.VALUE OR (a.VALUE IS NULL AND b.VALUE IS NOT NULL) OR
                            (a.VALUE IS NOT NULL AND b.VALUE IS NULL)) OR
                            (a.id_unit_measure <> b.id_unit_measure OR
                            (a.id_unit_measure IS NULL AND b.id_unit_measure IS NOT NULL) OR
                            (a.id_unit_measure IS NOT NULL AND b.id_unit_measure IS NULL)) OR
                            (a.dt_vital_sign_read <> b.dt_vital_sign_read OR
                            (a.dt_vital_sign_read IS NULL AND b.dt_vital_sign_read IS NOT NULL) OR
                            (a.dt_vital_sign_read IS NOT NULL AND b.dt_vital_sign_read IS NULL)) OR
                            (a.flg_pain <> b.flg_pain OR (a.flg_pain IS NULL AND b.flg_pain IS NOT NULL) OR
                            (a.flg_pain IS NOT NULL AND b.flg_pain IS NULL)) OR
                            (a.id_prof_read <> b.id_prof_read OR
                            (a.id_prof_read IS NULL AND b.id_prof_read IS NOT NULL) OR
                            (a.id_prof_read IS NOT NULL AND b.id_prof_read IS NULL)) OR
                            (a.id_prof_cancel <> b.id_prof_cancel OR
                            (a.id_prof_cancel IS NULL AND b.id_prof_cancel IS NOT NULL) OR
                            (a.id_prof_cancel IS NOT NULL AND b.id_prof_cancel IS NULL)) OR
                            (a.notes_cancel <> b.notes_cancel OR
                            (a.notes_cancel IS NULL AND b.notes_cancel IS NOT NULL) OR
                            (a.notes_cancel IS NOT NULL AND b.notes_cancel IS NULL)) OR
                            (a.flg_state <> b.flg_state OR (a.flg_state IS NULL AND b.flg_state IS NOT NULL) OR
                            (a.flg_state IS NOT NULL AND b.flg_state IS NULL)) OR
                            (a.dt_cancel <> b.dt_cancel OR (a.dt_cancel IS NULL AND b.dt_cancel IS NOT NULL) OR
                            (a.dt_cancel IS NOT NULL AND b.dt_cancel IS NULL)) OR
                            (a.flg_available <> b.flg_available OR
                            (a.flg_available IS NULL AND b.flg_available IS NOT NULL) OR
                            (a.flg_available IS NOT NULL AND b.flg_available IS NULL)) OR
                            (a.id_institution_read <> b.id_institution_read OR
                            (a.id_institution_read IS NULL AND b.id_institution_read IS NOT NULL) OR
                            (a.id_institution_read IS NOT NULL AND b.id_institution_read IS NULL)) OR
                            (a.flg_status_epis <> b.flg_status_epis OR
                            (a.flg_status_epis IS NULL AND b.flg_status_epis IS NOT NULL) OR
                            (a.flg_status_epis IS NOT NULL AND b.flg_status_epis IS NULL)) OR
                            (a.id_visit <> b.id_visit OR (a.id_visit IS NULL AND b.id_visit IS NOT NULL) OR
                            (a.id_visit IS NOT NULL AND b.id_visit IS NULL)) OR
                            (a.id_episode <> b.id_episode OR (a.id_episode IS NULL AND b.id_episode IS NOT NULL) OR
                            (a.id_episode IS NOT NULL AND b.id_episode IS NULL)) OR
                            (a.id_patient <> b.id_patient OR (a.id_patient IS NULL AND b.id_patient IS NOT NULL) OR
                            (a.id_patient IS NOT NULL AND b.id_patient IS NULL)) OR
                            (a.relation_domain <> b.relation_domain OR
                            (a.relation_domain IS NULL AND b.relation_domain IS NOT NULL) OR
                            (a.relation_domain IS NOT NULL AND b.relation_domain IS NULL)) OR
                            (a.id_epis_triage <> b.id_epis_triage OR
                            (a.id_epis_triage IS NULL AND b.id_epis_triage IS NOT NULL) OR
                            (a.id_epis_triage IS NOT NULL AND b.id_epis_triage IS NULL))))
        LOOP
            l_validation_type := 2;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'VITAL_SIGNS_EA',
                                                        i_id_pk_1_value       => rec1.id_vs_tmp,
                                                        i_id_pk_1_col_name    => 'ID_VITAL_SIGN_READ',
                                                        i_id_pk_2_value       => NULL,
                                                        i_id_pk_2_col_name    => NULL,
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
            
                RAISE ins_invalid_record_error;
            END IF;
        
            l_count_invalid := l_count_invalid + 1;
        
        END LOOP;
        COMMIT;
    
        --the ones that are missing
        FOR rec2 IN (SELECT vs_ea_t.id_vital_sign_read id_vs_tmp
                       FROM vital_signs_ea_tmp vs_ea_t
                      WHERE vs_ea_t.id_vital_sign_read NOT IN
                            (SELECT vs_ea.id_vital_sign_read
                               FROM vital_signs_ea vs_ea))
        LOOP
        
            l_validation_type := 1;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'VITAL_SIGNS_EA',
                                                        i_id_pk_1_value       => rec2.id_vs_tmp,
                                                        i_id_pk_1_col_name    => 'ID_VITAL_SIGN_READ',
                                                        i_id_pk_2_value       => NULL,
                                                        i_id_pk_2_col_name    => NULL,
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
            
                RAISE ins_invalid_record_error;
            END IF;
        
            l_count_invalid := l_count_invalid + 1;
        
        END LOOP;
        COMMIT;
    
        -- IF i_validate_table
    END IF;

    IF i_recreate_table
       AND i_validate_table
    THEN
        -- merge of invalid records
        dbms_output.put_line('merge of invalid records');
        MERGE INTO vital_signs_ea vse
        USING (SELECT *
                 FROM vital_signs_ea_tmp vse_tmp
                WHERE vse_tmp.id_vital_sign_read IN
                      (SELECT dgir.id_pk_1_value
                         FROM data_gov_invalid_recs dgir
                        WHERE dgir.ea_table_name = 'VITAL_SIGNS_EA'
                          AND dgir.dt_validation = l_current_timestamp)) t
        ON (vse.id_vital_sign_read = t.id_vital_sign_read)
        WHEN MATCHED THEN
        --dbms_output.put_line('update :'||t.id_patient);
            UPDATE
               SET vse.id_vital_sign       = t.id_vital_sign,
                   vse.id_vital_sign_desc  = t.id_vital_sign_desc,
                   vse.VALUE               = t.VALUE,
                   vse.id_unit_measure     = t.id_unit_measure,
                   vse.dt_vital_sign_read  = t.dt_vital_sign_read,
                   vse.flg_pain            = t.flg_pain,
                   vse.id_prof_read        = t.id_prof_read,
                   vse.id_prof_cancel      = t.id_prof_cancel,
                   vse.notes_cancel        = t.notes_cancel,
                   vse.flg_state           = t.flg_state,
                   vse.dt_cancel           = t.dt_cancel,
                   vse.flg_available       = t.flg_available,
                   vse.id_institution_read = t.id_institution_read,
                   vse.flg_status_epis     = t.flg_status_epis,
                   vse.id_visit            = t.id_visit,
                   vse.id_episode          = t.id_episode,
                   vse.id_patient          = t.id_patient,
                   vse.relation_domain     = t.relation_domain,
                   vse.id_epis_triage      = t.id_epis_triage,
                   vse.dt_dg_last_update   = l_current_timestamp
             WHERE vse.id_vital_sign_read = t.id_vital_sign_read
            
        
        WHEN NOT MATCHED THEN
        --dbms_output.put_line('insert :'||t.id_patient);
        
            INSERT
                (id_vital_sign,
                 id_vital_sign_read,
                 id_vital_sign_desc,
                 VALUE,
                 id_unit_measure,
                 dt_vital_sign_read,
                 flg_pain,
                 id_prof_read,
                 id_prof_cancel,
                 notes_cancel,
                 flg_state,
                 dt_cancel,
                 flg_available,
                 id_institution_read,
                 flg_status_epis,
                 id_visit,
                 id_episode,
                 id_patient,
                 relation_domain,
                 id_epis_triage,
                 dt_dg_last_update)
            VALUES
                (t.id_vital_sign,
                 t.id_vital_sign_read,
                 t.id_vital_sign_desc,
                 t.VALUE,
                 t.id_unit_measure,
                 t.dt_vital_sign_read,
                 t.flg_pain,
                 t.id_prof_read,
                 t.id_prof_cancel,
                 t.notes_cancel,
                 t.flg_state,
                 t.dt_cancel,
                 t.flg_available,
                 t.id_institution_read,
                 t.flg_status_epis,
                 t.id_visit,
                 t.id_episode,
                 t.id_patient,
                 t.relation_domain,
                 t.id_epis_triage,
                 l_current_timestamp);
        COMMIT;
        -- IF i_recreate_table AND i_validate_table
    END IF;

    -- delete records from temporary table
    DELETE FROM vital_signs_ea_tmp;
    COMMIT;

    -- delete last validation's records
    DELETE FROM data_gov_invalid_recs dgir
     WHERE dgir.ea_table_name = 'VITAL_SIGNS_EA'
       AND dgir.dt_validation < l_current_timestamp;
    COMMIT;

    dbms_output.put_line('OK: ' || l_count || ' inserted records');
    dbms_output.put_line('OK: ' || l_count_invalid || ' inserted invalid records');

    RETURN TRUE;
EXCEPTION
    WHEN function_error THEN
        dbms_output.put_line('Invalid input parameters');
        ROLLBACK;
        -- delete records from temporary table
        DELETE FROM vital_signs_ea_tmp;
        COMMIT;
        RETURN FALSE;
    WHEN ins_invalid_record_error THEN
        dbms_output.put_line('Error while saving invalid records');
        ROLLBACK;
        -- delete records from temporary table
        DELETE FROM vital_signs_ea_tmp;
        COMMIT;
        RETURN FALSE;
    WHEN invoking_external_prc_error THEN
        dbms_output.put_line('Error while invoking external procedure');
        ROLLBACK;
        -- delete records from temporary table
        DELETE FROM vital_signs_ea_tmp;
        COMMIT;
        RETURN FALSE;
    WHEN OTHERS THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
        ROLLBACK;
        -- delete records from temporary table
        DELETE FROM vital_signs_ea_tmp;
        COMMIT;
        RETURN FALSE;
END admin_vital_signs_ea;
/
