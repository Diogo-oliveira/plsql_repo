/*-- Last Change Revision: $Rev: 2027753 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_string_utils IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /**
    * Remove duplicated values of a varchar2 that corresponds in multiple elements delimited with a separator
    * Example: remove_repeated('1;2;1', ';') returns '1;2'
    *
    * @param i_input               the varchar2 to be processed
    * @param i_delim                the delimiter used, default ','
    *
    * @return              varchar2 -  a varchar2 without duplicated values
    *
    * @since 2008-06-16
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION remove_repeated
    (
        i_input VARCHAR2,
        i_delim VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 IS
        l_string_table table_varchar2 := pk_utils.str_split(i_input, i_delim);
    
        l_string_result VARCHAR2(32767) := i_delim;
    BEGIN
        --- Validations ---
        IF i_input IS NULL
        THEN
            RETURN NULL;
        END IF;
        -------------------
    
        --for each token of the string
        FOR i IN 1 .. l_string_table.count
        LOOP
            --is the token already in the result string?
            IF instr(l_string_result, i_delim || l_string_table(i) || i_delim) = 0
               OR instr(l_string_result, l_string_table(i)) IS NULL
            THEN
                --concatenate current position
                l_string_result := l_string_result || l_string_table(i);
            
                --concatenate delim
                l_string_result := l_string_result || i_delim;
            END IF;
        END LOOP;
    
        --remove last delim
        l_string_result := substr(l_string_result, length(i_delim) + 1, length(l_string_result) - length(i_delim));
    
        RETURN l_string_result;
    END remove_repeated;

    /********************************************************************************************
    * Returns a VARCHAR2 from a CLOB (truncating to i_maxlenght_bytes size)
    *
    
    * @param i_clob                      CLOB value                        
    * @param i_maxlenght_bytes           Max size (bytes)
    * @return                            VARCHAR2
    *
    * @author  ARIEL.MACHADO
    * @version 1.0 (v2.6)
    * @since   04-Oct-10
    * If database is using multi-byte character set where single character can occupy multiple bytes.
    * Therefore 4000 characters returned by DBMS_LOB.SUBSTR(i_clob,4000) occupy more than 4000 bytes.
    * VARCHAR2 in Oracle SQL holds up to 4000 bytes, not up to 4000 characters.
    * An approach was implemented to return a substring expressing their limit in bytes
    **********************************************************************************************/
    FUNCTION clob_to_varchar2
    (
        i_clob            IN CLOB,
        i_maxlenght_bytes IN NUMBER
    ) RETURN VARCHAR2 IS
        l_buffer VARCHAR2(32767);
        l_lenght NUMBER;
    BEGIN
        l_lenght := least(i_maxlenght_bytes, dbms_lob.getlength(i_clob));
    
        WHILE lengthb(dbms_lob.substr(i_clob, l_lenght, 1)) > i_maxlenght_bytes
        LOOP
            l_lenght := l_lenght - 1;
        END LOOP;
    
        l_buffer := dbms_lob.substr(i_clob, l_lenght, 1);
        RETURN l_buffer;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END clob_to_varchar2;

    /********************************************************************************************
    * Returns a VARCHAR2 from a CLOB (truncating to max SQL VARCHAR2 size)
    *
    
    * @param i_clob                      CLOB value                        
    * @return                            VARCHAR2
    *
    * @author  ARIEL.MACHADO
    * @version 1.0 (v2.5)
    * @since   26-May-09
    **********************************************************************************************/
    FUNCTION clob_to_sqlvarchar2(i_clob IN CLOB) RETURN VARCHAR2 IS
    BEGIN
        RETURN clob_to_varchar2(i_clob, pk_alert_constant.g_sql_varchar2_maxsize);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END clob_to_sqlvarchar2;

    /********************************************************************************************
    * Returns a VARCHAR2 from a CLOB (truncating to max PL/SQL VARCHAR2 size)
    *
    
    * @param i_clob                      CLOB value                        
    * @return                            VARCHAR2
    *
    * @author  ARIEL.MACHADO
    * @version 1.0 (v2.5)
    * @since   26-May-09
    **********************************************************************************************/
    FUNCTION clob_to_plsqlvarchar2(i_clob IN CLOB) RETURN VARCHAR2 IS
    BEGIN
        RETURN clob_to_varchar2(i_clob, pk_alert_constant.g_plsql_varchar2_maxsize);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END clob_to_plsqlvarchar2;

    /*********************************************************************************************
    * Split varchar into multiple tokens which can be used in PL/SQL scope
    * 
    * @param i_list   the input varchar 
    * @param i_delim  the delimiter
    *
    * @return a table_varchar 
    ********************************************************************************************/
    FUNCTION str_split
    (
        i_list  IN VARCHAR2,
        i_delim IN VARCHAR2 DEFAULT ','
    ) RETURN table_varchar IS
        l_idx       PLS_INTEGER;
        l_table_idx PLS_INTEGER;
        l_line      VARCHAR2(32767);
        l_list      VARCHAR2(32767) := i_list;
        l_ret       table_varchar := table_varchar();
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

    /*********************************************************************************************
    * Split varchar into multiple tokens which can be used in PL/SQL scope
    * 
    * @param i_list   the input varchar 
    * @param i_nr_of_chars  Nr of chars for each result
    *
    * @return a table_varchar 
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   19-Apr-2012
    ********************************************************************************************/
    FUNCTION str_split_pos
    (
        i_list        IN VARCHAR2,
        i_nr_of_chars IN PLS_INTEGER DEFAULT 1
    ) RETURN table_varchar IS
        l_idx       PLS_INTEGER;
        l_table_idx PLS_INTEGER;
        l_line      pk_translation.t_desc_translation;
        l_list      pk_translation.t_desc_translation := i_list;
        l_ret       table_varchar := table_varchar();
    BEGIN
    
        IF l_list IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_table_idx := 1;
        LOOP
            l_line := substr(l_list, 1, i_nr_of_chars);
            IF (l_line IS NOT NULL)
            THEN
                l_list := substr(l_list, 1 + i_nr_of_chars);
            
                l_ret.extend;
                l_ret(l_table_idx) := TRIM(l_line);
                l_table_idx := l_table_idx + 1;
            ELSE
                EXIT;
            END IF;
        
        END LOOP;
        RETURN l_ret;
    END str_split_pos;

    /*********************************************************************************************
    * Chops out the rightmost character(s) of a string
    * 
    * @param i_string     Original string
    * @param i_num_chars  Number of characters (default is 1)
    *
    * @return             The chopped string
    *
    * @author             Joao Martins
    * @version            v2.5.0.6
    * @since              2009/09/25
    ********************************************************************************************/
    FUNCTION chop
    (
        i_string    VARCHAR2,
        i_num_chars NUMBER DEFAULT 1
    ) RETURN VARCHAR2 IS
        l_num_chars PLS_INTEGER := i_num_chars;
    BEGIN
        IF l_num_chars < 1
        THEN
            RETURN i_string;
        ELSE
            RETURN substr(i_string, 1, length(i_string) - l_num_chars);
        END IF;
    END chop;

    /*********************************************************************************************
    * Surrounds the string with the provided pattern, or returns NULL if the string is NULL.
    * 
    * @param i_string         Original string
    * @param i_pattern        Pattern (the original string takes the place of the first '@'
    *                         character)
    * @param i_replace_char   The replacement character (optional)
    *
    * @return                 The surrounded string
    *
    * @author                 Joao Martins
    * @version                v2.5.0.6
    * @since                  2009/09/25
    ********************************************************************************************/
    FUNCTION surround
    (
        i_string       VARCHAR2,
        i_pattern      VARCHAR2,
        i_replace_char VARCHAR2 DEFAULT '@'
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_string IS NULL
        THEN
            RETURN i_string;
        END IF;
    
        RETURN REPLACE(i_pattern, i_replace_char, i_string);
    END surround;

    /**
    * Concatenates two strings with a separator. If one of the strings is null, ignores the separator
    *
    * @param i_str1      The first string.
    * @param i_str1      The second string.
    * @param i_sep       The string separator.
    *
    * @return  The concatenation of the two strings.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION concat_if_exists
    (
        i_str1 IN VARCHAR,
        i_str2 IN VARCHAR,
        i_sep  IN VARCHAR
    ) RETURN VARCHAR IS
    BEGIN
        IF i_str1 IS NULL
        THEN
            IF i_str2 IS NULL
            THEN
                RETURN '';
            ELSE
                RETURN i_str2;
            END IF;
        ELSE
            IF i_str2 IS NULL
            THEN
                RETURN i_str1;
            ELSE
                RETURN i_str1 || i_sep || i_str2;
            END IF;
        END IF;
    END concat_if_exists;

    FUNCTION concat_if_exists_clob
    (
        i_str1 IN CLOB,
        i_str2 IN CLOB,
        i_sep  IN VARCHAR
    ) RETURN CLOB IS
    BEGIN
        IF dbms_lob.getlength(i_str1) = 0
           OR i_str1 IS NULL
        THEN
            IF dbms_lob.getlength(i_str2) = 0
               OR i_str2 IS NULL
            THEN
                RETURN '';
            ELSE
                RETURN i_str2;
            END IF;
        ELSE
            IF dbms_lob.getlength(i_str2) = 0
               OR i_str2 IS NULL
            THEN
                RETURN i_str1;
            ELSE
                RETURN i_str1 || i_sep || i_str2;
            END IF;
        END IF;
    END concat_if_exists_clob;

    /********************************************************************************************
    *  Get the strings between i_start_chr and i_end_chr.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_strs             List of string to be searched 
    * @param i_start_chr        Start character
    * @param i_end_chr          End character    
    *
    * @return                          boolean
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_str_between_chars
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_strs      IN table_varchar,
        i_start_chr IN VARCHAR2,
        i_end_chr   IN VARCHAR2
    ) RETURN table_varchar IS
        l_error t_error_out;
        l_str   table_varchar;
    BEGIN
        g_error := 'GET the positions. ';
        pk_alertlog.log_debug(g_error);
    
        SELECT substr(str, start_pos + 1, end_pos - start_pos - 1)
          BULK COLLECT
          INTO l_str
          FROM (SELECT str, instr(str, i_start_chr, 1, LEVEL) start_pos, instr(str, i_end_chr, 1, LEVEL) end_pos, LEVEL
                  FROM (SELECT str
                          FROM (SELECT column_value AS str
                                  FROM TABLE(i_strs)))
                CONNECT BY PRIOR str = str
                       AND instr(str, i_start_chr, 1, LEVEL) > 0
                       AND PRIOR dbms_random.string('p', 10) IS NOT NULL);
    
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STR_BETWEEN_CHARS',
                                              l_error);
            RETURN NULL;
    END get_str_between_chars;

    /**
    * Strips a string from any HTML tag.
    *
    * @param i_str          input string
    *
    * @return               string without HTML tags
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/18
    */
    FUNCTION strip_html_tags(i_str IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
    BEGIN
        RETURN regexp_replace(i_str, '<[^>]+>', NULL);
    END strip_html_tags;

    /**
    * Removes the empty lines in the end and the begin of the text
    *
    * @param   i_text                 Text to be trimmed    
    *
    * @return  Trimmed text
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   15-12-2011
    */
    FUNCTION trim_empty_lines(i_text IN CLOB) RETURN CLOB IS
    BEGIN
        RETURN TRIM(both g_new_line FROM i_text);
    END trim_empty_lines;

    /**
    * Removes the empty lines in the end of the text
    *
    * @param   i_text                 Text to be trimmed    
    *
    * @return  Trimmed text
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   15-12-2011
    */
    FUNCTION trim_empty_lines_end(i_text IN CLOB) RETURN CLOB IS
    BEGIN
        RETURN TRIM(trailing g_new_line FROM i_text);
    END trim_empty_lines_end;

    /**
    * Concatenate a list of descriptions using a delimiter that is defined for each item of list
    *
    * @param   i_concat_list        Collection of t_rec_text_delimiter_tuple (text, delimiter)
    * @return  Returns the concatenated list
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   21-06-2012
    */
    FUNCTION concat_element_list(i_concat_list IN t_coll_text_delimiter_tuple) RETURN VARCHAR2 IS
        l_return VARCHAR2(32767);
        l_temp   VARCHAR2(32767);
        l_delim  VARCHAR2(10);
        l_first  BOOLEAN := TRUE;
        i        PLS_INTEGER;
    BEGIN
    
        IF i_concat_list IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        i := i_concat_list.first;
        WHILE i IS NOT NULL
        LOOP
        
            l_temp  := i_concat_list(i).text;
            l_delim := i_concat_list(i).delimiter;
        
            IF l_temp IS NOT NULL
            THEN
                IF l_first
                THEN
                    l_return := l_temp;
                    l_first  := FALSE;
                ELSE
                    l_return := l_return || l_delim || l_temp;
                END IF;
            END IF;
            i := i_concat_list.next(i);
        END LOOP;
    
        RETURN l_return;
    END concat_element_list;

    FUNCTION concat_element_list_clob(i_concat_list IN t_coll_text_delimiter_tuple) RETURN CLOB IS
        l_return VARCHAR2(32767);
        l_temp   VARCHAR2(32767);
        l_delim  VARCHAR2(10);
        l_first  BOOLEAN := TRUE;
        i        PLS_INTEGER;
    BEGIN
    
        IF i_concat_list IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        i := i_concat_list.first;
        WHILE i IS NOT NULL
        LOOP
        
            l_temp  := i_concat_list(i).text;
            l_delim := i_concat_list(i).delimiter;
        
            IF l_temp IS NOT NULL
            THEN
                IF l_first
                THEN
                    l_return := l_temp;
                    l_first  := FALSE;
                ELSE
                    l_return := l_return || l_delim || l_temp;
                END IF;
            END IF;
            i := i_concat_list.next(i);
        END LOOP;
    
        RETURN l_return;
    END concat_element_list_clob;

    /**
    * This function replaces characters that have special meaning in HTML with their escape sequences. 
    * Equivalent to htf.escape_sc function but for clobs.
    * The following characters are converted:
    *  & to &amp;
    * " to &quot:
    * < to &lt;
    * > to &gt;
    *
    * @param   i_clob         The text string clob to convert.
    * @return  clob
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3
    * @since   29-10-2012
    */
    FUNCTION escape_sc(i_clob IN CLOB) RETURN CLOB IS
        l_len     NUMBER(24);
        l_buf     CLOB;
        l_bufsize BINARY_INTEGER := 4000;
        l_pos     NUMBER(24) := 1;
        l_output  CLOB;
    BEGIN
        l_len := dbms_lob.getlength(i_clob);
        IF l_bufsize > l_len
        THEN
            l_bufsize := l_len;
        END IF;
    
        dbms_lob.createtemporary(lob_loc => l_output, cache => TRUE);
    
        WHILE l_len > 0
        LOOP
            dbms_lob.read(lob_loc => i_clob, amount => l_bufsize, offset => l_pos, buffer => l_buf);
            l_buf := htf.escape_sc(l_buf);
            dbms_lob.writeappend(lob_loc => l_output, amount => length(l_buf), buffer => l_buf);
            l_pos := l_pos + l_bufsize;
            l_len := l_len - l_bufsize;
        END LOOP;
        RETURN l_output;
    
    END escape_sc;

    /**
    * This function replaces HTML escape sequences to HTML characters that have special meaning. 
    * The following characters are converted:
    * &amp; to & 
    * &quot to ":
    * &lt; to <
    * &gt; to >
    *
    * @param   i_text         The text string to convert.
    * @return  varchar2
    *
    * @author  Sofia Mendes
    * @version 2.6.3
    * @since   14-06-2013
    */
    FUNCTION escape_sc_to_html_chars(i_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN REPLACE(REPLACE(REPLACE(REPLACE(i_text, '&' || 'amp;', '&'), '&' || 'quot;', '"'), '&' || 'lt;', '<'),
                       '&' || 'gt;',
                       '>');
    
    END escape_sc_to_html_chars;

    /**
    * This function replaces characters that have special meaning in HTML with their escape sequences. 
    * Equivalent to htf.escape_sc function but do not replace the '&' char when the following strings are presented: 
    * &gt, &lt, &quot, &amb
    * The following characters are converted:
    *  & to &amp;
    * " to &quot:
    * < to &lt;
    * > to &gt;
    *
    * @param   i_text         The text string to convert.
    * @return  VARCHAR2
    *
    * @author  Sofia Mendes
    * @version 2.6.3
    * @since   29-10-2012
    */
    FUNCTION escape_sc_extended(i_text IN VARCHAR2) RETURN VARCHAR2 IS
        l_res pk_translation.t_desc_translation;
    BEGIN
        l_res := (REPLACE(REPLACE(REPLACE(i_text, '"', '&' || 'quot;'), '<', '&' || 'lt;'), '>', '&' || 'gt;'));
    
        l_res := regexp_replace(l_res, '&[^&gt;&lt;&quot;&amb]+', '&amb');
    
        RETURN l_res;
    
    END escape_sc_extended;

    /**
    * Generates a string of tabs with the specified size.
    *
    * @param i_tab_size             Tab size. If not specified, use 2 as default
    * @param i_use_tab_character    Use tab character (chr 9) or space character. If not specified, uses space as default
    *
    * @return   The generated string with tabs
    *
    * @author   ARIEL.MACHADO
    * @version  
    * @since    3/26/2014
    */
    FUNCTION get_tab
    (
        i_tab_size          IN NUMBER DEFAULT 2,
        i_use_tab_character IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_use_tab_character
        THEN
            RETURN rpad(chr(9), i_tab_size, chr(9));
        ELSE
            RETURN rpad(' ', i_tab_size, ' ');
        END IF;
    END get_tab;

    /**
    * Adds punctuation character (.) at end of string if necessary.
    *
    * @param i_line    String to evaluate
    *
    * @return   A string with full stop at end, if necessary
    *
    * @author   ARIEL.MACHADO
    * @version  
    * @since    3/26/2014
    */
    FUNCTION add_full_stop(i_line IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE WHEN i_line IS NULL THEN NULL WHEN instr('!,.:;?', substr(i_line, -1)) = 0 THEN i_line || '.' ELSE i_line END;
    END add_full_stop;

    FUNCTION clob_split
    (
        i_text      CLOB,
        i_delimiter VARCHAR2
    ) RETURN table_clob IS
        l_ret table_clob;
    BEGIN
    
        WITH data AS
         (SELECT i_text AS str
            FROM dual)
        SELECT regexp_substr(str, '[^,]*', 1, LEVEL)
          BULK COLLECT
          INTO l_ret
        
          FROM data
        CONNECT BY instr(str, ',', 1, LEVEL - 1) > 0;
    
        RETURN l_ret;
    
    END clob_split;

BEGIN
    -- Initialization
    NULL;
END pk_string_utils;
/
