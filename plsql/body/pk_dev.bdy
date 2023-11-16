/*-- Last Change Revision: $Rev: 2026943 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_dev IS

    g_error        VARCHAR2(200);
    k_package_name VARCHAR2(30 CHAR);
    k_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';

    PROCEDURE exec_sql(i_sql IN VARCHAR2) IS
    BEGIN
        dbms_output.put_line(i_sql);
        EXECUTE IMMEDIATE (i_sql);
    END exec_sql;

    /******************************************************************************************
    * This function returns a string after all the keys in i_params are replaced.
    * It's very useful for dynamicaly built code so you can define code templates and set tokens
    * you have to replace to built an actual statement.
    *
    * @param i_template              Input - code template
    * @param i_params                Input - hash table with all the tokens to replace
    *
    * @return  varchar2
    *
    * @raises                
    *
    * @author                Fábio Oliveira
    * @version               V.2.6.1
    * @since                 2011/11/11
    ********************************************************************************************/

    FUNCTION build_statement
    (
        i_template IN VARCHAR2,
        i_params   IN pk_types.vc2_hash_table
    ) RETURN VARCHAR2 IS
        l_final_statement VARCHAR2(32000) := i_template;
        l_key             VARCHAR2(200 CHAR);
    BEGIN
        l_key := i_params.first;
        WHILE l_key IS NOT NULL
        LOOP
            l_final_statement := REPLACE(l_final_statement, l_key, i_params(l_key));
            l_key             := i_params.next(l_key);
        END LOOP;
    
        RETURN l_final_statement;
    END build_statement;

    FUNCTION get_pat_by_epis(i_episode IN NUMBER) RETURN NUMBER IS
        l_pat patient.id_patient%TYPE;
    BEGIN
        SELECT v.id_patient
          INTO l_pat
          FROM episode e
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE e.id_episode = i_episode;
    
        RETURN l_pat;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_by_epis;

    PROCEDURE get_epis_pat_by_tab
    (
        i_owner IN VARCHAR2,
        i_table IN VARCHAR2,
        o_epis  OUT VARCHAR2,
        o_pat   OUT VARCHAR2
    ) IS
        CURSOR c_pat_epis
        (
            i_owner VARCHAR2,
            i_table VARCHAR2
        ) IS
            WITH pivot_data AS
             (SELECT column_name, r_constraint_name
                FROM (SELECT acc.column_name,
                             ac.r_constraint_name,
                             row_number() over(PARTITION BY ac.r_constraint_name ORDER BY utl_match.edit_distance_similarity(s1 => decode(ac.r_constraint_name, 'EPIS_PK', 'ID_EPISODE', 'ID_PATIENT'), s2 => acc.column_name) DESC) rn
                        FROM all_cons_columns acc
                        JOIN all_constraints ac
                          ON (ac.owner = acc.owner AND ac.table_name = acc.table_name AND
                             ac.constraint_name = acc.constraint_name)
                       WHERE ac.constraint_type = 'R'
                         AND ac.r_constraint_name IN ('PAT_PK', 'EPIS_PK')
                         AND acc.table_name = i_table
                         AND acc.owner = i_owner)
               WHERE rn = 1)
            SELECT *
              FROM pivot_data
            pivot (MAX(column_name) FOR r_constraint_name IN('PAT_PK', 'EPIS_PK'));
    
    BEGIN
        OPEN c_pat_epis(i_owner, i_table);
        FETCH c_pat_epis
            INTO o_pat, o_epis;
        CLOSE c_pat_epis;
    EXCEPTION
        WHEN OTHERS THEN
            o_epis := NULL;
            o_pat  := NULL;
    END get_epis_pat_by_tab;

    PROCEDURE get_dependencies
    (
        i_owner    IN VARCHAR2,
        i_package  IN VARCHAR2,
        i_function IN VARCHAR2,
        i_iter     IN INTEGER DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO tbl_temp
            (vc_1, vc_2, num_1, vc_3, vc_4, num_2)
            SELECT *
              FROM (SELECT ds.owner,
                            ds.name,
                            ds.line,
                            ds.text,
                            upper(REPLACE(REPLACE(TRIM(REPLACE((SELECT DISTINCT first_value(ds2.text) over(ORDER BY line DESC) rn
                                                                  FROM dba_source ds2
                                                                 WHERE ds2.owner = ds.owner
                                                                   AND ds2.name = ds.name
                                                                   AND ds2.type = ds.type
                                                                   AND ds2.line < ds.line
                                                                   AND (TRIM(ds2.text) LIKE 'FUNCTION %' OR
                                                                       TRIM(ds2.text) LIKE 'PROCEDURE %')),
                                                                '
',
                                                                ' ')),
                                                   'PROCEDURE ',
                                                   ''),
                                           'FUNCTION ',
                                           '')) function_name,
                            i_iter
                       FROM dba_source ds
                      WHERE upper(ds.text) LIKE '%' || i_package || '.' || i_function || '%'
                     UNION ALL
                     SELECT ds.owner,
                            ds.name,
                            ds.line,
                            ds.text,
                            upper(REPLACE(REPLACE(TRIM(REPLACE((SELECT DISTINCT first_value(ds2.text) over(ORDER BY line DESC) rn
                                                                  FROM dba_source ds2
                                                                 WHERE ds2.owner = ds.owner
                                                                   AND ds2.name = ds.name
                                                                   AND ds2.type = ds.type
                                                                   AND ds2.line < ds.line
                                                                   AND (TRIM(ds2.text) LIKE 'FUNCTION %' OR
                                                                       TRIM(ds2.text) LIKE 'PROCEDURE %')),
                                                                '
',
                                                                ' ')),
                                                   'PROCEDURE ',
                                                   ''),
                                           'FUNCTION ',
                                           '')) function_name,
                            i_iter
                       FROM dba_source ds
                      WHERE upper(ds.text) LIKE '%' || i_function || '%'
                        AND ds.owner = i_owner
                        AND ds.name = i_package
                        AND ds.type != 'PACKAGE'
                        AND NOT (TRIM(ds.text) LIKE 'PROCEDURE%' OR TRIM(ds.text) LIKE '*%' OR
                                 TRIM(ds.text) LIKE 'FUNCTION%' OR TRIM(ds.text) LIKE 'END%')) t
             WHERE NOT EXISTS (SELECT 0
                      FROM tbl_temp tt
                     WHERE tt.vc_1 = t.owner
                       AND tt.vc_2 = t.name
                       AND tt.vc_4 = t.function_name);
    END get_dependencies;

    PROCEDURE get_all_dependencies
    (
        i_owner    IN VARCHAR2,
        i_package  IN VARCHAR2,
        i_function IN VARCHAR2,
        i_levels   IN PLS_INTEGER DEFAULT 1
    ) IS
    BEGIN
        INSERT INTO tbl_temp
            (vc_1, vc_2, vc_4, num_2)
        VALUES
            (upper(i_owner), upper(i_package), upper(i_function), 0);
    
        IF i_levels > 0
        THEN
            FOR i IN 1 .. i_levels
            LOOP
                FOR r IN (SELECT DISTINCT vc_1, vc_2, vc_4
                            FROM tbl_temp
                           WHERE num_2 = i - 1)
                LOOP
                    get_dependencies(r.vc_1, r.vc_2, r.vc_4, i);
                END LOOP;
            END LOOP;
        END IF;
    END get_all_dependencies;

    /**
    * Creates an audit trigger for a given table in the format B_IU_<object_ID>_AUDIT
    *
    * @param i_table   Table to audit
    * @param i_owner   Table's owner
    * @param o_trigger Name of the created trigger
    *
    * @return     boolean
    * @author     Fábio Oliveira
    * @version    2.5.0.2
    * @since      2009/04/16
    * @notes
    */
    FUNCTION create_audit_trigger
    (
        i_table   IN VARCHAR2,
        i_owner   IN VARCHAR2,
        o_trigger OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_maxtriggername CONSTANT PLS_INTEGER := 30;
    
        l_normalized_table VARCHAR2(400);
        l_table_id         NUMBER;
        l_normalized_owner VARCHAR2(0050);
    
        e_nametoolong EXCEPTION;
        e_notable     EXCEPTION;
        e_nocolumns   EXCEPTION;
        e_noowner     EXCEPTION;
    
        PROCEDURE check_parameters
        (
            i_table IN VARCHAR2,
            i_owner IN VARCHAR2
        ) IS
            l_exists NUMBER;
        BEGIN
            IF i_owner IS NULL
            THEN
                RAISE e_noowner;
            END IF;
        
            SELECT decode((SELECT 1
                            FROM dual
                           WHERE EXISTS (SELECT 0
                                    FROM dba_tables dt
                                   WHERE dt.owner = upper(i_owner)
                                     AND dt.table_name = upper(i_table))),
                          1,
                          1,
                          0)
              INTO l_exists
              FROM dual;
            IF l_exists = 0
            THEN
                RAISE e_notable;
            END IF;
        
            RETURN;
        END check_parameters;
    
        FUNCTION check_index
        (
            i_table IN VARCHAR2,
            i_owner IN VARCHAR2
        ) RETURN NUMBER IS
            l_object_id NUMBER;
        BEGIN
            SELECT do.object_id
              INTO l_object_id
              FROM dba_objects do
             WHERE do.owner = i_owner
               AND do.object_name = i_table
               AND do.object_type = 'TABLE';
        
            IF length(lpad(l_object_id, 6, '0')) + 11 > l_maxtriggername
            THEN
                RAISE e_nametoolong;
                RETURN NULL;
            END IF;
        
            RETURN l_object_id;
        END check_index;
    
        FUNCTION create_trigger
        (
            i_tbl_id IN NUMBER,
            i_table  IN VARCHAR2,
            i_owner  IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_trigger_name VARCHAR2(30) := 'B_IU_' || lpad(i_tbl_id, 6, '0') || '_AUDIT';
        BEGIN
        
            EXECUTE IMMEDIATE get_audit_trigger_body(i_tbl_id, i_table, i_owner);
            dbms_output.put_line('TRIGGER ' || l_trigger_name || ' SUCCESSFULLY CREATED.');
        
            RETURN l_trigger_name;
        
        END create_trigger;
    
    BEGIN
        check_parameters(i_table, i_owner);
    
        l_normalized_owner := upper(i_owner);
        l_normalized_table := upper(i_table);
    
        IF NOT check_audit_columns(l_normalized_table, l_normalized_owner)
        THEN
            RAISE e_nocolumns;
        END IF;
    
        l_table_id := check_index(l_normalized_table, l_normalized_owner);
    
        o_trigger := create_trigger(l_table_id, l_normalized_table, l_normalized_owner);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_nametoolong THEN
            dbms_output.put_line('Error ocurred: INDEX NAME LENGTH EXCEDED MAXIMUM (' || l_maxtriggername ||
                                 ' CHAR). PLEASE CREATE THE TRIGGER YOURSELF, SORRY.');
            RETURN FALSE;
        WHEN e_notable THEN
            dbms_output.put_line('Error ocurred: TABLE ' || i_table || 'DOESN''T EXIST.');
            RETURN FALSE;
        WHEN e_nocolumns THEN
            dbms_output.put_line('Error ocurred: TABLE ' || l_normalized_table || ' DOESN''T HAVE ALL AUDIT COLUMNS.');
            RETURN FALSE;
        WHEN e_noowner THEN
            dbms_output.put_line('Error ocurred: OWNER OF TABLE not SPECIFIED');
            RETURN FALSE;
        WHEN OTHERS THEN
            dbms_output.put_line('Error ocurred: ' || SQLERRM);
        
            RETURN FALSE;
        
    END create_audit_trigger;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_frmw.get_audit_trigger_body(i_obj_id, i_tbl_name, i_own_name);
    
    END get_audit_trigger_body;

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
    ) RETURN VARCHAR2 IS
        l_epis_col VARCHAR2(30 CHAR);
        l_pat_col  VARCHAR2(30 CHAR);
    
        k_qc_trigger_template CONSTANT VARCHAR2(32000) := 'CREATE OR REPLACE TRIGGER &OBJ_OWNER.B_IUD_' ||
                                                          '&OBJID_NORM' || '_ACTL
    BEFORE INSERT OR UPDATE OR DELETE ON &OBJ_OWNER.&TABLE_NAME
DECLARE
/* Trigger that validates access to &TABLE_NAME table.
This trigger should only exist on QC environments */

    l_operation VARCHAR2(30 CHAR);
BEGIN
    CASE
        WHEN updating THEN l_operation := ''UPDATE'';
        WHEN deleting THEN l_operation := ''DELETE'';
        WHEN inserting THEN l_operation := ''INSERT'';
    END CASE;

    pk_dev.log_qc_dml(i_tbl_name => ''&TABLE_NAME'',
                      i_dml_type => l_operation);
END;';
    
        k_qc_trigger_templ_ep_pat CONSTANT VARCHAR2(32000) := 'CREATE OR REPLACE TRIGGER &OBJ_OWNER.B_IUD_' ||
                                                              '&OBJID_NORM' || '_ACTL
    BEFORE INSERT OR UPDATE OR DELETE 
    OF &EPIS_COL, &PAT_COL
    ON &OBJ_OWNER.&TABLE_NAME
        for each row
DECLARE
/* Trigger that validates access to &TABLE_NAME table.
This trigger should only exist on QC environments */

    l_operation VARCHAR2(30 CHAR);
    l_pat_val   PATIENT.ID_PATIENT%TYPE;
    l_obj_name  VARCHAR2(30 CHAR);
    l_proc_name VARCHAR2(30 CHAR);

BEGIN
    CASE
        WHEN updating THEN l_operation := ''UPDATE'';
        WHEN deleting THEN l_operation := ''DELETE'';
        WHEN inserting THEN l_operation := ''INSERT'';
    END CASE;

    pk_dev.log_qc_dml(i_tbl_name => ''&TABLE_NAME'',
                      i_dml_type => l_operation);

    l_pat_val := pk_dev.get_pat_by_epis(i_episode => :new.&EPIS_COL );

    pk_dev.get_session_vars(o_obj_name  => l_obj_name,
                            o_procedure_name => l_proc_name);

    if :new.&PAT_COL != l_pat_val  and :new.&EPIS_COL != -1 and :new.&PAT_COL != -1 
      and l_obj_name != ''PK_MATCH''
    then
       pk_alertlog.log_error(''&TABLE_NAME | EPIS -> ''||:new.&EPIS_COL||'' | PAT(OLD) -> ''||
       :old.&PAT_COL||'' | PAT(NEW) -> ''||:new.&PAT_COL);
       raise_application_error(-20000, ''&TABLE_NAME | EPIS -> ''||:new.&EPIS_COL||'' | PAT(OLD) -> ''||
       :old.&PAT_COL||'' | PAT(NEW) -> ''||:new.&PAT_COL);
    end if;

END;';
    
        k_objid_norm_token CONSTANT VARCHAR2(30 CHAR) := '&OBJID_NORM';
        k_table_name_token CONSTANT VARCHAR2(30 CHAR) := '&TABLE_NAME';
        k_epis_col_token   CONSTANT VARCHAR2(30 CHAR) := '&EPIS_COL';
        k_pat_col_token    CONSTANT VARCHAR2(30 CHAR) := '&PAT_COL';
        k_owner            CONSTANT VARCHAR2(30 CHAR) := '&OBJ_OWNER';
    
        l_object_id  NUMBER(24);
        l_objid_norm VARCHAR2(30 CHAR);
    
        l_statement_elements pk_types.vc2_hash_table;
    
    BEGIN
        SELECT uo.object_id
          INTO l_object_id
          FROM dba_objects uo
         WHERE uo.object_name = i_tbl_name
           AND uo.owner = i_owner
           AND uo.object_type = 'TABLE'
           AND NOT EXISTS (SELECT 0
                  FROM user_external_tables uet
                 WHERE uet.table_name = uo.object_name);
    
        pk_dev.get_epis_pat_by_tab(i_owner => i_owner, i_table => i_tbl_name, o_epis => l_epis_col, o_pat => l_pat_col);
    
        l_objid_norm := lpad(l_object_id, 12, '0');
    
        l_statement_elements(k_objid_norm_token) := l_objid_norm;
        l_statement_elements(k_table_name_token) := i_tbl_name;
        l_statement_elements(k_epis_col_token) := l_epis_col;
        l_statement_elements(k_pat_col_token) := l_pat_col;
        l_statement_elements(k_owner) := i_owner;
    
        IF l_epis_col IS NOT NULL
           AND l_pat_col IS NOT NULL
        THEN
            RETURN build_statement(i_template => k_qc_trigger_templ_ep_pat, i_params => l_statement_elements);
        ELSE
            RETURN build_statement(i_template => k_qc_trigger_template, i_params => l_statement_elements);
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN '';
    END get_qc_trigger_body;

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
    ) IS
        l_osuser VARCHAR2(400 CHAR);
    
        e_bad_access EXCEPTION;
    BEGIN
        SELECT sys_context('USERENV', 'OS_USER') os_user
          INTO l_osuser
          FROM dual;
    
        IF USER = 'DSV'
        THEN
            RAISE e_bad_access;
        
        END IF;
    EXCEPTION
        WHEN e_bad_access THEN
            alertlog.pk_alertlog.log_error(text            => l_osuser || ' made an ' || i_dml_type || ' on ' ||
                                                              i_tbl_name,
                                           object_name     => 'QC_ACCESS_CONTROL',
                                           sub_object_name => i_tbl_name);
        
            raise_application_error(-20001, 'You''re not allowed to do any DML on this object. Sorry.');
    END log_qc_dml;
    /*
    PROCEDURE output
    (
        i_text        VARCHAR2,
        i_text_length NUMBER DEFAULT 255,
        i_divider     VARCHAR2 DEFAULT chr(32),
        i_new_line    VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
            pk_filter_built.output(i_text        => i_text,
                                   i_text_length => i_text_length,
                                   i_divider     => i_divider,
                                   i_new_line    => i_new_line);
    END output;
    */
    /**
    * Elimina comentários de uma expressão
    * O parse tem por base uma máquina de estados
    *
    * @returns expressão sem comentários
    *
    **/
    FUNCTION strip_comments(i_str IN VARCHAR2) RETURN VARCHAR2 IS
        g_nomode             CONSTANT PLS_INTEGER := 0; -- Estado inicial em que todos os caractéres são úteis
        g_linecomment        CONSTANT PLS_INTEGER := 1; -- Dentro de uma linha de comentários
        g_blockcomment       CONSTANT PLS_INTEGER := 2; -- Dentro de um bloco de comentário
        g_startlinecomment   CONSTANT PLS_INTEGER := 3; -- Início de uma linha de comentários
        g_startblockcomment  CONSTANT PLS_INTEGER := 4; -- Início de um bloco de comentários
        g_endblockcomment    CONSTANT PLS_INTEGER := 5; -- Fim de um bloco de comentários
        g_quote              CONSTANT PLS_INTEGER := 6; -- Dentro de uma quote
        g_endquote           CONSTANT PLS_INTEGER := 7; -- Fim de uma quote
        g_blockcommentorhint CONSTANT PLS_INTEGER := 8; -- Dentro de um bloco de comentários ou hint
    
        l_result     VARCHAR2(32000);
        l_remain_str VARCHAR2(32000);
        l_curr_char  VARCHAR2(1 CHAR);
        l_mode       PLS_INTEGER := g_nomode;
        l_temp       VARCHAR2(32000) := '';
    BEGIN
        l_curr_char  := ' ';
        l_remain_str := i_str;
        WHILE (l_remain_str IS NOT NULL)
        LOOP
            l_curr_char := substr(l_remain_str, 1, 1);
        
            IF l_curr_char IS NOT NULL
            THEN
                l_remain_str := substr(l_remain_str, 2, length(l_remain_str) - 1);
            
                CASE l_mode
                    WHEN g_quote THEN
                        -- [']  -> g_endquote  save_char;
                        -- [^'] -> g_quote  save_char
                        CASE l_curr_char
                            WHEN '''' THEN
                                l_mode := g_endquote;
                            ELSE
                                l_mode := g_quote;
                        END CASE;
                        l_result := l_result || l_curr_char;
                    WHEN g_endquote THEN
                        -- [']  -> g_quote  save_char;
                        -- [/]  -> g_startblockcomment  to_temp;
                        -- [-]  -> g_startlinecomment  to_temp;
                        -- [^'] -> g_nomode  save_char
                        CASE l_curr_char
                            WHEN '''' THEN
                                l_mode   := g_quote;
                                l_result := l_result || l_curr_char;
                            WHEN '/' THEN
                                l_mode := g_startblockcomment;
                                l_temp := l_curr_char;
                            WHEN '-' THEN
                                l_mode := g_startlinecomment;
                                l_temp := l_curr_char;
                            ELSE
                                l_mode   := g_nomode;
                                l_result := l_result || l_curr_char;
                        END CASE;
                    WHEN g_linecomment THEN
                        -- [\n]  -> g_nomode  save_char;
                        -- [^\n] -> g_linecomment
                        CASE l_curr_char
                            WHEN chr(10) THEN
                                l_mode   := g_nomode;
                                l_result := l_result || l_curr_char;
                            ELSE
                                l_mode := g_linecomment;
                                l_temp := '';
                        END CASE;
                    WHEN g_blockcomment THEN
                        -- [*]  -> g_endblockcomment;
                        -- [^*] -> g_blockcomment
                        CASE l_curr_char
                            WHEN '*' THEN
                                l_mode := g_endblockcomment;
                            ELSE
                                l_mode := g_blockcomment;
                        END CASE;
                        l_temp := '';
                    WHEN g_endblockcomment THEN
                        -- [/]   -> g_nomode;
                        -- [*]   -> g_endblockcomment;
                        -- [^*/] -> g_blockcomment
                        CASE l_curr_char
                            WHEN '/' THEN
                                l_mode := g_nomode;
                            WHEN '*' THEN
                                l_mode := g_endblockcomment;
                            ELSE
                                l_mode := g_blockcomment;
                        END CASE;
                        l_temp := '';
                    WHEN g_startlinecomment THEN
                        -- [-]  -> g_linecomment;
                        -- [^-] -> g_nomode  save_temp  save_char
                        CASE l_curr_char
                            WHEN '-' THEN
                                l_mode := g_linecomment;
                                l_temp := '';
                            ELSE
                                l_mode   := g_nomode;
                                l_result := l_result || l_temp || l_curr_char;
                                l_temp   := '';
                        END CASE;
                    WHEN g_startblockcomment THEN
                        -- [*]   -> g_blockcommentorhint  to_temp;
                        -- [/]   -> g_startblockcomment  save_temp  to_temp;
                        -- [^*/] -> g_nomode  save_temp  save_char
                        CASE l_curr_char
                            WHEN '*' THEN
                                l_mode := g_blockcommentorhint;
                                l_temp := l_temp || l_curr_char;
                            WHEN '/' THEN
                                l_mode   := g_startblockcomment;
                                l_result := l_result || l_temp;
                                l_temp   := l_curr_char;
                            ELSE
                                l_mode   := g_nomode;
                                l_result := l_result || l_temp || l_curr_char;
                                l_temp   := '';
                        END CASE;
                    WHEN g_blockcommentorhint THEN
                        -- [+]  -> g_nomode  save_temp  save_char;
                        -- [^+] -> g_blockcomment
                        CASE l_curr_char
                            WHEN '+' THEN
                                l_mode   := g_nomode;
                                l_result := l_result || l_temp || l_curr_char;
                                l_temp   := '';
                            ELSE
                                l_mode := g_blockcomment;
                                l_temp := '';
                        END CASE;
                    ELSE
                        -- [-]  -> g_startlinecomment  to_temp;
                        -- [']  -> g_quote  save_char;
                        -- [/]  -> g_startblockcomment  to_temp;
                        -- [^-'/] -> g_nomode  save_temp  save_char
                        CASE l_curr_char
                            WHEN '-' THEN
                                l_mode := g_startlinecomment;
                                l_temp := l_temp || l_curr_char;
                            WHEN '''' THEN
                                l_mode   := g_quote;
                                l_result := l_result || l_curr_char;
                            WHEN '/' THEN
                                l_mode := g_startblockcomment;
                                l_temp := l_curr_char;
                            ELSE
                                l_mode   := g_nomode;
                                l_result := l_result || l_temp || l_curr_char;
                                l_temp   := '';
                        END CASE;
                END CASE;
            ELSE
                l_result := l_result || l_temp;
            END IF;
        END LOOP;
    
        RETURN l_result;
    END strip_comments;

    PROCEDURE initialize_params
    (
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        k_lang             CONSTANT NUMBER(24) := 1;
        k_prof_id          CONSTANT NUMBER(24) := 2;
        k_prof_institution CONSTANT NUMBER(24) := 3;
        k_prof_software    CONSTANT NUMBER(24) := 4;
        k_episode          CONSTANT NUMBER(24) := 5;
        k_patient          CONSTANT NUMBER(24) := 6;
    
        l_msg_edis_grid_m003 CONSTANT sys_message.code_message%TYPE := 'EDIS_GRID_M003';
    
        g_sysdate_tstz              CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        g_cat_type_doc              CONSTANT category.flg_type%TYPE := 'D';
        g_cat_type_nurse            CONSTANT category.flg_type%TYPE := 'N';
        g_discharge_flg_status_pend CONSTANT discharge.flg_status%TYPE := 'P';
        g_icon_ft                   CONSTANT VARCHAR2(1 CHAR) := 'F';
        g_icon_ft_transfer          CONSTANT VARCHAR2(1 CHAR) := 'T';
        g_ft_color                  CONSTANT VARCHAR2(200 CHAR) := '0xFFFFFF';
        g_ft_triage_white           CONSTANT VARCHAR2(200 CHAR) := '0x787864';
        g_ft_status                 CONSTANT VARCHAR2(1 CHAR) := 'A';
        g_task_analysis             CONSTANT VARCHAR2(1 CHAR) := 'A';
        g_task_exam                 CONSTANT VARCHAR2(1 CHAR) := 'E';
        g_desc_grid                 CONSTANT VARCHAR2(1 CHAR) := 'G';
        g_yes                       CONSTANT VARCHAR2(1 CHAR) := 'Y';
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(k_prof_id),
                                                        i_context_ids(k_prof_institution),
                                                        i_context_ids(k_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(k_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(k_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    BEGIN
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_qty' THEN
                o_num := 69;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'l_msg_edis_grid_m003' THEN
                o_vc2 := l_msg_edis_grid_m003;
            WHEN 'g_sysdate_tstz' THEN
                o_tstz := g_sysdate_tstz;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := g_cat_type_doc;
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := g_cat_type_nurse;
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, o_vc2);
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, g_sysdate_tstz, l_prof);
            WHEN 'g_discharge_flg_status_pend' THEN
                o_vc2 := g_discharge_flg_status_pend;
            WHEN 'g_icon_ft' THEN
                o_vc2 := g_icon_ft;
            WHEN 'g_icon_ft_transfer' THEN
                o_vc2 := g_icon_ft_transfer;
            WHEN 'g_ft_color' THEN
                o_vc2 := g_ft_color;
            WHEN 'g_ft_triage_white' THEN
                o_vc2 := g_ft_triage_white;
            WHEN 'g_ft_status' THEN
                o_vc2 := g_ft_status;
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            WHEN 'g_desc_grid' THEN
                o_vc2 := g_desc_grid;
            WHEN 'g_yes' THEN
                o_vc2 := g_yes;
            WHEN 'next_month' THEN
                o_tstz := current_timestamp + INTERVAL '1' MONTH;
            WHEN 'last_month' THEN
                o_tstz := current_timestamp - INTERVAL '1' MONTH;
        END CASE;
    END initialize_params;

    FUNCTION check_audit_columns
    (
        i_table IN VARCHAR2,
        i_owner IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_exists NUMBER;
    BEGIN
        SELECT decode(COUNT(0), 6, 1, 0)
          INTO l_exists
          FROM dba_tab_columns dtc
         WHERE dtc.owner = i_owner
           AND dtc.table_name = i_table
           AND dtc.column_name IN
               ('CREATE_USER', 'CREATE_TIME', 'CREATE_INSTITUTION', 'UPDATE_USER', 'UPDATE_TIME', 'UPDATE_INSTITUTION');
    
        IF l_exists = 0
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    END check_audit_columns;

    /**
    * Create audit columns
    *
    * @param i_column_name     Column name
    * @param i_table           Table name
    * @param i_owner           Table owner
    *
    * @return     Boolean
    *
    * @author     Rui Spratley
    * @version    2.6.2.1
    * @since      2012/06/22
    * @notes
    */
    PROCEDURE set_audit_column
    (
        i_column_name IN VARCHAR2,
        i_table       IN VARCHAR2,
        i_owner       IN VARCHAR2
    ) IS
    BEGIN
        g_error := i_owner || '.' || i_table || '.' || i_column_name;
        IF i_column_name = 'CREATE_USER'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name || ' varchar2(30 char)');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''User that created the record''');
        ELSIF i_column_name = 'UPDATE_USER'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name || ' varchar2(30 char)');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''User that updated the record''');
        ELSIF i_column_name = 'CREATE_TIME'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name ||
                     ' timestamp with local time zone');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''Time when the record was created''');
        ELSIF i_column_name = 'UPDATE_TIME'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name ||
                     ' timestamp with local time zone');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''Time when the record was updated''');
        ELSIF i_column_name = 'CREATE_INSTITUTION'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name || ' number(24)');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''Institution where the record was created''');
        ELSIF i_column_name = 'UPDATE_INSTITUTION'
        THEN
            exec_sql('ALTER TABLE ' || i_owner || '.' || i_table || ' add ' || i_column_name || ' number(24)');
            exec_sql('comment on column ' || i_owner || '.' || i_table || '.' || i_column_name ||
                     ' is ''Institution where the record was updated''');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(k_package_name || '.set_audit_column -> ' || g_error || '-' || SQLERRM);
    END set_audit_column;

    PROCEDURE create_audit_columns
    (
        i_table IN VARCHAR2,
        i_owner IN VARCHAR2
    ) IS
        l_normalized_table VARCHAR2(30 CHAR);
        l_normalized_owner VARCHAR2(30 CHAR);
        l_trigger          VARCHAR2(1000 CHAR);
    
        CURSOR c_list_cols IS
            SELECT dtc.column_name
              FROM dba_tab_columns dtc
             WHERE dtc.owner = l_normalized_owner
               AND dtc.table_name = l_normalized_table;
    
        l_list_cols table_varchar;
        --        IN('CREATE_USER', 'CREATE_TIME', 'CREATE_INSTITUTION', 'UPDATE_USER', 'UPDATE_TIME', 'UPDATE_INSTITUTION');
    
    BEGIN
        l_normalized_table := upper(i_table);
        l_normalized_owner := upper(i_owner);
    
        g_error := 'Verifiy if table ' || l_normalized_owner || '.' || l_normalized_table || ' has audit columns';
        IF NOT check_audit_columns(l_normalized_table, l_normalized_owner)
        THEN
            g_error := 'fetch cursor';
            OPEN c_list_cols;
            FETCH c_list_cols BULK COLLECT
                INTO l_list_cols;
            CLOSE c_list_cols;
        
            g_error := 'check audit columns - if not exists create';
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'CREATE_USER') = -1
            THEN
                set_audit_column(i_column_name => 'CREATE_USER',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'CREATE_TIME') = -1
            THEN
                set_audit_column(i_column_name => 'CREATE_TIME',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'CREATE_INSTITUTION') = -1
            THEN
                set_audit_column(i_column_name => 'CREATE_INSTITUTION',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'UPDATE_USER') = -1
            THEN
                set_audit_column(i_column_name => 'UPDATE_USER',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'UPDATE_TIME') = -1
            THEN
                set_audit_column(i_column_name => 'UPDATE_TIME',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            IF pk_utils.search_table_varchar(i_table => l_list_cols, i_search => 'UPDATE_INSTITUTION') = -1
            THEN
                set_audit_column(i_column_name => 'UPDATE_INSTITUTION',
                                 i_table       => l_normalized_table,
                                 i_owner       => l_normalized_owner);
            END IF;
        
            g_error := 'CREATE_AUDIT_TRIGGER-';
            IF NOT pk_dev.create_audit_trigger(i_table   => l_normalized_table,
                                               i_owner   => l_normalized_owner,
                                               o_trigger => l_trigger)
            THEN
                NULL;
            END IF;
        
            exec_sql(l_trigger);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(k_package_name || '.create_audit_columns -> ' || g_error || '-' || SQLERRM);
    END create_audit_columns;

    PROCEDURE get_session_vars
    (
        o_obj_name       OUT VARCHAR2,
        o_procedure_name OUT VARCHAR2
    ) IS
        l_obj_name  VARCHAR2(30 CHAR);
        l_proc_name VARCHAR2(30 CHAR);
    
        CURSOR c_vars IS
            SELECT p.object_name, p.procedure_name
              FROM v$session s
              JOIN all_procedures p
                ON s.plsql_entry_object_id = p.object_id
               AND s.plsql_entry_subprogram_id = p.subprogram_id
             WHERE sid = sys_context('USERENV', 'SID');
    
    BEGIN
        OPEN c_vars;
        FETCH c_vars
            INTO l_obj_name, l_proc_name;
        CLOSE c_vars;
    
        o_obj_name       := l_obj_name;
        o_procedure_name := l_proc_name;
    
    END get_session_vars;

    FUNCTION init_macro_description
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_name IN VARCHAR2
    ) RETURN VARCHAR2 IS
        --g_prof_id CONSTANT NUMBER(24) := 2;
    
        --g_prof_institution CONSTANT NUMBER(24) := 3;
        --g_prof_software    CONSTANT NUMBER(24) := 4;
        --g_episode          CONSTANT NUMBER(24) := 5;
        -- g_patient          CONSTANT NUMBER(24) := 6;
        -- g_search_pat_name  CONSTANT NUMBER(24) := 7;
    
        tbl_return table_varchar := table_varchar();
        k_domain_p1_status CONSTANT VARCHAR2(0100 CHAR) := 'P1_EXTERNAL_REQUEST.FLG_STATUS';
        k_domain_p1_type   CONSTANT VARCHAR2(0100 CHAR) := 'P1_EXTERNAL_REQUEST.FLG_TYPE';
        k_domain_yes       CONSTANT VARCHAR2(200 CHAR) := 'YES_NO';
        l_flag   VARCHAR2(1 CHAR) := 'N';
        l_value  VARCHAR2(10 CHAR);
        l_domain VARCHAR2(200 CHAR);
        l_return VARCHAR2(4000);
    BEGIN
    
        g_error := 'i_name' || i_name;
        CASE i_name
            WHEN 'i_prof_id' THEN
                -- l_return := i_prof.id;
                SELECT name
                  BULK COLLECT
                  INTO tbl_return
                  FROM professional
                 WHERE id_professional = i_prof.id;
            WHEN 'i_prof_institution' THEN
            
                SELECT pk_translation.get_translation(i_lang, code_institution)
                  BULK COLLECT
                  INTO tbl_return
                  FROM institution
                 WHERE id_institution = i_prof.institution;
            WHEN 'g_p1_status_q' THEN
                l_flag   := k_yes;
                l_value  := 'Q';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_f' THEN
                l_flag   := k_yes;
                l_value  := 'F';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_s' THEN
                l_flag   := k_yes;
                l_value  := 'S';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_n' THEN
                l_flag   := k_yes;
                l_value  := 'N';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_m' THEN
                l_flag   := k_yes;
                l_value  := 'M';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_d' THEN
                l_flag   := k_yes;
                l_value  := 'D';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_a' THEN
                l_flag   := k_yes;
                l_value  := 'A';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_x' THEN
                l_flag   := k_yes;
                l_value  := 'X';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_i' THEN
                l_flag   := k_yes;
                l_value  := 'N';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_b' THEN
                l_flag   := k_yes;
                l_value  := 'B';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_v' THEN
                l_flag   := k_yes;
                l_value  := 'V';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_r' THEN
                l_flag   := k_yes;
                l_value  := 'R';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_t' THEN
                l_flag   := k_yes;
                l_value  := 'T';
                l_domain := k_domain_p1_status;
            WHEN 'g_p1_status_e' THEN
                l_flag   := k_yes;
                l_value  := 'E';
                l_domain := k_domain_p1_status;
            WHEN 'g_yes' THEN
                l_flag   := k_yes;
                l_value  := 'Y';
                l_domain := k_domain_yes;
            WHEN 'g_p1_type_c' THEN
                l_flag   := k_yes;
                l_value  := 'C';
                l_domain := k_domain_p1_type;
            WHEN 'dt_schedule_limit' THEN
                l_return := 'Date of schedule';
            WHEN 'g_func_d' THEN
                l_return := 'Func D';
            WHEN 'g_func_t' THEN
                l_return := 'Func T';
            WHEN 'g_func_c' THEN
                l_return := 'Func C';
            WHEN 'dt_status_today' THEN
                l_return := 'Today state';
            ELSE
                NULL;
        END CASE;
    
        IF l_flag = k_yes
        THEN
            l_return := pk_sysdomain.get_domain(i_code_dom => l_domain, i_val => l_value, i_lang => i_lang);
        END IF;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END init_macro_description;

BEGIN
    k_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(k_package_name);
END pk_dev;
/
