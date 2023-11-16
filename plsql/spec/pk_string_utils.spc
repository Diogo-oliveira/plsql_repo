/*-- Last Change Revision: $Rev: 2028990 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_string_utils IS

    -- Author  : SERGIO.SANTOS
    -- Created : 18-06-2008 12:31:37
    -- Purpose : Pack of functions to manipulate strings

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    FUNCTION clob_to_sqlvarchar2(i_clob IN CLOB) RETURN VARCHAR2;

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
    FUNCTION clob_to_plsqlvarchar2(i_clob IN CLOB) RETURN VARCHAR2;

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
    ) RETURN table_varchar;

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
    ) RETURN table_varchar;

    /*********************************************************************************************
    * chops out the rightmost character(s) of a string.
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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR;

    FUNCTION concat_if_exists_clob
    (
        i_str1 IN CLOB,
        i_str2 IN CLOB,
        i_sep  IN VARCHAR
    ) RETURN CLOB;

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
    ) RETURN table_varchar;

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
    FUNCTION strip_html_tags(i_str IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;

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
    FUNCTION trim_empty_lines(i_text IN CLOB) RETURN CLOB;

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
    FUNCTION trim_empty_lines_end(i_text IN CLOB) RETURN CLOB;

    /**
    * Concatenate a list of descriptions using a delimiter that is defined for each item of list
    *
    * @param   i_concat_list        Collection of t_rec_text_delimiter_tuple (text, delimiter)
    * @return  Returns the concatenated list
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.3
    * @since   21-06-2012
    */
    FUNCTION concat_element_list(i_concat_list IN t_coll_text_delimiter_tuple) RETURN VARCHAR2;

    FUNCTION concat_element_list_clob(i_concat_list IN t_coll_text_delimiter_tuple) RETURN CLOB;

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
    FUNCTION escape_sc(i_clob IN CLOB) RETURN CLOB;

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
    FUNCTION escape_sc_to_html_chars(i_text IN VARCHAR2) RETURN VARCHAR2;

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
    FUNCTION escape_sc_extended(i_text IN VARCHAR2) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    FUNCTION add_full_stop(i_line IN VARCHAR2) RETURN VARCHAR2;

    --

    g_pattern_parenthesis       CONSTANT VARCHAR2(3 CHAR) := '(@)';
    g_pattern_space_parenthesis CONSTANT VARCHAR2(4 CHAR) := ' (@)';
    g_pattern_colon             CONSTANT VARCHAR2(2 CHAR) := '@:';
    g_pattern_mandatory         CONSTANT VARCHAR2(2 CHAR) := '@*';
    g_pattern_colon_mandatory   CONSTANT VARCHAR2(3 CHAR) := '@:*';
    g_pattern_semicolon_space   CONSTANT VARCHAR2(3 CHAR) := '@; ';
    g_pattern_free_text         CONSTANT VARCHAR2(4 CHAR) := ', @.';
    g_new_line                  CONSTANT VARCHAR2(4 CHAR) := chr(10);

END pk_string_utils;
/
