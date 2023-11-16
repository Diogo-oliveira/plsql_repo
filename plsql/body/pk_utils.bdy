/*-- Last Change Revision: $Rev: 2027829 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_utils AS
    g_error VARCHAR2(4000);
    g_language_config CONSTANT sys_config.id_sys_config%TYPE := 'LANGUAGE';

    g_dbid       v$database.dbid%TYPE;
    g_trans_code VARCHAR2(64);
    g_trans_id   VARCHAR2(64);

    k_pl         CONSTANT VARCHAR2(0010 CHAR) := '''';
    k_sp         CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    k_yes        CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_yes;
    k_no         CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_no;
    k_context_id CONSTANT VARCHAR2(0050 CHAR) := 'ALERT_CONTEXT';

    k_mode_inst_name    CONSTANT VARCHAR2(0050 CHAR) := 'MODE_INST_NAME';
    k_mode_inst_address CONSTANT VARCHAR2(0050 CHAR) := 'MODE_INST_ADDRESS';

    TYPE status_record IS RECORD(
        status_msg  VARCHAR2(1000 CHAR),
        status_icon VARCHAR2(1000 CHAR),
        status_flg  VARCHAR2(1000 CHAR),
        status_str  VARCHAR2(4000 BYTE));

    k_soft_name       CONSTANT VARCHAR2(0100 CHAR) := 'MODE_SOFT_NAME';
    k_soft_audit_name CONSTANT VARCHAR2(0100 CHAR) := 'MODE_SOFT_AUDIT_NAME';

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

    /********************************************************************************************
    * This function gets unique code for the current transaction (if no transaction is started it returns null)
    *
    * RETURN                    unique transaction code 
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011/05/18
    ********************************************************************************************/
    FUNCTION get_transaction_code RETURN VARCHAR2 IS
        l_transaction_code VARCHAR2(64 CHAR);
        --l_sql              VARCHAR2(1000 CHAR);
        l_trans_id VARCHAR2(64 CHAR);
        k_system_mask CONSTANT VARCHAR2(0200 CHAR) := 'YYYYMMDDHH24MISS';
        k_custom_mask CONSTANT VARCHAR2(0200 CHAR) := 'MM/DD/YY HH24:MI:SS';
    BEGIN
        l_trans_id := dbms_transaction.local_transaction_id;
    
        IF l_trans_id = g_trans_id
        THEN
            l_transaction_code := g_trans_code;
        ELSE
            <<blk_get_trs_id>>
            BEGIN
                SELECT to_char(start_time, k_system_mask) || '.' || xidusn || '.' || xidslot || '.' || xidsqn
                  INTO l_transaction_code
                  FROM (SELECT to_date(start_time, k_custom_mask) start_time,
                               to_char(xidusn) xidusn,
                               to_char(xidslot) xidslot,
                               to_char(xidsqn) xidsqn
                          FROM v$transaction
                         WHERE to_char(xidusn) || '.' || to_char(xidslot) || '.' || to_char(xidsqn) = l_trans_id) xsql;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_transaction_code := NULL;
            END blk_get_trs_id;
        
            g_trans_id   := l_trans_id;
            g_trans_code := l_transaction_code;
        
        END IF;
    
        RETURN l_transaction_code;
    
    END get_transaction_code;

    /********************************************************************************************
    * This function gets database identifier
    *
    * RETURN                    database id
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011/05/18
    ********************************************************************************************/
    FUNCTION get_dbid RETURN NUMBER IS
        l_dbid NUMBER(24, 0);
    BEGIN
        IF g_dbid IS NULL
        THEN
        
            SELECT dbid
              INTO l_dbid
              FROM v$database;
        
            g_dbid := l_dbid;
        
        END IF;
    
        RETURN g_dbid;
    
    END get_dbid;

    PROCEDURE undo_changes IS
        l_undo_on_error VARCHAR2(1 CHAR);
    BEGIN
    
        l_undo_on_error := alert_context('l_undo_on_error');
    
        IF l_undo_on_error = pk_alert_constant.g_yes
           OR l_undo_on_error IS NULL
        THEN
            ROLLBACK;
        END IF;
    END undo_changes;

    /********************************************************************************************/
    FUNCTION search_table_number
    (
        i_table  IN table_number,
        i_search IN NUMBER
    ) RETURN NUMBER IS
        l_indice NUMBER;
    BEGIN
    
        l_indice := -1;
    
        FOR i IN 1 .. i_table.count
        LOOP
            IF i_table(i) = i_search
            THEN
                l_indice := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_indice;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END search_table_number;

    /********************************************************************************************/
    FUNCTION search_table_varchar
    (
        i_table  IN table_varchar,
        i_search IN VARCHAR2
    ) RETURN NUMBER IS
        l_indice NUMBER;
    BEGIN
    
        l_indice := -1;
    
        FOR i IN 1 .. i_table.count
        LOOP
            IF i_table(i) = i_search
            THEN
                l_indice := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_indice;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END search_table_varchar;

    /**
    * Equivalent to DBMS_OUTPUT.PUT_LINE, but slices I_LINE in chunks of 255 chars to overcome the limit of 255 chars when using BDMS_OUTPUT.PUT_LINE. 
    *
    * @param   I_LINE the string to print
    *
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   26-10-2006 
    */
    PROCEDURE put_line(i_line IN VARCHAR2) IS
        l_counter PLS_INTEGER DEFAULT 1;
        l_length  PLS_INTEGER DEFAULT 1;
        l_line    VARCHAR2(20000);
        k_limit CONSTANT NUMBER(24) := 255;
    BEGIN
        WHILE l_counter <= length(i_line)
        LOOP
            l_line   := substr(i_line, l_counter, k_limit);
            l_length := length(l_line);
        
            dbms_output.put_line(substr(i_line, l_counter, l_length));
            l_counter := l_counter + l_length;
        END LOOP;
    END put_line;

    /**
    * Converts the parameter to a varchar2.
    * Overloads are wellcome.
    * @param variable to convert
    * @return converted text
    */
    FUNCTION to_str(b BOOLEAN) RETURN VARCHAR2 IS
        l_return VARCHAR2(0050 CHAR);
    BEGIN
        l_return := iif(b, 'TRUE', 'FALSE');
    
        RETURN l_return;
    END to_str;

    /*
    * Name says it all
    */
    PROCEDURE reset_sequence
    (
        seq_name   IN VARCHAR2,
        startvalue IN NUMBER DEFAULT 1
    ) AS
    
        cval   NUMBER;
        inc_by VARCHAR2(25);
    
    BEGIN
        dbms_output.put_line('ALTER SEQUENCE ' || seq_name || ' MINVALUE 0'); --
        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || seq_name || ' MINVALUE 0';
    
        dbms_output.put_line('SELECT ' || seq_name || '.NEXTVAL FROM dual'); --
        EXECUTE IMMEDIATE 'SELECT ' || seq_name || '.NEXTVAL FROM dual'
            INTO cval;
    
        cval := cval - startvalue + 1;
        IF cval < 0
        THEN
            inc_by := ' INCREMENT BY ';
            cval   := abs(cval);
        ELSIF cval > 0
        THEN
            inc_by := ' INCREMENT BY -';
        ELSE
            --nothing to do
            RETURN;
        END IF;
    
        dbms_output.put_line('ALTER SEQUENCE ' || seq_name || inc_by || cval); --
        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || seq_name || inc_by || cval;
    
        dbms_output.put_line('SELECT ' || seq_name || '.NEXTVAL FROM dual'); --
        EXECUTE IMMEDIATE 'SELECT ' || seq_name || '.NEXTVAL FROM dual'
            INTO cval;
    
        dbms_output.put_line('ALTER SEQUENCE ' || seq_name || ' INCREMENT BY 1'); --
        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || seq_name || ' INCREMENT BY 1';
    
    END reset_sequence;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all varchar2 in the passed table
    *
    * @param i_tab a object of type 'table or varchar'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table
    (
        i_tab       IN table_varchar,
        i_delim     IN VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN VARCHAR2 IS
        l_string VARCHAR2(32767) := NULL;
        l_length NUMBER;
        l_tab    table_varchar;
    BEGIN
        l_tab := nvl(i_tab, table_varchar());
        IF i_length < 0
        THEN
            l_length := l_tab.count;
        ELSE
            l_length := i_length;
        END IF;
        FOR l_idx IN 1 .. l_tab.count
        LOOP
            IF l_idx BETWEEN i_start_off AND (i_start_off + l_length)
               AND l_tab(l_idx) IS NOT NULL
            THEN
                IF l_string IS NULL
                THEN
                    l_string := l_tab(l_idx);
                ELSE
                    l_string := l_string || i_delim || l_tab(l_idx);
                END IF;
            END IF;
        END LOOP;
        RETURN l_string;
    
    END concat_table;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all varchar2 in the passed table
    *
    * @param i_tab a object of type 'table or varchar'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table
    (
        i_table     IN table_varchar2,
        i_delim     IN VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN VARCHAR2 IS
        l_string VARCHAR2(32767) := NULL;
        l_length NUMBER;
        l_tab    table_varchar2;
    BEGIN
        l_tab := nvl(i_table, table_varchar2());
        IF i_length < 0
        THEN
            l_length := l_tab.count;
        ELSE
            l_length := i_length;
        END IF;
        FOR l_idx IN 1 .. l_tab.count
        LOOP
            IF l_idx BETWEEN i_start_off AND (i_start_off + l_length)
               AND l_tab(l_idx) IS NOT NULL
            THEN
                IF l_string IS NULL
                THEN
                    l_string := l_tab(l_idx);
                ELSE
                    l_string := l_string || i_delim || l_tab(l_idx);
                END IF;
            END IF;
        END LOOP;
        RETURN l_string;
    
    END concat_table;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all numbers in the passed table
    *
    * @param i_tab a object of type 'table or number'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table
    (
        i_tab       IN table_number,
        i_delim     IN VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN VARCHAR2 IS
        l_string VARCHAR2(32767) := NULL;
        --l_length NUMBER;
    
        l_tab table_number;
        vtab  table_varchar;
    BEGIN
        l_tab := nvl(i_tab, table_number());
        SELECT column_value
          BULK COLLECT
          INTO vtab
          FROM TABLE(l_tab);
    
        l_string := concat_table(i_tab => vtab, i_delim => i_delim, i_start_off => i_start_off, i_length => i_length);
    
        RETURN l_string;
    
    END concat_table;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all varchar2 in the passed table
    *
    * @param i_tab a object of type 'table or varchar'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table
    (
        i_tab   IN table_clob,
        i_delim IN VARCHAR2 DEFAULT '|'
    ) RETURN CLOB IS
        l_clob  CLOB := NULL;
        l_error t_error_out;
        l_len   NUMBER;
    BEGIN
        g_error := 'CONCAT TABLE CLOB';
        pk_alertlog.log_debug(g_error);
        dbms_lob.createtemporary(l_clob, TRUE);
    
        FOR l_idx IN 1 .. i_tab.count
        LOOP
            g_error := 'l_idx: ' || l_idx;
            pk_alertlog.log_debug(g_error);
        
            IF i_tab(l_idx) IS NOT NULL
            THEN
            
                IF l_idx = 1
                THEN
                    l_len   := length(i_tab(l_idx));
                    g_error := g_error || '#Len:' || to_char(l_len);
                    dbms_lob.writeappend(l_clob, l_len, i_tab(l_idx));
                ELSE
                    dbms_lob.append(dest_lob => l_clob, src_lob => i_delim);
                    dbms_lob.append(dest_lob => l_clob, src_lob => i_tab(l_idx));
                END IF; -- l_idx = 1
            
            END IF; -- is not null
        
        END LOOP;
        RETURN l_clob;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'CONCAT_TABLE',
                                              l_error);
        
            RETURN NULL;
    END concat_table;

    FUNCTION concat_table_clob
    (
        i_tab   IN table_clob,
        i_delim IN VARCHAR2 DEFAULT '|'
    ) RETURN CLOB IS
        l_clob  CLOB := NULL;
        l_error t_error_out;
        l_len   NUMBER;
    BEGIN
        g_error := 'CONCAT TABLE CLOB';
        pk_alertlog.log_debug(g_error);
        dbms_lob.createtemporary(l_clob, TRUE);
    
        FOR l_idx IN 1 .. i_tab.count
        LOOP
            g_error := 'l_idx: ' || l_idx;
            pk_alertlog.log_debug(g_error);
        
            IF i_tab(l_idx) IS NOT NULL
            THEN
            
                IF l_idx = 1
                THEN
                    --l_len   := length(i_tab(l_idx));
                    g_error := g_error || '#Len:' || to_char(l_len);
                    --dbms_lob.writeappend(l_clob, l_len, i_tab(l_idx));
                    l_clob := i_tab(l_idx);
                ELSE
                    dbms_lob.append(dest_lob => l_clob, src_lob => i_delim);
                    dbms_lob.append(dest_lob => l_clob, src_lob => i_tab(l_idx));
                END IF; -- l_idx = 1
            
            END IF; -- is not null
        
        END LOOP;
        RETURN l_clob;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'CONCAT_TABLE',
                                              l_error);
        
            RETURN NULL;
    END concat_table_clob;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all varchar2 in the passed table.
    * This one uses clobs, for larger amounts of text
    *
    * @param i_tab a object of type 'table or varchar'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table_l
    (
        i_tab       IN table_varchar,
        i_delim     IN VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN CLOB IS
        l_string CLOB := NULL;
        l_delim  CLOB := i_delim;
        l_el     CLOB;
        l_length NUMBER;
        l_tab    table_varchar;
    BEGIN
        l_tab := nvl(i_tab, table_varchar());
        IF i_length < 0
        THEN
            l_length := l_tab.count;
        ELSE
            l_length := i_length;
        END IF;
    
        FOR l_idx IN 1 .. l_tab.count
        LOOP
        
            l_el := l_tab(l_idx);
            IF l_idx BETWEEN i_start_off AND (i_start_off + l_length)
               AND l_el IS NOT NULL
            THEN
                IF l_string IS NULL
                THEN
                    l_string := l_el;
                ELSIF l_el IS NOT NULL
                THEN
                    l_string := l_string || l_delim || l_el;
                END IF;
            END IF;
        END LOOP;
        RETURN l_string;
    END concat_table_l;

    FUNCTION concatenate_list
    (
        p_cursor IN SYS_REFCURSOR,
        p_delim  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(32767);
        l_temp   VARCHAR2(32767);
    BEGIN
    
        LOOP
            FETCH p_cursor
                INTO l_temp;
            EXIT WHEN p_cursor%NOTFOUND;
            IF l_temp IS NOT NULL
            THEN
                l_return := l_return || p_delim || l_temp;
            END IF;
        END LOOP;
        CLOSE p_cursor;
    
        RETURN ltrim(l_return, p_delim);
    END concatenate_list;

    /**
    * String tokenizer
    * for example  str_token('one;two',2,';') returns 'two'
    *
    * @param i_string            text
    * @param i_token             token number
    * @param i_sep               token separator, defaults to ','
    *
    * @return the token, null if the are no more token 
    * @created 19-Jun-2007
    * @author João Sá
    */
    FUNCTION str_token
    (
        i_string IN VARCHAR2, -- input string
        i_token  IN PLS_INTEGER, -- token number
        i_sep    IN VARCHAR2 DEFAULT ',' -- separator character
    ) RETURN VARCHAR2 IS
        l_string VARCHAR2(32767) := i_sep || i_string;
        l_i      PLS_INTEGER;
        l_i2     PLS_INTEGER;
    BEGIN
        --Treat null input values
        IF l_string = ';'
        THEN
            RETURN NULL;
        END IF;
    
        l_i := instr(l_string, i_sep, 1, i_token);
        IF l_i > 0
        THEN
            l_i2 := instr(l_string, i_sep, 1, i_token + 1);
            IF l_i2 = 0
            THEN
                l_i2 := length(l_string) + 1;
            END IF;
            RETURN(substr(l_string, l_i + 1, l_i2 - l_i - 1));
        ELSE
            RETURN NULL;
        END IF;
    END str_token;

    /**
    * Find token in string, for example:
    *  str_token_find('one;two','two',';') returns 'Y'
    *  str_token_find('one;two','three',';') returns 'N'    
    *
    * @param i_string            text
    * @param i_token             token number
    * @param i_sep               token separator, defaults to ','
    *
    * @return 'Y' if the token is found, 'N' otherwise
    * @created 19-Jun-2007
    * @author João Sá
    */
    FUNCTION str_token_find
    (
        i_string IN VARCHAR2,
        i_token  IN VARCHAR2,
        i_sep    IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 IS
        i       PLS_INTEGER := 1;
        l_token VARCHAR2(2000);
    BEGIN
        LOOP
            l_token := pk_utils.str_token(i_string, i, i_sep);
            IF l_token = i_token
            THEN
                RETURN k_yes;
            END IF;
            EXIT WHEN l_token IS NULL;
            i := i + 1;
        END LOOP;
    
        RETURN k_no;
    
    END str_token_find;

    /**
    * Split varchar into mutiple tokens
    * using the delimiter as split point
    *
    * @param p_list the input varchar
    * @param p_delim the delimiter
    * @return a pipelined table_varchar which can be used in a sql query
    * @about http://builder.com.com/5100-6388-5259821.html
    * @since 2.3.6
    */
    FUNCTION str_split_c
    (
        p_list  VARCHAR2,
        p_delim VARCHAR2 := ','
    ) RETURN table_varchar
        PIPELINED IS
        l_idx  PLS_INTEGER;
        l_list VARCHAR2(32767) := p_list;
    BEGIN
        LOOP
            l_idx := instr(l_list, p_delim);
            IF l_idx > 0
            THEN
                PIPE ROW(substr(l_list, 1, l_idx - 1));
                l_list := substr(l_list, l_idx + length(p_delim));
            
            ELSE
                PIPE ROW(l_list);
                EXIT;
            END IF;
        END LOOP;
        RETURN;
    END str_split_c;

    /*********************************************************************************************
    * Split varchar into mutiple tokens
    * using fixed length line
    * 
    * @param i_string  the input varchar
    * @param i_lenght  the length of each line
    *
    * @return a pipelined table_varchar2 which can be used in a sql query
    *
    * @author rui.baeta@alert.pt
    * @date   2007/12/14
    * @since  2.4.2
    * @see    overloads str_split_c(p_list, p_delim)
    ********************************************************************************************/
    FUNCTION str_split_c
    (
        i_string IN VARCHAR2,
        i_lenght IN INTEGER
    ) RETURN table_varchar
        PIPELINED IS
        l_idx        INTEGER;
        l_string_len INTEGER;
        l_string_idx INTEGER;
    BEGIN
        l_string_len := length(i_string);
        l_idx        := 1;
        l_string_idx := 1;
        WHILE l_string_idx < l_string_len
        LOOP
            PIPE ROW(substr(i_string, l_string_idx, i_lenght));
            l_string_idx := l_string_idx + i_lenght;
            l_idx        := l_idx + 1;
        END LOOP;
        RETURN;
    END str_split_c;

    /********************************************************************************
    * Split varchar into mutiple tokens
    * using the delimiter as split point
    *
    * @param i_list the input varchar
    * @param i_delim the delimiter
    *
    * @return a table_varchar
    *
    *
    * @author José Silva
    * @date   2009/10/27
    *********************************************************************************/
    FUNCTION str_split_l
    (
        i_list  VARCHAR2,
        i_delim VARCHAR2 := ' '
    ) RETURN table_varchar IS
    
        l_idx   PLS_INTEGER;
        l_count PLS_INTEGER := 1;
        l_aux   table_varchar := table_varchar();
    
        l_input VARCHAR2(4000);
    
    BEGIN
    
        l_input := i_list;
    
        LOOP
            l_idx := instr(l_input, i_delim);
            IF l_idx > 0
            THEN
                l_aux.extend;
                l_aux(l_count) := substr(l_input, 1, l_idx - 1);
                l_input := substr(l_input, l_idx + length(i_delim));
                l_count := l_count + 1;
            ELSE
                l_aux.extend;
                l_aux(l_count) := l_input;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_aux;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END str_split_l;

    /********************************************************************************
    * Split varchar into using the delimiter as split point. Returns the varchar begining from 
    * the first point the delimiter is found
    *
    * @param i_list the input varchar
    * @param i_delim the delimiter
    *
    * @return a table_varchar
    *
    *
    * @author Sofia Mendes
    * @date   2010/05/18
    *********************************************************************************/
    FUNCTION str_split_first
    (
        i_list  VARCHAR2,
        i_delim VARCHAR2 := ' '
    ) RETURN VARCHAR2 IS
        l_idx PLS_INTEGER;
        --l_aux   VARCHAR2(4000);
        l_input VARCHAR2(4000);
    
    BEGIN
        l_input := i_list;
    
        l_idx := instr(l_input, i_delim);
        IF l_idx > 0
        THEN
            --l_aux   := substr(l_input, 1, l_idx - 1);
            l_input := substr(l_input, l_idx + length(i_delim) - 1);
        END IF;
    
        RETURN l_input;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END str_split_first;

    /*********************************************************************************************
    * Split varchar into mutiple tokens
    * using fixed length line
    * 
    * @param i_string  the input varchar
    * @param i_length  the length of each line
    *
    * @return a table_varchar2 which can be used in pl/sql scope
    *
    * @author rui.baeta@alert.pt
    * @date   2007/12/14
    * @since  2.4.2
    * @see    str_split_c(i_string, i_lenght)
    ********************************************************************************************/
    FUNCTION str_split
    (
        i_string IN VARCHAR2,
        i_length IN INTEGER,
        i_delim  IN VARCHAR2 := ' '
    ) RETURN table_varchar IS
        l_string     VARCHAR2(4000);
        l_table_idx  PLS_INTEGER;
        l_string_len PLS_INTEGER;
        l_string_idx PLS_INTEGER;
        l_split_idx  PLS_INTEGER;
        l_ret        table_varchar := table_varchar();
        l_line       VARCHAR2(0050 CHAR);
    BEGIN
        l_string_len := length(i_string);
        -- optimization
        IF l_string_len <= i_length
        THEN
            l_ret.extend;
            l_ret(1) := TRIM(i_string);
            RETURN l_ret;
        END IF;
    
        l_string     := i_string || i_delim; -- the extra delim (space) is used for last word recognition
        l_string_len := length(l_string);
    
        l_table_idx  := 1;
        l_string_idx := 1;
        WHILE l_string_idx <= l_string_len
        LOOP
            l_line      := substr(l_string, l_string_idx, i_length + 1); -- includes next char, because it might be a delim (space)
            l_split_idx := least(instr(l_line, i_delim, -1), i_length);
            IF l_split_idx = 0
            THEN
                l_split_idx := i_length;
            END IF;
            l_line := substr(l_line, 1, l_split_idx);
            l_ret.extend;
            l_ret(l_table_idx) := TRIM(l_line);
            l_string_idx := l_string_idx + l_split_idx;
            l_table_idx := l_table_idx + 1;
        END LOOP;
        RETURN l_ret;
    END str_split;

    /**
    * Split varchar into mutiple tokens using the delimiter as split point
    *
    * @param i_list              The input varchar
    * @param i_delim             The delimiter
    *   
    * @return                    The resulting tokens
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-06-2009   
    */
    FUNCTION str_split_n
    (
        i_list  VARCHAR2,
        i_delim VARCHAR2 := ','
    ) RETURN table_number IS
        l_idx          PLS_INTEGER;
        l_list         VARCHAR2(32767) := i_list;
        l_count        PLS_INTEGER := 0;
        l_table_number table_number := table_number();
    BEGIN
        IF l_list IS NOT NULL
        THEN
            LOOP
                l_idx := instr(l_list, i_delim);
                IF l_idx > 0
                THEN
                    l_count := l_count + 1;
                
                    l_table_number.extend;
                    l_table_number(l_count) := to_number(substr(l_list, 1, l_idx - 1));
                
                    l_list := substr(l_list, l_idx + length(i_delim));
                
                ELSE
                    l_count := l_count + 1;
                
                    l_table_number.extend;
                    l_table_number(l_count) := to_number(l_list);
                
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_table_number;
    
    END str_split_n;

    /*************************************************************************************************
    * Builds an EPL string for label printing. If i_body_text is too big to fit in a single label,
    * it will be spanned into multiple labels, accordingly to i_format_vars.
    * Special vars @page and @pages may be used in mask strings, for label pagination.
    * 
    * Example invocation:
    * declare
    *   i_label_vars  pk_patient.hashtable_varchar2;
    *   i_format_vars pk_patient.hashtable_varchar2;
    *   i_header_mask varchar2(4000);
    *   i_cont_mask   varchar2(4000);
    *   i_body_text   varchar2(4000);
    *   result  varchar2(4000);
    * begin
    *   i_format_vars('@header_body_lines') := 4;
    *   i_format_vars('@cont_body_lines') := 5;
    *   i_format_vars('@body_text_width') := 33;
    *
    *   i_label_vars('@01') := 'Pedro M. M. Fernandes'; -- name
    *   i_label_vars('@02') := 'M/25'; --sex/age
    *   i_label_vars('@03') := '123456789'; -- episode no.
    *   i_label_vars('@04') := '321654987'; -- process no.
    *   i_label_vars('@05') := to_char(current_timestamp, 'DD-MM-YYYY HH24:MI'); -- date
    *
    *   i_header_mask := chr(10) || 'N' || chr(10) || 'Q184,22' || chr(10) || 'q424' || chr(10) || 'S4' || chr(10) || 'D15' || chr(10) || 'ZT' || chr(10) || 'Rp1,000' || chr(10) || 'I8,3,351' || chr(10) || 'A10,10,0,2,1,1,N,"@01"' || chr(10) || 'A350,10,0,2,1,1,N,"@02"' || chr(10) || 'A10,30,0,2,1,1,N,"@03"' || chr(10) || 'A220,30,0,2,1,1,N,"@04"' || chr(10) || 'A10,60,0,2,1,1,N,"@body01"' || chr(10) || 'A10,80,0,2,1,1,N,"@body02"' || chr(10) || 'A10,100,0,2,1,1,N,"@body03"' || chr(10) || 'A10,120,0,2,1,1,N,"@body04"' || chr(10) || 'A10,150,0,1,1,1,N,"@05"' || chr(10) || 'A350,150,0,1,1,1,N,"@page/@pages"' || chr(10) || 'P1' || chr(10);
    *   i_cont_mask   := chr(10) || 'N' || chr(10) || 'Q184,22' || chr(10) || 'q424' || chr(10) || 'S4' || chr(10) || 'D15' || chr(10) || 'ZT' || chr(10) || 'Rp1,000' || chr(10) || 'I8,3,351' || chr(10) || 'A10,10,0,2,1,1,N,"@01"' || chr(10) || 'A350,10,0,2,1,1,N,"@02"' || chr(10) || 'A10,40,0,2,1,1,N,"@body05"' || chr(10) || 'A10,60,0,2,1,1,N,"@body06"' || chr(10) || 'A10,80,0,2,1,1,N,"@body07"' || chr(10) || 'A10,100,0,2,1,1,N,"@body08"' || chr(10) || 'A10,120,0,2,1,1,N,"@body09"' || chr(10) || 'A10,150,0,1,1,1,N,"@05"' || chr(10) || 'A350,150,0,1,1,1,N,"@page/@pages"' || chr(10) || 'P1' || chr(10);
    *   i_body_text   := 'Alergias: Venenos de origem fungica;Tintas;Amendoim;Sabao;Lixivias;Sprays ambientadores;Chocolate;Polen;Ar condicionado;Fumo de tabaco';
    *
    *   result := pk_patient.build_label_print(i_header_mask => i_header_mask, i_cont_mask => i_cont_mask, i_label_vars => i_label_vars, i_body_text => i_body_text, i_format_vars => i_format_vars);
    *   dbms_output.put_line(result);
    * end;
    *
    *
    * @param i_header_mask mask string for header label
    * @param i_cont_mask mask string for continuation label
    * @param i_label_vars hashtable of varchar2 with variables for replacement in mask string (header and continuation mask)
    * @param i_body_text body text of label (it can be wraped and spanned among multiple continuation labels)
    * @param i_format_vars hashtable of varchar2 with format variables that specify how i_body_text is wraped and spanned:
    *                          @header_body_lines maximum number of lines of text body (header label)
    *                          @cont_body_lines maximum number of lines of text body (continuation label)
    *                          @body_text_width width of body text
    * @return EPL string
    *
    * @author           Rui Baeta
    * @since            2007/12/19
    *************************************************************************************************/
    FUNCTION build_label_print
    (
        i_header_mask IN VARCHAR2,
        i_cont_mask   IN VARCHAR2,
        i_label_vars  IN hashtable_varchar2,
        i_body_text   IN VARCHAR2,
        i_format_vars IN hashtable_varchar2
    ) RETURN VARCHAR2 IS
        -- format vars
        l_header_body_lines INTEGER;
        l_cont_body_lines   INTEGER;
        l_body_text_width   INTEGER;
        --
        l_body_table      table_varchar;
        l_remaining_lines INTEGER;
        l_label_number    INTEGER;
        l_total_labels    INTEGER;
        l_buffer          VARCHAR2(4000);
        l_param           VARCHAR2(10);
        l_body_table_idx  INTEGER;
        l_var_idx         VARCHAR2(4000);
    BEGIN
        -- maximum number of lines of text body (header label)
        l_header_body_lines := to_number(i_format_vars('@header_body_lines'));
        -- maximum number of lines of text body (continuation label)
        l_cont_body_lines := to_number(i_format_vars('@cont_body_lines'));
        -- width of body text
        l_body_text_width := to_number(i_format_vars('@body_text_width'));
    
        -- split i_body_text into an array of varchar2, at specified width
        l_body_table := pk_utils.str_split(i_body_text, l_body_text_width);
    
        -- calculate total number of labels
        l_total_labels    := 1; -- assume header label always exists
        l_remaining_lines := l_body_table.count - l_header_body_lines;
        IF l_remaining_lines > 0
        THEN
            l_total_labels := ceil(l_remaining_lines / l_cont_body_lines) + 1; -- + 1 (count header label too)
        END IF;
    
        -- init buffer with header mask
        l_buffer := i_header_mask;
    
        /*********************
        * print header label
        *********************/
        -- prepare label variables
        l_label_number := 1; -- first label (header)
    
        -- replace body text
        FOR l_body_mask_idx IN 1 .. l_header_body_lines
        LOOP
            l_param          := '@body' || standard.to_char(to_number(l_body_mask_idx), 'FM09');
            l_body_table_idx := l_body_mask_idx;
            IF l_body_table.exists(l_body_mask_idx)
            THEN
                l_buffer := REPLACE(l_buffer, l_param, l_body_table(l_body_table_idx));
            ELSE
                l_buffer := REPLACE(l_buffer, l_param);
            END IF;
        END LOOP;
    
        -- replace all header label vars
        l_var_idx := i_label_vars.first; -- get subscript of first element
        WHILE l_var_idx IS NOT NULL
        LOOP
            --dbms_output.put_line('i_label_vars[' || l_var_idx || '] = ' || i_label_vars(l_var_idx));
            l_buffer  := REPLACE(l_buffer, l_var_idx, i_label_vars(l_var_idx));
            l_var_idx := i_label_vars.next(l_var_idx); -- get subscript of next element
        END LOOP;
        -- label pagination
        l_buffer := REPLACE(l_buffer, '@pages', l_total_labels);
        l_buffer := REPLACE(l_buffer, '@page', l_label_number);
    
        /***************************
        * print continuation labels
        ****************************/
        -- prepare label variables
        l_label_number   := l_label_number + 1; -- next label (cont)    
        l_body_table_idx := l_body_table_idx + 1;
    
        WHILE l_label_number <= l_total_labels
        LOOP
            -- append buffer with cont mask
            l_buffer := l_buffer || i_cont_mask;
        
            -- replace body text
            FOR l_body_mask_idx IN (l_header_body_lines + 1) .. (l_header_body_lines + l_cont_body_lines)
            LOOP
                l_param := '@body' || standard.to_char(l_body_mask_idx, 'FM09');
                IF l_body_table.exists(l_body_table_idx)
                THEN
                    l_buffer := REPLACE(l_buffer, l_param, l_body_table(l_body_table_idx));
                ELSE
                    l_buffer := REPLACE(l_buffer, l_param);
                END IF;
            
                l_body_table_idx := l_body_table_idx + 1;
            END LOOP;
        
            -- replace all header label vars
            l_var_idx := i_label_vars.first; -- get subscript of first element
            WHILE l_var_idx IS NOT NULL
            LOOP
                --dbms_output.put_line('i_label_vars[' || l_var_idx || '] = ' || i_label_vars(l_var_idx));
                l_buffer  := REPLACE(l_buffer, l_var_idx, i_label_vars(l_var_idx));
                l_var_idx := i_label_vars.next(l_var_idx); -- get subscript of next element
            END LOOP;
            -- label pagination
            l_buffer := REPLACE(l_buffer, '@pages', l_total_labels);
            l_buffer := REPLACE(l_buffer, '@page', l_label_number);
        
            l_label_number := l_label_number + 1;
        END LOOP;
    
        RETURN l_buffer;
    END build_label_print;

    /**
    * Function that replaces middle names with initials
    * @param i_name original name
    * @return the new name
    */
    FUNCTION format_middlename(i_name IN patient.name%TYPE) RETURN VARCHAR2 IS
        l_pat_middle_name VARCHAR2(200);
        l_aux_full_name   VARCHAR(200);
        l_aux_middlename  VARCHAR(200);
        l_count           NUMBER;
        l_last_space      NUMBER;
    
        l_result VARCHAR2(4000);
    BEGIN
    
        l_aux_full_name := i_name;
    
        l_pat_middle_name := ' ';
    
        l_count      := 0;
        l_last_space := instr(l_aux_full_name, ' ');
        WHILE l_last_space != 0
        LOOP
            l_aux_full_name := TRIM(substr(l_aux_full_name, l_last_space + 1));
        
            l_count      := l_count + 1;
            l_last_space := instr(l_aux_full_name, ' ');
        
            l_aux_middlename := substr(l_aux_full_name, 0, instr(l_aux_full_name, ' ') - 1);
        
            IF (l_last_space != 0 AND length(l_aux_middlename) > 1 AND
               upper(l_aux_middlename) NOT IN ('DE', 'DO', 'DA'))
            THEN
                l_pat_middle_name := l_pat_middle_name || substr(l_aux_full_name, 0, 1) || '. ';
            END IF;
        END LOOP;
    
        IF l_count > 0
        THEN
            l_result := TRIM(substr(i_name, 0, instr(i_name, ' '))) || l_pat_middle_name || l_aux_full_name;
        ELSE
            l_result := i_name;
        END IF;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_middlename;

    /********************************************************************************************
    * Sends e-mail
    *
    * @param i_mail_from            E-mail from
    * @param i_mail_to              E-mail to
    * @param i_mail_text            E-mail text
    * @param i_mail_subject         E-mail subject
    * @param i_user                 User Object
    
    * @param o_error                Error
                        
    * @return                       true or false on success or error
    * 
    * @author                       José Vilas Boas e Rui de Sousa Neves
    * @since                        2007/07/17
    **********************************************************************************************/

    FUNCTION send_mail
    (
        i_mail_from    IN VARCHAR2,
        i_mail_to      IN VARCHAR2,
        i_mail_text    IN VARCHAR2,
        i_mail_subject IN VARCHAR2,
        i_user         IN profissional,
        i_lang         IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        lv_conn utl_smtp.connection;
        l_subj_encoding  CONSTANT VARCHAR2(50) := 'Subject: =?ISO-8859-15?Q?';
        l_mime           CONSTANT VARCHAR2(50) := 'MIME-version: 1.0';
        l_content_type   CONSTANT VARCHAR2(100) := 'Content-Type: text/html;charset=ISO-8859-15';
        l_content_transf CONSTANT VARCHAR2(100) := 'Content-Transfer-Encoding: quoted-printable ';
        l_from           CONSTANT VARCHAR2(10) := 'From: ';
        l_to             CONSTANT VARCHAR2(10) := 'To: ';
        l_mail_host VARCHAR2(200);
    
    BEGIN
        ---- get the SMTP Server
        l_mail_host := pk_sysconfig.get_config('SMTP_MAIL_HOST', i_user);
        ---- send e-mail
        lv_conn := utl_smtp.open_connection(l_mail_host);
        -- helo
        utl_smtp.helo(lv_conn, l_mail_host);
        -- mail from
        utl_smtp.mail(lv_conn, i_mail_from);
        -- rcpt to
        utl_smtp.rcpt(lv_conn, i_mail_to);
        -- data
        utl_smtp.open_data(lv_conn);
        utl_smtp.write_data(lv_conn,
                            l_subj_encoding ||
                            utl_raw.cast_to_varchar2(utl_encode.quoted_printable_encode(utl_raw.cast_to_raw(i_mail_subject))) || '?=' ||
                            utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, l_mime || utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, l_content_type || utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, l_content_transf || utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, l_from || i_mail_from || utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, l_to || i_mail_to || utl_tcp.crlf);
        utl_smtp.write_data(lv_conn, utl_tcp.crlf);
        utl_smtp.write_raw_data(lv_conn, utl_encode.quoted_printable_encode(utl_raw.cast_to_raw(i_mail_text)));
        utl_smtp.write_data(lv_conn, utl_tcp.crlf);
        -- /data
        utl_smtp.close_data(lv_conn);
        -- quit
        utl_smtp.quit(lv_conn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN utl_smtp.transient_error
             OR utl_smtp.permanent_error THEN
            BEGIN
                utl_smtp.quit(lv_conn);
            EXCEPTION
                WHEN utl_smtp.transient_error
                     OR utl_smtp.permanent_error THEN
                    RETURN pk_alert_exceptions.process_error(i_lang,
                                                             SQLCODE,
                                                             SQLERRM,
                                                             NULL,
                                                             'ALERT',
                                                             'PK_UTILS',
                                                             'SEND_MAIL',
                                                             o_error);
            END;
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     'ALERT',
                                                     'PK_UTILS',
                                                     'SEND_MAIL',
                                                     o_error);
        
    END;

    PROCEDURE host_command(p_command IN VARCHAR2) AS
        LANGUAGE JAVA name 'Hostc.executeCommand (java.lang.String)';

    /**
    * Executes an sql statement and returns all records spaced by a delimiter
    *  query_to_string('select ''a'' from dual union select ''b'' from dual', '|') returns 'a|b'
    *
    * @param i_query             the query to be executed
    * @param i_separator         the separator to be added between the results
    *
    * @return the records returned by the execution of the query 
    * @created 25-Sep-2007
    * @author Eduardo Lourenço
    */
    FUNCTION query_to_string
    (
        i_query     IN VARCHAR2,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_string VARCHAR2(32767);
        l_aux    VARCHAR2(32767);
        l_cursor pk_types.cursor_type;
    BEGIN
        OPEN l_cursor FOR i_query;
        LOOP
            FETCH l_cursor
                INTO l_aux;
            EXIT WHEN l_cursor%NOTFOUND;
        
            l_string := iif(l_string IS NULL, l_aux, (l_string || i_separator || l_aux));
        
        END LOOP;
        CLOSE l_cursor;
    
        RETURN l_string;
    
    END query_to_string;

    /********************************************************************************************
    * Executes an sql statement and returns all records in a CLOB spaced by a delimiter  
    *
    * @param i_query                     SQL query to be executed
    * @param i_separator                 Separator between rows
    *                       
    * @return                            Result as CLOB
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   06-Nov-09
    **********************************************************************************************/
    FUNCTION query_to_clob
    (
        i_query     IN VARCHAR2,
        i_separator IN VARCHAR2
    ) RETURN CLOB IS
        l_first_step BOOLEAN := TRUE;
        l_cursor     pk_types.cursor_type;
        l_aux        VARCHAR2(32767);
        newclob      CLOB;
    BEGIN
    
        dbms_lob.createtemporary(newclob, TRUE);
    
        OPEN l_cursor FOR i_query;
        LOOP
            FETCH l_cursor
                INTO l_aux;
            EXIT WHEN l_cursor%NOTFOUND;
            IF l_first_step = TRUE
            THEN
                dbms_lob.writeappend(newclob, length(l_aux), l_aux);
                l_first_step := FALSE;
            ELSE
                dbms_lob.writeappend(newclob, length(i_separator), i_separator);
                dbms_lob.writeappend(newclob, length(l_aux), l_aux);
            END IF;
        END LOOP;
        CLOSE l_cursor;
    
        RETURN newclob;
    END query_to_clob;

    /**
    * Equivalent to replace function, but this one supports clobs
    *
    * @param the source clob
    * @param replacestr the occurence to search for
    * @param the piece to place in the clob
    * @return the new replaced clob
    */
    FUNCTION replaceclob
    (
        srcclob     IN CLOB,
        replacestr  IN VARCHAR2,
        replacewith IN VARCHAR2
    ) RETURN CLOB IS
    
        vbuffer    VARCHAR2(32767);
        l_amount   BINARY_INTEGER := 32767;
        l_pos      PLS_INTEGER := 1;
        l_clob_len PLS_INTEGER;
        newclob    CLOB := empty_clob;
    
    BEGIN
        -- initalize the new clob
        dbms_lob.createtemporary(newclob, TRUE);
    
        l_clob_len := dbms_lob.getlength(srcclob);
    
        WHILE l_pos < l_clob_len
        LOOP
            --nota: o clob é partido em pedaços de 32767 chars
            --pelo que pode-se há partir ao meio uma das ocorrências
            --que se quer substituir e assim depois não substitui
            dbms_lob.read(srcclob, l_amount, l_pos, vbuffer);
        
            IF vbuffer IS NOT NULL
            THEN
                -- replace the text
                vbuffer := REPLACE(vbuffer, replacestr, replacewith);
                -- write it to the new clob
                dbms_lob.writeappend(newclob, length(vbuffer), vbuffer);
            END IF;
            l_pos := l_pos + l_amount;
        END LOOP;
    
        RETURN newclob;
    END replaceclob;

    /********************************************************************************************
    * Equivalent to replace function, but this one supports clobs as replacement
    *
    * @param srcstr         source string
    * @param splitstr       the occurence to search for
    * @param replacewith    the piece to place in the clob
    * @return               the new replaced clob
    *
    * @date                 2011-10-18
    * @since                2.5.1.8.2
    * @author               marcio.dias
    ********************************************************************************************/
    FUNCTION replace_with_clob
    (
        srcstr      IN VARCHAR2,
        splitstr    IN VARCHAR2,
        replacewith IN CLOB
    ) RETURN CLOB IS
    
        l_list   table_varchar2;
        l_return CLOB;
        l_count  PLS_INTEGER;
    
    BEGIN
        IF srcstr IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_list   := str_split(srcstr, splitstr);
        l_count  := l_list.count;
        l_return := to_clob(l_list(1));
        FOR l_item IN 2 .. l_count
        LOOP
            l_return := l_return || replacewith || to_clob(l_list(l_item));
        END LOOP;
    
        RETURN l_return;
    END replace_with_clob;

    /*********************************************************************************************
    * Split varchar into multiple tokens which can be used in PL/SQL scope
    * 
    * 
    * @param i_list   the input varchar 
    * @param i_delim  the delimiter
    *
    * @return a table_varchar2 
    *
    * @author Ariel Geraldo Machado
    * @date   2008/05/20
    * @since  2.4.3
    * @see    str_split(i_string, i_lenght, i_delim)
    ********************************************************************************************/
    FUNCTION str_split
    (
        i_list  IN VARCHAR2,
        i_delim IN VARCHAR2 DEFAULT ','
    ) RETURN table_varchar2 IS
        l_idx       PLS_INTEGER;
        l_table_idx PLS_INTEGER;
        l_line      VARCHAR2(32767);
        l_list      VARCHAR2(32767) := i_list;
        l_ret       table_varchar2 := table_varchar2();
    BEGIN
    
        IF l_list IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_table_idx := 1;
        LOOP
            l_idx := instr(l_list, i_delim);
            IF l_idx > 0
            THEN
                l_line := substr(l_list, 1, l_idx - 1);
                l_list := substr(l_list, l_idx + length(i_delim));
            ELSE
                l_line := l_list;
            END IF;
            l_ret.extend;
            l_ret(l_table_idx) := TRIM(l_line);
            l_table_idx := l_table_idx + 1;
        
            IF l_idx = 0
               OR l_idx IS NULL
            THEN
                EXIT;
            END IF;
        END LOOP;
        RETURN l_ret;
    END str_split;

    /********************************************************************************************
    * Converts the input text to bold
    * @param i_text                   input text
    *                        
    * @return                         converted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/24
    **********************************************************************************************/
    FUNCTION to_bold(i_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_text IS NOT NULL
        THEN
            RETURN '<b>' || htf.escape_sc(i_text) || '</b>';
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN i_text;
    END to_bold;

    /**
    * Allows changing  a nls_session_parameter while getting the previous result
    *
    * @param i_parameter the parameter name
    * @param i_value the new value
    * @return the previous value
    */
    FUNCTION set_session_parameter
    (
        i_parameter VARCHAR2,
        i_value     VARCHAR2
    ) RETURN VARCHAR2 IS
        o_result VARCHAR2(400);
    BEGIN
        -- Obtém o valor actual para a variável de sessão NLS_...
        SELECT nsp.value
          INTO o_result
          FROM nls_session_parameters nsp
         WHERE nsp.parameter = i_parameter;
    
        -- Define o valor da variável de sessão NLS_... para aquele em i_value
        dbms_session.set_nls(param => i_parameter, VALUE => i_value);
    
        -- Retorna valor anterior para futuro restauro das definições
        RETURN(o_result);
    END set_session_parameter;

    /**
    * Used to build the status string according to the specifications
    * described on Code Convention's document at point 5.13 "Sending
    * tasks status information to Flash"
    *
    * @param      I_DISPLAY_TYPE     Display type
    * @param      I_FLG_STATE        Status flag - value domain
    * @param      I_VALUE_TEXT       Text value - code message
    * @param      I_VALUE_DATE       Date value - date
    * @param      I_VALUE_ICON       Icon value - code domain
    * @param      I_SHORTCUT         Application's shortcut
    * @param      I_BACK_COLOR       Background color
    * @param      I_ICON_COLOR       Icon color
    * @param      I_MESSAGE_STYLE    Message style
    * @param      I_MESSAGE_COLOR    Message color
    * @param      I_FLG_TEXT_DOMAIN  Indicates if text should be used as a sys_domain value 
    * @param      I_DEFAULT_COLOR    Indicates if icon color is to colored in the cellRendered  
    * @param      O_STATUS_STR       Request's status (in specific format)
    * @param      O_STATUS_MSG       Request's status message code
    * @param      O_STATUS_ICON      Request's status icon
    * @param      O_STATUS_FLG       Request's status flag (to return the icon)
    *
    * @value      I_FLG_TEXT_DOMAIN   {*} 'Y' text as a sys_domain value {*} 'N' or NULL text as a sys_message value
    *   
    * @author     Thiago Brito
    * @version    1.0
    * @since      2008-OCT-15
    */
    FUNCTION build_status_string
    (
        i_display_type    IN VARCHAR2,
        i_flg_state       IN VARCHAR2 DEFAULT NULL,
        i_value_text      IN VARCHAR2 DEFAULT NULL,
        i_value_date      IN VARCHAR2 DEFAULT NULL,
        i_value_icon      IN VARCHAR2 DEFAULT NULL,
        i_shortcut        IN VARCHAR2 DEFAULT NULL,
        i_back_color      IN VARCHAR2 DEFAULT NULL,
        i_icon_color      IN VARCHAR2 DEFAULT NULL,
        i_message_style   IN VARCHAR2 DEFAULT NULL,
        i_message_color   IN VARCHAR2 DEFAULT NULL,
        i_flg_text_domain IN VARCHAR2 DEFAULT NULL,
        i_tooltip_text    IN VARCHAR2 DEFAULT NULL,
        i_default_color   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN status_record IS
        l_value_date   VARCHAR2(200);
        l_value_text   VARCHAR2(200);
        l_value_icon   VARCHAR2(200);
        l_tooltip_text VARCHAR2(200);
    
        myrec status_record;
    
        k_status_rpl_chr_text_domain CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_text_domain;
        k_status_rpl_chr_text        CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_text;
        k_status_rpl_chr_icon        CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_icon;
        k_display_type_date          CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_date;
        k_display_type_text          CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_text;
        k_display_type_icon          CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_icon;
        k_display_type_text_icon     CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_text_icon;
        k_display_type_date_icon     CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_date_icon;
        k_display_type_fixed_date    CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_display_type_fixed_date;
        k_status_rpl_chr_fixed_date  CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_fixed_date;
        k_status_rpl_chr_dt_server   CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_dt_server;
        k_sep                        CONSTANT VARCHAR2(0200 CHAR) := '|';
    
    BEGIN
    
        -- <shortcut> "|" <display_type> "|" <date> "|" <text> "|" <icon_name> "|" <back_color> "|"
        -- <message_style> "|" <message_color> "|" <icon_color> "|" <dt_server> "|" <default_color>
        -- "|"<tooltip_message>
    
        CASE i_display_type
            WHEN k_display_type_date THEN
                -- date
                myrec.status_msg  := '';
                myrec.status_icon := '';
                myrec.status_flg  := '';
            
                l_value_date   := i_value_date;
                l_value_text   := '';
                l_value_icon   := '';
                l_tooltip_text := i_tooltip_text;
            WHEN k_display_type_text THEN
                -- text
                myrec.status_msg  := i_value_text;
                myrec.status_icon := '';
                myrec.status_flg  := iif(i_flg_text_domain = k_yes, i_flg_state, NULL);
            
                l_value_date := '';
                l_value_text := iif(i_flg_text_domain = k_yes, k_status_rpl_chr_text_domain, k_status_rpl_chr_text);
                l_value_icon := '';
            WHEN k_display_type_icon THEN
                -- icon
                myrec.status_msg  := '';
                myrec.status_icon := i_value_icon;
                myrec.status_flg  := i_flg_state;
            
                l_value_date   := '';
                l_value_text   := '';
                l_value_icon   := k_status_rpl_chr_icon;
                l_tooltip_text := i_tooltip_text; --tooltip
            WHEN k_display_type_text_icon THEN
                -- text + icon
                myrec.status_msg  := i_value_text;
                myrec.status_icon := i_value_icon;
                myrec.status_flg  := i_flg_state;
            
                l_value_date := '';
                l_value_text := k_status_rpl_chr_text;
                l_value_icon := k_status_rpl_chr_icon;
            WHEN k_display_type_date_icon THEN
                -- date + icon
                myrec.status_msg  := '';
                myrec.status_icon := i_value_icon;
                myrec.status_flg  := i_flg_state;
            
                l_value_date   := i_value_date;
                l_value_text   := '';
                l_value_icon   := k_status_rpl_chr_icon;
                l_tooltip_text := i_tooltip_text; --tooltip
            WHEN k_display_type_fixed_date THEN
                -- fixed date
                myrec.status_msg  := i_value_date;
                myrec.status_icon := '';
                myrec.status_flg  := '';
            
                l_value_date := '';
                l_value_text := k_status_rpl_chr_fixed_date;
                l_value_icon := '';
            ELSE
                myrec.status_msg  := '';
                myrec.status_icon := '';
                myrec.status_flg  := '';
            
                l_value_date := '';
                l_value_text := '';
                l_value_icon := '';
        END CASE;
    
        myrec.status_str := i_shortcut || k_sep || i_display_type || k_sep || l_value_date || k_sep || l_value_text ||
                            k_sep || l_value_icon || k_sep || i_back_color || k_sep || i_message_style || k_sep ||
                            i_message_color || k_sep || i_icon_color || k_sep || k_status_rpl_chr_dt_server || k_sep ||
                            i_default_color || k_sep || l_tooltip_text;
    
        RETURN myrec;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END build_status_string;

    PROCEDURE build_status_string
    (
        i_display_type    IN VARCHAR2,
        i_flg_state       IN VARCHAR2 DEFAULT NULL,
        i_value_text      IN VARCHAR2 DEFAULT NULL,
        i_value_date      IN VARCHAR2 DEFAULT NULL,
        i_value_icon      IN VARCHAR2 DEFAULT NULL,
        i_shortcut        IN VARCHAR2 DEFAULT NULL,
        i_back_color      IN VARCHAR2 DEFAULT NULL,
        i_icon_color      IN VARCHAR2 DEFAULT NULL,
        i_message_style   IN VARCHAR2 DEFAULT NULL,
        i_message_color   IN VARCHAR2 DEFAULT NULL,
        i_flg_text_domain IN VARCHAR2 DEFAULT NULL,
        i_tooltip_text    IN VARCHAR2 DEFAULT NULL,
        i_default_color   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status_str      OUT VARCHAR2,
        o_status_msg      OUT VARCHAR2,
        o_status_icon     OUT VARCHAR2,
        o_status_flg      OUT VARCHAR2
    ) IS
    
        myrec status_record;
    
        --l_value_date VARCHAR2(200);
        --l_value_text VARCHAR2(200);
        --l_value_icon VARCHAR2(200);
    BEGIN
    
        myrec := build_status_string(i_display_type    => i_display_type,
                                     i_flg_state       => i_flg_state,
                                     i_value_text      => i_value_text,
                                     i_value_date      => i_value_date,
                                     i_value_icon      => i_value_icon,
                                     i_shortcut        => i_shortcut,
                                     i_back_color      => i_back_color,
                                     i_icon_color      => i_icon_color,
                                     i_message_style   => i_message_style,
                                     i_message_color   => i_message_color,
                                     i_flg_text_domain => i_flg_text_domain,
                                     i_default_color   => i_default_color,
                                     i_tooltip_text    => i_tooltip_text);
    
        o_status_msg  := myrec.status_msg;
        o_status_icon := myrec.status_icon;
        o_status_flg  := myrec.status_flg;
        o_status_str  := myrec.status_str;
    
    END build_status_string;

    /**
    * Returns status string ready to be sent to the Flash layer.
    *
    * @param      I_LANG          Preferred language ID
    * @param      I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param      I_STATUS_STR    Request's status (in specific format)
    * @param      I_STATUS_MSG    Request's status message code
    * @param      I_STATUS_ICON   Request's status icon
    * @param      I_STATUS_FLG    Request's status flag (to return the icon)
    * @param      I_SHORTCUT      Shortcut ID (OPTIONAL)
    * @param      I_DT_SERVER     Current date server (OPTIONAL)
    * @param      O_ERROR         Error message
    *
    * @return     varchar2
    * @author     Tiago Silva
    * @version    1.0
    * @since      2008/15/10
    * @notes
    */
    FUNCTION get_status_string
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_status_str  IN VARCHAR2,
        i_status_msg  IN VARCHAR2,
        i_status_icon IN VARCHAR2,
        i_status_flg  IN VARCHAR2,
        i_shortcut    IN VARCHAR2 DEFAULT NULL,
        i_dt_server   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
        l_rank             NUMBER(24);
        l_aux1             VARCHAR2(0050 CHAR); --ALERT-26475
        l_aux2             VARCHAR2(0030 CHAR);
        l_final_status_str VARCHAR2(0500 CHAR);
        l_icon             VARCHAR2(0500 CHAR);
        l_date             VARCHAR2(0500 CHAR);
        l_msg              VARCHAR2(4000 BYTE);
        l_tmp              VARCHAR2(1000 CHAR);
        l_dt_send_tsz      VARCHAR2(0200 CHAR);
        l_domain           VARCHAR2(1000 CHAR);
        k_tsz_mask                   CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_dt_yyyymmddhh24miss_tzr;
        k_status_rpl_chr_text        CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_text;
        k_status_rpl_chr_text_domain CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_text_domain;
        k_status_rpl_chr_icon        CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_icon;
        k_status_rpl_chr_fixed_date  CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_fixed_date;
        k_status_rpl_chr_dt_server   CONSTANT VARCHAR2(0200 CHAR) := pk_alert_constant.g_status_rpl_chr_dt_server;
    BEGIN
    
        -- convert date to professional timezone
    
        l_final_status_str := i_status_str;
        l_aux1             := pk_utils.str_token(i_status_str, 3, '|');
    
        IF l_aux1 IS NOT NULL
        THEN
            l_aux2             := pk_date_utils.date_send_tsz(i_lang, to_timestamp_tz(l_aux1, k_tsz_mask), i_prof);
            l_final_status_str := REPLACE(l_final_status_str, l_aux1, l_aux2);
        END IF;
    
        l_icon := pk_sysdomain.get_img(i_lang, i_status_icon, i_status_flg);
    
        -- if i_status_msg is an invalid date then an exception will be thrown
        BEGIN
            l_date := pk_date_utils.dt_chr_year_short_tsz(i_lang, to_timestamp_tz(i_status_msg, k_tsz_mask), i_prof);
        EXCEPTION
            WHEN OTHERS THEN
                l_date := '';
        END;
    
        -- replace text and icon fields according to preferred language
        -- replace also the current server date
    
        -- text domain
        l_domain := pk_sysdomain.get_domain(i_status_msg, i_status_flg, i_lang);
        l_tmp    := REPLACE(l_final_status_str, k_status_rpl_chr_text_domain, l_domain);
        -- text_message
        l_msg := nvl(pk_message.get_message(i_lang, i_status_msg), i_status_msg);
        l_tmp := REPLACE(l_tmp, k_status_rpl_chr_text, l_msg);
    
        -- icon
        l_tmp := REPLACE(l_tmp, k_status_rpl_chr_icon, l_icon);
    
        -- fixed date (text)
        l_tmp := REPLACE(l_tmp, k_status_rpl_chr_fixed_date, l_date);
    
        -- server date
        l_rank             := pk_sysdomain.get_rank(i_lang, i_status_icon, i_status_flg);
        l_dt_send_tsz      := pk_date_utils.date_send_tsz(i_lang, i_dt_server, i_prof);
        l_final_status_str := REPLACE(l_tmp, k_status_rpl_chr_dt_server, l_dt_send_tsz || '|' || l_rank);
    
        -- concatenate shortcut ID if it exists                     
        RETURN i_shortcut || l_final_status_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_status_string;

    /**
    * Returns status string ready to be sent to the Flash layer.
    * This function calculates all the status string in runtime.
    *
    * @param      I_LANG             Preferred language ID
    * @param      I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param      I_DISPLAY_TYPE     Display type
    * @param      I_FLG_STATE        Status flag - value domain
    * @param      I_VALUE_TEXT       Text value - code message
    * @param      I_VALUE_DATE       Date value - date
    * @param      I_VALUE_ICON       Icon value - code domain
    * @param      I_SHORTCUT         Application's shortcut
    * @param      I_BACK_COLOR       Background color
    * @param      I_ICON_COLOR       Icon color
    * @param      I_MESSAGE_STYLE    Message style
    * @param      I_MESSAGE_COLOR    Message color
    * @param      I_FLG_TEXT_DOMAIN  Indicates if text should be used as a sys_domain value
    * @param      I_DEFAULT_COLOR    Indicates if icon color is to colored in the cellRendered  
    * @param      I_DT_SERVER        Current date server (OPTIONAL)
    * @param      O_ERROR            Error message
    *
    * @value      I_FLG_TEXT_DOMAIN   {*} 'Y' text as a sys_domain value {*} 'N' or NULL text as a sys_message value
    *
    * @return     varchar2
    * @author     Tiago Silva
    * @version    1.0
    * @since      2008/10/11
    * @notes
    */
    FUNCTION get_status_string_immediate
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_display_type    IN VARCHAR2,
        i_flg_state       IN VARCHAR2 DEFAULT NULL,
        i_value_text      IN VARCHAR2 DEFAULT NULL,
        i_value_date      IN VARCHAR2 DEFAULT NULL,
        i_value_icon      IN VARCHAR2 DEFAULT NULL,
        i_shortcut        IN VARCHAR2 DEFAULT NULL,
        i_back_color      IN VARCHAR2 DEFAULT NULL,
        i_icon_color      IN VARCHAR2 DEFAULT NULL,
        i_message_style   IN VARCHAR2 DEFAULT NULL,
        i_message_color   IN VARCHAR2 DEFAULT NULL,
        i_flg_text_domain IN VARCHAR2 DEFAULT NULL,
        i_tooltip_text    IN VARCHAR2 DEFAULT NULL,
        i_default_color   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_server       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
    
        l_status_str          VARCHAR2(200);
        l_status_msg          VARCHAR2(200);
        l_status_icon         VARCHAR2(200);
        l_status_flg          VARCHAR2(200);
        l_final_status_string VARCHAR2(200);
    
    BEGIN
    
        -- build status string
        build_status_string(i_display_type    => i_display_type,
                            i_flg_state       => i_flg_state,
                            i_value_text      => i_value_text,
                            i_value_date      => i_value_date,
                            i_value_icon      => i_value_icon,
                            i_shortcut        => i_shortcut,
                            i_back_color      => i_back_color,
                            i_icon_color      => i_icon_color,
                            i_message_style   => i_message_style,
                            i_message_color   => i_message_color,
                            i_flg_text_domain => i_flg_text_domain,
                            i_default_color   => i_default_color,
                            i_tooltip_text    => i_tooltip_text,
                            o_status_str      => l_status_str,
                            o_status_msg      => l_status_msg,
                            o_status_icon     => l_status_icon,
                            o_status_flg      => l_status_flg);
    
        -- prepare status string to be sent to the Flash layer
        l_final_status_string := get_status_string(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_status_str  => l_status_str,
                                                   i_status_msg  => l_status_msg,
                                                   i_status_icon => l_status_icon,
                                                   i_status_flg  => l_status_flg,
                                                   i_dt_server   => i_dt_server);
    
        RETURN l_final_status_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_status_string_immediate;

    /**
    * Returns the client identifier string from v$session.
    *
    * @return     varchar2
    * @author     Rui Spratley
    * @version    2.5.0.1
    * @since      2009/04/13
    * @notes
    */

    FUNCTION get_client_id RETURN VARCHAR2 IS
        l_res VARCHAR2(4000);
    BEGIN
    
        l_res := sys_context('userenv', 'client_identifier');
    
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_client_id;

    /*********************************************************************************************
    * Converts a numeric value into a string, leading-zeros-safe for numbers between 0 and 1.
    * 
    * @param         i_number  A number
    *
    * @return        String with the corresponding value
    *
    * @author        Joao Martins
    * @version       2.5.0.5
    * @date          2009/07/22
    ********************************************************************************************/
    FUNCTION to_str
    (
        i_number         IN NUMBER,
        i_decimal_symbol IN VARCHAR2,
        i_mask           IN VARCHAR2 DEFAULT 'FM9999999D999'
    ) RETURN VARCHAR2 IS
        l_abs    NUMBER; --(24);
        l_bool   BOOLEAN;
        l_return VARCHAR2(1000 CHAR);
        k_pl    CONSTANT VARCHAR2(0010 CHAR) := '''';
        k_parms CONSTANT VARCHAR2(0200 CHAR) := 'NLS_NUMERIC_CHARACTERS=' || k_pl || i_decimal_symbol || k_sp || k_pl;
    BEGIN
    
        l_bool := round(LEFT => i_number, RIGHT => 0) = i_number;
    
        IF l_bool
        THEN
            l_return := to_char(RIGHT => i_number);
        ELSE
        
            l_abs := abs(n => i_number);
            IF l_abs BETWEEN 0 AND 1
            THEN
            
                l_return := '0' || to_char(LEFT => l_abs, format => i_mask, parms => k_parms);
                l_return := REPLACE(srcstr => sign(n => i_number), oldsub => '1', newsub => NULL) || l_return;
            
            ELSE
            
                l_return := to_char(LEFT => i_number, format => i_mask, parms => k_parms);
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END to_str;

    /********************************************/
    FUNCTION to_str
    (
        i_number IN NUMBER,
        i_prof   IN profissional DEFAULT profissional(NULL, 0, 0),
        i_mask   IN VARCHAR2 DEFAULT 'FM9999999D999'
    ) RETURN VARCHAR2 IS
        l_decimal_point VARCHAR2(0200 CHAR);
        l_return        VARCHAR2(0500 CHAR);
        k_id_config CONSTANT VARCHAR2(0200 CHAR) := 'DECIMAL_SYMBOL';
    BEGIN
    
        l_decimal_point := pk_sysconfig.get_config(i_code_cf   => k_id_config,
                                                   i_prof_inst => i_prof.institution,
                                                   i_prof_soft => i_prof.software);
    
        l_return := to_str(i_number => i_number, i_decimal_symbol => l_decimal_point, i_mask => i_mask);
    
        RETURN l_return;
    
    END to_str;

    /*********************************************************************************************
    * Removes the accentuation of a String converted to UPPER case
    * 
    * @param         i_input  The string to be transformed
    *
    * @return        String with the accentuation remove
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/07/28
    ********************************************************************************************/
    FUNCTION remove_upper_accentuation(i_input IN VARCHAR2) RETURN VARCHAR2 IS
        k_with_accent CONSTANT VARCHAR2(0200 CHAR) := 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ';
        k_no_accent   CONSTANT VARCHAR2(0200 CHAR) := 'AEIOUAEIOUAEIOUAOCAEIOUN';
    BEGIN
        RETURN translate(upper(i_input), k_with_accent, k_no_accent);
    END remove_upper_accentuation;

    /*********************************************************************************************
    * Returns the institution name translated to the user language
    *
    * @param         i_lang                user language
    * @param         i_id_institution      institution ID
    *
    * @return        institution name translated
    *
    * @author        João Martins
    * @version       2.5.0.6
    * @date          2009/09/07
    ********************************************************************************************/
    FUNCTION get_institution_base
    (
        i_mode           IN VARCHAR2,
        i_lang           IN NUMBER,
        i_id_institution IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_name           table_varchar;
        l_institution_name pk_translation.t_desc_translation;
    BEGIN
    
        SELECT CASE i_mode
                   WHEN k_mode_inst_name THEN
                    pk_translation.get_translation(i_lang, i.code_institution)
                   WHEN k_mode_inst_address THEN
                    i.address || k_sp || i.zip_code || k_sp || i.district
                   ELSE
                    NULL
               END
          BULK COLLECT
          INTO tbl_name
          FROM institution i
         WHERE i.id_institution = i_id_institution;
    
        IF tbl_name.count > 0
        THEN
            l_institution_name := tbl_name(1);
        END IF;
    
        RETURN l_institution_name;
    
        --    END IF;
    
    END get_institution_base;

    /**************************************************************************************/
    FUNCTION get_institution_name
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        --tbl_name           table_varchar;
        l_institution_name pk_translation.t_desc_translation;
    BEGIN
    
        l_institution_name := get_institution_base(i_mode           => k_mode_inst_name,
                                                   i_lang           => i_lang,
                                                   i_id_institution => i_id_institution);
    
        RETURN l_institution_name;
    
    END get_institution_name;

    /*********************************************************************************************
    * Returns the institution name translated to the user language
    * 
    * @param         i_lang                user language
    * @param         i_id_institution      institution ID
    *
    * @param         o_instit_name         institution name translated
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Fábio Oliveira
    * @version       2.5.0.6
    * @date          2009/08/21
    ********************************************************************************************/
    FUNCTION get_institution_name
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_instit_name    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_instit_name := get_institution_name(i_lang => i_lang, i_id_institution => i_id_institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => '',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_UTILS',
                                              i_function => 'GET_INSTITUTION_NAME',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_institution_name;

    /*********************************************************************************************
    * Returns the software name translated to the user language
    * 
    * @param         i_lang                user language
    * @param         i_id_software         software ID
    *
    * @param         o_soft_name           software name translated
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Fábio Oliveira
    * @version       2.5.0.6
    * @date          2009/08/21
    ********************************************************************************************/
    FUNCTION get_software_base
    (
        i_mode        IN VARCHAR2,
        i_lang        IN language.id_language%TYPE,
        i_id_software IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        tbl_name        table_varchar;
        l_software_name pk_translation.t_desc_translation;
    BEGIN
    
        SELECT CASE i_mode
                   WHEN k_soft_name THEN
                    s.name
                   WHEN k_soft_audit_name THEN
                    pk_translation.get_translation(i_lang, s.code_software_audit)
                   ELSE
                    NULL
               END xdesc
          BULK COLLECT
          INTO tbl_name
          FROM software s
         WHERE s.id_software = i_id_software;
    
        IF tbl_name.count > 0
        THEN
            l_software_name := tbl_name(1);
        END IF;
    
        RETURN l_software_name;
    
    END get_software_base;

    /*********************************************************************************************
    * Returns the software name translated to the user language
    * 
    * @param         i_lang                user language
    * @param         i_id_software         software ID
    *
    * @return        software name translated
    *
    * @author        Sérgio Santos
    * @version       2.5.0.7.2
    * @date          2009/11/09
    ********************************************************************************************/
    FUNCTION get_software_name
    (
        i_lang        IN language.id_language%TYPE,
        i_id_software IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_software_name pk_translation.t_desc_translation;
    BEGIN
    
        l_software_name := get_software_base(k_soft_name, i_lang, i_id_software);
    
        RETURN l_software_name;
    
    END get_software_name;

    FUNCTION get_software_name
    (
        i_lang        IN language.id_language%TYPE,
        i_id_software IN software.id_software%TYPE,
        o_soft_name   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_soft_name := get_software_name(i_lang => i_lang, i_id_software => i_id_software);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => '',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_UTILS',
                                              i_function => 'GET_SOFTWARE_NAME',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_software_name;

    /*********************************************************************************************
    * Prints PROFISSIONAL type information
    * 
    * @param i_input      Variable of PROFESSIONAL type
    *
    * @return             String with the PROFESSIONAL information
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/08/24
    ********************************************************************************************/
    FUNCTION to_string(i_input IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'ID:' || i_input.id || ', INSTITUTION:' || i_input.institution || ', SOFTWARE:' || i_input.software;
    END to_string;

    /*********************************************************************************************
    * Prints TABLE_VARCHAR content
    * 
    * @param i_input      Variable of TABLE_VARCHAR type
    *
    * @return             VARCHAR2 with the TABLE_VARCHAR information (BE AWARE OF VARCHAR2 MAX CAPACITY)
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/08/24
    ********************************************************************************************/
    FUNCTION to_string(i_input IN table_varchar) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
    BEGIN
        IF i_input IS NULL
        THEN
            l_result := 'NULL';
        ELSIF i_input.count = 0
        THEN
            l_result := ' ';
        ELSE
            FOR i IN 1 .. i_input.count
            LOOP
                l_result := l_result || i_input(i) || '; ';
            END LOOP;
        END IF;
    
        RETURN l_result;
    END to_string;

    /*********************************************************************************************
    * Prints TABLE_NUMBER content (BE AWARE OF VARCHAR2 MAX CAPACITY)
    * 
    * @param i_input      Variable of TABLE_NUMBER type
    *
    * @return             VARCHAR2 with the TABLE_NUMBER information
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/08/24
    ********************************************************************************************/
    FUNCTION to_string(i_input IN table_number) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
        tbl      table_varchar;
    BEGIN
    
        SELECT column_value
          BULK COLLECT
          INTO tbl
          FROM TABLE(i_input);
    
        l_result := to_string(i_input => tbl);
    
        RETURN l_result;
    
    END to_string;

    /********************************************************************************************
    * Sort table_varchar
    *
    * @param i_table             table to sort (alphabetically)
    *
    * @return                    sorted table
    *
    * @author                    Pedro Teixeira
    * @since                     2009/10/14
    ********************************************************************************************/
    FUNCTION sort_table_varchar(i_table IN table_varchar) RETURN table_varchar IS
        l_sorted_table table_varchar;
    BEGIN
        IF i_table.count != 0
        THEN
            SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
             *
              BULK COLLECT
              INTO l_sorted_table
              FROM TABLE(i_table) t
             ORDER BY 1;
        END IF;
    
        RETURN l_sorted_table;
    END sort_table_varchar;

    /********************************************************************************************
    * Returns all available icons for VIP patients
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param o_vip_icons           Cursor with VIP icons
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @since                       2010/01/25
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_vip_icons
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vip_icons OUT NOCOPY pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_adt.get_vip_icons(i_lang      => i_lang,
                                       i_prof      => i_prof,
                                       o_vip_icons => o_vip_icons,
                                       o_error     => o_error);
    
        RETURN l_bool;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_VIP_ICONS',
                                              o_error);
            --
            pk_types.open_my_cursor(o_vip_icons);
            RETURN FALSE;
        
    END get_vip_icons;

    /********************************************************************************************
    * Gets the market associated with a given instituition
    *
    * @param i_lang              language id
    * @param i_id_institution    professional (id, institution, software)   
    *
    * @return                    market id 
    *
    * @author                    José Silva
    * @version                   2.6
    * @since                     19/02/2010
    ********************************************************************************************/
    FUNCTION get_institution_market
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN market.id_market%TYPE IS
        l_id_market market.id_market%TYPE;
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        RETURN l_id_market;
    
    END get_institution_market;

    FUNCTION get_institution_language
    (
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE DEFAULT 0
    ) RETURN language.id_language%TYPE IS
        l_software CONSTANT software.id_software%TYPE := 0;
        l_return VARCHAR2(4000);
    BEGIN
        l_return := pk_sysconfig.get_config(g_language_config, i_institution, nvl(i_software, l_software));
        RETURN l_return;
    END get_institution_language;

    /**********************************************************************************************
    * Function to return a list of IDs of sibling institutions.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids                
    * @param o_list                   array with institutions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        2.5.0.6 
    * @since                          2009/09/29
    **********************************************************************************************/
    FUNCTION get_institution_parent(i_inst IN NUMBER) RETURN NUMBER IS
        l_id_parent NUMBER(24);
        tbl_ids     table_number;
    BEGIN
    
        pk_alertlog.log_debug('GET INSTITUTIONS');
        SELECT nvl(i.id_parent, i.id_institution)
          BULK COLLECT
          INTO tbl_ids
          FROM institution i
         WHERE i.id_institution = i_inst;
    
        IF tbl_ids.count > 0
        THEN
            l_id_parent := tbl_ids(1);
        END IF;
    
        RETURN l_id_parent;
    
    END get_institution_parent;

    /*******************************************************************************/
    FUNCTION get_institutions_sib
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_inst institution.id_institution%TYPE;
    
    BEGIN
    
        l_start_inst := get_institution_parent(i_inst => i_inst);
    
        -- Get all institution in the tree starting with root
        g_error := 'GET INSTITUTIONS';
        pk_alertlog.log_debug(g_error);
        SELECT inst
          BULK COLLECT
          INTO o_list
          FROM (SELECT i.id_institution inst
                  FROM institution i
                 START WITH i.id_institution = l_start_inst
                CONNECT BY PRIOR i.id_institution = i.id_parent) data;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_RELATED_INSTITUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END get_institutions_sib;

    /**********************************************************************************************
    * Function to return a list of IDs of sibling institutions.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids                
    * @param i_parent                 ID of parent
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        2.5.0.6 
    * @since                          2009/09/29
    **********************************************************************************************/
    FUNCTION get_institution_parent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_inst   IN institution.id_institution%TYPE,
        o_parent OUT institution.id_institution%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_parent := get_institution_parent(i_inst => i_inst);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_RELATED_INSTITUTIONS',
                                              o_error);
        
            RETURN FALSE;
    END get_institution_parent;

    /***************************************************************************/
    FUNCTION get_institution_parent
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_inst IN institution.id_institution%TYPE
    ) RETURN institution.id_institution%TYPE IS
    BEGIN
    
        RETURN get_institution_parent(i_inst => i_inst);
    
    END get_institution_parent;

    /*********************************************************************************************
    * Converts char to number according DECIMAL_SYMBOL and GROUPING_SYMBOL setup
    * 
    * @param i_prof       Profissional type
    * @param i_input      VARCHAR with numeric value
    *
    * @return             NUMBER
    *
    * @author        Nuno Ferreira
    * @version       2.5.0.7
    * @date          2009/12/09
    ********************************************************************************************/
    FUNCTION get_nls_decimal_symb(i_prof IN profissional) RETURN VARCHAR2 IS
        l_decimal_symb sys_config.value%TYPE;
        l_nls_str      VARCHAR2(0500 CHAR);
    BEGIN
    
        l_decimal_symb := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
    
        l_nls_str := 'NLS_NUMERIC_CHARACTERS=' || k_pl || l_decimal_symb || k_sp || k_pl;
    
        RETURN l_nls_str;
    
    END get_nls_decimal_symb;

    FUNCTION char_to_number
    (
        i_prof  IN profissional,
        i_input IN VARCHAR2
    ) RETURN NUMBER IS
        --l_decimal_symb sys_config.value%TYPE;
        l_ret     NUMBER;
        l_nls_str VARCHAR2(0500 CHAR);
        --l_pl          CONSTANT VARCHAR2(0020 CHAR) := '''';
        k_number_mask CONSTANT VARCHAR2(0500 CHAR) := 'FM999999999999999999999999D9999999999';
    
    BEGIN
        l_nls_str := get_nls_decimal_symb(i_prof => i_prof);
        l_ret     := to_number(i_input, k_number_mask, l_nls_str);
    
        RETURN l_ret;
    END char_to_number;

    /********************************************************************************************
    * This function converts a number to char, according DECIMAL_SYMBOL and GROUPING_SYMBOL configs
    *
    * @param i_lang          Input - Language ID
    * @param i_input         Input - Number to convert
    *
    * @return                Return converted number in string format
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5.0.7.6.1
    * @since                 2010/02/06
    ********************************************************************************************/
    FUNCTION number_to_char
    (
        i_prof  IN profissional,
        i_input IN NUMBER
    ) RETURN VARCHAR2 IS
        l_decimal_symb sys_config.value%TYPE;
        l_aux_char     VARCHAR2(30);
        l_nls_str      VARCHAR2(0500 CHAR);
        k_number_mask CONSTANT VARCHAR2(0500 CHAR) := 'FM999999999999999999999990D9999999999';
    BEGIN
    
        l_decimal_symb := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
        l_nls_str      := get_nls_decimal_symb(i_prof => i_prof);
        l_aux_char     := to_char(i_input, k_number_mask, l_nls_str);
    
        IF substr(l_aux_char, -1) = l_decimal_symb
        THEN
            l_aux_char := substr(l_aux_char, 1, length(l_aux_char) - 1);
        END IF;
    
        RETURN l_aux_char;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END number_to_char;

    /************************************************************************************************************ 
    * Public Function.  Verificar se uma string é numérica.   
    *
    * @param      char_in               string
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2006/08/19
    ***********************************************************************************************************/
    FUNCTION is_number(char_in VARCHAR2) RETURN VARCHAR2 IS
        n NUMBER(24);
        k_pattern CONSTANT VARCHAR2(0200 CHAR) := '^[[:digit:]]*[.,]?[[:digit:]]+$';
        l_return VARCHAR2(0010 CHAR);
    BEGIN
    
        n := regexp_instr(char_in, k_pattern);
    
        l_return := iif(n = 1, k_yes, k_no);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN k_no;
    END is_number;

    /*********************************************************************************************
    * Returns the software name (for audit purposes) translated to the user language
    * 
    * @param         i_lang                user language
    * @param         i_id_software         software ID
    *
    * @param         o_soft_name           software name translated
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Rui Batista
    * @version       2.6.0.3
    * @date          2010/06/15
    ********************************************************************************************/
    FUNCTION get_software_audit_name
    (
        i_lang        IN language.id_language%TYPE,
        i_id_software IN software.id_software%TYPE,
        o_soft_name   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_software_name pk_translation.t_desc_translation;
    BEGIN
    
        l_software_name := get_software_base(k_soft_audit_name, i_lang, i_id_software);
    
        o_soft_name := l_software_name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_UTILS',
                                              i_function => 'GET_SOFTWARE_AUDIT_NAME',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_software_audit_name;

    /**
    * Get the UX numeric input mask for a given database table column.
    *
    * @param i_prof         logged professional structure
    * @param i_owner        table owner
    * @param i_table        table name
    * @param i_column       column name
    *
    * @return               UX numeric input mask
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.3
    * @since                2010/11/24
    */
    FUNCTION get_numeric_input_mask
    (
        i_prof   IN profissional,
        i_owner  IN all_tab_columns.owner%TYPE,
        i_table  IN all_tab_columns.table_name%TYPE,
        i_column IN all_tab_columns.column_name%TYPE
    ) RETURN t_str_mask IS
        l_mask_token CONSTANT VARCHAR2(1 CHAR) := '9';
        l_precision all_tab_columns.data_precision%TYPE;
        l_scale     all_tab_columns.data_scale%TYPE;
        l_mask      t_str_mask;
    BEGIN
        -- get column precision and scale
        g_error := 'SELECT l_precision, l_scale';
        BEGIN
            SELECT atb.data_precision, atb.data_scale
              INTO l_precision, l_scale
              FROM all_tab_columns atb
             WHERE atb.owner = i_owner
               AND atb.table_name = i_table
               AND atb.column_name = i_column;
        EXCEPTION
            WHEN no_data_found THEN
                l_precision := NULL;
        END;
    
        IF l_precision IS NOT NULL
        THEN
            -- no digits after decimal symbol
            IF l_scale IS NULL
            THEN
                l_scale := 0;
            END IF;
        
            -- digits before decimal symbol
            FOR i IN 1 .. l_precision - l_scale
            LOOP
                l_mask := l_mask || l_mask_token;
            END LOOP;
        
            IF l_scale > 0
            THEN
                -- decimal symbol
                l_mask := l_mask || pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
            
                -- digits after decimal symbol
                FOR i IN 1 .. l_scale
                LOOP
                    l_mask := l_mask || l_mask_token;
                END LOOP;
            END IF;
        END IF;
    
        RETURN l_mask;
    END get_numeric_input_mask;

    /*********************************************************************************************
    * Remove the occurrences of an number in a table_number 
    * 
    * @param i_input      Variable of TABLE_number type
    *
    * @return             TABLE_number with all elements of i_input except the ones equal to i_elem_to_Remove
    *
    * @author        Sofia Mendes
    * @version       2.6.0.5
    * @date          17-Dez-2010
    ********************************************************************************************/
    FUNCTION remove_element
    (
        i_input          IN table_number,
        i_elem_to_remove NUMBER
    ) RETURN table_number IS
        l_result table_number := NULL;
    BEGIN
        IF i_input IS NOT NULL
           AND i_input.exists(1)
        THEN
            l_result := table_number();
            FOR i IN 1 .. i_input.count
            LOOP
                IF (i_input(i) <> i_elem_to_remove)
                THEN
                    l_result.extend(1);
                    l_result(l_result.last) := i_input(i);
                END IF;
            END LOOP;
        
        END IF;
        RETURN l_result;
    END remove_element;

    /*********************************************************************************************
    * Remove the the element in a given position in a table_varchar
    * 
    * @param i_input      Variable of table_varchar type
    *
    * @return             TABLE_varchar with all elements of i_input except the one in the position i_pos_to_remove
    *
    * @author        Sofia Mendes
    * @version       2.6.0.5
    * @date          23-Feb-2011
    ********************************************************************************************/
    FUNCTION remove_element
    (
        i_input         IN table_varchar,
        i_pos_to_remove NUMBER,
        i_replace_enter IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_varchar IS
        l_result table_varchar := NULL;
    BEGIN
        IF i_input IS NOT NULL
           AND i_input.exists(1)
        THEN
            l_result := table_varchar();
            FOR i IN 1 .. i_input.count
            LOOP
                IF (i <> i_pos_to_remove)
                THEN
                    l_result.extend(1);
                    l_result(l_result.last) := i_input(i);
                ELSIF i = i_pos_to_remove
                      AND i_replace_enter = pk_alert_constant.g_yes
                THEN
                    l_result.extend(1);
                    --l_result(l_result.last) := 'be';
                
                END IF;
            END LOOP;
        
        END IF;
        RETURN l_result;
    END remove_element;

    /*********************************************************************************************
    * Remove the the element in a given position in a table_varchar2
    * 
    * @param i_input      Variable of table_varchar2 type
    * @param i_index      Element's index to remove
    *
    * @return             TABLE_varchar2 with all elements of i_input except the one in the position i_index
    *
    * @author        Miguel Leite
    * @version       2.6.5.2.2
    * @date          28-Aug-2016
    ********************************************************************************************/
    FUNCTION remove_element
    (
        i_input IN table_varchar2,
        i_index NUMBER
    ) RETURN table_varchar2 IS
        l_result table_varchar2 := NULL;
    BEGIN
        IF i_input IS NOT NULL
           AND i_input.exists(1)
        THEN
            l_result := table_varchar2();
            FOR i IN 1 .. i_input.count
            LOOP
                IF (i <> i_index)
                THEN
                    l_result.extend(1);
                    l_result(l_result.last) := i_input(i);
                END IF;
            END LOOP;
        
        END IF;
        RETURN l_result;
    END remove_element;

    /********************************************************************************************
    *  Append the elements of one VARCHAR table to another.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_table_to_append          Table to be appended        
    * @param i_flg_replace              Y-there is some text to replace     
    * @param i_replacement              Repace the '@1' by this text
    * @param io_total_table             Table with all the appended values    
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION append_tables
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_to_append IN table_varchar,
        i_flg_replace     IN VARCHAR2,
        i_replacement     IN VARCHAR2,
        io_total_table    IN OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_value                 VARCHAR2(32000);
        l_table_to_append_count PLS_INTEGER;
    BEGIN
        IF (i_table_to_append IS NOT NULL AND i_table_to_append.exists(1))
        THEN
            IF (io_total_table IS NOT NULL OR NOT io_total_table.exists(1))
            THEN
                l_table_to_append_count := i_table_to_append.count;
                FOR i IN 1 .. l_table_to_append_count
                LOOP
                    IF (i_flg_replace = k_yes)
                    THEN
                        l_value := REPLACE(i_replacement, '@1', i_table_to_append(i));
                        IF l_value IS NOT NULL
                           OR l_value <> ''
                        THEN
                            io_total_table.extend(1);
                            io_total_table(io_total_table.count) := TRIM(trailing chr(10) FROM l_value);
                        END IF;
                    ELSE
                        io_total_table.extend(1);
                        io_total_table(io_total_table.count) := i_table_to_append(i);
                    END IF;
                END LOOP;
            ELSE
                SELECT val
                  BULK COLLECT
                  INTO io_total_table
                  FROM (SELECT decode(i_flg_replace,
                                      k_yes,
                                      TRIM(trailing chr(10) FROM(REPLACE(i_replacement, '@1', column_value))),
                                      column_value) val
                          FROM TABLE(i_table_to_append))
                 WHERE val IS NOT NULL;
            END IF;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'APPEND_TABLES',
                                              o_error);
            RETURN FALSE;
    END append_tables;

    /**
    * Append the elements of one CLOB table to another.
    *
    * @param   i_lang                     Language identifier
    * @param   i_prof                     Professional
    * @param   i_table_to_append          Table to be appended        
    * @param   i_flg_replace              Y-there is some text to replace     
    * @param   i_replacement              Repace the '@1' by this text
    * @param   io_total_table             Table with all the appended values    
    * @param   o_error                    Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (based on Sofia Mendes's code)
    * @version 2.6.1.4
    * @since   21-10-2011
    */
    FUNCTION append_tables_clob
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_to_append IN table_clob,
        i_flg_replace     IN VARCHAR2,
        i_replacement     IN VARCHAR2,
        io_total_table    IN OUT table_clob,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_value                 CLOB;
        l_table_to_append_count PLS_INTEGER;
    BEGIN
        IF (i_table_to_append IS NOT NULL AND i_table_to_append.exists(1))
        THEN
            IF (io_total_table IS NOT NULL OR NOT io_total_table.exists(1))
            THEN
                l_table_to_append_count := i_table_to_append.count;
                FOR i IN 1 .. l_table_to_append_count
                LOOP
                    IF (i_flg_replace = pk_alert_constant.g_yes)
                    THEN
                        l_value := replace_with_clob(i_replacement, '@1', i_table_to_append(i));
                        IF l_value IS NOT NULL
                        THEN
                            io_total_table.extend(1);
                            io_total_table(io_total_table.count) := TRIM(trailing chr(10) FROM l_value);
                        END IF;
                    ELSE
                        io_total_table.extend(1);
                        io_total_table(io_total_table.count) := i_table_to_append(i);
                    END IF;
                END LOOP;
            ELSE
                SELECT val
                  BULK COLLECT
                  INTO io_total_table
                  FROM (SELECT decode(i_flg_replace,
                                      pk_alert_constant.g_yes,
                                      TRIM(trailing chr(10)
                                           FROM(pk_utils.replace_with_clob(i_replacement, '@1', column_value))),
                                      column_value) val
                          FROM TABLE(i_table_to_append))
                 WHERE val IS NOT NULL;
            END IF;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'APPEND_TABLES_CLOB',
                                              o_error);
            RETURN FALSE;
    END append_tables_clob;
    /**
    * Deletes the element of a table_number collection at the given index.
    * Keeps the collection not sparsed, ie, with consecutive subscripts.
    *
    * @param i_coll         collection to delete element from
    * @param i_idx          index of element to delete
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/28
    */
    PROCEDURE del_element
    (
        i_coll IN OUT NOCOPY table_number,
        i_idx  IN PLS_INTEGER
    ) IS
        l_index PLS_INTEGER;
    BEGIN
        IF i_coll IS NULL
           OR i_idx IS NULL
        THEN
            NULL;
        ELSIF i_coll.exists(i_idx)
        THEN
            -- starting at the index of element to delete,
            -- copy each element at "i" to "i-1"
            l_index := i_idx;
            LOOP
                l_index := i_coll.next(l_index);
                IF l_index IS NULL
                THEN
                    EXIT;
                ELSE
                    i_coll(i_coll.prior(l_index)) := i_coll(l_index);
                END IF;
            END LOOP;
            -- delete last element
            i_coll.trim;
        END IF;
    END del_element;

    /**
    * Deletes the element of a table_varchar collection at the given index.
    * Keeps the collection not sparsed, ie, with consecutive subscripts.
    *
    * @param i_coll         collection to delete element from
    * @param i_idx          index of element to delete
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/28
    */
    PROCEDURE del_element
    (
        i_coll IN OUT NOCOPY table_varchar,
        i_idx  IN PLS_INTEGER
    ) IS
        l_index PLS_INTEGER;
    BEGIN
        IF i_coll IS NULL
           OR i_idx IS NULL
        THEN
            NULL;
        ELSIF i_coll.exists(i_idx)
        THEN
            -- starting at the index of element to delete,
            -- copy each element at "i" to "i-1"
            l_index := i_idx;
            LOOP
                l_index := i_coll.next(l_index);
                IF l_index IS NULL
                THEN
                    EXIT;
                ELSE
                    i_coll(i_coll.prior(l_index)) := i_coll(l_index);
                END IF;
            END LOOP;
            -- delete last element
            i_coll.trim;
        END IF;
    END del_element;

    /**
    * Get a ref cursor row count.
    * Mind that the cursor will be fetched and exhausted.
    *
    * @param io_cursor      cursor
    *
    * @return               cursor row count
    *
    * @author               Pedro Carneiro
    * @version               2.5.2.3
    * @since                2012/05/28
    */
    FUNCTION get_rowcount(io_cursor IN OUT NOCOPY pk_types.cursor_type) RETURN NUMBER IS
        l_ret NUMBER;
        l_ctx dbms_xmlgen.ctxhandle;
        l_tmp CLOB;
    BEGIN
        IF io_cursor IS NULL
           OR NOT io_cursor%ISOPEN
        THEN
            l_ret := NULL;
        ELSE
            l_ctx := dbms_xmlgen.newcontext(querystring => io_cursor);
            l_tmp := dbms_xmlgen.getxml(ctx => l_ctx);
            l_ret := dbms_xmlgen.getnumrowsprocessed(ctx => l_ctx);
            dbms_xmlgen.closecontext(ctx => l_ctx);
            IF l_tmp IS NOT NULL
            THEN
                dbms_lob.freetemporary(lob_loc => l_tmp);
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_rowcount;

    /******************************************************************************************
    * This function is used to conver table_varchar to table_number
    *
    * @param i_table_varchar            Source string
    *
    * @return  table_number             
    *
    * @author                Mário Mineiro
    * @version               V.2.6.3.9
    * @since                 2013/11/29
    ********************************************************************************************/
    FUNCTION convert_tchar_tnumber(i_table_varchar IN table_varchar DEFAULT table_varchar()) RETURN table_number IS
        l_table_number table_number := table_number();
        l_count        PLS_INTEGER := 0;
        g_exception EXCEPTION;
    BEGIN
        IF i_table_varchar IS NOT empty
        THEN
        
            FOR i IN i_table_varchar.first .. i_table_varchar.last
            LOOP
            
                IF is_number(i_table_varchar(i)) = pk_alert_constant.g_yes
                THEN
                    l_count := l_count + 1;
                    l_table_number.extend;
                    l_table_number(l_count) := to_number(i_table_varchar(i));
                ELSE
                    -- if find element not number conversion cannot procced
                    RAISE g_exception;
                END IF;
            
            END LOOP;
        END IF;
        RETURN l_table_number;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END convert_tchar_tnumber;

    /******************************************************************************************
    * This function is used to append a string only if the source string is not null
    *
    * @param i_src_string            Source string
    * @param i_suffix_str            Suffix to append
    * @param i_prefix_str            Prefix to append
    *
    * @return  appended string              
    *
    * @author                José Silva
    * @version               V.2.6.2
    * @since                 2012/02/26
    ********************************************************************************************/
    FUNCTION append_str_if_not_null
    (
        i_src_string IN VARCHAR2,
        i_suffix_str IN VARCHAR2,
        i_prefix_str IN VARCHAR2 DEFAULT ''
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_src_string IS NOT NULL
        THEN
            RETURN i_prefix_str || i_src_string || i_suffix_str;
        ELSE
            RETURN NULL;
        END IF;
    END append_str_if_not_null;

    /**
    * Get an equal valued collection of table_clob type.
    *
    * @param i_val          clob value
    * @param i_len          collection length
    *
    * @return               equal valued table_clob collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/17
    */
    FUNCTION get_eq_val_coll
    (
        i_val IN CLOB,
        i_len IN PLS_INTEGER
    ) RETURN table_clob IS
        l_ret table_clob;
    BEGIN
        IF i_len IS NULL
           OR i_len < 1
        THEN
            -- invalid length
            l_ret := NULL;
        ELSE
            -- create
            l_ret := table_clob();
            l_ret.extend(i_len);
            -- fill
            FOR i IN l_ret.first .. l_ret.last
            LOOP
                l_ret(i) := i_val;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_eq_val_coll;
    FUNCTION bool_to_flag(i_bool IN BOOLEAN) RETURN VARCHAR2 IS
        l_return VARCHAR2(0050 CHAR);
    BEGIN
    
        IF i_bool IS NOT NULL
        THEN
            l_return := iif(i_bool, k_yes, k_no);
        END IF;
    
        RETURN l_return;
    
    END bool_to_flag;

    /********************************************************************************
    * Split clob into mutiple tokens
    * using the delimiter as split point
    *
    * @param i_text              The input clob
    * @param i_delimiter         The delimiter
    *
    * @return a table_varchar
    *
    * @author                    Vanessa Barsottelli
    * @date                      2014/01/16
    *********************************************************************************/
    FUNCTION split_clob
    (
        i_text      CLOB,
        i_delimiter VARCHAR2
    ) RETURN table_varchar
        PIPELINED IS
        l_idx       NUMBER;
        l_lista     CLOB;
        l_delimiter VARCHAR2(10 CHAR) := i_delimiter;
        tbl_chars   table_varchar := table_varchar();
        k_special_chars CONSTANT VARCHAR2(0050 CHAR) := '?,|,+,-,$,^,.,*';
        k_pattern       CONSTANT VARCHAR2(0050 CHAR) := '[[:space:]]+';
    BEGIN
    
        tbl_chars := pk_string_utils.str_split(k_special_chars, ',');
    
        --Escape reserved characters
        FOR i IN 1 .. tbl_chars.count
        LOOP
            l_delimiter := REPLACE(l_delimiter, tbl_chars(i), chr(92) || tbl_chars(i));
        END LOOP;
    
        --Remove extra spaces
        l_lista := regexp_replace(i_text, k_pattern, chr(32));
    
        LOOP
            l_idx := dbms_lob.instr(l_lista, l_delimiter);
            IF l_idx > 0
            THEN
                PIPE ROW(regexp_replace(regexp_substr(l_lista, '^.*?(' || l_delimiter || ')'), l_delimiter, ''));
                l_lista := regexp_replace(l_lista, '^.*?(' || l_delimiter || ')');
            ELSE
                PIPE ROW(l_lista);
                EXIT;
            END IF;
        END LOOP;
    
        RETURN;
    
    END split_clob;

    /*********************************************************************************************/
    FUNCTION get_client_institution_id RETURN NUMBER IS
        l_string         VARCHAR2(0200 CHAR);
        l_tmp            VARCHAR2(0200 CHAR);
        l_id_institution NUMBER;
        k_nls_string CONSTANT VARCHAR2(0200 CHAR) := 'NLS_NUMERIC_CHARACTERS =' || chr(32);
        k_mask       CONSTANT VARCHAR2(0100 CHAR) := '999999999999999999999999D999';
    BEGIN
        l_string         := k_nls_string || k_pl || '.' || chr(32) || k_pl;
        l_tmp            := REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.');
        l_id_institution := nvl(to_number(l_tmp, k_mask, l_string), 0);
    
        RETURN(l_id_institution);
    
    END get_client_institution_id;

    /*********************************************************************************************
    * Returns the institutions associated to a given market
    * 
    * @param         i_lang                user language
    * @param         i_id_market           Market ID
    *
    * @param         o_institution         institution ids
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Sofia Mendes
    * @version       2.6.3.13
    * @date          17-Mar-2014
    ********************************************************************************************/
    FUNCTION get_institutions_by_mkt
    (
        i_lang        IN language.id_language%TYPE,
        i_id_market   IN institution.id_market%TYPE,
        o_institution OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ID institutions. i_id_market: ' || i_id_market;
        pk_alertlog.log_debug(g_error);
        SELECT i.id_institution
          BULK COLLECT
          INTO o_institution
          FROM institution i
         WHERE i.id_market = i_id_market;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_UTILS',
                                              i_function => 'GET_INSTITUTIONS_BY_MKT',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_institutions_by_mkt;
    /* Method that returns institution address information */
    FUNCTION get_institution_address
    (
        i_lang    IN language.id_language%TYPE,
        i_inst_id institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_address institution.address%TYPE;
    BEGIN
    
        l_address := get_institution_base(i_mode           => k_mode_inst_address,
                                          i_lang           => i_lang,
                                          i_id_institution => i_inst_id);
    
        RETURN l_address;
    END get_institution_address;

    /**********************************************************************************************
    *  This fuction creates an OID based on an root and extension ids
    *
    * @param i_root         A root id/oid
    * @param i_extension    An extension id/oid
    *
    * @return               The full OID
    *
    * @author               Paulo Silva
    * @version              2.6.3.x
    * @since                30-04-2014
    ********************************************************************************************/
    FUNCTION create_oid
    (
        i_root      IN VARCHAR2,
        i_extension IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_oid VARCHAR2(512 CHAR);
    BEGIN
        IF i_root IS NULL
        THEN
            l_oid := i_extension;
        ELSIF i_extension IS NULL
        THEN
            l_oid := i_root;
        ELSE
            l_oid := i_root || '.' || i_extension;
        END IF;
    
        RETURN l_oid;
    END create_oid;

    /**********************************************************************************************
    *  This fuction creates an oid based on root (obtained from a sys_config) and extension ids
    *
    * @param i_prof                      The professional structure
    * @param i_root_sys_config           A sysconfig that contains the root id/oid
    * @param i_extension                 An extension id/oid
    *
    * @return                            The full OID
    *
    * @author                            Paulo Silva
    * @version                           2.6.3.x
    * @since                             30-04-2014
    ********************************************************************************************/
    FUNCTION create_oid
    (
        i_prof            IN profissional,
        i_root_sys_config IN VARCHAR2,
        i_extension       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN create_oid(pk_sysconfig.get_config(i_root_sys_config, i_prof), i_extension);
    END create_oid;

    FUNCTION get_var_route RETURN NUMBER IS
    BEGIN
        RETURN to_number(sys_context(k_context_id, 'i_grant_route'));
    END get_var_route;

    FUNCTION get_var_route_id RETURN VARCHAR2 IS
    BEGIN
        RETURN sys_context(k_context_id, 'i_route');
    END get_var_route_id;

    FUNCTION get_var_route_sup RETURN VARCHAR2 IS
    BEGIN
        RETURN sys_context(k_context_id, 'i_route_sup');
    END get_var_route_sup;

    FUNCTION get_var_mkt RETURN NUMBER IS
    BEGIN
        RETURN to_number(sys_context(k_context_id, 'i_id_market'));
    END get_var_mkt;

    /********************************************************************************************
    * Get currency description. Based on PK_BACKOFFICE.SET_CURRENCY_DESC.
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_value             Currency value
    * @param  i_id_currency       Currency ID
    *
    * @return Formatted currency string
    *
    * @author Jose Brito
    * @since  30/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_currency_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_value       IN NUMBER,
        i_id_currency IN currency.id_currency%TYPE
    ) RETURN VARCHAR2 IS
        l_currency_desc     VARCHAR2(60 CHAR);
        l_decimal_delimiter currency.decimal_delimiter%TYPE;
        l_value             VARCHAR2(0010 CHAR);
    BEGIN
    
        IF i_value = 0
        THEN
            l_value := ''; -- to avoid returnin '00,00 EUR' in the case of i_value = 0
        ELSE
            l_value := iif(trunc(i_value) = 0, '0', '');
        END IF;
    
        --g_error := 'SET CURRENCY_DESC';
        SELECT l_value || TRIM(to_char(i_value, xsql.number_format, xsql.format_mask)) currency_desc, decimal_delimiter
          INTO l_currency_desc, l_decimal_delimiter
          FROM (SELECT c.number_format,
                       c.decimal_delimiter,
                       'NLS_NUMERIC_CHARACTERS = ' || k_pl || c.decimal_delimiter || c.millenarian_delimiter || k_pl ||
                       ' NLS_CURRENCY = ' || k_pl || c.unit_measure || k_pl format_mask
                  FROM currency c
                 WHERE c.id_currency = i_id_currency
                   AND c.flg_available = k_yes) xsql;
    
        IF i_value = 0
        THEN
            l_currency_desc := REPLACE(l_currency_desc, l_decimal_delimiter, '0' || l_decimal_delimiter);
        END IF;
    
        RETURN l_currency_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_currency_desc;

    /* **************************************************************************************************
    * Build a string concatenating all elements sequencially, without excluding NULL values. 
    * All elements are separated by i_delimiter
    *
    * @param  i_tbl               array of values
    * @param  i_delimiter         delimiter to add between each element in final string
    *
    * @return string with all elements of array concatenated and separated by i_delimiter
    *
    * @author Carlos Ferreira
    * @since  30/04/2015
    *
    ********************************************************************************************/
    FUNCTION flistagg
    (
        i_tbl       IN table_varchar,
        i_delimiter IN VARCHAR2 DEFAULT '|'
    ) RETURN VARCHAR2 IS
        l_var VARCHAR2(4000);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
        
            <<lup_thru_positions>>
            l_var := l_var || i_tbl(1);
            FOR i IN 2 .. i_tbl.count
            LOOP
                l_var := l_var || i_delimiter || i_tbl(i);
            END LOOP lup_thru_positions;
        
            RETURN l_var;
        
        END IF;
    
        RETURN l_var;
    
    END flistagg;
    /********************************************************************************
    * Prepares the text to be used in search fields with text indexes (Oracle Text, Lucene, etc.)
    *
    * @param  i_text    search text
    * @return output    text
    *
    *
    * @author José Silva
    * @date   2009/10/27
    *********************************************************************************/
    FUNCTION get_criteria_text
    (
        i_lang         IN language.id_language%TYPE,
        i_text         IN VARCHAR2,
        i_index_column IN VARCHAR2 DEFAULT '',
        i_spec_char    IN VARCHAR2 DEFAULT ''
    ) RETURN VARCHAR2 IS
    
        l_input    VARCHAR2(4000);
        l_output   VARCHAR2(4000);
        l_aux      table_varchar;
        l_aux_init VARCHAR2(10);
        l_aux_end  VARCHAR2(10);
    
        l_special table_varchar := table_varchar(chr(92),
                                                 '+',
                                                 '-',
                                                 '&',
                                                 '|',
                                                 '!',
                                                 '(',
                                                 ')',
                                                 '{',
                                                 '}',
                                                 '[',
                                                 ']',
                                                 '^',
                                                 '"',
                                                 '~',
                                                 '*',
                                                 '?',
                                                 ':',
                                                 '=',
                                                 ';',
                                                 '$',
                                                 '>',
                                                 '<',
                                                 '%',
                                                 ',');
    
        l_wild_card VARCHAR2(1 CHAR) := '*';
    
        FUNCTION is_wild_card(i_word IN VARCHAR2) RETURN BOOLEAN IS
            l_stop_words table_varchar := table_varchar('A',
                                                        'AN',
                                                        'AND',
                                                        'ARE',
                                                        'AS',
                                                        'AT',
                                                        'BE',
                                                        'BUT',
                                                        'BY',
                                                        'FOR',
                                                        'IF',
                                                        'IN',
                                                        'INTO',
                                                        'IS',
                                                        'IT',
                                                        'NO',
                                                        'NOT',
                                                        'OF',
                                                        'ON',
                                                        'OR',
                                                        'SUCH',
                                                        'THAT',
                                                        'THE',
                                                        'THEIR',
                                                        'THEN',
                                                        'THERE',
                                                        'THESE',
                                                        'THEY',
                                                        'THIS',
                                                        'TO',
                                                        'WAS',
                                                        'WILL',
                                                        'WITH');
        BEGIN
            FOR i IN 1 .. l_stop_words.count
            LOOP
                IF i_word = l_stop_words(i)
                THEN
                    RETURN TRUE;
                END IF;
            END LOOP;
        
            RETURN FALSE;
        END is_wild_card;
    BEGIN
    
        l_input := i_text;
    
        FOR i IN 1 .. l_special.count
        LOOP
            l_input := REPLACE(l_input, l_special(i));
        END LOOP;
    
        l_input := TRIM(remove_upper_accentuation(l_input));
    
        IF i_spec_char IS NOT NULL
        THEN
            l_wild_card := i_spec_char;
        END IF;
    
        IF l_input IS NOT NULL
        THEN
            l_aux := pk_utils.str_split_l(i_list => l_input);
        
            IF i_index_column IS NOT NULL
            THEN
                l_aux_init := i_index_column || ':(';
                l_aux_end  := ')';
            ELSE
                l_aux_init := '';
                l_aux_end  := '';
            END IF;
        
            FOR i IN 1 .. l_aux.count - 1
            LOOP
                IF l_aux(i) <> ' '
                THEN
                    IF is_wild_card(i_word => TRIM(l_aux(i)))
                    THEN
                        NULL; -- stop words cant be used in this search
                    ELSE
                        l_output := l_output || TRIM(l_aux(i)) || i_spec_char || ' AND ';
                    END IF;
                END IF;
            END LOOP;
        
            IF is_wild_card(i_word => TRIM(l_aux(l_aux.count)))
            THEN
                IF l_aux.count > 1
                THEN
                    l_output := l_aux_init || substr(l_output, 1, length(l_output) - 5) || l_aux_end ||
                                'AND id_language:' || i_lang;
                ELSE
                    l_output := l_aux_init || TRIM(l_aux(l_aux.count)) || l_wild_card || ' ' || l_aux_end ||
                                'AND id_language:' || i_lang;
                END IF;
            ELSE
                l_output := l_aux_init || l_output || TRIM(l_aux(l_aux.count)) || i_spec_char || ' ' || l_aux_end ||
                            'AND id_language:' || i_lang;
            END IF;
        END IF;
    
        RETURN l_output;
    
    END get_criteria_text;

    PROCEDURE set_nls_numeric_characters
    (
        i_prof            IN profissional,
        i_back_nls        IN VARCHAR2 DEFAULT NULL,
        i_is_to_reset_nls IN BOOLEAN DEFAULT FALSE
    ) IS
    
        l_proc_name CONSTANT VARCHAR2(30) := 'SET_NLS_NUMERIC_CHARACTERS';
        l_package_name VARCHAR2(32 CHAR) := 'PK_UTILS';
        --
        l_decimal_symbol  sys_config.value%TYPE;
        l_grouping_symbol VARCHAR2(1);
        l_back_nls        VARCHAR2(2) := i_back_nls;
        l_is_to_reset_nls BOOLEAN := i_is_to_reset_nls;
        l_nls_num_char CONSTANT VARCHAR2(30) := 'NLS_NUMERIC_CHARACTERS';
    BEGIN
        IF l_is_to_reset_nls
           AND l_back_nls IS NOT NULL
        THEN
            g_error := 'RESET NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => l_package_name, sub_object_name => l_proc_name, text => g_error);
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_back_nls || '''';
        ELSIF NOT l_is_to_reset_nls
        THEN
            g_error := 'GET DECIMAL SYMBOL';
            pk_alertlog.log_debug(object_name => l_package_name, sub_object_name => l_proc_name, text => g_error);
            -- Flash is going to send all numbers with the . as decimal separator,
            -- so I'm not going to use this call pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof);
            l_decimal_symbol := '.';
        
            g_error := 'SET GROUPING SYMBOL';
            pk_alertlog.log_debug(object_name => l_package_name, sub_object_name => l_proc_name, text => g_error);
            IF l_decimal_symbol = ','
            THEN
                l_grouping_symbol := '.';
            ELSE
                l_grouping_symbol := ',';
            END IF;
        
            g_error := 'GET NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => l_package_name, sub_object_name => l_proc_name, text => g_error);
            SELECT VALUE
              INTO l_back_nls
              FROM nls_session_parameters
             WHERE parameter = l_nls_num_char;
        
            g_error := 'SET NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => l_package_name, sub_object_name => l_proc_name, text => g_error);
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_decimal_symbol ||
                              l_grouping_symbol || '''';
        END IF;
    END set_nls_numeric_characters;

    FUNCTION set_tbl_temp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN table_table_varchar,
        i_value IN table_table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sql       VARCHAR2(32767);
        l_sql_field VARCHAR2(32767);
        l_sql_value VARCHAR2(32767);
    
        x NUMBER;
    
    BEGIN
    
        DELETE tbl_temp;
    
        l_sql_field := 'INSERT INTO tbl_temp (';
        l_sql_value := 'VALUES (';
    
        IF i_field IS NOT NULL
           OR i_field.count > 0
        THEN
            FOR i IN 1 .. i_field.count
            LOOP
                l_sql_field := 'INSERT INTO tbl_temp (';
                l_sql_value := 'VALUES (';
            
                FOR j IN 1 .. i_field(i).count
                LOOP
                    l_sql_field := l_sql_field || i_field(i) (j);
                
                    IF instr(lower(i_field(i) (j)), 'vc_') > 0
                    THEN
                        l_sql_value := l_sql_value || '''' || i_value(i) (j) || '''';
                    
                    ELSE
                        l_sql_value := l_sql_value || i_value(i) (j);
                    END IF;
                
                    IF j < i_field(i).count
                    THEN
                        l_sql_field := l_sql_field || ', ';
                        l_sql_value := l_sql_value || ', ';
                    END IF;
                END LOOP;
            
                l_sql_field := l_sql_field || ')';
                l_sql_value := l_sql_value || ')';
            
                l_sql := l_sql_field || ' ' || l_sql_value;
            
                EXECUTE IMMEDIATE l_sql;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'SET_TBL_TEMP',
                                              o_error);
            RETURN FALSE;
    END set_tbl_temp;

    ------

    FUNCTION get_service_desc
    (
        i_lang IN NUMBER,
        i_id   IN NUMBER,
        i_mode IN VARCHAR2
    ) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
        l_code     VARCHAR2(0200 CHAR);
        l_id_dcs   NUMBER;
    
        FUNCTION get_dcs_department(i_id_dcs IN NUMBER) RETURN table_varchar IS
            tbl_return table_varchar;
        BEGIN
        
            SELECT dpt.code_department
              BULK COLLECT
              INTO tbl_return
              FROM department dpt
              JOIN dep_clin_serv dcs
                ON dcs.id_department = dpt.id_department
             WHERE dcs.id_dep_clin_serv = i_id_dcs;
        
            RETURN tbl_return;
        
        END get_dcs_department;
    
    BEGIN
    
        CASE i_mode
            WHEN pk_utils.desc_by_epis THEN
            
                SELECT id_dep_clin_serv
                  INTO l_id_dcs
                  FROM epis_info
                 WHERE id_episode = i_id;
            
                tbl_return := get_dcs_department(i_id_dcs => l_id_dcs);
            
            WHEN pk_utils.desc_by_dcs THEN
            
                tbl_return := get_dcs_department(i_id_dcs => i_id);
            
            WHEN pk_utils.desc_by_dpt THEN
                SELECT dpt.code_department
                  BULK COLLECT
                  INTO tbl_return
                  FROM department dpt
                 WHERE dpt.id_department = i_id;
            ELSE
                NULL;
        END CASE;
    
        IF tbl_return.count > 0
        THEN
            l_code   := tbl_return(1);
            l_return := pk_translation.get_translation(i_lang, l_code);
        END IF;
    
        RETURN l_return;
    
    END get_service_desc;

    FUNCTION exists_table_varchar
    (
        i_table  IN table_varchar,
        i_search IN VARCHAR2
    ) RETURN NUMBER IS
        l_indice NUMBER;
    BEGIN
    
        l_indice := -1;
    
        FOR i IN 1 .. i_table.count
        LOOP
            IF instr(i_table(i), i_search) > 0
            THEN
                l_indice := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_indice;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END exists_table_varchar;

    /********************************************************************************************
    * This function converts a number to char, according DECIMAL_SYMBOL and NUMBER_GROUP_SEPARATOR configs
    *
    * @param i_lang          Input - Language ID
    * @param i_input         Input - Number to convert
    *
    * @return                Return converted number in string format
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.7.3
    * @since                 2018/05/29
    ********************************************************************************************/
    FUNCTION number_to_char_with_separator
    (
        i_id_prof IN NUMBER,
        i_id_inst IN NUMBER,
        i_id_soft IN NUMBER,
        i_input   IN NUMBER
    ) RETURN VARCHAR2 result_cache relies_on(sys_config) IS
        l_decimal_symb sys_config.value%TYPE;
        l_aux_char     VARCHAR2(1000);
        l_nls_str      VARCHAR2(0500 CHAR);
        k_number_mask CONSTANT VARCHAR2(0500 CHAR) := 'FM9G999G999G999G999G999G999G999G990D999';
        l_group_separator VARCHAR2(30);
        l_prof            profissional := profissional(i_id_prof, i_id_inst, i_id_soft);
    BEGIN
    
        l_decimal_symb    := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => l_prof);
        l_group_separator := pk_sysconfig.get_config(i_code_cf => 'NUMBER_GROUP_SEPARATOR', i_prof => l_prof);
    
        IF (l_group_separator IS NOT NULL AND l_group_separator <> '0')
        THEN
            l_nls_str := 'NLS_NUMERIC_CHARACTERS=' || k_pl || l_decimal_symb || l_group_separator || k_sp || k_pl;
        
            --l_nls_str      := get_nls_decimal_symb(i_prof => i_prof);
            l_aux_char := to_char(i_input, k_number_mask, l_nls_str);
        
            IF substr(l_aux_char, -1) = l_decimal_symb
            THEN
                l_aux_char := substr(l_aux_char, 1, length(l_aux_char) - 1);
            END IF;
        ELSE
            l_aux_char := pk_utils.number_to_char(i_prof => l_prof, i_input => i_input);
        END IF;
    
        RETURN l_aux_char;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END number_to_char_with_separator;

END pk_utils;
/
