/*-- Last Change Revision: $Rev: 2001300 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-11-12 12:27:39 +0000 (sex, 12 nov 2021) $*/

CREATE OR REPLACE PACKAGE pk_not_order_reason IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 24-04-2014 14:37:14
    -- Purpose : Reasons not ordered

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Get the information about the reasons not ordered of one task type
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_task_type    task type 
    *
    * @param   o_list         Cursor containing reasons not ordered
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 1.0
    * @since   24-04-2014
    */
    PROCEDURE get_not_order_reason_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        o_list      OUT pk_types.cursor_type
    );

    FUNCTION get_not_order_reason_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN t_tbl_core_domain;

    /**
    * Create a not order reason
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_not_order_reason_ea Not order reason EA identifier    
    *
    * @return  id_not_order_reason   Not order reason identifier that were created
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   28-04-2014
    */
    FUNCTION set_not_order_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_not_order_reason_ea IN not_order_reason_ea.id_not_order_reason_ea%TYPE
    ) RETURN not_order_reason.id_not_order_reason%TYPE;

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
        i_lang                IN language.id_language%TYPE,
        i_id_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Gets the key id_not_order_reason_ea
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
END pk_not_order_reason;
/
