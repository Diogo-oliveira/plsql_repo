/*-- Last Change Revision: $Rev: 2026758 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_awareness_logic IS
    g_error VARCHAR2(1000 CHAR);
    /**
    * Get id_patient and id_episode based on rowid and table_name
    *
    * @param i_lang               Language
    * @param i_table_name         Table Name
    * @param i_rowids             ROWID of the i_table_name
    * @param o_patient            returned id_patien
    * @param o_episode            returned id_episode
    * @param o_error              Error message
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 02/10/2008
    */
    FUNCTION get_patient_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_table_name  IN VARCHAR2,
        i_rowid       IN VARCHAR2,
        o_patient     OUT table_number,
        o_episode     OUT table_number,
        o_visit       OUT table_number,
        o_column_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sql_stmt VARCHAR2(2000);
    
        l_patient_temp table_number := table_number();
        l_episode_temp table_number := table_number();
        l_visit_temp   table_number := table_number();
    
        l_patient_rec patient.id_patient%TYPE;
        l_episode_rec episode.id_episode%TYPE;
        l_visit_rec   visit.id_visit%TYPE;
    
    BEGIN
        o_patient     := table_number();
        o_episode     := table_number();
        o_visit       := table_number();
        o_column_name := i_table_name;
    
        IF lookup_table(i_table_name)
        THEN
            -- obtains id_patient and id_episode from the i_table_name
            g_error := 'EXECUTE IMMEDIATE L_SQL_STMT';
            pk_alertlog.log_debug(g_error);
        
            IF i_table_name IN ('EXAM_REQ', 'ANALYSIS_REQ', 'INTERV_PRESCRIPTION')
            THEN
                l_sql_stmt := 'select t.id_patient, t.id_episode, e.id_visit from ' || i_table_name ||
                              ' t join episode e on t.id_episode = e.id_episode where t.rowid = :i_rowid
						UNION ALL
						select t.id_patient, t.id_episode_origin, e.id_visit from ' || i_table_name ||
                              ' t join episode e on t.id_episode_origin = e.id_episode where t.rowid = :i_rowid';
            
                EXECUTE IMMEDIATE l_sql_stmt BULK COLLECT
                    INTO l_patient_temp, l_episode_temp, l_visit_temp
                    USING i_rowid, i_rowid;
                ------------------------------------------------------------------
            ELSIF i_table_name = 'PRESC'
            THEN
                -- obtain presc_med id_patient and id_episode in order to create Awareness record
                IF NOT pk_api_pfh_in.get_presc_med_details(i_lang       => i_lang,
                                                           i_prof       => NULL,
                                                           i_rowid      => i_rowid,
                                                           o_id_patient => l_patient_rec,
                                                           o_id_episode => l_episode_rec,
                                                           o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                o_column_name := 'PRESC_MED';
            
                -- obtain id_visit from episode
                IF l_patient_rec IS NOT NULL
                   AND l_episode_rec IS NOT NULL
                THEN
                    l_visit_rec := pk_episode.get_id_visit(l_episode_rec);
                END IF;
                -- check if id_visit is OK
                IF l_visit_rec IS NULL
                THEN
                    RETURN FALSE;
                END IF;
            
                -- log
                g_error := 'PK_AWARENESS_LOGIC | PRESC_MED : i_rowid = ' || i_rowid || '; l_patient_rec = ' ||
                           l_patient_rec || '; l_episode_rec = ' || l_episode_rec || '; l_visit_rec = ' || l_visit_rec;
                pk_alertlog.log_info(g_error);
            
                -- fill table_numbers
                l_patient_temp.extend;
                l_patient_temp(l_patient_temp.last) := l_patient_rec;
                l_episode_temp.extend;
                l_episode_temp(l_episode_temp.last) := l_episode_rec;
                l_visit_temp.extend;
                l_visit_temp(l_visit_temp.last) := l_visit_rec;
                ------------------------------------------------------------------
            ELSE
                l_sql_stmt := 'select t.id_patient, t.id_episode, e.id_visit from ' || i_table_name ||
                              ' t join episode e on t.id_episode = e.id_episode where t.rowid = :i_rowid';
            
                EXECUTE IMMEDIATE l_sql_stmt BULK COLLECT
                    INTO l_patient_temp, l_episode_temp, l_visit_temp
                    USING i_rowid;
            END IF;
        
            IF l_patient_temp.exists(1)
               AND l_patient_temp.count > 0
            THEN
                FOR i IN l_patient_temp.first .. l_patient_temp.last
                LOOP
                    IF l_patient_temp(i) IS NOT NULL
                       AND l_episode_temp(i) IS NOT NULL
                    THEN
                        -- o_patient and o_episode are OK so return TRUE
                        o_patient.extend;
                        o_episode.extend;
                        o_visit.extend;
                        o_patient(o_patient.last) := l_patient_temp(i);
                        o_episode(o_episode.last) := l_episode_temp(i);
                        o_visit(o_visit.last) := l_visit_temp(i);
                    
                    ELSIF l_patient_temp(i) IS NULL
                          AND l_episode_temp(i) IS NOT NULL
                    THEN
                        -- o_patient is NULL so obtain it from table episode
                        SELECT e.id_patient
                          INTO l_patient_temp(i)
                          FROM episode e
                         WHERE e.id_episode = l_episode_temp(i);
                    
                        IF l_patient_temp(i) IS NOT NULL
                        THEN
                            o_patient.extend;
                            o_episode.extend;
                            o_visit.extend;
                            o_patient(o_patient.last) := l_patient_temp(i);
                            o_episode(o_episode.last) := l_episode_temp(i);
                            o_visit(o_visit.last) := l_visit_temp(i);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            IF o_patient.exists(1)
               AND o_patient.count > 0
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_AWARENESS_LOGIC',
                                                     'GET_PATIENT_EPISODE',
                                                     o_error);
    END get_patient_episode;

    FUNCTION handle_sys_alert_det_delete
    (
        i_lang  IN language.id_language%TYPE,
        i_rowid IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sys_alert_det_tc ts_sys_alert_det.sys_alert_det_tc;
        l_found            VARCHAR2(1 CHAR);
        l_patient          table_number;
        l_episode          table_number;
        l_visit            table_number;
    BEGIN
        g_error := 'Get deleted rowids data';
        pk_alertlog.log_debug(g_error);
        l_sys_alert_det_tc := ts_sys_alert_det.get_data_rowid_pat(rows_in => table_varchar(i_rowid));
    
        IF l_sys_alert_det_tc IS NOT NULL
           AND l_sys_alert_det_tc.exists(1)
           AND l_sys_alert_det_tc(1).id_episode IS NOT NULL
        THEN
            g_error := 'Get rowids for data for the same episode';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT '0'
                  INTO l_found
                  FROM sys_alert_det
                 WHERE id_episode = l_sys_alert_det_tc(1).id_episode
                   AND rownum <= 1;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'Updates awareness.flg_sys_alert_det as ''N''';
                    pk_alertlog.log_debug(g_error);
                    UPDATE awareness
                       SET flg_sys_alert_det = pk_alert_constant.g_no
                     WHERE id_episode = l_sys_alert_det_tc(1).id_episode;
            END;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END handle_sys_alert_det_delete;

    /**
    * Verifies if the specified table belongs to the Awareness context
    *
    * @param i_table_name         Table Name
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 03/10/2008
    */
    FUNCTION lookup_table(i_table_name IN VARCHAR2) RETURN BOOLEAN IS
    
        i            INTEGER;
        l_table_list table_varchar := table_varchar('EPISODE',
                                                    'PAT_ALLERGY',
                                                    'PAT_HABIT',
                                                    'PAT_HISTORY_DIAGNOSIS',
                                                    'VITAL_SIGN_READ',
                                                    'EPIS_DIAGNOSIS',
                                                    'ANALYSIS_REQ',
                                                    'EXAM_REQ',
                                                    'PRESCRIPTION',
                                                    'DRUG_PRESCRIPTION',
                                                    'DRUG_REQ',
                                                    'INTERV_PRESCRIPTION',
                                                    'MONITORIZATION',
                                                    'ICNP_EPIS_DIAGNOSIS',
                                                    'ICNP_EPIS_INTERVENTION',
                                                    'PAT_PREGNANCY',
                                                    'SYS_ALERT_DET',
                                                    'PRESC');
    BEGIN
        -- Verifies if the input parameter i_table_name belongs to the Awareness identified tables
        FOR i IN l_table_list.first .. l_table_list.last
        LOOP
            IF upper(i_table_name) = l_table_list(i)
            THEN
                RETURN TRUE;
            END IF;
        END LOOP;
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END;

    /**
    * Process Awareness event logic / Package main entry function
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 02/10/2008
    */
    PROCEDURE process_event_logic
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        i NUMBER := 1;
    
        l_patient table_number;
        l_episode table_number;
        l_visit   table_number;
        o_error   t_error_out;
    
        e_call EXCEPTION;
        l_column_name pk_translation.t_desc_translation;
    
    BEGIN
        -- This is where the process event really starts
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        
        THEN
            IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
            THEN
                g_error := 'Regular insert or update';
                pk_alertlog.log_debug(g_error);
                -- for each record in rowids array check if necessary to update/insert awareness table
                FOR i IN i_rowids.first .. i_rowids.last
                LOOP
                    l_patient := NULL;
                    l_episode := NULL;
                
                    -- get id_patient and id_episode and verifies if everything is ok update/insert awareness table
                    IF get_patient_episode(i_lang        => i_lang,
                                           i_table_name  => i_source_table_name,
                                           i_rowid       => i_rowids(i),
                                           o_patient     => l_patient,
                                           o_episode     => l_episode,
                                           o_visit       => l_visit,
                                           o_column_name => l_column_name,
                                           o_error       => o_error)
                    THEN
                        -- update/insert awareness table
                        awareness_tbl_upd(i_patient    => l_patient,
                                          i_episode    => l_episode,
                                          i_visit      => l_visit,
                                          i_table_name => l_column_name);
                    END IF;
                END LOOP;
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
                  AND i_source_table_name = 'SYS_ALERT_DET'
            THEN
                g_error := 'Delete on sys_alert_Det';
                pk_alertlog.log_debug(g_error);
                -- get id_patient and id_episode and verifies if everything is ok update/insert awareness table
                IF NOT handle_sys_alert_det_delete(i_lang => i_lang, i_rowid => i_rowids(i), o_error => o_error)
                THEN
                    RAISE e_call;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END process_event_logic;

    /**
    * Inserts or updates awareness record bases on id_patient, id_episode and table_name
    *
    * @param i_patient            id_patien
    * @param i_episode            id_episode
    * @param i_table_name         Table Name
    *
    * @author Pedro Teixeira
    * @version 2.4.3-Denormalized
    * @since 03/10/2008
    */
    PROCEDURE awareness_tbl_upd
    (
        i_patient    table_number,
        i_episode    table_number,
        i_visit      table_number,
        i_table_name IN VARCHAR2
    ) IS
        l_sql_stmt VARCHAR2(2000);
    
    BEGIN
    
        FOR i IN i_patient.first .. i_patient.last
        LOOP
            -- l_sql_stmt represents the sql statment to execute, uses i_patient and i_episode as input parameters
            -- and i_table_name to identify the flag to update
            l_sql_stmt := 'BEGIN ts_awareness.upd_ins(id_patient_in => :1, id_episode_in => :2, flg_' || i_table_name ||
                          '_in => ''Y'', id_visit_in => :3); END;';
            EXECUTE IMMEDIATE l_sql_stmt
                USING i_patient(i), i_episode(i), i_visit(i);
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(g_package_name);

END pk_awareness_logic;
/
