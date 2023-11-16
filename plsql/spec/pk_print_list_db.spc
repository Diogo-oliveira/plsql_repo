/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_print_list_db IS

    -- Author  : TIAGO.SILVA
    -- Created : 23-09-2014
    -- Purpose : Print list database package

    -- print_list_area
    g_print_list_area_auto_r     CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_auto_r;
    g_print_list_area_edit_r     CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_edit_r;
    g_print_list_area_consent    CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_consent;
    g_print_list_area_certif     CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_certif;
    g_print_list_area_orders     CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_orders;
    g_print_list_area_ref        CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_ref;
    g_print_list_area_disch_i    CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_disch_i;
    g_print_list_area_disch      CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_disch;
    g_print_list_area_med        CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_med;
    g_print_list_area_lab_test   CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_lab_test;
    g_print_list_area_img_exam   CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_img_exam;
    g_print_list_area_other_exam CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_other_exam;
    g_print_list_area_touch_option CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_touch_option;
    g_print_list_area_ges          CONSTANT print_list_area.id_print_list_area%TYPE := pk_print_list.g_print_list_area_ges;

    -- status
    g_id_sts_pending   CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_pending;
    g_id_sts_printing  CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_printing;
    g_id_sts_completed CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_completed;
    g_id_sts_canceled  CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_canceled;
    g_id_sts_error     CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_error;
    g_id_sts_replaced  CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_replaced;
    g_id_sts_predef    CONSTANT wf_status.id_status%TYPE := pk_print_list.g_id_sts_predef;
    
    -- shortcut to printing list deepnav (patient area)
    g_print_list_id_shortcut_pat CONSTANT sys_shortcut.id_sys_shortcut%TYPE := pk_print_list.g_print_list_id_shortcut_pat;

    /**
    * Add new print job to print jobs table
    *
    * @param   i_lang                 preferred language id for this professional
    * @param   i_prof                 professional id structure
    * @param   i_patient              patient id
    * @param   i_episode              episode id
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List of context data needed to relate the print list job with its area
    * @param   i_print_arguments      List of print arguments
    * @param   o_print_list_jobs      cursor with the print jobs ids list
    * @param   o_error                error information    
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   07-10-2014
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
    * @param   i_lang                 preferred language id for this professional
    * @param   i_prof                 professional id structure
    * @param   i_patient              patient id
    * @param   i_episode              episode id
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List with print jobs context data
    * @param   o_print_list_jobs      List of print list jobs identifiers created
    * @param   o_error                error information    
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
    * Check if exists a similar job related to this context data in print list
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  VARCHAR2                     Y- exists a similar job in print list N- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
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
    * Set list jobs status to cancel
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          list print list job identifiers  
    * @param   o_id_print_list_job          list print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @version 1.0
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_cancel
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
    * @param   i_id_print_list_job    list print list job identifiers  
    * @param   i_print_arguments      list of print arguments
    * @param   o_id_print_list_job    list print list job identifiers
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
     * Gets print list default option
     *
     * @param   i_lang               preferred language id for this professional
     * @param   i_prof               professional id structure
     * @param   i_print_list_area    Print list area identifier
     * @param   o_default_option     Default option configured for this print list area
     * @param   o_error              error information    
     *
     * @return  boolean              True on sucess, otherwise false
     *
     * @author  ana.monteiro
     * @since   10-10-2014
    */
    FUNCTION get_print_list_def_option
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        o_default_option  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Delete all print lists n days after episode close. Number of days is a configurable for each area
    *   
    * @author  Miguel Gomes
    * @version 1.0
    * @since   13-10-2014
    */
    PROCEDURE clear_print_list;

    /**
    * Checks if this professional can add a job to the print list
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_flg_can_add         Flag that indicates if professional can add a job to the print list
    * @param   o_error               An error message, set when return=false
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
    * Gets all print list jobs of the print list, that are similar to print list job context data
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  table_number                 Print list jobs that are similar to i_print_list_job
    *
    * @author  ana.monteiro
    * @version 1.0
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
    * Gets all print list jobs identifiers of the print list
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    *
    * @return  table_number                 Print list jobs identifiers that are in print list
    *
    * @author  ana.monteiro
    * @version 1.0
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
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_id_print_list_jobs         Array of print list jobs identifiers
    * @param   o_print_args                 Print arguments of the print list jobs identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
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
    * @version 1.0
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

END pk_print_list_db;
/
