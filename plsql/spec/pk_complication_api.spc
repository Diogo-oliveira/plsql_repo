/*-- Last Change Revision: $Rev: 2028572 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_complication_api IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 04-12-2009 15:49:55
    -- Purpose : Complication API

    -- Public type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Public constant declarations
    --<ConstantName> CONSTANT <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    -- Public function and procedure declarations
    /**
    * Gets the list of complications for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_complications             List of complications for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-12-2009
    */
    FUNCTION get_epis_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of requests for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_requests                  List of requests for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_epis_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of complication specific button actions
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    * @param   i_subject                   Subject: CREATE - Button create options; ACTION - Button action options
    * @param   o_actions                   List of actions
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2,
        i_subject           IN action.subject%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the specified selection list type
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   i_parent_axe                Parent axe id or NULL to get root values
    * @param   o_axes                      List of pathologies/locations/external factors/effects
    * @param   o_max_level                 Maximum level that has this type of lis
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_axes_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN sys_list_group_rel.flg_context%TYPE,
        i_parent_axe IN comp_axe.id_comp_axe%TYPE,
        o_axes       OUT pk_types.cursor_type,
        o_max_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets selection list type groups
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   o_groups                    List of pathologies/locations/external factors/effects
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2009
    */
    FUNCTION get_axes_grp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN sys_list_group_rel.flg_context%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the complication selection list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_complication_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_def_path      OUT pk_types.cursor_type,
        o_def_loc       OUT pk_types.cursor_type,
        o_def_ext_fact  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the complication selection list (Without default values)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_lst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the complication default values lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_complication              Complication id
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_dft_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_complication IN complication.id_complication%TYPE,
        o_def_path     OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact OUT pk_complication_core.epis_comp_def_cursor,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_comp_detail               All complication detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_comp_detail       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets complication detail data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_request                   All request data
    * @param   o_request_detail            All request detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_request           OUT pk_types.cursor_type,
        o_request_detail    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add a new complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION create_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add a new complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION create_comp_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_comp_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of tasks to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   o_type_tasks                Type of tasks
    * @param   o_tasks                     Tasks list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_assoc_task_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_type_tasks OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the type of treatments to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_treat                     Types of treatment
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_treat_perf_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_treat OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reject a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_reject_reason             Reject reason id
    * @param   i_notes_reject              Reject notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION set_reject_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_reject_reason     IN epis_complication.id_reject_reason%TYPE,
        i_notes_reject      IN epis_complication.notes_rejected%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Accept the request and insert complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-01-2009
    */
    FUNCTION set_accept_request
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_cols  IN table_varchar,
        i_vals  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets discharge confirmation message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_show                      Y - Confirmation message is to be shown; Otherwise N
    * @param   o_title                     Confirmation title
    * @param   o_quest                     Confirmation question
    * @param   o_msg                       Confirmation message
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_disch_conf_msg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_show    OUT VARCHAR2,
        o_title   OUT VARCHAR2,
        o_quest   OUT VARCHAR2,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_clin_serv                 Clinical services list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   01-03-2010
    */
    FUNCTION get_prof_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get domain values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_code_dom                  Element domain
    * @param   i_dep_clin_serv             Dep_clin_serv ID                                                              
    * @param   o_data                      Domain values list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION get_domain_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get complaint for CDA section: Chief Complaint and Reason for Visit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_complaint             Cursor with all complaints for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2013/12/23 
    ***********************************************************************************************/
    FUNCTION get_epis_complaint_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        o_complaint  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_complication_api;
/
