CREATE OR REPLACE PACKAGE pk_alerts_ux IS

    /********************************************************************************************
    * Esta função marca os alertas como lidos para um determinado profissional.
    *
    * @param i_lang           Id do idioma
    * @param i_prof           Id do profissional
    * @param i_sys_alert_det  ID do alerta lido
    * @param i_sys_alert      ID do tipo de alerta
    * @param i_test           Indica se deve ser mostrada a mensagem de confirmação
    * @param o_flg_show       Indica se deve ser mostrada a mensagem de confirmação
    * @param o_msg_title      Título da mensagem de confirmação
    * @param o_msg_text       Descrição da mensagem de confirmação
    * @param o_button         Botões a mostrar. N - NÃO, R - LIDO, C - CONFIRMADO ou combinações destes
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author                 Rui Batista
    * @version                1.0
    * @since                  2007/07/11
    ********************************************************************************************/
    FUNCTION set_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN NUMBER,
        i_sys_alert     IN NUMBER,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_all_alert_read
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_selected_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN table_number,
        i_sys_alert     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_alert_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_alert   IN NUMBER,
        i_subject    IN varchar2,
        i_from_state IN varchar2,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    
        -- **********************************************
    FUNCTION set_alert_read_x_days
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_alerts_count
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_num_alerts OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_alerts_ux;
