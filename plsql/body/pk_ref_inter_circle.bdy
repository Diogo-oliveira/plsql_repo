/*-- Last Change Revision: $Rev: 1714849 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2015-11-06 14:39:15 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_inter_circle IS

    -- Function and procedure implementations
    FUNCTION get_detail_text
    (
        i_ref_id   IN p1_external_request.id_external_request%TYPE,
        i_flg_type IN p1_detail.flg_type%TYPE
    ) RETURN p1_detail.text%TYPE IS
        l_text p1_detail.text%TYPE;
    
        CURSOR c_cur IS
            SELECT text
              FROM p1_detail
             WHERE id_external_request = i_ref_id
               AND flg_type = i_flg_type
               AND flg_status = pk_ref_constant.g_active;
    
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_text;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_detail_text;

    /*
    * Get active id_details  
    *
    * @param   i_lang         Language 
    * @param   i_ref_id       Id External professional 
    * @param   i_flg_type     Detail type
    * @param   o_id_detail    Id detail
    * @param   o_error        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION get_id_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_ref_id    IN p1_external_request.id_external_request%TYPE,
        i_flg_type  IN p1_detail.flg_type%TYPE,
        o_id_detail OUT p1_detail.id_detail%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_detail
              FROM p1_detail
             WHERE id_external_request = i_ref_id
               AND flg_type = i_flg_type
               AND flg_status = pk_ref_constant.g_active;
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO o_id_detail;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
        
    END get_id_detail;

    /*
    * Get referral id  
    *
    * @param   i_lang              Language 
    * @param   i_ref_ext_sys       Referral id in the external system 
    * @param   i_id_extenal_sys    External system
    * @param   o_id_ref            Id external request
    * @param   o_id_pat            Id patient
    * @param   o_epis              Id episide
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION get_referral_id
    (
        i_lang           IN language.id_language%TYPE,
        i_ref_ext_sys    IN p1_external_request.ext_reference%TYPE,
        i_id_extenal_sys IN external_sys.id_external_sys%TYPE,
        o_id_ref         OUT p1_external_request.id_external_request%TYPE,
        o_id_pat         OUT patient.id_patient%TYPE,
        o_epis           OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_cur(x_num_req p1_external_request.ext_reference%TYPE) IS
            SELECT id_external_request, id_patient, id_episode
              FROM p1_external_request
             WHERE ext_reference = x_num_req
               AND id_external_sys = i_id_extenal_sys;
    
        l_count PLS_INTEGER;
    BEGIN
        l_count := 0;
        g_error := 'OPEN C_CUR';
        FOR i IN c_cur(i_ref_ext_sys)
        LOOP
            g_error := 'SAVE FIRST ID_EXTERNAL_REQUEST';
            IF l_count = 0
            THEN
                o_id_ref := i.id_external_request;
                o_id_pat := i.id_patient;
                o_epis   := i.id_episode;
            END IF;
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'MORE THEN ONE NUM_REQ';
        IF l_count != 1
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_ID',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_referral_id;

    /*
    * Check if is a valid institution  
    *
    * @param   i_lang              Language 
    * @param   i_institution       Institution Id 
    * @param   o_valid             {*}Y if is valid  {*} N if is invalid
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION check_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_valid       OUT VARCHAR2,
        o_error       OUT t_error_out
        
    ) RETURN BOOLEAN IS
        CURSOR c_cur IS
            SELECT COUNT(1)
              FROM institution
             WHERE id_institution = i_institution
               AND flg_available = pk_ref_constant.g_yes;
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_count;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        IF l_count = 1
        THEN
            o_valid := pk_ref_constant.g_yes;
        ELSE
            pk_alertlog.log_warn(g_error);
            o_valid := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_INSTITUTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
        
    END check_institution;

    /*
    * Check if is a valid Patient in the given institution  
    *
    * @param   i_lang              Language 
    * @param   i_id_patient        Patient  Id 
    * @param   i_id_inst           Institution Id
    * @param   o_valid             {*}Y if is valid  {*} N if is invalid
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION check_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_inst    IN institution.id_institution%TYPE,
        o_valid      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT COUNT(1)
              FROM patient p
              JOIN pat_identifier pi
                ON (pi.id_patient = p.id_patient)
             WHERE pi.id_patient = i_id_patient
               AND pi.id_institution = i_id_inst
               AND p.flg_status = pk_ref_constant.g_active
               AND pi.flg_status = pk_ref_constant.g_active;
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_count;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'CHECK L_COUNT = ' || l_count;
        IF l_count = 1
        THEN
            o_valid := pk_ref_constant.g_yes;
        ELSE
            pk_alertlog.log_warn(g_error);
            o_valid := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Error: ' || g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PATIENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
    END check_patient;

    /*
    * Check if is a valid professional  
    *
    * @param   i_lang              Language 
    * @param   i_id_prof           Professional  Id
    * @param   i_id_inst           Institution Id
    * @param   o_valid             {*}Y if is valid  {*} N if is invalid
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION check_professional
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_valid   OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT COUNT(1)
              FROM professional
             WHERE id_professional = i_id_prof
               AND flg_state = pk_ref_constant.g_active;
        l_count PLS_INTEGER;
    
    BEGIN
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_count;
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        IF l_count = 1
        THEN
            o_valid := pk_ref_constant.g_yes;
        ELSE
            pk_alertlog.log_warn(g_error);
            o_valid := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_ID',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
    END check_professional;
    /*
    * Update referral status and details and ckeck professional
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_dt_ref_received
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION update_referral_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_notes              IN p1_detail.text%TYPE, -- 17
        i_req_item           IN p1_detail.text%TYPE, -- 18
        i_reason             IN p1_detail.text%TYPE, -- 0
        i_dt_ref_received    IN p1_tracking.dt_tracking_tstz%TYPE,
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_dest profissional;
        l_prof_orig profissional;
        l_valid     VARCHAR2(1);
        l_ref_row   p1_external_request%ROWTYPE;
        l_track_row p1_tracking%ROWTYPE;
        l_rowids    table_varchar;
    
        CURSOR c_ref IS
            SELECT *
              FROM p1_external_request
             WHERE ext_reference = i_id_ref
               AND id_external_sys = i_id_ext_sys;
    
        l_id_detail          p1_detail.id_detail%TYPE;
        l_wf_transition_info table_varchar;
        l_status_begin       wf_status.id_status%TYPE;
        l_status_end         wf_status.id_status%TYPE;
        l_available          VARCHAR2(4000);
    
        -- CHANGED BY: Ana Monteiro
        -- CHANGED DATE: 2009-OCT-29
        -- CHANGED REASON: dt_tracking_tstz must not be repeated
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
    
        CURSOR c_track(i_id_ext_req IN p1_tracking.id_external_request%TYPE) IS
            SELECT t.dt_tracking_tstz
              FROM p1_tracking t
             WHERE t.id_external_request = i_id_ext_req
             ORDER BY t.dt_tracking_tstz DESC, t.id_tracking DESC;
        -- CHANGE END: Ana Monteiro
    
        l_id_cat      category.id_category%TYPE; -- ACM, 2010-06-29: ALERT-83871
        l_action_name wf_workflow_action.internal_name%TYPE;
    BEGIN
    
        g_error     := 'INIT';
        g_sysdate   := current_timestamp;
        l_prof_dest := profissional(i_id_prof, i_int_dest, pk_ref_constant.g_id_soft_referral);
        l_prof_orig := profissional(i_id_prof, i_int_orig, pk_ref_constant.g_id_soft_referral);
    
        g_error  := 'CALL ' || g_package_name || '.CHECK_INSTITUTION';
        g_retval := check_institution(i_lang        => i_lang,
                                      i_institution => i_int_orig,
                                      o_valid       => l_valid,
                                      o_error       => o_error);
    
        g_error := 'INSTITUTION ' || i_int_orig || ' INVALID ';
        IF l_valid = pk_ref_constant.g_no
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error  := 'CALL ' || g_package_name || '.CHECK_PROFESSIONAL';
        g_retval := check_professional(i_lang => i_lang, i_id_prof => i_id_prof, o_valid => l_valid, o_error => o_error);
    
        g_error := 'PROFESSIONAL ' || i_id_prof || ' INVALID ';
        IF l_valid = pk_ref_constant.g_no
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error := 'CHECK REFERRAL';
        OPEN c_ref;
        FETCH c_ref
            INTO l_ref_row;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
    
        g_error := 'REFERRAL DOES NOT EXISTS update_referral_internal';
        IF NOT g_found
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error := 'CASE i_status=' || i_flg_status;
        CASE i_flg_status
            WHEN pk_ref_constant.g_p1_status_n THEN
                l_action_name := pk_ref_constant.g_ref_action_n; -- NEW
        
            WHEN pk_ref_constant.g_p1_status_a THEN
                l_action_name := pk_ref_constant.g_ref_action_a; -- ACCEPTED
        
            WHEN pk_ref_constant.g_p1_status_s THEN
                l_action_name := pk_ref_constant.g_ref_action_s; -- SCHEDULE
        
            WHEN pk_ref_constant.g_p1_status_m THEN
                l_action_name := pk_ref_constant.g_ref_action_m; -- MAIL           
        
            WHEN pk_ref_constant.g_p1_status_e THEN
                l_action_name := pk_ref_constant.g_ref_action_e; -- EFFECTIVE
        
            WHEN pk_ref_constant.g_p1_status_x THEN
                l_action_name := pk_ref_constant.g_ref_action_x; -- REFUSE
        
            WHEN pk_ref_constant.g_p1_status_c THEN
                l_action_name := pk_ref_constant.g_ref_action_csh; -- CANCEL_SCH
        
            WHEN pk_ref_constant.g_p1_status_f THEN
                l_action_name := pk_ref_constant.g_ref_action_f; -- MISSED
        
            WHEN pk_ref_constant.g_p1_status_c THEN
                l_action_name := pk_ref_constant.g_ref_action_c; -- CANCEL              
        
            WHEN pk_ref_constant.g_p1_status_u THEN
                l_action_name := pk_ref_constant.g_ref_action_u; -- CANCEL      
        
            WHEN pk_ref_constant.g_p1_status_q THEN
                l_action_name := pk_ref_constant.g_ref_action_q; -- CANCEL      
        
        -- N A S M E X C U Q
        
            ELSE
                RAISE g_exception;
        END CASE;
    
        --g_error := 'Call pk_ref_core.init_wf_trans_tab / ID_EXT_REQ=' || l_ref_row.id_external_request;
        --pk_alertlog.log_debug(g_error);
        --l_wf_transition_info := pk_ref_core.init_wf_trans_tab(i_lang    => i_lang,
        --                                                      i_prof    => l_prof_dest,
        --                                                      i_ext_req => l_ref_row.id_external_request);
    
        g_error              := 'Calling pk_ref_core.init_param_tab';
        l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                           i_prof               => l_prof_dest,
                                                           i_ext_req            => l_ref_row.id_external_request,
                                                           i_id_patient         => l_ref_row.id_patient,
                                                           i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                           i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                           i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                           i_id_speciality      => l_ref_row.id_speciality,
                                                           i_flg_type           => l_ref_row.flg_type,
                                                           i_decision_urg_level => l_ref_row.decision_urg_level,
                                                           i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                           i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                           i_id_prof_status     => l_ref_row.id_prof_status,
                                                           i_external_sys       => l_ref_row.id_external_sys,
                                                           i_flg_status         => l_ref_row.flg_status);
    
        g_error        := 'CALL PK_REF_STATUS.CONVERT_STATUS_N / ID_EXT_REQ=' || l_ref_row.id_external_request ||
                          ' FLG_STATUS = ' || l_ref_row.flg_status;
        l_status_begin := pk_ref_status.convert_status_n(i_status => l_ref_row.flg_status);
    
        g_error      := 'CALL PK_REF_STATUS.CONVERT_STATUS_N / ID_EXT_REQ=' || l_ref_row.id_external_request ||
                        ' FLG_STATUS = ' || i_flg_status;
        l_status_end := pk_ref_status.convert_status_n(i_status => i_flg_status);
    
        -- ACM, 2010-06-29: ALERT-83871
        g_error  := 'Call pk_prof_utils.get_id_category / ID_PROF=' || l_prof_dest.id;
        l_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => l_prof_dest);
    
        g_error := 'CALL PK_WORKFLOW.CHECK_TRANSITION / ID_WF=' || l_ref_row.id_workflow || ' STATUS_BEGIN=' ||
                   l_status_begin || ' STATUS_END=' || l_status_end || ' ACTION_NAME=' || l_action_name;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => l_prof_dest,
                                                 i_id_workflow         => l_ref_row.id_workflow,
                                                 i_id_status_begin     => l_status_begin,
                                                 i_id_status_end       => l_status_end,
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(l_action_name),
                                                 i_id_category         => l_id_cat, -- ACM, 2010-06-29: ALERT-83871
                                                 i_id_profile_template => pk_ref_constant.g_profile_planner,
                                                 i_id_functionality    => 0,
                                                 i_param               => l_wf_transition_info,
                                                 o_flg_available       => l_available,
                                                 o_error               => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        IF l_available = pk_ref_constant.g_no
        THEN
            g_error := 'TRANSITION NOT ALLOWED. FROM ' || l_ref_row.flg_status || ' TO ' || i_flg_status;
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error              := 'L_REF_ROW';
        l_ref_row.flg_status := i_flg_status;
    
        IF i_decision_urg_level IS NOT NULL
        THEN
            l_ref_row.decision_urg_level := i_decision_urg_level;
        END IF;
    
        l_ref_row.id_prof_status           := i_id_prof;
        l_ref_row.dt_last_interaction_tstz := g_sysdate;
    
        -- validar transição
        g_error  := 'UPDATE P1_EXTERNAL_REQUEST';
        l_rowids := NULL;
        pk_alertlog.log_debug(g_error);
    
        g_error := ' CALL T_DATA_GOV_MNT.PROCESS_UPDATE ';
        ts_p1_external_request.upd(rec_in => l_ref_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof_orig,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error                         := 'L_TRACK_ROW';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := l_ref_row.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_institution      := i_int_dest;
        l_track_row.id_professional     := i_id_prof;
    
        l_track_row.dt_tracking_tstz := i_dt_ref_received; --(será?)
        l_track_row.dt_create        := g_sysdate;
    
        -- CHANGED BY: Ana Monteiro
        -- CHANGED DATE: 2009-OCT-29
        -- CHANGED REASON: dt_tracking_tstz must not be repeated
        g_error := 'OPEN c_track / ID_EXT_REQ=' || l_track_row.id_external_request;
        OPEN c_track(l_track_row.id_external_request);
        FETCH c_track
            INTO l_dt_tracking_tstz;
        CLOSE c_track;
    
        g_error := 'DT_TRACKING';
        IF l_track_row.dt_tracking_tstz = l_dt_tracking_tstz
        THEN
            l_track_row.dt_tracking_tstz := l_track_row.dt_tracking_tstz + INTERVAL '1' SECOND;
        END IF;
        -- CHANGE END: Ana Monteiro
    
        g_error                 := 'TS_P1_TRACKING.NEXT_KEY';
        l_track_row.id_tracking := ts_p1_tracking.next_key();
    
        l_rowids := NULL;
        g_error  := 'INSERT P1_TRACKING';
        ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'PROCESS_INSERT P1_TRACKING';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof_orig,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'Insert p1_details';
        IF i_reason IS NOT NULL
        THEN
            g_error := 'Call ' || g_package_name || '.GET_ID_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request ||
                       ' FLG_TYPE=' || pk_ref_constant.g_detail_type_jstf;
            pk_alertlog.log_debug(g_error);
            g_retval := get_id_detail(i_lang      => i_lang,
                                      i_ref_id    => l_ref_row.id_external_request,
                                      i_flg_type  => pk_ref_constant.g_detail_type_jstf,
                                      o_id_detail => l_id_detail,
                                      o_error     => o_error);
        
            IF l_id_detail IS NOT NULL
            THEN
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request ||
                           ' ID_DETAIL=' || l_id_detail;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(to_char(l_id_detail),
                                                                                                        pk_ref_constant.g_detail_type_jstf,
                                                                                                        i_reason,
                                                                                                        pk_ref_constant.g_detail_flg_o,
                                                                                                        NULL),
                                                                                          table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_jstf,
                                                                                                        i_reason,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            
            ELSE
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_jstf,
                                                                                                        i_reason,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            
            END IF;
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        IF i_notes IS NOT NULL
        THEN
            g_error  := 'CALL ' || g_package_name || '.GET_ID_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
            g_retval := get_id_detail(i_lang      => i_lang,
                                      i_ref_id    => l_ref_row.id_external_request,
                                      i_flg_type  => pk_ref_constant.g_detail_type_note,
                                      o_id_detail => l_id_detail,
                                      o_error     => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        
            IF l_id_detail IS NOT NULL
            THEN
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(to_char(l_id_detail),
                                                                                                        pk_ref_constant.g_detail_type_note,
                                                                                                        i_notes,
                                                                                                        pk_ref_constant.g_detail_flg_o,
                                                                                                        NULL),
                                                                                          table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_note,
                                                                                                        i_notes,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            ELSE
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_note,
                                                                                                        i_notes,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            END IF;
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        END IF;
    
        IF i_req_item IS NOT NULL
        THEN
            g_error  := 'CALL ' || g_package_name || '.GET_ID_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
            g_retval := get_id_detail(i_lang      => i_lang,
                                      i_ref_id    => l_ref_row.id_external_request,
                                      i_flg_type  => pk_ref_constant.g_detail_type_item,
                                      o_id_detail => l_id_detail,
                                      o_error     => o_error);
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        
            IF l_id_detail IS NOT NULL
            THEN
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL / ID_EXT_REQ=' || l_ref_row.id_external_request;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(to_char(l_id_detail),
                                                                                                        pk_ref_constant.g_detail_type_item,
                                                                                                        i_req_item,
                                                                                                        pk_ref_constant.g_detail_flg_o,
                                                                                                        NULL),
                                                                                          table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_item,
                                                                                                        i_req_item,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            
            ELSE
                g_error := 'CALLING PK_REF_CORE.SET_DETAIL';
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                   i_prof          => l_prof_orig,
                                                   i_ext_req       => l_ref_row.id_external_request,
                                                   i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                        pk_ref_constant.g_detail_type_item,
                                                                                                        i_req_item,
                                                                                                        pk_ref_constant.g_detail_flg_i,
                                                                                                        NULL)),
                                                   i_ext_req_track => l_track_row.id_tracking,
                                                   o_error         => o_error);
            END IF;
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        END IF;
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error   := 'O_EXT_REQ = ' || l_ref_row.id_external_request;
        o_ext_req := l_ref_row.id_external_request;
    
        g_error := 'O_EXT_REQ IS NULL';
        IF o_ext_req IS NULL
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_REFERRAL_INTERNAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_referral_internal;

    /*
    * Create referral 
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_prof_gender                  Professional gender
    * @param   i_prof_nick_name               Professional Nick Name  
    * @param   i_prof_first_name              Professional First Name
    * @param   i_prof_middle_name             Professional Middle             
    * @param   i_prof_last_name               Professional Last Name  
    * @param   i_title                        Professional Title                    
    * @param   i_patient                      Patient Id
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_flg_type                     Referral Type
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_dt_requested                 (RF1) Efective Date
    * @param   i_dt_ref_received              
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_ubrn                         External Referral Identifier
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION create_referral_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_dt_requested       IN p1_external_request.dt_requested%TYPE,
        i_dt_ref_received    IN p1_external_request.dt_requested%TYPE,
        i_notes              IN p1_detail.text%TYPE, -- 17
        i_req_item           IN p1_detail.text%TYPE, -- 19
        i_reason             IN p1_detail.text%TYPE, -- 0
        i_ubrn               IN p1_detail.text%TYPE, -- 20
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof      profissional;
        l_ref_row   p1_external_request%ROWTYPE;
        l_track_row p1_tracking%ROWTYPE;
    
        CURSOR c_ref IS
            SELECT *
              FROM p1_external_request
             WHERE ext_reference = i_id_ref
               AND id_external_sys = i_id_ext_sys;
    
        l_valid    VARCHAR2(1);
        l_rowids   table_varchar;
        l_workflow wf_workflow.id_workflow%TYPE;
    
        -- CHANGED BY: Ana Monteiro
        -- CHANGED DATE: 2009-OCT-29
        -- CHANGED REASON: dt_tracking_tstz must not be repeated
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
    
        CURSOR c_track(i_id_ext_req IN p1_tracking.id_external_request%TYPE) IS
            SELECT t.dt_tracking_tstz
              FROM p1_tracking t
             WHERE t.id_external_request = i_id_ext_req
             ORDER BY t.dt_tracking_tstz DESC, t.id_tracking DESC;
        -- CHANGE END: Ana Monteiro
        l_dt_ref_received p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error   := 'INIT';
        g_sysdate := current_timestamp;
        l_prof    := profissional(i_id_prof, i_int_orig, pk_ref_constant.g_id_soft_referral);
    
        ----------------------
        -- VAL
        ----------------------
    
        IF i_dt_requested > g_sysdate
        THEN
            g_error := 'DT_REQUESTED IS INVALID';
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        IF i_dt_requested IS NULL
        THEN
            g_error := 'DT_REQUESTED IS NULL';
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error           := 'DT_REF_RECEIVED = ' ||
                             pk_date_utils.to_char_insttimezone(l_prof, i_dt_ref_received, g_date_format);
        l_dt_ref_received := nvl(i_dt_ref_received, i_dt_requested);
    
        IF i_dt_requested > l_dt_ref_received
        THEN
            g_error := 'DT_REQUESTED greater than DT_REF_RECEIVED / DT_REQUESTED=' ||
                       pk_date_utils.to_char_insttimezone(l_prof, i_dt_requested, g_date_format) || ' DT_REF_RECEIVED=' ||
                       pk_date_utils.to_char_insttimezone(l_prof, i_dt_ref_received, g_date_format);
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        IF i_ubrn IS NULL
        THEN
            l_workflow := pk_ref_constant.g_wf_circle_normal;
        ELSE
            l_workflow := pk_ref_constant.g_wf_circle_cb;
        END IF;
    
        g_error  := 'CALL ' || g_package_name || '.CHECK_INSTITUTION / ID_INST=' || i_int_orig;
        g_retval := check_institution(i_lang        => i_lang,
                                      i_institution => i_int_orig,
                                      o_valid       => l_valid,
                                      o_error       => o_error);
    
        g_error := 'INSTITUTION ' || i_int_orig || ' INVALID ';
        IF l_valid = pk_ref_constant.g_no
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error  := 'CALL ' || g_package_name || '.CHECK_PROFESSIONAL / ID_PROF=' || i_id_prof;
        g_retval := check_professional(i_lang => i_lang, i_id_prof => i_id_prof, o_valid => l_valid, o_error => o_error);
    
        g_error := 'ID_PROFESSIONAL ' || i_id_prof || ' INVALID ';
        IF l_valid = pk_ref_constant.g_no
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error  := 'CALL ' || g_package_name || '.CHECK_PATIENT / ID_PAT=' || i_patient;
        g_retval := check_patient(i_lang       => i_lang,
                                  i_id_patient => i_patient,
                                  i_id_inst    => i_int_dest,
                                  o_valid      => l_valid,
                                  o_error      => o_error);
    
        g_error := 'ID_PATIENT = ' || i_patient || ' INVALID!';
        IF l_valid = pk_ref_constant.g_no
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        -- VALIDA SE O P1 EXISTE
        g_error := 'CHECK REFERRAL';
        OPEN c_ref;
        FETCH c_ref
            INTO l_ref_row;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
    
        g_error := 'REFERRAL EXISTS CREATE_REFERRAL_INTERNAL';
        IF g_found
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error                       := 'CALL TS_P1_EXTERNAL_REQUEST.NEXT_KEY()';
        l_ref_row.id_external_request := ts_p1_external_request.next_key();
    
        g_error                      := 'l_ref_row';
        l_ref_row.id_patient         := i_patient;
        l_ref_row.id_prof_requested  := i_id_prof;
        l_ref_row.id_prof_created    := i_id_prof;
        l_ref_row.num_req            := i_id_ref;
        l_ref_row.flg_status         := pk_ref_constant.g_p1_status_n;
        l_ref_row.flg_type           := i_flg_type;
        l_ref_row.id_inst_dest       := i_int_dest;
        l_ref_row.id_inst_orig       := i_int_orig;
        l_ref_row.req_type           := 'M';
        l_ref_row.decision_urg_level := i_decision_urg_level;
        l_ref_row.id_prof_status     := i_id_prof;
        l_ref_row.dt_status_tstz     := g_sysdate;
        l_ref_row.dt_requested       := i_dt_requested;
        l_ref_row.id_workflow        := l_workflow;
        l_ref_row.flg_interface      := 'S';
        l_ref_row.id_external_sys    := i_id_ext_sys;
        l_ref_row.ext_reference      := i_id_ref;
        l_ref_row.flg_mail           := pk_ref_constant.g_no;
        l_ref_row.flg_home           := pk_ref_constant.g_no;
        l_ref_row.flg_priority       := pk_ref_constant.g_no;
    
        g_error := 'INSERT INTO P1_EXTERNAL_REQUEST';
        pk_alertlog.log_debug(g_error);
    
        g_error := 'CALL TS_P1_EXTERNAL_REQUEST.INS';
        ts_p1_external_request.ins(rec_in => l_ref_row, rows_out => l_rowids);
    
        g_error := 'CALL  T_DATA_GOV_MNT.PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error                         := 'L_TRACK_ROW';
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := l_ref_row.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_institution      := i_int_dest;
        l_track_row.id_professional     := i_id_prof;
        l_track_row.dt_tracking_tstz    := i_dt_requested;
        l_track_row.dt_create           := g_sysdate;
    
        -- CHANGED BY: Ana Monteiro
        -- CHANGED DATE: 2009-OCT-29
        -- CHANGED REASON: dt_tracking_tstz must not be repeated
        g_error := 'OPEN c_track / ID_EXT_REQ=' || l_track_row.id_external_request;
        OPEN c_track(l_track_row.id_external_request);
        FETCH c_track
            INTO l_dt_tracking_tstz;
        CLOSE c_track;
    
        g_error := 'DT_TRACKING';
        IF l_track_row.dt_tracking_tstz = l_dt_tracking_tstz
        THEN
            l_track_row.dt_tracking_tstz := l_track_row.dt_tracking_tstz + INTERVAL '1' SECOND;
        END IF;
    
        g_error                 := 'CALL TS_P1_TRACKING.NEXT_KEY';
        l_track_row.id_tracking := ts_p1_tracking.next_key();
    
        l_rowids := NULL;
        g_error  := 'CALL TS_P1_TRACKING.INS';
        ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := ' CALL T_DATA_GOV_MNT.PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ACM, 2011-04-01: ALERT-156898 - inserting flg_priority and flg_home values
        g_error := 'Calling PK_REF_CORE.set_detail / ID_REF=' || l_ref_row.id_external_request || ' FLG_TYPE=' ||
                   pk_ref_constant.g_detail_type_fpriority || ' TEXT=' || l_ref_row.flg_priority;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => l_prof,
                                           i_ext_req       => l_ref_row.id_external_request,
                                           i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                pk_ref_constant.g_detail_type_fpriority,
                                                                                                l_ref_row.flg_priority,
                                                                                                pk_ref_constant.g_detail_flg_i,
                                                                                                NULL)),
                                           i_ext_req_track => l_track_row.id_tracking,
                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Calling PK_REF_CORE.set_detail / ID_REF=' || l_ref_row.id_external_request || ' FLG_TYPE=' ||
                   pk_ref_constant.g_detail_type_fhome || ' TEXT=' || l_ref_row.flg_home;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => l_prof,
                                           i_ext_req       => l_ref_row.id_external_request,
                                           i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                pk_ref_constant.g_detail_type_fhome,
                                                                                                l_ref_row.flg_home,
                                                                                                pk_ref_constant.g_detail_flg_i,
                                                                                                NULL)),
                                           i_ext_req_track => l_track_row.id_tracking,
                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error := 'INSERT P1_DETAILS I_UBRN = ' || i_ubrn;
        IF i_ubrn IS NOT NULL
        THEN
            g_error := 'CALLING PK_REF_CORE.SET_DETAIL INSERT UBRN';
            pk_alertlog.log_debug(g_error);
            g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                               i_prof          => l_prof,
                                               i_ext_req       => l_ref_row.id_external_request,
                                               i_detail        => table_table_varchar(table_varchar(NULL,
                                                                                                    pk_ref_constant.g_detail_type_ubrn,
                                                                                                    i_ubrn,
                                                                                                    pk_ref_constant.g_detail_flg_i,
                                                                                                    NULL)),
                                               i_ext_req_track => l_track_row.id_tracking,
                                               o_error         => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn(g_error);
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error  := 'CALL UPDATE_REFERRAL_INTERNAL';
        g_retval := update_referral_internal(i_lang               => i_lang,
                                             i_id_prof            => i_id_prof,
                                             i_int_orig           => i_int_orig,
                                             i_int_dest           => i_int_dest,
                                             i_id_ref             => i_id_ref,
                                             i_id_ext_sys         => i_id_ext_sys,
                                             i_flg_status         => i_flg_status,
                                             i_decision_urg_level => i_decision_urg_level,
                                             i_notes              => i_notes,
                                             i_req_item           => i_req_item,
                                             i_reason             => i_reason,
                                             i_dt_ref_received    => l_dt_ref_received,
                                             o_ext_req            => o_ext_req,
                                             o_error              => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error   := 'O_EXT_REQ = ' || l_ref_row.id_external_request;
        o_ext_req := l_ref_row.id_external_request;
    
        g_error := 'O_EXT_REQ IS NULL';
        IF o_ext_req IS NULL
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REFERRAL_INTERNAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_referral_internal;

    /*
    * Update referral status and details and ckeck professional
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_dt_ref_received
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION update_referral
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_gp_code       IN professional.num_order%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_notes              IN p1_detail.text%TYPE,
        i_req_item           IN p1_detail.text%TYPE,
        i_reason             IN p1_detail.text%TYPE,
        i_dt_ref_received    IN p1_tracking.dt_tracking_tstz%TYPE,
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_professional
              FROM professional
             WHERE num_order = i_prof_gp_code;
    
        l_prof professional.id_professional%TYPE;
    
    BEGIN
        g_error   := 'INIT';
        g_sysdate := current_timestamp;
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_prof;
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'PROFESSIONAL NOT FOUND';
        IF NOT g_found
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error  := 'CALL UPDATE_REFERRAL_INTERNAL';
        g_retval := update_referral_internal(i_lang               => i_lang,
                                             i_id_prof            => l_prof,
                                             i_int_orig           => i_int_orig,
                                             i_int_dest           => i_int_dest,
                                             i_id_ref             => i_id_ref,
                                             i_id_ext_sys         => i_id_ext_sys,
                                             i_flg_status         => i_flg_status,
                                             i_decision_urg_level => i_decision_urg_level,
                                             i_notes              => i_notes,
                                             i_req_item           => i_req_item,
                                             i_reason             => i_reason,
                                             i_dt_ref_received    => g_sysdate, --i_dt_ref_received,
                                             o_ext_req            => o_ext_req,
                                             o_error              => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_REFERRAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_referral;

    /*
    * Cancel referral 
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_id_prof        id professional, 
    * @param   i_inst           institution    
    * @param   i_ref_ext_sys    extenal system referral id   
    * @param   i_id_extenal_sys external system
    * @param   i_notes          cancelation notes episode id    
    * @param   i_reason         cancelation reason code    
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION cancel_referral
    (
        i_lang            IN language.id_language%TYPE,
        i_prof_gp_code    IN professional.num_order%TYPE,
        i_int_dest        IN institution.id_institution%TYPE,
        i_id_ref          IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys      IN p1_external_request.id_external_sys%TYPE,
        i_dt_ref_received IN p1_tracking.dt_tracking_tstz%TYPE,
        o_ext_req         OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_professional
              FROM professional
             WHERE num_order = i_prof_gp_code;
    
        l_prof professional.id_professional%TYPE;
    
        CURSOR c_inst IS
            SELECT id_inst_orig
              FROM p1_external_request
             WHERE id_external_sys = i_id_ext_sys
               AND ext_reference = i_id_ref;
    
        l_inst_orig institution.id_institution%TYPE;
    
    BEGIN
    
        g_error   := 'INIT';
        g_sysdate := current_timestamp;
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_prof;
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        IF NOT g_found
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN C_INST';
        OPEN c_inst;
    
        g_error := 'FETCH C_INST';
        FETCH c_inst
            INTO l_inst_orig;
        g_found := c_inst%FOUND;
    
        g_error := 'CLOSE C_INST';
        CLOSE c_inst;
    
        IF NOT g_found
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception;
        END IF;
    
        g_error  := 'CALLING ' || g_package_name || '.UPDATE_REFERRAL_INTERNAL I_NUM_REQ = ' || i_id_ref ||
                    'I_ID_EXTENAL_SYS = ' || i_id_ext_sys;
        g_retval := update_referral_internal(i_lang               => i_lang,
                                             i_id_prof            => l_prof,
                                             i_int_orig           => l_inst_orig,
                                             i_int_dest           => i_int_dest,
                                             i_id_ref             => i_id_ref,
                                             i_id_ext_sys         => i_id_ext_sys,
                                             i_flg_status         => pk_ref_constant.g_p1_status_x,
                                             i_decision_urg_level => NULL,
                                             i_notes              => NULL,
                                             i_req_item           => NULL,
                                             i_reason             => NULL,
                                             i_dt_ref_received    => i_dt_ref_received,
                                             o_ext_req            => o_ext_req,
                                             o_error              => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_warn(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REFERRAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_referral;

    /*
    * Create referral (and ProfessionaL if the gp_code is not in table professional )
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_prof_gender                  Professional gender
    * @param   i_prof_nick_name               Professional Nick Name  
    * @param   i_prof_first_name              Professional First Name
    * @param   i_prof_middle_name             Professional Middle             
    * @param   i_prof_last_name               Professional Last Name  
    * @param   i_title                        Professional Title                    
    * @param   i_patient                      Patient Id
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_flg_type                     Referral Type
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_dt_requested                 (RF1) Efective Date
    * @param   i_dt_ref_received              
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_ubrn                         External Referral Identifier
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION create_referral
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_gp_code       IN professional.num_order%TYPE,
        i_prof_gender        IN professional.gender%TYPE DEFAULT 'I',
        i_prof_nick_name     IN professional.nick_name%TYPE,
        i_prof_first_name    IN professional.first_name%TYPE,
        i_prof_middle_name   IN professional.middle_name%TYPE,
        i_prof_last_name     IN professional.last_name%TYPE,
        i_prof_title         IN professional.title%TYPE DEFAULT NULL,
        i_patient            IN patient.id_patient%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_dt_requested       IN p1_external_request.dt_requested%TYPE,
        i_dt_ref_received    IN p1_external_request.dt_requested%TYPE,
        i_notes              IN p1_detail.text%TYPE, -- 17
        i_req_item           IN p1_detail.text%TYPE, -- 19
        i_reason             IN p1_detail.text%TYPE, -- 0
        i_ubrn               IN p1_detail.text%TYPE, -- 20
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_professional
              FROM professional
             WHERE num_order = i_prof_gp_code;
    
        l_prof   professional.id_professional%TYPE;
        l_gender professional.gender%TYPE;
    
    BEGIN
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_prof;
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        IF g_found -- profissional já existe
        THEN
            g_error  := 'CALL CREATE_REFERRAL_INTERNAL PROF EXISTS';
            g_retval := create_referral_internal(i_lang               => i_lang,
                                                 i_id_prof            => l_prof,
                                                 i_patient            => i_patient,
                                                 i_int_orig           => i_int_orig,
                                                 i_int_dest           => i_int_dest,
                                                 i_id_ref             => i_id_ref,
                                                 i_id_ext_sys         => i_id_ext_sys,
                                                 i_flg_status         => i_flg_status,
                                                 i_flg_type           => i_flg_type,
                                                 i_decision_urg_level => i_decision_urg_level,
                                                 i_dt_requested       => i_dt_requested,
                                                 i_dt_ref_received    => i_dt_ref_received,
                                                 i_notes              => i_notes,
                                                 i_req_item           => i_req_item,
                                                 i_reason             => i_reason,
                                                 i_ubrn               => i_ubrn,
                                                 o_ext_req            => o_ext_req,
                                                 o_error              => o_error);
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn('ERROR :' || g_error);
                RAISE g_exception_np;
            END IF;
        ELSE
        
            IF i_prof_gender IS NULL
            THEN
                l_gender := pk_ref_constant.g_gender_i;
            ELSE
                l_gender := i_prof_gender;
            END IF;
        
            g_error := 'MISSING PROFESSIONAL DATA. I_PROF_FIRST_NAME = ' || i_prof_first_name ||
                       ' I_PROF_MIDDLE_NAME = ' || i_prof_middle_name || ' I_PROF_LAST_NAME = ' || i_prof_last_name ||
                       ' I_PROF_NICK_NAME = ' || i_prof_nick_name || ' I_PROF_GP_CODE = ' || i_prof_gp_code;
        
            IF i_prof_first_name IS NULL
               OR i_prof_middle_name IS NULL
               OR i_prof_last_name IS NULL
               OR i_prof_nick_name IS NULL
               OR i_prof_gp_code IS NULL
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception;
            END IF;
        
            -- cria profissional e depois o referral
            g_error  := 'CALL PK_API_BACKOFFICE.INTF_SET_PROFISSIONAL PROF NOT EXISTS';
            g_retval := pk_api_backoffice.intf_set_profissional(i_lang           => i_lang,
                                                                i_id_prof        => NULL,
                                                                i_id_inst        => i_int_orig,
                                                                i_title          => i_prof_title,
                                                                i_first_name     => i_prof_first_name,
                                                                i_middle_name    => i_prof_middle_name,
                                                                i_last_name      => i_prof_last_name,
                                                                i_nickname       => i_prof_nick_name,
                                                                i_initials       => '',
                                                                i_dt_birth       => '',
                                                                i_gender         => l_gender,
                                                                i_marital_status => '',
                                                                i_category       => table_number(pk_ref_constant.g_cat_id_med),
                                                                i_id_speciality  => '',
                                                                i_num_order      => i_prof_gp_code,
                                                                i_upin           => '',
                                                                i_dea            => '',
                                                                i_id_cat_surgery => table_number(NULL),
                                                                i_num_mecan      => '',
                                                                i_id_lang        => i_lang,
                                                                i_flg_state      => pk_ref_constant.g_active,
                                                                i_address        => '',
                                                                i_city           => '',
                                                                i_district       => '',
                                                                i_zip_code       => '',
                                                                i_id_country     => '',
                                                                i_phone          => '',
                                                                i_num_contact    => '',
                                                                i_mobile_phone   => '',
                                                                i_fax            => '',
                                                                i_email          => '',
                                                                --i_suffix         => NULL,
                                                                --i_contact_det    => NULL,
                                                                o_professional => l_prof,
                                                                o_error        => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_warn('ERROR :' || g_error);
                RAISE g_exception_np;
            END IF;
        
            g_error := 'FLG_STAUS CAN''T BE N';
            IF i_flg_status = pk_ref_constant.g_p1_status_n
            THEN
                pk_alertlog.log_warn('ERROR :' || g_error);
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'CALL CREATE_REFERRAL_INTERNAL';
            g_retval := create_referral_internal(i_lang               => i_lang,
                                                 i_id_prof            => l_prof,
                                                 i_patient            => i_patient,
                                                 i_int_orig           => i_int_orig,
                                                 i_int_dest           => i_int_dest,
                                                 i_id_ref             => i_id_ref,
                                                 i_id_ext_sys         => i_id_ext_sys,
                                                 i_flg_status         => i_flg_status,
                                                 i_flg_type           => i_flg_type,
                                                 i_decision_urg_level => i_decision_urg_level,
                                                 i_dt_requested       => i_dt_requested,
                                                 i_dt_ref_received    => i_dt_ref_received,
                                                 i_notes              => i_notes,
                                                 i_req_item           => i_req_item,
                                                 i_reason             => i_reason,
                                                 i_ubrn               => i_ubrn,
                                                 o_ext_req            => o_ext_req,
                                                 o_error              => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR :' || g_error;
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REFERRAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_referral;

    /*
    * Create schedule 
    *
    * @param   i_lang          Language 
    * @param   i_prof          (Professional, Institution, Software)
    * @param   i_sched_outp    Record containing data from an external system
    * @param   i_id_ext_ref    Referral id in the external system 
    * @param   i_id_ext_sys    External system
    * @param   o_new_id_sched  Schedule identifier on ALERT Scheduler
    * @param   o_warning       Warning message.
    * @param   o_error         An error message, set when return = false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-11-2009
    */

    FUNCTION create_ref_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_sched_outp   IN pk_schedule_interface.schedule_outp_struct,
        i_id_ext_ref   IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_external_request
              FROM p1_external_request
             WHERE ext_reference = i_id_ext_ref
               AND id_external_sys = i_id_ext_sys
               AND flg_type = pk_ref_constant.g_p1_type_c;
    
        l_id_ref p1_external_request.id_external_request%TYPE;
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_id_ref;
    
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'REFERRAL DO NOT EXIST';
        IF NOT g_found
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'CALL PK_SCHEDULE_INTERFACE.CREATE_SCHEDULE_OUTP';
        g_retval := pk_schedule_interface.create_schedule_outp(i_sched_outp   => i_sched_outp,
                                                               o_new_id_sched => o_new_id_sched,
                                                               o_warning      => o_warning,
                                                               o_error        => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'CALL PK_REF_EXT_SYS.UPDATE_REFERRAL_STATUS I_STATUS' || pk_ref_constant.g_p1_status_s;
        g_retval := pk_ref_ext_sys.update_referral_status(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_ext_req  => l_id_ref,
                                                          i_status   => pk_ref_constant.g_p1_status_s,
                                                          i_notes    => NULL,
                                                          i_schedule => o_new_id_sched,
                                                          i_episode  => NULL,
                                                          o_error    => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_SCHEDULE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_ref_schedule;

    /*
    * Create schedule with RE_map
    *
    * @param   i_lang          Language 
    * @param   i_prof          (Professional, Institution, Software)
    * @param   i_sched_outp    Record containing data from an external system
    * @param   i_id_ext_ref    Referral id in the external system 
    * @param   i_id_ext_sys    External system
    * @param   o_new_id_sched  Schedule identifier on ALERT Scheduler
    * @param   o_warning       Warning message.
    * @param   o_error         An error message, set when return = false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-11-2010
    */

    FUNCTION create_sch_with_ref_map
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_sched_outp   IN pk_schedule_interface.schedule_outp_struct,
        i_id_ext_ref   IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_id_ref_map   OUT ref_map.id_ref_map%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT id_external_request
              FROM p1_external_request
             WHERE ext_reference = i_id_ext_ref
               AND id_external_sys = i_id_ext_sys;
    
        l_id_ref p1_external_request.id_external_request%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_id_ref;
    
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'REFERRAL DO NOT EXIST';
        IF NOT g_found
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'CALL PK_SCHEDULE_INTERFACE.CREATE_SCHEDULE_OUTP';
        g_retval := pk_schedule_interface.create_schedule_outp(i_sched_outp   => i_sched_outp,
                                                               o_new_id_sched => o_new_id_sched,
                                                               o_warning      => o_warning,
                                                               o_error        => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'CALL PK_SCHEDULE_INTERFACE.create_ref_map i_id_ext_ref = ' || i_id_ext_ref || 'i_id_ext_sys = ' ||
                    i_id_ext_sys || 'i_id_schedule = ' || o_new_id_sched;
        g_retval := pk_ref_inter_circle.create_ref_map(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_ext_ref  => i_id_ext_ref,
                                                       i_id_ext_sys  => i_id_ext_sys,
                                                       i_id_schedule => o_new_id_sched,
                                                       i_id_episode  => NULL,
                                                       o_id_ref_map  => o_id_ref_map,
                                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_SCH_WITH_REF_MAP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_sch_with_ref_map;

    /*
    * Cancel schedule 
    *
    * @param   i_lang                  Language 
    * @param   i_prof                  (Professional, Institution, Software)
    * @param   i_sched_outp_cancel     Cancellation data.    
    * @param   o_id_ref                Alert Referral ID
    * @param   o_warning               Warning message.
    * @param   o_error                 an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-11-2009
    */

    FUNCTION cancel_ref_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_sched_outp_cancel IN pk_schedule_interface.schedule_outp_cancel_struct,
        i_id_ref            IN p1_external_request.id_external_request%TYPE,
        o_warning           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur IS
            SELECT COUNT(1)
              FROM p1_external_request
             WHERE id_external_request = i_id_ref
            -- AND flg_type = pk_ref_constant.g_p1_type_c
            ;
    
        l_var p1_external_request.id_external_request%TYPE;
    
    BEGIN
    
        --i_sched_outp_cancel.id_schedule
    
        g_error  := 'CALL PK_SCHEDULE_INTERFACE.CREATE_SCHEDULE_OUTP';
        g_retval := pk_schedule_interface.cancel_schedule_outp(i_sched_outp_cancel => i_sched_outp_cancel,
                                                               o_warning           => o_warning,
                                                               o_error             => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR = ' || g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN C_CUR';
        OPEN c_cur;
    
        g_error := 'FETCH C_CUR';
        FETCH c_cur
            INTO l_var;
        g_found := c_cur%FOUND;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'REFERRAL DO NOT EXIST';
        IF NOT g_found
        THEN
            pk_alertlog.log_error('ERROR = ' || g_error);
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'CALL pk_ref_ext_sys.cancel_ref_schedule i_schedule = ' || i_sched_outp_cancel.id_schedule ||
                    ' i_notes = ' || i_sched_outp_cancel.cancel_notes || ' i_date = ' || i_sched_outp_cancel.dt_cancel;
        g_retval := pk_ref_ext_sys.cancel_ref_schedule(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_id_ref   => i_id_ref,
                                                       i_schedule => i_sched_outp_cancel.id_schedule,
                                                       i_notes    => i_sched_outp_cancel.cancel_notes,
                                                       i_date     => i_sched_outp_cancel.dt_cancel,
                                                       o_error    => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR = ' || g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_SCHEDULE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END cancel_ref_schedule;

    /*
    * Get external system and external reference
    *
    * @param   i_lang         Language 
    * @param   i_prof        (Professional, Institution, Software)
    * @param   i_schedule     Id schedule
    * @param   o_id_ref       Referral id    
    * @param   o_error        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-11-2009
    */

    FUNCTION get_ref_from_map
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        o_id_ref   OUT p1_external_request.id_external_request%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_ref IS
            SELECT id_external_request
              FROM ref_map
             WHERE id_schedule = i_schedule
               AND flg_status = pk_ref_constant.g_active;
    
        l_id_external_request p1_external_request.id_external_request%TYPE;
    BEGIN
    
        g_error := 'OPEN C_REF';
        OPEN c_ref;
    
        g_error := 'FETCH C_REF';
        FETCH c_ref
            INTO l_id_external_request;
    
        g_found := c_ref%FOUND;
    
        g_error := 'CLOSE C_REF';
        CLOSE c_ref;
    
        g_error := 'REFERRAL DO NOT EXIST';
        IF NOT g_found
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        o_id_ref := l_id_external_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_FROM_MAP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_ref_from_map;

    /**
    * Cancels REF_MAP record 
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data 
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-06-2010
    */
    FUNCTION cancel_ref_map
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ref_map_schedule IN ref_map.id_schedule%TYPE,
        i_ref_map_episode  IN ref_map.id_episode%TYPE,
        i_id_ext_ref       IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys       IN p1_external_request.id_external_sys%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ref_map_row ref_map%ROWTYPE;
        l_id_ref_map  ref_map.id_ref_map%TYPE;
        l_id_pat      patient.id_patient%TYPE;
        l_epis        episode.id_episode%TYPE;
    
        CURSOR c_cur(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT flg_status
              FROM p1_external_request
             WHERE id_external_request = x_ref;
    
        CURSOR c_count(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT COUNT(id_ref_map)
              FROM ref_map
             WHERE id_external_request = x_ref
               AND flg_status = pk_ref_constant.g_active;
    
        l_flg_status p1_external_request.flg_status%TYPE;
        l_count      PLS_INTEGER;
    
        l_ref_row p1_external_request%ROWTYPE;
        l_var     p1_external_request.id_external_request%TYPE;
    
    BEGIN
    
        g_error  := 'CALL get_referral_id i_ref_ext_sys = ' || i_id_ext_ref || ' i_id_extenal_sys = ' || i_id_ext_sys;
        g_retval := get_referral_id(i_lang           => i_lang,
                                    i_ref_ext_sys    => i_id_ext_ref,
                                    i_id_extenal_sys => i_id_ext_sys,
                                    o_id_ref         => l_ref_map_row.id_external_request,
                                    o_id_pat         => l_id_pat,
                                    o_epis           => l_epis,
                                    o_error          => o_error);
    
        g_error := 'SELECT  l_id_ref_map = ' || l_id_ref_map || 'id_external_request = ' ||
                   l_ref_map_row.id_external_request;
        SELECT rm.id_ref_map
          INTO l_id_ref_map
          FROM ref_map rm
         WHERE rm.id_external_request = l_ref_map_row.id_external_request
           AND ((i_ref_map_schedule IS NOT NULL AND rm.id_schedule = i_ref_map_schedule) OR
               (i_ref_map_episode IS NOT NULL AND rm.id_episode = i_ref_map_episode))
           AND rm.flg_status = pk_ref_constant.g_active;
    
        l_ref_map_row.id_ref_map  := l_id_ref_map;
        l_ref_map_row.id_schedule := i_ref_map_schedule;
        l_ref_map_row.id_episode  := i_ref_map_episode;
        l_ref_map_row.flg_status  := 'C';
    
        g_error := 'OPEN C_CUR l_id_external_request = ' || l_ref_map_row.id_external_request;
        OPEN c_cur(l_ref_map_row.id_external_request);
    
        g_error := 'FETCH l_flg_status = ' || l_flg_status;
        FETCH c_cur
            INTO l_flg_status;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        g_error := 'OPEN c_count l_id_external_request = ' || l_ref_map_row.id_external_request;
        OPEN c_count(l_ref_map_row.id_external_request);
    
        g_error := 'FETCH l_count = ' || l_count;
        FETCH c_count
            INTO l_count;
    
        g_error := 'CLOSE c_count';
        CLOSE c_count;
    
        IF l_flg_status = pk_ref_constant.g_p1_status_s
        THEN
        
            IF l_count = 1
            THEN
            
                SELECT *
                  INTO l_ref_row
                  FROM p1_external_request
                 WHERE id_external_request = l_ref_map_row.id_external_request;
            
                g_error  := 'CALL pk_ref_ext_sys.update_referral_status';
                g_retval := update_referral_internal(i_lang               => i_lang,
                                                     i_id_prof            => i_prof.id,
                                                     i_int_orig           => l_ref_row.id_inst_orig,
                                                     i_int_dest           => l_ref_row.id_inst_dest,
                                                     i_id_ref             => i_id_ext_ref,
                                                     i_id_ext_sys         => i_id_ext_sys,
                                                     i_flg_status         => pk_ref_constant.g_p1_status_a,
                                                     i_decision_urg_level => l_ref_row.decision_urg_level,
                                                     i_notes              => get_detail_text(i_ref_id   => l_ref_map_row.id_external_request,
                                                                                             i_flg_type => pk_ref_constant.g_detail_type_note), -- 17
                                                     i_req_item           => get_detail_text(i_ref_id   => l_ref_map_row.id_external_request,
                                                                                             i_flg_type => pk_ref_constant.g_detail_type_item),
                                                     i_reason             => get_detail_text(i_ref_id   => l_ref_map_row.id_external_request,
                                                                                             i_flg_type => pk_ref_constant.g_detail_type_jstf),
                                                     i_dt_ref_received    => current_timestamp,
                                                     o_ext_req            => l_var,
                                                     o_error              => o_error);
            
                IF NOT g_retval
                THEN
                    pk_alertlog.log_error(g_error);
                    RAISE g_exception_np;
                END IF;
            
                /* g_retval := pk_ref_ext_sys.update_referral_status(i_lang     => i_lang,
                i_prof     => i_prof,
                i_ext_req  => l_ref_map_row.id_external_request,
                i_status   => pk_ref_constant.g_p1_status_c,
                i_notes    => NULL,
                i_schedule => i_ref_map_schedule,
                i_episode  => i_ref_map_episode,
                i_date     => current_timestamp,
                o_error    => o_error);*/
            END IF;
        
            g_error  := 'CALL pk_ref_api.cancel_ref_map';
            g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_ref_map_row => l_ref_map_row,
                                                  o_error       => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error('ERROR = ' || g_error);
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_MAP',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_ref_map;

    /*
    * Creates an active REF_MAP record 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_schedule    Schedule identifier
    * @param   i_id_episode     Episode identifier
    * @param   o_id_ref_map     REF_MAP identifier     
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-06-2010
    */
    FUNCTION create_ref_map
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_ref  IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        i_id_schedule IN ref_map.id_schedule%TYPE DEFAULT NULL,
        i_id_episode  IN ref_map.id_episode%TYPE,
        o_id_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat              patient.id_patient%TYPE;
        l_epis                episode.id_episode%TYPE;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_flg_status          p1_external_request.flg_status%TYPE;
    
        CURSOR c_cur IS
            SELECT flg_status
              FROM p1_external_request
             WHERE id_external_request = l_id_external_request;
    
        l_ref_row p1_external_request%ROWTYPE;
        l_var     p1_external_request.id_external_request%TYPE;
    
    BEGIN
    
        g_error  := 'CALL get_referral_id';
        g_retval := get_referral_id(i_lang           => i_lang,
                                    i_ref_ext_sys    => i_id_ext_ref,
                                    i_id_extenal_sys => i_id_ext_sys,
                                    o_id_ref         => l_id_external_request,
                                    o_id_pat         => l_id_pat,
                                    o_epis           => l_epis,
                                    o_error          => o_error);
    
        g_error := 'OPEN C_CUR l_id_external_request = ' || l_id_external_request;
        OPEN c_cur;
    
        g_error := 'FETCH l_flg_status = ' || l_flg_status;
        FETCH c_cur
            INTO l_flg_status;
    
        g_error := 'CLOSE C_CUR';
        CLOSE c_cur;
    
        IF l_flg_status = pk_ref_constant.g_p1_status_a
        THEN
            g_error := 'CALL pk_ref_ext_sys.update_referral_status';
        
            SELECT *
              INTO l_ref_row
              FROM p1_external_request
             WHERE id_external_request = l_id_external_request;
        
            g_error  := 'CALL pk_ref_ext_sys.update_referral_status';
            g_retval := update_referral_internal(i_lang               => i_lang,
                                                 i_id_prof            => i_prof.id,
                                                 i_int_orig           => l_ref_row.id_inst_orig,
                                                 i_int_dest           => l_ref_row.id_inst_dest,
                                                 i_id_ref             => i_id_ext_ref,
                                                 i_id_ext_sys         => i_id_ext_sys,
                                                 i_flg_status         => pk_ref_constant.g_p1_status_s,
                                                 i_decision_urg_level => l_ref_row.decision_urg_level,
                                                 i_notes              => get_detail_text(i_ref_id   => l_id_external_request,
                                                                                         i_flg_type => pk_ref_constant.g_detail_type_note), -- 17
                                                 i_req_item           => get_detail_text(i_ref_id   => l_id_external_request,
                                                                                         i_flg_type => pk_ref_constant.g_detail_type_item),
                                                 i_reason             => get_detail_text(i_ref_id   => l_id_external_request,
                                                                                         i_flg_type => pk_ref_constant.g_detail_type_jstf),
                                                 i_dt_ref_received    => current_timestamp,
                                                 o_ext_req            => l_var,
                                                 o_error              => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception_np;
            END IF;
        
            /*            
             g_retval := pk_ref_ext_sys.update_referral_status(i_lang     => i_lang,
                                                                  i_prof     => i_prof,
                                                                  i_ext_req  => l_id_external_request,
                                                                  i_status   => pk_ref_constant.g_p1_status_s,
                                                                  i_notes    => NULL,
                                                                  i_schedule => i_id_schedule,
                                                                  i_episode  => i_id_episode,
                                                                  i_date     => current_timestamp,
                                                                  o_error    => o_error);
            */
        END IF;
        g_error  := 'CALL PK_REF_API.CREATE_REF_MAP';
        g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_ref      => l_id_external_request,
                                              i_id_schedule => i_id_schedule,
                                              i_id_episode  => i_id_episode,
                                              o_id_ref_map  => o_id_ref_map,
                                              o_error       => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR = ' || g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_MAP',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_ref_map;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ref_inter_circle;
/
