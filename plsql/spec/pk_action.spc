/*-- Last Change Revision: $Rev: 2045952 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-09-22 16:32:41 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_action IS

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_flg_default CONSTANT VARCHAR2(1) := 'D';

    TYPE p_action_rec IS RECORD(
        id_action     action.id_action%TYPE,
        id_parent     action.id_parent%TYPE,
        LEVEL         NUMBER,
        from_state    action.from_state%TYPE,
        to_state      action.to_state%TYPE,
        desc_action   pk_translation.t_desc_translation,
        icon          action.icon%TYPE,
        flg_default   action.flg_default%TYPE,
        flg_status    action.flg_status%TYPE,
        internal_name action.internal_name%TYPE);

    TYPE p_action_cur IS REF CURSOR RETURN p_action_rec;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2008/04/03
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT p_action_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a list of subjects and a list of states.
     * Makes the intersection of available states.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Array of Subjects
     * @param i_from_state             Array of States
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Eduardo Lourenco
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State     
     * 
     * @param i_class_origin           i_class_origin 
     * @param i_class_origin_context   i_class_origin_context      
     * @return                         Table with actions info
     *
     * @author                          Pedro Quinteiro
     * @version                         2.6.1
     * @since                           25-Fev-2011
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN NUMBER,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets actions by workflow and subject  
    *
    * @param  i_lang            The language ID
    * @param  i_prof            The professional array
    * @param  i_id_workflow     Workflow ID
    * @param  i_subject         Action Subject
    * @param  o_actions         Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN action.id_workflow%TYPE,
        i_subject     IN action.subject%TYPE,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions to be executed when a specific action is selected.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_action                 Selected action
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2008/04/28
    **********************************************************************************************/
    FUNCTION get_actions_to_execute
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_action  IN action.id_action%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions to be executed when a specific action is selected, specified by a profile_template.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_action                 Selected action
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Rita Lopes
     * @version                         0.1
     * @since                           2008/05/29
    **********************************************************************************************/
    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a specified subject and state, but taking into consideration
     * the exceptions.
     * The defined exceptions indicates if an action is A-active or I-inactive, but do 
     * not remove the action from the returned list. 
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2009/12/11
    **********************************************************************************************/
    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a list of subjects and a list of states,
     * making the intersection of available states, but taking into consideration
     * the exceptions.
     * The defined exceptions indicates if an action is A-active or I-inactive, but do 
     * not remove the action from the returned list.  
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Array of Subjects
     * @param i_from_state             Array of States
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2009/12/11
    **********************************************************************************************/
    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Get the value of flg_status (A/I) for a given action parametrized as exception.
    * This allows to have exceptions for the existing action's behavior, where the exceptions
    * can be parameterized by profissional's category, profile template or id (exclusively).
    * 
    * @param       i_lang            preferred language id for this professional 
    * @param       i_prof            professional id structure 
    * @param       i_action          action id                                                  
    * @return                        values A, I or NULL, if no exceptions has been parametrized
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/12/11    
    ********************************************************************************************/
    FUNCTION get_actions_exception
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.id_action%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_cross_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cross_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_task_type  IN task_type.id_task_type%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_id_action IN action.id_action%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get action status.
    *
    * @param i_subject      action subject
    * @param i_from_state   origin status flag
    * @param i_to_state     destination status flag
    *
    * @return               action status: 'A'ctive, 'I'nactive.
    *
    * @author               Sérgio Santos
    * @version               2.6.2
    * @since                2011/04/20
    */
    FUNCTION get_action_flg_status
    (
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_to_state   IN action.to_state%TYPE
    ) RETURN action.flg_status%TYPE;

    /********************************************************************************************
     * Get list of action information for a specified set of id_action's.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_action              id action
     *
     * @return                         The Icon Name
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

    FUNCTION get_action_rank
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.rank%TYPE
    ) RETURN action.rank%TYPE;

    /********************************************************************************************
     * Get list of actions for a specified subject and state, but taking into consideration
     * the exceptions and group_id.
     * The defined exceptions indicates if an action is A-active or I-inactive, but do 
     * not remove the action from the returned list. 
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Nuno Neves
     * @version                         2.6.2
     * @since                           2012/09/27
    **********************************************************************************************/
    FUNCTION get_actions_by_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Function that checks if from_state -> to_state workflow is possible     *
    * Returns true if possible otherwise returns false.                       *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_subject                Subject name                            *
    * @param i_from_state             origin state                            *
    * @param i_to_state               destination state                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/23                              *
    **************************************************************************/
    FUNCTION check_state_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_to_state   IN action.to_state%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State     
     *
     * @return                         Table with actions info
     *
     * @author                          Sofia Mendes
     * @version                         2.6.0.5
     * @since                           27-Jan-2011
    **********************************************************************************************/
    FUNCTION tf_get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action;

    /********************************************************************************************
     * Get list of actions for a specified set of id_workflow's.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_workflows              A table_number collection of id_workflows
     *
     * @return                         Table with actions info
     *
     * @author                         Nelson Canastro
     * @version                        2.6.1
     * @since                          10/03/2011
    **********************************************************************************************/
    FUNCTION tf_get_actions_by_wf_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action;

    /********************************************************************************************
     * Get list of action information for a specified set of id_action's.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_actions                A table_number collection with id_actions
     *
     * @return                         Table with actions info
     *
     * @author                         Nelson Canastro
     * @version                        2.6.1
     * @since                          10/03/2011
    **********************************************************************************************/
    FUNCTION tf_get_actions_by_id_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_actions              IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action;

    /**
    * Get list of actions to be executed when a specific action is selected, specified by a profile_template.
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_subject          Subject name
    * @param   i_from_state       Origin state
    *
    * @return  t_coll_action      Table with actions information
    *
    * @author                     Ana Monteiro
    * @since                      2015-01-16
    */
    FUNCTION tf_get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action;

    /**
    * Get list of actions to be executed when a specific action is selected, specified by a profile_template
    * (with flash method or screen transition).
    *
    * @param   i_lang                    Professional preferred language
    * @param   i_prof                    Professional identification and its context (institution and software)
    * @param   i_subject                 Subject name
    * @param   i_from_state              Origin state
    * @param   i_class_origin
    * @param   i_class_origin_context
    *
    * @return  t_coll_action      Table with actions information
    *
    * @author                     rui.mendonca
    * @since                      2016-05-06
    */
    FUNCTION tf_get_actions_permissions_wm
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_subject              IN action.subject%TYPE,
        i_from_state           IN action.from_state%TYPE,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action;

    /********************************************************************************************
     * Get list of actions for a specified subject and state with exceptions.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_from_state             State     
     *
     * @return                         Table with actions info
     *
     * @author                         Elisabete Bugalho
     * @version                        2.6.5.2
     * @since                          02-Set-2016
    **********************************************************************************************/
    FUNCTION tf_get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action;

    FUNCTION tf_get_actions_base
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar
    ) RETURN t_coll_action;

END pk_action;
/
