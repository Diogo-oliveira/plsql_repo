/*-- Last Change Revision: $Rev: 845620 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2011-01-14 11:29:48 +0000 (sex, 14 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_wf_workflow IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:32:17
    -- Purpose : API for table wf_workflow

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Update a record into table wf_workflow
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Insert a record into table wf_workflow, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_WORKFLOW    Workflow id
    * @param  I_INTERNAL_NAME    Workflow internal name
    * @param  I_DESCRIPTION    Workflow description
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_workflow   IN wf_workflow.id_workflow%TYPE,
        i_internal_name IN wf_workflow.internal_name%TYPE,
        i_description   IN wf_workflow.description%TYPE,
        o_error         OUT t_error_out
    );

    /**
    * Get a record form table wf_workflow given the primary key)
    *
    * @param  I_ID_WORKFLOW    Workflow id
    *
    * @RETURN  The wf_workflow record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec(i_id_workflow IN wf_workflow.id_workflow%TYPE) RETURN wf_workflow%ROWTYPE;
END pk_wf_workflow;
/