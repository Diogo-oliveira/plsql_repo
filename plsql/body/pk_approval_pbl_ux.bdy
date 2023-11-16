/*-- Last Change Revision: $Rev: 2026752 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_approval_pbl_ux IS

    /**
    * Returns all approval resquests that are associated with the logged professional specialities. 
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    */
    FUNCTION get_all_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_ALL_APPROVAL_REQUESTS';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof));
    
        g_error := 'PK_APPROVAL.GET_APPROVAL_REQUESTS';
        IF NOT pk_approval.get_approval_requests(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_filter_by_dcs => pk_alert_constant.g_yes,
                                                 o_approvals     => o_approvals,
                                                 o_appr_types    => o_appr_types,
                                                 o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Returns all approval resquests in witch the logged professional is responsible.
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    */
    FUNCTION get_my_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_MY_APPROVAL_REQUESTS';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof));
    
        g_error := 'PK_APPROVAL.GET_APPROVAL_REQUESTS';
        IF NOT pk_approval.get_approval_requests(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_filter_by_prof => pk_alert_constant.g_yes,
                                                 o_approvals      => o_approvals,
                                                 o_appr_types     => o_appr_types,
                                                 o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Returns all approval resquests associated to the given patient.
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_patient            Patient identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    */
    FUNCTION get_patient_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PATIENT_APPROVAL_REQUESTS';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_patient: ' || i_id_patient);
    
        IF NOT pk_approval.get_approval_requests(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_filter_by_patient => pk_alert_constant.g_yes,
                                                 o_approvals         => o_approvals,
                                                 o_appr_types        => o_appr_types,
                                                 o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Returns all approval resquests that are expired associated to the given patient.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_patient            Patient identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    */
    FUNCTION get_hist_pat_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_HIST_PAT_APPROVAL_REQUESTS';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_patient: ' || i_id_patient);
    
        IF NOT pk_approval.get_approval_requests(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_filter_by_history => pk_alert_constant.g_yes,
                                                 i_filter_by_patient => pk_alert_constant.g_yes,
                                                 o_approvals         => o_approvals,
                                                 o_appr_types        => o_appr_types,
                                                 o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Returns all approval resquests based on the search conditions.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_criteria           Search criterias list
    * @param i_values             Search values list
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    */
    FUNCTION get_search_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_criteria   IN table_number,
        i_values     IN table_varchar,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SEARCH_APPROVAL_REQUESTS';
    
        l_filter_by_prof_req  table_number;
        l_filter_by_dir_resp  table_number;
        l_filter_by_origin    table_number;
        l_filter_by_req_date  VARCHAR2(200);
        l_filter_by_app_type  table_number;
        l_filter_by_app_state table_varchar;
        l_filter_by_app_desc  VARCHAR2(200);
    
        l_no_crit EXCEPTION;
    
        -- converts a table_varchar to a table_number
        FUNCTION table_varchar_to_table_number(i_input table_varchar2) RETURN table_number IS
            l_result table_number;
        BEGIN
            l_result := table_number();
        
            FOR i IN 1 .. i_input.COUNT
            LOOP
                l_result.EXTEND();
            
                l_result(i) := to_number(i_input(i));
            END LOOP;
        
            RETURN l_result;
        END;
    
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) || ' | i_criteria: ' ||
                             pk_utils.to_string(i_criteria) || ' | i_values: ' || pk_utils.to_string(i_values));
    
        IF i_criteria IS NOT NULL
        THEN
            FOR i IN 1 .. i_criteria.COUNT
            LOOP
                IF i_criteria(i) IS NULL
                THEN
                    NULL;
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_prof_req
                THEN
                    l_filter_by_prof_req := table_varchar_to_table_number(pk_utils.str_split(i_values(i), ','));
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_dir_resp
                THEN
                    l_filter_by_dir_resp := table_varchar_to_table_number(pk_utils.str_split(i_values(i), ','));
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_origin
                THEN
                    l_filter_by_origin := table_varchar_to_table_number(pk_utils.str_split(i_values(i), ','));
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_app_req_date
                THEN
                    l_filter_by_req_date := i_values(i);
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_app_type
                THEN
                    l_filter_by_app_type := table_varchar_to_table_number(pk_utils.str_split(i_values(i), ','));
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_status
                THEN
                    l_filter_by_app_state := pk_string_utils.str_split(i_values(i), ',');
                ELSIF i_criteria(i) = pk_approval.g_id_criteria_app_desc
                THEN
                    l_filter_by_app_desc := i_values(i);
                ELSE
                    g_error := 'THIS CRITERIA IS NOT AVAILABLE / NOT IMPLEMENTED';
                    RAISE l_no_crit;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT pk_approval.get_approval_requests(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_filter_by_search    => pk_alert_constant.g_yes,
                                                 i_filter_by_prof_req  => l_filter_by_prof_req,
                                                 i_filter_by_dir_resp  => l_filter_by_dir_resp,
                                                 i_filter_by_origin    => l_filter_by_origin,
                                                 i_filter_by_req_date  => l_filter_by_req_date,
                                                 i_filter_by_app_type  => l_filter_by_app_type,
                                                 i_filter_by_app_state => l_filter_by_app_state,
                                                 i_filter_by_app_desc  => l_filter_by_app_desc,
                                                 o_approvals           => o_approvals,
                                                 o_appr_types          => o_appr_types,
                                                 o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Checks if the provided approval requests have no responsible or are already assigned to another
    * professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_flg_show           Show modal window (Y - yes, N - no)
    * @param o_msg_title          Modal window title
    * @param o_msg_text_highlight Modal window highlighted text
    * @param o_msg_text_detail    Modal window detail text
    * @param o_button             Modal window buttons
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION check_prof_responsibility
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN table_number,
        i_id_external        IN table_number,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_msg_text_detail    OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CHECK_PROF_RESPONSIBILITY';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_approval_type: ' || pk_utils.to_string(i_id_approval_type) ||
                             ' | i_id_external: ' || pk_utils.to_string(i_id_external));
    
        IF NOT pk_approval.check_prof_responsibility(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_approval_type   => i_id_approval_type,
                                                     i_id_external        => i_id_external,
                                                     o_flg_show           => o_flg_show,
                                                     o_msg_title          => o_msg_title,
                                                     o_msg_text_highlight => o_msg_text_highlight,
                                                     o_msg_text_detail    => o_msg_text_detail,
                                                     o_button             => o_button,
                                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Checks if the provided approval requests have no responsible or are already assigned to another
    * professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_flg_show           Show modal window (Y - yes, N - no)
    * @param o_msg_title          Modal window title
    * @param o_msg_text_highlight Modal window highlighted text
    * @param o_msg_text_detail    Modal window detail text
    * @param o_button             Modal window buttons
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION set_prof_responsibility
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN table_number,
        i_id_external        IN table_number,
        o_flg_show           OUT VARCHAR2, --retirar?
        o_msg_title          OUT VARCHAR2, --retirar?
        o_msg_text_highlight OUT VARCHAR2, --retirar?
        o_msg_text_detail    OUT VARCHAR2, --retirar?
        o_button             OUT VARCHAR2, --retirar?
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_PROF_RESPONSIBILITY';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_approval_type: ' || pk_utils.to_string(i_id_approval_type) ||
                             ' | i_id_external: ' || pk_utils.to_string(i_id_external));
    
        IF NOT pk_approval.set_prof_responsible_no_commit(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_approval_type => i_id_approval_type,
                                                          i_id_external      => i_id_external,
                                                          o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Approve a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION approve_approval_request
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'APPROVE_APPROVAL_REQUEST';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_approval_type: ' || i_id_approval_type || ' | i_id_external: ' || i_id_external);
    
        IF NOT pk_approval.approve_appr_request_no_commit(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_approval_type => i_id_approval_type,
                                                          i_id_external      => i_id_external,
                                                          i_notes            => i_notes,
                                                          o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Reject a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION reject_approval_request
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'REJECT_APPROVAL_REQUEST';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_approval_type: ' || i_id_approval_type || ' | i_id_external: ' || i_id_external ||
                             ' | i_notes: ' || i_notes);
    
        IF NOT pk_approval.reject_appr_request_no_commit(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_approval_type => i_id_approval_type,
                                                         i_id_external      => i_id_external,
                                                         i_notes            => i_notes,
                                                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Cancel a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION canc_appr_req_decis
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN approval_request.id_approval_type%TYPE,
        i_id_external        IN approval_request.id_external%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_APPR_REQUEST_DECISION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_approval_type: ' || i_id_approval_type || ' | i_id_external: ' || i_id_external);
    
        IF NOT pk_approval.canc_appr_req_decis_no_commit(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_approval_type   => i_id_approval_type,
                                                         i_id_external        => i_id_external,
                                                         o_flg_show           => o_flg_show,
                                                         o_msg_title          => o_msg_title,
                                                         o_msg_text_highlight => o_msg_text_highlight,
                                                         o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_approval_pbl_ux;
/
