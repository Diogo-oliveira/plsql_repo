/*-- Last Change Revision: $Rev: 2027600 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_trans_resp_hist IS

    e_check_constraint_failure EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_constraint_failure, -2290);

    e_no_parent_key EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_parent_key, -2291);

    e_child_record_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_child_record_found, -2292);

    e_null_column_value EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_null_column_value, -1400);

    -- Defined for backward compatibilty.
    e_integ_constraint_failure EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_integ_constraint_failure, -2291);
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    --g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    -- Private utilities
    PROCEDURE get_constraint_info
    (
        owner_out OUT all_constraints.owner%TYPE,
        name_out  OUT all_constraints.constraint_name%TYPE
    ) IS
        l_errm  VARCHAR2(2000) := dbms_utility.format_error_stack;
        dotloc  PLS_INTEGER;
        leftloc PLS_INTEGER;
    BEGIN
        dotloc    := instr(l_errm, '.');
        leftloc   := instr(l_errm, '(');
        owner_out := substr(l_errm, leftloc + 1, dotloc - leftloc - 1);
        name_out  := substr(l_errm, dotloc + 1, instr(l_errm, ')') - dotloc - 1);
    END get_constraint_info;

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-09-2010
    */
    PROCEDURE ins
    (
        id_trans_resp_hist_in   IN ref_trans_resp_hist.id_trans_resp_hist%TYPE,
        id_trans_resp_in        IN ref_trans_resp_hist.id_trans_resp%TYPE DEFAULT NULL,
        id_status_in            IN ref_trans_resp_hist.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_resp_hist.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_resp_hist.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_resp_hist.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_resp_hist.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_resp_hist.id_prof_dest%TYPE DEFAULT NULL,
        id_professional_in      IN ref_trans_resp_hist.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_resp_hist.id_institution%TYPE DEFAULT NULL,
        dt_created_in           IN ref_trans_resp_hist.dt_created%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_resp_hist.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_resp_hist.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_resp_hist.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_resp_hist.notes%TYPE DEFAULT NULL,
        id_inst_orig_tr_in      IN ref_trans_resp_hist.id_inst_orig_tr%TYPE DEFAULT NULL,
        id_inst_dest_tr_in      IN ref_trans_resp_hist.id_inst_dest_tr%TYPE DEFAULT NULL,
        id_workflow_action_in   IN ref_trans_resp_hist.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    ) IS
    BEGIN
    
        INSERT INTO ref_trans_resp_hist
            (id_trans_resp_hist,
             id_trans_resp,
             id_status,
             id_workflow,
             id_external_request,
             id_prof_ref_owner,
             id_prof_transf_owner,
             id_prof_dest,
             dt_created,
             id_reason_code,
             reason_code_text,
             flg_active,
             notes,
             id_professional,
             id_institution,
             id_inst_orig_tr,
             id_inst_dest_tr)
        VALUES
            (id_trans_resp_hist_in,
             id_trans_resp_in,
             id_status_in,
             id_workflow_in,
             id_external_request_in,
             id_prof_ref_owner_in,
             id_prof_transf_owner_in,
             id_prof_dest_in,
             dt_created_in,
             id_reason_code_in,
             reason_code_text_in,
             flg_active_in,
             notes_in,
             id_professional_in,
             id_institution_in,
             id_inst_orig_tr_in,
             id_inst_dest_tr_in);
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF NOT handle_error_in
            THEN
                RAISE;
            ELSE
                DECLARE
                    l_owner all_constraints.owner%TYPE;
                    l_name  all_constraints.constraint_name%TYPE;
                BEGIN
                    get_constraint_info(l_owner, l_name);
                    IF FALSE
                    THEN
                        NULL; -- Placeholder in case no unique indexes
                    ELSE
                        pk_alert_exceptions.raise_error(error_name_in => 'DUPLICATE-VALUE',
                                                        name1_in      => 'OWNER',
                                                        value1_in     => l_owner,
                                                        name2_in      => 'CONSTRAINT_NAME',
                                                        value2_in     => l_name,
                                                        name3_in      => 'TABLE_NAME',
                                                        value3_in     => 'REF_TRANS_RESP_HIST');
                    END IF;
                END;
            END IF;
        WHEN e_check_constraint_failure THEN
            IF NOT handle_error_in
            THEN
                RAISE;
            ELSE
                DECLARE
                    l_owner all_constraints.owner%TYPE;
                    l_name  all_constraints.constraint_name%TYPE;
                BEGIN
                    get_constraint_info(l_owner, l_name);
                    pk_alert_exceptions.raise_error(error_name_in => 'CHECK-CONSTRAINT-FAILURE',
                                                    name1_in      => 'OWNER',
                                                    value1_in     => l_owner,
                                                    name2_in      => 'CONSTRAINT_NAME',
                                                    value2_in     => l_name,
                                                    name3_in      => 'TABLE_NAME',
                                                    value3_in     => 'REF_TRANS_RESP_HIST');
                END;
            END IF;
        WHEN e_integ_constraint_failure
             OR e_no_parent_key
             OR e_child_record_found THEN
            IF NOT handle_error_in
            THEN
                RAISE;
            ELSE
                DECLARE
                    l_owner    all_constraints.owner%TYPE;
                    l_name     all_constraints.constraint_name%TYPE;
                    l_id       PLS_INTEGER;
                    l_err_name VARCHAR2(32767) DEFAULT 'NO-PARENT-KEY-FOUND';
                BEGIN
                    get_constraint_info(l_owner, l_name);
                    IF SQLCODE = -2292 -- Child record found
                    THEN
                        l_err_name := 'CHILD-RECORD-FOUND';
                    END IF;
                    pk_alert_exceptions.register_error(error_name_in       => l_err_name,
                                                       err_instance_id_out => l_id,
                                                       name1_in            => 'OWNER',
                                                       value1_in           => l_owner,
                                                       name2_in            => 'CONSTRAINT_NAME',
                                                       value2_in           => l_name,
                                                       name3_in            => 'TABLE_NAME',
                                                       value3_in           => 'REF_TRANS_RESP_HIST');
                    IF l_name = 'RTRH_RTR_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_TRANS_RESP',
                                                        value_in           => id_trans_resp_in);
                    END IF;
                    pk_alert_exceptions.raise_error_instance(err_instance_id_in => l_id);
                END;
            END IF;
        WHEN e_null_column_value THEN
            IF NOT handle_error_in
            THEN
                RAISE;
            ELSE
                DECLARE
                    v_errm    VARCHAR2(2000) := dbms_utility.format_error_stack;
                    dot1loc   INTEGER;
                    dot2loc   INTEGER;
                    parenloc  INTEGER;
                    c_owner   all_constraints.owner%TYPE;
                    c_tabname all_tables.table_name%TYPE;
                    c_colname all_tab_columns.column_name%TYPE;
                BEGIN
                    dot1loc   := instr(v_errm, '.', 1, 1);
                    dot2loc   := instr(v_errm, '.', 1, 2);
                    parenloc  := instr(v_errm, '(');
                    c_owner   := substr(v_errm, parenloc + 1, dot1loc - parenloc - 1);
                    c_tabname := substr(v_errm, dot1loc + 1, dot2loc - dot1loc - 1);
                    c_colname := substr(v_errm, dot2loc + 1, instr(v_errm, ')') - dot2loc - 1);
                
                    pk_alert_exceptions.raise_error(error_name_in => 'COLUMN-CANNOT-BE-NULL',
                                                    name1_in      => 'OWNER',
                                                    value1_in     => c_owner,
                                                    name2_in      => 'TABLE_NAME',
                                                    value2_in     => c_tabname,
                                                    name3_in      => 'COLUMN_NAME',
                                                    value3_in     => c_colname);
                END;
            END IF;
    END ins;

    /**
    * Inserts the entire record into table ref_trans_resp_hist
    *
    * @param   rec_in          record data
    * @param   handle_error_in error treatment
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-06-2013
    */
    PROCEDURE ins
    (
        rec_in          IN ref_trans_resp_hist%ROWTYPE,
        handle_error_in IN BOOLEAN := TRUE
    ) IS
    BEGIN
    
        ins(id_trans_resp_hist_in   => rec_in.id_trans_resp_hist,
            id_trans_resp_in        => rec_in.id_trans_resp,
            id_status_in            => rec_in.id_status,
            id_workflow_in          => rec_in.id_workflow,
            id_external_request_in  => rec_in.id_external_request,
            id_prof_ref_owner_in    => rec_in.id_prof_ref_owner,
            id_prof_transf_owner_in => rec_in.id_prof_transf_owner,
            id_prof_dest_in         => rec_in.id_prof_dest,
            id_professional_in      => rec_in.id_professional,
            id_institution_in       => rec_in.id_institution,
            dt_created_in           => rec_in.dt_created,
            id_reason_code_in       => rec_in.id_reason_code,
            reason_code_text_in     => rec_in.reason_code_text,
            flg_active_in           => rec_in.flg_active,
            notes_in                => rec_in.notes,
            id_inst_orig_tr_in      => rec_in.id_inst_orig_tr,
            id_inst_dest_tr_in      => rec_in.id_inst_dest_tr,
            id_workflow_action_in   => rec_in.id_workflow_action,
            handle_error_in         => handle_error_in);
    END ins;

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN ref_trans_resp_hist.id_trans_resp_hist%TYPE
    
     IS
        retval ref_trans_resp_hist.id_trans_resp_hist%TYPE;
    
    BEGIN
        IF sequence_in IS NULL
        THEN
            SELECT seq_ref_trans_resp_hist.nextval
              INTO retval
              FROM dual;
        ELSE
            EXECUTE IMMEDIATE 'SELECT ' || sequence_in || '.NEXTVAL FROM dual'
                INTO retval;
        END IF;
        RETURN retval;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_name_in => 'SEQUENCE-GENERATION-FAILURE',
                                            name1_in      => 'SEQUENCE',
                                            value1_in     => nvl(sequence_in, 'seq_REF_TRANS_RESP_HIST'));
    END next_key;
BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_trans_resp_hist;
/
