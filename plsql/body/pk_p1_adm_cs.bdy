/*-- Last Change Revision: $Rev: 2027411 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_adm_cs AS

    g_package_name  VARCHAR2(30 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_retval        BOOLEAN;
    g_error         VARCHAR2(1000 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Validates if the request is editable.
    *
    * @param   i_ext_req external request id
    *
    * @RETURN  Y if editable, N otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   15-12-2007
    */
    FUNCTION is_editable
    (
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'Init is_editable / i_ext_req=' || i_ext_req || ' i_flg_status=' || i_flg_status;
        CASE i_flg_status
            WHEN pk_ref_constant.g_p1_status_n THEN
                RETURN pk_ref_constant.g_yes;
            WHEN pk_ref_constant.g_p1_status_b THEN
                RETURN pk_ref_constant.g_yes;
            ELSE
                RETURN pk_ref_constant.g_no;
        END CASE;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || '/ ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END is_editable;

    /**
    * Update status of tasks for the request (replaces UPD_TASKS_DONE)
    *
    * @param   I_LANG  language
    * @param   I_PROF  profissional, institution, software
    * @param   i_id_external_request Referral identifier
    * @param   I_ID_TASKS array of tasks ids
    * @param   I_FLG_STATUS_INI array tasks initial status
    * @param   I_FLG_STATUS_FIN array tasks final status
    * @param   i_notes notes     
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION update_tasks_done_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_id_tasks            IN table_number,
        i_flg_status_ini      IN table_varchar,
        i_flg_status_fin      IN table_varchar,
        i_notes               IN p1_detail.text%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tsd            p1_task_done%ROWTYPE;
        l_id_track       p1_tracking.id_tracking%TYPE;
        l_editable       VARCHAR2(1 CHAR);
        l_ext_req_status p1_external_request.flg_status%TYPE;
        l_rowids         table_varchar;
        o_track          table_number;
    BEGIN
        g_error        := 'Init update_tasks_done_internal / i_id_external_request=' || i_id_external_request;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        o_track        := table_number();
    
        FOR i IN 1 .. i_id_tasks.count
        LOOP
            IF (nvl(i_flg_status_fin(i), pk_ref_constant.g_p1_task_done_tdone_n) !=
               nvl(i_flg_status_ini(i), pk_ref_constant.g_p1_task_done_tdone_n))
            THEN
            
                l_tsd.flg_task_done := nvl(i_flg_status_fin(i), pk_ref_constant.g_p1_task_done_tdone_n);
                IF l_tsd.flg_task_done = pk_ref_constant.g_p1_task_done_tdone_y
                THEN
                    l_tsd.dt_completed_tstz := g_sysdate_tstz;
                END IF;
            
                g_error := 'UPDATE p1_task_done / i_id_external_request=' || i_id_external_request;
                UPDATE p1_task_done
                   SET flg_task_done     = l_tsd.flg_task_done,
                       dt_completed_tstz = l_tsd.dt_completed_tstz,
                       id_prof_exec      = i_prof.id,
                       id_inst_exec      = i_prof.institution -- ALERT-824
                 WHERE id_external_request = i_id_external_request
                   AND id_task_done = i_id_tasks(i);
            
                g_error := 'UPDATE P1_EXTERNAL_REQUEST / i_id_external_request=' || i_id_external_request;
                ts_p1_external_request.upd(id_external_request_in      => i_id_external_request,
                                           dt_last_interaction_tstz_in => g_sysdate_tstz,
                                           rows_out                    => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'P1_EXTERNAL_REQUEST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
        END LOOP;
    
        g_error  := 'Call pk_p1_external_request.get_flg_status / ID_REF=' || i_id_external_request;
        g_retval := pk_p1_external_request.get_flg_status(i_lang       => i_lang,
                                                          i_id_ref     => i_id_external_request,
                                                          o_flg_status => l_ext_req_status,
                                                          o_error      => o_error);
    
        l_editable := is_editable(i_ext_req => i_id_external_request, i_flg_status => l_ext_req_status);
    
        IF l_ext_req_status = pk_ref_constant.g_p1_status_n
        THEN
        
            g_error  := 'Call pk_p1_core.issue_request / i_id_external_request=' || i_id_external_request;
            g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_ext_req => i_id_external_request,
                                                 --i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                 o_track => o_track,
                                                 o_error => o_error);
        
            IF NOT g_retval
            THEN
                RETURN FALSE;
            END IF;
        
            IF o_track.exists(1)
               AND o_track(1) IS NOT NULL
            THEN
                l_id_track := o_track(1); -- first iteration
            END IF;
        END IF;
    
        -- JS 2007-12-15: O registo de notas so é feito se o pedido for editavel
        IF l_editable = pk_ref_constant.g_yes
        THEN
            IF i_notes IS NOT NULL
            THEN
            
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_admi || '  / i_id_external_request=' ||
                           i_id_external_request;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_id_external_request,
                     i_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_admi,
                     i_prof.id,
                     i_prof.institution,
                     l_id_track,
                     pk_ref_constant.g_active);
            
            END IF;
        END IF;
    
        -- JS 2007-12-15: Se l_id_track e' nao nulo e' porque houve mudanca de estado
        -- Neste caso, associa todas as notas com id_tracking nulo ao id tracking do estado actual.
        IF l_id_track IS NOT NULL
        THEN
        
            g_error := 'UPDATE p1_detail / i_id_external_request=' || i_id_external_request;
            UPDATE p1_detail d
               SET id_tracking = l_id_track
             WHERE id_external_request = i_id_external_request
               AND d.flg_type = pk_ref_constant.g_detail_type_admi
               AND d.id_tracking IS NULL;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_TASKS_DONE_INTERNAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_tasks_done_internal;

    /**
    * Lists all tasks related to referral by doctor
    *
    * @param   i_lang                Language
    * @param   i_prof                Profissional, institution, software
    * @param   i_id_external_request Referral identifier
    * @param   i_id_tasks            Array of tasks ids
    * @param   i_flg_status_ini      Array tasks initial status
    * @param   i_flg_status_fin      Array tasks final status
    * @param   i_notes               Notes     
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION get_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        o_tasks    OUT pk_types.cursor_type,
        o_info     OUT pk_types.cursor_type,
        o_notes    OUT pk_types.cursor_type,
        o_editable OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_aux        VARCHAR2(1 CHAR);
        l_flg_status p1_external_request.flg_status%TYPE;
    BEGIN
        g_error  := 'Call pk_ref_orig_reg.get_tasks_done / ID_REF=' || i_ext_req;
        g_retval := pk_ref_orig_reg.get_tasks_done(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_ext_req => i_ext_req,
                                                   o_tasks   => o_tasks,
                                                   o_info    => o_info,
                                                   o_notes   => o_notes,
                                                   -- l_aux contains a value that is returned from workflows framework
                                                   -- We want the value from is_editable function of this package
                                                   o_editable => l_aux,
                                                   o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- Can the registrar change the referral?
        g_error  := 'Call pk_p1_external_request.get_flg_status / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_flg_status(i_lang       => i_lang,
                                                          i_id_ref     => i_ext_req,
                                                          o_flg_status => l_flg_status,
                                                          o_error      => o_error);
    
        g_error    := 'o_editable / ID_REF=' || i_ext_req || ' l_flg_status=' || l_flg_status;
        o_editable := is_editable(i_ext_req => i_ext_req, i_flg_status => l_flg_status);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASK_DONE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes);
            RETURN FALSE;
    END get_tasks_done;

    /**
    * Returns the options for the administrative.
    *
    * @param   I_LANG  language
    * @param   i_prof                Profissional, institution, software
    * @param   i_id_ext_req          Referral identifier    
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   O_STATUS options list
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_p1 IS
            SELECT dt_last_interaction_tstz, flg_status
              FROM p1_external_request
             WHERE id_external_request = i_id_ext_req;
        l_exr_row            c_p1%ROWTYPE;
        l_req_cancel_enabled VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- CONFIG
        ----------------------        
        g_error              := 'Call pk_ref_status.check_config_enabled / ID_REF=' || i_id_ext_req || ' CONFIG=' ||
                                pk_ref_constant.g_ref_cancel_req_enabled;
        l_req_cancel_enabled := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                                   i_prof   => i_prof,
                                                                   i_config => pk_ref_constant.g_ref_cancel_req_enabled);
        ----------------------
        -- FUNC
        ----------------------        
        g_error := 'OPEN c_p1 / ID_REF=' || i_id_ext_req;
        OPEN c_p1;
        FETCH c_p1
            INTO l_exr_row;
        CLOSE c_p1;
    
        o_flg_show := pk_ref_constant.g_no;
        IF pk_date_utils.trunc_insttimezone(i_prof, l_exr_row.dt_last_interaction_tstz, 'SS') >
           pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_COMMON_T008');
            o_msg       := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_COMMON_T007');
            o_button    := 'R';
            pk_types.open_my_cursor(o_status);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN o_status / ID_REF=' || i_id_ext_req;
        OPEN o_status FOR
            SELECT NULL                 id_workflow,
                   l_exr_row.flg_status status_begin,
                   data                 status_end,
                   icon,
                   label,
                   NULL                 rank,
                   data                 action
              FROM (SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_b
                       AND sd.code_domain = 'P1_STATUS_OPTIONS.ADM_CS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = 'I'
                    UNION
                    -- Request referral cancellation
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_n,
                                                    pk_ref_constant.g_p1_status_i,
                                                    pk_ref_constant.g_p1_status_b,
                                                    pk_ref_constant.g_p1_status_t,
                                                    pk_ref_constant.g_p1_status_a,
                                                    pk_ref_constant.g_p1_status_r,
                                                    pk_ref_constant.g_p1_status_d,
                                                    pk_ref_constant.g_p1_status_o,
                                                    pk_ref_constant.g_p1_status_p,
                                                    pk_ref_constant.g_p1_status_g)
                       AND sd.code_domain = 'P1_STATUS_OPTIONS.ADM_CS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_ref_action_z -- CANCEL_REQ
                       AND l_req_cancel_enabled = pk_ref_constant.g_yes
                    UNION
                    -- Avoid request cancellation
                    SELECT DISTINCT sd.desc_val label, sd.val data, sd.img_name icon
                      FROM sys_domain sd
                     WHERE l_exr_row.flg_status = pk_ref_constant.g_p1_status_z
                       AND sd.code_domain = 'P1_STATUS_OPTIONS.ADM_CS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pk_ref_constant.g_ref_action_zdn -- CANCEL_REQ_DENY   
                       AND l_req_cancel_enabled = pk_ref_constant.g_yes
                          -- this can only be done if it was this professional requesting the referral cancellation
                       AND i_prof.id = (SELECT id_professional
                                          FROM (SELECT id_professional
                                                  FROM p1_tracking t
                                                 WHERE t.id_external_request = i_id_ext_req
                                                   AND t.flg_type = pk_ref_constant.g_tracking_type_s
                                                   AND t.ext_req_status = pk_ref_constant.g_p1_status_z
                                                 ORDER BY t.dt_tracking_tstz DESC)
                                         WHERE rownum <= 1));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_OPTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_status_options;

    /**
    * Updates request status.
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   I_ID_P1         Referral identifier
    * @param   I_STATUS        Action to be done
    * @param   I_REASON_CODE   Reason code when requesting a referral cancellation
    * @param   I_NOTES         Notes
    * @param   I_DATE          Operation date
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION set_status_internal
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_p1       IN p1_external_request.id_external_request%TYPE,
        i_status      IN VARCHAR2,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_p1=' || i_id_p1 || ' i_status=' || i_status ||
                    ' i_reason_code=' || i_reason_code;
        g_error  := 'Init set_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        IF i_status = pk_ref_constant.g_p1_status_i
        THEN
            g_error  := 'Call issue_request / ' || l_params;
            g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_ext_req => i_id_p1,
                                                 i_date    => g_sysdate_tstz,
                                                 o_track   => o_track,
                                                 o_error   => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- JS 2007-12-15: associates all details with id_tracking=null to the current id_tracking status
            g_error := 'UPDATE p1_detail / ' || l_params;
            UPDATE p1_detail d
               SET id_tracking = o_track(1)
             WHERE id_external_request = i_id_p1
               AND d.flg_type = pk_ref_constant.g_detail_type_admi
               AND d.id_tracking IS NULL;
        
        ELSIF i_status IN (pk_ref_constant.g_ref_action_z, pk_ref_constant.g_ref_action_zdn)
        THEN
            -- Requesting referral cancellation
            g_error  := 'Call pk_p1_adm_hs.set_status_internal / ' || l_params;
            g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_ext_req     => i_id_p1,
                                                         i_status      => i_status,
                                                         i_notes       => i_notes,
                                                         i_reason_code => i_reason_code,
                                                         i_dcs         => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => o_track,
                                                         o_error       => o_error);
        
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
                                              i_function => 'SET_STATUS_INTERNAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_status_internal;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_adm_cs;
/
