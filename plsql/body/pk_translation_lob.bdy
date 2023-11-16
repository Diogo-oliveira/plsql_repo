/*-- Last Change Revision: $Rev: 2027814 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_translation_lob AS
    -- #################################################################################################

    -- VARIAVEIS PRIVADAS
    g_chr_comma       CONSTANT t_flg_char := ',';
    g_chr_period      CONSTANT t_flg_char := '.';
    g_chr_semi_column CONSTANT t_flg_char := ';';
    g_2p              CONSTANT t_flg_char := ';';
    g_plicas          CONSTANT t_low_char := '''';
    g_space           CONSTANT t_flg_char := chr(32);
    g_numeric_mask    CONSTANT t_low_char := '999999999999999999999999D999';

    g_tbl_translation_default CONSTANT t_low_char := 'TRANSLATION_LOB';
    g_code_word               CONSTANT t_low_char := '#LANGUAGE#';

    g_sys_cfg_missing_code       CONSTANT t_low_char := 'SHOW_MISSING_TRANSLATION_CODE';
    g_sys_cfg_bck_lang_available CONSTANT t_low_char := 'USE_BCKUP_LANGUAGE';

    --G_PACKAGE_OWNER              CONSTANT T_LOW_CHAR := 'ALERT';
    g_package_name             CONSTANT t_low_char := 'pk_translation_lob';
    g_validation_pattern       CONSTANT t_low_char := '^[A-Z_1]+\.[A-Z_]+\.[-0-9A-Z]+';
    g_wrong_pattern_error_code CONSTANT t_low_num := -20001;

    g_value_default CONSTANT t_low_num := 0;
    g_msg_length    CONSTANT t_low_num := 255;
	
    g_trl_versioning t_low_char := 'Y';

    -- new from bulk processing
    k_insert_mode CONSTANT t_low_char := 'INSERT_MODE';
    k_update_mode CONSTANT t_low_char := 'UPDATE_MODE';

    k_field_name_pattern CONSTANT t_low_char := 'DESC_LANG_';
    k_tbl_real_name      CONSTANT t_low_char := 'TRANSLATION';
    k_schema_core        CONSTANT t_low_char := 'ALERT_CORE_DATA';

    g_last_id_lang  t_big_num;
    g_first_id_lang t_big_num;
    --    trl_lob         t_tbl_translation_lob;
    k_trl_indexes1 CONSTANT t_med_char := 'TRANSLATION_LOB, TRNSLTNLOB_PK';
    --    k_trl_indexes2 CONSTANT t_med_char := 'TRANSLATION, CODE_TRANSLATION_UK';
    -- ########################################################

    g_show_debug BOOLEAN := FALSE;

    g_id_institution t_big_num;
    g_id_software    t_big_num;

    g_default_language     t_low_num;
    g_show_missing_code    t_flg_char;
    g_bckup_lang_available t_flg_char;

    g_tbl_translation t_low_char;
    g_func_name       t_low_char;

    g_upd_sql_part1  t_med_char;
    g_upd_sql_part2  t_med_char;
    g_ins_sql_part1  t_med_char;
    g_ins_sql_part2  t_med_char;
    g_read_sql_part1 t_med_char;
    g_read_sql_part2 t_med_char;

    wrong_pattern EXCEPTION;
    PRAGMA EXCEPTION_INIT(wrong_pattern, -20001);

    -- PRIVATE FUNCTIONS/PROCEDURES
    -- *************************************************************************************************
    FUNCTION iif
    (
        i_expr      IN BOOLEAN,
        i_val_true  IN VARCHAR2,
        i_val_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_expr
        THEN
            RETURN i_val_true;
        ELSE
            RETURN i_val_false;
        END IF;
    
    END iif;

    FUNCTION get_code_word RETURN t_low_char IS
    BEGIN
        RETURN g_code_word;
    END get_code_word;
    FUNCTION get_default_table_name RETURN t_low_char IS
    BEGIN
        RETURN g_tbl_translation_default;
    END get_default_table_name;
    FUNCTION get_validation_pattern RETURN t_med_char IS
    BEGIN
        RETURN g_validation_pattern;
    END get_validation_pattern;

    FUNCTION get_yes RETURN t_flg_char IS
    BEGIN
        RETURN g_yes;
    END get_yes;
    FUNCTION get_no RETURN t_flg_char IS
    BEGIN
        RETURN g_no;
    END get_no;
    FUNCTION get_space RETURN t_flg_char IS
    BEGIN
        RETURN g_space;
    END get_space;
    FUNCTION get_2p RETURN t_flg_char IS
    BEGIN
        RETURN g_2p;
    END get_2p;
    FUNCTION get_chr_comma RETURN t_flg_char IS
    BEGIN
        RETURN g_chr_comma;
    END get_chr_comma;
    FUNCTION get_chr_period RETURN t_flg_char IS
    BEGIN
        RETURN g_chr_period;
    END get_chr_period;
    FUNCTION get_chr_semi_column RETURN t_flg_char IS
    BEGIN
        RETURN g_chr_semi_column;
    END get_chr_semi_column;
    FUNCTION get_plicas RETURN t_low_char IS
    BEGIN
        RETURN g_plicas;
    END get_plicas;
    FUNCTION get_numeric_mask RETURN t_low_char IS
    BEGIN
        RETURN g_numeric_mask;
    END get_numeric_mask;

    FUNCTION get_default_language RETURN t_big_num IS
    BEGIN
        RETURN g_default_language;
    END get_default_language;
    FUNCTION get_show_missing_code RETURN t_flg_char IS
    BEGIN
        RETURN g_show_missing_code;
    END get_show_missing_code;

    PROCEDURE show_text(i_text IN t_msg_char) IS
        l_text t_msg_char;
    BEGIN
    
        l_text := substr(i_text, 1, g_msg_length);
        dbms_output.put_line(l_text);
    
    END show_text;

    /** @clean_value
    * fixed string/marker for NULL updating purpose on TRANSLATION
    *
    * @author     CMF
    *
    * @since      2010/10/21
    */
    FUNCTION clean_value RETURN t_low_char IS
        k_clean_value CONSTANT t_low_char := 'CLEAN_VALUE';
    BEGIN
        RETURN k_clean_value;
    END clean_value;

    /** @get_value
    * function for NULL updating purpose on TRANSLATION_LOB
    * If i_Value equal to clean_Value, update will be with value NULL
    * instead of re-applying same content
    *
    * @param i_Value            value of translation 
    * @param i_default_value    alternate value  if i_Value is null
    *
    * @author     CMF   
    *
    * @since      2010/10/21
    */
    FUNCTION get_value
    (
        i_value         IN t_big_byte,
        i_default_value IN t_big_byte
    ) RETURN t_big_byte IS
        l_return t_big_byte;
    BEGIN
    
        l_return := i_value;
        IF i_value IS NULL
        THEN
            l_return := i_default_value;
        ELSIF i_value = clean_value()
        THEN
            l_return := NULL;
        END IF;
    
        RETURN l_return;
    
    END get_value;

    -- **************************************************************************************************
    PROCEDURE ins_debug
    (
        i_func_name IN t_low_char,
        i_text      IN t_big_char
    ) IS
    BEGIN
    
        IF g_show_debug = TRUE
        THEN
            pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
            show_text(i_text);
        END IF;
    
    END ins_debug;
    -- #################################################################################################

    -- *************************************************************************************************
    PROCEDURE set_id_institution(i_id_institution IN t_big_num DEFAULT NULL) IS
        l_string t_low_char;
        l_tmp    t_low_char;
        l_period t_flg_char;
    BEGIN
    
        g_func_name := 'SET_ID_INSTITUTION';
    
        l_period := get_chr_period;
    
        ins_debug(g_func_name, 'I_ID_INSTITUTION:' || to_char(i_id_institution));
    
        g_id_institution := i_id_institution;
        IF i_id_institution IS NULL
        THEN
        
            l_string := 'NLS_NUMERIC_CHARACTERS = ' || get_plicas() || l_period || get_space() || get_plicas();
        
            l_tmp            := REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, get_chr_semi_column),
                                        get_chr_comma(),
                                        l_period);
            g_id_institution := nvl(to_number(l_tmp, get_numeric_mask(), l_string), g_value_default);
            ins_debug(g_func_name, 'I_ID_INSTITUTION FROM TOKEN:' || to_char(g_id_institution));
        
        END IF;
    
    END set_id_institution;
    -- #################################################################################################

    -- *************************************************************************************************
    PROCEDURE set_id_software(i_id_software IN t_big_num DEFAULT NULL) IS
    BEGIN
    
        g_func_name := 'SET_ID_SOFTWARE';
    
        ins_debug(g_func_name, 'I_ID_SOFTWARE:' || to_char(i_id_software));
    
        g_id_software := i_id_software;
        IF i_id_software IS NULL
        THEN
            g_id_software := nvl(pk_utils.str_token(pk_utils.get_client_id, 3, ';'), g_value_default);
            ins_debug(g_func_name, 'I_ID_SOFTWARE FROM TOKEN:' || to_char(i_id_software));
        END IF;
    
    END set_id_software;

    -- *************************************************************************************************
    FUNCTION get_id_institution RETURN t_big_num IS
    BEGIN
    
        g_func_name := 'GET_ID_INSTITUTION';
    
        IF g_id_institution IS NULL
        THEN
            set_id_institution();
        END IF;
    
        ins_debug(g_func_name, g_func_name || get_2p || to_char(g_id_institution));
        RETURN g_id_institution;
    
    END get_id_institution;
    -- #################################################################################################

    -- *************************************************************************************************
    FUNCTION get_id_software RETURN t_big_num IS
    BEGIN
    
        g_func_name := 'GET_ID_SOFTWARE';
    
        IF g_id_software IS NULL
        THEN
            set_id_software();
        END IF;
    
        ins_debug(g_func_name, g_func_name || get_2p || to_char(g_id_software));
        RETURN g_id_software;
    
    END get_id_software;
    -- #################################################################################################

    -- *************************************************************************************************
    PROCEDURE set_bckp_lang_available(i_flag IN t_flg_char DEFAULT NULL) IS
    BEGIN
    
        g_func_name := 'SET_BCKP_LANG_AVAILABLE';
    
        IF i_flag IS NULL
        THEN
            g_bckup_lang_available := pk_sysconfig.get_config(g_sys_cfg_bck_lang_available,
                                                              get_id_institution(),
                                                              get_id_software());
        ELSE
            g_bckup_lang_available := i_flag;
        END IF;
    
        ins_debug(g_func_name, g_func_name || get_2p || g_bckup_lang_available);
    
    END set_bckp_lang_available;

    -- **************************************************************************************************
    PROCEDURE ins_error
    (
        i_func_name IN t_low_char,
        i_text      IN t_big_char
    ) IS
    BEGIN
    
        pk_alertlog.log_error(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
        show_text(i_text);
    
    END ins_error;

    FUNCTION get_bckp_lang_available RETURN t_flg_char IS
    BEGIN
    
        g_func_name := 'GET_BCKP_LANG_AVAILABLE';
    
        IF g_bckup_lang_available IS NULL
        THEN
            set_bckp_lang_available();
        END IF;
    
        RETURN g_bckup_lang_available;
    
    END get_bckp_lang_available;

    FUNCTION build_sql
    (
        i_lang  IN t_big_num,
        i_part1 IN t_med_char,
        i_part2 IN t_med_char
    ) RETURN t_big_char IS
        l_sql  t_big_char;
        l_lang t_low_char;
    BEGIN
    
        g_func_name := 'BUILD_SQL';
        l_lang      := ltrim(to_char(i_lang));
        l_sql       := i_part1 || l_lang || i_part2;
    
        RETURN l_sql;
    
    END build_sql;

    -- **************************************************************************************************
    FUNCTION build_read_sql(i_lang IN t_big_num) RETURN t_big_char IS
        l_sql t_big_char;
    BEGIN
    
        g_func_name := 'BUILD_READ_SQL';
    
        l_sql := build_sql(i_lang, g_read_sql_part1, g_read_sql_part2);
        RETURN l_sql;
    
    END build_read_sql;

    -- **************************************************************************************************
    FUNCTION build_ins_sql(i_lang IN t_big_num) RETURN t_big_char IS
        l_sql t_big_char;
    BEGIN
    
        g_func_name := 'BUILD_INS_SQL';
    
        l_sql := build_sql(i_lang, g_ins_sql_part1, g_ins_sql_part2);
        RETURN l_sql;
    
    END build_ins_sql;
    -- #################################################################################################

    -- **************************************************************************************************
    FUNCTION build_upd_sql(i_lang IN t_big_num) RETURN t_big_char IS
        l_sql t_big_char;
    BEGIN
    
        g_func_name := 'BUILD_UPD_SQL';
    
        l_sql := build_sql(i_lang, g_upd_sql_part1, g_upd_sql_part2);
        RETURN l_sql;
    
    END build_upd_sql;
    -- #################################################################################################

    -- **************************************************************************************************
    FUNCTION get_translation_internal
    (
        i_lang IN language.id_language%TYPE,
        i_code IN t_code
    ) RETURN CLOB IS
        l_desc_lang table_clob;
        l_return    CLOB;
        l_sql       t_big_char;
    BEGIN
    
        g_func_name := 'GET_TRANSLATION_INTERNAL';
    
        l_sql := build_read_sql(i_lang);
    
        ins_debug(g_func_name, 'EXECUTE:' || l_sql);
        EXECUTE IMMEDIATE l_sql BULK COLLECT
            INTO l_desc_lang
            USING i_code;
    
        ins_debug(g_func_name, 'RETURNED ROWS:' || to_char(l_desc_lang.count));
    
        IF l_desc_lang.count = 0
        THEN
            l_return := NULL;
        ELSE
            l_return := l_desc_lang(1);
        END IF;
    
        RETURN l_return;
    
    END get_translation_internal;
    -- #################################################################################################

    /** @GET_TRANSLATION
    * Public Function. Get translation of given code
    * @param      I_LANG                 Language for translation
    * @param      I_CODE_MESS           identifier to get translated
    * @param      O_DESC_MESS           translation ( overload )
    *
    * @author     CMF
    * @version    1.0
    * @since      2010/10/21
    */
    FUNCTION get_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN t_code,
        o_desc_mess OUT t_desc_translation
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_desc_mess := get_translation(i_lang, i_code_mess);
    
        RETURN TRUE;
    
    END get_translation;
    -- #################################################################################################

    -- **************************************************************************************************
    FUNCTION get_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN t_code
    ) RETURN CLOB IS
        l_desc_lang         CLOB;
        l_show_code_if_null BOOLEAN;
    BEGIN
    
        g_func_name := 'UPD_TRANSLATION_INTERNAL';
    
        ins_debug(g_func_name, 'CODE:' || i_code_mess);
        IF i_code_mess IS NOT NULL
        THEN
        
            <<get_prefered_language>>
            BEGIN
                l_desc_lang := get_translation_internal(i_lang => i_lang, i_code => i_code_mess);
            END get_prefered_language;
        
            <<get_instit_lang_if_lang_null>>
            BEGIN
                IF l_desc_lang IS NULL
                THEN
                    IF get_bckp_lang_available = get_yes
                    THEN
                        l_desc_lang := get_translation_internal(i_lang => get_default_language, i_code => i_code_mess);
                    END IF;
                END IF;
            END get_instit_lang_if_lang_null;
        
            <<return_code_if_desc_is_null>>
            BEGIN
                l_show_code_if_null := (l_desc_lang IS NULL) AND (get_show_missing_code = get_yes);
                IF l_show_code_if_null = TRUE
                THEN
                    l_desc_lang := i_code_mess;
                END IF;
            END return_code_if_desc_is_null;
        
        END IF;
    
        RETURN l_desc_lang;
    
        --EXCEPTION
        --WHEN OTHERS THEN RETURN L_DESC_LANG;
    END get_translation;

    PROCEDURE set_default_language(i_lang IN language.id_language%TYPE DEFAULT NULL) IS
    BEGIN
    
        g_func_name := 'SET_DEFAULT_LANGUAGE';
        IF i_lang IS NULL
        THEN
            g_default_language := pk_utils.get_institution_language(get_id_institution, get_id_software);
        ELSE
            g_default_language := i_lang;
        END IF;
    
        ins_debug(g_func_name, g_func_name || get_2p || to_char(g_default_language));
    
    END set_default_language;

    PROCEDURE set_show_missing_code(i_flag IN t_flg_char DEFAULT NULL) IS
    BEGIN
    
        g_func_name := 'SET_SHOW_MISSING_CODE';
    
        IF i_flag IS NULL
        THEN
            g_show_missing_code := pk_sysconfig.get_config(g_sys_cfg_missing_code, get_id_institution, get_id_software);
        ELSE
            g_show_missing_code := i_flag;
        END IF;
    
        ins_debug(g_func_name, g_func_name || get_2p || g_show_missing_code);
    
    END set_show_missing_code;

    -- PUBLIC FUNCTIONS/PROCEDURES
    /** @get_table_name
    * Public Function. Get target table for translations
    *
    * @author     CMF
    * @version    1.0
    * @since      2010/10/21
    */
    FUNCTION get_table_name RETURN t_low_char IS
    BEGIN
        RETURN nvl(g_tbl_translation, get_default_table_name);
    END get_table_name;

    -- **************************************************************************************************
    /** @set_table_name
    * Public Function. Set target table for translations
    *
    * @param      i_table_name                 Target table for translations
    *
    * @author     CMF
    * @version    1.0
    * @since      2010/10/21
    */
    PROCEDURE set_table_name(i_table_name IN t_low_char DEFAULT NULL) IS
    BEGIN
        g_tbl_translation := nvl(i_table_name, get_default_table_name);
    END set_table_name;

    -- **************************************************************************************************
    PROCEDURE ready_sql IS
        l_table     t_low_char;
        l_code_word t_low_char;
        l_sp        t_flg_char;
    BEGIN
    
        g_func_name := 'SET_SQL';
    
        l_table     := get_table_name();
        l_code_word := get_code_word();
        l_sp        := get_space();
    
        ins_debug(g_func_name, 'TABLE_NAME:' || l_table || '--CODE_WORD:' || l_code_word);
    
        g_upd_sql_part1 := 'UPDATE ' || l_table || ' SET DESC_LANG_';
        g_upd_sql_part2 := ' = :I_DESC WHERE CODE_TRANSLATION = :CODE_TRANSLATION';
    
        ins_debug(g_func_name, 'UPD_SQL READY');
    
        g_ins_sql_part1 := 'INSERT INTO ' || l_table || ' ( ID_TRANSLATION, DESC_LANG_';
        g_ins_sql_part2 := ', CODE_TRANSLATION ) VALUES ( SEQ_TRANSLATION_LOB.NEXTVAL, :I_DESC, :I_CODE )';
    
        ins_debug(g_func_name, 'INS_SQL READY');
    
        g_read_sql_part1 := 'SELECT DESC_LANG_';
        g_read_sql_part2 := l_sp || 'FROM' || l_sp || l_table || l_sp || 'WHERE CODE_TRANSLATION = :1';
    
        ins_debug(g_func_name, 'INS_READY READY');
    
    END ready_sql;

    -- **************************************************************************************************
    FUNCTION run_execute
    (
        i_sql  IN t_big_char,
        i_code IN t_code,
        i_desc IN t_desc
    ) RETURN t_big_num IS
    BEGIN
    
        g_func_name := 'RUN_EXECUTE';
        ins_debug(g_func_name, 'SQL:' || i_sql);
        EXECUTE IMMEDIATE i_sql
            USING i_desc, i_code;
    
        RETURN SQL%ROWCOUNT;
    
    END run_execute;

    -- **************************************************************************************************
    FUNCTION ins_translation_internal
    (
        i_lang IN language.id_language%TYPE,
        i_code IN t_code,
        i_desc IN t_desc
    ) RETURN t_big_num IS
        l_sql   t_big_char;
        l_error t_med_char;
        l_count t_big_num;
    
    BEGIN
    
        g_func_name := 'INS_TRANSLATION_INTERNAL';
    
        l_error := 'I_LANG' || to_char(i_lang) || '--CODE:' || i_code;
        ins_debug(g_func_name, l_error);
    
        l_sql := build_ins_sql(i_lang);
    
        ins_debug(g_func_name, 'SQL:' || l_sql);
    
        l_count := run_execute(l_sql, i_code, i_desc);
    
        RETURN l_count;
    
    END ins_translation_internal;
    -- #################################################################################################

    -- **************************************************************************************************
    FUNCTION upd_translation_internal
    (
        i_lang IN language.id_language%TYPE,
        i_code IN t_code,
        i_desc IN t_desc
    ) RETURN t_big_num IS
        l_sql   t_big_char;
        l_error t_med_char;
        l_count t_big_num;
    BEGIN
    
        g_func_name := 'UPD_TRANSLATION_INTERNAL';
    
        l_error := 'I_LANG' || to_char(i_lang) || '--CODE:' || i_code;
        ins_debug(g_func_name, l_error);
    
        l_sql := build_upd_sql(i_lang);
    
        ins_debug(g_func_name, 'SQL:' || l_sql);
        l_count := run_execute(l_sql, i_code, i_desc);
    
        RETURN l_count;
    
    END upd_translation_internal;
    -- #################################################################################################

    /** @INSERT_INTO_TRANSLATION
    * Public Function. Set code_translation given to format <TABLE.COLUMN_NAME>
    * @param      I_LANG                 Language for translation
    * @param      code_trans             identifier of translation
    * @param      i_desc_trans           translation
    * @param      i_module               related module ( obsolete, only for retrocompatibility ) ( overload )
    *
    * @author     CMF
    * @version    1.0
    * @since      2010/10/21
    */
    PROCEDURE insert_into_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_code_trans IN t_code,
        i_desc_trans IN t_desc,
        i_module     IN t_module
    ) IS
    BEGIN
    
        insert_into_translation(i_lang, i_code_trans, i_desc_trans);
    
    END insert_into_translation;
    -- #################################################################################################

    -- **************************************************************************************************
    FUNCTION validate_trl_pattern(i_string IN t_big_char) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        l_ret := regexp_like(i_string, get_validation_pattern);
        RETURN l_ret;
    END validate_trl_pattern;

    -- **************************************************************************************************
    PROCEDURE insert_into_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_code_trans IN t_code,
        i_desc_trans IN t_desc
    ) IS
        l_row_count t_big_num;
        l_msg       CLOB;
    BEGIN
    
        g_func_name := 'INSERT_INTO_TRANSLATION';
        l_msg       := 'I_LANG' || to_char(i_lang) || '--CODE:' || i_code_trans || '--DESC:' || i_desc_trans;
    
        IF i_desc_trans IS NOT NULL
        THEN
        
            IF validate_trl_pattern(i_code_trans) = TRUE
            THEN
            
                ins_debug(g_func_name, 'UPD_INTERNAL:' || l_msg);
                l_row_count := upd_translation_internal(i_lang, i_code_trans, i_desc_trans);
                ins_debug(g_func_name, 'UPD_INTERNAL ROWCOUNT:' || to_char(l_row_count));
            
                IF l_row_count = 0
                THEN
                    ins_debug(g_func_name, 'INS_INTERNAL:' || l_msg);
                    l_row_count := ins_translation_internal(i_lang, i_code_trans, i_desc_trans);
                
                    pk_translation.set_trl_versioning(i_trl_owner    => 'ALERT',
                                                      i_trl_tbl_name => g_tbl_translation_default,
                                                      i_code         => i_code_trans);
                
                    ins_debug(g_func_name, 'INS_INTERNAL ROWCOUNT:' || to_char(l_row_count));
                END IF;
            
            ELSE
                RAISE wrong_pattern;
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN wrong_pattern THEN
            l_msg := 'INSERTION ABORTED: WRONG PATTERN GIVEN:' || i_code_trans;
            ins_error(g_func_name, l_msg);
            raise_application_error(g_wrong_pattern_error_code, l_msg);
        WHEN OTHERS THEN
            l_msg := 'ERROR INSERTING ' || i_code_trans;
            ins_error(g_func_name, l_msg);
            RAISE;
    END insert_into_translation;

    /** @get_search_translation
    * Public Function. Given a context and a term to search, returns the correspondent matches from the table TRANSLATION_LOB.
    * @param      I_LANG                   Language for translation
    * @param      i_search                 The string to be searched
    * @param      i_column_name            The code_translation without id (can be formatted using pk_translation.format_column_name)
    * @param      i_relevance              The relevance value. Use only if want to show the relevance value.
    * @param      i_paging                 Apply paging 
    * @param      i_start_record           The initial position in result set
    * @param      i_num_records            The number of rows to return from result set
    * @param      i_order_trans            Apply alphabetic order. 
    * @param      i_use_wildcard           Force multiple character wildcard ('*')
    * @param      i_highlight              Apply highlight to search results
    * @param      i_escape_special_chars   Escape special characters
    *
    * @author     PP
    * @version    1.0
    * @since      2011/FEB/04
    */
    FUNCTION get_search_translation
    (
        i_lang                 IN language.id_language%TYPE,
        i_search               IN t_desc,
        i_column_name          IN t_low_char,
        i_relevance            IN t_flg_char DEFAULT NULL,
        i_paging               IN t_flg_char DEFAULT NULL,
        i_start_record         IN t_big_num DEFAULT NULL,
        i_num_records          IN t_big_num DEFAULT NULL,
        i_order_trans          IN t_flg_char DEFAULT NULL,
        i_use_wildcard         IN t_flg_char DEFAULT NULL,
        i_highlight            IN t_flg_char DEFAULT NULL,
        i_escape_special_chars IN t_flg_char DEFAULT NULL
    ) RETURN table_t_search_lob IS
    
        l_out_rec table_t_search_lob := table_t_search_lob(NULL);
        l_sql     t_big_char;
        l_search  t_big_char;
        l_no      t_flg_char := get_no;
        --l_yes                  t_flg_char := get_yes;
        l_tmp          t_flg_char;
        l_relevance    t_flg_char;
        l_paging       t_flg_char;
        l_start_record t_big_num;
        l_num_records  t_big_num;
        l_order_trans  t_flg_char;
        l_table        user_tables.table_name%TYPE := get_default_table_name();
        --l_hits                 t_big_num;
        l_use_wildcard         t_flg_char;
        l_highlight            t_flg_char;
        l_escape_special_chars t_flg_char;
    BEGIN
    
        g_func_name := 'GET_SEARCH_TRANSLATION';
    
        ins_debug(g_func_name, 'COLUMN_NAME:' || i_column_name);
    
        l_search               := TRIM(i_search);
        l_relevance            := nvl(i_relevance, l_no);
        l_paging               := nvl(i_paging, l_no);
        l_start_record         := nvl(i_start_record, pk_lucene.get_default_start_record);
        l_num_records          := nvl(i_num_records, pk_lucene.get_num_records);
        l_order_trans          := nvl(i_order_trans, l_no);
        l_tmp                  := l_no;
        l_use_wildcard         := nvl(i_use_wildcard, l_no);
        l_highlight            := nvl(i_highlight, l_no);
        l_escape_special_chars := nvl(i_escape_special_chars, get_yes());
    
        /* avoid empty search */
        IF (nvl(length(l_search), 0) = 0)
        THEN
            RETURN NULL;
        END IF;
    
        ins_debug(g_func_name, 'USE_WILDCARD:' || l_use_wildcard);
    
        ins_debug(g_func_name, 'ORDER_TRANS:' || l_order_trans);
        IF l_order_trans = l_no
        THEN
            l_tmp := l_paging;
        END IF;
    
        l_search := pk_lucene.build_query_string(i_lang,
                                                 l_search,
                                                 i_column_name,
                                                 l_tmp,
                                                 l_start_record,
                                                 l_num_records,
                                                 l_use_wildcard,
                                                 NULL,
                                                 l_escape_special_chars);
    
        IF (nvl(length(l_search), 0) = 0)
        THEN
            RETURN NULL;
        END IF;
    
        ins_debug(g_func_name, 'GET LCONTAINS QUERY');
    
        l_sql := pk_lucene.build_sql_string(l_table,
                                            i_lang,
                                            l_relevance,
                                            l_paging,
                                            l_start_record,
                                            l_num_records,
                                            l_order_trans,
                                            l_highlight);
    
        ins_debug(g_func_name, 'SEARCH QUERY:' || l_sql || ', USING: ' || l_search);
    
        EXECUTE IMMEDIATE l_sql BULK COLLECT
            INTO l_out_rec
            USING l_search;
    
        g_count_error := 0;
    
        RETURN l_out_rec;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE IN (-1555, -29902, -29903)
            THEN
                IF g_count_error < 2
                THEN
                    g_count_error := g_count_error + 1;
                    g_func_name   := 'GET_TRANSLATION_SEARCH';
                    ins_debug(g_func_name, 'ERROR: ' || SQLCODE || ' Try again: (' || g_count_error || ')');
                    g_endsession := dbms_java.endsession;
                    ins_debug(g_func_name, 'Clear Java session state: ' || g_endsession);
                
                    RETURN get_search_translation(i_lang,
                                                  i_search,
                                                  i_column_name,
                                                  i_relevance,
                                                  i_paging,
                                                  i_start_record,
                                                  i_num_records,
                                                  i_order_trans,
                                                  i_use_wildcard,
                                                  i_highlight,
                                                  i_escape_special_chars);
                ELSE
                    RAISE;
                END IF;
            ELSE
                RAISE;
            END IF;
        
    END get_search_translation;

    -- **************************************************************************************************
    PROCEDURE initialize IS
    BEGIN
        g_func_name := 'INICIALIZE';
    
        ins_debug(g_func_name, 'RUNNING...');
    
        set_id_institution();
        set_id_software();
    
        set_default_language();
        set_show_missing_code();
        set_bckp_lang_available();
    
        set_table_name(get_default_table_name);
		
        g_trl_versioning := nvl(pk_sysconfig.get_config('TRL_VERSIONING_ENABLED', profissional(0, 0, 0)), 'Y');
		
        ready_sql;
    
        ins_debug(g_func_name, 'ENDING...');
    
    END initialize;

    -- *************************************************************************************************
    FUNCTION get_first_id_lang RETURN t_low_num IS
    BEGIN
        RETURN g_first_id_lang;
    END get_first_id_lang;

    FUNCTION get_last_id_lang RETURN t_low_num IS
    BEGIN
        RETURN g_last_id_lang;
    END get_last_id_lang;

    FUNCTION get_idx_code RETURN t_low_num IS
        k_inc_field_code CONSTANT t_low_num := 1;
    BEGIN
        RETURN get_last_id_lang() + k_inc_field_code;
    END get_idx_code;

    FUNCTION get_idx_id RETURN t_low_num IS
        k_inc_field_code CONSTANT t_low_num := 2;
    BEGIN
        RETURN get_last_id_lang() + k_inc_field_code;
    END get_idx_id;

    PROCEDURE set_min_max_id_lang IS
        k_empty_string CONSTANT t_low_char := '';
        k_field_name   CONSTANT t_low_char := k_field_name_pattern;
    BEGIN
    
        SELECT MAX(ids) max_id, MIN(ids) min_id
          INTO g_last_id_lang, g_first_id_lang
          FROM (SELECT to_number(REPLACE(column_name, k_field_name, k_empty_string)) ids
                  FROM all_tab_columns
                 WHERE table_name = k_tbl_real_name
                   AND owner = k_schema_core
                   AND column_name LIKE k_field_name || '%');
    
    END set_min_max_id_lang;
    --######################################################################################

    FUNCTION build_ins_bulk_lob(i_ignore_dup IN t_flg_char DEFAULT g_no) RETURN t_big_byte IS
    
        k_func_name CONSTANT t_low_char := 'BUILD_INS_BULK_LOB';
        l_sql        t_big_byte;
        l_fields     t_big_byte;
        l_values     t_big_byte;
        g_insert_cmd t_low_char;
        l_bool       BOOLEAN;
    
        k_desc_field_name CONSTANT t_low_char := k_field_name_pattern;
        k_p               CONSTANT t_flg_char := ':';
        k_sp              CONSTANT t_flg_char := g_space;
        k_hint_str1       CONSTANT t_low_char := '/*+ ignore_row_on_dupkey_index(';
        k_hint_str9       CONSTANT t_low_char := ') */';
        k_hint1           CONSTANT t_med_char := k_hint_str1 || k_trl_indexes1 || k_hint_str9;
        --        k_hint2           CONSTANT t_med_char := k_hint_str1 || k_trl_indexes2 || k_hint_str9;
        k_hint3      CONSTANT t_big_char := k_hint1; -- || k_sp || k_hint2;
        k_idx_fields CONSTANT t_low_char := ', code_translation, id_translation ) values (';
    
    BEGIN
    
        set_min_max_id_lang();
    
        l_bool       := (i_ignore_dup = g_no);
        g_insert_cmd := 'insert ' || iif((l_bool), '', k_hint3) || ' into';
    
        -- Build beginning expression
        l_sql := g_insert_cmd || k_sp || get_table_name() || '(';
    
        -- 1? elements
        l_fields := k_desc_field_name || to_char(get_first_id_lang());
        l_values := k_p || to_char(get_first_id_lang());
    
        <<loop_thru_languages>>
        FOR i IN (get_first_id_lang() + 1) .. get_last_id_lang()
        LOOP
            -- set destination fields
            l_fields := l_fields || g_chr_comma || k_desc_field_name || to_char(i);
        
            -- set binding values
            l_values := l_values || g_chr_comma || k_p || to_char(i);
        END LOOP loop_thru_languages;
    
        ins_debug(k_func_name, 'VAL1:' || l_values);
    
        --        l_values := l_values || g_chr_comma || k_p || get_idx_module();
        l_values := l_values || g_chr_comma || k_p || get_idx_code();
        l_values := l_values || g_chr_comma || k_p || get_idx_id();
    
        ins_debug(k_func_name, 'VAL2:' || l_values);
    
        l_fields := l_fields || k_idx_fields || l_values || ')';
    
        l_sql := l_sql || k_sp || l_fields;
    
        ins_debug(k_func_name, 'INS_BULK:' || l_sql);
    
        RETURN l_sql;
    
    END build_ins_bulk_lob;

    /** @build_upd_bulk_lob
    * build sql statement for update operation
    *
    * @param i_ignore_dup   Set to N to allow ignore on duplicate rows
    *
    * @author     CMF
    *
    * @since      2010/10/21
    */
    FUNCTION build_upd_bulk_lob RETURN t_big_byte IS
        l_sql    t_big_byte;
        l_fields t_big_byte;
        l_tmp    t_big_byte;
        l_chk    t_big_byte;
        l_idx    t_low_char;
        k_func_name       CONSTANT t_low_char := 'build_upd_bulk';
        k_desc_field_name CONSTANT t_low_char := k_field_name_pattern;
        k_p               CONSTANT t_flg_char := ':';
        k_sp              CONSTANT t_flg_char := g_space;
        k_equal           CONSTANT t_low_char := k_sp || '=' || k_sp;
        k_lf              CONSTANT t_low_char := chr(10);
    
        k_table_marker CONSTANT t_low_char := '#TABLE#';
        k_update_cmd   CONSTANT t_low_char := 'update ' || k_table_marker || ' set';
        k_check_marker CONSTANT t_low_char := g_package_name || '.get_value(';
        k_where_cmd    CONSTANT t_low_char := 'where ';
        k_code         CONSTANT t_low_char := 'code_translation = ';
        k_msg_max_len  CONSTANT t_big_num := 2000;
        l_where t_big_char;
    BEGIN
    
        set_min_max_id_lang();
    
        -- Build beginning expression
        l_sql := REPLACE(k_update_cmd, k_table_marker, get_table_name()) || k_lf;
    
        ins_debug(k_func_name, 'SQL INICIAL:' || substr(l_sql, 1, k_msg_max_len));
        <<loop_thru_languages>>
        FOR i IN get_first_id_lang() .. get_last_id_lang()
        LOOP
            l_idx := to_char(i);
            -- set destination fields
            l_tmp := k_desc_field_name || l_idx;
            l_chk := k_check_marker || k_sp || k_p || l_idx || k_sp || g_chr_comma || l_tmp || k_sp || ')';
            l_tmp := l_tmp || k_equal || l_chk;
            IF i != get_last_id_lang()
            THEN
                l_fields := l_fields || l_tmp || g_chr_comma || k_lf;
            ELSE
                l_fields := l_fields || l_tmp;
            END IF;
            ins_debug(k_func_name, 'IN CICLO:' || l_tmp || g_chr_comma);
        END LOOP loop_thru_languages;
    
        ins_debug(k_func_name, 'SQL APOS CICLO:' || substr(l_sql, 1, k_msg_max_len));
    
        --l_fields := l_fields || k_module_marker || k_p || get_idx_module();
        --ins_debug(k_func_name, 'FIELD:' || l_fields);
        l_sql := l_sql || l_fields;
    
        --l_where := k_owner || k_p || get_idx_owner() || ' and ' || k_code || k_p || get_idx_code();
        l_where := k_code || k_p || get_idx_code();
    
        ins_debug(k_func_name, 'WHE:' || l_where);
        l_sql := l_sql || k_lf || k_where_cmd || l_where;
    
        ins_debug(k_func_name, 'SQL:' || substr(l_sql, 1, 2 * k_msg_max_len));
    
        RETURN l_sql;
    
    END build_upd_bulk_lob;

	-- ********************************************************************
    FUNCTION ins_bulk_values_lob
    (
        i_sql IN t_big_byte,
        i_tab IN t_tbl_translation_lob
    ) RETURN t_big_num IS
        l_count t_big_num;
    BEGIN
    
        FORALL i IN i_tab.first .. i_tab.last EXECUTE IMMEDIATE i_sql USING i_tab(i).desc_lang_1, i_tab(i).desc_lang_2, i_tab(i)
                                  .desc_lang_3, i_tab(i).desc_lang_4, i_tab(i).desc_lang_5, i_tab(i).desc_lang_6, i_tab(i)
                                  .desc_lang_7, i_tab(i).desc_lang_8, i_tab(i).desc_lang_9, i_tab(i).desc_lang_10, i_tab(i)
                                  .desc_lang_11, i_tab(i).desc_lang_12, i_tab(i).desc_lang_13, i_tab(i).desc_lang_14, i_tab(i)
                                  .desc_lang_15, i_tab(i).desc_lang_16, i_tab(i).desc_lang_17, i_tab(i).desc_lang_18, i_tab(i)
                                  .desc_lang_19, i_tab(i).code_translation, i_tab(i).id_translation
            ;
    
        l_count := SQL%ROWCOUNT;
        RETURN l_count;
    
    END ins_bulk_values_lob;

	-- ********************************************************************
    FUNCTION upd_bulk_values_lob
    (
        i_sql IN t_big_byte,
        i_tab IN t_tbl_translation_lob
    ) RETURN t_big_num IS
        l_count t_big_num;
    BEGIN
    
        FORALL i IN i_tab.first .. i_tab.last EXECUTE IMMEDIATE i_sql USING i_tab(i).desc_lang_1, i_tab(i).desc_lang_2, i_tab(i)
                                  .desc_lang_3, i_tab(i).desc_lang_4, i_tab(i).desc_lang_5, i_tab(i).desc_lang_6, i_tab(i)
                                  .desc_lang_7, i_tab(i).desc_lang_8, i_tab(i).desc_lang_9, i_tab(i).desc_lang_10, i_tab(i)
                                  .desc_lang_11, i_tab(i).desc_lang_12, i_tab(i).desc_lang_13, i_tab(i).desc_lang_14, i_tab(i)
                                  .desc_lang_15, i_tab(i).desc_lang_16, i_tab(i).desc_lang_17, i_tab(i).desc_lang_18, i_tab(i)
                                  .desc_lang_19, i_tab(i).code_translation
            ;
    
        l_count := SQL%ROWCOUNT;
        RETURN l_count;
    
    END upd_bulk_values_lob;

	-- ********************************************************************
    FUNCTION set_bulk_trl_lob_internal
    (
        i_mode       IN t_low_char,
        i_tab        IN t_tbl_translation_lob,
        i_ignore_dup IN t_flg_char DEFAULT 'N'
    ) RETURN t_big_num IS
        --k_func_name CONSTANT t_low_char := 'SET_BULK_TRL_LOB_INTERNAL';
        l_sql   t_big_byte;
        l_count t_big_num;
    BEGIN
    
        CASE i_mode
            WHEN k_insert_mode THEN
                l_sql   := build_ins_bulk_lob(i_ignore_dup);
                l_count := ins_bulk_values_lob(l_sql, i_tab);
            WHEN k_update_mode THEN
                l_sql   := build_upd_bulk_lob();
                l_count := upd_bulk_values_lob(l_sql, i_tab);
        END CASE;
    
        RETURN l_count;
    
    END set_bulk_trl_lob_internal;

	-- ********************************************************************
    FUNCTION upd_bulk_translation_lob(i_tab IN t_tbl_translation_lob) RETURN t_big_num IS
        l_count t_big_num;
    BEGIN
        l_count := set_bulk_trl_lob_internal(k_update_mode, i_tab);
        RETURN l_count;
    END upd_bulk_translation_lob;

    -- ####################################################################
    FUNCTION ins_bulk_translation_lob
    (
        i_tab        IN t_tbl_translation_lob,
        i_ignore_dup IN t_flg_char DEFAULT g_no
    ) RETURN t_big_num IS
        l_count t_big_num;
    BEGIN
        l_count := set_bulk_trl_lob_internal(k_insert_mode, i_tab, i_ignore_dup);
		
		ins_bulk_trl_versioning(i_tab => i_tab );
		
        RETURN l_count;
    END ins_bulk_translation_lob;
	
	
	-- *********************************************************************************
    PROCEDURE ins_bulk_trl_versioning(i_tab IN t_tbl_translation_lob) IS
        l_tab_pos  NUMBER;
        l_col_pos  NUMBER;
        l_table    VARCHAR2(0100 CHAR);
        l_col_name VARCHAR2(0100 CHAR);
    BEGIN

        IF g_trl_versioning = 'Y'
        THEN
    
			FORALL i IN 1 .. i_tab.count
				INSERT /*+ ignore_row_on_dupkey_index( TRL_VERSIONING, TRL_VERSIONING_PK ) */
				INTO trl_versioning
					(trl_owner, trl_tbl_name, table_name, column_name, flg_translatable)
					SELECT k_schema_core trl_owner,
						   k_tbl_real_name trl_tbl_name,
						   substr(i_code, 1, l_tab_pos - 1) table_name,
						   substr(i_code, l_tab_pos + 1, (l_col_pos - l_tab_pos) - 1) column_name,
						   'N/A' flg_translatable
					  FROM (SELECT i_code, instr(i_code, '.', 2, 1) l_tab_pos, instr(i_code, '.', 2, 2) l_col_pos
							  FROM (SELECT i_tab(i).code_translation i_code
									  FROM dual)) xsql;
								  
		end if;
    
    END ins_bulk_trl_versioning;
	

BEGIN

    pk_alertlog.log_init(object_name => g_package_name);

    initialize;
END pk_translation_lob;
/
