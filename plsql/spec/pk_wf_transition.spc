/*-- Last Change Revision: $Rev: 782912 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2010-11-25 09:43:21 +0000 (qui, 25 nov 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_transition IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:36:34
    -- Purpose : API for table wf_transition

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_transition
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    );

    /**
    * Update a record into table wf_transition
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    );

    /**
    * Insert a record into table wf_transition, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    * @param  I_CODE_TRANSITION    Transition (or action) name
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE,
        --i_code_transition IN wf_transition.code_transition%TYPE,
        i_flg_available   IN wf_transition.flg_available%TYPE,
        o_error           OUT t_error_out
    );

    /**
    * Get a record form table wf_transition given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow that uses this transition
    * @param  I_ID_STATUS_BEGIN    Starting status for transition
    * @param  I_ID_STATUS_END    Finish status for transition
    *
    * @RETURN  The wf_transition record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow     IN wf_transition.id_workflow%TYPE,
        i_id_status_begin IN wf_transition.id_status_begin%TYPE,
        i_id_status_end   IN wf_transition.id_status_end%TYPE
    ) RETURN wf_transition%ROWTYPE;
END pk_wf_transition;
/