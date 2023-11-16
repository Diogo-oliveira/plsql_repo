/*-- Last Change Revision: $Rev: 2028903 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_change_resp IS

    -- Author  : FILIPE.SOUSA
    -- Created : 03-09-2010 12:05:53
    -- Purpose : Change responsibility

    /**
    * Check if this professional can request hand off for this referral
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_ref       Referral identifier           
    * @param   i_id_inst_orig Referral origin institution identifier
    * @param   i_id_prof_requested   Professional that requested the referral
    * @param   o_error        An error message, set when return=false    
    *
    * @RETURN  'Y'- hand off can be created for this referral 'N'- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_handoff_creation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN ref_trans_responsibility.id_external_request%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE
    ) RETURN VARCHAR2;

    /**
    * Check parameters for the hand off creation
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_workflow        Hand off workflow identifier
    * @param   i_id_prof_dest       Professional to which the referral is being hand off
    * @param   i_id_inst_dest_tr    Institution to where the referral is being hand off
    *
    * @RETURN  'Y'- parameters are ok 'N'- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-06-2013
    */
    FUNCTION check_handoff_creation_param
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_prof_dest    IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_inst_dest_tr IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2;

    /**
    * Check if this professional is responsible to manage hand off
    *
    * @param   i_prof              Professional id, institution and software    
    *
    * @return  Y- can manage hand off, N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION check_func_handoff_app(i_prof IN profissional) RETURN VARCHAR2;
    
    /**
    * Checks if this professional can analyze hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_prof_dest   Professional that is requesting hand off
    *
    * @return  Y- can request hand off, N- otherwise 
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION can_analyze
    (
        i_prof            IN profissional,
        i_tr_id_workflow  IN wf_workflow.id_workflow%TYPE,
        i_tr_id_status    IN wf_status.id_status%TYPE,
        i_tr_id_prof_dest IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if this professional can analyze exernal hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier    
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_inst_dest   Hand off dest institution identifier
    *
    * @return  Y- can analyze external hand off , N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   22-08-2013
    */
    FUNCTION can_analyze_inst
    (
        i_prof            IN profissional,
        i_tr_id_workflow  IN ref_trans_responsibility.id_workflow%TYPE,
        i_tr_id_status            IN wf_status.id_status%TYPE,
        i_tr_id_inst_dest IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if this professional can cancel hand off
    *
    * @param   i_prof              Professional id, institution and software
    * @param   i_tr_id_workflow    Hand off workflow identifier
    * @param   i_tr_id_status      Status identifier
    * @param   i_tr_id_prof_owner  Professional that created referral handoff    
    *
    * @return  Y- can cancel hand off, N- otherwise 
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-06-2013
    */
    FUNCTION can_cancel
    (
        i_prof             IN profissional,
        i_tr_id_workflow   IN ref_trans_responsibility.id_workflow%TYPE,
        i_tr_id_status     IN ref_trans_responsibility.id_status%TYPE,
        i_tr_id_prof_owner IN ref_trans_responsibility.id_prof_transf_owner%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the string with dest hand off (used in grids)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_workflow   Hand off workflow identifier
    * @param   i_id_prof_dest  Dest professional identifier
    * @param   i_id_inst_dest  Dest institution identifier
    *
    * @RETURN  dest hand off string
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   29-08-2013
    */
    FUNCTION get_handoff_dest_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_prof_dest IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_inst_dest IN ref_trans_responsibility.id_inst_dest_tr%TYPE
    ) RETURN VARCHAR2;
    
    /**
    * Gets hand off historic data
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_hist_data     Hand off historic data
    * @param   o_hist_data     Hand off historic detail data
    * @param   o_error        Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-06-2013
    */
    FUNCTION get_detail_hist
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref        IN ref_trans_responsibility.id_external_request%TYPE,
        o_hist_data     OUT pk_types.cursor_type,
        o_hist_data_det OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes this transf resp to the next status
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_transf_resp  Row data related to the transf resp
    * @param   i_params       
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION change_to_next_status
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_transf_resp IN ref_trans_responsibility%ROWTYPE,
        i_params      IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Transfers referral responsibility to professional i_id_prof
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_id_external_request    Referral identifier
    * @param   i_id_prof                Professional identifier to which the referral is being transfered
    * @param   i_id_prof_request        Professional identifier that is transfering the referral
    * @param   i_id_reason_code         Reason code identifier
    * @param   i_notes                  Notes
    * @param   i_id_inst_dest_tr        Referral new origin institution identifier (dest hand off)
    * @param   i_date                   Operation date
    * @param   o_track                  Array of ID_TRACKING transitions
    * @param   o_error                  An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION change_responsibility
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_id_prof             IN professional.id_professional%TYPE,
        i_id_prof_request     IN professional.id_professional%TYPE,
        i_id_reason_code      IN p1_reason_code.id_reason_code%TYPE,
        i_notes               IN VARCHAR2,
        i_id_inst_dest_tr     IN ref_trans_responsibility.id_inst_dest_tr%TYPE,
        i_date                IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track               OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create a new request to hand off referral
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_transf_resp  Data related to transferring responsibility
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION req_new_responsibility
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_transf_resp IN ref_trans_responsibility%ROWTYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Opens a cursor with a dynamic query
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_tab_name     Table name
    * @param   i_column       Column name
    * @param   i_field_name   Field name
    * @param   i_val          Value
    * @param   o_crs          Cursor returned
    * @param   o_error        Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    PROCEDURE dyn_sel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tab_name   IN VARCHAR2,
        i_column     IN VARCHAR2,
        i_field_name IN VARCHAR2,
        i_val        IN VARCHAR2,
        o_crs        IN OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    );

    /**
    * Validates that this professional is allowed to search for several physicians
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   o_multi        {*} Y- is allowed {*} N- otherwise
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   03-09-2010
    */
    FUNCTION tr_is_multi_prof
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        o_multi OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   03-09-2010
    */
    FUNCTION row_valid_to_show
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_id_workflow    IN wf_workflow.id_workflow%TYPE,
        i_id_status      IN wf_status.id_status%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_dt_update      IN ref_trans_responsibility.dt_update%TYPE
    ) RETURN VARCHAR2;

    /**
    * Return the distinct value of an array, or returns the string default (if multiple values)
    *
    * @param   i_val_tab       Array of values to check
    * @param   i_str_default   Default string to be returned if there are multiple values
    *
    * @RETURN  value to be returned
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_value
    (
        i_val_tab     IN table_varchar,
        i_str_default IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Gets hand off detail
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_tr_tab     Array of hand off identifiers
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_short_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_tr_tab   IN table_number,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets hand off detail
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_ref_det       Referral detail
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   29-05-2013
    */
    FUNCTION get_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN ref_trans_responsibility.id_external_request%TYPE,
        o_ref_det       OUT pk_types.cursor_type,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the domain of hand off status filtered by id_market
    * Used by id_criteria=217
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-01-2013
    */
    FUNCTION get_search_tr_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_wf_status_info_def
        PIPELINED;

    /**
    * Returns the list of transitions available from the action previously selected
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status             Actual status identifier
    * @param   o_options               Options available
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_tr_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_workflow IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status   IN ref_trans_responsibility.id_status%TYPE,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the description of hand off workflow status
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   o_status_desc    Workflow status description
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2013
    */
    FUNCTION get_handoff_status_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_status_desc OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_change_resp;
/
