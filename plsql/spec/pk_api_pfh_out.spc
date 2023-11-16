/*-- Last Change Revision: $Rev: 2055814 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2023-02-24 15:43:04 +0000 (sex, 24 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_out IS

    r_ti_log            ti_log%ROWTYPE;
    r_sys_shortcut      sys_shortcut%ROWTYPE;
    r_grid_task         grid_task%ROWTYPE;
    r_professional      professional%ROWTYPE;
    r_co_sign           co_sign_task%ROWTYPE;
    r_sample_text_type  sample_text_type%ROWTYPE;
    r_action            action%ROWTYPE;
    r_grid_task_between grid_task_between%ROWTYPE;

    -- grid_task necessary constants
    g_grid_drug_admin CONSTANT sys_shortcut.intern_name%TYPE := pk_alert_constant.g_shortcut_prescrip_inten;
    g_date            CONSTANT pk_grid.g_date%TYPE := 'D';
    g_no_color        CONSTANT pk_grid.g_no_color%TYPE := 'X';
    g_color_red       CONSTANT pk_grid.g_color_red%TYPE := 'R';
    g_color_green     CONSTANT pk_grid.g_color_green%TYPE := 'G';

    -- problems type
    g_problem_type_p CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_type_p;
    g_problem_type_a CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_type_a;
    g_problem_type_d CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_type_d;

    -- problems flg_source
    g_problem_source_allergy CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_problem_type_allergy;
    g_problem_source_diag    CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_problem_type_diag;
    g_problem_source_habit   CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_problem_type_habit;
    g_problem_source_problem CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_problem_type_problem;
    g_problem_source_pmh     CONSTANT VARCHAR2(2 CHAR) := pk_problems.g_problem_type_pmh;

    TYPE pat_problem_table IS TABLE OF pk_problems.pat_problem_rec;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_action              Action identifier
     *
     * @return                         true or false on success or error
     *
     * @author                         Bruno Rego
     * @version                        1.0
     * @since                          2011/11/03
    **********************************************************************************************/
    FUNCTION get_action_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN r_action.id_action%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************************
    * This function returns the translation for workflow id_status
    *
    * @param i_lang                                Input language
    * @param i_prof                                Input professional
    * @param i_id_status                           Input workflow id_status
    *
    * Returns the translated status
    *
    * @author                Bruno Rego
    * @version               V.2.6.1
    * @since                 2011/09/08
    ********************************************************************************************/
    FUNCTION get_status_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN wf_status.id_status%TYPE
    ) RETURN VARCHAR2;

    /* Public Function. Call ins_log function from T_TI_LOG package
    *
    * @param      i_lang                Language for translation
    * @param      i_prof                Profissional type
    * @param      i_id_episode          Episode indetification
    * @param      i_flg_status          Status flag
    * @param      i_id_record           Record indentifier
    * @param      i_flg_type            Type flag
    * @param      o_error               Error message
    *
    * @return     TRUE for success and FALSE for error
    *
    * @author     Rui Spratley
    * @version    2.6.1.2
    * @since      2011/07/26
    */
    FUNCTION ins_log
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN r_ti_log.flg_status%TYPE,
        i_id_record  IN r_ti_log.id_record%TYPE,
        i_flg_type   IN r_ti_log.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_ID_SHORTCUT                  Gets the shortcut associated to the given intern_name
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Shortcut internal name
    * @param o_id_shortcut             Shortcut id
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION get_id_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_shortcut.intern_name%TYPE,
        o_id_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update_grid_task                 Update grid task string
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_grid_task               grid_task rowtype
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION update_grid_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete_epis_grid_task            Delete grid task string
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_episode                 Episode indetification
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION delete_epis_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the CO_SIGN task register function              *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_prof_dest  CoSign profissional identifier                      *
    * @param i_episode    Episode identifier                                  *
    * @param i_id_task    Prescription identifier                             *
    * @param i_dt_reg     Date of cosign request                              *
    * @param i_flg_type   Type of cosign (default 'P')                        *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/07/28                                                     *
    **************************************************************************/
    FUNCTION set_co_sign_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_task       IN co_sign_task.id_task%TYPE,
        i_dt_reg        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type      IN co_sign_task.flg_type%TYPE DEFAULT 'P',
        i_id_order_type IN order_type.id_order_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the CO_SIGN task remove function                *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_episode    Episode identifier                                  *
    * @param i_id_task    Prescription identifier                             *
    * @param i_flg_type   Type of cosign (default 'P')                        *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/07/28                                                     *
    **************************************************************************/
    FUNCTION remove_co_sign_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_id_task  IN co_sign_task.id_task%TYPE,
        i_flg_type IN co_sign_task.flg_type%TYPE DEFAULT 'P',
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_justif_list                  Get Justification List
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_grid_task               grid_task rowtype
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Pedro Teixeira
    * @version                         2.6.1.2
    * @since                           2011/08/05
    *
    **********************************************************************************************/
    FUNCTION get_justif_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the CO_SIGN professionals list function         *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_episode    Episode identifier                                  *
    * @param o_prof_list  List of professionals available for co-sign         *
    * @param o_error      Error message                                       *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/29                                                     *
    **************************************************************************/
    FUNCTION get_co_sign_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the CO_SIGN professionals list function
    *
    * @param i_lang       The ID of the user language
    * @param i_prof       The profissional array
    * @param i_episode    Episode identifier
    * @param o_prof_list  List of professionals available for co-sign
    * @param o_error      Error message
    *
    *
    * @author  Pedro Teixeira
    * @since   2013/10/21
    **************************************************************************/
    FUNCTION get_co_sign_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the CO_SIGN contact type list function          *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param o_order_type List of order types available for co-sign           *
    * @param o_error      Error message                                       *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/29                                                     *
    **************************************************************************/
    FUNCTION get_co_sign_order_type_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will call the pk_sample_text.get_sample_text function     *
    * that will return the list of sample text to use on text fields          *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_sample_text_type   Sample text type                            *
    * @param i_patient            The patient identifier                      *
    * @param i_prof               The profissional array                      *
    * @param o_sample_text        List of sample texts                        *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/31                                                     *
    **************************************************************************/
    FUNCTION get_most_frequent_texts
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of action information for a specified set of id_action's.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_action              id action
     *
     * @return                         The icon Name
     *
     * @author                         Pedro Quinteiro
     * @version                        2.6.1
     * @since                          12/09/2011
    **********************************************************************************************/
    FUNCTION get_action_icon_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN action.id_action%TYPE
    ) RETURN action.icon%TYPE;

    /******************************************************************************
    * Get the id_visit  given a episode
    * @param i_episode                                  IN: episode id
    *
    * @param o_error                                    OUT: error
    *********************************************************************************/
    FUNCTION get_visit
    (
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN visit.id_visit%TYPE;

    /**
    * Updates the prescription identifier used in the CDR engine.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_presc_old    outdated prescription identifier
    * @param i_presc_new    updated prescription identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2?
    * @since                2011/09/28
    */
    PROCEDURE set_cdr_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_presc_old IN cdr_call_det.id_task_request%TYPE,
        i_presc_new IN cdr_call_det.id_task_request%TYPE,
        o_error     OUT t_error_out
    );

    /******************************************************************************
    * Get reports list
    * @param i_lang             IN language id
    * @param i_prof             IN  profissional (id, institution, software)
    * @param i_episode          IN  episode
    * @param i_screen_name      IN  screen name
    * @param i_sys_button_prop  IN  sys_button_prop
    *
    * @param o_reports          OUT report list
    * @param o_error            OUT error
    *
    * @return                    boolean
    *
    * @author                    Pedro Quinteiro
    * @version                   2.6.1.2
    * @since                     2011/10/07
    *********************************************************************************/
    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_area_report     IN VARCHAR2,
        i_screen_name     IN VARCHAR2,
        i_sys_button_prop IN NUMBER,
        i_task_type       IN table_number,
        i_context         IN table_varchar,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION set_diag_problem
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_diagnosis IN table_number,
        i_id_problems  IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter lista dos profissionais da instituição (para medicação)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  o_error                       The error object
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  23/05/2010
    *
    ********************************************************************************************/
    FUNCTION get_prof_med_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_category IN table_varchar,
        o_prof     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the id_software associated to a type of episode in an institution
    *
    * @param i_epis_type              Type of episode
    * @param i_institution            Institution ID
    * @return                         Software ID
    *
    * @author                         Ariel Geraldo Machado
    * @version                         1.0 (2.4.4)
    * @since                          2008/11/10
    ********************************************************************************************/
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
        
    ) RETURN epis_type_soft_inst.id_software%TYPE;

    /*******************************************************************************************************************************************
    * Gets all the scales available for any given timeline
    *
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information array
    * @param ID_TL_TIMELINE           Timeline ID
    * @param O_tl_timeline            Contains the scales available in the given timeline
    * @param O_ERROR                  Devolução do erro
    *
    * @return                         False if an error occurs, true otherwise
    *
    * @author                         Nelson Canastro
    * @version                         1.0
    * @since                          15/02/2011
    *******************************************************************************************************************************************/
    FUNCTION get_timescale_by_tl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_scale_inst_soft_market.id_tl_timeline%TYPE,
        o_tl_scales      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actions available for a given status of a given workflow
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_ID_WORKFLOW      Workflow identifier
    * @param   I_ID_STATUS_BEGIN  Begin action state
    * @param   I_PARAMS           Params table_varchar for validateing transitions
    * @param   I_VALIDATE_TRANS   Validates the possible status transitions
    * @param   I_SHOW_DISABLE     Shows or hides the disable actions (either user has no access to them or they are not valid for the given status)
    * @param   O_ACTIONS          actions
    *
    * @value   I_VALIDATE_TRANS   {*} Y - Validates the possible status transitions {*} N - Ignores transition validation
    * @value   I_SHOW_DISABLE     {*} Y - Shows actions not enabled for the user/current status {*} N - Hides actions not enabled for the user/current status
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Nelson Canastro
    * @version 2.6
    * @since   14-01-2011
    */
    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin      IN wf_status.id_status%TYPE,
        i_params               IN table_varchar,
        i_validate_trans       IN VARCHAR2,
        i_show_disable         IN VARCHAR2,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get actions based on the multiple subject and workflow
    * the inactive records are dominant and overlap active records (for the same ID_ACTION)
    *
    * @param  i_lang              The language ID
    * @param  i_prof              The professional array
    * @param  i_subject           Action Subject
    * @param  i_id_workflow       Workflow ID
    * @param  i_id_status_begin   Workflow Status
    * @param  i_params
    * @param  i_validate_trans    Flag that indicates if trans is to be validated
    * @param  i_show_disable      Flag indicating if disabled status is to be shown
    * @param  o_actions           Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    FUNCTION get_actions_subject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_id_workflow     IN table_number,
        i_id_status_begin IN table_number,
        i_params          IN table_varchar,
        i_validate_trans  IN VARCHAR2,
        i_show_disable    IN VARCHAR2,
        i_force_inactive  IN VARCHAR2,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if transition is available (id_workflow, i_id_status_begin, i_id_status_end)
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Begin status identifier
    * @param   i_id_status_begin      End status identifier
    * @param   i_id_workflow_action   Action identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition           Transition identifier
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition.id_status_end%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_flg_available       OUT NOCOPY VARCHAR2,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_act_wf_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_actions              IN table_number,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2 DEFAULT NULL,
        i_class_origin_context IN VARCHAR2 DEFAULT NULL,
        o_actions              OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Get the final state based on workflow action, workflow identifier and initial state
    * NOTE: this function ONLY works when one action have ONLY one transition
    *
    * @param  i_lang                      The language ID
    * @param  i_prof                      The professional array
    * @param  i_id_wf_action              Workflow ID
    * @param  i_id_workflow               Workflow Status
    * @param  i_id_status_begin           Status Begin
    * @param  o_id_status_end             Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    PROCEDURE get_wf_trans_status_end
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_wf_action    IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        o_id_status_end   OUT wf_status.id_status%TYPE
    );

    FUNCTION get_actions_by_wf
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /**
    * Get status color
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_color
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Get the begining status of workflow
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */
    FUNCTION get_status_begin
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN wf_status_workflow.id_workflow%TYPE,
        o_status_begin OUT NOCOPY wf_status_workflow.id_status%TYPE,
        o_error        OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns an array with all professsional from the same dep_clin_serv of the current professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Elisabete Bugalho
    * @version                         2.6.1.2
    * @since                           2011/10/10
    *
    **********************************************************************************************/
    FUNCTION get_prof_dcs_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;
    /********************************************************************************************
    * Returns problems
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_pat                     patient identifier
    * @param i_status                  flag status
    * @param i_type                    type
    * @param i_problem                 problem id
    * @param i_episode                 episode identifier
    * @param i_report                  report flag
    * @param i_dt_ini                  init date
    * @param i_dt_end                  end date
    *
    * @author                          Paulo Teixeira
    * @version                         2.6.1.2
    * @since                           2011/10/12
    *
    **********************************************************************************************/
    FUNCTION get_pat_problem_tf
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pk_problems.pat_problem_table
        PIPELINED;

    /** @headcom
    * Public Function. Returns market for given institution.
    *
    * @param      I_institution              ID of instituition
    *
    * @return     number
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2006/11/04
    */
    FUNCTION get_inst_mkt(i_id_institution IN institution.id_institution%TYPE) RETURN market.id_market%TYPE;

    /**
    * List associations between allergies and products.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_allergies    allergy identifiers list
    * @param o_allg_prod    data cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/17
    */
    FUNCTION get_products
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_allergies IN table_number,
        o_allg_prod OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get id of the report for a specific market, institution, software and type of prescription
    *
    *
    * @author Pedro Teixeira
    * @since  23/12/2011
    *
    ********************************************************************************************/
    FUNCTION get_rep_prescription_match
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_presc_type          IN VARCHAR2,
        i_drug_type           IN VARCHAR2,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        o_id_reports          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * List associations between allergies and products.
    *
    * @param i_lang         language identifier
    * @param o_cursor    symptoms_list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Quinteiro
    * @version               2.6.2
    * @since                2012/02/01
    */
    FUNCTION get_symptoms_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * DELETE_DRUG_PRESC_FIELD         Forces the deletion of DRUG_PRESC field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @version                        2.6.2
    * @since                          15/02/2012
    * @alteration                     
    **********************************************************************************************/
    FUNCTION grid_task_del_drug_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * validar se o perfil tem ou não permissão requisitar sem co-sign 
    
    * @param i_lang                   The language ID
    * @param o_prof                   Cursor containing the professional list 
    
    * @param i_flg_type               Devolve Y ou N                                      
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/08/30
    **********************************************************************************************/
    FUNCTION get_date_time_stamp_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualizar tabelas EA no delete_presc
    * @param i_lang                   The language ID
    * @param i_prof                   Cursor containing the professional list 
    * @param i_id_patient             patient
    * @param i_num_med    IN NUMBER,
    * @param i_desc_med   IN VARCHAR2,
    * @param i_code_med   IN VARCHAR2,
    * @param i_dt_med     IN TIMESTAMP WITH LOCAL TIME ZONE
    * 
    * @author                         Pedro Morais
    * @since                          2012/07/10
    **********************************************************************************************/
    PROCEDURE update_ea_for_deleted_rows
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_num_med    IN NUMBER,
        i_desc_med   IN VARCHAR2,
        i_code_med   IN VARCHAR2,
        i_dt_med     IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**********************************************************************************************
    * Registers the consumption of supplies in the prescription administration
    * 
    * @i_lang               Language ID
    * @i_prof               Professional's info
    * @i_id_episode         Episode ID
    * @i_id_context         Context ID
    * @i_flg_context        Flag for context
    * @i_id_supply_workflow Workflow IDs
    * @i_supply             Supplies' IDs
    * @i_supply_set         Parent supply set (if applicable)
    * @i_supply_qty         Supply quantities
    * @i_flg_supply_type    Supply or supply Kit
    * @i_barcode_scanned    Barcode scanned
    * @i_deliver_needed     Deliver needed
    * @i_flg_cons_type      Consumption type
    * i_dt_expected_date    Expected return date
    * @o_error              Error info
    * 
    * @return               True on success, false on error
    * 
    * @author               Rita Lopes
    * @version              2.6.2
    * @since                2012/10/02
    **********************************************************************************************/
    FUNCTION create_sup_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply_workflow IN table_number,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_flg_supply_type    IN table_varchar,
        i_barcode_scanned    IN table_varchar,
        i_deliver_needed     IN table_varchar,
        i_flg_cons_type      IN table_varchar,
        i_notes              IN table_varchar,
        i_dt_expiration      IN table_varchar,
        i_flg_validation     IN table_varchar,
        i_lot                IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Procedure to update task_timeline_ea with information regarding reconciliation information
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               The episode id
    * @param   I_ID_PATIENT               The patient id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Pedro Teixeira
    * @version                            2.6.2
    *
    **********************************************************************************************/
    FUNCTION update_task_tl_recon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN episode.id_patient%TYPE,
        i_id_presc        IN NUMBER,
        i_dt_req          IN episode.dt_begin_tstz%TYPE,
        i_id_prof_req     IN episode.id_prof_cancel%TYPE,
        i_id_institution  IN episode.id_institution%TYPE,
        i_event_type      IN VARCHAR2,
        i_id_tl_task      IN NUMBER,
        i_id_prev_tl_task IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates a new prescription for one or more procedures associated with administered medication 
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     i_intervention   Procedure id
    * @param     i_flg_time       Flag that indicates when the procedure is to be executed
    * @param     i_dt_begin       Begin date
    * @param     i_medication     Medication id
    * @param     o_error          Error message
    
    * @return    string on success or error
    *
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/10/14 
    */

    FUNCTION set_procedure_with_medication
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_medication   IN NUMBER,
        i_notes        IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a string with supplies info 
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_CONTEXT               The context id
    * @param   I_FLG_CONTEXT              The flg context id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             VARCHAR
    *
    * @author                             Rita Lopes
    * @version                            2.6.3
    *
    **********************************************************************************************/
    FUNCTION get_count_supplies_str_all
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_context               IN supply_context.id_context%TYPE,
        i_flg_context              IN supply_context.flg_context%TYPE,
        i_flg_filter_type          IN VARCHAR2 DEFAULT 'A',
        i_flg_status               IN VARCHAR2 DEFAULT NULL,
        i_flg_show_set_description IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    g_interv_request CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';

    /********************************************************************************************
    * Returns Y if current professional has cosign; N otherwise
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    *
    * @RETURN                             VARCHAR
    *
    * @author                             Rui Mendonça
    * @version                            2.6.3.1
    **********************************************************************************************/
    FUNCTION get_cosign_config
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_witness_prof_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_header_messages OUT pk_types.cursor_type,
        o_prof_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List all patient's response to treatment  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_treat                  id_treatment (id prescription)
    * @param o_treat_manag            Patient's response to treatment 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013/06/05 
    *
    **********************************************************************************************/
    FUNCTION get_treat_manag_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE,
        o_treat     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List all service alocated to professional  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         table_number ( id_dep_clin_serv )
    * 
    * @author                         Carlos FErreira
    * @version                        1.0
    * @since                          2013/09/10
    *
    **********************************************************************************************/
    FUNCTION get_list_prof_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;

    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN NUMBER;

    /********************************************************************************************
    * return login of given professional  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         table_number ( login )
    * 
    * @author                         Carlos FErreira
    * @version                        1.0
    * @since                          2013/09/12
    *
    **********************************************************************************************/
    FUNCTION get_prof_login
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_prof_photo(i_prof IN profissional) RETURN VARCHAR2;

    /** @clone_contraindications
    * Public procedure. clones data from given medication Id to other medication ID
    *   Tables cloned:  CDR_INSTANCE, CDR_INST_PARAM, CDR_INST_PAR_VAL,
    *                   CDR_INST_PAR_ACTION, CDR_INST_PAR_ACT_VAL
    *
    * @param    i_prof                  info of professional used
    * @param    i_old_cds_product       id of old product ( already formatted )
    * @param    i_new_cds_product       id of new product ( already formatted )
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    PROCEDURE clone_contraindications
    (
        i_prof            IN profissional,
        i_old_cds_product IN VARCHAR2,
        i_new_cds_product IN VARCHAR2
    );

    /*********************************************************************************************
    * Returns the institutions associated to a given market
    * 
    * @param         i_lang                user language
    * @param         i_id_market           Market ID
    *
    * @param         o_institution         institution ids
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Sofia Mendes
    * @version       2.6.3.13
    * @date          17-Mar-2014
    ********************************************************************************************/
    FUNCTION get_institutions_by_mkt
    (
        i_lang        IN language.id_language%TYPE,
        i_id_market   IN institution.id_market%TYPE,
        o_institution OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Returns the institutions associated to a given market
    * 
    * @param         i_lang                user language
    * @param         i_prof                professional, institution and software ids
    * @param         i_id_patient          Patient ID
    * @param         i_id_episode          Episode ID
    * @param         i_barcode             Patient Barcode
    *
    * @param         o_summary             Validation description
    * @param         o_result              Validation result
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          25-Mar-2014
    ********************************************************************************************/
    FUNCTION validate_patient_barcode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_barcode    IN VARCHAR2,
        o_summary    OUT VARCHAR2,
        o_result     OUT VARCHAR2,
        o_patient    OUT patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Returns the patient info
    * 
    * @param i_lang             The ID of the user language
    * @param i_id_pat           Patient ID
    * @param i_prof             The profissional array
    *
    * @param o_name             Patient name
    * @param o_nick_name        Patient nick name
    * @param o_gender           Patient gender
    * @param o_dt_birth         Patient date of birth
    * @param o_age              Patient current age
    * @param o_dt_deceased      Patient decease date
    * @param o_error            Error message
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_nick_name   OUT patient.nick_name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_dt_birth    OUT VARCHAR2,
        o_age         OUT VARCHAR2,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Returns the patient episode number
    * 
    * @param i_lang             The ID of the user language
    * @param i_id_episode       Episode ID
    * @param i_prof             The profissional array
    *
    * @param o_episode          Episode ID
    * @param o_error            Error message
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_epis_ext
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_episode    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Returns the patient process
    * 
    * @param i_lang             The ID of the user language
    * @param i_prof             The profissional array
    * @param i_id_patient       Patient ID
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_process
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_show_content_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *********************************************************************************************/
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

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION remove_print_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        i_context_data    IN CLOB,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION cancel_pg_print_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_presc_list   IN table_number,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_medication_print_poput_opt
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_poput_opt OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Sets episode 1st observation
    * 
    * @author        Sofia Mendes
    * @version       2.6.4
    * @date          2014/11/11
    ********************************************************************************************/
    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_api_pfh_out.get_vs_most_recent_value
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_VITAL_SIGN                         IN        NUMBER(22,24)
    * @param  I_SCOPE                                 IN        NUMBER
    * @param  I_SCOPE_TYPE                            IN        VARCHAR2
    * @param  I_DT_BEGIN                              IN        VARCHAR2
    * @param  I_DT_END                                IN        VARCHAR2
    * @param  O_INFO                                  OUT       REF CURSOR
    * @param  O_ERROR                                 OUT       T_ERROR_OUT
    *
    * @return  BOOLEAN
    *
    * @author      Pedro Miranda
    * @version     
    * @since       18/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_api_pfh_out.get_vs_value_dt_reg
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_VITAL_SIGN_READ                    IN        NUMBER(22,24)
    * @param  I_DT_VS_READ                            IN        TIMESTAMP WITH LOCAL TIME ZONE
    * @param  I_DT_REGISTRY                           IN        TIMESTAMP WITH LOCAL TIME ZONE
    * @param  O_INFO                                  OUT       REF CURSOR
    * @param  O_ERROR                                 OUT       T_ERROR_OUT
    *
    * @return  BOOLEAN
    *
    * @author      Sergio Cunha
    * @version     
    * @since       27/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Convert unit measures
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_value             Value to convert
    * @param  i_unit_meas         Origin unit measure
    * @param  i_unit_meas_def     Target unit measure
    *
    * @return Converted value
    *
    * @author Jose Brito
    * @since  31/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_unit_mea_conversion
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get interventions aliases or descriptions
    *
    * @param i_lang                language id
    * @param i_prof                professional type
    * @param i_code_interv         
    * @param i_dep_clin_serv       
    *
    * @return                      VARCHAR2
    *
    * @author                      Rui Mendonça
    * @version                     2.6.5.1
    * @since                       2015/11/06
    ********************************************************************************************/
    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get diagnosis description associated to the given id_epis_diagnosis
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_epis_diagnosis Epis Diagnosis ID  
    *
    * @return Diagnosis description associated to the given id_epis_diagnosis
    *
    * @author Sofia Mendes
    * @since  07/11/2016
    *
    ********************************************************************************************/
    FUNCTION get_diagnosis_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Get the b_value from table inter_map.map according with the given arguments
    *
    * @param   i_a_system        IN VARCHAR2
    * @param   i_b_system        IN VARCHAR2
    * @param   i_a_value         IN VARCHAR2
    * @param   i_a_definition    IN VARCHAR2
    * @param   i_b_definition    IN VARCHAR2
    * @param   i_id_institution  IN NUMBER
    * @param   i_id_software     IN NUMBER
    * @param   o_b_value         OUT NOCOPY VARCHAR2
    * @param   o_error           OUT NOCOPY VARCHAR2
    *
    * @return                      BOOLEAN
    *
    * @author                      rui.mendonca
    * @version                     2.7.1.0
    * @since                       2017/04/12
    ********************************************************************************************/
    FUNCTION get_map_a_b
    (
        i_a_system       IN VARCHAR2,
        i_b_system       IN VARCHAR2,
        i_a_value        IN VARCHAR2,
        i_a_definition   IN VARCHAR2,
        i_b_definition   IN VARCHAR2,
        i_id_institution IN NUMBER,
        i_id_software    IN NUMBER,
        o_b_value        OUT NOCOPY VARCHAR2,
        o_error          OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * DELETE_DRUG_REQ_FIELD         Forces the deletion of DRUG_REQ field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION grid_task_del_drug_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * UPDATE_DRUG_REQ_FIELD
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION grid_task_upd_drug_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_drug_req   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Provides the bed description  of the active bed allocation
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_epis              ID_EPIS
    * @param      o_desc              Bed description (null if no allocation)
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.7
    * @since   15-01-2018
    *
    ****************************************************************************************************/
    FUNCTION get_bed_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_desc  OUT pk_translation.t_desc_translation,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to get rank from grid_task string
    *
    * @param   i_grid_task_str   Grid Task String, ex.: 6|I|||DispensationPendingIcon|0xE8BE44|||||1
    *
    * @return  NUMBER
    *
    * @author          Pedro Teixeira
    * @since           15/01/2018
    ********************************************************************************************/
    FUNCTION get_rank_from_gt_string(i_grid_task_str IN VARCHAR2) RETURN NUMBER;

    /********************************************************************************************
    * Get multichoice options by a multichoice type
    *
    * @author       Pedro Teixeira
    * @since        28/02/2018
    **********************************************************************************************/
    FUNCTION get_multichoice_options
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_multichoice_type    IN VARCHAR2,
        o_multichoice_options OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to get icon from grid_task string
    *
    * @param   i_grid_task_str   Grid Task String, ex.: 6|DI|20180321112600||UrgentIcon||||0xEBEBC8|20180321142638|
    *
    * @return  VARCHAR
    *
    * @author          CRISTINA.OLIVEIRA
    * @since           23/03/2018
    ********************************************************************************************/
    FUNCTION get_icon_from_gt_string(i_grid_task_str IN VARCHAR2) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_inst_epis_departments
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_dept_department_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_desc_type     IN VARCHAR2 DEFAULT NULL -- D -> Department; S -> Service; NULL -> Department ' - ' Service
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function to get the number of refill from column refill_date of view V_MYPATIENTS_PHARMACY_GRID
    *
    * @param   i_refill_date_str   ex.: 1|25-APR-18 01.00.49.217000 AM
    *
    * @return  NUMBER
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   02/05/2018
    ********************************************************************************************/
    FUNCTION get_nr_refill_from_review(i_refill_date_str IN VARCHAR2) RETURN NUMBER;

    /********************************************************************************************
    * Function to get the date from column refill_date of view V_MYPATIENTS_PHARMACY_GRID
    *
    * @param   i_refill_date_str   ex.: 1|25-APR-18 01.00.49.217000 AM
    *
    * @return  VARCHAR2
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   02/05/2018
    ********************************************************************************************/
    FUNCTION get_date_from_review(i_refill_date_str IN VARCHAR2) RETURN VARCHAR2;

    /************************************************************************************************************
    * This function returns the previous visit id associated to a episode and type of episode
    *
    * @param      i_episode         Episode Id
    * @param      i_id_epis_type    Type of episode Id (ex: inpatient=5)
    *
    * @return     Visit Id
    *
    * @author     CRISTINA.OLIVEIRA
    * @version    2.7
    * @since      2018/06/05
    ************************************************************************************************************/
    FUNCTION get_previous_visit
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN episode.id_visit%TYPE;

    /************************************************************************************************************
    * This function returns all allergies of patient
    *
    * @param      i_lang                     language ID
    * @param      i_prof                     ALERT profissional
    * @param      i_patient                  Id_patient
    * @param      o_allergies                Cursor of allergies
    * @param      o_allergies_unawareness    Cursor of allergies unawareness
    * @param      o_error                    If an error accurs, this parameter will have information about the error
    *
    * @return     TRUE or FALSE
    *
    * @author     Adriana Ramos
    * @version    2.7
    * @since      2018/07/05
    ************************************************************************************************************/
    FUNCTION get_pat_allergies_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_flg_show_msg          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_allergies             OUT pk_types.cursor_type,
        o_allergies_unawareness OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_vs_value_unit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg      IN vital_sign_read.dt_vital_sign_read_tstz%TYPE DEFAULT NULL,
        o_vs_value        OUT VARCHAR2,
        o_vs_unit_measure OUT NUMBER,
        o_vs_um_desc      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************
    ********************************************************************************/
    FUNCTION set_confirmed_epis_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_params            IN CLOB,
        o_id_epis_diagnosis OUT table_number,
        o_id_diagnosis      OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_hand_off_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        io_hand_off_type IN OUT sys_config.value%TYPE
    );

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_sa_dispense_label_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_validation     IN profissional,
        i_prof_print_label    IN profissional,
        o_inst_name           OUT VARCHAR2,
        o_inst_name_sa        OUT VARCHAR2,
        o_phone_num           OUT VARCHAR2,
        o_num_mec_val         OUT VARCHAR2,
        o_num_mec_print_label OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    ************************************************************************************************************/
    FUNCTION get_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN VARCHAR2,
        i_patient          IN NUMBER,
        i_prof             IN profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get a set of professionals that are able to do cosign
    *
    * @param   i_lang            IN   language.id_language%TYPE
    * @param   i_prof            IN   profissional
    * @param   i_id_episode      IN   episode.id_episode%TYPE
    * @param   i_id_order_type   IN   order_type.id_order_type%TYPE
    * @param   o_prof_list       OUT  pk_types.cursor_type
    * @param   o_error           OUT  t_error_out
    *
    * @return  Boolean
    *
    * @author  rui.mendonca
    * @version PFH 2.7.4.0
    * @since   29/08/2018
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION generate_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_barcode_type IN VARCHAR2,
        i_institution  IN NUMBER,
        i_software     IN NUMBER,
        o_barcode      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Provides the room description associate to a bed
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_epis              ID_EPIS
    * @param      o_desc              room description (null if no allocation)
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN     TRUE or FALSE
    * @author     CRISTINA.OLIVEIRA
    * @version    2.7
    * @since      04-10-2018
    ****************************************************************************************************/
    FUNCTION get_room_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_desc  OUT pk_translation.t_desc_translation,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE;

    /**********************************************************************************************
    * Update field disp_ivroom of grid_task for a given episode 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             Episode identifier
    * @param i_disp_ivroom            field disp_ivroom of grid_task
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         CRISTINA.OLIVEIRA
    * @since                          18/01/2019
    **********************************************************************************************/
    FUNCTION grid_task_upd_disp_ivroom
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_disp_ivroom IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Update field i_disp_task of grid_task for a given episode 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             Episode identifier
    * @param i_disp_task              field i_disp_task of grid_task
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         CRISTINA.OLIVEIRA
    * @since                          18/01/2019
    **********************************************************************************************/
    FUNCTION grid_task_upd_disp_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_disp_task  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *Forces the deletion of DISP_IVROOM field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         CRISTINA.OLIVEIRA     
    * @since                          18/01/2019
    **********************************************************************************************/
    FUNCTION grid_task_del_disp_ivroom
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *Forces the deletion of DISP_TASK field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         CRISTINA.OLIVEIRA     
    * @since                          18/01/2019
    **********************************************************************************************/
    FUNCTION grid_task_del_disp_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *********************************************************************************/
    FUNCTION get_pat_comp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN alert.profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_flg_comp         OUT VARCHAR2,
        o_flg_special_comp OUT VARCHAR2,
        o_flg_plan_type    OUT VARCHAR2,
        o_flg_recm         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************
    *********************************************************************************/
    FUNCTION check_patient_rules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_message_title   OUT VARCHAR2,
        o_message_text    OUT VARCHAR2,
        o_forward_button  OUT VARCHAR2,
        o_back_button     OUT VARCHAR2,
        o_flg_can_proceed OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_patient_rules_ue
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_message_text OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_name_to_sort
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context_m  IN table_varchar,
        i_id_context_p  IN table_varchar,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_next_cpoe_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_start OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end   OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_current_cpoe_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_dt_start   OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_param
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_param IN table_number,
        i_dt_result      IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_analysis_result_par IN analysis_result_par.dt_analysis_result_par_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_epis_out_on_pass_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_patient_alerts_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_id_patient   IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    FUNCTION get_inst_epis_departments
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_requested_supplies_per_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN supply_request.flg_context%TYPE,
        i_id_context  IN supply_workflow.id_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_default_supplies_req_cfg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context_d   IN supply_request.flg_context%TYPE,
        i_id_context_d    IN supply_workflow.id_context%TYPE,
        i_id_context_m    IN table_varchar,
        i_id_context_p    IN table_varchar,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        o_supply_request    OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_workflow_lst
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        o_supply_wokflow_lst OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2;

    FUNCTION update_supply_record
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_lot      IN table_varchar,
        i_barcode_scanned IN table_varchar,
        i_dt_request      IN table_varchar,
        i_dt_expiration   IN table_varchar,
        i_flg_validation  IN table_varchar,
        i_flg_supply_type IN table_varchar,
        i_deliver_needed  IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_flg_consumption IN table_varchar,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_supply_request  OUT supply_request.id_supply_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_supply_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN supply_context.id_context%TYPE,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN supply_request.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_supplies_not_in_inicial_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN supply_request.flg_context%TYPE,
        i_id_context       IN supply_workflow.id_context%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE
    ) RETURN VARCHAR2;

    FUNCTION inactivate_records_by_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update_nurse_task                Insert/Update in the table GRID_TASK_BETWEEN
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_grid_task               grid_task rowtype
    * @param o_error                   Error message
    * 
    * @return                          true or false on success or error
    *
    * @author                          Cristina Oliveira
    * @version                         2.8.4
    * @since                           2022/02/14
    *
    **********************************************************************************************/
    FUNCTION update_nurse_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task_between%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supplies_descr_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2;

    FUNCTION get_process_end_date_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * verify CPOE working mode for given institution or software
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       o_flg_mode        CPOE working mode 
    * @param       o_error           error message
    *
    * @value       o_flg_mode        {*} 'S' working in simple mode 
    *                                {*} 'A' working in advanced mode
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/06
    ********************************************************************************************/
    FUNCTION get_cpoe_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_mode OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION check_area_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN VARCHAR2,
        o_val     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_my_patients              Called from a 'My patients' grid: (Y) Yes (N) No - default
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN table_number;

    FUNCTION get_med_info_button_url
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc            IN NUMBER,
        o_url                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_pharm_info_stock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_product       IN VARCHAR2,
        i_id_supply_source IN NUMBER,
        o_info_stock       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
END pk_api_pfh_out;
/
