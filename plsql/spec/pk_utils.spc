CREATE OR REPLACE PACKAGE pk_utils AS
    desc_by_dpt  CONSTANT VARCHAR2(0050 CHAR) := 'DEPT_DESC_BY_DPT';
    desc_by_dcs  CONSTANT VARCHAR2(0050 CHAR) := 'DEPT_DESC_BY_DCS';
    desc_by_epis CONSTANT VARCHAR2(0050 CHAR) := 'DEPT_DESC_BY_EPIS';

    FUNCTION get_service_desc
    (
        i_lang IN NUMBER,
        i_id   IN NUMBER,
        i_mode IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function gets unique code for the current transaction (if no transaction is started it returns null)
    *
    * RETURN                    unique transaction code 
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011/05/18
    ********************************************************************************************/
    FUNCTION get_transaction_code RETURN VARCHAR2;

    /********************************************************************************************
    * This function gets database identifier
    *
    * RETURN                    database id
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011/05/18
    ********************************************************************************************/
    FUNCTION get_dbid RETURN NUMBER;

    PROCEDURE undo_changes;

    TYPE hashtable_varchar2 IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(4000);

    TYPE hashtable_pls_integer IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;

    SUBTYPE t_str_mask IS VARCHAR2(50 CHAR); -- UX input object masks

    FUNCTION search_table_number
    (
        i_table  IN table_number,
        i_search IN NUMBER
    ) RETURN NUMBER;

    FUNCTION search_table_varchar
    (
        i_table  IN table_varchar,
        i_search IN VARCHAR2
    ) RETURN NUMBER;

    /**
    * Equivalent to DBMS_OUTPUT.PUT_LINE, but slices I_LINE in chunks of 255 chars to overcome the limit of 255 chars when using BDMS_OUTPUT.PUT_LINE. 
    *
    * @param   I_LINE the string to print
    *
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   26-10-2006 
    */
    PROCEDURE put_line(i_line IN VARCHAR2);

    /**
    * Converts the parameter to a varchar2.
    * Overloads are wellcome.
    * @param variable to convert
    * @return converted text
    */
    FUNCTION to_str(b BOOLEAN) RETURN VARCHAR2;

    /*
    * Name says it all
    */
    PROCEDURE reset_sequence
    (
        seq_name   IN VARCHAR2,
        startvalue IN NUMBER DEFAULT 1
    );

    /**
    * Removes superfluous white-space.
    * One blank space is kept between letters.
    * All other is removed.
    *
    * @param text text to normalize
    * @param return normalized text
    */
    --FUNCTION normalize_white_space(text IN VARCHAR2) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all clobs in the passed table
    *
    * @param i_tab a object of type 'table of clobs'
    * @param i_delim delimiter between elements in the table
    * @return the Clob text
    */
    FUNCTION concat_table
    (
        i_tab   IN table_clob,
        i_delim IN VARCHAR2 DEFAULT '|'
    ) RETURN CLOB;

    FUNCTION concat_table_clob
    (
        i_tab   IN table_clob,
        i_delim IN VARCHAR2 DEFAULT '|'
    ) RETURN CLOB;

    /**
    * Aggregate function for group by clauses, and others.
    * Concatenates all varchar2 in the passed table
    * This one uses clobs, for larger amounts of text
    *
    * @param i_tab a object of type 'table or varchar'
    * @param i_delim delimiter between elements in the table
    * @return the text
    */
    FUNCTION concat_table_l
    (
        i_tab       IN table_varchar,
        i_delim     VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN CLOB;

    FUNCTION concatenate_list
    (
        p_cursor IN SYS_REFCURSOR,
        p_delim  IN VARCHAR2
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
        PIPELINED;

    /*********************************************************************************************
    * Split varchar into mutiple tokens
    * using fixed length line
    * 
    * @param i_string  the input varchar
    * @param i_lenght  the length of each line
    *
    * @return a pipelined table_varchar2 which can be used in a sql query
    *
    * @author rui.baeta@pt
    * @date   2007/12/14
    * @since  2.4.2
    * @see    overloads str_split_c(p_list, p_delim)
    ********************************************************************************************/
    FUNCTION str_split_c
    (
        i_string IN VARCHAR2,
        i_lenght IN INTEGER
    ) RETURN table_varchar
        PIPELINED;

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
    ) RETURN table_varchar;

    /*********************************************************************************************
    * Split varchar into mutiple tokens
    * using fixed length line
    * 
    * @param i_string  the input varchar
    * @param i_length  the length of each line
    *
    * @return a table_varchar2 which can be used in pl/sql scope
    *
    * @author rui.baeta@pt
    * @date   2007/12/14
    * @since  2.4.2
    * @see    str_split_c(i_string, i_lenght)
    ********************************************************************************************/
    FUNCTION str_split
    (
        i_string IN VARCHAR2,
        i_length IN INTEGER,
        i_delim  IN VARCHAR2 := ' '
    ) RETURN table_varchar;

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
    ) RETURN table_number;

    /*************************************************************************************************
    * Builds an EPL string for label printing. If i_body_text is too big to fit in a single label,
    * it will be spanned into multiple label, accordingly to i_format_vars.
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
    ) RETURN VARCHAR2;

    /**
    * Function that replaces middle names with initials
    * @param i_name original name
    * @return the new name
    */
    FUNCTION format_middlename(i_name IN patient.name%TYPE) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Chamadas ao S.O.
    * 
    * Devolve via DBMS_OUTPUT.get_lines o resultado
    *
    * @return                       output com o resultado
    * 
    * @author                       Rui Spratley
    * @since                        2008/08/08
    **********************************************************************************************/

    PROCEDURE host_command(p_command IN VARCHAR2);

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
    ) RETURN VARCHAR2;

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
    ) RETURN CLOB;

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
    ) RETURN CLOB;

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
    ) RETURN CLOB;

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
    ) RETURN table_varchar2;

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
    FUNCTION to_bold(i_text IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION set_session_parameter
    (
        i_parameter VARCHAR2,
        i_value     VARCHAR2
    ) RETURN VARCHAR2;

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
    );

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /**
    * Returns the client identifier string from v$session.
    *
    * @return     varchar2
    * @author     Rui Spratley
    * @version    2.5.0.1
    * @since      2009/04/13
    * @notes
    */

    FUNCTION get_client_id RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;
    --
    FUNCTION to_str
    (
        i_number IN NUMBER,
        i_prof   IN profissional DEFAULT profissional(NULL, 0, 0),
        i_mask   IN VARCHAR2 DEFAULT 'FM9999999D999'
    ) RETURN VARCHAR2;

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
    FUNCTION remove_upper_accentuation(i_input IN VARCHAR2) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    FUNCTION get_institution_name
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

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
    FUNCTION get_software_name
    (
        i_lang        IN language.id_language%TYPE,
        i_id_software IN software.id_software%TYPE,
        o_soft_name   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * Prints PROFISSIONAL type information
    * 
    * @param i_input      Variable of PROFESSIONAL type
    *
    * @return             VARCHAR2 with the PROFESSIONAL information
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/08/24
    ********************************************************************************************/
    FUNCTION to_string(i_input IN profissional) RETURN VARCHAR2;

    /*********************************************************************************************
    * Prints TABLE_NUMBER content
    * 
    * @param i_input      Variable of TABLE_NUMBER type
    *
    * @return             VARCHAR2 with the TABLE_NUMBER information
    *
    * @author        Sérgio Santos
    * @version       2.5.0.5
    * @date          2009/08/24
    ********************************************************************************************/
    FUNCTION to_string(i_input IN table_number) RETURN VARCHAR2;

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
    FUNCTION to_string(i_input IN table_varchar) RETURN VARCHAR2;

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
    FUNCTION sort_table_varchar(i_table IN table_varchar) RETURN table_varchar;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN market.id_market%TYPE;

    FUNCTION get_institution_language
    (
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE DEFAULT 0
    ) RETURN language.id_language%TYPE;

    /**********************************************************************************************
    * Function to return a list of IDs of related institutions.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids       
    * @param i_inst                   ID of institution to consider         
    * @param o_list                   array with institutions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        2.6 
    * @since                          2010/02/22
    **********************************************************************************************/
    FUNCTION get_institutions_sib
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Function to return a list of IDs of sibling institutions.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids                
    * @param i_inst                   ID of institution to consider
    * @param o_parent                 ID of parent
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         RicardoNunoAlmeida
    * @version                        2.6 
    * @since                          2010/02/22
    **********************************************************************************************/
    FUNCTION get_institution_parent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_inst   IN institution.id_institution%TYPE,
        o_parent OUT institution.id_institution%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_parent
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_inst IN institution.id_institution%TYPE
    ) RETURN institution.id_institution%TYPE;

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
    FUNCTION char_to_number
    (
        i_prof  IN profissional,
        i_input IN VARCHAR2
    ) RETURN NUMBER;

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
    ) RETURN VARCHAR2;

    FUNCTION is_number(char_in VARCHAR2) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN t_str_mask;

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
    ) RETURN table_number;

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
    ) RETURN table_varchar;

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
    ) RETURN table_varchar2;

    /********************************************************************************************
    *  Append the elements of one table to another.
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    );

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
    );

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
    FUNCTION get_rowcount(io_cursor IN OUT NOCOPY pk_types.cursor_type) RETURN NUMBER;

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
    ) RETURN VARCHAR2;

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
    ) RETURN table_clob;

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
    FUNCTION convert_tchar_tnumber(i_table_varchar IN table_varchar DEFAULT table_varchar()) RETURN table_number;

    /**
    * Translates 3-valued BOOLEAN TO VARCHAR2. Based on sys.diutil.bool_to_int
    *
    * @param    i_bool            Boolean value
    *   
    * @return   false = 'N', true = 'Y', NULL = NULL
    *    
    * @author   ARIEL.MACHADO
    * @version
    * @since    12/30/2013
    */
    FUNCTION bool_to_flag(i_bool IN BOOLEAN) RETURN VARCHAR2;

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
        PIPELINED;

    FUNCTION get_client_institution_id RETURN NUMBER;

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
    ) RETURN BOOLEAN;
    /* Method that returns institution address information */
    FUNCTION get_institution_address
    (
        i_lang    IN language.id_language%TYPE,
        i_inst_id institution.id_institution%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    FUNCTION get_var_route RETURN NUMBER;

    FUNCTION get_var_mkt RETURN NUMBER;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    PROCEDURE set_nls_numeric_characters
    (
        i_prof            IN profissional,
        i_back_nls        IN VARCHAR2 DEFAULT NULL,
        i_is_to_reset_nls IN BOOLEAN DEFAULT FALSE
    );

    FUNCTION set_tbl_temp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN table_table_varchar,
        i_value IN table_table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION exists_table_varchar
    (
        i_table  IN table_varchar,
        i_search IN VARCHAR2
    ) RETURN NUMBER;

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
    ) RETURN VARCHAR2 result_cache;
END pk_utils;
/
