/*-- Last Change Revision: $Rev: 1922708 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2019-10-29 08:31:42 +0000 (ter, 29 out 2019) $*/

CREATE OR REPLACE PACKAGE pk_print_list IS

    -- Author  : TIAGO.SILVA
    -- Created : 23-09-2014
    -- Purpose : Print list database package

    -- print_list_area
    g_print_list_area_auto_r       CONSTANT print_list_area.id_print_list_area%TYPE := 1;
    g_print_list_area_edit_r       CONSTANT print_list_area.id_print_list_area%TYPE := 2;
    g_print_list_area_consent      CONSTANT print_list_area.id_print_list_area%TYPE := 3;
    g_print_list_area_certif       CONSTANT print_list_area.id_print_list_area%TYPE := 4;
    g_print_list_area_orders       CONSTANT print_list_area.id_print_list_area%TYPE := 5;
    g_print_list_area_ref          CONSTANT print_list_area.id_print_list_area%TYPE := 6;
    g_print_list_area_disch_i      CONSTANT print_list_area.id_print_list_area%TYPE := 7;
    g_print_list_area_disch        CONSTANT print_list_area.id_print_list_area%TYPE := 8;
    g_print_list_area_med          CONSTANT print_list_area.id_print_list_area%TYPE := 9;
    g_print_list_area_lab_test     CONSTANT print_list_area.id_print_list_area%TYPE := 10;
    g_print_list_area_img_exam     CONSTANT print_list_area.id_print_list_area%TYPE := 11;
    g_print_list_area_other_exam   CONSTANT print_list_area.id_print_list_area%TYPE := 12;
    g_print_list_area_touch_option CONSTANT print_list_area.id_print_list_area%TYPE := 13;
    g_print_list_area_ges          CONSTANT print_list_area.id_print_list_area%TYPE := 14;

    -- status
    g_id_sts_pending   CONSTANT wf_status.id_status%TYPE := 510;
    g_id_sts_printing  CONSTANT wf_status.id_status%TYPE := 511;
    g_id_sts_completed CONSTANT wf_status.id_status%TYPE := 512;
    g_id_sts_canceled  CONSTANT wf_status.id_status%TYPE := 513;
    g_id_sts_error     CONSTANT wf_status.id_status%TYPE := 514;
    g_id_sts_replaced  CONSTANT wf_status.id_status%TYPE := 515;
    g_id_sts_predef    CONSTANT wf_status.id_status%TYPE := 516;

    -- shortcut to printing list deepnav (patient area)
    g_print_list_id_shortcut_pat CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 53000008;

    FUNCTION get_print_list_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN table_number;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    );

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
    ) RETURN t_rec_print_list_job;

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
    ) RETURN VARCHAR2;

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
    ) RETURN NUMBER;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN table_number;

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
    ) RETURN BOOLEAN;

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
    ) RETURN table_varchar;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /**
    * Delete all print lists n days after episode close. Number of days is a configurable for each area
    *   
    * @author  Miguel Gomes
    * @since   13-10-2014
    */
    PROCEDURE clear_print_list;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_print_list;
/
