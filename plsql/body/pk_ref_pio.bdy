CREATE OR REPLACE PACKAGE BODY pk_ref_pio AS

    g_error         VARCHAR2(1000 CHAR);
    g_found         BOOLEAN;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION; -- do not process error with PK_ALERT_EXCEPTIONS
    g_sysdate_tstz       TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_flg_status_allowed sys_config.value%TYPE;
    g_max_days           sys_config.value%TYPE;
    g_retval             BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    PROCEDURE reset_vars IS
    BEGIN
    
        --g_sysdate_tstz := NULL;
    
        -- error codes
        g_error_code := NULL;
        g_error_desc := NULL;
        g_flg_action := NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'reset_vars';
            pk_alertlog.log_error(g_error);
    END reset_vars;

    /**
    * Setting professional interface based on i_prof parameter
    *
    * @param   i_prof             Profissional institution and software
    *
    * @return  professional interface
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION set_prof_interface(i_prof IN profissional) RETURN profissional IS
        l_id NUMBER;
    BEGIN
        g_error := 'Calling pk_sysconfig.get_config ' || pk_ref_constant.g_sc_intf_prof_id;
        l_id    := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_intf_prof_id,
                                                     i_prof.institution,
                                                     i_prof.software));
    
        RETURN profissional(l_id, i_prof.institution, i_prof.software);
    END set_prof_interface;

    /**
    * Checks if referral is ready to be sent to SIGLIC
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_flg_status       Referral status
    * @param   i_dt_schedule_tstz Referral appointment date
    * @param   i_dt_requested     Referral requested date
    *
    * @return  {*} 'Y' referral can be sent to SIGLIC {*} 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION check_pio_cond
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN p1_external_request.flg_status%TYPE,
        i_dt_schedule_tstz IN schedule.dt_begin_tstz%TYPE,
        i_dt_requested     IN p1_external_request.dt_requested%TYPE
    ) RETURN VARCHAR2 IS
        l_elapsed NUMBER;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        IF g_flg_status_allowed IS NULL
        THEN
            g_error              := 'Calling pk_sysconfig.get_config ' || pk_ref_constant.g_sc_pio_ref_status;
            g_flg_status_allowed := pk_sysconfig.get_config(pk_ref_constant.g_sc_pio_ref_status, i_prof);
        END IF;
    
        IF g_max_days IS NULL
        THEN
            g_error    := 'Calling pk_sysconfig.get_config ' || pk_ref_constant.g_sc_pio_max_days;
            g_max_days := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_pio_max_days, i_prof));
        END IF;
    
        --pk_alertlog.log_debug('g_flg_status_allowed=' || g_flg_status_allowed || '|g_max_days=' || g_max_days);
    
        ----------------------
        -- VAL
        ----------------------
        g_error := 'FLG_STATUS';
        IF instr(g_flg_status_allowed, i_flg_status, 1) = 0
        THEN
            RETURN pk_ref_constant.g_no;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        IF i_flg_status IN (pk_ref_constant.g_p1_status_m, pk_ref_constant.g_p1_status_s)
        THEN
            g_error   := 'ELAPSED';
            l_elapsed := trunc(i_dt_schedule_tstz) - trunc(i_dt_requested);
        
            g_error := 'MAX_DAYS ' || g_max_days;
            IF l_elapsed > to_number(g_max_days)
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        ELSE
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn('PK_REF_PIO.CHECK_PIO_COND / ' || g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_pio_cond;

    /**    
    * Checks if referral is ready to be sent to SIGLIC
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referral identification
    *
    * @return  {*} 'Y' referral can be sent to SIGLIC {*} 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION check_pio_cond
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_ref IS
            SELECT exr.flg_status, s.dt_begin_tstz, exr.dt_requested
              FROM p1_external_request exr
              LEFT JOIN schedule s
                ON (s.id_schedule = exr.id_schedule AND s.flg_status = pk_ref_constant.g_active)
             WHERE exr.id_external_request = i_ext_req;
    
        l_flg_status       p1_external_request.flg_status%TYPE;
        l_dt_schedule_tstz schedule.dt_begin_tstz%TYPE;
        l_dt_requested     p1_external_request.dt_requested%TYPE;
        l_prof             profissional;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'l_prof';
        l_prof  := set_prof_interface(i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error := 'OPEN c_ref';
        OPEN c_ref;
    
        g_error := 'FETCH c_ref';
        FETCH c_ref
            INTO l_flg_status, l_dt_schedule_tstz, l_dt_requested;
        g_found := c_ref%FOUND;
    
        g_error := 'CLOSE c_ref';
        CLOSE c_ref;
    
        g_error := 'Calling check_pio_cond';
        RETURN check_pio_cond(i_lang             => i_lang,
                              i_prof             => l_prof,
                              i_flg_status       => l_flg_status,
                              i_dt_schedule_tstz => l_dt_schedule_tstz,
                              i_dt_requested     => l_dt_requested);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn('PK_REF_PIO.CHECK_PIO_COND / ' || g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_pio_cond;

    /**
    * Changes referral status to b(L)ocked in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional id, institution, software
    * @param   i_prof_data        Profissional profile template, category and functionality 
    * @param   i_ref_row          P1_EXTERNAL_REQUEST rowtype   
    * @param   i_date             Blocking date
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION set_ref_blocked
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_tab       table_number;
        l_pio_block_notes p1_detail.text%TYPE;
        l_dt_date         p1_tracking.dt_tracking_tstz%TYPE;
        l_param           table_varchar;
        l_track_row       p1_tracking%ROWTYPE;
        l_old_status      VARCHAR2(50 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error   := 'Init set_ref_blocked';
        l_dt_date := nvl(i_date, current_timestamp);
        reset_vars;
        l_track_tab := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error           := 'Calling pk_message.get_message ' || pk_ref_constant.g_sm_block_notes;
        l_pio_block_notes := pk_message.get_message(i_lang, pk_ref_constant.g_sm_block_notes);
    
        ----------------------
        -- FUNC
        ----------------------
        -- changing referral status to b(L)ocked
        IF i_ref_row.id_workflow IS NULL
        THEN
        
            -- b(L)ock referral                       
            IF g_flg_status_allowed IS NULL
            THEN
                g_error              := 'Calling pk_sysconfig.get_config ' || pk_ref_constant.g_sc_pio_ref_status;
                g_flg_status_allowed := pk_sysconfig.get_config(pk_ref_constant.g_sc_pio_ref_status, i_prof);
            END IF;
        
            l_old_status := g_flg_status_allowed;
        
            g_error                         := 'UPDATE STATUS ' || pk_ref_constant.g_p1_status_l;
            l_track_row.id_external_request := i_ref_row.id_external_request;
            l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_l;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := l_dt_date;
            l_track_row.id_professional     := i_prof.id;
            l_track_row.id_institution      := i_prof.institution;
            l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_l);
        
            g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                        l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
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
        
        ELSE
        
            g_error  := 'Calling pk_ref_core.process_transition / WF=' ||
                        nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_l || ' ID_REF=' || i_ref_row.id_external_request ||
                        ' PROF_PRF_TEMPL=' || i_prof_data.id_profile_template || ' PROF_FUNC=' ||
                        i_prof_data.id_functionality || ' PROF_CAT=' || i_prof_data.id_category;
            g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_prof_data  => i_prof_data,
                                                        i_action     => pk_ref_constant.g_ref_action_l, -- BLOCK
                                                        i_status_end => NULL,
                                                        i_date       => l_dt_date,
                                                        i_ref_row    => i_ref_row,
                                                        io_param     => l_param,
                                                        io_track     => l_track_tab,
                                                        o_error      => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- inserting notes 
        g_error  := 'Call pk_ref_core.set_detail / ID_REF=' || i_ref_row.id_external_request || ' DETAIL_TYPE=' ||
                    pk_ref_constant.g_detail_type_nblc || ' DETAIL_TEXT=' || l_pio_block_notes;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_ext_req       => i_ref_row.id_external_request,
                                           i_prof          => i_prof,
                                           i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                pk_ref_constant.g_detail_type_nblc,
                                                                                                l_pio_block_notes,
                                                                                                pk_ref_constant.g_detail_flg_i,
                                                                                                NULL)),
                                           i_ext_req_track => l_track_tab(1), -- first iteration
                                           i_date          => l_dt_date,
                                           o_error         => o_error);
    
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
                                              i_function => 'SET_REF_BLOCKED',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_blocked;

    /**    
    * Changes referral status to previous status before b(L)ocked in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_prof_data        Profissional profile template, category and functionality 
    * @param   i_ref_row          P1_EXTERNAL_REQUEST rowtype   
    * @param   i_date             Blocking date
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION set_ref_unblocked
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_tab  table_number;
        l_dt_date    p1_tracking.dt_tracking_tstz%TYPE;
        l_param      table_varchar;
        l_track_row  p1_tracking%ROWTYPE;
        l_old_status VARCHAR2(50 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error   := 'Init set_ref_unblocked';
        l_dt_date := nvl(i_date, current_timestamp);
        reset_vars;
        l_track_tab := table_number();
    
        ----------------------
        -- FUNC
        ----------------------
    
        IF i_ref_row.flg_status != pk_ref_constant.g_p1_status_l
        THEN
            -- b(L)ocked
            g_error := g_error || ' / FLG_STATUS=' || i_ref_row.flg_status;
            RAISE g_exception;
        END IF;
    
        -- unblocking referral in CTH
        IF i_ref_row.id_workflow IS NULL
        THEN
        
            l_old_status := pk_ref_constant.g_p1_status_l;
        
            g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                          i_prof   => i_prof,
                                                          i_id_ref => i_ref_row.id_external_request,
                                                          o_data   => l_track_row,
                                                          o_error  => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            g_error                         := 'UPDATE STATUS ' || l_track_row.ext_req_status;
            l_track_row.id_external_request := i_ref_row.id_external_request;
            --l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz   := l_dt_date;
            l_track_row.id_professional    := i_prof.id;
            l_track_row.id_institution     := i_prof.institution;
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_unl);
        
            g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request || ' FLG_STATUS=' ||
                        l_track_row.ext_req_status || ' FLG_TYPE=' || l_track_row.flg_type;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
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
        
        ELSE
        
            g_error  := 'Calling pk_ref_core.process_transition / WF=' ||
                        nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_unl || ' ID_REF=' || i_ref_row.id_external_request ||
                        ' PROF_PRF_TEMPL=' || i_prof_data.id_profile_template || ' PROF_FUNC=' ||
                        i_prof_data.id_functionality || ' PROF_CAT=' || i_prof_data.id_category;
            g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_prof_data  => i_prof_data,
                                                        i_action     => pk_ref_constant.g_ref_action_unl, -- UNBLOCK
                                                        i_status_end => NULL,
                                                        i_date       => l_dt_date,
                                                        i_ref_row    => i_ref_row,
                                                        io_param     => l_param,
                                                        io_track     => l_track_tab,
                                                        o_error      => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error_code := pk_ref_constant.g_ref_error_1003; -- Error unblocking Referral request
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_UNBLOCKED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_unblocked;

    /**    
    * Updates referral pio status registering changes in ref_pio_tracking.
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_track_row        Referral PIO data
    * @param   i_old_status       Valid status for this update. Single word formed by the letter of valid status.
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION update_status_pio
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_track_row  IN ref_pio_tracking%ROWTYPE,
        i_old_status IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref_pio(i_ext_req IN ref_pio.id_external_request%TYPE) IS
            SELECT flg_status_pio
              FROM ref_pio
             WHERE id_external_request = i_track_row.id_external_request
               FOR UPDATE;
    
        l_ref_pio_status ref_pio.flg_status_pio%TYPE;
        l_dt_tstz        ref_pio_tracking.dt_ref_pio_tracking_tstz%TYPE;
        l_new_status_pio ref_pio.flg_status_pio%TYPE;
        l_insert_track   PLS_INTEGER := 0;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'INIT';
        reset_vars;
        l_dt_tstz        := nvl(i_track_row.dt_ref_pio_tracking_tstz, current_timestamp);
        l_new_status_pio := i_track_row.flg_status_pio;
    
        ----------------------
        -- FUNC
        ----------------------
        -- checking status change
        g_error := 'OPEN c_ref_pio';
        OPEN c_ref_pio(i_track_row.id_external_request);
    
        g_error := 'FETCH c_ref_pio';
        FETCH c_ref_pio
            INTO l_ref_pio_status;
        g_found := c_ref_pio%FOUND;
    
        g_error := 'CLOSE c_ref_pio';
        CLOSE c_ref_pio;
    
        IF NOT g_found
        THEN
            -- referral doesn't exist in the application
        
            IF i_old_status IS NULL
            THEN
                g_error := 'INSERT REF_PIO ID=' || i_track_row.id_external_request;
                INSERT INTO ref_pio
                    (id_external_request,
                     flg_status_pio,
                     dt_ref_pio_tstz,
                     dt_untransf_tstz,
                     id_professional,
                     id_institution)
                VALUES
                    (i_track_row.id_external_request, l_new_status_pio, l_dt_tstz, NULL, i_prof.id, i_prof.institution);
            
                l_insert_track := 1;
            ELSE
                -- cannot create referral
                g_error      := 'Cannot create referral id=' || i_track_row.id_external_request || ': ' ||
                                l_new_status_pio;
                g_error_code := pk_ref_constant.g_ref_error_1002; -- Referral request doesn't exist in PIO (but do exists in Referral)
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSE
            -- referral exists in the application
            l_insert_track := 1;
        
            -- updating pio status
            g_error := 'checking status change';
            IF instr(i_old_status, l_ref_pio_status, 1) = 0
            THEN
                g_error := 'PIO: invalid status change ID=' || i_track_row.id_external_request || ' STATUS_OLD=' ||
                           l_ref_pio_status || ' STATUS_NEW=' || i_track_row.flg_status_pio || ' POSSIBLE OLD STATUS=' ||
                           i_old_status;
                RAISE g_exception;
            END IF;
        
            IF i_track_row.flg_status_pio != '0'
            THEN
                g_error := 'UPDATE REF_PIO ID=' || i_track_row.id_external_request;
                UPDATE ref_pio
                   SET flg_status_pio = l_new_status_pio, dt_untransf_tstz = i_track_row.dt_untransf_tstz
                 WHERE id_external_request = i_track_row.id_external_request;
            
            ELSIF i_track_row.flg_status_pio = '0'
            THEN
                -- removing referral from the application
                g_error := 'DELETE REF_PIO ID=' || i_track_row.id_external_request;
                DELETE FROM ref_pio
                 WHERE id_external_request = i_track_row.id_external_request;
            
                l_new_status_pio := NULL;
            
            END IF;
        
        END IF;
    
        IF l_insert_track = 1
        THEN
            g_error := 'INSERT REF_PIO_TRACKING ID=' || i_track_row.id_external_request;
            INSERT INTO ref_pio_tracking
                (id_external_request,
                 flg_status_pio,
                 dt_untransf_tstz,
                 dt_ref_pio_tracking_tstz,
                 action,
                 id_reason_code,
                 id_dep_clin_serv,
                 id_professional,
                 id_institution)
            VALUES
                (i_track_row.id_external_request,
                 l_new_status_pio,
                 i_track_row.dt_untransf_tstz,
                 l_dt_tstz,
                 i_track_row.action,
                 i_track_row.id_reason_code,
                 i_track_row.id_dep_clin_serv,
                 i_prof.id,
                 i_prof.institution);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'UPDATE_STATUS_PIO',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END update_status_pio;

    /**
    * Collect referrals to be sent to SIGLIC
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    PROCEDURE set_ref_pio(i_lang IN language.id_language%TYPE) IS
    
        l_sql    VARCHAR2(1000 CHAR);
        l_cursor pk_types.cursor_type;
    
        -- referral exists in table REF_PIO but not in adw view        
        TYPE t_rec_not_adw IS RECORD(
            id_external_request NUMBER(24),
            flg_status_pio      VARCHAR2(1 CHAR));
    
        TYPE t_coll_not_adw IS TABLE OF t_rec_not_adw INDEX BY BINARY_INTEGER;
        l_ref_not_in_adw_tab t_coll_not_adw;
    
        -- referral exists in ADW view and may (or may not) exist in table REF_PIO
        TYPE t_rec_in_adw IS RECORD(
            id_external_request   NUMBER(24),
            id_state              VARCHAR2(1 CHAR),
            state                 VARCHAR2(1000 CHAR),
            id_p1_sub_speciality  NUMBER(24),
            sub_speciality        VARCHAR2(1000 CHAR),
            dt_first_request      TIMESTAMP(6) WITH LOCAL TIME ZONE,
            dt_last_scheduled_for TIMESTAMP(6) WITH LOCAL TIME ZONE,
            id_ext_req_pio        NUMBER(24),
            flg_status_pio        VARCHAR2(1 CHAR),
            dt_untransf_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE);
    
        TYPE t_coll_adw IS TABLE OF t_rec_in_adw INDEX BY BINARY_INTEGER;
        l_ref_in_adw_tab t_coll_adw;
    
        l_limit PLS_INTEGER := 2000;
    
        l_track_pio_row ref_pio_tracking%ROWTYPE;
        l_old_status    VARCHAR2(10);
        l_prof          profissional;
        l_valid         VARCHAR2(1);
        l_id_specs      table_number;
        l_id_specs_v    sys_config.value%TYPE;
        l_error         t_error_out;
    
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'g_sysdate_tstz';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'l_prof';
        l_prof  := set_prof_interface(profissional(NULL, 0, 4));
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error      := 'Calling pk_sysconfig.get_config';
        l_id_specs_v := pk_sysconfig.get_config(pk_ref_constant.g_sc_pio_specialities,
                                                l_prof.institution,
                                                l_prof.software);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error    := 'Calling str_split_n / LIST=' || l_id_specs_v;
        l_id_specs := pk_utils.str_split_n(i_list => l_id_specs_v, i_delim => ',');
    
        -----------------------------------
        -- Referral does not exists in adw view
        -----------------------------------
        g_error := 'l_sql';
        l_sql   := 'SELECT rp.id_external_request, rp.flg_status_pio
              FROM ref_pio rp
             WHERE rp.id_external_request NOT IN
                   (SELECT id_external_request
                      FROM v_pio_wait_time_x_days v_adw
                      JOIN TABLE(CAST(:1 AS table_number)) t ON (t.column_value = v_adw.id_p1_sub_speciality OR
                                                                        t.column_value = 0))
               AND rp.flg_status_pio IN (''' || pk_ref_constant.g_ref_pio_status_w || ''', ''' ||
                   pk_ref_constant.g_ref_pio_status_u || ''',
                    ''' || pk_ref_constant.g_ref_pio_status_s || ''')';
    
        pk_alertlog.log_debug(l_sql);
    
        g_error := 'OPEN l_cursor';
        OPEN l_cursor FOR l_sql
            USING l_id_specs;
    
        LOOP
        
            g_error := 'FETCH c_ref_not_in_adw';
            FETCH l_cursor BULK COLLECT
                INTO l_ref_not_in_adw_tab LIMIT l_limit;
        
            FOR idx IN 1 .. l_ref_not_in_adw_tab.count
            LOOP
            
                BEGIN
                    -- removing referral from the application
                    g_error                                  := 'tracking pio row';
                    l_track_pio_row.id_external_request      := l_ref_not_in_adw_tab(idx).id_external_request;
                    l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                    l_track_pio_row.flg_status_pio           := '0'; -- to be removed
                
                    l_old_status := pk_ref_constant.g_ref_pio_status_w || pk_ref_constant.g_ref_pio_status_u ||
                                    pk_ref_constant.g_ref_pio_status_s;
                
                    g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                                ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                    g_retval := update_status_pio(i_lang       => i_lang,
                                                  i_prof       => l_prof,
                                                  i_track_row  => l_track_pio_row,
                                                  i_old_status => l_old_status,
                                                  o_error      => l_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    ------------------------
                    COMMIT;
                    ------------------------
                EXCEPTION
                    WHEN g_exception THEN
                        -- continues to the next referral
                        g_error := g_error || ' ID=' || l_ref_not_in_adw_tab(idx).id_external_request;
                        pk_alertlog.log_warn(g_error);
                        ------------------------
                        pk_utils.undo_changes;
                        ------------------------
                END;
            
            END LOOP;
        
            g_error := 'EXIT c_ref_not_in_adw';
            EXIT WHEN l_cursor%NOTFOUND;
        
        END LOOP;
    
        g_error := 'CLOSE c_ref_not_in_adw';
        CLOSE l_cursor;
    
        g_error                                  := 'CLEAN ref_pio_tracking';
        l_track_pio_row.id_external_request      := NULL;
        l_track_pio_row.flg_status_pio           := NULL;
        l_track_pio_row.dt_ref_pio_tracking_tstz := NULL;
    
        -----------------------------------
        -- Referral exists in adw view
        -----------------------------------
    
        g_error := 'OPEN c_ref_in_adw';
    
        l_sql := 'SELECT v_adw.*,
                   rp.id_external_request id_ext_req_pio,
                   rp.flg_status_pio flg_status_pio,
                   rp.dt_untransf_tstz
              FROM v_pio_wait_time_x_days v_adw
              LEFT JOIN ref_pio rp ON (v_adw.id_external_request = rp.id_external_request)
              JOIN TABLE(CAST(:1 AS table_number)) t ON (t.column_value = v_adw.id_p1_sub_speciality OR
                                                                t.column_value = 0)';
    
        pk_alertlog.log_debug(l_sql);
    
        g_error := 'OPEN l_cursor';
        OPEN l_cursor FOR l_sql
            USING l_id_specs;
    
        LOOP
            g_error := 'FETCH c_ref_in_adw';
            FETCH l_cursor BULK COLLECT
                INTO l_ref_in_adw_tab LIMIT l_limit;
        
            FOR idx IN 1 .. l_ref_in_adw_tab.count
            LOOP
            
                BEGIN
                
                    g_error := 'Calling check_pio_cond';
                    l_valid := check_pio_cond(i_lang             => i_lang,
                                              i_prof             => l_prof,
                                              i_flg_status       => l_ref_in_adw_tab(idx).id_state,
                                              i_dt_schedule_tstz => l_ref_in_adw_tab(idx).dt_last_scheduled_for,
                                              i_dt_requested     => l_ref_in_adw_tab(idx).dt_first_request);
                
                    g_error := 'ID=' || l_ref_in_adw_tab(idx).id_external_request || ' VALID=' || l_valid;
                    pk_alertlog.log_debug(g_error);
                
                    IF l_ref_in_adw_tab(idx).id_ext_req_pio IS NOT NULL
                    THEN
                    
                        -- referral exists in adw view and in table REF_PIO
                        CASE l_ref_in_adw_tab(idx).flg_status_pio
                            WHEN pk_ref_constant.g_ref_pio_status_w THEN
                            
                                g_error := 'STATUS W';
                                IF l_valid = pk_ref_constant.g_no
                                THEN
                                
                                    -- referral is no longer ready to be sent to SIGLIC, update status to (S)tand by
                                    g_error                                  := 'tracking pio row S';
                                    l_track_pio_row.id_external_request      := l_ref_in_adw_tab(idx).id_external_request;
                                    l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_s;
                                    l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                                
                                    l_old_status := pk_ref_constant.g_ref_pio_status_w;
                                
                                    g_error  := 'Calling update_status_pio / ID_REF=' ||
                                                l_track_pio_row.id_external_request || ' STATUS_PIO=' ||
                                                l_track_pio_row.flg_status_pio;
                                    g_retval := update_status_pio(i_lang       => i_lang,
                                                                  i_prof       => l_prof,
                                                                  i_track_row  => l_track_pio_row,
                                                                  i_old_status => l_old_status,
                                                                  o_error      => l_error);
                                
                                    IF NOT g_retval
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            
                            WHEN pk_ref_constant.g_ref_pio_status_u THEN
                            
                                g_error := 'STATUS U';
                                IF trunc(l_ref_in_adw_tab(idx).dt_untransf_tstz) <= trunc(g_sysdate_tstz)
                                THEN
                                    -- untransferable period has ended
                                
                                    g_error := 'valid';
                                    IF l_valid = pk_ref_constant.g_yes
                                    THEN
                                        -- sending to SIGLIC again
                                        g_error                                  := 'tracking pio row W';
                                        l_track_pio_row.id_external_request      := l_ref_in_adw_tab(idx).id_external_request;
                                        l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_w;
                                        l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                                    
                                        l_old_status := pk_ref_constant.g_ref_pio_status_u;
                                    
                                        g_error  := 'Calling update_status_pio / ID_REF=' ||
                                                    l_track_pio_row.id_external_request || ' STATUS_PIO=' ||
                                                    l_track_pio_row.flg_status_pio;
                                        g_retval := update_status_pio(i_lang       => i_lang,
                                                                      i_prof       => l_prof,
                                                                      i_track_row  => l_track_pio_row,
                                                                      i_old_status => l_old_status,
                                                                      o_error      => l_error);
                                        IF NOT g_retval
                                        THEN
                                            RAISE g_exception;
                                        END IF;
                                    ELSE
                                        -- referral is no longer ready to be sent to SIGLIC, update status to (S)tand by
                                        g_error                                  := 'tracking pio row S 2';
                                        l_track_pio_row.id_external_request      := l_ref_in_adw_tab(idx).id_external_request;
                                        l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_s;
                                        l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                                    
                                        l_old_status := pk_ref_constant.g_ref_pio_status_u;
                                    
                                        g_error  := 'Calling update_status_pio 2 / ID_REF=' ||
                                                    l_track_pio_row.id_external_request || ' STATUS_PIO=' ||
                                                    l_track_pio_row.flg_status_pio;
                                        g_retval := update_status_pio(i_lang       => i_lang,
                                                                      i_prof       => l_prof,
                                                                      i_track_row  => l_track_pio_row,
                                                                      i_old_status => l_old_status,
                                                                      o_error      => l_error);
                                        IF NOT g_retval
                                        THEN
                                            RAISE g_exception;
                                        END IF;
                                    END IF;
                                
                                END IF;
                            
                            WHEN pk_ref_constant.g_ref_pio_status_s THEN
                            
                                g_error := 'STATUS S';
                                IF l_valid = pk_ref_constant.g_yes
                                THEN
                                    -- sending to SIGLIC again
                                    g_error                                  := 'tracking pio row W 2';
                                    l_track_pio_row.id_external_request      := l_ref_in_adw_tab(idx).id_external_request;
                                    l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_w;
                                    l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                                
                                    l_old_status := pk_ref_constant.g_ref_pio_status_s;
                                
                                    g_error  := 'Calling update_status_pio 2 / ID_REF=' ||
                                                l_track_pio_row.id_external_request || ' STATUS_PIO=' ||
                                                l_track_pio_row.flg_status_pio;
                                    g_retval := update_status_pio(i_lang       => i_lang,
                                                                  i_prof       => l_prof,
                                                                  i_track_row  => l_track_pio_row,
                                                                  i_old_status => l_old_status,
                                                                  o_error      => l_error);
                                    IF NOT g_retval
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                END IF;
                            
                            WHEN pk_ref_constant.g_ref_pio_status_r THEN
                                NULL;
                            WHEN pk_ref_constant.g_ref_pio_status_p THEN
                                NULL;
                            ELSE
                                g_error := 'NO CASE FOUND ' || l_ref_in_adw_tab(idx).flg_status_pio;
                                RAISE g_exception;
                        END CASE;
                    
                    ELSE
                        -- referral exists in adw view but not in table REF_PIO
                        g_error := 'valid';
                        IF l_valid = pk_ref_constant.g_yes
                        THEN
                            -- referral has to be processed by SIGLIC, creating referral in the application
                            g_error                                  := 'tracking pio row W';
                            l_track_pio_row.id_external_request      := l_ref_in_adw_tab(idx).id_external_request;
                            l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_w;
                            l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                        
                            l_old_status := NULL;
                        
                            g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                                        ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                            g_retval := update_status_pio(i_lang       => i_lang,
                                                          i_prof       => l_prof,
                                                          i_track_row  => l_track_pio_row,
                                                          i_old_status => l_old_status,
                                                          o_error      => l_error);
                        
                            IF NOT g_retval
                            THEN
                                RAISE g_exception;
                            END IF;
                        END IF;
                    
                    END IF;
                
                    g_error                                  := 'CLEAN ref_pio_tracking 2';
                    l_track_pio_row.id_external_request      := NULL;
                    l_track_pio_row.flg_status_pio           := NULL;
                    l_track_pio_row.dt_ref_pio_tracking_tstz := NULL;
                
                    ------------------------
                    COMMIT;
                    ------------------------
                EXCEPTION
                    WHEN g_exception THEN
                        -- continues to the next referral
                        g_error := g_error || ' ID=' || l_ref_in_adw_tab(idx).id_external_request;
                        pk_alertlog.log_warn(g_error);
                        ------------------------
                        pk_utils.undo_changes;
                        ------------------------
                END;
            
            END LOOP;
        
            g_error := 'EXIT c_ref_in_adw';
            EXIT WHEN l_cursor%NOTFOUND;
        END LOOP;
    
        g_error := 'CLOSE c_ref_in_adw';
        CLOSE l_cursor;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            ------------------------
            pk_utils.undo_changes;
            ------------------------
            pk_alertlog.log_warn(g_error);
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            pk_alert_exceptions.reset_error_state();
        WHEN OTHERS THEN
            ------------------------
            pk_utils.undo_changes;
            ------------------------
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_PIO',
                                              o_error    => l_error);
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            pk_alert_exceptions.reset_error_state();
    END set_ref_pio;

    /**
    * Changes referral pio status to (R)ead, blocking referral in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referral identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_read
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_old_status    VARCHAR2(10 CHAR);
        l_track_pio_row ref_pio_tracking%ROWTYPE;
        l_prof          profissional;
    
        CURSOR c_ref IS
            SELECT p.*
              FROM p1_external_request p
              JOIN TABLE(CAST(i_ext_req AS table_number)) tt
                ON (p.id_external_request = tt.column_value);
    
        TYPE t_tab_ref IS TABLE OF p1_external_request%ROWTYPE;
        l_ref_tab   t_tab_ref;
        l_prof_data t_rec_prof_data; -- professional data
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'g_sysdate_tstz';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'l_prof';
        l_prof  := set_prof_interface(i_prof);
    
        ----------------------
        -- FUNC
        ----------------------        
        g_error := 'i_ext_req';
        IF i_ext_req IS NOT NULL
        THEN
        
            -- getting professional data
            g_error  := 'Calling get_prof_data';
            g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                                  i_prof      => l_prof,
                                                  i_dcs       => NULL,
                                                  o_prof_data => l_prof_data,
                                                  o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'OPEN C_REF';
            OPEN c_ref;
            FETCH c_ref BULK COLLECT
                INTO l_ref_tab;
            CLOSE c_ref;
        
            -- check if all referrals exists
            IF l_ref_tab.count != i_ext_req.count
            THEN
                g_error      := 'l_ref_tab.COUNT=' || l_ref_tab.count || ' i_ext_req.COUNT=' || i_ext_req.count;
                g_error_code := pk_ref_constant.g_ref_error_1000; -- referral does not exist
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            FOR i IN 1 .. l_ref_tab.count
            LOOP
            
                -- blocking referral in CTH
                g_error  := 'Calling set_ref_blocked / ID_REF=' || l_ref_tab(i).id_external_request;
                g_retval := set_ref_blocked(i_lang      => i_lang,
                                            i_prof      => l_prof,
                                            i_prof_data => l_prof_data,
                                            i_ref_row   => l_ref_tab(i),
                                            i_date      => g_sysdate_tstz,
                                            o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- changing pio status to (R)ead
                g_error                                  := 'tracking pio row R / ID_REF=' || l_ref_tab(i).id_external_request;
                l_track_pio_row.id_external_request      := l_ref_tab(i).id_external_request;
                l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_r;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_w;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error                                  := 'CLEAN ref_pio_tracking';
                l_track_pio_row.id_external_request      := NULL;
                l_track_pio_row.flg_status_pio           := NULL;
                l_track_pio_row.dt_ref_pio_tracking_tstz := NULL;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_READ',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_read;

    /**    
    * Changes referral pio status from (R)ead to (W)aiting for approval, unblocking referral status in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referrals identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_unread
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_old_status    VARCHAR2(10 CHAR);
        l_track_pio_row ref_pio_tracking%ROWTYPE;
        l_prof          profissional;
    
        CURSOR c_ref IS
            SELECT p.*
              FROM p1_external_request p
              JOIN TABLE(CAST(i_ext_req AS table_number)) tt
                ON (p.id_external_request = tt.column_value);
    
        TYPE t_tab_ref IS TABLE OF p1_external_request%ROWTYPE;
        l_ref_tab   t_tab_ref;
        l_prof_data t_rec_prof_data; -- professional data
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'g_sysdate_tstz';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'l_prof';
        l_prof  := set_prof_interface(i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error := 'i_ext_req';
        IF i_ext_req IS NOT NULL
        THEN
            -- getting professional data
            g_error  := 'Calling get_prof_data';
            g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                                  i_prof      => l_prof,
                                                  i_dcs       => NULL,
                                                  o_prof_data => l_prof_data,
                                                  o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'OPEN C_REF';
            OPEN c_ref;
            FETCH c_ref BULK COLLECT
                INTO l_ref_tab;
            CLOSE c_ref;
        
            -- check if all referrals exists
            IF l_ref_tab.count != i_ext_req.count
            THEN
                g_error      := 'l_ref_tab.COUNT=' || l_ref_tab.count || ' i_ext_req.COUNT=' || i_ext_req.count;
                g_error_code := pk_ref_constant.g_ref_error_1000; -- referral does not exist
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            FOR i IN 1 .. l_ref_tab.count
            LOOP
            
                -- unblocking referral in CTH
                g_error  := 'Calling set_ref_unblocked / ID_REF=' || l_ref_tab(i).id_external_request;
                g_retval := set_ref_unblocked(i_lang      => i_lang,
                                              i_prof      => l_prof,
                                              i_prof_data => l_prof_data,
                                              i_ref_row   => l_ref_tab(i),
                                              i_date      => g_sysdate_tstz,
                                              o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- changing pio status to (W)aiting for approval
                g_error                                  := 'tracking pio row W';
                l_track_pio_row.id_external_request      := l_ref_tab(i).id_external_request;
                l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_w;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_r;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- cleaning up vars
                g_error                                  := 'CLEAN ref_pio_tracking';
                l_track_pio_row.id_external_request      := NULL;
                l_track_pio_row.flg_status_pio           := NULL;
                l_track_pio_row.dt_ref_pio_tracking_tstz := NULL;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_UNREAD',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_unread;

    /**
    * SIGLIC has acknowledge referral receipt. Changes referral pio status from (R)ead to (P)rocessing
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referrals identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_ack
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_old_status    VARCHAR2(10 CHAR);
        l_track_pio_row ref_pio_tracking%ROWTYPE;
        l_prof          profissional;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'g_sysdate_tstz';
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'l_prof';
        l_prof  := set_prof_interface(i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error := 'i_ext_req';
        IF i_ext_req IS NOT NULL
        THEN
            FOR i IN 1 .. i_ext_req.count
            LOOP
            
                -- changing pio status from (R)ead to (P)rocessing
                g_error                                  := 'tracking pio row P';
                l_track_pio_row.id_external_request      := i_ext_req(i);
                l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_p;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_r;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- cleaning up vars
                g_error                                  := 'CLEAN ref_pio_tracking';
                l_track_pio_row.id_external_request      := NULL;
                l_track_pio_row.flg_status_pio           := NULL;
                l_track_pio_row.dt_ref_pio_tracking_tstz := NULL;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_ACK',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_ack;

    /**
    * SIGLIC has responded. Removes referral from the application or changes referral pio status (from (P)rocessing to
    * (W)aiting for approval or (S)tand by), depending on i_action
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referral identification
    * @param   i_action           SIGLIC action: {*} (N)o action {*} (C)ancel referral {*} (T)ransfer {*} (U)ntransferable
    * @param   i_id_dep_clin_serv New referral dep_clin_serv
    * @param   i_id_institution   New dest institution
    * @param   i_id_reason_code   Cancelation reason
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_response
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_action           IN ref_pio_tracking.action%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_institution   IN p1_external_request.id_inst_dest%TYPE,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_pio_row   ref_pio_tracking%ROWTYPE;
        l_old_status      VARCHAR2(10);
        l_prof            profissional;
        l_pio_notes       p1_detail.text%TYPE;
        l_track_tab       table_number;
        l_id_institution  p1_external_request.id_inst_dest%TYPE;
        l_pat_transf_days NUMBER;
        l_pat_refuse_days NUMBER;
        l_sysconfig_cur   pk_types.cursor_type;
        l_sysconfig_desc  table_varchar;
        l_sysconfig_val   table_varchar;
        l_param           table_varchar;
    
        CURSOR c_dcs(i_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT d.id_institution
              FROM dep_clin_serv dcs
              JOIN department d
                ON (d.id_department = dcs.id_department)
             WHERE dcs.id_dep_clin_serv = i_dcs;
    
        CURSOR c_ref(x_id_ext_req IN p1_external_request.id_external_request%TYPE) IS
            SELECT *
              FROM p1_external_request
             WHERE id_external_request = x_id_ext_req;
    
        CURSOR c_ref_pio(x_id_ext_req IN p1_external_request.id_external_request%TYPE) IS
            SELECT COUNT(1)
              FROM ref_pio
             WHERE id_external_request = x_id_ext_req;
    
        l_count PLS_INTEGER;
    
        l_ref_row       p1_external_request%ROWTYPE;
        l_prof_data     t_rec_prof_data;
        l_flg_available VARCHAR2(1 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_response / ID_REF=' || i_ext_req || ' ACTION=' || i_action || ' ID_DEP_CLIN_SERV=' ||
                   i_id_dep_clin_serv || ' ID_INSTITUTION=' || i_id_institution || ' ID_REASON_CODE=' ||
                   i_id_reason_code;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := current_timestamp;
        l_prof         := set_prof_interface(i_prof);
        l_track_tab    := table_number();
    
        ----------------------
        -- VAL
        ----------------------
        IF i_action IS NULL
        THEN
        
            -- invalid parameter
            g_error      := 'INVALID ACTION / i_action is null';
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        
        ELSIF i_action = pk_ref_constant.g_ref_pio_action_c
        THEN
        
            IF i_id_reason_code IS NULL
            THEN
                g_error      := 'REASON_CODE IS NULL';
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- Cancel referral
            g_error  := 'Call pk_api_ref_ws.check_ref_reason_code / ID_REASON_CODE=' || i_id_reason_code ||
                        ' REASON_TYPE=' || pk_ref_constant.g_reason_code_c;
            g_retval := pk_api_ref_ws.check_ref_reason_code(i_lang          => i_lang,
                                                            i_prof          => l_prof,
                                                            i_reason_code   => i_id_reason_code,
                                                            i_reason_type   => pk_ref_constant.g_reason_code_c,
                                                            o_flg_available => l_flg_available,
                                                            o_error         => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error      := 'INVALID REASON CODE / ID_REASON_CODE=' || i_id_reason_code || ' REASON_TYPE=' ||
                                pk_ref_constant.g_reason_code_c;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        ELSIF i_action = pk_ref_constant.g_ref_pio_action_t
        THEN
        
            IF i_id_dep_clin_serv IS NULL
            THEN
                -- invalid parameter
                g_error      := 'ID_DEP_CLIN_SERV IS NULL';
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- Transfer referral
            IF i_id_institution IS NULL
            THEN
                g_error := 'OPEN c_dcs';
                OPEN c_dcs(i_id_dep_clin_serv);
            
                g_error := 'FETCH c_dcs';
                FETCH c_dcs
                    INTO l_id_institution;
            
                g_error := 'CLOSE c_dcs';
                CLOSE c_dcs;
            ELSE
            
                -- checking if dep_clin_serv is valid for institution
                g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv';
                g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                              i_prof          => l_prof,
                                                              i_id_inst_dest  => i_id_institution,
                                                              i_dcs           => i_id_dep_clin_serv,
                                                              o_flg_available => l_flg_available,
                                                              o_error         => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'Error: ' || g_error;
                    RAISE g_exception_np;
                END IF;
            
                IF l_flg_available = pk_ref_constant.g_no
                THEN
                    g_error      := 'ID_INSTITUTION=' || i_id_institution || ' and ID_DEP_CLIN_SERV=' ||
                                    i_id_dep_clin_serv || ' DO NOT MATCH';
                    g_error_code := pk_ref_constant.g_ref_error_1009;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                g_error          := 'ID_INSTITUTION';
                l_id_institution := i_id_institution;
            END IF;
        
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error     := 'pk_message.get_message / code_message=' || pk_ref_constant.g_sm_pio_notes;
        l_pio_notes := pk_message.get_message(i_lang, pk_ref_constant.g_sm_pio_notes);
    
        g_retval := pk_sysconfig.get_config(i_code_cf => table_varchar(pk_ref_constant.g_sc_pio_pat_transf,
                                                                       pk_ref_constant.g_sc_pio_pat_refuse),
                                            i_prof    => l_prof,
                                            o_msg_cf  => l_sysconfig_cur);
    
        IF NOT g_retval
        THEN
            g_error      := 'SYS_CONFIG ERROR';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'BULK COLLECT sys_config';
        FETCH l_sysconfig_cur BULK COLLECT
            INTO l_sysconfig_desc, l_sysconfig_val;
        CLOSE l_sysconfig_cur;
    
        FOR i IN 1 .. l_sysconfig_desc.count
        LOOP
            IF l_sysconfig_desc(i) = pk_ref_constant.g_sc_pio_pat_transf
            THEN
                l_pat_transf_days := l_sysconfig_val(i);
            ELSIF l_sysconfig_desc(i) = pk_ref_constant.g_sc_pio_pat_refuse
            THEN
                l_pat_refuse_days := l_sysconfig_val(i);
            END IF;
        END LOOP;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- checking if referral request exists
        g_error := 'Checking ID_EXT_REQ=' || i_ext_req || ' in P1_EXTERNAL_REQUEST';
        OPEN c_ref(i_ext_req);
        FETCH c_ref
            INTO l_ref_row;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
    
        IF NOT g_found
        THEN
            -- Referral request does not exist
            g_error      := 'ID_EXT_REQ=' || i_ext_req || ' does not exists P1_EXTERNAL_REQUEST';
            g_error_code := pk_ref_constant.g_ref_error_1000;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- checking if referral request exists in PIO
        g_error := 'Checking ID_EXT_REQ=' || i_ext_req || ' in REF_PIO';
        OPEN c_ref_pio(i_ext_req);
        FETCH c_ref_pio
            INTO l_count;
        g_found := c_ref_pio%FOUND;
        CLOSE c_ref_pio;
    
        IF l_count = 0
        THEN
            -- Referral request does not exist in PIO
            g_error      := 'ID_EXT_REQ=' || i_ext_req || ' does not exists REF_PIO';
            g_error_code := pk_ref_constant.g_ref_error_1002;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => l_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1004;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'CASE ACTION=' || i_action || ' ID_REF=' || l_ref_row.id_external_request;
        CASE i_action
            WHEN pk_ref_constant.g_ref_pio_action_n THEN
            
                -- ACTION: no hospital found, change referral pio status to (W)aiting for approval
            
                -- unblocking referral in CTH
                g_error  := 'Calling set_ref_unblocked / ID_REF=' || l_ref_row.id_external_request;
                g_retval := set_ref_unblocked(i_lang      => i_lang,
                                              i_prof      => l_prof,
                                              i_prof_data => l_prof_data,
                                              i_ref_row   => l_ref_row,
                                              i_date      => g_sysdate_tstz,
                                              o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception_np;
                END IF;
            
                g_error                                  := 'tracking pio row ' || i_action;
                l_track_pio_row.id_external_request      := i_ext_req;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                l_track_pio_row.action                   := i_action;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_p;
            
                -- checking if referral is ready to be sent to SIGLIC
                g_error := 'Calling check_pio_cond';
                IF check_pio_cond(i_lang, l_prof, i_ext_req) = pk_ref_constant.g_yes
                THEN
                    -- ready, pio status = (W)aiting for approval
                    l_track_pio_row.flg_status_pio := pk_ref_constant.g_ref_pio_status_w;
                ELSE
                    -- not ready, pio status = (S)tand by
                    -- this situation will never happen because referral was blocked
                    l_track_pio_row.flg_status_pio := pk_ref_constant.g_ref_pio_status_s;
                    g_error_code                   := pk_ref_constant.g_ref_error_1001; -- Referral request is not ready to be processed by SIGLIC
                    g_error_desc                   := pk_ref_core.get_ref_error_desc(i_lang         => i_lang,
                                                                                     i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
            WHEN pk_ref_constant.g_ref_pio_action_c THEN
            
                -- ACTION: cancel referral. Referral is removed from the application (tracking is not deleted)                
            
                -- removing referral from the application
                g_error                                  := 'tracking pio row ' || i_action;
                l_track_pio_row.id_external_request      := i_ext_req;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                l_track_pio_row.flg_status_pio           := '0'; -- to be removed
                l_track_pio_row.action                   := i_action;
                l_track_pio_row.id_reason_code           := i_id_reason_code;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_p;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                -- Cancel referral
                IF l_ref_row.id_workflow IS NULL
                THEN
                
                    g_error  := 'Call pk_p1_med_cs.cancel_external_request_int / ID_REFERRAL=' ||
                                l_ref_row.id_external_request || ' REASON_CODE=' || i_id_reason_code ||
                                ' ID_PROFESSIONAL=' || l_prof.id;
                    g_retval := pk_p1_med_cs.cancel_external_request_int(i_lang           => i_lang,
                                                                         i_prof           => l_prof,
                                                                         i_ext_req        => l_ref_row.id_external_request,
                                                                         i_mcdts          => NULL,
                                                                         i_id_patient     => l_ref_row.id_patient,
                                                                         i_id_episode     => NULL,
                                                                         i_notes          => l_pio_notes,
                                                                         i_reason         => i_id_reason_code,
                                                                         i_transaction_id => NULL,
                                                                         o_track          => l_track_tab,
                                                                         o_error          => o_error);
                ELSE
                
                    g_error  := 'Calling pk_ref_orig_phy.cancel_referral / ID_REF=' || l_ref_row.id_external_request ||
                                ' ID_PATIENT=' || l_ref_row.id_patient || ' ID_REASON_CODE=' || i_id_reason_code;
                    g_retval := pk_ref_orig_phy.cancel_referral(i_lang           => i_lang,
                                                                i_prof           => l_prof,
                                                                i_ext_req        => l_ref_row.id_external_request,
                                                                i_id_patient     => l_ref_row.id_patient,
                                                                i_id_episode     => NULL,
                                                                i_notes          => l_pio_notes,
                                                                i_reason         => i_id_reason_code,
                                                                i_transaction_id => NULL,
                                                                o_track          => l_track_tab,
                                                                o_error          => o_error);
                
                END IF;
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_pio_action_t THEN
            
                -- ACTION: transfer referral to another hospital. Change referral pio status to (U)ntransferable                            
            
                -- changing pio status from (P)rocessing to (U)ntransferable
                g_error                                  := 'tracking pio row ' || i_action;
                l_track_pio_row.id_external_request      := i_ext_req;
                l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_u;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                l_track_pio_row.action                   := i_action;
                l_track_pio_row.id_dep_clin_serv         := i_id_dep_clin_serv;
                l_track_pio_row.dt_untransf_tstz         := g_sysdate_tstz + l_pat_transf_days;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_p;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                -- changing dest institution
                IF l_ref_row.id_workflow IS NULL
                THEN
                
                    g_error  := 'Call pk_p1_core.set_dest_institution_int / ID_REF=' || l_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || l_id_institution || ' ID_DCS=' || i_id_dep_clin_serv;
                    g_retval := pk_p1_core.set_dest_institution_int(i_lang      => i_lang,
                                                                    i_prof      => l_prof,
                                                                    i_ext_req   => l_ref_row.id_external_request,
                                                                    i_inst_dest => l_id_institution,
                                                                    i_dcs_dest  => i_id_dep_clin_serv,
                                                                    i_date      => g_sysdate_tstz,
                                                                    o_track     => l_track_tab,
                                                                    o_error     => o_error);
                ELSE
                    g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || l_ref_row.id_external_request ||
                                ' ACTION=' || pk_ref_constant.g_ref_action_di || ' DATE=' ||
                                pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDDHH24MISS');
                    g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                                i_prof       => l_prof,
                                                                i_prof_data  => l_prof_data,
                                                                i_ref_row    => l_ref_row,
                                                                i_action     => pk_ref_constant.g_ref_action_di, -- CHANGE_INST 
                                                                i_status_end => NULL,
                                                                i_inst_dest  => l_id_institution,
                                                                i_dcs        => i_id_dep_clin_serv,
                                                                i_date       => g_sysdate_tstz,
                                                                io_param     => l_param,
                                                                io_track     => l_track_tab,
                                                                o_error      => o_error);
                
                END IF;
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- inserting notes 
                g_error  := 'Call pk_ref_core.set_detail / ID_REF=' || l_ref_row.id_external_request || ' DETAIL_TYPE=' ||
                            pk_ref_constant.g_detail_type_ndec || ' DETAIL_TEXT=' || l_pio_notes;
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_prof          => l_prof,
                                                   i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_ndec,
                                                                                                        l_pio_notes,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_tab(1), -- first iteration
                                                   i_date          => g_sysdate_tstz,
                                                   o_error         => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
            WHEN pk_ref_constant.g_ref_pio_action_u THEN
            
                -- ACTION: patient has refused transfer. Change referral pio status to (U)ntransferable
            
                -- unblocking referral in CTH
                g_error  := 'Calling set_ref_unblocked / ID_REF=' || l_ref_row.id_external_request;
                g_retval := set_ref_unblocked(i_lang      => i_lang,
                                              i_prof      => l_prof,
                                              i_prof_data => l_prof_data,
                                              i_ref_row   => l_ref_row,
                                              i_date      => g_sysdate_tstz,
                                              o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                -- changing pio status from (P)rocessing to (U)ntransferable
                g_error                                  := 'tracking pio row ' || i_action;
                l_track_pio_row.id_external_request      := l_ref_row.id_external_request;
                l_track_pio_row.flg_status_pio           := pk_ref_constant.g_ref_pio_status_u;
                l_track_pio_row.dt_ref_pio_tracking_tstz := g_sysdate_tstz;
                l_track_pio_row.action                   := i_action;
                l_track_pio_row.dt_untransf_tstz         := g_sysdate_tstz + l_pat_refuse_days;
            
                l_old_status := pk_ref_constant.g_ref_pio_status_p;
            
                g_error  := 'Calling update_status_pio / ID_REF=' || l_track_pio_row.id_external_request ||
                            ' STATUS_PIO=' || l_track_pio_row.flg_status_pio;
                g_retval := update_status_pio(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_track_row  => l_track_pio_row,
                                              i_old_status => l_old_status,
                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1004;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
            ELSE
                g_error      := 'NO CASE FOUND ' || i_action;
                g_error_code := pk_ref_constant.g_ref_error_1004;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
                                              i_function    => 'SET_REF_RESPONSE',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_response;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_flg_status_allowed := NULL;
    g_max_days           := NULL;
END pk_ref_pio;
/
