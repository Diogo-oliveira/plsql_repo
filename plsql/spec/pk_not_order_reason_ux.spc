/*-- Last Change Revision: $Rev: 1592437 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-05-20 14:30:39 +0100 (ter, 20 mai 2014) $*/

CREATE OR REPLACE PACKAGE pk_not_order_reason_ux IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 24-04-2014 15:37:13
    -- Purpose : Reason not ordered: Methods for UX

    -- Public type declarations
    

    -- Public constant declarations
    

    -- Public variable declarations
    

    -- Public function and procedure declarations
    
    /**
    * get_not_order_reason_list
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
    
END pk_not_order_reason_ux;
/
