/*-- Last Change Revision: $Rev: 2026927 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_data_compare IS

    ------------------------------ PRIVATE PACKAGE VARIABLES ---------------------------
    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);

    /*******************************************************************************************************************************************
    * Name :                          count_record_match                                                                                       *
    * Description:                    Count the number of times the rows in the source object appear in the target object according to the     *
    *                                 rules specified in DATA_COMPARE_RULE table                                                               *
    *                                                                                                                                          *
    * @param i_lang                   Input - Language                                                                                         *
    * @param i_id_institution         Input - Institution ID                                                                                   *
    * @param i_obj_source             Input - The object containing the data to compare from                                                   *
    * @param i_rowid_source           Input - A collection of rowids in the source object to compare                                           *
    * @param i_obj_target             Input - The object containing the data to compare to                                                     *
    * @param i_rowid_target           Input - A collection of rowids in the target object to compare                                           *
    *                                                                                                                                          *
    * @author                         Nelson Canastro                                                                                          *
    * @version                        1.0                                                                                                      *
    * @since                          25-Mar-2010                                                                                              *
    *******************************************************************************************************************************************/
    FUNCTION count_record_match
    (
        i_lang           IN NUMBER,
        i_id_institution IN NUMBER,
        i_obj_source     IN VARCHAR2,
        i_rowid_source   IN dbms_sql.urowid_table,
        i_obj_target     IN VARCHAR2,
        i_rowid_target   IN dbms_sql.urowid_table,
        o_error          OUT t_error_out
    ) RETURN NUMBER IS
        --stores the number of matches found
        l_count_match NUMBER := 0;
    
        --dummy return of dbms_sql.execute
        l_exec_ret NUMBER;
    
        -- Cursor containing the rules configured for the given objects and institution
        CURSOR c_rules IS
            SELECT t.col_source, t.col_target
              FROM data_compare_rule t
             WHERE t.obj_source = i_obj_source
               AND t.obj_target = i_obj_target
               AND t.id_institution = i_id_institution
               AND t.flg_available = pk_alert_constant.g_yes;
    
        --Rowtype of the rules cursor
        r_rules c_rules%ROWTYPE;
    
        --Dynamic SQL statement
        l_sql_stmt  VARCHAR2(4000);
        l_sql_rules VARCHAR2(1000 CHAR);
    
        --Name of the current function for error handling purposes
        l_func_name VARCHAR2(24) := 'count_record_match';
    
        --exception for no rules parameterized
        e_no_rules EXCEPTION;
    
        --Cursor for dynamic SQL statement processing
        c_engine PLS_INTEGER := dbms_sql.open_cursor;
    BEGIN
        /*
        TODO: owner="nelson.canastro" priority="1 - High" created="25-03-2010" closed="06-04-2010"
        text="Validate parameters"
        */
        /*
        TODO: owner="nelson.canastro" priority="1 - High" created="25-03-2010" closed="06-04-2010"
        text="Validate table names against injection"
        */
        /*
        TODO: owner="nelson.canastro" priority="2 - Medium" created="25-03-2010" closed="06-04-2010"
        text="Comment function"
        */
        /*
        TODO: owner="nelson.canastro" priority="2 - Medium" created="23-03-2010"
        text="Check rules count. Raise exception if no rules found."
        */
        dbms_output.put_line('Start ' || l_func_name);
    
        --Checks if rules are parameterized for the given objects and institution
        FOR r_rules IN c_rules
        LOOP
            l_sql_rules := l_sql_rules || ' AND a.' || r_rules.col_source || ' = b.' || r_rules.col_target;
        END LOOP;
    
        IF l_sql_rules IS NULL
        THEN
            RAISE e_no_rules;
        END IF;
    
        --Builds the starting point of the dynamic SQL statement
        l_sql_stmt := 'SELECT count(*) FROM ' || dbms_assert.sql_object_name(i_obj_source) || ' a, ' ||
                      dbms_assert.sql_object_name(i_obj_target) || ' b WHERE';
    
        --Add rowids for source object
        IF i_rowid_source IS NOT NULL
           AND i_rowid_source.COUNT > 0
        THEN
            -- first rowid prepares the IN statement
            l_sql_stmt := l_sql_stmt || ' AND a."rowid" in (''' || i_rowid_source(1) || '''';
        
            -- add the remaining rowids
            FOR i IN 2 .. i_rowid_source.COUNT
            LOOP
                l_sql_stmt := l_sql_stmt || ',''' || i_rowid_source(i) || '''';
            END LOOP;
            -- close the IN statement
            l_sql_stmt := l_sql_stmt || ') ';
        END IF;
    
        --Add rowids for target object
        IF i_rowid_target IS NOT NULL
           AND i_rowid_target.COUNT > 0
        THEN
            -- first rowid prepares the IN statement
            l_sql_stmt := l_sql_stmt || ' AND b."rowid" in (''' || i_rowid_target(1) || '''';
        
            -- add the remaining rowids
            FOR i IN 2 .. i_rowid_target.COUNT
            LOOP
                l_sql_stmt := l_sql_stmt || ',''' || i_rowid_target(i) || '''';
            END LOOP;
            -- close the IN statement
            l_sql_stmt := l_sql_stmt || ') ';
        END IF;
    
        --Add join rules configured in data_compare_rule
        l_sql_stmt := l_sql_stmt || l_sql_rules;
    
        --Removes the first AND after the WHERE
        l_sql_stmt := REPLACE(l_sql_stmt, 'WHERE AND', 'WHERE');
        dbms_output.put_line(l_sql_stmt);
    
        --Parse SQL statement
        dbms_sql.parse(c_engine, l_sql_stmt, dbms_sql.native);
    
        -- Define a column to retrieve the count
        dbms_sql.define_column(c_engine, 1, l_count_match);
    
        --Execute SQL statement
        l_exec_ret := dbms_sql.EXECUTE(c_engine);
    
        LOOP
            -- Fetch a row from the source table
            IF dbms_sql.fetch_rows(c_engine) > 0
            THEN
                -- get count result
                dbms_sql.column_value(c_engine, 1, l_count_match);
            ELSE
                -- No more rows to copy
                EXIT;
            END IF;
        END LOOP;
    
        -- Close the engine cursor
        dbms_sql.close_cursor(c_engine);
    
        dbms_output.put_line('Count Matches: ' || l_count_match);
    
        RETURN l_count_match;
    EXCEPTION
        WHEN e_no_rules THEN
            pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                i_sqlcode     => NULL,
                                                i_sqlerrm     => NULL,
                                                i_message     => NULL,
                                                i_owner       => g_package_owner,
                                                i_package     => g_package_name,
                                                i_function    => 'VALIDATE_DRUG_BARCODE',
                                                i_action_type => 'U',
                                                i_action_msg  => pk_message.get_message(i_lang,
                                                                                        'MEDICATION_BARCODE_M013'),
                                                i_msg_title   => pk_message.get_message(i_lang,
                                                                                        'MEDICATION_BARCODE_T007'),
                                                o_error       => o_error);
            RETURN - 2;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN - 1;
    END;
    /* ======================
    * --Global definitions--
    * ======================
    */

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
