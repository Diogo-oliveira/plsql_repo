/*-- Last Change Revision: $Rev: 2028426 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_data_gov_mnt IS

    k_package_name CONSTANT VARCHAR2(0100 CHAR) := 'T_DATA_GOV_MNT';

    k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0001 CHAR) := 'N';

    k_lf CONSTANT VARCHAR2(0010 CHAR) := chr(10);
    k_sp CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    k_pl CONSTANT VARCHAR2(0010 CHAR) := '''';

    k_idx01 CONSTANT VARCHAR2(0050 CHAR) := '001';
    k_idx02 CONSTANT VARCHAR2(0050 CHAR) := '002';
    k_idx03 CONSTANT VARCHAR2(0050 CHAR) := '003';
    k_idx04 CONSTANT VARCHAR2(0050 CHAR) := '004';

    --k_alert_default  CONSTANT VARCHAR2(0050 CHAR) := 'ALERT_DEFAULT';
    k_default_cols   CONSTANT VARCHAR2(0050 CHAR) := 'ID_PATIENT';
    k_silent_mode    CONSTANT VARCHAR2(0050 CHAR) := 'SILENT';
    k_exception_mode CONSTANT VARCHAR2(0050 CHAR) := 'EXCEPTION';
    k_default_mode   CONSTANT VARCHAR2(0050 CHAR) := k_silent_mode;
    k_data_error_msg CONSTANT VARCHAR2(1000 CHAR) := 'Data inconsistency detected';
    k_auto_mode      CONSTANT VARCHAR2(1000 CHAR) := 'AUTO_MODE';
    k_manual_mode    CONSTANT VARCHAR2(1000 CHAR) := 'MANUAL_MODE';

    k_event_update CONSTANT VARCHAR2(0001 CHAR) := 'V';

    -- global variable for debugging output in dev environment
    g_output_enable BOOLEAN := FALSE;

    -- max error number: -20999
    err_bad_rowid EXCEPTION;
    PRAGMA EXCEPTION_INIT(err_bad_rowid, -20010);

    err_too_many_table EXCEPTION;
    PRAGMA EXCEPTION_INIT(err_too_many_table, -20012);

    -- ***************************************************************************
    PROCEDURE set_output_enable IS
    BEGIN
        g_output_enable := TRUE;
    END set_output_enable;

    PROCEDURE set_output_disable IS
    BEGIN
        g_output_enable := FALSE;
    END set_output_disable;

    FUNCTION is_output_enable RETURN BOOLEAN IS
    BEGIN
        RETURN g_output_enable;
    END is_output_enable;

    -- ***************************************************************************
    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    PROCEDURE log_error
    (
        i_text      IN VARCHAR2,
        i_func_name IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => k_package_name, sub_object_name => i_func_name);
    END log_error;

    PROCEDURE log_debug
    (
        i_msg       IN VARCHAR2,
        i_func_name IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_msg, object_name => k_package_name, sub_object_name => i_func_name);
    END log_debug;

    PROCEDURE println(i_msg IN VARCHAR2) IS
        --k_limit CONSTANT NUMBER(24) := 250;
    BEGIN
    
        IF is_output_enable()
        THEN
            dbms_output.put_line(i_msg);
        END IF;
        log_debug(i_msg => i_msg, i_func_name => 'DEBUG');
    END println;

    FUNCTION get_err_str(i_table_name IN VARCHAR2) RETURN VARCHAR2 IS
        l_err_str VARCHAR2(4000);
    BEGIN
    
        l_err_str := k_data_error_msg || ':' || i_table_name;
        l_err_str := l_err_str || SQLERRM || ')';
    
        println(l_err_str);
        RETURN l_err_str;
    
    END get_err_str;

    -- ***************************************************************************
    FUNCTION get_config
    (
        i_config IN VARCHAR2,
        i_prof   IN profissional
    ) RETURN VARCHAR2 IS
        l_id_sys_config VARCHAR2(0100 CHAR);
        l_return        VARCHAR2(4000);
        k_chk_behaviour   CONSTANT VARCHAR2(0050 CHAR) := 'DATA_GOV_CHK_BEHAVIOUR';
        k_cols_2_validate CONSTANT VARCHAR2(0050 CHAR) := 'DATA_GOV_COLS_VALIDATION';
        k_validation_mode CONSTANT VARCHAR2(0050 CHAR) := 'DT_GOV_VALIDATION_MODE';
        k_fks_2_validate  CONSTANT VARCHAR2(0050 CHAR) := 'DATA_GOV_FKS_VALIDATION';
    BEGIN
    
        CASE i_config
            WHEN k_idx04 THEN
                l_id_sys_config := k_fks_2_validate;
            WHEN k_idx03 THEN
                l_id_sys_config := k_validation_mode;
            WHEN k_idx02 THEN
                l_id_sys_config := k_cols_2_validate;
            WHEN k_idx01 THEN
                l_id_sys_config := k_chk_behaviour;
        END CASE;
    
        l_return := pk_sysconfig.get_config(l_id_sys_config, i_prof);
    
        RETURN l_return;
    
    END get_config;

    -- ***************************************************************************
    FUNCTION parse_string(i_string IN VARCHAR2) RETURN table_varchar IS
        l_tbl  table_varchar := table_varchar();
        word   VARCHAR2(0100 CHAR);
        xlen   NUMBER(24) := 0;
        xtart  NUMBER(24) := 1;
        pos    NUMBER(24) := 0;
        cur    NUMBER(24) := 0;
        l_bool BOOLEAN;
    BEGIN
    
        xlen := length(i_string);
        pos  := xtart;
    
        l_bool := TRUE;
        WHILE (l_bool)
        LOOP
        
            IF xlen = 0
            THEN
                EXIT;
            END IF;
            cur := instr(i_string, '|', pos);
        
            word := substr(i_string, pos, cur - pos);
        
            CASE
                WHEN cur > 0 THEN
                    word := substr(i_string, pos, cur - pos);
                WHEN cur = 0 THEN
                    word := substr(i_string, pos);
                ELSE
                    NULL;
            END CASE;
        
            l_tbl.extend;
            l_tbl(l_tbl.count) := word;
        
            pos := cur + 1;
        
            l_bool := NOT ((pos > xlen) OR (cur = 0));
        
        END LOOP;
    
        RETURN l_tbl;
    
    END parse_string;

    -- ***************************************************************************
    FUNCTION get_auto_cols_list
    (
        i_prof       IN profissional,
        i_owner      IN VARCHAR2,
        i_table_name IN VARCHAR2
    ) RETURN table_varchar IS
        l_cols_table  table_varchar := table_varchar();
        l_cols_return table_varchar;
        l_cfg_cols    VARCHAR2(4000);
    BEGIN
    
        l_cfg_cols   := nvl(get_config(k_idx04, i_prof), k_default_cols);
        l_cols_table := parse_string(l_cfg_cols);
    
        SELECT acc.column_name
          BULK COLLECT
          INTO l_cols_return
          FROM all_constraints ac
          JOIN all_cons_columns acc
            ON acc.constraint_name = ac.constraint_name
           AND acc.owner = ac.owner
         WHERE ac.table_name = i_table_name
           AND ac.owner = i_owner
           AND ac.r_constraint_name IN (SELECT tmp.column_value
                                          FROM TABLE(l_cols_table) tmp);
    
        RETURN l_cols_return;
    
    END get_auto_cols_list;

    -- ***************************************************************************
    FUNCTION get_manual_cols_list
    (
        i_owner    IN VARCHAR2,
        i_obj_name IN VARCHAR2
    ) RETURN table_varchar IS
        l_cols_table table_varchar;
    BEGIN
    
        SELECT column_name
          BULK COLLECT
          INTO l_cols_table
          FROM frmw_obj_columns
         WHERE owner = i_owner
           AND obj_name = i_obj_name
           AND flg_data_gov_validation = k_yes;
    
        RETURN l_cols_table;
    
    END get_manual_cols_list;

    -- ***************************************************************************
    FUNCTION get_behaviour(i_prof IN profissional) RETURN VARCHAR2 IS
        l_return VARCHAR2(0100 CHAR);
    BEGIN
    
        l_return := get_config(k_idx01, i_prof);
        l_return := nvl(l_return, k_default_mode);
    
        IF l_return NOT IN (k_silent_mode, k_exception_mode)
        THEN
            l_return := k_default_mode;
        END IF;
    
        RETURN l_return;
    
    END get_behaviour;

    -- ************************************************************************************************************
    FUNCTION build_chk_sql_tbl_eligible
    (
        i_owner      IN VARCHAR2,
        i_table_name IN VARCHAR2,
        i_tbl_cols   IN table_varchar
    ) RETURN VARCHAR2 IS
        l_sql VARCHAR2(4000);
    BEGIN
    
        l_sql := l_sql || 'select count(1) from all_tab_columns' || k_lf;
        l_sql := l_sql || 'where table_name = ' || k_pl || i_table_name || k_pl || k_lf;
        l_sql := l_sql || 'and owner = ' || k_pl || i_owner || k_pl || k_lf;
        l_sql := l_sql || 'and column_name in(' || k_pl || i_tbl_cols(1) || k_pl;
    
        <<lup_thru_valid_cols>>
        FOR i IN 2 .. i_tbl_cols.count
        LOOP
            l_sql := l_sql || ', ' || k_pl || i_tbl_cols(i) || k_pl;
        END LOOP lup_thru_valid_cols;
    
        l_sql := l_sql || k_sp || ')';
    
        println(l_sql);
        RETURN l_sql;
    
    END build_chk_sql_tbl_eligible;

    -- ***************************************************************************
    /*
    if true, table must be checked for consistency
    */
    FUNCTION chck_if_table_eligible
    (
        i_owner      IN VARCHAR2,
        i_table_name IN VARCHAR2,
        i_tbl_cols   IN table_varchar
    ) RETURN BOOLEAN IS
        l_sql   VARCHAR2(0500 CHAR);
        l_count NUMBER(24);
        l_bool  BOOLEAN := FALSE;
    BEGIN
    
        IF i_tbl_cols.count > 0
        THEN
        
            l_sql := build_chk_sql_tbl_eligible(i_owner, i_table_name, i_tbl_cols);
        
            EXECUTE IMMEDIATE l_sql
                INTO l_count;
        
            l_bool := l_count > 0;
        
        END IF;
    
        RETURN l_bool;
    
    END chck_if_table_eligible;

    -- ************************************************************************************************************
    FUNCTION get_ids
    (
        i_column     IN VARCHAR2,
        i_table_name IN VARCHAR2,
        i_rowids     IN table_varchar
    ) RETURN NUMBER IS
        k_where CONSTANT VARCHAR2(0500 CHAR) := ' WHERE ROWID IN (SELECT COLUMN_VALUE FROM TABLE(:3) T ) group by ';
        tbl_ids table_number;
        l_count NUMBER(24);
        l_sql   VARCHAR2(4000);
    BEGIN
    
        -- agrupamento pelo codigo, se houver 1+ linhas, está algo de errado
        l_sql := ' SELECT ' || i_column || ' FROM ' || i_table_name || k_where || i_column;
    
        EXECUTE IMMEDIATE l_sql BULK COLLECT
            INTO tbl_ids
            USING i_rowids;
    
        l_count := SQL%ROWCOUNT;
    
        RETURN l_count;
    
    END get_ids;

    -- ************************************************************************************************************    
    FUNCTION chck_if_rowids_ok
    (
        i_table_name IN VARCHAR2,
        i_cols_table IN table_varchar,
        i_rowids     IN table_varchar
    ) RETURN BOOLEAN IS
        --l_ids  table_number := table_number();
        l_count NUMBER;
        l_bool  BOOLEAN := TRUE;
    BEGIN
    
        FOR i IN 1 .. i_cols_table.count
        LOOP
            l_count := get_ids(i_cols_table(i), i_table_name, i_rowids);
        
            IF l_count > 1
            THEN
                l_bool := FALSE;
                println('MSG010: chck_if_rowids_ok is false with COL:' || i_cols_table(i) || ' And l_count = ' ||
                        l_count);
                EXIT; -- exits loop on first occurence
            END IF;
        
        END LOOP;
    
        RETURN l_bool;
    
    END chck_if_rowids_ok;

    -- ***************************************************************************
    PROCEDURE write_log
    (
        i_func_name  IN VARCHAR2,
        i_table_name IN VARCHAR2
    ) IS
        l_text VARCHAR2(4000);
    BEGIN
    
        l_text := 'TABLE:' || i_table_name;
        println(l_text);
        l_text := l_text || '-' || dbms_utility.format_error_backtrace;
        log_error(i_text => l_text, i_func_name => i_func_name);
    END write_log;

    -- ***************************************************************************
    PROCEDURE perform_behaviour
    (
        i_bool      IN BOOLEAN,
        i_behaviour IN VARCHAR2,
        i_text      IN VARCHAR2
    ) IS
    BEGIN
    
        IF NOT i_bool
        THEN
            write_log('CHECK_CONSISTENCY', i_text);
            IF i_behaviour != k_silent_mode
            THEN
                RAISE err_bad_rowid;
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN err_bad_rowid THEN
            RAISE;
    END perform_behaviour;

    -- ***************************************************************************    
    FUNCTION get_cols
    (
        i_prof       IN profissional,
        i_owner      IN VARCHAR2,
        i_table_name IN VARCHAR2
    ) RETURN table_varchar IS
        l_cols_table      table_varchar := table_varchar();
        l_validation_mode VARCHAR2(0050 CHAR);
    BEGIN
    
        l_validation_mode := get_config(k_idx03, i_prof);
    
        IF l_validation_mode IS NOT NULL
        THEN
        
            println('0004 get list of columns for validation');
            CASE l_validation_mode
                WHEN k_auto_mode THEN
                    println('0004a Auto validation');
                    l_cols_table := get_auto_cols_list(i_prof, i_owner, i_table_name);
                WHEN k_manual_mode THEN
                    println('0004a manual validation');
                    l_cols_table := get_manual_cols_list(i_owner, i_table_name);
                ELSE
                    NULL;
            END CASE;
        
        END IF;
    
        RETURN l_cols_table;
    
    END get_cols;

    -- ***************************************************************************    

    /**
    Function to get owner of given table
    */
    FUNCTION get_owner(i_table_name IN VARCHAR2) RETURN VARCHAR2 IS
        tbl_owner table_varchar;
        l_return  VARCHAR2(0050 CHAR);
    BEGIN
    
        SELECT DISTINCT source_owner
          BULK COLLECT
          INTO tbl_owner
          FROM data_gov_event
         WHERE source_table_name = i_table_name;
    
        CASE
            WHEN tbl_owner.count = 1 THEN
                l_return := tbl_owner(1);
            WHEN tbl_owner.count > 1 THEN
                RAISE err_too_many_table;
            ELSE
                NULL;
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN err_too_many_table THEN
            println('Error: tale ' || i_table_name || ' in several schema.');
            RAISE;
    END get_owner;

    PROCEDURE chck_consistency
    (
        i_prof              IN profissional,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2
    ) IS
        l_cols_table table_varchar := table_varchar();
        l_behaviour  VARCHAR2(0100 CHAR);
        l_owner      VARCHAR2(0100 CHAR);
        l_tmp_string VARCHAR2(1000 CHAR);
        l_bool       BOOLEAN;
    BEGIN
    
        println('0005 check for silent behaviour/interrupt behaviour');
        l_behaviour := get_behaviour(i_prof);
    
        l_owner := get_owner(i_source_table_name);
    
        -- table is data gov consistency enable
        l_cols_table := get_cols(i_prof => i_prof, i_owner => l_owner, i_table_name => i_source_table_name);
    
        println('0001 check if  table has columns to validate');
        l_bool := chck_if_table_eligible(l_owner, i_source_table_name, l_cols_table);
    
        IF l_bool
        THEN
            println('0002 if afirmative, check rowid for different Ids');
            l_bool := chck_if_rowids_ok(i_source_table_name, l_cols_table, i_rowids);
        
            IF NOT l_bool
            THEN
                println('0003 if any, then apply action');
                l_tmp_string := l_behaviour || '-' || l_owner || '.' || i_source_table_name;
                perform_behaviour(l_bool, l_behaviour, l_tmp_string);
            END IF;
        
        END IF;
    
        println('0013 End of process');
    
    END chck_consistency;

    FUNCTION chck_consistency
    (
        i_prof       IN profissional,
        i_table_name IN VARCHAR2,
        i_rowids     IN table_varchar
    ) RETURN BOOLEAN IS
    BEGIN
    
        chck_consistency(i_prof => i_prof, i_source_table_name => i_table_name, i_rowids => i_rowids);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            log_error(i_text => SQLERRM, i_func_name => 'CHCK_CONSISTENCY');
            RETURN FALSE;
    END chck_consistency;

    -- This package supports the creation and maintenance of Data Governance tables.
    -- It provides a generic event signalling and processing framework that enables code decoupling
    -- between business logic and EA tables maintenance.
    -- @author Nuno Guerreiro
    -- @version 2.4.3-Denormalized

    /**
    * Launches a job that calls the procedure using the right arguments.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_procedure          Name of the procedure to be called.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/10
    */
    PROCEDURE launch_event_job
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_procedure         IN VARCHAR2,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_list_columns      IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_dg_table_name     IN VARCHAR2
    ) IS
        -- DBMS_SCHEDULER program name
        l_program_name VARCHAR2(32);
    
        -- DBMS_SCHEDULER job name
        l_job_name VARCHAR2(32);
    
        -- Cleans up old programs whose jobs were already executed and auto-dropped
        PROCEDURE inner_cleanup_old_programs IS
        BEGIN
            BEGIN
                -- Find all programs that do not have an associated job and that are enabled
                FOR r_program IN (SELECT program_name
                                    FROM user_scheduler_programs usp
                                   WHERE program_name LIKE REPLACE(g_data_gov_program_prefix, '_', '\_') || '%' ESCAPE
                                   '\'
                                     AND usp.program_type = 'STORED_PROCEDURE'
                                     AND usp.number_of_arguments = 7
                                     AND usp.enabled = 'TRUE'
                                     AND NOT EXISTS (SELECT 1
                                            FROM user_scheduler_jobs usj
                                           WHERE usj.program_name = usp.program_name))
                
                LOOP
                    -- Drop each job without forcing
                    dbms_scheduler.drop_program(r_program.program_name);
                END LOOP;
            END;
        END inner_cleanup_old_programs;
    
        -- Defines arguments for calling the procedure. Complex types must be converted to ANYDATA.
        -- If sometime in the future the standard event procedure argument set changes, this procedure must be changed!
        PROCEDURE inner_set_event_job_arguments(l_program_name IN VARCHAR2) IS
        BEGIN
            dbms_scheduler.define_program_argument(program_name      => l_program_name,
                                                   argument_position => 1,
                                                   argument_name     => 'I_LANG',
                                                   argument_type     => 'NUMBER');
            dbms_scheduler.define_anydata_argument(program_name      => l_program_name,
                                                   argument_position => 2,
                                                   argument_name     => 'I_PROF',
                                                   argument_type     => 'PROFISSIONAL',
                                                   default_value     => anydata.convertobject(profissional(NULL,
                                                                                                           NULL,
                                                                                                           NULL)));
            dbms_scheduler.define_program_argument(program_name      => l_program_name,
                                                   argument_position => 3,
                                                   argument_name     => 'I_EVENT_TYPE',
                                                   argument_type     => 'VARCHAR2');
            dbms_scheduler.define_anydata_argument(program_name      => l_program_name,
                                                   argument_position => 4,
                                                   argument_name     => 'I_ROWIDS',
                                                   argument_type     => 'TABLE_VARCHAR',
                                                   default_value     => anydata.convertcollection(table_varchar()));
            dbms_scheduler.define_program_argument(program_name      => l_program_name,
                                                   argument_position => 5,
                                                   argument_name     => 'I_SOURCE_TABLE_NAME',
                                                   argument_type     => 'VARCHAR2');
            dbms_scheduler.define_anydata_argument(program_name      => l_program_name,
                                                   argument_position => 6,
                                                   argument_name     => 'I_LIST_COLUMNS',
                                                   argument_type     => 'TABLE_VARCHAR',
                                                   default_value     => anydata.convertcollection(table_varchar()));
            dbms_scheduler.define_program_argument(program_name      => l_program_name,
                                                   argument_position => 7,
                                                   argument_name     => 'I_DG_TABLE_NAME',
                                                   argument_type     => 'VARCHAR2');
        END inner_set_event_job_arguments;
    
        -- Define argument values for calling the procedure. Complex types must be converted to ANYDATA.
        -- If sometime in the future the standard event procedure argument set changes, this procedure must be changed!
        PROCEDURE inner_set_event_job_arg_vals
        (
            i_prof              IN profissional,
            i_rowids            IN table_varchar,
            i_event_type        IN VARCHAR2,
            i_list_columns      IN table_varchar,
            i_dg_table_name     IN VARCHAR2,
            i_source_table_name IN VARCHAR2,
            i_job_name          IN VARCHAR2
        ) IS
        BEGIN
            dbms_scheduler.set_job_argument_value(job_name       => i_job_name,
                                                  argument_name  => 'I_LANG',
                                                  argument_value => i_lang);
        
            dbms_scheduler.set_job_anydata_value(job_name       => i_job_name,
                                                 argument_name  => 'I_PROF',
                                                 argument_value => anydata.convertobject(i_prof));
        
            dbms_scheduler.set_job_argument_value(job_name       => i_job_name,
                                                  argument_name  => 'I_EVENT_TYPE',
                                                  argument_value => i_event_type);
        
            dbms_scheduler.set_job_anydata_value(job_name       => i_job_name,
                                                 argument_name  => 'I_ROWIDS',
                                                 argument_value => anydata.convertcollection(i_rowids));
        
            dbms_scheduler.set_job_argument_value(job_name       => i_job_name,
                                                  argument_name  => 'I_SOURCE_TABLE_NAME',
                                                  argument_value => i_source_table_name);
        
            dbms_scheduler.set_job_anydata_value(job_name       => i_job_name,
                                                 argument_name  => 'I_LIST_COLUMNS',
                                                 argument_value => anydata.convertcollection(nvl(i_list_columns,
                                                                                                 table_varchar())));
        
            dbms_scheduler.set_job_argument_value(job_name       => i_job_name,
                                                  argument_name  => 'I_DG_TABLE_NAME',
                                                  argument_value => i_dg_table_name);
        END inner_set_event_job_arg_vals;
    BEGIN
        -- Clean up old programs
        inner_cleanup_old_programs;
    
        -- Generate job and program names
        l_program_name := dbms_scheduler.generate_job_name(g_data_gov_program_prefix);
        l_job_name     := dbms_scheduler.generate_job_name(g_data_gov_job_prefix);
    
        -- Create a program for running the procedure, using the standard parameter number
        dbms_scheduler.create_program(program_name        => l_program_name,
                                      program_type        => 'STORED_PROCEDURE',
                                      program_action      => i_procedure,
                                      number_of_arguments => 7,
                                      comments            => 'Processing event using ' || i_procedure,
                                      enabled             => FALSE);
    
        -- Define event procedure arguments
        inner_set_event_job_arguments(l_program_name);
    
        -- Create disabled job
        dbms_scheduler.create_job(job_name     => l_job_name,
                                  program_name => l_program_name,
                                  enabled      => FALSE,
                                  comments     => 'Data Governance update job',
                                  start_date   => current_timestamp);
    
        -- Set event procedure argument values
        inner_set_event_job_arg_vals(i_prof              => i_prof,
                                     i_rowids            => i_rowids,
                                     i_event_type        => i_event_type,
                                     i_list_columns      => i_list_columns,
                                     i_dg_table_name     => i_dg_table_name,
                                     i_source_table_name => i_source_table_name,
                                     i_job_name          => l_job_name);
    
        -- Enable the program and the job, in order to execute the procedure.
        dbms_scheduler.enable(l_program_name);
        dbms_scheduler.enable(l_job_name);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_EVENT_TYPE',
                                            value1_in     => i_event_type,
                                            name2_in      => 'I_SOURCE_TABLE_NAME',
                                            value2_in     => i_source_table_name,
                                            name3_in      => 'I_DG_TABLE_NAME',
                                            value3_in     => i_dg_table_name,
                                            name4_in      => 'I_PROCEDURE',
                                            value4_in     => i_procedure);
            pk_utils.undo_changes();
    END launch_event_job;

    /**
    * Calls a procedure using the right arguments.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_procedure          Name of the procedure to be called.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table
    * @param i_flg_background     Background processing? ('Y' yes, 'N' no)
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/01
    */
    -- Gets a string representation out of a table_varchar
    FUNCTION inner_get_table_varchar_str(i_table table_varchar) RETURN VARCHAR2 IS
        l_string VARCHAR2(4000);
        k_buffer_too_small_msg CONSTANT VARCHAR2(100 CHAR) := 'Error:String buffer too long...';
        l_buffer_too_small EXCEPTION;
        PRAGMA EXCEPTION_INIT(l_buffer_too_small, -06502);
    BEGIN
        SELECT substr(concatenate(column_value), 1, 4000)
          INTO l_string
          FROM TABLE(i_table);
    
        RETURN l_string;
    EXCEPTION
        WHEN l_buffer_too_small THEN
            RETURN k_buffer_too_small_msg;
        WHEN no_data_found THEN
            RETURN NULL;
    END inner_get_table_varchar_str;

    PROCEDURE call_event_procedure
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_procedure         IN VARCHAR2,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_list_columns      IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_dg_table_name     IN VARCHAR2,
        i_flg_background    IN VARCHAR2
    ) IS
        l_code             VARCHAR2(4000);
        l_rowids_str       VARCHAR2(4000);
        l_list_columns_str VARCHAR2(4000);
        l_func_proc_name   VARCHAR2(30);
        l_prof             profissional;
    
        PROCEDURE logging_debug IS
        BEGIN
        
            -- Log parameters and call
            log_debug('-- Background? ' || i_flg_background || k_lf || '-- Parameters: ' || k_lf || '-- i_lang: ' ||
                      i_lang || k_lf || '-- i_prof: profissional(' || l_prof.id || ',' || l_prof.institution || ',' ||
                      l_prof.software || ')' || k_lf || '-- i_event_type: ' || i_event_type || k_lf || '-- i_rowids: ' ||
                      l_rowids_str || k_lf || '-- i_source_table_name: ' || i_source_table_name || k_lf ||
                      '-- i_list_columns: ' || l_list_columns_str || k_lf || '-- i_dg_table_name: ' || i_dg_table_name || k_lf ||
                      l_code,
                      l_func_proc_name);
        
        END logging_debug;
    
    BEGIN
        l_func_proc_name := 'CALL_EVENT_PROCEDURE';
    
        IF i_prof IS NULL
        THEN
            l_prof := profissional(0, 0, 0);
        ELSE
            l_prof := i_prof;
        END IF;
    
        -- Build code to execute
        l_code := 'BEGIN ' || k_lf || '  ' || i_procedure || '(:1,:2,:3,:4,:5,:6,:7);' || k_lf || 'END;';
    
        -- Generate DEBUG information only if DEBUG mode is enabled (to avoid overhead).
        IF pk_alertlog.isdebugenabled
        THEN
            -- Get a string representation of the list of ROWIDs
            g_error      := 'GET ROWIDS STRING';
            l_rowids_str := inner_get_table_varchar_str(i_rowids);
        
            -- Get a string representation of the list of columns
            g_error            := 'GET COLUMNS STRING';
            l_list_columns_str := inner_get_table_varchar_str(i_list_columns);
        
            logging_debug();
        
        END IF;
    
        IF i_flg_background = g_yes
        THEN
            -- Launch a job, using the same arguments
            launch_event_job(i_lang              => i_lang,
                             i_procedure         => i_procedure,
                             i_prof              => l_prof,
                             i_event_type        => i_event_type,
                             i_rowids            => i_rowids,
                             i_source_table_name => i_source_table_name,
                             i_list_columns      => i_list_columns,
                             i_dg_table_name     => i_dg_table_name);
        ELSE
            -- Execute in the same session
            EXECUTE IMMEDIATE l_code
                USING i_lang, l_prof, i_event_type, i_rowids, i_source_table_name, i_list_columns, i_dg_table_name;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_EVENT_TYPE',
                                            value1_in     => i_event_type,
                                            name2_in      => 'I_SOURCE_TABLE_NAME',
                                            value2_in     => i_source_table_name,
                                            name3_in      => 'I_DG_TABLE_NAME',
                                            value3_in     => i_dg_table_name);
            pk_utils.undo_changes();
    END call_event_procedure;

    /**
    * This procedure processes an event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Event type (UPDATE, INSERT, etc)
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */

    PROCEDURE process_event
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_list_columns IN table_varchar DEFAULT table_varchar(),
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) IS
        -- Invalid code exception
        e_invalid_code EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_invalid_code, -6550);
    
        -- Package state exception
        e_state_discarded EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_state_discarded, -4068);
    
        -- Insufficient privileges exception
        e_insufficient_privs EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_state_discarded, -1031);
    
        l_current_event     data_gov_event.id_data_gov_event%TYPE;
        l_current_procedure data_gov_event.exec_procedure%TYPE;
    
        l_func_proc_name VARCHAR2(30);
        l_bool           BOOLEAN;
    
        -- Events to process
        CURSOR c_events IS
            SELECT id_data_gov_event, dg_table_name, exec_procedure, flg_background, flg_iud
              FROM (SELECT id_data_gov_event,
                           dg_table_name,
                           exec_procedure,
                           flg_background,
                           flg_iud,
                           exec_order,
                           row_number() over(PARTITION BY exec_procedure ORDER BY id_data_gov_event) rn
                      FROM (SELECT dge.id_data_gov_event,
                                   dge.dg_table_name,
                                   dge.exec_procedure,
                                   dge.flg_background,
                                   dge.flg_iud,
                                   dge.exec_order
                              FROM data_gov_event dge
                             WHERE dge.source_table_name = i_table_name
                               AND dge.source_column_name IS NULL
                               AND dge.flg_enabled = k_yes
                               AND dge.id_software IN (0, i_prof.software)
                               AND EXISTS (SELECT 1
                                      FROM frmw_objects fo
                                     WHERE fo.owner = dge.dg_owner
                                       AND fo.obj_name = dge.dg_table_name
                                       AND fo.obj_type = 'TABLE'
                                       AND fo.flg_nzd = k_no
                                       AND i_flg_nzd = k_yes
                                    UNION ALL
                                    SELECT 1
                                      FROM dual
                                     WHERE i_flg_nzd = k_no)
                            UNION ALL
                            SELECT dge.id_data_gov_event,
                                   dge.dg_table_name,
                                   dge.exec_procedure,
                                   dge.flg_background,
                                   dge.flg_iud,
                                   dge.exec_order
                              FROM data_gov_event dge
                             WHERE dge.source_table_name = i_table_name
                               AND i_list_columns IS NULL
                               AND dge.flg_enabled = k_yes
                               AND dge.id_software IN (0, i_prof.software)
                               AND EXISTS (SELECT 1
                                      FROM frmw_objects fo
                                     WHERE fo.owner = dge.dg_owner
                                       AND fo.obj_name = dge.dg_table_name
                                       AND fo.obj_type = 'TABLE'
                                       AND fo.flg_nzd = k_no
                                       AND i_flg_nzd = k_yes
                                    UNION ALL
                                    SELECT 1
                                      FROM dual
                                     WHERE i_flg_nzd = k_no)
                            UNION ALL
                            SELECT dge.id_data_gov_event,
                                   dge.dg_table_name,
                                   dge.exec_procedure,
                                   dge.flg_background,
                                   dge.flg_iud,
                                   dge.exec_order
                              FROM data_gov_event dge
                             WHERE dge.source_table_name = i_table_name
                               AND (SELECT /*+ opt_estimate(table t rows=1) */
                                     COUNT(1)
                                      FROM TABLE(i_list_columns) t) = 0
                               AND dge.flg_enabled = k_yes
                               AND dge.id_software IN (0, i_prof.software)
                               AND EXISTS (SELECT 1
                                      FROM frmw_objects fo
                                     WHERE fo.owner = dge.dg_owner
                                       AND fo.obj_name = dge.dg_table_name
                                       AND fo.obj_type = 'TABLE'
                                       AND fo.flg_nzd = k_no
                                       AND i_flg_nzd = k_yes
                                    UNION ALL
                                    SELECT 1
                                      FROM dual
                                     WHERE i_flg_nzd = k_no)
                            UNION ALL
                            SELECT dge.id_data_gov_event,
                                   dge.dg_table_name,
                                   dge.exec_procedure,
                                   dge.flg_background,
                                   dge.flg_iud,
                                   dge.exec_order
                              FROM data_gov_event dge
                             WHERE dge.source_table_name = i_table_name
                               AND lower(dge.source_column_name) IN
                                   (SELECT /*+ opt_estimate(table t rows=1) */
                                     lower(column_value)
                                      FROM TABLE(i_list_columns) t)
                               AND dge.flg_enabled = k_yes
                               AND dge.id_software IN (0, i_prof.software)
                               AND EXISTS (SELECT 1
                                      FROM frmw_objects fo
                                     WHERE fo.owner = dge.dg_owner
                                       AND fo.obj_name = dge.dg_table_name
                                       AND fo.obj_type = 'TABLE'
                                       AND fo.flg_nzd = k_no
                                       AND i_flg_nzd = k_yes
                                    UNION ALL
                                    SELECT 1
                                      FROM dual
                                     WHERE i_flg_nzd = k_no)))
             WHERE rn = 1
             ORDER BY exec_order NULLS LAST;
    
        -- **********************************************************
        PROCEDURE raise_error
        (
            i_sqlcode       IN NUMBER,
            i_sqlerrm       IN VARCHAR2,
            i_cur_procedure IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.raise_error(error_code_in => i_sqlcode,
                                            text_in       => i_sqlerrm,
                                            name1_in      => 'I_EVENT_TYPE',
                                            value1_in     => i_event_type,
                                            name2_in      => 'EXEC_PROCEDURE',
                                            value2_in     => i_cur_procedure,
                                            name3_in      => 'I_TABLE_NAME',
                                            value3_in     => i_table_name);
            pk_utils.undo_changes();
        
        END raise_error;
    
    BEGIN
        l_func_proc_name := 'PROCESS_EVENT';
    
        -- Ignore empty or null rowid lists
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            -- Loop through events
            g_error := 'LOOP';
            <<lup_thru_events>>
            FOR r_event IN c_events
            LOOP
                -- Debug info
                l_current_event     := r_event.id_data_gov_event;
                l_current_procedure := r_event.exec_procedure;
            
                g_error := 'Processing event #' || l_current_event || ' | Type ' || i_event_type;
                log_debug(g_error, l_func_proc_name);
            
                --test if the event is registered for the DML operation
                l_bool := (instr(r_event.flg_iud, i_event_type) > 0);
                IF l_bool
                   OR (r_event.flg_iud = k_event_update)
                THEN
                
                    -- Process event, by calling the associated procedure
                    g_error := 'CALL EVENT PROCEDURE #' || l_current_event;
                    call_event_procedure(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_procedure         => r_event.exec_procedure,
                                         i_event_type        => i_event_type,
                                         i_rowids            => i_rowids,
                                         i_list_columns      => i_list_columns,
                                         i_source_table_name => i_table_name,
                                         i_dg_table_name     => r_event.dg_table_name,
                                         i_flg_background    => r_event.flg_background);
                ELSE
                    g_error := 'Event #' || l_current_event || ' skipped: not registered for type ' || i_event_type;
                    log_debug(g_error, l_func_proc_name);
                END IF;
            
            END LOOP lup_thru_events;
        
        END IF;
    
    EXCEPTION
        WHEN e_invalid_code THEN
            g_error := 'Invalid procedure code - Check configuration and number of arguments';
            raise_error(i_sqlcode => SQLCODE, i_sqlerrm => g_error, i_cur_procedure => l_current_procedure);
        
        WHEN e_state_discarded THEN
            g_error := 'Package state has been discarded - Recompile the procedure''s package';
            raise_error(i_sqlcode => SQLCODE, i_sqlerrm => g_error, i_cur_procedure => l_current_procedure);
        
        WHEN e_insufficient_privs THEN
            g_error := 'Insufficient privileges - Check grants';
            raise_error(i_sqlcode => SQLCODE, i_sqlerrm => g_error, i_cur_procedure => l_current_procedure);
        
        WHEN g_excp_invalid_arguments THEN
            g_error := 'The procedure received unexpected arguments';
            raise_error(i_sqlcode => SQLCODE, i_sqlerrm => g_error, i_cur_procedure => l_current_procedure);
        
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        
        WHEN OTHERS THEN
            g_error := SQLERRM;
            raise_error(i_sqlcode => SQLCODE, i_sqlerrm => g_error, i_cur_procedure => l_current_procedure);
    END process_event;

    ------------------------------------------ PUBLIC ----------------------------------------------

    /*
    * Validates the arguments passed on to an event procedure
    *
    * @param i_rowids                   List of ROWIDs belonging to the changed records.
    * @param i_source_table_name        Name of the table that was changed.
    * @param i_dg_table_name            Name of the Data Governance table to be changed.
    * @param i_expected_table_name      Name of the table that the procedure is expecting to receive.
    * @param i_expected_dg_table_name   Name of the Data Governance table that the procedure is expecting to update
    * @param i_list_columns             List of columns that were changed.
    * @param i_expected_columns         List of columns that the procedure is expecting to be modified.
    *
    * @return TRUE if all arguments match what the procedure was expecting, FALSE otherwise
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/08/01
    */
    FUNCTION validate_arguments
    (
        i_rowids                 IN table_varchar,
        i_source_table_name      IN VARCHAR2,
        i_dg_table_name          IN VARCHAR2,
        i_expected_table_name    IN VARCHAR2,
        i_expected_dg_table_name IN VARCHAR2,
        i_list_columns           IN table_varchar DEFAULT NULL,
        i_expected_columns       IN table_varchar DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN := FALSE;
        --l_intersection_columns table_varchar;
        l_exists NUMBER;
    BEGIN
    
        -- Check arguments
        g_error := 'CHECK #1';
        IF (i_rowids IS NOT NULL AND i_source_table_name = i_expected_table_name AND
           i_dg_table_name = i_expected_dg_table_name)
        THEN
            g_error := 'CHECK #2';
            -- Check columns list
            IF (i_expected_columns IS NULL OR i_expected_columns.count = 0)
            THEN
                -- All columns expected
                l_ret := TRUE;
            ELSIF (i_list_columns IS NULL OR i_list_columns.count = 0)
            THEN
                -- All affected
                l_ret := TRUE;
            ELSE
                g_error := 'INTERSECT';
                -- At least one of the expected columns exist inside the changed columns list
                SELECT decode((SELECT 0
                                FROM dual
                               WHERE EXISTS (SELECT 0
                                        FROM TABLE(i_expected_columns) expected
                                        JOIN TABLE(i_list_columns) get
                                          ON (upper(get.column_value) = upper(expected.column_value)))),
                              0,
                              1,
                              0)
                  INTO l_exists
                  FROM dual;
            
                --l_intersection_columns := i_expected_columns MULTISET INTERSECT i_list_columns;
                --l_ret                  := l_intersection_columns IS NOT NULL AND l_intersection_columns.COUNT > 0;
                l_ret := l_exists = 1;
            END IF;
        END IF;
    
        g_error := 'RET';
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_SOURCE_TABLE_NAME',
                                            value1_in     => i_source_table_name,
                                            name2_in      => 'I_DG_TABLE_NAME',
                                            value2_in     => i_dg_table_name);
            pk_utils.undo_changes();
    END validate_arguments;

    /*
    * Searches the rowid's values for the given table filtering the result
    * by the given columns/values lists.
    *
    * @param i_table_name         Name of the table that was changed.
    * @param i_list_columns       List of PK column names.
    * @param i_list_values        List of PK column values.
    * @param o_rowids             List with the rowids
    *
    * @return TRUE if no error occurred, FALSE otherwise
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    FUNCTION get_rowids
    (
        i_table_name   IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_list_values  IN table_varchar,
        o_rowids       OUT table_varchar
    ) RETURN BOOLEAN IS
        l_err_diff_lst_size EXCEPTION;
        l_straux VARCHAR2(8000);
    BEGIN
        -- The number of elements of PK columns and values lists must be equal
        IF (i_list_columns.count != i_list_values.count)
        THEN
            RAISE l_err_diff_lst_size;
        END IF;
    
        -- Construct the query
        l_straux := 'select rowid from ' || i_table_name;
    
        FOR i IN i_list_columns.first .. i_list_columns.last
        LOOP
        
            l_straux := l_straux || iif((i = 1), ' where ', ' and ');
        
            l_straux := l_straux || i_list_columns(i) || ' = ''' || i_list_values(i) || '''';
        END LOOP;
    
        -- Execute the query and get the rowid
        EXECUTE IMMEDIATE l_straux BULK COLLECT
            INTO o_rowids;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            text_in       => SQLERRM,
                                            name1_in      => 'i_table_name',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
            RETURN FALSE;
    END get_rowids;

    /**
    * This function returns true or false whether procedure process_update executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_update
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN IS
    BEGIN
        process_update(i_lang         => i_lang,
                       i_prof         => i_prof,
                       i_table_name   => i_table_name,
                       i_rowids       => i_rowids,
                       i_list_columns => i_list_columns,
                       o_error        => o_error,
                       i_flg_nzd      => i_flg_nzd);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'PROCESS_UPDATE',
                                              i_owner    => 'ALERT',
                                              i_package  => 'T_DATA_GOV_MNT',
                                              i_function => 'PROCESS_UPDATE',
                                              o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
        
    END process_update;

    /**
    * This procedure processes an update event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR2,
        i_rowids     IN table_varchar,
        o_error      OUT t_error_out,
        
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) IS
    BEGIN
        -- Process event        
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_update,
                      i_table_name   => i_table_name,
                      i_rowids       => i_rowids,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
    END process_update;

    /**
    * This procedure processes an update event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    PROCEDURE process_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        i_list_columns    IN table_varchar DEFAULT NULL,
        i_flg_nzd         IN VARCHAR2 DEFAULT 'N'
    ) IS
        l_rowid table_varchar;
        l_exception EXCEPTION;
    BEGIN
        -- Get rowid
        IF (NOT get_rowids(i_table_name   => i_table_name,
                           i_list_columns => i_pk_list_columns,
                           i_list_values  => i_pk_list_values,
                           o_rowids       => l_rowid))
        THEN
            RAISE l_exception;
        END IF;
    
        -- Process event
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_update,
                      i_table_name   => i_table_name,
                      i_rowids       => l_rowid,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
    END process_update;

    /**
    * This function returns true or false whether procedure process_insert executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN IS
    BEGIN
        process_insert(i_lang         => i_lang,
                       i_prof         => i_prof,
                       i_table_name   => i_table_name,
                       i_rowids       => i_rowids,
                       i_list_columns => i_list_columns,
                       o_error        => o_error,
                       i_flg_nzd      => i_flg_nzd);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
            RETURN FALSE;
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'PROCESS_INSERT',
                                              i_owner    => 'ALERT',
                                              i_package  => 'T_DATA_GOV_MNT',
                                              i_function => 'PROCESS_INSERT',
                                              o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END process_insert;

    /**
    * This procedure processes an insert event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) IS
    BEGIN
        -- Process event
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_insert,
                      i_table_name   => i_table_name,
                      i_rowids       => i_rowids,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
    END process_insert;

    /**
    * This procedure processes an insert event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Alexandre Santos
    * @version 2.5
    * @since 2009/04/03
    */
    PROCEDURE process_insert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        i_list_columns    IN table_varchar DEFAULT NULL,
        i_flg_nzd         IN VARCHAR2 DEFAULT 'N'
    ) IS
        l_rowid table_varchar;
        l_exception EXCEPTION;
    BEGIN
        -- Get rowid
        IF (NOT get_rowids(i_table_name   => i_table_name,
                           i_list_columns => i_pk_list_columns,
                           i_list_values  => i_pk_list_values,
                           o_rowids       => l_rowid))
        THEN
            RAISE l_exception;
        END IF;
    
        -- Process event        
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_insert,
                      i_table_name   => i_table_name,
                      i_rowids       => l_rowid,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
    END process_insert;

    /**
    * This function returns true or false whether procedure process_delete executes correctly or don't.
    * This allows for better error control.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Fábio Oliveira
    * @version 2.5.0.6
    * @since 2009/10/07
    */
    FUNCTION process_delete
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) RETURN BOOLEAN IS
    BEGIN
        process_delete(i_lang         => i_lang,
                       i_prof         => i_prof,
                       i_table_name   => i_table_name,
                       i_rowids       => i_rowids,
                       i_list_columns => i_list_columns,
                       o_error        => o_error,
                       i_flg_nzd      => i_flg_nzd);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'PROCESS_DELETE',
                                              i_owner    => 'ALERT',
                                              i_package  => 'T_DATA_GOV_MNT',
                                              i_function => 'PROCESS_DELETE',
                                              o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END process_delete;

    /**
    * This procedure processes a delete event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_rowids             Changed records' ROWIDs
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Nuno Guerreiro
    * @version 2.4.3-Denormalized
    * @since 2008/10/02
    */
    PROCEDURE process_delete
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_table_name   IN VARCHAR2,
        i_rowids       IN table_varchar,
        o_error        OUT t_error_out,
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) IS
    BEGIN
        -- Process event
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_delete,
                      i_table_name   => i_table_name,
                      i_rowids       => i_rowids,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
        
    END process_delete;

    /**
    * This procedure processes a delete event, by calling all the procedures
    * associated with a change on table i_table_name and optionally on columns present
    * on i_list_columns.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the table that was changed.
    * @param i_pk_list_columns    List of PK column names.
    * @param i_pk_list_values     List of PK column values.
    * @param o_error              Error message (if an error occurred).
    * @param i_list_columns       (Optional) Names of the columns that were affected.
    *
    * @author Alexandre Santos
    * @version 2.4.3-Denormalized
    * @since 2009/04/03
    */
    PROCEDURE process_delete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_name      IN VARCHAR2,
        i_pk_list_columns IN table_varchar,
        i_pk_list_values  IN table_varchar,
        o_error           OUT t_error_out,
        
        i_list_columns IN table_varchar DEFAULT NULL,
        i_flg_nzd      IN VARCHAR2 DEFAULT 'N'
    ) IS
        l_rowid table_varchar;
        l_exception EXCEPTION;
    BEGIN
        -- Get rowid
        IF (NOT get_rowids(i_table_name   => i_table_name,
                           i_list_columns => i_pk_list_columns,
                           i_list_values  => i_pk_list_values,
                           o_rowids       => l_rowid))
        THEN
            RAISE l_exception;
        END IF;
    
        -- Process event
        process_event(i_lang         => i_lang,
                      i_prof         => i_prof,
                      i_event_type   => g_event_delete,
                      i_table_name   => i_table_name,
                      i_rowids       => l_rowid,
                      i_list_columns => i_list_columns,
                      i_flg_nzd      => i_flg_nzd);
    EXCEPTION
        WHEN err_bad_rowid THEN
            raise_application_error(-20010, get_err_str(i_table_name));
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            name1_in      => 'I_TABLE_NAME',
                                            value1_in     => i_table_name);
            pk_utils.undo_changes();
    END process_delete;

    FUNCTION assert_obj_owner
    (
        i_owner    IN VARCHAR2,
        i_obj_name IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_cnt NUMBER;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_cnt
          FROM dba_objects ao
         WHERE ao.object_name = i_obj_name
           AND ao.owner = i_owner;
    
        RETURN(l_cnt > 0);
    
    EXCEPTION
        WHEN OTHERS THEN
            log_error(i_text => SQLERRM, i_func_name => 'assert_obj_owner');
            RETURN FALSE;
    END assert_obj_owner;

    PROCEDURE upd_ins_data_gov_event
    (
        i_source_owner       IN VARCHAR2 DEFAULT NULL,
        i_source_table_name  IN VARCHAR2 DEFAULT NULL,
        i_source_column_name IN VARCHAR2 DEFAULT NULL,
        i_dg_owner           IN VARCHAR2 DEFAULT NULL,
        i_dg_table_name      IN VARCHAR2 DEFAULT NULL,
        i_flg_enabled        IN VARCHAR2,
        i_flg_background     IN VARCHAR2,
        i_flg_iud            IN VARCHAR2 DEFAULT 'IUD',
        i_exec_procedure     IN VARCHAR2,
        i_exec_order         IN VARCHAR2,
        i_id_software        IN NUMBER
    ) IS
        invalid_src_owner  EXCEPTION;
        invalid_dest_owner EXCEPTION;
        l_rowcount           NUMBER(24) := 0;
        l_source_owner       VARCHAR2(0100 CHAR) := upper(i_source_owner);
        l_source_table_name  VARCHAR2(0100 CHAR) := upper(i_source_table_name);
        l_source_column_name VARCHAR2(0100 CHAR) := upper(i_source_column_name);
        l_dg_owner           VARCHAR2(0100 CHAR) := upper(i_dg_owner);
        l_dg_table_name      VARCHAR2(0100 CHAR) := upper(i_dg_table_name);
        l_exec_procedure     VARCHAR2(0200 CHAR) := upper(i_exec_procedure);
        l_id_data_gov_event  NUMBER(24) := 0;
    BEGIN
        IF NOT assert_obj_owner(i_owner => i_source_owner, i_obj_name => i_source_table_name)
        THEN
            RAISE invalid_src_owner;
        END IF;
    
        IF NOT assert_obj_owner(i_owner => i_dg_owner, i_obj_name => i_dg_table_name)
        THEN
            RAISE invalid_dest_owner;
        END IF;
    
        g_error := 'update data_gov_event';
        UPDATE data_gov_event dge
           SET dge.exec_order     = i_exec_order,
               dge.flg_enabled    = i_flg_enabled,
               dge.flg_background = i_flg_background,
               dge.flg_iud        = nvl(i_flg_iud, dge.flg_iud),
               dge.id_software    = i_id_software
         WHERE dge.dg_owner = l_dg_owner
           AND dge.dg_table_name = l_dg_table_name
           AND dge.source_owner = l_source_owner
           AND dge.source_table_name = l_source_table_name
           AND (l_source_column_name IS NULL OR dge.source_column_name = l_source_column_name)
           AND dge.exec_procedure = l_exec_procedure;
    
        l_rowcount := SQL%ROWCOUNT;
    
        IF l_rowcount = 0 --INS
        THEN
            g_error             := 'insert data_gov_event';
            l_id_data_gov_event := seq_data_gov_event.nextval;
        
            INSERT INTO data_gov_event
                (id_data_gov_event,
                 source_owner,
                 source_table_name,
                 source_column_name,
                 dg_owner,
                 dg_table_name,
                 flg_enabled,
                 flg_background,
                 flg_iud,
                 exec_procedure,
                 exec_order,
                 id_software)
            VALUES
                (l_id_data_gov_event,
                 l_source_owner,
                 l_source_table_name,
                 l_source_column_name,
                 l_dg_owner,
                 l_dg_table_name,
                 i_flg_enabled,
                 i_flg_background,
                 i_flg_iud,
                 i_exec_procedure,
                 i_exec_order,
                 i_id_software);
        END IF;
    EXCEPTION
        WHEN invalid_src_owner THEN
            g_error := 'Source owner and table name are not valid - ' || i_source_owner || '.' || i_source_table_name;
            raise_application_error(-20003, g_error || '-' || SQLERRM);
        
        WHEN invalid_dest_owner THEN
            g_error := 'Destination owner and table name are not valid - ' || i_dg_owner || '.' || i_dg_table_name;
            raise_application_error(-20004, g_error || '-' || SQLERRM);
        
        WHEN OTHERS THEN
            raise_application_error(-20005, g_error || '-' || SQLERRM);
    END upd_ins_data_gov_event;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END t_data_gov_mnt;
/
