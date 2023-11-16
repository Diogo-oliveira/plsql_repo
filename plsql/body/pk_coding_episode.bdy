/*-- Last Change Revision: $Rev: 2013161 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2022-04-26 22:40:43 +0100 (ter, 26 abr 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_coding_episode IS

    -- =========================== Private constant declarations =====================
    k_active CONSTANT VARCHAR2(1) := 'A';
    k_yes    CONSTANT VARCHAR2(1) := 'Y';
    k_no     CONSTANT VARCHAR2(1) := 'N';

    -- =========================== Private variables =====================
    g_package_owner VARCHAR2(30 CHAR); -- Log and debug
    g_package_name  VARCHAR2(30 CHAR); -- Log and debug
    g_error         VARCHAR2(4000); -- Log and debug

    FUNCTION get_episodes_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt       IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result BOOLEAN;
    BEGIN
        -- Call the function
        l_result := alert.pk_episode.get_episodes_list(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_dt       => i_dt,
                                                       o_episodes => o_episodes,
                                                       o_error    => o_error);
        RETURN l_result;
    END get_episodes_list;

    FUNCTION get_patient_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN NUMBER,
        o_patient_data OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET PATIENT DATA';
        OPEN o_patient_data FOR
            SELECT p.id_patient,
                   p.id_person,
                   p.name,
                   p.gender,
                   p.dt_birth,
                   p.flg_status,
                   p.last_name,
                   p.middle_name,
                   p.institution_key,
                   p.patient_number,
                   p.record_status,
                   p.flg_sensitive_record,
                   p.flg_patient_test
              FROM alert_adtcod.patient p
             WHERE p.id_patient = i_id_patient;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_patient_data);
            RETURN FALSE;
    END get_patient_data;

    FUNCTION get_pat_soc_attributes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN NUMBER,
        o_soc_attributes OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET RECORDS FROM TABLE pat_soc_attributes';
        OPEN o_soc_attributes FOR
            SELECT cnt.id_pat_soc_attributes,
                   cnt.address,
                   cnt.location,
                   cnt.district,
                   cnt.zip_code,
                   cnt.country,
                   cnt.num_main_contact,
                   cnt.num_contact,
                   cnt.id_country_nation,
                   cnt.country_alpha2_code,
                   cnt.id_doc_type,
                   cnt.num_contrib,
                   cnt.national_health_number,
                   cnt.record_status
              FROM (SELECT row_number() over(ORDER BY psa.id_institution DESC) AS rn,
                           psa.id_pat_soc_attributes,
                           psa.address,
                           psa.location,
                           psa.district,
                           psa.zip_code,
                           pk_translation.get_translation(i_lang, cn.code_country) AS country,
                           psa.num_main_contact,
                           psa.num_contact,
                           psa.id_country_nation,
                           cn.alpha2_code AS country_alpha2_code,
                           psa.id_doc_type,
                           psa.num_contrib,
                           psa.national_health_number,
                           psa.record_status
                      FROM pat_soc_attributes psa
                      LEFT OUTER JOIN alert.country cn
                        ON cn.id_country = psa.id_country_nation
                     WHERE psa.id_patient = i_id_patient
                       AND psa.id_institution IN (i_prof.institution, 0)) cnt
             WHERE cnt.rn = 1;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_SOC_ATTRIBUTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soc_attributes);
            RETURN FALSE;
    END get_pat_soc_attributes;

    FUNCTION get_epis_health_plans
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER,
        o_epis_health_plans OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EPISODE HEALTH PLANS';
        OPEN o_epis_health_plans FOR
            SELECT p.id_pat_health_plan,
                   p.id_health_plan,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT hpe.code_health_plan_entity
                                                     FROM alert_adtcod_cfg.health_plan_entity hpe
                                                    WHERE hpe.id_health_plan_entity = hp.id_health_plan_entity)) AS health_plan_entity,
                   pk_translation.get_translation(i_lang, hp.code_health_plan) AS health_plan,
                   p.num_health_plan,
                   p.dt_effective,
                   p.dt_health_plan,
                   p.flg_default,
                   decode(e.record_status, k_active, k_yes, k_no) AS flg_episode,
                   coalesce(e.flg_primary, k_no) AS flg_primary,
                   e.billing_notes
              FROM pat_health_plan p
             INNER JOIN alert_adtcod_cfg.health_plan hp
                ON hp.id_health_plan = p.id_health_plan
              LEFT OUTER JOIN epis_health_plan e
                ON e.id_pat_health_plan = p.id_pat_health_plan
               AND e.id_episode = i_id_episode
             WHERE p.id_patient = i_id_patient
               AND p.institution_key = i_prof.institution
               AND p.flg_status = k_active;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EPIS_HEALTH_PLANS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_epis_health_plans);
            RETURN FALSE;
    END get_epis_health_plans;

BEGIN
    -- Initialization and log
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    alertlog.pk_alertlog.log_init(object_name => g_package_name);
END pk_coding_episode;
/
