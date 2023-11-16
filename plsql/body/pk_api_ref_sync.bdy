/*-- Last Change Revision: $Rev: 1518489 $*/
/*-- Last Change by: $Author: joana.barroso $*/
/*-- Date of last change: $Date: 2013-10-28 12:19:51 +0000 (seg, 28 out 2013) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_ref_sync IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception EXCEPTION;
    g_sysdate TIMESTAMP(6)
        WITH LOCAL TIME ZONE;

    -- Function and procedure implementations

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Note: The only validation that is done is the operation date order.
    *
    * @param i_lang          Language identifier
    * @param i_prof          Professional, institution and software ids
    * @param i_track_row     P1_tracking rowtype. Includes all data to record the referral change. 
    * @param o_track         Resulting id for p1_tracking
    * @param o_error         An error message, set when return=false
    *
    * @return true if success, false otherwise
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION update_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_track_row IN p1_tracking%ROWTYPE,
        o_track     OUT p1_tracking.id_tracking%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row  p1_tracking%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_rowids     table_varchar;
        l_read_count PLS_INTEGER;
    
        CURSOR c_read(x_round_id IN p1_tracking.round_id%TYPE) IS
            SELECT COUNT(1)
              FROM p1_tracking t
             WHERE t.id_external_request = i_track_row.id_external_request
               AND t.id_professional = i_prof.id
               AND t.flg_type = pk_ref_constant.g_tracking_type_r
               AND t.round_id = x_round_id
                  -- js 2007-07-19: Only on "read" record by user/round/status
               AND t.ext_req_status = i_track_row.ext_req_status;
    
        l_prof_dest        p1_tracking.id_prof_dest%TYPE;
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_create        p1_tracking.dt_create%TYPE;
    
        CURSOR c_track IS
            SELECT t.dt_tracking_tstz
              FROM p1_tracking t
             WHERE t.id_external_request = i_track_row.id_external_request
             ORDER BY t.dt_tracking_tstz DESC, t.id_tracking DESC;
    
        --l_dt_last_status_tstz p1_tracking.dt_tracking_tstz%TYPE; -- ACM, 2009-10-06: ALERT-24796
        l_check_date VARCHAR2(1 CHAR);
        l_id_speciality p1_tracking.id_speciality%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    BEGIN
    
        g_error := 'Init update_status /' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_tracking_row => i_track_row);
        pk_alertlog.log_debug(g_error);
        l_read_count := 0;
        l_dt_create  := current_timestamp;
        -- js, 2008-04-02: for update - avoid duplicadted records in p1_tracking.
        g_error := 'SELECT P1_EXTERNAL_REQUEST / ID_REF=' || i_track_row.id_external_request;
        SELECT *
          INTO l_ref_row
          FROM p1_external_request
         WHERE id_external_request = i_track_row.id_external_request
           FOR UPDATE;
    
        g_error := 'ID_REF=' || l_ref_row.id_external_request || ' FLG_STATUS OLD=' || l_ref_row.flg_status ||
                   ' FLG_STATUS NEW=' || i_track_row.ext_req_status;
        pk_alertlog.log_debug(g_error);
    
        -- does not check for transition availability, it was done before    
        g_error                     := 'COPY TRACK ROW';
        l_track_row                 := i_track_row;
        l_track_row.id_professional := i_prof.id;
        l_track_row.id_institution  := i_prof.institution;
    
        g_error                      := 'Process date';
        l_track_row.dt_tracking_tstz := nvl(i_track_row.dt_tracking_tstz, l_dt_create);
        l_track_row.dt_create        := l_dt_create;
    
        g_error  := 'Call pk_ref_status.validate_tracking_date';
        g_retval := pk_ref_status.validate_tracking_date(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_ref            => l_ref_row.id_external_request,
                                                         i_flg_type          => l_track_row.flg_type,
                                                         io_dt_tracking_date => l_track_row.dt_tracking_tstz,
                                                         o_error             => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN c_track';
        OPEN c_track;
        FETCH c_track
            INTO l_dt_tracking_tstz;
        CLOSE c_track;
    
        IF l_track_row.dt_tracking_tstz IS NOT NULL
           AND l_dt_tracking_tstz IS NOT NULL
        THEN
            g_error      := 'Call pk_date_utils.compare_dates_tsz';
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => l_track_row.dt_tracking_tstz,
                                                            i_date2 => l_dt_tracking_tstz);
        
            g_error := 'DT_TRACKING';
            IF l_check_date = pk_ref_constant.g_date_equal
            THEN
                l_track_row.dt_tracking_tstz := l_track_row.dt_tracking_tstz + INTERVAL '1' SECOND;
            END IF;
        END IF;
    
        -- getting round id
        g_error  := 'Call get_round / ID_REF=' || l_track_row.id_external_request || ' PREVIOUS_FLG_STATUS=' ||
                    l_ref_row.flg_status || ' NEW_FLG_STATUS=' || l_track_row.ext_req_status;
        g_retval := pk_ref_status.get_round(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_flg_status_prev => l_ref_row.flg_status, -- previous flg_status (before this update)
                                            i_track_row       => l_track_row,
                                            o_round_id        => l_track_row.round_id,
                                            o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'ID_REF=' || l_track_row.id_external_request || ' ROUND_ID=' || l_track_row.round_id;
        pk_alertlog.log_debug(g_error);
    
        -- If the type is "Status change" or "Send to triage physician" then changes request status
        -- ACM, 2009-03-30, ALERT-21468: added g_tracking_type_c
        IF instr(pk_ref_constant.g_tracking_type_s || pk_ref_constant.g_tracking_type_p ||
                 pk_ref_constant.g_tracking_type_c,
                 i_track_row.flg_type) > 0
        THEN
            l_ref_row.flg_status               := l_track_row.ext_req_status;
            l_ref_row.id_prof_status           := l_track_row.id_professional;
            l_ref_row.dt_status_tstz           := l_track_row.dt_tracking_tstz;
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
            -- records destiny professional (forwarded to triage professional, schedule for professional)
            IF l_track_row.id_prof_dest IS NOT NULL
            THEN
                -- JS, 2008-04-15: id_prof_dest - Clean if id is 0
                IF i_track_row.id_prof_dest = 0
                THEN
                    l_prof_dest := NULL;
                ELSE
                    l_prof_dest := i_track_row.id_prof_dest;
                END IF;
            
                IF i_track_row.ext_req_status = pk_ref_constant.g_p1_status_r
                THEN
                    -- referral being forwarded
                    g_error := 'EXT_REQ=' || l_ref_row.id_external_request || ' ID_PROF_REDIRECTED=' || l_prof_dest;
                    pk_alertlog.log_debug(g_error);
                
                    l_ref_row.id_prof_redirected := l_prof_dest;
                END IF;
            
                l_track_row.id_prof_dest := l_prof_dest;
            
            END IF;
        
            IF l_track_row.id_schedule IS NOT NULL
            THEN
                l_ref_row.id_schedule := l_track_row.id_schedule;
            END IF;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_u
        THEN
            -- If it's data update then updates dt_last_interaction
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_r
        THEN
        
            -- If there's a "read" record for this user/round/status don't reord again
            g_error := 'OPEN c_read / ROUND_ID=' || l_track_row.round_id;
            OPEN c_read(l_track_row.round_id);
        
            g_error := 'FETCH c_read';
            FETCH c_read
                INTO l_read_count;
        
            g_error := 'CLOSE c_read';
            CLOSE c_read;
        
            IF l_read_count != 0
            THEN
                -- do not record again            
                g_error := 'Do not record ID_REF=' || l_track_row.id_external_request || ' ROUND_ID=' ||
                           l_track_row.round_id;
                pk_alertlog.log_debug(g_error);
            
                RETURN TRUE;
            
            END IF;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_t
        THEN
            -- transf resp
            g_error := 'Transf resp / ID_PROF_DEST=' || l_track_row.id_prof_dest;
            IF l_track_row.id_prof_dest IS NOT NULL
            THEN
                l_ref_row.id_prof_requested := l_track_row.id_prof_dest;
            ELSE
                g_error := 'Transf resp: Dest professional must be defined';
                RAISE g_exception;
            END IF;
        
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
        END IF;
    
        -- js, 2008-04-14: Centralizes id_dep_clin_serv updates
        IF l_track_row.id_dep_clin_serv IS NOT NULL
        THEN
            l_ref_row.id_dep_clin_serv := l_track_row.id_dep_clin_serv;
            l_flg_availability         := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_ref_row.id_workflow,
                                                                             i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                             i_id_inst_dest => l_ref_row.id_inst_dest);
        
            g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ID_REF=' ||
                        l_ref_row.id_external_request || ' NEW DCS=' || l_ref_row.id_dep_clin_serv || ' ID_PATIENT=' ||
                        l_ref_row.id_patient || ' ID_EXTERNAL_SYS=' || l_ref_row.id_external_sys ||
                        ' FLG_AVAILABILITY=' || l_flg_availability;
            g_retval                   := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                                           i_prof             => i_prof,
                                                                                           i_id_dep_clin_serv => l_track_row.id_dep_clin_serv,
                                                                                           i_id_patient       => l_ref_row.id_patient,
                                                                                           i_id_external_sys  => l_ref_row.id_external_sys,
                                                                         i_flg_availability => l_flg_availability,
                                                                                           o_id_speciality    => l_id_speciality, -- new spec
                                                                                           o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
            l_ref_row.id_speciality := l_id_speciality;
        END IF;
    
        -- updating P1_EXTERNAL_REQUEST
        IF i_track_row.flg_type != pk_ref_constant.g_tracking_type_r
        THEN
            l_rowids := NULL;
            g_error  := 'UPDATE P1_EXTERNAL_REQUEST';
            ts_p1_external_request.upd(rec_in => l_ref_row, handle_error_in => TRUE, rows_out => l_rowids);
        
            -- js, 2008-12-04: processe changes to the record
            g_error := 'process_update P1_EXTERNAL_REQUEST';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_EXTERNAL_REQUEST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        -- INSERT P1_TRACKING
        g_error                 := 'ts_p1_tracking.next_key';
        l_track_row.id_tracking := ts_p1_tracking.next_key();
    
        l_rowids := NULL;
        g_error  := 'INSERT P1_TRACKING';
        ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'process_insert P1_TRACKING';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_track := l_track_row.id_tracking;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'UPDATE_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_status;

    /**
    * Inserts diagnosis
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral identifier
    * @param   i_type               Type of diagnosis being inserted. {*} P - problems {*} D - diagnosis
    * @param   i_diagnosis          Referral diagnosis. For each problem: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes],
    *                                     Note1: Begin_date and end_date mask like this: YYYYMMDDHH24MISS
    *                                     Note2: End_date and notes are not used yet for flg_type=P.
    *                                     Note3: Begin_date, end_date and notes are not used yet for flg_type=D.
    * @param   i_date               Operation date
    * @param   o_year_begin         The oldest problem year date, when flg_type=P.
    * @param   o_month_begin        The oldest problem month date, when flg_type=P.
    * @param   o_day_begin          The oldest problem day date, when flg_type=P.
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   05-08-2010
    */
    FUNCTION create_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_type           IN p1_exr_diagnosis.flg_type%TYPE,
        i_diagnosis      IN table_table_varchar,
        i_date           IN DATE,
        o_year_begin  OUT p1_exr_diagnosis.year_begin%TYPE,
        o_month_begin OUT p1_exr_diagnosis.month_begin%TYPE,
        o_day_begin   OUT p1_exr_diagnosis.day_begin%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exrdiag_row    p1_exr_diagnosis%ROWTYPE;
        l_id_diagnosis   p1_exr_diagnosis.id_exr_diagnosis%TYPE;
        l_year_begin   p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin  p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin    p1_exr_diagnosis.day_begin%TYPE;
        l_result       VARCHAR2(5 CHAR);
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init create_diagnosis / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' TYPE=' || i_type || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        IF i_diagnosis IS NOT NULL
        THEN
        
            g_error := 'i_diagnosis.COUNT=' || i_diagnosis.count;
            pk_alertlog.log_debug(g_error);
        
            --------------------------
            -- getting the oldest problem date
            FOR i IN 1 .. i_diagnosis.count
            LOOP
                IF i_type = pk_ref_constant.g_exr_diag_type_p
                THEN
                    -- getting the oldest problem date
                    g_error := 'Problem ID=' || i_diagnosis(i) (1) || ' Begin Date';
                    IF i_diagnosis(i).exists(3)
                        AND i_diagnosis(i) (3) IS NOT NULL
                    THEN
                        -- begin_date
                        g_error := g_error || ' = ' || i_diagnosis(i) (3);
                        l_year_begin  := substr(i_diagnosis(i) (3), 1, 4); -- problem begin year date
                        l_month_begin := substr(i_diagnosis(i) (3), 5, 2); -- problem begin month date
                        l_day_begin   := substr(i_diagnosis(i) (3), 7, 2); -- problem begin day date
                    
                        IF o_year_begin IS NULL
                        THEN
                            o_year_begin  := l_year_begin;
                            o_month_begin := l_month_begin;
                            o_day_begin   := l_day_begin;
                        ELSE
                        
                            g_error  := 'Call pk_ref_utils.compare_dt / i_year_1=' || o_year_begin || ' i_month_1=' ||
                                        o_month_begin || ' i_day_1=' || o_day_begin || ' i_year_2=' || l_year_begin ||
                                        ' i_month_2=' || l_month_begin || ' i_day_2=' || l_day_begin;
                            l_result := pk_ref_utils.compare_dt(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_year_1  => o_year_begin,
                                                                i_month_1 => o_month_begin,
                                                                i_day_1   => o_day_begin,
                                                                i_year_2  => l_year_begin,
                                                                i_month_2 => l_month_begin,
                                                                i_day_2   => l_day_begin);
                        
                            g_error := g_error || ' / result=' || l_result;
                            IF l_result = pk_ref_constant.g_date_greater
                            THEN
                                o_year_begin  := l_year_begin;
                                o_month_begin := l_month_begin;
                                o_day_begin   := l_day_begin;
                            END IF;
                        END IF;
                    
                    END IF;
                END IF;
            END LOOP;
        
            --------------------------
            -- inserting diagnosis
            FOR i IN 1 .. i_diagnosis.count
            LOOP
            
                -- l_exrdiag_row(i) = [id_diagnosis|desc_diagnosis|begin_date|end_date|notes] 
            
                g_error                           := 'Problems(' || i || ')';
                l_exrdiag_row                     := NULL;
                l_exrdiag_row.id_external_request := i_id_ref;
                l_exrdiag_row.id_diagnosis        := i_diagnosis(i) (1); -- id_diagnosis
            
                IF i_diagnosis(i).exists(2)
                THEN
                    l_exrdiag_row.desc_diagnosis := i_diagnosis(i) (2); -- desc_diagnosis
                END IF;
            
                l_exrdiag_row.id_professional     := i_prof.id;
                l_exrdiag_row.id_institution      := i_prof.institution;
                l_exrdiag_row.flg_type            := i_type; -- P or D                
                l_exrdiag_row.flg_status          := pk_ref_constant.g_active;
                l_exrdiag_row.dt_insert_tstz      := i_date;
                l_exrdiag_row.year_begin      := o_year_begin; -- ALERT-194568
                l_exrdiag_row.month_begin     := o_month_begin;
                l_exrdiag_row.day_begin       := o_day_begin;
            
                g_error  := 'Calling PK_REF_API.set_p1_exr_diagnosis / ID_DIAGNOSIS=' || l_exrdiag_row.id_diagnosis ||
                            ' FLG_TYPE=' || l_exrdiag_row.flg_type;
                g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_p1_exr_diagnosis    => l_exrdiag_row,
                                                            o_id_p1_exr_diagnosis => l_id_diagnosis,
                                                            o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'CREATE_DIAGNOSIS',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END create_diagnosis;

    /**
    * Inserts referral details
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral identifier
    * @param   i_id_tracking        Tracking identifier, to which details are related
    * @param   i_detail             P1 detail info. For each detail: [detail_type|description], where detail_type is
    *                                     0- Reason, 1- Signs and symptoms, 2- Progress, 3- History, 4- Family history,
    *                                     5- Objective exam, 6- Diagnostic tests, 50- Tasks for scheduling
    * @param   i_date               Operation date
    * @param   o_dt_probl_begin     The oldest problem date, when flg_type=P.
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   05-08-2010
    */
    FUNCTION create_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_tracking IN p1_tracking.id_tracking%TYPE,
        i_detail      IN table_table_varchar,
        i_date        IN DATE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_taskdone_row   p1_task_done%ROWTYPE;
        l_id             NUMBER;
        l_tasks_sch_type PLS_INTEGER := 50; -- todo: validar?       
        l_detail_row     p1_detail%ROWTYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init create_details / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' ID_TRACK=' || i_id_tracking || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        IF i_detail IS NOT NULL
        THEN
        
            g_error := 'i_detail.COUNT=' || i_detail.count;
            pk_alertlog.log_debug(g_error);
        
            FOR i IN 1 .. i_detail.count
            LOOP
            
                IF to_number(i_detail(i) (1)) IN (pk_ref_constant.g_detail_type_jstf,
                                                  pk_ref_constant.g_detail_type_sntm,
                                                  pk_ref_constant.g_detail_type_evlt,
                                                  pk_ref_constant.g_detail_type_hstr,
                                                  pk_ref_constant.g_detail_type_hstf,
                                                  pk_ref_constant.g_detail_type_obje,
                                                  pk_ref_constant.g_detail_type_cmpe,
                                                  pk_ref_constant.g_detail_type_fpriority,
                                                  pk_ref_constant.g_detail_type_fhome)
                THEN
                
                    -- l_detail_row(i) = [detail_type|description]
                    g_error := 'detail_type=' || i_detail(i) (1);
                    pk_alertlog.log_debug(g_error);
                
                    g_error                          := 'Detail(' || i || ')';
                    l_detail_row                     := NULL;
                    l_detail_row.id_external_request := i_id_ref;
                    l_detail_row.text                := i_detail(i) (2); -- description
                    l_detail_row.flg_type            := i_detail(i) (1); -- flg_type
                    l_detail_row.id_professional     := i_prof.id;
                    l_detail_row.id_institution      := i_prof.institution;
                    l_detail_row.id_tracking         := i_id_tracking;
                    l_detail_row.flg_status          := pk_ref_constant.g_active;
                    l_detail_row.dt_insert_tstz      := i_date;
                
                    g_error := 'Call PK_REF_API.set_p1_detail / detail_row=' ||
                               pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_detail_row => l_detail_row);
                    pk_alertlog.log_debug(g_error);
                    g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_p1_detail => l_detail_row,
                                                         o_id_detail => l_id,
                                                         o_error     => o_error);
                
                    IF NOT g_retval
                    THEN
                        g_error := 'ERROR: ' || g_error;
                        RAISE g_exception_np;
                    END IF;
                
                ELSIF to_number(i_detail(i) (1)) = l_tasks_sch_type
                THEN
                
                    g_error := 'Tasks needed(' || i || ')';
                    pk_alertlog.log_debug(g_error);
                
                    l_taskdone_row := NULL;
                
                    -- getting ID_TASK, based on description                    
                    g_error := 'Getting id_task based on description';
                    pk_alertlog.log_debug(g_error);
                
                    BEGIN
                        SELECT p.id_task
                          INTO l_taskdone_row.id_task
                          FROM p1_task p
                         WHERE p.flg_purpose = pk_ref_constant.g_p1_task_done_type_c -- tasks needed for consultation
                           AND flg_type = pk_ref_constant.g_p1_type_c
                           AND upper(pk_translation.get_translation(1, p.code_task)) LIKE
                               upper('%' || i_detail(i) (2) || '%');
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                
                    IF l_taskdone_row.id_task IS NOT NULL
                    THEN
                    
                        g_error := 'Fill l_taskdone_row / id_task=' || l_taskdone_row.id_task;
                        pk_alertlog.log_debug(g_error);
                        l_taskdone_row.id_prof_exec        := NULL;
                        l_taskdone_row.id_external_request := i_id_ref;
                        l_taskdone_row.flg_task_done       := pk_ref_constant.g_no;
                        l_taskdone_row.flg_type            := pk_ref_constant.g_p1_task_done_type_c;
                        l_taskdone_row.dt_inserted_tstz    := i_date;
                        l_taskdone_row.flg_status          := pk_ref_constant.g_active;
                        l_taskdone_row.id_professional     := i_prof.id;
                        l_taskdone_row.id_institution      := i_prof.institution;
                    
                        g_error  := 'Calling PK_REF_API.set_p1_task_done / id_external_request=' || i_id_ref;
                        g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_p1_task_done => l_taskdone_row,
                                                                o_id_task_done => l_id,
                                                                o_error        => o_error);
                        IF NOT g_retval
                        THEN
                            g_error := 'ERROR: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                    END IF;
                
                ELSE
                    -- it is not supposed to enter here...
                    g_error := 'DETAIL_TYPE=' || i_detail(i) (1) || ' DETAIL_DESC=' || i_detail(i) (2);
                    pk_alertlog.log_warn(g_error);
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'CREATE_DETAILS',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END create_details;

    /**
    * Creates a referral request.
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral Identifier on the central system (PT- ACSS)
    * @param   i_id_patient         Patient Identifier
    * @param   i_speciality         Referral specialty
    * @param   i_inst_dest          Institution dest identifier
    * @param   i_flg_priority       Referral priority. {*} Y - Urgent {*} N - not urgent 
    * @param   i_flg_home           Home consultation? {*} Y - Home consultation {*} N - otherwise
    * @param   i_detail             P1 detail info. For each detail: [detail_type|description], where detail_type is
    *                                     0- Reason, 1- Signs and symptoms, 2- Progress, 3- History, 4- Family history,
    *                                     5- Objective exam, 6- Diagnostic tests, 50- Tasks for scheduling        
    * @param   i_problems           Referral problems to solve. For each problem: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes],
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: End_date and notes are not used yet.
    * @param   i_diagnosis          Referral diagnosis. For each diagnosis: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes]
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: Begin_date, end_date and notes are not used yet.
    * @param   i_external_sys       External system identifier
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral local identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   05-08-2010
    */
    FUNCTION create_referral_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_id_patient   IN p1_external_request.id_patient%TYPE,
        i_speciality   IN p1_speciality.id_speciality%TYPE,
        i_inst_dest    IN institution.id_institution%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        i_detail       IN table_table_varchar,
        i_problems     IN table_table_varchar,
        i_diagnosis    IN table_table_varchar,
        i_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date         IN DATE,
        o_id_ref       OUT p1_external_request.id_external_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_ref_row   p1_external_request%ROWTYPE;
        l_track_row p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_ref_num_req_mask sys_config.desc_sys_config%TYPE;
        l_detail           table_table_varchar;
        l_new_flg_status   p1_external_request.flg_status%TYPE;
        l_id               NUMBER;
        l_year_begin       p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin      p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin        p1_exr_diagnosis.day_begin%TYPE;
    
        l_rowids table_varchar;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init create_referral_data / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   'SPECIALTY=' || i_speciality || ' INST_DEST=' || i_inst_dest || ' FLG_PRIORITY=' || i_flg_priority ||
                   ' FLG_HOME=' || i_flg_home || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        l_detail := i_detail;
        l_dt_create := current_timestamp;
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_ref_num_req_mask || ' l_prof=' ||
                   pk_utils.to_string(l_prof);
        pk_alertlog.log_debug(g_error);
        l_ref_num_req_mask := pk_sysconfig.get_config(pk_ref_constant.g_ref_num_req_mask, l_prof);
    
        ----------------------
        -- FUNC
        ----------------------            
    
        -------------------------
        -- P1_EXTERNAL_REQUEST
        -- creating referral row
        g_error                       := 'ts_p1_external_request.next_key()';
        l_ref_row.id_external_request := ts_p1_external_request.next_key();
    
        g_error                   := 'Fill l_ref_row';
        l_ref_row.id_patient      := i_id_patient;
        l_ref_row.id_speciality   := i_speciality;
        l_ref_row.id_inst_orig    := l_prof.institution;
        l_ref_row.id_inst_dest    := i_inst_dest;
        l_ref_row.id_external_sys := i_external_sys;
    
        -- saving id_referral on the central system
        g_error                 := 'EXT_REFERENCE=' || i_id_ref;
        l_ref_row.ext_reference := i_id_ref;
        -- num_req saved on this format (to differentiate a local referral from a remote referral)
        l_ref_row.num_req := REPLACE(l_ref_num_req_mask, '<NR>', i_id_ref);
    
        g_error := 'NUM_REQ=' || l_ref_row.num_req;
        pk_alertlog.log_debug(g_error);
    
        -- id_dep_clin_serv calculated when issuing referral
    
        l_ref_row.req_type          := pk_ref_constant.g_p1_req_type_m;
        l_ref_row.flg_type          := pk_ref_constant.g_p1_type_c;
        l_ref_row.id_prof_requested := l_prof.id;
        l_ref_row.id_prof_created   := l_prof.id;
        l_ref_row.flg_priority      := nvl(i_flg_priority, pk_ref_constant.g_no);
        l_ref_row.flg_home          := nvl(i_flg_home, pk_ref_constant.g_no);
    
        -- getting id_workflow
        g_error := 'Call pk_ref_utils.get_workflow / i_prof=' || pk_utils.to_string(l_prof) || ' ID_EXT_SYS=' ||
                   l_ref_row.id_external_sys || ' ID_INST_ORIG=' || l_ref_row.id_inst_orig || ' ID_INST_DEST=' ||
                   l_ref_row.id_inst_dest;
        pk_alertlog.log_debug(g_error);
    
        l_ref_row.id_workflow := pk_ref_utils.get_workflow(i_prof         => l_prof,
                                                           i_lang         => i_lang,
                                                           i_id_ext_sys   => l_ref_row.id_external_sys,
                                                           i_id_inst_orig => l_ref_row.id_inst_orig,
                                                           i_id_inst_dest => l_ref_row.id_inst_dest,
                                                           i_detail       => l_detail);
    
        g_error                            := 'P1_EXTERNAL_REQUEST 2';
        l_ref_row.dt_last_interaction_tstz := g_sysdate;
        l_ref_row.id_prof_status           := l_prof.id;
        l_ref_row.dt_status_tstz           := g_sysdate;
        l_ref_row.flg_paper_doc            := pk_ref_constant.g_no;
        l_ref_row.flg_digital_doc          := pk_ref_constant.g_no;
        l_ref_row.flg_mail                 := pk_ref_constant.g_no;
        l_ref_row.dt_requested             := g_sysdate;
        l_ref_row.id_episode               := NULL; -- id_episode associated when patient is registered in outp
    
        -- referral status = N 
        l_new_flg_status     := pk_ref_constant.g_p1_status_n;
        l_ref_row.flg_status := l_new_flg_status;
    
        -- inserting P1_EXTERNAL_REQUEST
        g_error := 'INSERT INTO P1_EXTERNAL_REQUEST / ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_ref_row => l_ref_row);
        pk_alertlog.log_debug(g_error);
        ts_p1_external_request.ins(rec_in => l_ref_row, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -------------------------
        -- P1_TRACKING        
    
        -- Changing referral status to N
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_n;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_inst_dest        := l_ref_row.id_inst_dest;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_n);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => l_id,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := l_id;
    
        -------------------------
        -- PROBLEMS
        -- inserting new problems to solve
        g_error := 'Call create_diagnosis / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_p;
        pk_alertlog.log_debug(g_error);
        g_retval := create_diagnosis(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_ref         => l_ref_row.id_external_request,
                                     i_type           => pk_ref_constant.g_exr_diag_type_p, -- problems to solve
                                     i_diagnosis      => i_problems,
                                     i_date           => g_sysdate,
                                     o_year_begin  => l_ref_row.year_begin, -- ALERT-194568
                                     o_month_begin => l_ref_row.month_begin,
                                     o_day_begin   => l_ref_row.day_begin,
                                     o_error          => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        -------------------------
        -- DIAGNOSIS    
        -- inserting new diagnosis
        g_error := 'Call create_diagnosis / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_d;
        pk_alertlog.log_debug(g_error);
        g_retval := create_diagnosis(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_ref         => l_ref_row.id_external_request,
                                     i_type           => pk_ref_constant.g_exr_diag_type_d, -- diagnosis
                                     i_diagnosis      => i_diagnosis,
                                     i_date           => g_sysdate,
                                     o_year_begin  => l_year_begin, -- ALERT-194568
                                     o_month_begin => l_month_begin,
                                     o_day_begin   => l_day_begin,
                                     o_error          => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        -------------------------
        -- DETAILS and TASKs DONE    
        -- inserting new details and task done
    
        -- ACM, 2011-04-01: ALERT-156898
        -- adding flg_priority and flg_home to details
        g_error := 'FLG_PRIORITY';
        l_detail.extend;
        l_detail(l_detail.last) := table_varchar(pk_ref_constant.g_detail_type_fpriority, l_ref_row.flg_priority);
    
        g_error := 'FLG_HOME';
        l_detail.extend;
        l_detail(l_detail.last) := table_varchar(pk_ref_constant.g_detail_type_fhome, l_ref_row.flg_home);
    
        g_error := 'Call create_details / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_d;
        pk_alertlog.log_debug(g_error);
        g_retval := create_details(i_lang        => i_lang,
                                   i_prof        => l_prof,
                                   i_id_ref      => l_ref_row.id_external_request,
                                   i_id_tracking => l_track_row.id_tracking,
                                   i_detail      => l_detail,
                                   i_date        => g_sysdate,
                                   o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- updating p1_external_request  (only the fields updated, not the entire row)  
        l_rowids := NULL;
        g_error  := 'Update p1_external_request / ID_REF=' || l_ref_row.id_external_request;
        ts_p1_external_request.upd(id_external_request_in  => l_ref_row.id_external_request,
                                   year_begin_in          => l_ref_row.year_begin,
                                   year_begin_nin         => FALSE, -- updates to null if is null -- ALERT-194568
                                   month_begin_in         => l_ref_row.month_begin,
                                   month_begin_nin        => FALSE, -- updates to null if is null
                                   day_begin_in           => l_ref_row.day_begin,
                                   day_begin_nin          => FALSE, -- updates to null if is null                                                                     
                                   --dt_probl_begin_tstz_in  => l_ref_row.dt_probl_begin_tstz,
                                   --dt_probl_begin_tstz_nin => FALSE, -- updates to null if l_ref_row.dt_probl_begin_tstz is null                                   
                                   handle_error_in         => TRUE,
                                   rows_out                => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- changing referral status to (I)ssued       
        g_error := 'Calling pk_ref_core.get_default_dcs / i_prof=' || pk_utils.to_string(l_prof) || ' ID_INST_DEST=' ||
                   l_ref_row.id_inst_dest || ' ID_SPECIALITY=' || l_ref_row.id_speciality;
        g_retval := pk_ref_core.get_default_dcs(i_lang    => i_lang,
                                                i_prof    => l_prof,
                                                i_exr_row => l_ref_row,
                                                o_dcs     => l_track_row.id_dep_clin_serv,
                                                o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_i;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate + INTERVAL '1' SECOND;
        l_track_row.dt_create           := l_dt_create + INTERVAL '1' SECOND;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
        l_track_row.id_speciality       := l_ref_row.id_speciality;
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => l_id,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := l_id;
    
        g_error  := 'ID_EXTERNAL_REQUEST=' || l_ref_row.id_external_request;
        o_id_ref := l_ref_row.id_external_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'CREATE_REFERRAL_DATA',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END create_referral_data;

    /**
    * Updates clinical referral data, and may changes referral status
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral Identifier         
    * @param   i_flg_priority       Referral priority. {*} Y - Urgent {*} N - not urgent 
    * @param   i_flg_home           Home consultation? {*} Y - Home consultation {*} N - otherwise
    * @param   i_detail             P1 detail info. For each detail: [detail_type|description], where detail_type is
    *                                     0- Reason, 1- Signs and symptoms, 2- Progress, 3- History, 4- Family history,
    *                                     5- Objective exam, 6- Diagnostic tests, 50- Tasks for scheduling        
    * @param   i_problems           Referral problems to solve. For each problem: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes],
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: End_date and notes are not used yet.
    * @param   i_diagnosis          Referral diagnosis. For each diagnosis: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes]
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: Begin_date, end_date and notes are not used yet.
    * @param   i_date               Operation date
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   04-08-2010
    */
    FUNCTION update_referral_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        i_detail       IN table_table_varchar,
        i_problems     IN table_table_varchar,
        i_diagnosis    IN table_table_varchar,
        i_date         IN DATE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_ref_row   p1_external_request%ROWTYPE;
        l_track_row p1_tracking%ROWTYPE;
        l_year_begin  p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin   p1_exr_diagnosis.day_begin%TYPE;
    
        l_id             NUMBER;
        l_rowids         table_varchar;
        l_new_flg_status p1_external_request.flg_status%TYPE;
        l_new_flg_type   p1_tracking.flg_type%TYPE;
        l_dt_create      p1_tracking.dt_create%TYPE;
    
        l_detail table_table_varchar;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init update_referral_data / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        l_detail := i_detail;
        l_dt_create := current_timestamp;
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'P1_EXTERNAL_REQUEST OLD ROW = ' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_ref_row => l_ref_row);
        pk_alertlog.log_debug(g_error);
    
        -----------------------
        -- Cancel all previous data
    
        -- DIAGNOSIS
        -- cancelling old problems to solve and diagnosis
        g_error := 'UPDATE p1_exr_diagnosis SET flg_status = ' || pk_ref_constant.g_cancelled ||
                   ' WHERE id_external_request=' || l_ref_row.id_external_request || ' AND flg_status=' ||
                   pk_ref_constant.g_active;
        pk_alertlog.log_debug(g_error);
    
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = l_ref_row.id_external_request
           AND flg_status = pk_ref_constant.g_active;
    
        -- DETAILs
        -- cancelling old details (flg_types between 0 and 6 only!)    
        g_error := 'UPDATE p1_detail SET flg_status = ' || pk_ref_constant.g_cancelled || ' WHERE id_external_request=' ||
                   l_ref_row.id_external_request || ' AND flg_status=' || pk_ref_constant.g_active ||
                   ' AND flg_type IN (' || pk_ref_constant.g_detail_type_jstf || ',' ||
                   pk_ref_constant.g_detail_type_sntm || ',' || pk_ref_constant.g_detail_type_evlt || ',' ||
                   pk_ref_constant.g_detail_type_hstr || ',' || pk_ref_constant.g_detail_type_hstf || ',' ||
                   pk_ref_constant.g_detail_type_obje || ',' || pk_ref_constant.g_detail_type_cmpe || ');';
        pk_alertlog.log_debug(g_error);
    
        UPDATE p1_detail
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = l_ref_row.id_external_request
           AND flg_status = pk_ref_constant.g_active
           AND flg_type IN (pk_ref_constant.g_detail_type_jstf,
                            pk_ref_constant.g_detail_type_sntm,
                            pk_ref_constant.g_detail_type_evlt,
                            pk_ref_constant.g_detail_type_hstr,
                            pk_ref_constant.g_detail_type_hstf,
                            pk_ref_constant.g_detail_type_obje,
                            pk_ref_constant.g_detail_type_cmpe,
                            pk_ref_constant.g_detail_type_fpriority, -- ACM, 2011-04-01: ALERT-156898
                            pk_ref_constant.g_detail_type_fhome);
    
        -- TASKs DONE
        -- cancelling old tasks done (needed for appointment only!!)    
        g_error := 'UPDATE p1_task_done SET flg_status = ' || pk_ref_constant.g_cancelled ||
                   ' WHERE id_external_request=' || l_ref_row.id_external_request || ' AND flg_status=' ||
                   pk_ref_constant.g_active || ' AND flg_type=' || pk_ref_constant.g_p1_task_done_type_c || ';';
        pk_alertlog.log_debug(g_error);
    
        UPDATE p1_task_done
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = l_ref_row.id_external_request
           AND flg_status = pk_ref_constant.g_active
           AND flg_type = pk_ref_constant.g_p1_task_done_type_c; -- task done needed for the appointment                
    
        -- changing referral data
    
        -------------------------
        -- P1_EXTERNAL_REQUEST
        g_error                            := 'P1_EXTERNAL_REQUEST';
        l_ref_row.flg_home                 := nvl(i_flg_home, pk_ref_constant.g_no);
        l_ref_row.flg_priority             := nvl(i_flg_priority, pk_ref_constant.g_no);
        l_ref_row.dt_last_interaction_tstz := g_sysdate;
    
        -------------------------
        -- P1_TRACKING        
    
        -- checking if referral status has to be changed
        g_error := 'ID_REF=' || l_ref_row.id_external_request || ' flg_status=' || l_ref_row.flg_status;
        CASE l_ref_row.flg_status
            WHEN pk_ref_constant.g_p1_status_b THEN
            
                -- referral has to be changed to (I)ssued
                l_new_flg_status               := pk_ref_constant.g_p1_status_i;
                l_new_flg_type                 := pk_ref_constant.g_tracking_type_s;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
        
            WHEN pk_ref_constant.g_p1_status_d THEN
            
                -- referral has to be changed to (N)ew
                l_new_flg_status               := pk_ref_constant.g_p1_status_n;
                l_new_flg_type                 := pk_ref_constant.g_tracking_type_s;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_n);
            ELSE
            
                -- it is just a referral update, status is not changed
                l_new_flg_status := l_ref_row.flg_status;
                l_new_flg_type   := pk_ref_constant.g_tracking_type_u;
        END CASE;
    
        g_error := 'ID_REF=' || l_ref_row.id_external_request || ' l_new_flg_status=' || l_new_flg_status;
        pk_alertlog.log_debug(g_error);
    
        -- inserting referral update on p1_tracking
        g_error                         := 'P1_TRACKING';
        l_track_row.ext_req_status      := l_new_flg_status;
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.flg_type            := l_new_flg_type;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        g_error := 'update_status / TRACK_ROW=' ||
                                           pk_ref_utils.to_string(i_lang         => i_lang,
                                                                            i_prof         => l_prof,
                                                                            i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => l_id,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := l_id;
    
        -------------------------
        -- DIAGNOSIS        
        -------------------------
        -- DIAGNOSIS
        -- inserting new problems to solve
        g_error := 'Call create_diagnosis / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_p;
        pk_alertlog.log_debug(g_error);
        g_retval := create_diagnosis(i_lang           => i_lang,
                                     i_prof           => l_prof,
                                     i_id_ref         => l_ref_row.id_external_request,
                                     i_type           => pk_ref_constant.g_exr_diag_type_p, -- problems to solve
                                     i_diagnosis      => i_problems,
                                     i_date           => g_sysdate,
                                     o_year_begin  => l_ref_row.year_begin, -- ALERT-194568
                                     o_month_begin => l_ref_row.month_begin,
                                     o_day_begin   => l_ref_row.day_begin,
                                     o_error          => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        -- inserting new diagnosis
        g_error := 'Call create_diagnosis / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_d;
        pk_alertlog.log_debug(g_error);
        g_retval := create_diagnosis(i_lang           => i_lang,
                                     i_prof           => l_prof,
                                     i_id_ref         => l_ref_row.id_external_request,
                                     i_type           => pk_ref_constant.g_exr_diag_type_d, -- diagnosis
                                     i_diagnosis      => i_diagnosis,
                                     i_date           => g_sysdate,
                                     o_year_begin  => l_year_begin, -- ALERT-194568
                                     o_month_begin => l_month_begin,
                                     o_day_begin   => l_day_begin,
                                     o_error          => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        -------------------------
        -- DETAILS and TASKs DONE
        -- inserting new details and task done
    
        -- ACM, 2011-04-01: ALERT-156898
        -- adding flg_priority and flg_home to details
        g_error := 'FLG_PRIORITY';
        l_detail.extend;
        l_detail(l_detail.last) := table_varchar(pk_ref_constant.g_detail_type_fpriority, l_ref_row.flg_priority);
    
        g_error := 'FLG_HOME';
        l_detail.extend;
        l_detail(l_detail.last) := table_varchar(pk_ref_constant.g_detail_type_fhome, l_ref_row.flg_home);
    
        g_error := 'Call create_details / ID_REF=' || l_ref_row.id_external_request || ' TYPE=' ||
                   pk_ref_constant.g_exr_diag_type_d;
        g_retval := create_details(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_id_ref      => l_ref_row.id_external_request,
                                   i_id_tracking => l_track_row.id_tracking,
                                   i_detail      => l_detail,
                                   i_date        => g_sysdate,
                                   o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- updating p1_external_request  (only the fields updated, not the entire row)  
        l_rowids := NULL;
        g_error  := 'Update p1_external_request / ID_REF=' || l_ref_row.id_external_request;
        ts_p1_external_request.upd(id_external_request_in  => l_ref_row.id_external_request,
                                   flg_priority_in         => l_ref_row.flg_priority,
                                   flg_home_in             => l_ref_row.flg_home,
                                   year_begin_in          => l_ref_row.year_begin,
                                   year_begin_nin         => FALSE, -- updates to null if is null -- ALERT-194568
                                   month_begin_in         => l_ref_row.month_begin,
                                   month_begin_nin        => FALSE, -- updates to null if is null
                                   day_begin_in           => l_ref_row.day_begin,
                                   day_begin_nin          => FALSE, -- updates to null if is null                                          
                                   --dt_probl_begin_tstz_in  => l_ref_row.dt_probl_begin_tstz,
                                   --dt_probl_begin_tstz_nin => FALSE, -- updates to null if l_ref_row.dt_probl_begin_tstz is null
                                   handle_error_in         => TRUE,
                                   rows_out                => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'UPDATE_REFERRAL_DATA',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END update_referral_data;

    /**
    * Changes status referral to (T)riage.
    * Note 1: This function do not change referral status to fo(R)warded if it have already been in triage and was forwarded.
    * Note 2: Id_dep_clin_serv is not provided (we have to calculate it)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier 
    * @param   i_notes          Status change notes
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   27-07-2010
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN VARCHAR2,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof       profissional;
        l_detail_row p1_detail%ROWTYPE;
        l_track_row  p1_tracking%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        l_ref_row   p1_external_request%ROWTYPE;
        l_dcs_count PLS_INTEGER;
        l_dcs       p1_tracking.id_dep_clin_serv%TYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_sent_triage / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- getting id_dep_clin_serv
        g_error := 'Call pk_ref_Status.get_dcs_info / ID_REF=' || l_ref_row.id_external_request ||
                   ' i_dcs=NULL i_MODE=S';
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_status.get_dcs_info(i_lang      => i_lang,
                                               i_prof      => l_prof,
                                               i_ref_row   => l_ref_row,
                                               i_dcs       => NULL,
                                               i_mode      => 'S', -- (S)ame institution
                                               o_dcs_count => l_dcs_count,
                                               o_track_dcs => l_dcs,
                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                         := 'Filling l_track_row';
        l_track_row.id_dep_clin_serv    := l_dcs;
        l_track_row.id_external_request := i_id_ref;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_t;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
    
        g_error := 'Call update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            g_error      := 'ERROR: ' || g_error;
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        -- Notes to triage doctor
        IF i_notes IS NOT NULL
        THEN
            g_error                          := 'PK_REF_API.set_p1_detail ' || pk_ref_constant.g_detail_type_ntri || ' ';
            l_detail_row.id_external_request := i_id_ref;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ntri;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.id_tracking         := o_track;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
        
            g_error := 'Call PK_REF_API.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_SENT_TRIAGE',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_sent_triage;

    /**
    * Changes status referral to (A)ccepted
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes
    * @param   i_prof_dest      Professional consultation suggested
    * @param   i_dcs            Dep_clin_serv id
    * @param   i_level          Triage decision urgency level
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_triaged
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_prof_dest IN professional.id_professional%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_level     IN p1_external_request.decision_urg_level%TYPE,
        i_date      IN DATE,
        o_track     OUT p1_tracking.id_tracking%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_triaged / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' PROF_DEST=' || i_prof_dest || ' DCS=' || i_dcs || ' LEVEL=' || i_level || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        --- SEND FOR SCHEDULING
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_a;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_dep_clin_serv    := i_dcs;
        l_track_row.id_prof_dest        := i_prof_dest;
        l_track_row.decision_urg_level  := i_level;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_a);
        l_track_row.dt_create           := l_dt_create;
    
        IF l_ref_row.flg_status = pk_ref_constant.g_p1_status_a
        THEN
            --- RESCHEDULE
            l_track_row.flg_subtype := pk_ref_constant.g_tracking_subtype_r;
        END IF;
    
        -- Tracking the new referral status     
        g_error := 'Call update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            g_error      := 'ERROR: ' || g_error;
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        g_error := 'Add notes';
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_TRIAGED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_triaged;

    /**
    * Changes referral status after scheduling
    * Do NOT update id_schedule (it was already updated by the OutP scheduling function, or is to be updated)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_dt_appointment Appointment date
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_scheduled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_date           IN DATE,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_track_row p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
    
        l_module         sys_config.value%TYPE;
        l_flg_status_new p1_external_request.flg_status%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_scheduled / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DT_APPOINTMENT=' || i_dt_appointment || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module || ' l_prof=' ||
                   pk_utils.to_string(l_prof);
        pk_alertlog.log_debug(g_error);
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, l_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'MODULE =' || l_module;
        pk_alertlog.log_debug(g_error);
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- todo: not finished yet... (not used yet)
                NULL;
            
            ELSE
                -- default behaviour                    
                -- this function will not cancel referrals associated with this schedule
            
                -- changes referral status to 'S'
                g_error                        := 'l_flg_status_new';
                l_flg_status_new               := pk_ref_constant.g_p1_status_s;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_s);
        
        END CASE;
    
        g_error := 'l_flg_status_new=' || l_flg_status_new;
        IF l_flg_status_new IS NOT NULL
        THEN
        
            -- It is not the first time it is scheduled
            g_error := 'Fill l_track_row';
            IF l_ref_row.id_schedule IS NOT NULL
            THEN
                l_track_row.flg_reschedule := pk_ref_constant.g_yes;
            END IF;
        
            l_track_row.id_external_request := l_ref_row.id_external_request;
            l_track_row.ext_req_status      := l_flg_status_new;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        
            -- we assume that referral was scheduled for the already associated dep_clin_serv           
            g_error                        := 'DCS=' || l_ref_row.id_dep_clin_serv;
            l_track_row.id_dep_clin_serv   := l_ref_row.id_dep_clin_serv;
            l_track_row.dt_tracking_tstz   := g_sysdate;
            l_track_row.dt_create          := l_dt_create;
            l_track_row.decision_urg_level := NULL;
        
            -- We cannot record id_schedule on P1_TRACKING (this value is known only in outp function)
            --l_track_row.id_schedule := i_schedule;
        
            -- Tracking the new referral status     
            g_error := 'Call update_status / ID_REF=' || l_ref_row.id_external_request;
            pk_alertlog.log_debug(g_error);
            g_retval := update_status(i_lang      => i_lang,
                                      i_prof      => l_prof,
                                      i_track_row => l_track_row,
                                      o_track     => o_track,
                                      o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error      := 'ERROR: ' || g_error;
                l_error_code := pk_ref_constant.g_ref_error_1008;
                l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
                RAISE g_exception;
            END IF;
        
            l_track_row.id_tracking := o_track;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_SCHEDULED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_scheduled;

    /**
    * Cancels a previous appointment (referral data only. Schedule is not cancelled in this function)
    * 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_dt_appointment Appointment date. Parameter ignored...
    * @param   i_notes          Status change notes
    * @param   i_date           Status change date
    * @param   i_reason_code    Referral reason code              
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_cancel_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN VARCHAR2,
        i_date           IN DATE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,        
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof       profissional;
        l_ref_row    p1_external_request%ROWTYPE;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        l_module         sys_config.value%TYPE; -- specifies referral module
        l_flg_status_new p1_external_request.flg_status%TYPE;
    
        CURSOR c_last IS
            SELECT id_dep_clin_serv, decision_urg_level, id_prof_dest
              FROM p1_tracking t
             WHERE t.id_external_request = l_ref_row.id_external_request
               AND t.flg_type = pk_ref_constant.g_tracking_type_s
               AND t.ext_req_status = pk_ref_constant.g_p1_status_a
             ORDER BY dt_tracking_tstz DESC;
    
        l_last c_last%ROWTYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_cancel_sch / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DT_APPOINTMENT=' || i_dt_appointment || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, l_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'MODULE =' || l_module;
        pk_alertlog.log_debug(g_error);
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- todo: not finished yet... (not used yet)
                NULL;
            
            ELSE
                -- always cancels referral (has only one schedule)
                l_flg_status_new               := pk_ref_constant.g_p1_status_a;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_csh);
        END CASE;
    
        g_error := 'NEW FLG_STATUS=' || l_flg_status_new;
        pk_alertlog.log_debug(g_error);
    
        -- only cancels referral if l_flg_cancel_ref is set to 'Y'
        IF l_flg_status_new IS NOT NULL
        THEN
        
            g_error := 'OPEN c_last';
            pk_alertlog.log_debug(g_error);
            OPEN c_last;
            FETCH c_last
                INTO l_last;
            CLOSE c_last;
        
            g_error                         := 'Fill l_track_row';
            l_track_row.id_external_request := l_ref_row.id_external_request;
            l_track_row.id_dep_clin_serv    := l_last.id_dep_clin_serv;
            l_track_row.decision_urg_level  := l_last.decision_urg_level;
            l_track_row.flg_subtype         := pk_ref_constant.g_tracking_subtype_r;
            l_track_row.id_prof_dest        := l_last.id_prof_dest;
            l_track_row.ext_req_status      := l_flg_status_new;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate;
            l_track_row.dt_create           := l_dt_create;
            l_track_row.id_reason_code      := i_reason_code;
        
            g_error := 'Call update_status / TRACK_ROW=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
            pk_alertlog.log_debug(g_error);
            g_retval := update_status(i_lang      => i_lang,
                                      i_prof      => l_prof,
                                      i_track_row => l_track_row,
                                      o_track     => o_track,
                                      o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error      := 'ERROR: ' || g_error;
                l_error_code := pk_ref_constant.g_ref_error_1008;
                l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
                RAISE g_exception;
            END IF;
        
            l_track_row.id_tracking := o_track;
        
            -- Add notes
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'Fill l_detail_row';
                -- inicializar detalhe
                l_detail_row.id_external_request := l_ref_row.id_external_request;
                l_detail_row.text                := i_notes;
                l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
                l_detail_row.id_professional     := l_prof.id;
                l_detail_row.id_institution      := l_prof.institution;
                l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
                l_detail_row.dt_insert_tstz      := g_sysdate;
            
                l_detail_row.id_tracking         := l_track_row.id_tracking;
            
                g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                           pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                     i_prof      => l_prof,
                                                     i_p1_detail => l_detail_row,
                                                     o_id_detail => l_id_detail,
                                                     o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_CANCEL_SCH',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_cancel_sch;

    /**
    * Medical refuse
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier 
    * @param   i_date           Status change date      
    * @param   i_notes          Status change notes
    * @param   i_reason_code    Refuse reason code            
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_refuse
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_ref_row    p1_external_request%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_track_row  p1_tracking%ROWTYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_refuse / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- REFUSE
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_x;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_prof_dest        := l_prof.id;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_x);
    
        g_error := 'Call update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            g_error      := 'ERROR: ' || g_error;
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_REFUSE',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_refuse;

    /**
    * Changes referral clinical service
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier      
    * @param   i_dcs            New dep_clin_serv identifier
    * @param   i_notes          Status change notes        
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_cs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_dcs    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_cs / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref || ' DCS=' ||
                   i_dcs || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_t;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_c;
        l_track_row.id_dep_clin_serv    := i_dcs;
        -- js, 2007-10-16 - Changes dep_clin_Serv, cleans previous professional to which the referral was forwarded
        l_track_row.id_prof_dest       := 0;
        l_track_row.dt_tracking_tstz   := g_sysdate;
        l_track_row.dt_create          := l_dt_create;
        l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_cs);
    
        g_error := 'Call update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            g_error      := 'ERROR: ' || g_error;
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        IF i_notes IS NOT NULL
        THEN
        
            g_error := 'Fill l_detail_row';
            -- inicializar detalhe
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_CS',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_cs;

    /**
    * Changes referral status to "E" (efectivation)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_efectv
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_track_row p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_ref_row   p1_external_request%ROWTYPE;
        l_module         sys_config.value%TYPE; -- specifies referral module
        l_flg_status_new p1_external_request.flg_status%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_efectv / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref || ' DATE=' ||
                   i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, l_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'MODULE =' || l_module;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- todo: not finished yet... (not used yet)
                NULL;
            
            ELSE
                -- changes referral status to 'E' (has only one schedule)
                l_flg_status_new               := pk_ref_constant.g_p1_status_e;
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_e);
        END CASE;
    
        g_error := 'NEW FLG_STATUS=' || l_flg_status_new || ' ID_REF=' || l_ref_row.id_external_request ||
                   ' current FLG_STATUS=' || l_ref_row.flg_status;
        pk_alertlog.log_debug(g_error);
    
        -- changing referral status
        IF l_flg_status_new IS NOT NULL
        THEN
        
            g_error                         := 'Fill l_track_row';
            l_track_row.id_external_request := l_ref_row.id_external_request;
            l_track_row.ext_req_status      := l_flg_status_new;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate;
            l_track_row.dt_create           := l_dt_create;
            g_error := 'Call update_status / TRACK_ROW=' ||
                                               pk_ref_utils.to_string(i_lang         => i_lang,
                                                        i_prof         => l_prof,
                                                        i_tracking_row => l_track_row);
            pk_alertlog.log_debug(g_error);
            g_retval := update_status(i_lang      => i_lang,
                                      i_prof      => l_prof,
                                      i_track_row => l_track_row,
                                      o_track     => o_track,
                                      o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error      := 'ERROR: ' || g_error;
                l_error_code := pk_ref_constant.g_ref_error_1008;
                l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
                RAISE g_exception;
            END IF;
        
            l_track_row.id_tracking := o_track;
        
        END IF;
    
        /*
        -- Scheduler 3.0
        IF i_transaction_id IS NOT NULL
        THEN
        
            g_error := 'Call pk_schedule_api_upstream.register_schedule / l_transaction_id = ' || i_transaction_id ||
                       ' i_id_schedule = ' || i_ref_row.id_schedule || ' i_id_patient = ' || i_ref_row.id_patient;
        
            g_retval := pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                            i_prof           => l_prof,
                                                                            i_id_schedule    => i_ref_row.id_schedule,
                                                                            i_id_patient     => i_ref_row.id_patient,
                                                                            i_flg_state      => pk_schedule_api_upstream.g_flg_state_pat_waiting,
                                                                            i_transaction_id => i_transaction_id,
                                                                            o_error          => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error;
                RAISE e_invalid_status;
            END IF;
        
        END IF;
        */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_EFECTV',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_efectv;

    /**
    * Insert referral's answer 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier           
    * @param   i_diagnosis      Selected diagnosis
    * @param   i_diag_desc      Diagnosis description, when entered in text mode
    * @param   i_answer         Observation, Therapy, Exam and Conclusion
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   27-07-2010
    */
    FUNCTION set_ref_answer
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_diagnosis IN table_number,
        i_diag_desc IN table_varchar,
        i_answer    IN table_table_varchar,
        i_date      IN DATE,
        o_track     OUT p1_tracking.id_tracking%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof          profissional;
        l_exr_diagnosis p1_exr_diagnosis%ROWTYPE;
        l_detail        p1_detail%ROWTYPE;
        l_track_row     p1_tracking%ROWTYPE;
        l_dt_create     p1_tracking.dt_create%TYPE;
        l_detail_type p1_detail.flg_type%TYPE;
        l_count       PLS_INTEGER;
        l_var         p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_answer / ID_REF=' || i_id_ref || ' DIAGNOSIS=' || pk_utils.to_string(i_diagnosis) ||
                   ' DIAG_DESC=' || pk_utils.to_string(i_diag_desc) || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        l_count := 0;
    
        g_error                         := 'UPDATE STATUS';
        l_track_row.id_external_request := i_id_ref;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_w;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_w);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'INSERT DIAGNOSIS / DIAGNOSIS=' || pk_utils.to_string(i_diagnosis) || ' COUNT=' || i_diagnosis.count;
        pk_alertlog.log_debug(g_error);
    
        FOR i IN 1 .. i_diagnosis.count
        LOOP
        
            l_count := l_count + 1;
            g_error := 'l_count=' || l_count;
        
            l_exr_diagnosis.id_exr_diagnosis    := NULL;
            l_exr_diagnosis.id_external_request := i_id_ref;
            l_exr_diagnosis.id_diagnosis        := i_diagnosis(i);
            l_exr_diagnosis.dt_insert_tstz      := g_sysdate;
            l_exr_diagnosis.id_professional     := l_prof.id;
            l_exr_diagnosis.id_institution      := l_prof.institution;
            l_exr_diagnosis.flg_type            := pk_ref_constant.g_exr_diag_type_a;
            l_exr_diagnosis.flg_status          := pk_ref_constant.g_active;
        
            l_exr_diagnosis.desc_diagnosis := i_diag_desc(i);
        
            g_error := 'Call pk_ref_api.set_p1_exr_diagnosis / ID_REF=' || l_exr_diagnosis.id_external_request;
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                        i_prof                => l_prof,
                                                        i_p1_exr_diagnosis    => l_exr_diagnosis,
                                                        o_id_p1_exr_diagnosis => l_var,
                                                        o_error               => o_error);
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            g_error         := 'Clean l_exr_diagnosis';
            l_exr_diagnosis := NULL;
        
        END LOOP;
    
        g_error := 'INSERT ANSWER';
        pk_alertlog.log_debug(g_error);
    
        FOR i IN 1 .. i_answer.count
        LOOP
        
            /*CASE i_answer(i) (1)
                WHEN 'OBSERVATION' THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_obs;
                WHEN 'THERAPY' THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_ter;
                WHEN 'EXAM' THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_exa;
                WHEN 'CONCLUSION' THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_con;
                ELSE
                    l_detail_type := -1;
            END CASE;*/
        
            CASE i_answer(i) (1)
                WHEN pk_ref_constant.g_detail_type_a_obs THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_obs;
                WHEN pk_ref_constant.g_detail_type_a_ter THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_ter;
                WHEN pk_ref_constant.g_detail_type_a_exa THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_exa;
                WHEN pk_ref_constant.g_detail_type_a_con THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_con;
                ELSE
                    l_detail_type := -1;
            END CASE;
        
            g_error := 'INSERT DETAIL';
            IF i_answer(i) (2) IS NOT NULL
            THEN
                l_count := l_count + 1;
            
                l_detail.id_detail           := NULL;
                l_detail.id_external_request := i_id_ref;
                l_detail.text                := i_answer(i) (2);
                l_detail.dt_insert_tstz      := g_sysdate;
                l_detail.flg_type            := l_detail_type;
                l_detail.id_professional     := l_prof.id;
                l_detail.id_institution      := l_prof.institution;
                l_detail.id_tracking         := o_track;
                l_detail.flg_status          := pk_ref_constant.g_detail_status_a;
            
                g_error := 'Call pk_ref_api.set_p1_detail / DETAIL_ROW=' ||
                           pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail);
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                     i_prof      => l_prof,
                                                     i_p1_detail => l_detail,
                                                     o_id_detail => l_var,
                                                     o_error     => o_error);
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Clean l_detail';
                l_detail := NULL;
            
            END IF;
        
        END LOOP;
    
        -- Se l_count vazio não houve nenhum insert
        g_error := 'l_count=' || l_count;
        pk_alertlog.log_debug(g_error);
        IF l_count > 0
        THEN
            --COMMIT;
            NULL;
            -- ACM, 2010-02-24: ALERT-44578
        ELSE
            pk_utils.undo_changes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_ANSWER',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_answer;

    /**
    * Performs a bureaucratic decline
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier       
    * @param   i_reason_code    Bureaucratic decline reason code    
    * @param   i_notes          Status change notes   
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false         
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_bur_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_detail_row p1_detail%ROWTYPE;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_ref_row    p1_external_request%ROWTYPE;
    
        l_id_detail p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_bur_declined / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_b;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_b);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        IF i_notes IS NOT NULL
        THEN
            g_error := 'Fill l_detail_row';
        
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_bdcl;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_BUR_DECLINED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_bur_declined;

    /**
    * Changes referral status to "F". Means that the patient missed the appointment 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier        
    * @param   i_dt_appointment Appointment date. Parameter ignored
    * @param   i_notes          Notes related to the missed appointment   
    * @param   i_date           Status change date      
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_failed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
    
        l_id_detail p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_failed / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DT_APPOINTMENT=' || i_dt_appointment || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_f;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_reason_code      := i_id_reason_code;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_f);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_miss;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_FAILED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_failed;

    /**
    * Cancel referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_cancel / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_c;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ncan;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_CANCEL',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_cancel;

    /**
    * Medical decline
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_declined / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_d;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_prof_dest        := l_prof.id;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_d);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_DECLINED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_declined;

    /**
    * Medical decline (by Clinical director)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6
    * @since   25-03-2011
    */
    FUNCTION set_ref_declined_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_declined / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_y;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_prof_dest        := l_prof.id;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_y);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec_cd;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_DECLINED_CD',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_declined_cd;

    /**
    * This function requests a referral cancellation
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancellation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   16-09-2010
    */
    FUNCTION set_ref_req_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_req_cancel / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_z;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_prof_dest        := l_prof.id;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_z);
        l_track_row.dt_create           := l_dt_create;
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_req_can;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_REQ_CANCEL',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_req_cancel;

    /**
    * This function denies a referral request cancellation.
    * This action can be done by the physician (answering to a registrar request) or can be done by the registrar (cancelling
    * his own cancellation request)
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   16-09-2010
    */
    FUNCTION set_ref_req_cancel_deny
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_req_cancel / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status       
        g_error := 'Call pk_ref_utils.get_prev_status_data / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => i_id_ref,
                                                      o_data   => l_track_row,
                                                      o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                        := 'Fill l_track_row';
        l_track_row.id_professional    := i_prof.id;
        l_track_row.id_institution     := i_prof.institution;
        l_track_row.flg_type           := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz   := g_sysdate;
        l_track_row.dt_create          := l_dt_create;
        l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_zdn);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_req_can;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_REQ_CANCEL_DENY',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_req_cancel_deny;

    /**
    * This function sends the referral to the dest registrar 
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   27-10-2010
    */
    FUNCTION set_ref_decline_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_decline_to_reg / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' REASON_CODE=' || i_reason_code || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_i;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_dcl_r);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_dcl_r;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_DECLINE_TO_REG',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_decline_to_reg;

    /** 
    * Changes referral status to "V". Means that the referral was approved by clinical director and needs informed consent.
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION set_ref_approved
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        l_p1_task_done     p1_task_done%ROWTYPE;
        l_task_inf_consent p1_task.id_task%TYPE;
        l_id_task_done     p1_task_done.id_task_done%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_approved / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------  
        g_error            := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_ref_task_inf_consent;
        l_task_inf_consent := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_task_inf_consent, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_v;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_v);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- insert task l_task_inf_consent ("Anexar termo de responsabilidade")        
        g_error                            := 'Fill l_p1_task_done / ID_TASK=' || l_task_inf_consent;
        l_p1_task_done.id_task             := l_task_inf_consent;
        l_p1_task_done.id_external_request := l_ref_row.id_external_request;
        l_p1_task_done.flg_task_done       := pk_ref_constant.g_no; -- Not completed
        l_p1_task_done.flg_type            := pk_ref_constant.g_p1_task_done_type_s; -- Needed for (S)cheduling
        l_p1_task_done.notes               := NULL;
        l_p1_task_done.dt_inserted_tstz    := g_sysdate;
        l_p1_task_done.dt_completed_tstz   := NULL;
        l_p1_task_done.id_prof_exec        := NULL;
        l_p1_task_done.id_inst_exec        := NULL;
        l_p1_task_done.flg_status          := pk_ref_constant.g_active;
        l_p1_task_done.id_group            := NULL;
        l_p1_task_done.id_professional     := i_prof.id;
        l_p1_task_done.id_institution      := i_prof.institution;
    
        g_error := 'Calling PK_REF_API.set_p1_task_done / ID_REF=' || l_p1_task_done.id_external_request || ' ID_TASK=' ||
                   l_p1_task_done.id_task || ' FLG_TASK_DONE=' || l_p1_task_done.flg_task_done || ' FLG_TYPE=' ||
                   l_p1_task_done.flg_type || ' FLG_STATUS=' || l_p1_task_done.flg_status || ' ID_PROFESSIONAL=' ||
                   l_p1_task_done.id_professional || ' ID_INSTITUTION=' || l_p1_task_done.id_institution;
        pk_alertlog.log_debug(g_error);
    
        g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_p1_task_done => l_p1_task_done,
                                                o_id_task_done => l_id_task_done,
                                                o_error        => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_APPROVED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_approved;

    /** 
    * Clinical director does not approves the referral
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION set_ref_not_approved
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_not_approved / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_h;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_h);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -- Add notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_ndec;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_NOT_APPROVED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_not_approved;

    /** 
    * Cancel a patient no show - undo to last flg_status
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6.1.3
    * @since   27-Sep-2011
    */
    FUNCTION set_ref_cancel_noshow
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_track_row p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_ref_row   p1_external_request%ROWTYPE;
        l_action    wf_workflow_action.internal_name%TYPE;
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_failed / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref || ' DATE=' ||
                   i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'PK_API_REF_SYNC.SET_REF_CANCEL_NOSHOW l_ref_row.flg_status=' || l_ref_row.flg_status;
        IF l_ref_row.flg_status <> pk_ref_constant.g_p1_status_f
        THEN
            g_error      := 'ERROR: ' || g_error;
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
        
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call pk_ref_utils.get_prev_status_data i_id_ref=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => i_id_ref,
                                                      o_data   => l_track_row,
                                                      o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'Error: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        <<ext_req_status>>CASE l_track_row.ext_req_status
            WHEN pk_ref_constant.g_p1_status_e THEN
                l_action := pk_ref_constant.g_ref_action_ute;
            WHEN pk_ref_constant.g_p1_status_m THEN
                l_action := pk_ref_constant.g_ref_action_utm;
            WHEN pk_ref_constant.g_p1_status_s THEN
                l_action := pk_ref_constant.g_ref_action_uts;
            ELSE
                RETURN FALSE;
        END CASE ext_req_status;
    
        -- Changing referral status
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := l_track_row.ext_req_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(l_action);
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_CANCEL_NOSHOW',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_cancel_noshow;

    /** 
    * Origin registrar attachs informed consent
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION attach_informed_consent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create  p1_tracking.dt_create%TYPE;
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        l_task_inf_consent p1_task.id_task%TYPE;
        l_rowids           table_varchar;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init attach_informed_consent / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref ||
                   ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------  
        g_error            := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_ref_task_inf_consent;
        l_task_inf_consent := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_task_inf_consent, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -------------------------------
        -- completing task informed consent
        g_error := 'UPDATE p1_task_done / ID_REF=' || i_id_ref || ' ID_TASK=' || l_task_inf_consent;
        pk_alertlog.log_debug(g_error);
        UPDATE p1_task_done
           SET flg_task_done     = pk_ref_constant.g_yes,
               dt_completed_tstz = g_sysdate,
               id_prof_exec      = i_prof.id,
               id_inst_exec      = i_prof.institution -- ALERT-824
         WHERE id_external_request = i_id_ref
           AND id_task = l_task_inf_consent
           AND flg_status = pk_ref_constant.g_active;
    
        g_error := 'UPDATE P1_EXTERNAL_REQUEST';
        ts_p1_external_request.upd(id_external_request_in      => i_id_ref,
                                   dt_last_interaction_tstz_in => g_sysdate,
                                   rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -------------------------------       
        -- Changing referral status to (I)ssued       
        g_error := 'Calling pk_ref_core.get_default_dcs / i_prof=' || pk_utils.to_string(l_prof) || ' ID_INST_DEST=' ||
                   l_ref_row.id_inst_dest || ' ID_SPECIALITY=' || l_ref_row.id_speciality;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_core.get_default_dcs(i_lang    => i_lang,
                                                i_prof    => l_prof,
                                                i_exr_row => l_ref_row,
                                                o_dcs     => l_track_row.id_dep_clin_serv,
                                                o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_i;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
    
        g_error := 'update_status / TRACK_ROW=' ||
                    pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -------------------------------
        -- Adding notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_admi;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                       pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'ATTACH_INFORMED_CONSENT',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END attach_informed_consent;

    /**
    * This function do Responsibility Transf.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_id_prof_dest   Professional to which the referral was transferred to
    * @param   i_id_reason_code Reason code 
    * @param   i_notes          Notes
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   25-02-2011
    */

    FUNCTION transf_referral_responsibility
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_prof_dest   IN professional.id_professional%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_track_row  p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    
        l_detail_row p1_detail%ROWTYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_id_detail  p1_detail.id_detail%TYPE;
    
        -- error
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init transf_referral_responsibility / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' ||
                   i_id_ref || ' ID_PROF_DEST=' || i_id_prof_dest || ' ID_REASON_CODE=' || i_id_reason_code || ' DATE=' ||
                   i_date;
        pk_alertlog.log_debug(g_error);
    
        -- getting operation date
        g_error := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_prof.ID=' || i_prof.id;
        IF i_prof.id IS NULL
        THEN
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------  
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting referral row
        g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -------------------------------       
        -- Register transf responsibility
        g_error                         := 'Fill l_track_row';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := l_ref_row.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_t;
        l_track_row.dt_tracking_tstz    := g_sysdate;
        l_track_row.dt_create           := l_dt_create;
        --l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.);
        l_track_row.id_prof_dest   := i_id_prof_dest;
        l_track_row.id_reason_code := i_id_reason_code;
    
        g_error := 'update_status / TRACK_ROW=' ||
                   pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_tracking_row => l_track_row);
        pk_alertlog.log_debug(g_error);
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => l_prof,
                                  i_track_row => l_track_row,
                                  o_track     => o_track,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            RAISE g_exception;
        END IF;
    
        l_track_row.id_tracking := o_track;
    
        -------------------------------
        -- Adding notes
        IF i_notes IS NOT NULL
        THEN
        
            g_error                          := 'Fill l_detail_row';
            l_detail_row.id_external_request := l_ref_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_transresp;
            l_detail_row.id_professional     := l_prof.id;
            l_detail_row.id_institution      := l_prof.institution;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := g_sysdate;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
        
            g_error := 'Call pk_ref_api.set_p1_detail / detail_row=' ||
                        pk_ref_utils.to_string(i_lang => i_lang, i_prof => l_prof, i_detail_row => l_detail_row);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => l_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_id_detail,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'TRANSF_REFERRAL_RESPONSIBILITY',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END transf_referral_responsibility;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_ref_sync;
/
