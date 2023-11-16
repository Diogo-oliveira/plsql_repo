/*-- Last Change Revision: $Rev: 2027596 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_status AS

    g_error         VARCHAR2(1000 CHAR);
    g_sysdate       TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    g_tab_status_v t_ibt_status_v;
    g_tab_status_n t_ibt_status_n;

    PROCEDURE init_status IS
        CURSOR c_ref_status IS
            SELECT *
              FROM ref_wf_status;
    BEGIN
    
        -- initializing status ibts
        FOR i IN c_ref_status
        LOOP
            g_error := 'status ' || i.id_status;
            g_tab_status_v(i.id_status) := i.flg_status;
            g_tab_status_n(i.flg_status) := i.id_status;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
    END init_status;

    PROCEDURE reset_vars IS
    BEGIN
    
        --g_sysdate := NULL;
    
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
    * Is the referral already answered?
    *
    * @param   I_LANG              Language associated to the professional executing the request
    * @param   I_PROF              Professional, institution and software ids
    * @param   I_EPISODE           Id episode 
    * @param   O_ID_EXT_REQ        External Request Identifier 
    * @param   O_WORKFLOW          workflow of the external request
    * @param   O_STATUS_DETAIL     status_detail , null by default
    * @param   O_NEEDS_ANSWER      Does the referral need answer?
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   22-07-2010
    */
    FUNCTION check_ref_answered
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN p1_external_request.id_episode%TYPE,
        o_id_ext_req    OUT p1_external_request.id_external_request%TYPE,
        o_workflow      OUT p1_external_request.id_workflow%TYPE,
        o_status_detail OUT p1_detail.flg_status%TYPE,
        o_needs_answer  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT p.id_external_request, p.id_workflow, NULL
              FROM p1_external_request p
             WHERE p.id_episode = i_episode
               AND p.flg_status = pk_ref_constant.g_p1_status_e
            --AND p.ext_reference IS NOT NULL
            ;
    
    BEGIN
    
        g_error := 'Init check_ref_answered / ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN CURSOR';
        OPEN c_ref;
        g_error := 'FETCH CURSOR';
        FETCH c_ref
            INTO o_id_ext_req, o_workflow, o_status_detail;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
        g_error := 'c_ref empty';
    
        IF NOT g_found
        THEN
            o_needs_answer := pk_ref_constant.g_no;
        ELSE
            o_needs_answer := pk_ref_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_ANSWERED',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_ref_answered;

    /**
    * Checks if referral can change to the new workflow identifier
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_wf_old           Id episode 
    * @param   i_id_wf_new         Referral new workflow identifier 
    * @param   i_flg_status        Referral flag status
    * @param   O_STATUS_DETAIL     status_detail , null by default
    * @param   O_NEEDS_ANSWER      Does the referral need answer?
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-05-2013
    */
    FUNCTION check_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_wf_old  IN p1_external_request.id_workflow%TYPE,
        i_id_wf_new  IN p1_external_request.id_workflow%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_can_change OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_id_wf_old=' || i_id_wf_old || ' i_id_wf_new=' || i_id_wf_new || ' i_flg_status=' || i_flg_status;
        g_error  := 'Init check_workflow_change / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_can_change := pk_ref_constant.g_no;
    
        -- check if the new status exists in the new workflow
        o_can_change := pk_workflow.check_wf_status(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_workflow => i_id_wf_new,
                                                    i_id_status   => convert_status_n(i_flg_status));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_WORKFLOW_CHANGE',
                                              o_error    => o_error);
            o_can_change := pk_ref_constant.g_no;
            RETURN FALSE;
    END check_workflow_change;

    /**
    * Gets dep_clin_serv available for issuing the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_ref_row        Referral rowtype
    * @param   i_dcs            Dep_clin_Serv identifier
    * @param   i_mode           Mode: change (S)ame or (O)ther Institution
    * @param   o_dcs_count      dep_clin_serv count
    * @param   o_track_dcs      Dep_clin_Serv default
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-08-2010
    */
    FUNCTION get_dcs_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mode      IN VARCHAR2 DEFAULT NULL,
        o_dcs_count OUT NUMBER,
        o_track_dcs OUT p1_tracking.id_dep_clin_serv%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dcs_id    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_dcs_count NUMBER DEFAULT 0;
    BEGIN
        g_error  := 'Calling pk_ref_core.get_clin_serv_forward_count / I_PROF=' || pk_utils.to_string(i_prof) ||
                    ' ID_REF=' || i_ref_row.id_external_request;
        g_retval := pk_ref_core.get_clin_serv_forward_count(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_ext_req => i_ref_row.id_external_request,
                                                            o_count   => l_dcs_count,
                                                            o_id      => l_dcs_id,
                                                            o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'ID_REF=' || i_ref_row.id_external_request || ' I_DCS=' || i_dcs || ' I_MODE=' || i_mode ||
                   ' DCS_COUNT=' || l_dcs_count || ' DCS_ID=' || l_dcs_id || ' FLG_TYPE=' || i_ref_row.flg_type ||
                   ' REF_DCS=' || i_ref_row.id_dep_clin_serv;
        IF i_ref_row.flg_type = pk_ref_constant.g_p1_type_c
        THEN
            IF (i_mode = pk_ref_constant.g_issue_mode_o AND i_dcs IS NOT NULL) -- instituion change
               OR (i_mode = pk_ref_constant.g_issue_mode_s AND i_ref_row.id_dep_clin_serv IS NOT NULL) -- dep_clin_serv changed previously
            THEN
                o_track_dcs := i_dcs;
                l_dcs_count := 1;
            ELSIF (i_mode = pk_ref_constant.g_issue_mode_o AND i_dcs IS NULL)
                  OR (i_mode = pk_ref_constant.g_issue_mode_s AND i_ref_row.id_dep_clin_serv IS NULL)
            THEN
                -- If theres only one id_dep_clin_serv defined in p1_workflow_config uses it
                IF l_dcs_count = 1
                THEN
                    o_track_dcs := l_dcs_id;
                ELSE
                
                    g_error  := 'Call pk_ref_core.get_default_dcs / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_DEP_CLIN_SERV=' || i_ref_row.id_dep_clin_serv;
                    g_retval := pk_ref_core.get_default_dcs(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_exr_row => i_ref_row,
                                                            o_dcs     => o_track_dcs,
                                                            o_error   => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    g_error := 'l_dcs_count=' || l_dcs_count;
                    IF l_dcs_count = 0
                    THEN
                        l_dcs_count := 1;
                    END IF;
                
                END IF;
            
            ELSIF i_mode = pk_ref_constant.g_issue_mode_s
                  AND i_ref_row.id_workflow = pk_ref_constant.g_wf_srv_srv
            THEN
            
                g_error     := 'WF=' || i_ref_row.id_workflow || ' REF_DCS=' || i_ref_row.id_dep_clin_serv;
                l_dcs_count := 1;
                o_track_dcs := i_ref_row.id_dep_clin_serv;
            END IF;
        END IF;
    
        g_error     := 'L_DCS_COUNT=' || l_dcs_count;
        o_dcs_count := l_dcs_count;
    
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
                                              i_function => 'GET_DCS_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_dcs_info;

    /**
    * Converts referral status varchar into a number
    *
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_n(i_status IN p1_external_request.flg_status%TYPE) RETURN NUMBER IS
    BEGIN
        g_error := 'RETURN converting status ' || i_status || ' to number';
        RETURN g_tab_status_n(i_status);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END convert_status_n;

    /**
    * Converts referral status number into a varchar
    *
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_v(i_status IN wf_status.id_status%TYPE) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'RETURN converting status ' || i_status || ' to varchar';
    
        RETURN g_tab_status_v(i_status);
    EXCEPTION
        WHEN OTHERS THEN
            IF i_status != pk_ref_constant.g_p1_status_initial
            THEN
                pk_alertlog.log_warn(g_error);
            END IF;
            RETURN NULL;
        
    END convert_status_v;

    /**
    * Returns next status when processing this action.
    * Only possible for ID_WORKFLOW/ID_STATUS_BEGIN/ID_ACTION with only one ID_STATUS_END.
    *
    * @param   I_LANG                     Language associated to the professional executing the request
    * @param   I_PROF                     Professional, institution and software ids
    * @param   I_PROF_DATA                Professional info: profile template, category and functionality
    * @param   I_ID_WORKFLOW              Workflow identifier
    * @param   I_FLG_STATUS               Referral current status
    * @param   I_ACTION_NAME              Action internal name
    * @param   IO_PARAM                   Workflows general parameter (for function evaluation)   
    * @param   i_flg_auto_transition      Indicates whether we want automatic transitions.    
    *                                           {*} Y - automatic transitions returned
    *                                           {*} N - non-autiomatic transitions returned
    *                                           {*} <null>  - all transitions returned (automatic or not)   
    * @param   O_FLG_STATUS               Next referral status
    * @param   O_ERROR                    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-10-2010
    */
    FUNCTION get_next_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_data           IN t_rec_prof_data,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_action_name         IN wf_workflow_action.internal_name%TYPE,
        i_flg_auto_transition IN VARCHAR2,
        io_param              IN OUT NOCOPY table_varchar,
        o_flg_status          OUT p1_external_request.flg_status%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        -- wf
        l_flg_status_n    wf_status.id_status%TYPE;
        l_tab_transitions t_coll_wf_transition;
    
        l_id_workflow_action wf_workflow_action.id_workflow_action%TYPE;
        l_id_workflow        p1_external_request.id_workflow%TYPE;
    BEGIN
        g_error := 'Init get_next_status / WF=' || i_id_workflow || ' FLG_STATUS=' || i_flg_status || ' ACTION=' ||
                   i_action_name || ' IO_PARAM=' || pk_utils.to_string(io_param);
        pk_alertlog.log_debug(g_error);
    
        reset_vars;
    
        g_error        := 'Call convert_status_n / FLG_STATUS=' || i_flg_status;
        l_flg_status_n := convert_status_n(i_flg_status);
        l_id_workflow  := nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp);
    
        g_error              := 'pk_ref_constant.get_action_id / ACTION_NAME=' || i_action_name;
        l_id_workflow_action := pk_ref_constant.get_action_id(i_action_name);
    
        -- getting available transitions
        g_error  := 'Calling PK_WORKFLOW.get_transitions / WF=' || l_id_workflow || ' BEG=' || l_flg_status_n ||
                    ' ACTION=' || l_id_workflow_action || ' CAT=' || i_prof_data.id_category || ' PROFILE=' ||
                    i_prof_data.id_profile_template || ' FUNC=' || i_prof_data.id_functionality || ' PARAM=' ||
                    pk_utils.to_string(io_param) || ' AUTO=' || i_flg_auto_transition;
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_id_workflow,
                                                i_id_status_begin     => l_flg_status_n,
                                                i_id_workflow_action  => l_id_workflow_action,
                                                i_id_category         => i_prof_data.id_category,
                                                i_id_profile_template => i_prof_data.id_profile_template,
                                                i_id_functionality    => i_prof_data.id_functionality,
                                                i_param               => io_param,
                                                i_flg_auto_transition => i_flg_auto_transition,
                                                o_transitions         => l_tab_transitions,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        BEGIN
            SELECT convert_status_v(t.id_status_end)
              INTO o_flg_status
              FROM TABLE(CAST(l_tab_transitions AS t_coll_wf_transition)) t;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_status := NULL;
            WHEN too_many_rows THEN
                o_flg_status := NULL; -- there is more than one status_end available
        END;
    
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
                                              i_function    => 'GET_NEXT_STATUS',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END get_next_status;

    /**
    * Returns next available action to be processed.
    * Only possible when there is only one action availabe for processing.
    * Used to process automatic transitions
    *
    * @param   I_LANG                     Language associated to the professional executing the request
    * @param   I_PROF                     Professional, institution and software ids
    * @param   I_PROF_DATA                Professional info: profile template, category and functionality
    * @param   I_ID_WORKFLOW              Workflow identifier
    * @param   i_flg_status               Current referral status
    * @param   IO_PARAM                   Workflows general parameter (for function evaluation)      
    * @param   O_ACTION_NAME              Action internal name
    * @param   O_FLG_STATUS               Referral end status
    * @param   O_ERROR                    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-10-2010
    */
    FUNCTION get_next_action
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_flg_status  IN p1_external_request.flg_status%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_action_name OUT wf_workflow_action.internal_name%TYPE,
        o_flg_status  OUT p1_external_request.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        -- wf
        l_tab_transitions t_coll_wf_transition;
        l_id_workflow     p1_external_request.id_workflow%TYPE;
        l_status_n        wf_status.id_status%TYPE;
        l_id_prev_action  wf_workflow_action.id_workflow_action%TYPE;
    BEGIN
        g_error := 'Init get_next_action / WF=' || i_id_workflow || ' FLG_STATUS=' || i_flg_status || ' IO_PARAM=' ||
                   pk_utils.to_string(io_param);
        --pk_alertlog.log_debug(g_error);
    
        reset_vars;
    
        l_id_workflow    := nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp);
        l_status_n       := convert_status_n(i_flg_status);
        l_id_prev_action := io_param(pk_ref_constant.g_idx_id_action);
    
        -- getting available transitions
        g_error  := 'Calling PK_WORKFLOW.GET_TRANSITIONS / WF=' || l_id_workflow || ' BEG=' || l_status_n || ' CAT=' ||
                    i_prof_data.id_category || ' PRF=' || i_prof_data.id_profile_template || ' FUNC=' ||
                    i_prof_data.id_functionality || ' PARAM=' || pk_utils.to_string(io_param) || ' AUTO=Y';
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_id_workflow,
                                                i_id_status_begin     => l_status_n,
                                                i_id_category         => i_prof_data.id_category,
                                                i_id_profile_template => i_prof_data.id_profile_template,
                                                i_id_functionality    => i_prof_data.id_functionality,
                                                i_param               => io_param,
                                                i_flg_auto_transition => pk_ref_constant.g_yes,
                                                o_transitions         => l_tab_transitions,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_tab_transitions.count > 0
        THEN
            g_error := 'l_id_prev_action=' || l_id_prev_action;
            BEGIN
                IF l_id_prev_action IS NULL
                THEN
                    -- do not consider table ref_auto_transitions because is the first transition in this status change
                    SELECT pk_ref_constant.get_action_name(t.id_workflow_action), convert_status_v(t.id_status_end)
                      INTO o_action_name, o_flg_status
                      FROM TABLE(CAST(l_tab_transitions AS t_coll_wf_transition)) t
                     WHERE t.id_workflow = l_id_workflow
                       AND t.id_status_begin = l_status_n;
                ELSE
                    -- do consider table ref_auto_transitions because is the first transition in this status change
                    SELECT pk_ref_constant.get_action_name(t.id_workflow_action), convert_status_v(t.id_status_end)
                      INTO o_action_name, o_flg_status
                      FROM TABLE(CAST(l_tab_transitions AS t_coll_wf_transition)) t
                      JOIN ref_auto_transitions r
                        ON (r.id_workflow = t.id_workflow AND r.id_status_begin = t.id_status_begin AND
                           r.id_status_end = t.id_status_end AND r.id_workflow_action = t.id_workflow_action)
                     WHERE t.id_workflow = l_id_workflow
                       AND t.id_status_begin = l_status_n
                       AND r.id_workflow_action_prev = l_id_prev_action; -- automatic only for this previous action
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_action_name := NULL;
                    o_flg_status  := NULL;
                WHEN OTHERS THEN
                    IF SQLCODE = -1422
                    THEN
                        -- exact fetch returns more than requested number of rows
                        -- there is more than one action_name available
                        g_error      := 'WF=' || l_id_workflow || ' BEGIN=' || l_status_n || ' CAT=' ||
                                        i_prof_data.id_category || ' PPT=' || i_prof_data.id_profile_template ||
                                        ' FUNC=' || i_prof_data.id_functionality || ' PREV_ID_ACTION=' ||
                                        l_id_prev_action || ' IO_PARAM=' || pk_utils.to_string(io_param);
                        g_error_code := pk_ref_constant.g_ref_error_1008;
                        g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                        RAISE g_exception;
                    END IF;
            END;
        ELSE
            -- there are no transitions available
            o_action_name := NULL;
            o_flg_status  := NULL;
        END IF;
    
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
                                              i_function    => 'GET_NEXT_ACTION',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END get_next_action;

    /**
    * Validates if tracking date is correct.
    * Cannot register a status change date lower than the last status change date.
    * Cannot register a referral update date lower than MAX(last update, last status change, last transf resp) date
    * Cannot register a referral transf resp date lower than MAX(last update, last status change, last transf resp) date
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_flg_type           Tracking type
    * @param   io_dt_tracking_date  Tracking date to be validated
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'S' Status change, {*} 'C' Forward to another clinical service, {*} 'P' Forward to triage
    *                               {*} 'R' Read by professional, {*} 'T' Hand off, {*} 'U' Data update
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION validate_tracking_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_ref            IN p1_external_request.id_external_request%TYPE,
        i_flg_type          IN p1_tracking.flg_type%TYPE,
        io_dt_tracking_date IN OUT p1_tracking.dt_tracking_tstz%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_last_status     p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_last_status_upd p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_last_status_tr  p1_tracking.dt_tracking_tstz%TYPE;
        l_check_date         VARCHAR2(1 CHAR);
        l_idx                PLS_INTEGER;
        l_idx_u              PLS_INTEGER;
        l_idx_t              PLS_INTEGER;
    
        CURSOR c_tracking IS
            SELECT dt_tracking_tstz, flg_type
              FROM p1_tracking
             WHERE id_external_request = i_id_ref
               AND flg_type != pk_ref_constant.g_tracking_type_r
             ORDER BY dt_tracking_tstz;
    
        TYPE t_tracking IS TABLE OF c_tracking%ROWTYPE;
        l_tracking_tab t_tracking;
    BEGIN
        g_error := 'Init validate_tracking_date / ID_REF=' || i_id_ref || ' FLG_TYPE=' || i_flg_type;
        l_idx   := 0;
    
        IF i_flg_type != pk_ref_constant.g_tracking_type_r -- this type doesn't matter
        THEN
        
            -----------------------------
            -- getting last referral date to compare
            OPEN c_tracking;
            FETCH c_tracking BULK COLLECT
                INTO l_tracking_tab;
            CLOSE c_tracking;
        
            FOR i IN 1 .. l_tracking_tab.count
            LOOP
            
                -- array is sorted by date asc
                IF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_u
                THEN
                    l_dt_last_status_upd := l_tracking_tab(i).dt_tracking_tstz;
                    l_idx_u              := i;
                ELSIF l_tracking_tab(i).flg_type = pk_ref_constant.g_tracking_type_t
                THEN
                    l_dt_last_status_tr := l_tracking_tab(i).dt_tracking_tstz;
                    l_idx_t             := i;
                ELSE
                    l_dt_last_status := l_tracking_tab(i).dt_tracking_tstz;
                    l_idx            := i;
                END IF;
            END LOOP;
        
            -- l_dt_last_status_upd has thas last referral update date
            -- l_dt_last_status_tr has thas last referral transf resp date
            -- l_dt_last_status has thas last referral status change date
        
            g_error := 'ID_REF=' || i_id_ref || ' FLG_TYPE=' || i_flg_type;
            IF i_flg_type IN (pk_ref_constant.g_tracking_type_u, pk_ref_constant.g_tracking_type_t)
            THEN
            
                -----------------------------
                -- check if last update status is greater than last status change (in case of a referral update only)
                IF l_dt_last_status IS NOT NULL
                   AND l_dt_last_status_upd IS NOT NULL
                THEN
                    l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                    i_date1 => l_dt_last_status_upd,
                                                                    i_date2 => l_dt_last_status);
                
                    IF l_check_date = pk_ref_constant.g_date_greater
                    THEN
                    
                        -- consider l_dt_last_status_upd instead of l_dt_last_status, for referral update purposes only
                        g_error          := 'ID_REF=' || i_id_ref || ' last status update considered';
                        l_dt_last_status := l_dt_last_status_upd;
                        l_idx            := l_idx_u;
                    END IF;
                END IF;
            
                -----------------------------
                -- check if last update status is greater than last status transf resp
                IF l_dt_last_status IS NOT NULL
                   AND l_dt_last_status_tr IS NOT NULL
                THEN
                    l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                    i_date1 => l_dt_last_status_tr,
                                                                    i_date2 => l_dt_last_status);
                
                    IF l_check_date = pk_ref_constant.g_date_greater
                    THEN
                    
                        -- consider l_dt_last_status_tr instead of l_dt_last_status, for referral transf resp purposes only
                        g_error          := 'ID_REF=' || i_id_ref || ' last status transf resp considered';
                        l_dt_last_status := l_dt_last_status_tr;
                        l_idx            := l_idx_t;
                    END IF;
                END IF;
            END IF;
        
            -- log
            g_error := g_error || ' LAST DT_TRACKING_TSTZ=' ||
                       pk_date_utils.to_char_insttimezone(i_prof, l_dt_last_status, pk_ref_constant.g_format_date) ||
                       ' NEW DT_TRACKING=' ||
                       pk_date_utils.to_char_insttimezone(i_prof, io_dt_tracking_date, pk_ref_constant.g_format_date);
        
            -----------------------------
            -- comparing dates
            IF io_dt_tracking_date IS NOT NULL
               AND l_dt_last_status IS NOT NULL
            THEN
                l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                i_date1 => io_dt_tracking_date,
                                                                i_date2 => l_dt_last_status);
            
                g_error := 'l_check_date=' || l_check_date;
                IF l_check_date = pk_ref_constant.g_date_lower
                THEN
                
                    g_error      := 'NEW tracking date= ' ||
                                    pk_date_utils.to_char_insttimezone(i_prof,
                                                                       io_dt_tracking_date,
                                                                       pk_ref_constant.g_format_date) ||
                                    ' LAST tracking date=' ||
                                    pk_date_utils.to_char_insttimezone(i_prof,
                                                                       l_dt_last_status,
                                                                       pk_ref_constant.g_format_date) || ' TRACK_TYPE=' ||
                                    i_flg_type || ' ID_REF=' || i_id_ref;
                    g_error_code := pk_ref_constant.g_ref_error_1011;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                ELSIF l_check_date = pk_ref_constant.g_date_equal
                THEN
                
                    -- prevent from setting P1_TRACKING.DT_TRACKING_TSTZ equal to the last dt_tracking_tstz
                    g_error             := 'EQUAL';
                    io_dt_tracking_date := io_dt_tracking_date + INTERVAL '1' SECOND;
                END IF;
            END IF;
        
            -----------------------------
            -- io_dt_tracking_date
            -- comparing dates in l_tracking_tab from the position l_idx (this prevents inserting the same date)
            g_error := 'for i in ' || (l_idx + 1) || '..' || l_tracking_tab.count || ' loop';
            FOR i IN (l_idx + 1) .. l_tracking_tab.count
            LOOP
            
                IF l_tracking_tab(i).dt_tracking_tstz IS NOT NULL
                    AND io_dt_tracking_date IS NOT NULL
                THEN
                    l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                    i_date1 => io_dt_tracking_date,
                                                                    i_date2 => l_tracking_tab(i).dt_tracking_tstz);
                
                    IF l_check_date = pk_ref_constant.g_date_equal
                    THEN
                    
                        g_error             := 'Adding one second to ' ||
                                               pk_date_utils.to_char_insttimezone(i_prof,
                                                                                  io_dt_tracking_date,
                                                                                  pk_ref_constant.g_format_date);
                        io_dt_tracking_date := io_dt_tracking_date + INTERVAL '1' SECOND;
                        -- continues to the next round, to see if needs to add one more second
                    
                    ELSIF l_check_date = pk_ref_constant.g_date_greater
                    THEN
                        -- this is the correct date, exit loop
                        EXIT;
                    ELSIF l_check_date = pk_ref_constant.g_date_lower
                    THEN
                        -- this only can happen when we are doing a status change, and the current
                        -- date (l_tracking_tab(i).dt_tracking_tstz) refers to an update or a transf resp
                    
                        IF l_tracking_tab(i)
                         .flg_type IN (pk_ref_constant.g_tracking_type_u, pk_ref_constant.g_tracking_type_t)
                            AND i_flg_type = pk_ref_constant.g_tracking_type_s
                        THEN
                            EXIT;
                        ELSE
                        
                            g_error      := 'Error, date is lower... ID_REF=' || i_id_ref || ' l_idx=' || l_idx ||
                                            ' i=' || i || ' l_tracking_tab.COUNT=' || l_tracking_tab.count ||
                                            ' l_check_date=' || l_check_date || ' new_dt_track=' ||
                                            pk_date_utils.to_char_insttimezone(i_prof,
                                                                               io_dt_tracking_date,
                                                                               pk_ref_constant.g_format_date) ||
                                            ' current_dt_track=' ||
                                            pk_date_utils.to_char_insttimezone(i_prof,
                                                                               l_tracking_tab(i).dt_tracking_tstz,
                                                                               pk_ref_constant.g_format_date);
                            g_error_code := pk_ref_constant.g_ref_error_1011;
                            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang         => i_lang,
                                                                           i_id_ref_error => g_error_code);
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
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
                                              i_function    => 'VALIDATE_TRACKING_DATE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END validate_tracking_date;

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          language associated to the professional executing the request
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change. 
    * @param i_dt_requested  Referral date requested (if not null)
    * @param io_param        Array used in framework workflows    
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
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_track_row    IN p1_tracking%ROWTYPE,
        i_dt_requested IN p1_external_request.dt_requested%TYPE DEFAULT NULL,
        io_param       IN OUT NOCOPY table_varchar,
        o_track        OUT table_number,
        o_error        OUT t_error_out
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
    
        CURSOR c_track IS
            SELECT t.dt_tracking_tstz
              FROM p1_tracking t
             WHERE t.id_external_request = i_track_row.id_external_request
             ORDER BY t.dt_tracking_tstz DESC, t.id_tracking DESC;
    
        l_check_date       VARCHAR2(1 CHAR);
        l_id_speciality    p1_tracking.id_speciality%TYPE;
        l_dt_create        p1_tracking.dt_create%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    
        l_ref_context t_rec_ref_context;
        l_params      VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) ||
                    pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_tracking_row => i_track_row);
        g_error  := 'Init update_status / ' || l_params;
    
        l_ref_context := pk_ref_utils.get_ref_context;
        l_read_count  := 0;
        l_dt_create   := coalesce(l_ref_context.dt_system_date, i_track_row.dt_create, current_timestamp);
        o_track       := table_number();
    
        ----------------------
        -- FUNC
        ----------------------            
        -- js, 2008-04-02: for update - avoid duplicadted records in p1_tracking.
        g_error := 'SELECT P1_EXTERNAL_REQUEST / ' || l_params;
        SELECT *
          INTO l_ref_row
          FROM p1_external_request
         WHERE id_external_request = i_track_row.id_external_request
           FOR UPDATE;
    
        l_params := l_params || ' REF_ROW= ID_PAT=' || l_ref_row.id_patient || ' ID_DCS=' || l_ref_row.id_dep_clin_serv ||
                    ' FLG_STATUS=' || l_ref_row.flg_status || ' ID_INST_DEST=' || l_ref_row.id_inst_dest ||
                    ' ID_INST_ORIG=' || l_ref_row.id_inst_orig || ' ID_SPECIALITY=' || l_ref_row.id_speciality ||
                    ' ID_WORKFLOW=' || l_ref_row.id_workflow;
    
        -- does not check for transition availability, it was done before
        g_error                      := 'l_track_row / ' || l_params;
        l_track_row                  := i_track_row;
        l_track_row.id_professional  := i_prof.id;
        l_track_row.id_institution   := i_prof.institution;
        l_track_row.dt_tracking_tstz := nvl(i_track_row.dt_tracking_tstz, l_dt_create);
        l_track_row.dt_create        := l_dt_create;
    
        -- checking tracking date and returns the correct date
        g_error  := 'Call validate_tracking_date / ' || l_params;
        g_retval := validate_tracking_date(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_ref            => l_track_row.id_external_request,
                                           i_flg_type          => l_track_row.flg_type,
                                           io_dt_tracking_date => l_track_row.dt_tracking_tstz,
                                           o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- avoid inserting two records with the same dt_tracking_tstz
        g_error := 'OPEN c_track / ' || l_params;
        OPEN c_track;
        FETCH c_track
            INTO l_dt_tracking_tstz;
        CLOSE c_track;
    
        IF l_track_row.dt_tracking_tstz IS NOT NULL
           AND l_dt_tracking_tstz IS NOT NULL
        THEN
            g_error      := 'Call pk_date_utils.compare_dates_tsz / ' || l_params;
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => l_track_row.dt_tracking_tstz,
                                                            i_date2 => l_dt_tracking_tstz);
        
            g_error := 'DT_TRACKING / l_check_date=' || l_check_date || ' / ' || l_params;
            IF l_check_date = pk_ref_constant.g_date_equal
            THEN
                l_track_row.dt_tracking_tstz := l_track_row.dt_tracking_tstz + INTERVAL '1' SECOND;
                l_track_row.dt_create        := l_dt_create; -- + INTERVAL '1' SECOND;
            
            END IF;
        END IF;
    
        -- getting round id
        g_error  := 'Call get_round / ' || l_params;
        g_retval := get_round(i_lang            => i_lang,
                              i_prof            => i_prof,
                              i_flg_status_prev => l_ref_row.flg_status, -- previous flg_status (before this update)
                              i_track_row       => l_track_row,
                              o_round_id        => l_track_row.round_id,
                              o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ROUND_ID=' || l_track_row.round_id;
    
        -- If the type is "Status change" or "Send to triage physician" then changes request status
        -- ALERT-21468: added g_tracking_type_c
        g_error := 'FLG_TYPE / ' || l_params;
        IF instr(pk_ref_constant.g_tracking_type_s || pk_ref_constant.g_tracking_type_p ||
                 pk_ref_constant.g_tracking_type_c,
                 i_track_row.flg_type) > 0
        THEN
            l_ref_row.flg_status               := l_track_row.ext_req_status;
            l_ref_row.id_prof_status           := l_track_row.id_professional;
            l_ref_row.dt_status_tstz           := l_track_row.dt_tracking_tstz;
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
            io_param(pk_ref_constant.g_idx_id_prof_status) := l_ref_row.id_prof_status;
        
            IF i_dt_requested IS NOT NULL
            THEN
                l_ref_row.dt_requested := i_dt_requested;
            END IF;
        
            -- records the priority set by the triage professional decision_urg_level           
            g_error := 'l_track_row.decision_urg_level / ' || l_params;
            IF l_track_row.decision_urg_level IS NOT NULL
            THEN
                l_ref_row.decision_urg_level := l_track_row.decision_urg_level;
                io_param(pk_ref_constant.g_idx_decision_urg_level) := l_ref_row.decision_urg_level;
            END IF;
        
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
                    g_error := 'id_prof_redirected=' || l_prof_dest || ' / ' || l_params;
                    l_ref_row.id_prof_redirected := l_prof_dest;
                    io_param(pk_ref_constant.g_idx_id_prof_redirected) := l_ref_row.id_prof_redirected;
                END IF;
            
                l_track_row.id_prof_dest := l_prof_dest;
            
            END IF;
        
            g_error := 'l_track_row.id_schedule / ' || l_params;
            IF l_track_row.id_schedule IS NOT NULL
            THEN
                l_ref_row.id_schedule := l_track_row.id_schedule;
            END IF;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_u
        THEN
            -- If it's data update then updates dt_last_interaction
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_t
        THEN
            -- transf resp
            g_error := 'Transf resp / ' || l_params;
            IF l_track_row.id_prof_dest IS NOT NULL
            THEN
                l_ref_row.id_prof_requested := l_track_row.id_prof_dest;
            ELSE
                g_error := 'Transf resp: Dest professional must be defined / ' || l_params;
                RAISE g_exception;
            END IF;
        
            l_ref_row.dt_last_interaction_tstz := l_track_row.dt_tracking_tstz;
        
            -- change origin institution
            g_error := 'id_inst_orig / ' || l_params;
            IF l_track_row.id_inst_orig != l_ref_row.id_inst_orig
            THEN
                l_ref_row.id_inst_orig := l_track_row.id_inst_orig;
            END IF;
        
            -- change id_workflow
            g_error := 'id_workflow / ' || l_params;
            IF l_track_row.id_workflow != l_ref_row.id_workflow
            THEN
                l_ref_row.id_workflow := l_track_row.id_workflow;
            END IF;
        
        ELSIF i_track_row.flg_type = pk_ref_constant.g_tracking_type_r
        THEN
        
            -- If there's a "read" record for this user/round/status don't reord again
            g_error := 'OPEN c_read / ' || l_params;
            OPEN c_read(l_track_row.round_id);
        
            g_error := 'FETCH c_read / ' || l_params;
            FETCH c_read
                INTO l_read_count;
        
            g_error := 'CLOSE c_read / ' || l_params;
            CLOSE c_read;
        
            IF l_read_count != 0
            THEN
                -- do not record again            
                g_error := 'Do not record ID_REF=' || l_track_row.id_external_request || ' / ' || l_params;
                RETURN TRUE;
            
            END IF;
        
        END IF;
    
        -- js, 2008-04-14: Centralizes id_dep_clin_serv updates
        g_error := 'id_dep_clin_serv / ' || l_params;
        IF l_track_row.id_dep_clin_serv IS NOT NULL
        THEN
            l_ref_row.id_dep_clin_serv := l_track_row.id_dep_clin_serv;
            io_param(pk_ref_constant.g_idx_id_dcs) := l_ref_row.id_dep_clin_serv;
        
            -- IF updating id_dep_clin_serv, update also id_speciality (if internal referral)
            --IF l_ref_row.id_workflow = pk_ref_constant.g_wf_srv_srv
            --THEN
            l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_ref_row.id_workflow,
                                                                     i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                     i_id_inst_dest => l_ref_row.id_inst_dest);
        
            g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ' || l_params;
            g_retval := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_id_dep_clin_serv => l_track_row.id_dep_clin_serv,
                                                                         i_id_patient       => l_ref_row.id_patient,
                                                                         i_id_external_sys  => l_ref_row.id_external_sys,
                                                                         i_flg_availability => l_flg_availability,
                                                                         o_id_speciality    => l_id_speciality,
                                                                         o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
            --END IF;
        
            l_ref_row.id_speciality := l_id_speciality;
            io_param(pk_ref_constant.g_idx_id_speciality) := l_ref_row.id_speciality;
        
        END IF;
    
        -- updating P1_EXTERNAL_REQUEST
        IF i_track_row.flg_type != pk_ref_constant.g_tracking_type_r
        THEN
            l_rowids := NULL;
            g_error  := 'Call ts_p1_external_request.upd / ' || l_params;
            ts_p1_external_request.upd(rec_in => l_ref_row, handle_error_in => TRUE, rows_out => l_rowids);
        
            -- js, 2008-12-04: processe changes to the record
            g_error := 'Call t_data_gov_mnt.process_update / ' || l_params;
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_EXTERNAL_REQUEST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        -- INSERT P1_TRACKING
        g_error                   := 'ts_p1_tracking.next_key / ' || l_params;
        l_track_row.id_tracking   := ts_p1_tracking.next_key();
        l_track_row.id_speciality := nvl(l_id_speciality, i_track_row.id_speciality);
    
        l_rowids := NULL;
        g_error  := 'INSERT P1_TRACKING / ' || l_params;
        ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        g_error := 'process_insert P1_TRACKING / ' || l_params;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_track.extend();
        o_track(o_track.last) := l_track_row.id_tracking;
    
        io_param(pk_ref_constant.g_idx_flg_status) := l_ref_row.flg_status;
    
        -- Create sys_alert_events (with status validation) only if is a status change.
        -- Remove old sys_alert_events (with status validation) before create new one
        IF l_track_row.flg_type = pk_ref_constant.g_tracking_type_s
           AND l_ref_row.flg_status IN (pk_ref_constant.g_p1_status_x,
                                        pk_ref_constant.g_p1_status_d,
                                        pk_ref_constant.g_p1_status_y,
                                        pk_ref_constant.g_p1_status_h,
                                        pk_ref_constant.g_p1_status_b)
        THEN
            g_error  := 'call pk_ref_core_internal.set_referral_alerts / ' || l_params;
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
                                              i_function => 'UPDATE_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_status;

    /**
    * Registering referral reading
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_EXT_ROW        Referral info 
    * @param   I_DATE           Read date
    * @param   io_param         Array used in framework workflows
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_read
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param    IN OUT NOCOPY table_varchar,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row p1_tracking%ROWTYPE;
        l_dt_create p1_tracking.dt_create%TYPE;
    BEGIN
        g_error     := 'Init set_ref_read / ID_REF=' || i_ref_row.id_external_request || ' ID_PROFESSIONAL=' ||
                       i_prof.id;
        l_dt_create := pk_ref_utils.get_sysdate;
        o_track     := table_number();
    
        l_track_row.ext_req_status      := i_ref_row.flg_status;
        l_track_row.id_external_request := i_ref_row.id_external_request;
        l_track_row.id_institution      := i_prof.institution;
        l_track_row.id_professional     := i_prof.id;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_r;
        l_track_row.dt_tracking_tstz    := nvl(i_date, l_dt_create);
        l_track_row.dt_create           := l_dt_create;
    
        g_error  := 'Calling update_status';
        g_retval := update_status(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_track_row => l_track_row,
                                  io_param    => io_param,
                                  o_track     => o_track,
                                  o_error     => o_error);
    
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
                                              i_function => 'SET_REF_READ',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_read;

    /**
    * Calculates round_id 
    *
    * @param   i_lang              Language associated to the professional 
    * @param   i_prof              Professional, institution and software ids
    * @param   i_flg_status_prev   Previous referral flag status    
    * @param   i_track_row         P1_TRACKING row info
    * @param   o_round_id          The resulting round id
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION get_round
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status_prev IN p1_external_request.flg_status%TYPE,
        i_track_row       IN p1_tracking%ROWTYPE,
        o_round_id        OUT p1_tracking.round_id%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_round p1_tracking.round_id%TYPE;
    BEGIN
    
        -- p1_tracking.round_id changes value everytime:
        --    - the status changes to (N)ew
        --    - the status is (I)ssued and is returned by the registar (changes to status B)  
        g_error := 'Init get_round / ID_REF=' || i_track_row.id_external_request || ' FLG_STATUS=' || i_flg_status_prev ||
                   ' ID_TRACKING=' || i_track_row.id_tracking;
        --pk_alertlog.log_debug(g_error);
    
        SELECT MAX(t.round_id)
          INTO l_round
          FROM p1_tracking t
         WHERE t.id_external_request = i_track_row.id_external_request;
    
        IF i_track_row.flg_type = pk_ref_constant.g_tracking_type_s
        THEN
            IF i_track_row.ext_req_status = pk_ref_constant.g_p1_status_n
            THEN
                l_round := NULL; --- Force new value
            ELSIF i_track_row.ext_req_status = pk_ref_constant.g_p1_status_i
            THEN
                IF i_flg_status_prev = pk_ref_constant.g_p1_status_b
                THEN
                    l_round := NULL;
                END IF;
            END IF;
        END IF;
    
        g_error := 'ROUND_ID=' || l_round;
        IF l_round IS NULL
        THEN
            SELECT seq_p1_exr_track_round.nextval
              INTO o_round_id
              FROM dual;
        ELSE
            o_round_id := l_round;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ROUND',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_round;

    ------------------------------------------------------------
    -- Workflow functions   
    -----------------------------------------------------------

    /**
    * Gets parameter values of framework workflow into separate variables
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_param              Referral information
    * @param   o_id_ref             Referral identifier
    * @param   o_id_patient         Patient identifier
    * @param   o_id_inst_orig       Referral origin institution
    * @param   o_id_inst_dest       Referral destination institution
    * @param   o_id_dcs             Referral dep_clin_serv
    * @param   o_id_speciality      Referral speciality
    * @param   o_flg_type           Referral type
    * @param   o_dec_urg_level      Triage urgency level
    * @param   o_id_prof_requested  Professional that requested the referral
    * @param   o_id_prof_redirected Professional to whom the referral was forwarded to
    * @param   o_id_prof_status     Professional that changed referral status
    * @param   o_id_external_sys    Referral external system where the referral was created
    * @param   o_location           Referral location
    * @param   o_flg_completed      Flag indicating if referral has been completed
    * @param   o_id_action          Previous workflow action identifier (in this status change)
    * @param   o_flg_prof_dcs       Flag indicating if professional is related to this id_dep_clin_serv (used for the registrar)
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    * @value   o_location           {*} 'G' - grid {*} 'D' - detail
    * @value   o_completed          {*} 'Y' - referral completed {*} 'N' - otherwise
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_param_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_param              IN table_varchar,
        o_id_ref             OUT p1_external_request.id_external_request%TYPE,
        o_id_patient         OUT p1_external_request.id_patient%TYPE,
        o_id_inst_orig       OUT p1_external_request.id_inst_orig%TYPE,
        o_id_inst_dest       OUT p1_external_request.id_inst_dest%TYPE,
        o_id_dcs             OUT p1_external_request.id_dep_clin_serv%TYPE,
        o_id_speciality      OUT p1_external_request.id_speciality%TYPE,
        o_flg_type           OUT p1_external_request.flg_type%TYPE,
        o_dec_urg_level      OUT p1_external_request.decision_urg_level%TYPE,
        o_id_prof_requested  OUT p1_external_request.id_prof_requested%TYPE,
        o_id_prof_redirected OUT p1_external_request.id_prof_redirected%TYPE,
        o_id_prof_status     OUT p1_external_request.id_prof_status%TYPE,
        o_id_external_sys    OUT p1_external_request.id_external_sys%TYPE,
        o_location           OUT VARCHAR2,
        o_flg_completed      OUT VARCHAR2,
        o_id_action          OUT wf_workflow_action.id_workflow_action%TYPE,
        o_flg_prof_dcs       OUT VARCHAR2,
        o_prof_clin_dir      OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_param_values / i_param=' || pk_utils.to_string(i_param);
    
        -- getting values from i_param
        IF i_param.exists(pk_ref_constant.g_idx_id_ref)
        THEN
            -- id_external_request
            o_id_ref := to_number(i_param(pk_ref_constant.g_idx_id_ref));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_patient)
        THEN
            -- id_patient
            o_id_patient := to_number(i_param(pk_ref_constant.g_idx_id_patient));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_inst_orig)
        THEN
            -- id_inst_orig
            o_id_inst_orig := to_number(i_param(pk_ref_constant.g_idx_id_inst_orig));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_inst_dest)
        THEN
            -- id_inst_dest
            o_id_inst_dest := to_number(i_param(pk_ref_constant.g_idx_id_inst_dest));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_dcs)
        THEN
            -- id_dep_clin_serv
            o_id_dcs := to_number(i_param(pk_ref_constant.g_idx_id_dcs));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_speciality)
        THEN
            -- id_speciality
            o_id_speciality := to_number(i_param(pk_ref_constant.g_idx_id_speciality));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_flg_type)
        THEN
            -- flg_type
            o_flg_type := i_param(pk_ref_constant.g_idx_flg_type);
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_decision_urg_level)
        THEN
            -- decision_urg_level
            o_dec_urg_level := to_number(i_param(pk_ref_constant.g_idx_decision_urg_level));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_prof_requested)
        THEN
            -- id_prof_requested
            o_id_prof_requested := to_number(i_param(pk_ref_constant.g_idx_id_prof_requested));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_prof_redirected)
        THEN
            -- id_prof_redirected
            o_id_prof_redirected := to_number(i_param(pk_ref_constant.g_idx_id_prof_redirected));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_prof_status)
        THEN
            -- id_prof_status
            o_id_prof_status := to_number(i_param(pk_ref_constant.g_idx_id_prof_status));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_external_sys)
        THEN
            -- id_external_sys
            o_id_external_sys := to_number(i_param(pk_ref_constant.g_idx_external_sys));
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_location)
        THEN
            -- location
            o_location := i_param(pk_ref_constant.g_idx_location);
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_completed)
        THEN
            -- flg_completed
            o_flg_completed := i_param(pk_ref_constant.g_idx_completed);
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_id_action)
        THEN
            -- o_id_action
            o_id_action := i_param(pk_ref_constant.g_idx_id_action);
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_flg_prof_dcs)
        THEN
            -- is this professional related to this id_dep_clin_serv? (used for the registrar)
            o_flg_prof_dcs := i_param(pk_ref_constant.g_idx_flg_prof_dcs);
        END IF;
    
        IF i_param.exists(pk_ref_constant.g_idx_prof_clin_dir)
        THEN
            -- is this professional clinical director? (this is just because of easy access calculation)
            o_prof_clin_dir := i_param(pk_ref_constant.g_idx_prof_clin_dir);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PARAM_VALUES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_param_values;

    /**
    * Gets transition configuration depending on software, institution, category, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_wf_transition
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error          t_error_out;
        l_priv_inst      VARCHAR2(1 CHAR);
        l_prev_track_row p1_tracking%ROWTYPE;
        l_config         sys_config.value%TYPE;
        l_status_begin_v p1_external_request.flg_status%TYPE;
        l_status_end_v   p1_external_request.flg_status%TYPE;
        l_prof_sch       professional.id_professional%TYPE;
        l_prof_sch_no    professional.num_order%TYPE;
        l_prof_func      sys_functionality.id_functionality%TYPE;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' WF=' || i_workflow || ' BEG=' || i_status_begin ||
                    ' END=' || i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' ||
                    i_profile || ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_error  := 'Init get_wf_transition / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- converting status to varchar
        g_error          := 'Calling convert_status_v / ' || l_params;
        l_status_begin_v := convert_status_v(i_status => i_status_begin);
        l_status_end_v   := convert_status_v(i_status => i_status_end);
    
        g_error  := 'Call get_param_values / ' || l_params;
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        l_params := l_params || ' ID_REF=' || l_id_ref;
        g_error  := l_params;
    
        CASE
            WHEN l_status_end_v = pk_ref_constant.g_p1_status_o THEN
            
                ---------------------------
                -- Begin created
                ---------------------------
                g_error := 'FLG_COMPLETED=' || l_flg_completed || ' / ' || l_params;
                IF l_flg_completed = pk_ref_constant.g_no
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            
            WHEN l_status_end_v = pk_ref_constant.g_p1_status_n
                 AND (i_status_begin = pk_ref_constant.g_p1_status_initial OR
                 l_status_begin_v = pk_ref_constant.g_p1_status_o) THEN
                -- todo: mudar
            
                ---------------------------
                -- (N)ew
                ---------------------------             
                g_error := 'FLG_COMPLETED=' || l_flg_completed || ' / ' || l_params;
                IF l_flg_completed = pk_ref_constant.g_yes
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            
            WHEN l_status_begin_v = pk_ref_constant.g_p1_status_l THEN
            
                ---------------------------
                -- from B(L)ocked to any status
                ---------------------------
            
                -- check if referral previous status = l_status_end_v
                -- getting previous referral status
                g_error  := 'Call pk_ref_utils.get_prev_status_data / ' || l_params;
                g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                              i_prof   => i_prof,
                                                              i_id_ref => l_id_ref,
                                                              o_data   => l_prev_track_row,
                                                              o_error  => l_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF l_prev_track_row.ext_req_status = l_status_end_v
                THEN
                    RETURN pk_ref_constant.g_transition_deny;
                END IF;
            
            WHEN l_status_end_v = pk_ref_constant.g_p1_status_a
                 AND l_status_begin_v = pk_ref_constant.g_p1_status_s THEN
            
                ---------------------------
                -- From (S)Schedule   To  (A)ccepted
                ---------------------------
                IF i_prof.institution = l_id_inst_dest
                   AND pk_prof_utils.get_prof_profile_template(i_prof => i_prof) = pk_ref_constant.g_profile_adm_hs_cl
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                ELSE
                    RETURN pk_ref_constant.g_transition_deny;
                END IF;
            
            WHEN l_status_begin_v IN (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_y) THEN
            
                ---------------------------
                -- From Declined to...
                ---------------------------               
                -- D->I: pk_ref_constant.g_wf_x_hosp has no function
            
                -- (C)anceled or (N)ew (all WFs) or (I)ssued (WF=4)
                g_error := 'ID_PROF_REQUESTED=' || l_id_prof_requested || ' / ' || l_params;
                IF l_id_prof_requested = i_prof.id
                THEN
                    IF i_workflow_action IS NULL
                       OR i_workflow_action NOT IN
                       (pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_d),
                           pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_y)) -- this prevents referral to be issued at the moment of denying the referral
                    THEN
                        RETURN pk_ref_constant.g_transition_allow;
                    END IF;
                END IF;
            
            WHEN l_status_begin_v = pk_ref_constant.g_p1_status_a
                 AND l_status_end_v = pk_ref_constant.g_p1_status_s THEN
                ---------------------------
                -- Scheduling      
                ---------------------------            
                IF i_prof.institution = l_id_inst_dest
                THEN
                
                    g_error  := 'SCHEDULE_TYPE / ' || l_params;
                    l_config := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                            i_id_sys_config => pk_ref_constant.g_ref_schedule_type);
                
                    CASE i_profile
                        WHEN pk_ref_constant.g_profile_adm_hs THEN
                        
                            g_error := 'profile_adm_hs / ' || l_params;
                            IF l_config = g_simulation
                            THEN
                                -- Marcar (Simulação)
                                RETURN pk_ref_constant.g_transition_allow;
                            ELSE
                                RETURN pk_ref_constant.g_transition_deny;
                            END IF;
                        
                    -- ALERT-98838                         
                        WHEN pk_ref_constant.g_profile_adm_hs_cl THEN
                        
                            g_error := 'profile_adm_hs_cl / ' || l_params;
                            RETURN pk_ref_constant.g_transition_allow;
                        
                        WHEN pk_ref_constant.g_profile_intf THEN
                        
                            g_error := 'profile_intf / ' || l_params;
                            IF l_config = g_simulation
                            THEN
                                RETURN pk_ref_constant.g_transition_deny;
                            ELSE
                                RETURN pk_ref_constant.g_transition_allow;
                            END IF;
                        ELSE
                            g_error := 'else / ' || l_params;
                            RETURN pk_ref_constant.g_transition_deny;
                    END CASE;
                
                END IF;
            
            WHEN l_status_begin_v = pk_ref_constant.g_p1_status_i THEN
            
                IF l_status_end_v = pk_ref_constant.g_p1_status_b
                THEN
                    ---------------------------
                    -- Bureaucratic decline
                    ---------------------------                
                
                    IF l_id_prof_requested != i_prof.id -- JB 2010-02-26 Não devolve para ele proprio
                    THEN
                    
                        IF l_id_inst_dest = i_prof.institution
                        THEN
                            -- DEST institution: professional plays the role of dest registrar    
                        
                            -- checking if orig institution is private or not (FERTIS requirement)
                            g_error  := 'Call pk_ref_core.check_private_inst / ID_INST_ORIG=' || l_id_inst_orig ||
                                        ' / ' || l_params;
                            g_retval := pk_ref_core.check_private_inst(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_inst    => l_id_inst_orig,
                                                                       o_flg_result => l_priv_inst,
                                                                       o_error      => l_error);
                        
                            g_error := 'ID_INST_ORIG=' || l_id_inst_orig || ' PRIVATE=' || l_priv_inst || ' / ' ||
                                       l_params;
                            IF l_priv_inst = pk_ref_constant.g_yes
                            THEN
                            
                                RETURN pk_ref_constant.g_transition_deny;
                            ELSE
                            
                                g_error := 'Calling pk_ref_dest_reg.validate_dcs / ID_DCS=' || l_id_dcs || ' / ' ||
                                           l_params;
                                IF pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs) =
                                   pk_ref_constant.g_yes
                                THEN
                                    RETURN pk_ref_constant.g_transition_allow;
                                END IF;
                            END IF;
                        
                        END IF;
                    
                    ELSE
                        RETURN pk_ref_constant.g_transition_deny;
                    END IF;
                
                END IF;
            
            WHEN l_status_begin_v = pk_ref_constant.g_p1_status_m
                 AND l_status_end_v = pk_ref_constant.g_p1_status_e THEN
            
                ---------------------------
                -- Efectivation
                ---------------------------
            
                g_error  := 'EFECTIVATION_TYPE / ' || l_params;
                l_config := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                        i_id_sys_config => pk_ref_constant.g_ref_efectivation_type);
            
                CASE i_profile
                    WHEN pk_ref_constant.g_profile_adm_hs_cl THEN
                    
                        g_error := 'profile_adm_hs_cl / l_config=' || l_config || ' / ' || l_params;
                        -- Marcar 
                        RETURN pk_ref_constant.g_transition_allow;
                    
                    WHEN pk_ref_constant.g_profile_adm_hs THEN
                    
                        g_error := 'profile_adm_hs / l_config=' || l_config || ' / ' || l_params;
                        IF l_config = g_simulation
                        THEN
                            -- Marcar (Simulação)
                            RETURN pk_ref_constant.g_transition_allow;
                        ELSE
                            RETURN pk_ref_constant.g_transition_deny;
                        END IF;
                    
                    WHEN pk_ref_constant.g_profile_intf THEN
                        g_error := 'profile_intf / l_config=' || l_config || ' / ' || l_params;
                        IF l_config = g_simulation
                        THEN
                            RETURN pk_ref_constant.g_transition_deny;
                        ELSE
                            RETURN pk_ref_constant.g_transition_allow;
                        END IF;
                    
                    ELSE
                        RETURN pk_ref_constant.g_transition_deny;
                END CASE;
            
            WHEN l_status_begin_v IN (pk_ref_constant.g_p1_status_e, pk_ref_constant.g_p1_status_w)
                 AND l_status_end_v = pk_ref_constant.g_p1_status_w THEN
            
                ---------------------------
                -- Ans(W)er referral
                ---------------------------
                -- get professional to whom the referral was scheduled
                g_error  := 'Call pk_api_ref_ws.get_ref_schedule_prof / ' || l_params;
                g_retval := pk_api_ref_ws.get_ref_schedule_prof(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_id_ref    => l_id_ref,
                                                                o_id_prof   => l_prof_sch,
                                                                o_num_order => l_prof_sch_no,
                                                                o_error     => l_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error     := 'Calling pk_ref_core.get_prof_func / DEP_CLIN_SERV=' || l_id_dcs || ' / ' || l_params;
                l_prof_func := pk_ref_core.get_prof_func(i_lang => i_lang, i_prof => i_prof, i_dcs => l_id_dcs);
            
                IF l_prof_func = pk_ref_constant.g_func_d
                THEN
                    g_error := 'Specialty triage physician / DEP_CLIN_SERV=' || l_id_dcs || ' / ' || l_params;
                    RETURN pk_ref_constant.g_transition_allow;
                
                ELSIF l_prof_func = pk_ref_constant.g_func_t
                      AND (l_id_prof_redirected = i_prof.id OR i_prof.id = l_prof_sch)
                THEN
                    g_error := 'Triage physician / DEP_CLIN_SERV=' || l_id_dcs || ' ID_PROF_REDIRECTED=' ||
                               l_id_prof_redirected || ' / ' || l_params;
                    RETURN pk_ref_constant.g_transition_allow;
                
                ELSIF l_prof_func = pk_ref_constant.g_func_c
                      AND (i_prof.id = l_prof_sch OR l_prof_sch IS NULL)
                THEN
                
                    g_error := 'Consulting physician / DEP_CLIN_SERV=' || l_id_dcs || ' ID_PROF_SCH=' || l_prof_sch ||
                               ' / ' || l_params;
                    RETURN pk_ref_constant.g_transition_allow;
                
                END IF;
            
            WHEN l_status_begin_v = pk_ref_constant.g_p1_status_w
                 AND l_status_end_v = pk_ref_constant.g_p1_status_k THEN
                ---------------------------
                -- (K)Read referral answer
                ---------------------------
                IF l_id_prof_requested = i_prof.id
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            ELSE
                RETURN pk_ref_constant.g_transition_deny;
            
        END CASE;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WF_TRANSITION',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END get_wf_transition;

    ------------------------------------------------------------
    -- Workflow functions   
    ------------------------------------------------------------

    /**
    * Check if can change referral to another institution
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION can_change_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error              t_error_out;
        l_count              PLS_INTEGER;
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init can_change_institution / i_prof=' || pk_utils.to_string(i_prof) || ' WF=' || i_workflow ||
                   ' STS_BEG=' || i_status_begin || ' STS_END=' || i_status_end || ' ACTION=' || i_workflow_action ||
                   ' CAT=' || i_category || ' CAT=' || i_profile || ' FUNC=' || i_func || ' i_param=' ||
                   pk_utils.to_string(i_param);
        --pk_alertlog.log_debug(g_error);
    
        ---------------------------
        -- Change Institution
        ---------------------------    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        IF l_id_inst_dest = i_prof.institution -- can only be done if professional is in dest institution
        THEN
        
            g_error  := 'Call pk_ref_core.get_pat_age_gender / ID_REF=' || l_id_ref || ' ID_PAT=' || l_id_patient;
            g_retval := pk_ref_core.get_pat_age_gender(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => l_id_patient,
                                                       o_gender  => l_gender,
                                                       o_age     => l_age,
                                                       o_error   => l_error);
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CHANGE_INST / ID_REF=' || l_id_ref;
            SELECT COUNT(1)
              INTO l_count
              FROM TABLE(CAST(pk_ref_dest_phy.get_inst_dcs_forward_p(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_id_spec      => l_id_speciality,
                                                                     i_id_workflow  => i_workflow,
                                                                     i_id_inst_orig => l_id_inst_orig,
                                                                     i_id_inst_dest => l_id_inst_dest,
                                                                     i_pat_gender   => l_gender,
                                                                     i_pat_age      => l_age,
                                                                     i_external_sys => l_id_external_sys) AS
                              t_coll_ref_inst_dcs_fwd)) t;
        
            g_error := 'l_count=' || l_count;
            IF l_count != 0
            THEN
                RETURN pk_ref_constant.g_transition_allow;
            END IF;
        
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CAN_CHANGE_INSTITUTION',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END can_change_institution;

    /**
    * Check if professional is clinical director
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-03-2012
    */
    FUNCTION check_clinical_director
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_clinical_director / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        --pk_alertlog.log_debug(g_error);
    
        g_retval := pk_ref_core.is_clinical_director(i_lang => i_lang, i_prof => i_prof);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        RETURN pk_ref_constant.g_transition_allow;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CLINICAL_DIRECTOR',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
        
    END check_clinical_director;

    /**
    * Check if professional is clinical director and can decline the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-07-2012
    */
    FUNCTION check_can_decline_cd
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
        l_config VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_can_decline_cd / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        -- check if configuration is enabled
        g_error  := 'Call check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_decline_cd_enabled;
        l_config := check_config_enabled(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_config => pk_ref_constant.g_ref_decline_cd_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            l_result := pk_ref_constant.g_transition_deny;
        ELSE
            -- check if professional is clinical director
            l_result := check_clinical_director(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_workflow        => i_workflow,
                                                i_status_begin    => i_status_begin,
                                                i_status_end      => i_status_end,
                                                i_workflow_action => i_workflow_action,
                                                i_category        => i_category,
                                                i_profile         => i_profile,
                                                i_func            => i_func,
                                                i_param           => i_param);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CAN_DECLINE_CD',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_decline_cd;

    /**
    * Check if professional can decline the referral to the registrar
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-08-2012
    */
    FUNCTION check_can_decline_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
        l_config VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_can_decline_reg / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        -- check if configuration is enabled
        g_error  := 'Call check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_decline_reg_enabled;
        l_config := check_config_enabled(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_config => pk_ref_constant.g_ref_decline_reg_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            l_result := pk_ref_constant.g_transition_deny;
        ELSE
            -- check if professional is triage physician of this dep_clin_serv
            l_result := check_dep_clin_serv_te(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_workflow        => i_workflow,
                                               i_status_begin    => i_status_begin,
                                               i_status_end      => i_status_end,
                                               i_workflow_action => i_workflow_action,
                                               i_category        => i_category,
                                               i_profile         => i_profile,
                                               i_func            => i_func,
                                               i_param           => i_param);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CAN_DECLINE_REG',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_decline_reg;

    /**
    * Check if professional can triage the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_can_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_can_triage / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                    ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                    i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error := 'Calling pk_ref_dest_phy.validate_dcs_triage';
        IF i_prof.institution = l_id_inst_dest
           AND pk_ref_dest_phy.validate_dcs_triage(i_prof => i_prof, i_dcs => l_id_dcs) = pk_ref_constant.g_yes
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CAN_TRIAGE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_triage;

    /**
    * Check if professional can send the referral to triage
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2013
    */
    FUNCTION check_can_send_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        CURSOR c_match
        (
            x_id_inst IN p1_external_request.id_inst_dest%TYPE,
            x_id_pat  IN p1_external_request.id_patient%TYPE
        ) IS
        --SELECT m.id_match
        --  FROM p1_external_request exr
        --  JOIN p1_match m
        --    ON (exr.id_inst_dest = m.id_institution AND exr.id_patient = m.id_patient)
        -- WHERE exr.id_external_request = x
        --   AND m.flg_status = pk_ref_constant.g_match_status_a; -- Rematch
            SELECT 1
              FROM p1_match m
             WHERE m.id_institution = x_id_inst
               AND m.id_patient = x_id_pat
               AND m.flg_status = pk_ref_constant.g_match_status_a -- Rematch
               AND rownum <= 1;
    
        l_match_available VARCHAR2(1 CHAR);
        l_count           PLS_INTEGER;
        l_flg_ws          VARCHAR2(1 CHAR);
    
        l_flg_adm_required VARCHAR2(1 CHAR);
        l_flg_func         VARCHAR2(1 CHAR);
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || '  WF=' || i_workflow || ' BEG=' || i_status_begin ||
                    ' END=' || i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' ||
                    i_profile || ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_error  := 'Init check_can_send_triage / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------        
        l_match_available := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                         i_code_cf => pk_ref_constant.g_ref_match_available),
                                 pk_ref_constant.g_no);
    
        g_error  := 'Call get_param_values / ' || l_params;
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        -- match
        g_error := 'Call pk_interfaces_referral.get_is_inst_ref_simulation(' || l_id_inst_dest || ') / ' || l_params;
        BEGIN
            EXECUTE IMMEDIATE 'SELECT pk_interfaces_referral.get_is_inst_ref_simulation(:inst) FROM DUAL'
                INTO l_flg_ws
                USING l_id_inst_dest;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- default behaviour is using referral application   
            --ORA-00904: "PK_INTERFACES_REFERRAL"."GET_IS_INST_REF_SIMULATION": invalid identifier
        END;
    
        IF l_flg_ws = '1'
        THEN
            -- webservices behaviour, does not need match
            NULL;
        ELSE
            -- using referral application
            g_error := 'OPEN c_match(' || l_id_inst_dest || ',' || l_id_patient || ') / ' || l_params;
            OPEN c_match(x_id_inst => l_id_inst_dest, x_id_pat => l_id_patient);
            --OPEN c_match(l_id_ref);
            FETCH c_match
                INTO l_count;
            g_found := c_match%FOUND;
            CLOSE c_match;
        
            g_error := 'l_match_available=' || l_match_available || ' / ' || l_params;
            IF l_match_available = pk_ref_constant.g_yes
               AND NOT g_found
            THEN
                g_error := 'MATCH REQUIRED AND NOT FOUND / ID_REF=' || l_id_ref || ' / ' || l_params;
                RETURN pk_ref_constant.g_transition_deny;
            END IF;
        END IF;
    
        l_params := l_params || ' ID_PROF_REQUESTED=' || l_id_prof_requested || ' ID_INST_ORIG=' || l_id_inst_orig ||
                    ' l_id_dcs=' || l_id_dcs;
    
        g_error := 'i_workflow_action / ' || l_params;
        IF i_workflow_action = pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i)
        THEN
            -- REF_ISSUED (flg_auto_transition=Y)
            g_error            := 'Calling pk_ref_core.get_workflow_config / ' || l_params;
            l_flg_adm_required := pk_ref_core.get_workflow_config(i_prof       => i_prof,
                                                                  i_code_param => pk_ref_constant.g_adm_required,
                                                                  i_speciality => l_id_speciality,
                                                                  i_inst_dest  => l_id_inst_dest,
                                                                  i_inst_orig  => l_id_inst_orig,
                                                                  i_workflow   => i_workflow);
        
            g_error := 'ADM_REQUIRED=' || l_flg_adm_required || ' / ' || l_params;
            IF (l_id_inst_dest = i_prof.institution AND i_category = pk_ref_constant.g_cat_id_adm)
               OR l_id_inst_orig = i_prof.institution
            THEN
                IF l_flg_adm_required = pk_ref_constant.g_no
                THEN
                    -- registrar professional from the origin institution can do transition I->T                                     
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            END IF;
        
            --g_error := 'ADM_REQUIRED=' || l_flg_adm_required || ' / ' || l_params;
            --IF l_id_inst_dest = i_prof.institution
            --   AND i_category = pk_ref_constant.g_cat_id_adm
            --THEN
            --    -- DEST institution: professional plays the role of dest registrar
            --    -- must be configured for referral dep_clin_serv
            --    g_error := 'Call pk_ref_dest_reg.validate_dcs / ' || l_params;
            --    IF pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs) = pk_ref_constant.g_yes
            --       AND l_flg_adm_required = pk_ref_constant.g_no
            --    THEN
            --        RETURN pk_ref_constant.g_transition_allow;
            --    END IF;
        
            --END IF;
        
            --IF l_id_inst_orig = i_prof.institution
            --THEN
            --    -- ORIGIN institution: professional plays the role of origin registrar                                                        
            --    IF l_flg_adm_required = pk_ref_constant.g_no
            --    THEN
            --        -- registrar professional from the origin institution can do transition I->T                                     
            --        RETURN pk_ref_constant.g_transition_allow;
            --    END IF;
            --END IF;
        
        ELSE
            -- REF_TRIAGE (flg_auto_transition=N)
            g_error    := 'Call pk_ref_dest_reg.validate_dcs / ' || l_params;
            l_flg_func := pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs);
        
            IF l_flg_func = pk_ref_constant.g_yes
            THEN
                RETURN pk_ref_constant.g_transition_allow;
            END IF;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CAN_SEND_TRIAGE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_send_triage;

    /**
    * Check if can request a referral cancellation
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_request_cancellation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_config             VARCHAR2(1 CHAR);
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_request_cancellation / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        --pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error  := 'Call check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_cancel_req_enabled;
        l_config := check_config_enabled(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_config => pk_ref_constant.g_ref_cancel_req_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            -- functionality not enabled
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error := 'Call check_dep_clin_serv';
        RETURN check_dep_clin_serv(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_workflow        => i_workflow,
                                   i_status_begin    => i_status_begin,
                                   i_status_end      => i_status_end,
                                   i_workflow_action => i_workflow_action,
                                   i_category        => i_category,
                                   i_profile         => i_profile,
                                   i_func            => i_func,
                                   i_param           => i_param);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REQUEST_CANCELLATION',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_request_cancellation;

    /**
    * Check if can cancel request cancellation
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_cancel_r_cancellation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error          t_error_out;
        l_status_end_v   p1_external_request.flg_status%TYPE;
        l_prev_track_row p1_tracking%ROWTYPE;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_config             VARCHAR2(1 CHAR);
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_cancel_r_cancellation / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        --pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        l_status_end_v := convert_status_v(i_status => i_status_end);
    
        ---------------------------                
        -- this can be done only if:
        -- is the professional that requested the referral or is the registrar that ordered the cancellation request
        -- if the previous referral status is the same as l_status_end_v
        -- if this functionality is enabled
        ---------------------------
    
        g_error  := 'Call check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_cancel_req_enabled;
        l_config := check_config_enabled(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_config => pk_ref_constant.g_ref_cancel_req_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            -- functionality not enabled
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        -- check if referral previous status = l_status_end_v
        -- getting previous referral status
        g_error  := 'Call pk_ref_utils.get_prev_status_data / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' ||
                    l_id_ref;
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => l_id_ref,
                                                      o_data   => l_prev_track_row,
                                                      o_error  => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'ID_PROF=' || i_prof.id || ' PROF_REQUESTED=' || l_id_prof_requested || ' STATUS_END=' ||
                   l_status_end_v;
        IF l_prev_track_row.ext_req_status = l_status_end_v
           AND (l_id_prof_status = i_prof.id OR l_id_prof_requested = i_prof.id)
        THEN
        
            g_error := 'i_profile=' || i_profile || ' ID_REF=' || l_id_ref || ' ID_DEP_CLIN_SERV=' || l_id_dcs ||
                       ' ID_PROF_REQUESTED=' || l_id_prof_requested;
            RETURN pk_ref_constant.g_transition_allow;
        
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CANCEL_R_CANCELLATION',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_cancel_r_cancellation;

    /**
    * Check if functionality 'Request referral cancellation' is enabled
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_req_c_enabled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_config VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_req_c_enabled / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        g_error  := 'Call check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_cancel_req_enabled;
        l_config := check_config_enabled(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_config => pk_ref_constant.g_ref_cancel_req_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        RETURN pk_ref_constant.g_transition_allow;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REQ_C_ENABLED',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_req_c_enabled;

    /**
    * Check if professional is associated to referral dep_clin_serv
    * Note: Returns (A)llow if no dep_clin_serv defined for the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-05-2011
    */
    FUNCTION check_tasks_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        l_status_begin_v p1_external_request.flg_status%TYPE;
        l_status_end_v   p1_external_request.flg_status%TYPE;
    
        l_inside_ref_area ref_dest_institution_spec.flg_inside_ref_area%TYPE;
        l_count           PLS_INTEGER;
    
        CURSOR c_task_count(x_id_ref p1_external_request.id_external_request%TYPE) IS
            SELECT COUNT(1)
              FROM p1_task_done td
             WHERE td.id_external_request = x_id_ref
               AND td.flg_task_done = pk_ref_constant.g_p1_task_done_tdone_n
               AND td.flg_type IN (pk_ref_constant.g_p1_task_done_type_z, pk_ref_constant.g_p1_task_done_type_s)
               AND td.flg_status = pk_ref_constant.g_active; -- only active tasks
    
        CURSOR c_tracking_v(x_ext_req IN p1_external_request.id_external_request%TYPE) IS
            SELECT COUNT(1)
              FROM p1_tracking
             WHERE id_external_request = x_ext_req
               AND ext_req_status = pk_ref_constant.g_p1_status_v --JB ALERT-137884 2010-11-18
               AND flg_type = pk_ref_constant.g_tracking_type_s;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_tasks_complete / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                   i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                   ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        ----------------------
        -- FUNC
        ----------------------
        -- converting status to varchar
        l_status_begin_v := convert_status_v(i_status => i_status_begin);
        l_status_end_v   := convert_status_v(i_status => i_status_end);
    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        -------------------------
        -- Validating mandatory data
        g_error  := 'Calling pk_ref_core.check_mandatory_data / WF=' || i_workflow || ' BEG=' || i_status_begin ||
                    ' END=' || i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' ||
                    i_profile || ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := pk_ref_core.check_mandatory_data(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     i_pat    => l_id_patient,
                                                     i_id_ref => l_id_ref,
                                                     o_error  => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        -------------------------
        -- Validating tasks to be done
        g_error := 'OPEN c_task_count';
        OPEN c_task_count(l_id_ref);
        FETCH c_task_count
            INTO l_count;
        g_found := c_task_count%FOUND;
        CLOSE c_task_count;
    
        g_error := 'TASKS LEFT=' || l_count;
        IF l_count = 0 -- There are no tasks left...
        THEN
        
            IF l_status_begin_v = pk_ref_constant.g_p1_status_b
               AND l_status_end_v = pk_ref_constant.g_p1_status_i
            THEN
            
                g_error := 'B -> I / i_workflow=' || i_workflow;
                IF i_workflow = pk_ref_constant.g_wf_x_hosp
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                ELSE
                    -- must validate id_inst_orig also
                    g_error := 'i_workflow=' || i_workflow || ' i_prof=' || pk_utils.to_string(i_prof) ||
                               ' l_id_inst_orig' || l_id_inst_orig;
                    IF i_prof.institution = l_id_inst_orig
                    THEN
                        RETURN pk_ref_constant.g_transition_allow;
                    END IF;
                END IF;
            END IF;
        
            IF l_status_begin_v = pk_ref_constant.g_p1_status_v
               AND l_status_end_v = pk_ref_constant.g_p1_status_i
            THEN
                g_error := 'V -> I / i_workflow=' || i_workflow;
                RETURN pk_ref_constant.g_transition_allow;
            END IF;
        
            -------------------------
            -- checking id_inst_dest ref area
            g_error           := 'Call pk_ref_core.get_inside_ref_area / ID_INST_ORIG=' || l_id_inst_orig ||
                                 ' ID_INST_DEST=' || l_id_inst_dest || ' REF_TYPE=' || l_flg_type || ' ID_SPEC=' ||
                                 l_id_speciality;
            l_inside_ref_area := pk_ref_core.get_inside_ref_area(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_inst_orig => l_id_inst_orig,
                                                                 i_inst_dest => l_id_inst_dest,
                                                                 i_ref_type  => l_flg_type,
                                                                 i_id_spec   => l_id_speciality);
        
            g_error := 'STATUS_BEGIN=' || l_status_begin_v || ' STATUS_END=' || l_status_end_v || ' WF=' || i_workflow ||
                       ' INSIDE_REF_AREA=' || l_inside_ref_area;
            CASE
                WHEN l_status_begin_v = pk_ref_constant.g_p1_status_n
                     AND l_status_end_v = pk_ref_constant.g_p1_status_i THEN
                
                    g_error := 'WF=' || i_workflow;
                    IF i_workflow != pk_ref_constant.g_wf_hosp_hosp
                    THEN
                        RETURN pk_ref_constant.g_transition_allow;
                    ELSE
                    
                        -- WF=g_wf_hosp_hosp, checking flg_inside_ref_area
                        g_error := 'FLG_INSIDE_REF_AREA=' || l_inside_ref_area;
                        IF l_inside_ref_area = pk_ref_constant.g_yes
                        THEN
                            RETURN pk_ref_constant.g_transition_allow;
                        ELSE
                            -- validate that the referral has ever been in the state 'J' (for approval)
                            g_error := 'OPEN c_tracking_v / ID_REF=' || l_id_ref;
                            l_count := NULL;
                        
                            OPEN c_tracking_v(l_id_ref);
                            FETCH c_tracking_v
                                INTO l_count;
                            CLOSE c_tracking_v;
                        
                            IF l_count > 0
                            THEN
                                -- this referral was approved once, so this transition is allowed
                                RETURN pk_ref_constant.g_transition_allow;
                            ELSE
                                -- this referral has to be approved by the clinical director, this transition is not allowed
                                RETURN pk_ref_constant.g_transition_deny;
                            END IF;
                        
                        END IF;
                    
                    END IF;
                
                WHEN l_status_begin_v = pk_ref_constant.g_p1_status_n
                     AND l_status_end_v = pk_ref_constant.g_p1_status_j THEN
                
                    -- WF=g_wf_hosp_hosp, checking flg_inside_ref_area
                    g_error := 'FLG_INSIDE_REF_AREA=' || l_inside_ref_area;
                    IF l_inside_ref_area = pk_ref_constant.g_no
                    THEN
                    
                        -- validate that the referral has ever been in the state 'J' (for approval)
                        g_error := 'OPEN c_tracking_v / ID_REF=' || l_id_ref;
                        l_count := NULL;
                    
                        OPEN c_tracking_v(l_id_ref);
                        FETCH c_tracking_v
                            INTO l_count;
                        CLOSE c_tracking_v;
                    
                        IF l_count = 0
                        THEN
                            -- this referral has to be approved by the clinical director, so this transition is allowed
                            RETURN pk_ref_constant.g_transition_allow;
                        ELSE
                            -- this referral was already approved by the clinical director, this transition is not allowed
                            RETURN pk_ref_constant.g_transition_deny;
                        END IF;
                    END IF;
                
                WHEN (l_status_begin_v = pk_ref_constant.g_p1_status_o OR l_status_begin_v IS NULL)
                     AND l_status_end_v = pk_ref_constant.g_p1_status_i
                     AND i_workflow = pk_ref_constant.g_wf_x_hosp THEN
                
                    RETURN pk_ref_constant.g_transition_allow;
                
                ELSE
                    RETURN pk_ref_constant.g_transition_deny;
            END CASE;
        
        END IF;
        --END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_TASKS_COMPLETE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_tasks_complete;

    /**
    * Check if professional is associated to referral dep_clin_serv
    * Note: Returns (A)llow if no dep_clin_serv defined for the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_dep_clin_serv / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                    i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        -- check if professional is associated to the dep_clin_serv (only in dest institution)
        IF i_workflow = pk_ref_constant.g_wf_srv_srv
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        ELSE
            IF l_id_inst_dest = i_prof.institution
            THEN
            
                g_error  := 'Call pk_ref_dest_reg.validate_dcs / I_PROF=' || pk_utils.to_string(i_prof) || ' ID_REF=' ||
                            l_id_ref || ' ID_DCS=' || l_id_dcs;
                l_result := pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs);
            
                IF l_result = pk_ref_constant.g_yes
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            
            ELSIF l_id_inst_orig = i_prof.institution
            THEN
                RETURN pk_ref_constant.g_transition_allow;
            END IF;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DEP_CLIN_SERV',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_dep_clin_serv;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Clinical service triage physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_te
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_dep_clin_serv_te / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                    i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error  := 'Call pk_ref_dest_phy.validate_dcs_func / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' ||
                    l_id_dcs;
        l_result := pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                      i_dcs  => l_id_dcs,
                                                      i_func => table_number(pk_ref_constant.g_func_d));
    
        IF l_result = pk_ref_constant.g_yes
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DEP_CLIN_SERV_TE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_dep_clin_serv_te;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Triage physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_t
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_dep_clin_serv_t / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                    i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error  := 'Call pk_ref_dest_phy.validate_dcs_func / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' ||
                    l_id_dcs;
        l_result := pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                      i_dcs  => l_id_dcs,
                                                      i_func => table_number(pk_ref_constant.g_func_d,
                                                                             pk_ref_constant.g_func_t));
    
        IF l_result = pk_ref_constant.g_yes
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DEP_CLIN_SERV_T',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_dep_clin_serv_t;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Consulting physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_c
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_dep_clin_serv_c / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' ||
                    i_status_end || ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error  := 'Call pk_ref_dest_phy.validate_dcs_func / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' ||
                    l_id_dcs;
        l_result := pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                      i_dcs  => l_id_dcs,
                                                      i_func => table_number(pk_ref_constant.g_func_d,
                                                                             pk_ref_constant.g_func_t,
                                                                             pk_ref_constant.g_func_c));
    
        IF l_result = pk_ref_constant.g_yes
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DEP_CLIN_SERV_C',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_dep_clin_serv_c;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Clinical service triage physician" or if 
    * professional the one to whom the referral was forwarded
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-10-2013
    */
    FUNCTION check_dcs_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error  := 'Init check_dcs_triage / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                    ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                    i_func || ' PARAM=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        IF i_prof.institution = l_id_inst_dest
        THEN
        
            -- clinical service triage physician
            g_error  := 'Call pk_ref_dest_phy.validate_dcs_func / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' ||
                        l_id_dcs;
            l_result := pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                          i_dcs  => l_id_dcs,
                                                          i_func => table_number(pk_ref_constant.g_func_d));
        
            IF l_result = pk_ref_constant.g_yes
            THEN
                RETURN pk_ref_constant.g_transition_allow;
            END IF;
        
            -- triage physician
            IF l_id_prof_redirected = i_prof.id
            THEN
                g_error  := 'Call pk_ref_dest_phy.validate_dcs_func / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' ||
                            l_id_dcs;
                l_result := pk_ref_dest_phy.validate_dcs_func(i_prof => i_prof,
                                                              i_dcs  => l_id_dcs,
                                                              i_func => table_number(pk_ref_constant.g_func_t));
            
                IF l_result = pk_ref_constant.g_yes
                THEN
                    RETURN pk_ref_constant.g_transition_allow;
                END IF;
            END IF;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DCS_TRIAGE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_dcs_triage;

    /**
    * Checks if referral can be marked as no show
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-05-2012
    */
    FUNCTION check_no_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error              t_error_out;
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        l_dt_sysdate     p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_appointment schedule.dt_begin_tstz%TYPE;
        l_result         VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_no_show / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                   ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                   i_func || ' PARAM=' || pk_utils.to_string(i_param);
        --l_dt_sysdate := current_timestamp;
        l_dt_sysdate := pk_ref_utils.get_sysdate;
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        g_error          := 'Call pk_ref_module.get_ref_sch_dt_generic / ID_REF=' || l_id_ref;
        l_dt_appointment := pk_ref_module.get_ref_sch_dt_generic(i_lang   => i_lang,
                                                                 i_prof   => i_prof,
                                                                 i_id_ref => l_id_ref);
    
        l_result := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                    i_date1 => l_dt_appointment, -- appointment date
                                                    i_date2 => l_dt_sysdate -- actual date
                                                    );
    
        IF l_result IN ('L', 'E')
        THEN
            RETURN pk_ref_constant.g_transition_allow;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_NO_SHOW',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
        
    END check_no_show;

    /**
    * Checks if professional is associated to the dep_clin_serv and if the referral can be marked as no show
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-05-2012
    */
    FUNCTION check_dcs_no_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_error  t_error_out;
        l_result VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_dcs_no_show / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                   ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                   i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        ----------------------
        -- FUNC
        ----------------------    
        l_result := check_dep_clin_serv(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_workflow        => i_workflow,
                                        i_status_begin    => i_status_begin,
                                        i_status_end      => i_status_end,
                                        i_workflow_action => i_workflow_action,
                                        i_category        => i_category,
                                        i_profile         => i_profile,
                                        i_func            => i_func,
                                        i_param           => i_param);
    
        IF l_result = pk_ref_constant.g_transition_allow
        THEN
            RETURN check_no_show(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_workflow        => i_workflow,
                                 i_status_begin    => i_status_begin,
                                 i_status_end      => i_status_end,
                                 i_workflow_action => i_workflow_action,
                                 i_category        => i_category,
                                 i_profile         => i_profile,
                                 i_func            => i_func,
                                 i_param           => i_param);
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_DCS_NO_SHOW',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
        
    END check_dcs_no_show;

    /**
    * Check if professional can cancel the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-07-2012
    */
    FUNCTION check_can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_status_begin_v     p1_external_request.flg_status%TYPE;
        l_error              t_error_out;
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
    
        l_cancel_days       PLS_INTEGER;
        l_dt_print          p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_sysdate        p1_tracking.dt_tracking_tstz%TYPE;
        l_num_days          PLS_INTEGER;
        l_dt_sch            p1_tracking.dt_tracking_tstz%TYPE;
        l_id_prof_interface professional.id_professional%TYPE;
        l_wf                wf_transition_config.id_workflow%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init check_can_cancel / WF=' || i_workflow || ' BEG=' || i_status_begin || ' END=' || i_status_end ||
                   ' ACTION=' || i_workflow_action || ' CAT=' || i_category || ' PRF=' || i_profile || ' FUNC=' ||
                   i_func || ' PARAM=' || pk_utils.to_string(i_param);
    
        --l_dt_sysdate := current_timestamp;
        l_dt_sysdate := pk_ref_utils.get_sysdate;
        l_wf         := nvl(i_workflow, pk_ref_constant.g_wf_pcc_hosp);
    
        ----------------------
        -- FUNC
        ----------------------  
        -- converting status to varchar
        g_error          := 'Calling convert_status_v';
        l_status_begin_v := convert_status_v(i_status => i_status_begin);
    
        g_error  := 'Call get_param_values / i_param=' || pk_utils.to_string(i_param);
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_transition_deny;
        END IF;
    
        ---------------------------
        -- to (C)ancelled
        ---------------------------            
        IF l_id_prof_requested = i_prof.id
        THEN
        
            IF l_status_begin_v = pk_ref_constant.g_p1_status_p
            THEN
            
                g_error       := 'sys_config=REF_CANCEL_PRINTED_REQUEST_DAYS';
                l_cancel_days := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                       i_id_sys_config => 'REF_CANCEL_PRINTED_REQUEST_DAYS'));
            
                g_error := 'CASE l_cancel_days=' || l_cancel_days;
                CASE
                    WHEN l_cancel_days IS NULL
                         OR l_cancel_days = -1 THEN
                        -- can cancel
                        RETURN pk_ref_constant.g_transition_allow;
                    
                    WHEN l_cancel_days = 0 THEN
                        -- printed referral cannot be canceled
                        RETURN pk_ref_constant.g_transition_deny;
                    ELSE
                        -- number of days 
                        g_error    := 'Call pk_p1_utils.get_status_date / ID_REF=' || l_id_ref;
                        l_dt_print := pk_p1_utils.get_status_date(i_lang       => i_lang,
                                                                  i_id_ext_req => l_id_ref,
                                                                  i_flg_status => pk_ref_constant.g_p1_status_p);
                    
                        -- Validates if the interval between the date of printing and the operation date is 
                        -- valid to cancel the referral
                        IF (l_dt_print + l_cancel_days) < l_dt_sysdate
                        THEN
                            RETURN pk_ref_constant.g_transition_deny;
                        ELSE
                            RETURN pk_ref_constant.g_transition_allow;
                        END IF;
                END CASE;
            
            ELSIF l_status_begin_v = pk_ref_constant.g_p1_status_s
                  AND i_workflow = pk_ref_constant.g_wf_gp
            THEN
            
                g_error    := 'pk_ref_utils.get_sys_config' || pk_ref_constant.g_sc_ref_days_bcancel;
                l_num_days := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                    i_id_sys_config => pk_ref_constant.g_sc_ref_days_bcancel));
            
                -- todo GP Portal
                g_error := 'SELECT dt_tracking_tstz FROM p1_tracking';
                SELECT dt_tracking_tstz
                  INTO l_dt_sch
                  FROM p1_tracking p
                 WHERE id_external_request = l_id_ref
                   AND ext_req_status = pk_ref_constant.g_p1_status_s;
            
                g_error := 'pk_date_utils.compare_dates_tsz';
                IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                   i_date1 => current_timestamp + l_num_days,
                                                   i_date2 => l_dt_sch) = 'G'
                THEN
                    RETURN pk_ref_constant.g_transition_deny;
                END IF;
            ELSE
                RETURN pk_ref_constant.g_transition_allow;
            
            END IF;
        ELSIF l_id_prof_requested != i_prof.id
              AND i_prof.institution = l_id_inst_dest
              AND pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof) = pk_ref_constant.g_registrar
              AND pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs) = pk_ref_constant.g_yes
              AND ((l_status_begin_v NOT IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_n) AND
              l_wf != pk_ref_constant.g_wf_x_hosp) OR
              (l_wf = pk_ref_constant.g_wf_x_hosp AND l_status_begin_v NOT IN (pk_ref_constant.g_p1_status_o)))
        
        -- ALERT-171287
        THEN
        
            IF nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                               i_id_sys_config => pk_ref_constant.g_ref_registrar_can_cancel),
                   pk_ref_constant.g_no) = pk_ref_constant.g_yes
            THEN
                RETURN pk_ref_constant.g_transition_allow;
            ELSE
                RETURN pk_ref_constant.g_transition_deny;
            END IF;
        ELSE
            l_id_prof_interface := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                         i_prof.institution,
                                                                                                         i_prof.software),
                                                                         i_id_sys_config => pk_ref_constant.g_sc_intf_prof_id));
        
            IF i_prof.id = l_id_prof_interface
               AND i_prof.institution = l_id_inst_dest
            THEN
                -- interface can cancel referral, only in dest institution (like dest registrar only)
                RETURN pk_ref_constant.g_transition_allow;
            ELSE
                -- cannot cancel the referral
                RETURN pk_ref_constant.g_transition_deny;
            END IF;
        END IF;
    
        RETURN pk_ref_constant.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CAN_CANCEL',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_transition_deny;
    END check_can_cancel;

    /**
    * Changes referral status to the previous status (undo the last status change)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action to be processed
    * @param   I_STATUS_END     End status of this transition
    * @param   I_NOTES_DESC     Status change notes    
    * @param   I_NOTES_TYPE     Status change notes type    
    * @param   I_OP_DATE        Status change date      
    * @param   io_param         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010
    */
    FUNCTION set_ref_prev_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_notes_desc IN p1_detail.text%TYPE DEFAULT NULL,
        i_notes_type IN p1_detail.flg_type%TYPE DEFAULT NULL,
        i_op_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row     p1_tracking%ROWTYPE;
        l_detail_row    p1_detail%ROWTYPE;
        l_var           p1_detail.id_detail%TYPE;
        l_flg_available VARCHAR2(1 CHAR);
        l_dt_create     p1_tracking.dt_create%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------                
        g_error := 'Init set_ref_prev_status / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status || ' STATUS_END=' || i_status_end;
        reset_vars;
        l_dt_create := pk_ref_utils.get_sysdate;
        o_track     := table_number();
    
        g_sysdate := nvl(i_op_date, l_dt_create);
    
        ----------------------
        -- FUNC
        ----------------------     
    
        -- getting previous status
        g_error  := 'Call pk_ref_utils.get_prev_status_data / ID_REF=' || i_ref_row.id_external_request;
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
    
        -- checking transition availability
        IF i_status_end IS NULL
           OR i_status_end = l_track_row.ext_req_status
        THEN
        
            g_error  := 'Calling pk_workflow.check_transition / I_PROF=' || pk_utils.to_string(i_prof) || ' WF=' ||
                        i_ref_row.id_workflow || '|BEGIN=' || convert_status_n(i_ref_row.flg_status) || '|END=' ||
                        convert_status_n(l_track_row.ext_req_status) || ' ACTION=' || i_action || '|PROF_PRF_TEMPL=' ||
                        i_prof_data.id_profile_template || '|FUNC=' || i_prof_data.id_functionality || ' CAT=' ||
                        i_prof_data.id_category || ' IO_PARAM=' || pk_utils.to_string(io_param);
            g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                                  pk_ref_constant.g_wf_pcc_hosp),
                                                     i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                     i_id_status_end       => convert_status_n(l_track_row.ext_req_status),
                                                     i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                     i_id_category         => i_prof_data.id_category,
                                                     i_id_profile_template => i_prof_data.id_profile_template,
                                                     i_id_functionality    => i_prof_data.id_functionality,
                                                     i_param               => io_param,
                                                     o_flg_available       => l_flg_available,
                                                     o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error      := 'ERROR: ' || g_error;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
            
                g_error                      := 'l_track_row';
                l_track_row.id_professional  := i_prof.id;
                l_track_row.id_institution   := i_prof.institution;
                l_track_row.dt_tracking_tstz := g_sysdate;
                l_track_row.dt_create        := l_dt_create;
            
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(i_action);
            
                g_error  := 'Calling update_status';
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => o_track,
                                          o_error     => o_error);
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- returns error, no transition available
                g_error      := 'FLG_AVAILABLE=' || l_flg_available || ' / No transition valid for action ' || i_action ||
                                ' / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status ||
                                ' STS_END=' || i_status_end;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSE
            -- returns error, no transition available
            g_error      := 'No transition valid for action ' || i_action || ' / ID_REF=' ||
                            i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' STS_END=' ||
                            i_status_end || ' PREV_FLG_STATUS=' || l_track_row.ext_req_status;
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- inserting notes        
        IF i_notes_desc IS NOT NULL
           AND i_notes_type IS NOT NULL
        THEN
        
            g_error                          := 'Inserting NOTES_TYPE=' || i_notes_type;
            l_detail_row.id_external_request := i_ref_row.id_external_request;
            l_detail_row.text                := i_notes_desc;
            l_detail_row.flg_type            := i_notes_type;
            l_detail_row.id_professional     := i_prof.id;
            l_detail_row.id_institution      := i_prof.institution;
            l_detail_row.id_tracking         := o_track(1); -- first iteration
            l_detail_row.flg_status          := pk_ref_constant.g_active;
            l_detail_row.dt_insert_tstz      := g_sysdate;
        
            g_error  := 'Call pk_ref_api.set_p1_detail / DETAIL_ROW=' ||
                        pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_detail_row => l_detail_row);
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_var,
                                                 o_error     => o_error);
        
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
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_PREV_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_prev_status;

    /**
    * Changes referral status. This is a base function. 
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action to be processed
    * @param   I_STATUS_END     End status of this transition
    * @param   I_FLG_TYPE       Type of change.   
    * @param   I_REASON_CODE    Status change reason code
    * @param   I_DCS            Dep_clin_Serv identifier
    * @param   I_ID_PROF_DEST   Professional destination identifier
    * @param   I_FLG_SUBTYPE    FLG_SUBTYPE
    * @param   I_ID_SCHEDULE    Schedule identifier
    * @param   I_FLG_RESCHEDULE Flag indicating it is not the first schedule    
    * @param   I_LEVEL          Deciion urgency level   
    * @param   I_ID_INST_DEST   Institution dest indentifier   
    * @param   I_ID_SPECIALITY  Referral speciality indentifier
    * @param   I_DT_REQUESTED   Referral date requested (if not null)
    * @param   I_NOTES_DESC     Status change notes    
    * @param   I_NOTES_TYPE     Status change notes type     
    * @param   I_OP_DATE        Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation   
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_FLG_STATUS     Referral status after update    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION set_ref_base
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_flg_type       IN p1_tracking.flg_type%TYPE,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs            IN p1_tracking.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_prof_dest   IN p1_tracking.id_prof_dest%TYPE DEFAULT NULL,
        i_flg_subtype    IN p1_tracking.flg_subtype%TYPE DEFAULT NULL,
        i_id_schedule    IN p1_tracking.id_schedule%TYPE DEFAULT NULL,
        i_flg_reschedule IN p1_tracking.flg_reschedule%TYPE DEFAULT NULL,
        i_level          IN p1_tracking.decision_urg_level%TYPE DEFAULT NULL,
        i_id_inst_dest   IN p1_tracking.id_inst_dest%TYPE DEFAULT NULL,
        i_id_speciality  IN p1_tracking.id_speciality%TYPE DEFAULT NULL,
        i_dt_requested   IN p1_external_request.dt_requested%TYPE DEFAULT NULL,
        i_notes_desc     IN p1_detail.text%TYPE DEFAULT NULL,
        i_notes_type     IN p1_detail.flg_type%TYPE DEFAULT NULL,
        i_op_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_flg_status     OUT p1_tracking.ext_req_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params        VARCHAR2(1000 CHAR);
        l_track_row     p1_tracking%ROWTYPE;
        l_detail_row    p1_detail%ROWTYPE;
        l_var           p1_detail.id_detail%TYPE;
        l_flg_available VARCHAR2(1 CHAR);
        l_dt_create     p1_tracking.dt_create%TYPE;
        l_sysdate       TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' FLG_STATUS=' || i_ref_row.flg_status ||
                    ' i_action=' || i_action || ' i_status_end=' || i_status_end || ' i_flg_type=' || i_flg_type ||
                    ' i_notes_type=' || i_notes_type || ' i_reason_code=' || i_reason_code || ' i_dcs=' || i_dcs ||
                    ' i_id_prof_dest=' || i_id_prof_dest || ' i_flg_subtype=' || i_flg_subtype || ' i_level=' ||
                    i_level || ' i_id_speciality=' || i_id_speciality || ' i_id_schedule=' || i_id_schedule ||
                    ' i_flg_reschedule=' || i_flg_reschedule || ' i_id_inst_dest=' || i_id_inst_dest || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_base / ' || l_params;
        reset_vars;
        l_dt_create := pk_ref_utils.get_sysdate;
        o_track     := table_number();
    
        l_sysdate       := nvl(i_op_date, l_dt_create);
        l_flg_available := pk_ref_constant.g_no;
    
        -- checking transition availability
        g_error  := 'Calling pk_workflow.check_transition / ' || l_params;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                              pk_ref_constant.g_wf_pcc_hosp),
                                                 i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                 i_id_status_end       => convert_status_n(i_status_end),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                 i_id_category         => i_prof_data.id_category,
                                                 i_id_profile_template => i_prof_data.id_profile_template,
                                                 i_id_functionality    => i_prof_data.id_functionality,
                                                 i_param               => io_param,
                                                 o_flg_available       => l_flg_available,
                                                 o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            -- returns error, no transition available
            g_error      := 'No transition valid for action ' || i_action || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- transition available: proceed with the status change               
        g_error                         := 'UPDATE STATUS / ' || l_params;
        l_track_row.dt_tracking_tstz    := l_sysdate;
        l_track_row.dt_create           := l_dt_create;
        l_track_row.id_external_request := i_ref_row.id_external_request;
        l_track_row.ext_req_status      := i_status_end;
        l_track_row.flg_type            := i_flg_type;
        l_track_row.id_reason_code      := i_reason_code;
        l_track_row.id_dep_clin_serv    := i_dcs;
        l_track_row.id_prof_dest        := i_id_prof_dest;
        l_track_row.flg_subtype         := i_flg_subtype;
        l_track_row.decision_urg_level  := i_level;
        l_track_row.flg_reschedule      := i_flg_reschedule;
        l_track_row.id_schedule         := i_id_schedule;
        l_track_row.id_inst_dest        := i_id_inst_dest;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(i_action);
        l_track_row.id_speciality       := i_id_speciality;
    
        g_error  := 'Call update_status / ' || l_params;
        g_retval := update_status(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_track_row    => l_track_row,
                                  i_dt_requested => i_dt_requested,
                                  io_param       => io_param,
                                  o_track        => o_track,
                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        o_flg_status := i_status_end;
    
        -- inserting notes        
        IF i_notes_desc IS NOT NULL
           AND i_notes_type IS NOT NULL
        THEN
        
            g_error                          := 'Inserting NOTES_TYPE=' || i_notes_type || ' / ' || l_params;
            l_detail_row.id_external_request := i_ref_row.id_external_request;
            l_detail_row.text                := i_notes_desc;
            l_detail_row.flg_type            := i_notes_type;
            l_detail_row.id_professional     := i_prof.id;
            l_detail_row.id_institution      := i_prof.institution;
            l_detail_row.id_tracking         := o_track(1); -- first iteration
            l_detail_row.flg_status          := pk_ref_constant.g_active;
            l_detail_row.dt_insert_tstz      := l_track_row.dt_tracking_tstz;
        
            g_error  := 'Call pk_ref_api.set_p1_detail / ' || l_params;
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_var,
                                                 o_error     => o_error);
        
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
                                              i_function    => 'SET_REF_BASE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_base;

    /**
    * Issues request, changes referral status to I
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   I_MODE           Change (S)ame or (O)ther Institution
    * @param   I_DCS            Dep_clin_serv id
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro / Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_issued2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_mode       IN VARCHAR2 DEFAULT pk_ref_constant.g_issue_mode_s,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params          VARCHAR2(1000 CHAR);
        l_dcs             p1_tracking.id_dep_clin_serv%TYPE;
        l_flg_status      p1_external_request.flg_status%TYPE;
        l_dcs_count       NUMBER DEFAULT 0;
        l_id_dcs_to_issue p1_external_request.id_dep_clin_serv%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' DCS=' || i_ref_row.id_dep_clin_serv || ' i_dcs=' ||
                    i_dcs || ' l_id_dcs_to_issue=' || l_id_dcs_to_issue || ' i_MODE=' || i_mode || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_issued / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        IF i_ref_row.id_dep_clin_serv IS NULL
        THEN
            l_id_dcs_to_issue := nvl(i_dcs, i_ref_row.id_dep_clin_serv);
        
            g_error  := 'Calling get_dcs_info / ' || l_params;
            g_retval := get_dcs_info(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_ref_row   => i_ref_row,
                                     i_dcs       => l_id_dcs_to_issue,
                                     i_mode      => i_mode,
                                     o_dcs_count => l_dcs_count,
                                     o_track_dcs => l_dcs,
                                     o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        --  Register issued status
        g_error  := 'Call set_ref_base / o_dcs_count=' || l_dcs_count || ' o_track_dcs=' || l_dcs || ' / ' || l_params;
        g_retval := set_ref_base(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_data  => i_prof_data,
                                 i_ref_row    => i_ref_row,
                                 i_action     => i_action,
                                 i_status_end => i_status_end,
                                 i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                 i_dcs        => l_dcs,
                                 i_op_date    => g_sysdate,
                                 io_param     => io_param,
                                 o_track      => o_track,
                                 o_flg_status => l_flg_status,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- ALERT-223767: Associates all origin registrar notes with id_tracking=null to this status change        
        g_error := 'UPDATE p1_detail / ID_TRACKING=' || o_track(1) || ' / ' || l_params;
        UPDATE p1_detail d
           SET id_tracking = o_track(1)
         WHERE id_external_request = i_ref_row.id_external_request
           AND d.flg_type = pk_ref_constant.g_detail_type_admi
           AND d.id_tracking IS NULL;
    
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
                                              i_function    => 'SET_REF_ISSUED',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_issued2;

    /**
    * Changes referral destination institution
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action          
    * @param   I_STATUS_END     End status
    * @param   I_INST_DEST      New Institution id        
    * @param   I_DCS            Dep_clin_serv id  
    * @param   I_NOTES          Status change notes  
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false         
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-06-2009
    */
    FUNCTION set_ref_dest_inst2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params        VARCHAR2(1000 CHAR);
        l_ref_row       p1_external_request%ROWTYPE;
        l_rowids        table_varchar;
        l_detail_tab    table_varchar;
        l_flg_available VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' i_inst_dest=' || i_inst_dest || ' i_dcs=' || i_dcs ||
                    ' io_param=' || pk_utils.to_string(io_param);
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        IF (i_inst_dest IS NULL)
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------   
        l_ref_row := i_ref_row;
    
        -- checking if dep_clin_serv is related to id_inst_dest (if available)
        IF i_dcs IS NOT NULL
        THEN
            g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / ' || l_params;
            g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_inst_dest  => i_inst_dest,
                                                          i_dcs           => i_dcs,
                                                          o_flg_available => l_flg_available,
                                                          o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error := 'Id Institution and Dep_clin_serv do not match / INST=' || i_inst_dest || '|DCS=' || i_dcs ||
                           ' / ' || l_params;
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error                := 'l_ref_row / ' || l_params;
        l_ref_row.id_inst_orig := i_prof.institution; -- This is done because it will be used to get p1_workflow_config configs (only)
        l_ref_row.id_inst_dest := i_inst_dest;
    
        g_error  := 'Calling set_ref_issued / ' || l_params;
        g_retval := set_ref_issued2(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_prof_data  => i_prof_data,
                                    i_ref_row    => l_ref_row,
                                    i_action     => i_action,
                                    i_status_end => i_status_end,
                                    i_mode       => 'O', --(O)ther institution
                                    i_dcs        => i_dcs,
                                    i_date       => g_sysdate,
                                    io_param     => io_param,
                                    o_track      => o_track,
                                    o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call ts_p1_external_request.upd / ' || l_params;
        ts_p1_external_request.upd(id_external_request_in => l_ref_row.id_external_request,
                                   id_inst_dest_in        => i_inst_dest,
                                   flg_forward_dcs_in     => pk_ref_constant.g_yes,
                                   rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_notes IS NOT NULL
        THEN
            -- [id_detail|flg_type|text|flg|id_group]
            g_error      := 'INIT detail / ' || l_params;
            l_detail_tab := table_varchar(NULL,
                                          pk_ref_constant.g_detail_type_ndec,
                                          i_notes,
                                          pk_ref_constant.g_detail_flg_i,
                                          NULL);
        
            g_error  := 'Call pk_ref_core.set_notes / ' || l_params;
            g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                               i_ext_req       => l_ref_row.id_external_request,
                                               i_prof          => i_prof,
                                               i_detail        => table_table_varchar(l_detail_tab),
                                               i_ext_req_track => o_track(1),
                                               o_error         => o_error);
        
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
                                              i_function    => 'SET_REF_DEST_INST',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_dest_inst2;

    /**
    * Changes status referral to (T)riage
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids 
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Reason code id
    * @param   I_DCS            Dep_clin_serv id
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params            VARCHAR2(1000 CHAR);
        l_track_row         p1_tracking%ROWTYPE;
        l_last_triage_track p1_tracking%ROWTYPE;
        l_id_track_tab      table_number;
        l_flg_status        p1_external_request.flg_status%TYPE;
        l_id_dep_clin_serv  p1_tracking.id_dep_clin_serv%TYPE;
        l_dt_create         p1_tracking.dt_create%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' i_action=' || i_action || ' i_status_end=' ||
                    i_status_end || ' i_reason_code=' || i_reason_code || ' i_dcs=' || i_dcs || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_sent_triage / ' || l_params;
        reset_vars;
        l_dt_create := pk_ref_utils.get_sysdate;
    
        g_sysdate := nvl(i_date, l_dt_create);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ----------------------            
        g_error             := 'Call pk_p1_utils.get_last_triage_status / ' || l_params;
        l_last_triage_track := pk_p1_utils.get_last_triage_status(i_ref_row.id_external_request); -- must be done before set_ref_base
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_prof_data   => i_prof_data,
                                 i_ref_row     => i_ref_row,
                                 i_action      => i_action,
                                 i_status_end  => i_status_end,
                                 i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                 i_dcs         => i_dcs,
                                 i_reason_code => i_reason_code,
                                 i_notes_desc  => i_notes,
                                 i_notes_type  => pk_ref_constant.g_detail_type_ntri, -- Notes to triage doctor
                                 io_param      => io_param,
                                 i_op_date     => g_sysdate,
                                 o_track       => o_track,
                                 o_flg_status  => l_flg_status,
                                 o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Se ja esteve em triagem e foi reencaminhado deve ficar reencaminhado
        g_error := 'l_last_triage_track.ext_req_status=' || l_last_triage_track.ext_req_status ||
                   ' l_last_triage_track.id_prof_dest=' || l_last_triage_track.id_prof_dest || ' / ' || l_params;
        IF l_last_triage_track.ext_req_status = pk_ref_constant.g_p1_status_r
        THEN
            -- get id_dep_clin_serv when referral was forwarded
            g_error := 'SELECT id_dep_clin_serv / ' || l_params;
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
        
            g_error := 'l_id_dep_clin_serv=' || l_id_dep_clin_serv || ' i_dcs=' || i_dcs ||
                       ' i_ref_row.id_dep_clin_serv=' || i_ref_row.id_dep_clin_serv || ' / ' || l_params;
            IF l_id_dep_clin_serv = nvl(i_dcs, i_ref_row.id_dep_clin_serv)
            THEN
            
                -- Forwards the referral only if is the same id_dep_clin_serv
                g_error                         := 'UPDATE STATUS R / ' || l_params;
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_r;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_p;
                l_track_row.id_prof_dest        := l_last_triage_track.id_prof_dest;
                l_track_row.dt_tracking_tstz    := g_sysdate + INTERVAL '1' SECOND;
                l_track_row.dt_create           := l_dt_create;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_t);
            
                g_error  := 'Call update_staus / ext_req_status=' || l_track_row.ext_req_status || ' id_prof_dest=' ||
                            l_track_row.id_prof_dest || ' id_workflow_action=' || l_track_row.id_workflow_action ||
                            ' / ' || l_params;
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => l_id_track_tab,
                                          o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1008;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                o_track := o_track MULTISET UNION l_id_track_tab;
            END IF;
        
        END IF;
    
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
                                              i_function    => 'SET_REF_SENT_TRIAGE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_sent_triage;

    /**
    * Changes referral clinical service
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DCS            Dep_clin_serv id    
    * @param   I_SUBTYPE                
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_cs2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_subtype    IN VARCHAR2,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params     VARCHAR2(1000 CHAR);
        l_flg_status p1_external_request.flg_status%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' i_action=' || i_action || ' i_status_end=' ||
                    i_status_end || ' i_dcs=' || i_dcs || ' i_subtype=' || i_subtype || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_cs2 / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ----------------------     
        IF (i_dcs IS NULL)
        THEN
            RAISE g_exception;
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base';
        g_retval := set_ref_base(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_prof_data    => i_prof_data,
                                 i_ref_row      => i_ref_row,
                                 i_action       => i_action,
                                 i_status_end   => i_status_end,
                                 i_flg_type     => pk_ref_constant.g_tracking_type_c,
                                 i_dcs          => i_dcs,
                                 i_id_prof_dest => 0,
                                 i_flg_subtype  => i_subtype,
                                 i_notes_desc   => i_notes,
                                 i_notes_type   => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date      => g_sysdate,
                                 io_param       => io_param,
                                 o_track        => o_track,
                                 o_flg_status   => l_flg_status,
                                 o_error        => o_error);
    
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
                                              i_function    => 'SET_REF_CS',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_cs2;

    /**
    * Changes status referral to (A)ccepted
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action         
    * @param   I_STATUS_END     End status
    * @param   I_PROF_DEST      Appointment professional id
    * @param   I_DCS            Dep_clin_serv id
    * @param   I_LEVEL          Triage decision urgency       
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-06-2009
    */
    FUNCTION set_ref_triaged2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_prof_dest  IN professional.id_professional%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_level      IN p1_external_request.decision_urg_level%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params      VARCHAR2(1000 CHAR);
        l_flg_subtype p1_tracking.flg_subtype%TYPE;
        l_flg_status  p1_external_request.flg_status%TYPE;
        l_level       p1_external_request.decision_urg_level%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' i_action=' || i_action || ' i_status_end=' ||
                    i_status_end || ' i_dcs=' || i_dcs || ' i_prof_dest=' || i_prof_dest || ' i_level=' || i_level ||
                    ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_triaged / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        l_level := i_level;
    
        IF i_ref_row.id_workflow = pk_ref_constant.g_wf_gp
        THEN
            IF i_ref_row.flg_priority = pk_ref_constant.g_yes
            THEN
                l_level := pk_ref_constant.g_decision_urg_level_1;
            ELSE
                l_level := pk_ref_constant.g_decision_urg_level_3;
            END IF;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------   
        IF (l_level IS NULL)
        THEN
            RAISE g_exception;
        END IF;
    
        --- RESCHEDULE
        IF i_ref_row.flg_status = pk_ref_constant.g_p1_status_a
        THEN
            l_flg_subtype := pk_ref_constant.g_tracking_subtype_r;
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base / l_flg_subtype=' || l_flg_subtype || ' l_level=' || l_level || ' / ' ||
                    l_params;
        g_retval := set_ref_base(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_prof_data    => i_prof_data,
                                 i_ref_row      => i_ref_row,
                                 i_action       => i_action,
                                 i_status_end   => i_status_end,
                                 i_flg_type     => pk_ref_constant.g_tracking_type_s,
                                 i_dcs          => i_dcs,
                                 i_id_prof_dest => i_prof_dest,
                                 i_flg_subtype  => l_flg_subtype,
                                 i_level        => l_level,
                                 i_notes_desc   => i_notes,
                                 i_notes_type   => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date      => g_sysdate,
                                 io_param       => io_param,
                                 o_track        => o_track,
                                 o_flg_status   => l_flg_status,
                                 o_error        => o_error);
    
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
                                              i_function    => 'SET_REF_TRIAGED',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_triaged2;

    /**
    * Changes referral status after scheduling
    * (based on PK_P1_EXT_SYS.set_status_scheduled)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Profile_template, functionality, and category ids   
    * @param   i_ref_row        Referral info   
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   i_date           Status change date  
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009
    */
    FUNCTION set_ref_scheduled2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_schedule   IN p1_external_request.id_schedule%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_module         sys_config.value%TYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_dcs            schedule.id_dcs_requested%TYPE;
        l_flg_status_new p1_external_request.flg_status%TYPE;
        l_id_track_tab   table_number;
        -- wf
        l_flg_available VARCHAR2(1 CHAR);
        l_dt_create     p1_tracking.dt_create%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' FLG_STATUS=' || i_ref_row.flg_status ||
                    ' i_action=' || i_action || ' i_status_end=' || i_status_end || ' i_schedule=' || i_schedule ||
                    ' i_episode=' || i_episode || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_scheduled / ' || l_params;
        reset_vars;
        l_dt_create := pk_ref_utils.get_sysdate;
    
        g_sysdate       := nvl(i_date, l_dt_create);
        l_flg_available := pk_ref_constant.g_no;
        o_track         := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error  := 'Call pk_ref_utils.get_sys_config / SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module || ' / ' ||
                    l_params;
        l_module := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        ----------------------
        -- FUNC
        ----------------------   
    
        g_error := 'Get schedule data / ' || l_params;
        SELECT s.id_dcs_requested
          INTO l_dcs
          FROM schedule s
         WHERE s.id_schedule = i_schedule;
    
        g_error := 'MODULE =' || l_module || ' / ' || l_params;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- CIRCLE UK: ALERT-27343        
                g_error  := 'Call PK_REF_MODULE.set_ref_scheduled_circle / ' || l_params;
                g_retval := pk_ref_module.set_ref_scheduled_circle(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_ref_row        => i_ref_row,
                                                                   i_schedule       => i_schedule,
                                                                   i_episode        => i_episode,
                                                                   o_flg_status_new => l_flg_status_new,
                                                                   o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error || ' NEW_FLG_STATUS=' || l_flg_status_new;
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- default behaviour
            
                -- CIRCLE UK: ALERT-27343        
                g_error  := 'Call PK_REF_MODULE.set_ref_scheduled_generic / l_dcs=' || l_dcs || ' / ' || l_params;
                g_retval := pk_ref_module.set_ref_scheduled_generic(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_prof_data      => i_prof_data,
                                                                    i_ref_row        => i_ref_row,
                                                                    i_dcs            => l_dcs,
                                                                    i_schedule       => i_schedule,
                                                                    i_date           => g_sysdate,
                                                                    o_track          => l_id_track_tab,
                                                                    o_flg_status_new => l_flg_status_new,
                                                                    o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                o_track := o_track MULTISET UNION l_id_track_tab;
            
        END CASE;
    
        IF l_flg_status_new IS NOT NULL
        THEN
        
            -- It is not the first time it is scheduled
            IF i_ref_row.id_schedule IS NOT NULL
            THEN
                l_track_row.flg_reschedule := pk_ref_constant.g_yes;
            END IF;
        
            -- checking transition availability
            g_error  := 'Calling pk_workflow.check_transition / l_flg_status_new=' || l_flg_status_new || ' / ' ||
                        l_params;
            g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                                  pk_ref_constant.g_wf_pcc_hosp),
                                                     i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                     i_id_status_end       => convert_status_n(l_flg_status_new),
                                                     i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                     i_id_category         => i_prof_data.id_category,
                                                     i_id_profile_template => i_prof_data.id_profile_template,
                                                     i_id_functionality    => i_prof_data.id_functionality,
                                                     i_param               => io_param,
                                                     o_flg_available       => l_flg_available,
                                                     o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
            
                g_error                         := 'UPDATE STATUS / l_flg_status_new=' || l_flg_status_new || ' / ' ||
                                                   l_params;
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := l_flg_status_new;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.id_dep_clin_serv    := l_dcs;
                l_track_row.dt_tracking_tstz    := g_sysdate;
                l_track_row.dt_create           := l_dt_create;
                l_track_row.decision_urg_level  := NULL;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(i_action);
                l_track_row.id_schedule         := i_schedule; -- 2007-12-13: keep track of schedule
            
                g_error  := 'Call update_status / l_flg_status_new=' || l_flg_status_new || ' / ' || l_params;
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => l_id_track_tab,
                                          o_error     => o_error);
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1008;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
                o_track := o_track MULTISET UNION l_id_track_tab;
            
            ELSE
                -- returns error, no transition available
                g_error      := 'No transition valid for action ' || i_action || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
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
                                              i_function    => 'SET_REF_SCHEDULED',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_scheduled2;

    /**
    * Changes status referral to (M)ailed
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date    
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions  
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_mailed2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_module         sys_config.value%TYPE;
        l_flg_status_new p1_external_request.flg_status%TYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_flg_available  VARCHAR2(1 CHAR);
        l_dt_create      p1_tracking.dt_create%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_mailed / ' || l_params;
        reset_vars;
        l_dt_create     := pk_ref_utils.get_sysdate;
        g_sysdate       := nvl(i_date, l_dt_create);
        l_flg_available := pk_ref_constant.g_no;
        o_track         := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------            
        g_error  := 'Call pk_ref_utils.get_sys_config / SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module || ' / ' ||
                    l_params;
        l_module := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        ----------------------
        -- FUNC
        ----------------------            
        g_error := 'MODULE =' || l_module || ' / ' || l_params;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                g_error  := 'Call PK_REF_MODULE.set_ref_mailed_circle / ' || l_params;
                g_retval := pk_ref_module.set_ref_mailed_circle(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_ref_row        => i_ref_row,
                                                                o_flg_status_new => l_flg_status_new,
                                                                o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- changes referral status to 'M' (has only one schedule)
                l_flg_status_new := pk_ref_constant.g_p1_status_m;
        END CASE;
    
        g_error := 'l_flg_status_new=' || l_flg_status_new || ' / ' || l_params;
        IF l_flg_status_new IS NOT NULL
        THEN
        
            -- checking transition availability
            g_error  := 'Calling pk_workflow.check_transition / id_status_end=' || l_flg_status_new || ' / ' ||
                        l_params;
            g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                                  pk_ref_constant.g_wf_pcc_hosp),
                                                     i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                     i_id_status_end       => convert_status_n(l_flg_status_new),
                                                     i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                     i_id_category         => i_prof_data.id_category,
                                                     i_id_profile_template => i_prof_data.id_profile_template,
                                                     i_id_functionality    => i_prof_data.id_functionality,
                                                     i_param               => io_param,
                                                     o_flg_available       => l_flg_available,
                                                     o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            g_error := 'l_flg_available=' || l_flg_available || ' id_status_end=' || l_flg_status_new || ' / ' ||
                       l_params;
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
            
                g_error                         := 'UPDATE STATUS to' || l_flg_status_new || ' / ' || l_params;
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := l_flg_status_new;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := g_sysdate;
                l_track_row.dt_create           := l_dt_create;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(i_action);
            
                g_error  := 'CALL UPDATE_STATUS / FLG_STATUS_NEW=' || l_flg_status_new || ' / ' || l_params;
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => o_track,
                                          o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1008;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            ELSE
                -- returns error, no transition available
                g_error      := 'No transition valid for action ' || i_action || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
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
                                              i_function    => 'SET_REF_MAILED',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_mailed2;

    /**
    * Changes referral status to "E" (efectivation)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_efectv2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_module         sys_config.value%TYPE;
        l_flg_status_new p1_external_request.flg_status%TYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_flg_available  VARCHAR2(1 CHAR);
        l_dt_create      p1_tracking.dt_create%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_efectv / ' || l_params;
        reset_vars;
        l_dt_create     := pk_ref_utils.get_sysdate;
        g_sysdate       := nvl(i_date, l_dt_create);
        l_flg_available := pk_ref_constant.g_no;
        o_track         := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------            
        g_error  := 'Call pk_ref_utils.get_sys_config / SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module || ' / ' ||
                    l_params;
        l_module := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        ----------------------
        -- FUNC
        ----------------------            
    
        g_error := 'MODULE =' || l_module || ' / ' || l_params;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- CIRCLE UK: ALERT-27343                    
                g_error  := 'Call PK_REF_MODULE.set_ref_efectv_circle / ' || l_params;
                g_retval := pk_ref_module.set_ref_efectv_circle(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_ref_row        => i_ref_row,
                                                                o_flg_status_new => l_flg_status_new,
                                                                o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- changes referral status to 'E' (has only one schedule)
                l_flg_status_new := pk_ref_constant.g_p1_status_e;
        END CASE;
    
        g_error := 'NEW FLG_STATUS=' || l_flg_status_new || ' / ' || l_params;
        IF l_flg_status_new IS NOT NULL
        THEN
        
            -- checking transition availability
            g_error  := 'Calling pk_workflow.check_transition / end_status=' || l_flg_status_new || ' / ' || l_params;
            g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                                  pk_ref_constant.g_wf_pcc_hosp),
                                                     i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                     i_id_status_end       => convert_status_n(l_flg_status_new),
                                                     i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                     i_id_category         => i_prof_data.id_category,
                                                     i_id_profile_template => i_prof_data.id_profile_template,
                                                     i_id_functionality    => i_prof_data.id_functionality,
                                                     i_param               => io_param,
                                                     o_flg_available       => l_flg_available,
                                                     o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            g_error := 'l_flg_available=' || l_flg_available || ' end_status=' || l_flg_status_new || ' / ' || l_params;
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
            
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.ext_req_status      := l_flg_status_new;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := g_sysdate;
                l_track_row.dt_create           := l_dt_create;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(i_action);
            
                g_error  := 'Calling update_status / ' || l_params;
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => o_track,
                                          o_error     => o_error);
                IF NOT g_retval
                THEN
                    g_error_code := pk_ref_constant.g_ref_error_1008;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            ELSE
                -- returns error, no transition available
                g_error      := 'No transition valid for action ' || i_action || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        END IF;
    
        IF i_transaction_id IS NOT NULL
        THEN
        
            g_error  := 'Call pk_schedule_api_upstream.register_schedule l_transaction_id = ' || i_transaction_id ||
                        ' i_id_schedule = ' || i_ref_row.id_schedule || ' i_id_patient = ' || i_ref_row.id_patient;
            g_retval := pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_id_schedule    => i_ref_row.id_schedule,
                                                                            i_id_patient     => i_ref_row.id_patient,
                                                                            i_flg_state      => pk_schedule_api_upstream.g_flg_state_pat_waiting,
                                                                            i_transaction_id => i_transaction_id,
                                                                            o_error          => o_error);
        
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
                                              i_function    => 'SET_REF_EFECTV',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_efectv2;

    /**
    * Medical decline
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Decline reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_decline2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params      VARCHAR2(1000 CHAR);
        l_flg_subtype p1_tracking.flg_subtype%TYPE;
        l_flg_status  p1_external_request.flg_status%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_reason_code=' || i_reason_code || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_decline / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ----------------------              
        IF i_ref_row.flg_status = pk_ref_constant.g_p1_status_a
        THEN
            l_flg_subtype := pk_ref_constant.g_tracking_subtype_r; -- js, 2007-11-22: Marcar devolucoes de pedidos ja aceites 
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_prof_data   => i_prof_data,
                                 i_ref_row     => i_ref_row,
                                 i_action      => i_action,
                                 i_status_end  => i_status_end,
                                 i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                 i_reason_code => i_reason_code,
                                 i_flg_subtype => l_flg_subtype,
                                 i_notes_desc  => i_notes,
                                 i_notes_type  => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date     => g_sysdate,
                                 io_param      => io_param,
                                 o_track       => o_track,
                                 o_flg_status  => l_flg_status,
                                 o_error       => o_error);
    
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
                                              i_function    => 'SET_REF_DECLINE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_decline2;

    /**
    * Medical decline
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Decline reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-03-2011
    */
    FUNCTION set_ref_decline_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params      VARCHAR2(1000 CHAR);
        l_flg_subtype p1_tracking.flg_subtype%TYPE;
        l_flg_status  p1_external_request.flg_status%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_reason_code=' || i_reason_code || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_decline / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ----------------------              
        IF i_ref_row.flg_status = pk_ref_constant.g_p1_status_a
        THEN
            l_flg_subtype := pk_ref_constant.g_tracking_subtype_r; -- js, 2007-11-22: Marcar devolucoes de pedidos ja aceites 
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_prof_data   => i_prof_data,
                                 i_ref_row     => i_ref_row,
                                 i_action      => i_action,
                                 i_status_end  => i_status_end,
                                 i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                 i_reason_code => i_reason_code,
                                 i_flg_subtype => l_flg_subtype,
                                 i_notes_desc  => i_notes,
                                 i_notes_type  => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date     => g_sysdate,
                                 io_param      => io_param,
                                 o_track       => o_track,
                                 o_flg_status  => l_flg_status,
                                 o_error       => o_error);
    
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
                                              i_function    => 'SET_REF_DECLINE_CD',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_decline_cd;

    /**
    * Forwards referral
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   i_prof_dest      Professional id to which referral is being forwarded    
    * @param   i_subtype            
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_forward2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_prof_dest  IN professional.id_professional%TYPE,
        i_subtype    IN VARCHAR2,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params     VARCHAR2(1000 CHAR);
        l_flg_status p1_external_request.flg_status%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_prof_dest=' || i_prof_dest || ' i_subtype=' || i_subtype ||
                    ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_forward / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ---------------------- 
        -- FORWARD
        IF (i_prof_dest IS NULL)
        THEN
            RAISE g_exception;
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_prof_data    => i_prof_data,
                                 i_ref_row      => i_ref_row,
                                 i_action       => i_action,
                                 i_status_end   => i_status_end,
                                 i_flg_type     => pk_ref_constant.g_tracking_type_p,
                                 i_id_prof_dest => i_prof_dest,
                                 i_flg_subtype  => i_subtype,
                                 i_notes_desc   => i_notes,
                                 i_notes_type   => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date      => g_sysdate,
                                 io_param       => io_param,
                                 o_track        => o_track,
                                 o_flg_status   => l_flg_status,
                                 o_error        => o_error);
    
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
                                              i_function    => 'SET_REF_FORWARD',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_forward2;

    /**
    * Medical refuse
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Refuse reason code    
    * @param   i_subtype        
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_refuse2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_subtype     IN VARCHAR2,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params     VARCHAR2(1000 CHAR);
        l_flg_status p1_external_request.flg_status%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_reason_code=' || i_reason_code || ' i_subtype=' ||
                    i_subtype || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_refuse / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        -- i_subtype not null: recusa recebida por interface
        -- l_track_subtype nao nulo entao e':
        --    1. recusa por interface 
        --    2. remarcacao
        --    3. recusa ou devolucao de pedido ja aceite.
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_prof_data    => i_prof_data,
                                 i_ref_row      => i_ref_row,
                                 i_action       => i_action,
                                 i_status_end   => i_status_end,
                                 i_flg_type     => pk_ref_constant.g_tracking_type_s,
                                 i_reason_code  => i_reason_code,
                                 i_id_prof_dest => i_prof.id,
                                 i_flg_subtype  => i_subtype,
                                 i_notes_desc   => i_notes,
                                 i_notes_type   => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date      => g_sysdate,
                                 io_param       => io_param,
                                 o_track        => o_track,
                                 o_flg_status   => l_flg_status,
                                 o_error        => o_error);
    
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
                                              i_function    => 'SET_REF_REFUSE',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_refuse2;

    /**
    * Cancel referral
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   I_NOTES          Status change notes    
    * @param   I_REASON_CODE    Cancelation reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-06-2009
    */
    FUNCTION set_ref_cancel2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Image and Other exams
        CURSOR c_exam_req IS
            SELECT ROWID
              FROM exam_req_det
             WHERE id_exam_req_det IN (SELECT id_exam_req_det
                                         FROM p1_exr_exam
                                        WHERE id_external_request = i_ref_row.id_external_request
                                       UNION ALL
                                       SELECT id_exam_req_det
                                         FROM p1_exr_temp pt
                                        WHERE id_external_request = i_ref_row.id_external_request);
        l_exam_req_det_row exam_req_det%ROWTYPE;
    
        -- Analysis
        TYPE l_t_analysis_req_det_row IS TABLE OF analysis_req_det%ROWTYPE;
        l_analysis_req_det_rows l_t_analysis_req_det_row;
    
        l_rows_out table_varchar := table_varchar();
        l_rowids   table_varchar;
        l_where    VARCHAR2(4000);
    
        l_notes      p1_detail.text%TYPE;
        l_flg_status p1_external_request.flg_status%TYPE;
        l_params     VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_reason_code=' || i_reason_code || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_cancel / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ---------------------- 
        --IF i_reason_code IS NULL
        --THEN
        --    g_error := 'REASON CODE is null';
        --    RAISE g_exception;
        --END IF;
    
        IF i_prof_data.flg_category = pk_ref_constant.g_registrar
        THEN
            l_notes := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => 'REF_ADM_CANCEL_DETAIL') || chr(10) || i_notes;
        ELSE
            l_notes := i_notes;
        END IF;
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_prof_data   => i_prof_data,
                                 i_ref_row     => i_ref_row,
                                 i_action      => i_action,
                                 i_status_end  => i_status_end,
                                 i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                 i_reason_code => i_reason_code,
                                 i_notes_desc  => l_notes,
                                 i_notes_type  => pk_ref_constant.g_detail_type_ncan,
                                 i_op_date     => g_sysdate,
                                 io_param      => io_param,
                                 o_track       => o_track,
                                 o_flg_status  => l_flg_status,
                                 o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_ref_row.flg_type = pk_ref_constant.g_p1_type_a
        THEN
            g_error  := 'CALL TS_ANALYSIS_REQ_DET.UPD / ' || l_params;
            l_rowids := table_varchar();
            l_where  := 'id_analysis_req_det IN (SELECT id_analysis_req_det FROM p1_exr_analysis WHERE id_external_request = ' ||
                        i_ref_row.id_external_request ||
                        ' UNION ALL SELECT pt.id_analysis_req_det FROM p1_exr_temp pt WHERE pt.id_external_request = ' ||
                        i_ref_row.id_external_request || ')';
            ts_analysis_req_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                    flg_referral_nin => FALSE,
                                    where_in         => l_where,
                                    rows_out         => l_rowids);
        
            g_error := 'SELECT * BULK COLLECT INTO / ' || l_params;
            SELECT *
              BULK COLLECT
              INTO l_analysis_req_det_rows
              FROM analysis_req_det
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(l_rowids));
        
            g_error := 'FOR i IN 1 .. l_analysis_req_det_rows.count / ' || l_params;
            FOR i IN 1 .. l_analysis_req_det_rows.count
            LOOP
                g_error  := 'Call PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK / ID_ANALYSIS_REQ_DET=' || l_analysis_req_det_rows(i).id_analysis_req_det ||
                            ' / ' || l_params;
                g_retval := pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                       i_prof             => i_prof,
                                                                       i_patient          => NULL,
                                                                       i_episode          => i_ref_row.id_episode,
                                                                       i_analysis_req     => NULL,
                                                                       i_analysis_req_det => l_analysis_req_det_rows(i).id_analysis_req_det,
                                                                       o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END LOOP;
        
            g_error := 'CALL process_update / ' || l_params;
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'ANALYSIS_REQ_DET',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_REFERRAL'));
        
        ELSIF (i_ref_row.flg_type = pk_ref_constant.g_p1_type_i OR i_ref_row.flg_type = pk_ref_constant.g_p1_type_e)
        THEN
        
            FOR w IN c_exam_req
            LOOP
            
                g_error := 'select for update ' || pk_ref_constant.g_p1_type_i || ' / ' || l_params;
                SELECT *
                  INTO l_exam_req_det_row
                  FROM exam_req_det
                 WHERE ROWID = w.rowid
                   FOR UPDATE;
            
                g_error := 'Call ts_exam_req_det.upd / ' || pk_ref_constant.g_p1_type_i || ' / ' || l_params;
                ts_exam_req_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                    flg_referral_nin => FALSE,
                                    where_in         => 'ROWID = ''' || w.rowid || '''',
                                    rows_out         => l_rows_out);
            
                g_error  := 'Call PK_EXAMS_API_DB.SET_EXAM_GRID_TASK / ID_EXAM_REQ=' || l_exam_req_det_row.id_exam_req ||
                            ' ID_EXAM_REQ_DET=' || l_exam_req_det_row.id_exam_req_det || ' / ' || l_params;
                g_retval := pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => NULL,
                                                               i_episode      => i_ref_row.id_episode,
                                                               i_exam_req     => l_exam_req_det_row.id_exam_req,
                                                               i_exam_req_det => l_exam_req_det_row.id_exam_req_det,
                                                               o_error        => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END LOOP;
        
            g_error := 'CALL PROCESS_UPDATE / ' || l_params;
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        ELSIF i_ref_row.flg_type = pk_ref_constant.g_p1_type_p
        THEN
            g_error  := 'update interv_presc_det ' || pk_ref_constant.g_p1_type_p || ' / ' || l_params;
            l_rowids := table_varchar();
            l_where  := 'id_interv_presc_det IN (SELECT id_interv_presc_det FROM p1_exr_intervention WHERE id_external_request = ' ||
                        i_ref_row.id_external_request ||
                        ' UNION ALL SELECT id_interv_presc_det FROM p1_exr_temp pt WHERE id_external_request = ' ||
                        i_ref_row.id_external_request || ')';
            ts_interv_presc_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                    flg_referral_nin => FALSE,
                                    where_in         => l_where,
                                    rows_out         => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'INTERV_PRESC_DET',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_REFERRAL'));
        
        ELSIF i_ref_row.flg_type = pk_ref_constant.g_p1_type_f
        THEN
            g_error  := 'update rehab_presc ' || i_ref_row.flg_type || ' / ' || l_params;
            l_rowids := table_varchar();
            l_where  := 'id_rehab_presc IN (SELECT id_rehab_presc FROM p1_exr_intervention WHERE id_external_request = ' ||
                        i_ref_row.id_external_request ||
                        ' UNION ALL SELECT id_rehab_presc FROM p1_exr_temp pt WHERE id_external_request = ' ||
                        i_ref_row.id_external_request || ')';
        
            g_error := 'Call ts_rehab_presc.upd / ' || l_params;
            ts_rehab_presc.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                               flg_referral_nin => FALSE,
                               where_in         => l_where,
                               rows_out         => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'REHAB_PRESC',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_REFERRAL'));
        
        END IF;
    
        IF i_ref_row.id_episode IS NOT NULL
        THEN
            g_error  := 'CALL pk_visit.set_first_obs / ' || l_params;
            g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                               i_id_episode          => i_ref_row.id_episode,
                                               i_pat                 => i_ref_row.id_patient,
                                               i_prof                => i_prof,
                                               i_prof_cat_type       => NULL,
                                               i_dt_last_interaction => g_sysdate,
                                               i_dt_first_obs        => NULL,
                                               o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- set print list job as canceled (if exists in printing list)
            g_error  := 'Call pk_ref_ext_sys.set_print_jobs_cancel / ' || l_params;
            g_retval := pk_ref_ext_sys.set_print_jobs_cancel(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_patient => i_ref_row.id_patient,
                                                             i_id_episode => i_ref_row.id_episode,
                                                             i_id_ref     => i_ref_row.id_external_request,
                                                             o_error      => o_error);
        
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
                                              i_function    => 'SET_REF_CANCEL',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_cancel2;

    /**
    * Insert consultation doctor 
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_PROF_DATA        Profile_template, functionality, and category ids   
    * @param   I_REF_ROW          Referral info 
    * @param   I_ACTION           Action
    * @param   I_STATUS_END       End status
    * @param   I_DATE             Status change date      
    * @param   I_DIAGNOSIS        Selected diagnosis
    * @param   I_DIAG_DESC        Diagnosis description, when entered in text mode
    * @param   I_ANSWER           Observation, Therapy, Exam and Conclusion
    * @param   IO_PARAM           Parameters for framework workflows evaluation
    * @param   I_HEALTH_PROB      Select Health Problem 
    * @param   I_HEALTH_PROB_DESC Health Problem description, when entered in text mode        
    * @param   O_TRACK            Array of ID_TRACKING transitions
    * @param   O_ERROR            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-06-2009
    */
    FUNCTION set_ref_answer2
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        i_action           IN wf_workflow_action.internal_name%TYPE,
        i_status_end       IN p1_external_request.flg_status%TYPE,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        io_param           IN OUT NOCOPY table_varchar,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr_diagnosis p1_exr_diagnosis%ROWTYPE;
        l_detail        p1_detail%ROWTYPE;
        l_var           p1_detail.id_detail%TYPE;
        l_detail_type   p1_detail.flg_type%TYPE;
        l_count         NUMBER;
        l_flg_status    p1_external_request.flg_status%TYPE;
        l_params        VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' io_param=' || pk_utils.to_string(io_param) ||
                    ' i_diagnosis.count=' || i_diagnosis.count || ' i_answer.count=' || i_answer.count;
        g_error  := 'Init set_ref_answer /' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_data  => i_prof_data,
                                 i_ref_row    => i_ref_row,
                                 i_action     => i_action,
                                 i_status_end => i_status_end,
                                 i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                 i_op_date    => g_sysdate,
                                 io_param     => io_param,
                                 o_track      => o_track,
                                 o_flg_status => l_flg_status,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'UPDATE p1_exr_diagnosis / ' || l_params;
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE flg_type IN (pk_ref_constant.g_exr_diag_type_a, pk_ref_constant.g_exr_diag_type_r)
           AND id_external_request = i_ref_row.id_external_request
           AND id_professional = i_prof.id;
    
        -- inserting diagnosis
        l_count := 0;
        g_error := 'INSERT DIAGNOSIS  / ' || l_params;
        FOR i IN 1 .. i_diagnosis.count
        LOOP
            l_count                             := l_count + 1;
            l_exr_diagnosis.id_exr_diagnosis    := NULL;
            l_exr_diagnosis.id_external_request := i_ref_row.id_external_request;
            l_exr_diagnosis.id_diagnosis        := i_diagnosis(i);
            l_exr_diagnosis.dt_insert_tstz      := g_sysdate;
            l_exr_diagnosis.id_professional     := i_prof.id;
            l_exr_diagnosis.id_institution      := i_prof.institution;
            l_exr_diagnosis.flg_type            := pk_ref_constant.g_exr_diag_type_a;
            l_exr_diagnosis.flg_status          := pk_ref_constant.g_active;
            l_exr_diagnosis.desc_diagnosis      := i_diag_desc(i);
        
            g_error  := 'Call pk_ref_api.set_p1_exr_diagnosis / id_diagnosis=' || l_exr_diagnosis.id_diagnosis || ' / ' ||
                        l_params;
            g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_p1_exr_diagnosis    => l_exr_diagnosis,
                                                        o_id_p1_exr_diagnosis => l_var,
                                                        o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_exr_diagnosis := NULL;
        
        END LOOP;
    
        IF i_health_prob IS NOT NULL
        THEN
            g_error := 'INSERT DIAGNOSIS  I_HEALTH_PROB / ' || l_params;
            FOR i IN 1 .. i_health_prob.count
            LOOP
                l_count                             := l_count + 1;
                l_exr_diagnosis.id_exr_diagnosis    := NULL;
                l_exr_diagnosis.id_external_request := i_ref_row.id_external_request;
                l_exr_diagnosis.id_diagnosis        := i_health_prob(i);
                l_exr_diagnosis.dt_insert_tstz      := g_sysdate;
                l_exr_diagnosis.id_professional     := i_prof.id;
                l_exr_diagnosis.id_institution      := i_prof.institution;
                l_exr_diagnosis.flg_type            := pk_ref_constant.g_exr_diag_type_r;
                l_exr_diagnosis.flg_status          := pk_ref_constant.g_active;
                l_exr_diagnosis.desc_diagnosis      := i_health_prob_desc(i);
            
                g_error  := 'Call pk_ref_api.set_p1_exr_diagnosis / id_diagnosis=' || l_exr_diagnosis.id_diagnosis ||
                            ' / ' || l_params;
                g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_p1_exr_diagnosis    => l_exr_diagnosis,
                                                            o_id_p1_exr_diagnosis => l_var,
                                                            o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_exr_diagnosis := NULL;
            
            END LOOP;
        END IF;
    
        g_error := 'UPDATE p1_detail / ' || l_params;
        UPDATE p1_detail
           SET flg_status = pk_ref_constant.g_detail_status_o
         WHERE id_external_request = i_ref_row.id_external_request
           AND flg_status = pk_ref_constant.g_detail_status_a
           AND flg_type IN (pk_ref_constant.g_detail_type_a_obs,
                            pk_ref_constant.g_detail_type_a_ter,
                            pk_ref_constant.g_detail_type_a_exa,
                            pk_ref_constant.g_detail_type_a_con,
                            pk_ref_constant.g_detail_type_answ_evol,
                            pk_ref_constant.g_detail_type_dt_come_back)
           AND id_professional = i_prof.id;
    
        g_error := 'INSERT ANSWER / ' || l_params;
        FOR i IN 1 .. i_answer.count
        LOOP
            CASE i_answer(i) (1)
                WHEN pk_ref_constant.g_ref_answer_o THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_obs;
                WHEN pk_ref_constant.g_ref_answer_t THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_ter;
                WHEN pk_ref_constant.g_ref_answer_e THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_exa;
                WHEN pk_ref_constant.g_ref_answer_c THEN
                    l_detail_type := pk_ref_constant.g_detail_type_a_con;
                WHEN pk_ref_constant.g_ref_answer_ev THEN
                    --MX
                    l_detail_type := pk_ref_constant.g_detail_type_answ_evol;
                WHEN pk_ref_constant.g_ref_answer_dt_cb THEN
                    --MX
                    l_detail_type := pk_ref_constant.g_detail_type_dt_come_back;
                ELSE
                    l_detail_type := -1;
            END CASE;
        
            g_error := 'INSERT DETAIL / ' || l_params;
            IF i_answer(i) (2) IS NOT NULL
            THEN
                l_count := l_count + 1;
            
                l_detail.id_detail           := NULL;
                l_detail.id_external_request := i_ref_row.id_external_request;
                l_detail.text                := i_answer(i) (2);
                l_detail.dt_insert_tstz      := g_sysdate;
                l_detail.flg_type            := l_detail_type;
                l_detail.id_professional     := i_prof.id;
                l_detail.id_institution      := i_prof.institution;
                l_detail.id_tracking         := o_track(1); -- first iteration
                l_detail.flg_status          := pk_ref_constant.g_detail_status_a;
            
                g_error  := 'Call pk_ref_api.set_p1_detail / FLG_TYPE=' || l_detail.flg_type || ' / ' || l_params;
                g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_p1_detail => l_detail,
                                                     o_id_detail => l_var,
                                                     o_error     => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_detail := NULL;
            
            END IF;
        
        END LOOP;
    
        -- If empty l_count then there was no insert
        g_error := 'l_count=' || l_count || ' / ' || l_params;
        IF l_count > 0
        THEN
            NULL;
        ELSE
            pk_utils.undo_changes;
        END IF;
    
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
                                              i_function    => 'SET_REF_ANSWER',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_answer2;

    /**
    * Updates referral status to "N"
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_DCS            Department and service identifier (in case FLG_VISIBLE=Y)
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION set_ref_new2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_dcs        IN p1_external_request.id_dep_clin_serv%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params        VARCHAR2(1000 CHAR);
        l_id_inst_dest  p1_tracking.id_inst_dest%TYPE;
        l_id_speciality p1_tracking.id_speciality%TYPE;
        l_dcs           p1_external_request.id_dep_clin_serv%TYPE;
        l_dt_requested  p1_external_request.dt_requested%TYPE;
        l_flg_status    p1_external_request.flg_status%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_dcs=' || i_dcs || ' io_param=' ||
                    pk_utils.to_string(io_param);
    
        g_error := 'Init set_ref_new / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- FUNC
        ----------------------     
        g_error := 'io_param(g_idx_flg_status)=' || io_param(pk_ref_constant.g_idx_flg_status) || ' / ' || l_params;
        IF io_param(pk_ref_constant.g_idx_flg_status) = pk_ref_constant.g_p1_status_o
        THEN
        
            IF i_ref_row.id_inst_dest IS NULL
            THEN
                RAISE g_exception;
            END IF;
        
            -- JS: 2008-07-27: If the old status is O and the new is N then updates referral creation date
            l_dt_requested  := g_sysdate;
            l_id_speciality := i_ref_row.id_speciality;
            l_dcs           := i_dcs;
        
        END IF;
    
        l_id_inst_dest := i_ref_row.id_inst_dest;
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang          => i_lang,
                                 i_prof          => i_prof,
                                 i_prof_data     => i_prof_data,
                                 i_ref_row       => i_ref_row,
                                 i_action        => i_action,
                                 i_status_end    => i_status_end,
                                 i_flg_type      => pk_ref_constant.g_tracking_type_s,
                                 i_id_inst_dest  => l_id_inst_dest,
                                 i_id_speciality => l_id_speciality,
                                 i_dcs           => l_dcs,
                                 i_dt_requested  => l_dt_requested,
                                 i_op_date       => g_sysdate,
                                 io_param        => io_param,
                                 o_track         => o_track,
                                 o_flg_status    => l_flg_status,
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
                                              i_function    => 'SET_REF_NEW',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_new2;

    /**
    * Cancels a previous appointment
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_SCHEDULE       Schedule identifier   
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date      
    * @param   i_reason_code    Referral reason code            
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_cancel_sch2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_schedule    IN schedule.id_schedule%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_last IS
            SELECT t.id_prof_dest, t.id_dep_clin_serv, t.decision_urg_level, p.id_inst_dest
              FROM p1_tracking t
              JOIN p1_external_request p
                ON (t.id_external_request = p.id_external_request)
             WHERE t.id_external_request = i_ref_row.id_external_request
               AND t.flg_type = pk_ref_constant.g_tracking_type_s
               AND t.ext_req_status = pk_ref_constant.g_p1_status_a
             ORDER BY dt_tracking_tstz DESC;
    
        l_track_row      p1_tracking%ROWTYPE;
        l_last           c_last%ROWTYPE;
        l_module         sys_config.value%TYPE;
        l_flg_status_new p1_external_request.flg_status%TYPE;
        l_detail_tab     table_varchar;
        -- wf
        l_flg_available    VARCHAR2(1 CHAR);
        l_id_inst_dcs      institution.id_institution%TYPE;
        l_rowids           table_varchar;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_dt_create        p1_tracking.dt_create%TYPE;
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_schedule=' || i_schedule || ' i_reason_code=' ||
                    i_reason_code || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_cancel_sch / ' || l_params;
        reset_vars;
        l_dt_create     := pk_ref_utils.get_sysdate;
        g_sysdate       := nvl(i_date, l_dt_create);
        l_flg_available := pk_ref_constant.g_no;
        o_track         := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------  
        g_error  := 'Call pk_ref_utils.get_sys_config / SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module || ' / ' ||
                    l_params;
        l_module := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        ----------------------
        -- FUNC
        ----------------------  
        g_error := 'MODULE =' || l_module || ' / ' || l_params;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- CIRCLE UK: ALERT-27343                    
                g_error  := 'Call PK_REF_MODULE.set_ref_cancel_sch_circle / ' || l_params;
                g_retval := pk_ref_module.set_ref_cancel_sch_circle(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_ref_row        => i_ref_row,
                                                                    i_schedule       => i_schedule,
                                                                    o_flg_status_new => l_flg_status_new,
                                                                    o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- always cancels referral (has only one schedule)
                l_flg_status_new := pk_ref_constant.g_p1_status_a;
        END CASE;
    
        g_error := 'NEW FLG_STATUS=' || l_flg_status_new || ' / ' || l_params;
        IF l_flg_status_new IS NOT NULL
        THEN
        
            -- checking transition availability
            g_error  := 'Calling pk_workflow.check_transition / STATUS_END=' || l_flg_status_new || ' / ' || l_params;
            g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => nvl(i_ref_row.id_workflow,
                                                                                  pk_ref_constant.g_wf_pcc_hosp),
                                                     i_id_status_begin     => convert_status_n(i_ref_row.flg_status),
                                                     i_id_status_end       => convert_status_n(l_flg_status_new),
                                                     i_id_workflow_action  => pk_ref_constant.get_action_id(i_action),
                                                     i_id_category         => i_prof_data.id_category,
                                                     i_id_profile_template => i_prof_data.id_profile_template,
                                                     i_id_functionality    => i_prof_data.id_functionality,
                                                     i_param               => io_param,
                                                     o_flg_available       => l_flg_available,
                                                     o_error               => o_error);
        
            IF NOT g_retval
            THEN
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_yes
            THEN
            
                g_error := 'OPEN c_last / ' || l_params;
                OPEN c_last;
                FETCH c_last
                    INTO l_last;
                CLOSE c_last;
            
                -- check if dep_clin_serv belongs to referral dest institution
                g_error  := 'Call pk_ref_utils.get_institution / Last DCS=' || l_last.id_dep_clin_serv || ' / ' ||
                            l_params;
                g_retval := pk_ref_utils.get_institution(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_dcs            => l_last.id_dep_clin_serv,
                                                         o_id_institution => l_id_inst_dcs,
                                                         o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF l_id_inst_dcs != l_last.id_inst_dest
                THEN
                
                    g_error            := 'Call pk_api_ref_ws.get_flg_availability / ID_INST_ORIG=' ||
                                          i_ref_row.id_inst_orig || ' ID_INST_DEST=' || i_ref_row.id_inst_dest || ' / ' ||
                                          l_params;
                    l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => i_ref_row.id_workflow,
                                                                             i_id_inst_orig => i_ref_row.id_inst_orig,
                                                                             i_id_inst_dest => i_ref_row.id_inst_dest);
                
                    -- cannot change referral institution for internal and at hospital entrance referrals
                    IF l_flg_availability IN
                       (pk_ref_constant.g_flg_availability_i, pk_ref_constant.g_flg_availability_p)
                    THEN
                        g_error := 'Cannot change dep_clin_serv for this kind of referrals / ID_INST_ORIG=' ||
                                   i_ref_row.id_inst_orig || ' ID_INST_DEST=' || i_ref_row.id_inst_dest ||
                                   ' ID_DEP_CLIN_SERV_NEW=' || l_last.id_dep_clin_serv || ' ID_INST_DEST_NEW=' ||
                                   l_id_inst_dcs || ' / ' || l_params;
                        RAISE g_exception;
                    END IF;
                
                    -- change referral dest institution             
                    g_error := 'Call ts_p1_external_request.upd / ID_INST_DEST_OLD=' || l_last.id_inst_dest ||
                               ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' || l_last.id_dep_clin_serv ||
                               ' / ' || l_params;
                    ts_p1_external_request.upd(id_external_request_in => i_ref_row.id_external_request,
                                               id_inst_dest_in        => l_id_inst_dcs,
                                               rows_out               => l_rowids);
                
                    g_error := 'Process_update P1_EXTERNAL_REQUEST / ID_INST_DEST_OLD=' || l_last.id_inst_dest ||
                               ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' || l_last.id_dep_clin_serv ||
                               ' / ' || l_params;
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'P1_EXTERNAL_REQUEST',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END IF;
            
                g_error                         := 'l_track_row / ' || l_params;
                l_track_row.id_external_request := i_ref_row.id_external_request;
                l_track_row.id_dep_clin_serv    := l_last.id_dep_clin_serv;
                l_track_row.decision_urg_level  := l_last.decision_urg_level;
                l_track_row.flg_subtype         := pk_ref_constant.g_tracking_subtype_c;
                l_track_row.id_prof_dest        := l_last.id_prof_dest;
                l_track_row.ext_req_status      := l_flg_status_new;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := g_sysdate;
                l_track_row.dt_create           := l_dt_create;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(i_action);
                l_track_row.id_reason_code      := i_reason_code;
            
                g_error  := 'Calling update_status / ' || l_params;
                g_retval := update_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_track_row => l_track_row,
                                          io_param    => io_param,
                                          o_track     => o_track,
                                          o_error     => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF i_notes IS NOT NULL
                THEN
                    -- [id_detail|flg_type|text|flg|id_group]
                    g_error      := 'INIT detail / ' || l_params;
                    l_detail_tab := table_varchar(NULL,
                                                  pk_ref_constant.g_detail_type_ndec,
                                                  i_notes,
                                                  pk_ref_constant.g_detail_flg_i,
                                                  NULL);
                
                    g_error  := 'Call pk_ref_core.set_notes / ' || l_params;
                    g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                                       i_ext_req       => i_ref_row.id_external_request,
                                                       i_prof          => i_prof,
                                                       i_detail        => table_table_varchar(l_detail_tab),
                                                       i_ext_req_track => o_track(1), -- first iteration
                                                       o_error         => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            ELSE
                -- returns error, no transition available
                g_error      := 'No transition valid for action ' || i_action || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1008;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
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
                                              i_function    => 'SET_REF_CANCEL_SCH',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_cancel_sch2;

    /**
    * Changes referral status to "V". Means that the referral was approved by clinical director and needs informed consent.
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info     
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes   
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-01
    */
    FUNCTION set_ref_approved2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params           VARCHAR2(1000 CHAR);
        l_task_inf_consent p1_task.id_task%TYPE;
        l_flg_status       p1_external_request.flg_status%TYPE;
        l_p1_task_done     p1_task_done%ROWTYPE;
        l_id_task_done     p1_task_done.id_task_done%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' io_param=' || pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_approved / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------  
        g_error            := 'Call pk_ref_utils.get_sys_config / ID_SYS_CONFIG=' ||
                              pk_ref_constant.g_ref_task_inf_consent || ' / ' || l_params;
        l_task_inf_consent := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                    i_id_sys_config => pk_ref_constant.g_ref_task_inf_consent));
    
        ----------------------
        -- FUNC
        ----------------------  
    
        --  Register status change
        g_error  := 'Call set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_data  => i_prof_data,
                                 i_ref_row    => i_ref_row,
                                 i_action     => i_action,
                                 i_status_end => i_status_end,
                                 i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                 i_notes_desc => i_notes,
                                 i_notes_type => pk_ref_constant.g_detail_type_ndec,
                                 i_op_date    => g_sysdate,
                                 io_param     => io_param,
                                 o_track      => o_track,
                                 o_flg_status => l_flg_status,
                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- insert task l_task_inf_consent ("Anexar termo de responsabilidade")        
        g_error                            := 'Fill l_p1_task_done / ID_TASK=' || l_task_inf_consent || ' / ' ||
                                              l_params;
        l_p1_task_done.id_task             := l_task_inf_consent;
        l_p1_task_done.id_external_request := i_ref_row.id_external_request;
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
    
        g_error  := 'Calling PK_REF_API.set_p1_task_done / ' || l_params;
        g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_p1_task_done => l_p1_task_done,
                                                o_id_task_done => l_id_task_done,
                                                o_error        => o_error);
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
                                              i_function    => 'SET_REF_APPROVED',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_approved2;

    /**
    * Changes referral status to "F". Means that the Patient no show
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info     
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes   
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   2010-03-01
    */
    FUNCTION set_ref_noshow
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_flg_status_end p1_external_request.flg_status%TYPE;
        l_cancel_reason  cancel_reason.id_cancel_reason%TYPE;
        l_so_row         schedule_outp%ROWTYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------                                
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || 'ID_PROF_DATA=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status || ' WF=' ||
                    nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' i_action=' || i_action ||
                    ' i_status_end=' || i_status_end || ' i_reason_code=' || i_reason_code || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init set_ref_noshow / ' || l_params;
        reset_vars;
        g_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        g_error  := 'Calling set_ref_base / ' || l_params;
        g_retval := set_ref_base(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_prof_data   => i_prof_data,
                                 i_ref_row     => i_ref_row,
                                 i_action      => i_action,
                                 i_status_end  => i_status_end,
                                 i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                 i_reason_code => i_reason_code,
                                 i_notes_desc  => i_notes,
                                 i_notes_type  => pk_ref_constant.g_detail_type_miss,
                                 i_op_date     => g_sysdate,
                                 io_param      => io_param,
                                 o_track       => o_track,
                                 o_flg_status  => l_flg_status_end,
                                 o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'call pk_ref_core.get_no_show_id_reason / ' || l_params;
        g_retval := pk_ref_core.get_no_show_id_reason(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_p1_reason_code => i_reason_code,
                                                      o_value          => l_cancel_reason,
                                                      o_error          => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_transaction_id IS NOT NULL
        THEN
            g_error  := 'Call pk_schedule_api_upstream.set_patient_no_show / ' || l_params;
            g_retval := pk_schedule_api_upstream.set_patient_no_show(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_transaction_id   => i_transaction_id,
                                                                     i_id_schedule      => i_ref_row.id_schedule,
                                                                     i_id_patient       => i_ref_row.id_patient,
                                                                     i_id_cancel_reason => l_cancel_reason,
                                                                     i_notes            => i_notes,
                                                                     o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            g_error := 'SET_REF_NOSHOW - UPDATE SCH_GROUP NO-SHOW COLUMNS FOR i_id_patient=' ||
                       to_char(i_ref_row.id_patient) || ', id_schedule)=' || i_ref_row.id_schedule;
            ts_sch_group.upd(id_cancel_reason_in  => l_cancel_reason,
                             id_cancel_reason_nin => FALSE,
                             no_show_notes_in     => i_notes,
                             no_show_notes_nin    => FALSE,
                             where_in             => 'id_patient=' || to_char(i_ref_row.id_patient) ||
                                                     ' AND id_schedule=' || i_ref_row.id_schedule,
                             handle_error_in      => FALSE);
        
            -- actualiza schedule_outp.flg_state
            BEGIN
                l_so_row.id_schedule_outp := NULL;
                g_error                   := 'SET_REF_NOSHOW - GET ID_SCHEDULE_OUTP FOR id_schedule=' ||
                                             i_ref_row.id_schedule;
                SELECT id_schedule_outp
                  INTO l_so_row.id_schedule_outp
                  FROM schedule_outp so
                 WHERE so.id_schedule = i_ref_row.id_schedule
                   AND rownum = 1;
            
                g_error              := 'SET_REF_NOSHOW - UPDATE SCHEDULE_OUTP.FLG_STATE FOR id_schedule=' ||
                                        i_ref_row.id_schedule;
                l_so_row.id_schedule := i_ref_row.id_schedule;
                l_so_row.flg_state   := 'B';
                ts_schedule_outp.upd(rec_in => l_so_row, handle_error_in => FALSE);
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- nao encontrou registo na schedule_outp. Pode ser porque nao e' consulta 
            END;
        
        END IF;
    
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
                                              i_function    => 'SET_REF_NOSHOW',
                                              i_action_type => g_flg_action,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_ref_noshow;

    /**
    * Checks if funcionality is enabled
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_CONFIG         Configuration to be validated
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  'Y'- config is enabled, 'N' - otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-01-13
    */
    FUNCTION check_config_enabled
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_config IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_enabled VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------                                
        g_error := 'Init check_config_enabled / i_config=' || i_config;
        reset_vars;
    
        l_enabled := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => i_config);
    
        IF l_enabled IS NULL
           OR l_enabled = pk_ref_constant.g_no
        THEN
            -- this functionality is not enabled
            l_enabled := pk_ref_constant.g_no;
        ELSE
            -- this functionality is enabled
            l_enabled := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_enabled;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN pk_ref_constant.g_no;
    END check_config_enabled;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_rec_status            Status data       
    * @param   i_dt_status_tstz        Date of last status change
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-02-2013
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_rec_status     IN t_rec_wf_status_info,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(4000);
    BEGIN
        g_error := 'Init get_flash_status_info / icon=' || i_rec_status.icon || ' color=' || i_rec_status.color ||
                   ' rank=' || i_rec_status.rank || ' flg_update=' || i_rec_status.flg_update || ' i_dt_status_tstz=' ||
                   i_dt_status_tstz;
    
        l_result := get_flash_status_info(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_sts_icon       => i_rec_status.icon,
                                          i_sts_color      => i_rec_status.color,
                                          i_sts_rank       => i_rec_status.rank,
                                          i_sts_flg_update => i_rec_status.flg_update,
                                          i_dt_status_tstz => i_dt_status_tstz);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_flash_status_info / icon=' || i_rec_status.icon || ' color=' || i_rec_status.color ||
                       ' rank=' || i_rec_status.rank || ' flg_update=' || i_rec_status.flg_update ||
                       ' i_dt_status_tstz=' || i_dt_status_tstz || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flash_status_info;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_sts_icon              Status icon    
    * @param   i_sts_color             Status color
    * @param   i_sts_rank              Status rank
    * @param   i_sts_flg_update        Flag indicating if the referral can be update in this status       
    * @param   i_dt_status_tstz        Date of last status change
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-08-2009
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sts_icon       IN wf_status.icon%TYPE,
        i_sts_color      IN wf_status.color%TYPE,
        i_sts_rank       IN wf_status.rank%TYPE,
        i_sts_flg_update IN wf_status_config.flg_update%TYPE,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_result       VARCHAR2(4000);
        l_flg_editable VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'Init get_flash_status_info / i_sts_icon=' || i_sts_icon || ' i_sts_color=' || i_sts_color ||
                   ' i_sts_rank=' || i_sts_rank || ' i_sts_flg_update=' || i_sts_flg_update || ' i_dt_status_tstz=' ||
                   i_dt_status_tstz;
        IF i_sts_flg_update = pk_ref_constant.g_na
        THEN
            l_flg_editable := pk_ref_constant.g_no;
        ELSE
            l_flg_editable := i_sts_flg_update;
        END IF;
    
        -- l_result has the following format: icon|color|rank|flg_editable|order_by_field            
        l_result := i_sts_icon || '|' || i_sts_color || '|' || lpad(i_sts_rank, 6, '0') || '|' || l_flg_editable;
        -- order by field
        l_result := l_result || '|' || get_flash_status_order(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_color          => i_sts_color,
                                                              i_rank           => i_sts_rank,
                                                              i_dt_status_tstz => i_dt_status_tstz);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_flash_status_info / i_sts_icon=' || i_sts_icon || ' i_sts_color=' || i_sts_color ||
                       ' i_sts_rank=' || i_sts_rank || ' i_sts_flg_update=' || i_sts_flg_update || ' i_dt_status_tstz=' ||
                       i_dt_status_tstz || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flash_status_info;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_ext_req               Referral identifier    
    * @param   i_id_prof_templ         Professional profile_template identifier
    * @param   i_id_category           Professional category identifier
    * @param   i_id_func               Professional functionality identifier       
    * @param   i_workflow              Referral workflow
    * @param   i_flg_status            Referral status       
    * @param   i_dt_status_tstz        Last status change date   
    * @param   i_location              Referral location
    * @param   i_id_patient            Referral patient identifier
    * @param   i_id_inst_orig          Referral institution origin
    * @param   i_id_inst_dest          Referral institution dest
    * @param   i_id_dep_clin_serv      Referral dep_clin_serv
    * @param   i_decision_urg_level    Decision urgency level assigned when triaging referral
    * @param   i_id_prof_requested     Professional that requested referral   
    * @param   i_id_prof_redirected    Professional to whom the referral was forwarded to
    * @param   i_id_speciality         Referral specialty
    * @param   i_flg_type              Referral type
    * @param   i_id_prof_status        Professional that changed the referral status
    * @param   i_external_sys          External system that created the referral
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-08-2009
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_prof_templ  IN profile_template.id_profile_template%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_func        IN sys_functionality.id_functionality%TYPE,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_flg_status     IN p1_external_request.flg_status%TYPE,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE,
        -- workflow data
        i_location           IN VARCHAR2 DEFAULT pk_ref_constant.g_location_detail,
        i_id_patient         IN p1_external_request.id_patient%TYPE DEFAULT NULL,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE DEFAULT NULL,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE DEFAULT NULL,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE DEFAULT NULL,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE DEFAULT NULL,
        i_flg_type           IN p1_external_request.flg_type%TYPE DEFAULT NULL,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE DEFAULT NULL,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_status_info t_rec_wf_status_info;
        l_error       t_error_out;
        l_param       table_varchar;
        l_result      VARCHAR2(4000);
        l_workflow    p1_external_request.id_workflow%TYPE;
    BEGIN
        g_error    := 'Init get_flash_status_info / ID_REF=' || i_ext_req || ' WF=' || i_workflow || ' FLG_STATUS=' ||
                      i_flg_status || ' ID_CAT=' || i_id_category || ' PROF_TEMPL=' || i_id_prof_templ || ' ID_FUNC=' ||
                      i_id_func;
        l_workflow := nvl(i_workflow, pk_ref_constant.g_wf_pcc_hosp);
    
        g_error := 'Call init_param_tab / ID_REF=' || i_ext_req;
        l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_ext_req            => i_ext_req,
                                              i_id_patient         => i_id_patient,
                                              i_id_inst_orig       => i_id_inst_orig,
                                              i_id_inst_dest       => i_id_inst_dest,
                                              i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                              i_id_speciality      => i_id_speciality,
                                              i_flg_type           => i_flg_type,
                                              i_decision_urg_level => i_decision_urg_level,
                                              i_id_prof_requested  => i_id_prof_requested,
                                              i_id_prof_redirected => i_id_prof_redirected,
                                              i_id_prof_status     => i_id_prof_status,
                                              i_external_sys       => i_external_sys,
                                              i_location           => i_location,
                                              i_flg_status         => i_flg_status);
    
        g_error  := 'Call pk_workflow.get_status_info / ID_REF=' || i_ext_req || ' ID_WF=' || l_workflow ||
                    ' FLG_STATUS=' || i_flg_status || ' ID_CAT=' || i_id_category || ' PROF_TEMPL=' || i_id_prof_templ ||
                    ' ID_FUNC=' || i_id_func || ' I_PARAM=' || pk_utils.to_string(l_param);
        g_retval := pk_workflow.get_status_info(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_workflow,
                                                i_id_status           => convert_status_n(i_flg_status),
                                                i_id_category         => i_id_category,
                                                i_id_profile_template => i_id_prof_templ,
                                                i_id_functionality    => i_id_func,
                                                i_param               => l_param,
                                                o_status_info         => l_status_info,
                                                o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RETURN NULL;
        END IF;
    
        g_error  := 'Call get_flash_status_info / i_sts_icon=' || l_status_info.icon || ' i_sts_color=' ||
                    l_status_info.color || ' i_sts_rank=' || l_status_info.rank || ' i_sts_flg_update=' ||
                    l_status_info.flg_update;
        l_result := get_flash_status_info(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_sts_icon       => l_status_info.icon,
                                          i_sts_color      => l_status_info.color,
                                          i_sts_rank       => l_status_info.rank,
                                          i_sts_flg_update => l_status_info.flg_update,
                                          i_dt_status_tstz => i_dt_status_tstz);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_flash_status_info / ' || 'ID_EXT_REQ=' || i_ext_req || '|WF=' || l_workflow ||
                       '|FLG_STATUS=' || i_flg_status || '|ID_CAT=' || i_id_category || '|PRF_TEMPL=' ||
                       i_id_prof_templ || '|FUNC=' || i_id_func || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flash_status_info;

    /**
    * Function used in grids to return status sort column 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_color                 Color icon
    * @param   i_rank                  Rank icon
    * @param   i_dt_status_tstz        Last status date
    *
    * @RETURN  Status sort column 
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   05-04-2011
    */
    FUNCTION get_flash_status_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_color          IN VARCHAR2,
        i_rank           IN VARCHAR2,
        i_dt_status_tstz IN referral_ea.dt_status%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1000 CHAR);
    
        -- returns 0 if color is red, 1 otherwise
        FUNCTION get_color_number(x_color IN wf_status.color%TYPE) RETURN NUMBER IS
        BEGIN
            CASE
                WHEN x_color IN (pk_ref_constant.g_icon_color_red, pk_ref_constant.g_icon_color_red2) THEN
                    RETURN 0;
                ELSE
                    RETURN 1;
            END CASE;
        END get_color_number;
    
    BEGIN
        g_error := 'Init get_flash_status_order / i_color=' || i_color || ' i_rank=' || i_rank;
    
        -- l_result has the following format: <number>|<rank>|<dt_status_tstz>        
        -- and <number> is: 0- if icon color is red; 1- otherwise
        IF i_rank IS NOT NULL
           AND i_color IS NOT NULL
        THEN
            l_result := get_color_number(i_color) || '|' || lpad(i_rank, 6, '0') || '|' ||
                        pk_date_utils.date_send_tsz(i_lang, i_dt_status_tstz, i_prof); -- order by field                 
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flash_status_order;

    /**
    * Function used in grids to return status sort column 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_rec_status            Status data
    * @param   i_dt_status_tstz        Last status date
    *
    * @RETURN  Status sort column 
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   21-02-2013
    */
    FUNCTION get_flash_status_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_rec_status     IN t_rec_wf_status_info,
        i_dt_status_tstz IN referral_ea.dt_status%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1000 CHAR);
    BEGIN
        g_error  := 'Init get_flash_status_order / id_status=' || i_rec_status.id_status || ' i_color=' ||
                    i_rec_status.color || ' i_rank=' || i_rec_status.rank;
        l_result := get_flash_status_order(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_color          => i_rec_status.color,
                                           i_rank           => i_rec_status.rank,
                                           i_dt_status_tstz => i_dt_status_tstz);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flash_status_order;

    /**
    * Gets status configuration depending on software, institution, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids   
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identification        
    * @param   i_func               Functionality identification
    * @param   i_status_info        Status information configured in table WF_STATUS_CONFIG
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  status info
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_wf_status_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_category    IN wf_status_config.id_category%TYPE,
        i_profile     IN wf_status_config.id_profile_template%TYPE,
        i_func        IN wf_status_config.id_functionality%TYPE,
        i_status_info IN t_rec_wf_status_info,
        i_param       IN table_varchar
    ) RETURN t_rec_wf_status_info IS
        l_rec_wf_status_info t_rec_wf_status_info := t_rec_wf_status_info();
        l_flg_status_v       p1_external_request.flg_status%TYPE;
    
        l_id_ref             p1_external_request.id_external_request%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_dcs             p1_external_request.id_dep_clin_serv%TYPE;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_flg_type           p1_external_request.flg_type%TYPE;
        l_dec_urg_level      p1_external_request.decision_urg_level%TYPE;
        l_id_prof_requested  p1_external_request.id_prof_requested%TYPE;
        l_id_prof_redirected p1_external_request.id_prof_redirected%TYPE;
        l_id_prof_status     p1_external_request.id_prof_status%TYPE;
        l_id_external_sys    p1_external_request.id_external_sys%TYPE;
        l_location           VARCHAR2(1 CHAR);
        l_flg_completed      VARCHAR2(1 CHAR);
        l_id_action          wf_workflow_action.id_workflow_action%TYPE;
        l_flg_prof_dcs       VARCHAR2(1 CHAR);
        l_prof_clin_dir      VARCHAR2(1 CHAR);
        l_config             VARCHAR2(1 CHAR);
    
        l_error  t_error_out;
        l_params VARCHAR2(1000 CHAR);
    
        l_wf_ref_med sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'REFERRAL_WF_MED', i_prof => i_prof);
    BEGIN
        -- NOTE: professional data cannot be validated with SELECTs... must be validated by input parameter (because of get_status_string_ea)
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' CAT=' || i_category || ' PRF=' || i_profile ||
                    ' FUNC=' || i_func || ' i_param=' || pk_utils.to_string(i_param);
        g_error  := 'Init get_wf_status_info / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- converting status to varchar
        g_error        := 'Calling convert_status_v / ' || l_params;
        l_flg_status_v := convert_status_v(i_status => i_status_info.id_status);
    
        g_error  := 'Call get_param_values / ' || l_params;
        g_retval := get_param_values(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_param              => i_param,
                                     o_id_ref             => l_id_ref,
                                     o_id_patient         => l_id_patient,
                                     o_id_inst_orig       => l_id_inst_orig,
                                     o_id_inst_dest       => l_id_inst_dest,
                                     o_id_dcs             => l_id_dcs,
                                     o_id_speciality      => l_id_speciality,
                                     o_flg_type           => l_flg_type,
                                     o_dec_urg_level      => l_dec_urg_level,
                                     o_id_prof_requested  => l_id_prof_requested,
                                     o_id_prof_redirected => l_id_prof_redirected,
                                     o_id_prof_status     => l_id_prof_status,
                                     o_id_external_sys    => l_id_external_sys,
                                     o_location           => l_location,
                                     o_flg_completed      => l_flg_completed,
                                     o_id_action          => l_id_action,
                                     o_flg_prof_dcs       => l_flg_prof_dcs,
                                     o_prof_clin_dir      => l_prof_clin_dir,
                                     o_error              => l_error);
    
        l_params := l_params || ' ID_REF=' || l_id_ref || ' ID_PAT=' || l_id_patient || ' ID_INST_ORIG=' ||
                    l_id_inst_orig || ' ID_INST_DEST=' || l_id_inst_dest || ' ID_DCS=' || l_id_dcs || ' ID_SPEC=' ||
                    l_id_speciality;
    
        -- assigning default values (from table WF_STATUS_CONFIG)
        g_error              := 'I_STATUS_INFO / ' || l_params;
        l_rec_wf_status_info := i_status_info;
    
        g_error := 'CASE / ' || l_params;
        CASE
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_o THEN
                ---------------------------
                -- (O)Being created
                ---------------------------
                IF i_prof.id = l_id_prof_requested
                   AND (l_id_inst_orig = i_prof.institution OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp)
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                    l_rec_wf_status_info.flg_read   := pk_ref_constant.g_yes;
                ELSE
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                    l_rec_wf_status_info.flg_read   := pk_ref_constant.g_no;
                END IF;
            
            WHEN l_flg_status_v IN (pk_ref_constant.g_p1_status_j, pk_ref_constant.g_p1_status_v) THEN
            
                ---------------------------
                -- (J) For approval by clinical director
                ---------------------------
            
                IF l_prof_clin_dir IS NOT NULL
                   AND l_prof_clin_dir = pk_ref_constant.g_yes
                THEN
                    -- this is because of easy access calculation
                    g_retval := TRUE;
                ELSE
                    g_retval := pk_ref_core.is_clinical_director(i_lang => i_lang, i_prof => i_prof);
                END IF;
            
                g_error := 'l_prof_clin_dir=' || l_prof_clin_dir || ' l_flg_status_v=' || l_flg_status_v ||
                           ' l_id_prof_requested=' || l_id_prof_requested || ' l_id_inst_orig=' || l_id_inst_orig ||
                           ' i_prof.institution=' || i_prof.institution;
                IF (g_retval AND l_flg_status_v = pk_ref_constant.g_p1_status_j)
                THEN
                    l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                END IF;
            
                -- referral can be edited by the professional that requested it only if is in origin institution (except for WF=4)
                IF i_prof.id = l_id_prof_requested
                   AND l_id_inst_orig = i_prof.institution
                -- OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp) - this status does not exist in this wf
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                END IF;
            
            WHEN l_flg_status_v IN (pk_ref_constant.g_p1_status_n, pk_ref_constant.g_p1_status_b) THEN
            
                ---------------------------
                -- (N)ew / (B)ureaucratic decline
                ---------------------------                                          
            
                IF i_status_info.id_workflow = pk_ref_constant.g_wf_srv_srv
                THEN
                
                    ---------------------------
                    -- WORKFLOW=3
                    ---------------------------
                
                    -- default value
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                
                    IF (i_profile = pk_ref_constant.g_profile_adm_hs OR i_profile = pk_ref_constant.g_profile_adm_hs_cl)
                    THEN
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                        l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                    END IF;
                
                    IF i_prof.id = l_id_prof_requested
                       AND l_id_inst_orig = i_prof.institution
                    THEN
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                    END IF;
                
                ELSIF i_status_info.id_workflow IN
                      (pk_ref_constant.g_wf_pcc_hosp, pk_ref_constant.g_wf_hosp_hosp, pk_ref_constant.g_wf_fertis)
                THEN
                
                    ---------------------------
                    -- WORKFLOW in (1,2,8)
                    ---------------------------
                
                    CASE
                        WHEN i_profile IN (pk_ref_constant.g_profile_adm_hs,
                                           pk_ref_constant.g_profile_adm_hs_cl,
                                           pk_ref_constant.g_profile_adm_cs,
                                           pk_ref_constant.g_profile_adm_cs_cl)
                             AND i_prof.institution = l_id_inst_orig THEN
                            -- registrar from referral origin institution
                        
                            l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                            l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                        
                    --WHEN i_profile = pk_ref_constant.g_profile_adm_hs_cl
                    --    AND i_prof.institution = l_id_inst_orig THEN
                    --   -- registrar from referral origin institution
                    
                    --   l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                    --   l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                    
                        WHEN i_profile IN (pk_ref_constant.g_profile_adm_hs, pk_ref_constant.g_profile_adm_hs_cl)
                             AND i_prof.institution = l_id_inst_dest THEN
                            -- registrar from referral dest institution
                            NULL; -- default values configured in table
                    
                    --WHEN i_profile = pk_ref_constant.g_profile_adm_hs_cl
                    -- AND i_prof.institution = l_id_inst_dest THEN
                    ---- registrar from referral dest institution
                    --NULL; -- default values configured in table
                    
                        ELSE
                            g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
                            IF l_id_prof_requested = i_prof.id
                               AND l_id_inst_orig = i_prof.institution
                            THEN
                                l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                            ELSE
                                -- default value
                                l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                            END IF;
                        
                    END CASE;
                
                    --  pk_ref_constant.g_wf_x_hosp has no function             
                
                END IF;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_i THEN
            
                ---------------------------
                -- Issued
                ---------------------------                          
            
                g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
                IF i_status_info.id_workflow = pk_ref_constant.g_wf_srv_srv
                THEN
                
                    ---------------------------
                    -- WORKFLOW=3
                    ---------------------------
                    l_rec_wf_status_info.icon := pk_ref_constant.g_icon_received;
                
                    IF (i_profile = pk_ref_constant.g_profile_adm_hs OR i_profile = pk_ref_constant.g_profile_adm_hs_cl)
                    THEN
                    
                        -- validating dep_clin_serv
                        g_error := 'Calling pk_ref_dest_reg.validate_dcs / l_flg_prof_dcs=' || l_flg_prof_dcs || ' / ' ||
                                   l_params;
                        IF nvl(l_flg_prof_dcs, pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs)) =
                           pk_ref_constant.g_yes
                        THEN
                            l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                            l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                        ELSE
                            l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                        END IF;
                    
                    ELSIF (i_profile = pk_ref_constant.g_profile_med_hs OR
                          i_profile = pk_ref_constant.g_profile_med_hs_cl)
                    THEN
                    
                        g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
                        IF l_id_prof_requested = i_prof.id
                           AND l_id_inst_orig = i_prof.institution
                        THEN
                            l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                        ELSE
                            -- default value
                            l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                        END IF;
                    END IF;
                
                ELSIF i_status_info.id_workflow IN (pk_ref_constant.g_wf_pcc_hosp,
                                                    pk_ref_constant.g_wf_hosp_hosp,
                                                    pk_ref_constant.g_wf_x_hosp,
                                                    pk_ref_constant.g_wf_fertis)
                THEN
                
                    ---------------------------
                    -- WORKFLOW in (1,2,4,8)
                    ---------------------------                   
                
                    CASE
                        WHEN i_profile IN (pk_ref_constant.g_profile_adm_hs, pk_ref_constant.g_profile_adm_hs_cl)
                             AND i_prof.institution = l_id_inst_dest THEN
                            -- registrar from referral dest institution
                            -- validating dep_clin_serv
                            g_error := 'Calling pk_ref_dest_reg.validate_dcs / l_flg_prof_dcs=' || l_flg_prof_dcs ||
                                       ' / ' || l_params;
                            IF nvl(l_flg_prof_dcs, pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs)) =
                               pk_ref_constant.g_yes
                            THEN
                                l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                                l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                            ELSE
                                l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                            END IF;
                        
                        WHEN i_profile IN (pk_ref_constant.g_profile_adm_hs, pk_ref_constant.g_profile_adm_hs_cl)
                             AND i_prof.institution = l_id_inst_orig THEN
                            -- registrar from referral origin institution
                            NULL; -- default values configured in table
                    
                        ELSE
                            NULL;
                    END CASE;
                
                    g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
                    IF l_id_prof_requested = i_prof.id
                       AND
                       (l_id_inst_orig = i_prof.institution OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp)
                    THEN
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                    ELSE
                        -- default value
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                    END IF;
                
                    g_error := 'icon ' || l_flg_status_v || ' / ' || l_params;
                    IF l_id_inst_dest = i_prof.institution
                    THEN
                        l_rec_wf_status_info.icon := pk_ref_constant.g_icon_received;
                    ELSE
                        -- default value
                        l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sent;
                    END IF;
                
                END IF;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_t THEN
            
                ---------------------------
                -- (T)riage
                ---------------------------               
            
                g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
            
                IF (i_profile = pk_ref_constant.g_profile_med_hs OR i_profile = pk_ref_constant.g_profile_med_hs_cl)
                   AND i_prof.institution = l_id_inst_dest
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                
                    -- checking dep_clin_serv and functionality (do ***not call*** pk_ref_dest_phy.validate_dcs_func)
                    IF i_func = pk_ref_constant.g_func_d
                    THEN
                        -- Triage physician (speciality) or clinical director
                        l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                    
                    ELSIF i_func = pk_ref_constant.g_func_t
                          AND l_id_prof_redirected = i_prof.id
                    THEN
                        -- Triage physician professional to which the Referral was forwarded 
                        l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                    ELSE
                        l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_def;
                    END IF;
                END IF;
            
                IF l_id_prof_requested = i_prof.id
                   AND (l_id_inst_orig = i_prof.institution OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp)
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                ELSE
                    -- default value
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                END IF;
            
            WHEN l_flg_status_v IN (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_y) THEN
            
                ---------------------------
                -- (D)eclined Triage (Y)Declined CD
                ---------------------------
            
                g_error := 'flg_update|color ' || l_flg_status_v || ' l_flg_prof_dcs=' || l_flg_prof_dcs || ' / ' ||
                           l_params;
                IF i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp
                THEN
                    -- at hospital entrance workflow
                    IF l_id_inst_dest = i_prof.institution
                       AND (l_id_prof_requested = i_prof.id OR
                       (nvl(l_flg_prof_dcs, pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs)) =
                       pk_ref_constant.g_yes))
                    THEN
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                        l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                        pk_alertlog.log_info('l_rec_wf_status_info.flg_update' || pk_ref_constant.g_yes);
                    ELSE
                        -- default value
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                        pk_alertlog.log_info('l_rec_wf_status_info.flg_update' || pk_ref_constant.g_no);
                    END IF;
                
                ELSE
                    -- all other workflows
                    IF l_id_prof_requested = i_prof.id
                       AND l_id_inst_orig = i_prof.institution
                    THEN
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                        l_rec_wf_status_info.color      := pk_ref_constant.g_icon_color_red;
                    ELSE
                        -- default value
                        l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                    END IF;
                
                END IF;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_r THEN
            
                ---------------------------
                -- (R)esent
                ---------------------------
            
                g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params;
                IF (i_profile = pk_ref_constant.g_profile_med_hs OR i_profile = pk_ref_constant.g_profile_med_hs_cl)
                   AND i_prof.institution = l_id_inst_dest
                THEN
                
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                
                    -- checking referral prof redirected
                    BEGIN
                        SELECT i.id_prof_dest
                          INTO l_id_prof_redirected
                          FROM (SELECT t.id_prof_dest
                                  FROM p1_tracking t
                                 WHERE t.ext_req_status = pk_ref_constant.g_p1_status_r
                                   AND t.flg_type IN
                                       (pk_ref_constant.g_tracking_type_c, pk_ref_constant.g_tracking_type_p)
                                   AND t.id_external_request = l_id_ref
                                 ORDER BY dt_tracking_tstz DESC) i
                         WHERE rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_prof_redirected := NULL;
                    END;
                
                    g_error := 'ID_PROF_REDIRECTED=' || l_id_prof_redirected || ' / ' || l_params;
                    IF i_prof.id = l_id_prof_redirected
                    THEN
                        -- resent to professional
                        l_rec_wf_status_info.icon  := pk_ref_constant.g_icon_triage_received;
                        l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                    
                    ELSE
                        -- resent to another professional
                        l_rec_wf_status_info.icon  := pk_ref_constant.g_icon_triage_sent;
                        l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_def;
                    END IF;
                
                END IF;
            
                IF l_id_prof_requested = i_prof.id
                   AND (l_id_inst_orig = i_prof.institution OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp)
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                END IF;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_a THEN
            
                ---------------------------
                -- (A)ccepted
                ---------------------------
            
                -- getting config
                g_error  := 'Call check_config_enabled / ' || l_params || ' / CONFIG=' ||
                            pk_ref_constant.g_ref_upd_sts_a_enabled;
                l_config := check_config_enabled(i_lang   => i_lang,
                                                 i_prof   => i_prof,
                                                 i_config => pk_ref_constant.g_ref_upd_sts_a_enabled);
            
                -- setting rank
                g_error                   := 'RANK / ' || l_params;
                l_rec_wf_status_info.rank := l_rec_wf_status_info.rank + l_dec_urg_level;
            
                -- setting flg_update
                g_error := 'flg_update ' || l_flg_status_v || ' / ' || l_params || ' PROF_REQUESTED=' ||
                           l_id_prof_requested || ' l_config=' || l_config;
                IF i_prof.id = l_id_prof_requested
                   AND (l_id_inst_orig = i_prof.institution OR i_status_info.id_workflow = pk_ref_constant.g_wf_x_hosp)
                   AND l_config = pk_ref_constant.g_yes -- ALERT-237656
                THEN
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_yes;
                ELSE
                    l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
                END IF;
            
                g_error := 'CASE l_dec_urg_level ' || l_dec_urg_level || ' / ' || l_params;
                CASE l_dec_urg_level
                
                    WHEN pk_ref_constant.g_decision_urg_level_normal THEN
                    
                        IF (i_profile IN (pk_ref_constant.g_profile_adm_hs, pk_ref_constant.g_profile_adm_hs_cl) OR
                           i_category = pk_ref_constant.g_cat_id_adm OR
                           (i_profile = pk_ref_constant.g_profile_med_hs AND l_wf_ref_med = pk_alert_constant.g_yes)) -- this is because of ALERT-854 (registrar can schedule a referral in another software other than referral)
                           AND
                           i_profile NOT IN (pk_ref_constant.g_profile_adm_hs_vo, pk_ref_constant.g_profile_adm_cs_vo)
                           AND l_id_inst_dest = i_prof.institution
                        THEN
                            -- grid or other: white icon for g_profile_adm_hs
                            l_rec_wf_status_info.icon  := pk_ref_constant.g_icon_sch_new_w;
                            l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                        ELSE
                            -- icon for other profiles
                            -- detail: beige icon | other: dark icon
                            IF l_location = pk_ref_constant.g_location_detail
                            THEN
                                -- beige icon for detail
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_new_b;
                            ELSE
                                -- dark icon for other
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_new;
                            END IF;
                        
                        END IF;
                    
                    WHEN pk_ref_constant.g_decision_urg_level_pri THEN
                    
                        IF (i_profile = pk_ref_constant.g_profile_adm_hs OR
                           i_profile = pk_ref_constant.g_profile_adm_hs_cl OR
                           i_category = pk_ref_constant.g_cat_id_adm OR
                           (i_profile = pk_ref_constant.g_profile_med_hs AND l_wf_ref_med = pk_alert_constant.g_yes)) -- this is because of ALERT-854 (registrar can schedule a referral in another software other than referral)
                           AND
                           i_profile NOT IN (pk_ref_constant.g_profile_adm_hs_vo, pk_ref_constant.g_profile_adm_cs_vo)
                           AND l_id_inst_dest = i_prof.institution
                        THEN
                            -- grid or other: white icon for g_profile_adm_hs
                            l_rec_wf_status_info.icon  := pk_ref_constant.g_icon_sch_pri_w;
                            l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                        ELSE
                        
                            -- icon for other profiles
                            -- detail: beige icon | other: dark icon
                            IF l_location = pk_ref_constant.g_location_detail
                            THEN
                                -- beige icon for detail
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_pri_b;
                            ELSE
                                -- dark icon for other
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_pri;
                            END IF;
                        
                        END IF;
                    
                    WHEN pk_ref_constant.g_decision_urg_level_v_pri THEN
                    
                        IF (i_profile = pk_ref_constant.g_profile_adm_hs OR
                           i_profile = pk_ref_constant.g_profile_adm_hs_cl OR
                           i_category = pk_ref_constant.g_cat_id_adm OR
                           (i_profile = pk_ref_constant.g_profile_med_hs AND l_wf_ref_med = pk_alert_constant.g_yes)) -- this is because of ALERT-854 (registrar can schedule a referral in another software other than referral)
                           AND
                           i_profile NOT IN (pk_ref_constant.g_profile_adm_hs_vo, pk_ref_constant.g_profile_adm_cs_vo)
                           AND l_id_inst_dest = i_prof.institution
                        THEN
                            -- grid or other: white icon for g_profile_adm_hs
                            l_rec_wf_status_info.icon  := pk_ref_constant.g_icon_sch_very_pri_b;
                            l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                        ELSE
                        
                            -- icon for other profiles
                            -- detail: beige icon | other: dark icon
                            IF l_location = pk_ref_constant.g_location_detail
                            THEN
                                -- beige icon for detail
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_very_pri_b;
                            ELSE
                                -- dark icon for other
                                l_rec_wf_status_info.icon := pk_ref_constant.g_icon_sch_very_pri;
                            END IF;
                        END IF;
                    
                    ELSE
                        g_error := 'CASE NOT FOUND / ' || l_params;
                        RAISE g_exception;
                END CASE;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_s THEN
                ---------------------------
                -- (S)cheduled
                ---------------------------  
            
                l_rec_wf_status_info.flg_update := pk_ref_constant.g_no;
            
                IF i_status_info.id_workflow = pk_ref_constant.g_wf_srv_srv
                THEN
                
                    ---------------------------
                    -- WORKFLOW=3
                    ---------------------------                
                    IF (i_profile = pk_ref_constant.g_profile_adm_hs OR i_profile = pk_ref_constant.g_profile_adm_hs_cl)
                    THEN
                        -- validating dep_clin_serv
                        g_error := 'Calling pk_ref_dest_reg.validate_dcs / l_flg_prof_dcs=' || l_flg_prof_dcs || ' / ' ||
                                   l_params;
                        IF nvl(l_flg_prof_dcs, pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs)) =
                           pk_ref_constant.g_yes
                        THEN
                            l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                        END IF;
                    END IF;
                
                ELSIF i_status_info.id_workflow IN (pk_ref_constant.g_wf_pcc_hosp,
                                                    pk_ref_constant.g_wf_hosp_hosp,
                                                    pk_ref_constant.g_wf_x_hosp,
                                                    pk_ref_constant.g_wf_fertis)
                THEN
                
                    ---------------------------
                    -- WORKFLOW in (1,2,4,8)
                    ---------------------------
                
                    IF (i_profile = pk_ref_constant.g_profile_adm_hs OR i_profile = pk_ref_constant.g_profile_adm_hs_cl)
                       AND i_prof.institution = l_id_inst_dest
                    THEN
                        -- registrar from referral dest institution
                    
                        -- validating dep_clin_serv
                        g_error := 'Calling pk_ref_dest_reg.validate_dcs / l_flg_prof_dcs=' || l_flg_prof_dcs || ' / ' ||
                                   l_params;
                        IF nvl(l_flg_prof_dcs, pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => l_id_dcs)) =
                           pk_ref_constant.g_yes
                        THEN
                            l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                        END IF;
                    END IF;
                
                END IF;
            
            WHEN l_flg_status_v = pk_ref_constant.g_p1_status_w THEN
            
                ---------------------------
                -- Ans(W)ered
                ---------------------------                                    
            
                IF l_id_prof_requested = i_prof.id
                   AND i_prof.institution = l_id_inst_orig
                THEN
                    l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red2;
                    -- ELSE -- default color 
                END IF;
            
            WHEN l_flg_status_v IN
                 (pk_ref_constant.g_p1_status_x, pk_ref_constant.g_p1_status_h, pk_ref_constant.g_p1_status_z) THEN
            
                ---------------------------
                -- Refused (X), Not approved (H), Cancel Referral Request (Z)
                ---------------------------                                   
                IF l_id_prof_requested = i_prof.id
                   AND i_prof.institution = l_id_inst_orig
                THEN
                    l_rec_wf_status_info.color := pk_ref_constant.g_icon_color_red;
                    -- ELSE -- default color 
                END IF;
            
        END CASE;
    
        RETURN l_rec_wf_status_info;
    
    END get_wf_status_info;

    /**
    * Get the referral status string used in grids 
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Professional id, institution and software   
    * @param   i_ref_row              Referral row data
    * @param   o_sts_prof_resp        Status string visible to the professional that is responsible for the referral
    * @param   o_sts_orig_phy_cs_dc   Status string visible to the orig clinical director (profile_template=300)    
    * @param   o_sts_orig_phy_hs_dc   Status string visible to the orig clinical director (profile_template=330)
    * @param   o_sts_orig_phy_cs      Status string visible to the orig physician (profile_template=300)
    * @param   o_sts_orig_phy_hs      Status string visible to the orig physician (profile_template=330)
    * @param   o_sts_orig_reg_cs      Status string visible to the orig registrar (profile_template=310)
    * @param   o_sts_orig_reg_hs      Status string visible to the orig registrar (profile_template=320)
    * @param   o_sts_dest_reg         Status string visible to the dest registrar (profile_template=320)
    * @param   o_sts_dest_phy_te      Status string visible to the dest physician: clinical service triage physician (profile_template=330)
    * @param   o_sts_dest_phy_t       Status string visible to the dest physician: triage physician (profile_template=330)
    * @param   o_sts_dest_phy_mc      Status string visible to the dest physician: consulting physician (profile_template=330)
    * @param   o_sts_dest_phy_t_me       Status string visible to the dest physician: I am the triage physician (profile_template=330)
    *
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   04-04-2013
    */
    PROCEDURE get_status_string_ea
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ref_row            IN p1_external_request%ROWTYPE,
        o_sts_prof_resp      OUT referral_ea.sts_prof_resp%TYPE,
        o_sts_orig_phy_cs_dc OUT referral_ea.sts_orig_phy_cs_dc%TYPE,
        o_sts_orig_phy_hs_dc OUT referral_ea.sts_orig_phy_hs_dc%TYPE,
        o_sts_orig_phy_cs    OUT referral_ea.sts_orig_phy_cs%TYPE,
        o_sts_orig_phy_hs    OUT referral_ea.sts_orig_phy_hs%TYPE,
        o_sts_orig_reg_cs    OUT referral_ea.sts_orig_reg_cs%TYPE,
        o_sts_orig_reg_hs    OUT referral_ea.sts_orig_reg_hs%TYPE,
        o_sts_dest_reg       OUT referral_ea.sts_dest_reg%TYPE,
        o_sts_dest_phy_te    OUT referral_ea.sts_dest_phy_te%TYPE,
        o_sts_dest_phy_t     OUT referral_ea.sts_dest_phy_t%TYPE,
        o_sts_dest_phy_mc    OUT referral_ea.sts_dest_phy_mc%TYPE,
        o_sts_dest_phy_t_me  OUT referral_ea.sts_dest_phy_t_me%TYPE
    ) IS
        l_params VARCHAR2(1000 CHAR);
    
        l_prof               profissional;
        l_id_status          wf_status.id_status%TYPE;
        l_rec_wf_status_info t_rec_wf_status_info;
        l_wf_param           table_varchar;
        l_id_workflow        referral_ea.id_workflow%TYPE;
        l_id_category        category.id_category%TYPE;
        l_id_prof_templ      profile_template.id_profile_template%TYPE;
        l_id_func            sys_functionality.id_functionality%TYPE;
        l_id_market          market.id_market%TYPE;
    
        --l_current_timestamp_beg p1_tracking.dt_tracking_tstz%TYPE;
        --l_current_timestamp_end p1_tracking.dt_tracking_tstz%TYPE;       
    BEGIN
        l_params := 'ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status ||
                    ' ID_PROF_REQUESTED=' || i_ref_row.id_prof_requested;
        g_error  := 'Init get_status_string_ea / ' || l_params;
    
        --l_current_timestamp_beg := current_timestamp;
    
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        -- this is only done for id_software 4 and for id_market=1        
        IF l_id_market = pk_ref_constant.g_market_pt
        THEN
            l_id_workflow := nvl(i_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp);
            l_id_status   := convert_status_n(i_ref_row.flg_status); -- the new referral status
            l_wf_param    := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_ext_req            => i_ref_row.id_external_request,
                                                        i_id_patient         => i_ref_row.id_patient,
                                                        i_id_inst_orig       => i_ref_row.id_inst_orig,
                                                        i_id_inst_dest       => i_ref_row.id_inst_dest,
                                                        i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                                        i_id_speciality      => i_ref_row.id_speciality,
                                                        i_flg_type           => i_ref_row.flg_type,
                                                        i_decision_urg_level => i_ref_row.decision_urg_level,
                                                        i_id_prof_requested  => i_ref_row.id_prof_requested,
                                                        i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                                        i_id_prof_status     => i_ref_row.id_prof_status,
                                                        i_external_sys       => i_ref_row.id_external_sys,
                                                        i_location           => pk_ref_constant.g_location_grid, -- this code used only in grids
                                                        i_flg_status         => i_ref_row.flg_status,
                                                        i_flg_prof_dcs       => pk_ref_constant.g_yes,
                                                        i_prof_clin_dir      => pk_ref_constant.g_no);
        
            --------------------------------------
            -- Professional responsible for the referral
            g_error              := 'Professional responsible for the referral / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(i_ref_row.id_prof_requested,
                                                 i_ref_row.id_inst_orig,
                                                 pk_ref_constant.g_id_soft_referral); -- professional that requested the referral
            l_id_category        := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => l_prof);
            l_id_prof_templ      := pk_tools.get_prof_profile_template(l_prof);
            l_id_func            := 0; -- not needed in this case
        
            g_error              := 'Call pk_workflow.get_status_info / Professional responsible for the referral / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_prof_resp
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_prof_resp := NULL;
            ELSE
                g_error         := 'Call get_flash_status_order / Professional responsible for the referral / ' ||
                                   l_params;
                o_sts_prof_resp := get_flash_status_order(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_color          => l_rec_wf_status_info.color,
                                                          i_rank           => l_rec_wf_status_info.rank,
                                                          i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig clinical director (profile_template=300)
            g_error              := 'Orig clinical director (profile_template=300) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_cs;
            l_id_func            := pk_ref_constant.g_ref_func_cd;
        
            l_wf_param(pk_ref_constant.g_idx_prof_clin_dir) := pk_ref_constant.g_yes; -- this is required here
        
            g_error              := 'Call pk_workflow.get_status_info / Orig clinical director (profile_template=300) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
            -- o_sts_orig_phy_cs_dc
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_phy_cs_dc := NULL;
            ELSE
                o_sts_orig_phy_cs_dc := get_flash_status_order(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_color          => l_rec_wf_status_info.color,
                                                               i_rank           => l_rec_wf_status_info.rank,
                                                               i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig clinical director (profile_template=330)
            g_error              := 'Orig clinical director (profile_template=330) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
            l_id_func            := pk_ref_constant.g_ref_func_cd;
        
            l_wf_param(pk_ref_constant.g_idx_prof_clin_dir) := pk_ref_constant.g_yes; -- this is required here
        
            g_error              := 'Call pk_workflow.get_status_info / Orig clinical director (profile_template=330) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_orig_phy_hs_dc
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_phy_hs_dc := NULL;
            ELSE
                o_sts_orig_phy_hs_dc := get_flash_status_order(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_color          => l_rec_wf_status_info.color,
                                                               i_rank           => l_rec_wf_status_info.rank,
                                                               i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig physician (profile_template=300)
            g_error              := 'Orig physician (profile_template=300) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_cs;
            l_id_func            := 0;
        
            l_wf_param(pk_ref_constant.g_idx_prof_clin_dir) := NULL; -- clean this variable
        
            g_error              := 'Call pk_workflow.get_status_info / Orig physician (profile_template=300) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
            -- o_sts_orig_phy_cs
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_phy_cs := NULL;
            ELSE
                o_sts_orig_phy_cs := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig physician (profile_template=330)
            g_error              := 'Orig physician (profile_template=330) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
            l_id_func            := 0;
        
            g_error              := 'Call pk_workflow.get_status_info / Orig physician (profile_template=330) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_orig_phy_hs
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_phy_hs := NULL;
            ELSE
                o_sts_orig_phy_hs := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig registrar (profile_template=310)
            g_error              := 'Orig registrar (profile_template=310) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_adm;
            l_id_prof_templ      := pk_ref_constant.g_profile_adm_cs;
            l_id_func            := 0; -- not needed in this case
        
            g_error              := 'Call pk_workflow.get_status_info / Orig registrar (profile_template=310) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_orig_reg_cs
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_reg_cs := NULL;
            ELSE
                o_sts_orig_reg_cs := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Orig registrar (profile_template=320)
            g_error              := 'Orig registrar (profile_template=310) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_adm;
            l_id_prof_templ      := pk_ref_constant.g_profile_adm_hs;
            l_id_func            := 0; -- not needed in this case
        
            g_error              := 'Call pk_workflow.get_status_info / Orig registrar (profile_template=320) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_orig_reg_hs
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_orig_reg_hs := NULL;
            ELSE
                o_sts_orig_reg_hs := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Dest registrar (profile_template=320)
            g_error              := 'Dest registrar (profile_template=320) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_adm;
            l_id_prof_templ      := pk_ref_constant.g_profile_adm_hs;
            l_id_func            := 0; -- not needed in this case
        
            g_error              := 'Call pk_workflow.get_status_info / Dest registrar (profile_template=320) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_dest_reg
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_dest_reg := NULL;
            ELSE
                o_sts_dest_reg := get_flash_status_order(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_color          => l_rec_wf_status_info.color,
                                                         i_rank           => l_rec_wf_status_info.rank,
                                                         i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- Dest physician: clinical service triage physician (profile_template=330)
            g_error              := 'Dest physician: clinical service triage physician (profile_template=330) / ' ||
                                    l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
            l_id_func            := pk_ref_constant.g_func_d;
        
            g_error              := 'Call pk_workflow.get_status_info / Dest physician: clinical service triage physician (profile_template=330) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_dest_phy_te            
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_dest_phy_te := NULL;
            ELSE
                o_sts_dest_phy_te := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- dest physician: triage physician (profile_template=330)
            g_error              := 'dest physician: triage physician (profile_template=330) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
            l_id_func            := pk_ref_constant.g_func_t;
        
            g_error := 'Call pk_workflow.get_status_info / dest physician: triage physician (profile_template=330) / ' ||
                       ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow || ' ID_STATUS=' ||
                       l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' || l_id_prof_templ || ' ID_FUNC=' ||
                       l_id_func || ' PARAMS=' || pk_utils.to_string(l_wf_param) || ' / ' || l_params;
        
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_dest_phy_t
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_dest_phy_t := NULL;
            ELSE
                o_sts_dest_phy_t := get_flash_status_order(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_color          => l_rec_wf_status_info.color,
                                                           i_rank           => l_rec_wf_status_info.rank,
                                                           i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
            --------------------------------------
            -- dest physician: I am the triage physician (profile_template=330)
            g_error := 'dest physician: triage physician (profile_template=330) / ' || l_params;
            IF i_ref_row.id_prof_redirected IS NULL
            THEN
                o_sts_dest_phy_t_me := o_sts_dest_phy_t; -- no need to calculate
            ELSE
            
                l_rec_wf_status_info := t_rec_wf_status_info();
                l_prof               := profissional(i_ref_row.id_prof_redirected,
                                                     i_ref_row.id_inst_dest,
                                                     pk_ref_constant.g_id_soft_referral);
                l_id_category        := pk_ref_constant.g_cat_id_med;
                l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
                l_id_func            := pk_ref_constant.g_func_t;
            
                g_error := 'Call pk_workflow.get_status_info / dest physician: triage physician (profile_template=330) / ' ||
                           ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow || ' ID_STATUS=' ||
                           l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' || l_id_prof_templ ||
                           ' ID_FUNC=' || l_id_func || ' PARAMS=' || pk_utils.to_string(l_wf_param) || ' / ' ||
                           l_params;
            
                l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                    i_prof                => l_prof,
                                                                    i_id_workflow         => l_id_workflow,
                                                                    i_id_status           => l_id_status,
                                                                    i_id_category         => l_id_category,
                                                                    i_id_profile_template => l_id_prof_templ,
                                                                    i_id_functionality    => l_id_func,
                                                                    i_param               => l_wf_param);
            
                -- o_sts_dest_phy_t_me
                IF l_rec_wf_status_info.id_status IS NULL
                THEN
                    o_sts_dest_phy_t_me := NULL;
                ELSE
                    o_sts_dest_phy_t_me := get_flash_status_order(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_color          => l_rec_wf_status_info.color,
                                                                  i_rank           => l_rec_wf_status_info.rank,
                                                                  i_dt_status_tstz => i_ref_row.dt_status_tstz);
                END IF;
            END IF;
            --------------------------------------
            -- Dest physician: consulting physician (profile_template=330)
            g_error              := 'Dest physician: consulting physician (profile_template=330) / ' || l_params;
            l_rec_wf_status_info := t_rec_wf_status_info();
            l_prof               := profissional(NULL, i_ref_row.id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_id_category        := pk_ref_constant.g_cat_id_med;
            l_id_prof_templ      := pk_ref_constant.g_profile_med_hs;
            l_id_func            := pk_ref_constant.g_func_c;
        
            g_error              := 'Call pk_workflow.get_status_info / Dest physician: consulting physician (profile_template=330) / ' ||
                                    ' l_prof=' || pk_utils.to_string(l_prof) || ' ID_WF=' || l_id_workflow ||
                                    ' ID_STATUS=' || l_id_status || ' ID_CAT=' || l_id_category || ' ID_PRF_TEMPL=' ||
                                    l_id_prof_templ || ' ID_FUNC=' || l_id_func || ' PARAMS=' ||
                                    pk_utils.to_string(l_wf_param) || ' / ' || l_params;
            l_rec_wf_status_info := pk_workflow.get_status_info(i_lang                => i_lang,
                                                                i_prof                => l_prof,
                                                                i_id_workflow         => l_id_workflow,
                                                                i_id_status           => l_id_status,
                                                                i_id_category         => l_id_category,
                                                                i_id_profile_template => l_id_prof_templ,
                                                                i_id_functionality    => l_id_func,
                                                                i_param               => l_wf_param);
        
            -- o_sts_dest_phy_mc
            IF l_rec_wf_status_info.id_status IS NULL
            THEN
                o_sts_dest_phy_mc := NULL;
            ELSE
                o_sts_dest_phy_mc := get_flash_status_order(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_color          => l_rec_wf_status_info.color,
                                                            i_rank           => l_rec_wf_status_info.rank,
                                                            i_dt_status_tstz => i_ref_row.dt_status_tstz);
            END IF;
        
        END IF;
        --l_current_timestamp_end := current_timestamp;
        --pk_alertlog.log_debug(l_current_timestamp_end - l_current_timestamp_beg); 
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
    END get_status_string_ea;

    /**
    * Checks if the referral has already been issued (at least once)
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier 
    *   
    * @RETURN  BOOLEAN              {*} Y- the referral has already been issued once {*} N- the referral has never been issued
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   11-04-2014
    */
    FUNCTION check_ref_issued_once
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_ref_issued_once';
        l_flg_result VARCHAR2(1 CHAR);
        l_count      PLS_INTEGER;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        SELECT COUNT(1)
          INTO l_count
          FROM p1_tracking
         WHERE ext_req_status IN (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_j) -- issued or pending approval
           AND flg_type = pk_ref_constant.g_tracking_type_s
           AND id_external_request = i_id_ref;
    
        IF l_count = 0
        THEN
            -- referral has never been issued
            l_flg_result := pk_ref_constant.g_no;
        ELSE
            -- referral has already been issued
            l_flg_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_flg_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END check_ref_issued_once;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    -- initializing ibts
    init_status;

END pk_ref_status;
/
