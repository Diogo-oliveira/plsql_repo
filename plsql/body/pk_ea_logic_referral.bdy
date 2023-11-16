/*-- Last Change Revision: $Rev: 2027056 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:52 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_referral IS
    -- This package provides Easy Access logic procedures to maintain the Referral's EA table.
    -- @author Joao Sa
    -- @version 2.4.3-Denormalized

    TYPE t_coll_external_request IS TABLE OF p1_external_request%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE t_coll_tracking IS TABLE OF p1_tracking%ROWTYPE INDEX BY BINARY_INTEGER;

    e_update_error EXCEPTION;
    g_owner VARCHAR2(30 CHAR);

    ------------------------------------------------ PUBLIC ----------------------------------------------------------

    /**
    * Updates for p1_external_request
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *     
    * ID_EXTERNAL_REQUEST
    * ID_PATIENT
    * NUM_REQ
    * FLG_TYPE
    * FLG_STATUS
    * ID_PROF_STATUS
    * DT_STATUS
    * FLG_PRIORITY
    * FLG_HOME
    * ID_SPECIALITY
    * DECISION_URG_LEVEL
    * ID_INST_ORIG
    * ID_INST_DEST
    * ID_DEP_CLIN_SERV
    * ID_PROF_REQUESTED
    * DT_REQUESTED
    * ID_SCHEDULE
    * ID_PROF_SCHEDULE (Estado S - Profissional do agendamento)
    * DT_SCHEDULE
    * DT_LAST_INTERACTION_TSTZ
    * FLG_MIGRATED
    * 
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_external_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids table_varchar;
    
        coll_referral_ea      ts_referral_ea.referral_ea_tc;
        coll_external_request t_coll_external_request;
    
        CURSOR c_p1_match
        (
            x_patient   p1_external_request.id_patient%TYPE,
            x_inst_dest p1_external_request.id_inst_dest%TYPE
        ) IS
            SELECT id_match
              FROM p1_match
             WHERE id_patient = x_patient
               AND id_institution = x_inst_dest
               AND flg_status = 'A';
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'P1_EXTERNAL_REQUEST',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            SELECT /*+rule */
             *
              BULK COLLECT
              INTO coll_external_request
              FROM p1_external_request exr
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(i_rowids) t);
        
            IF (coll_external_request.count > 0)
            THEN
            
                FOR i IN coll_external_request.first .. coll_external_request.last
                LOOP
                
                    coll_referral_ea(i).id_external_request := coll_external_request(i).id_external_request;
                    coll_referral_ea(i).id_patient := coll_external_request(i).id_patient;
                    coll_referral_ea(i).num_req := coll_external_request(i).num_req;
                    coll_referral_ea(i).flg_type := coll_external_request(i).flg_type;
                    coll_referral_ea(i).flg_status := coll_external_request(i).flg_status;
                    coll_referral_ea(i).id_prof_status := coll_external_request(i).id_prof_status;
                    coll_referral_ea(i).dt_status := coll_external_request(i).dt_status_tstz;
                    coll_referral_ea(i).flg_priority := coll_external_request(i).flg_priority;
                    coll_referral_ea(i).flg_home := coll_external_request(i).flg_home;
                    coll_referral_ea(i).id_speciality := coll_external_request(i).id_speciality;
                    coll_referral_ea(i).decision_urg_level := coll_external_request(i).decision_urg_level;
                    coll_referral_ea(i).id_inst_orig := coll_external_request(i).id_inst_orig;
                    coll_referral_ea(i).id_inst_dest := coll_external_request(i).id_inst_dest;
                    coll_referral_ea(i).id_dep_clin_serv := coll_external_request(i).id_dep_clin_serv;
                    coll_referral_ea(i).id_prof_requested := coll_external_request(i).id_prof_requested;
                    coll_referral_ea(i).dt_requested := coll_external_request(i).dt_requested;
                    coll_referral_ea(i).id_schedule := coll_external_request(i).id_schedule;
                    coll_referral_ea(i).dt_last_interaction_tstz := coll_external_request(i).dt_last_interaction_tstz;
                    coll_referral_ea(i).id_workflow := coll_external_request(i).id_workflow;
                    coll_referral_ea(i).id_external_sys := coll_external_request(i).id_external_sys;
                    coll_referral_ea(i).ext_reference := coll_external_request(i).ext_reference;
                    coll_referral_ea(i).flg_migrated := coll_external_request(i).flg_migrated;
                    coll_referral_ea(i).id_episode := coll_external_request(i).id_episode;
                    coll_referral_ea(i).flg_clin_comm_read := pk_ref_constant.g_no;
                    coll_referral_ea(i).flg_adm_comm_read := pk_ref_constant.g_no;
                    coll_referral_ea(i).prof_certificate := coll_external_request(i).prof_certificate;
                    coll_referral_ea(i).prof_name := coll_external_request(i).prof_name;
                    coll_referral_ea(i).prof_surname := coll_external_request(i).prof_surname;
                    coll_referral_ea(i).prof_phone := coll_external_request(i).prof_phone;
                    coll_referral_ea(i).id_fam_rel := coll_external_request(i).id_fam_rel;
                    coll_referral_ea(i).name_first_rel := coll_external_request(i).name_first_rel;
                    coll_referral_ea(i).name_middle_rel := coll_external_request(i).name_middle_rel;
                    coll_referral_ea(i).name_last_rel := coll_external_request(i).name_last_rel;
                    coll_referral_ea(i).consent := coll_external_request(i).consent;
                    coll_referral_ea(i).family_relationship_notes := coll_external_request(i).family_relationship_notes;
                
                    -- Check event type
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'ts_referral_ea.ins / ID_REF=' || coll_referral_ea(i).id_external_request;
                        ts_referral_ea.ins(rec_in          => coll_referral_ea(i),
                                           handle_error_in => TRUE,
                                           rows_out        => l_rowids);
                    
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'ts_referral_ea.upd / ID_REF=' || coll_referral_ea(i).id_external_request;
                        ts_referral_ea.upd(rec_in => coll_referral_ea(i),
                                           
                                           handle_error_in => TRUE,
                                           rows_out        => l_rowids);
                    
                        IF coll_referral_ea(i).id_workflow IS NULL
                        THEN
                            -- id_workflow could be updated to null (ALERT-309632)
                            -- BR example: after select "Guia de encaminhamento" (leads to id_wf=28), the option "Requisição de exames externos" could be chosen (referral must update id_workflow to null)
                            g_error := 'Call ts_referral_ea.upd / ID_WF=NULL / id_external_request_in=' || coll_referral_ea(i).id_external_request;
                            ts_referral_ea.upd(id_external_request_in => coll_referral_ea(i).id_external_request,
                                               id_workflow_in         => coll_referral_ea(i).id_workflow,
                                               id_workflow_nin        => FALSE, -- must update to null                          
                                               handle_error_in        => TRUE,
                                               rows_out               => l_rowids);
                        END IF;
                    
                        CASE coll_external_request(i).flg_status
                            WHEN pk_ref_constant.g_p1_status_r THEN
                                NULL;
                            WHEN pk_ref_constant.g_p1_status_a THEN
                                -- Tratar schedule
                                IF coll_external_request(i).id_schedule IS NOT NULL
                                THEN
                                    -- Limpar dados de agendamento se voltar a estado 'A'
                                    ts_referral_ea.upd(id_external_request_in => coll_external_request(i).id_external_request,
                                                       dt_schedule_in         => NULL,
                                                       dt_schedule_nin        => FALSE,
                                                       rows_out               => l_rowids);
                                
                                END IF;
                            
                            WHEN pk_ref_constant.g_p1_status_s THEN
                            
                                -- Tratar schedule
                                IF coll_external_request(i).id_schedule IS NOT NULL
                                THEN
                                    -- Actualizar dados de agendamento se passa a estado 'S' 
                                    SELECT s.dt_begin_tstz, spo.id_professional
                                      INTO coll_referral_ea(i).dt_schedule,coll_referral_ea(i).id_prof_schedule
                                      FROM schedule s
                                      LEFT JOIN schedule_outp so
                                        ON (s.id_schedule = so.id_schedule)
                                      LEFT JOIN sch_prof_outp spo
                                        ON (so.id_schedule_outp = spo.id_schedule_outp)
                                     WHERE s.id_schedule = coll_external_request(i).id_schedule;
                                
                                    ts_referral_ea.upd(id_external_request_in => coll_external_request(i).id_external_request,
                                                       id_schedule_in         => coll_external_request(i).id_schedule,
                                                       dt_schedule_in         => coll_referral_ea(i).dt_schedule,
                                                       id_prof_schedule_in    => coll_referral_ea(i).id_prof_schedule,
                                                       rows_out               => l_rowids);
                                
                                END IF;
                            
                            WHEN pk_ref_constant.g_p1_status_i THEN
                            
                                -- actualizar id_match da referral_ea:
                                -- se passar directamente para triagem (match ja tiver sido feito noutra altura), 
                                --    tem que ser actualizado o id_match na REFERRAL_EA
                                -- se existir alteracao de instituicao (na triagem), tem que ser actualizado o 
                                --    id_match para NULL na REFERRAL_EA (id_inst_dest diferente, nao tem id_match)                                                            
                            
                                g_error := 'OPEN c_p1_match / ID_REF=' || coll_referral_ea(i).id_external_request;
                                OPEN c_p1_match(coll_external_request(i).id_patient,
                                                coll_external_request(i).id_inst_dest);
                                FETCH c_p1_match
                                    INTO coll_referral_ea(i).id_match;
                            
                                IF c_p1_match%NOTFOUND
                                THEN
                                    g_error := 'NOTFOUND c_p1_match / ID_REF=' || coll_referral_ea(i).id_external_request;
                                    coll_referral_ea(i).id_match := NULL;
                                END IF;
                            
                                g_error := 'CLOSE c_p1_match / ID_REF=' || coll_referral_ea(i).id_external_request;
                                CLOSE c_p1_match;
                            
                                g_error := 'UPDATE REFERRAL_EA / ID_REF=' || coll_referral_ea(i).id_external_request;
                                ts_referral_ea.upd(id_external_request_in => coll_external_request(i).id_external_request,
                                                   id_match_in            => coll_referral_ea(i).id_match,
                                                   id_match_nin           => FALSE,
                                                   rows_out               => l_rowids);
                            
                            ELSE
                                NULL;
                        END CASE;
                    
                        g_error := 'UPDATE REFERRAL_EA / ID_REF=' || coll_referral_ea(i).id_external_request;
                        ts_referral_ea.upd(id_external_request_in        => coll_external_request(i).id_external_request,
                                           id_fam_rel_in                 => coll_external_request(i).id_fam_rel,
                                           id_fam_rel_nin                => FALSE,
                                           family_relationship_notes_in  => coll_external_request(i).family_relationship_notes,
                                           family_relationship_notes_nin => FALSE,
                                           rows_out                      => l_rowids);
                    
                    ELSIF i_event_type = t_data_gov_mnt.g_event_delete
                    THEN
                    
                        ts_referral_ea.del(id_external_request_in => coll_referral_ea(i).id_external_request,
                                           handle_error_in        => TRUE,
                                           rows_out               => l_rowids);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_external_request;

    /**
    * Updates for p1_tracking
    * Esta funcao trata as seguintes colunas de REFERRAL_EA: 
    *
    * ID_PROF_REDIRECTED
    * DT_NEW
    * DT_ISSUED
    * ID_PROF_TRIAGE
    * DT_TRIAGE
    * DT_FORWARDED
    * ID_PROF_SCHEDULE (Estado A)
    * DT_EFECTIV
    * DT_ACKNOWLEDGE
    *    
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_tracking
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids         table_varchar;
        coll_referral_ea ts_referral_ea.referral_ea_tc;
        coll_tracking    t_coll_tracking;
        i                PLS_INTEGER DEFAULT 0;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'P1_TRACKING',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            SELECT /*+rule*/
             *
              BULK COLLECT
              INTO coll_tracking
              FROM p1_tracking t
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(i_rowids) t);
        
            FOR r_cur IN (SELECT /*+opt_estimate(table, t, scale_rows=1)*/
                           t.id_external_request,
                           t.ext_req_status,
                           t.id_professional,
                           t.flg_type,
                           t.id_prof_dest,
                           t.id_dep_clin_serv,
                           t.decision_urg_level,
                           t.dt_tracking_tstz,
                           t.id_schedule,
                           t.id_inst_dest,
                           exr.id_patient,
                           s.dt_begin_tstz,
                           spo.id_professional id_prof_schedule
                            FROM p1_tracking t
                            JOIN p1_external_request exr
                              ON (t.id_external_request = exr.id_external_request)
                            LEFT JOIN schedule s
                              ON (s.id_schedule = exr.id_schedule)
                            LEFT JOIN schedule_outp so
                              ON (s.id_schedule = so.id_schedule)
                            LEFT JOIN sch_prof_outp spo
                              ON (so.id_schedule_outp = spo.id_schedule_outp)
                           WHERE t.rowid IN (SELECT /*+opt_estimate(table, tab, scale_rows=1)*/
                                              *
                                               FROM TABLE(i_rowids) tab)
                             AND t.flg_type IN (pk_ref_constant.g_tracking_type_s,
                                                pk_ref_constant.g_tracking_type_p,
                                                pk_ref_constant.g_tracking_type_c))
            LOOP
            
                g_error := 'ID_REF=' || r_cur.id_external_request || ' FLG_STATUS=' || r_cur.ext_req_status;
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
            
                CASE r_cur.ext_req_status
                    WHEN pk_ref_constant.g_p1_status_n THEN
                        coll_referral_ea(i).dt_new := r_cur.dt_tracking_tstz;
                    
                -- actualizacao de id_match feita na set_external_request para o estado pk_ref_constant.g_p1_status_i
                
                    WHEN pk_ref_constant.g_p1_status_i THEN
                        coll_referral_ea(i).dt_issued := r_cur.dt_tracking_tstz;
                        coll_referral_ea(i).id_prof_sch_sugg := NULL; -- cleans suggested professional
                
                    WHEN pk_ref_constant.g_p1_status_t THEN
                        coll_referral_ea(i).dt_triage := r_cur.dt_tracking_tstz;
                    
                        -- id_prof_requested cleaned when changing clinical service
                        IF r_cur.flg_type = pk_ref_constant.g_tracking_type_c
                        THEN
                            coll_referral_ea(i).id_prof_redirected := NULL;
                            coll_referral_ea(i).id_prof_sch_sugg := NULL; -- cleans suggested professional
                        END IF;
                    
                    WHEN pk_ref_constant.g_p1_status_a THEN
                        coll_referral_ea(i).id_prof_triage := r_cur.id_professional;
                        coll_referral_ea(i).id_prof_sch_sugg := r_cur.id_prof_dest;
                    
                    WHEN pk_ref_constant.g_p1_status_x THEN
                        coll_referral_ea(i).id_prof_triage := r_cur.id_professional;
                    WHEN pk_ref_constant.g_p1_status_d THEN
                        coll_referral_ea(i).id_prof_triage := r_cur.id_professional;
                        coll_referral_ea(i).id_prof_sch_sugg := NULL; -- cleans suggested professional
                    WHEN pk_ref_constant.g_p1_status_r THEN
                        coll_referral_ea(i).id_prof_redirected := r_cur.id_prof_dest;
                        coll_referral_ea(i).dt_forwarded := r_cur.dt_tracking_tstz;
                        coll_referral_ea(i).id_prof_triage := r_cur.id_prof_dest; -- ALERT-24874
                        coll_referral_ea(i).id_prof_sch_sugg := NULL; -- cleans suggested professional
                    WHEN pk_ref_constant.g_p1_status_e THEN
                        coll_referral_ea(i).dt_efectiv := r_cur.dt_tracking_tstz;
                    WHEN pk_ref_constant.g_p1_status_k THEN
                        coll_referral_ea(i).dt_acknowledge := r_cur.dt_tracking_tstz;
                    ELSE
                        NULL;
                END CASE;
            
                -- Check event type
                IF i_event_type = t_data_gov_mnt.g_event_insert
                   OR i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    -- Qd houver função para multiplas colunas substituir o loop pela função.
                    ts_referral_ea.upd(rec_in => coll_referral_ea(i), handle_error_in => TRUE, rows_out => l_rowids);
                
                ELSIF i_event_type = t_data_gov_mnt.g_event_delete
                THEN
                    NULL;
                END IF;
            
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_tracking;

    /**
    * Updates for p1_match
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *    
    * ID_MATCH
    *    
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joao Sa
    * @version 2.4.3-Denormalized
    * @since 2008/09/26
    */
    PROCEDURE set_match
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids         table_varchar;
        coll_referral_ea ts_referral_ea.referral_ea_tc;
        coll_tracking    t_coll_tracking;
        i                PLS_INTEGER DEFAULT 0;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'P1_MATCH',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            SELECT /*+rule*/
             *
              BULK COLLECT
              INTO coll_tracking
              FROM p1_tracking t
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(i_rowids) t);
        
            FOR r_cur IN (SELECT /*+use_nl(m, exr)*/
                           m.id_match, m.flg_status, exr.id_external_request
                            FROM p1_match m
                            JOIN p1_external_request exr
                              ON (m.id_patient = exr.id_patient AND m.id_institution = exr.id_inst_dest)
                           WHERE m.rowid IN (SELECT /*+opt_estimate(table, t, rows=1)*/
                                              *
                                               FROM TABLE(i_rowids) t))
            LOOP
            
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
            
                IF r_cur.flg_status = 'A'
                THEN
                    coll_referral_ea(i).id_match := r_cur.id_match;
                ELSE
                    coll_referral_ea(i).id_match := NULL;
                END IF;
            
                -- Check event type
                IF i_event_type = t_data_gov_mnt.g_event_insert
                   OR i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    ts_referral_ea.upd(rec_in => coll_referral_ea(i), handle_error_in => TRUE, rows_out => l_rowids);
                ELSIF i_event_type = t_data_gov_mnt.g_event_delete
                THEN
                    ts_referral_ea.upd(id_external_request_in => coll_referral_ea(i).id_external_request,
                                       id_match_in            => NULL,
                                       id_match_nin           => FALSE,
                                       handle_error_in        => TRUE,
                                       rows_out               => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_match;

    /**
    * Updates for ref_orig_data
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *    
    * ID_MATCH
    *    
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.5.0.7
    * @since 2010/01/19
    */

    PROCEDURE set_ref_orig_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids         table_varchar;
        coll_referral_ea ts_referral_ea.referral_ea_tc;
        coll_tracking    t_coll_tracking;
        i                PLS_INTEGER DEFAULT 0;
    BEGIN
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'REF_ORIG_DATA',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            SELECT /*+rule*/
             *
              BULK COLLECT
              INTO coll_tracking
              FROM p1_tracking t
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(i_rowids) t);
        
            FOR r_cur IN (SELECT /*+opt_estimate(table, m, scale_rows=1)*/
                           m.id_professional,
                           exr.id_inst_orig, -- ALERT-262716
                           m.institution_name,
                           exr.id_external_request,
                           exr.id_workflow
                            FROM ref_orig_data m
                            JOIN p1_external_request exr
                              ON (exr.id_external_request = m.id_external_request)
                           WHERE m.rowid IN (SELECT /*+opt_estimate(table, t, scale_rows=1)*/
                                              *
                                               FROM TABLE(i_rowids) t))
            
            LOOP
            
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
            
                IF r_cur.id_workflow = pk_ref_constant.g_wf_x_hosp
                THEN
                
                    coll_referral_ea(i).id_prof_orig := r_cur.id_professional;
                    coll_referral_ea(i).institution_name_roda := r_cur.institution_name;
                
                ELSE
                    coll_referral_ea(i).id_prof_orig := NULL;
                    coll_referral_ea(i).institution_name_roda := NULL;
                END IF;
            
                -- Check event type
                IF i_event_type = t_data_gov_mnt.g_event_insert
                   OR i_event_type = t_data_gov_mnt.g_event_update
                THEN
                
                    g_error := '1 Call ts_referral_ea.upd / ID_REF=' || coll_referral_ea(i).id_external_request;
                    ts_referral_ea.upd(rec_in => coll_referral_ea(i), handle_error_in => TRUE, rows_out => l_rowids);
                ELSIF i_event_type = t_data_gov_mnt.g_event_delete
                THEN
                
                    g_error := '2 Call ts_referral_ea.upd / ID_REF=' || coll_referral_ea(i).id_external_request;
                    ts_referral_ea.upd(id_external_request_in   => coll_referral_ea(i).id_external_request,
                                       id_match_in              => NULL,
                                       id_match_nin             => FALSE,
                                       id_prof_orig_in          => coll_referral_ea(i).id_prof_orig,
                                       institution_name_roda_in => coll_referral_ea(i).institution_name_roda,
                                       handle_error_in          => TRUE,
                                       rows_out                 => l_rowids);
                END IF;
            END LOOP;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_ref_orig_data;

    /**
    * Updates for DOC_EXTERNAL
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *    
    * NR_CLINICAL_DOC
    *    
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.6.1.20
    * @since 2013/07/10
    */

    PROCEDURE set_doc_external
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids         table_varchar;
        coll_referral_ea ts_referral_ea.referral_ea_tc;
        i                PLS_INTEGER DEFAULT 0;
        l_nr             referral_ea.nr_clinical_doc%TYPE;
        l_flg_sent_by    referral_ea.flg_sent_by%TYPE;
        l_flg_received   referral_ea.flg_received%TYPE;
    BEGIN
    
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'DOC_EXTERNAL',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
            FOR r_cur IN (SELECT /*+opt_estimate(table, m, scale_rows=1)*/
                           de.id_external_request
                            FROM doc_external de
                            JOIN p1_external_request exr
                              ON (de.id_external_request = exr.id_external_request)
                           WHERE de.rowid IN (SELECT /*+opt_estimate(table, t, scale_rows=1)*/
                                               *
                                                FROM TABLE(i_rowids) t)
                             AND de.flg_status = pk_ref_constant.g_active)
            LOOP
                g_error := 'Get vals';
                SELECT (SELECT COUNT(de.id_external_request) nr
                          FROM doc_external de
                         WHERE de.id_external_request = r_cur.id_external_request
                           AND de.flg_status = pk_ref_constant.g_active) nr,
                       (SELECT decode(COUNT(de.id_doc_external), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes) flg_sent_by
                          FROM doc_external de
                         WHERE de.id_external_request = r_cur.id_external_request
                           AND de.flg_status = pk_ref_constant.g_active
                           AND de.flg_sent_by IS NOT NULL),
                       (SELECT decode(COUNT(de.id_doc_external), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes)
                          FROM doc_external de
                         WHERE de.id_external_request = r_cur.id_external_request
                           AND de.flg_status = pk_ref_constant.g_active
                           AND de.flg_sent_by IS NOT NULL
                           AND de.flg_received = pk_ref_constant.g_yes)
                  INTO l_nr, l_flg_sent_by, l_flg_received
                  FROM dual;
            
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
                coll_referral_ea(i).nr_clinical_doc := l_nr;
                coll_referral_ea(i).flg_sent_by := l_flg_sent_by;
                coll_referral_ea(i).flg_received := l_flg_received;
            
                -- Check event type
                IF i_event_type = t_data_gov_mnt.g_event_insert
                   OR i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    g_error := '1 Call ts_referral_ea.upd / ID_REF=' || coll_referral_ea(i).id_external_request;
                    ts_referral_ea.upd(rec_in => coll_referral_ea(i), handle_error_in => TRUE, rows_out => l_rowids);
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_doc_external;

    /**
    * Updates for REF_COMMENTS
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *    
    * nr_clin_comments
    * id_prof_clin_comment
    * id_inst_clin_comment
    * dt_clin_last_comment
    * flg_clin_comm_read
    * nr_adm_comments
    * id_prof_adm_comment
    * id_inst_adm_comment
    * dt_adm_last_comment
    * flg_adm_comm_read
    *    
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Joana Barroso
    * @version 2.6.1.21
    * @since 2013/07/10
    */

    PROCEDURE set_ref_comments
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids         table_varchar;
        coll_referral_ea ts_referral_ea.referral_ea_tc;
        i                PLS_INTEGER DEFAULT 0;
        l_flg_type       ref_comments.flg_type%TYPE;
        l_nr             PLS_INTEGER;
        l_id_prof        ref_comments.id_professional%TYPE;
        l_id_inst        ref_comments.id_institution%TYPE;
        l_dt_comment     ref_comments.dt_comment%TYPE;
        l_flg_comm_read  VARCHAR2(1 CHAR);
    BEGIN
    
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'REF_COMMENTS',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof) = pk_ref_constant.g_cat_id_med
        THEN
            l_flg_type := pk_ref_constant.g_clinical_comment;
        ELSE
            l_flg_type := pk_ref_constant.g_administrative_comment;
        END IF;
    
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
            FOR r_cur IN (SELECT DISTINCT rc.id_external_request -- there may be several comments belonging to the same id_external_request
                            FROM ref_comments rc
                           WHERE rc.rowid IN (SELECT /*+opt_estimate(table, t, scale_rows=1)*/
                                               *
                                                FROM TABLE(i_rowids) t))
            LOOP
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
            
                -- get data considering flg_status=A                
                BEGIN
                    g_error := 'ID_REF=' || r_cur.id_external_request;
                    SELECT t.cnt, t.id_professional, t.id_institution, t.dt_comment
                      INTO l_nr, l_id_prof, l_id_inst, l_dt_comment
                      FROM (SELECT row_number() over(PARTITION BY rc2.id_external_request ORDER BY rc2.dt_comment DESC) my_row,
                                   COUNT(1) over(PARTITION BY rc2.id_external_request) cnt,
                                   rc2.id_professional,
                                   rc2.id_institution,
                                   rc2.dt_comment,
                                   rc2.id_external_request,
                                   rc2.flg_status,
                                   rc2.flg_type
                              FROM ref_comments rc2
                             WHERE rc2.id_external_request = r_cur.id_external_request
                               AND rc2.flg_type = l_flg_type
                               AND rc2.flg_status = pk_ref_constant.g_active_comment) t
                     WHERE my_row = 1; -- only the most recent record
                EXCEPTION
                    WHEN no_data_found THEN
                        -- if there are no records with flg_status=A, then update to 0 and null
                        l_nr         := 0;
                        l_id_prof    := NULL;
                        l_id_inst    := NULL;
                        l_dt_comment := NULL;
                END;
            
                g_error := 'CASE ' || l_flg_type || ' / ID_REF=' || r_cur.id_external_request || ' i_event_type=' ||
                           i_event_type || ' l_nr=' || l_nr || ' l_id_prof=' || l_id_prof || ' l_id_inst=' || l_id_inst ||
                           ' l_dt_comment=' || l_dt_comment;
                CASE l_flg_type
                    WHEN pk_ref_constant.g_clinical_comment THEN
                        coll_referral_ea(i).nr_clin_comments := l_nr;
                        coll_referral_ea(i).id_prof_clin_comment := l_id_prof;
                        coll_referral_ea(i).id_inst_clin_comment := l_id_inst;
                        coll_referral_ea(i).dt_clin_last_comment := l_dt_comment;
                        coll_referral_ea(i).flg_clin_comm_read := pk_ref_constant.g_no; -- new comment
                    
                        ts_referral_ea.upd(id_external_request_in   => coll_referral_ea(i).id_external_request,
                                           nr_clin_comments_in      => coll_referral_ea(i).nr_clin_comments,
                                           dt_clin_last_comment_in  => coll_referral_ea(i).dt_clin_last_comment,
                                           dt_clin_last_comment_nin => FALSE, -- in order to update to null
                                           id_prof_clin_comment_in  => coll_referral_ea(i).id_prof_clin_comment,
                                           id_prof_clin_comment_nin => FALSE,
                                           id_inst_clin_comment_in  => coll_referral_ea(i).id_inst_clin_comment,
                                           id_inst_clin_comment_nin => FALSE,
                                           flg_clin_comm_read_in    => coll_referral_ea(i).flg_clin_comm_read,
                                           handle_error_in          => TRUE,
                                           rows_out                 => l_rowids);
                    
                    WHEN pk_ref_constant.g_administrative_comment THEN
                        coll_referral_ea(i).nr_adm_comments := l_nr;
                        coll_referral_ea(i).dt_adm_last_comment := l_dt_comment;
                        coll_referral_ea(i).id_prof_adm_comment := l_id_prof;
                        coll_referral_ea(i).id_inst_adm_comment := l_id_inst;
                        coll_referral_ea(i).flg_adm_comm_read := pk_ref_constant.g_no; -- new comment
                    
                        ts_referral_ea.upd(id_external_request_in  => coll_referral_ea(i).id_external_request,
                                           nr_adm_comments_in      => coll_referral_ea(i).nr_adm_comments,
                                           dt_adm_last_comment_in  => coll_referral_ea(i).dt_adm_last_comment,
                                           dt_adm_last_comment_nin => FALSE, -- in order to update to null
                                           id_prof_adm_comment_in  => coll_referral_ea(i).id_prof_adm_comment,
                                           id_prof_adm_comment_nin => FALSE,
                                           id_inst_adm_comment_in  => coll_referral_ea(i).id_inst_adm_comment,
                                           id_inst_adm_comment_nin => FALSE,
                                           flg_adm_comm_read_in    => coll_referral_ea(i).flg_adm_comm_read,
                                           handle_error_in         => TRUE,
                                           rows_out                => l_rowids);
                END CASE;
            
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_ref_comments;

    /**
    * Updates for REF_COMMENTS_READ
    * This function updates the following columns of REFERRAL_EA table:
    *    
    * flg_clin_comm_read
    * flg_adm_comm_read
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-01-2014
    */
    PROCEDURE set_ref_comments_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids              table_varchar;
        coll_referral_ea      ts_referral_ea.referral_ea_tc;
        i                     PLS_INTEGER DEFAULT 0;
        l_flg_type            ref_comments.flg_type%TYPE;
        l_flg_comm_read       VARCHAR2(1 CHAR);
        l_flg_receiver        VARCHAR2(1 CHAR);
        l_params              VARCHAR2(1000 CHAR);
        l_id_cat              prof_cat.id_category%TYPE;
        l_id_prof_comm_create ref_comments.id_professional%TYPE;
        l_id_inst_comm_create ref_comments.id_institution%TYPE;
    BEGIN
        g_error := 'Init set_ref_comments_read / VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'REF_COMMENTS_READ',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        l_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'l_id_cat=' || l_id_cat;
        IF l_id_cat = pk_ref_constant.g_cat_id_med
        THEN
            l_flg_type := pk_ref_constant.g_clinical_comment;
        ELSE
            l_flg_type := pk_ref_constant.g_administrative_comment;
        END IF;
    
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
            --FOR r_cur IN (SELECT DISTINCT rc.id_external_request -- there may be several comments belonging to the same id_external_request
            FOR r_cur IN (SELECT DISTINCT rc.id_external_request, -- there may be several comments belonging to the same id_external_request
                                          rc.id_professional,
                                          rc.id_institution,
                                          r.id_prof_requested,
                                          r.id_inst_orig,
                                          r.id_inst_dest,
                                          r.id_dep_clin_serv,
                                          r.id_prof_clin_comment,
                                          r.id_prof_adm_comment,
                                          r.id_inst_clin_comment,
                                          r.id_inst_adm_comment,
                                          r.id_workflow
                            FROM ref_comments rc
                            JOIN ref_comments_read rcr
                              ON (rcr.id_ref_comment = rc.id_ref_comment)
                            JOIN referral_ea r
                              ON (r.id_external_request = rc.id_external_request)
                           WHERE rcr.rowid IN (SELECT /*+opt_estimate(table, t, scale_rows=1)*/
                                                *
                                                 FROM TABLE(i_rowids) t))
            LOOP
                i := i + 1;
                coll_referral_ea(i).id_external_request := r_cur.id_external_request;
            
                l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' l_id_cat=' || l_id_cat || ' flg_type=' ||
                            l_flg_type || ' ID_REF=' || r_cur.id_external_request || ' ID_WF=' || r_cur.id_workflow ||
                            ' id_prof_requested=' || r_cur.id_prof_requested || ' id_inst_orig=' || r_cur.id_inst_orig ||
                            ' id_inst_dest=' || r_cur.id_inst_dest || ' id_dep_clin_serv=' || r_cur.id_dep_clin_serv ||
                            ' l_flg_type=' || l_flg_type || ' id_prof=' || r_cur.id_professional || ' id_institution=' ||
                            r_cur.id_institution;
            
                g_error := 'Comment creation / ' || l_params;
                IF l_flg_type = pk_ref_constant.g_clinical_comment
                THEN
                    l_id_prof_comm_create := r_cur.id_prof_clin_comment;
                    l_id_inst_comm_create := r_cur.id_inst_clin_comment;
                ELSIF l_flg_type = pk_ref_constant.g_administrative_comment
                THEN
                    l_id_prof_comm_create := r_cur.id_prof_adm_comment;
                    l_id_inst_comm_create := r_cur.id_inst_adm_comment;
                END IF;
            
                l_params := l_params || ' l_id_prof_comm_create=' || l_id_prof_comm_create || ' l_id_inst_comm_create=' ||
                            l_id_inst_comm_create;
                g_error  := 'i_prof.id != l_id_prof_comm_create / ' || l_params;
                IF NOT (i_prof.id = l_id_prof_comm_create AND i_prof.institution = l_id_inst_comm_create)
                THEN
                    -- check if the professional is a receiver (if he was not the one that created the comment - WF=3)
                    g_error        := 'Call pk_ref_core.check_comm_receiver / ' || l_params;
                    l_flg_receiver := pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                                      i_prof              => i_prof,
                                                                      i_id_cat            => l_id_cat,
                                                                      i_id_workflow       => r_cur.id_workflow,
                                                                      i_id_prof_requested => r_cur.id_prof_requested,
                                                                      i_id_inst_orig      => r_cur.id_inst_orig,
                                                                      i_id_inst_dest      => r_cur.id_inst_dest,
                                                                      i_id_dcs            => r_cur.id_dep_clin_serv,
                                                                      i_flg_type_comm     => l_flg_type,
                                                                      i_id_inst_comm      => r_cur.id_institution);
                
                    IF l_flg_receiver = pk_ref_constant.g_yes
                    THEN
                        l_flg_comm_read := l_flg_receiver;
                    END IF;
                
                    IF l_flg_comm_read IS NOT NULL
                    THEN
                    
                        g_error := 'l_flg_comm_read=' || l_flg_comm_read || ' / ' || l_params;
                        CASE l_flg_type
                            WHEN pk_ref_constant.g_clinical_comment THEN
                                coll_referral_ea(i).flg_clin_comm_read := l_flg_comm_read;
                            
                            WHEN pk_ref_constant.g_administrative_comment THEN
                                coll_referral_ea(i).flg_adm_comm_read := l_flg_comm_read;
                            
                        END CASE;
                    
                        g_error := 'Call ts_referral_ea.upd / flg_clin_comm_read=' || coll_referral_ea(i).flg_clin_comm_read ||
                                   ' flg_adm_comm_read=' || coll_referral_ea(i).flg_adm_comm_read || ' / ' || l_params;
                        ts_referral_ea.upd(id_external_request_in => coll_referral_ea(i).id_external_request,
                                           flg_clin_comm_read_in  => coll_referral_ea(i).flg_clin_comm_read, -- if null, keeps old value
                                           flg_adm_comm_read_in   => coll_referral_ea(i).flg_adm_comm_read, -- if null, keeps old value
                                           handle_error_in        => TRUE,
                                           rows_out               => l_rowids);
                    
                    END IF;
                
                END IF;
            
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_ref_comments_read;

    /**
    * Updates for flg_status of p1_external_request
    * Esta funcao trata as seguintes colunas de REFERRAL_EA:
    *
    * STS_PROF_RESP
    * STS_ORIG_PHY
    * STS_ORIG_REG
    * STS_DEST_REG
    * STS_DEST_PHY_TE
    * STS_DEST_PHY_T
    * STS_DEST_PHY_MC
    * STS_ORIG_DC
    * STS_ORIG_DEFAULT
    * STS_DEST_DEFAULT
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-04-2013
    */
    PROCEDURE set_exr_flg_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids              table_varchar;
        coll_referral_ea      ts_referral_ea.referral_ea_tc;
        coll_external_request t_coll_external_request;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'P1_EXTERNAL_REQUEST',
                                                 i_expected_dg_table_name => 'REFERRAL_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        --IF i_event_type = t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        IF i_event_type = t_data_gov_mnt.g_event_update
        THEN
            g_error := 'LOOP INSERTED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
            
                g_error := 'SELECT p1_external_request';
                SELECT /*+rule */
                 *
                  BULK COLLECT
                  INTO coll_external_request
                  FROM p1_external_request exr
                 WHERE ROWID IN (SELECT column_value
                                   FROM TABLE(i_rowids) t);
            
                g_error := 'coll_external_request.count=' || coll_external_request.count;
                IF (coll_external_request.count > 0)
                THEN
                
                    FOR i IN 1 .. coll_external_request.count
                    LOOP
                    
                        -- calcula os estados todos
                        g_error := 'Call pk_ref_status.get_status_string_ea / ID_REF=' || coll_external_request(i).id_external_request;
                        pk_ref_status.get_status_string_ea(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_ref_row            => coll_external_request(i),
                                                           o_sts_prof_resp      => coll_referral_ea(i).sts_prof_resp,
                                                           o_sts_orig_phy_cs_dc => coll_referral_ea(i).sts_orig_phy_cs_dc,
                                                           o_sts_orig_phy_hs_dc => coll_referral_ea(i).sts_orig_phy_hs_dc,
                                                           o_sts_orig_phy_cs    => coll_referral_ea(i).sts_orig_phy_cs,
                                                           o_sts_orig_phy_hs    => coll_referral_ea(i).sts_orig_phy_hs,
                                                           o_sts_orig_reg_cs    => coll_referral_ea(i).sts_orig_reg_cs,
                                                           o_sts_orig_reg_hs    => coll_referral_ea(i).sts_orig_reg_hs,
                                                           o_sts_dest_reg       => coll_referral_ea(i).sts_dest_reg,
                                                           o_sts_dest_phy_te    => coll_referral_ea(i).sts_dest_phy_te,
                                                           o_sts_dest_phy_t     => coll_referral_ea(i).sts_dest_phy_t,
                                                           o_sts_dest_phy_t_me  => coll_referral_ea(i).sts_dest_phy_t_me,
                                                           o_sts_dest_phy_mc    => coll_referral_ea(i).sts_dest_phy_mc);
                    
                        g_error := 'UPDATE REFERRAL_EA / ID_REF=' || coll_referral_ea(i).id_external_request;
                        ts_referral_ea.upd(id_external_request_in => coll_external_request(i).id_external_request,
                                           sts_prof_resp_in       => coll_referral_ea(i).sts_prof_resp,
                                           sts_prof_resp_nin      => FALSE, -- update to null if null
                                           sts_orig_phy_cs_dc_in  => coll_referral_ea(i).sts_orig_phy_cs_dc,
                                           sts_orig_phy_cs_dc_nin => FALSE, -- update to null if null
                                           sts_orig_phy_hs_dc_in  => coll_referral_ea(i).sts_orig_phy_hs_dc,
                                           sts_orig_phy_hs_dc_nin => FALSE, -- update to null if null
                                           sts_orig_phy_cs_in     => coll_referral_ea(i).sts_orig_phy_cs,
                                           sts_orig_phy_cs_nin    => FALSE, -- update to null if null
                                           sts_orig_phy_hs_in     => coll_referral_ea(i).sts_orig_phy_hs,
                                           sts_orig_phy_hs_nin    => FALSE, -- update to null if null
                                           sts_orig_reg_cs_in     => coll_referral_ea(i).sts_orig_reg_cs,
                                           sts_orig_reg_cs_nin    => FALSE, -- update to null if null
                                           sts_orig_reg_hs_in     => coll_referral_ea(i).sts_orig_reg_hs,
                                           sts_orig_reg_hs_nin    => FALSE, -- update to null if null
                                           sts_dest_reg_in        => coll_referral_ea(i).sts_dest_reg,
                                           sts_dest_reg_nin       => FALSE, -- update to null if null
                                           sts_dest_phy_te_in     => coll_referral_ea(i).sts_dest_phy_te,
                                           sts_dest_phy_te_nin    => FALSE, -- update to null if null
                                           sts_dest_phy_t_in      => coll_referral_ea(i).sts_dest_phy_t,
                                           sts_dest_phy_t_nin     => FALSE, -- update to null if null
                                           sts_dest_phy_t_me_in   => coll_referral_ea(i).sts_dest_phy_t_me,
                                           sts_dest_phy_t_me_nin  => FALSE, -- update to null if null
                                           sts_dest_phy_mc_in     => coll_referral_ea(i).sts_dest_phy_mc,
                                           sts_dest_phy_mc_nin    => FALSE, -- update to null if null
                                           rows_out               => l_rowids);
                    
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN e_update_error THEN
            g_error := '[PK_EA_LOGIC_REFERRAL] AN ERROR OCCURRED WHEN UPDATING STATUS IN REFERRAL_EA / ' || g_error;
            pk_alert_exceptions.raise_error(error_name_in => 'UPDATE ERROR', text_in => g_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_exr_flg_status;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_referral
    * Description:                    Function that updates patient Referrals information in the Easy Access table (task_timeline_ea)
    *
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    *
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1.1
    * @since                          14/06/2017
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_new_rec_row       task_timeline_ea%ROWTYPE;
        l_func_proc_name    VARCHAR2(30) := 'SET_TL_REFERRAL';
        l_name_table_ea     VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name      VARCHAR2(30);
        l_event_into_ea     VARCHAR2(1);
        l_update_reg        NUMBER(24);
        o_rowids            table_varchar;
        l_error_out         t_error_out;
        l_nutrition_content VARCHAR2(200 CHAR) := 'TMP166.2654';
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
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
                l_event_into_ea := 'U';
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
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                pk_alertlog.log_debug('rowS:' || pk_utils.to_string(i_input => i_rowids));
                FOR r_cur IN (SELECT id_external_request,
                                     id_patient,
                                     id_episode,
                                     flg_status,
                                     id_prof_requested,
                                     dt_requested,
                                     id_inst_orig,
                                     code_description,
                                     --  id_prof_requested,
                                     dt_last_interaction_tstz,
                                     id_visit,
                                     flg_outdated,
                                     flg_ongoing,
                                     id_tl_task,
                                     flg_status_epis
                                FROM (SELECT p.id_external_request,
                                             p.id_patient,
                                             p.id_episode,
                                             p.flg_status,
                                             p.id_prof_requested,
                                             p.dt_requested,
                                             p.id_inst_orig,
                                             CASE
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_a THEN
                                                   'TL_TASK.CODE_TL_TASK.' || pk_prog_notes_constants.g_task_referral_lab
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_i THEN
                                                   'TL_TASK.CODE_TL_TASK.' ||
                                                   pk_prog_notes_constants.g_task_referral_img_exams
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_e THEN
                                                   'TL_TASK.CODE_TL_TASK.' ||
                                                   pk_prog_notes_constants.g_task_referral_other_exams
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_p THEN
                                                   'TL_TASK.CODE_TL_TASK.' || pk_prog_notes_constants.g_task_referral_proc
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_f THEN
                                                   'TL_TASK.CODE_TL_TASK.' || pk_prog_notes_constants.g_task_referral_rehab
                                                  ELSE
                                                   CASE
                                                       WHEN (SELECT id_content
                                                               FROM p1_speciality s
                                                              WHERE s.id_speciality = p.id_speciality) = l_nutrition_content THEN
                                                        'TL_TASK.CODE_TL_TASK.' ||
                                                        pk_prog_notes_constants.g_task_referral_nutrition
                                                       ELSE
                                                        'TL_TASK.CODE_TL_TASK.' || pk_prog_notes_constants.g_task_referral
                                                   END
                                              END code_description,
                                             p.id_prof_redirected,
                                             e.id_visit id_visit,
                                             CASE
                                                  WHEN p.flg_status IN
                                                       (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_x) THEN
                                                   pk_ea_logic_tasktimeline.g_flg_outdated
                                                  ELSE
                                                   pk_ea_logic_tasktimeline.g_flg_not_outdated
                                              END flg_outdated,
                                             CASE
                                                  WHEN p.flg_status IN (pk_ref_constant.g_p1_status_p) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             CASE
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_a THEN
                                                   pk_prog_notes_constants.g_task_referral_lab
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_i THEN
                                                   pk_prog_notes_constants.g_task_referral_img_exams
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_e THEN
                                                   pk_prog_notes_constants.g_task_referral_other_exams
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_p THEN
                                                   pk_prog_notes_constants.g_task_referral_proc
                                                  WHEN p.flg_type = pk_ref_constant.g_p1_type_f THEN
                                                   pk_prog_notes_constants.g_task_referral_rehab
                                                  ELSE
                                                   CASE
                                                       WHEN (SELECT id_content
                                                               FROM p1_speciality s
                                                              WHERE s.id_speciality = p.id_speciality) = l_nutrition_content THEN
                                                        pk_prog_notes_constants.g_task_referral_nutrition
                                                       ELSE
                                                        pk_prog_notes_constants.g_task_referral
                                                   END
                                              END id_tl_task,
                                             e.flg_status flg_status_epis,
                                             p.dt_last_interaction_tstz
                                        FROM p1_external_request p
                                        LEFT JOIN episode e
                                          ON p.id_episode = e.id_episode
                                       WHERE p.rowid IN (SELECT vc_1
                                                           FROM tbl_temp)))
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    g_error := 'CALL set_tl_referral - id_external_request: ' || r_cur.id_external_request ||
                               ' id_patient: ' || r_cur.id_patient;
                    pk_alertlog.log_debug(g_error);
                
                    l_new_rec_row.id_tl_task        := r_cur.id_tl_task;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_referral;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_external_request;
                    l_new_rec_row.dt_begin          := r_cur.dt_requested;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_requested;
                    l_new_rec_row.dt_req            := r_cur.dt_requested;
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_inst_orig;
                    l_new_rec_row.code_description  := r_cur.code_description;
                    l_new_rec_row.id_prof_exec      := r_cur.id_prof_requested;
                    l_new_rec_row.flg_outdated      := r_cur.flg_outdated;
                    l_new_rec_row.flg_sos           := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing       := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal        := pk_alert_constant.g_yes;
                    l_new_rec_row.flg_has_comments  := pk_alert_constant.g_no;
                    --     l_new_rec_row.status_flg        := r_cur.status_flg;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_interaction_tstz;
                    l_new_rec_row.rank           := 10;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status <> pk_ref_constant.g_p1_status_c -- Active Data
                       AND r_cur.flg_status_epis <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = pk_ref_constant.g_p1_status_c
                          OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
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
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin       => FALSE,
                                                table_name_in        => l_new_rec_row.table_name,
                                                flg_show_method_nin  => FALSE,
                                                flg_show_method_in   => l_new_rec_row.flg_show_method,
                                                code_description_nin => FALSE,
                                                code_description_in  => l_new_rec_row.code_description,
                                                --
                                                flg_outdated_nin         => TRUE,
                                                flg_outdated_in          => l_new_rec_row.flg_outdated,
                                                rank_nin                 => TRUE,
                                                rank_in                  => l_new_rec_row.rank,
                                                flg_sos_nin              => FALSE,
                                                flg_sos_in               => l_new_rec_row.flg_sos,
                                                id_parent_task_refid_nin => TRUE,
                                                id_parent_task_refid_in  => l_new_rec_row.id_parent_task_refid,
                                                flg_ongoing_nin          => TRUE,
                                                flg_ongoing_in           => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin           => TRUE,
                                                flg_normal_in            => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin         => TRUE,
                                                id_prof_exec_in          => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin     => TRUE,
                                                flg_has_comments_in      => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in        => l_new_rec_row.dt_last_update,
                                                rows_out                 => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        NULL;
                    END IF;
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_TL_REFERRAL',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_referral;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_referral;
/
