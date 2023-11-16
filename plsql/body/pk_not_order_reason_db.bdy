/*-- Last Change Revision: $Rev: 1592445 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-05-20 14:33:56 +0100 (ter, 20 mai 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_not_order_reason_db IS

    -- Private type declarations

    -- Private constant declarations

    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    FUNCTION set_not_order_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_not_order_reason_ea IN not_order_reason_ea.id_not_order_reason_ea%TYPE,
        o_id_not_order_reason OUT not_order_reason.id_not_order_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_not_order_reason';
        l_id not_order_reason.id_not_order_reason%TYPE;
    BEGIN
        l_id := pk_not_order_reason.set_not_order_reason(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_not_order_reason_ea => i_not_order_reason_ea);
    
        o_id_not_order_reason := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_not_order_reason;
    
    FUNCTION get_not_order_reason_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_desc pk_translation.t_desc_translation;
    BEGIN        
        l_desc := pk_not_order_reason.get_not_order_reason_desc(i_lang                => i_lang,
                                                                i_id_not_order_reason => i_not_order_reason);
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_not_order_reason_desc;
    
    
     FUNCTION get_not_order_reason_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN not_order_reason_ea.id_not_order_reason_ea%TYPE IS
        l_id                      not_order_reason_ea.id_not_order_reason_ea%TYPE;
    BEGIN
        l_id:=pk_not_order_reason.get_not_order_reason_id(i_lang => i_lang,i_id_not_order_reason => i_id_not_order_reason);
        
         RETURN l_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_not_order_reason_id;
    
     FUNCTION get_not_order_reason_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_not_order_reason_list';
    
    BEGIN
    
        pk_not_order_reason.get_not_order_reason_list(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_task_type => i_task_type,
                                                      o_list      => o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_not_order_reason_list;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_not_order_reason_db;
/
