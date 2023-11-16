/*-- Last Change Revision: $Rev: 1589482 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-05-13 14:54:56 +0100 (ter, 13 mai 2014) $*/

CREATE OR REPLACE PACKAGE pk_info_button_ux IS

    FUNCTION get_show_info_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_info_button_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_title        OUT sys_message.desc_message%TYPE,
        o_subtitle     OUT sys_message.desc_message%TYPE,
        o_info         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_info_button_url
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        
        i_element_type IN table_varchar DEFAULT table_varchar(), -- for the multiple parameters like cds
        i_id_element   IN table_varchar DEFAULT table_varchar(), -- id for diagnosis, medication, lab tests
        
        i_code     IN table_varchar DEFAULT table_varchar(), -- ICD9 code
        i_standard IN table_varchar DEFAULT table_varchar(), -- HL7
        
        i_id_task_type IN task_type.id_task_type%TYPE, -- area where it comes
        
        i_id_links IN links.id_links%TYPE DEFAULT NULL, -- receives id link of url to send to interalert         
        
        i_extra_info IN table_table_varchar DEFAULT table_table_varchar(), -- Receives , INTERNAL_NAME and VAL
        
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_info_button_ux;
/
