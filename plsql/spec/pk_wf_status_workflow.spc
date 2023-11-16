/*-- Last Change Revision: $Rev: 640250 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:06:09 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_status_workflow IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:30:50
    -- Purpose : API for table wf_status_workflow

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_status_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_ID_STATUS    Status Id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_FLG_BEGIN    Y it's the starting status, N otherwise.
    * @param  I_FLG_FINAL    Y if it's a final status, N otherwise
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_id_status     IN wf_status_workflow.id_status%TYPE,
        i_description   IN wf_status_workflow.description%TYPE,
        i_flg_begin     IN wf_status_workflow.flg_begin%TYPE,
        i_flg_final     IN wf_status_workflow.flg_final%TYPE,
        i_flg_available IN wf_status_workflow.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Update a record into table wf_status_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_ID_STATUS    Status Id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_FLG_BEGIN    Y it's the starting status, N otherwise.
    * @param  I_FLG_FINAL    Y if it's a final status, N otherwise
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_id_status     IN wf_status_workflow.id_status%TYPE,
        i_description   IN wf_status_workflow.description%TYPE,
        i_flg_begin     IN wf_status_workflow.flg_begin%TYPE,
        i_flg_final     IN wf_status_workflow.flg_final%TYPE,
        i_flg_available IN wf_status_workflow.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Insert a record into table wf_status_workflow, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_ID_STATUS    Status Id
    * @param  I_DESCRIPTION    Full description of status meaning. For internal use
    * @param  I_FLG_BEGIN    Y it's the starting status, N otherwise.
    * @param  I_FLG_FINAL    Y if it's a final status, N otherwise
    * @param  I_FLG_AVAILABLE    Y if available, N otherwise
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_status_workflow.id_workflow%TYPE,
        i_id_status     IN wf_status_workflow.id_status%TYPE,
        i_description   IN wf_status_workflow.description%TYPE,
        i_flg_begin     IN wf_status_workflow.flg_begin%TYPE,
        i_flg_final     IN wf_status_workflow.flg_final%TYPE,
        i_flg_available IN wf_status_workflow.flg_available%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Get a record form table wf_status_workflow given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_ID_STATUS    Status Id
    *
    * @RETURN  The wf_status_workflow record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_workflow IN wf_status_workflow.id_workflow%TYPE,
        i_id_status   IN wf_status_workflow.id_status%TYPE
    ) RETURN wf_status_workflow%ROWTYPE;
END pk_wf_status_workflow;
/