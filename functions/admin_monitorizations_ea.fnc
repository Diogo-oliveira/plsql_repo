CREATE OR REPLACE FUNCTION admin_monitorizations_ea
(
    i_patient          IN NUMBER DEFAULT NULL,
    i_episode          IN NUMBER DEFAULT NULL,
    i_schedule         IN NUMBER DEFAULT NULL,
    i_external_request IN NUMBER DEFAULT NULL,
    i_institution      IN NUMBER DEFAULT NULL,
    i_start_dt         IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    i_end_dt           IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    i_validate_table   IN BOOLEAN DEFAULT TRUE,
    i_recreate_table   IN BOOLEAN DEFAULT FALSE,
    i_commit_step      IN NUMBER DEFAULT 10000
) RETURN BOOLEAN IS

    -- Migration script for MONITORIZATIONS_EA

    l_count_invalid             NUMBER := 0;
    l_count                     NUMBER := 0;
    l_id_monitorization_vs_plan monitorization_vs_plan.id_monitorization_vs_plan%TYPE;
    l_flg_status_plan           monitorization_vs_plan.flg_status%TYPE;
    l_dt_plan_tstz              monitorization_vs_plan.dt_plan_tstz%TYPE;
    l_monit_count               NUMBER(6) := 0;
    l_current_timestamp         TIMESTAMP WITH TIME ZONE := current_timestamp;
    l_validation_type           data_gov_invalid_recs.validation_type%TYPE;

    l_prof        profissional := profissional(142, 1, 1);
    l_status_str  monitorizations_ea.status_str%TYPE;
    l_status_msg  monitorizations_ea.status_msg%TYPE;
    l_status_icon monitorizations_ea.status_icon%TYPE;
    l_status_flg  monitorizations_ea.status_flg%TYPE;

    function_error EXCEPTION;
    ins_invalid_record_error EXCEPTION;
    invoking_external_prc_error EXCEPTION;

    g_error VARCHAR2(4000);

BEGIN

    g_error := 'INI';

    IF NOT i_validate_table
       AND NOT i_recreate_table
    THEN
        RAISE function_error;
    END IF;

    /*    IF i_recreate_table
           AND NOT i_validate_table
        THEN
        
            g_error := 'DELETE MONITORIZATIONS EA PAT:' || i_patient || '/EPIS:' || i_episode;
            DELETE FROM monitorizations_ea
             WHERE (id_patient = i_patient OR i_patient IS NULL)
               AND (id_episode = i_episode OR i_episode IS NULL);
        
            COMMIT;
        
        END IF;
    */
    g_error := 'OPEN RECORD';

    FOR rec IN (SELECT m.id_monitorization,
                       mvs.id_monitorization_vs,
                       --mvp.id_monitorization_vs_plan,
                       mvs.id_vital_sign,
                       m.flg_status,
                       mvs.flg_status flg_status_det,
                       -- mvp.flg_status flg_status_plan,
                       m.flg_time,
                       m.dt_monitorization_tstz dt_monitorization,
                       --mvp.dt_plan_tstz dt_plan,
                       m.INTERVAL,
                       m.id_episode_origin,
                       m.dt_begin_tstz dt_begin,
                       m.dt_end_tstz dt_end,
                       --'CALCULADO' num_monit,
                       e.id_visit,
                       -- 'CALCULADO' status_str,
                       -- 'CALCULADO' status_msg,
                       -- 'CALCULADO' status_icon,
                       -- 'CALCULADO' status_flg,
                       decode(coalesce(mvs.notes_cancel, m.notes_cancel, m.notes), NULL, 'N', 'Y') flg_notes,
                       m.id_episode,
                       m.id_prev_episode,
                       e.id_patient,
                       m.id_professional
                  FROM monitorization m, monitorization_vs mvs, episode e
                 WHERE mvs.id_monitorization = m.id_monitorization
                   AND (m.id_patient = i_patient OR i_patient IS NULL)
                   AND (m.id_episode = i_episode OR i_episode IS NULL)
                   AND e.id_episode = m.id_episode
                   AND mvs.id_monitorization_vs NOT IN (SELECT m_ea.id_monitorization_vs
                                                          FROM monitorizations_ea m_ea)
                   AND EXISTS (SELECT 1
                          FROM monitorization_vs_plan mvp
                         WHERE mvp.id_monitorization_vs = mvs.id_monitorization_vs))
    LOOP
    
        g_error := 'GET DETAILS';
        BEGIN
            SELECT id_monitorization_vs_plan, dt_plan_tstz, flg_status
              INTO l_id_monitorization_vs_plan, l_dt_plan_tstz, l_flg_status_plan
              FROM (SELECT mvp.id_monitorization_vs_plan, mvp.dt_plan_tstz, mvp.flg_status
                      FROM monitorization_vs_plan mvp
                     WHERE mvp.id_monitorization_vs = rec.id_monitorization_vs
                       AND mvp.dt_plan_tstz =
                           (SELECT MAX(mvp1.dt_plan_tstz)
                              FROM monitorization_vs_plan mvp1
                             WHERE mvp1.id_monitorization_vs = rec.id_monitorization_vs)
                     ORDER BY mvp.id_monitorization_vs_plan DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                dbms_output.put_line(rec.id_monitorization_vs || '-' || SQLERRM);
                NULL;
        END;
    
        g_error := 'GET_LOGIC_STATUS';
    
        BEGIN
            --Obtains status info
            pk_ea_logic_monitorizations.get_monitorizations_status(i_prof            => l_prof,
                                                                   i_episode_origin  => rec.id_episode_origin,
                                                                   i_flg_time        => rec.flg_time,
                                                                   i_dt_begin        => rec.dt_begin,
                                                                   i_flg_status_det  => rec.flg_status_det,
                                                                   i_flg_status_plan => l_flg_status_plan,
                                                                   i_dt_plan         => l_dt_plan_tstz,
                                                                   o_status_str      => l_status_str,
                                                                   o_status_msg      => l_status_msg,
                                                                   o_status_icon     => l_status_icon,
                                                                   o_status_flg      => l_status_flg);
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE invoking_external_prc_error;
        END;
    
        g_error := 'COUNT MONIT';
    
        BEGIN
            SELECT COUNT(1)
              INTO l_monit_count
              FROM monitorization m
             WHERE m.id_episode = rec.id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_monit_count := 0;
        END;
    
        IF i_validate_table
        THEN
            g_error := 'INSERT TEMPORARY TABLE: ' || rec.id_monitorization_vs;
        
            INSERT INTO monitorizations_ea_tmp
                (id_monitorization,
                 id_monitorization_vs,
                 id_monitorization_vs_plan,
                 id_vital_sign,
                 flg_status,
                 flg_status_det,
                 flg_status_plan,
                 flg_time,
                 dt_monitorization,
                 dt_plan,
                 INTERVAL,
                 id_episode_origin,
                 dt_begin,
                 dt_end,
                 num_monit,
                 id_visit,
                 status_str,
                 status_msg,
                 status_icon,
                 status_flg,
                 flg_notes,
                 id_episode,
                 id_prev_episode,
                 id_patient,
                 id_professional)
            VALUES
                (rec.id_monitorization,
                 rec.id_monitorization_vs,
                 l_id_monitorization_vs_plan,
                 rec.id_vital_sign,
                 rec.flg_status,
                 rec.flg_status_det,
                 l_flg_status_plan,
                 rec.flg_time,
                 rec.dt_monitorization,
                 l_dt_plan_tstz,
                 rec.INTERVAL,
                 rec.id_episode_origin,
                 rec.dt_begin,
                 rec.dt_end,
                 l_monit_count,
                 rec.id_visit,
                 l_status_str,
                 l_status_msg,
                 l_status_icon,
                 l_status_flg,
                 rec.flg_notes,
                 rec.id_episode,
                 rec.id_prev_episode,
                 rec.id_patient,
                 rec.id_professional);
        
        END IF;
    
        IF i_recreate_table
           AND NOT i_validate_table
        THEN
        
            g_error := 'INSERT TABLE (*) REC: ' || rec.id_monitorization_vs || ' / PLAN:' || l_flg_status_plan ||
                       ' / l_id_monitorization_vs_plan: ' || l_id_monitorization_vs_plan;
        
            INSERT INTO monitorizations_ea
                (id_monitorization, --1
                 id_monitorization_vs, --2
                 id_monitorization_vs_plan, --3
                 id_vital_sign, --4
                 flg_status, --5
                 flg_status_det, --6
                 flg_status_plan, --7
                 flg_time, --8
                 dt_monitorization,
                 dt_plan,
                 INTERVAL,
                 id_episode_origin,
                 dt_begin,
                 dt_end,
                 num_monit,
                 id_visit,
                 status_str,
                 status_msg,
                 status_icon,
                 status_flg,
                 flg_notes,
                 id_episode,
                 id_prev_episode,
                 id_patient,
                 id_professional,
                 dt_dg_last_update)
            VALUES
                (rec.id_monitorization, --1
                 rec.id_monitorization_vs, --2
                 l_id_monitorization_vs_plan, --3
                 rec.id_vital_sign, --4
                 rec.flg_status, --5
                 rec.flg_status_det, --6
                 l_flg_status_plan, --7
                 rec.flg_time, --8
                 rec.dt_monitorization,
                 l_dt_plan_tstz,
                 rec.INTERVAL,
                 rec.id_episode_origin,
                 rec.dt_begin,
                 rec.dt_end,
                 l_monit_count,
                 rec.id_visit,
                 l_status_str,
                 l_status_msg,
                 l_status_icon,
                 l_status_flg,
                 rec.flg_notes,
                 rec.id_episode,
                 rec.id_prev_episode,
                 rec.id_patient,
                 rec.id_professional,
                 l_current_timestamp);
        
        END IF;
    
        IF MOD(l_count, i_commit_step) = 0
        THEN
            COMMIT;
        END IF;
    
        l_count := l_count + 1;
    
    END LOOP;

    g_error := 'OUT OF LOOP';

    IF i_validate_table
    THEN
        --compares and saves on table DATA_GOV_INVALID_RECS
    
        g_error := 'COMPARE VALUES';
    
        --the ones that are diferent
        FOR rec1 IN (SELECT b.id_monitorization_vs id_mon_tmp
                       FROM monitorizations_ea a, monitorizations_ea_tmp b
                      WHERE a.id_monitorization_vs = b.id_monitorization_vs
                        AND ((a.id_monitorization <> b.id_monitorization OR
                            (a.id_monitorization IS NULL AND b.id_monitorization IS NOT NULL) OR
                            (a.id_monitorization IS NOT NULL AND b.id_monitorization IS NULL)) OR
                            (a.id_monitorization_vs <> b.id_monitorization_vs OR
                            (a.id_monitorization_vs IS NULL AND b.id_monitorization_vs IS NOT NULL) OR
                            (a.id_monitorization_vs IS NOT NULL AND b.id_monitorization_vs IS NULL)) OR
                            (a.id_monitorization_vs_plan <> b.id_monitorization_vs_plan OR
                            (a.id_monitorization_vs_plan IS NULL AND b.id_monitorization_vs_plan IS NOT NULL) OR
                            (a.id_monitorization_vs_plan IS NOT NULL AND b.id_monitorization_vs_plan IS NULL)) OR
                            (a.id_vital_sign <> b.id_vital_sign OR
                            (a.id_vital_sign IS NULL AND b.id_vital_sign IS NOT NULL) OR
                            (a.id_vital_sign IS NOT NULL AND b.id_vital_sign IS NULL)) OR
                            (a.flg_status <> b.flg_status OR (a.flg_status IS NULL AND b.flg_status IS NOT NULL) OR
                            (a.flg_status IS NOT NULL AND b.flg_status IS NULL)) OR
                            (a.flg_status_det <> b.flg_status_det OR
                            (a.flg_status_det IS NULL AND b.flg_status_det IS NOT NULL) OR
                            (a.flg_status_det IS NOT NULL AND b.flg_status_det IS NULL)) OR
                            (a.flg_status_plan <> b.flg_status_plan OR
                            (a.flg_status_plan IS NULL AND b.flg_status_plan IS NOT NULL) OR
                            (a.flg_status_plan IS NOT NULL AND b.flg_status_plan IS NULL)) OR
                            (a.flg_time <> b.flg_time OR (a.flg_time IS NULL AND b.flg_time IS NOT NULL) OR
                            (a.flg_time IS NOT NULL AND b.flg_time IS NULL)) OR
                            (a.dt_monitorization <> b.dt_monitorization OR
                            (a.dt_monitorization IS NULL AND b.dt_monitorization IS NOT NULL) OR
                            (a.dt_monitorization IS NOT NULL AND b.dt_monitorization IS NULL)) OR
                            (a.dt_plan <> b.dt_plan OR (a.dt_plan IS NULL AND b.dt_plan IS NOT NULL) OR
                            (a.dt_plan IS NOT NULL AND b.dt_plan IS NULL)) OR
                            (a.INTERVAL <> b.INTERVAL OR (a.INTERVAL IS NULL AND b.INTERVAL IS NOT NULL) OR
                            (a.INTERVAL IS NOT NULL AND b.INTERVAL IS NULL)) OR
                            (a.id_episode_origin <> b.id_episode_origin OR
                            (a.id_episode_origin IS NULL AND b.id_episode_origin IS NOT NULL) OR
                            (a.id_episode_origin IS NOT NULL AND b.id_episode_origin IS NULL)) OR
                            (a.dt_begin <> b.dt_begin OR (a.dt_begin IS NULL AND b.dt_begin IS NOT NULL) OR
                            (a.dt_begin IS NOT NULL AND b.dt_begin IS NULL)) OR
                            (a.dt_end <> b.dt_end OR (a.dt_end IS NULL AND b.dt_end IS NOT NULL) OR
                            (a.dt_end IS NOT NULL AND b.dt_end IS NULL)) OR
                            (a.num_monit <> b.num_monit OR (a.num_monit IS NULL AND b.num_monit IS NOT NULL) OR
                            (a.num_monit IS NOT NULL AND b.num_monit IS NULL)) OR
                            (a.id_visit <> b.id_visit OR (a.id_visit IS NULL AND b.id_visit IS NOT NULL) OR
                            (a.id_visit IS NOT NULL AND b.id_visit IS NULL)) OR
                            (a.status_str <> b.status_str OR (a.status_str IS NULL AND b.status_str IS NOT NULL) OR
                            (a.status_str IS NOT NULL AND b.status_str IS NULL)) OR
                            (a.status_msg <> b.status_msg OR (a.status_msg IS NULL AND b.status_msg IS NOT NULL) OR
                            (a.status_msg IS NOT NULL AND b.status_msg IS NULL)) OR
                            (a.status_icon <> b.status_icon OR (a.status_icon IS NULL AND b.status_icon IS NOT NULL) OR
                            (a.status_icon IS NOT NULL AND b.status_icon IS NULL)) OR
                            (a.status_flg <> b.status_flg OR (a.status_flg IS NULL AND b.status_flg IS NOT NULL) OR
                            (a.status_flg IS NOT NULL AND b.status_flg IS NULL)) OR
                            (a.flg_notes <> b.flg_notes OR (a.flg_notes IS NULL AND b.flg_notes IS NOT NULL) OR
                            (a.flg_notes IS NOT NULL AND b.flg_notes IS NULL)) OR
                            (a.id_episode <> b.id_episode OR (a.id_episode IS NULL AND b.id_episode IS NOT NULL) OR
                            (a.id_episode IS NOT NULL AND b.id_episode IS NULL)) OR
                            (a.id_prev_episode <> b.id_prev_episode OR
                            (a.id_prev_episode IS NULL AND b.id_prev_episode IS NOT NULL) OR
                            (a.id_prev_episode IS NOT NULL AND b.id_prev_episode IS NULL)) OR
                            (a.id_patient <> b.id_patient OR (a.id_patient IS NULL AND b.id_patient IS NOT NULL) OR
                            (a.id_patient IS NOT NULL AND b.id_patient IS NULL)) OR
                            (a.id_professional <> b.id_professional OR
                            (a.id_professional IS NULL AND b.id_professional IS NOT NULL) OR
                            (a.id_professional IS NOT NULL AND b.id_professional IS NULL))))
        LOOP
        
            l_validation_type := 2;
        
            g_error := 'INVALID RECS:' || l_validation_type;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'MONITORIZATIONS_EA',
                                                        i_id_pk_1_value       => rec1.id_mon_tmp,
                                                        i_id_pk_1_col_name    => 'ID_MONITORIZATION_VS',
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
        FOR rec2 IN (SELECT mon_ea_t.id_monitorization_vs id_mon_tmp
                       FROM monitorizations_ea_tmp mon_ea_t
                      WHERE mon_ea_t.id_monitorization_vs NOT IN
                            (SELECT mon_ea.id_monitorization_vs
                               FROM monitorizations_ea mon_ea))
        LOOP
        
            l_validation_type := 1;
        
            g_error := 'INVALID RECS:' || l_validation_type;
        
            IF NOT pk_data_gov_admin.ins_invalid_record(i_ea_table_name       => 'MONITORIZATIONS_EA',
                                                        i_id_pk_1_value       => rec2.id_mon_tmp,
                                                        i_id_pk_1_col_name    => 'ID_MONITORIZATION_VS',
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
    
    END IF;

    IF i_recreate_table
       AND i_validate_table
    THEN
    
        g_error := 'MERGE RECS';
    
        --merge of invalid records
        MERGE INTO monitorizations_ea mon_ea
        USING (SELECT *
                 FROM monitorizations_ea_tmp mon_ea_tmp
                WHERE mon_ea_tmp.id_monitorization_vs IN
                      (SELECT dgir.id_pk_1_value
                         FROM data_gov_invalid_recs dgir
                        WHERE dgir.ea_table_name = 'MONITORIZATIONS_EA'
                          AND dgir.dt_validation = l_current_timestamp)) t
        ON (mon_ea.id_monitorization_vs = t.id_monitorization_vs)
        WHEN MATCHED THEN
            UPDATE
               SET mon_ea.id_monitorization         = t.id_monitorization,
                   mon_ea.id_monitorization_vs_plan = t.id_monitorization_vs_plan,
                   mon_ea.id_vital_sign             = t.id_vital_sign,
                   mon_ea.flg_status                = t.flg_status,
                   mon_ea.flg_status_det            = t.flg_status_det,
                   mon_ea.flg_status_plan           = t.flg_status_plan,
                   mon_ea.flg_time                  = t.flg_time,
                   mon_ea.dt_monitorization         = t.dt_monitorization,
                   mon_ea.dt_plan                   = t.dt_plan,
                   mon_ea.INTERVAL                  = t.INTERVAL,
                   mon_ea.id_episode_origin         = t.id_episode_origin,
                   mon_ea.dt_begin                  = t.dt_begin,
                   mon_ea.dt_end                    = t.dt_end,
                   mon_ea.num_monit                 = t.num_monit,
                   mon_ea.id_visit                  = t.id_visit,
                   mon_ea.status_str                = t.status_str,
                   mon_ea.status_msg                = t.status_msg,
                   mon_ea.status_icon               = t.status_icon,
                   mon_ea.status_flg                = t.status_flg,
                   mon_ea.flg_notes                 = t.flg_notes,
                   mon_ea.id_episode                = t.id_episode,
                   mon_ea.id_prev_episode           = t.id_prev_episode,
                   mon_ea.id_patient                = t.id_patient,
                   mon_ea.id_professional           = t.id_professional,
                   mon_ea.dt_dg_last_update         = l_current_timestamp
             WHERE mon_ea.id_monitorization_vs = t.id_monitorization_vs
        WHEN NOT MATCHED THEN
            INSERT
                (id_monitorization,
                 id_monitorization_vs,
                 id_monitorization_vs_plan,
                 id_vital_sign,
                 flg_status,
                 flg_status_det,
                 flg_status_plan,
                 flg_time,
                 dt_monitorization,
                 dt_plan,
                 INTERVAL,
                 id_episode_origin,
                 dt_begin,
                 dt_end,
                 num_monit,
                 id_visit,
                 status_str,
                 status_msg,
                 status_icon,
                 status_flg,
                 flg_notes,
                 id_episode,
                 id_prev_episode,
                 id_patient,
                 id_professional,
                 dt_dg_last_update)
            VALUES
                (t.id_monitorization,
                 t.id_monitorization_vs,
                 t.id_monitorization_vs_plan,
                 t.id_vital_sign,
                 t.flg_status,
                 t.flg_status_det,
                 t.flg_status_plan,
                 t.flg_time,
                 t.dt_monitorization,
                 t.dt_plan,
                 t.INTERVAL,
                 t.id_episode_origin,
                 t.dt_begin,
                 t.dt_end,
                 t.num_monit,
                 t.id_visit,
                 t.status_str,
                 t.status_msg,
                 t.status_icon,
                 t.status_flg,
                 t.flg_notes,
                 t.id_episode,
                 t.id_prev_episode,
                 t.id_patient,
                 t.id_professional,
                 l_current_timestamp);
    
        COMMIT;
    END IF;

    g_error := 'DELETE TEMPORARY TABLE';

    --delete records from temporary table
    DELETE FROM monitorizations_ea_tmp;
    COMMIT;

    g_error := 'DELETE OLD INVALID RECS';

    --delete last validation's records
    DELETE FROM data_gov_invalid_recs dgir
     WHERE dgir.ea_table_name = 'MONITORIZATIONS_EA'
       AND dgir.dt_validation < l_current_timestamp;

    COMMIT;

    dbms_output.put_line('OK: ' || l_count || ' inserted records');
    dbms_output.put_line('OK: ' || l_count_invalid || ' inserted invalid records');

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(g_error || '-' || SQLERRM);
        ROLLBACK;
        DELETE FROM monitorizations_ea_tmp;
        COMMIT;
        RETURN FALSE;
END admin_monitorizations_ea;
/
