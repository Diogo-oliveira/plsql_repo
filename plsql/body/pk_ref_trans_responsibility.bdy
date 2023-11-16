/*-- Last Change Revision: $Rev: 2027598 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_trans_responsibility IS

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

    g_error VARCHAR2(1000 CHAR);

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
    * Get hand off record
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_id_trans_resp Hand off identifier 
    * @param   o_rec           Hand off record
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-05-2013
    */
    FUNCTION get_trans_resp_row
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trans_resp IN ref_trans_responsibility.id_trans_resp%TYPE,
        o_row           OUT ref_trans_responsibility%ROWTYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tr IS
            SELECT *
              FROM ref_trans_responsibility
             WHERE id_trans_resp = i_id_trans_resp;
    BEGIN
        g_error := 'Init get_trans_resp_row / I_PROF=' || pk_utils.to_string(i_prof) || ' i_id_trans_resp=' ||
                   i_id_trans_resp;
        OPEN c_tr;
        FETCH c_tr
            INTO o_row;
        CLOSE c_tr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRANS_RESP_ROW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_trans_resp_row;

    /**
    * Get active hand off record
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional id, institution and software
    * @param   i_id_external_request          Referral identifier 
    * @param   o_rec                          Hand off record
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION get_active_trans_resp_row
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN ref_trans_responsibility.id_external_request%TYPE,
        o_row                 OUT ref_trans_responsibility%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tr IS
            SELECT *
              FROM ref_trans_responsibility r
             WHERE r.id_external_request = i_id_external_request
               AND r.flg_active = pk_ref_constant.g_yes;
    BEGIN
        g_error := 'Init get_active_trans_resp_row / I_PROF=' || pk_utils.to_string(i_prof) ||
                   ' i_id_external_request=' || i_id_external_request;
        OPEN c_tr;
        FETCH c_tr
            INTO o_row;
        CLOSE c_tr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIVE_TRANS_RESP_ROW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_active_trans_resp_row;

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
        id_trans_resp_in        IN ref_trans_responsibility.id_trans_resp%TYPE,
        id_status_in            IN ref_trans_responsibility.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_responsibility.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_responsibility.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_responsibility.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_responsibility.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        id_professional_in      IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        dt_created_in           IN ref_trans_responsibility.dt_created%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        id_inst_orig_tr_in      IN ref_trans_responsibility.id_inst_orig_tr%TYPE DEFAULT NULL,
        id_inst_dest_tr_in      IN ref_trans_responsibility.id_inst_dest_tr%TYPE DEFAULT NULL,
        id_workflow_action_in   IN ref_trans_resp_hist.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    ) IS
        l_dt_created ref_trans_responsibility.dt_created%TYPE;
        l_flg_active ref_trans_responsibility.flg_active%TYPE;
    BEGIN
    
        l_dt_created := nvl(dt_created_in, current_timestamp);
        l_flg_active := nvl(flg_active_in, pk_ref_constant.g_yes);
    
        INSERT INTO ref_trans_responsibility
            (id_trans_resp,
             id_status,
             id_workflow,
             id_external_request,
             id_prof_ref_owner,
             id_prof_transf_owner,
             id_prof_dest,
             dt_created,
             dt_update,
             id_reason_code,
             reason_code_text,
             flg_active,
             notes,
             id_professional,
             id_institution,
             id_inst_orig_tr,
             id_inst_dest_tr)
        VALUES
            (id_trans_resp_in,
             id_status_in,
             id_workflow_in,
             id_external_request_in,
             id_prof_ref_owner_in,
             id_prof_transf_owner_in,
             id_prof_dest_in,
             l_dt_created,
             l_dt_created,
             id_reason_code_in,
             reason_code_text_in,
             l_flg_active,
             notes_in,
             id_professional_in,
             id_institution_in,
             id_inst_orig_tr_in,
             id_inst_dest_tr_in);
    
        pk_ref_trans_resp_hist.ins(id_trans_resp_hist_in   => pk_ref_trans_resp_hist.next_key,
                                   id_trans_resp_in        => id_trans_resp_in,
                                   id_status_in            => id_status_in,
                                   id_workflow_in          => id_workflow_in,
                                   id_external_request_in  => id_external_request_in,
                                   id_prof_ref_owner_in    => id_prof_ref_owner_in,
                                   id_prof_transf_owner_in => id_prof_transf_owner_in,
                                   id_prof_dest_in         => id_prof_dest_in,
                                   id_professional_in      => id_professional_in,
                                   id_institution_in       => id_institution_in,
                                   dt_created_in           => l_dt_created,
                                   id_reason_code_in       => id_reason_code_in,
                                   reason_code_text_in     => reason_code_text_in,
                                   flg_active_in           => l_flg_active,
                                   notes_in                => notes_in,
                                   id_inst_orig_tr_in      => id_inst_orig_tr_in,
                                   id_inst_dest_tr_in      => id_inst_dest_tr_in,
                                   id_workflow_action_in   => id_workflow_action_in);
    
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
                                                        value3_in     => 'REF_TRANS_RESPONSIBILITY');
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
                                                    value3_in     => 'REF_TRANS_RESPONSIBILITY');
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
                                                       value3_in           => 'REF_TRANS_RESPONSIBILITY');
                    IF l_name = 'RTR_PERT_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_EXTERNAL_REQUEST',
                                                        value_in           => id_external_request_in);
                    END IF;
                    IF l_name = 'RTR_PL_DEST_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_PROF_DEST',
                                                        value_in           => id_prof_dest_in);
                    END IF;
                    IF l_name = 'RTR_PL_RO_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_PROF_REF_OWNER',
                                                        value_in           => id_prof_ref_owner_in);
                    END IF;
                    IF l_name = 'RTR_PL_TO_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_PROF_TRANSF_OWNER',
                                                        value_in           => id_prof_transf_owner_in);
                    END IF;
                    IF l_name = 'RTR_PRE_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_REASON_CODE',
                                                        value_in           => id_reason_code_in);
                    END IF;
                    IF l_name = 'RTR_WSW_FK'
                    THEN
                        -- Add a context value for each column
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_WORKFLOW',
                                                        value_in           => id_workflow_in);
                        pk_alert_exceptions.add_context(err_instance_id_in => l_id,
                                                        name_in            => 'ID_STATUS',
                                                        value_in           => id_status_in);
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
    PROCEDURE upd
    (
        id_trans_resp_in        IN ref_trans_responsibility.id_trans_resp%TYPE,
        id_status_in            IN ref_trans_responsibility.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_responsibility.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_responsibility.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_responsibility.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_responsibility.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        id_prof_dest_nin        IN BOOLEAN := TRUE,
        dt_update_in            IN ref_trans_responsibility.dt_update%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        id_professional_in      IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        id_workflow_action_in   IN wf_workflow_action.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    ) IS
        l_ref_trans_resp_hist ref_trans_resp_hist%ROWTYPE;
        l_id_prof_dest_n      NUMBER(1);
        l_notes_n             NUMBER(1);
    BEGIN
        l_id_prof_dest_n := sys.diutil.bool_to_int(id_prof_dest_nin);
        l_notes_n        := sys.diutil.bool_to_int(notes_nin);
    
        UPDATE ref_trans_responsibility
           SET id_status           = nvl(id_status_in, id_status),
               id_workflow         = nvl(id_workflow_in, id_workflow),
               id_external_request = nvl(id_external_request_in, id_external_request),
               id_prof_ref_owner   = nvl(id_prof_ref_owner_in, id_prof_ref_owner),
               --id_prof_dest     = nvl(id_prof_dest_in, id_prof_dest),
               id_prof_dest     = decode(l_id_prof_dest_n, 0, id_prof_dest_in, nvl(id_prof_dest_in, id_prof_dest)),
               dt_update        = nvl(dt_update_in, current_timestamp),
               id_reason_code   = nvl(id_reason_code_in, id_reason_code),
               reason_code_text = nvl(reason_code_text_in, reason_code_text),
               flg_active       = nvl(flg_active_in, flg_active),
               --notes            = nvl(notes_in, notes),
               notes           = decode(l_notes_n, 0, notes_in, nvl(notes_in, notes)),
               id_professional = id_professional_in,
               id_institution  = id_institution_in
         WHERE id_trans_resp = id_trans_resp_in
        RETURNING id_trans_resp, id_status, id_workflow, id_external_request, dt_update, flg_active, id_inst_orig_tr, id_inst_dest_tr INTO l_ref_trans_resp_hist.id_trans_resp, l_ref_trans_resp_hist.id_status, l_ref_trans_resp_hist.id_workflow, l_ref_trans_resp_hist.id_external_request, l_ref_trans_resp_hist.dt_created, l_ref_trans_resp_hist.flg_active, l_ref_trans_resp_hist.id_inst_orig_tr, l_ref_trans_resp_hist.id_inst_dest_tr;
    
        IF SQL%FOUND IS NOT NULL
        THEN
            l_ref_trans_resp_hist.id_trans_resp_hist   := pk_ref_trans_resp_hist.next_key;
            l_ref_trans_resp_hist.id_prof_ref_owner    := id_prof_ref_owner_in;
            l_ref_trans_resp_hist.id_prof_transf_owner := id_prof_transf_owner_in;
            l_ref_trans_resp_hist.id_prof_dest         := id_prof_dest_in;
            l_ref_trans_resp_hist.id_reason_code       := id_reason_code_in;
            l_ref_trans_resp_hist.reason_code_text     := reason_code_text_in;
            l_ref_trans_resp_hist.notes                := notes_in;
            l_ref_trans_resp_hist.id_professional      := id_professional_in;
            l_ref_trans_resp_hist.id_institution       := id_institution_in;
            l_ref_trans_resp_hist.id_workflow_action   := id_workflow_action_in;
        
            pk_ref_trans_resp_hist.ins(rec_in => l_ref_trans_resp_hist);
        
        END IF;
    END upd;

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
    PROCEDURE upd_by_id_external_request
    (
        id_external_request_in IN ref_trans_responsibility.id_external_request%TYPE,
        dt_update_in           IN ref_trans_responsibility.dt_update%TYPE DEFAULT NULL,
        flg_active_in          IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        id_professional_in     IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in      IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        id_workflow_action_in  IN wf_workflow_action.id_workflow_action%TYPE DEFAULT NULL
    ) IS
        l_ref_trans_resp_hist ref_trans_resp_hist%ROWTYPE;
    BEGIN
        UPDATE ref_trans_responsibility
           SET dt_update       = nvl(dt_update_in, current_timestamp),
               flg_active      = nvl(flg_active_in, flg_active),
               id_professional = nvl(id_professional_in, id_professional),
               id_institution  = nvl(id_institution_in, id_institution)
         WHERE id_external_request = id_external_request_in
           AND flg_active = pk_ref_constant.g_yes
        RETURNING id_trans_resp, id_status, id_workflow, id_external_request, dt_update, flg_active, id_inst_orig_tr, id_inst_dest_tr, id_prof_ref_owner, id_prof_transf_owner, id_prof_dest, id_reason_code, reason_code_text, notes, id_professional, id_institution INTO l_ref_trans_resp_hist.id_trans_resp, l_ref_trans_resp_hist.id_status, l_ref_trans_resp_hist.id_workflow, l_ref_trans_resp_hist.id_external_request, l_ref_trans_resp_hist.dt_created, l_ref_trans_resp_hist.flg_active, l_ref_trans_resp_hist.id_inst_orig_tr, l_ref_trans_resp_hist.id_inst_dest_tr, l_ref_trans_resp_hist.id_prof_ref_owner, l_ref_trans_resp_hist.id_prof_transf_owner, l_ref_trans_resp_hist.id_prof_dest, l_ref_trans_resp_hist.id_reason_code, l_ref_trans_resp_hist.reason_code_text, l_ref_trans_resp_hist.notes, l_ref_trans_resp_hist.id_professional, l_ref_trans_resp_hist.id_institution;
    
        IF SQL%FOUND
        THEN
        
            l_ref_trans_resp_hist.id_trans_resp_hist := pk_ref_trans_resp_hist.next_key;
            l_ref_trans_resp_hist.id_workflow_action := id_workflow_action_in;
        
            pk_ref_trans_resp_hist.ins(rec_in => l_ref_trans_resp_hist);
        
        END IF;
    
    END upd_by_id_external_request;

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN ref_trans_responsibility.id_trans_resp%TYPE IS
        retval ref_trans_responsibility.id_trans_resp%TYPE;
    BEGIN
        IF sequence_in IS NULL
        THEN
            SELECT seq_ref_trans_responsibility.nextval
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
                                            value1_in     => nvl(sequence_in, 'seq_P1_EXTERNAL_REQUEST'));
    END next_key;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_trans_responsibility;
/
