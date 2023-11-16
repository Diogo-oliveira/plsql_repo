/*-- Last Change Revision: $Rev: 2029021 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_translation_lob AS

    SUBTYPE t_desc_translation IS CLOB;

    SUBTYPE t_code IS translation_lob.code_translation%TYPE;
    SUBTYPE t_desc IS translation_lob.desc_lang_1%TYPE;

    SUBTYPE t_module IS VARCHAR2(200 CHAR);

    SUBTYPE t_big_char IS VARCHAR2(4000);
    SUBTYPE t_big_byte IS pk_types.t_big_byte;
    SUBTYPE t_med_char IS VARCHAR2(0500 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0100 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    SUBTYPE t_msg_char IS VARCHAR2(0255 BYTE);

    SUBTYPE t_low_num IS NUMBER(06);
    SUBTYPE t_med_num IS NUMBER(12);
    SUBTYPE t_big_num IS NUMBER(24);

    g_count_error t_low_num := 0;
    g_endsession  t_med_char;

    g_yes CONSTANT t_flg_char := 'Y';
    g_no  CONSTANT t_flg_char := 'N';

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
        i_code_mess IN t_code
    ) RETURN CLOB;

    FUNCTION get_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN t_code,
        o_desc_mess OUT t_desc_translation
    ) RETURN BOOLEAN;

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
        i_desc_trans IN t_desc
    );

    PROCEDURE insert_into_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_code_trans IN t_code,
        i_desc_trans IN t_desc,
        i_module     IN t_module
    );

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
    ) RETURN table_t_search_lob;

    -- new
    FUNCTION build_ins_bulk_lob(i_ignore_dup IN t_flg_char DEFAULT g_no) RETURN t_big_byte;
    FUNCTION build_upd_bulk_lob RETURN t_big_byte;

    FUNCTION ins_bulk_translation_lob
    (
        i_tab        IN t_tbl_translation_lob,
        i_ignore_dup IN t_flg_char DEFAULT g_no
    ) RETURN t_big_num;

    FUNCTION upd_bulk_translation_lob(i_tab IN t_tbl_translation_lob) RETURN t_big_num;
    FUNCTION get_value
    (
        i_value         IN t_big_byte,
        i_default_value IN t_big_byte
    ) RETURN t_big_byte;
    FUNCTION clean_value RETURN t_low_char;
	
    PROCEDURE ins_bulk_trl_versioning(i_tab IN t_tbl_translation_lob);
    
END pk_translation_lob;
/
