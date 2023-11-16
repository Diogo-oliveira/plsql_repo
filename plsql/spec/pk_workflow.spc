/*-- Last Change Revision: $Rev: 1903202 $*/
/*-- Last Change by: $Author: pedro.teixeira $*/
/*-- Date of last change: $Date: 2019-05-10 14:44:38 +0100 (sex, 10 mai 2019) $*/

CREATE OR REPLACE PACKAGE pk_workflow AS

    TYPE t_rec_wf_trans_config IS RECORD(
        id_workflow         NUMBER(24),
        id_status_begin     NUMBER(24),
        id_status_end       NUMBER(24),
        id_workflow_action  NUMBER(24),
        id_software         NUMBER(24),
        id_institution      NUMBER(24),
        id_profile_template NUMBER(12),
        id_functionality    NUMBER(12),
        FUNCTION            VARCHAR2(2000),
        rank                NUMBER(6),
        icon                VARCHAR2(200),
        desc_transition     VARCHAR2(4000),
        flg_permission      VARCHAR2(1),
        flg_auto_transition VARCHAR2(1),
        flg_visible VARCHAR2(1));

    g_transition_allow CONSTANT wf_transition_config.flg_permission%TYPE := 'A'; -- (A)llow
    g_transition_deny  CONSTANT wf_transition_config.flg_permission%TYPE := 'D'; -- (D)eny

    /**
    * Get grid backgroud color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_grid_bg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get grid foreground color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_grid_fg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get other backgroud color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_other_bg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get other foreground color status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_color_str            Color string
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_other_fg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_color_str IN wf_status.color%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get status information without evaluating function
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier  
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   o_status_config_info   WF_STATUS_CONFIG data
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_config
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        o_status_config_info  OUT NOCOPY t_rec_wf_status_info,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get status information (pipelined function)
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
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    *
    FUNCTION get_status_info_p
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN t_coll_wf_status_info
        PIPELINED;
    
    /**
    * Get status information
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_status_info          Status information
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_info
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        o_status_info         OUT NOCOPY t_rec_wf_status_info,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get status information
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
    * @RETURN  Status information
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   15-03-2011
    */
    FUNCTION get_status_info
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN t_rec_wf_status_info;

    /**
    * Get status icon
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
    * @RETURN  ICON name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_icon
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2;

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
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Get status rank
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
    * @RETURN  status rank
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_rank
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN NUMBER;

    /**
    * Get status description
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
    * @RETURN  status description
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION get_status_desc
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
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
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN wf_status_workflow.id_workflow%TYPE,
        o_status_begin OUT NOCOPY wf_status_workflow.id_status%TYPE,
        o_error        OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the begining status of workflow
    *
    * @param   i_id_workflow          Workflow identifier
    *
    * @RETURN  Begin status identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-06-2013
    */
    FUNCTION get_status_begin(i_id_workflow IN wf_status_workflow.id_workflow%TYPE)
        RETURN wf_status_workflow.id_status%TYPE;

    /**
    * Get transitions available starting from i_id_status_begin status
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Status identifier
    * @param   i_id_workflow_action   Workflow action identifier. If null, all workflow actions are considered.
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   i_flg_auto_transition  Indicates whether we want automatic transitions. 
    *                                           {*} Y - automatic transitions returned
    *                                           {*} N - non-autiomatic transitions returned
    *                                           {*} <null>  - all transitions returned (automatic or not)
    * @param   o_transitions          Transitions information
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-03-2009
    */
    FUNCTION get_transitions
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE DEFAULT NULL,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_flg_auto_transition IN wf_transition.flg_auto_transition%TYPE,
        o_transitions         OUT NOCOPY t_coll_wf_transition,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get software status default info
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software   
    * @param   i_id_market            Market identifier
    * @param   o_status_info          Status information [ID_STATUS|DESC_STATUS|ICON|COLOR|RANK|CODE_STATUS]
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined. Status information [ID_STATUS|DESC_STATUS|ICON|COLOR|RANK|CODE_STATUS]
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */

    FUNCTION get_status_software
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_id_market IN market.id_market%TYPE
    ) RETURN t_coll_wf_status_info_def
        PIPELINED;

    /**
    * Checks if transition is available (id_workflow, i_id_status_begin, i_id_workflow_action) and returns transition data
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Begin status identifier
    * @param   i_id_status_end        End status identifier
    * @param   i_id_workflow_action   Action identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition_info      Transition info
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION check_transition
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
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
        o_transition_info     OUT NOCOPY t_rec_wf_trans_config,
        o_error               OUT NOCOPY t_error_out
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
        i_lang                IN LANGUAGE.id_language%TYPE,
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

    /**
    * Checks if this status is available for this workflow
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    *
    * @RETURN  {*} Y- status available for this workflow {*} N- otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-05-2013
    */
    FUNCTION check_wf_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN wf_status_config.id_workflow%TYPE,
        i_id_status   IN wf_status_config.id_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if this status is final
    *
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    *
    * @RETURN  {*} Y- status is final for this workflow {*} N- otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-06-2013
    */
    FUNCTION check_status_final
    (
        i_id_workflow IN wf_status_config.id_workflow%TYPE,
        i_id_status   IN wf_status_config.id_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * Enables or Disables workflow configuration
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_flg_available        {*} Y - enable workflow {*} N - disable workflow
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */

    FUNCTION set_workflow
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_flg_available IN VARCHAR2,
        o_error         OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Enables or Disables status workflow configuration
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier   
    * @param   i_flg_available        {*} Y - enable workflow {*} N - disable workflow
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */

    FUNCTION set_status_workflow
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_id_status     IN wf_status_workflow.id_status%TYPE,
        i_flg_available IN VARCHAR2,
        o_error         OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Getting transitions for one action/workflow/status_begin
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   I_ACTION          Action identifier. Mandatory.   
    * @param   I_ID_WORKFLOW     Workflow identifier. Optional.     
    * @param   I_ID_STATUS_BEGIN Begin status identifier. Optional.
    * @param   O_TRANS_DATA      Transitions data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   25-02-2014
    */
    FUNCTION get_wf_action_trans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action          IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_action.id_workflow%TYPE,
        i_id_status_begin IN wf_action.id_status_begin%TYPE
    ) RETURN t_coll_wf_action;
    
    /********************************************************************************************
    * Gets actions available for a given status of a given workflow
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_ID_WORKFLOW      Workflow identifier
    * @param   I_ID_STATUS_BEGIN  Begin action state 
    * @param   I_PARAMS           Params table_varchar for validateing transitions     
    * @param   O_ACTIONS          actions
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Nelson Canastro
    * @version 2.6
    * @since   14-01-2011
    ********************************************************************************************/
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
        o_actions              OUT t_coll_action
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
    * Gets the printed and faxed prescriptions, each prescription has its own medications  
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
    /*FUNCTION get_actions_subject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        i_params          IN table_varchar,
        i_validate_trans  IN VARCHAR2,
        i_show_disable    IN VARCHAR2,
        o_actions         OUT pk_types.cursor_type
    ) RETURN BOOLEAN;*/

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
    /********************************************************************
    ********************************************************************/

    FUNCTION is_action_valid
    (
        i_id_workflow  IN wf_workflow.id_workflow%TYPE,
        i_id_wf_status IN wf_status.id_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_wf_stat_col_by_action
    (
        i_id_action IN wf_action.id_action%TYPE,
        i_workflows IN table_number
    ) RETURN table_varchar2;

    /********************************************************************************************
    * Same as get_wf_stat_col_by_action but also takes into account the status of the WF_TRANSITION
    *
    * @param  i_id_action         Action to validate
    * @param  i_workflows         Workflows to validate
    *
    *
    * @author Pedro Teixeira
    * @since  03/05/2011
    *
    ********************************************************************************************/
    FUNCTION get_wf_stat_act_by_action
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN wf_action.id_action%TYPE,
        i_workflows IN table_number
    ) RETURN table_varchar2;
    /********************************************************************
    ********************************************************************/

    PROCEDURE get_all_actions_by_wf_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    );

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

END pk_workflow;
/
