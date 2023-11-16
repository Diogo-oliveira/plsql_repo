/*-- Last Change Revision: $Rev: 2049199 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2022-11-04 16:54:58 +0000 (sex, 04 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_info_button AS

    FUNCTION get_show_info_button
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT NULL
    ) RETURN sys_config.value%TYPE IS
    
        l_show_info_button table_number := table_number();
    
        l_id_sys_config   sys_config.id_sys_config%TYPE;
        l_desc_sys_config sys_config.desc_sys_config%TYPE;
        l_id_prof_cat     NUMBER;
    
    BEGIN
    
        BEGIN
            l_id_prof_cat      := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
            l_show_info_button := pk_utils.str_split_n(i_list  => pk_sysconfig.get_config('SHOW_INFO_BUTTON', i_prof),
                                                       i_delim => '|');
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        -- Validate if button should be active or not by sys_config
        -- sys config is by category pipelined        
        IF pk_utils.search_table_number(i_table => l_show_info_button, i_search => l_id_prof_cat) = -1
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        -- GET THE CONFIGURATION  URL ON TABLE by AREA if theres no URL CONFIGURED THE INFO BUTTON SHOULD BE DISABLED
        BEGIN
            SELECT ttib.id_sys_config
              INTO l_id_sys_config
              FROM task_type_info_button ttib
             WHERE ttib.id_task_type = i_id_task_type;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN pk_alert_constant.g_no;
        END;
    
        l_desc_sys_config := pk_sysconfig.get_config(l_id_sys_config, i_prof);
    
        IF l_desc_sys_config IS NULL
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
    END get_show_info_button;

    FUNCTION get_cds_def_show_info_button
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_inst_par_action.id_cdr_inst_par_action%TYPE,
        i_id_links          IN links.id_links%TYPE
    ) RETURN links.id_links%TYPE IS
    
        l_show_info_button sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_INFO_BUTTON', i_prof);
        l_id_links         links.id_links%TYPE;
    
    BEGIN
    
        -- Validate if button should be active or not
        IF l_show_info_button = pk_alert_constant.g_no
        THEN
            RETURN NULL;
        END IF;
    
        IF i_id_links IS NULL
        THEN
            -- GET THE CONFIGURATION URL BY THE DEFINITION
            BEGIN
                SELECT cdrd.id_links
                  INTO l_id_links
                  FROM cdr_definition cdrd
                 WHERE cdrd.id_cdr_definition = i_id_cdr_definition;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
            END;
        END IF;
    
        RETURN l_id_links;
    
    END get_cds_def_show_info_button;

    FUNCTION get_cds_show_info_button
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_cdr_inst_par_action IN cdr_inst_par_action.id_cdr_inst_par_action%TYPE
    ) RETURN links.id_links%TYPE IS
    
        l_show_info_button sys_config.value%TYPE := pk_sysconfig.get_config('SHOW_INFO_BUTTON', i_prof);
        l_id_links         links.id_links%TYPE;
    
    BEGIN
    
        -- Validate if button should be active or not
        IF l_show_info_button = pk_alert_constant.g_no
        THEN
            RETURN NULL;
        END IF;
    
        -- GET THE CONFIGURATION URL BY THE DEFINITION
        BEGIN
            SELECT cdrd.id_links
              INTO l_id_links
              FROM cdr_inst_par_action cdripa
              JOIN cdr_inst_param cdrip
                ON cdrip.id_cdr_inst_param = cdripa.id_cdr_inst_param
              JOIN cdr_instance cdri
                ON cdri.id_cdr_instance = cdrip.id_cdr_instance
              JOIN cdr_definition cdrd
                ON cdrd.id_cdr_definition = cdri.id_cdr_definition
             WHERE cdripa.id_cdr_inst_par_action = i_id_cdr_inst_par_action;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    
        RETURN l_id_links;
    
    END get_cds_show_info_button;

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
    ) RETURN BOOLEAN IS
    
        l_name      patient.name%TYPE;
        l_nick_name patient.nick_name%TYPE;
        l_gender    patient.gender%TYPE;
    
        l_desc_gender    VARCHAR2(100 CHAR);
        l_dt_birth       VARCHAR2(100 CHAR);
        l_dt_birth_send  VARCHAR2(100 CHAR);
        l_age            VARCHAR2(100 CHAR);
        l_dt_deceased    VARCHAR2(100 CHAR);
        l_desc_age       VARCHAR2(100 CHAR);
        l_include_age    VARCHAR2(10 CHAR);
        l_include_gender VARCHAR2(10 CHAR);
        l_num_age        NUMBER;
    
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, to_date(to_char(p.dt_deceased, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    
    BEGIN
    
        g_error := 'GET PATIENT DATA';
        IF NOT pk_patient.get_desc_pat_info(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            l_name,
                                            l_nick_name,
                                            l_gender,
                                            l_desc_gender,
                                            l_dt_birth,
                                            l_dt_birth_send,
                                            l_age,
                                            l_dt_deceased,
                                            o_error)
        THEN
            RAISE g_other_exception;
        END IF;
        -- Maybe use: ID_PATIENT_GENDER , ID_PATIENT_AGE -- need to copy them to software 0
    
        IF l_gender IS NOT NULL
        THEN
            l_desc_gender    := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_T047') || ' (' ||
                                l_desc_gender || ')';
            l_include_gender := pk_alert_constant.g_yes;
        END IF;
    
        IF l_age IS NOT NULL
        THEN
            l_desc_age    := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_T048') || ' (' ||
                             to_char(l_age) || ')';
            l_include_age := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth, l_age, l_dt_deceased;
        CLOSE c_pat;
    
        -- convert l_age to days
        l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                            i_dt_birth    => l_dt_birth,
                                            i_dt_deceased => l_dt_deceased,
                                            i_age         => l_age,
                                            i_age_format  => 'DAYS');
    
        g_error := 'GET O_INFO';
        OPEN o_info FOR
            SELECT 1 rank,
                   'ALL' internal_name,
                   to_char(-1) val,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M014') description,
                   pk_alert_constant.get_yes bold
              FROM dual
             WHERE l_include_age = pk_alert_constant.g_yes
               AND l_include_gender = pk_alert_constant.g_yes
            UNION
            SELECT 2 rank,
                   'AGE' internal_name,
                   to_char(l_num_age) val,
                   l_desc_age description,
                   pk_alert_constant.get_no bold
              FROM dual
             WHERE l_include_age = pk_alert_constant.g_yes
            UNION
            SELECT 3 rank,
                   'GENDER' internal_name,
                   l_gender val,
                   l_desc_gender description,
                   pk_alert_constant.get_no bold
              FROM dual
             WHERE l_include_gender = pk_alert_constant.g_yes
             ORDER BY rank;
    
        IF l_include_age = pk_alert_constant.g_yes
           OR l_include_gender = pk_alert_constant.g_yes
        THEN
            o_title         := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'CONTENT_BUTTON_T001');
            o_options_title := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'CONTENT_BUTTON_T002');
        END IF;
    
        -- RADIO BUTTONS OPTIONS START HERE
    
        o_radio_title := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'INFO_BUTTON_T003');
    
        OPEN o_radio_button FOR
            SELECT 1 rank, -- provider
                   'INFORMATION_RECIPIENT' internal_name,
                   'PROV' val,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M133') description,
                   pk_alert_constant.get_yes flg_selected
              FROM dual
            UNION
            
            SELECT 2 rank, -- patient
                   'INFORMATION_RECIPIENT' internal_name,
                   'PAT' val,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M134') description,
                   pk_alert_constant.get_no flg_selected
              FROM dual
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_INFO_BUTTON_DETAIL',
                                                     o_error);
    END get_info_button_detail;

    FUNCTION get_cds_elements
    (
        i_id_task_type IN task_type.id_task_type%TYPE,
        i_id           IN VARCHAR2, -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
        o_element_type OUT table_varchar,
        o_id_element   OUT table_varchar
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_task_type = pk_alert_constant.g_task_cds
        THEN
            SELECT cc.id_task_type, cip.id_element
              BULK COLLECT
              INTO o_element_type, o_id_element
              FROM cdr_inst_param cip
              JOIN cdr_parameter cp
                ON cp.id_cdr_parameter = cip.id_cdr_parameter
              JOIN cdr_concept cc
                ON cc.id_cdr_concept = cp.id_cdr_concept
             WHERE cip.id_cdr_instance IN
                   (SELECT xcip.id_cdr_instance
                      FROM cdr_inst_par_action cipa
                      JOIN cdr_inst_param xcip
                        ON xcip.id_cdr_inst_param = cipa.id_cdr_inst_param
                     WHERE cipa.id_cdr_inst_par_action IN (SELECT z.id_cdr_inst_par_action
                                                             FROM cdr_event z
                                                            WHERE z.id_cdr_event = i_id));
        
        ELSIF i_id_task_type = pk_alert_constant.g_task_patient_edu
        THEN
            -- GET elements BY id_cdr_inst_par_action        
            SELECT cc.id_task_type, cip.id_element
              BULK COLLECT
              INTO o_element_type, o_id_element
              FROM cdr_inst_param cip
              JOIN cdr_parameter cp
                ON cp.id_cdr_parameter = cip.id_cdr_parameter
              JOIN cdr_concept cc
                ON cc.id_cdr_concept = cp.id_cdr_concept
             WHERE cip.id_cdr_instance IN (SELECT xcip.id_cdr_instance
                                             FROM cdr_inst_par_action cipa
                                             JOIN cdr_inst_param xcip
                                               ON xcip.id_cdr_inst_param = cipa.id_cdr_inst_param
                                            WHERE cipa.id_cdr_inst_par_action = i_id);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_cds_elements;

    FUNCTION get_cds_url
    (
        i_id_task_type IN task_type.id_task_type%TYPE,
        i_id           IN VARCHAR2, -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
        o_id_links     OUT links.id_links%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_task_type = pk_alert_constant.g_task_cds
        THEN
            SELECT cd.id_links
              INTO o_id_links
              FROM cdr_definition cd
              JOIN cdr_instance ci
                ON ci.id_cdr_definition = cd.id_cdr_definition
             WHERE ci.id_cdr_instance IN
                   (SELECT xcip.id_cdr_instance
                      FROM cdr_inst_par_action cipa
                      JOIN cdr_inst_param xcip
                        ON xcip.id_cdr_inst_param = cipa.id_cdr_inst_param
                     WHERE cipa.id_cdr_inst_par_action IN (SELECT z.id_cdr_inst_par_action
                                                             FROM cdr_event z
                                                            WHERE z.id_cdr_event = i_id));
        
        ELSIF i_id_task_type = pk_alert_constant.g_task_patient_edu
        THEN
            SELECT cd.id_links
              INTO o_id_links
              FROM cdr_definition cd
              JOIN cdr_instance ci
                ON ci.id_cdr_definition = cd.id_cdr_definition
             WHERE ci.id_cdr_instance IN (SELECT xcip.id_cdr_instance
                                            FROM cdr_inst_par_action cipa
                                            JOIN cdr_inst_param xcip
                                              ON xcip.id_cdr_inst_param = cipa.id_cdr_inst_param
                                           WHERE cipa.id_cdr_inst_par_action = i_id);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_cds_url;

    FUNCTION get_task_sys_config_val
    (
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE,
        o_id_content   OUT task_type_info_button.id_sys_config%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            SELECT ttib.id_sys_config
              INTO o_id_content
              FROM task_type_info_button ttib
             WHERE ttib.id_task_type = i_id_task_type;
        
        EXCEPTION
            WHEN OTHERS THEN
                o_id_content := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_task_sys_config_val;

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
    ) RETURN BOOLEAN IS
    
        l_code        table_varchar := table_varchar();
        l_standard    table_varchar := table_varchar();
        l_description table_varchar := table_varchar();
    
        l_temp_code     table_varchar := table_varchar();
        l_content       table_varchar := table_varchar();
        l_temp_standard table_varchar := table_varchar();
    
        l_sent_count INTEGER := 0;
        l_go_direct  BOOLEAN DEFAULT FALSE;
    
        -- elements to get standards
        l_element_type table_varchar := table_varchar();
        l_id_element   table_varchar := table_varchar();
    
        l_temp_element_type table_varchar := table_varchar();
        l_temp_id_element   table_varchar := table_varchar();
    
        l_element_type_number NUMBER;
    
        -- medication
        l_med_desc_rxnorm table_varchar := table_varchar();
    
        l_id_content external_link.id_content%TYPE;
        l_id_links   external_link.id_external_link%TYPE;
        l_url        external_link_soft_inst.normal_link%TYPE;
    
        l_age                   patient.age%TYPE;
        l_gender                patient.gender%TYPE;
        l_information_recipient VARCHAR2(10 CHAR);
        l_include_age           BOOLEAN := FALSE;
        l_include_gender        BOOLEAN := FALSE;
    
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, to_date(to_char(p.dt_deceased, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    
        l_dt_birth    VARCHAR2(100 CHAR);
        l_dt_deceased VARCHAR2(100 CHAR);
        l_num_age     NUMBER;
    
    BEGIN
    
        -- [VALIDATION] - At least one parameter must be filled
        IF i_id_element IS NULL
           AND i_code IS NULL
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- decide what whay to go - DIRECT OR PREPARE DATA
        IF i_id_element IS NOT NULL
           AND i_element_type IS NOT NULL
        THEN
            IF i_id_element.count > 0
            THEN
                -- Group parameters must be equal size
                IF i_element_type.count != i_id_element.count
                THEN
                    RAISE g_other_exception;
                END IF;
                l_go_direct := FALSE;
            END IF;
        END IF;
    
        IF i_code IS NOT NULL
           AND i_standard IS NOT NULL
        THEN
            IF i_code.count > 0
            THEN
                -- Group parameters must be equal size
                IF i_code.count != i_standard.count
                THEN
                    RAISE g_other_exception;
                END IF;
                l_go_direct   := TRUE;
                l_code        := i_code;
                l_standard    := i_standard;
                l_description := i_description;
            END IF;
        END IF;
    
        -- SET EXTERNAL ID_LINKS
        IF i_id_links IS NOT NULL
        THEN
            l_id_links := i_id_links;
        END IF;
    
        -- PREPARE DATA
        IF l_go_direct = FALSE
        THEN
            -- Check area registered for other logic like CDS
            IF i_id_task_type IN (pk_alert_constant.g_task_cds, pk_alert_constant.g_task_patient_edu) -- 83 e 42
            THEN
                -- prepared to receive multiple cds
                FOR i IN i_id_element.first .. i_id_element.last
                LOOP
                    -- GET CDS ELEMENTS 
                    IF NOT get_cds_elements(i_id_task_type => i_id_task_type,
                                            i_id           => i_id_element(i), -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
                                            o_element_type => l_temp_element_type,
                                            o_id_element   => l_temp_id_element)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_element_type := l_element_type MULTISET UNION l_temp_element_type;
                    l_id_element   := l_id_element MULTISET UNION l_temp_id_element;
                
                    IF l_id_links IS NULL
                    THEN
                        -- GET CDS URL
                        IF NOT get_cds_url(i_id_task_type => i_id_task_type,
                                           i_id           => i_id_element(i), -- ID_CDR_EVENT or ID_CDR_INST_PAR_ACTION (dependes if comes from CDS or PATIENT_EDUCATION)
                                           o_id_links     => l_id_links)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END LOOP;
                -- Medication - Receives array id_presc and decomposed to products.
            ELSIF i_id_task_type IN (pk_alert_constant.g_task_medication) -- 51
            THEN
                -- prepared to receive multiple id_presc
                FOR i IN i_id_element.first .. i_id_element.last
                LOOP
                    -- Get the products of a prescription
                    IF NOT pk_api_pfh_in.get_products_by_presc(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_presc      => i_id_element(i),
                                                               o_elements      => l_temp_id_element,
                                                               o_elements_type => l_temp_element_type)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_element_type := l_element_type MULTISET UNION l_temp_element_type;
                    l_id_element   := l_id_element MULTISET UNION l_temp_id_element;
                END LOOP;
                -- all other scenarios treath directly    
            ELSE
                l_element_type := l_element_type MULTISET UNION i_element_type;
                l_id_element   := l_id_element MULTISET UNION i_id_element;
            END IF;
        
            -- DECOMPOSE IDS TO STANDARDS (HL7, TERMINOLOGY)
            g_error := 'DECOMPOSE IDS TO STANDARDS';
            FOR r_elem_type IN 1 .. l_element_type.count
            LOOP
                l_element_type_number := to_number(l_element_type(r_elem_type));
                -- PROBLEMS - DIAGNOSIS
                IF l_element_type_number IN (pk_alert_constant.g_task_problems, pk_alert_constant.g_task_diagnosis) -- 60,63
                THEN
                    l_sent_count := l_sent_count + 1;
                    l_code.extend;
                    l_standard.extend;
                    l_description.extend;
                
                    -- diagnosis is a view is like API so its ok do this here
                    -- Get the Standards for the given diagnosis.
                    SELECT d.code_icd,
                           d.term_international_code,
                           pk_translation.get_translation(i_lang, d.code_diagnosis)
                      INTO l_code(l_sent_count), l_standard(l_sent_count), l_description(l_sent_count)
                      FROM diagnosis d
                     WHERE d.id_diagnosis = l_id_element(r_elem_type);
                
                    -- MEDICATION group
                ELSIF l_element_type_number IN (12) -- medication group
                THEN
                    -- 12 - drug group
                    IF NOT pk_api_pfh_in.get_info_button_med_therap(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_id_elements => table_varchar(l_id_element(r_elem_type)),
                                                                    i_id_patient  => i_id_patient,
                                                                    o_id_rxnorm   => l_temp_code,
                                                                    o_desc_rxnorm => l_med_desc_rxnorm, -- ignored
                                                                    o_terminology => l_temp_standard)
                    
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_code     := l_code MULTISET UNION l_temp_code;
                    l_standard := l_standard MULTISET UNION l_temp_standard;
                    -- medication    
                
                ELSIF l_element_type_number = pk_alert_constant.g_task_medication -- 51
                THEN
                
                    IF NOT pk_api_pfh_in.get_info_button_med(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_elements => table_varchar(l_id_element(r_elem_type)),
                                                             o_id_rxnorm   => l_temp_code,
                                                             o_desc_rxnorm => l_med_desc_rxnorm, -- ignored
                                                             o_terminology => l_temp_standard)
                    
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_code     := l_code MULTISET UNION l_temp_code;
                    l_standard := l_standard MULTISET UNION l_temp_standard;
                    -- lab tests                    
                ELSIF l_element_type_number = pk_alert_constant.g_task_lab_tests -- 11
                THEN
                    IF i_id_task_type IN (pk_alert_constant.g_task_cds, pk_alert_constant.g_task_patient_edu)
                    THEN
                        -- 83 e 42 
                        IF NOT pk_lab_tests_external.get_lab_test_context_help(i_lang                => i_lang,
                                                                               i_prof                => i_prof,
                                                                               i_analysis            => table_varchar(l_id_element(r_elem_type)),
                                                                               i_analysis_result_par => table_number(),
                                                                               o_content             => l_content, -- ignored
                                                                               o_map_target_code     => l_temp_code,
                                                                               o_id_map_set          => l_temp_standard,
                                                                               o_error               => o_error)
                        
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    ELSE
                        IF NOT pk_lab_tests_external.get_lab_test_context_help(i_lang                => i_lang,
                                                                               i_prof                => i_prof,
                                                                               i_analysis            => table_varchar(), -- ignored go's null
                                                                               i_analysis_result_par => table_number(l_id_element(r_elem_type)),
                                                                               o_content             => l_content, -- ignored
                                                                               o_map_target_code     => l_temp_code,
                                                                               o_id_map_set          => l_temp_standard,
                                                                               o_error               => o_error)
                        
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                
                    l_code     := l_code MULTISET UNION l_temp_code;
                    l_standard := l_standard MULTISET UNION l_temp_standard;
                
                ELSIF l_element_type_number = pk_alert_constant.g_task_age
                THEN
                    l_include_age := TRUE;
                ELSIF l_element_type_number = pk_alert_constant.g_task_gender
                THEN
                    l_include_gender := TRUE;
                END IF;
            END LOOP; -- end loop element_types
        END IF; -- end if go direct false
    
        -- GET EXTRA INFO: 'AGE','GENDER'
        IF i_extra_info.exists(1)
        THEN
            FOR c1 IN 1 .. i_extra_info.count
            LOOP
                IF i_extra_info(c1).exists(1)
                THEN
                    -- GET AGE
                    IF i_extra_info(c1) (1) = 'AGE'
                    THEN
                        l_age := to_number(i_extra_info(c1) (2));
                        -- GET GENDER                
                    ELSIF i_extra_info(c1) (1) = 'GENDER'
                    THEN
                        l_gender := i_extra_info(c1) (2);
                    ELSIF i_extra_info(c1) (1) = 'INFORMATION_RECIPIENT'
                    THEN
                        l_information_recipient := i_extra_info(c1) (2);
                    END IF;
                END IF;
            END LOOP;
        ELSE
        
            IF l_include_age = TRUE
               OR l_include_gender = TRUE
            THEN
                -- get patient info (gender, age)
                IF NOT pk_patient.get_pat_info_by_patient(i_lang    => i_lang,
                                                          i_patient => i_id_patient,
                                                          o_gender  => l_gender,
                                                          o_age     => l_age)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'GET CURSOR';
                OPEN c_pat;
                FETCH c_pat
                    INTO l_dt_birth, l_age, l_dt_deceased;
                CLOSE c_pat;
            
                -- convert l_age to days
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_age,
                                                    i_age_format  => 'DAYS');
            
                l_age := l_num_age;
            
                -- set to null if include is false
                IF l_include_age = FALSE
                THEN
                    l_gender := NULL;
                END IF;
            
                IF l_include_gender = FALSE
                THEN
                    l_gender := NULL;
                END IF;
            END IF;
        END IF;
    
        -- GET THE URL CONFIGURED BY ID_LINKS    
        -- GET ID LINKS SINGLE AREAS (OTHER AREAS)
        IF l_id_links IS NULL
           AND i_id_task_type IS NOT NULL
        THEN
            IF NOT
                get_task_sys_config_val(i_prof => i_prof, i_id_task_type => i_id_task_type, o_id_content => l_id_content)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        l_url := pk_links.get_links_val(i_lang => i_lang, i_prof => i_prof, i_id_content => l_id_content);
    
        -- CALL INTER-ALERT TO COMPOSE THE URL
        IF NOT pk_ia_util_url.get_app_url_info_button(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_age                   => l_age,
                                                      i_gender                => l_gender,
                                                      i_information_recipient => l_information_recipient,
                                                      i_url                   => l_url,
                                                      i_app_cfg               => 'INFO_BUTTON', --- Vai ser fixo desta area                                             
                                                      i_episode               => i_id_episode,
                                                      i_patient               => i_id_patient,
                                                      i_code                  => l_code,
                                                      i_standard              => l_standard,
                                                      i_description           => l_description,
                                                      o_url                   => o_url,
                                                      o_flg_show              => o_flg_show,
                                                      o_button                => o_button,
                                                      o_msg_title             => o_msg_title,
                                                      o_msg                   => o_msg,
                                                      o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     o_error.err_desc,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_INFO_BUTTON_URL',
                                                     o_error);
    END get_info_button_url;

    FUNCTION get_med_info_button_url
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc            IN NUMBER,
        o_url                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_product          table_varchar;
        l_id_product_supplier table_varchar;
    
        l_product_f          VARCHAR2(100 CHAR);
        l_product_supplier_f VARCHAR2(100 CHAR);
    
        l_id_content VARCHAR2(20 CHAR) := pk_sysconfig.get_config('CONTENT_BUTTON_VIDAL_EXT_LINK', i_prof);
        l_token      sys_config.value%TYPE := pk_sysconfig.get_config('CONTENT_BUTTON_VIDAL_TOKEN', i_prof);
    
        l_flg_show  VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(1000 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
    
    BEGIN
    
        -- Call the function
    
        IF i_id_product IS NOT NULL
        THEN
            IF NOT pk_rt_med_pfh.get_product_parent(i_id_product          => i_id_product,
                                                    i_id_product_supplier => i_id_product_supplier,
                                                    o_id_parent           => l_product_f,
                                                    o_id_parent_supplier  => l_product_supplier_f)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF NOT pk_ia_util_url.get_app_url_replace(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_app_cfg    => NULL,
                                                      i_replace    => table_varchar(l_token,
                                                                                    pk_api_pfh_in.remove_product_level_tag(l_product_f)),
                                                      i_url        => NULL,
                                                      i_id_content => l_id_content,
                                                      i_begin_tag  => NULL,
                                                      i_end_tag    => NULL,
                                                      o_url        => o_url,
                                                      o_flg_show   => l_flg_show,
                                                      o_button     => l_button,
                                                      o_msg_title  => l_msg_title,
                                                      o_msg        => l_msg,
                                                      o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            pk_rt_med_pfh.get_prod_by_presc(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_presc            => i_id_presc,
                                            o_id_product          => l_id_product,
                                            o_id_product_supplier => l_id_product_supplier);
        
            IF l_id_product.count = 1
            THEN
                IF NOT pk_rt_med_pfh.get_product_parent(i_id_product          => l_id_product(1),
                                                        i_id_product_supplier => l_id_product_supplier(1),
                                                        o_id_parent           => l_product_f,
                                                        o_id_parent_supplier  => l_product_supplier_f)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF NOT pk_ia_util_url.get_app_url_replace(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_app_cfg    => NULL,
                                                          i_replace    => table_varchar(l_token,
                                                                                        pk_api_pfh_in.remove_product_level_tag(l_product_f)),
                                                          i_url        => NULL,
                                                          i_id_content => l_id_content,
                                                          i_begin_tag  => NULL,
                                                          i_end_tag    => NULL,
                                                          o_url        => o_url,
                                                          o_flg_show   => l_flg_show,
                                                          o_button     => l_button,
                                                          o_msg_title  => l_msg_title,
                                                          o_msg        => l_msg,
                                                          o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                IF NOT pk_ia_util_url.get_app_url_replace(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_app_cfg    => NULL,
                                                          i_replace    => table_varchar(l_token),
                                                          i_url        => NULL,
                                                          i_id_content => l_id_content,
                                                          i_begin_tag  => NULL,
                                                          i_end_tag    => NULL,
                                                          o_url        => o_url,
                                                          o_flg_show   => l_flg_show,
                                                          o_button     => l_button,
                                                          o_msg_title  => l_msg_title,
                                                          o_msg        => l_msg,
                                                          o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
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
                                              'GET_MED_INFO_BUTTON_URL',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_med_info_button_url;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_info_button;
/
