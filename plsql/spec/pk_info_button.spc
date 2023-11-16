/*-- Last Change Revision: $Rev: 1993370 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-07-05 11:07:06 +0100 (seg, 05 jul 2021) $*/

CREATE OR REPLACE PACKAGE pk_info_button IS

    FUNCTION get_info_button_detail
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
    ) RETURN BOOLEAN;

    FUNCTION get_show_info_button
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT NULL
    ) RETURN sys_config.value%TYPE;

    FUNCTION get_cds_show_info_button
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_cdr_inst_par_action IN cdr_inst_par_action.id_cdr_inst_par_action%TYPE
    ) RETURN links.id_links%TYPE;

    FUNCTION get_cds_def_show_info_button
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_inst_par_action.id_cdr_inst_par_action%TYPE,
        i_id_links          IN links.id_links%TYPE
    ) RETURN links.id_links%TYPE;

    FUNCTION get_info_button_url
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_element_type IN table_varchar DEFAULT table_varchar(), -- for the multiple parameters
        i_id_element   IN table_varchar DEFAULT table_varchar(),
        i_code         IN table_varchar DEFAULT table_varchar(), -- ICD9 code
        i_standard     IN table_varchar DEFAULT table_varchar(), -- HL7        
        i_description  IN table_varchar DEFAULT table_varchar(), -- Description
        i_id_task_type IN task_type.id_task_type%TYPE, -- area where it comes
        i_id_links     IN links.id_links%TYPE DEFAULT NULL, -- receives url to send to interalert
        i_extra_info   IN table_table_varchar DEFAULT table_table_varchar(), -- Receives , INTERNAL_NAME and VAL        
        o_url          OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_med_info_button_url
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc            IN NUMBER,
        o_url                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cds_elements
    (
        i_id_task_type IN task_type.id_task_type%TYPE,
        i_id           IN VARCHAR2, -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
        o_element_type OUT table_varchar,
        o_id_element   OUT table_varchar
    ) RETURN BOOLEAN;

    FUNCTION get_cds_url
    (
        i_id_task_type IN task_type.id_task_type%TYPE,
        i_id           IN VARCHAR2, -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
        o_id_links     OUT links.id_links%TYPE
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_info_button;
/
