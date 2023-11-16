/*-- Last Change Revision: $Rev: 2026900 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_content_button_ux AS

    FUNCTION get_show_content_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error           := 'CALL PK_INFO_BUTTON.GET_SHOW_INFO_BUTTON';
        o_have_permission := pk_info_button.get_show_info_button(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_task_type => i_id_task_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HAVE_EXCEPTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_show_content_button;

    FUNCTION get_content_button_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_title         OUT sys_message.desc_message%TYPE,
        o_radio_title   OUT sys_message.desc_message%TYPE,
        o_options_title OUT sys_message.desc_message%TYPE,
        o_radio_button  OUT pk_types.cursor_type,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_INFO_BUTTON.GET_INFO_BUTTON_DETAIL';
        IF NOT pk_info_button.get_info_button_detail(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_patient    => i_id_patient,
                                                     i_id_task_type  => i_id_task_type,
                                                     o_title         => o_title,
                                                     o_radio_title   => o_radio_title,
                                                     o_options_title => o_options_title,
                                                     o_radio_button  => o_radio_button,
                                                     o_info          => o_info,
                                                     o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INFO_BUTTON_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_content_button_detail;

    FUNCTION get_content_button_url
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_element_type IN table_varchar DEFAULT table_varchar(), -- for the multiple parameters like cds
        i_id_element   IN table_varchar DEFAULT table_varchar(), -- id for diagnosis, medication, lab tests        
        i_code         IN table_varchar DEFAULT table_varchar(), -- ICD9 code
        i_standard     IN table_varchar DEFAULT table_varchar(), -- HL7
        i_description  IN table_varchar DEFAULT table_varchar(), -- Description        
        i_id_task_type IN task_type.id_task_type%TYPE, -- area where it comes        
        i_id_links     IN links.id_links%TYPE DEFAULT NULL, -- receives id link of url to send to interalert
        i_extra_info   IN table_table_varchar DEFAULT table_table_varchar(), -- Receives , INTERNAL_NAME and VAL
        o_url          OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_INFO_BUTTON.GET_INFO_BUTTON_URL';
        IF NOT pk_info_button.get_info_button_url(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_episode   => i_id_episode,
                                                  i_id_patient   => i_id_patient,
                                                  i_element_type => i_element_type,
                                                  i_id_element   => i_id_element,
                                                  i_code         => i_code,
                                                  i_standard     => i_standard,
                                                  i_description  => i_description,
                                                  i_id_task_type => i_id_task_type,
                                                  i_id_links     => i_id_links,
                                                  i_extra_info   => i_extra_info,
                                                  o_url          => o_url,
                                                  o_flg_show     => o_flg_show,
                                                  o_button       => o_button,
                                                  o_msg_title    => o_msg_title,
                                                  o_msg          => o_msg,
                                                  o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              o_error.err_desc,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INFO_BUTTON_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_content_button_url;

    FUNCTION get_med_content_button_url
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc            IN NUMBER,
        o_url                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_INFO_BUTTON.GET_MED_INFO_BUTTON_URL';
        IF NOT pk_info_button.get_med_info_button_url(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_product          => i_id_product,
                                                      i_id_product_supplier => i_id_product_supplier,
                                                      i_id_presc            => i_id_presc,
                                                      o_url                 => o_url,
                                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MED_CONTENT_BUTTON_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_med_content_button_url;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_content_button_ux;
/
