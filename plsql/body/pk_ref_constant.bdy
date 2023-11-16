/*-- Last Change Revision: $Rev: 2027571 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_constant AS
    /**
    * Initializes ibts to be used in mapping actions (internal name / id)
    * 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-10-2010
    */
    PROCEDURE init_actions IS
    
        CURSOR c_wf_actions IS
            SELECT a.internal_name, a.id_workflow_action
              FROM wf_workflow_action a;
        l_error VARCHAR2(1000 CHAR);
    BEGIN
        -- initializing actions ibts
        FOR i IN c_wf_actions
        LOOP
            l_error := 'id_workflow_action ' || i.id_workflow_action;
            g_tab_action_name(i.id_workflow_action) := i.internal_name;
            g_tab_action_id(i.internal_name) := i.id_workflow_action;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(l_error || ' / ' || SQLERRM);
    END init_actions;

    /**
    * Maps action internal name into id
    *
    * @param   i_action        Action internal name to be mapped
    *
    * @RETURN  Action identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-10-2010   
    */
    FUNCTION get_action_id(i_action IN wf_workflow_action.internal_name%TYPE)
        RETURN wf_workflow_action.id_workflow_action%TYPE IS
    BEGIN
        RETURN g_tab_action_id(i_action);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_action_id;

    /**
    * Maps action id into internal name
    *
    * @param   i_status        Action id to be mapped
    *
    * @RETURN  Action name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-10-2010   
    */
    FUNCTION get_action_name(i_action IN wf_workflow_action.id_workflow_action%TYPE)
        RETURN wf_workflow_action.internal_name%TYPE IS
    BEGIN
        RETURN g_tab_action_name(i_action);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_action_name;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    -- initializing ibts
    init_actions;

END pk_ref_constant;
/
