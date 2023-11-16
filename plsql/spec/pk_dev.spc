/*-- Last Change Revision: $Rev: 2028596 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_dev IS

    -- Author  : FABIO.OLIVEIRA
    -- Created : 17-04-2009 10:53:21
    -- Purpose : Package used for development purposes only

    /**
    * Returns ID_PATIENT and ID_EPISODE column names from a table
    *
    * @param i_epis       Episode id
    *
    * @return     Patient id
    *
    * @author     Rui Spratley
    * @version    2.6.2.1
    * @since      2012/03/26
    * @notes
    */
    FUNCTION get_pat_by_epis(i_episode IN NUMBER) RETURN NUMBER;

    /**
    * Returns ID_PATIENT and ID_EPISODE column names from a table
    *
    * @param i_owner      Owner
    * @param i_table      Table name
    * @param o_epis       Episode column name
    * @param o_pat        Patient column name
    *
    * @author     Rui Spratley
    * @version    2.6.2.1
    * @since      2012/03/26
    * @notes
    */
    PROCEDURE get_epis_pat_by_tab
    (
        i_owner IN VARCHAR2,
        i_table IN VARCHAR2,
        o_epis  OUT VARCHAR2,
        o_pat   OUT VARCHAR2
    );

    PROCEDURE get_dependencies
    (
        i_owner    IN VARCHAR2,
        i_package  IN VARCHAR2,
        i_function IN VARCHAR2,
        i_iter     IN INTEGER DEFAULT NULL
    );

    PROCEDURE get_all_dependencies
    (
        i_owner    IN VARCHAR2,
        i_package  IN VARCHAR2,
        i_function IN VARCHAR2,
        i_levels   IN PLS_INTEGER DEFAULT 1
    );

    FUNCTION create_audit_trigger
    (
        i_table   IN VARCHAR2,
        i_owner   IN VARCHAR2,
        o_trigger OUT VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Returns a DDL script to create an audit trigger for a given table in the format B_IU_<object_ID>_AUDIT
    *
    * @param i_obj_id      Object ID
    * @param i_tbl_name    Table on which to create the trigger
    * @param i_own_name    Table owner
    *
    * @return     Trigger DDL
    * @author     Fábio Oliveira
    * @version    2.5.0.6
    * @since      2009/09/14
    * @notes
    */
    FUNCTION get_audit_trigger_body
    (
        i_obj_id   IN NUMBER,
        i_tbl_name IN VARCHAR2,
        i_own_name IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Returns a DDL script to create a trigger to audit QC DML for a given table in the format B_IU_<object_ID>_QC
    *
    * @param i_tbl_name    Table on which to create the trigger
    * @param i_owner       Table owner
    *
    * @return     Trigger DDL
    * @author     Fábio Oliveira
    * @version    2.6.0.1
    * @since      09-Mar-2010
    */
    FUNCTION get_qc_trigger_body
    (
        i_tbl_name IN VARCHAR2,
        i_owner    IN VARCHAR2 DEFAULT USER
    ) RETURN VARCHAR2;

    /**
    * Handles an event of DML runt (this is intended to run on QC environment only)
    *
    * @param i_tbl_name    Table on which to create the trigger
    * @param i_dml_type    DML type (INSERT|UPDATE|DELETE)
    *
    * @author     Fábio Oliveira
    * @version    2.6.0.1
    * @since      09-Mar-2010
    */
    PROCEDURE log_qc_dml
    (
        i_tbl_name IN VARCHAR2,
        i_dml_type IN VARCHAR2
    );

    PROCEDURE initialize_params
    (
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Verifies if a table has audit columns
    *
    * @param i_table       Table name
    * @param i_owner       Table owner
    *
    * @return     Boolean
    *
    * @author     Rui Spratley
    * @version    2.6.2.1
    * @since      2012/06/22
    * @notes
    */
    FUNCTION check_audit_columns
    (
        i_table IN VARCHAR2,
        i_owner IN VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Create audit columns and audit triggers in a table
    *
    * @param i_table       Table name
    * @param i_owner       Table owner
    *
    * @return     Boolean
    *
    * @author     Rui Spratley
    * @version    2.6.2.1
    * @since      2012/06/22
    * @notes
    */
    PROCEDURE create_audit_columns
    (
        i_table IN VARCHAR2,
        i_owner IN VARCHAR2
    );

    PROCEDURE get_session_vars
    (
        o_obj_name       OUT VARCHAR2,
        o_procedure_name OUT VARCHAR2
    );

    FUNCTION init_macro_description
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_name IN VARCHAR2
    ) RETURN VARCHAR2;

END pk_dev;
/
