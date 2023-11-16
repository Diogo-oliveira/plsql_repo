/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_nnn_lnk_model IS

    -- Private type declarations

    -- Private constant declarations
    /*g_flg_nic_type_m CONSTANT VARCHAR2(1) := 'M'; -- Intervention link type (M)ajor
    g_flg_nic_type_s CONSTANT VARCHAR2(1) := 'S'; -- Intervention link type (S)uggested
    g_flg_nic_type_o CONSTANT VARCHAR2(1) := 'O'; -- Intervention link type (O)ptional*/

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE insert_into_nan_noc_nic_link
    (
        i_terminology_version IN nan_noc_nic_linkage.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_outcome_code        IN noc.outcome_code%TYPE,
        i_intervention_code   IN nic.intervention_code%TYPE,
        i_nic_link_type       IN nan_noc_nic_linkage.flg_nic_link_type%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_noc_nic_link';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code), '<null>');
        g_error := g_error || ' i_outcome_code = ' || coalesce(to_char(i_outcome_code), '<null>');
        g_error := g_error || ' i_intervention_code = ' || coalesce(to_char(i_intervention_code), '<null>');
        g_error := g_error || ' i_nic_link_type = ' || coalesce(i_nic_link_type, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'insert/update in NAN_NOC_NIC_LINKAGE table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        ts_nan_noc_nic_linkage.upd_ins(id_terminology_version_in => i_terminology_version,
                                       diagnosis_code_in         => i_diagnosis_code,
                                       outcome_code_in           => i_outcome_code,
                                       intervention_code_in      => i_intervention_code,
                                       flg_nic_link_type_in      => i_nic_link_type);
    END insert_into_nan_noc_nic_link;

    PROCEDURE insert_into_nan_noc_link
    (
        i_terminology_version IN noc_outcome.id_terminology_version%TYPE,
        i_outcome_code        IN noc_outcome.outcome_code%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_nic_link_type       IN nan_noc_linkage.flg_link_type%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_noc_link';
        l_id_noc_outcome noc_outcome.id_noc_outcome%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_outcome_code = ' || coalesce(to_char(i_outcome_code), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code), '<null>');
        g_error := g_error || ' i_nic_link_type = ' || coalesce(i_nic_link_type, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NOC Outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT no.id_noc_outcome
              INTO l_id_noc_outcome
              FROM noc_outcome no
             WHERE no.id_terminology_version = i_terminology_version
               AND no.outcome_code = i_outcome_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NOC Outcome Code not found in noc_outcome.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_outcome',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_outcome_code',
                                                       value3_in           => coalesce(i_outcome_code, '<null>'));
                    RAISE e_invalid_noc_outcome;
                END;
        END;
    
        g_error := 'insert/update in NAN_NOC_LINKAGE table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        ts_nan_noc_linkage.upd_ins(diagnosis_code_in => i_diagnosis_code,
                                   id_noc_outcome_in => l_id_noc_outcome,
                                   flg_link_type_in  => i_nic_link_type);
    END insert_into_nan_noc_link;

    PROCEDURE insert_into_nan_nic_link
    (
        i_terminology_version IN nic_intervention.id_terminology_version%TYPE,
        i_intervention_code   IN nic_intervention.intervention_code%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_nic_link_type       IN nan_nic_linkage.flg_link_type%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_nic_link';
        l_id_nic_intervention nic_intervention.id_nic_intervention%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_intervention_code = ' || coalesce(to_char(i_intervention_code), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code), '<null>');
        g_error := g_error || ' i_nic_link_type = ' || coalesce(i_nic_link_type, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NIC Intervention';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT ni.id_nic_intervention
              INTO l_id_nic_intervention
              FROM nic_intervention ni
             WHERE ni.id_terminology_version = i_terminology_version
               AND ni.intervention_code = i_intervention_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NIC Intervention Code not found in nic_intervention.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nic_intervention',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_intervention_code',
                                                       value3_in           => coalesce(i_intervention_code, '<null>'));
                    RAISE e_invalid_nic_intervention;
                END;
        END;
    
        g_error := 'insert/update in NAN_NIC_LINKAGE table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        ts_nan_nic_linkage.upd_ins(id_nic_intervention_in => l_id_nic_intervention,
                                   diagnosis_code_in      => i_diagnosis_code,
                                   flg_link_type_in       => i_nic_link_type);
    
    END insert_into_nan_nic_link;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_lnk_model;
/
