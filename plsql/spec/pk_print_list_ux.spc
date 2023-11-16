/*-- Last Change Revision: $Rev: 1922708 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2019-10-29 08:31:42 +0000 (ter, 29 out 2019) $*/

CREATE OR REPLACE PACKAGE pk_print_list_ux IS

    -- Author  : TIAGO.SILVA
    -- Created : 23-09-2014
    -- Purpose : Print list database package

    FUNCTION get_print_list_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
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
    * Set list jobs status to cancel
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
    FUNCTION set_print_jobs_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
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

END pk_print_list_ux;
/
