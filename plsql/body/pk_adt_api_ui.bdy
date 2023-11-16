/*-- Last Change Revision: $Rev: 2026618 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_adt_api_ui AS

    FUNCTION get_patient_deceased_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        o_deceased_date   OUT VARCHAR2,
        o_deceased_motive OUT patient.deceased_motive%TYPE,
        o_deceased_place  OUT patient.deceased_place%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        verror t_error_out;
    BEGIN
    
        SELECT pk_date_utils.date_send_tsz(i_lang, p.dt_deceased, i_prof) dt_begin, p.deceased_motive, p.deceased_place
          INTO o_deceased_date, o_deceased_motive, o_deceased_place
          FROM patient p
         WHERE id_patient = i_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_DECEASED_INFO',
                                              o_error    => verror);
            RETURN FALSE;
    END get_patient_deceased_info;

    --read spec for full comments
    FUNCTION get_pat_exemptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_exemptions OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_adt.get_pat_exemptions(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_id_patient   => i_id_patient,
                                         i_current_date => NULL,
                                         o_exemptions   => o_exemptions,
                                         o_error        => o_error);
    
    END get_pat_exemptions;

    /******************************************************************************
    * read spec for full description 
    *********************************************************************************/
    FUNCTION get_national_health_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hp_id_hp pat_health_plan.id_health_plan%TYPE;
    BEGIN
    
        RETURN pk_adt.get_national_health_number(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_patient      => i_id_patient,
                                                 o_hp_id_hp        => l_hp_id_hp,
                                                 o_num_health_plan => o_num_health_plan,
                                                 o_hp_entity       => o_hp_entity,
                                                 o_hp_desc         => o_hp_desc,
                                                 o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_national_health_number',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_national_health_number;

    /******************************************************************************
    * read spec for full description 
    *********************************************************************************/
    FUNCTION get_flg_recm
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_flg_recm   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt.get_flg_recm(i_lang       => i_lang,
                                   i_id_patient => i_id_patient,
                                   i_prof       => i_prof,
                                   o_flg_recm   => o_flg_recm,
                                   o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_flg_recm',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_flg_recm;

    /******************************************************************************
    * read spec for full description 
    *********************************************************************************/
    FUNCTION get_other_names
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_other_names OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
        l_id_sys_config sys_config.id_sys_config%TYPE := 'PATIENT_NAME_PATTERN';
    BEGIN
    
        --IF has_other_names(i_patient => i_patient) = pk_alert_constant.g_yes
        --THEN
        SELECT p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO l_other_names_1, l_other_names_2, l_other_names_3, l_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        o_other_names := pk_adt.concat_other_names(NULL,
                                                   i_prof,
                                                   l_other_names_1,
                                                   l_other_names_4,
                                                   l_other_names_2,
                                                   l_other_names_3,
                                                   FALSE,
                                                   l_id_sys_config);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_other_names',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_other_names;

    FUNCTION get_create_patient_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_adt.get_create_patient_options(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 o_options => o_options,
                                                 o_error   => o_error);
    
    END get_create_patient_options;

    FUNCTION get_epis_type_create
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_adt.get_epis_type_create(i_lang     => i_lang,
                                           i_prof     => i_prof,
                                           o_flg_type => o_flg_type,
                                           o_error    => o_error);
    END get_epis_type_create;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_adt_api_ui;
/
