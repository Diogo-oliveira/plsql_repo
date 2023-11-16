/*-- Last Change Revision: $Rev: 1965495 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-10-08 11:28:29 +0100 (qui, 08 out 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_print_list IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;

    -- workflow info
    g_id_workflow CONSTANT wf_workflow.id_workflow%TYPE := 41;

    -- workflow actions
    g_id_action_print    CONSTANT wf_workflow_action.id_workflow_action%TYPE := 650;
    g_id_action_cancel   CONSTANT wf_workflow_action.id_workflow_action%TYPE := 652;
    g_id_action_complete CONSTANT wf_workflow_action.id_workflow_action%TYPE := 651;
    g_id_action_error    CONSTANT wf_workflow_action.id_workflow_action%TYPE := 653;
    g_id_action_replace  CONSTANT wf_workflow_action.id_workflow_action%TYPE := 654;
    g_id_action_pending  CONSTANT wf_workflow_action.id_workflow_action%TYPE := 655;

    -- icons
    g_icon_small_printongoing CONSTANT VARCHAR2(30 CHAR) := 'smallPrintOngoingIcon';
    g_icon_small_print_error  CONSTANT VARCHAR2(30 CHAR) := 'smallPrintErrorIcon';

    -- functionality
    g_func_can_print CONSTANT sys_functionality.intern_name_func%TYPE := 'PRINT_LIST_CAN_PRINT';
    g_func_can_add   CONSTANT sys_functionality.intern_name_func%TYPE := 'PRINT_LIST_CAN_ADD';

    g_code_status             CONSTANT sys_domain.code_domain%TYPE := 'PRINT_LIST.ID_STATUS';
    g_print_list_generate_rep CONSTANT sys_config.id_sys_config%TYPE := 'PRINT_LIST_GENERATE_REPORT';

    -- indexes to be used in workflows (table_varchar)
    g_idx_print_list_job  CONSTANT PLS_INTEGER := 1;
    g_idx_id_prof_req     CONSTANT PLS_INTEGER := 2;
    g_idx_func_can_print  CONSTANT PLS_INTEGER := 3;
    g_idx_ignore_prof_req CONSTANT PLS_INTEGER := 4;

    /**
    * Function for get buttons identifier that professional have access
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)    
    * @param   i_id_buttons                List of buttons identifier
    * @param   i_id_sys_button_prop        Sys_button_prop Identifier (used for get acesses for childrens)
    * @param   i_flg_create                Flag Create button
    * @param   i_flg_cancel                Flag Cancel button 
    * @param   i_flg_action                Flag Action button
    * @param   o_access_id_buttons         Identifier of buttons that have respective acesses
    * @param   o_error                     Error information
    *
    * @value   i_flg_create                {*} N - not applicable {*} I - inactive {*} A - active
    * @value   i_flg_cancel                {*} N - not applicable {*} I - inactive {*} A - active
    * @value   i_flg_action                {*} N - not applicable {*} I - inactive {*} A - active
    *
    * @return  boolean                     True on sucess, otherwise false                    
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION get_prof_access_button
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_buttons         IN table_number,
        i_id_sys_button_prop IN sys_button_prop.id_btn_prp_parent%TYPE,
        i_flg_create         IN profile_templ_access.flg_create%TYPE DEFAULT NULL,
        i_flg_cancel         IN profile_templ_access.flg_cancel%TYPE DEFAULT NULL,
        i_flg_action         IN profile_templ_access.flg_action%TYPE DEFAULT NULL,
        o_access_id_buttons  OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_prof_access_button';
    
        l_id_sys_button_prop table_number := table_number(i_id_sys_button_prop);
    BEGIN
    
        l_params := 'i_lang= ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_buttons = ' ||
                    pk_utils.to_string(i_id_buttons) || ' i_id_sys_button_prop=' || i_id_sys_button_prop ||
                    ' i_flg_create=' || i_flg_create || ' i_flg_cancel=' || i_flg_cancel || ' i_flg_action=' ||
                    i_flg_action;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- get buttons to which the professional has access to
        g_error := 'Select distinct id_sys_button / ' || l_params;
        SELECT DISTINCT id_sys_button
          BULK COLLECT
          INTO o_access_id_buttons
          FROM TABLE(pk_access.get_access(i_lang, i_prof, null, null, l_id_sys_button_prop)) ac
         WHERE ac.id_sys_button IN (SELECT /*+ OPT_ESTIMATE(table t rows = 1) */
                                     column_value
                                      FROM TABLE(i_id_buttons) t)
           AND nvl(ac.flg_create, -1) = nvl(i_flg_create, nvl(ac.flg_create, -1))
           AND nvl(ac.flg_cancel, -1) = nvl(i_flg_cancel, nvl(ac.flg_cancel, -1))
           AND nvl(ac.flg_action, -1) = nvl(i_flg_action, nvl(ac.flg_action, -1));
    
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
            RETURN FALSE;
    END get_prof_access_button;

    FUNCTION get_print_list_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            g_error := 'CALL PK_EPISODE.GET_EPIS_TYPE';
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_adt
        THEN
            IF l_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_urgent_care)
            THEN
                o_shortcut := 821797;
            ELSIF l_epis_type = pk_alert_constant.g_epis_type_inpatient
            THEN
                o_shortcut := 821801;
            ELSE
                o_shortcut := 821805;
            END IF;
        ELSIF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
                o_shortcut := 53000008;
            ELSE
                o_shortcut := 53000024;
            END IF;
        ELSE
            o_shortcut := 53000008;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PRINT_LIST_SHORTCUT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_print_list_shortcut;

    /**
    * Add print list job to history table
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)  
    * @param   i_print_list_job_row    Print list job row
    * @param   o_id_hist               Print list job history identifier
    * @param   o_error                 Error information    
    *
    * @return  boolean                 True on sucess, otherwise false
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION insert_print_list_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_print_list_job_row IN print_list_job%ROWTYPE,
        o_id_hist            OUT print_list_job_hist.id_print_list_job_hist%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'insert_print_list_hist';
    
        l_hist_row print_list_job_hist%ROWTYPE;
        l_rowids   table_varchar;
    
    BEGIN
    
        l_params := 'i_lang= ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' id_print_list_job=' ||
                    i_print_list_job_row.id_print_list_job;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- prepare print list job history row
        l_hist_row.id_print_list_job_hist := seq_print_list_job_hist.nextval;
        l_hist_row.id_print_list_job      := i_print_list_job_row.id_print_list_job;
        l_hist_row.id_print_list_area     := i_print_list_job_row.id_print_list_area;
        l_hist_row.print_arguments        := i_print_list_job_row.print_arguments;
        l_hist_row.id_workflow            := i_print_list_job_row.id_workflow;
        l_hist_row.id_status              := i_print_list_job_row.id_status;
        l_hist_row.dt_status              := i_print_list_job_row.dt_status;
        l_hist_row.id_prof_status         := i_print_list_job_row.id_prof_status;
        l_hist_row.id_patient             := i_print_list_job_row.id_patient;
        l_hist_row.id_episode             := i_print_list_job_row.id_episode;
        l_hist_row.id_prof_req            := i_print_list_job_row.id_prof_req;
        l_hist_row.id_inst_req            := i_print_list_job_row.id_inst_req;
        l_hist_row.dt_req                 := i_print_list_job_row.dt_req;
        l_hist_row.context_data           := i_print_list_job_row.context_data;
    
        -- insert print list job history row
        g_error := 'Call ts_print_list_job_hist.ins / ' || l_params;
        ts_print_list_job_hist.ins(rec_in => l_hist_row, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRINT_LIST_JOB_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- return print list job history identifier
        o_id_hist := l_hist_row.id_print_list_job_hist;
    
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
            RETURN FALSE;
    END insert_print_list_hist;

    /**
    * Check if a transition is valid
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_workflow                Workflow identifier
    * @param   i_id_status_begin            Begin status identifier
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_id_category                Category identifier
    * @param   i_id_profile_template        Profile template identifier
    * @param   i_id_print_list_job          Print list job identifier
    * @param   i_id_prof_req                Professional that requested the print list job
    * @param   i_func_can_print             Indicates if this professional has the functionality of printing permissions
    * @param   i_flg_ignore_prof_req        This job can be canceled by any professional (not only by the one that added this print list job)?
    *
    * @value   i_func_can_print             {*} Y- professional has permission to print {*} N- otherwise
    * @value   i_flg_ignore_prof_req        {*} Y- Yes {*} N- No
    *
    * @return  varchar2                     'Y'- transition allowed 'N'- transition denied
    *
    * @author  ana.monteiro
    * @since   14-10-2014
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN print_list_job.id_workflow%TYPE,
        i_id_status_begin     IN print_list_job.id_status%TYPE,
        i_id_status_end       IN print_list_job.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_print_list_job   IN print_list_job.id_print_list_job%TYPE,
        i_id_prof_req         IN print_list_job.id_prof_req%TYPE,
        i_func_can_print      IN VARCHAR2,
        i_flg_ignore_prof_req IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_transition';
        l_params              VARCHAR2(1000 CHAR);
        l_wf_params           table_varchar;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_result              VARCHAR2(1 CHAR);
        l_error_out           t_error_out;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_status_begin=' || i_id_status_begin || ' i_id_status_end=' ||
                    i_id_status_end || ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_category=' ||
                    i_id_category || ' i_id_profile_template=' || i_id_profile_template || ' i_id_print_list_job=' ||
                    i_id_print_list_job || ' i_id_prof_req=' || i_id_prof_req || ' i_func_can_print=' ||
                    i_func_can_print || ' i_flg_ignore_prof_req=' || i_flg_ignore_prof_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
        l_result := pk_alert_constant.g_no;
    
        -- func
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        -- check workflow permission
        g_error     := 'Call init_wf_params / ' || l_params;
        l_wf_params := init_wf_params(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_print_list_job   => i_id_print_list_job,
                                      i_id_prof_req         => i_id_prof_req,
                                      i_func_can_print      => i_func_can_print,
                                      i_flg_ignore_prof_req => i_flg_ignore_prof_req);
    
        g_error  := 'Call pk_workflow.check_transition / ' || l_params;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => i_id_workflow,
                                                 i_id_status_begin     => i_id_status_begin,
                                                 i_id_status_end       => i_id_status_end,
                                                 i_id_workflow_action  => i_id_workflow_action,
                                                 i_id_category         => l_id_category,
                                                 i_id_profile_template => l_id_profile_template,
                                                 i_id_functionality    => NULL,
                                                 i_param               => l_wf_params,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_alert_constant.g_no;
    END check_transition;

    /**
     * Get print list configs
     *
     * @param   i_lang                 Professional preferred language
     * @param   i_prof                 Professional identification and its context (institution and software)   
     * @param   i_print_list_area      Print list area identifier
     * @param   o_print_list_cfgs      V_PRINT_LIST_CFG row with print list configs
     * @param   o_error                Error information     
     *
     * @return  boolean                True on sucess, otherwise false          
     *
     * @author  miguel.gomes
     * @since   30-09-2014
    */
    FUNCTION get_print_list_configs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        o_print_list_cfgs OUT v_print_list_cfg%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_list_configs';
    
        l_id_market           market.id_market%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_area=' ||
                    i_print_list_area;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        -- get all configs for a given print list area
        g_error := 'Get all configs for a given print list area / ' || l_params;
        SELECT *
          INTO o_print_list_cfgs
          FROM (SELECT *
                  FROM v_print_list_cfg vplc
                 WHERE vplc.id_print_list_area = i_print_list_area
                   AND vplc.id_institution IN (i_prof.institution, 0)
                   AND vplc.id_professional IN (i_prof.id, 0)
                   AND vplc.id_software IN (i_prof.software, 0)
                   AND vplc.id_market IN (l_id_market, 0)
                   AND vplc.id_category IN (l_id_category, 0)
                   AND vplc.id_profile_template IN (l_id_profile_template, 0)
                 ORDER BY vplc.id_market           DESC,
                          vplc.id_institution      DESC,
                          vplc.id_software         DESC,
                          vplc.id_category         DESC,
                          vplc.id_profile_template DESC,
                          vplc.id_professional     DESC)
         WHERE rownum = 1;
    
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
            RETURN FALSE;
    END get_print_list_configs;

    /**
    * Gets all print list jobs identifiers of the print list
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)   
    * @param   i_patient               Patient identifier
    * @param   i_episode               Episode identifier
    * @param   i_print_list_area       Print list area identifier
    *
    * @return  table_number            Print list jobs identifiers that are in print list
    *
    * @author  ana.monteiro
    * @since   15-10-2014
    */
    FUNCTION get_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN print_list_job.id_patient%TYPE,
        i_episode         IN print_list_job.id_episode%TYPE,
        i_print_list_area IN print_list_job.id_print_list_area%TYPE
    ) RETURN table_number IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_list_jobs';
    
        l_print_list_jobs table_number;
    BEGIN
    
        l_params := 'i_lang = ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- getting all print_list_jobs that exists in printing list of this area/episode
        g_error := 'SELECT plj.id_print_list_job / ' || l_params;
        SELECT plj.id_print_list_job
          BULK COLLECT
          INTO l_print_list_jobs
          FROM print_list_job plj
         WHERE plj.id_patient = i_patient
           AND plj.id_episode = i_episode
           AND plj.id_print_list_area = nvl(i_print_list_area, plj.id_print_list_area);
    
        RETURN l_print_list_jobs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN table_number();
    END get_print_list_jobs;

    /**
    * Gets all print list jobs print arguments
    * Used by reports in order to generate reports in background
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)   
    * @param   i_id_print_list_jobs    Array of print list jobs identifiers
    * @param   o_print_args            Print arguments of the print list jobs identifiers
    * @param   o_error                 Error information
    *
    * @return  boolean                 True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   17-10-2014
    */
    FUNCTION get_print_list_jobs_args
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_print_list_jobs IN table_number,
        o_print_args         OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_list_jobs_args';
    BEGIN
        l_params := 'i_lang= ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_jobs=' ||
                    pk_utils.to_string(i_id_print_list_jobs);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        o_print_args := table_varchar();
    
        -- getting all print_list_jobs arguments to return to the reports
        g_error := 'SELECT plj.id_print_list_job / ' || l_params;
        SELECT /*+ opt_estimate(table t rows = 1) */
         plj.print_arguments
          BULK COLLECT
          INTO o_print_args
          FROM print_list_job plj
          JOIN TABLE(i_id_print_list_jobs) t
            ON plj.id_print_list_job = t.column_value;
    
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
            RETURN FALSE;
    END get_print_list_jobs_args;

    /**
    * Gets print list configuration to generate report
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)  
    * @param   o_config         Config value
    * @param   o_error          Error information
    *
    * @value   o_config         {*} PP - Preview and print
    *                           {*} P  - Print
    *                           {*} BP - Generate in background and print
    *                           {*} B  - Only generate in background  
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   08-10-2014
    */
    FUNCTION get_generate_report_cfg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_config OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_generate_report_cfg';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'i_lang= ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        --- get config to generate report
        o_config := pk_sysconfig.get_config(i_code_cf => g_print_list_generate_rep, i_prof => i_prof);
        -- background cannot be implemented yet
        o_config := 'PP'; -- preview and print
    
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
            RETURN FALSE;
    END get_generate_report_cfg;

    /**
    * Get print jobs list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)  
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   o_print_list_jobs    Cursor with the print jobs list
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   23-09-2014
    */
    FUNCTION get_print_jobs_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_print_jobs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_jobs_list';
        l_prof_id_category         category.id_category%TYPE;
        l_prof_id_profile_template profile_template.id_profile_template%TYPE;
        l_flg_func_can_print       VARCHAR2(1 CHAR);
    BEGIN
    
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        l_prof_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_prof_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error  := 'Call pk_print_list.check_func_can_print / ' || l_params;
        g_retval := pk_print_list.check_func_can_print(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       o_flg_can_print => l_flg_func_can_print,
                                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_print_jobs / ' || l_params;
        OPEN o_print_jobs FOR
            SELECT id_print_list_job AS print_list_job_id,
                   print_list_title,
                   print_list_sub_title,
                   print_list_date,
                   (CASE print_list_flg_enable
                       WHEN pk_alert_constant.g_no THEN
                        pk_alert_constant.g_inactive
                       ELSE
                        pk_alert_constant.g_active
                   END) AS print_list_flg_select,
                   print_list_flg_enable,
                   print_list_icon,
                   '<b>' || print_list_title || '</b>' || chr(10) || print_list_sub_title ||
                   nvl2(print_list_sub_title, chr(10), NULL) || print_list_date || chr(10) || chr(10) ||
                   pk_print_list.get_status_desc(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => id_workflow,
                                                 i_id_status           => id_status,
                                                 i_id_category         => l_prof_id_category,
                                                 i_id_profile_template => l_prof_id_profile_template) AS print_list_tooltip,
                   print_arguments,
                   id_print_list_area
              FROM (SELECT plj.id_print_list_job,
                           pk_print_list.get_print_job_info(i_lang, i_prof, plj.id_print_list_job, plj.id_print_list_area).get_title() AS print_list_title,
                           pk_print_list.get_print_job_info(i_lang, i_prof, plj.id_print_list_job, plj.id_print_list_area).get_subtitle() AS print_list_sub_title,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, plj.dt_req, i_prof) AS print_list_date,
                           pk_print_list.check_can_print(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_workflow         => plj.id_workflow,
                                                         i_id_status_begin     => plj.id_status,
                                                         i_id_category         => l_prof_id_category,
                                                         i_id_profile_template => l_prof_id_profile_template,
                                                         i_id_print_list_job   => plj.id_print_list_job,
                                                         i_id_prof_req         => plj.id_prof_req,
                                                         i_func_can_print      => l_flg_func_can_print) AS print_list_flg_enable,
                           (CASE plj.id_status
                               WHEN g_id_sts_printing THEN
                                g_icon_small_printongoing
                               WHEN g_id_sts_error THEN
                                g_icon_small_print_error
                               ELSE
                                NULL
                           END) AS print_list_icon,
                           plj.id_status,
                           plj.id_workflow,
                           plj.print_arguments,
                           plj.id_print_list_area,
                           plj.dt_status
                      FROM print_list_job plj
                     WHERE plj.id_patient = i_patient
                       AND plj.id_episode = i_episode
                       AND (plj.id_print_list_area IS NULL OR plj.id_print_list_area <> g_print_list_area_lab_test OR
                           pk_lab_tests_external_api_db.get_lab_tests_allowed(i_lang    => i_lang,
                                                                               i_prof    => i_prof,
                                                                               i_context => plj.context_data) > 0))
            -- this order by must be the same as filter 'PrintList'
             ORDER BY pk_print_list.get_status_rank(i_lang,
                                                    i_prof,
                                                    id_workflow,
                                                    id_status,
                                                    l_prof_id_category,
                                                    l_prof_id_profile_template),
                      dt_status DESC,
                      pk_print_list.get_print_job_info(i_lang, i_prof, id_print_list_job, id_print_list_area).get_title();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_print_jobs);
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
            pk_types.open_my_cursor(o_print_jobs);
            RETURN FALSE;
    END get_print_jobs_list;

    /**
    * Gets print list job status string
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)  
    * @param   i_id_status          Print list job status
    *
    * @return  varchar2             Print list job status string
    *
    * @author  ana.monteiro
    * @since   29-09-2014
    */
    FUNCTION get_job_status_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN print_list_job.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_job_status_string';
        l_params VARCHAR2(1000 CHAR);
    
        l_status_string VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_status=' || i_id_status;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_display_type => pk_alert_constant.g_display_type_icon,
                                                                i_flg_state    => i_id_status,
                                                                i_value_icon   => g_code_status);
    
        RETURN l_status_string;
    END get_job_status_string;

    /**
    * Checks if this professional has the functionality of printing
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_flg_can_print       Flag that indicates if professional has the functionality of printing
    * @param   o_error               Error information
    *
    * @value   o_flg_can_print       {*} Y- this professional has the functionality of printing {*} N- otherwise
    *  
    * @return  boolean               True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   29-09-2014
    */
    FUNCTION check_func_can_print
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_flg_can_print OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_func_can_print';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error         := 'Call pk_prof_utils.check_has_functionality / ' || l_params;
        o_flg_can_print := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_intern_name => g_func_can_print);
    
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
            RETURN FALSE;
    END check_func_can_print;

    /**
    * Checks if this professional can add a job to the print list
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_flg_can_add         Flag that indicates if professional can add a job to the print list
    * @param   o_error               Error information
    *
    * @value   o_flg_can_add         {*} Y- this professional can add {*} N- otherwise
    *  
    * @return  boolean               True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   09-10-2014
    */
    FUNCTION check_func_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_func_can_add';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error       := 'Call pk_prof_utils.check_has_functionality / ' || l_params;
        o_flg_can_add := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_intern_name => g_func_can_add);
    
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
            RETURN FALSE;
    END check_func_can_add;

    /**
    * Check if this print list job can be printed by this professional
    * Used by workflows framework
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_workflow                Workflow identifier
    * @param   i_id_status_begin            Begin status identifier
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_id_category                Category identifier
    * @param   i_id_profile_template        Profile template identifier
    * @param   i_id_print_list_job          Print list job identifier
    * @param   i_id_prof_req                Professional that requested the print list job
    * @param   i_func_can_print             Indicates if this professional has the functionality of printing permissions
    *
    * @value   i_func_can_print             {*} Y- professional has permission to print {*} N- otherwise
    *
    * @return  varchar2                     'Y'- transition allowed 'N'- transition denied
    *
    * @author  ana.monteiro
    * @since   14-10-2014
    */
    FUNCTION check_can_print
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN print_list_job.id_workflow%TYPE,
        i_id_status_begin     IN print_list_job.id_status%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_print_list_job   IN print_list_job.id_print_list_job%TYPE,
        i_id_prof_req         IN print_list_job.id_prof_req%TYPE,
        i_func_can_print      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_print';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_status_begin=' || i_id_status_begin || ' i_id_category=' || i_id_category ||
                    ' i_id_profile_template=' || i_id_profile_template || ' i_id_print_list_job=' ||
                    i_id_print_list_job || ' i_id_prof_req=' || i_id_prof_req || ' i_func_can_print=' ||
                    i_func_can_print;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        -- check workflow permission
        RETURN check_transition(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_id_workflow         => i_id_workflow,
                                i_id_status_begin     => i_id_status_begin,
                                i_id_status_end       => g_id_sts_printing,
                                i_id_workflow_action  => g_id_action_print,
                                i_id_category         => i_id_category,
                                i_id_profile_template => i_id_profile_template,
                                i_id_print_list_job   => i_id_print_list_job,
                                i_id_prof_req         => i_id_prof_req,
                                i_func_can_print      => i_func_can_print,
                                i_flg_ignore_prof_req => NULL);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_alert_constant.g_no;
    END check_can_print;

    /**
    * Check if this print list job can be cancelled by this professional
    * Used by filters
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_workflow                Workflow identifier
    * @param   i_id_status_begin            Begin status identifier
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_id_category                Category identifier
    * @param   i_id_profile_template        Profile template identifier
    * @param   i_id_print_list_job          Print list job identifier
    * @param   i_id_prof_req                Professional that requested the print list job
    * @param   i_func_can_print             Indicates if this professional has the functionality of printing permissions
    * @param   i_flg_ignore_prof_req        This job can be canceled by any professional (not only by the one that added this print list job)?
    *
    * @value   i_func_can_print             {*} Y- professional has permission to print {*} N- otherwise
    * @value   i_flg_ignore_prof_req        {*} Y- Yes {*} N- No
    *
    * @return  varchar2                     'Y'- transition allowed 'N'- transition denied
    *
    * @author  ana.monteiro
    * @since   14-10-2014
    */
    FUNCTION check_can_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN print_list_job.id_workflow%TYPE,
        i_id_status_begin     IN print_list_job.id_status%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_print_list_job   IN print_list_job.id_print_list_job%TYPE,
        i_id_prof_req         IN print_list_job.id_prof_req%TYPE,
        i_func_can_print      IN VARCHAR2,
        i_flg_ignore_prof_req IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_cancel';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_status_begin=' || i_id_status_begin || ' i_id_category=' || i_id_category ||
                    ' i_id_profile_template=' || i_id_profile_template || ' i_id_print_list_job=' ||
                    i_id_print_list_job || ' i_id_prof_req=' || i_id_prof_req || ' i_func_can_print=' ||
                    i_func_can_print || ' i_flg_ignore_prof_req=' || i_flg_ignore_prof_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        -- check workflow permission
        RETURN check_transition(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_id_workflow         => i_id_workflow,
                                i_id_status_begin     => i_id_status_begin,
                                i_id_status_end       => g_id_sts_canceled,
                                i_id_workflow_action  => g_id_action_cancel,
                                i_id_category         => i_id_category,
                                i_id_profile_template => i_id_profile_template,
                                i_id_print_list_job   => i_id_print_list_job,
                                i_id_prof_req         => i_id_prof_req,
                                i_func_can_print      => i_func_can_print,
                                i_flg_ignore_prof_req => i_flg_ignore_prof_req);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_alert_constant.g_no;
    END check_can_cancel;

    /**
    * Gets mapping contexts in print list grid
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etc)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  ana.monteiro
    * @since   29-09-2014
    */
    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
        g_search_field     CONSTANT NUMBER(24) := 7;
    
        l_prof         profissional;
        l_lang         language.id_language%TYPE;
        l_patient      patient.id_patient%TYPE;
        l_episode      episode.id_episode%TYPE;
        l_search_field VARCHAR2(1000 CHAR);
        l_error_out    t_error_out;
    BEGIN
    
        l_prof    := profissional(i_context_ids(g_prof_id),
                                  i_context_ids(g_prof_institution),
                                  i_context_ids(g_prof_software));
        l_lang    := i_context_ids(g_lang);
        l_patient := i_context_ids(g_patient);
        l_episode := i_context_ids(g_episode);
    
        g_error := 'i_name=' || i_name;
        IF i_context_vals IS NULL
        THEN
            l_search_field := '';
        
        ELSIF i_context_vals.count > 0
              AND i_context_vals.exists(g_search_field)
        THEN
            l_search_field := i_context_vals(g_search_field);
        ELSE
            l_search_field := '';
        END IF;
    
        g_error := 'i_name=' || i_name || ' l_search_field=' || l_search_field;
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
                pk_context_api.set_parameter('PROF_ID', o_id);
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
                pk_context_api.set_parameter('ID_INSTITUTION', o_id);
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
                pk_context_api.set_parameter('ID_SOFTWARE', o_id);
            
            WHEN 'i_patient' THEN
                o_id := l_patient;
            
            WHEN 'i_episode' THEN
                o_id := l_episode;
            
            WHEN 'g_id_workflow' THEN
                o_id := g_id_workflow;
            
            WHEN 'g_id_sts_completed' THEN
                o_id := g_id_sts_completed;
            
            WHEN 'g_id_sts_canceled' THEN
                o_id := g_id_sts_canceled;
            
            WHEN 'g_id_sts_replaced' THEN
                o_id := g_id_sts_replaced;
            
            WHEN 'search_field' THEN
                o_vc2 := l_search_field;
            
            WHEN 'i_prof_id_cat' THEN
                o_id := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_prof_templ' THEN
                o_id := pk_prof_utils.get_prof_profile_template(l_prof);
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            
            WHEN 'g_active' THEN
                o_vc2 := pk_alert_constant.g_active;
            
            WHEN 'g_func_can_print' THEN
                g_retval := check_func_can_print(i_lang          => l_lang,
                                                 i_prof          => l_prof,
                                                 o_flg_can_print => o_vc2,
                                                 o_error         => l_error_out);
            
                IF NOT g_retval
                THEN
                    o_vc2 := pk_alert_constant.g_no;
                END IF;
            
        END CASE;
    
    END init_params;

    /**
    * Gets print job information to populate grids
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)   
    * @param   i_print_list_job        Print list job identifier
    * @param   i_print_list_area       Print list area identifier
    *
    * @return  t_rec_print_list_job    Print list job information
    *
    * @author  ana.monteiro
    * @since   30-09-2014
    */
    FUNCTION get_print_job_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN print_list_job.id_print_list_job%TYPE,
        i_print_list_area IN print_list_job.id_print_list_area%TYPE
    ) RETURN t_rec_print_list_job IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_job_info';
    
        l_func print_list_area.func_print_job_info%TYPE;
        l_sql  VARCHAR2(1000 CHAR);
    
        l_result t_rec_print_list_job := t_rec_print_list_job();
    BEGIN
    
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_job=' ||
                    i_print_list_job || ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
    
        -- getting function by print_list_area
        g_error := 'SELECT pla.func_print_job_info / ' || l_params;
        SELECT pla.func_print_job_info
          INTO l_func
          FROM print_list_area pla
         WHERE pla.id_print_list_area = i_print_list_area;
    
        -- returning result of print_list_area.FUNC_PRINT_JOB_INFO
        -- PK_PACKAGE.function_name(:LANG, profissional(:PROFESSIONAL,:INSTITUTION,:SOFTWARE),:ID_PRINT_LIST_JOB)            
    
        -- build select
        l_sql := 'SELECT ' || l_func || ' from dual';
    
        -- execute immediate function, using bind variables
        g_error := 'EXECUTE IMMEDIATE / l_sql=' || l_sql || ' / ' || l_params;
        EXECUTE IMMEDIATE l_sql
            INTO l_result
            USING i_lang, -- :LANG
        i_prof.id, -- :PROFESSIONAL
        i_prof.institution, -- :INSTITUTION
        i_prof.software, -- :SOFTWARE
        i_print_list_job; -- :ID_PRINT_LIST_JOB
    
        -- set print list area identifier
        g_error                     := 'set print list area identifier / ' || l_params;
        l_result.id_print_list_area := i_print_list_area;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN t_rec_print_list_job();
    END get_print_job_info;

    /**
    * Gets print job name to populate grids
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_print_list_job     Print list job identifier
    * @param   i_print_list_area    Print list area identifier
    * @param   i_flg_bold_title     Flag that indicates if title must be return in bold format or not
    *
    * @value   i_flg_bold_title     {*} Y- bold {*} N- normal
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author  ana.monteiro
    * @since   02-10-2014
    */
    FUNCTION get_print_job_name
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN print_list_job.id_print_list_job%TYPE,
        i_print_list_area IN print_list_job.id_print_list_area%TYPE,
        i_flg_bold_title  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_job_name';
        l_format_bold_string VARCHAR2(10 CHAR) := (CASE i_flg_bold_title
                                                      WHEN pk_alert_constant.g_yes THEN
                                                       '<b>@</b>'
                                                      ELSE
                                                       '@'
                                                  END);
    
        l_print_list_job_info t_rec_print_list_job := t_rec_print_list_job();
        l_subtitle            VARCHAR2(1000 CHAR);
        l_result              VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_job=' ||
                    i_print_list_job || ' i_print_list_area=' || i_print_list_area || ' i_flg_bold_title=' ||
                    i_flg_bold_title;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        -- getting print list job information
        g_error               := 'Call pk_print_list.get_print_job_info / ' || l_params;
        l_print_list_job_info := pk_print_list.get_print_job_info(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_print_list_job  => i_print_list_job,
                                                                  i_print_list_area => i_print_list_area);
    
        -- getting title
        g_error  := 'Get title / ' || l_params;
        l_result := l_print_list_job_info.get_title();
    
        -- format description in bold if necessary
        l_result := REPLACE(l_format_bold_string, '@', l_result);
    
        -- getting subtitle
        g_error    := 'Get subtitle / ' || l_params;
        l_subtitle := l_print_list_job_info.get_subtitle();
        IF l_subtitle IS NOT NULL
        THEN
            IF i_flg_bold_title = pk_alert_constant.g_yes
            THEN
                l_result := l_result || '<br>' || l_subtitle;
            ELSE
                l_result := l_result || chr(10) || l_subtitle;
            END IF;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_print_job_name;

    /**
    * Gets the rank of a print list job to be shown in grids
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    *
    * @return  number                 Status rank
    *
    * @author  ana.monteiro
    * @since   30-09-2014
    */
    FUNCTION get_status_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE DEFAULT 0,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE DEFAULT 0
    ) RETURN NUMBER IS
        l_status_rank wf_status_config.rank%TYPE;
    BEGIN
        g_error       := 'Call pk_workflow.get_status_rank / i_lang=' || i_lang || ' i_prof=' ||
                         pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_status=' ||
                         i_id_status || ' i_id_category=' || i_id_category || ' i_id_profile_template=' ||
                         i_id_profile_template;
        l_status_rank := pk_workflow.get_status_rank(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => i_id_workflow,
                                                     i_id_status           => i_id_status,
                                                     i_id_category         => i_id_category,
                                                     i_id_profile_template => i_id_profile_template,
                                                     i_id_functionality    => NULL,
                                                     i_param               => table_varchar());
    
        RETURN l_status_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- pk_alertlog.log_error(l_params || ' / ' || g_error);
            RETURN NULL;
    END get_status_rank;

    /**
    * Gets the status desc of a print list job to be shown in grids
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    *
    * @return  VARCHAR2               Status description
    *
    * @author  ana.monteiro
    * @since   02-10-2014
    */
    FUNCTION get_status_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE DEFAULT 0,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE DEFAULT 0
    ) RETURN VARCHAR2 IS
        l_status_desc VARCHAR2(1000 CHAR);
    BEGIN
        g_error       := 'Call pk_workflow.get_status_rank / i_lang=' || i_lang || ' i_prof=' ||
                         pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_status=' ||
                         i_id_status || ' i_id_category=' || i_id_category || ' i_id_profile_template=' ||
                         i_id_profile_template;
        l_status_desc := pk_workflow.get_status_desc(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_workflow         => i_id_workflow,
                                                     i_id_status           => i_id_status,
                                                     i_id_category         => i_id_category,
                                                     i_id_profile_template => i_id_profile_template,
                                                     i_id_functionality    => NULL,
                                                     i_param               => table_varchar());
    
        RETURN l_status_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- pk_alertlog.log_error(l_params || ' / ' || g_error);
            RETURN NULL;
    END get_status_desc;

    /**
    * Add new print job to print jobs table
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_patient              Patient identifier
    * @param   i_episode              Episode identifier
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List with print jobs context data
    * @param   i_print_arguments      List of print arguments
    * @param   i_id_status            List of print list job status
    * @param   o_print_list_jobs      List with the print jobs ids
    * @param   o_error                Rrror information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION add_print_jobs_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        i_print_arguments  IN table_varchar,
        i_id_status        IN table_number,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_jobs_internal';
        l_params         VARCHAR2(1000 CHAR);
        l_print_list_job print_list_job%ROWTYPE;
        l_rowids         table_varchar;
        l_rowids_total   table_varchar;
        l_id_hist        print_list_job.id_print_list_job%TYPE;
        l_sysdate        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_prof_cat       category.flg_type%TYPE;
        -- ibt to load configuration by print list area
        TYPE t_ibt_pl_cfg IS TABLE OF v_print_list_cfg%ROWTYPE INDEX BY PLS_INTEGER;
        l_print_list_cfg t_ibt_pl_cfg;
    
        l_similar_plj table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_areas=' || pk_utils.to_string(i_print_list_areas) ||
                    ' i_id_status=' || pk_utils.to_string(i_id_status);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_sysdate  := current_timestamp;
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- val
        IF i_print_list_areas.count != i_context_data.count
           AND i_print_list_areas.count != i_print_arguments.count
           AND i_print_list_areas.count != i_id_status.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_print_list_areas.count = 0
        THEN
            g_error := 'Empty print list jobs / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- func
        l_rowids_total    := table_varchar();
        o_print_list_jobs := table_number();
        o_print_list_jobs.extend(i_print_list_areas.count);
    
        -- add this print list job to the print list
        g_error                         := 'Set l_print_list_job / ' || l_params;
        l_print_list_job.id_episode     := i_episode;
        l_print_list_job.id_patient     := i_patient;
        l_print_list_job.id_prof_req    := i_prof.id;
        l_print_list_job.dt_req         := l_sysdate;
        l_print_list_job.id_prof_status := i_prof.id;
        l_print_list_job.dt_status      := l_sysdate;
        l_print_list_job.id_workflow    := g_id_workflow;
        l_print_list_job.id_inst_req    := i_prof.institution;
    
        g_error := 'FOR i IN 1 .. ' || i_print_list_areas.count || ' / ' || l_params;
        FOR i IN 1 .. i_print_list_areas.count
        LOOP
            l_print_list_job.id_print_list_job := ts_print_list_job.next_key;
        
            --Add to return array
            o_print_list_jobs(i) := l_print_list_job.id_print_list_job;
        
            l_print_list_job.id_status          := i_id_status(i);
            l_print_list_job.print_arguments    := i_print_arguments(i);
            l_print_list_job.id_print_list_area := i_print_list_areas(i);
            l_print_list_job.context_data       := i_context_data(i);
        
            g_error := 'ID_STATUS=' || l_print_list_job.id_status || ' / ' || l_params;
        
            -- check config if similar jobs must be replaced (do this before insert into print_list_job)
            IF NOT l_print_list_cfg.exists(l_print_list_job.id_print_list_area)
            THEN
            
                -- load configuration by area, only if it isn't loaded yet
                g_error := 'Call get_print_list_configs / id_print_list_area=' || l_print_list_job.id_print_list_area ||
                           ' / ' || l_params;
            
                g_retval := get_print_list_configs(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_print_list_area => l_print_list_job.id_print_list_area,
                                                   o_print_list_cfgs => l_print_list_cfg(l_print_list_job.id_print_list_area),
                                                   o_error           => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
            -- check if similar jobs in the print list must be replaced
            g_error := 'flg_replace_similar_jobs=' || l_print_list_cfg(l_print_list_job.id_print_list_area).flg_replace_similar_jobs ||
                       ' / ' || l_params;
            IF l_print_list_cfg(l_print_list_job.id_print_list_area).flg_replace_similar_jobs = pk_alert_constant.g_yes
            THEN
                -- get similar jobs in the printing list
                g_error       := 'Call get_similar_print_list_jobs / ' || l_params;
                l_similar_plj := get_similar_print_list_jobs(i_lang                   => i_lang,
                                                             i_prof                   => i_prof,
                                                             i_patient                => l_print_list_job.id_patient,
                                                             i_episode                => l_print_list_job.id_episode,
                                                             i_print_list_area        => l_print_list_job.id_print_list_area,
                                                             i_print_job_context_data => l_print_list_job.context_data);
            
                -- change state to Replaced
                IF l_similar_plj.count > 0
                THEN
                    g_error  := 'Call set_print_jobs_replaced / ' || l_params;
                    g_retval := set_print_jobs_replaced(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_print_list_job => l_similar_plj,
                                                        o_id_print_list_job => l_similar_plj,
                                                        o_error             => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END IF;
        
            --Insert in table
            g_error := 'Call ts_print_list_job.ins / ' || l_params;
            ts_print_list_job.ins(rec_in => l_print_list_job, rows_out => l_rowids);
        
            l_rowids_total := l_rowids_total MULTISET UNION l_rowids;
        
            -- add information to history table
            g_error  := 'Call insert_print_list_hist / ' || l_params;
            g_retval := insert_print_list_hist(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_print_list_job_row => l_print_list_job,
                                               o_id_hist            => l_id_hist,
                                               o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END LOOP;
    
        g_error := 'Call t_data_gov_mnt.process_insert / ' || l_params;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRINT_LIST_JOB',
                                      i_rowids     => l_rowids_total,
                                      o_error      => o_error);
    
        g_error  := 'Call pk_visit.set_first_obs / ' || l_params;
        g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                           i_id_episode          => i_episode,
                                           i_pat                 => i_patient,
                                           i_prof                => i_prof,
                                           i_prof_cat_type       => l_prof_cat,
                                           i_dt_last_interaction => l_sysdate,
                                           i_dt_first_obs        => l_sysdate,
                                           o_error               => o_error);
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_print_jobs_internal;

    /**
    * Add new print job to print jobs table
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_patient              Patient identifier
    * @param   i_episode              Episode identifier
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List with print jobs context data
    * @param   i_print_arguments      List of print arguments
    * @param   o_print_list_jobs      List with the print jobs ids
    * @param   o_error                Error information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION add_print_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        i_print_arguments  IN table_varchar,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_jobs';
        l_params    VARCHAR2(1000 CHAR);
        l_id_status table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_areas=' || pk_utils.to_string(i_print_list_areas);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
    
        -- initialize all print jobs with status=pending
        l_id_status := table_number();
        l_id_status.extend(i_context_data.count);
        FOR i IN 1 .. l_id_status.count
        LOOP
            l_id_status(i) := g_id_sts_pending;
        END LOOP;
    
        g_error  := 'Call add_print_jobs_internal / ' || l_params;
        g_retval := add_print_jobs_internal(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_patient          => i_patient,
                                            i_episode          => i_episode,
                                            i_print_list_areas => i_print_list_areas,
                                            i_context_data     => i_context_data,
                                            i_print_arguments  => i_print_arguments,
                                            i_id_status        => l_id_status,
                                            o_print_list_jobs  => o_print_list_jobs,
                                            o_error            => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_print_jobs;

    /**
    * Add a print list job to the print list, in a predefined state. No print arguments are set.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_patient              Patient identifier
    * @param   i_episode              Episode identifier
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List with print jobs context data
    * @param   o_print_list_jobs      List of print list jobs identifiers created
    * @param   o_error                Error information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   10-10-2014
    */
    FUNCTION add_print_jobs_predef
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_jobs_predef';
        l_params          VARCHAR2(1000 CHAR);
        l_id_status       table_number;
        l_print_arguments table_varchar;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_areas=' || pk_utils.to_string(i_print_list_areas);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
    
        -- initialize all print jobs with status=predefined
        l_id_status       := table_number();
        l_print_arguments := table_varchar();
        l_id_status.extend(i_context_data.count);
        l_print_arguments.extend(i_context_data.count);
    
        g_error := 'FOR i IN 1 .. ' || l_id_status.count || ' / ' || l_params;
        FOR i IN 1 .. l_id_status.count
        LOOP
            l_id_status(i) := g_id_sts_predef;
        END LOOP;
    
        -- add all print list predefined jobs to the print list
        g_error  := 'Call add_print_jobs_internal / ' || l_params;
        g_retval := add_print_jobs_internal(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_patient          => i_patient,
                                            i_episode          => i_episode,
                                            i_print_list_areas => i_print_list_areas,
                                            i_context_data     => i_context_data,
                                            i_print_arguments  => l_print_arguments,
                                            i_id_status        => l_id_status,
                                            o_print_list_jobs  => o_print_list_jobs,
                                            o_error            => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_print_jobs_predef;

    /**
    * Check and change status
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_list_id_print_list_job     Array of print list identifiers to change status
    * @param   i_print_arguments            Print list job arguments
    * @param   i_flg_ignore_wf_rules        Ignore workflow rules (used by job to set print list job as canceled, without asking workflow framework for permissions)
    * @param   i_flg_ignore_prof_req        This job can be canceled by any professional (not only by the one that added this print list job)?
    * @param   o_list_id_print_list_job     Array of prin tlist job identifiers changed
    * @param   o_error                      Error information
    *
    * @value   i_flg_ignore_wf_rules        {*} Y- Ignore workflow rules {*} N- otherwise
    * @value   i_flg_ignore_prof_req        {*} Y- Yes {*} N- No
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION change_print_list_job_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_status_end          IN print_list_job.id_status%TYPE,
        i_id_workflow_action     IN wf_workflow_action.id_workflow_action%TYPE,
        i_list_id_print_list_job IN table_number,
        i_print_arguments        IN table_varchar DEFAULT table_varchar(),
        i_flg_ignore_wf_rules    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_ignore_prof_req    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list_id_print_list_job OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'change_print_list_job_status';
        l_params              VARCHAR2(1000 CHAR);
        l_params_int          VARCHAR2(1000 CHAR);
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_prof_cat            category.flg_type%TYPE;
        l_result              VARCHAR2(1 CHAR);
        l_rowids              table_varchar;
        l_id_hist             print_list_job_hist.id_print_list_job_hist%TYPE;
        l_sysdate             print_list_job.dt_status%TYPE := current_timestamp;
        l_print_list_job_row  print_list_job%ROWTYPE;
        l_flg_can_print       VARCHAR2(1 CHAR);
    
        TYPE t_ibt_id_episode IS TABLE OF episode.id_episode%TYPE INDEX BY PLS_INTEGER;
        l_ibt_episodes t_ibt_id_episode;
    
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_status_end=' ||
                    i_id_status_end || ' i_id_workflow_action=' || i_id_workflow_action || ' i_list_id_print_list_job=' ||
                    pk_utils.to_string(i_list_id_print_list_job) || ' i_flg_ignore_wf_rules=' || i_flg_ignore_wf_rules ||
                    ' i_flg_ignore_prof_req=' || i_flg_ignore_prof_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_id_category            := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_prof_cat               := pk_prof_utils.get_category(i_lang, i_prof);
        l_id_profile_template    := pk_tools.get_prof_profile_template(i_prof);
        l_rowids                 := table_varchar();
        o_list_id_print_list_job := table_number();
    
        -- func    
        -- check if this professional has the functionality of printing enabled
        IF i_flg_ignore_wf_rules = pk_alert_constant.g_no
        THEN
            g_error  := 'Call check_func_can_print / ' || l_params;
            g_retval := check_func_can_print(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             o_flg_can_print => l_flg_can_print,
                                             o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || i_list_id_print_list_job.count || ' / ' || l_params;
        FOR i IN 1 .. i_list_id_print_list_job.count
        LOOP
            l_params_int := 'id_print_list_job=' || i_list_id_print_list_job(i);
        
            g_error := 'Get print list jobs data / ' || l_params || ' / ' || l_params_int;
            SELECT *
              INTO l_print_list_job_row
              FROM print_list_job plj
             WHERE plj.id_print_list_job = i_list_id_print_list_job(i);
        
            l_params_int := l_params_int || ' id_status_begin=' || l_print_list_job_row.id_status;
        
            IF i_flg_ignore_wf_rules = pk_alert_constant.g_no
            THEN
                g_error  := 'Call check_transition / ' || l_params;
                l_result := check_transition(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_workflow         => l_print_list_job_row.id_workflow,
                                             i_id_status_begin     => l_print_list_job_row.id_status,
                                             i_id_status_end       => i_id_status_end,
                                             i_id_workflow_action  => i_id_workflow_action,
                                             i_id_category         => l_id_category,
                                             i_id_profile_template => l_id_profile_template,
                                             i_id_print_list_job   => l_print_list_job_row.id_print_list_job,
                                             i_id_prof_req         => l_print_list_job_row.id_prof_req,
                                             i_func_can_print      => l_flg_can_print,
                                             i_flg_ignore_prof_req => i_flg_ignore_prof_req);
            
            END IF;
        
            g_error := 'l_result=' || l_result || ' / ' || l_params || ' / ' || l_params_int;
            IF l_result = pk_alert_constant.g_yes
               OR i_flg_ignore_wf_rules = pk_alert_constant.g_yes
            THEN
            
                l_print_list_job_row.id_status      := i_id_status_end;
                l_print_list_job_row.dt_status      := l_sysdate;
                l_print_list_job_row.id_prof_status := i_prof.id;
            
                IF i_print_arguments.exists(i)
                   AND i_print_arguments.exists(i) IS NOT NULL
                THEN
                    l_print_list_job_row.print_arguments := i_print_arguments(i);
                END IF;
            
                g_error := 'Call ts_print_list_job.upd / ' || l_params;
                ts_print_list_job.upd(rec_in => l_print_list_job_row, rows_out => l_rowids);
                -- process_update done below
            
                g_error  := 'Call insert_print_list_hist / ' || l_params;
                g_retval := insert_print_list_hist(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_print_list_job_row => l_print_list_job_row,
                                                   o_id_hist            => l_id_hist,
                                                   o_error              => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- only call function pk_visit.set_first_obs once for each episode
                g_error := 'ID_EPISODE=' || l_print_list_job_row.id_episode || ' / ' || l_params;
                IF NOT l_ibt_episodes.exists(l_print_list_job_row.id_episode)
                THEN
                    l_ibt_episodes(l_print_list_job_row.id_episode) := l_print_list_job_row.id_episode;
                
                    g_error  := 'Call pk_visit.set_first_obs / ' || l_params;
                    g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                                       i_id_episode          => l_print_list_job_row.id_episode,
                                                       i_pat                 => l_print_list_job_row.id_patient,
                                                       i_prof                => i_prof,
                                                       i_prof_cat_type       => l_prof_cat,
                                                       i_dt_last_interaction => l_sysdate,
                                                       i_dt_first_obs        => l_sysdate,
                                                       o_error               => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            ELSE
                g_error := 'Not a valid transition / ' || l_params || ' / ' || l_params_int;
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        g_error := 'Call t_data_gov_mnt.process_update / ' || l_params;
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRINT_LIST_JOB',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_list_id_print_list_job := i_list_id_print_list_job;
    
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
            RETURN FALSE;
    END change_print_list_job_status;

    /**
    * Deletes a print list job from table PRINT_LIST_JOB
    * To be used internally only
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          Array of print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  ana.monteiro
    * @since   08-19-2014
    */
    FUNCTION delete_print_list_job
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'delete_print_list_job';
        l_params VARCHAR2(1000 CHAR);
        l_rowids table_varchar;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- remove print list job id from table print_list_job
        l_rowids := table_varchar();
        g_error  := 'Call ts_print_list_job.del_by / ' || l_params;
        ts_print_list_job.del_by(where_clause_in => 'id_print_list_job in (' ||
                                                    pk_utils.concat_table(i_tab => i_id_print_list_job, i_delim => ',') || ')');
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRINT_LIST_JOB',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
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
            RETURN FALSE;
    END delete_print_list_job;

    /**
    * Set list jobs status to cancel
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   i_flg_ignore_wf_rules        Ignore workflow rules (used by job to set print list job as canceled, without asking workflow framework for permissions)
    * @param   i_flg_ignore_prof_req        This job can be canceled by any professional (not only by the one that added this print list job)?
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @value   i_flg_ignore_wf_rules        {*} Y- Ignore workflow rules {*} N- otherwise
    * @value   i_flg_ignore_prof_req        {*} Y- Yes {*} N- No
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_print_list_job   IN table_number,
        i_flg_ignore_wf_rules IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_ignore_prof_req IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_print_list_job   OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_cancel';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job) || ' i_flg_ignore_wf_rules=' || i_flg_ignore_wf_rules ||
                    ' i_flg_ignore_prof_req=' || i_flg_ignore_prof_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        -- change print list job state
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_canceled,
                                                 i_id_workflow_action     => g_id_action_cancel,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 i_flg_ignore_wf_rules    => i_flg_ignore_wf_rules,
                                                 i_flg_ignore_prof_req    => i_flg_ignore_prof_req,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- remove print list job id from table print_list_job
        g_error  := 'Call delete_print_list_job / ' || l_params;
        g_retval := delete_print_list_job(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_print_list_job => i_id_print_list_job,
                                          o_error             => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_cancel;

    /**
    * Set list jobs status to error
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_error
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_error';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func   
        -- change print list job state     
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_error,
                                                 i_id_workflow_action     => g_id_action_error,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_error;

    /**
    * Set list jobs status to complete
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_complete
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_complete';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func 
    
        -- change print list job state
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_completed,
                                                 i_id_workflow_action     => g_id_action_complete,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- remove print list job id from table print_list_job
        g_error  := 'Call delete_print_list_job / ' || l_params;
        g_retval := delete_print_list_job(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_print_list_job => i_id_print_list_job,
                                          o_error             => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_complete;

    /**
    * Set list jobs status to replaced
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_replaced
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_replaced';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func       
        -- change print list job state
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_replaced,
                                                 i_id_workflow_action     => g_id_action_replace,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- remove print list job id from table print_list_job
        g_error  := 'Call delete_print_list_job / ' || l_params;
        g_retval := delete_print_list_job(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_print_list_job => i_id_print_list_job,
                                          o_error             => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_replaced;

    /**
    * Set list jobs status to print
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @version 1.0
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_print';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func        
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_printing,
                                                 i_id_workflow_action     => g_id_action_print,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_print;

    /**
    * Changes status of the print list jobs to pending
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job    List print list job identifiers  
    * @param   i_print_arguments      List of print arguments
    * @param   o_id_print_list_job    List print list job identifiers
    * @param   o_error                Error information
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   10-10-2014
    */
    FUNCTION set_print_jobs_pending
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        i_print_arguments   IN table_varchar,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_pending';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || 'i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job) || ' i_print_arguments.count=' || i_print_arguments.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func        
        g_retval := change_print_list_job_status(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_id_status_end          => g_id_sts_pending,
                                                 i_id_workflow_action     => g_id_action_pending,
                                                 i_list_id_print_list_job => i_id_print_list_job,
                                                 i_print_arguments        => i_print_arguments,
                                                 o_list_id_print_list_job => o_id_print_list_job,
                                                 o_error                  => o_error);
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_print_jobs_pending;

    /**
    * Check if exists a similar job related to this context data in print list
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)   
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  VARCHAR2                     Y- exists a similar job in print list N- otherwise
    *
    * @author  ana.monteiro
    * @since   08-10-2014
    */
    FUNCTION check_if_context_exists
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN print_list_job.id_patient%TYPE DEFAULT NULL,
        i_episode                IN print_list_job.id_episode%TYPE,
        i_print_list_area        IN print_list_job.id_print_list_area%TYPE,
        i_print_job_context_data IN print_list_job.context_data%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_if_context_exists';
        l_print_list_jobs table_number;
        l_flg_exists      VARCHAR2(1 CHAR);
        l_patient         patient.id_patient%TYPE;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        l_flg_exists := pk_alert_constant.g_no;
    
        -- getting id_patient
        l_patient := nvl(i_patient,
                         pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode));
    
        l_params := l_params || ' l_patient=' || l_patient;
    
        -- get similar jobs in print list
        g_error           := 'Call get_similar_print_list_jobs / ' || l_params;
        l_print_list_jobs := get_similar_print_list_jobs(i_lang                   => i_lang,
                                                         i_prof                   => i_prof,
                                                         i_patient                => l_patient,
                                                         i_episode                => i_episode,
                                                         i_print_list_area        => i_print_list_area,
                                                         i_print_job_context_data => i_print_job_context_data);
    
        IF l_print_list_jobs.count > 0
        THEN
            l_flg_exists := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_flg_exists;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN pk_alert_constant.g_no;
    END check_if_context_exists;

    /**
    * Gets all print list jobs of the print list, that are similar to print list job context data
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)   
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  table_number                 Print list jobs that are similar to i_print_list_job
    *
    * @author  ana.monteiro
    * @since   07-10-2014
    */
    FUNCTION get_similar_print_list_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN print_list_job.id_patient%TYPE,
        i_episode                IN print_list_job.id_episode%TYPE,
        i_print_list_area        IN print_list_job.id_print_list_area%TYPE,
        i_print_job_context_data IN print_list_job.context_data%TYPE
    ) RETURN table_number IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_similar_print_list_jobs';
        l_func                    print_list_area.func_print_job_compare%TYPE;
        l_sql                     VARCHAR2(1000 CHAR);
        l_print_list_jobs         table_number;
        l_similar_print_list_jobs table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode || ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_similar_print_list_jobs := table_number();
    
        -- getting all print_list_jobs that exists in printing list of this area
        g_error := 'SELECT plj.id_print_list_job / ' || l_params;
        SELECT plj.id_print_list_job
          BULK COLLECT
          INTO l_print_list_jobs
          FROM print_list_job plj
         WHERE plj.id_patient = i_patient
           AND plj.id_episode = i_episode
           AND plj.id_print_list_area = i_print_list_area;
    
        -- getting function by print_list_area, to compare jobs
        g_error := 'SELECT pla.func_print_job_compare / ' || l_params;
        SELECT pla.func_print_job_compare
          INTO l_func
          FROM print_list_area pla
         WHERE pla.id_print_list_area = i_print_list_area;
    
        -- returning result of print_list_area.FUNC_PRINT_JOB_COMPARE
        -- PK_PACKAGE.function_name(:LANG, profissional(:PROFESSIONAL,:INSTITUTION,:SOFTWARE),:CONTEXT_DATA, :ARRAY_PRINT_LIST_JOBS)
    
        -- build select
        l_sql := 'SELECT ' || l_func || ' from dual';
    
        -- execute immediate function, using bind variables
        -- returns all similar jobs in printing list that are similar with i_print_list_area
        g_error := 'EXECUTE IMMEDIATE / l_sql=' || l_sql || ' / ' || l_params;
        EXECUTE IMMEDIATE l_sql
            INTO l_similar_print_list_jobs
            USING i_lang, -- :LANG
        i_prof.id, -- :PROFESSIONAL
        i_prof.institution, -- :INSTITUTION
        i_prof.software, -- :SOFTWARE
        i_print_job_context_data, -- :CONTEXT_DATA
        l_print_list_jobs -- :ARRAY_PRINT_LIST_JOBS
        ;
    
        RETURN l_similar_print_list_jobs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN table_number();
    END get_similar_print_list_jobs;

    /**
     * Get information for add button
     *
     * @param   i_lang               Preferred language id for this professional
     * @param   i_prof               Professional id structure
     * @param   i_id_sys_button_prop SysButtonProp Identifier (used for get acesses for childrens)
     * @param   o_list               List of values
     * @param   o_error              Error information
     *
     * @return  boolean              True on sucess, otherwise false
     *
     * @author  miguel.gomes
     * @since   1-10-2014
    */
    FUNCTION get_actions_button_add
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_btn_prp_parent%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_actions_button_add';
        l_params            VARCHAR2(1000 CHAR);
        l_access_id_buttons table_number := table_number(1153, 1155, 1154, 6725, 6221);
        l_o_id_sys_button   table_number;
        l_flg_can_add       VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_sys_button_prop=' ||
                    i_id_sys_button_prop;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- getting permissions to add items to the print list
        g_retval := check_func_can_add(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       o_flg_can_add => l_flg_can_add,
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if deepnavs of reports are available
        g_error  := 'Call get_prof_access_button / ' || l_params;
        g_retval := get_prof_access_button(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_sys_button_prop => i_id_sys_button_prop,
                                           i_id_buttons         => l_access_id_buttons,
                                           o_access_id_buttons  => l_o_id_sys_button,
                                           o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_list FOR / ' || l_params;
        OPEN o_list FOR
            SELECT /*+ opt_estimate(table t rows = 1) */
             pk_message.get_message(i_lang, i_prof, sb.code_button) text,
             CASE l_flg_can_add
                 WHEN pk_alert_constant.g_no THEN
                  pk_alert_constant.g_inactive -- do not have permissions to add items to print list
                 ELSE
                  pk_alert_constant.g_active
             -- decode(pk_utils.search_table_number(l_o_id_sys_button, sb.id_sys_button),
             --        -1,
             --        pk_alert_constant.g_inactive,
             --        pk_alert_constant.g_active)
             END flg_active,
             decode(sb.id_sys_button,
                    1153,
                    g_print_list_area_auto_r,
                    1155,
                    g_print_list_area_certif,
                    1154,
                    g_print_list_area_consent,
                    6725,
                    g_print_list_area_orders,
                    6221,
                    g_print_list_area_edit_r) id_print_list_area
              FROM sys_button sb
              JOIN TABLE(CAST(l_access_id_buttons AS table_number)) t
                ON sb.id_sys_button = t.column_value
             WHERE pk_utils.search_table_number(l_o_id_sys_button, sb.id_sys_button) != -1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
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
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_actions_button_add;

    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Professional preferred language
    * @param   i_prof                    Professional identification and its context (institution and software)   
    * @param   i_id_print_list_job       Print list job identifier    
    * @param   i_id_prof_req             Professional that added the print list job to the print list
    * @param   i_func_can_print          Indicates if this professional has the functionality of printing permissions
    * @param   i_flg_ignore_prof_req     This job can be canceled by any professional (not only by the one that added this print list job)?
    *
    * @value   i_func_can_print          {*} Y- professional has permission to print {*} N- otherwise
    * @value   i_flg_ignore_prof_req     {*} Y- Yes {*} N- No
    *
    * @return  table_varchar             input of workflow transition function
    *
    * @author  ana.monteiro
    * @since   09-10-2014
    *
    */
    FUNCTION init_wf_params
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_print_list_job   IN print_list_job.id_print_list_job%TYPE,
        i_id_prof_req         IN print_list_job.id_prof_req%TYPE,
        i_func_can_print      IN VARCHAR2,
        i_flg_ignore_prof_req IN VARCHAR2
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'init_wf_params';
        l_params VARCHAR2(1000 CHAR);
        l_result table_varchar;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    i_id_print_list_job || ' i_id_prof_req=' || i_id_prof_req || ' i_func_can_print=' ||
                    i_func_can_print || ' i_flg_ignore_prof_req=' || i_flg_ignore_prof_req;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_result := table_varchar();
        l_result.extend(4);
    
        l_result(g_idx_print_list_job) := i_id_print_list_job;
        l_result(g_idx_id_prof_req) := i_id_prof_req;
        l_result(g_idx_func_can_print) := i_func_can_print;
        l_result(g_idx_ignore_prof_req) := i_flg_ignore_prof_req;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END init_wf_params;

    /**
    * Gets parameter values of framework workflow into separate variables
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_wf_params          Print list job information
    * @param   o_id_print_list_job  Print list job identifier
    * @param   o_id_prof_req        Professional that added the job to the print list
    * @param   o_func_can_print     Indicates if this professional has the functionality of printing permissions
    * @param   o_flg_ignore_prof_req     Indicates if job can be canceled by any professional (not only by the one that added this print list job)
    * @param   o_error              Error information
    *   
    * @value   o_func_can_print          {*} Y- professional has permission to print {*} N- otherwise
    * @value   o_flg_ignore_prof_req     {*} Y- Yes {*} N- No
    *   
    * @RETURN  boolean              TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   09-10-2014
    */
    FUNCTION get_wf_params_values
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_wf_params           IN table_varchar,
        o_id_print_list_job   OUT print_list_job.id_print_list_job%TYPE,
        o_id_prof_req         OUT print_list_job.id_prof_req%TYPE,
        o_func_can_print      OUT VARCHAR2,
        o_flg_ignore_prof_req OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_wf_params_values';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_wf_params=' ||
                    pk_utils.to_string(i_wf_params);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting values from i_wf_params
        IF i_wf_params.exists(g_idx_print_list_job)
        THEN
            -- id_print_list_job
            o_id_print_list_job := i_wf_params(g_idx_print_list_job);
        END IF;
    
        IF i_wf_params.exists(g_idx_id_prof_req)
        THEN
            -- id_prof_req
            o_id_prof_req := i_wf_params(g_idx_id_prof_req);
        END IF;
    
        IF i_wf_params.exists(g_idx_func_can_print)
        THEN
            -- func_can_print
            o_func_can_print := i_wf_params(g_idx_func_can_print);
        END IF;
    
        IF i_wf_params.exists(g_idx_ignore_prof_req)
        THEN
            -- flg_ignore_prof_req
            o_flg_ignore_prof_req := i_wf_params(g_idx_ignore_prof_req);
        END IF;
    
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
            RETURN FALSE;
    END get_wf_params_values;

    /**
    * Check if professional can cancel the print list job
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Print list information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  ana.monteiro
    * @since   09-10-2014
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
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_cancel';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    
        l_id_print_list_job   print_list_job.id_print_list_job%TYPE;
        l_id_prof_req         print_list_job.id_prof_req%TYPE;
        l_func_can_print      VARCHAR2(1 CHAR);
        l_flg_ignore_prof_req VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_print_list_job   => l_id_print_list_job,
                                         o_id_prof_req         => l_id_prof_req,
                                         o_func_can_print      => l_func_can_print,
                                         o_flg_ignore_prof_req => l_flg_ignore_prof_req,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        g_error := 'l_id_prof_req=' || l_id_prof_req || ' / ' || l_params;
        IF (i_prof.id = l_id_prof_req AND l_flg_ignore_prof_req = pk_alert_constant.g_no)
           OR (l_flg_ignore_prof_req = pk_alert_constant.g_yes)
        THEN
            RETURN pk_workflow.g_transition_allow;
        END IF;
    
        RETURN pk_workflow.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_workflow.g_transition_deny;
    END check_can_cancel;

    /**
    * Check if professional can print the print list job
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Print list information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  ana.monteiro
    * @since   14-10-2014
    */
    FUNCTION check_can_print
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
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_print';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    
        l_id_print_list_job   print_list_job.id_print_list_job%TYPE;
        l_id_prof_req         print_list_job.id_prof_req%TYPE;
        l_func_can_print      VARCHAR2(1 CHAR);
        l_flg_ignore_prof_req VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_print_list_job   => l_id_print_list_job,
                                         o_id_prof_req         => l_id_prof_req,
                                         o_func_can_print      => l_func_can_print,
                                         o_flg_ignore_prof_req => l_flg_ignore_prof_req,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        g_error := 'l_func_can_print=' || l_func_can_print || ' / ' || l_params;
        IF l_func_can_print = pk_alert_constant.g_yes
        THEN
            RETURN pk_workflow.g_transition_allow;
        END IF;
    
        RETURN pk_workflow.g_transition_deny;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_workflow.g_transition_deny;
    END check_can_print;

    /**
    * Delete all print lists n days after episode close. Number of days is a configurable for each area
    *   
    * @author  Miguel Gomes
    * @since   13-10-2014
    */
    PROCEDURE clear_print_list IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CLEAR_PRINT_LIST';
        l_list_inactive_episodes table_number;
        l_changed_rows           table_number;
        o_error                  t_error_out;
        l_id_prof                professional.id_professional%TYPE;
    
        l_lang    language.id_language%TYPE := 1;
        l_prof    profissional := profissional(l_id_prof, 0, 0);
        l_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        CURSOR c_plj IS
            SELECT plj.id_print_list_job
              FROM print_list_job plj
              JOIN episode ep
                ON ep.id_episode = plj.id_episode
              JOIN v_print_list_cfg vplj
                ON vplj.id_print_list_area = plj.id_print_list_area
             WHERE plj.id_status IN (g_id_sts_pending, g_id_sts_printing, g_id_sts_error, g_id_sts_predef)
               AND ep.flg_status IN (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_cancel)
               AND pk_date_utils.compare_dates_tsz(i_prof  => profissional(l_id_prof, ep.id_institution, 0),
                                                   i_date1 => ep.dt_end_tstz,
                                                   i_date2 => trunc(pk_date_utils.add_days_to_tstz(i_timestamp => l_sysdate,
                                                                                                   i_days      => -vplj.n_days_after_epis_inactivation))) IN
                   (pk_alert_constant.g_date_equal, pk_alert_constant.g_date_lower);
    BEGIN
        g_error := 'Init ' || l_func_name;
        pk_alertlog.log_debug(g_error);
        l_sysdate := trunc(current_timestamp);
    
        l_id_prof := pk_sysconfig.get_config(i_code_cf => 'ID_PROF_BACKGROUND', i_prof_inst => 0, i_prof_soft => 0);
        l_prof    := profissional(l_id_prof, 0, 0);
    
        -- getting all print list jobs of inactive/canceled episodes
        g_error := 'OPEN c_plj / l_id_prof=' || l_id_prof;
        OPEN c_plj;
        LOOP
            g_error := 'FETCH c_plj BULK COLLECT / l_id_prof=' || l_id_prof;
            FETCH c_plj BULK COLLECT
                INTO l_list_inactive_episodes LIMIT 1000;
        
            EXIT WHEN l_list_inactive_episodes.count = 0;
        
            g_error  := 'Call set_print_jobs_cancel / l_id_prof=' || l_id_prof || ' l_list_inactive_episodes.count=' ||
                        l_list_inactive_episodes.count;
            g_retval := set_print_jobs_cancel(i_lang                => l_lang,
                                              i_prof                => l_prof,
                                              i_id_print_list_job   => l_list_inactive_episodes,
                                              i_flg_ignore_wf_rules => pk_alert_constant.g_yes,
                                              o_id_print_list_job   => l_changed_rows,
                                              o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        -- Clean up
        g_error := 'CLOSE c_plj / l_id_prof=' || l_id_prof;
        CLOSE c_plj;
        l_list_inactive_episodes.delete;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
    END clear_print_list;

    /**
    * This function deletes all data related to print list jobs of an episode
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patients                Array of patient identifiers
    * @param   i_id_episodes                Array of episode identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   16-10-2014
    */
    FUNCTION reset_print_list_job
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'reset_print_list_job';
        l_params VARCHAR2(1000 CHAR);
        l_rowids table_varchar := table_varchar();
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patients.count=' ||
                    i_id_patients.count || ' i_id_episodes.count=' || i_id_episodes.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        IF i_id_episodes IS NOT NULL
           AND i_id_episodes.count > 0
        THEN
        
            -- print_list_job_hist
            l_rowids := table_varchar();
            g_error  := 'DELETE FROM print_list_job_hist pljh / ' || l_params;
            DELETE FROM print_list_job_hist pljh
             WHERE pljh.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        column_value
                                         FROM TABLE(CAST(i_id_episodes AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRINT_LIST_JOB_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- print_list_job
            l_rowids := table_varchar();
            g_error  := 'DELETE FROM print_list_job plj / ' || l_params;
            DELETE FROM print_list_job plj
             WHERE plj.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_episodes AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRINT_LIST_JOB',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSIF i_id_patients IS NOT NULL
              AND i_id_patients.count > 0
        THEN
        
            -- print_list_job_hist
            l_rowids := table_varchar();
            g_error  := 'DELETE FROM print_list_job_hist pljh / ' || l_params;
            DELETE FROM print_list_job_hist pljh
             WHERE pljh.id_patient IN (SELECT /*+opt_estimate (table t rows=1)*/
                                        column_value
                                         FROM TABLE(CAST(i_id_patients AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRINT_LIST_JOB_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- print_list_job
            l_rowids := table_varchar();
            g_error  := 'DELETE FROM print_list_job plj / ' || l_params;
            DELETE FROM print_list_job plj
             WHERE plj.id_patient IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(CAST(i_id_patients AS table_number)) t)
            RETURNING ROWID BULK COLLECT INTO l_rowids;
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PRINT_LIST_JOB',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            g_error := 'ID_PATIENT and ID_EPISODE cannot be null / ' || l_params;
            RAISE g_exception;
        END IF;
    
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
            RETURN FALSE;
    END reset_print_list_job;

    /**
    * Updates a print list job data: context_data and print_arguments
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_print_list_jobs      List with the print jobs ids
    * @param   i_context_data         List of new context data
    * @param   i_print_arguments      List of new print arguments
    * @param   o_print_list_jobs      List with the print jobs ids updated
    * @param   o_error                Error information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   26-11-2014
    */
    FUNCTION update_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_jobs IN table_number,
        i_context_data    IN table_clob,
        i_print_arguments IN table_varchar,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'update_print_list_jobs';
        l_params             VARCHAR2(1000 CHAR);
        l_params_int         VARCHAR2(1000 CHAR);
        l_print_list_job_row print_list_job%ROWTYPE;
        l_rowids             table_varchar;
        l_id_hist            print_list_job.id_print_list_job%TYPE;
        l_sysdate            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_prof_cat           category.flg_type%TYPE;
    
        TYPE t_ibt_id_episode IS TABLE OF episode.id_episode%TYPE INDEX BY PLS_INTEGER;
        l_ibt_episodes t_ibt_id_episode;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_jobs=' ||
                    substr(pk_utils.to_string(i_print_list_jobs), 1, 200) || ' i_context_data.count=' ||
                    i_context_data.count || ' i_print_arguments.count=' || i_print_arguments.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_sysdate         := current_timestamp;
        o_print_list_jobs := table_number();
        l_prof_cat        := pk_prof_utils.get_category(i_lang, i_prof);
        l_rowids          := table_varchar();
    
        -- val
        IF i_print_list_jobs.count != i_context_data.count
           AND i_print_list_jobs.count != i_print_arguments.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_print_list_jobs.count = 0
        THEN
            g_error := 'Empty print list jobs / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- func
        g_error := 'FOR i IN 1 .. ' || i_print_list_jobs.count || ' / ' || l_params;
        FOR i IN 1 .. i_print_list_jobs.count
        LOOP
            l_params_int := 'ID_PRINT_LIST_JOB=' || i_print_list_jobs(i);
        
            IF i_context_data(i) IS NULL
               OR i_print_arguments(i) IS NULL
               OR length(i_print_arguments(i)) = 0
            THEN
                g_error := 'Invalid data to update / ' || l_params_int || ' / ' || l_params;
                RAISE g_exception;
            END IF;
        
            BEGIN
                g_error := 'Get print list jobs data / ' || l_params || ' / ' || l_params_int;
                SELECT *
                  INTO l_print_list_job_row
                  FROM print_list_job plj
                 WHERE plj.id_print_list_job = i_print_list_jobs(i);
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'Print list job identifier not found / ' || l_params_int || ' / ' || l_params;
                    RAISE g_exception;
            END;
        
            -- update data of this print list job id
            g_error                              := 'Set l_print_list_job_row / ' || l_params || ' / ' || l_params_int;
            l_print_list_job_row.context_data    := i_context_data(i);
            l_print_list_job_row.print_arguments := i_print_arguments(i);
        
            -- Update in table
            g_error := 'Call ts_print_list_job.upd / ' || l_params || ' / ' || l_params_int;
            ts_print_list_job.upd(rec_in => l_print_list_job_row, rows_out => l_rowids);
        
            -- process_update done below
            g_error  := 'Call insert_print_list_hist / ' || l_params || ' / ' || l_params_int;
            g_retval := insert_print_list_hist(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_print_list_job_row => l_print_list_job_row,
                                               o_id_hist            => l_id_hist,
                                               o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- only call function pk_visit.set_first_obs once for each episode
            g_error := 'ID_EPISODE=' || l_print_list_job_row.id_episode || ' / ' || l_params || ' / ' || l_params_int;
            IF NOT l_ibt_episodes.exists(l_print_list_job_row.id_episode)
            THEN
                l_ibt_episodes(l_print_list_job_row.id_episode) := l_print_list_job_row.id_episode;
            
                g_error  := 'Call pk_visit.set_first_obs / ' || l_params || ' / ' || l_params_int;
                g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                                   i_id_episode          => l_print_list_job_row.id_episode,
                                                   i_pat                 => l_print_list_job_row.id_patient,
                                                   i_prof                => i_prof,
                                                   i_prof_cat_type       => l_prof_cat,
                                                   i_dt_last_interaction => l_sysdate,
                                                   i_dt_first_obs        => l_sysdate,
                                                   o_error               => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
        END LOOP;
    
        g_error := 'Call t_data_gov_mnt.process_update / ' || l_params;
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PRINT_LIST_JOB',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_print_list_jobs := i_print_list_jobs;
    
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
            RETURN FALSE;
    END update_print_list_jobs;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_print_list;
/
