/*-- Last Change Revision: $Rev: 1607535 $*/
/*-- Last Change by: $Author: gisela.couto $*/
/*-- Date of last change: $Date: 2014-06-27 18:59:05 +0100 (sex, 27 jun 2014) $*/

create or replace package body pk_edis_handle_refcursor is

    g_cursor_id   NUMBER;
    g_line_number NUMBER;
    g_num_of_cols NUMBER;

    g_desc_table dbms_sql.desc_tab;
    g_result_tbl table_varchar_idx;

    FUNCTION is_supported_type(i_col_type IN PLS_INTEGER) RETURN BOOLEAN IS
        c_tbl_supported_types CONSTANT table_number := table_number(dbms_types.typecode_varchar,
                                                                    dbms_types.typecode_varchar2,
                                                                    dbms_types.typecode_char,
                                                                    dbms_types.typecode_number);
    
        l_supported_type PLS_INTEGER;
        l_function_name  VARCHAR2(1000) := 'IS_SUPPORTED_TYPE';
        l_error          VARCHAR2(1000);
    BEGIN
        l_error := 'VERIFY IF EXISTS SUPPORTED TYPES';
        SELECT COUNT(1)
          INTO l_supported_type
          FROM TABLE(c_tbl_supported_types)
         WHERE column_value = i_col_type;
    
        RETURN(l_supported_type > 0);
    END is_supported_type;
		
    /********************************************************************************************
    * Initializes one global cursor dinamicaly
    * @param i_cursor               pk_types.cursor_type
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    PROCEDURE init_cursor(i_cursor IN OUT pk_types.cursor_type) IS
        l_my_res_vc VARCHAR2(1000 CHAR);
        l_desc_rec  dbms_sql.desc_rec;
    BEGIN
        g_cursor_id := dbms_sql.to_cursor_number(i_cursor);
        dbms_sql.describe_columns(c => g_cursor_id, col_cnt => g_num_of_cols, desc_t => g_desc_table);
    
        FOR i IN 1 .. g_num_of_cols
        LOOP
            l_desc_rec := g_desc_table(i);
        
            IF is_supported_type(i_col_type => l_desc_rec.col_type)
            THEN
                dbms_sql.define_column(c => g_cursor_id, position => i, column => l_my_res_vc, column_size => 1000);
            END IF;
        END LOOP;
    END init_cursor;

    /********************************************************************************************
    * Fetchs the cursor initialized, row per row
    * @param i_cursor               pk_types.cursor_type
    * 
		* @return fetched line number
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    FUNCTION fetch_row RETURN NUMBER IS
        l_aux        VARCHAR2(1000 CHAR);
        l_result_tbl table_varchar_idx;
        l_desc_rec   dbms_sql.desc_rec;
    BEGIN
        --Fetch record
        g_line_number := dbms_sql.fetch_rows(g_cursor_id);
        --reset current result table
        g_result_tbl := l_result_tbl;
    
        IF g_line_number != 0
        THEN
            FOR i IN 1 .. g_num_of_cols
            LOOP
                l_desc_rec := g_desc_table(i);
            
                IF is_supported_type(i_col_type => l_desc_rec.col_type)
                THEN
                    dbms_sql.column_value(c => g_cursor_id, position => i, VALUE => l_aux);
                    g_result_tbl(g_desc_table(i).col_name) := l_aux;
                END IF;
            END LOOP;
        END IF;
    
        RETURN g_line_number;
    END fetch_row;

    /********************************************************************************************
    * Get a value from initialized cursor by column name
    * @param i_column_name            Column name to find and return the value
    * 
		* @return column value
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    FUNCTION get_value(i_column_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN g_result_tbl(i_column_name);
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_value;
    
		/********************************************************************************************
    * Close cursor initialized
    * @param i_cursor               pk_types.cursor_type
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    PROCEDURE close_cursor IS
    
    BEGIN
        IF g_cursor_id IS NOT NULL
        THEN
            dbms_sql.close_cursor(g_cursor_id);
        END IF;
        g_cursor_id := NULL;
    END close_cursor;

BEGIN
    NULL;
END pk_edis_handle_refcursor;
/
