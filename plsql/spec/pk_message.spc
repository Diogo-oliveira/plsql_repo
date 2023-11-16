/*-- Last Change Revision: $Rev: 2028804 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_message IS

    FUNCTION get_message
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN sys_message.code_message%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_message
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_mess IN sys_message.code_message%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /**
    * Gets an array of messages returning the result as hash table.
    *
    * @param    i_lang                    Professional preferred language
    * @param    i_prof                    Professional identification and its context (institution and software)
    * @param    i_code_msg_arr            Array of code_message
    * @param    io_desc_msg_hashtable     Hash table (key, value) = (code_message, message)
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    7/9/2014
    */
    FUNCTION get_message_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_code_msg_arr        IN table_varchar,
        io_desc_msg_hashtable IN OUT NOCOPY pk_types.vc2_hash_table
    ) RETURN BOOLEAN;

    FUNCTION get_help_message
    (
        i_lang        IN language.id_language%TYPE,
        i_code_mess   IN sys_message.code_message%TYPE,
        o_title       OUT VARCHAR2,
        o_mesg        OUT VARCHAR2,
        o_button_desc OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_help_message
    (
        i_lang        IN language.id_language%TYPE,
        i_code_mess   IN sys_message.code_message%TYPE,
        i_prof        IN profissional,
        o_title       OUT VARCHAR2,
        o_mesg        OUT VARCHAR2,
        o_button_desc OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Formats message with the passed parameters in I_PARAMS.
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_MSG the message to format
    * @param I_PARAMS the parameters to format the message 
    * @param O_FORMATED_MSG The formated message
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   02-11-2006 
    */
    FUNCTION format
    (
        i_lang         IN language.id_language%TYPE,
        i_msg          IN sys_message.desc_message%TYPE,
        i_params       IN table_varchar,
        o_formated_msg OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000);
    g_yes CONSTANT VARCHAR2(1) := 'Y';

    /************************************************************************************
    * Merges a record into sys_message table                                            *
    *                                                                                   *
    * @param i_lang           record language                                           *     
    * @param i_code_message   message code                                              *
    * @param i_desc_message   description                                               *
    * @param i_flg_type       message type (optional)                                   *
    * @param i_software       software where the message is to be used (default = 0)    *
    * @param i_institution    institution where the message is to be used (default = 0) *
    * @param i_img_name       image name (optional)                                     *
    * @param i_id_sys_message message unique identifier (optional)                      *
    * @param i_module         module (optional)                                         * 
    *                                                                                   *
    ************************************************************************************/
    PROCEDURE insert_into_sys_message
    (
        i_lang           language.id_language%TYPE,
        i_code_message   sys_message.code_message%TYPE,
        i_desc_message   sys_message.desc_message%TYPE,
        i_flg_type       sys_message.flg_type%TYPE DEFAULT NULL,
        i_software       software.id_software%TYPE DEFAULT 0,
        i_institution    institution.id_institution%TYPE DEFAULT 0,
        i_img_name       sys_message.img_name%TYPE DEFAULT NULL,
        i_id_sys_message sys_message.id_sys_message%TYPE DEFAULT NULL,
        i_module         sys_message.module%TYPE DEFAULT NULL,
        i_market         sys_message.id_market%TYPE DEFAULT 0
    );

END pk_message;
/
