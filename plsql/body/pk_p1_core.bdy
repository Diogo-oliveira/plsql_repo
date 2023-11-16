/*-- Last Change Revision: $Rev: 2027422 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_core AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_error VARCHAR2(1000 CHAR);

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          professional language id
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change. 
    * @param i_old_status    valid status for this update. Single word formed by the letter of valid status.
    * @param o_track         Array of ID_TRACKING transitions
    * @param o_error         an error message, set when return=false
    *
    * @return true if success, false otherwise
    *
    * @author  Joao Sa
    * @version 1.0
    * @since   15-04-2008
    */
    FUNCTION update_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_track_row   IN p1_tracking%ROWTYPE,
        i_old_status  IN VARCHAR2,
        i_flg_isencao IN VARCHAR2 DEFAULT NULL,
        i_mcdt_nature IN VARCHAR2 DEFAULT NULL,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_create p1_tracking.dt_create%TYPE;
        l_round     p1_tracking.round_id%TYPE;
        l_rowids    table_varchar;
        l_track_row p1_tracking%ROWTYPE;
    
        CURSOR c_read(l_round_in p1_tracking.round_id%TYPE) IS
            SELECT COUNT(pt.id_tracking)
              FROM p1_tracking pt
             WHERE pt.id_external_request = i_track_row.id_external_request
               AND pt.id_professional = i_prof.id
               AND pt.flg_type = pk_ref_constant.g_tracking_type_r
               AND pt.round_id = l_round_in
                  -- js 2007-07-19: Only on "read" record by user/round/status
               AND pt.ext_req_status = i_track_row.ext_req_status;
    
        CURSOR c_track IS
            SELECT t.dt_tracking_tstz
              FROM p1_tracking t
             WHERE t.id_external_request = i_track_row.id_external_request
             ORDER BY t.dt_tracking_tstz DESC, t.id_tracking DESC;
    
        l_track_read_count NUMBER;
        l_ref_row          p1_external_request%ROWTYPE;
        l_prof_dest        p1_tracking.id_prof_dest%TYPE;
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
        l_check_date       VARCHAR2(1 CHAR);
        l_id_speciality    p1_tracking.id_speciality%TYPE;
        l_flg_status_old   p1_external_request.flg_status%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    
        l_bdnp_available      sys_config.value%TYPE;
        l_bdnp_presc_tracking bdnp_presc_tracking%ROWTYPE;
    
        l_ref_context t_rec_ref_context;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error            := 'Init update_status / ID_REF=' || i_track_row.id_external_request || ' New FLG_STATUS=' ||
                              i_track_row.ext_req_status || ' FLG_TYPE=' || i_track_row.flg_type || ' i_old_status=' ||
                              i_old_status || ' i_flg_isencao=' || i_flg_isencao || ' i_mcdt_nature=' || i_mcdt_nature;
        l_track_read_count := 0;
        l_ref_context      := pk_ref_utils.get_ref_context;
        l_dt_create        := coalesce(l_ref_context.dt_system_date, i_track_row.dt_create, current_timestamp);
        o_track            := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------        
        g_error := 'SELECT * INTO l_ref_row / ID_REF=' || i_track_row.id_external_request;
        SELECT *
          INTO l_ref_row
          FROM p1_external_request
         WHERE id_external_request = i_track_row.id_external_request
           FOR UPDATE; -- for update - avoid duplicated records in p1_tracking.
    
        l_flg_status_old := l_ref_row.flg_status;
    
        -- Validate if present status -> new status is a valid transition
        g_error := 'Validate status / ID_REF=' || l_ref_row.id_external_request || ' FLG_STATUS OLD=' ||
                   l_flg_status_old || ' FLG_STATUS NEW=' || i_track_row.ext_req_status || ' FLG_STATUS OLD PERMITTED=' ||
                   i_old_status || ' id_workflow_action=' || i_track_row.id_workflow_action || ' flg_type=' ||
                   i_track_row.flg_type || ' id_speciality=' || i_track_row.id_speciality || ' i_prof=' ||
                   pk_utils.to_string(i_prof);
        IF instr(i_old_status, l_flg_status_old, 1) = 0
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error   := 'Process date / ID_REF=' || i_track_row.id_external_request;
        l_dt_tstz := nvl(i_track_row.dt_tracking_tstz, l_dt_create);
    
        -- checking tracking date and returns the correct date
        g_error  := 'Call PK_REF_STATUS.validate_tracking_date / ID_REF=' || i_track_row.id_external_request;
        g_retval := pk_ref_status.validate_tracking_date(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_ref            => i_track_row.id_external_request,
                                                         i_flg_type          => i_track_row.flg_type,
                                                         io_dt_tracking_date => l_dt_tstz,
                                                         o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- avoid records with the same dt_tracking_tstz
        g_error := 'OPEN c_track / ID_REF=' || i_track_row.id_external_request;
        OPEN c_track;
        FETCH c_track
            INTO l_dt_tracking_tstz;
        CLOSE c_track;
    
        g_error := 'ID_REF=' || i_track_row.id_external_request || 'Last tracking date l_dt_tracking_tstz=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, l_dt_tracking_tstz, pk_ref_constant.g_format_date) ||
                   ' new tracking date l_dt_tstz=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, l_dt_tstz, pk_ref_constant.g_format_date) ||
                   ' new create date l_dt_create=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, l_dt_create, pk_ref_constant.g_format_date);
        IF l_dt_tstz IS NOT NULL
           AND l_dt_tracking_tstz IS NOT NULL
        THEN
            g_error      := 'DT_TRACKING / ID_REF=' || i_track_row.id_external_request;
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => l_dt_tstz,
                                                            i_date2 => l_dt_tracking_tstz);
        
            IF l_check_date = pk_ref_constant.g_date_equal
            THEN
                l_dt_tstz := l_dt_tstz + INTERVAL '1' SECOND;
            END IF;
        END IF;
    
        -- getting round id
        g_error  := 'Call pk_ref_status.get_round / ID_REF=' || l_track_row.id_external_request ||
                    ' PREVIOUS_FLG_STATUS=' || l_flg_status_old || ' NEW_FLG_STATUS=' || l_track_row.ext_req_status;
        g_retval := pk_ref_status.get_round(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_flg_status_prev => l_flg_status_old, -- previous flg_status (before this update)
                                            i_track_row       => i_track_row,
                                            o_round_id        => l_round,
                                            o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- If the type is "Status change" or "Send to triage physician" then changes request status
        -- ALERT-21468: added g_tracking_type_c
        g_error := 'ID_REF=' || l_track_row.id_external_request || ' ROUND_ID=' || l_track_row.round_id || ' IF';
        IF instr(pk_ref_constant.g_tracking_type_s || pk_ref_constant.g_tracking_type_p ||
                 pk_ref_constant.g_tracking_type_c,
                 i_track_row.flg_type) > 0
        THEN
        
            g_error                            := 'UPDATE P1_EXTERNAL_REQUEST 1 / ID_REF=' ||
                                                  i_track_row.id_external_request;
            l_ref_row.flg_status               := i_track_row.ext_req_status;
            l_ref_row.id_prof_status           := i_prof.id;
            l_ref_row.dt_status_tstz           := l_dt_tstz;
            l_ref_row.dt_last_interaction_tstz := l_dt_tstz;
        
            -- JS: 2008-07-27: If the old status is O and the new is N then updates referral creation date
            IF l_flg_status_old = pk_ref_constant.g_p1_status_o
               AND i_track_row.ext_req_status = pk_ref_constant.g_p1_status_n
            THEN
                g_error                := 'UPDATE P1_EXTERNAL_REQUEST 2 / ID_REF=' || i_track_row.id_external_request;
                l_ref_row.dt_requested := l_dt_tstz;
            ELSIF l_flg_status_old = pk_ref_constant.g_p1_status_o
                  AND i_track_row.ext_req_status = pk_ref_constant.g_p1_status_p
            THEN
                g_error                := 'UPDATE P1_EXTERNAL_REQUEST 3 / ID_REF=' || i_track_row.id_external_request;
                l_ref_row.dt_requested := l_dt_tstz;
                l_ref_row.flg_migrated := pk_ref_constant.g_no;
                l_ref_row.print_nr     := 1;
            
                IF l_bdnp_available = pk_ref_constant.g_yes
                THEN
                
                    l_bdnp_presc_tracking.id_presc          := l_ref_row.id_external_request;
                    l_bdnp_presc_tracking.flg_presc_type    := pk_ref_constant.g_bdnp_ref_type;
                    l_bdnp_presc_tracking.dt_presc_tracking := i_track_row.dt_tracking_tstz;
                    l_bdnp_presc_tracking.dt_event          := i_track_row.dt_create;
                    l_bdnp_presc_tracking.flg_event_type    := pk_ref_constant.g_bdnp_event_type_i;
                    l_bdnp_presc_tracking.id_prof_event     := i_prof.id;
                    l_bdnp_presc_tracking.id_institution    := i_prof.institution;
                
                    g_error  := 'Call pk_bdnp.set_bdnp_presc_detail / ID_REF=' || i_track_row.id_external_request;
                    g_retval := pk_bdnp.set_bdnp_presc_detail(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_patient     => l_ref_row.id_patient,
                                                              i_episode     => l_ref_row.id_episode,
                                                              i_type        => pk_ref_constant.g_bdnp_ref_type,
                                                              i_presc       => l_ref_row.id_external_request,
                                                              i_flg_isencao => i_flg_isencao, --i_flg_isencao,
                                                              i_mcdt_nature => NULL, --i_mcdt_nature,
                                                              o_error       => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    g_error := 'CALL pk_ia_event_prescription.prescription_mcdt_new / ID_REF=' ||
                               i_track_row.id_external_request;
                    pk_alertlog.log_info(g_error);
                    pk_ia_event_prescription.prescription_mcdt_new(i_id_external_request => i_track_row.id_external_request,
                                                                   i_id_institution      => i_prof.institution);
                    g_error  := 'Call pk_bdnp.set_bdnp_presc_tracking / ID_REF=' || i_track_row.id_external_request;
                    g_retval := pk_bdnp.set_bdnp_presc_tracking(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_bdnp_presc_tracking => l_bdnp_presc_tracking,
                                                                o_error               => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END IF;
            END IF;
        
            -- records destiny professional (forwarded to triage professional, schedule for professional)
            IF i_track_row.id_prof_dest IS NOT NULL
            THEN
                -- JS, 2008-04-15: id_prof_dest - Clean if id is 0
                IF i_track_row.id_prof_dest = 0
                THEN
                    l_prof_dest := NULL;
                ELSE
                    l_prof_dest := i_track_row.id_prof_dest;
                END IF;
            
                -- JS, 2007-10-16: Records triage professional
                g_error                      := 'UPDATE P1_EXTERNAL_REQUEST 4 / ID_REF=' ||
                                                i_track_row.id_external_request;
                l_ref_row.id_prof_redirected := l_prof_dest;
            END IF;
        
            -- records the priority set by the triage professional decision_urg_level
            IF i_track_row.decision_urg_level IS NOT NULL
            THEN
                g_error                      := 'UPDATE P1_EXTERNAL_REQUEST 5 / ID_REF=' ||
                                                i_track_row.id_external_request;
                l_ref_row.decision_urg_level := i_track_row.decision_urg_level;
            END IF;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_u
        THEN
            -- If it's data update then updates dt_last_interaction
            g_error                            := 'UPDATE P1_EXTERNAL_REQUEST 6 / ID_REF=' ||
                                                  i_track_row.id_external_request;
            l_ref_row.dt_last_interaction_tstz := current_timestamp;
        
        END IF;
    
        -- js, 2008-04-14: Centralizes id_dep_clin_serv updates
        IF i_track_row.id_dep_clin_serv IS NOT NULL
        THEN
            l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_ref_row.id_workflow,
                                                                     i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                     i_id_inst_dest => l_ref_row.id_inst_dest);
        
            g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ID_REF=' ||
                        l_ref_row.id_external_request || ' NEW_DCS=' || i_track_row.id_dep_clin_serv || ' OLD_DCS=' ||
                        l_ref_row.id_dep_clin_serv || ' OLD_ID_SPECIALITY=' || l_ref_row.id_speciality ||
                        ' ID_EXTERNAL_SYS=' || l_ref_row.id_external_sys || ' FLG_AVAILABILITY=' || l_flg_availability;
            g_retval := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_id_dep_clin_serv => i_track_row.id_dep_clin_serv,
                                                                         i_id_patient       => l_ref_row.id_patient,
                                                                         i_id_external_sys  => l_ref_row.id_external_sys,
                                                                         i_flg_availability => l_flg_availability,
                                                                         o_id_speciality    => l_id_speciality, -- new spec
                                                                         o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error                    := 'UPDATE P1_EXTERNAL_REQUEST 7 / ID_REF=' || i_track_row.id_external_request;
            l_ref_row.id_dep_clin_serv := i_track_row.id_dep_clin_serv;
            l_ref_row.id_speciality    := l_id_speciality;
        END IF;
    
        -- js, 2008-12-04: process changes to the record
        g_error := 'Call ts_p1_external_request.upd / ID_REF=' || i_track_row.id_external_request;
        ts_p1_external_request.upd(rec_in => l_ref_row, handle_error_in => TRUE, rows_out => l_rowids);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- If there's a "read" record for this user/round/status don't reord again
        IF i_track_row.flg_type = pk_ref_constant.g_tracking_type_r
        THEN
            OPEN c_read(l_round);
            FETCH c_read
                INTO l_track_read_count;
            CLOSE c_read;
        END IF;
    
        -- Insert the record except if it's a "read" record and theres already one for the same user/round/status
        IF l_track_read_count = 0
        THEN
            -- copy i_track_row
            g_error     := 'COPY i_track / ID_REF=' || i_track_row.id_external_request;
            l_track_row := i_track_row;
        
            l_track_row.id_tracking      := ts_p1_tracking.next_key;
            l_track_row.id_institution   := i_prof.institution;
            l_track_row.id_professional  := i_prof.id;
            l_track_row.dt_tracking_tstz := l_dt_tstz;
            l_track_row.dt_create        := l_dt_create;
            l_track_row.id_prof_dest     := l_prof_dest;
            l_track_row.round_id         := l_round;
            l_track_row.id_speciality    := nvl(l_id_speciality, i_track_row.id_speciality);
        
            l_rowids := NULL;
            g_error  := 'INSERT P1_TRACKING / ID_REF=' || l_track_row.id_external_request;
            ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
        
            g_error := 'process_insert P1_TRACKING / ID_REF=' || l_track_row.id_external_request;
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_TRACKING',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        -- Create sys_alert_events (with status validation) only if is a status change.
        -- Remove old sys_alert_events (with status validation) before create new one
        IF l_track_row.flg_type = pk_ref_constant.g_tracking_type_s
           AND l_ref_row.flg_status IN (pk_ref_constant.g_p1_status_x,
                                        pk_ref_constant.g_p1_status_d,
                                        pk_ref_constant.g_p1_status_y,
                                        pk_ref_constant.g_p1_status_h,
                                        pk_ref_constant.g_p1_status_s,
                                        pk_ref_constant.g_p1_status_b)
        THEN
            g_error  := 'call pk_ref_core_internal.set_referral_alerts / I_PAT=' || l_ref_row.id_patient ||
                        'L_REF_ROW.ID_EXTERNAL_REQUEST=' || l_ref_row.id_external_request || 'L_REF_ROW.FLG_STATUS=' ||
                        l_ref_row.flg_status;
            g_retval := pk_ref_core_internal.set_referral_alerts(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_ref_row   => l_ref_row,
                                                                 i_pat       => l_ref_row.id_patient,
                                                                 i_track_row => l_track_row,
                                                                 i_dt_create => l_dt_create,
                                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        o_track.extend();
        o_track(o_track.last) := l_track_row.id_tracking;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'UPDATE_STATUS',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END update_status;

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          professional language id
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change.
    * @param i_old_status    valid status for this update. Single word formed by the letter of valid status.
    * @param o_track         Array of ID_TRACKING transitions
    * @param o_error         an error message, set when return=false
    *
    * @return true if success, false otherwise
    *
    * @author  Joao Sa
    * @version 1.0
    * @since   15-04-2008
    */
    FUNCTION update_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_track_row  IN p1_tracking%ROWTYPE,
        i_old_status IN VARCHAR2,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'Call update_status / ID_REF=' || i_track_row.id_external_request;
        g_retval := update_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_track_row   => i_track_row,
                                  i_old_status  => i_old_status,
                                  i_flg_isencao => NULL,
                                  i_mcdt_nature => NULL,
                                  o_track       => o_track,
                                  o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_status;

    /**
    * Checks if the referral can be canceled
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software
    * @param   i_ref                Referral identifier
    * @param   i_flg_status         Referral status
    * @param   i_id_prof_requested  Professional identifier that requested the referral
    * @param   i_id_inst_dest       Referral dest institution
    * @param   i_dcs                Referral dep_clin_serv identifier
    * @param   i_dt_date            Operation date
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-09-2009
    */
    FUNCTION can_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ref               IN p1_external_request.id_external_request%TYPE,
        i_flg_status        IN p1_external_request.flg_status%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_dcs               IN p1_external_request.id_dep_clin_serv%TYPE,
        i_dt_date           IN p1_tracking.dt_tracking_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_prev_status table_varchar;
        l_res         PLS_INTEGER;
        l_cancel_days PLS_INTEGER;
        l_dt_print    p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_sysdate  p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
        g_error := 'Init can_cancel / ID_REF=' || i_ref;
        --l_dt_sysdate := nvl(i_dt_date, current_timestamp);
        l_dt_sysdate := nvl(i_dt_date, pk_ref_utils.get_sysdate);
    
        ---------------------------
        -- validating professional that requested the referral
        IF i_id_prof_requested <> i_prof.id
           AND i_prof.institution = i_id_inst_dest
           AND pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof) = pk_ref_constant.g_registrar
           AND pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => i_dcs) = pk_ref_constant.g_yes
           AND nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                               i_id_sys_config => pk_ref_constant.g_ref_registrar_can_cancel),
                   pk_ref_constant.g_no) = pk_ref_constant.g_yes
           AND i_flg_status NOT IN (pk_ref_constant.g_p1_status_n, pk_ref_constant.g_p1_status_o)
        THEN
        
            -- check referral status (N,O are already excluded)
            l_prev_status := get_cancel_prev_status(i_lang => i_lang, i_prof => i_prof);
            l_res         := pk_utils.search_table_varchar(i_table => l_prev_status, i_search => i_flg_status);
        
            IF l_res != -1
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        
        ELSIF i_prof.id = i_id_prof_requested
        THEN
        
            ---------------------------
            -- validating flg_status P
            IF i_flg_status = pk_ref_constant.g_p1_status_p
            THEN
                -- ALERT-25811
                g_error       := 'sys_config=REF_CANCEL_PRINTED_REQUEST_DAYS / ID_REF=' || i_ref;
                l_cancel_days := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                       i_id_sys_config => 'REF_CANCEL_PRINTED_REQUEST_DAYS'));
            
                g_error := 'CASE l_cancel_days=' || l_cancel_days;
                CASE
                    WHEN l_cancel_days IS NULL
                         OR l_cancel_days = -1 THEN
                        -- can cancel
                        RETURN pk_ref_constant.g_yes;
                    
                    WHEN l_cancel_days = 0 THEN
                        -- printed referral cannot be canceled
                        RETURN pk_ref_constant.g_no;
                    ELSE
                        -- number of days 
                        g_error    := 'Call pk_p1_utils.get_status_date / ID_REF=' || i_ref;
                        l_dt_print := pk_p1_utils.get_status_date(i_lang       => i_lang,
                                                                  i_id_ext_req => i_ref,
                                                                  i_flg_status => pk_ref_constant.g_p1_status_p);
                    
                        -- Validates if the interval between the date of printing and the operation date is 
                        -- valid to cancel the referral
                        IF (l_dt_print + l_cancel_days) < l_dt_sysdate
                        THEN
                            RETURN pk_ref_constant.g_no;
                        ELSE
                            RETURN pk_ref_constant.g_yes;
                        END IF;
                END CASE;
            END IF;
        
            ---------------------------           
            -- getting referral status from which the referral can be canceled
            g_error       := 'Call get_cancel_prev_status / ID_REF=' || i_ref;
            l_prev_status := get_cancel_prev_status(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'Call pk_utils.search_table_varchar / ID_REF=' || i_ref;
            l_res   := pk_utils.search_table_varchar(i_table => l_prev_status, i_search => i_flg_status);
        
            IF l_res != -1
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_ref_constant.g_no;
    END can_cancel;

    /**
    * Get patient social attributes
    * Used by QueryFlashService.
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_pat Patient id
    * @param   i_prof professional, institution and software ids
    * @param   o_pat patient attributes
    * @param   o_sns "Sistema Nacional de Saude" data
    * @param   o_seq_num external system id for this patient (available if has match)    
    * @param   o_photo url for patient photo    
    * @param   o_id patient id document data (number, expiration date, etc)  
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_pat_soc_att
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_sns     OUT pk_types.cursor_type,
        o_seq_num OUT p1_match.sequential_number%TYPE,
        o_photo   OUT VARCHAR2,
        o_id      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Call pk_ref_list.get_pat_soc_att / ID_PAT=' || i_id_pat;
        RETURN pk_ref_list.get_pat_soc_att(i_lang    => i_lang,
                                           i_id_pat  => i_id_pat,
                                           i_prof    => i_prof,
                                           o_pat     => o_pat,
                                           o_sns     => o_sns,
                                           o_seq_num => o_seq_num,
                                           o_photo   => o_photo,
                                           o_id      => o_id,
                                           o_error   => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_SOC_ATT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_sns);
            pk_types.open_my_cursor(o_id);
            RETURN FALSE;
    END get_pat_soc_att;

    /**
    * Get country attributes
    * Used by QueryFlashService.java
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_country country id
    * @param   o_country cursor
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   12-02-2008
    */
    FUNCTION get_country_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_country_data / i_country=' || i_country;
        RETURN pk_ref_list.get_country_data(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_country => i_country,
                                            o_country => o_country,
                                            o_error   => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_COUNTRY_DATA',
                                                     o_error    => o_error);
    END get_country_data;

    /**
    * Actualizar estado dos pedidos apos actualização dos dados de identificação.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PATIENT Patient id
    * @param   I_PROF professional, institution and software ids
    * @param   I_DATE       Operation date
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   23-10-2007
    */
    FUNCTION update_patient_requests
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error t_error_out;
    
        CURSOR c_p1 IS
            SELECT *
              FROM p1_external_request exr
             WHERE exr.id_patient = i_id_patient
               AND exr.flg_status = pk_ref_constant.g_p1_status_n; -- So considera pedidos em estado 'N'
    
        l_track_tab table_number;
        l_prof_data t_rec_prof_data;
        l_param     table_varchar;
    BEGIN
        g_error        := 'Init update_patient_requests / i_id_patient=' || i_id_patient;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        l_track_tab    := table_number();
    
        g_error  := 'Call pk_ref_core.check_mandatory_data / i_id_patient=' || i_id_patient;
        g_retval := pk_ref_core.check_mandatory_data(i_lang  => i_lang,
                                                     i_prof  => i_prof,
                                                     i_pat   => i_id_patient,
                                                     o_error => l_error);
    
        -- Actualiza a tarefa "completar dados" para todos os pedidos deste paciente
        IF g_retval
        THEN
        
            g_error := 'UPDATE p1_task_done 1 / ID_PROF=' || i_prof.id || ' ID_INSTITUTION=' || i_prof.institution;
            UPDATE p1_task_done
               SET flg_task_done     = pk_ref_constant.g_p1_task_done_tdone_y,
                   dt_completed_tstz = g_sysdate_tstz,
                   id_prof_exec      = i_prof.id,
                   id_inst_exec      = i_prof.institution
             WHERE id_external_request IN (SELECT id_external_request
                                             FROM p1_external_request
                                            WHERE id_patient = i_id_patient)
               AND flg_type = pk_ref_constant.g_p1_task_done_type_z
               AND flg_task_done = pk_ref_constant.g_p1_task_done_tdone_n;
        
        ELSE
            g_error := 'UPDATE p1_task_done 2 / ID_PROF=' || i_prof.id || ' ID_INSTITUTION=' || i_prof.institution;
            UPDATE p1_task_done
            -- js, 2007-08-21 - NÆo deve acontecer
               SET flg_task_done     = pk_ref_constant.g_p1_task_done_tdone_n,
                   dt_completed_tstz = g_sysdate_tstz,
                   id_prof_exec      = i_prof.id,
                   id_inst_exec      = i_prof.institution
             WHERE id_external_request IN (SELECT id_external_request
                                             FROM p1_external_request
                                            WHERE id_patient = i_id_patient)
               AND flg_type = pk_ref_constant.g_p1_task_done_type_z
               AND flg_task_done = pk_ref_constant.g_p1_task_done_tdone_y;
        END IF;
    
        g_error  := 'Calling pk_ref_core.get_prof_data / i_id_patient=' || i_id_patient;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Tratar estado dos pedidos do paciente
        g_error := 'OPEN C_P1 / i_id_patient=' || i_id_patient;
        FOR w IN c_p1
        LOOP
        
            IF w.id_workflow IS NULL
            THEN
            
                -- Se o pedido est  em estado (N)ew deve ser passar a emitido ou triagem
                g_error  := 'Call issue_request / ID_REF=' || w.id_external_request;
                g_retval := issue_request(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_ext_req => w.id_external_request,
                                          i_date    => g_sysdate_tstz,
                                          o_track   => l_track_tab,
                                          o_error   => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            ELSE
            
                g_error                      := 'Call pk_ref_core.get_prof_func / ID_REF=' || w.id_external_request ||
                                                ' ID_DEP_CLIN_SERV=' || w.id_dep_clin_serv;
                l_prof_data.id_functionality := pk_ref_core.get_prof_func(i_lang => i_lang,
                                                                          i_prof => i_prof,
                                                                          i_dcs  => w.id_dep_clin_serv);
            
                g_error := 'Calling pk_ref_core.init_param_tab / ID_REF=' || w.id_external_request;
                l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_ext_req            => w.id_external_request,
                                                      i_id_patient         => w.id_patient,
                                                      i_id_inst_orig       => w.id_inst_orig,
                                                      i_id_inst_dest       => w.id_inst_dest,
                                                      i_id_dep_clin_serv   => w.id_dep_clin_serv,
                                                      i_id_speciality      => w.id_speciality,
                                                      i_flg_type           => w.flg_type,
                                                      i_decision_urg_level => w.decision_urg_level,
                                                      i_id_prof_requested  => w.id_prof_requested,
                                                      i_id_prof_redirected => w.id_prof_redirected,
                                                      i_id_prof_status     => w.id_prof_status,
                                                      i_external_sys       => w.id_external_sys,
                                                      i_flg_status         => w.flg_status);
            
                g_error  := 'Call pk_ref_core.process_auto_transition / WF=' || w.id_workflow || ' ID_REF=' ||
                            w.id_external_request;
                g_retval := pk_ref_core.process_auto_transition(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_prof_data => l_prof_data,
                                                                i_id_ref    => w.id_external_request,
                                                                i_date      => g_sysdate_tstz,
                                                                io_param    => l_param,
                                                                io_track    => l_track_tab,
                                                                o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_PATIENT_REQUESTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_patient_requests;

    /**
    * Pesquisar por pacientes
    *
    * @param I_LANG Lingua registada como preferencia do profissional
    * @param I_ID_SYS_BTN_CRIT Lista de ID'S de crit¨rios de pesquisa.
    * @param I_CRIT_VAL lista de valores dos crit¨rios de pesquisa
    * @param I_PROF profissional q regista
    * @param I_PROF_CAT_TYPE Tipo de categoria do profissional, tal como e retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param o_msg_title titulo a mostrar junto de o_msg
    * @param o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param O_PAT - resultados
    * @param O_ERROR - erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_pat
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error  := 'Call  pk_ref_list.get_search_pat / i_prof_cat_type=' || i_prof_cat_type;
        g_retval := pk_ref_list.get_search_pat(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_crit_id_tab   => i_id_sys_btn_crit,
                                               i_crit_val_tab  => i_crit_val,
                                               i_prof_cat_type => i_prof_cat_type,
                                               o_flg_show      => o_flg_show,
                                               o_msg           => o_msg,
                                               o_msg_title     => o_msg_title,
                                               o_button        => o_button,
                                               o_pat           => o_pat,
                                               o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_SEARCH_PAT', o_error);
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_SEARCH_PAT', o_error);
        WHEN l_exception THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'COMMON_M015');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'COMMON_M015',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_SEARCH_PAT',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_pat);
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SEARCH_PAT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exr_row IN p1_external_request%ROWTYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_wc
        (
            x_inst      institution.id_institution%TYPE,
            x_spec      p1_speciality.id_speciality%TYPE,
            x_inst_orig institution.id_institution%TYPE,
            x_inst_dest institution.id_institution%TYPE,
            x_ext_req   p1_external_request.id_external_request%TYPE
        ) IS
            SELECT DISTINCT to_number(wc.value) id
              FROM p1_workflow_config wc, p1_external_request per -- JB 2009-05-21 ALERT-29134
             WHERE wc.code_workflow_config = pk_ref_constant.g_adm_forward_dcs
               AND wc.id_institution IN (x_inst, 0)
               AND wc.id_speciality IN (x_spec, 0)
               AND wc.id_inst_dest IN (x_inst_dest, 0)
               AND wc.id_inst_orig IN (x_inst_orig, 0)
               AND per.id_external_request = x_ext_req
               AND nvl(per.flg_forward_dcs, pk_ref_constant.g_no) <> pk_ref_constant.g_yes;
    
        l_count NUMBER DEFAULT 0;
    BEGIN
    
        g_error := 'open c_wc / ID_REF=' || i_exr_row.id_external_request;
        FOR w IN c_wc(i_exr_row.id_inst_dest,
                      i_exr_row.id_speciality,
                      i_exr_row.id_inst_orig,
                      i_exr_row.id_inst_dest,
                      i_exr_row.id_external_request)
        LOOP
            -- guarda id do primeiro
            IF l_count = 0
            THEN
                o_id := w.id;
            END IF;
        
            l_count := l_count + 1;
        END LOOP;
    
        -- So retorna id se for so um
        IF l_count != 1
        THEN
            o_id := NULL;
        END IF;
        o_count := l_count;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                                     o_error    => o_error);
    END get_clin_serv_forward_count;

    /**
    * Issues request, i.e. updates request status
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   i_mode           Change (S)ame or (O)ther Institution
    * @param   i_date           Operation date    
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa 
    * @version 1.0
    * @since   30-04-2008
    */
    FUNCTION set_issue_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exr_row  IN p1_external_request%ROWTYPE,
        i_mode     IN VARCHAR2,
        i_dcs_dest IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track    OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_match(x p1_external_request.id_external_request%TYPE) IS
            SELECT m.id_match
              FROM p1_external_request exr, p1_match m
             WHERE exr.id_external_request = x
               AND exr.id_patient = m.id_patient
               AND exr.id_inst_dest = m.id_institution
                  -- js, 2007-07-31 - Rematch
               AND m.flg_status = pk_ref_constant.g_match_status_a;
    
        l_match             p1_match.id_match%TYPE;
        l_last_triage_track p1_tracking%ROWTYPE;
        l_track_row         p1_tracking%ROWTYPE;
        l_dcs_count         NUMBER DEFAULT 0;
        l_old_status        VARCHAR2(10 CHAR);
        l_id_dep_clin_serv  p1_external_request.id_dep_clin_serv%TYPE;
        l_track_tab         table_number;
    
        l_wf_ref_med sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'REFERRAL_WF_MED', i_prof => i_prof);
    
    BEGIN
        g_error        := 'Init set_issue_status / ID_REF=' || i_exr_row.id_external_request || ' FLG_STATUS=' ||
                          i_exr_row.flg_status || ' i_mode=' || i_mode || ' i_dcs_dest=' || i_dcs_dest;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        g_error  := 'Call pk_ref_status.get_dcs_info / ID_REF=' || i_exr_row.id_external_request ||
                    ' ID_DEP_CLIN_SERV=' || i_exr_row.id_dep_clin_serv || ' i_dcs_dest=' || i_dcs_dest || ' i_mode=' ||
                    i_mode;
        g_retval := pk_ref_status.get_dcs_info(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_ref_row   => i_exr_row,
                                               i_dcs       => i_dcs_dest,
                                               i_mode      => i_mode,
                                               o_dcs_count => l_dcs_count,
                                               o_track_dcs => l_track_row.id_dep_clin_serv,
                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Registar estado emitido
        g_error                         := 'UPDATE STATUS / ID_REF=' || i_exr_row.id_external_request;
        l_track_row.id_external_request := i_exr_row.id_external_request;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_i;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz + INTERVAL '1' SECOND;
    
        IF i_mode = 'S'
        THEN
            l_old_status                   := pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_b ||
                                              pk_ref_constant.g_p1_status_l;
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
        ELSE
        
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_di);
            l_track_row.id_inst_dest       := i_exr_row.id_inst_dest;
            -- Incluidos estados 'A', 'S' e 'M' para pedidos que sao agendados para uma instituicao diferente sem terem sido triados
            l_old_status := pk_ref_constant.g_p1_status_r || pk_ref_constant.g_p1_status_t ||
                            pk_ref_constant.g_p1_status_a || pk_ref_constant.g_p1_status_s ||
                            pk_ref_constant.g_p1_status_m || pk_ref_constant.g_p1_status_l;
        END IF;
    
        g_error  := 'UPDATE_STATUS / ID_REF=' || i_exr_row.id_external_request;
        g_retval := update_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_track_row   => l_track_row,
                                  i_old_status  => l_old_status,
                                  i_flg_isencao => NULL,
                                  i_mcdt_nature => NULL,
                                  o_track       => l_track_tab,
                                  o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_track := o_track MULTISET UNION l_track_tab;
    
        -- Validar match --
        g_error := 'OPEN C_MATCH / ID_REF=' || i_exr_row.id_external_request;
        OPEN c_match(i_exr_row.id_external_request);
        FETCH c_match
            INTO l_match;
        g_found := c_match%FOUND;
        CLOSE c_match;
    
        IF g_found
           OR l_wf_ref_med = pk_alert_constant.g_yes -- Tem match na instituicao destino
          -- if its the clerk intervention is not mandatory and there's none or only one dcs configured 
          -- (if there's none in p1_workflow_config its using the default)
           AND pk_ref_core.get_workflow_config(i_prof,
                                                  pk_ref_constant.g_adm_required,
                                                  i_exr_row.id_speciality,
                                                  i_exr_row.id_inst_dest,
                                                  i_exr_row.id_inst_orig,
                                                  nvl(i_exr_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp)) =
           pk_ref_constant.g_no
           AND l_dcs_count = 1
        THEN
        
            -- JS, 2007-DEZ-20: Obter ultimo estado de triagem (R ou T, se ja esteve em triagem)
            g_error             := 'Call pk_p1_utils.get_last_triage_status / ID_REF=' || i_exr_row.id_external_request;
            l_last_triage_track := pk_p1_utils.get_last_triage_status(i_exr_row);
        
            g_error                         := 'UPDATE STATUS T / ID_REF=' || i_exr_row.id_external_request;
            l_track_row.id_external_request := i_exr_row.id_external_request;
            l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_t;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz + INTERVAL '2' SECOND;
        
            g_retval := update_status(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_track_row   => l_track_row,
                                      i_old_status  => pk_ref_constant.g_p1_status_i,
                                      i_flg_isencao => NULL,
                                      i_mcdt_nature => NULL,
                                      o_track       => l_track_tab,
                                      o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            o_track := o_track MULTISET UNION l_track_tab;
        
            -- JS, 2007-DEZ-20: Se ja esteve em triagem e foi reencaminhado deve ficar reencaminhado
            IF l_last_triage_track.ext_req_status = pk_ref_constant.g_p1_status_r
            THEN
            
                -- get id_dep_clin_serv when referral was forwarded
                g_error := 'SELECT id_dep_clin_serv / ID_REF=' || i_exr_row.id_external_request;
                BEGIN
                    SELECT id_dep_clin_serv
                      INTO l_id_dep_clin_serv
                      FROM (SELECT id_dep_clin_serv
                              FROM p1_tracking t
                             WHERE t.id_external_request = l_last_triage_track.id_external_request
                               AND t.dt_tracking_tstz < l_last_triage_track.dt_tracking_tstz
                               AND t.id_dep_clin_serv IS NOT NULL
                             ORDER BY t.dt_tracking_tstz DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_dep_clin_serv := NULL;
                END;
            
                g_error := 'l_id_dep_clin_serv=' || l_id_dep_clin_serv || ' l_track_row.id_dep_clin_serv=' ||
                           l_track_row.id_dep_clin_serv || ' / ID_REF=' || i_exr_row.id_external_request;
                IF l_id_dep_clin_serv = l_track_row.id_dep_clin_serv
                THEN
                
                    g_error                         := 'UPDATE STATUS R / ID_REF=' || i_exr_row.id_external_request;
                    l_track_row.id_external_request := i_exr_row.id_external_request;
                    l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_r;
                    l_track_row.flg_type            := pk_ref_constant.g_tracking_type_p;
                    l_track_row.id_prof_dest        := l_last_triage_track.id_prof_dest;
                    l_track_row.dt_tracking_tstz    := g_sysdate_tstz + INTERVAL '3' SECOND;
                    l_track_row.id_dep_clin_serv    := NULL;
                
                    g_retval := update_status(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_track_row   => l_track_row,
                                              i_old_status  => pk_ref_constant.g_p1_status_t,
                                              i_flg_isencao => NULL,
                                              i_mcdt_nature => NULL,
                                              o_track       => l_track_tab,
                                              o_error       => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    o_track := o_track MULTISET UNION l_track_tab;
                
                END IF;
            END IF; -- R
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_ISSUE_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_issue_status;

    /**
    * Issues request, i.e. updates request status
    * Must have mandatory data completed and all task must be completed.
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_req       Referral identifier
    * @param   I_DATE          Operation date
    * @param   o_track         Array of ID_TRACKING transitions
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-12-2007
    */
    FUNCTION issue_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_date    IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track   OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_task_count(x p1_external_request.id_external_request%TYPE) IS
            SELECT COUNT(1)
              FROM p1_task_done td
             WHERE td.id_external_request = x
               AND td.flg_task_done = pk_ref_constant.g_p1_task_done_tdone_n
               AND td.flg_type IN (pk_ref_constant.g_p1_task_done_type_z, pk_ref_constant.g_p1_task_done_type_s);
    
        l_count   PLS_INTEGER;
        l_exr_row p1_external_request%ROWTYPE;
    BEGIN
        g_error        := 'Init issue_request / ID_REF=' || i_ext_req;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        -- Validar dados de identificação do paciente --
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Tem que ter os dados do paciente preenchidos
        g_error  := 'Call pk_ref_core.check_mandatory_data / ID_REF=' || l_exr_row.id_external_request;
        g_retval := pk_ref_core.check_mandatory_data(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     i_pat    => l_exr_row.id_patient,
                                                     i_id_ref => l_exr_row.id_external_request,
                                                     o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RETURN TRUE;
        END IF;
    
        -- Validar tarefas --
    
        -- Numero de tarefas por completar (Tipo P (completar dados) ou para S (agendamento))
        g_error := 'OPEN c_task_count / ID_REF=' || l_exr_row.id_external_request;
        OPEN c_task_count(i_ext_req);
        FETCH c_task_count
            INTO l_count;
        g_found := c_task_count%FOUND;
        CLOSE c_task_count;
    
        IF l_count = 0 -- There are no tasks left...
        THEN
            g_error  := 'Call set_issue_status / ID_REF=' || l_exr_row.id_external_request || ' MODE=S';
            g_retval := set_issue_status(i_lang    => i_lang,
                                         i_prof    => i_prof,
                                         i_exr_row => l_exr_row,
                                         i_mode    => 'S', -- (S)ame institution
                                         --i_dcs_dest => NULL,
                                         i_dcs_dest => l_exr_row.id_dep_clin_serv, -- ALERT-231108: sub-speciality
                                         i_date     => g_sysdate_tstz,
                                         o_track    => o_track,
                                         o_error    => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'ISSUE_REQUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END issue_request;

    /**
    * Return sequential_number for the request
    *
    * This function is used by the servlet of the report interface to confirm that the
    * request comes from a reliable source.
    *
    * @param   i_ext_req request id
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo’o S
    * @version 1.0
    * @since   17-02-2007
    */
    FUNCTION get_req_data
    (
        --i_prof    IN profissional,
        --i_lang    IN LANGUAGE.id_language%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang language.id_language%TYPE;
    BEGIN
    
        OPEN o_data FOR
            SELECT m.sequential_number, m.id_institution
              FROM p1_external_request exr, p1_match m
             WHERE exr.id_external_request = i_ext_req
               AND exr.id_patient = m.id_patient
               AND exr.id_inst_dest = m.id_institution
                  -- js, 2007-07-31 - Rematch
               AND m.flg_status = pk_ref_constant.g_match_status_a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_REQ_DATA',
                                                     o_error    => o_error);
    END get_req_data;

    /**
    * Changes the destination institution 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier    
    * @param   i_inst_dest new   New dest institution identifier
    * @param   i_dep_clin_serv   Destination service/speciality
    * @param   i_notes           Notes             
    * @param   i_date            Date of status change   
    * @param   o_track           Array of ID_TRACKING transitions    
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_dest_institution_int
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        i_dcs_dest  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr_row p1_external_request%ROWTYPE;
        --CURSOR c_validate_inst
        -- (
        --     i_inst_old institution.id_institution%TYPE,
        --     i_inst_new institution.id_institution%TYPE
        -- ) IS
        --     SELECT COUNT(1)
        --       FROM institution son, institution par, institution sib
        --      WHERE son.id_institution = i_inst_old
        --        AND son.id_parent = par.id_institution
        --        AND par.flg_type = pk_ref_constant.g_hospital
        --        AND sib.id_parent = par.id_institution
        --        AND sib.id_institution = i_inst_new
        --        AND sib.id_institution != i_inst_old;
    
        --l_aux          NUMBER;
        l_rowids       table_varchar;
        l_sysdate_tstz p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
        g_error        := 'Init set_dest_institution_int / ID_REF=' || i_ext_req;
        l_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- ALERT-25768: Enquanto nao existir configurados centros hospitalares, nao se pode fazer esta validacao
        /*
        g_error := 'Validate inst_dest';
        OPEN c_validate_inst(l_exr_row.id_inst_dest, i_inst_dest);
        FETCH c_validate_inst
            INTO l_aux;
        CLOSE c_validate_inst;
        
        IF l_aux = 0
        THEN
            g_error := 'Invalid Institution';
            RAISE g_exception;
        END IF;
        */
    
        g_error := 'Call ts_p1_external_request.upd / ID_REF=' || i_ext_req;
        ts_p1_external_request.upd(id_external_request_in => i_ext_req,
                                   id_inst_dest_in        => i_inst_dest,
                                   handle_error_in        => TRUE,
                                   rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_exr_row.id_inst_orig := i_prof.institution; -- Actualizar id_inst_orig. Nao vai ser alterado mas e' usado para obter configurações me p1_workflow_config
        l_exr_row.id_inst_dest := i_inst_dest; -- Actualizar id_inst_dest em l_exr_row !!
    
        g_error  := 'Call set_issue_status / ID_REF=' || l_exr_row.id_external_request || ' MODE=O ID_DCS=' ||
                    i_dcs_dest;
        g_retval := set_issue_status(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_exr_row  => l_exr_row,
                                     i_mode     => 'O', --(O)ther institution
                                     i_dcs_dest => i_dcs_dest,
                                     i_date     => l_sysdate_tstz,
                                     o_track    => o_track,
                                     o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_DEST_INSTITUTION_INT',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_dest_institution_int;

    /**
    * Changes the destination institution 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier    
    * @param   i_inst_dest new   New dest institution identifier
    * @param   i_dep_clin_serv   Destination service/speciality             
    * @param   i_date            Date of status change   
    * @param   o_track           Array of ID_TRACKING transitions    
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_dest_institution
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        i_dcs_dest  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error  := 'Call set_dest_institution_int / ID_REF=' || i_ext_req || ' ID_INST_DEST=' || i_inst_dest ||
                    ' ID_DCS=' || i_dcs_dest;
        g_retval := set_dest_institution_int(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_ext_req   => i_ext_req,
                                             i_inst_dest => i_inst_dest,
                                             i_dcs_dest  => i_dcs_dest,
                                             --i_date      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                             o_track => o_track,
                                             o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_DEST_INSTITUTION',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_dest_institution;

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar, -- (TABELA, ID[VAL], [CODE_DOMAIN])
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_ref_core.get_description(i_lang  => i_lang,
                                           i_prof  => i_prof,
                                           i_key   => i_key,
                                           o_id    => o_id,
                                           o_desc  => o_desc,
                                           o_error => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DESCRIPTION',
                                                     o_error    => o_error);
    END get_description;

    /**
    * Returns referral status from which the referral can be canceled
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    *
    * @RETURN  table_varchar containing referral status from which it can be canceled
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-09-2009
    */
    FUNCTION get_cancel_prev_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar IS
        l_result table_varchar;
    BEGIN
        g_error  := 'Init get_cancel_prev_status';
        l_result := table_varchar(pk_ref_constant.g_p1_status_n,
                                  pk_ref_constant.g_p1_status_i,
                                  pk_ref_constant.g_p1_status_b,
                                  pk_ref_constant.g_p1_status_t,
                                  pk_ref_constant.g_p1_status_a,
                                  pk_ref_constant.g_p1_status_r,
                                  pk_ref_constant.g_p1_status_d,
                                  pk_ref_constant.g_p1_status_o,
                                  pk_ref_constant.g_p1_status_p,
                                  pk_ref_constant.g_p1_status_g,
                                  pk_ref_constant.g_p1_status_l,
                                  pk_ref_constant.g_p1_status_z);
        RETURN l_result;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_varchar();
    END get_cancel_prev_status;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_core;
/
