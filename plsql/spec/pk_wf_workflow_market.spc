/*-- Last Change Revision: $Rev: 640250 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2010-09-17 23:06:09 +0100 (sex, 17 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_wf_workflow_market IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 14-09-2010 18:33:39
    -- Purpose : API for table wf_workflow_market

    -- Public type declarations
    --  type <TypeName> is <Datatype>;

    -- Public constant declarations
    -- <ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    -- <VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * Insert a record into table wf_workflow_market
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_MARKET    Market id
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE ins_rec
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_id_market   IN wf_workflow_market.id_market%TYPE,
        i_id_workflow IN wf_workflow_market.id_workflow%TYPE,
        o_error       OUT t_error_out
    );

    /**
    * Update a record into table wf_workflow_market
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_MARKET    Market id
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE upd_rec
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_id_market   IN wf_workflow_market.id_market%TYPE,
        i_id_workflow IN wf_workflow_market.id_workflow%TYPE,
        o_error       OUT t_error_out
    );

    /**
    * Insert a record into table wf_workflow_market, if record already exists updates it
    *
    * @param  I_LANG           Professional language
    * @param  I_ID_MARKET    Market id
    * @param  I_ID_WORKFLOW    Workflow Id
    * @param   o_error        Error information
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    PROCEDURE merge_rec
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_id_market   IN wf_workflow_market.id_market%TYPE,
        i_id_workflow IN wf_workflow_market.id_workflow%TYPE,
        o_error       OUT t_error_out
    );

    /**
    * Get a record form table wf_workflow_market given the primary key)
    *
    * @param  I_ID_MARKET    Market id
    * @param  I_ID_WORKFLOW    Workflow Id
    *
    * @RETURN  The wf_workflow_market record
    *
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   14-SET-2010
    */

    FUNCTION get_rec
    (
        i_id_market   IN wf_workflow_market.id_market%TYPE,
        i_id_workflow IN wf_workflow_market.id_workflow%TYPE
    ) RETURN wf_workflow_market%ROWTYPE;
END pk_wf_workflow_market;
/