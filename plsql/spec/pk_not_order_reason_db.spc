/*-- Last Change Revision: $Rev: 1592436 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-05-20 14:30:32 +0100 (ter, 20 mai 2014) $*/

CREATE OR REPLACE PACKAGE pk_not_order_reason_db IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 28-04-2014 11:49:16
    -- Purpose : Reasons not ordered: DB methods

    -- Public type declarations

    -- Public constant declarations    
    g_mcode_not_order_info    CONSTANT sys_message.code_message%TYPE := 'COMMON_M128'; -- Not ordering information
    g_mcode_reas_not_order    CONSTANT sys_message.code_message%TYPE := 'COMMON_M129'; -- Reason for not ordering:
    g_mcode_reas_not_order1    CONSTANT sys_message.code_message%TYPE := 'COMMON_M132'; -- Reason for not ordering
    g_mcode_not_ordered_label CONSTANT sys_message.code_message%TYPE := 'COMMON_M130'; -- Not ordered:
    g_mcode_not_ordered_data  CONSTANT sys_message.code_message%TYPE := 'COMMON_M131'; -- Not ordered

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Inserts a not order reason if not exist and returns the id that each area will use to record in your data model 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_not_order_reason_ea Not order reason EA identifier
    * @param   o_id_not_order_reason Not order reason identifier
    * @param   o_error               Error information
    *
    * @return  True or False on success or error
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   28-04-2014
    */
    FUNCTION set_not_order_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_not_order_reason_ea IN not_order_reason_ea.id_not_order_reason_ea%TYPE,
        o_id_not_order_reason OUT not_order_reason.id_not_order_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the concept term description
    *
    * @param   i_lang                 Professional preferred language    
    * @param   i_id_not_order_reason  Not order reason identifier
    *
    * @return  The description of a given concept term
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   30-04-2014
    */
    FUNCTION get_not_order_reason_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN pk_translation.t_desc_translation;
    
    /**
    * Gets the key used to identify a not order reason stored in the table easy acess 
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_id_not_order_reason  Not order reason identifier
    *
    * @return  The identifier of a given concept term
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   06-05-2014
    */
     FUNCTION get_not_order_reason_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN not_order_reason_ea.id_not_order_reason_ea%TYPE;
    
    /**
    * Return the list of reasons not ordered of one task type (each area)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_task_type    task type 
    *
    * @param   o_list         Cursor containing information reasons not ordered of one task type
    * @param   o_error        Error information
    *
    * @return  boolean        True on sucess, otherwise false
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 1.0
    * @since   24-04-2014
    */
    FUNCTION get_not_order_reason_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_task_type          IN task_type.id_task_type%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
END pk_not_order_reason_db;
/
