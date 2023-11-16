/*-- Last Change Revision: $Rev: 1910301 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2019-07-31 14:29:48 +0100 (qua, 31 jul 2019) $*/

CREATE OR REPLACE PACKAGE pk_cancel_reason IS

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the description of a specific cancel reason identifier.
    * Avoid using this function inside a query!
    * It's better to get the description using the code_cancel_reason field
    *
    * @param i_lang             Language identifier.
    * @param i_id_cancel_reason The cancel reason area.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    */
    FUNCTION get_cancel_reason_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    * @param i_flg_action_type   Reason type, values: C - cancel, S - suspend, R - refuse, O - other, D - discontinue, T - return
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sergio Dias
    * @version  2.6.1.
    * @since    8-04-2011
    */
    FUNCTION get_reason_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_area            IN cancel_rea_area.intern_name%TYPE,
        i_flg_action_type IN reason_action.flg_type%TYPE,
        o_reasons         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang              Language identifier.
    * @param i_prof              The professional record.
    * @param i_area              The cancel reason area.
    * @param i_flg_action_type   Reason type, values: C - cancel, S - suspend, R - refuse, O - other, D - discontinue, T - return
    * @param i_id_reason         List of reason ids
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sergio Dias
    * @version  2.6.1.
    * @since    8-04-2011
    */
    FUNCTION get_reason_list_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_area            IN cancel_rea_area.intern_name%TYPE,
        i_flg_action_type IN reason_action.flg_type%TYPE,
        i_id_reason       IN table_number DEFAULT NULL,
        o_reasons         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_by_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_cnt  IN cancel_reason.id_content%TYPE
    ) RETURN cancel_reason.id_cancel_reason%TYPE;
    
    FUNCTION get_content_by_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN cancel_reason.id_content%TYPE;

    /**
    * Gets existing cancel configurations by task_type
    *
    * @param i_lang                          Language identifier.
    * @param i_prof                          The professional record.
    * @param i_task_type                     The task type related with area.
    * @param o_flg_cancel_reas_mandatory     Cancel reason configuration value (Y- cancel reason will be shown, N-Otherwise). 
    * @param o_flg_priority_mandatory        Priority configuration value (Y- priority will be shown , N-Otherwise)
    * @param o_priority_default_value        Default priority value (Y- Checked, N- Otherwise). 
    * @param o_error                         Message to be shown to the user.
    *
    * @return  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory. 
    *
    * @author   Gisela Couto
    * @version  2.6.4.3
    * @since    27-11-2014
    */
    FUNCTION get_cancel_configurations
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_task_type                 IN task_type.id_task_type%TYPE,
        i_action                    IN NUMBER DEFAULT NULL,
        o_flg_cancel_reas_mandatory OUT VARCHAR2, --i_field_01
        o_flg_priority_mandatory    OUT VARCHAR2, --i_field_02
        o_priority_default_value    OUT VARCHAR2, --i_field_03
        o_flg_date_visible          OUT VARCHAR2, --i_field_04
        o_date_mandatory            OUT VARCHAR2, --i_field_05
        o_min_date                  OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets existing cancel configurations by task_type
    *
    * @param i_lang                          Language identifier.
    * @param i_prof                          The professional record.
    * @param i_tbl_task_type                 The array of task types related with the areas.
    * @param o_flg_cancel_reas_mandatory     Cancel reason configuration value (Y- cancel reason will be shown, N-Otherwise). 
    * @param o_flg_priority_mandatory        Priority configuration value (Y- priority will be shown , N-Otherwise)
    * @param o_priority_default_value        Default priority value (Y- Checked, N- Otherwise). 
    * @param o_error                         Message to be shown to the user.
    *
    * @return  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory. 
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    * based on get_cancel_configurations but receiving an array of task types
    */
    FUNCTION get_cancel_configurations
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_tbl_task_type             IN table_number,
        i_action                    IN NUMBER DEFAULT NULL,
        o_flg_cancel_reas_mandatory OUT VARCHAR2, --i_field_01
        o_flg_priority_mandatory    OUT VARCHAR2, --i_field_02
        o_priority_default_value    OUT VARCHAR2, --i_field_03
        o_flg_date_visible          OUT VARCHAR2, --i_field_04
        o_date_mandatory            OUT VARCHAR2, --i_field_05
        o_min_date                  OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves information about cancel reason configuration.
    *
    * @param i_id_config                   Config table identifier (config_table).
    * @param i_task_type                   The task type related with area.
    * @param i_id_inst_owner               Institution identifier.
    * @param i_flg_add_remove              Flag add/remove.
    * @param i_flg_cancel_reas_mandatory   Cancel reason configuration value. 
    * @param i_flg_priority_mandatory      Priority configuration value.
    * @param i_priority_default_value      Default priority value (Y- Checked, N- Otherwise). 
    *
    * @value i_flg_cancel_reas_mandatory   Y - Cancel reason field will be shown
    *                                      N - Otherwise
    * @value i_flg_priority_mandatory      Y - Priority field will be shown
    *                                      N - Otherwise
    * @value i_priority_default_value      Y - Priority field checked
    *                                      N - Otherwise
    * @value i_flg_date_mandatory          Y - Discontinue date  field will be shown
    *                                      N - Otherwise
    *
    *
    * @author   Gisela Couto
    * @version  2.6.4.3
    * @since    27-11-2014
    */
    PROCEDURE insert_cancel_reason_config
    (
        i_id_config                 IN NUMBER,
        i_task_type                 IN task_type.id_task_type%TYPE,
        i_action                    IN action.id_action%TYPE DEFAULT NULL,
        i_id_inst_owner             IN institution.id_institution%TYPE DEFAULT pk_alert_constant.g_inst_all,
        i_flg_add_remove            IN VARCHAR2 DEFAULT pk_alert_constant.g_active,
        i_flg_cancel_reas_mandatory IN VARCHAR2, --i_field_01
        i_flg_priority_mandatory    IN VARCHAR2, --i_field_02
        i_priority_default_value    IN VARCHAR2 DEFAULT NULL, --i_field_03
        i_flg_date_visible          IN VARCHAR2 DEFAULT NULL, -- i_field_4
        i_date_mandatory            IN VARCHAR2 DEFAULT NULL -- i_field_5
    );

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;

    c_reason_action_cancel      VARCHAR2(1) := 'C';
    c_reason_action_suspend     VARCHAR2(1) := 'S';
    c_reason_action_discontinue VARCHAR2(1) := 'D';
    c_reason_action_refuse      VARCHAR2(1) := 'R';
    c_reason_action_other       VARCHAR2(1) := 'O';
    c_reason_action_return      VARCHAR2(1) := 'T';

    /* constants for reasons (cancel/suspend/discontinue) */
    c_reason_patient_death         CONSTANT NUMBER := 2989;
    c_reason_client_death          CONSTANT NUMBER := 2885;
    c_reason_other                 CONSTANT NUMBER := 2974;
    c_reason_error                 CONSTANT NUMBER := 2914;
    c_reason_entered_in_error      CONSTANT NUMBER := 2911;
    c_reason_contraind_future_proc CONSTANT NUMBER := 2897;

    c_canc_reas_conf_tab CONSTANT VARCHAR2(100 CHAR) := 'CANCEL';

    -- acções de cancelamento
    c_id_action_default   CONSTANT NUMBER := 6981;
    c_id_action_com_order CONSTANT NUMBER := 235529905;
    c_id_action_med       CONSTANT NUMBER := 700007;
END pk_cancel_reason;
/
