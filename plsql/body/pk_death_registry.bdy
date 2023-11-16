/*-- Last Change Revision: $Rev: 2026933 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_death_registry AS
    -- nom024

    k_alert_diagnosis CONSTANT VARCHAR2(0200 CHAR) := 'K_ALERT_DIAGNOSIS';
    k_epis_diagnosis  CONSTANT VARCHAR2(0200 CHAR) := 'K_EPIS_DIAGNOSIS';

    xsp  CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    k_lf CONSTANT VARCHAR2(0010 CHAR) := chr(10);

    tbl_anomaly table_varchar := table_varchar();

    k_mx_max_age CONSTANT NUMBER := 120;
    err_wrong_date_norm EXCEPTION;
    --subtype t_ltz is timestamp with local time zone;
    SUBTYPE t_low_char IS VARCHAR2(0200 CHAR);

    --
    -- PRIVATE SUBTYPES

    tbl_age_type     table_varchar := table_varchar('YEARS', 'MONTHS', 'WEEKS', 'DAYS', 'HOURS', 'MINUTES');
    tbl_age_num_type table_varchar := table_varchar('Y', 'M', 'W', 'D', 'H', 'MI');
    tbl_unit_mea     table_number := table_number(10373, 1127, 10375, 1039, 1041, 81040);

    -- PARTIAL DATE VALIDATION CONSTANTS
    k_pos_dd CONSTANT NUMBER := 7;
    k_pos_mm CONSTANT NUMBER := 5;
    k_pos_yy CONSTANT NUMBER := 1;
    k_pos_hr CONSTANT NUMBER := 9;
    k_len    CONSTANT NUMBER := 2;
    k_leny   CONSTANT NUMBER := 4;
    k_empty  CONSTANT VARCHAR2(0010 CHAR) := '00';

    k_dp_mode_mmyyyy CONSTANT VARCHAR2(0050 CHAR) := 'PARTIAL_DATE_MMYYYY';
    k_dp_mode_yyyy   CONSTANT VARCHAR2(0050 CHAR) := 'PARTIAL_DATE_YYYY';
    k_dp_mode_full   CONSTANT VARCHAR2(0050 CHAR) := 'FULL_DATE';

    k_mode_dyndata_summary CONSTANT VARCHAR2(0050 CHAR) := 'SUMMARY';
    k_mode_dyndata_detail  CONSTANT VARCHAR2(0050 CHAR) := 'DETAIL';

    --k_market_mx CONSTANT NUMBER := 16;

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    --
    -- PRIVATE CONSTANTS
    --
    k_yes                 CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    k_no                  CONSTANT VARCHAR2(0001 CHAR) := 'N';
    k_flg_dr_type_patient CONSTANT VARCHAR2(0010 CHAR) := 'P';
    k_flg_dr_type_fetus   CONSTANT VARCHAR2(0010 CHAR) := 'F';

    k_patient_is_alive      CONSTANT VARCHAR2(0001 CHAR) := k_yes;
    k_patient_is_not_alive  CONSTANT VARCHAR2(0001 CHAR) := k_no;
    k_section_is_active     CONSTANT VARCHAR2(0001 CHAR) := k_yes;
    k_section_is_not_active CONSTANT VARCHAR2(0001 CHAR) := k_no;

    k_dtype_n CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_dtype_v CONSTANT VARCHAR2(0010 CHAR) := 'V';
    k_dtype_t CONSTANT VARCHAR2(0010 CHAR) := 'D';

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    -- Death registry dynamic screen component names
    c_ds_death_registry CONSTANT ds_component.internal_name%TYPE := 'DEATH_REGISTRY';
    --
    c_ds_death_data       CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATA';
    c_ds_death_data_fetal CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATA_FETAL';
    c_ds_organ_donor      CONSTANT ds_component.internal_name%TYPE := 'ORGAN_DONATION';
    --
    c_ds_dt_death              CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATE_TIME';
    c_ds_prof_verified_death   CONSTANT ds_component.internal_name%TYPE := 'DEATH_VERIFIED';
    c_ds_natural_cause         CONSTANT ds_component.internal_name%TYPE := 'NATURAL_CAUSES';
    c_ds_coroner_warned        CONSTANT ds_component.internal_name%TYPE := 'CORONER_WARNED';
    c_ds_death_certifier_phone CONSTANT ds_component.internal_name%TYPE := 'DEATH_CERTIFIER_PHONE';

    c_phone_no_aplica CONSTANT VARCHAR2(200 CHAR) := '8888888888';

    --k_ds_folio_birth CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATA_FOLIO_BIRTH';

    -- changing array may cause to changes to be reflected in check_dyn_field
    c_ds_death_cause     CONSTANT table_varchar := table_varchar('DIRECT_CAUSE',
                                                                 'UNDERLYING_CAUSE_1',
                                                                 'UNDERLYING_CAUSE_2',
                                                                 'UNDERLYING_CAUSE_3',
                                                                 'DEATH_DATA_ADDITIONAL_CAUSE_1',
                                                                 'DEATH_DATA_ADDITIONAL_CAUSE_2',
                                                                 'DEATH_DATA_CAUSE_6',
                                                                 'DS_UNDERLYING_CAUSE_4',
                                                                 'DS_DEATH_DATA_ANTECENT_CAUSE2',
                                                                 'DS_DEATH_DATA_MORBID2',
                                                                 'DS_DEATH_DATA_ANY_CAUSE2',
                                                                 'DS_DEATH_DATA_ABOVE_CAUSE2',
                                                                 'DS_DEATH_PROBABLE_CAUSE',
                                                                 'DS_MAIN_CAUSE',
                                                                 'DS_FETAL_CAUSE_1',
                                                                 'DS_FETAL_CAUSE_2',
                                                                 'DS_FETAL_CAUSE_3',
                                                                 'DS_FETAL_CAUSE_4');
    c_ds_autopsy         CONSTANT ds_component.internal_name%TYPE := 'AUTOPSY';
    k_ds_folio_birth     CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATA_FOLIO_BIRTH';
    k_ds_folio_birth_flg CONSTANT ds_component.internal_name%TYPE := 'DEATH_DATA_FOLIO_BIRTH_FLG';

    k_ctype_d   CONSTANT VARCHAR2(0010 CHAR) := 'D';
    k_ctype_dt  CONSTANT VARCHAR2(0010 CHAR) := 'DT';
    k_ctype_dp  CONSTANT VARCHAR2(0010 CHAR) := 'DP';
    k_ctype_dtp CONSTANT VARCHAR2(0010 CHAR) := 'DTP';
    k_ctype_ft  CONSTANT VARCHAR2(0010 CHAR) := 'FT';
    k_ctype_ms  CONSTANT VARCHAR2(0010 CHAR) := 'MS';
    k_ctype_mm  CONSTANT VARCHAR2(0010 CHAR) := 'MM';
    k_ctype_md  CONSTANT VARCHAR2(0010 CHAR) := 'MD';
    k_ctype_mc  CONSTANT VARCHAR2(0010 CHAR) := 'MC';
    k_ctype_mr  CONSTANT VARCHAR2(0010 CHAR) := 'MR';
    k_ctype_mo  CONSTANT VARCHAR2(0010 CHAR) := 'MO';
    k_ctype_mj  CONSTANT VARCHAR2(0010 CHAR) := 'MJ';
    k_ctype_mp  CONSTANT VARCHAR2(0010 CHAR) := 'MP';
    k_ctype_ml  CONSTANT VARCHAR2(0010 CHAR) := 'ML';
    k_ctype_me  CONSTANT VARCHAR2(0010 CHAR) := 'ME';
    k_ctype_n   CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_ctype_fr  CONSTANT VARCHAR2(0010 CHAR) := 'FR';
    k_ctype_fc  CONSTANT VARCHAR2(0010 CHAR) := 'FC';
    k_ctype_k   CONSTANT VARCHAR2(0010 CHAR) := 'K';

    --
    c_direct_cause_rank CONSTANT death_cause.death_cause_rank%TYPE := 1;

    --
    -- PRIVATE FUNCTIONS
    --

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    FUNCTION map_dt_type_2_abr(i_type IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(0100 CHAR);
    BEGIN
    
        -- default value
        l_return := tbl_age_num_type(1);
    
        <<lup_thru_dt_mask>>
        FOR i IN 1 .. tbl_age_type.count
        LOOP
            IF tbl_age_type(i) = i_type
            THEN
                l_return := tbl_age_num_type(i);
                EXIT lup_thru_dt_mask;
            END IF;
        END LOOP lup_thru_dt_mask;
    
        RETURN l_return;
    
    END map_dt_type_2_abr;

    -- **********************************************************************
    FUNCTION get_death_cause_tbl(i_death_registry IN NUMBER) RETURN ts_death_cause.death_cause_tc IS
        l_dc_tbl ts_death_cause.death_cause_tc;
    BEGIN
    
        SELECT dc.*
          BULK COLLECT
          INTO l_dc_tbl
          FROM death_cause dc
         WHERE dc.id_death_registry = i_death_registry;
    
        RETURN l_dc_tbl;
    
    END get_death_cause_tbl;

    -- **********************************************************************
    FUNCTION get_id_ds_component(i_internal_name IN VARCHAR2) RETURN NUMBER IS
        tbl_id   table_number;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT id_ds_component
          BULK COLLECT
          INTO tbl_id
          FROM ds_component
         WHERE internal_name = i_internal_name;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_ds_component;

    FUNCTION get_flg_data_type(i_id_ds_comp IN NUMBER) RETURN VARCHAR2 IS
        l_datatype VARCHAR2(0010 CHAR);
        tbl_dtype  table_varchar;
    BEGIN
    
        SELECT flg_data_type
          BULK COLLECT
          INTO tbl_dtype
          FROM ds_component
         WHERE id_ds_component = i_id_ds_comp;
    
        IF tbl_dtype.count > 0
        THEN
            l_datatype := tbl_dtype(1);
        END IF;
    
        RETURN l_datatype;
    
    END get_flg_data_type;

    -- *****************************************************
    FUNCTION check_if_organ_donor(i_patient IN NUMBER) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM organ_donor
         WHERE id_patient = i_patient
           AND flg_status = 'A';
    
        RETURN l_count > 0;
    
    END check_if_organ_donor;

    -- ***************************************************************************
    PROCEDURE register_anomaly(i_text IN VARCHAR2) IS
    BEGIN
    
        tbl_anomaly.extend;
        tbl_anomaly(tbl_anomaly.count) := i_text || k_lf;
    
    END register_anomaly;

    -- ****************************************************************
    FUNCTION check_mx_max_age
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN BOOLEAN IS
        l_age     NUMBER;
        l_bool    BOOLEAN;
        l_anomaly VARCHAR2(4000);
        k_code_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_010';
        k_year     CONSTANT VARCHAR2(0100 CHAR) := tbl_age_num_type(1);
    BEGIN
    
        l_age := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_type    => k_year);
    
        l_bool := l_age > k_mx_max_age;
    
        IF l_bool
        THEN
        
            -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
            l_anomaly := pk_message.get_message(i_lang, k_code_msg);
            register_anomaly(l_anomaly);
        
        END IF;
    
        RETURN TRUE;
    
    END check_mx_max_age;

    -- ****************************************************************
    FUNCTION check_age_range
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_flg_death IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age NUMBER;
        k_year     CONSTANT VARCHAR2(0010 CHAR) := tbl_age_num_type(1);
        k_code_msg CONSTANT VARCHAR2(0200 CHAR) := 'DR_NORM024_013';
        l_bool_inf BOOLEAN;
        l_bool_sup BOOLEAN;
        l_msg      VARCHAR2(4000);
    
    BEGIN
    
        l_age := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_type    => k_year);
    
        l_bool_inf := l_age BETWEEN 8 AND 9;
        l_bool_sup := l_age BETWEEN 55 AND 59;
    
        o_flg_show := k_no;
    
        IF (l_bool_inf OR l_bool_sup)
        THEN
            o_flg_show := k_yes;
            l_msg      := pk_message.get_message(i_lang, k_code_msg);
            l_msg      := REPLACE(l_msg, '@1', to_char(l_age));
            o_msg      := l_msg;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => 'CHECK_AGE_RANGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END check_age_range;

    -- *****************************************************************
    FUNCTION check_if_patient_dead(i_patient IN NUMBER) RETURN VARCHAR2 IS
        k_dr_active CONSTANT VARCHAR2(0010 CHAR) := 'A';
        l_return VARCHAR2(0010 CHAR) := k_patient_is_alive;
        l_count  NUMBER(24);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM death_registry dr
          JOIN episode e
            ON e.id_episode = dr.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE dr.flg_status = k_dr_active
           AND dr.flg_type = k_flg_dr_type_patient
           AND v.id_patient = i_patient;
    
        l_return := iif(l_count > 0, k_patient_is_not_alive, l_return);
    
        RETURN l_return;
    
    END check_if_patient_dead;

    -- *****************************************************
    FUNCTION check_death_registry(i_patient IN NUMBER) RETURN NUMBER IS
        k_dr_active CONSTANT VARCHAR2(0010 CHAR) := 'A';
        l_count NUMBER(24);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM death_registry dr
          JOIN episode e
            ON e.id_episode = dr.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE dr.flg_status = k_dr_active
           AND v.id_patient = i_patient;
    
        RETURN l_count;
    
    END check_death_registry;
    -- Para cert-MX-NORM24
    FUNCTION check_folio_uk
    (
        i_lang           IN NUMBER,
        i_section        IN VARCHAR2,
        i_patient        IN NUMBER,
        i_death_registry IN NUMBER
    ) RETURN BOOLEAN IS
        l_count  NUMBER;
        tbl_comp table_varchar := table_varchar('DEATH_DATA_FOLIO', 'DEATH_FETAL_PREV_PREG_FOLIO');
    
        xdrd           death_registry_det%ROWTYPE;
        k_code_msg_025 VARCHAR2(0100 CHAR) := 'DR_NORM024_025';
        k_code_msg_026 VARCHAR2(0100 CHAR) := 'DR_NORM024_026';
        l_anomaly      VARCHAR2(1000 CHAR);
    
        CURSOR cur_dc(i_death_registry IN NUMBER) IS
            SELECT x.*, d.internal_name
              FROM death_registry_det x
              JOIN ds_component d
                ON d.id_ds_component = x.id_ds_component
             WHERE x.id_death_registry = i_death_registry
               AND d.internal_name IN (SELECT column_value comp_name
                                         FROM TABLE(tbl_comp) xtbl);
    BEGIN
    
        <<lup_thru_intervals>>
        FOR xdrd IN cur_dc(i_death_registry)
        LOOP
        
            IF xdrd.value_n IS NOT NULL
            THEN
                IF i_section = c_ds_death_data
                   OR xdrd.internal_name = 'DEATH_DATA_FOLIO'
                THEN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM death_registry dr
                      JOIN death_registry_det drd
                        ON dr.id_death_registry = drd.id_death_registry
                     WHERE drd.id_ds_component = xdrd.id_ds_component
                       AND drd.id_death_registry <> i_death_registry
                       AND drd.value_n = xdrd.value_n
                    --AND dr.flg_status <> 'C'
                    ;
                ELSE
                    SELECT COUNT(1)
                      INTO l_count
                      FROM death_registry dr
                      JOIN death_registry_det drd
                        ON dr.id_death_registry = drd.id_death_registry
                     WHERE drd.id_ds_component = xdrd.id_ds_component
                       AND drd.id_death_registry <> i_death_registry
                       AND dr.id_episode NOT IN (SELECT id_episode
                                                   FROM episode
                                                  WHERE id_patient = i_patient)
                       AND drd.value_n = xdrd.value_n
                    --AND dr.flg_status <> 'C'
                    ;
                END IF;
                IF l_count > 0
                THEN
                    IF i_section = c_ds_death_data
                       OR xdrd.internal_name = 'DEATH_DATA_FOLIO'
                    THEN
                        l_anomaly := pk_message.get_message(i_lang, k_code_msg_025);
                    ELSE
                        l_anomaly := pk_message.get_message(i_lang, k_code_msg_026);
                    END IF;
                    register_anomaly(l_anomaly);
                
                END IF;
            END IF;
        END LOOP;
        RETURN TRUE;
    END check_folio_uk;
    -- *************************************************************************
    FUNCTION get_section_status
    (
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        i_patient       IN NUMBER,
        i_type          IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2 IS
        l_flg_active  VARCHAR2(001 CHAR);
        l_is_pat_dead VARCHAR2(0010 CHAR);
        l_bool        BOOLEAN;
        k_sys_config CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_REGISTRY_ALLOW_EDIT';
    BEGIN
    
        CASE i_internal_name
            WHEN c_ds_death_data THEN
            
                l_is_pat_dead := check_if_patient_dead(i_patient => i_patient);
            
                l_bool       := l_is_pat_dead = k_patient_is_alive;
                l_flg_active := iif(l_bool, k_section_is_active, k_section_is_not_active);
                IF i_type = 'E'
                THEN
                    IF pk_sysconfig.get_config(i_code_cf => k_sys_config, i_prof => i_prof) = pk_alert_constant.g_no
                    THEN
                        l_flg_active := k_section_is_not_active;
                    ELSE
                        l_flg_active := k_section_is_active;
                    END IF;
                END IF;
            WHEN c_ds_organ_donor THEN
            
                l_bool       := check_if_organ_donor(i_patient => i_patient);
                l_flg_active := iif(l_bool, k_section_is_not_active, k_section_is_active);
            
            ELSE
                l_flg_active := k_section_is_active;
        END CASE;
    
        RETURN l_flg_active;
    
    END get_section_status;

    --***********************************************************
    FUNCTION get_death_registry_row
    (
        i_death_registry IN death_registry.id_death_registry%TYPE DEFAULT NULL,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_status         IN death_registry.flg_status%TYPE DEFAULT NULL
    ) RETURN death_registry%ROWTYPE IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_REGISTRY_ROW';
        l_dbg_msg debug_msg;
        l_dr_row  death_registry%ROWTYPE;
    BEGIN
    
        IF i_death_registry IS NOT NULL
        THEN
            l_dbg_msg := 'get death registry data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT dr.*
              INTO l_dr_row
              FROM death_registry dr
             WHERE dr.id_death_registry = i_death_registry;
        
        ELSE
            l_dbg_msg := 'get patient death data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT dro.*
              INTO l_dr_row
              FROM (SELECT dr.*
                      FROM death_registry dr
                     INNER JOIN episode e
                        ON dr.id_episode = e.id_episode
                     WHERE e.id_patient = i_patient
                          -- cmf 02-12-2016
                       AND dr.flg_type = k_flg_dr_type_patient
                          --
                       AND (i_status IS NULL OR dr.flg_status = i_status)
                     ORDER BY dr.dt_death_registry DESC) dro
             WHERE rownum = 1;
        
        END IF;
    
        RETURN l_dr_row;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_dbg_msg := 'patient does not have a death registry';
            pk_alertlog.log_warn(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_dr_row.id_death_registry := NULL;
            RETURN l_dr_row;
        
    END get_death_registry_row;

    --************************************************************************************
    FUNCTION get_death_registry_row_f(i_death_registry IN death_registry.id_death_registry%TYPE DEFAULT NULL)
        RETURN death_registry%ROWTYPE IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_REGISTRY_ROW';
        l_dbg_msg debug_msg;
    
        l_dr_row death_registry%ROWTYPE;
    
    BEGIN
        IF i_death_registry IS NOT NULL
        THEN
            l_dbg_msg := 'get death registry data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_dr_row := get_death_registry_row(i_death_registry => i_death_registry,
                                               i_patient        => NULL,
                                               i_status         => NULL);
        
        END IF;
    
        RETURN l_dr_row;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_dbg_msg := 'patient does not have a death registry';
            pk_alertlog.log_warn(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            l_dr_row.id_death_registry := NULL;
            RETURN l_dr_row;
        
    END get_death_registry_row_f;

    --************************************************************************************
    FUNCTION get_death_cause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        i_component_name IN VARCHAR2 DEFAULT c_ds_death_data,
        o_data_val       IN OUT NOCOPY table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_CAUSE';
        l_dbg_msg debug_msg;
    
        l_dc_tbl ts_death_cause.death_cause_tc;
    BEGIN
        l_dbg_msg := 'get death causes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dc_tbl := get_death_cause_tbl(i_death_registry => i_death_registry);
    
        <<lup_thru_death_cause>>
        FOR idx IN 1 .. l_dc_tbl.count()
        LOOP
        
            CASE i_component_name
                WHEN c_ds_death_data THEN
                
                    IF l_dc_tbl(idx).id_epis_diagnosis IS NOT NULL
                        AND l_dc_tbl(idx).id_epis_diagnosis <> -1
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_epis_diagn(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_data_val => o_data_val,
                                                                             i_name     => c_ds_death_cause(l_dc_tbl(idx).death_cause_rank),
                                                                             i_value    => l_dc_tbl(idx).id_epis_diagnosis);
                    ELSE
                        o_data_val := pk_dynamic_screen.add_value_diagn(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_data_val   => o_data_val,
                                                                        i_name       => c_ds_death_cause(l_dc_tbl(idx).death_cause_rank),
                                                                        i_value      => l_dc_tbl(idx).id_death_cause,
                                                                        i_value_hist => NULL);
                    END IF;
                ELSE
                    --WHEN c_ds_death_data_fetal THEN
                    IF l_dc_tbl(idx).id_epis_diagnosis <> -1
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_epis_diagn(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_data_val => o_data_val,
                                                                             i_name     => c_ds_death_cause(l_dc_tbl(idx).death_cause_rank),
                                                                             i_value    => l_dc_tbl(idx).id_epis_diagnosis);
                    ELSE
                        o_data_val := pk_dynamic_screen.add_value_diagn(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_data_val   => o_data_val,
                                                                        i_name       => c_ds_death_cause(l_dc_tbl(idx).death_cause_rank),
                                                                        i_value      => l_dc_tbl(idx).id_death_cause,
                                                                        i_value_hist => NULL);
                    END IF;
            END CASE;
        
        END LOOP lup_thru_death_cause;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_death_cause;

    -- ***************************************************************
    FUNCTION check_folio_birth_value
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_value      IN VARCHAR2 DEFAULT NULL,
        i_flg_origin IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_ds_folio_birth VARCHAR2(4000);
        l_age            NUMBER;
        k_default_value CONSTANT VARCHAR2(0050 CHAR) := '000000000';
        k_value_ne      CONSTANT VARCHAR2(0050 CHAR) := '888888888';
        k_year          CONSTANT VARCHAR2(0100 CHAR) := tbl_age_num_type(1);
        k_one_year      CONSTANT NUMBER := 1;
    BEGIN
    
        l_ds_folio_birth := i_value;
        IF i_value IS NULL
        THEN
            l_age := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_patient => i_patient,
                                                i_type    => k_year);
            IF l_age <= k_one_year
            THEN
                l_ds_folio_birth := pk_adt.get_code_birth_certificate(i_patient => i_patient);
            END IF;
        END IF;
        IF i_flg_origin IS NOT NULL
        --   AND l_ds_folio_birth IS NULL
        THEN
        
            l_ds_folio_birth := iif(l_age >= k_one_year, k_default_value, k_value_ne);
        END IF;
    
        RETURN l_ds_folio_birth;
    
    END check_folio_birth_value;

    -- ***************************************************************
    FUNCTION get_death_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_status    IN death_registry.flg_status%TYPE DEFAULT NULL,
        o_data_val  OUT table_table_varchar,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_DATA';
        l_dbg_msg debug_msg;
        l_dr_row  death_registry%ROWTYPE;
    
        l_name           ds_cmpt_mkt_rel.internal_name_parent%TYPE;
        l_value          sys_list.id_sys_list%TYPE;
        l_ds_folio_birth VARCHAR2(4000);
        k_folio_birth_flg_spec CONSTANT sys_list.id_sys_list%TYPE := 11552;
    BEGIN
        l_dbg_msg := 'get patient death data, if exists';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dr_row := get_death_registry_row(i_patient => i_patient, i_status => i_status);
    
        pk_dynamic_screen.set_data_key(l_dr_row.id_death_registry);
    
        o_data_val := pk_dynamic_screen.add_value_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_data_val  => o_data_val,
                                                       i_name      => c_ds_dt_death,
                                                       i_value     => l_dr_row.dt_death,
                                                       i_desc_mode => l_dr_row.death_date_format);
    
        o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_data_val => o_data_val,
                                                       i_name     => c_ds_prof_verified_death,
                                                       i_value    => l_dr_row.id_prof_verified_death);
    
        <<lup_thru_sl_fields>>
        FOR i IN 1 .. 3
        LOOP
        
            CASE i
                WHEN 1 THEN
                    l_name  := c_ds_natural_cause;
                    l_value := l_dr_row.id_sl_natural_cause;
                WHEN 2 THEN
                    l_name  := c_ds_coroner_warned;
                    l_value := l_dr_row.id_sl_coroner_warned;
                    /*
                          WHEN 3 THEN
                              l_name  := c_ds_autopsy;
                              l_value := l_dr_row.id_sl_autopsy;
                    */
                ELSE
                    l_name  := NULL;
                    l_value := NULL;
            END CASE;
        
            IF l_name IS NOT NULL
            THEN
                o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_data_val => o_data_val,
                                                             i_name     => l_name,
                                                             i_value    => l_value);
            END IF;
        
        END LOOP lup_thru_sl_fields;
    
        IF NOT get_death_cause(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_death_registry => l_dr_row.id_death_registry,
                               o_data_val       => o_data_val,
                               o_error          => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        o_data_val := get_dyn_data(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_death_registry => l_dr_row.id_death_registry,
                                   i_data_val       => o_data_val);
    
        l_dbg_msg := 'get info about the professional that made the registry';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_dynamic_screen.get_death_registry_prof_data(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_tbl_id    => table_number(l_dr_row.id_death_registry),
                                                              o_prof_data => o_prof_data,
                                                              o_error     => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_death_data;

    /* *********************************************************************************************
    * Get death cause next id
    *
    * @return       Death cause next id
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        29-Jun-2010
    **********************************************************************************************/
    FUNCTION set_flag_mode(i_flg_mode IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        CASE i_flg_mode
            WHEN k_dp_mode_mmyyyy THEN
                l_return := pk_dynamic_screen.k_dp_mode_mmyyyy;
            WHEN k_dp_mode_yyyy THEN
                l_return := pk_dynamic_screen.k_dp_mode_yyyy;
            ELSE
                l_return := pk_dynamic_screen.k_dt_output_01;
        END CASE;
    
        RETURN l_return;
    
    END set_flag_mode;

    -- *************************************************************************************
    FUNCTION get_all_dyn_data
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_mode        IN VARCHAR2,
        i_id_registry IN NUMBER,
        i_data_val    IN table_table_varchar
    ) RETURN table_table_varchar IS
    
        CURSOR c_drd(i_dregistry IN NUMBER) IS
            SELECT xsql.*
              FROM (SELECT dc.id_ds_component,
                           dc.internal_name,
                           drd.value_n,
                           drd.value_tz,
                           drd.value_vc2,
                           drd.unit_measure_value,
                           pk_death_registry.get_datatype(dc.id_ds_component) ds_datatype
                      FROM (
                            -- detail page
                            SELECT dhist.value_n,
                                    dhist.value_tz,
                                    dhist.value_vc2,
                                    dhist.unit_measure_value,
                                    dhist.id_ds_component
                              FROM death_registry_det_hist dhist
                             WHERE dhist.id_death_registry_hist = i_dregistry
                               AND i_mode = k_mode_dyndata_detail
                            UNION ALL
                            -- summary page
                            SELECT dsum.value_n,
                                    dsum.value_tz,
                                    dsum.value_vc2,
                                    dsum.unit_measure_value,
                                    dsum.id_ds_component
                              FROM death_registry_det dsum
                             WHERE dsum.id_death_registry = i_dregistry
                               AND i_mode = k_mode_dyndata_summary) drd
                      JOIN ds_component dc
                        ON drd.id_ds_component = dc.id_ds_component) xsql;
    
        l_main_id   NUMBER;
        l_hist_id   NUMBER;
        l_mode      t_low_char;
        l_flag_mode t_low_char;
    
        TYPE typ_tbl_drd IS TABLE OF c_drd%ROWTYPE;
        tbl_row           typ_tbl_drd;
        l_data_val        table_table_varchar := i_data_val;
        l_name            VARCHAR2(0200 CHAR);
        l_flg_data_type   VARCHAR2(0010 CHAR);
        l_id_jurisdiction NUMBER;
        l_desc            VARCHAR2(500 CHAR);
        -- **********************************************************
        PROCEDURE process_main_n_hist_id
        (
            i_mode        IN VARCHAR2,
            i_id_registry IN NUMBER,
            o_main_id     OUT NUMBER,
            o_hist_id     OUT NUMBER
        ) IS
        BEGIN
        
            CASE i_mode
                WHEN k_mode_dyndata_summary THEN
                    o_main_id := i_id_registry;
                    o_hist_id := NULL;
                WHEN k_mode_dyndata_detail THEN
                    o_main_id := i_id_registry;
                    o_hist_id := i_id_registry;
                ELSE
                    o_main_id := i_id_registry;
                    o_hist_id := NULL;
            END CASE;
        
        END process_main_n_hist_id;
    
        FUNCTION get_nationality(i_country IN NUMBER) RETURN VARCHAR2 IS
            l_desc VARCHAR2(500 CHAR);
        BEGIN
            SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => c.code_nationality) || ' (' ||
                   pk_translation.get_translation(i_lang, c.code_country) || ')'
              INTO l_desc
              FROM country c
             WHERE c.id_country = i_country;
            RETURN l_desc;
        END get_nationality;
    
        FUNCTION get_relation(i_relation IN NUMBER) RETURN VARCHAR2 IS
            l_desc VARCHAR2(500 CHAR);
        BEGIN
            SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => fr.code_family_relationship)
              INTO l_desc
              FROM family_relationship fr
             WHERE fr.id_family_relationship = i_relation;
            RETURN l_desc;
        END get_relation;
    
    BEGIN
    
        process_main_n_hist_id(i_mode        => i_mode,
                               i_id_registry => i_id_registry,
                               o_main_id     => l_main_id,
                               o_hist_id     => l_hist_id);
    
        OPEN c_drd(i_dregistry => l_main_id);
        FETCH c_drd BULK COLLECT
            INTO tbl_row;
        CLOSE c_drd;
    
        <<lup_thru_records>>
        FOR i IN 1 .. tbl_row.count
        LOOP
        
            l_name          := tbl_row(i).internal_name;
            l_flg_data_type := get_flg_data_type(tbl_row(i).id_ds_component);
            --        l_internal_name = 
            CASE tbl_row(i).ds_datatype
                WHEN k_dtype_n THEN
                    CASE
                        WHEN l_flg_data_type = k_ctype_ms THEN
                            IF tbl_row(i).internal_name IN ('DEATH_PAT_INFO_FATHER_NAT', 'DEATH_PAT_INFO_MOTHER_NAT')
                            THEN
                                IF tbl_row(i).value_n IS NOT NULL
                                THEN
                                    l_desc     := get_nationality(tbl_row(i).value_n);
                                    l_data_val := pk_dynamic_screen.add_values_all(i_lang     => i_lang,
                                                                                   i_prof     => i_prof,
                                                                                   i_data_val => l_data_val,
                                                                                   i_name     => l_name,
                                                                                   i_value    => tbl_row(i).value_n,
                                                                                   i_text     => l_desc,
                                                                                   i_hist     => l_hist_id);
                                END IF;
                            ELSIF tbl_row(i).internal_name IN ('DEATH_DATA_EXAMIN_PHYSICIAN',
                                                     'DEATH_DATA_TREAT_PHYSICIAN',
                                                     'DEATH_DATA_DOCTOR_HOSP',
                                                     'DS_DEATH_DATA_CERTIFY_PHYSICIAN')
                            THEN
                                IF tbl_row(i).value_n IS NOT NULL
                                THEN
                                    l_data_val := pk_dynamic_screen.add_values_all(i_lang     => i_lang,
                                                                                   i_prof     => i_prof,
                                                                                   i_data_val => l_data_val,
                                                                                   i_name     => l_name,
                                                                                   i_value    => tbl_row(i).value_n,
                                                                                   i_text     => pk_prof_utils.get_name_signature(i_lang,
                                                                                                                                  i_prof,
                                                                                                                                  tbl_row(i).value_n),
                                                                                   i_hist     => l_hist_id);
                                END IF;
                            ELSIF tbl_row(i).internal_name = 'DEATH_DATA_PERSON_RELATION'
                            THEN
                                IF tbl_row(i).value_n IS NOT NULL
                                THEN
                                    l_desc     := get_relation(tbl_row(i).value_n);
                                    l_data_val := pk_dynamic_screen.add_values_all(i_lang     => i_lang,
                                                                                   i_prof     => i_prof,
                                                                                   i_data_val => l_data_val,
                                                                                   i_name     => l_name,
                                                                                   i_value    => tbl_row(i).value_n,
                                                                                   i_text     => l_desc,
                                                                                   i_hist     => l_hist_id);
                                END IF;
                            ELSE
                                l_data_val := pk_dynamic_screen.add_value_slms(i_lang     => i_lang,
                                                                               i_prof     => i_prof,
                                                                               i_data_val => l_data_val,
                                                                               i_name     => l_name,
                                                                               i_value    => tbl_row(i).value_n,
                                                                               i_hist     => l_hist_id);
                            END IF;
                        WHEN l_flg_data_type = k_ctype_k THEN
                            l_data_val := pk_dynamic_screen.add_value_k(i_lang     => i_lang,
                                                                        i_prof     => i_prof,
                                                                        i_data_val => l_data_val,
                                                                        i_name     => l_name,
                                                                        i_value    => tbl_row(i).value_n,
                                                                        i_um       => tbl_row(i).unit_measure_value,
                                                                        i_hist     => l_hist_id);
                        
                        WHEN l_flg_data_type IN (k_ctype_me, k_ctype_ml, k_ctype_mp) THEN
                        
                            l_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          i_data_val => l_data_val,
                                                                          i_name     => l_name,
                                                                          i_value    => nvl(tbl_row(i).value_n,
                                                                                            to_number(tbl_row(i).value_vc2)),
                                                                          i_hist     => l_hist_id);
                        WHEN l_flg_data_type = k_ctype_mj THEN
                            l_id_jurisdiction := pk_adt.get_jurisdiction_id(tbl_row(i).value_n);
                        
                            l_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          i_data_val => l_data_val,
                                                                          i_name     => l_name,
                                                                          i_value    => tbl_row(i).value_n,
                                                                          i_type     => l_flg_data_type,
                                                                          i_hist     => l_hist_id);
                        WHEN l_flg_data_type = k_ctype_fc THEN
                            l_data_val := pk_dynamic_screen.add_value_fc(i_lang     => i_lang,
                                                                         i_prof     => i_prof,
                                                                         i_data_val => l_data_val,
                                                                         i_name     => l_name,
                                                                         i_value    => tbl_row(i).value_n,
                                                                         i_hist     => l_hist_id);
                        
                        ELSE
                            l_data_val := pk_dynamic_screen.add_value_text(i_data_val => l_data_val,
                                                                           i_name     => l_name,
                                                                           i_value    => to_char(tbl_row(i).value_n),
                                                                           i_hist     => l_hist_id);
                    END CASE;
                
                WHEN k_dtype_v THEN
                
                    l_data_val := pk_dynamic_screen.add_value_text(i_data_val => l_data_val,
                                                                   i_name     => l_name,
                                                                   i_value    => tbl_row(i).value_vc2,
                                                                   i_hist     => l_hist_id);
                
                WHEN k_dtype_t THEN
                
                    CASE
                        WHEN l_flg_data_type = k_ctype_d THEN
                            l_data_val := pk_dynamic_screen.add_value_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_data_val  => l_data_val,
                                                                           i_name      => l_name,
                                                                           i_desc_mode => pk_dynamic_screen.k_dt_output_02,
                                                                           i_value     => tbl_row(i).value_tz,
                                                                           i_hist      => l_hist_id);
                            --WHEN l_flg_data_type = k_ctype_dt THEN
                        WHEN l_flg_data_type IN (k_ctype_dp, k_ctype_dtp) THEN
                        
                            l_flag_mode := tbl_row(i).value_vc2;
                        
                            l_mode := set_flag_mode(i_flg_mode => l_flag_mode);
                        
                            l_data_val := pk_dynamic_screen.add_value_tstz(i_lang      => i_lang,
                                                                           i_prof      => i_prof,
                                                                           i_data_val  => l_data_val,
                                                                           i_name      => l_name,
                                                                           i_value     => tbl_row(i).value_tz,
                                                                           i_desc_mode => l_mode,
                                                                           i_hist      => l_hist_id);
                        
                        ELSE
                        
                            l_data_val := pk_dynamic_screen.add_value_tstz(i_lang     => i_lang,
                                                                           i_prof     => i_prof,
                                                                           i_data_val => l_data_val,
                                                                           i_name     => l_name,
                                                                           i_value    => tbl_row(i).value_tz,
                                                                           i_hist     => l_hist_id);
                        
                    END CASE;
                ELSE
                    l_data_val := pk_dynamic_screen.add_value_text(i_data_val => l_data_val,
                                                                   i_name     => l_name,
                                                                   i_value    => tbl_row(i).value_vc2,
                                                                   i_hist     => l_hist_id);
                
            END CASE;
        
        END LOOP lup_thru_records;
    
        RETURN l_data_val;
    
    END get_all_dyn_data;

    -- ***********************************************************************
    FUNCTION get_dyn_data
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_death_registry IN NUMBER,
        i_data_val       IN table_table_varchar
    ) RETURN table_table_varchar IS
    BEGIN
    
        RETURN get_all_dyn_data(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_mode        => k_mode_dyndata_summary,
                                i_id_registry => i_death_registry,
                                i_data_val    => i_data_val);
    
    END get_dyn_data;

    FUNCTION get_dyn_data_detail
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_death_registry_hist IN NUMBER,
        i_data_val            IN table_table_varchar
    ) RETURN table_table_varchar IS
    BEGIN
    
        RETURN get_all_dyn_data(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_mode        => k_mode_dyndata_detail,
                                i_id_registry => i_death_registry_hist,
                                i_data_val    => i_data_val);
    
    END get_dyn_data_detail;
    /**********************************************************************************************
    * Get death cause next id
    *
    * @return       Death cause next id
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        29-Jun-2010
    **********************************************************************************************/
    FUNCTION get_death_cause_nextval RETURN death_cause.id_death_cause%TYPE IS
        l_death_cause death_cause.id_death_cause%TYPE;
    BEGIN
        l_death_cause := seq_death_cause.nextval;
        RETURN l_death_cause;
    END get_death_cause_nextval;

    /**********************************************************************************************
    * Get death cause history next id
    *
    * @return       Death cause history next id
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        29-Jun-2010
    **********************************************************************************************/
    FUNCTION get_death_cause_hist_nextval RETURN death_cause_hist.id_death_cause_hist%TYPE IS
        l_death_cause_hist death_cause_hist.id_death_cause_hist%TYPE;
    BEGIN
        l_death_cause_hist := seq_death_cause_hist.nextval;
        RETURN l_death_cause_hist;
    END get_death_cause_hist_nextval;

    /**********************************************************************************************
    * Set death cause history
    *
    * @param        i_lang                   Language id
    * @param        i_death_registry         Death registry id
    * @param        i_death_registry_hist    Death registry history id
    * @param        o_death_cause_hist       Death cause history ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/

    FUNCTION set_death_cause_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_death_registry      IN death_registry.id_death_registry%TYPE,
        i_death_registry_hist IN death_registry_hist.id_death_registry_hist%TYPE,
        o_epis_diagnosis      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_CAUSE_DETAIL';
        l_dbg_msg debug_msg;
    
        l_dc_tbl  ts_death_cause.death_cause_tc;
        l_dch_tbl ts_death_cause_hist.death_cause_hist_tc;
        l_nrows   PLS_INTEGER;
    
    BEGIN
        l_dbg_msg := 'get death cause registries';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dc_tbl := get_death_cause_tbl(i_death_registry => i_death_registry);
    
        l_nrows := l_dc_tbl.count();
        IF l_nrows = 0
        THEN
            l_dbg_msg := 'Donor does not have organ/tissue donation registries';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            o_epis_diagnosis := NULL;
        
        ELSE
        
            o_epis_diagnosis := table_number();
            o_epis_diagnosis.extend(l_nrows);
        
            l_dbg_msg := 'fill death cause history data';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            FOR idx IN 1 .. l_nrows
            LOOP
                l_dch_tbl(idx).id_death_registry_hist := i_death_registry_hist;
                l_dch_tbl(idx).id_death_cause := l_dc_tbl(idx).id_death_cause;
                l_dch_tbl(idx).id_death_registry := l_dc_tbl(idx).id_death_registry;
                l_dch_tbl(idx).id_epis_diagnosis := l_dc_tbl(idx).id_epis_diagnosis;
                l_dch_tbl(idx).id_diagnosis := l_dc_tbl(idx).id_diagnosis;
                l_dch_tbl(idx).id_alert_diagnosis := l_dc_tbl(idx).id_alert_diagnosis;
                l_dch_tbl(idx).id_diag_inst_owner := l_dc_tbl(idx).id_diag_inst_owner;
                l_dch_tbl(idx).id_adiag_inst_owner := l_dc_tbl(idx).id_adiag_inst_owner;
                l_dch_tbl(idx).death_cause_rank := l_dc_tbl(idx).death_cause_rank;
                l_dch_tbl(idx).id_death_cause_hist := get_death_cause_hist_nextval();
            
                o_epis_diagnosis(idx) := l_dch_tbl(idx).id_epis_diagnosis;
            
            END LOOP;
        
            l_dbg_msg := 'insert values into death cause history';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            ts_death_cause_hist.ins(rows_in => l_dch_tbl);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_epis_diagnosis := NULL;
            RETURN FALSE;
        
    END set_death_cause_detail;

    /**********************************************************************************************
    * Set death registry history
    *
    * @param        i_lang                   Language id
    * @param        i_death_registry         Death registry id
    * @param        o_death_registry_hist    Death registry history id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/
    FUNCTION set_death_registry_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_death_registry      IN death_registry.id_death_registry%TYPE,
        o_death_registry_hist OUT death_registry_hist.id_death_registry_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_REGISTRY_DETAIL';
        l_dbg_msg debug_msg;
    
        l_dr_row         death_registry%ROWTYPE;
        l_drh_row        death_registry_hist%ROWTYPE;
        l_epis_diagnosis table_number;
    
    BEGIN
        l_dbg_msg := 'get death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dr_row := get_death_registry_row_f(i_death_registry => i_death_registry);
    
        l_dbg_msg := 'fill death registry history data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_drh_row.id_death_registry      := l_dr_row.id_death_registry;
        l_drh_row.id_episode             := l_dr_row.id_episode;
        l_drh_row.dt_death               := l_dr_row.dt_death;
        l_drh_row.id_prof_verified_death := l_dr_row.id_prof_verified_death;
        l_drh_row.id_sl_natural_cause    := l_dr_row.id_sl_natural_cause;
        l_drh_row.id_sl_coroner_warned   := l_dr_row.id_sl_coroner_warned;
        l_drh_row.id_sl_autopsy          := l_dr_row.id_sl_autopsy;
        l_drh_row.id_prof_death_registry := l_dr_row.id_prof_death_registry;
        l_drh_row.dt_death_registry      := l_dr_row.dt_death_registry;
        l_drh_row.id_cancel_reason       := l_dr_row.id_cancel_reason;
        l_drh_row.notes_cancel           := l_dr_row.notes_cancel;
        l_drh_row.flg_status             := l_dr_row.flg_status;
        l_drh_row.id_susp_action         := l_dr_row.id_susp_action;
        l_drh_row.death_date_format      := l_dr_row.death_date_format;
        l_drh_row.id_death_registry_hist := ts_death_registry_hist.next_key();
    
        ts_death_registry_hist.ins(rec_in => l_drh_row);
    
        set_death_history_det_h(i_death_registry      => l_dr_row.id_death_registry,
                                i_death_registry_hist => l_drh_row.id_death_registry_hist);
    
        l_dbg_msg := 'insert into death cause history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT set_death_cause_detail(i_lang                => i_lang,
                                      i_death_registry      => i_death_registry,
                                      i_death_registry_hist => l_drh_row.id_death_registry_hist,
                                      o_epis_diagnosis      => l_epis_diagnosis,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry_hist := NULL;
            RETURN FALSE;
        END IF;
    
        o_death_registry_hist := l_drh_row.id_death_registry_hist;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_death_registry_hist := NULL;
            RETURN FALSE;
        
    END set_death_registry_detail;

    /**********************************************************************************************
    * Returns a epis diagnosis id, if a given (final) diagnosis was already registered in
    * a given episode
    *
    * @param        i_episode                Episode id
    * @param        i_diagnosis              Diagnosis id
    *
    * @return       Epis diagnosis id
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        22-Jun-2010
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_episode   IN episode.id_episode%TYPE,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_epis_diagnosis%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_EPIS_DIAGNOSIS';
        l_dbg_msg debug_msg;
    
        tbl_id_ed        table_number;
        l_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
    
    BEGIN
    
        l_dbg_msg := 'get epis diagnosis id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT ed.id_epis_diagnosis
          BULK COLLECT
          INTO tbl_id_ed
          FROM epis_diagnosis ed
          JOIN diagnosis d
            ON d.id_diagnosis = ed.id_diagnosis
         WHERE ed.flg_type = pk_diagnosis.g_diag_type_d
           AND ed.flg_status NOT IN (pk_diagnosis.g_epis_status_c, pk_diagnosis.g_ed_flg_status_r)
           AND d.flg_other <> pk_alert_constant.g_yes
           AND ed.id_episode = i_episode
           AND ed.id_diagnosis = i_diagnosis;
    
        IF tbl_id_ed.count > 0
        THEN
            l_epis_diagnosis := tbl_id_ed(1);
        END IF;
    
        RETURN l_epis_diagnosis;
    
    END get_epis_diagnosis;

    /**********************************************************************************************
    * Returns a epis diagnosis description
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_epis_diagnosis         Epis diagnosis id
    *
    * @return       Epis diagnosis description
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        14-Jul-2010
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_id_diagnosis       IN NUMBER,
        i_id_alert_diagnosis IN NUMBER
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_EPIS_DIAGNOSIS_DESC';
        l_dbg_msg debug_msg;
    
        l_direct_cause_desc pk_translation.t_desc_translation;
        tbl_desc            table_varchar := table_varchar();
    
    BEGIN
        l_dbg_msg := 'get epis diagnosis description i_epis_diagnosis:' || i_epis_diagnosis;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF i_epis_diagnosis != -1
           AND i_epis_diagnosis IS NOT NULL
        THEN
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => NULL)
              BULK COLLECT
              INTO tbl_desc
              FROM epis_diagnosis ed
             INNER JOIN diagnosis d
                ON ed.id_diagnosis = d.id_diagnosis
              LEFT OUTER JOIN alert_diagnosis ad
                ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE ed.id_epis_diagnosis = i_epis_diagnosis;
        ELSE
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => NULL,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => NULL)
              BULK COLLECT
              INTO tbl_desc
              FROM diagnosis d
              LEFT OUTER JOIN alert_diagnosis ad
                ON d.id_diagnosis = ad.id_diagnosis
             WHERE ad.id_diagnosis = i_id_diagnosis
               AND ad.id_alert_diagnosis = i_id_alert_diagnosis;
        END IF;
    
        IF tbl_desc.count > 0
        THEN
            l_direct_cause_desc := tbl_desc(1);
        END IF;
    
        RETURN l_direct_cause_desc;
    
    END get_epis_diagnosis_desc;

    --

    FUNCTION set_death_cause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        i_data_val       IN table_table_varchar,
        i_component_name IN VARCHAR2 DEFAULT c_ds_death_data,
        o_epis_diagnosis OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_CAUSE';
        l_dbg_msg debug_msg;
    
        l_diagnosis       diagnosis.id_diagnosis%TYPE;
        l_diagnosisdesc   VARCHAR2(1000 CHAR);
        l_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
        l_epis_diagnosis  epis_diagnosis.id_epis_diagnosis%TYPE;
    
        l_dc_tbl ts_death_cause.death_cause_tc;
        l_nrows  PLS_INTEGER;
    
        l_flg_show       VARCHAR2(10 CHAR);
        l_flg_val_final  sys_config.value%TYPE;
        l_flg_final_type epis_diagnosis.flg_final_type%TYPE;
    
        -- dummy variable
        l_msg sys_message.desc_message%TYPE;
    
        l_rec_diag        pk_edis_types.rec_in_diagnosis;
        l_rec_epis_diag   pk_edis_types.rec_in_epis_diagnoses;
        l_diag_out_params pk_edis_types.table_out_epis_diags;
        l_add_diagnosis   sys_config.value%TYPE;
    
        l_idx NUMBER := 0;
    
    BEGIN
        l_dbg_msg := 'remove old death causes diagnosis';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_death_cause.del_by(where_clause_in => ' id_death_registry = ' || i_death_registry);
    
        -- add diagnosis to final diagnosis
        l_add_diagnosis := pk_sysconfig.get_config('DEATH_REGISTRY_ADD_DIAGNOSIS', i_prof);
        l_idx           := 0;
        FOR idx IN 1 .. c_ds_death_cause.count
        LOOP
        
            --l_idx       := idx;
            l_dbg_msg   := 'get death cause data from data structure';
            l_diagnosis := pk_dynamic_screen.get_value_number(i_component_name => c_ds_death_cause(idx),
                                                              i_data_val       => i_data_val);
        
            l_diagnosisdesc  := pk_dynamic_screen.get_diag_str(i_component_name => c_ds_death_cause(idx),
                                                               i_data_val       => i_data_val);
            l_epis_diagnosis := pk_dynamic_screen.get_id_epis_diag(i_component_name => c_ds_death_cause(idx),
                                                                   i_data_val       => i_data_val);
        
            IF l_diagnosis IS NOT NULL
            THEN
                l_idx             := l_idx + 1;
                l_alert_diagnosis := pk_dynamic_screen.get_value_number(i_component_name => c_ds_death_cause(idx),
                                                                        i_data_val       => i_data_val,
                                                                        i_alt_val        => TRUE);
                CASE i_component_name
                    WHEN c_ds_death_data THEN
                    
                        l_dbg_msg := 'get death cause epis diagnosis id';
                        IF l_epis_diagnosis IS NULL
                        THEN
                            l_epis_diagnosis := get_epis_diagnosis(i_episode => i_episode, i_diagnosis => l_diagnosis);
                        END IF;
                        IF l_epis_diagnosis IS NULL
                        THEN
                            IF l_add_diagnosis = k_yes
                            THEN
                                IF idx = c_direct_cause_rank
                                THEN
                                    l_dbg_msg       := 'get SINGLE_PRIMARY_DIAGNOSIS configuration';
                                    l_flg_val_final := nvl(pk_sysconfig.get_config(i_code_cf   => 'SINGLE_PRIMARY_DIAGNOSIS',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software),
                                                           k_yes);
                                
                                    IF l_flg_val_final = k_yes
                                    THEN
                                        l_dbg_msg := 'check if it already has a primary diagnosis';
                                        IF NOT pk_diagnosis.check_primary_diagnosis(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_episode         => i_episode,
                                                                                    i_epis_diagnosis  => NULL,
                                                                                    i_flg_final_type  => table_varchar(pk_diagnosis.g_flg_final_type_p),
                                                                                    i_diagnosis       => table_number(l_diagnosis),
                                                                                    i_sub_analysis    => table_number(NULL),
                                                                                    i_anatomical_area => table_number(NULL),
                                                                                    i_anatomical_side => table_number(NULL),
                                                                                    o_flg_show        => l_flg_show,
                                                                                    o_msg             => l_msg,
                                                                                    o_error           => o_error)
                                        THEN
                                            pk_utils.undo_changes;
                                            o_epis_diagnosis := NULL;
                                            RETURN FALSE;
                                        END IF;
                                    ELSE
                                        l_flg_show := k_no;
                                    
                                    END IF;
                                
                                    l_flg_final_type := iif(l_flg_show = k_yes,
                                                            pk_diagnosis.g_flg_final_type_s,
                                                            pk_diagnosis.g_flg_final_type_p);
                                
                                ELSE
                                    l_flg_final_type := pk_diagnosis.g_flg_final_type_s;
                                
                                END IF;
                            
                                l_dbg_msg                     := 'create diagnosis';
                                l_rec_diag.flg_status         := pk_diagnosis.g_ed_flg_status_co;
                                l_rec_diag.id_diagnosis       := l_diagnosis;
                                l_rec_diag.desc_diagnosis     := l_diagnosisdesc;
                                l_rec_diag.flg_final_type     := l_flg_final_type;
                                l_rec_diag.id_alert_diagnosis := l_alert_diagnosis;
                            
                                l_rec_epis_diag.epis_diagnosis.id_episode        := i_episode;
                                l_rec_epis_diag.epis_diagnosis.id_epis_diagnosis := l_epis_diagnosis;
                                l_rec_epis_diag.epis_diagnosis.flg_type          := pk_diagnosis.g_diag_type_d;
                                l_rec_epis_diag.epis_diagnosis.tbl_diagnosis     := pk_edis_types.table_in_diagnosis(l_rec_diag);
                            
                                IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_epis_diagnoses => l_rec_epis_diag,
                                                                       o_params         => l_diag_out_params,
                                                                       o_error          => o_error)
                                THEN
                                    pk_utils.undo_changes;
                                    o_epis_diagnosis := NULL;
                                    RETURN FALSE;
                                END IF;
                            
                                IF l_diag_out_params IS NOT NULL
                                THEN
                                    l_epis_diagnosis := l_diag_out_params(1).id_epis_diagnosis;
                                END IF;
                            
                                l_dc_tbl(l_idx).id_epis_diagnosis := l_epis_diagnosis;
                                l_dc_tbl(l_idx).id_diagnosis := -1;
                                l_dc_tbl(l_idx).id_alert_diagnosis := -1;
                                l_dc_tbl(l_idx).id_diag_inst_owner := 0;
                                l_dc_tbl(l_idx).id_adiag_inst_owner := 0;
                            
                            ELSE
                                l_dc_tbl(l_idx).id_epis_diagnosis := -1;
                                l_dc_tbl(l_idx).id_diagnosis := l_diagnosis;
                                l_dc_tbl(l_idx).id_alert_diagnosis := l_alert_diagnosis;
                                l_dc_tbl(l_idx).id_diag_inst_owner := 0;
                                l_dc_tbl(l_idx).id_adiag_inst_owner := 0;
                            END IF;
                        ELSE
                            l_dc_tbl(l_idx).id_epis_diagnosis := l_epis_diagnosis;
                            l_dc_tbl(l_idx).id_diagnosis := -1;
                            l_dc_tbl(l_idx).id_alert_diagnosis := -1;
                            l_dc_tbl(l_idx).id_diag_inst_owner := 0;
                            l_dc_tbl(l_idx).id_adiag_inst_owner := 0;
                        END IF;
                    
                    WHEN c_ds_death_data_fetal THEN
                        IF l_epis_diagnosis IS NULL
                        THEN
                            l_epis_diagnosis := get_epis_diagnosis(i_episode => i_episode, i_diagnosis => l_diagnosis);
                        END IF;
                        l_dc_tbl(l_idx).id_epis_diagnosis := nvl(l_epis_diagnosis, -1);
                        l_dc_tbl(l_idx).id_diagnosis := l_diagnosis;
                        l_dc_tbl(l_idx).id_alert_diagnosis := l_alert_diagnosis;
                        l_dc_tbl(l_idx).id_diag_inst_owner := 0;
                        l_dc_tbl(l_idx).id_adiag_inst_owner := 0;
                    ELSE
                        l_dc_tbl(l_idx).id_epis_diagnosis := -1;
                        l_dc_tbl(l_idx).id_diagnosis := l_diagnosis;
                        l_dc_tbl(l_idx).id_alert_diagnosis := l_alert_diagnosis;
                        l_dc_tbl(l_idx).id_diag_inst_owner := 0;
                        l_dc_tbl(l_idx).id_adiag_inst_owner := 0;
                    
                END CASE;
            
                l_dc_tbl(l_idx).id_death_registry := i_death_registry;
                l_dc_tbl(l_idx).death_cause_rank := idx;
                l_dc_tbl(l_idx).id_death_cause := get_death_cause_nextval();
            
            END IF;
        
        END LOOP;
    
        l_dbg_msg := 'insert into death cause the direct causes diagnosis';
        ts_death_cause.ins(rows_in => l_dc_tbl);
    
        l_dbg_msg := 'fill output collection with patient episode diagnosis ids';
        l_nrows   := l_dc_tbl.count();
        IF l_nrows < 1
        THEN
            o_epis_diagnosis := NULL;
        
        ELSE
            o_epis_diagnosis := table_number();
            o_epis_diagnosis.extend(l_nrows);
        
            -----
            DECLARE
                l_count NUMBER := 1;
            BEGIN
                l_idx := l_dc_tbl.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    o_epis_diagnosis(l_count) := l_dc_tbl(l_idx).id_epis_diagnosis;
                    l_idx := l_dc_tbl.next(l_idx);
                    l_count := l_count + 1;
                END LOOP;
            END;
        
            -----
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_epis_diagnosis := NULL;
            RETURN FALSE;
        
    END set_death_cause;

    --
    FUNCTION get_deceased_place
    (
        i_lang              IN NUMBER,
        i_id_death_registry IN NUMBER
    ) RETURN VARCHAR2 IS
        k_id_ds_component_name CONSTANT VARCHAR2(0100 CHAR) := 'DS_PLACE_OF_DEATH';
        tbl_list      table_number;
        tbl_code      table_varchar;
        l_id_sys_list NUMBER;
        l_return      VARCHAR2(4000);
        l_code        VARCHAR2(0200 CHAR);
    BEGIN
    
        SELECT value_n
          BULK COLLECT
          INTO tbl_list
          FROM death_registry_det dr
          JOIN ds_component dc
            ON dc.id_ds_component = dr.id_ds_component
         WHERE dc.internal_name = k_id_ds_component_name
           AND dr.id_death_registry = i_id_death_registry;
    
        IF tbl_list.count > 0
        THEN
        
            l_id_sys_list := tbl_list(1);
        
            SELECT code_sys_list
              BULK COLLECT
              INTO tbl_code
              FROM sys_list
             WHERE id_sys_list = l_id_sys_list;
        
            IF tbl_code.count > 0
            THEN
                l_code   := tbl_code(1);
                l_return := pk_translation.get_translation(i_lang, l_code);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_deceased_place;

    --********************************************************************
    FUNCTION set_death_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN death_registry.dt_death_registry%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_data_val       IN table_table_varchar,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_DATA';
        l_ret     BOOLEAN;
        l_dbg_msg debug_msg;
    
        l_dr_tbl              ts_death_registry.death_registry_tc;
        l_epis_diagnosis      table_number;
        l_death_registry_hist death_registry_hist.id_death_registry_hist%TYPE;
        l_dir_cause_desc      pk_translation.t_desc_translation;
        l_err_msg             VARCHAR2(1000 CHAR);
        l_id_epis_diagnosis   death_cause.id_epis_diagnosis%TYPE;
        l_id_diagnosis        death_cause.id_diagnosis%TYPE;
        l_id_alert_diagnosis  death_cause.id_alert_diagnosis%TYPE;
        l_deceased_place      VARCHAR2(0100 CHAR);
    
        CURSOR c_death_diagnosis(i_id_death_registry IN death_registry.id_death_registry%TYPE) IS
            SELECT id_epis_diagnosis, id_diagnosis, id_alert_diagnosis
              FROM death_cause dc
             WHERE dc.id_death_registry = i_id_death_registry
               AND dc.death_cause_rank = c_direct_cause_rank;
    BEGIN
        l_dbg_msg := 'get the active death registry for the patient, if he has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dr_tbl(1) := get_death_registry_row(i_patient => i_patient, i_status => pk_alert_constant.g_active);
    
        l_dbg_msg := 'fill professional and date information';
        l_dr_tbl(1).id_prof_death_registry := i_prof.id;
        l_dr_tbl(1).dt_death_registry := i_date;
    
        l_dbg_msg := 'get death registry data from data structure';
        l_dr_tbl(1).death_date_format := pk_dynamic_screen.get_dt_format(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_component_name => c_ds_dt_death,
                                                                         i_data_val       => i_data_val);
    
        l_dr_tbl(1).dt_death := pk_dynamic_screen.get_value_tstz(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_component_name => c_ds_dt_death,
                                                                 i_data_val       => i_data_val,
                                                                 i_orig_val       => l_dr_tbl(1).dt_death,
                                                                 i_flg_partial_dt => l_dr_tbl(1).death_date_format);
    
        l_dr_tbl(1).id_prof_verified_death := pk_dynamic_screen.get_value_number(i_component_name => c_ds_prof_verified_death,
                                                                                 i_data_val       => i_data_val,
                                                                                 i_orig_val       => l_dr_tbl(1).id_prof_verified_death);
        l_dr_tbl(1).id_sl_natural_cause := pk_dynamic_screen.get_value_number(i_component_name => c_ds_natural_cause,
                                                                              i_data_val       => i_data_val,
                                                                              i_orig_val       => l_dr_tbl(1).id_sl_natural_cause);
        l_dr_tbl(1).id_sl_coroner_warned := pk_dynamic_screen.get_value_number(i_component_name => c_ds_coroner_warned,
                                                                               i_data_val       => i_data_val,
                                                                               i_orig_val       => l_dr_tbl(1).id_sl_coroner_warned);
        l_dr_tbl(1).id_sl_autopsy := pk_dynamic_screen.get_value_number(i_component_name => c_ds_autopsy,
                                                                        i_data_val       => i_data_val,
                                                                        i_orig_val       => l_dr_tbl(1).id_sl_autopsy);
    
        IF l_dr_tbl(1).id_death_registry IS NULL
        THEN
            l_dbg_msg := 'fill episode, status and death registry next key';
            l_dr_tbl(1).id_episode := i_episode;
            l_dr_tbl(1).flg_status := pk_alert_constant.g_active;
            l_dr_tbl(1).id_death_registry := ts_death_registry.next_key;
            l_dr_tbl(1).flg_type := k_flg_dr_type_patient;
        
            l_dbg_msg := 'insert values into death registry';
            ts_death_registry.ins(rows_in => l_dr_tbl);
        
        ELSE
            l_dbg_msg := 'update death registry values';
            ts_death_registry.upd(col_in => l_dr_tbl, ignore_if_null_in => FALSE);
        
        END IF;
    
        set_dyn_data(i_lang              => i_lang,
                     i_prof              => i_prof,
                     i_id_death_registry => l_dr_tbl(1).id_death_registry,
                     i_section           => c_ds_death_data,
                     i_data_val          => i_data_val);
    
        l_dbg_msg := 'set death causes';
        IF NOT set_death_cause(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_episode        => i_episode,
                               i_death_registry => l_dr_tbl(1).id_death_registry,
                               i_data_val       => i_data_val,
                               o_epis_diagnosis => l_epis_diagnosis,
                               o_error          => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'insert into death registry history';
        IF NOT set_death_registry_detail(i_lang                => i_lang,
                                         i_death_registry      => l_dr_tbl(1).id_death_registry,
                                         o_death_registry_hist => l_death_registry_hist,
                                         o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN c_death_diagnosis(l_dr_tbl(1).id_death_registry);
        FETCH c_death_diagnosis
            INTO l_id_epis_diagnosis, l_id_diagnosis, l_id_alert_diagnosis;
        CLOSE c_death_diagnosis;
    
        l_dir_cause_desc := get_epis_diagnosis_desc(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_epis_diagnosis     => l_id_epis_diagnosis,
                                                    i_id_diagnosis       => l_id_diagnosis,
                                                    i_id_alert_diagnosis => l_id_alert_diagnosis);
    
        l_deceased_place := get_deceased_place(i_lang, l_dr_tbl(1).id_death_registry);
    
        l_dbg_msg := 'set death details';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_adt.set_patient_death_details(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_patient         => i_patient,
                                                i_dt_deceased     => l_dr_tbl(1).dt_death,
                                                i_deceased_motive => l_dir_cause_desc,
                                                i_deceased_place  => l_deceased_place,
                                                o_error           => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'call to pk_patient_tracking.set_patient_death_status';
        IF NOT pk_patient_tracking.set_patient_death_status(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_episode     => i_episode,
                                                            i_dt_deceased => l_dr_tbl(1).dt_death,
                                                            o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'call set first obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        END IF;
    
        o_death_registry := l_dr_tbl(1).id_death_registry;
    
        l_ret := check_anomalies(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_patient => i_patient,
                                 i_id_dr   => l_dr_tbl(1).id_death_registry);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN err_wrong_date_norm THEN
            l_err_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'NOM24_WRONG_FOLIO_FORMAT');
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => l_err_msg,
                                              i_message     => NULL,
                                              i_owner       => c_package_owner,
                                              i_package     => c_package_name,
                                              i_action_type => 'U',
                                              i_function    => c_function_name,
                                              o_error       => o_error);
        
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
    END set_death_data;

    -- **********************************************************
    FUNCTION set_death_data_fetal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN death_registry.dt_death_registry%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_data_val       IN table_table_varchar,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_DATA_FETAL';
        l_dbg_msg debug_msg;
    
        l_err_msg             VARCHAR2(1000 CHAR);
        l_dr_tbl              ts_death_registry.death_registry_tc;
        l_epis_diagnosis      table_number := table_number();
        l_death_registry_hist death_registry_hist.id_death_registry_hist%TYPE;
        l_ret                 BOOLEAN;
    
        err_custom_01 EXCEPTION;
    
    BEGIN
        l_dbg_msg := 'get the active death registry for the patient, if he has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dr_tbl(1) := get_death_registry_row_f(i_death_registry => i_death_registry);
    
        l_dbg_msg := 'fill professional and date information';
        l_dr_tbl(1).id_prof_death_registry := i_prof.id;
        l_dr_tbl(1).dt_death_registry := i_date;
    
        IF l_dr_tbl(1).id_death_registry IS NULL
        THEN
            l_dbg_msg := 'fill episode, status and death registry next key';
            l_dr_tbl(1).id_episode := i_episode;
            l_dr_tbl(1).flg_status := pk_alert_constant.g_active;
            l_dr_tbl(1).id_death_registry := ts_death_registry.next_key;
            l_dr_tbl(1).flg_type := k_flg_dr_type_fetus;
            ------------------------------------------------------------------
            l_dr_tbl(1).death_date_format := pk_dynamic_screen.get_dt_format(i_lang           => i_lang,
                                                                             i_prof           => i_prof,
                                                                             i_component_name => c_ds_dt_death,
                                                                             i_data_val       => i_data_val);
        
            l_dr_tbl(1).dt_death := pk_dynamic_screen.get_value_tstz(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_component_name => c_ds_dt_death,
                                                                     i_data_val       => i_data_val,
                                                                     i_orig_val       => l_dr_tbl(1).dt_death,
                                                                     i_flg_partial_dt => l_dr_tbl(1).death_date_format);
            ------------------------------------------------------------------------------------------
            l_dbg_msg := 'insert values into death registry';
            ts_death_registry.ins(rows_in => l_dr_tbl);
        
        ELSE
            l_dbg_msg := 'update death registry values';
            ts_death_registry.upd(col_in => l_dr_tbl, ignore_if_null_in => FALSE);
        
        END IF;
    
        --l_count := i_data_val.count;
        set_dyn_data(i_lang              => i_lang,
                     i_prof              => i_prof,
                     i_id_death_registry => l_dr_tbl(1).id_death_registry,
                     i_section           => c_ds_death_data_fetal,
                     i_data_val          => i_data_val);
    
        l_dbg_msg := 'set death causes';
        IF NOT set_death_cause(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_episode        => i_episode,
                               i_death_registry => l_dr_tbl(1).id_death_registry,
                               i_data_val       => i_data_val,
                               i_component_name => c_ds_death_data_fetal,
                               o_epis_diagnosis => l_epis_diagnosis,
                               o_error          => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'insert into death registry history';
        IF NOT set_death_registry_detail(i_lang                => i_lang,
                                         i_death_registry      => l_dr_tbl(1).id_death_registry,
                                         o_death_registry_hist => l_death_registry_hist,
                                         o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'call set first obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        o_death_registry := l_dr_tbl(1).id_death_registry;
    
        l_ret := check_fetal_anomalies(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_id_dr   => l_dr_tbl(1).id_death_registry);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN err_custom_01 THEN
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
        WHEN err_wrong_date_norm THEN
            l_err_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'NOM24_WRONG_FOLIO_FORMAT');
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => l_err_msg,
                                              i_message     => NULL,
                                              i_owner       => c_package_owner,
                                              i_package     => c_package_name,
                                              i_action_type => 'U',
                                              i_function    => c_function_name,
                                              o_error       => o_error);
        
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
    END set_death_data_fetal;

    /**********************************************************************************************
    * Cancel death data
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_date                   Cancel date
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_death_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN death_registry.dt_death_registry%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN death_registry.notes_cancel%TYPE,
        o_susp_action   OUT death_registry.id_susp_action%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_DEATH_DATA';
        l_dbg_msg             debug_msg;
        l_dr_tbl              ts_death_registry.death_registry_tc;
        l_death_registry_hist death_registry_hist.id_death_registry_hist%TYPE;
        err_custom_01 EXCEPTION;
    BEGIN
    
        l_dbg_msg := 'get patient death data, if exists';
        l_dr_tbl(1) := get_death_registry_row(i_patient => i_patient, i_status => pk_alert_constant.g_active);
        IF l_dr_tbl(1).id_death_registry IS NULL
        THEN
            o_susp_action := NULL;
            RETURN TRUE;
        END IF;
    
        l_dbg_msg := 'set death registry cancel information';
        l_dr_tbl(1).flg_status := pk_alert_constant.g_cancelled;
        l_dr_tbl(1).id_prof_death_registry := i_prof.id;
        l_dr_tbl(1).dt_death_registry := i_date;
        l_dr_tbl(1).id_cancel_reason := i_cancel_reason;
        l_dr_tbl(1).notes_cancel := i_notes_cancel;
    
        l_dbg_msg := 'update death registry';
        ts_death_registry.upd(col_in => l_dr_tbl, ignore_if_null_in => FALSE);
    
        o_susp_action := l_dr_tbl(1).id_susp_action;
    
        l_dbg_msg := 'insert into death registry history';
        IF NOT set_death_registry_detail(i_lang                => i_lang,
                                         i_death_registry      => l_dr_tbl(1).id_death_registry,
                                         o_death_registry_hist => l_death_registry_hist,
                                         o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'set death details';
        IF NOT pk_adt.set_patient_death_details(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_patient         => i_patient,
                                                i_dt_deceased     => NULL,
                                                i_deceased_motive => NULL,
                                                o_error           => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'call to pk_patient_tracking.reset_care_stage_death';
        IF NOT pk_patient_tracking.reset_care_stage_death(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_error   => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'call set first obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_custom_01 THEN
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
    END cancel_death_data;

    --
    FUNCTION cancel_death_data_fetal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN death_registry.dt_death_registry%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel   IN death_registry.notes_cancel%TYPE,
        o_susp_action    OUT death_registry.id_susp_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_DEATH_DATA_FETAL';
        l_dbg_msg             debug_msg;
        l_dr_tbl              ts_death_registry.death_registry_tc;
        l_death_registry_hist death_registry_hist.id_death_registry_hist%TYPE;
    
        err_custom_01 EXCEPTION;
    BEGIN
        l_dbg_msg := 'get patient death data, if exists';
        l_dr_tbl(1) := get_death_registry_row_f(i_death_registry => i_death_registry);
        IF l_dr_tbl(1).id_death_registry IS NULL
        THEN
            o_susp_action := NULL;
            RETURN TRUE;
        END IF;
    
        l_dbg_msg := 'set death registry cancel information';
        l_dr_tbl(1).flg_status := pk_alert_constant.g_cancelled;
        l_dr_tbl(1).id_prof_death_registry := i_prof.id;
        l_dr_tbl(1).dt_death_registry := i_date;
        l_dr_tbl(1).id_cancel_reason := i_cancel_reason;
        l_dr_tbl(1).notes_cancel := i_notes_cancel;
    
        l_dbg_msg := 'update death registry';
        ts_death_registry.upd(col_in => l_dr_tbl, ignore_if_null_in => FALSE);
    
        o_susp_action := l_dr_tbl(1).id_susp_action;
    
        l_dbg_msg := 'insert into death registry history';
        IF NOT set_death_registry_detail(i_lang                => i_lang,
                                         i_death_registry      => l_dr_tbl(1).id_death_registry,
                                         o_death_registry_hist => l_death_registry_hist,
                                         o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        l_dbg_msg := 'call set first obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_date,
                                      i_dt_first_obs        => i_date,
                                      o_error               => o_error)
        THEN
            RAISE err_custom_01;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_custom_01 THEN
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
    END cancel_death_data_fetal;

    FUNCTION get_dr_hist_prof_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE DEFAULT NULL,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_HIST_PROF_DATA';
        l_dbg_msg debug_msg;
    
        l_created   sys_message.desc_message%TYPE;
        l_edited    sys_message.desc_message%TYPE;
        l_cancelled sys_message.desc_message%TYPE;
    
    BEGIN
        l_dbg_msg   := 'get detail status messages';
        l_created   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M001');
        l_edited    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M002');
        l_cancelled := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DETAIL_COMMON_M003');
    
        l_dbg_msg := 'get info about the professional that made each registry';
        OPEN o_prof_data FOR
            SELECT pk_date_utils.date_char_tsz(i_lang, drh.dt_death_registry, i_prof.institution, i_prof.software) AS registry_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, drh.id_prof_death_registry) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    drh.id_prof_death_registry,
                                                    drh.dt_death_registry,
                                                    drh.id_episode) AS prof_speciality,
                   drh.flg_status,
                   decode(drh.flg_status,
                          pk_alert_constant.g_active,
                          decode(drh.dt_death_registry,
                                 (SELECT MIN(m.dt_death_registry)
                                    FROM death_registry_hist m
                                   WHERE m.id_death_registry = drh.id_death_registry
                                     AND m.flg_status = drh.flg_status),
                                 l_created,
                                 l_edited),
                          l_cancelled) AS desc_status,
                   drh.id_death_registry_hist AS id_hist,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, drh.id_cancel_reason) AS cancel_reason_desc,
                   drh.notes_cancel
              FROM death_registry_hist drh
             INNER JOIN episode e
                ON drh.id_episode = e.id_episode
              JOIN death_registry dr
                ON dr.id_death_registry = drh.id_death_registry
             WHERE e.id_patient = i_patient
               AND (drh.id_death_registry = i_death_registry OR
                   (i_death_registry IS NULL AND dr.flg_type = k_flg_dr_type_patient))
             ORDER BY drh.dt_death_registry DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_dr_hist_prof_data;

    --

    FUNCTION get_dr_hist_wft
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_dr_wf    OUT table_table_varchar,
        o_sys_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_HIST_WFT';
        l_dbg_msg debug_msg;
    
        CURSOR c_dr_wf(i_pat IN patient.id_patient%TYPE) IS
            SELECT drh.id_death_registry_hist, drh.flg_status, drh.id_susp_action
              FROM death_registry_hist drh
             INNER JOIN episode e
                ON drh.id_episode = e.id_episode
             WHERE e.id_patient = i_pat
               AND (drh.dt_death_registry = (SELECT MIN(m.dt_death_registry)
                                               FROM death_registry_hist m
                                              WHERE m.id_death_registry = drh.id_death_registry
                                                AND m.flg_status = drh.flg_status) OR
                   drh.flg_status = pk_alert_constant.g_cancelled)
               AND id_susp_action IS NOT NULL
             ORDER BY drh.dt_death_registry DESC;
    
        l_susp_tasks_list  pk_types.cursor_type;
        l_nsusp_tasks_list pk_types.cursor_type;
        l_reac_tasks_list  pk_types.cursor_type;
        l_nreac_tasks_list pk_types.cursor_type;
    
        l_dr_wf_row table_varchar;
    
    BEGIN
        o_dr_wf := table_table_varchar();
    
        <<lup_thru_drh>>
        FOR cur IN c_dr_wf(i_pat => i_patient)
        LOOP
            l_dbg_msg := 'get all tasks associated to the suspension action';
            IF NOT pk_suspended_tasks.get_action_tasks_all(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_susp_action   => cur.id_susp_action,
                                                           o_sys_list         => o_sys_list,
                                                           o_susp_tasks_list  => l_susp_tasks_list,
                                                           o_nsusp_tasks_list => l_nsusp_tasks_list,
                                                           o_reac_tasks_list  => l_reac_tasks_list,
                                                           o_nreac_tasks_list => l_nreac_tasks_list,
                                                           o_error            => o_error)
            THEN
                o_dr_wf := NULL;
                pk_types.open_my_cursor(i_cursor => o_sys_list);
                RETURN FALSE;
            END IF;
        
            IF cur.flg_status = pk_alert_constant.g_active
            THEN
            
                l_dbg_msg := 'fill data structure with suspended tasks';
                LOOP
                    l_dr_wf_row := table_varchar();
                    l_dr_wf_row.extend(8);
                    l_dr_wf_row(1) := cur.id_death_registry_hist;
                    l_dr_wf_row(2) := pk_suspended_tasks.c_wfstatus_susp;
                    FETCH l_susp_tasks_list
                        INTO l_dr_wf_row(3),
                             l_dr_wf_row(4),
                             l_dr_wf_row(5),
                             l_dr_wf_row(6),
                             l_dr_wf_row(7),
                             l_dr_wf_row(8);
                    EXIT WHEN l_susp_tasks_list%NOTFOUND;
                    o_dr_wf.extend();
                    o_dr_wf(o_dr_wf.last()) := l_dr_wf_row;
                END LOOP;
            
                l_dbg_msg := 'fill data structure with not suspended tasks';
                LOOP
                    l_dr_wf_row := table_varchar();
                    l_dr_wf_row.extend(8);
                    l_dr_wf_row(1) := cur.id_death_registry_hist;
                    l_dr_wf_row(2) := pk_suspended_tasks.c_wfstatus_nsusp;
                    FETCH l_nsusp_tasks_list
                        INTO l_dr_wf_row(3),
                             l_dr_wf_row(4),
                             l_dr_wf_row(5),
                             l_dr_wf_row(6),
                             l_dr_wf_row(7),
                             l_dr_wf_row(8);
                    EXIT WHEN l_nsusp_tasks_list%NOTFOUND;
                    o_dr_wf.extend();
                    o_dr_wf(o_dr_wf.last()) := l_dr_wf_row;
                END LOOP;
            
            ELSIF cur.flg_status = pk_alert_constant.g_cancelled
            THEN
            
                l_dbg_msg := 'fill data structure with reactivated tasks';
                LOOP
                    l_dr_wf_row := table_varchar();
                    l_dr_wf_row.extend(8);
                    l_dr_wf_row(1) := cur.id_death_registry_hist;
                    l_dr_wf_row(2) := pk_suspended_tasks.c_wfstatus_reac;
                    FETCH l_reac_tasks_list
                        INTO l_dr_wf_row(3),
                             l_dr_wf_row(4),
                             l_dr_wf_row(5),
                             l_dr_wf_row(6),
                             l_dr_wf_row(7),
                             l_dr_wf_row(8);
                    EXIT WHEN l_reac_tasks_list%NOTFOUND;
                    o_dr_wf.extend();
                    o_dr_wf(o_dr_wf.last()) := l_dr_wf_row;
                END LOOP;
            
                l_dbg_msg := 'fill data structure with not reactivated tasks';
                LOOP
                    l_dr_wf_row := table_varchar();
                    l_dr_wf_row.extend(8);
                    l_dr_wf_row(1) := cur.id_death_registry_hist;
                    l_dr_wf_row(2) := pk_suspended_tasks.c_wfstatus_nreac;
                    FETCH l_nreac_tasks_list
                        INTO l_dr_wf_row(3),
                             l_dr_wf_row(4),
                             l_dr_wf_row(5),
                             l_dr_wf_row(6),
                             l_dr_wf_row(7),
                             l_dr_wf_row(8);
                    EXIT WHEN l_nreac_tasks_list%NOTFOUND;
                    o_dr_wf.extend();
                    o_dr_wf(o_dr_wf.last()) := l_dr_wf_row;
                END LOOP;
            
            END IF;
        
            l_dbg_msg := 'close tasks cursors';
            CLOSE l_susp_tasks_list;
            CLOSE l_nsusp_tasks_list;
            CLOSE l_reac_tasks_list;
            CLOSE l_nreac_tasks_list;
        
        END LOOP lup_thru_drh;
    
        IF o_dr_wf.count() < 1
        THEN
            o_dr_wf := NULL;
            pk_types.open_my_cursor(i_cursor => o_sys_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_dr_wf := NULL;
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
    END get_dr_hist_wft;

    --

    FUNCTION get_death_cause_hist(i_death_registry_hist IN death_registry_hist.id_death_registry%TYPE)
        RETURN ts_death_cause_hist.death_cause_hist_tc IS
        l_dch_tbl ts_death_cause_hist.death_cause_hist_tc;
    BEGIN
        SELECT dch.*
          BULK COLLECT
          INTO l_dch_tbl
          FROM death_cause_hist dch
         WHERE dch.id_death_registry_hist = i_death_registry_hist;
    
        RETURN l_dch_tbl;
    
    END get_death_cause_hist;

    -- ***********************
    FUNCTION get_death_cause_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_component_name      IN VARCHAR2 DEFAULT c_ds_death_data,
        i_death_registry_hist IN death_registry_hist.id_death_registry%TYPE,
        o_data_val            IN OUT NOCOPY table_table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_CAUSE_DETAIL';
    
        l_dbg_msg debug_msg;
        l_dch_tbl ts_death_cause_hist.death_cause_hist_tc;
    
    BEGIN
        l_dbg_msg := 'get death causes history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dch_tbl := get_death_cause_hist(i_death_registry_hist => i_death_registry_hist);
    
        l_dbg_msg := 'fill structure with death causes history i_death_registry_hist:' || i_death_registry_hist;
        <<lup_thru_dch>>
        FOR idx IN 1 .. l_dch_tbl.count()
        LOOP
        
            CASE i_component_name
                WHEN c_ds_death_data THEN
                    IF l_dch_tbl(idx).id_epis_diagnosis IS NOT NULL
                        AND l_dch_tbl(idx).id_epis_diagnosis <> -1
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_epis_diagn(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_data_val => o_data_val,
                                                                             i_name     => c_ds_death_cause(l_dch_tbl(idx).death_cause_rank),
                                                                             i_value    => l_dch_tbl(idx).id_epis_diagnosis,
                                                                             i_hist     => i_death_registry_hist);
                    ELSE
                        o_data_val := pk_dynamic_screen.add_value_diagn(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_data_val   => o_data_val,
                                                                        i_name       => c_ds_death_cause(l_dch_tbl(idx).death_cause_rank),
                                                                        i_value      => NULL,
                                                                        i_value_hist => l_dch_tbl(idx).id_death_cause_hist,
                                                                        i_hist       => i_death_registry_hist);
                    END IF;
                ELSE
                    --WHEN c_ds_death_data_fetal THEN
                    IF l_dch_tbl(idx).id_epis_diagnosis <> -1
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_epis_diagn(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_data_val => o_data_val,
                                                                             i_name     => c_ds_death_cause(l_dch_tbl(idx).death_cause_rank),
                                                                             i_value    => l_dch_tbl(idx).id_epis_diagnosis,
                                                                             i_hist     => i_death_registry_hist);
                    
                    ELSE
                        o_data_val := pk_dynamic_screen.add_value_diagn(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_data_val   => o_data_val,
                                                                        i_name       => c_ds_death_cause(l_dch_tbl(idx).death_cause_rank),
                                                                        i_value      => l_dch_tbl(idx).id_death_cause,
                                                                        i_value_hist => NULL,
                                                                        i_hist       => i_death_registry_hist);
                    END IF;
            END CASE;
        
        END LOOP lup_thru_dch;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_death_cause_detail;

    --

    FUNCTION get_death_data_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DEATH_DATA_DETAIL';
        l_dbg_msg debug_msg;
    
        l_drh_tbl ts_death_registry_hist.death_registry_hist_tc;
    
    BEGIN
        l_dbg_msg := 'get death registry history';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT drh.*
          BULK COLLECT
          INTO l_drh_tbl
          FROM death_registry_hist drh
         INNER JOIN episode e
            ON drh.id_episode = e.id_episode
          JOIN death_registry dr
            ON drh.id_death_registry = dr.id_death_registry
         WHERE e.id_patient = i_patient
              --     AND drh.id_death_registry = i_death_registry
           AND dr.flg_type = k_flg_dr_type_patient
         ORDER BY drh.dt_death_registry DESC;
    
        l_dbg_msg := 'build structure with death data';
    
        <<lup_thru_drh>>
        FOR idx IN 1 .. l_drh_tbl.count()
        LOOP
            o_data_val := pk_dynamic_screen.add_value_tstz(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => c_ds_dt_death,
                                                           i_value    => l_drh_tbl(idx).dt_death,
                                                           i_hist     => l_drh_tbl(idx).id_death_registry_hist);
        
            o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => c_ds_prof_verified_death,
                                                           i_value    => l_drh_tbl(idx).id_prof_verified_death,
                                                           i_hist     => l_drh_tbl(idx).id_death_registry_hist);
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_natural_cause,
                                                         i_value    => l_drh_tbl(idx).id_sl_natural_cause,
                                                         i_hist     => l_drh_tbl(idx).id_death_registry_hist);
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_coroner_warned,
                                                         i_value    => l_drh_tbl(idx).id_sl_coroner_warned,
                                                         i_hist     => l_drh_tbl(idx).id_death_registry_hist);
        
            l_dbg_msg := 'get death causes history';
            IF NOT get_death_cause_detail(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_component_name      => c_ds_death_data,
                                          i_death_registry_hist => l_drh_tbl(idx).id_death_registry_hist,
                                          o_data_val            => o_data_val,
                                          o_error               => o_error)
            THEN
                o_data_val := NULL;
                o_dr_wf    := NULL;
                pk_types.open_my_cursor(i_cursor => o_prof_data);
                pk_types.open_my_cursor(i_cursor => o_sys_list);
                RETURN FALSE;
            END IF;
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => c_ds_autopsy,
                                                         i_value    => l_drh_tbl(idx).id_sl_autopsy,
                                                         i_hist     => l_drh_tbl(idx).id_death_registry_hist);
        
            o_data_val := get_dyn_data_detail(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_death_registry_hist => l_drh_tbl(idx).id_death_registry_hist,
                                              i_data_val            => o_data_val);
        
        END LOOP lup_thru_drh;
    
        l_dbg_msg := 'get info about the professional that made the registries';
        IF NOT get_dr_hist_prof_data(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_patient => i_patient,
                                     -- i_death_registry => i_death_registry,
                                     o_prof_data => o_prof_data,
                                     o_error     => o_error)
        THEN
            o_data_val := NULL;
            o_dr_wf    := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get info about workflow tasks suspended or reactivated';
        IF NOT get_dr_hist_wft(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_patient  => i_patient,
                               o_dr_wf    => o_dr_wf,
                               o_sys_list => o_sys_list,
                               o_error    => o_error)
        THEN
            o_data_val := NULL;
            o_dr_wf    := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            o_dr_wf    := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            RETURN FALSE;
        
    END get_death_data_detail;

    /**********************************************************************************************
    * Returns de detail information  for fetal detah for history
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_death_registry         ID death registry
    * @param        o_data_val               Components values
    * @param        o_prof_data              Professional who has made the changes (name,
    *                                        speciality and date of changes)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Elisabete Bugalho
    * @version      2.7.1.0
    * @since        27/03/2017
    **********************************************************************************************/
    FUNCTION get_death_data_fetal_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT obj_name := 'GET_DEATH_DATA_FETAL';
        l_dbg_msg debug_msg;
    
        l_dr_row death_registry%ROWTYPE;
    
        -- get all editions od a fetal death
        CURSOR dr_fetal_c(i_death_fetal IN death_registry.id_death_registry%TYPE) IS
            SELECT drh.*
              FROM death_registry_hist drh
             WHERE drh.id_death_registry = i_death_fetal;
    
    BEGIN
        l_dbg_msg := 'get patient death data, if exists';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => k_function_name);
    
        <<lup_thru_dr>>
        FOR l_dr_row IN dr_fetal_c(i_death_fetal => i_death_registry)
        LOOP
        
            pk_dynamic_screen.set_data_key(l_dr_row.id_death_registry);
        
            l_dbg_msg  := 'build structure with death data';
            o_data_val := pk_dynamic_screen.add_value_tstz(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => c_ds_dt_death,
                                                           i_value    => l_dr_row.dt_death,
                                                           i_hist     => l_dr_row.id_death_registry_hist);
        
            o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => c_ds_prof_verified_death,
                                                           i_value    => l_dr_row.id_prof_verified_death,
                                                           i_hist     => l_dr_row.id_death_registry_hist);
        
            -- get the information for dynamic fields
            o_data_val := get_dyn_data_detail(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_death_registry_hist => l_dr_row.id_death_registry_hist,
                                              i_data_val            => o_data_val);
        
            -- get the causes for death
            IF NOT get_death_cause_detail(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_component_name      => c_ds_death_data_fetal,
                                          i_death_registry_hist => l_dr_row.id_death_registry_hist,
                                          o_data_val            => o_data_val,
                                          o_error               => o_error)
            THEN
                o_data_val := NULL;
                pk_types.open_my_cursor(i_cursor => o_prof_data);
                RETURN FALSE;
            END IF;
        
        END LOOP lup_thru_dr;
    
        l_dbg_msg := 'get info about the professional that made the registry';
        IF NOT get_dr_hist_prof_data(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_patient        => i_patient,
                                     i_death_registry => i_death_registry,
                                     o_prof_data      => o_prof_data,
                                     o_error          => o_error)
        THEN
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_death_data_fetal_detail;

    /**********************************************************************************************
    * Returns patient deceased date
    *
    * @param        i_patient                Patient id
    *
    * @return       Deceased date
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        14-Jul-2010
    **********************************************************************************************/
    FUNCTION get_patient_dt_deceased(i_patient IN patient.id_patient%TYPE) RETURN patient.dt_deceased%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_PATIENT_DT_DECEASED';
        l_dbg_msg debug_msg;
    
        l_death_date patient.dt_deceased%TYPE;
    
    BEGIN
        l_dbg_msg := 'get patient deceased date';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT p.dt_deceased
          INTO l_death_date
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN l_death_date;
    
    END get_patient_dt_deceased;

    --
    -- PUBLIC FUNCTIONS
    --

    /**********************************************************************************************
    * Returns the patient death registry id
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        o_death_registry         Death registry id (null if patient has none)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_DEATH_REGISTRY';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get (most recent) patient death registry id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        -- o_death_registry := get_death_registry_row(i_patient => i_patient).id_death_registry;
        o_death_registry := check_death_registry(i_patient => i_patient);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_death_registry := NULL;
            RETURN FALSE;
        
    END get_pat_death_registry;

    /**********************************************************************************************
    * Returns death registry summary
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        o_section                Section components structure
    * @param        o_data_val               Components values
    * @param        o_prof_data              Professional who has made the changes (name,
    *                                        speciality and date of changes)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_dr_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SUMMARY';
        l_dbg_msg debug_msg;
    
        l_ret    BOOLEAN;
        l_filter VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_dbg_msg := 'get patient death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF i_component_name = c_ds_death_data_fetal
        THEN
            l_filter := pk_alert_constant.g_yes;
        END IF;
    
        CASE i_component_name
            WHEN c_ds_death_data THEN
                l_ret := get_death_data(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_patient   => i_patient,
                                        o_data_val  => o_data_val,
                                        o_prof_data => o_prof_data,
                                        o_error     => o_error);
            
            WHEN c_ds_death_data_fetal THEN
                l_ret := get_death_data_fetal(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_patient        => i_patient,
                                              i_death_registry => NULL,
                                              o_data_val       => o_data_val,
                                              o_prof_data      => o_prof_data,
                                              o_error          => o_error);
            
            WHEN c_ds_organ_donor THEN
                l_ret := pk_organ_donor.get_organ_donor_data(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_patient   => i_patient,
                                                             o_data_val  => o_data_val,
                                                             o_prof_data => o_prof_data,
                                                             o_error     => o_error);
            
            ELSE
                l_dbg_msg := 'wrong component name';
                pk_alertlog.log_error(text            => l_dbg_msg,
                                      object_name     => c_package_name,
                                      sub_object_name => c_function_name);
                l_ret := FALSE;
            
        END CASE;
    
        IF NOT l_ret
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        IF o_data_val IS NULL
        THEN
            l_dbg_msg := 'section without records, there''s no need to get the sections structure';
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            o_data_val := NULL;
            RETURN TRUE;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section structure';
        IF NOT pk_dynamic_screen.get_ds_section(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_component_name => i_component_name,
                                                i_component_type => i_component_type,
                                                i_patient        => i_patient,
                                                i_filter         => l_filter,
                                                o_section        => o_section,
                                                o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_dr_summary;

    --

    FUNCTION get_dr_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        --c_function_name CONSTANT obj_name := 'GET_DR_SECTION_LIST';
        --l_dbg_msg debug_msg;
        l_bool BOOLEAN;
    BEGIN
        --l_dbg_msg := 'get dynamic screen section list';
        l_bool := pk_dynamic_screen.get_ds_section_list(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_component_name => c_ds_death_registry,
                                                        i_component_type => pk_dynamic_screen.c_root_component,
                                                        i_patient        => i_patient,
                                                        o_section        => o_section,
                                                        o_error          => o_error);
    
        IF NOT l_bool
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
        END IF;
    
        RETURN l_bool;
    
    END get_dr_section_list;

    --

    FUNCTION get_dr_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_EVENTS_LIST';
        l_dbg_msg debug_msg;
        l_bool    BOOLEAN;
    BEGIN
        l_dbg_msg := 'get dynamic screen section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_bool := pk_dynamic_screen.get_ds_section_events_list(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_component_name => c_ds_death_registry,
                                                               i_component_type => pk_dynamic_screen.c_root_component,
                                                               o_section        => o_section,
                                                               o_def_events     => o_def_events,
                                                               o_error          => o_error);
    
        IF NOT l_bool
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
        END IF;
    
        RETURN l_bool;
    
    END get_dr_section_events_list;

    --
    FUNCTION get_data_inst_clues
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_data_val    IN OUT table_table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT obj_name := 'GET_DEATH_DATA_INST_CLUES';
        l_dbg_msg      debug_msg;
        l_id_clues     NUMBER;
        l_id           NUMBER;
        l_tmp          NUMBER;
        l_entity       VARCHAR2(4000);
        l_municipio    VARCHAR2(4000);
        l_local        VARCHAR2(4000);
        l_jurisdiction VARCHAR2(4000);
        l_street       VARCHAR2(4000);
        l_colony       VARCHAR2(4000);
        l_code_clues   VARCHAR2(4000);
        --l_id_jurisdiction NUMBER(24);
        l_institution table_varchar;
        t_clues       t_coll_clues_inst_mx := t_coll_clues_inst_mx();
    
        tbl_desc table_varchar := table_varchar('', '', '', '', '', '', '', '', '', '');
        tbl_name table_varchar := table_varchar('DEATH_DATA_ADRRESS_NUMBER',
                                                'DEATH_DATA_ADRRESS_COLONY',
                                                'DEATH_DATA_ADRRESS_ENTITY',
                                                'DEATH_DATA_ADRRESS_MUNICIPY',
                                                'DEATH_DATA_ADRRESS_LOCATION',
                                                'DEATH_DATA_ADDRESS_JURISD',
                                                'DEATH_DATA_INSTITUTION',
                                                'DR_DEATH_KNOWN_ADDRESS',
                                                'DEATH_DATA_KNOWN_ADDRESS',
                                                'DEATH_DATA_ADRRESS_FEDERAL_ENTITY',
                                                'DEATH_REGISTRY_CLUES_CODE',
                                                'DEATH_DATA_OCURRENCE',
                                                'DEATH_CERTIFIER_STREET', --13
                                                'DEATH_CERTIFIER_COLONY',
                                                'DEATH_CERTIFIER_ENTITY',
                                                'DEATH_CERTIFIER_MUNICIPY',
                                                'DEATH_CERTIFIER_LOCATION',
                                                'DEATH_CERTIFIER_FEDERAL_ENTITY',
                                                'DEATH_CERT_KNOWN_ADDRESS',
                                                'DEATH_FETAL_CERT_STREET');
    
        l_address_tt CONSTANT VARCHAR2(2 CHAR) := 'TT';
        --   l_id_adress constant number(24) := 11554;
        l_sys_list_address CONSTANT sys_list_group.internal_name%TYPE := 'DR_KNOWN_ADDRESS_SLG';
        l_id_address      sys_list.id_sys_list%TYPE := 11554;
        l_federal         VARCHAR2(10 CHAR) := '2004';
        l_settlement      VARCHAR2(200 CHAR);
        l_occurrence_site NUMBER;
    BEGIN
    
        l_id_clues := pk_adt.get_clues_inst(i_lang => i_lang, i_prof => i_prof, i_id_institution => i_institution);
    
        t_clues := pk_adt_core.get_clues_inst_mx(i_lang => i_lang, i_prof => i_prof, i_id_clues => l_id_clues);
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          BULK COLLECT
          INTO l_institution
          FROM institution i
         WHERE i.id_institution = i_institution;
    
        IF t_clues.count > 0
        THEN
            l_id         := t_clues(1).id_rb_regional_classifier;
            l_settlement := pk_adt.get_settlement_type_desc(i_lang, i_prof, t_clues(1).id_type_settlement);
            l_street     := t_clues(1).street_type || ' ' || t_clues(1).residence || ' ' || t_clues(1).inside_number || ' ' || t_clues(1).numero_exterior;
            l_colony     := l_settlement || ' ' || t_clues(1).urbanization;
            l_code_clues := t_clues(1).code_clues;
            --l_jurisdiction := t_clues(1).id_rb_reg_class_juris;
            tbl_desc(2) := l_colony;
            tbl_desc(1) := l_street;
        
            l_occurrence_site := pk_adt_core.get_occurrence_site(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_institution_code => t_clues(1).short_code_institution);
        END IF;
    
        IF l_institution.count > 0
           AND l_id_clues <> -1
        THEN
            tbl_desc(7) := l_institution(1);
        END IF;
        IF l_id_clues NOT IN (-1, -2)
        THEN
            l_tmp    := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_entidade);
            l_entity := to_char(l_tmp);
        
            l_tmp       := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_municipio);
            l_municipio := to_char(l_tmp);
        
            l_tmp   := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_localidade);
            l_local := to_char(pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id,
                                                               i_rank         => pk_adt.k_rank_localidade));
        
        END IF;
        tbl_desc(10) := pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_id_option => l_federal);
        IF l_occurrence_site IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_slms(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => tbl_name(12),
                                                           i_value    => l_occurrence_site);
        END IF;
        IF l_street IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(1),
                                                           i_value    => l_street);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(13),
                                                           i_value    => l_street);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(20),
                                                           i_value    => l_street);
        END IF;
        IF l_colony IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(2),
                                                           i_value    => l_colony);
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(14),
                                                           i_value    => l_colony);
        END IF;
        IF l_code_clues IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_fc(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => tbl_name(11),
                                                         i_value    => i_institution);
        END IF;
        IF l_entity IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(3),
                                                          i_value    => l_entity);
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(15),
                                                          i_value    => l_entity);
        END IF;
        IF l_municipio IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(4),
                                                          i_value    => l_municipio);
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(16),
                                                          i_value    => l_municipio);
        END IF;
        IF l_local IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(5),
                                                          i_value    => l_local);
            o_data_val := pk_dynamic_screen.add_value_adt(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_data_val => o_data_val,
                                                          i_name     => tbl_name(17),
                                                          i_value    => l_local);
        END IF;
        IF tbl_desc(7) IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                           i_name     => tbl_name(7),
                                                           i_value    => tbl_desc(7));
        END IF;
        IF l_id_address IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => tbl_name(8),
                                                         i_value    => l_id_address);
        
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => tbl_name(9),
                                                         i_value    => l_id_address);
            o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_data_val => o_data_val,
                                                         i_name     => tbl_name(19),
                                                         i_value    => l_id_address);
        END IF;
    
        IF l_federal IS NOT NULL
        THEN
            o_data_val := pk_dynamic_screen.add_value_slms(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => tbl_name(10),
                                                           i_value    => l_federal);
        
            o_data_val := pk_dynamic_screen.add_value_slms(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_data_val => o_data_val,
                                                           i_name     => tbl_name(18),
                                                           i_value    => l_federal);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END get_data_inst_clues;

    FUNCTION get_data_suggest
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_data_val    IN OUT table_table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT obj_name := 'GET_DATA_INFORMANT';
    
        tbl_name table_varchar := table_varchar('DEATH_INF_INFO_NAME_Q',
                                                'DEATH_INF_INFO_FATHER_Q',
                                                'DEATH_INF_INFO_MOTHER_Q',
                                                'DEATH_FETAL_CERT_NAME_Q',
                                                'DEATH_FETAL_CERT_FNAME_Q',
                                                'DEATH_FETAL_CERT_MNAME_Q');
    
        l_address_tt       CONSTANT VARCHAR2(2 CHAR) := 'TT';
        l_sys_list_address CONSTANT sys_list_group.internal_name%TYPE := 'DEATH_TXT_NOSPEC_SI';
        l_id_address sys_list.id_sys_list%TYPE := 11554;
        l_dbg_msg    debug_msg;
    BEGIN
    
        FOR i IN tbl_name.first .. tbl_name.last
        LOOP
            IF l_id_address IS NOT NULL
            THEN
                o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_data_val => o_data_val,
                                                             i_name     => tbl_name(i),
                                                             i_value    => l_id_address);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END get_data_suggest;

    FUNCTION get_dr_section_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN NUMBER,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_DATA';
        l_dbg_msg debug_msg;
    
        l_prof_data     pk_types.cursor_type;
        l_ret           BOOLEAN;
        l_death_date    TIMESTAMP WITH LOCAL TIME ZONE;
        l_patient_death patient.dt_deceased%TYPE;
        c_suggest_dt_death  CONSTANT sys_config.id_sys_config%TYPE := 'DEATH_REGISTRY_SUGG_DATE';
        c_check_health_plan CONSTANT sys_config.id_sys_config%TYPE := 'DEATH_REGISTRY_CHECK_HEALT_PLAN';
        l_suggest        sys_config.value%TYPE;
        l_market         market.id_market%TYPE;
        l_value          sys_list.id_sys_list%TYPE;
        l_ds_folio_birth VARCHAR2(4000);
        k_folio_birth_flg_spec CONSTANT sys_list.id_sys_list%TYPE := 11552;
        l_check_health_plan sys_config.value%TYPE;
        l_health_plan EXCEPTION;
        l_err_msg          VARCHAR2(200 CHAR);
        l_tbl_items_values t_table_ds_items_values;
        l_tbl_sections     t_table_ds_sections;
        l_tbl_def_events   t_table_ds_def_events;
        l_tbl_events       t_table_ds_events;
        l_dt_admission     VARCHAR2(0100 CHAR);
        l_final_diagnosis  VARCHAR2(4000);
        l_filter           VARCHAR2(1 CHAR);
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
    
        IF i_component_name = c_ds_death_data_fetal
        THEN
            l_filter := pk_alert_constant.g_yes;
        END IF;
    
        l_check_health_plan := pk_sysconfig.get_config(i_code_cf => c_check_health_plan, i_prof => i_prof);
        IF l_check_health_plan = pk_alert_constant.g_yes
        THEN
            IF pk_adt.get_pat_health_plan_mx(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_patient  => i_patient,
                                             i_flg_main => 'Y') IS NULL
            THEN
                o_flg_show := pk_alert_constant.g_yes;
                o_msg      := pk_message.get_message(i_lang, 'DR_NORM024_030');
                pk_types.open_my_cursor(i_cursor => o_section);
                pk_types.open_my_cursor(i_cursor => o_def_events);
                pk_types.open_my_cursor(i_cursor => o_events);
                pk_types.open_my_cursor(i_cursor => o_items_values);
                o_data_val := NULL;
                RETURN TRUE;
            
            END IF;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section complete structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_dynamic_screen.get_ds_section_complete_struct(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_component_name => i_component_name,
                                                                i_component_type => nvl(i_component_type,
                                                                                        pk_dynamic_screen.c_node_component),
                                                                i_patient        => i_patient,
                                                                i_filter         => l_filter,
                                                                o_section        => l_tbl_sections,
                                                                o_def_events     => l_tbl_def_events,
                                                                o_events         => l_tbl_events,
                                                                o_items_values   => l_tbl_items_values,
                                                                o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        IF NOT get_death_item_values(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_section          => l_tbl_sections,
                                     i_tbl_items_values => l_tbl_items_values,
                                     o_error            => o_error)
        THEN
            NULL;
        END IF;
        l_market  := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
        l_dbg_msg := 'get death registry values';
        CASE i_component_name
            WHEN c_ds_death_data THEN
                IF i_death_registry IS NOT NULL
                THEN
                    l_ret := get_death_data(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_patient   => i_patient,
                                            i_status    => pk_alert_constant.g_active,
                                            o_data_val  => o_data_val,
                                            o_prof_data => l_prof_data,
                                            o_error     => o_error);
                
                ELSE
                
                    --l_ds_folio_birth := pk_adt.get_code_birth_certificate(i_patient => i_patient);
                    l_ds_folio_birth := check_folio_birth_value(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_patient => i_patient);
                    IF l_ds_folio_birth IS NOT NULL
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                                       i_name     => k_ds_folio_birth,
                                                                       i_value    => l_ds_folio_birth);
                    
                        o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_data_val => o_data_val,
                                                                     i_name     => k_ds_folio_birth_flg,
                                                                     i_value    => k_folio_birth_flg_spec);
                    END IF;
                
                    l_dbg_msg       := 'get patient death date, if it has one, or current timestamp';
                    l_patient_death := get_patient_dt_deceased(i_patient => i_patient);
                    l_suggest       := pk_sysconfig.get_config(i_code_cf => c_suggest_dt_death, i_prof => i_prof);
                    IF l_suggest = pk_alert_constant.g_yes
                    THEN
                        l_death_date := nvl(b1 => l_patient_death, b2 => current_timestamp);
                    ELSE
                        l_death_date := l_patient_death;
                    END IF;
                
                    l_dbg_msg := 'return default values for a new death registry form';
                    IF l_death_date IS NOT NULL
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_tstz(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_data_val => o_data_val,
                                                                       i_name     => c_ds_dt_death,
                                                                       i_value    => l_death_date);
                    END IF;
                
                    -- cmf
                    l_dt_admission := pk_hea_prv_epis.get_admission_date(i_lang        => i_lang,
                                                                         i_prof        => i_prof,
                                                                         i_id_episode  => i_episode,
                                                                         i_id_schedule => NULL);
                    IF l_dt_admission IS NOT NULL
                    THEN
                        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                                       i_name     => 'DS_ADMISSION_DATE',
                                                                       i_value    => l_dt_admission);
                    END IF;
                
                    l_final_diagnosis := get_all_diag_string(i_lang, i_prof, i_episode);
                    IF l_final_diagnosis IS NOT NULL
                    THEN
                    
                        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                                       i_name     => 'DS_DEATH_ADMISSION',
                                                                       i_value    => l_final_diagnosis);
                    
                    END IF;
                
                    o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_data_val => o_data_val,
                                                                   i_name     => c_ds_prof_verified_death,
                                                                   i_value    => i_prof.id);
                
                    IF l_market = pk_alert_constant.g_id_market_mx
                    THEN
                        l_ret := get_data_inst_clues(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_institution => i_prof.institution,
                                                     o_data_val    => o_data_val,
                                                     o_error       => o_error);
                        l_ret := get_data_suggest(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_institution => i_prof.institution,
                                                  o_data_val    => o_data_val,
                                                  o_error       => o_error);
                    END IF;
                    o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_data_val => o_data_val,
                                                                   i_name     => 'DEATH_DATA_EXAMIN_PHYSICIAN',
                                                                   i_value    => i_prof.id);
                
                END IF;
            WHEN c_ds_death_data_fetal THEN
            
                IF i_death_registry IS NOT NULL
                THEN
                    l_ret := get_death_data_fetal(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_patient        => i_patient,
                                                  i_death_registry => i_death_registry,
                                                  i_status         => pk_alert_constant.g_active,
                                                  o_data_val       => o_data_val,
                                                  o_prof_data      => l_prof_data,
                                                  o_error          => o_error);
                ELSE
                
                    IF o_data_val IS NULL
                    THEN
                        l_dbg_msg  := 'get patient death date, if it has one, or current timestamp';
                        o_data_val := pk_dynamic_screen.add_value_text(i_data_val => o_data_val,
                                                                       i_name     => c_ds_death_certifier_phone,
                                                                       i_value    => c_phone_no_aplica);
                    
                        o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_data_val => o_data_val,
                                                                       i_name     => 'DS_DEATH_DATA_CERTIFY_PHYSICIAN',
                                                                       i_value    => i_prof.id);
                        IF l_market = pk_alert_constant.g_id_market_mx
                        THEN
                            l_ret := get_data_inst_clues(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_institution => i_prof.institution,
                                                         o_data_val    => o_data_val,
                                                         o_error       => o_error);
                            l_ret := get_data_suggest(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_institution => i_prof.institution,
                                                      o_data_val    => o_data_val,
                                                      o_error       => o_error);
                        END IF;
                    END IF;
                
                END IF;
            
            WHEN c_ds_organ_donor THEN
                l_ret := pk_organ_donor.get_organ_donor_data(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_patient   => i_patient,
                                                             i_status    => pk_alert_constant.g_active,
                                                             o_data_val  => o_data_val,
                                                             o_prof_data => l_prof_data,
                                                             o_error     => o_error);
            
            ELSE
                l_dbg_msg := 'wrong component name';
                pk_alertlog.log_error(text            => l_dbg_msg,
                                      object_name     => c_package_name,
                                      sub_object_name => c_function_name);
                l_ret := FALSE;
            
        END CASE;
    
        OPEN o_items_values FOR
            SELECT *
              FROM TABLE(l_tbl_items_values);
    
        OPEN o_section FOR
            SELECT *
              FROM TABLE(l_tbl_sections);
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_tbl_def_events);
    
        OPEN o_events FOR
            SELECT *
              FROM TABLE(l_tbl_events);
    
        IF NOT l_ret
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_health_plan THEN
            l_err_msg := pk_message.get_message(i_lang, 'DR_NORM024_030');
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => NULL,
                                              i_sqlerrm     => l_err_msg,
                                              i_message     => NULL,
                                              i_owner       => c_package_owner,
                                              i_package     => c_package_name,
                                              i_action_type => 'U',
                                              i_function    => c_function_name,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_dr_section_data;
    --

    /*    FUNCTION get_dr_section_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    begin
      
      return get_dr_section_data
        (
         i_lang           => i_lang          
        ,i_prof           => i_prof          
        ,i_patient        => i_patient       
        ,i_episode        => null
        ,i_death_registry => i_death_registry
        ,i_component_name => i_component_name
        ,i_component_type => i_component_type
        ,o_section        => o_section       
        ,o_def_events     => o_def_events    
        ,o_events         => o_events        
        ,o_items_values   => o_items_values  
        ,o_data_val       => o_data_val      
        ,o_error          => o_error         
        );
    
    end get_dr_section_data;*/

    -- ******************************************************************************
    FUNCTION check_anomaly
    (
        i_lang  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
        l_text   VARCHAR2(4000);
        k_lf CONSTANT VARCHAR2(0010 CHAR) := chr(10);
    BEGIN
    
        -- MRK01
        IF tbl_anomaly.count > 0
        THEN
        
            <<lup_thru_anomalies>>
            FOR i IN 1 .. tbl_anomaly.count
            LOOP
                l_text := l_text || tbl_anomaly(i) || k_lf;
            END LOOP lup_thru_anomalies;
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => NULL,
                                              i_sqlerrm     => l_text,
                                              i_message     => NULL,
                                              i_owner       => 'ALERT',
                                              i_action_type => 'U',
                                              i_package     => 'PK_DEATH_REGISTRY',
                                              i_function    => 'CHECK_ANOMALY',
                                              o_error       => o_error);
            l_return := FALSE;
        
        END IF; -- MRK01
    
        RETURN l_return;
    
    END check_anomaly;

    -- ******************************************************************************
    FUNCTION set_dr_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        o_id_section     OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DR_DATA';
        l_dbg_msg debug_msg;
    
        c_timestamp CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_ret BOOLEAN;
    
    BEGIN
        l_dbg_msg := 'save death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        tbl_anomaly := table_varchar();
    
        CASE i_component_name
            WHEN c_ds_death_data THEN
                l_ret := set_death_data(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_date           => c_timestamp,
                                        i_patient        => i_patient,
                                        i_episode        => i_episode,
                                        i_data_val       => i_data_val,
                                        o_death_registry => o_id_section,
                                        o_error          => o_error);
            
            WHEN c_ds_death_data_fetal THEN
                l_ret := set_death_data_fetal(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_date           => c_timestamp,
                                              i_patient        => i_patient,
                                              i_episode        => i_episode,
                                              i_death_registry => i_death_registry,
                                              i_data_val       => i_data_val,
                                              o_death_registry => o_id_section,
                                              o_error          => o_error);
            
            WHEN c_ds_organ_donor THEN
                l_ret := pk_organ_donor.set_organ_donor(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_date        => c_timestamp,
                                                        i_patient     => i_patient,
                                                        i_episode     => i_episode,
                                                        i_data_val    => i_data_val,
                                                        o_organ_donor => o_id_section,
                                                        o_error       => o_error);
            
            ELSE
                l_dbg_msg := 'wrong component name';
                pk_alertlog.log_error(text            => l_dbg_msg,
                                      object_name     => c_package_name,
                                      sub_object_name => c_function_name);
                l_ret := FALSE;
            
        END CASE;
    
        l_ret := l_ret AND check_anomaly(i_lang => i_lang, o_error => o_error);
    
        IF NOT l_ret
        THEN
            o_id_section := NULL;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_id_section := NULL;
            RETURN FALSE;
        
    END set_dr_data;

    /**********************************************************************************************
    * Set suspension action id for a patient death registry
    *
    * @param        i_lang                   Language id
    * @param        i_death_registry         Death registry id
    * @param        i_id_susp_action         Suspension action id
    * @param        o_death_registry         Updated death registry id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        22-Jun-2010
    **********************************************************************************************/
    FUNCTION set_death_registry_susp_action
    (
        i_lang           IN language.id_language%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        i_id_susp_action IN death_registry.id_susp_action%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_DEATH_REGISTRY_SUSP_ACTION';
        l_dbg_msg debug_msg;
    
        l_death_registry_hist death_registry_hist.id_death_registry_hist%TYPE;
    
    BEGIN
        l_dbg_msg := 'set death registry suspension action';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        ts_death_registry.upd(id_death_registry_in => i_death_registry,
                              id_susp_action_in    => i_id_susp_action,
                              id_susp_action_nin   => FALSE);
    
        l_dbg_msg := 'get most recent death registry history id';
        SELECT id_death_registry_hist
          INTO l_death_registry_hist
          FROM (SELECT drh.id_death_registry_hist
                  FROM death_registry_hist drh
                 WHERE drh.id_death_registry = i_death_registry
                 ORDER BY drh.dt_death_registry DESC)
         WHERE rownum = 1;
    
        l_dbg_msg := 'set death registry history suspension action';
        ts_death_registry_hist.upd(id_death_registry_hist_in => l_death_registry_hist,
                                   id_susp_action_in         => i_id_susp_action,
                                   id_susp_action_nin        => FALSE);
    
        o_death_registry := i_death_registry;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_death_registry := NULL;
            RETURN FALSE;
        
    END set_death_registry_susp_action;

    /**********************************************************************************************
    * Returns patient final diagnosis for this episode
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        o_diagnosis              Cursor with patient final diagnosis
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        10-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_disch_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_DISCH_DIAGNOSIS';
        l_dbg_msg           debug_msg;
        l_suggest_diagnosis sys_config.value%TYPE;
    
    BEGIN
        l_suggest_diagnosis := pk_sysconfig.get_config('DEATH_REGISTRY_SUGGEST_DIAGNOSIS', i_prof);
    
        l_dbg_msg := 'get patient final diagnosis for this episode';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF l_suggest_diagnosis = k_yes
        THEN
            OPEN o_diagnosis FOR
                SELECT ed.id_epis_diagnosis,
                       ed.id_diagnosis,
                       ed.id_alert_diagnosis,
                       pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => ad.flg_icd9,
                                                  i_epis_diag           => ed.id_epis_diagnosis,
                                                  i_flg_search_mode     => k_yes) AS desc_diagnosis,
                       ed.desc_epis_diagnosis AS other_diag_desc,
                       d.flg_other
                  FROM epis_diagnosis ed
                 INNER JOIN diagnosis d
                    ON ed.id_diagnosis = d.id_diagnosis
                  LEFT OUTER JOIN alert_diagnosis ad
                    ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
                 WHERE ed.id_episode = i_episode
                   AND ed.flg_type = pk_diagnosis.g_diag_type_d
                   AND ed.flg_status NOT IN (pk_diagnosis.g_epis_status_c, pk_diagnosis.g_ed_flg_status_r);
        ELSE
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            RETURN FALSE;
        
    END get_pat_disch_diagnosis;

    /**********************************************************************************************
    * Cancel death registry
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        i_component_name         Component internal name
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel   IN death_registry.notes_cancel%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_susp_action    OUT death_registry.id_susp_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_DEATH_REGISTRY';
        l_dbg_msg debug_msg;
    
        c_timestamp CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_ret BOOLEAN;
    
    BEGIN
        CASE i_component_name
            WHEN c_ds_death_data THEN
                l_dbg_msg := 'cancel death data registry';
                l_ret     := cancel_death_data(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_patient       => i_patient,
                                               i_episode       => i_episode,
                                               i_date          => c_timestamp,
                                               i_cancel_reason => i_cancel_reason,
                                               i_notes_cancel  => i_notes_cancel,
                                               o_susp_action   => o_susp_action,
                                               o_error         => o_error);
            
            WHEN c_ds_death_data_fetal THEN
                l_dbg_msg := 'cancel death data registry';
                l_ret     := cancel_death_data_fetal(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_patient        => i_patient,
                                                     i_episode        => i_episode,
                                                     i_death_registry => i_death_registry,
                                                     i_date           => c_timestamp,
                                                     i_cancel_reason  => i_cancel_reason,
                                                     i_notes_cancel   => i_notes_cancel,
                                                     o_susp_action    => o_susp_action,
                                                     o_error          => o_error);
            
            WHEN c_ds_organ_donor THEN
                l_dbg_msg     := 'cancel organ donor registry';
                l_ret         := pk_organ_donor.cancel_organ_donor(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_date          => c_timestamp,
                                                                   i_patient       => i_patient,
                                                                   i_episode       => i_episode,
                                                                   i_cancel_reason => i_cancel_reason,
                                                                   i_notes_cancel  => i_notes_cancel,
                                                                   o_error         => o_error);
                o_susp_action := NULL;
            ELSE
                l_dbg_msg := 'wrong component name';
                pk_alertlog.log_error(text            => l_dbg_msg,
                                      object_name     => c_package_name,
                                      sub_object_name => c_function_name);
                l_ret := FALSE;
            
        END CASE;
    
        IF NOT l_ret
        THEN
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            o_susp_action := NULL;
            RETURN FALSE;
        
    END cancel_death_registry;

    --

    FUNCTION get_dr_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_record         IN death_registry.id_death_registry%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_DETAIL';
        l_dbg_msg debug_msg;
    
        l_ret BOOLEAN;
    
    BEGIN
        l_dbg_msg := 'get patient death registry details';
        CASE i_component_name
            WHEN c_ds_death_data THEN
                l_ret := get_death_data_detail(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_patient        => i_patient,
                                               i_death_registry => i_record,
                                               o_data_val       => o_data_val,
                                               o_prof_data      => o_prof_data,
                                               o_dr_wf          => o_dr_wf,
                                               o_sys_list       => o_sys_list,
                                               o_error          => o_error);
            
            WHEN c_ds_death_data_fetal THEN
                o_dr_wf := NULL;
                l_ret   := get_death_data_fetal_detail(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_death_registry => i_record,
                                                       o_data_val       => o_data_val,
                                                       o_prof_data      => o_prof_data,
                                                       o_error          => o_error);
            WHEN c_ds_organ_donor THEN
                o_dr_wf := NULL;
                pk_types.open_my_cursor(i_cursor => o_sys_list);
                l_ret := pk_organ_donor.get_organ_donor_detail(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_patient   => i_patient,
                                                               o_data_val  => o_data_val,
                                                               o_prof_data => o_prof_data,
                                                               o_error     => o_error);
            
            ELSE
                l_dbg_msg := 'wrong component name';
                pk_alertlog.log_error(text            => l_dbg_msg,
                                      object_name     => c_package_name,
                                      sub_object_name => c_function_name);
                l_ret := FALSE;
            
        END CASE;
    
        IF NOT l_ret
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            o_data_val := NULL;
            o_dr_wf    := NULL;
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section structure';
        IF NOT pk_dynamic_screen.get_ds_section(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_patient        => i_patient,
                                                i_component_name => i_component_name,
                                                i_component_type => i_component_type,
                                                o_section        => o_section,
                                                o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            o_data_val := NULL;
            o_dr_wf    := NULL;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            pk_types.open_my_cursor(i_cursor => o_sys_list);
            o_data_val := NULL;
            o_dr_wf    := NULL;
            RETURN FALSE;
        
    END get_dr_detail;

    /**********************************************************************************************
    * Changes the episode id in a death registry (This function should only be called
    * by pk_match.set_match_core)
    *
    * @param        i_lang                   Language id
    * @param        i_new_episode            New episode id
    * @param        i_old_episode            Old episode id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_dr_episode_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_episode IN organ_donor.id_episode%TYPE,
        i_old_episode IN organ_donor.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CHANGE_DR_EPISODE_ID';
        l_dbg_msg debug_msg;
    
        l_where VARCHAR2(200 CHAR);
    
    BEGIN
        l_where := ' id_episode = ' || i_old_episode;
    
        l_dbg_msg := 'update episode id for all registries';
        ts_death_registry.upd(id_episode_in => i_new_episode, id_episode_nin => FALSE, where_in => l_where);
    
        l_dbg_msg := 'update episode id for all history registries';
        ts_death_registry_hist.upd(id_episode_in => i_new_episode, id_episode_nin => FALSE, where_in => l_where);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END change_dr_episode_id;

    --
    -- INITIALIZATION SECTION
    --

    /**********************************************************************************************
    * Returns datatype of component for save purpose
    *
    * @param        i_id_ds_comp      id in ds_component table
    *
    * @return       supposed datatype of component
    *
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        28-11-2016
    **********************************************************************************************/
    FUNCTION get_datatype(i_id_ds_comp IN NUMBER) RETURN VARCHAR2 IS
        --tbl_dtype  table_varchar;
        l_datatype ds_component.flg_data_type%TYPE;
    
        tbl_data_type table_varchar := table_varchar(k_ctype_d,
                                                     k_ctype_dt,
                                                     k_ctype_dp,
                                                     k_ctype_dtp,
                                                     k_ctype_ft,
                                                     k_ctype_ms,
                                                     k_ctype_mm,
                                                     k_ctype_md,
                                                     k_ctype_mc,
                                                     k_ctype_mr,
                                                     k_ctype_mo,
                                                     k_ctype_n,
                                                     k_ctype_fr,
                                                     k_ctype_fc,
                                                     k_ctype_me,
                                                     k_ctype_ml,
                                                     k_ctype_mp,
                                                     k_ctype_mj,
                                                     k_ctype_k);
    
        tbl_comp_type table_varchar := table_varchar(k_dtype_t,
                                                     k_dtype_t,
                                                     k_dtype_t,
                                                     k_dtype_t,
                                                     k_dtype_v,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_v,
                                                     k_dtype_n,
                                                     k_dtype_v,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n,
                                                     k_dtype_n);
    
    BEGIN
    
        IF i_id_ds_comp IS NOT NULL
        THEN
        
            l_datatype := get_flg_data_type(i_id_ds_comp => i_id_ds_comp);
        
            <<lup_thru_types>>
            FOR i IN 1 .. tbl_data_type.count
            LOOP
            
                IF tbl_data_type(i) = l_datatype
                THEN
                    l_datatype := tbl_comp_type(i);
                    EXIT lup_thru_types;
                END IF;
            
            END LOOP lup_thru_types;
        ELSE
            l_datatype := k_dtype_v;
        END IF;
    
        RETURN l_datatype;
    
    END get_datatype;

    -- *****************************************************************
    FUNCTION check_dyn_field(i_ds_comp_name IN VARCHAR2) RETURN BOOLEAN IS
        l_bool            BOOLEAN;
        k_main_components table_varchar := table_varchar(c_ds_dt_death,
                                                         c_ds_prof_verified_death,
                                                         c_ds_natural_cause,
                                                         c_ds_coroner_warned,
                                                         c_ds_death_cause(1),
                                                         c_ds_death_cause(2),
                                                         c_ds_death_cause(3),
                                                         c_ds_death_cause(4),
                                                         c_ds_death_cause(5),
                                                         c_ds_death_cause(6),
                                                         c_ds_death_cause(7),
                                                         c_ds_death_cause(8),
                                                         c_ds_death_cause(9),
                                                         c_ds_death_cause(10),
                                                         c_ds_death_cause(11),
                                                         c_ds_death_cause(12),
                                                         c_ds_death_cause(13),
                                                         c_ds_death_cause(14),
                                                         c_ds_death_cause(15),
                                                         c_ds_death_cause(16),
                                                         c_ds_death_cause(17),
                                                         c_ds_death_cause(18));
    BEGIN
    
        l_bool := NOT (i_ds_comp_name MEMBER OF k_main_components);
    
        RETURN l_bool;
    
    END check_dyn_field;

    -- Para cert-MX-NORM24
    FUNCTION validate_cert_date
    (
        i_name    IN VARCHAR2,
        i_value   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN IS
        k_component        CONSTANT VARCHAR2(0200 CHAR) := 'DEATH_DATA_FOLIO';
        k_component_mother CONSTANT VARCHAR2(0200 CHAR) := 'DEATH_FETAL_PREV_PREG_FOLIO';
        l_pos_1  NUMBER := 3;
        l_pos_yy NUMBER := 1;
        l_year   VARCHAR2(0010 CHAR);
        l_value  VARCHAR2(1000 CHAR) := to_char(i_value);
        --l_return BOOLEAN := TRUE;
        l_bool   BOOLEAN := TRUE;
        l_year_n NUMBER(24);
    BEGIN
    
        IF i_name IN (k_component, k_component_mother)
        THEN
        
            l_year   := to_char(current_timestamp, 'YY');
            l_year_n := to_number(l_year);
            IF i_section = c_ds_death_data_fetal
               AND i_name = k_component
            THEN
                l_bool := substr(l_value, l_pos_1, 1) = '1';
            ELSIF (i_section = c_ds_death_data AND i_name = k_component)
                  OR i_name = k_component_mother
            THEN
                l_bool := substr(l_value, l_pos_1, 1) = '0';
            END IF;
        
            IF l_bool
            THEN
                l_bool := length(l_value) = 9;
            END IF;
        
            IF l_bool
            THEN
            
                l_bool := substr(l_value, l_pos_yy, 2) = l_year;
                IF l_bool
                THEN
                    RETURN l_bool;
                END IF;
                l_bool := substr(l_value, l_pos_yy, 2) = (l_year_n + 1);
                IF l_bool
                THEN
                    RETURN l_bool;
                END IF;
            
                l_bool := substr(l_value, l_pos_yy, 2) = (l_year_n - 1);
            END IF;
        END IF;
    
        RETURN l_bool;
    
    END validate_cert_date;

    -- **********************************************************************
    FUNCTION get_dp_mode(i_date IN VARCHAR2) RETURN VARCHAR2 IS
        k_empty CONSTANT VARCHAR2(0010 CHAR) := '00';
    
        l_dd     VARCHAR2(0020 CHAR);
        l_mm     VARCHAR2(0020 CHAR);
        l_return VARCHAR2(0020 CHAR);
    BEGIN
    
        l_dd := substr(i_date, k_pos_dd, k_len);
        l_mm := substr(i_date, k_pos_mm, k_len);
    
        CASE
            WHEN l_mm = k_empty
                 AND l_dd = k_empty THEN
                l_return := k_dp_mode_yyyy;
            WHEN l_mm != k_empty
                 AND l_dd = k_empty THEN
                l_return := k_dp_mode_mmyyyy;
            ELSE
                l_return := k_dp_mode_full;
        END CASE;
    
        RETURN l_return;
    
    END get_dp_mode;
    -- **********************************************************************
    FUNCTION process_date_in(i_date IN VARCHAR2) RETURN VARCHAR2 IS
    
        l_dd     t_low_char;
        l_mm     t_low_char;
        l_yy     t_low_char;
        l_return t_low_char;
        l_hr     t_low_char;
        l_case   t_low_char;
    BEGIN
    
        l_case := get_dp_mode(i_date);
    
        CASE l_case
        --when l_mm = k_empty and l_dd = k_empty then
            WHEN k_dp_mode_yyyy THEN
                l_yy := substr(i_date, k_pos_yy, k_leny);
                l_mm := '01';
                l_dd := '01';
                l_hr := '000000';
                --when l_mm != k_empy and l_dd = k_empty then
            WHEN k_dp_mode_mmyyyy THEN
                l_yy := substr(i_date, k_pos_yy, k_leny);
                l_mm := substr(i_date, k_pos_mm, k_len);
                l_dd := '01';
                l_hr := '000000';
            ELSE
                l_yy := substr(i_date, k_pos_yy, k_leny);
                l_mm := substr(i_date, k_pos_mm, k_len);
                l_dd := substr(i_date, k_pos_dd, k_len);
                l_hr := substr(i_date, k_pos_hr);
        END CASE;
    
        l_return := l_yy || l_mm || l_dd || l_hr;
    
        RETURN l_return;
    
    END process_date_in;

    -- **********************************************************************
    PROCEDURE set_dyn_data
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_death_registry IN NUMBER,
        i_data_val          IN table_table_varchar,
        i_section           IN VARCHAR2
    ) IS
    
        k_name_pos   CONSTANT NUMBER(6) := 1;
        k_value_pos  CONSTANT NUMBER(6) := 3;
        k_altval_pos CONSTANT NUMBER(6) := 4;
        l_comp          NUMBER(24);
        l_value         VARCHAR2(4000);
        l_name          VARCHAR2(4000);
        l_datatype      VARCHAR2(0200 CHAR);
        l_um            NUMBER(24);
        l_flg_data_type VARCHAR2(0010 CHAR);
    
        r_drd              death_registry_det%ROWTYPE;
        l_count            NUMBER;
        l_bool             BOOLEAN;
        l_anomaly          sys_message.desc_message%TYPE;
        k_folio_msg        sys_message.code_message%TYPE := 'NOM24_WRONG_FOLIO_FORMAT';
        k_folio_msg_mother sys_message.code_message%TYPE := 'DR_NORM024_029';
        k_component        CONSTANT VARCHAR2(0200 CHAR) := 'DEATH_DATA_FOLIO';
        k_component_mother CONSTANT VARCHAR2(0200 CHAR) := 'DEATH_FETAL_PREV_PREG_FOLIO';
        -- ********************************************************************
        PROCEDURE push_value
        (
            i_datatype IN VARCHAR2,
            i_value    IN VARCHAR2
        ) IS
            l_dt_value VARCHAR2(0200 CHAR);
        BEGIN
        
            CASE i_datatype
                WHEN k_dtype_n THEN
                
                    r_drd.value_n := i_value;
                WHEN k_dtype_v THEN
                
                    r_drd.value_vc2 := i_value;
                WHEN k_dtype_t THEN
                
                    l_dt_value      := process_date_in(i_date => i_value);
                    r_drd.value_vc2 := get_dp_mode(i_value);
                    r_drd.value_tz  := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_timestamp => l_dt_value,
                                                                     i_timezone  => NULL);
                ELSE
                    r_drd.value_vc2 := i_value;
            END CASE;
        
        END push_value;
    
        -- *******************************************
        FUNCTION exists_component
        (
            i_death_registry death_registry.id_death_registry%TYPE,
            i_ds_component   ds_component.id_ds_component%TYPE
        ) RETURN BOOLEAN IS
            l_cnt NUMBER;
            l_ret BOOLEAN;
        BEGIN
            SELECT COUNT(1)
              INTO l_cnt
              FROM death_registry_det drd
             WHERE drd.id_death_registry = i_death_registry
               AND drd.id_ds_component = i_ds_component;
        
            l_ret := NOT (l_cnt = 0);
        
            RETURN l_ret;
        END exists_component;
    
    BEGIN
    
        <<lup_thru_components>>
        FOR i IN 1 .. i_data_val.count
        LOOP
        
            l_name := i_data_val(i) (k_name_pos);
        
            IF check_dyn_field(l_name)
            THEN
            
                l_comp  := get_id_ds_component(i_internal_name => l_name);
                l_value := i_data_val(i) (k_value_pos);
            
                --IF l_value IS NOT NULL  THEN
                l_flg_data_type := get_flg_data_type(i_id_ds_comp => l_comp);
            
                IF l_flg_data_type = pk_dynamic_screen.c_data_type_k
                THEN
                    l_um := i_data_val(i) (k_altval_pos);
                END IF;
            
                IF l_flg_data_type IN (pk_dynamic_screen.c_data_type_dtp, pk_dynamic_screen.c_data_type_dp)
                THEN
                    r_drd.value_vc2 := get_dp_mode(i_date => l_value);
                ELSE
                    r_drd.value_vc2 := NULL;
                END IF;
            
                l_datatype := get_datatype(i_id_ds_comp => l_comp);
            
                r_drd                    := NULL;
                r_drd.id_death_registry  := i_id_death_registry;
                r_drd.id_ds_component    := l_comp;
                r_drd.unit_measure_value := l_um;
            
                push_value(i_datatype => l_datatype, i_value => l_value);
            
                -- NOM24
                IF l_name IN (k_component, k_component_mother)
                THEN
                    l_bool := validate_cert_date(i_name => l_name, i_value => r_drd.value_n, i_section => i_section);
                    IF NOT l_bool
                    THEN
                        IF l_name = k_component_mother
                        THEN
                            l_anomaly := pk_message.get_message(i_lang, k_folio_msg_mother);
                        ELSE
                            l_anomaly := pk_message.get_message(i_lang, k_folio_msg);
                        
                        END IF;
                        register_anomaly(l_anomaly);
                    END IF;
                END IF;
            
                IF exists_component(i_id_death_registry, r_drd.id_ds_component)
                THEN
                    ts_death_registry_det.upd(id_death_registry_in   => r_drd.id_death_registry,
                                              id_ds_component_in     => r_drd.id_ds_component,
                                              value_n_in             => r_drd.value_n,
                                              value_n_nin            => FALSE,
                                              value_tz_in            => r_drd.value_tz,
                                              value_tz_nin           => FALSE,
                                              value_vc2_in           => r_drd.value_vc2,
                                              value_vc2_nin          => FALSE,
                                              unit_measure_value_in  => r_drd.unit_measure_value,
                                              unit_measure_value_nin => FALSE,
                                              where_in               => 'id_death_registry=' || r_drd.id_death_registry ||
                                                                        ' and id_ds_component=' || r_drd.id_ds_component);
                ELSE
                    ts_death_registry_det.ins(id_death_registry_in  => r_drd.id_death_registry,
                                              id_ds_component_in    => r_drd.id_ds_component,
                                              value_n_in            => r_drd.value_n,
                                              value_tz_in           => r_drd.value_tz,
                                              value_vc2_in          => r_drd.value_vc2,
                                              unit_measure_value_in => r_drd.unit_measure_value);
                END IF;
            
                l_count := SQL%ROWCOUNT;
            
            END IF;
        
        END LOOP lup_thru_components;
    
    END set_dyn_data;

    /**********************************************************************************************
    * get get_dr_section_add returns rows with status of section.
    *
    *
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        02-12-2016
    **********************************************************************************************/
    FUNCTION get_dr_section_add
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_DR_SECTION_ADD';
        l_msg VARCHAR2(4000);
    
    BEGIN
    
        l_msg := 'Processing GET_DR_SECTION_ADD';
        OPEN o_section FOR
            SELECT a.id_ds_cmpt_mkt_rel,
                   a.id_ds_component_parent,
                   a.id_ds_component,
                   a.component_desc,
                   a.internal_name,
                   a.flg_component_type,
                   a.flg_data_type,
                   a.slg_internal_name,
                   a.addit_info_xml_value,
                   a.rank,
                   a.max_len,
                   a.min_value,
                   a.max_value,
                   pk_death_registry.get_section_status(i_prof          => i_prof,
                                                        i_internal_name => a.internal_name,
                                                        i_patient       => i_patient) flg_section_enabled,
                   pk_death_registry.get_section_status(i_prof          => i_prof,
                                                        i_internal_name => a.internal_name,
                                                        i_patient       => i_patient,
                                                        i_type          => 'E') flg_edit_enabled
              FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_component_name => c_ds_death_registry,
                                                          i_component_type => pk_dynamic_screen.c_root_component,
                                                          i_component_list => k_yes,
                                                          i_patient        => i_patient)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
    END get_dr_section_add;

    /**********************************************************************************************
    * get id_death_registry from fetus record.
    *
    *
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        02-12-2016
    **********************************************************************************************/
    FUNCTION get_fetal_death_registry
    (
        i_id_patient     IN NUMBER,
        i_death_registry IN NUMBER
    ) RETURN table_number IS
        tbl_return table_number;
    BEGIN
    
        IF i_death_registry IS NULL
        THEN
            SELECT dr.id_death_registry
              BULK COLLECT
              INTO tbl_return
              FROM death_registry dr
              JOIN episode e
                ON e.id_episode = dr.id_episode
              JOIN visit v
                ON v.id_visit = e.id_visit
             WHERE v.id_patient = i_id_patient
               AND dr.flg_type = k_flg_dr_type_fetus;
        ELSE
            tbl_return := table_number(i_death_registry);
        END IF;
    
        RETURN tbl_return;
    
    END get_fetal_death_registry;

    /**********************************************************************************************
    * get death fetal section data.
    *
    *
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        02-12-2016
    **********************************************************************************************/
    FUNCTION get_death_data_fetal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN NUMBER,
        i_status         IN death_registry.flg_status%TYPE DEFAULT NULL,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT obj_name := 'GET_DEATH_DATA_FETAL';
        l_dbg_msg debug_msg;
    
        l_dr_row death_registry%ROWTYPE;
    
        tbl_ids table_number := table_number();
    
        CURSOR dr_fetal_c(i_tbl IN table_number) IS
            SELECT dr.*
              FROM death_registry dr
              JOIN (SELECT /*+ OPT_ESTIMATE(TABLE dri ROWS=1) */
                     column_value id_death_registry
                      FROM TABLE(i_tbl) dri) xdr
                ON xdr.id_death_registry = dr.id_death_registry
             WHERE dr.flg_type = k_flg_dr_type_fetus;
    
    BEGIN
        l_dbg_msg := 'get patient death data, if exists';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => k_function_name);
    
        tbl_ids := pk_death_registry.get_fetal_death_registry(i_id_patient     => i_patient,
                                                              i_death_registry => i_death_registry);
    
        IF tbl_ids.count > 0
        THEN
        
            <<lup_thru_dr>>
            FOR l_dr_row IN dr_fetal_c(i_tbl => tbl_ids)
            LOOP
            
                pk_dynamic_screen.set_data_key(l_dr_row.id_death_registry);
            
                l_dbg_msg  := 'build structure with death data';
                o_data_val := pk_dynamic_screen.add_value_tstz(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_data_val => o_data_val,
                                                               i_name     => c_ds_dt_death,
                                                               i_value    => l_dr_row.dt_death);
            
                o_data_val := pk_dynamic_screen.add_value_prof(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_data_val => o_data_val,
                                                               i_name     => c_ds_prof_verified_death,
                                                               i_value    => l_dr_row.id_prof_verified_death);
            
                o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_data_val => o_data_val,
                                                             i_name     => c_ds_natural_cause,
                                                             i_value    => l_dr_row.id_sl_natural_cause);
            
                o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_data_val => o_data_val,
                                                             i_name     => c_ds_coroner_warned,
                                                             i_value    => l_dr_row.id_sl_coroner_warned);
            
                o_data_val := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_data_val => o_data_val,
                                                             i_name     => c_ds_autopsy,
                                                             i_value    => l_dr_row.id_sl_autopsy);
            
                o_data_val := get_dyn_data(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_death_registry => l_dr_row.id_death_registry,
                                           i_data_val       => o_data_val);
            
                IF NOT get_death_cause(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_death_registry => l_dr_row.id_death_registry,
                                       i_component_name => c_ds_death_data_fetal,
                                       o_data_val       => o_data_val,
                                       o_error          => o_error)
                THEN
                    o_data_val := NULL;
                    pk_types.open_my_cursor(i_cursor => o_prof_data);
                    RETURN FALSE;
                END IF;
            
            END LOOP lup_thru_dr;
        
            l_dbg_msg := 'get info about the professional that made the registry';
            IF NOT pk_dynamic_screen.get_death_registry_prof_data(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_tbl_id    => tbl_ids,
                                                                  o_prof_data => o_prof_data,
                                                                  o_error     => o_error)
            THEN
                o_data_val := NULL;
                pk_types.open_my_cursor(i_cursor => o_prof_data);
                RETURN FALSE;
            END IF;
        
        ELSE
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            o_data_val := NULL;
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_death_data_fetal;

    --
    PROCEDURE set_death_history_det_h
    (
        i_death_registry      IN NUMBER,
        i_death_registry_hist IN NUMBER
    ) IS
        l_row death_registry_det_hist%ROWTYPE;
    
        CURSOR c_reg IS
            SELECT *
              FROM death_registry_det
             WHERE id_death_registry = i_death_registry;
    
    BEGIN
    
        l_row.id_death_registry_hist := i_death_registry_hist;
        l_row.id_death_registry      := i_death_registry;
    
        FOR xrow IN c_reg
        LOOP
        
            l_row.id_ds_component    := xrow.id_ds_component;
            l_row.value_n            := xrow.value_n;
            l_row.value_tz           := xrow.value_tz;
            l_row.value_vc2          := xrow.value_vc2;
            l_row.unit_measure_value := xrow.unit_measure_value;
        
            ts_death_registry_det_hist.ins(id_death_registry_hist_in => l_row.id_death_registry_hist,
                                           id_death_registry_in      => l_row.id_death_registry,
                                           id_ds_component_in        => l_row.id_ds_component,
                                           value_n_in                => l_row.value_n,
                                           value_tz_in               => l_row.value_tz,
                                           value_vc2_in              => l_row.value_vc2,
                                           unit_measure_value_in     => l_row.unit_measure_value);
        
        END LOOP;
    
    END set_death_history_det_h;

    FUNCTION get_cause_mx
    (
        i_id_death_registry IN NUMBER,
        i_rank              IN NUMBER,
        i_field             IN VARCHAR2
    ) RETURN VARCHAR2 IS
        tbl_diag       table_number;
        tbl_epis_diag  table_number;
        tbl_alert_diag table_number;
        l_return       VARCHAR2(4000);
    BEGIN
    
        SELECT dc.id_diagnosis, dc.id_epis_diagnosis, dc.id_alert_diagnosis
          BULK COLLECT
          INTO tbl_diag, tbl_epis_diag, tbl_alert_diag
          FROM death_cause dc
         WHERE dc.id_death_registry = i_id_death_registry
           AND dc.death_cause_rank = i_rank;
    
        IF tbl_diag.count > 0
        THEN
        
            CASE i_field
                WHEN 'ID_DIAGNOSIS' THEN
                    l_return := tbl_diag(1);
                WHEN 'ID_EPIS_DIAGNOSIS' THEN
                    l_return := tbl_epis_diag(1);
                WHEN 'ID_ALERT_DIAGNOSIS' THEN
                    l_return := tbl_alert_diag(1);
                ELSE
                    l_return := NULL;
            END CASE;
        
        END IF;
    
        RETURN l_return;
    
    END get_cause_mx;

    FUNCTION get_fetal_cause_type
    (
        i_id_death_registry IN NUMBER,
        i_order             IN NUMBER
    ) RETURN VARCHAR2 IS
    
        tbl_value table_number;
        -- ds_component para death_cause_type
        tbl_comp          table_number := table_number(404, 405, 406, 407, 408, 409, 443);
        l_id_ds_component NUMBER;
        l_id_content      VARCHAR2(4000);
    
        FUNCTION get_id_ds_component(i_order IN NUMBER) RETURN NUMBER IS
            l_return NUMBER := -1;
        BEGIN
        
            IF i_order BETWEEN 0 AND 6
            THEN
                l_return := tbl_comp(i_order + 1);
            END IF;
        
            RETURN l_return;
        
        END get_id_ds_component;
    
    BEGIN
    
        l_id_ds_component := get_id_ds_component(i_order);
    
        SELECT drd.value_n
          BULK COLLECT
          INTO tbl_value
          FROM death_registry_det drd
         WHERE drd.id_death_registry = i_id_death_registry
           AND drd.id_ds_component = l_id_ds_component;
    
        IF tbl_value.count > 0
        THEN
            l_id_content := pk_multichoice.get_id_content(i_multichoice_option => tbl_value(1));
        END IF;
    
        RETURN l_id_content;
    
    END get_fetal_cause_type;

    -- ****************************************
    FUNCTION get_death_data_folio_by_id(i_id_death_registry IN NUMBER) RETURN VARCHAR2 IS
        tbl_value table_varchar;
        l_return  VARCHAR2(4000);
        k_folio_component CONSTANT VARCHAR2(0050 CHAR) := 'DEATH_DATA_FOLIO';
    BEGIN
    
        SELECT to_char(value_n)
          BULK COLLECT
          INTO tbl_value
          FROM death_registry_det drd
          JOIN ds_component d
            ON d.id_ds_component = drd.id_ds_component
         WHERE drd.id_death_registry = i_id_death_registry
           AND d.internal_name = k_folio_component
           AND d.flg_component_type = 'L';
    
        IF tbl_value.count > 0
        THEN
            l_return := tbl_value(1);
        END IF;
    
        RETURN l_return;
    
    END get_death_data_folio_by_id;

    -- **************************************************
    FUNCTION get_death_data_folio(i_patient IN NUMBER) RETURN VARCHAR2 IS
        tbl_id   table_number;
        l_return VARCHAR2(4000);
        k_active CONSTANT VARCHAR2(0001 CHAR) := 'A';
    BEGIN
    
        SELECT id_death_registry
          BULK COLLECT
          INTO tbl_id
          FROM death_registry dr
          JOIN episode e
            ON e.id_episode = dr.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE v.id_patient = i_patient
           AND dr.flg_status = k_active
           AND dr.flg_type = k_flg_dr_type_patient;
    
        IF tbl_id.count > 0
        THEN
            l_return := get_death_data_folio_by_id(i_id_death_registry => tbl_id(1));
        END IF;
    
        RETURN l_return;
    
    END get_death_data_folio;

    -- ********************************
    FUNCTION get_death_data_inst_clues
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_clues_data  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT obj_name := 'GET_DEATH_DATA_INST_CLUES';
        l_dbg_msg      debug_msg;
        l_id_clues     NUMBER;
        l_id           NUMBER;
        l_tmp          NUMBER;
        l_entity       VARCHAR2(4000);
        l_municipio    VARCHAR2(4000);
        l_local        VARCHAR2(4000);
        l_jurisdiction VARCHAR2(4000);
        l_street       VARCHAR2(4000);
        l_colony       VARCHAR2(4000);
        --l_id_jurisdiction NUMBER(24);
        l_institution table_varchar;
        t_clues       t_coll_clues_inst_mx := t_coll_clues_inst_mx();
    
        tbl_desc table_varchar := table_varchar('', '', '', '', '', '', '', '', '', '');
        tbl_name table_varchar := table_varchar('DEATH_DATA_ADRRESS_NUMBER',
                                                'DEATH_DATA_ADRRESS_COLONY',
                                                'DEATH_DATA_ADRRESS_ENTITY',
                                                'DEATH_DATA_ADRRESS_MUNICIPY',
                                                'DEATH_DATA_ADRRESS_LOCATION',
                                                'DEATH_DATA_ADDRESS_JURISD',
                                                'DEATH_DATA_INSTITUTION',
                                                'DR_DEATH_KNOWN_ADDRESS',
                                                'DEATH_DATA_KNOWN_ADDRESS',
                                                'DEATH_DATA_ADRRESS_FEDERAL_ENTITY');
        l_address_tt       CONSTANT VARCHAR2(2 CHAR) := 'TT';
        l_sys_list_address CONSTANT sys_list_group.internal_name%TYPE := 'DR_KNOWN_ADDRESS_SLG';
        l_id_address sys_list.id_sys_list%TYPE;
        l_federal    VARCHAR2(10 CHAR) := '2004';
        l_settlement VARCHAR2(200 CHAR);
    BEGIN
    
        l_id_clues := pk_adt.get_clues_inst(i_lang => i_lang, i_prof => i_prof, i_id_institution => i_institution);
    
        t_clues := pk_adt_core.get_clues_inst_mx(i_lang => i_lang, i_prof => i_prof, i_id_clues => l_id_clues);
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          BULK COLLECT
          INTO l_institution
          FROM institution i
         WHERE i.id_institution = i_institution;
    
        IF t_clues.count > 0
        THEN
            l_settlement := pk_adt.get_settlement_type_desc(i_lang, i_prof, t_clues(1).id_type_settlement);
            l_id         := t_clues(1).id_rb_regional_classifier;
            l_street     := t_clues(1).street_type || ' ' || t_clues(1).residence || ' ' || t_clues(1).inside_number || ' ' || t_clues(1).numero_exterior;
            l_colony     := l_settlement || ' ' || t_clues(1).urbanization;
            --l_jurisdiction := t_clues(1).id_rb_reg_class_juris;
            tbl_desc(2) := l_colony;
            tbl_desc(1) := l_street;
        END IF;
    
        IF l_institution.count > 0
           AND l_id_clues <> -1
        THEN
            tbl_desc(7) := l_institution(1);
        END IF;
        IF l_id_clues NOT IN (-1, -2)
        THEN
            l_tmp := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_entidade);
            l_entity := to_char(l_tmp);
            tbl_desc(3) := pk_adt.get_regional_classifier_desc(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_id_rb_regional_classifier => l_tmp);
        
            l_tmp := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_municipio);
            l_municipio := to_char(l_tmp);
            tbl_desc(4) := pk_adt.get_regional_classifier_desc(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_id_rb_regional_classifier => l_tmp);
        
            l_tmp := pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id, i_rank => pk_adt.k_rank_localidade);
            l_local := to_char(pk_adt.get_rb_reg_classifier_id(i_rb_reg_class => l_id,
                                                               i_rank         => pk_adt.k_rank_localidade));
            tbl_desc(5) := pk_adt.get_regional_classifier_desc(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_id_rb_regional_classifier => l_tmp);
            tbl_desc(8) := pk_sys_list.get_sys_list_value_desc(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_grp_internal_name => l_sys_list_address,
                                                               i_flg_context       => l_address_tt);
            l_id_address := pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_grp_internal_name => l_sys_list_address,
                                                        i_flg_context       => l_address_tt);
        END IF;
        tbl_desc(10) := pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_id_option => l_federal);
    
        OPEN o_clues_data FOR
            SELECT tbl_desc(1) description, tbl_name(1) internal_name, l_street VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(2) description, tbl_name(2) internal_name, l_colony VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(3) description, tbl_name(3) internal_name, l_entity VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(4) description, tbl_name(4) internal_name, l_municipio VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(5) description, tbl_name(5) internal_name, l_local VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT NULL description, tbl_name(6) internal_name, NULL VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(7) description, tbl_name(7) internal_name, tbl_desc(7) VALUE, NULL alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(8) description,
                   tbl_name(8) internal_name,
                   to_char(l_id_address) VALUE,
                   l_address_tt alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(8) description,
                   tbl_name(9) internal_name,
                   to_char(l_id_address) VALUE,
                   l_address_tt alt_value
              FROM dual
            UNION ALL
            SELECT tbl_desc(10) description, tbl_name(10) internal_name, l_federal VALUE, NULL alt_value
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_clues_data);
            RETURN FALSE;
        
    END get_death_data_inst_clues;

    -- *************************************************************************
    FUNCTION get_diag_letter
    (
        i_type         IN VARCHAR2,
        i_id_diagnosis IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_letter table_varchar;
        l_return   VARCHAR2(0010 CHAR);
    BEGIN
    
        -- get diagnosis cat
        SELECT letra
          BULK COLLECT
          INTO tbl_letter
          FROM (SELECT letra
                  FROM cat_diagnosis cd
                  JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = cd.id_concept_term
                 WHERE ad.id_alert_diagnosis = i_id_diagnosis
                   AND i_type = k_alert_diagnosis
                UNION ALL
                SELECT letra
                  FROM cat_diagnosis cd
                  JOIN epis_diagnosis ed
                    ON ed.id_alert_diagnosis = cd.id_concept_term
                 WHERE ed.id_epis_diagnosis = i_id_diagnosis
                   AND i_type = k_epis_diagnosis) xsql;
    
        IF tbl_letter.count > 0
        THEN
            l_return := tbl_letter(1);
        END IF;
    
        RETURN l_return;
    
    END get_diag_letter;

    -- ******************************************************************
    FUNCTION map_mea_to_dt_type(i_id_mea IN NUMBER) RETURN VARCHAR2 IS
    
        tbl_mea table_number := tbl_unit_mea;
        --tbl_dtt  table_varchar := table_varchar('MINUTES', 'HOURS', 'DAYS', 'WEEKS', 'MONTHS', 'YEARS');
        tbl_dtt  table_varchar := tbl_age_type;
        l_return VARCHAR2(0010 CHAR);
    
    BEGIN
    
        <<lup_thru_mea>>
        FOR i IN 1 .. tbl_mea.count
        LOOP
            IF i_id_mea = tbl_mea(i)
            THEN
                l_return := tbl_dtt(i);
                EXIT lup_thru_mea;
            END IF;
        END LOOP lup_thru_mea;
    
        RETURN l_return;
    
    END map_mea_to_dt_type;

    -- ****************************************************
    FUNCTION get_component_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER
    ) RETURN VARCHAR2 IS
        l_text   VARCHAR2(4000);
        tbl_text table_varchar;
    BEGIN
    
        RETURN pk_dynamic_screen.get_component_desc(i_lang, i_ds_component);
    
    END get_component_desc;

    -- *******************************************************
    FUNCTION get_parent_id
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER,
        i_section      IN VARCHAR2,
        i_type         IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_id     NUMBER;
        l_id_mkt NUMBER;
    BEGIN
        SELECT dc.id_ds_component_parent, dc.id_ds_cmpt_mkt_rel
          INTO l_id, l_id_mkt
          FROM ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_component_child = i_ds_component
        CONNECT BY PRIOR dc.id_ds_component_child = dc.id_ds_component_parent
         START WITH internal_name_parent = i_section;
    
        IF i_type = 'R'
        THEN
            RETURN l_id_mkt;
        ELSE
            RETURN l_id;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_parent_id;

    --***********************************************
    FUNCTION get_component_by_target
    (
        i_lang       IN NUMBER,
        i_ds_mkt_rel IN NUMBER
    ) RETURN NUMBER IS
        l_id_cmp ds_component.id_ds_component%TYPE;
    BEGIN
        SELECT dcmr.id_ds_component_child
          INTO l_id_cmp
          FROM ds_event_target det
          JOIN ds_event de
            ON det.id_ds_event = de.id_ds_event
          JOIN ds_cmpt_mkt_rel dcmr
            ON de.id_ds_cmpt_mkt_rel = dcmr.id_ds_cmpt_mkt_rel
         WHERE det.id_ds_cmpt_mkt_rel = i_ds_mkt_rel
           AND rownum = 1;
    
        RETURN l_id_cmp;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_component_by_target;

    -- *************************************************
    FUNCTION get_desc_component
    (
        i_lang IN NUMBER,
        i_tbl  IN table_number
    ) RETURN table_varchar IS
        tbl_text table_varchar;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, code_ds_component) xdesc
          BULK COLLECT
          INTO tbl_text
          FROM ds_component d
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
                 column_value id_ds_component
                  FROM TABLE(i_tbl) t) xsql
            ON xsql.id_ds_component = d.id_ds_component;
    
        RETURN tbl_text;
    
    END get_desc_component;

    -- *************************************************
    FUNCTION get_component_parent_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER,
        i_section      IN VARCHAR2,
        i_level        IN VARCHAR2 DEFAULT 1
    ) RETURN VARCHAR2 IS
        l_text         VARCHAR2(4000);
        tbl_text       table_varchar;
        l_tbl          table_number := table_number();
        l_id_component NUMBER;
    BEGIN
    
        l_tbl.extend(i_level);
        l_id_component := i_ds_component;
        FOR i IN 1 .. i_level
        LOOP
            l_tbl(i) := get_parent_id(i_lang, l_id_component, i_section);
            l_id_component := l_tbl(i);
        END LOOP;
    
        tbl_text := get_desc_component(i_lang => i_lang, i_tbl => l_tbl);
        l_text   := pk_utils.concat_table(tbl_text, xsp);
    
        RETURN l_text;
    
    END get_component_parent_desc;

    -- ******************************************************
    FUNCTION get_component_target_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER,
        i_section      IN VARCHAR2,
        i_level        IN NUMBER DEFAULT 1
    ) RETURN VARCHAR2 IS
        l_text         VARCHAR2(4000);
        tbl_text       table_varchar;
        l_tbl          table_number := table_number();
        l_id_mkt       NUMBER;
        l_id_component NUMBER;
    BEGIN
    
        l_tbl.extend(i_level);
        l_id_component := i_ds_component;
        FOR i IN 1 .. i_level
        LOOP
            l_id_mkt := get_parent_id(i_lang, l_id_component, i_section, 'R');
            l_tbl(i) := get_component_by_target(i_lang, l_id_mkt);
            l_id_component := l_tbl(i);
        END LOOP;
    
        tbl_text := get_desc_component(i_lang => i_lang, i_tbl => l_tbl);
        l_text   := pk_utils.concat_table(tbl_text, ' ');
    
        RETURN l_text;
    
    END get_component_target_desc;

    -- ******************************************************
    FUNCTION get_diag_text
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_ds_component    IN NUMBER,
        i_alert_diagnosis IN NUMBER
    ) RETURN VARCHAR2 IS
        l_text      VARCHAR2(4000);
        l_diag_text VARCHAR2(4000);
    BEGIN
        l_diag_text := pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => i_alert_diagnosis,
                                                  i_id_diagnosis        => NULL,
                                                  i_desc_epis_diagnosis => NULL,
                                                  i_code                => NULL,
                                                  i_flg_other           => NULL,
                                                  i_flg_std_diag        => NULL,
                                                  i_epis_diag           => NULL,
                                                  i_flg_search_mode     => k_no);
    
        l_text := l_diag_text;
    
        RETURN l_text;
    
    END get_diag_text;

    -- **************************************************
    FUNCTION get_dr_det_info
    (
        i_id_dr     IN NUMBER,
        i_comp_name IN VARCHAR2
    ) RETURN death_registry_det%ROWTYPE IS
        xdrd death_registry_det%ROWTYPE;
    BEGIN
    
        SELECT drd.*
          INTO xdrd
          FROM death_registry_det drd
          JOIN ds_component ds
            ON ds.id_ds_component = drd.id_ds_component
         WHERE drd.id_death_registry = i_id_dr
           AND ds.internal_name = i_comp_name;
    
        RETURN xdrd;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_dr_det_info;

    -- **************************************************
    FUNCTION get_dr_info(i_id_dr IN NUMBER) RETURN death_registry%ROWTYPE IS
        xdr death_registry%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xdr
          FROM death_registry
         WHERE id_death_registry = i_id_dr;
    
        RETURN xdr;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_dr_info;

    -- *****************************************************
    FUNCTION check_diag_no_cbd
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
    
        k_code_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_028';
        xdrd death_registry_det%ROWTYPE;
        k_idx_min    CONSTANT NUMBER := 2;
        k_idx_max    CONSTANT NUMBER := 7;
        k_good_letra CONSTANT VARCHAR2(0010 CHAR) := 'P';
        l_letter VARCHAR2(0010 CHAR);
        l_idx    NUMBER;
    
        l_mea_type     VARCHAR2(0010 CHAR);
        l_type         VARCHAR2(0050 CHAR);
        l_id_diagnosis NUMBER;
        l_age          NUMBER;
        l_diag_text    VARCHAR2(4000);
        l_anomaly      VARCHAR2(4000);
    
        CURSOR cur_dc IS
            SELECT x.*
              FROM death_cause x
             WHERE x.id_death_registry = i_id_dr
               AND x.death_cause_rank = 1;
        xpat patient%ROWTYPE;
    
        -- *************************************************************************
        FUNCTION is_no_cbd
        (
            i_type         IN VARCHAR2,
            i_id_diagnosis IN NUMBER
        ) RETURN VARCHAR2 IS
            tbl_no_cbd table_varchar;
            l_count    NUMBER;
            l_return   VARCHAR2(0010 CHAR) := pk_alert_constant.g_no;
            k_no_cbd CONSTANT VARCHAR2(0010 CHAR) := 'SI';
        BEGIN
        
            -- get diagnosis cat
            SELECT COUNT(1)
              INTO l_count
              FROM (SELECT no_cbd
                      FROM cat_diagnosis cd
                      JOIN alert_diagnosis ad
                        ON ad.id_alert_diagnosis = cd.id_concept_term
                     WHERE ad.id_alert_diagnosis = i_id_diagnosis
                       AND i_type = k_alert_diagnosis
                       AND no_cbd = k_no_cbd
                    UNION ALL
                    SELECT no_cbd
                      FROM cat_diagnosis cd
                      JOIN epis_diagnosis ed
                        ON ed.id_alert_diagnosis = cd.id_concept_term
                     WHERE ed.id_epis_diagnosis = i_id_diagnosis
                       AND i_type = k_epis_diagnosis
                       AND no_cbd = k_no_cbd) xsql;
        
            IF l_count > 0
            THEN
                l_return := pk_alert_constant.g_yes;
            END IF;
        
            RETURN l_return;
        
        END is_no_cbd;
    BEGIN
    
        <<lup_thru_causes>>
        FOR cur IN cur_dc
        LOOP
        
            l_idx := cur.death_cause_rank;
        
            -- MRK04
            IF cur.id_epis_diagnosis != -1
            THEN
                l_id_diagnosis := cur.id_epis_diagnosis;
                l_type         := k_epis_diagnosis;
            ELSE
                l_id_diagnosis := cur.id_alert_diagnosis;
                l_type         := k_alert_diagnosis;
            END IF; -- MRK04
        
            IF is_no_cbd(i_type => l_type, i_id_diagnosis => l_id_diagnosis) = pk_alert_constant.g_yes
            THEN
            
                -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                IF l_type = k_alert_diagnosis
                THEN
                
                    l_diag_text := get_diag_text(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_ds_component    => NULL,
                                                 i_alert_diagnosis => l_id_diagnosis);
                ELSE
                    l_diag_text := get_epis_diagnosis_desc(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_epis_diagnosis     => cur.id_epis_diagnosis,
                                                           i_id_diagnosis       => cur.id_diagnosis,
                                                           i_id_alert_diagnosis => cur.id_alert_diagnosis);
                END IF;
                l_anomaly := pk_message.get_message(i_lang, k_code_msg);
                l_anomaly := REPLACE(l_anomaly, '@1', l_diag_text);
                register_anomaly(l_anomaly);
            
            END IF; -- MRK01
        
        END LOOP lup_thru_causes;
    
        RETURN TRUE;
    
    END check_diag_no_cbd;

    -- *****************************************************
    FUNCTION check_diag_p
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
    
        k_code_msg   CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_011';
        k_code_msg_d CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_031';
        xdrd death_registry_det%ROWTYPE;
        k_idx_min    CONSTANT NUMBER := 2;
        k_idx_max    CONSTANT NUMBER := 7;
        k_good_letra CONSTANT VARCHAR2(0010 CHAR) := 'P';
        l_letter VARCHAR2(0010 CHAR);
        l_idx    NUMBER;
    
        l_mea_type     VARCHAR2(0010 CHAR);
        l_type         VARCHAR2(0050 CHAR);
        l_id_diagnosis NUMBER;
        l_age          NUMBER;
        l_diag_text    VARCHAR2(4000);
        l_anomaly      VARCHAR2(4000);
        l_code_msg     VARCHAR2(0100 CHAR);
    
        tbl_comp table_varchar := table_varchar('',
                                                'DEATH_DATA_TIME_ILLNESS1',
                                                'DEATH_DATA_TIME_ILLNESS2',
                                                'DEATH_DATA_TIME_ILLNESS3',
                                                'DEATH_DATA_TIME_ILLNESS4',
                                                'DEATH_DATA_TIME_ILLNESS5',
                                                'DEATH_DATA_TIME_ILLNESS6',
                                                'DS_DEATH_DATA_TIME_ILLNESS7', ---
                                                'DS_DEATH_DATA_TIME_ILLNESS8', ---
                                                'DS_DEATH_DATA_TIME_ILLNESS9', ---
                                                'DS_DEATH_DATA_TIME_ILLNESS10', ---
                                                'DS_DEATH_DATA_TIME_ILLNESS11', ---
                                                'DS_DEATH_DATA_TIME_ILLNESS12' ---
                                                );
    
        CURSOR cur_dc IS
            SELECT x.*
              FROM death_cause x
             WHERE x.id_death_registry = i_id_dr;
        xpat patient%ROWTYPE;
        xrow death_registry%ROWTYPE;
    
        CURSOR c_diagnosis(i_diag IN concept_term.id_concept_term%TYPE) IS
            SELECT d.age_min, d.age_max, c.lsup, c.linf
              FROM diagnosis_ea d
              JOIN cat_diagnosis c
                ON d.id_concept_term = c.id_concept_term
             WHERE d.id_concept_term = i_diag;
        r_diagnosis    c_diagnosis%ROWTYPE;
        l_age_type     VARCHAR2(2 CHAR);
        l_age_year     NUMBER;
        l_age_months   NUMBER;
        l_show_warning VARCHAR2(1 CHAR);
        l_ageinterval  NUMBER;
    
        FUNCTION get_pat_age_interval
        (
            i_dt_death      IN TIMESTAMP WITH LOCAL TIME ZONE,
            i_dt_birth_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
            i_value         IN NUMBER,
            i_type          IN VARCHAR2,
            i_type_pat_age  IN VARCHAR2 DEFAULT 'YEARS'
        ) RETURN NUMBER IS
            l_date   TIMESTAMP WITH LOCAL TIME ZONE;
            l_ageaux NUMBER;
        BEGIN
        
            IF i_value IS NOT NULL
            THEN
                --table_varchar('YEARS', 'MONTHS', 'WEEKS', 'DAYS', 'HOURS', 'MINUTES');
                IF i_type IN ('HOURS', 'MINUTES')
                THEN
                    l_date := i_dt_death;
                ELSIF i_type = 'DAYS'
                THEN
                    l_date := pk_date_utils.add_to_ltstz(i_dt_death, i_amount => -i_value, i_unit => 'DAY');
                ELSIF i_type = 'WEEKS'
                THEN
                    l_date := pk_date_utils.add_to_ltstz(i_dt_death, i_amount => - (i_value * 7), i_unit => 'DAY');
                ELSIF i_type = 'MONTHS'
                THEN
                    l_date := pk_date_utils.add_to_ltstz(i_dt_death, i_amount => -i_value, i_unit => 'MONTH');
                ELSIF i_type = 'YEARS'
                THEN
                    l_date := pk_date_utils.add_to_ltstz(i_dt_death, i_amount => -i_value, i_unit => 'YEAR');
                END IF;
            ELSE
                l_date := i_dt_death;
            END IF;
        
            l_ageaux := pk_patient.get_pat_age(i_lang       => i_lang,
                                               i_dt_start   => i_dt_birth_tstz,
                                               i_dt_end     => l_date,
                                               i_age_format => i_type_pat_age);
            RETURN l_ageaux;
        END get_pat_age_interval;
    
    BEGIN
        --TODO: necessário rever esta função.. as validações estão fixas
        xrow := get_death_registry_row(i_death_registry => i_id_dr);
        SELECT *
          INTO xpat
          FROM patient x
         WHERE x.id_patient = i_patient;
    
        l_age_type   := pk_patient.get_pat_age_type(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
        l_age_year   := pk_patient.get_pat_age(i_lang       => i_lang,
                                               i_dt_start   => xpat.dt_birth_tstz,
                                               i_dt_end     => xrow.dt_death,
                                               i_age_format => 'YEARS');
        l_age_months := pk_patient.get_pat_age(i_lang       => i_lang,
                                               i_dt_start   => xpat.dt_birth_tstz,
                                               i_dt_end     => xrow.dt_death,
                                               i_age_format => 'MONTHS');
        <<lup_thru_causes>>
        FOR cur IN cur_dc
        LOOP
        
            l_idx := cur.death_cause_rank;
        
            -- MRK04
            IF cur.id_epis_diagnosis != -1
            THEN
                l_id_diagnosis := cur.id_epis_diagnosis;
                l_type         := k_epis_diagnosis;
            ELSE
                l_id_diagnosis := cur.id_alert_diagnosis;
                l_type         := k_alert_diagnosis;
            END IF; -- MRK04
        
            l_letter := get_diag_letter(i_type => l_type, i_id_diagnosis => l_id_diagnosis);
        
            -- get value of age
            xdrd := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(l_idx));
        
            l_mea_type := map_mea_to_dt_type(i_id_mea => xdrd.unit_measure_value);
            --l_mea_type := map_dt_type_2_abr(l_mea_type);
        
            l_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                            i_dt_start   => xpat.dt_birth_tstz,
                                            i_dt_end     => xrow.dt_death,
                                            i_age_format => l_mea_type);
        
            -- MRK03
            OPEN c_diagnosis(cur.id_alert_diagnosis);
            FETCH c_diagnosis
                INTO r_diagnosis;
            CLOSE c_diagnosis;
            IF l_type = k_alert_diagnosis
            THEN
            
                l_diag_text := get_diag_text(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_ds_component    => xdrd.id_ds_component,
                                             i_alert_diagnosis => l_id_diagnosis);
            ELSE
                l_diag_text := get_epis_diagnosis_desc(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_epis_diagnosis     => cur.id_epis_diagnosis,
                                                       i_id_diagnosis       => cur.id_diagnosis,
                                                       i_id_alert_diagnosis => cur.id_alert_diagnosis);
            END IF;
            -- MRK01
            IF l_letter = k_good_letra
               AND l_idx BETWEEN k_idx_min AND k_idx_max
            THEN
            
                --    IF l_age != xdrd.value_n
                IF (l_age != xdrd.value_n AND l_mea_type = 'YEARS' AND l_age_type = 'Y')
                
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF ((l_age - xdrd.value_n) > 11 AND l_mea_type = 'MONTHS' AND l_age_type = 'Y' AND
                      r_diagnosis.lsup <> '027D')
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'Y'
                      AND r_diagnosis.lsup = '027D'
                      AND l_mea_type <> 'YEARS'
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'MI'
                      AND l_age < xdrd.value_n
                      AND l_mea_type <> 'MINUTES'
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'H'
                      AND l_age < xdrd.value_n
                      AND l_mea_type IN ('HOURS', 'MINUTES')
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'D'
                      AND l_age < xdrd.value_n
                      AND l_mea_type NOT IN ('DAYS', 'HOURS', 'MINUTES')
                      AND r_diagnosis.lsup <> '027D'
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'D'
                      AND r_diagnosis.lsup = '027D'
                THEN
                    IF l_mea_type = 'DAYS'
                       AND (l_age - xdrd.value_n) > 27
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    ELSIF l_mea_type IN ('HOURS', 'MINUTES')
                          AND l_age > 27
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                ELSIF l_age_type = 'M'
                      AND l_age < xdrd.value_n
                      AND l_mea_type NOT IN ('DAYS', 'HOURS', 'MINUTES', 'MINUTES')
                      AND r_diagnosis.lsup <> '027D'
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'Y'
                      AND r_diagnosis.lsup = '027D'
                      AND l_mea_type = 'DAYS'
                      AND (l_age - xdrd.value_n) > 27
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                ELSIF l_age_type = 'Y'
                      AND r_diagnosis.lsup <> '027D'
                      AND l_mea_type IN ('DAYS', 'HOURS', 'MINUTES')
                THEN
                    l_show_warning := pk_alert_constant.g_yes;
                END IF; -- MRK03
                l_code_msg := k_code_msg;
            ELSE
                l_code_msg := k_code_msg_d;
                -- other type of diagnosis diferent from P
                IF l_age_type = 'Y'
                   AND (r_diagnosis.age_min IS NOT NULL OR r_diagnosis.age_max IS NOT NULL)
                   AND r_diagnosis.lsup <> '027D'
                THEN
                    -- l_age_year between r_diagnosis.age_min
                    IF l_age_year > nvl(r_diagnosis.age_max, 999)
                       AND xdrd.value_n IS NULL -- NOT BETWEEN nvl(r_diagnosis.age_min, 0) AND nvl(r_diagnosis.age_max, 999)
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    
                    ELSE
                        l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                              i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                              i_value         => xdrd.value_n,
                                                              i_type          => l_mea_type);
                        IF l_ageinterval NOT BETWEEN nvl(r_diagnosis.age_min, 0) AND nvl(r_diagnosis.age_max, 999)
                        THEN
                            l_show_warning := pk_alert_constant.g_yes;
                        END IF;
                    
                    END IF;
                END IF;
                IF r_diagnosis.lsup = '027D'
                   AND l_show_warning = pk_alert_constant.g_no
                THEN
                    l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                          i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                          i_value         => xdrd.value_n,
                                                          i_type          => l_mea_type,
                                                          i_type_pat_age  => 'DAYS');
                
                    IF l_ageinterval > 27
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                ELSIF r_diagnosis.lsup = '011M'
                      AND l_show_warning = pk_alert_constant.g_no
                THEN
                    l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                          i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                          i_value         => xdrd.value_n,
                                                          i_type          => l_mea_type,
                                                          i_type_pat_age  => 'MONTHS');
                
                    IF l_ageinterval > 11
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                ELSIF r_diagnosis.linf = '006M'
                      AND l_show_warning = pk_alert_constant.g_no
                THEN
                    l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                          i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                          i_value         => xdrd.value_n,
                                                          i_type          => l_mea_type,
                                                          i_type_pat_age  => 'MONTHS');
                
                    IF l_ageinterval < 6
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                ELSIF r_diagnosis.linf = '002M'
                      AND l_show_warning = pk_alert_constant.g_no
                THEN
                    l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                          i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                          i_value         => xdrd.value_n,
                                                          i_type          => l_mea_type,
                                                          i_type_pat_age  => 'MONTHS');
                
                    IF l_ageinterval < 2
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                ELSIF r_diagnosis.linf = '028D'
                      AND l_show_warning = pk_alert_constant.g_no
                THEN
                    l_ageinterval := get_pat_age_interval(i_dt_death      => xrow.dt_death,
                                                          i_dt_birth_tstz => xpat.dt_birth_tstz,
                                                          i_value         => xdrd.value_n,
                                                          i_type          => l_mea_type,
                                                          i_type_pat_age  => 'DAYS');
                
                    IF l_ageinterval < 28
                    THEN
                        l_show_warning := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            
            END IF; -- MRK01
            IF l_show_warning = pk_alert_constant.g_yes
            THEN
                l_anomaly := pk_message.get_message(i_lang, l_code_msg);
                l_anomaly := REPLACE(l_anomaly, '@1', l_diag_text);
                register_anomaly(l_anomaly);
            END IF;
            l_show_warning := pk_alert_constant.g_no;
        END LOOP lup_thru_causes;
    
        RETURN TRUE;
    
    END check_diag_p;

    -- ******************************************
    FUNCTION check_causes
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
        --xdr  death_registry%ROWTYPE;
        k_code_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_018';
        xdrd      death_registry_det%ROWTYPE;
        xdrd_type death_registry_det%ROWTYPE;
        l_parent  VARCHAR2(200 CHAR);
        l_anomaly VARCHAR2(4000);
        l_compare VARCHAR2(4000);
    
        tbl_comp_type table_varchar := table_varchar('DEATH_FETAL_CAUSES_TYPE_1',
                                                     'DEATH_FETAL_CAUSES_TYPE_2',
                                                     'DEATH_FETAL_CAUSES_TYPE_3',
                                                     'DEATH_FETAL_CAUSES_TYPE_4',
                                                     'DEATH_FETAL_CAUSES_TYPE_5',
                                                     'DEATH_FETAL_CAUSES_TYPE_6');
    
        tbl_comp_desc table_varchar := table_varchar('DEATH_DATA_CAUSE_DESC_1',
                                                     'DEATH_DATA_CAUSE_DESC_2',
                                                     'DEATH_DATA_CAUSE_DESC_3',
                                                     'DEATH_DATA_CAUSE_DESC_4',
                                                     'DEATH_DATA_CAUSE_DESC_5',
                                                     'DEATH_DATA_CAUSE_DESC_6');
    
        tbl_comp_code table_varchar := table_varchar('UNDERLYING_CAUSE_1',
                                                     'UNDERLYING_CAUSE_2',
                                                     'UNDERLYING_CAUSE_3',
                                                     'DEATH_DATA_ADDITIONAL_CAUSE_1',
                                                     'DEATH_DATA_ADDITIONAL_CAUSE_2',
                                                     'DEATH_DATA_CAUSE_6');
    
        CURSOR cur_dc(i_rank NUMBER) IS
            SELECT to_char(x.id_diagnosis)
              FROM death_cause x
             WHERE x.id_death_registry = i_id_dr
               AND death_cause_rank = i_rank;
        --xpat        patient%ROWTYPE;
        l_diagnosis VARCHAR2(20 CHAR);
    BEGIN
    
        --xdr := get_dr_info(i_id_dr => i_id_dr);
    
        <<lup_thru_causes>>
        FOR l_idx IN tbl_comp_code.first .. tbl_comp_code.last
        LOOP
            l_diagnosis := NULL;
            OPEN cur_dc(l_idx + 1);
            FETCH cur_dc
                INTO l_diagnosis;
            CLOSE cur_dc;
        
            xdrd      := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp_desc(l_idx));
            xdrd_type := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp_type(l_idx));
            l_compare := coalesce(l_diagnosis, xdrd.value_vc2, to_char(xdrd_type.value_n));
            IF l_compare IS NOT NULL
            THEN
                IF l_diagnosis IS NULL
                   OR xdrd.value_vc2 IS NULL
                   OR xdrd_type.value_n IS NULL
                THEN
                    l_parent := get_component_parent_desc(i_lang, xdrd.id_ds_component, c_ds_death_data_fetal, 2);
                
                    l_anomaly := pk_message.get_message(i_lang, k_code_msg);
                    l_anomaly := REPLACE(l_anomaly, '%1', l_parent);
                    register_anomaly(l_anomaly);
                END IF;
            END IF;
        
        END LOOP lup_thru_causes;
    
        RETURN TRUE;
    
    END check_causes;

    -- ***************************************************************
    FUNCTION check_mandatory_folio
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
    
        tbl_comp table_varchar := table_varchar('DEATH_DATA_FOLIO_BIRTH');
        k_year        CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_limit_value CONSTANT NUMBER := 1;
        l_age                NUMBER;
        l_field_is_mandatory BOOLEAN := FALSE;
    
        xdrd          death_registry_det%ROWTYPE;
        l_datatype    VARCHAR2(0020 CHAR);
        k_code_msg_02 VARCHAR2(0100 CHAR) := 'DR_NORM024_002';
        k_code_msg_12 VARCHAR2(0100 CHAR) := 'DR_NORM024_012';
        l_anomaly     VARCHAR2(1000 CHAR);
        l_len         NUMBER;
    
    BEGIN
    
        -- RULE:  Folio de nacimiento should be mandatory for patients under 1 year
    
        -- get age of patient
        l_age := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_type    => k_year);
    
        l_field_is_mandatory := l_age < k_limit_value;
        xdrd                 := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(1));
    
        IF l_field_is_mandatory
        THEN
        
            l_datatype := pk_death_registry.get_datatype(xdrd.id_ds_component);
        
            IF l_datatype = k_dtype_v
            THEN
            
                IF xdrd.value_vc2 IS NULL
                THEN
                
                    -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                    l_anomaly := pk_message.get_message(i_lang, k_code_msg_02);
                    register_anomaly(l_anomaly);
                END IF;
            
            END IF;
        
        END IF;
    
        l_len := length(nvl(xdrd.value_vc2, ''));
        IF l_len != 9
        THEN
            -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
            l_anomaly := pk_message.get_message(i_lang, k_code_msg_12);
            register_anomaly(l_anomaly);
        END IF;
    
        RETURN TRUE;
    
    END check_mandatory_folio;

    /**********************************************************************************************
    * This function validates if the selected death_cause is valid according to patient age
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   profissional
    * @param        i_patient                Patient ID
    * @param
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Elisabete Bugalho
    * @version      2.7.0.1 - NOM024
    * @since        28/07/2017
    **********************************************************************************************/

    FUNCTION check_valid_death_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN epis_diagnosis.id_patient%TYPE,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN epis_diagnosis.id_alert_diagnosis%TYPE,
        i_component          IN ds_component.internal_name%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_age             NUMBER;
        l_check_diagnosis sys_config.value%TYPE;
        l_invalid_age     table_number := table_number(9, 55, 56, 57, 58, 59);
        l_index           NUMBER;
        l_error           VARCHAR2(200 CHAR);
        l_diag_type       VARCHAR2(1 CHAR);
    BEGIN
    
        l_error           := 'GET CONFIG DEATH_REGISTRY_DIAGNOSIS_VALIDATION';
        l_check_diagnosis := pk_sysconfig.get_config('DEATH_REGISTRY_DIAGNOSIS_VALIDATION', i_prof);
    
        IF l_check_diagnosis = pk_alert_constant.g_yes
           AND i_component = 'DIRECT_CAUSE' --'DEATH_DATA_CAUSE_BASIC'
        THEN
            l_error := 'GET PATIENT AGE';
            l_age   := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_patient => i_patient,
                                                  i_type    => 'Y');
            IF l_age IS NOT NULL
            THEN
                l_index := pk_utils.search_table_number(l_invalid_age, i_search => l_age);
            
                IF l_index <> -1
                THEN
                    SELECT letra
                      INTO l_diag_type
                      FROM cat_diagnosis c
                     WHERE c.id_concept_term = i_id_alert_diagnosis;
                    IF l_diag_type = 'O'
                    THEN
                        o_flg_show := pk_alert_constant.g_yes;
                        o_msg      := pk_message.get_message(i_lang, 'DEATH_REGISTRY_M002');
                    END IF;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              l_error,
                                              '',
                                              'ALERT',
                                              c_package_name,
                                              'CHECK_VALID_DEATH_DIAGNOSIS',
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_valid_death_diagnosis;

    FUNCTION check_range_death_diag1
    (
        i_lang  IN NUMBER,
        i_id_dr IN NUMBER
    ) RETURN BOOLEAN IS
        xdrd  death_registry_det%ROWTYPE;
        l_idx NUMBER;
        k_idx_min CONSTANT NUMBER := 2;
        k_idx_max CONSTANT NUMBER := 7;
        l_bool         BOOLEAN := TRUE;
        l_mea_type     VARCHAR2(0010 CHAR);
        l_type         VARCHAR2(0050 CHAR);
        l_id_diagnosis NUMBER;
        l_msg          VARCHAR2(0100 CHAR);
        l_anomaly      VARCHAR2(4000);
    
        tbl_comp table_varchar := table_varchar('',
                                                'DEATH_TIPO_DT_DEFUNCION',
                                                'DEATH_TIPO_DT_DEFUNCION_2',
                                                'DEATH_TIPO_DT_DEFUNCION_3',
                                                'DEATH_TIPO_DT_DEFUNCION_4',
                                                'DEATH_TIPO_DT_DEFUNCION_5',
                                                'DEATH_TIPO_DT_DEFUNCION_6');
    
        CURSOR cur_dc(i_id_dr IN NUMBER) IS
            SELECT x.*
              FROM death_cause x
             WHERE x.id_death_registry = i_id_dr
             ORDER BY x.death_cause_rank;
    
    BEGIN
    
        --xdr := get_dr_info(i_id_dr => i_id_dr);
    
        <<lup_thru_causes>>
        FOR cur IN cur_dc(i_id_dr)
        LOOP
        
            l_idx := cur.death_cause_rank;
        
            -- MRK04
            IF cur.id_epis_diagnosis = -1
            THEN
                l_id_diagnosis := cur.id_alert_diagnosis;
                l_type         := k_alert_diagnosis;
            ELSE
                l_id_diagnosis := cur.id_epis_diagnosis;
                l_type         := k_epis_diagnosis;
            END IF; -- MRK04
        
            -- MRK02
            IF l_idx BETWEEN k_idx_min AND k_idx_max
            THEN
            
                -- get value of age
                xdrd := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(l_idx));
            
                l_mea_type := map_mea_to_dt_type(i_id_mea => xdrd.unit_measure_value);
            
                CASE l_mea_type
                    WHEN 'MI' THEN
                        l_msg  := 'DR_NORM024_003';
                        l_bool := xdrd.value_n BETWEEN 1 AND 59;
                    WHEN 'H' THEN
                        l_msg  := 'DR_NORM024_004';
                        l_bool := xdrd.value_n BETWEEN 1 AND 23;
                    WHEN 'D' THEN
                        l_msg  := 'DR_NORM024_005';
                        l_bool := xdrd.value_n BETWEEN 1 AND 29;
                    WHEN 'W' THEN
                        l_msg  := 'DR_NORM024_006';
                        l_bool := xdrd.value_n BETWEEN 1 AND 6;
                    WHEN 'M' THEN
                        l_msg  := 'DR_NORM024_007';
                        l_bool := xdrd.value_n BETWEEN 1 AND 11;
                    WHEN 'Y' THEN
                        l_msg  := 'DR_NORM024_008';
                        l_bool := xdrd.value_n BETWEEN 1 AND 130;
                    ELSE
                        l_bool := TRUE;
                END CASE;
            
                -- MRK03
                IF NOT l_bool
                THEN
                    -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                    l_anomaly := get_component_desc(i_lang => i_lang, i_ds_component => xdrd.id_ds_component);
                    l_anomaly := l_anomaly || xsp || pk_message.get_message(i_lang, l_msg);
                
                    register_anomaly(l_anomaly);
                END IF; -- MRK03
            
            END IF; -- MRK02
        
        END LOOP lup_thru_causes;
    
        RETURN TRUE;
    
    END check_range_death_diag1;

    -- ********************************************************************************************************
    FUNCTION check_range_death_diag
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
    
        l_age      NUMBER;
        xpat       patient%ROWTYPE;
        l_bool     BOOLEAN := TRUE;
        l_mea_type VARCHAR2(0010 CHAR);
        l_msg      VARCHAR2(0100 CHAR);
        l_anomaly  VARCHAR2(4000);
    
        tbl_comp table_varchar := table_varchar('DEATH_DATA_TIME_ILLNESS1',
                                                'DEATH_DATA_TIME_ILLNESS2',
                                                'DEATH_DATA_TIME_ILLNESS3',
                                                'DEATH_DATA_TIME_ILLNESS4',
                                                'DEATH_DATA_TIME_ILLNESS5',
                                                'DEATH_DATA_TIME_ILLNESS6');
    
        CURSOR cur_dc(i_id_dr IN NUMBER) IS
            SELECT x.*, dr.dt_death
              FROM death_registry_det x
              JOIN ds_component d
                ON d.id_ds_component = x.id_ds_component
              JOIN death_registry dr
                ON x.id_death_registry = dr.id_death_registry
             WHERE x.id_death_registry = i_id_dr
               AND d.internal_name IN (SELECT column_value comp_name
                                         FROM TABLE(tbl_comp) xtbl);
    
    BEGIN
    
        SELECT *
          INTO xpat
          FROM patient
         WHERE id_patient = i_patient;
    
        <<lup_thru_intervals>>
        FOR xdrd IN cur_dc(i_id_dr)
        LOOP
        
            l_mea_type := map_mea_to_dt_type(i_id_mea => xdrd.unit_measure_value);
        
            l_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                            i_dt_start   => xpat.dt_birth,
                                            i_dt_end     => nvl(xpat.dt_deceased, xdrd.dt_death),
                                            i_age_format => l_mea_type);
        
            CASE l_mea_type
                WHEN tbl_age_type(6) THEN
                    --'MI' THEN
                    l_msg  := 'DR_NORM024_003';
                    l_bool := xdrd.value_n BETWEEN 1 AND 59;
                WHEN tbl_age_type(5) THEN
                    -- --'H' THEN
                    l_msg  := 'DR_NORM024_004';
                    l_bool := xdrd.value_n BETWEEN 1 AND 23;
                WHEN tbl_age_type(4) THEN
                    --'D' THEN
                    l_msg  := 'DR_NORM024_005';
                    l_bool := xdrd.value_n BETWEEN 1 AND 29;
                WHEN tbl_age_type(3) THEN
                    --'W' THEN
                    l_msg  := 'DR_NORM024_006';
                    l_bool := xdrd.value_n BETWEEN 1 AND 6;
                WHEN tbl_age_type(2) THEN
                    -- M
                    l_msg  := 'DR_NORM024_007';
                    l_bool := xdrd.value_n BETWEEN 1 AND 11;
                WHEN tbl_age_type(1) THEN
                    -- Y
                    l_msg  := 'DR_NORM024_008';
                    l_bool := xdrd.value_n BETWEEN 1 AND 130;
                ELSE
                    l_bool := TRUE;
            END CASE;
        
            -- MRK03
            IF NOT l_bool
            THEN
                -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                l_anomaly := pk_message.get_message(i_lang, l_msg);
            
                register_anomaly(l_anomaly);
            END IF; -- MRK03
        
            IF xdrd.value_n > l_age
            THEN
            
                -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                l_anomaly := get_component_desc(i_lang => i_lang, i_ds_component => xdrd.id_ds_component);
                l_anomaly := l_anomaly || xsp || pk_message.get_message(i_lang, 'DR_NORM024_009');
            
                register_anomaly(l_anomaly);
            
            END IF;
        END LOOP lup_thru_causes;
    
        RETURN TRUE;
    
    END check_range_death_diag;

    -- ********************************************************************************************************
    FUNCTION check_over_under_base
    (
        i_value      IN NUMBER,
        i_tbl_option IN table_number
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := i_value MEMBER OF i_tbl_option;
    
        RETURN(NOT l_bool);
    
    END check_over_under_base;
    -- **********************************************************
    FUNCTION check_over_80(i_value IN NUMBER) RETURN BOOLEAN IS
        tbl_option table_number := table_number(32);
    BEGIN
    
        RETURN check_over_under_base(i_value => i_value, i_tbl_option => tbl_option);
    
    END check_over_80;

    -- **********************************************************
    FUNCTION check_over_90(i_value IN NUMBER) RETURN BOOLEAN IS
        tbl_option table_number := table_number(32, 30);
    BEGIN
    
        RETURN check_over_under_base(i_value => i_value, i_tbl_option => tbl_option);
    
    END check_over_90;

    -- **********************************************************
    FUNCTION check_under_10(i_value IN NUMBER) RETURN BOOLEAN IS
        tbl_option table_number := table_number(27, 28, 29, 33, 39);
    BEGIN
    
        RETURN check_over_under_base(i_value => i_value, i_tbl_option => tbl_option);
    
    END check_under_10;

    -- **********************************************************
    FUNCTION check_widow(i_value IN NUMBER) RETURN BOOLEAN IS
        tbl_option table_number := table_number(27);
    BEGIN
    
        RETURN check_over_under_base(i_value => i_value, i_tbl_option => tbl_option);
    
    END check_widow;

    -- ********************************************************************************************************
    FUNCTION get_marital_status
    (
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_status table_varchar;
        l_return   VARCHAR2(0010 CHAR);
    BEGIN
    
        SELECT marital_status
          BULK COLLECT
          INTO tbl_status
          FROM pat_soc_attributes psa
         WHERE psa.id_institution = i_prof.institution
           AND psa.id_patient = i_patient;
    
        -- MRK01
        IF tbl_status.count > 0
        THEN
            l_return := tbl_status(1);
        END IF; -- MRK01
    
        RETURN l_return;
    
    END get_marital_status;

    -- ********************************************************************************************************
    FUNCTION check_relationship
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
        l_age NUMBER;
        ---l_datatype VARCHAR2(0010 CHAR);
        xdrd         death_registry_det%ROWTYPE;
        tbl_comp     table_varchar := table_varchar('DEATH_INFORMANT_INFO_RELATION', 'DEATH_ACCED_VIOL_ALLEGED_PERP');
        l_code       VARCHAR2(0100 CHAR) := 'DR_NORM024_014';
        l_code_widow VARCHAR2(0100 CHAR) := 'DR_NORM024_015';
        l_status     VARCHAR2(0010 CHAR);
        l_bool       BOOLEAN := TRUE;
        k_flag_widow CONSTANT VARCHAR2(0010 CHAR) := 'W';
        k_year       CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        l_anomaly VARCHAR2(4000);
    BEGIN
    
        -- get age of patient
        l_age := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_type    => k_year);
    
        l_status := get_marital_status(i_prof => i_prof, i_patient => i_patient);
    
        <<lup_thru_comp>>
        FOR i IN 1 .. tbl_comp.count
        LOOP
        
            xdrd := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(i));
        
            IF xdrd.value_n IS NOT NULL
            THEN
                CASE
                    WHEN l_age < 10 THEN
                        -- exclude esposa, /* companera,*/ hijo, ex-exposo, nieto, suegro
                        l_bool := check_under_10(xdrd.value_n);
                    WHEN l_age BETWEEN 80 AND 90 THEN
                        -- exclude abuelo, madre, padre
                        l_bool := check_over_80(xdrd.value_n);
                    WHEN l_age > 90 THEN
                        -- exclude abuelo, madre, padre
                        l_bool := check_over_90(xdrd.value_n);
                    ELSE
                        l_bool := TRUE;
                END CASE;
            
                -- MRK03
                IF NOT l_bool
                THEN
                    -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                    l_anomaly := pk_message.get_message(i_lang, l_code);
                    register_anomaly(l_anomaly);
                    -- one occurence is enough
                    EXIT lup_thru_comp;
                END IF; -- MRK03
            
                -- MRK01
                IF l_status = k_flag_widow
                THEN
                    l_bool := check_widow(xdrd.value_n);
                
                    IF NOT l_bool
                    THEN
                        -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                        l_anomaly := pk_message.get_message(i_lang, l_code_widow);
                        register_anomaly(l_anomaly);
                        -- one occurence is enough
                        EXIT lup_thru_comp;
                    END IF; -- MRK03
                
                END IF; -- MRK01
            
            END IF;
        END LOOP lup_thru_comp;
    
        RETURN TRUE;
    
    END check_relationship;

    --**************************************************************
    FUNCTION check_fetal_relationship
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
        xdrd       death_registry_det%ROWTYPE;
        tbl_comp   table_varchar := table_varchar('DEATH_FETAL_INFOR_INFO_RELAT');
        l_code     VARCHAR2(0100 CHAR) := 'DR_NORM024_019';
        l_bool     BOOLEAN := TRUE;
        l_anomaly  VARCHAR2(4000);
        tbl_option table_number := table_number(68, 70, 69, 29, 28, 33, 39);
    
    BEGIN
    
        <<lup_thru_comp>>
        FOR i IN 1 .. tbl_comp.count
        LOOP
            xdrd := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(i));
        
            IF xdrd.value_n IS NOT NULL
            THEN
            
                l_bool := check_over_under_base(i_value => xdrd.value_n, i_tbl_option => tbl_option);
                IF NOT l_bool
                THEN
                    l_anomaly := pk_message.get_message(i_lang, l_code);
                    register_anomaly(l_anomaly);
                    -- one occurence is enough
                    EXIT lup_thru_comp;
                END IF;
            END IF;
        END LOOP lup_thru_comp;
    
        RETURN TRUE;
    
    END check_fetal_relationship;

    FUNCTION get_data_time_illness
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_mode IN VARCHAR2,
        i_tipo IN VARCHAR2,
        i_data IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_data IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF i_tipo = 'O'
        THEN
        
            IF i_mode = 'T'
            THEN
                l_return := substr(i_data, 1, instr(i_data, '|') - 1);
            ELSE
                l_return := substr(i_data, instr(i_data, '|') + 1);
            END IF;
        
        ELSE
        
            l_return := NULL;
            IF i_mode = 'T'
            THEN
                CASE i_tipo
                    WHEN 'S' THEN
                        l_return := 999;
                    WHEN 'I' THEN
                        l_return := 999;
                    WHEN 'N' THEN
                        l_return := 888;
                    ELSE
                        l_return := NULL;
                END CASE;
            ELSE
                l_return := i_tipo;
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_data_time_illness;

    -- ***************************************************************
    FUNCTION check_previous_pregnancy
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
    
        tbl_comp table_varchar := table_varchar('DEATH_FETAL_PREV_PREG_LIVE', 'DEATH_FETAL_PREV_PREG_DEATH');
        --k_limit_value CONSTANT NUMBER := 1;
    
        xdrd death_registry_det%ROWTYPE;
        --l_datatype     VARCHAR2(0020 CHAR);
        k_code_msg_016 VARCHAR2(0100 CHAR) := 'DR_NORM024_016';
        l_anomaly      VARCHAR2(1000 CHAR);
        l_live         NUMBER;
        l_death        NUMBER;
    BEGIN
    
        -- RULE:  La suma de los valores de ambas variables no puede ser m?de 25
    
        xdrd    := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(1));
        l_live  := xdrd.value_n;
        xdrd    := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(2));
        l_death := xdrd.value_n;
    
        IF l_live + l_death > 25
        THEN
        
            -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
            l_anomaly := pk_message.get_message(i_lang, k_code_msg_016);
            register_anomaly(l_anomaly);
        
        END IF;
    
        RETURN TRUE;
    
    END check_previous_pregnancy;

    -- ***************************************************************
    FUNCTION check_fields_min_len
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        tbl_comp table_varchar := table_varchar('DEATH_INFORMANT_INFO_NAME',
                                                'DEATH_INFORMANT_INFO_FATHER',
                                                'DEATH_INFORMANT_INFO_MOTHER',
                                                'DEATH_FETAL_INFO_NAME',
                                                'DEATH_FETAL_INFO_FATHER',
                                                'DEATH_FETAL_INFO_MOTHER',
                                                'DEATH_DATA_CAUSE_DESC_1',
                                                'DEATH_DATA_CAUSE_DESC_2',
                                                'DEATH_DATA_CAUSE_DESC_3',
                                                'DEATH_DATA_CAUSE_DESC_4',
                                                'DEATH_DATA_CAUSE_DESC_5',
                                                'DEATH_DATA_CAUSE_DESC_6',
                                                'DEATH_DATA_INSTITUTION',
                                                'DEATH_FETAL_CERT_NAME',
                                                'DEATH_FETAL_CERT_FATHER_NAME',
                                                'DEATH_FETAL_CERT_MOTHER_NAME',
                                                'DEATH_CERTIFIER_NAME',
                                                'DEATH_CERTIFIER_FATHER_NAME',
                                                'DEATH_CERTIFIER_MOTHER_NAME');
    
        xdrd                 death_registry_det%ROWTYPE;
        k_code_msg_017       VARCHAR2(0100 CHAR) := 'DR_NORM024_017';
        l_anomaly            VARCHAR2(1000 CHAR);
        l_comp_description   VARCHAR2(4000);
        l_parent_description VARCHAR2(4000);
    
        CURSOR cur_dc(i_id_dr IN NUMBER) IS
            SELECT x.*
              FROM death_registry_det x
              JOIN ds_component d
                ON d.id_ds_component = x.id_ds_component
             WHERE x.id_death_registry = i_id_dr
               AND d.internal_name IN (SELECT column_value comp_name
                                         FROM TABLE(tbl_comp) xtbl);
    BEGIN
    
        -- RULE:  LA LONGITUD M?IMA DEBE SER DE 2.
    
        <<lup_thru_intervals>>
        FOR xdrd IN cur_dc(i_id_dr)
        LOOP
            IF length(xdrd.value_vc2) = 1
            THEN
                l_comp_description := get_component_desc(i_lang, xdrd.id_ds_component);
                IF TRIM(l_comp_description) IS NULL
                THEN
                    l_comp_description := get_component_target_desc(i_lang, xdrd.id_ds_component, i_section);
                END IF;
                l_parent_description := get_component_parent_desc(i_lang, xdrd.id_ds_component, i_section);
                l_anomaly            := l_parent_description || ' - ' ||
                                        REPLACE(pk_message.get_message(i_lang, k_code_msg_017),
                                                '%1',
                                                l_comp_description);
                register_anomaly(l_anomaly);
            END IF;
        END LOOP lup_thru_intervals;
    
        RETURN TRUE;
    
    END check_fields_min_len;

    FUNCTION check_fields_min_len_equal
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        tbl_comp table_varchar := table_varchar('DEATH_INFORMANT_INFO_NAME',
                                                'DEATH_INFORMANT_INFO_FATHER',
                                                'DEATH_INFORMANT_INFO_MOTHER',
                                                'DEATH_FETAL_INFO_NAME',
                                                'DEATH_FETAL_INFO_FATHER',
                                                'DEATH_FETAL_INFO_MOTHER',
                                                'DEATH_FETAL_CERT_NAME',
                                                'DEATH_FETAL_CERT_FATHER_NAME',
                                                'DEATH_FETAL_CERT_MOTHER_NAME',
                                                'DEATH_CERTIFIER_NAME',
                                                'DEATH_CERTIFIER_FATHER_NAME',
                                                'DEATH_CERTIFIER_MOTHER_NAME');
    
        xdrd                 death_registry_det%ROWTYPE;
        k_code_msg_017       VARCHAR2(0100 CHAR) := 'DR_NORM024_027';
        l_anomaly            VARCHAR2(1000 CHAR);
        l_comp_description   VARCHAR2(4000);
        l_parent_description VARCHAR2(4000);
    
        CURSOR cur_dc(i_id_dr IN NUMBER) IS
            SELECT x.*
              FROM death_registry_det x
              JOIN ds_component d
                ON d.id_ds_component = x.id_ds_component
             WHERE x.id_death_registry = i_id_dr
               AND d.internal_name IN (SELECT column_value comp_name
                                         FROM TABLE(tbl_comp) xtbl);
    BEGIN
    
        -- RULE:  LA LONGITUD M?IMA DEBE SER DE 2.
    
        <<lup_thru_intervals>>
        FOR xdrd IN cur_dc(i_id_dr)
        LOOP
            IF length(xdrd.value_vc2) = 2
               AND upper(substr(xdrd.value_vc2, 1, 1)) = upper(substr(xdrd.value_vc2, 2, 1))
               OR regexp_like(upper(xdrd.value_vc2), '^(.)\1{2}') = TRUE
            THEN
                l_comp_description := get_component_desc(i_lang, xdrd.id_ds_component);
                IF TRIM(l_comp_description) IS NULL
                THEN
                    l_comp_description := get_component_target_desc(i_lang, xdrd.id_ds_component, i_section);
                END IF;
                l_parent_description := get_component_parent_desc(i_lang, xdrd.id_ds_component, i_section);
                l_anomaly            := l_parent_description || ' - ' ||
                                        REPLACE(pk_message.get_message(i_lang, k_code_msg_017),
                                                '%1',
                                                l_comp_description);
                register_anomaly(l_anomaly);
            END IF;
        END LOOP lup_thru_intervals;
    
        RETURN TRUE;
    
    END check_fields_min_len_equal;

    FUNCTION check_fields_special_car
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        tbl_comp table_varchar := table_varchar('DEATH_DATA_INSTITUTION',
                                                'DEATH_DATA_ADRRESS_NUMBER',
                                                'DEATH_DATA_ADRRESS_COLONY',
                                                'DEATH_FETAL_PREG_PROC_EXP_INF',
                                                'DEATH_DATA_CAUSE_DESC_1',
                                                'DEATH_DATA_CAUSE_DESC_2',
                                                'DEATH_DATA_CAUSE_DESC_3',
                                                'DEATH_DATA_CAUSE_DESC_4',
                                                'DEATH_DATA_CAUSE_DESC_5',
                                                'DEATH_DATA_CAUSE_DESC_6',
                                                'DEATH_FETAL_CERT_STREET',
                                                'DEATH_CERTIFIER_COLONY',
                                                'DEATH_DATA_FOLIO_CONTROL',
                                                'DEATH_ACCED_VIOL_PUB_MIN_NUM',
                                                'DEATH_ACCED_VIOL_DESCRIPTION',
                                                'DEATH_ACCED_VIOL_STREET_NUMBER',
                                                'DEATH_ACCED_VIOL_COLONY',
                                                'DEATH_CERTIFIER_STREET',
                                                'DEATH_CERTIFIER_COLONY');
    
        xdrd                 death_registry_det%ROWTYPE;
        k_code_msg_017       VARCHAR2(0100 CHAR) := 'DR_NORM024_027';
        l_anomaly            VARCHAR2(1000 CHAR);
        l_comp_description   VARCHAR2(4000);
        l_parent_description VARCHAR2(4000);
    
        CURSOR cur_dc(i_id_dr IN NUMBER) IS
            SELECT x.*
              FROM death_registry_det x
              JOIN ds_component d
                ON d.id_ds_component = x.id_ds_component
             WHERE x.id_death_registry = i_id_dr
               AND d.internal_name IN (SELECT column_value comp_name
                                         FROM TABLE(tbl_comp) xtbl);
    BEGIN
    
        -- RULE:  LA LONGITUD M?IMA DEBE SER DE 2.
    
        <<lup_thru_intervals>>
        FOR xdrd IN cur_dc(i_id_dr)
        LOOP
            IF regexp_like(upper(xdrd.value_vc2), '^(.)\1{2}') = TRUE
            --   OR regexp_like(upper(xdrd.value_vc2), '[^a-zA-Z0-9 ]') = true
            THEN
                l_comp_description := get_component_desc(i_lang, xdrd.id_ds_component);
                IF TRIM(l_comp_description) IS NULL
                THEN
                    l_comp_description := get_component_target_desc(i_lang, xdrd.id_ds_component, i_section);
                END IF;
                l_parent_description := get_component_parent_desc(i_lang, xdrd.id_ds_component, i_section);
                l_anomaly            := l_parent_description || ' - ' ||
                                        REPLACE(pk_message.get_message(i_lang, k_code_msg_017),
                                                '%1',
                                                l_comp_description);
                register_anomaly(l_anomaly);
            END IF;
        END LOOP lup_thru_intervals;
    
        RETURN TRUE;
    
    END check_fields_special_car;

    -- **************************************************************************************

    FUNCTION get_mx_name_from_list
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_value    IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_flag     IN VARCHAR2,
        i_group_id IN NUMBER,
        i_id_ne    IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_return      VARCHAR2(4000) := i_name;
        l_id_sys_list NUMBER;
    BEGIN
    
        IF i_value != i_flag
        THEN
            IF i_id_ne IS NOT NULL
            THEN
                l_return := pk_sys_list.get_sys_list_value_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_sys_list => i_id_ne);
            ELSE
                l_id_sys_list := pk_sys_list.get_id_sys_list(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_sys_list_group => i_group_id,
                                                             i_flg_context    => i_value);
            
                l_return := pk_sys_list.get_sys_list_value_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_sys_list => l_id_sys_list);
            END IF;
        END IF;
    
        RETURN upper(l_return);
    
    END get_mx_name_from_list;

    -- *******************************************************************
    FUNCTION get_pat_dt_nasc(i_id_pat IN NUMBER) RETURN patient.dt_birth_tstz%TYPE IS
        tbl_dt_birth table_timestamp;
        l_return     patient.dt_birth_tstz%TYPE;
    BEGIN
    
        SELECT dt_birth_tstz
          BULK COLLECT
          INTO tbl_dt_birth
          FROM patient t
         WHERE t.id_patient = i_id_pat;
    
        IF tbl_dt_birth.count > 0
        THEN
            l_return := tbl_dt_birth(1);
        END IF;
    
        RETURN l_return;
    
    END get_pat_dt_nasc;

    -- *******************************************************
    PROCEDURE check_certify_dt_nasc
    (
        i_lang    IN NUMBER,
        i_dt_pat  IN patient.dt_birth_tstz%TYPE,
        i_dt_cert IN death_registry_det.value_tz%TYPE
    ) IS
        l_bool    BOOLEAN;
        l_anomaly VARCHAR2(4000);
        k_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_020';
    BEGIN
    
        -- DEATH_DATE
        IF i_dt_pat IS NOT NULL
        THEN
            -- certifier date should b always greater than birth date
            l_bool := i_dt_cert > trunc(i_dt_pat);
        
            IF NOT l_bool
            THEN
            
                -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                l_anomaly := pk_message.get_message(i_lang, k_msg);
                register_anomaly(l_anomaly);
            
            END IF;
        
        END IF;
    
    END check_certify_dt_nasc;

    -- *******************************************************
    PROCEDURE check_death_dt_nasc
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_dt_pat   IN patient.dt_birth_tstz%TYPE,
        i_dt_death IN death_registry.dt_death%TYPE,
        i_dt_type  IN VARCHAR2
    ) IS
        l_bool    BOOLEAN;
        l_anomaly VARCHAR2(4000);
        k_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_021';
        l_death_str VARCHAR2(200 CHAR);
    BEGIN
    
        IF i_dt_pat IS NOT NULL
           AND i_dt_death IS NOT NULL
           AND i_dt_type = pk_dynamic_screen.k_dp_mode_full
        THEN
            l_death_str := pk_date_utils.date_send_tsz(i_lang, i_dt_death, i_prof);
            IF substr(l_death_str, 9) = '000000'
            THEN
                l_bool := trunc(pk_date_utils.trunc_insttimezone(i_prof, i_dt_death)) >=
                          trunc(pk_date_utils.trunc_insttimezone(i_prof, i_dt_pat));
            ELSE
                l_bool := i_dt_death > i_dt_pat;
            END IF;
        
            IF NOT l_bool
            THEN
                -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                l_anomaly := pk_message.get_message(i_lang, k_msg);
                register_anomaly(l_anomaly);
            
            END IF;
        
        END IF;
    
    END check_death_dt_nasc;

    -- *******************************************************************
    PROCEDURE check_certify_dt_death
    (
        i_lang     IN NUMBER,
        i_dt_cert  IN death_registry_det.value_tz%TYPE,
        i_dt_death IN death_registry.dt_death%TYPE,
        i_dt_type  IN VARCHAR2
    ) IS
        l_bool    BOOLEAN;
        l_anomaly VARCHAR2(4000);
        k_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_022';
    BEGIN
    
        IF i_dt_cert IS NOT NULL
           AND i_dt_death IS NOT NULL
        THEN
            IF i_dt_type = pk_dynamic_screen.k_dp_mode_full
            THEN
                l_bool := trunc(i_dt_cert) BETWEEN trunc(i_dt_death) AND
                          (trunc(i_dt_death) + numtodsinterval(2, 'DAY'));
            
                IF NOT l_bool
                THEN
                
                    -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
                    l_anomaly := pk_message.get_message(i_lang, k_msg);
                    register_anomaly(l_anomaly);
                
                END IF;
            END IF;
        END IF;
    
    END check_certify_dt_death;

    -- *******************************************************************************************
    PROCEDURE check_year_dt_certify
    (
        i_lang    IN NUMBER,
        i_dt_cert IN death_registry_det.value_tz%TYPE
    ) IS
        l_current_year NUMBER(4);
        l_dt_year      NUMBER(4);
        l_anomaly      VARCHAR2(4000);
        l_bool         BOOLEAN;
        k_msg       CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_023';
        k_year_mask CONSTANT VARCHAR2(0100 CHAR) := 'YYYY';
    BEGIN
    
        l_current_year := to_number(to_char(current_timestamp, k_year_mask));
        l_dt_year      := to_number(to_char(i_dt_cert, k_year_mask));
    
        l_bool := l_dt_year NOT IN ((l_current_year - 1), l_current_year);
    
        IF l_bool
        THEN
            -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
            l_anomaly := pk_message.get_message(i_lang, k_msg);
            register_anomaly(l_anomaly);
        
        END IF;
    
    END check_year_dt_certify;

    -- *******************************************************************************************
    PROCEDURE check_expulsion_dt_certify
    (
        i_lang       IN NUMBER,
        i_dt_cert    IN death_registry_det.value_tz%TYPE,
        i_dt_extract IN death_registry_det.value_tz%TYPE
    ) IS
        l_anomaly VARCHAR2(4000);
        l_bool    BOOLEAN;
        k_msg CONSTANT VARCHAR2(0100 CHAR) := 'DR_NORM024_024';
    BEGIN
    
        l_bool := i_dt_cert > trunc(i_dt_extract);
    
        IF NOT l_bool
        THEN
            -- !!! ANOMALY -> REGISTER IT RIGHT AWAY!!!!!
            l_anomaly := pk_message.get_message(i_lang, k_msg);
            register_anomaly(l_anomaly);
        
        END IF;
    
    END check_expulsion_dt_certify;

    -- ******************************************************
    FUNCTION check_dates
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN IS
        k_dt_certify CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_CERTIFIER_DATE';
        k_dt_death   CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_DATE_TIME';
        k_dt_extract CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_FETAL_PREG_EXTRACT_DATE';
    
        tbl_comp     table_varchar := table_varchar(k_dt_certify, k_dt_death, k_dt_extract);
        l_dt_nasc    patient.dt_birth_tstz%TYPE;
        xrow         death_registry%ROWTYPE;
        xdrd         death_registry_det%ROWTYPE;
        xdrd_date    death_registry_det%ROWTYPE;
        l_dt_certify death_registry_det.value_tz%TYPE;
    BEGIN
    
        xrow      := get_death_registry_row(i_death_registry => i_id_dr);
        l_dt_nasc := get_pat_dt_nasc(i_id_pat => i_patient);
    
        <<lup_thru_comp>>
        FOR i IN 1 .. tbl_comp.count
        LOOP
        
            xdrd := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => tbl_comp(i));
        
            CASE i_section
                WHEN c_ds_death_data THEN
                
                    CASE tbl_comp(i)
                        WHEN k_dt_certify THEN
                        
                            --certifier cannot be less than dt of death
                            check_certify_dt_nasc(i_lang => i_lang, i_dt_pat => l_dt_nasc, i_dt_cert => xdrd.value_tz);
                            check_certify_dt_death(i_lang     => i_lang,
                                                   i_dt_cert  => xdrd.value_tz,
                                                   i_dt_death => xrow.dt_death,
                                                   i_dt_type  => xrow.death_date_format);
                        
                        WHEN k_dt_death THEN
                            -- death greater than birth date
                            check_death_dt_nasc(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_dt_pat   => l_dt_nasc,
                                                i_dt_death => xrow.dt_death,
                                                i_dt_type  => xrow.death_date_format);
                            NULL;
                        ELSE
                            NULL;
                        
                    END CASE;
                
                WHEN c_ds_death_data_fetal THEN
                    CASE tbl_comp(i)
                        WHEN k_dt_certify THEN
                            check_year_dt_certify(i_lang => i_lang, i_dt_cert => xdrd.value_tz);
                            l_dt_certify := xdrd.value_tz;
                        WHEN k_dt_extract THEN
                            check_expulsion_dt_certify(i_lang       => i_lang,
                                                       i_dt_cert    => l_dt_certify,
                                                       i_dt_extract => xdrd.value_tz);
                        ELSE
                            NULL;
                    END CASE;
                
            END CASE;
        
        END LOOP lup_thru_comp;
    
        RETURN TRUE;
    
    END check_dates;

    -- ********************************************************************
    FUNCTION get_mother_folio
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        i_field IN VARCHAR2,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(020 CHAR);
        k_value_no CONSTANT VARCHAR2(20 CHAR) := '000000000';
        k_value_ne CONSTANT VARCHAR2(020 CHAR) := '888888888';
        k_value_si CONSTANT VARCHAR2(020 CHAR) := '999999999';
    BEGIN
        IF i_type = k_yes
        THEN
            l_value := k_value_no;
        ELSE
            CASE i_field
                WHEN pk_alert_constant.g_ne THEN
                    l_value := k_value_ne;
                WHEN pk_alert_constant.g_si THEN
                    l_value := k_value_si;
                ELSE
                    l_value := i_value;
            END CASE;
        END IF;
    
        RETURN l_value;
    
    END get_mother_folio;

    -- ********************************************************************
    FUNCTION get_field_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN VARCHAR2,
        i_value IN VARCHAR2,
        i_flg_4 IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(020 CHAR);
        k_value_ne CONSTANT VARCHAR2(020 CHAR) := '88';
        k_value_si CONSTANT VARCHAR2(020 CHAR) := '99';
    BEGIN
    
        CASE i_field
            WHEN pk_alert_constant.g_ne THEN
                l_value := k_value_ne;
            WHEN pk_alert_constant.g_si THEN
                l_value := k_value_si;
            ELSE
                l_value := i_value;
        END CASE;
    
        IF i_flg_4 = k_yes
           AND i_field IN (pk_alert_constant.g_ne, pk_alert_constant.g_si)
        THEN
            l_value := l_value || l_value;
        END IF;
    
        RETURN l_value;
    
    END get_field_value;

    FUNCTION get_cert_order_number
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_type     IN VARCHAR2,
        i_question IN VARCHAR2,
        i_value    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(020 CHAR);
        k_value_no CONSTANT VARCHAR2(20 CHAR) := '0000000';
        k_value_ne CONSTANT VARCHAR2(020 CHAR) := '8888888';
        k_value_si CONSTANT VARCHAR2(020 CHAR) := '9999999';
    BEGIN
        IF i_value IS NOT NULL
        THEN
            l_value := i_value;
        ELSIF i_question IS NOT NULL
        THEN
            IF i_type = 'F'
            THEN
                l_value := k_value_ne;
            ELSE
                l_value := k_value_si;
            END IF;
        ELSIF i_question IS NULL
              AND i_type = 'F'
        THEN
            l_value := k_value_no;
        ELSIF i_question IS NULL
              AND i_type = 'G'
        THEN
            l_value := k_value_ne;
        ELSE
            l_value := NULL;
        END IF;
    
        RETURN l_value;
    
    END get_cert_order_number;

    FUNCTION get_procedure_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_id_dr IN death_registry.id_death_registry%TYPE
    ) RETURN VARCHAR2 IS
    
        k_procedure      CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_FETAL_PREG_PROC_EXP';
        k_procedure_free CONSTANT VARCHAR2(0100 CHAR) := 'DEATH_FETAL_PREG_PROC_EXP_INF';
    
        tbl_comp         table_varchar := table_varchar(k_procedure, k_procedure_free);
        xdrd             death_registry_det%ROWTYPE;
        l_procedure      death_registry_det.value_n%TYPE;
        l_procedure_free death_registry_det.value_vc2%TYPE;
        k_se_ignora CONSTANT VARCHAR2(100 CHAR) := 'SE IGNORA';
        k_no_aplica CONSTANT VARCHAR2(100 CHAR) := 'NO APLICA';
    BEGIN
    
        xdrd        := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => k_procedure);
        l_procedure := xdrd.value_n;
    
        xdrd             := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => k_procedure_free);
        l_procedure_free := xdrd.value_vc2;
        IF l_procedure = 26
        THEN
            RETURN k_se_ignora;
        ELSE
            RETURN k_no_aplica;
        END IF;
    END get_procedure_desc;

    FUNCTION get_code_by_federal_entity
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dr     IN death_registry.id_death_registry%TYPE,
        i_comp_name IN ds_component.internal_name%TYPE,
        i_type      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_federal_id death_registry_det.value_n%TYPE;
        l_code       VARCHAR2(10 CHAR);
        xdrd         death_registry_det%ROWTYPE;
    BEGIN
    
        xdrd         := get_dr_det_info(i_id_dr => i_id_dr, i_comp_name => i_comp_name);
        l_federal_id := xdrd.value_n;
        CASE i_type
            WHEN 5 THEN
                CASE l_federal_id
                    WHEN 2001 THEN
                        l_code := '33';
                    WHEN 2002 THEN
                        l_code := '34';
                    WHEN 2003 THEN
                        l_code := '35';
                    ELSE
                        RETURN NULL;
                END CASE;
            WHEN 10 THEN
                -- MUNICIPIO
                l_code := '000';
            WHEN 15 THEN
                -- LOCALIDAD
                l_code := '0000';
            ELSE
                RETURN NULL;
        END CASE;
    
        RETURN l_code;
    
    END get_code_by_federal_entity;
    -- ************************************************************************************
    FUNCTION check_fetal_anomalies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN := TRUE;
        c_check_fetal_anomalies CONSTANT sys_config.id_sys_config%TYPE := 'FETAL_DEATH_CHECK_ANOMALIES';
    
    BEGIN
    
        IF pk_sysconfig.get_config(i_code_cf => c_check_fetal_anomalies, i_prof => i_prof) = pk_alert_constant.g_no
        THEN
            RETURN TRUE;
        END IF;
        l_ret := l_ret AND
                 check_mandatory_folio(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND
                 check_diag_no_cbd(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND check_previous_pregnancy(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    i_id_dr   => i_id_dr);
    
        l_ret := l_ret AND check_fields_min_len(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_patient => i_patient,
                                                i_id_dr   => i_id_dr,
                                                i_section => c_ds_death_data_fetal);
    
        l_ret := l_ret AND check_fields_min_len_equal(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_patient => i_patient,
                                                      i_id_dr   => i_id_dr,
                                                      i_section => c_ds_death_data);
    
        l_ret := l_ret AND check_fields_special_car(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    i_id_dr   => i_id_dr,
                                                    i_section => c_ds_death_data);
    
        l_ret := l_ret AND check_causes(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
        l_ret := l_ret AND check_fetal_relationship(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    i_id_dr   => i_id_dr);
    
        l_ret := l_ret AND check_dates(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_id_dr   => i_id_dr,
                                       i_section => c_ds_death_data_fetal);
    
        l_ret := l_ret AND check_folio_uk(i_lang           => i_lang,
                                          i_section        => c_ds_death_data_fetal,
                                          i_patient        => i_patient,
                                          i_death_registry => i_id_dr);
    
        RETURN l_ret;
    
    END check_fetal_anomalies;

    FUNCTION check_anomalies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN := TRUE;
    BEGIN
    
        l_ret := l_ret AND check_mx_max_age(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
        l_ret := l_ret AND check_diag_p(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND
                 check_diag_no_cbd(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND
                 check_range_death_diag(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND
                 check_relationship(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        --    l_ret := l_ret AND
        --            check_mandatory_folio(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_id_dr => i_id_dr);
    
        l_ret := l_ret AND check_fields_min_len(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_patient => i_patient,
                                                i_id_dr   => i_id_dr,
                                                i_section => c_ds_death_data);
        l_ret := l_ret AND check_fields_min_len_equal(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_patient => i_patient,
                                                      i_id_dr   => i_id_dr,
                                                      i_section => c_ds_death_data);
        l_ret := l_ret AND check_fields_special_car(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    i_id_dr   => i_id_dr,
                                                    i_section => c_ds_death_data);
        l_ret := l_ret AND check_dates(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_id_dr   => i_id_dr,
                                       i_section => c_ds_death_data);
    
        l_ret := l_ret AND check_folio_uk(i_lang           => i_lang,
                                          i_section        => c_ds_death_data,
                                          i_patient        => i_patient,
                                          i_death_registry => i_id_dr);
        RETURN l_ret;
    
    END check_anomalies;

    FUNCTION get_death_item_values
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_section          IN t_table_ds_sections,
        i_tbl_items_values IN OUT t_table_ds_items_values,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        r_section              t_rec_ds_sections; --auxiliar var that has the current record when looping through i_sections table
        l_tbl_items_values_aux t_table_ds_items_values;
        k_function_name        VARCHAR2(50 CHAR) := 'GET_DEATH_ITEM_VALUES';
    
        PROCEDURE add_nationality
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        )
        
         IS
            l_dbg_msg debug_msg;
        
        BEGIN
            SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => a.id_ds_cmpt_mkt_rel,
                                         id_ds_component    => a.id_ds_component,
                                         internal_name      => a.internal_name,
                                         flg_component_type => a.flg_component_type,
                                         item_desc          => a.item_desc,
                                         item_value         => a.item_value,
                                         item_alt_value     => a.item_alt_value,
                                         item_xml_value     => NULL,
                                         item_rank          => a.item_rank)
              BULK COLLECT
              INTO l_tbl_items_values_aux
              FROM (SELECT i_ds_cmpt_mkt_rel id_ds_cmpt_mkt_rel,
                           i_ds_component id_ds_component,
                           i_internal_name internal_name,
                           i_flg_component_type flg_component_type,
                           pk_translation.get_translation(i_lang, c.code_nationality) || ' (' ||
                           pk_translation.get_translation(i_lang, c.code_country) || ')' AS item_desc,
                           id_country AS item_value,
                           id_country AS item_alt_value,
                           1 AS item_rank
                      FROM country c
                     WHERE flg_available = pk_alert_constant.g_yes
                       AND pk_translation.get_translation(i_lang, c.code_nationality) IS NOT NULL
                     ORDER BY item_desc) a;
            i_tbl_items_values := i_tbl_items_values MULTISET UNION ALL l_tbl_items_values_aux;
        
        END add_nationality;
    
        PROCEDURE add_professional
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            i_type_specialist    IN VARCHAR2 DEFAULT NULL
        ) IS
        
        BEGIN
            SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => a.id_ds_cmpt_mkt_rel,
                                         id_ds_component    => a.id_ds_component,
                                         internal_name      => a.internal_name,
                                         flg_component_type => a.flg_component_type,
                                         item_desc          => a.item_desc,
                                         item_value         => a.item_value,
                                         item_alt_value     => a.item_alt_value,
                                         item_xml_value     => NULL,
                                         item_rank          => a.item_rank)
              BULK COLLECT
              INTO l_tbl_items_values_aux
              FROM (SELECT DISTINCT i_ds_cmpt_mkt_rel id_ds_cmpt_mkt_rel,
                                    i_ds_component id_ds_component,
                                    i_internal_name internal_name,
                                    i_flg_component_type flg_component_type,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) AS item_desc,
                                    prf.id_professional AS item_value,
                                    prf.id_professional AS item_alt_value,
                                    1 AS item_rank
                      FROM professional prf
                     INNER JOIN prof_cat prc
                        ON (prc.id_professional = prf.id_professional)
                     INNER JOIN category cat
                        ON (cat.id_category = prc.id_category)
                     INNER JOIN prof_profile_template ppt
                        ON (ppt.id_professional = prf.id_professional)
                     INNER JOIN prof_institution pi
                        ON (prf.id_professional = pi.id_professional)
                     INNER JOIN profile_template pt
                        ON ppt.id_profile_template = pt.id_profile_template
                     WHERE cat.flg_type = pk_alert_constant.g_cat_type_doc
                       AND prf.flg_state = 'A'
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pi.dt_end_tstz IS NULL
                       AND prc.id_institution = i_prof.institution
                       AND ppt.id_software = pk_alert_constant.g_soft_inpatient
                       AND ppt.id_institution = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, prf.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND nvl(prf.flg_prof_test, pk_alert_constant.g_no) = pk_alert_constant.g_no
                       AND ((pt.flg_profile = 'S' AND i_type_specialist = pk_alert_constant.g_yes) OR
                           i_type_specialist IS NULL)
                     ORDER BY item_desc) a;
            i_tbl_items_values := i_tbl_items_values MULTISET UNION ALL l_tbl_items_values_aux;
        
        END add_professional;
    
        PROCEDURE add_relation
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        )
        
         IS
        BEGIN
            SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => a.id_ds_cmpt_mkt_rel,
                                         id_ds_component    => a.id_ds_component,
                                         internal_name      => a.internal_name,
                                         flg_component_type => a.flg_component_type,
                                         item_desc          => a.item_desc,
                                         item_value         => a.item_value,
                                         item_alt_value     => a.item_alt_value,
                                         item_xml_value     => NULL,
                                         item_rank          => a.item_rank)
              BULK COLLECT
              INTO l_tbl_items_values_aux
              FROM (SELECT i_ds_cmpt_mkt_rel id_ds_cmpt_mkt_rel,
                           i_ds_component id_ds_component,
                           i_internal_name internal_name,
                           i_flg_component_type flg_component_type,
                           pk_translation.get_translation(i_lang, f.code_family_relationship) AS item_desc,
                           f.id_family_relationship AS item_value,
                           id_family_relationship AS item_alt_value,
                           1 AS item_rank
                      FROM family_relationship f
                     WHERE flg_available = pk_alert_constant.g_yes
                       AND pk_translation.get_translation(i_lang, f.code_family_relationship) IS NOT NULL
                     ORDER BY item_desc) a;
            i_tbl_items_values := i_tbl_items_values MULTISET UNION ALL l_tbl_items_values_aux;
        
        END add_relation;
    BEGIN
        IF i_section IS NOT NULL
           AND i_section.count > 0
        THEN
            FOR i IN i_section.first .. i_section.last
            LOOP
                r_section := i_section(i);
                IF r_section.internal_name IN ('DEATH_PAT_INFO_FATHER_NAT', 'DEATH_PAT_INFO_MOTHER_NAT')
                THEN
                    add_nationality(r_section.id_ds_cmpt_mkt_rel,
                                    r_section.id_ds_component,
                                    r_section.internal_name,
                                    r_section.flg_component_type);
                ELSIF r_section.internal_name IN ('DEATH_DATA_EXAMIN_PHYSICIAN',
                                                  'DEATH_DATA_TREAT_PHYSICIAN',
                                                  'DS_DEATH_DATA_CERTIFY_PHYSICIAN',
                                                  'DS_DEATH_DATA_CERTIFY_PHYSICIAN')
                THEN
                    add_professional(r_section.id_ds_cmpt_mkt_rel,
                                     r_section.id_ds_component,
                                     r_section.internal_name,
                                     r_section.flg_component_type);
                ELSIF r_section.internal_name = 'DEATH_DATA_DOCTOR_HOSP'
                THEN
                    add_professional(r_section.id_ds_cmpt_mkt_rel,
                                     r_section.id_ds_component,
                                     r_section.internal_name,
                                     r_section.flg_component_type,
                                     pk_alert_constant.g_yes);
                ELSIF r_section.internal_name IN ('DEATH_DATA_PERSON_RELATION')
                THEN
                    add_relation(r_section.id_ds_cmpt_mkt_rel,
                                 r_section.id_ds_component,
                                 r_section.internal_name,
                                 r_section.flg_component_type);
                END IF;
            
            END LOOP;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_death_item_values;

    -- CMF ***************
    FUNCTION get_dr_rep_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SUMMARY';
        l_dbg_msg debug_msg;
    
        l_ret BOOLEAN;
        func_exception EXCEPTION;
    
        PROCEDURE do_exception IS
        BEGIN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            o_data_val := NULL;
        
        END do_exception;
    
    BEGIN
        l_dbg_msg := 'get patient death registry data';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_ret := get_death_data(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                o_data_val  => o_data_val,
                                o_prof_data => o_prof_data,
                                o_error     => o_error);
    
        IF NOT l_ret
        THEN
            RAISE func_exception;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section structure';
        l_ret     := pk_dynamic_screen.get_ds_rep_section(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_section_name   => i_section_name,
                                                          i_component_name => i_component_name,
                                                          i_component_type => i_component_type,
                                                          i_patient        => i_patient,
                                                          o_section        => o_section,
                                                          o_error          => o_error);
        IF NOT l_ret
        THEN
            RAISE func_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN func_exception THEN
            do_exception();
            RETURN FALSE;
        WHEN OTHERS THEN
            do_exception();
            RETURN FALSE;
    END get_dr_rep_summary;

    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_dynamic_screen.get_rep_component_desc(i_lang               => i_lang,
                                                        i_section_name       => i_section_name,
                                                        i_id_ds_cmpt_kmt_rel => i_id_ds_cmpt_kmt_rel);
    
    END get_rep_component_desc;

    FUNCTION get_all_diag_string
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
        k_sp CONSTANT VARCHAR2(0010 CHAR) := ';';
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
        
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed.id_epis_diagnosis,
                                              i_flg_search_mode     => k_yes) AS desc_diagnosis
              BULK COLLECT
              INTO tbl_return
              FROM epis_diagnosis ed
             INNER JOIN diagnosis d
                ON ed.id_diagnosis = d.id_diagnosis
              LEFT OUTER JOIN alert_diagnosis ad
                ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE ed.id_episode = i_episode
               AND ed.flg_type = pk_diagnosis.g_diag_type_d
               AND ed.flg_status NOT IN (pk_diagnosis.g_epis_status_c, pk_diagnosis.g_ed_flg_status_r)
             ORDER BY decode(ed.flg_type, 'P', 0, 1);
        
            <<lup_thru_diags>>
            FOR i IN 1 .. tbl_return.count
            LOOP
            
                IF i > 1
                THEN
                    l_return := l_return || k_sp;
                END IF;
            
                l_return := l_return || tbl_return(i);
            
            END LOOP lup_thru_diags;
        
        END IF;
    
        RETURN l_return;
    
    END get_all_diag_string;

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);
END pk_death_registry;
/
