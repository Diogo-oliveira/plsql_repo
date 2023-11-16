/*-- Last Change Revision: $Rev: 1665067 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-11-26 14:24:17 +0000 (qua, 26 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_rcm_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;
    g_sysdate pk_rcm_constant.t_timestamp;

    /**
    * Gets available transitions for a workflow/status recommendation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_workflow  Recommendation workflow identifier
    * @param   i_id_status    Recommendation status identifier
    * @param   o_transitions  Transitions available
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-02-2012
    */
    FUNCTION get_rcm_transitions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN pat_rcm_h.id_workflow%TYPE,
        i_id_status   IN pat_rcm_h.id_status%TYPE,
        o_transitions OUT NOCOPY pk_types.cursor_type,
        o_error       OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_TRANSITIONS';
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_func             sys_functionality.id_functionality%TYPE;
        l_empty_tv            table_varchar := table_varchar();
        l_transitions_tab     t_coll_wf_transition;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_workflow=' || i_id_workflow || ' i_id_status=' || i_id_status;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error  := 'Call pk_workflow.get_transitions / i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' ||
                    i_id_status || ' i_id_category=' || l_id_category || ' i_id_profile_template=' ||
                    l_id_profile_template || ' i_id_functionality=' || l_id_func;
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => i_id_workflow,
                                                i_id_status_begin     => i_id_status,
                                                i_id_category         => l_id_category,
                                                i_id_profile_template => l_id_profile_template,
                                                i_id_functionality    => l_id_func,
                                                i_param               => l_empty_tv,
                                                i_flg_auto_transition => pk_alert_constant.get_no,
                                                o_transitions         => l_transitions_tab,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_transitions FOR';
        OPEN o_transitions FOR
            SELECT tab.id_workflow,
                   tab.id_status_begin,
                   tab.id_workflow_action,
                   tab.id_status_end,
                   tab.icon,
                   tab.desc_transition,
                   tab.rank
              FROM TABLE(CAST(l_transitions_tab AS t_coll_wf_transition)) tab
             WHERE tab.flg_visible = pk_alert_constant.get_yes
             ORDER BY tab.rank;
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_transitions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_rcm_transitions;

    /**
    * Checks if this recommendation has transitions available
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_workflow  Recommendation workflow identifier
    * @param   i_id_status    Recommendation status identifier
    *
    * @return  'Y'- if transitions available, 'N'- otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   07-05-2012
    */
    FUNCTION check_transitions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN pat_rcm_h.id_workflow%TYPE,
        i_id_status   IN pat_rcm_h.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CHECK_TRANSITIONS';
        l_error              t_error_out;
        l_transitions        pk_types.cursor_type;
        l_id_workflow        pat_rcm_h.id_workflow%TYPE;
        l_id_status_begin    pat_rcm_h.id_status%TYPE;
        l_id_workflow_action pat_rcm_h.id_workflow_action%TYPE;
        l_id_status_end      pat_rcm_h.id_status%TYPE;
        l_icon               wf_status.icon%TYPE;
        l_desc_transition    VARCHAR2(1000 CHAR);
        l_rank               wf_status.rank%TYPE;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_workflow=' || i_id_workflow || ' i_id_status=' || i_id_status;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error  := 'Call pk_workflow.get_transitions / i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' ||
                    i_id_status;
        g_retval := get_rcm_transitions(i_lang        => i_lang,
                                        i_prof        => i_prof,
                                        i_id_workflow => i_id_workflow,
                                        i_id_status   => i_id_status,
                                        o_transitions => l_transitions,
                                        o_error       => l_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        FETCH l_transitions
            INTO l_id_workflow,
                 l_id_status_begin,
                 l_id_workflow_action,
                 l_id_status_end,
                 l_icon,
                 l_desc_transition,
                 l_rank;
    
        IF l_transitions%ROWCOUNT > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
            RETURN NULL;
    END check_transitions;

    /**
    * Gets all recommendations data of this patient
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   07-02-2012
    */
    FUNCTION get_pat_rcm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_rcm_data   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM';
        l_code_label_notes CONSTANT sys_message.code_message%TYPE := 'COMMON_M101';
    
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_func             sys_functionality.id_functionality%TYPE;
        l_empty_tv            table_varchar := table_varchar();
        l_label_notes         sys_message.desc_message%TYPE;
        l_ignored_days        NUMBER;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_sysdate := current_timestamp;
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        l_ignored_days := to_number(pk_sysconfig.get_config(i_code_cf => pk_rcm_constant.g_grid_ignored_d,
                                                            i_prof    => i_prof));
        l_label_notes  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_label_notes);
    
        OPEN o_rcm_data FOR
            SELECT rcm_data.id_rcm,
                   rcm_data.id_rcm_det,
                   pk_translation.get_translation(i_lang, rcm_data.code_rcm_summ) rcm_summ,
                   pk_translation.get_translation(i_lang, rcm_data.code_rcm_desc) rcm_desc,
                   --nvl2(rcm_data.notes, l_label_notes, NULL) label_notes,
                   (CASE
                        WHEN dbms_lob.getlength(rcm_data.notes) != 0 THEN
                         l_label_notes
                        ELSE
                         NULL
                    END) label_notes,
                   (SELECT pk_translation.get_translation(i_lang, rcm_data.code_rcm_type)
                      FROM dual) rcm_type_desc,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        pk_alert_constant.g_display_type_icon, -- i_display_type 
                                                        rcm_data.rcm_sts_info.id_status, --i_flg_state-
                                                        rcm_data.rcm_sts_info.desc_status, --i_value_text
                                                        pk_date_utils.date_send_tsz(i_lang, rcm_data.dt_status, i_prof), --i_value_date
                                                        'WF_STATUS.CODE_STATUS', --rcm_data.rcm_sts_info.icon, --i_value_icon -
                                                        NULL, --i_shortcut
                                                        pk_workflow.get_grid_bg_color(i_lang,
                                                                                      i_prof,
                                                                                      rcm_data.rcm_sts_info.color), --i_back_color
                                                        pk_workflow.get_grid_fg_color(i_lang,
                                                                                      i_prof,
                                                                                      rcm_data.rcm_sts_info.color), --i_icon_color
                                                        NULL, --i_message_style
                                                        NULL, --i_message_color
                                                        NULL, --i_flg_text_domain
                                                        g_sysdate --i_dt_server
                                                        ) status_string,
                   -- status info
                   rcm_data.rcm_sts_info.id_workflow id_workflow,
                   rcm_data.rcm_sts_info.id_status id_status,
                   rcm_data.rcm_sts_info.desc_status status_desc,
                   pk_date_utils.date_send_tsz(i_lang, rcm_data.dt_status, i_prof) dt_status,
                   pk_date_utils.date_char_tsz(i_lang, rcm_data.dt_status, i_prof.institution, i_prof.software) dt_status_str,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rcm_data.id_prof_status) prof_name_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rcm_data.id_prof_status, rcm_data.dt_status, NULL) prof_spec_status,
                   rcm_data.rcm_text,
                   rcm_data.notes rcm_notes,
                   check_transitions(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_id_workflow => rcm_data.rcm_sts_info.id_workflow,
                                     i_id_status   => rcm_data.rcm_sts_info.id_status) flg_transition_available,
                   
                   rcm_data.color triggered_by_color, --ALERT-255254                
                   id_rcm_orig_value id_cdr_inst_par_action,
                   pk_info_button.get_cds_show_info_button(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_id_cdr_inst_par_action => id_rcm_orig_value) id_links
            
              FROM (SELECT tab.dt_status,
                           tab.id_prof_status,
                           tab.notes,
                           tab.rcm_text,
                           tab.id_rcm,
                           rt.id_rcm_type,
                           r.code_rcm_summ,
                           r.code_rcm_desc,
                           rt.code_rcm_type,
                           tab.id_rcm_det,
                           pk_workflow.get_status_info(i_lang,
                                                       i_prof,
                                                       tab.id_workflow,
                                                       tab.id_status,
                                                       l_id_category,
                                                       l_id_profile_template,
                                                       l_id_func,
                                                       l_empty_tv) rcm_sts_info, -- rcm status info
                           r.color, --ALERT-255254 
                           tab.id_rcm_orig_value
                      FROM (SELECT prh.dt_status,
                                   prh.id_status,
                                   prh.id_prof_status,
                                   prh.notes,
                                   prh.id_workflow,
                                   prd.rcm_text,
                                   prd.id_rcm,
                                   prd.id_rcm_det,
                                   prd.id_rcm_orig_value, -- id_cdr_inst_par_action
                                   row_number() over(PARTITION BY prd.id_rcm, prd.id_rcm_det ORDER BY prh.dt_status DESC) my_row
                              FROM pat_rcm_det prd
                              JOIN pat_rcm_h prh
                                ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND
                                   prd.id_rcm_det = prh.id_rcm_det AND prd.id_institution = prh.id_institution)
                             WHERE prd.id_patient = i_id_patient
                               AND prd.id_institution = i_prof.institution) tab
                      JOIN rcm r
                        ON (r.id_rcm = tab.id_rcm)
                      JOIN rcm_type rt
                        ON (rt.id_rcm_type = r.id_rcm_type)
                     WHERE my_row = 1
                       AND ((tab.id_status = pk_rcm_constant.g_id_status_ignored AND
                           tab.dt_status > (g_sysdate - l_ignored_days)) OR
                           tab.id_status != pk_rcm_constant.g_id_status_ignored)) rcm_data
             ORDER BY rcm_data.rcm_sts_info.rank, rcm_data.dt_status DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_rcm_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_rcm;

    /**
    * Gets historic data of this recommendation detail (used by flash)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_list_act     Array with actual recommendations info
    * @param   o_list_hist    Array with historic recommendations info
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   22-02-2012
    */
    FUNCTION get_pat_rcm_det_flash
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_list_act   OUT table_table_varchar,
        o_list_hist  OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM_DET_FLASH';
        l_code_label_created CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M015';
        l_code_label_edited  CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M016';
        l_label_created    sys_message.desc_message%TYPE;
        l_label_edited     sys_message.desc_message%TYPE;
        l_label_status     sys_message.desc_message%TYPE;
        l_label_new        sys_message.desc_message%TYPE;
        l_label_notes      sys_message.desc_message%TYPE;
        l_label_documented sys_message.desc_message%TYPE;
        l_label_rcm_text   sys_message.desc_message%TYPE;
    
        l_rcm_data     pk_rcm_constant.t_cur_rcm_info;
        l_tab_rcm_data pk_rcm_constant.t_coll_rcm_info;
        l_tab_diff     pk_rcm_constant.t_coll_rcm_info_diff := pk_rcm_constant.t_coll_rcm_info_diff();
    
        l_type_title  VARCHAR2(1 CHAR) := 'T'; -- is of type title
        l_type_bold   VARCHAR2(1 CHAR) := 'B'; -- is of type bold
        l_type_red    VARCHAR2(1 CHAR) := 'R'; -- is o type red
        l_type_italic VARCHAR2(1 CHAR) := 'N'; -- is o type italic
    
        l_prev_id    pat_rcm_h.id_rcm_det_h%TYPE;
        l_prev_dt    pat_rcm_h.dt_status%TYPE;
        l_flg_extend PLS_INTEGER;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        o_list_act  := table_table_varchar();
        o_list_hist := table_table_varchar();
    
        l_label_created    := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_label_created);
        l_label_edited     := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_label_edited);
        l_label_status     := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_rcm_t009);
        l_label_new        := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_rcm_t030);
        l_label_notes      := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_rcm_t014);
        l_label_documented := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_rcm_t015);
        l_label_rcm_text   := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sm_rcm_t013);
    
        g_error  := l_func_name || ':  Call pk_rcm_core.get_pat_rcm_det / i_id_patient=' || i_id_patient ||
                    ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det;
        g_retval := pk_rcm_core.get_pat_rcm_det(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_patient => i_id_patient,
                                                i_id_rcm     => i_id_rcm,
                                                i_id_rcm_det => i_id_rcm_det,
                                                o_rcm_data   => l_rcm_data,
                                                o_error      => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- find differences between records
        FETCH l_rcm_data BULK COLLECT
            INTO l_tab_rcm_data;
        CLOSE l_rcm_data;
    
        --start in first position, compare with next position, find differences
        g_error := 'FOR i IN 1 .. l_tab_rcm_data.count / ' || l_tab_rcm_data.count;
        FOR i IN 1 .. l_tab_rcm_data.count - 1
        LOOP
        
            IF l_tab_rcm_data.count > 1
            THEN
                l_flg_extend := 0;
            
                IF l_tab_rcm_data(i).id_status <> l_tab_rcm_data(i + 1).id_status
                THEN
                    l_tab_diff.extend;
                    l_tab_diff(l_tab_diff.last).id_rcm_det_h := l_tab_rcm_data(i).id_rcm_det_h;
                    l_tab_diff(l_tab_diff.last).dt_status := l_tab_rcm_data(i).dt_status_tstz;
                    l_flg_extend := 1;
                
                    l_tab_diff(l_tab_diff.last).status_new := l_tab_rcm_data(i).status_desc;
                    l_tab_diff(l_tab_diff.last).status_old := l_tab_rcm_data(i + 1).status_desc;
                END IF;
            
                IF dbms_lob.getlength(l_tab_rcm_data(i).rcm_notes) != 0 -- IS NOT NULL
                THEN
                    IF l_flg_extend = 0
                    THEN
                        l_tab_diff.extend;
                        l_tab_diff(l_tab_diff.last).id_rcm_det_h := l_tab_rcm_data(i).id_rcm_det_h;
                        l_tab_diff(l_tab_diff.last).dt_status := l_tab_rcm_data(i).dt_status_tstz;
                        l_flg_extend := 1;
                    END IF;
                
                    l_tab_diff(l_tab_diff.last).rcm_notes := l_tab_rcm_data(i).rcm_notes;
                END IF;
            
                IF l_flg_extend = 0
                THEN
                    l_tab_diff.extend;
                END IF;
            
                l_tab_diff(l_tab_diff.last).documented := l_tab_rcm_data(i)
                                                          .prof_name_status || pk_rcm_constant.g_semicolon ||
                                                           pk_date_utils.date_char_tsz(i_lang,
                                                                                       l_tab_rcm_data(i).dt_status_tstz,
                                                                                       i_prof.institution,
                                                                                       i_prof.software);
            END IF;
        END LOOP;
    
        -- build before / after rcm history information
        g_error     := l_func_name || ': build o_list_hist';
        o_list_hist := table_table_varchar();
    
        -- loop in reverse, show most recent transitions first
        g_error := 'FOR i IN 1 .. l_tab_diff.count / ' || l_tab_diff.count;
        FOR i IN 1 .. l_tab_diff.count
        LOOP
        
            IF l_prev_dt IS NULL
               OR l_prev_dt != l_tab_diff(i).dt_status
               OR l_prev_id IS NULL
               OR l_prev_id != l_tab_diff(i).id_rcm_det_h
            THEN
                -- changed data
                o_list_hist.extend;
                o_list_hist(o_list_hist.last) := table_varchar(l_type_title, l_label_edited, NULL);
            
            END IF;
        
            IF l_tab_diff(i).status_old IS NOT NULL
            THEN
                o_list_hist.extend;
                o_list_hist(o_list_hist.last) := table_varchar(l_type_bold,
                                                               l_label_status || pk_rcm_constant.g_colon,
                                                               l_tab_diff(i).status_old);
            END IF;
        
            IF l_tab_diff(i).status_new IS NOT NULL
            THEN
                o_list_hist.extend;
                o_list_hist(o_list_hist.last) := table_varchar(l_type_red,
                                                               l_label_status || pk_rcm_constant.g_space || l_label_new ||
                                                               pk_rcm_constant.g_colon,
                                                               l_tab_diff(i).status_new);
            END IF;
        
            --IF l_tab_diff(i).rcm_notes IS NOT NULL
            IF dbms_lob.getlength(l_tab_diff(i).rcm_notes) != 0
            THEN
                o_list_hist.extend;
                o_list_hist(o_list_hist.last) := table_varchar(l_type_red,
                                                               l_label_notes || pk_rcm_constant.g_space || l_label_new ||
                                                               pk_rcm_constant.g_colon,
                                                               l_tab_diff(i).rcm_notes);
            END IF;
        
            IF l_prev_dt IS NULL
               OR l_prev_dt != l_tab_diff(i).dt_status
               OR l_prev_id IS NULL
               OR l_prev_id != l_tab_diff(i).id_rcm_det_h
            THEN
                -- documented
                o_list_hist.extend;
                o_list_hist(o_list_hist.last) := table_varchar(l_type_italic,
                                                               l_label_documented || pk_rcm_constant.g_colon,
                                                               l_tab_diff(i).documented);
            
            END IF;
        
            l_prev_id := l_tab_diff(i).id_rcm_det_h;
            l_prev_dt := l_tab_diff(i).dt_status;
        
        END LOOP;
    
        -- created record
        g_error := 'create record';
        o_list_hist.extend(6);
        o_list_hist(o_list_hist.last - 5) := table_varchar(l_type_title, l_label_created, NULL);
        o_list_hist(o_list_hist.last - 4) := table_varchar(l_type_bold,
                                                           l_tab_rcm_data(l_tab_rcm_data.last)
                                                           .rcm_type_desc || pk_rcm_constant.g_colon,
                                                           l_tab_rcm_data(l_tab_rcm_data.last).rcm_desc);
        o_list_hist(o_list_hist.last - 3) := table_varchar(l_type_bold,
                                                           l_label_rcm_text || pk_rcm_constant.g_colon,
                                                           l_tab_rcm_data(l_tab_rcm_data.last).rcm_text);
        o_list_hist(o_list_hist.last - 2) := table_varchar(l_type_bold,
                                                           l_label_status || pk_rcm_constant.g_colon,
                                                           l_tab_rcm_data(l_tab_rcm_data.last).status_desc);
    
        IF l_tab_rcm_data(l_tab_rcm_data.last).rcm_notes IS NOT NULL
        THEN
            o_list_hist(o_list_hist.last - 1) := table_varchar(l_type_bold,
                                                               l_label_notes || pk_rcm_constant.g_colon,
                                                               l_tab_rcm_data(l_tab_rcm_data.last).rcm_notes);
        END IF;
    
        o_list_hist(o_list_hist.last) := table_varchar(l_type_italic,
                                                       l_label_documented || pk_rcm_constant.g_colon,
                                                       l_tab_rcm_data(l_tab_rcm_data.last)
                                                       .prof_name_status || pk_rcm_constant.g_semicolon ||
                                                        pk_date_utils.date_char_tsz(i_lang,
                                                                                    l_tab_rcm_data(l_tab_rcm_data.last)
                                                                                    .dt_status_tstz,
                                                                                    i_prof.institution,
                                                                                    i_prof.software));
    
        --actual record
        g_error := 'actual record';
    
        o_list_act.extend(6);
    
        o_list_act(o_list_act.last - 5) := table_varchar(l_type_title, l_tab_rcm_data(1).rcm_summ, NULL);
        o_list_act(o_list_act.last - 4) := table_varchar(l_type_bold,
                                                         l_tab_rcm_data(1).rcm_type_desc || pk_rcm_constant.g_colon,
                                                         l_tab_rcm_data(1).rcm_desc);
        o_list_act(o_list_act.last - 3) := table_varchar(l_type_bold,
                                                         l_label_rcm_text || pk_rcm_constant.g_colon,
                                                         l_tab_rcm_data(1).rcm_text);
        o_list_act(o_list_act.last - 2) := table_varchar(l_type_bold,
                                                         l_label_status || pk_rcm_constant.g_colon,
                                                         l_tab_rcm_data(1).status_desc);
    
        o_list_act(o_list_act.last - 1) := table_varchar(l_type_bold,
                                                         l_label_notes || pk_rcm_constant.g_colon,
                                                         l_tab_rcm_data(1).rcm_notes);
    
        o_list_act(o_list_act.last) := table_varchar(l_type_italic,
                                                     l_label_documented || pk_rcm_constant.g_colon,
                                                     l_tab_rcm_data(1)
                                                     .prof_name_status || pk_rcm_constant.g_semicolon ||
                                                      pk_date_utils.date_char_tsz(i_lang,
                                                                                  l_tab_rcm_data(1).dt_status_tstz,
                                                                                  i_prof.institution,
                                                                                  i_prof.software));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_rcm_det_flash;

    /**
    * Gets actual and historic data of this recommendation detail
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_rcm_data     Recommendation info
    * @param   o_error        Error information
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   27-04-2012
    */
    FUNCTION get_pat_rcm_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_rcm_data   OUT pk_rcm_constant.t_cur_rcm_info,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM_DET';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det;
        RETURN pk_rcm_core.get_pat_rcm_det(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_patient => i_id_patient,
                                           i_id_rcm     => i_id_rcm,
                                           i_id_rcm_det => i_id_rcm_det,
                                           o_rcm_data   => o_rcm_data,
                                           o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_rcm_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_rcm_det;

    /**
    * Updates recommendation status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Workflow identifier
    * @param   i_id_workflow_action       Workflow action identifier
    * @param   i_id_status_begin          Reccomendation status begin
    * @param   i_id_status_end            Reccomendation status end
    * @param   i_rcm_notes                Notes associated to this recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION set_pat_rcm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_rcm             IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det         IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow        IN pat_rcm_h.id_workflow%TYPE,
        i_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_begin    IN pat_rcm_h.id_status%TYPE,
        i_id_status_end      IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes          IN pat_rcm_h.notes%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_PAT_RCM';
        l_rcm_data            t_rec_rcm;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_func             sys_functionality.id_functionality%TYPE;
        l_empty_tv            table_varchar := table_varchar();
        l_flg_available       pk_rcm_constant.t_low_char;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_episode=' || i_id_episode;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        -- getting actual rcm data
        g_error    := 'Call pk_rcm_base.get_pat_rcm_data';
        l_rcm_data := pk_rcm_base.get_pat_rcm_data(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_rcm     => i_id_rcm,
                                                   i_id_rcm_det => i_id_rcm_det);
    
        IF -- id_workflow 
         (l_rcm_data.id_workflow != i_id_workflow)
         OR (l_rcm_data.id_workflow IS NULL AND i_id_workflow IS NOT NULL)
         OR (l_rcm_data.id_workflow IS NOT NULL AND i_id_workflow IS NULL)
        -- id_status
         OR (l_rcm_data.id_status != i_id_status_begin)
         OR (l_rcm_data.id_status IS NULL AND i_id_status_begin IS NOT NULL)
         OR (l_rcm_data.id_status IS NOT NULL AND i_id_status_begin IS NULL)
        -- id_rcm_det
         OR (l_rcm_data.id_rcm_det != i_id_rcm_det)
         OR (l_rcm_data.id_rcm_det IS NULL AND i_id_rcm_det IS NOT NULL)
         OR (l_rcm_data.id_rcm_det IS NOT NULL AND i_id_rcm_det IS NULL)
        
        THEN
            g_error := l_func_name || ': id_worklow, id_status or id_rcm_det are inconsistent / i_id_patient=' ||
                       i_id_patient || ' i_id_episode=' || i_id_episode || ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' ||
                       i_id_rcm_det || ' i_id_workflow=' || i_id_workflow || ' i_id_workflow_action=' ||
                       i_id_workflow_action || ' i_id_status_begin=' || i_id_status_begin || ' i_id_status_end=' ||
                       i_id_status_end || ' / ID_STATUS=' || l_rcm_data.id_status || ' ID_WORKFLOW=' ||
                       l_rcm_data.id_workflow || ' ID_RCM_DET=' || l_rcm_data.id_rcm_det;
            RAISE g_exception_np;
        END IF;
    
        -- check if transition is still available
        g_error  := l_func_name || ': Call pk_workflow.check_transition / i_id_workflow=' || l_rcm_data.id_workflow ||
                    ' i_id_status_begin=' || l_rcm_data.id_status || ' i_id_status_end=' || i_id_status_end ||
                    ' i_id_workflow_action=' || i_id_workflow_action || ' l_id_category=' || l_id_category ||
                    ' l_id_profile_template=' || l_id_profile_template || ' l_id_func=' || l_id_func;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => l_rcm_data.id_workflow,
                                                 i_id_status_begin     => l_rcm_data.id_status,
                                                 i_id_status_end       => i_id_status_end,
                                                 i_id_workflow_action  => i_id_workflow_action,
                                                 i_id_category         => l_id_category,
                                                 i_id_profile_template => l_id_profile_template,
                                                 i_id_functionality    => l_id_func,
                                                 i_param               => l_empty_tv,
                                                 o_flg_available       => l_flg_available,
                                                 o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_alert_constant.get_no
        THEN
            g_error := l_func_name || ': Transition not available / i_id_patient=' || i_id_patient || ' i_id_episode=' ||
                       i_id_episode || ' i_id_rcm=' || i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det ||
                       ' i_id_workflow=' || i_id_workflow || ' i_id_workflow_action=' || i_id_workflow_action ||
                       ' i_id_status_begin=' || i_id_status_begin || ' i_id_status_end=' || i_id_status_end;
            RAISE g_exception;
        END IF;
    
        g_error  := l_func_name || ' : Call pk_rcm_core.set_pat_rcm / i_id_patient=' || i_id_patient || ' i_id_rcm=' ||
                    i_id_rcm || ' i_id_rcm_det=' || i_id_rcm_det || ' i_id_episode=' || i_id_episode ||
                    ' i_id_workflow=' || i_id_workflow || ' i_id_workflow_action=' || i_id_workflow_action ||
                    ' i_id_status_begin=' || i_id_status_begin || ' i_id_status_end=' || i_id_status_end ||
                    ' i_id_category=' || l_id_category || ' i_id_profile_template=' || l_id_profile_template ||
                    ' i_id_functionality=' || l_id_func;
        g_retval := pk_rcm_core.set_pat_rcm(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_patient          => i_id_patient,
                                            i_id_episode          => i_id_episode,
                                            i_id_rcm              => i_id_rcm,
                                            i_id_rcm_det          => i_id_rcm_det,
                                            i_id_workflow         => i_id_workflow,
                                            i_id_workflow_action  => i_id_workflow_action,
                                            i_id_status_begin     => i_id_status_begin,
                                            i_id_status_end       => i_id_status_end,
                                            i_rcm_notes           => i_rcm_notes,
                                            i_id_category         => l_id_category,
                                            i_id_profile_template => l_id_profile_template,
                                            i_id_functionality    => l_id_func,
                                            i_param               => l_empty_tv,
                                            o_flg_show            => o_flg_show,
                                            o_msg_title           => o_msg_title,
                                            o_msg                 => o_msg,
                                            o_button              => o_button,
                                            o_error               => o_error);
    
        IF NOT g_retval
        THEN
            IF o_flg_show = pk_alert_constant.g_yes
            THEN
                pk_utils.undo_changes;
                RETURN TRUE; -- to show the message
            END IF;
        
            RAISE g_exception;
        END IF;
    
        pk_rcm_base.do_commit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_pat_rcm;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rcm_ux;
/
