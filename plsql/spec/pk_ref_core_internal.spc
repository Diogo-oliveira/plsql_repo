/*-- Last Change Revision: $Rev: 2028906 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_core_internal AS

    /**
    * Gets the query for the profiles grid
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   i_var_desc    Variables description
    * @param   i_var_val     Variables values
    * @param   i_filter Filter to apply. Depends on button selected.
    * @param   i_view        View to get data. v_p1_grid by default
    * @param   o_sql sql text
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */

    FUNCTION get_grid_sql
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_var_desc IN table_varchar,
        i_var_val  IN table_varchar,
        i_filter   IN p1_grid_config.filter%TYPE,
        i_view     IN VARCHAR2 DEFAULT pk_ref_constant.g_view_p1_grid,
        o_sql      OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get P1 list - Return grid data depending on professional profile
    *
    * @param   i_sql query text
    *
    * @RETURN  Return table (t_coll_p1_request) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */
    FUNCTION get_grid_data(i_sql IN VARCHAR2) RETURN t_coll_p1_request
        PIPELINED;

    /**
    * Gets the query for patient search
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit    
    * @param   i_condition query condition to add to the returned query        
    * @param   o_sql sql text
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_pat_sql
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_sql             OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pipelined function to return the data for the query provided
    *
    * @param   i_sql sql code (as returned by get_req_search_sql)
    *
    * @RETURN  t_coll_ref_search record
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_pat_data(i_sql IN CLOB) RETURN t_coll_ref_search
        PIPELINED;

    /**
    * Gets the query for requests search
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab            
    * @param   i_pt profile template id for the user    
    * @param   o_sql sql text
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_ref_sql
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_crit_id_tab  IN table_number,
        i_crit_val_tab IN table_varchar,
        i_pt           IN profile_template.id_profile_template%TYPE,
        o_sql          OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the query for referral search (no criteria hard coded)
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_crit_id_tab   List of search criteria identifiers
    * @param   i_crit_val_tab  List of values for the criteria in i_crit_id_tab    
    * @param   i_leading_tab_exp  Leading table expression to be used (because of performance issues)
    * @param   o_sql           Sql text
    * @param   o_error         Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-01-2013
    */
    FUNCTION get_search_ref_sql_base
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_crit_id_tab  IN table_number,
        i_crit_val_tab IN table_varchar,
        i_leading_tab_exp IN VARCHAR2 DEFAULT NULL,
        o_sql          OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get P1 list - Return grid data depending on professional profile
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   i_filter Filter to apply. Depends on button selected.
    *
    * @RETURN  Return table (t_coll_ref_search) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */
    FUNCTION get_search_ref_data(i_sql IN CLOB) RETURN t_coll_ref_search
        PIPELINED;

    /**
    * Returns the domain of referral status filtered by id_market
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-10-2009
    */
    FUNCTION get_search_ref_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_wf_status_info_def
        PIPELINED;

    /**
    * Getting patient social attributes (Used by match screen)
    * As ADT is integrated, this function should not be used.
    * Same as PK_PATIENT.get_pat_soc_att, but filtering PAT_SOC_ATTRIBUTES.id_institution.
    *
    * @param   i_lang        Language associated to the professional executing the request
    * @param   i_id_pat      Patient identifier   
    * @param   i_prof        Professional id, institution and software
    * @param   o_pat         Patient social attributes
    * @param   o_error       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   15-06-2010
    */
    FUNCTION get_pat_soc_att
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_pat    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral actions available for a subject
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_ref_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns information about valid transitions associated to one action
    *
    * @param   I_LANG                  Language associated to the professional executing the request
    * @param   I_PROF                  Professional, institution and software ids
    * @param   I_ID_ACTION             Action identifier
    * @param   I_ID_WORKFLOW           Workflow identifier
    * @param   I_ID_STATUS_BEGIN       Begin status identifier
    * @param   I_ID_CATEGORY           Professional category
    * @param   I_ID_PROFILE_TEMPLATE   Professional profile template identifier
    * @param   I_ID_FUNCTIONALITY      Professional functionality
    * @param   I_PARAM                 Parameter for workflow framework
    * @param   I_BEHAVIOUR             Function behaviour: {*} 1- returns after having verified that the first transition is enabled    
                                                           {*} 0- returns after having verified all (default)
    * @param   O_EXISTS_TRANSITION     Flag indicating if there is a transition associated to this action (ID_ACTION)
    * @param   O_ENABLED               Flag indicating if this action/workflow/begin status is enabled      
    * @param   O_ERROR                 An error message, set when return=false
    *
    * @value   O_EXISTS_TRANSITION     {*} 'Y' - there is a transition associated to this action {*} 'N' - otherwise
    * @value   O_ENABLED               {*} 'Y' - this action/workflow/begin status is enabled {*} 'N' - otherwise 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_action_trans_valid
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_behaviour           IN PLS_INTEGER DEFAULT 0,
        o_exists_transition   OUT VARCHAR2,
        o_enabled             OUT VARCHAR2,
        o_transition_info     OUT t_coll_wf_transition,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns sql query to calculate the column names
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   i_prof_data             Professional category, profile template and functionality
    * @param   i_column_name_tab       Array of column names
    * @param   i_flg_alias             Return alias columns? Y- yes, N- no
    * @param   o_query_column          Query to calculate the column names defined
    * @param   O_ERROR           An error message, set when return=false    
    *
    * @value   i_flg_alias             {*} Y- yes {*} N- no
    *
    * @RETURN  Query to calculate the column names defined
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-09-2012
    */
    FUNCTION get_column_sql
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_data       IN t_rec_prof_data,
        i_column_name_tab IN table_varchar,
        i_flg_alias       IN VARCHAR2 DEFAULT pk_ref_constant.g_yes
    ) RETURN CLOB;

    /**
    * Set referrals sys_alerts
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_ref_row               P1_external_request ROWTYPE
    * @param   i_pat                   Patient id
    * @param   i_track_row             p1_tracking ROWTYPE
    * @param   i_dt_create             Operation date
    * @param   o_error                 An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-05-2013
    */

    FUNCTION set_referral_alerts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_pat       IN p1_external_request.id_patient%TYPE,
        i_track_row IN p1_tracking%ROWTYPE,
        i_dt_create p1_tracking.dt_create%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the message to visible to the professional, in alerts area
    * Used in sys_alert.sql_alert for referral alerts
    *
    * @param   i_expression       Expression to evaluate
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-06-2013
    */
    FUNCTION get_alerts_message(i_expression IN sys_alert_event.replace1%TYPE) RETURN VARCHAR2;

    FUNCTION get_code_ref_comments(i_id_ref_comment NUMBER) RETURN VARCHAR2 DETERMINISTIC;

END pk_ref_core_internal;
/
