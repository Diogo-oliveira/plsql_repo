/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE BODY pk_nnn_ux IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION get_nan_domains
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nan_domains';
    BEGIN
        pk_nan_cfg.get_nan_domains(i_lang => i_lang, i_prof => i_prof, o_data => o_data);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_nan_domains;

    FUNCTION get_nan_classes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_nan_domain IN nan_class.id_nan_domain%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nan_classes';
    BEGIN
    
        pk_nan_cfg.get_nan_classes(i_lang => i_lang, i_prof => i_prof, i_nan_domain => i_nan_domain, o_data => o_data);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_nan_classes;

    FUNCTION get_nan_diagnoses
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_class      IN nan_diagnosis.id_nan_class%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nan_diagnoses';
    BEGIN
        pk_nan_cfg.get_nan_diagnoses(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_nan_class        => i_nan_class,
                                     i_include_inactive => pk_alert_constant.g_no,
                                     i_paging           => i_paging,
                                     i_startindex       => i_startindex,
                                     i_items_per_page   => i_items_per_page,
                                     o_diagnosis        => o_data,
                                     o_total_items      => o_total_items);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_nan_diagnoses;

    FUNCTION get_nan_diagnosis_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_title         OUT VARCHAR2,
        o_content_help  OUT CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nan_diagnosis_info';
        l_obj_nan_diagnosis t_obj_nan_diagnosis;
        l_terminology_info  pk_nnn_in.t_terminology_info_rec;
        l_lob               CLOB;
        l_lst_labels        table_varchar;
        l_hash_labels       pk_types.vc2_hash_table;
    
        -- HTML template used by the "Context Help" screen for NANDA Diagnosis
        --Notice: Do not add spaces or tabs in the following lines that will affect the output in Flash
        k_template_html               CONSTANT pk_types.t_big_byte := '<b>{{NANDA_DIAGNOSIS.NAME}}</b><br>
<br>
<b>{{NNN_CONTENT_M002}}</b> {{NANDA_DIAGNOSIS.NANDA_CODE}}<br>
{{>SECTION_APPROVED}}
{{>SECTION_REVISED}}
{{>SECTION_LOE}}
<br>
<b>{{NNN_CONTENT_M006}}</b><br>
{{NANDA_DIAGNOSIS.DEFINITION}}<br>
<br>
<b>{{NNN_CONTENT_M007}}</b> {{NANDA_DIAGNOSIS.CLASS.DOMAIN.NAME}} ({{NANDA_DIAGNOSIS.CLASS.DOMAIN.DOMAIN_CODE}})<br>
<b>{{NNN_CONTENT_M008}}</b> {{NANDA_DIAGNOSIS.CLASS.NAME}} ({{NANDA_DIAGNOSIS.CLASS.CLASS_CODE}})<br>
<br>
{{>SECTION_REFERENCES}}
<i>
<b>{{COMMON_T038}}</b><br>
<b>{{COMMON_T039}}</b> {{TERMINOLOGY.NAME}} ({{TERMINOLOGY.ABBREVIATION}})<br>
<b>{{COMMON_T041}}</b> {{TERMINOLOGY.VERSION}}<br>
<b>{{COMMON_T042}}</b> {{TERMINOLOGY.COPYRIGHT}}<br>
</i>';
        k_template_section_approved   CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M003}}</b> {{NANDA_DIAGNOSIS.YEAR_APPROVED}}<br>';
        k_template_section_revised    CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M004}}</b> {{NANDA_DIAGNOSIS.YEAR_REVISED}}<br>';
        k_template_section_loe        CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M005}}</b> {{NANDA_DIAGNOSIS.LOE}}<br>';
        k_template_section_references CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M009}}</b><br> {{NANDA_DIAGNOSIS.REFERENCES}}<br><br>';
    BEGIN
    
        -- Gets info about diagnosis and what terminology version belongs to it
        l_obj_nan_diagnosis := pk_nan_model.get_nan_diagnosis(i_lang => i_lang, i_nan_diagnosis => i_nan_diagnosis);
        l_terminology_info  := pk_nan_model.get_terminology_information(i_nan_diagnosis => i_nan_diagnosis);
    
        -- Gets labels    
        l_lst_labels := table_varchar(pk_nnn_constant.g_mcode_nanda,
                                      pk_nnn_constant.g_mcode_nanda_code,
                                      pk_nnn_constant.g_mcode_approved,
                                      pk_nnn_constant.g_mcode_revised,
                                      pk_nnn_constant.g_mcode_loe,
                                      pk_nnn_constant.g_mcode_definition,
                                      pk_nnn_constant.g_mcode_domain,
                                      pk_nnn_constant.g_mcode_class,
                                      pk_nnn_constant.g_mcode_references,
                                      pk_nnn_constant.g_mcode_terminology_info,
                                      pk_nnn_constant.g_mcode_terminology_name,
                                      pk_nnn_constant.g_mcode_terminology_version,
                                      pk_nnn_constant.g_mcode_terminology_copyright);
    
        IF NOT pk_message.get_message_array(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_code_msg_arr        => l_lst_labels,
                                            io_desc_msg_hashtable => l_hash_labels)
        THEN
            g_error := 'Error found while calling PK_MESSAGE.GET_MESSAGE_ARRAY';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        -- Format the content help to return
    
        -- NANDA-I Diagnosis:        
        o_title := l_hash_labels(pk_nnn_constant.g_mcode_nanda);
    
        dbms_lob.createtemporary(lob_loc => l_lob, cache => TRUE);
    
        -- Apply template html
        dbms_lob.append(l_lob, k_template_html);
    
        -- Evaluate sections
    
        -- Approved 
        IF l_obj_nan_diagnosis.year_approved IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_APPROVED}}', k_template_section_approved);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_APPROVED}}', '');
        END IF;
    
        -- Revised
        IF l_obj_nan_diagnosis.year_revised IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_REVISED}}', k_template_section_revised);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_REVISED}}', '');
        END IF;
    
        -- LoE
        IF l_obj_nan_diagnosis.loe IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_LOE}}', k_template_section_loe);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_LOE}}', '');
        END IF;
    
        IF l_obj_nan_diagnosis.references IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', k_template_section_references);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', '');
        END IF;
    
        -- Adds diagnosis data into the same hash table that holds labels and that will be used to render the given template
    
        -- diagnosisName
        l_hash_labels('NANDA_DIAGNOSIS.NAME') := l_obj_nan_diagnosis.name;
        -- nandaCode
        l_hash_labels('NANDA_DIAGNOSIS.NANDA_CODE') := to_char(l_obj_nan_diagnosis.nanda_code,
                                                               pk_nan_model.g_nanda_code_format);
        -- approved        
        l_hash_labels('NANDA_DIAGNOSIS.YEAR_APPROVED') := l_obj_nan_diagnosis.year_approved;
        -- revised        
        l_hash_labels('NANDA_DIAGNOSIS.YEAR_REVISED') := l_obj_nan_diagnosis.year_revised;
        -- loe        
        l_hash_labels('NANDA_DIAGNOSIS.LOE') := l_obj_nan_diagnosis.loe;
        -- definition
        l_hash_labels('NANDA_DIAGNOSIS.DEFINITION') := l_obj_nan_diagnosis.definition;
    
        -- domainName
        l_hash_labels('NANDA_DIAGNOSIS.CLASS.DOMAIN.NAME') := l_obj_nan_diagnosis.class.domain.name;
        --domainCode
        l_hash_labels('NANDA_DIAGNOSIS.CLASS.DOMAIN.DOMAIN_CODE') := l_obj_nan_diagnosis.class.domain.domain_code;
        -- className
        l_hash_labels('NANDA_DIAGNOSIS.CLASS.NAME') := l_obj_nan_diagnosis.class.name;
        -- classCode
        l_hash_labels('NANDA_DIAGNOSIS.CLASS.CLASS_CODE') := l_obj_nan_diagnosis.class.class_code;
    
        -- references
        l_hash_labels('NANDA_DIAGNOSIS.REFERENCES') := l_obj_nan_diagnosis.references;
    
        -- terminologyName
        l_hash_labels('TERMINOLOGY.NAME') := pk_translation.get_translation(i_lang, l_terminology_info.code_terminology);
        -- terminologyAbbreviation
        l_hash_labels('TERMINOLOGY.ABBREVIATION') := pk_translation.get_translation(i_lang,
                                                                                    l_terminology_info.code_abbreviation);
        -- terminologyVersion
        l_hash_labels('TERMINOLOGY.VERSION') := pk_translation.get_translation(i_lang, l_terminology_info.code_version);
        -- terminologyCopyright
        l_hash_labels('TERMINOLOGY.COPYRIGHT') := pk_translation.get_translation(i_lang,
                                                                                 l_terminology_info.code_copyright);
    
        -- Render the given template with the given data.
        pk_nnn_core.render_template(io_template => l_lob, i_hash_values => l_hash_labels);
    
        -- Remove line feeds
        l_lob := REPLACE(l_lob, chr(10), '');
    
        o_content_help := l_lob;
        dbms_lob.freetemporary(lob_loc => l_lob);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            dbms_lob.freetemporary(lob_loc => l_lob);
            RETURN FALSE;
    END get_nan_diagnosis_info;

    FUNCTION get_defined_characteristics
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_defined_characteristics';
    BEGIN
    
        pk_nan_model.get_defined_characteristics(i_lang           => i_lang,
                                                 i_nan_diagnosis  => i_nan_diagnosis,
                                                 i_paging         => i_paging,
                                                 i_startindex     => i_startindex,
                                                 i_items_per_page => i_items_per_page,
                                                 o_data           => o_data,
                                                 o_total_items    => o_total_items);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_defined_characteristics;

    FUNCTION get_related_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_related_factors';
    BEGIN
    
        pk_nan_model.get_related_factors(i_lang           => i_lang,
                                         i_nan_diagnosis  => i_nan_diagnosis,
                                         i_paging         => i_paging,
                                         i_startindex     => i_startindex,
                                         i_items_per_page => i_items_per_page,
                                         o_data           => o_data,
                                         o_total_items    => o_total_items);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_related_factors;

    FUNCTION get_risk_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_risk_factors';
    BEGIN
    
        pk_nan_model.get_risk_factors(i_lang           => i_lang,
                                      i_nan_diagnosis  => i_nan_diagnosis,
                                      i_paging         => i_paging,
                                      i_startindex     => i_startindex,
                                      i_items_per_page => i_items_per_page,
                                      o_data           => o_data,
                                      o_total_items    => o_total_items);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_risk_factors;

    FUNCTION get_noc_outcomes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_noc_outcomes';
    BEGIN
        pk_noc_cfg.get_noc_outcomes(i_prof => i_prof, i_nan_diagnosis => i_nan_diagnosis, o_outcomes => o_data);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_noc_outcomes;

    FUNCTION get_noc_outcome_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_noc_outcome  IN noc_outcome.id_noc_outcome%TYPE,
        o_title        OUT VARCHAR2,
        o_content_help OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_noc_outcome_info';
        l_obj_noc_outcome  t_obj_noc_outcome;
        l_terminology_info pk_nnn_in.t_terminology_info_rec;
        l_lob              CLOB;
        l_lst_labels       table_varchar;
        l_hash_labels      pk_types.vc2_hash_table;
        -- HTML template used by the "Context Help" screen for NOC Outcome
        --Notice: Do not add spaces or tabs in the following lines that will affect the output in Flash
        k_template_html               CONSTANT pk_types.t_big_byte := '<b>{{NOC_OUTCOME.NAME}}</b><br>
<br>
<b>{{NNN_CONTENT_M011}}</b> {{NOC_OUTCOME.NOC_CODE}}<br>
<b>{{NNN_CONTENT_M014}}</b> {{NOC_OUTCOME.NOC_SCALE}}<br>
<br>
<b>{{NNN_CONTENT_M006}}</b><br>
{{NOC_OUTCOME.DEFINITION}}<br>
<br>
<b>{{NNN_CONTENT_M007}}</b> {{NOC_OUTCOME.CLASS.DOMAIN.NAME}} ({{NOC_OUTCOME.CLASS.DOMAIN.DOMAIN_CODE}})<br>
<b>{{NNN_CONTENT_M008}}</b> {{NOC_OUTCOME.CLASS.NAME}} ({{NOC_OUTCOME.CLASS.CLASS_CODE}})<br>
<br>
{{>SECTION_REFERENCES}}
<i>
<b>{{COMMON_T038}}</b><br>
<b>{{COMMON_T039}}</b> {{TERMINOLOGY.NAME}} ({{TERMINOLOGY.ABBREVIATION}})<br>
<b>{{COMMON_T041}}</b> {{TERMINOLOGY.VERSION}}<br>
<b>{{COMMON_T042}}</b> {{TERMINOLOGY.COPYRIGHT}}<br>
</i>';
        k_template_section_references CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M009}}</b><br> {{NOC_OUTCOME.REFERENCES}}<br><br>';
    BEGIN
        -- Gets info about outcome and what terminology version belongs to it
        l_obj_noc_outcome  := pk_noc_model.get_noc_outcome(i_lang => i_lang, i_noc_outcome => i_noc_outcome);
        l_terminology_info := pk_noc_model.get_terminology_information(i_noc_outcome => i_noc_outcome);
    
        -- Gets labels    
        l_lst_labels := table_varchar(pk_nnn_constant.g_mcode_noc,
                                      pk_nnn_constant.g_mcode_noc_code,
                                      pk_nnn_constant.g_mcode_noc_scale,
                                      pk_nnn_constant.g_mcode_definition,
                                      pk_nnn_constant.g_mcode_domain,
                                      pk_nnn_constant.g_mcode_class,
                                      pk_nnn_constant.g_mcode_references,
                                      pk_nnn_constant.g_mcode_terminology_info,
                                      pk_nnn_constant.g_mcode_terminology_name,
                                      pk_nnn_constant.g_mcode_terminology_version,
                                      pk_nnn_constant.g_mcode_terminology_copyright);
    
        IF NOT pk_message.get_message_array(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_code_msg_arr        => l_lst_labels,
                                            io_desc_msg_hashtable => l_hash_labels)
        THEN
            g_error := 'Error found while calling PK_MESSAGE.GET_MESSAGE_ARRAY';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        -- Format the content help to return
    
        -- NOC Outcome:        
        o_title := l_hash_labels(pk_nnn_constant.g_mcode_noc);
    
        dbms_lob.createtemporary(lob_loc => l_lob, cache => TRUE);
    
        -- Apply template html
        dbms_lob.append(l_lob, k_template_html);
    
        -- Evaluate sections
        IF l_obj_noc_outcome.references IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', k_template_section_references);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', '');
        END IF;
    
        -- Adds outcome data into the same hash table that holds labels and that will be used to render the given template
    
        -- outcomeName
        l_hash_labels('NOC_OUTCOME.NAME') := l_obj_noc_outcome.name;
        -- nocCode
        l_hash_labels('NOC_OUTCOME.NOC_CODE') := to_char(l_obj_noc_outcome.noc_code, pk_noc_model.g_noc_code_format);
        -- scale        
        l_hash_labels('NOC_OUTCOME.NOC_SCALE') := l_obj_noc_outcome.noc_scale.desc_noc_scale;
        -- definition
        l_hash_labels('NOC_OUTCOME.DEFINITION') := l_obj_noc_outcome.definition;
        -- domain
        l_hash_labels('NOC_OUTCOME.CLASS.DOMAIN.NAME') := l_obj_noc_outcome.class.domain.name;
        -- domainCode
        l_hash_labels('NOC_OUTCOME.CLASS.DOMAIN.DOMAIN_CODE') := l_obj_noc_outcome.class.domain.domain_code;
        -- class
        l_hash_labels('NOC_OUTCOME.CLASS.NAME') := l_obj_noc_outcome.class.name;
        -- classCode
        l_hash_labels('NOC_OUTCOME.CLASS.CLASS_CODE') := l_obj_noc_outcome.class.class_code;
        -- references
        l_hash_labels('NOC_OUTCOME.REFERENCES') := l_obj_noc_outcome.references;
        -- terminologyName
        l_hash_labels('TERMINOLOGY.NAME') := pk_translation.get_translation(i_lang, l_terminology_info.code_terminology);
        -- terminologyAbbreviation
        l_hash_labels('TERMINOLOGY.ABBREVIATION') := pk_translation.get_translation(i_lang,
                                                                                    l_terminology_info.code_abbreviation);
        -- terminologyVersion
        l_hash_labels('TERMINOLOGY.VERSION') := pk_translation.get_translation(i_lang, l_terminology_info.code_version);
        -- terminologyCopyright
        l_hash_labels('TERMINOLOGY.COPYRIGHT') := pk_translation.get_translation(i_lang,
                                                                                 l_terminology_info.code_copyright);
    
        -- Render the given template with the given data.
        pk_nnn_core.render_template(io_template => l_lob, i_hash_values => l_hash_labels);
    
        -- Remove line feeds
        l_lob := REPLACE(l_lob, chr(10), '');
    
        o_content_help := l_lob;
        dbms_lob.freetemporary(lob_loc => l_lob);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            dbms_lob.freetemporary(lob_loc => l_lob);
            RETURN FALSE;
    END get_noc_outcome_info;

    FUNCTION get_noc_indicators
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_noc_outcome IN noc_outcome.id_noc_outcome %TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_noc_indicators';
    BEGIN
        pk_noc_cfg.get_noc_indicators(i_prof => i_prof, i_noc_outcome => i_noc_outcome, o_indicators => o_data);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_noc_indicators;

    FUNCTION get_noc_scale
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_noc_scale       IN noc_scale.id_noc_scale%TYPE,
        i_flg_option_none IN VARCHAR,
        o_scale_info      OUT pk_types.cursor_type,
        o_scale_levels    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_noc_scale';
    BEGIN
        pk_noc_model.get_scale(i_noc_scale       => i_noc_scale,
                               i_flg_option_none => i_flg_option_none,
                               o_scale_info      => o_scale_info,
                               o_scale_levels    => o_scale_levels);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_scale_info);
            pk_types.open_my_cursor(o_scale_levels);
            RETURN FALSE;
    END get_noc_scale;

    FUNCTION get_nic_interventions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nic_interventions';
    BEGIN
        IF i_noc_outcome IS NOT NULL
        THEN
            pk_nic_cfg.get_inst_interventions(i_prof          => i_prof,
                                              i_noc_outcome   => i_noc_outcome,
                                              i_nan_diagnosis => i_nan_diagnosis,
                                              o_interventions => o_data);
        ELSE
            pk_nic_cfg.get_inst_interventions(i_prof          => i_prof,
                                              i_nan_diagnosis => i_nan_diagnosis,
                                              o_interventions => o_data);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_nic_interventions;

    FUNCTION get_nic_intervention_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_title            OUT VARCHAR2,
        o_content_help     OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nic_intervention_info';
        l_obj_nic_intervention t_obj_nic_intervention;
        l_terminology_info     pk_nnn_in.t_terminology_info_rec;
        l_lob                  CLOB;
        l_lst_labels           table_varchar;
        l_hash_labels          pk_types.vc2_hash_table;
        -- HTML template used by the "Context Help" screen for NIC Intervention
        --Notice: Do not add spaces or tabs in the following lines that will affect the output in Flash
        k_template_html               CONSTANT pk_types.t_big_byte := '<b>{{NIC_INTERVENTION.NAME}}</b><br>
<br>
<b>{{NNN_CONTENT_M013}}</b> {{NIC_INTERVENTION.NIC_CODE}}<br>
<br>
<b>{{NNN_CONTENT_M006}}</b><br>
{{NIC_INTERVENTION.DEFINITION}}<br>
<br>
<b>{{NNN_CONTENT_M007}}</b> {{NIC_INTERVENTION.CLASS.DOMAIN.NAME}} ({{NIC_INTERVENTION.CLASS.DOMAIN.DOMAIN_CODE}})<br>
<b>{{NNN_CONTENT_M008}}</b> {{NIC_INTERVENTION.CLASS.NAME}} ({{NIC_INTERVENTION.CLASS.CLASS_CODE}})<br>
<br>
{{>SECTION_REFERENCES}}
<i>
<b>{{COMMON_T038}}</b><br>
<b>{{COMMON_T039}}</b> {{TERMINOLOGY.NAME}} ({{TERMINOLOGY.ABBREVIATION}})<br>
<b>{{COMMON_T041}}</b> {{TERMINOLOGY.VERSION}}<br>
<b>{{COMMON_T042}}</b> {{TERMINOLOGY.COPYRIGHT}}<br>
</i>';
        k_template_section_references CONSTANT pk_types.t_big_byte := '<b>{{NNN_CONTENT_M009}}</b><br> {{NIC_INTERVENTION.REFERENCES}}<br><br>';
    BEGIN
        -- Gets info about intervention and what terminology version belongs to it
        l_obj_nic_intervention := pk_nic_model.get_nic_intervention(i_lang             => i_lang,
                                                                    i_nic_intervention => i_nic_intervention);
        l_terminology_info     := pk_nic_model.get_terminology_information(i_nic_intervention => i_nic_intervention);
    
        -- Gets labels    
        l_lst_labels := table_varchar(pk_nnn_constant.g_mcode_nic,
                                      pk_nnn_constant.g_mcode_nic_code,
                                      pk_nnn_constant.g_mcode_definition,
                                      pk_nnn_constant.g_mcode_domain,
                                      pk_nnn_constant.g_mcode_class,
                                      pk_nnn_constant.g_mcode_references,
                                      pk_nnn_constant.g_mcode_terminology_info,
                                      pk_nnn_constant.g_mcode_terminology_name,
                                      pk_nnn_constant.g_mcode_terminology_version,
                                      pk_nnn_constant.g_mcode_terminology_copyright);
    
        IF NOT pk_message.get_message_array(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_code_msg_arr        => l_lst_labels,
                                            io_desc_msg_hashtable => l_hash_labels)
        THEN
            g_error := 'Error found while calling PK_MESSAGE.GET_MESSAGE_ARRAY';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        -- Format the content help to return
    
        -- Nursing Interventions Classification:        
        o_title := l_hash_labels(pk_nnn_constant.g_mcode_nic);
    
        dbms_lob.createtemporary(lob_loc => l_lob, cache => TRUE);
    
        -- Apply template html
        dbms_lob.append(l_lob, k_template_html);
    
        -- Evaluate sections
        IF l_obj_nic_intervention.references IS NOT NULL
        THEN
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', k_template_section_references);
        ELSE
            l_lob := REPLACE(l_lob, '{{>SECTION_REFERENCES}}', '');
        END IF;
    
        -- Adds intervention data into the same hash table that holds labels and that will be used to render the given template
    
        -- interventionName
        l_hash_labels('NIC_INTERVENTION.NAME') := l_obj_nic_intervention.name;
        -- nicCode
        l_hash_labels('NIC_INTERVENTION.NIC_CODE') := to_char(l_obj_nic_intervention.nic_code,
                                                              pk_nic_model.g_nic_code_format);
        -- definition
        l_hash_labels('NIC_INTERVENTION.DEFINITION') := l_obj_nic_intervention.definition;
        -- domain
        l_hash_labels('NIC_INTERVENTION.CLASS.DOMAIN.NAME') := l_obj_nic_intervention.lst_class(1).domain.name;
        -- domainCode
        l_hash_labels('NIC_INTERVENTION.CLASS.DOMAIN.DOMAIN_CODE') := l_obj_nic_intervention.lst_class(1)
                                                                      .domain.domain_code;
        -- class
        l_hash_labels('NIC_INTERVENTION.CLASS.NAME') := l_obj_nic_intervention.lst_class(1).name;
        -- classCode
        l_hash_labels('NIC_INTERVENTION.CLASS.CLASS_CODE') := l_obj_nic_intervention.lst_class(1).class_code;
        -- references
        l_hash_labels('NIC_INTERVENTION.REFERENCES') := l_obj_nic_intervention.references;
    
        -- terminologyName
        l_hash_labels('TERMINOLOGY.NAME') := pk_translation.get_translation(i_lang, l_terminology_info.code_terminology);
        -- terminologyAbbreviation
        l_hash_labels('TERMINOLOGY.ABBREVIATION') := pk_translation.get_translation(i_lang,
                                                                                    l_terminology_info.code_abbreviation);
        -- terminologyVersion
        l_hash_labels('TERMINOLOGY.VERSION') := pk_translation.get_translation(i_lang, l_terminology_info.code_version);
        -- terminologyCopyright
        l_hash_labels('TERMINOLOGY.COPYRIGHT') := pk_translation.get_translation(i_lang,
                                                                                 l_terminology_info.code_copyright);
    
        -- Render the given template with the given data.
        pk_nnn_core.render_template(io_template => l_lob, i_hash_values => l_hash_labels);
    
        -- Remove line feeds
        l_lob := REPLACE(l_lob, chr(10), '');
    
        o_content_help := l_lob;
        dbms_lob.freetemporary(lob_loc => l_lob);
        RETURN TRUE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            dbms_lob.freetemporary(lob_loc => l_lob);
            RETURN FALSE;
    END get_nic_intervention_info;

    FUNCTION get_nic_activities
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_data             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nic_activities';
    BEGIN
        pk_nic_cfg.get_inst_activities(i_prof             => i_prof,
                                       i_nic_intervention => i_nic_intervention,
                                       o_activities       => o_data);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_nic_activities;

    FUNCTION get_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'check_epis_nan_diagnosis';
    BEGIN
        pk_nnn_core.get_prn_list(i_lang => i_lang, o_list => o_list);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_prn_list;

    FUNCTION get_time_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_time_list';
    BEGIN
    
        pk_nnn_core.get_time_list(i_lang => i_lang,
                                  i_inst => i_prof.institution,
                                  i_soft => i_prof.software,
                                  o_time => o_time);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_time);
            RETURN FALSE;
    END get_time_list;

    FUNCTION get_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_priority_list';
    BEGIN
    
        pk_nnn_core.get_priority_list(i_lang => i_lang, o_list => o_list);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_priority_list;

    FUNCTION get_diag_eval_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_diagnosis_status_list';
    BEGIN
        g_error := 'GET DOMAIN';
        RETURN pk_sysdomain.get_values_domain(i_code_dom      => pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                              i_lang          => i_lang,
                                              o_data          => o_list,
                                              i_vals_included => NULL,
                                              i_vals_excluded => table_varchar(pk_nnn_constant.g_diagnosis_status_cancelled));
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diag_eval_status_list;

    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_priority      IN nnn_epis_activity.flg_priority%TYPE,
        i_flg_prn           IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn         IN CLOB,
        i_flg_time          IN nnn_epis_activity.flg_time%TYPE,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        o_instructions      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_instructions';
    BEGIN
        o_instructions := pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_flg_priority      => i_flg_priority,
                                                       i_flg_prn           => i_flg_prn,
                                                       i_notes_prn         => i_notes_prn,
                                                       i_flg_time          => i_flg_time,
                                                       i_order_recurr_plan => i_order_recurr_plan,
                                                       i_mask              => pk_nnn_constant.g_inst_format_mask_default);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_instructions;

    FUNCTION get_pat_nursing_careplan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diagnosis    OUT pk_types.cursor_type,
        o_outcome      OUT pk_types.cursor_type,
        o_indicator    OUT pk_types.cursor_type,
        o_intervention OUT pk_types.cursor_type,
        o_activity     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_nursing_careplan';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
    
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="2/6/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
    
        pk_nnn_core.get_pat_nursing_careplan(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_scope        => l_scope,
                                             i_scope_type   => l_scope_type,
                                             o_diagnosis    => o_diagnosis,
                                             o_outcome      => o_outcome,
                                             o_indicator    => o_indicator,
                                             o_intervention => o_intervention,
                                             o_activity     => o_activity);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_outcome);
            pk_types.open_my_cursor(o_indicator);
            pk_types.open_my_cursor(o_intervention);
            pk_types.open_my_cursor(o_activity);
            RETURN FALSE;
    END get_pat_nursing_careplan;

    FUNCTION get_pat_evaluations_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_paging       IN VARCHAR2,
        i_start_column IN NUMBER,
        i_num_columns  IN NUMBER,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_evaluations_view';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
    
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="2/6/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
    
        pk_nnn_core.get_pat_evaluations_view(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_scope        => l_scope,
                                             i_scope_type   => l_scope_type,
                                             i_paging       => i_paging,
                                             i_start_column => i_start_column,
                                             i_num_columns  => i_num_columns,
                                             o_rows         => o_rows,
                                             o_cols         => o_cols);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_rows);
            pk_types.open_my_cursor(o_cols);
            RETURN FALSE;
    END get_pat_evaluations_view;

    FUNCTION get_pat_plan_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_paging       IN VARCHAR2,
        i_start_column IN NUMBER,
        i_num_columns  IN NUMBER,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_plan_view';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
    
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="2/6/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
    
        pk_nnn_core.get_pat_plan_view(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_patient      => i_patient,
                                      i_scope        => l_scope,
                                      i_scope_type   => l_scope_type,
                                      i_paging       => i_paging,
                                      i_start_column => i_start_column,
                                      i_num_columns  => i_num_columns,
                                      o_rows         => o_rows,
                                      o_cols         => o_cols);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_rows);
            pk_types.open_my_cursor(o_cols);
            RETURN FALSE;
    END get_pat_plan_view;

    FUNCTION get_pat_unresolved_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_unresolved_diagnosis';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
    
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="2/6/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
    
        pk_nnn_core.get_pat_unresolved_diagnosis(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_patient    => i_patient,
                                                 i_scope      => l_scope,
                                                 i_scope_type => l_scope_type,
                                                 o_diagnosis  => o_diagnosis);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_pat_unresolved_diagnosis;

    FUNCTION get_pat_unresolved_outcome
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_outcome OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_unresolved_outcome';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
    
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="6/13/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
    
        pk_nnn_core.get_pat_unresolved_outcome(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_patient    => i_patient,
                                               i_scope      => l_scope,
                                               i_scope_type => l_scope_type,
                                               o_outcome    => o_outcome);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_outcome);
            RETURN FALSE;
    END get_pat_unresolved_outcome;

    FUNCTION get_inst_nursing_careplans
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_sncp  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_nursing_careplan';
    BEGIN
        -- TODO: Code Here and remove open_cursor
        pk_types.open_my_cursor(o_sncp);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sncp);
            RETURN FALSE;
    END get_inst_nursing_careplans;

    FUNCTION check_epis_nan_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        o_exists        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'check_epis_nan_diagnosis';
    BEGIN
        IF pk_nnn_core.check_epis_nan_diagnosis(i_patient       => i_patient,
                                                i_episode       => i_episode,
                                                i_nan_diagnosis => i_nan_diagnosis)
        THEN
            o_exists := pk_alert_constant.g_yes;
        ELSE
            o_exists := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_epis_nan_diagnosis;

    FUNCTION create_default_instructions
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_lst_outcome                IN table_number,
        i_lst_indicator              IN table_number,
        i_lst_activity               IN table_number,
        o_default_outcome_instruct   OUT pk_types.cursor_type,
        o_default_indicator_instruct OUT pk_types.cursor_type,
        o_default_activity_instruct  OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'create_default_instructions';
    BEGIN
        pk_nnn_core.create_default_instructions(i_lang                       => i_lang,
                                                i_prof                       => i_prof,
                                                i_lst_outcome                => i_lst_outcome,
                                                i_lst_indicator              => i_lst_indicator,
                                                i_lst_activity               => i_lst_activity,
                                                o_default_outcome_instruct   => o_default_outcome_instruct,
                                                o_default_indicator_instruct => o_default_indicator_instruct,
                                                o_default_activity_instruct  => o_default_activity_instruct);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_default_outcome_instruct);
            pk_types.open_my_cursor(o_default_indicator_instruct);
            pk_types.open_my_cursor(o_default_activity_instruct);
            RETURN FALSE;
        
    END create_default_instructions;

    FUNCTION create_care_plan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_jsn_careplan IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'create_care_plan';
    BEGIN
        pk_nnn_api_db.create_care_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_patient      => i_patient,
                                       i_episode      => i_episode,
                                       i_jsn_careplan => i_jsn_careplan);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_care_plan;

    FUNCTION get_actions_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_lst_from_state IN table_varchar,
        i_lst_entries    IN table_number,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_actions_permissions';
    BEGIN
        pk_nnn_core.get_actions_permissions(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_subject        => i_subject,
                                            i_lst_from_state => i_lst_from_state,
                                            i_lst_entries    => i_lst_entries,
                                            o_actions        => o_actions);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_permissions;

    FUNCTION get_actions_staging_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN action.subject%TYPE,
        i_staging_data IN CLOB,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_actions_staging_area';
    BEGIN
        pk_nnn_core.get_actions_staging_area(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_subject      => i_subject,
                                             i_staging_data => i_staging_data,
                                             o_actions      => o_actions);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_staging_area;

    FUNCTION get_actions_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_actions_add_button';
    BEGIN
        pk_nnn_core.get_actions_add_button(i_lang => i_lang, i_prof => i_prof, o_actions => o_actions);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_add_button;

    FUNCTION get_nic_filter_dropdown
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_dropdown OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_nic_filter_dropdown';
        l_scope      NUMBER(24);
        l_scope_type VARCHAR2(1 CHAR);
    BEGIN
        /*
        TODO: owner="ariel.machado" category="Improvement" priority="3 - Low" created="6/13/2014"
        text="Be possible to dynamically select the scope according with a configuration"
        */
        l_scope_type := pk_alert_constant.g_scope_type_episode;
        l_scope      := i_episode;
        pk_nnn_core.get_nic_filter_dropdown(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_patient    => i_patient,
                                            i_scope      => l_scope,
                                            i_scope_type => l_scope_type,
                                            o_dropdown   => o_dropdown);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_dropdown);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nic_filter_dropdown;

    FUNCTION get_epis_nan_diagnosis_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nan_diagnosis_det';
    BEGIN
        pk_nnn_api_db.get_epis_nan_diagnosis_det(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                                 i_flg_detail_type    => i_flg_detail_type,
                                                 o_detail             => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_nan_diagnosis_det;

    FUNCTION get_epis_nan_diagnosis_evl_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nan_diagnosis_evl_det';
    BEGIN
        pk_nnn_api_db.get_epis_nan_diagnosis_evl_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_nnn_epis_diag_eval => i_nnn_epis_diag_eval,
                                                     i_flg_detail_type    => i_flg_detail_type,
                                                     o_detail             => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_nan_diagnosis_evl_det;

    FUNCTION get_epis_noc_outcome_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_detail_type  IN VARCHAR2,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_det';
    BEGIN
        pk_nnn_api_db.get_epis_noc_outcome_det(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_nnn_epis_outcome => i_nnn_epis_outcome,
                                               i_flg_detail_type  => i_flg_detail_type,
                                               o_detail           => o_detail);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_noc_outcome_det;

    FUNCTION get_epis_noc_outcome_eval_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_eval_det';
    BEGIN
        pk_nnn_api_db.get_epis_noc_outcome_eval_det(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_nnn_epis_outcome_eval => i_nnn_epis_outcome_eval,
                                                    i_flg_detail_type       => i_flg_detail_type,
                                                    o_detail                => o_detail);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_noc_outcome_eval_det;

    FUNCTION get_epis_noc_indicator_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_indicator_det';
    BEGIN
        pk_nnn_api_db.get_epis_noc_indicator_det(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_nnn_epis_indicator => i_nnn_epis_indicator,
                                                 i_flg_detail_type    => i_flg_detail_type,
                                                 o_detail             => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_noc_indicator_det;

    FUNCTION get_epis_noc_indicator_evl_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_indicator_evl_det';
    BEGIN
        pk_nnn_api_db.get_epis_noc_indicator_evl_det(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_nnn_epis_outcome  => i_nnn_epis_outcome,
                                                     i_nnn_epis_ind_eval => i_nnn_epis_ind_eval,
                                                     i_flg_detail_type   => i_flg_detail_type,
                                                     o_detail            => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_noc_indicator_evl_det;

    FUNCTION get_epis_nic_intervention_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_intervention_det';
    BEGIN
        pk_nnn_api_db.get_epis_nic_intervention_det(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_nnn_epis_intervention => i_nnn_epis_intervention,
                                                    i_flg_detail_type       => i_flg_detail_type,
                                                    o_detail                => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_nic_intervention_det;

    FUNCTION get_epis_nic_activity_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_activity_det';
    BEGIN
        pk_nnn_api_db.get_epis_nic_activity_det(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_nnn_epis_activity => i_nnn_epis_activity,
                                                i_flg_detail_type   => i_flg_detail_type,
                                                o_detail            => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_nic_activity_det;

    FUNCTION get_epis_nic_activity_det_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_activity_det_det';
    BEGIN
        pk_nnn_api_db.get_epis_nic_activity_det_det(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_nnn_epis_activity_det => i_nnn_epis_activity_det,
                                                    i_flg_detail_type       => i_flg_detail_type,
                                                    o_detail                => o_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_nic_activity_det_det;
    ----------------------------------------------------------
    -- NANDA Diagnosis in a Patient's Nursing Care Plan - Methods
    ----------------------------------------------------------

    FUNCTION get_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_diagnosis          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_diagnosis';
    BEGIN
        pk_nnn_core.get_epis_nan_diagnosis(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                           o_diagnosis          => o_diagnosis);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnosis;

    FUNCTION set_diagnosis_update
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nan_diagnosis      IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_dt_diagnosis       IN VARCHAR2,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_notes              IN nnn_epis_diagnosis.edited_diagnosis_name%TYPE,
        i_flg_req_status     IN nnn_epis_diagnosis.flg_req_status%TYPE,
        o_nnn_epis_diagnosis OUT nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_diagnosis_update';
        l_id nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE;
    
    BEGIN
        l_id := pk_nnn_api_db.set_diagnosis_update(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_patient            => i_patient,
                                                   i_episode            => i_episode,
                                                   i_nan_diagnosis      => i_nan_diagnosis,
                                                   i_dt_diagnosis       => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                         i_prof      => i_prof,
                                                                                                         i_timestamp => i_dt_diagnosis,
                                                                                                         i_timezone  => NULL),
                                                   i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                                   i_notes              => i_notes,
                                                   i_flg_req_status     => i_flg_req_status);
        COMMIT;
        o_nnn_epis_diagnosis := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_diagnosis_update;

    FUNCTION set_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_lst_epis_diag IN table_number,
        i_cancel_reason IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN nnn_epis_diagnosis.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_diagnosis_cancel';
    
    BEGIN
        pk_nnn_api_db.set_diagnosis_cancel(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_patient       => i_patient,
                                           i_episode       => i_episode,
                                           i_lst_epis_diag => i_lst_epis_diag,
                                           i_cancel_reason => i_cancel_reason,
                                           i_cancel_notes  => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_diagnosis_cancel;

    FUNCTION set_diagnosis_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_dt_evaluation      IN VARCHAR2,
        i_notes              IN CLOB,
        i_lst_nan_relf       IN table_number,
        i_lst_nan_riskf      IN table_number,
        i_lst_nan_defc       IN table_number,
        o_nnn_epis_diag_eval OUT nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_diagnosis_evaluate';
        l_id nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;
    
    BEGIN
        l_id := pk_nnn_api_db.set_diagnosis_evaluate(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_patient            => i_patient,
                                                     i_episode            => i_episode,
                                                     i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                                     i_nnn_epis_diag_eval => i_nnn_epis_diag_eval,
                                                     i_flg_status         => i_flg_status,
                                                     i_dt_evaluation      => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                           i_prof      => i_prof,
                                                                                                           i_timestamp => i_dt_evaluation,
                                                                                                           i_timezone  => NULL),
                                                     i_notes              => i_notes,
                                                     i_lst_nan_relf       => i_lst_nan_relf,
                                                     i_lst_nan_riskf      => i_lst_nan_riskf,
                                                     i_lst_nan_defc       => i_lst_nan_defc);
    
        COMMIT;
        o_nnn_epis_diag_eval := l_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_diagnosis_evaluate;

    FUNCTION set_diagnosis_evaluate_st
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        o_nnn_epis_diag_eval OUT nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_diagnosis_evaluate_st';
        l_id nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;
    BEGIN
    
        l_id := pk_nnn_api_db.set_diagnosis_evaluate_st(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_patient            => i_patient,
                                                        i_episode            => i_episode,
                                                        i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                                        i_flg_status         => i_flg_status);
    
        COMMIT;
        o_nnn_epis_diag_eval := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_diagnosis_evaluate_st;

    FUNCTION set_diagnosis_eval_cancel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_lst_epis_diag_eval IN table_number,
        i_cancel_reason      IN nnn_epis_diag_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diag_eval.cancel_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_diagnosis_eval_cancel';
    BEGIN
        pk_nnn_api_db.set_diagnosis_eval_cancel(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_patient            => i_patient,
                                                i_episode            => i_episode,
                                                i_lst_epis_diag_eval => i_lst_epis_diag_eval,
                                                i_cancel_reason      => i_cancel_reason,
                                                i_cancel_notes       => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_diagnosis_eval_cancel;

    FUNCTION get_diagnosis_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_eval               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_diagnosis_evaluate';
    BEGIN
        pk_nnn_core.get_epis_nan_diagnosis_eval(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_nnn_epis_diag_eval => i_nnn_epis_diag_eval,
                                                o_eval               => o_eval);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_eval);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_diagnosis_evaluate;

    ----------------------------------------------------------
    -- NOC Outcomes in a Patient's Nursing Care Plan - Methods
    ----------------------------------------------------------

    FUNCTION get_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_outcome          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_outcome';
    BEGIN
        pk_nnn_core.get_epis_noc_outcome(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_nnn_epis_outcome => i_nnn_epis_outcome,
                                         o_outcome          => o_outcome);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_outcome);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_outcome;

    FUNCTION set_outcome_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_outcome.id_patient%TYPE,
        i_episode             IN nnn_epis_outcome.id_episode%TYPE,
        i_noc_outcome         IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_nnn_epis_outcome    IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_episode_origin      IN nnn_epis_outcome.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_outcome.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_outcome.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_outcome.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_outcome.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_outcome.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_outcome.flg_req_status%TYPE,
        o_nnn_epis_outcome    OUT nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_update';
        l_id nnn_epis_outcome.id_nnn_epis_outcome%TYPE;
    BEGIN
        l_id := pk_nnn_api_db.set_outcome_update(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_patient             => i_patient,
                                                 i_episode             => i_episode,
                                                 i_noc_outcome         => i_noc_outcome,
                                                 i_nnn_epis_outcome    => i_nnn_epis_outcome,
                                                 i_episode_origin      => i_episode_origin,
                                                 i_episode_destination => i_episode_destination,
                                                 i_flg_prn             => i_flg_prn,
                                                 i_notes_prn           => i_notes_prn,
                                                 i_flg_time            => i_flg_time,
                                                 i_flg_priority        => i_flg_priority,
                                                 i_order_recurr_plan   => i_order_recurr_plan,
                                                 i_flg_req_status      => i_flg_req_status);
        COMMIT;
        o_nnn_epis_outcome := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_outcome_update;

    FUNCTION set_outcome_cancel
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        i_cancel_reason        IN nnn_epis_outcome.id_cancel_reason%TYPE,
        i_cancel_notes         IN nnn_epis_outcome.cancel_notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_cancel';
    BEGIN
        pk_nnn_api_db.set_outcome_cancel(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_patient              => i_patient,
                                         i_episode              => i_episode,
                                         i_lst_nnn_epis_outcome => i_lst_nnn_epis_outcome,
                                         i_cancel_reason        => i_cancel_reason,
                                         i_cancel_notes         => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_outcome_cancel;

    FUNCTION set_outcome_hold
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_hold';
    BEGIN
        pk_nnn_api_db.set_outcome_hold(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_patient              => i_patient,
                                       i_episode              => i_episode,
                                       i_lst_nnn_epis_outcome => i_lst_nnn_epis_outcome);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_outcome_hold;

    FUNCTION set_outcome_resume
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_resume';
    BEGIN
        pk_nnn_api_db.set_outcome_resume(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_patient              => i_patient,
                                         i_episode              => i_episode,
                                         i_lst_nnn_epis_outcome => i_lst_nnn_epis_outcome);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_outcome_resume;

    FUNCTION get_next_outcome_eval_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        o_eval             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_next_outcome_eval_info';
    BEGIN
        pk_nnn_api_db.get_next_outcome_eval_info(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_nnn_epis_outcome => i_nnn_epis_outcome,
                                                 o_eval             => o_eval);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_eval);
            RETURN FALSE;
    END get_next_outcome_eval_info;

    FUNCTION set_outcome_evaluate
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_outcome_eval.id_patient%TYPE,
        i_episode               IN nnn_epis_outcome_eval.id_episode%TYPE,
        i_nnn_epis_outcome      IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_dt_evaluation         IN VARCHAR2,
        i_target_value          IN nnn_epis_outcome_eval.target_value%TYPE,
        i_outcome_value         IN nnn_epis_outcome_eval.outcome_value%TYPE,
        i_notes                 IN CLOB,
        o_nnn_epis_outcome_eval OUT nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_evaluate';
        l_id nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE;
    BEGIN
        l_id := pk_nnn_api_db.set_outcome_evaluate(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_patient               => i_patient,
                                                   i_episode               => i_episode,
                                                   i_nnn_epis_outcome      => i_nnn_epis_outcome,
                                                   i_nnn_epis_outcome_eval => i_nnn_epis_outcome_eval,
                                                   i_dt_evaluation         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_timestamp => i_dt_evaluation,
                                                                                                            i_timezone  => NULL),
                                                   i_target_value          => i_target_value,
                                                   i_outcome_value         => i_outcome_value,
                                                   i_notes                 => i_notes);
    
        COMMIT;
        o_nnn_epis_outcome_eval := l_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_outcome_evaluate;

    FUNCTION set_outcome_eval_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_outcome_eval IN table_number,
        i_cancel_reason             IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_outcome_eval.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_outcome_eval_cancel';
    BEGIN
        pk_nnn_api_db.set_outcome_eval_cancel(i_lang                      => i_lang,
                                              i_prof                      => i_prof,
                                              i_patient                   => i_patient,
                                              i_episode                   => i_episode,
                                              i_lst_nnn_epis_outcome_eval => i_lst_nnn_epis_outcome_eval,
                                              i_cancel_reason             => i_cancel_reason,
                                              i_cancel_notes              => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_outcome_eval_cancel;

    FUNCTION get_outcome_evaluate
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        o_eval                  OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_outcome_evaluate';
        l_obj_epis_outcome_eval t_obj_nnn_epis_outcome_eval;
        l_obj_epis_outcome      t_obj_nnn_epis_outcome;
        l_obj_noc_outcome       t_obj_noc_outcome;
    BEGIN
        -- Returns a cursor using a more object-oriented approach (as if PL/SQL someday will be OO... )
    
        -- Gets the Evaluation of a NOC Outcome
        l_obj_epis_outcome_eval := pk_nnn_api_db.get_epis_noc_outcome_eval(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => i_nnn_epis_outcome_eval);
    
        -- Gets the NOC Outcome request
        l_obj_epis_outcome := pk_nnn_api_db.get_epis_noc_outcome(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_nnn_epis_outcome => l_obj_epis_outcome_eval.id_nnn_epis_outcome);
    
        -- Gets the NOC Outcome
        l_obj_noc_outcome := pk_noc_model.get_noc_outcome(i_lang        => i_lang,
                                                          i_noc_outcome => l_obj_epis_outcome.id_noc_outcome);
    
        -- Returns just the fields that matters for the UX. 
        -- Notice when using an object in SQL must use alias to identify the fields
        OPEN o_eval FOR
            SELECT l_obj_epis_outcome_eval.id_nnn_epis_outcome_eval id_nnn_epis_outcome_eval,
                   l_obj_epis_outcome_eval.id_nnn_epis_outcome id_nnn_epis_outcome,
                   l_obj_epis_outcome.id_noc_outcome id_noc_outcome,
                   pk_noc_model.get_outcome_name(i_noc_outcome => l_obj_epis_outcome.id_noc_outcome,
                                                 i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                   l_obj_epis_outcome_eval.status.flg_status flg_status,
                   l_obj_epis_outcome_eval.status.desc_flg_status desc_flg_status,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => l_obj_epis_outcome_eval.dt_evaluation,
                                               i_prof => i_prof) dt_evaluation,
                   l_obj_noc_outcome.noc_scale.id_noc_scale id_noc_scale,
                   l_obj_epis_outcome_eval.target_value.scale_level_value target_value,
                   l_obj_epis_outcome_eval.outcome_value.scale_level_value outcome_value,
                   l_obj_epis_outcome_eval.target_value.desc_scale_level_value desc_target_value,
                   l_obj_epis_outcome_eval.outcome_value.desc_scale_level_value desc_outcome_value,
                   l_obj_epis_outcome_eval.notes desc_notes
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_eval);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_outcome_evaluate;

    FUNCTION get_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_indicator          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_indicator';
    BEGIN
        pk_nnn_core.get_epis_noc_indicator(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_nnn_epis_indicator => i_nnn_epis_indicator,
                                           o_indicator          => o_indicator);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_indicator);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_indicator;

    FUNCTION set_indicator_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_indicator.id_patient%TYPE,
        i_episode             IN nnn_epis_indicator.id_episode%TYPE,
        i_noc_indicator       IN nnn_epis_indicator.id_noc_indicator%TYPE,
        i_nnn_epis_indicator  IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_episode_origin      IN nnn_epis_indicator.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_indicator.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_indicator.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_indicator.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_indicator.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_indicator.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_indicator.flg_req_status%TYPE,
        o_nnn_epis_indicator  OUT nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_update';
        l_id nnn_epis_indicator.id_noc_indicator%TYPE;
    BEGIN
        l_id := pk_nnn_api_db.set_indicator_update(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_patient             => i_patient,
                                                   i_episode             => i_episode,
                                                   i_noc_indicator       => i_noc_indicator,
                                                   i_nnn_epis_indicator  => i_nnn_epis_indicator,
                                                   i_episode_origin      => i_episode_origin,
                                                   i_episode_destination => i_episode_destination,
                                                   i_flg_prn             => i_flg_prn,
                                                   i_notes_prn           => i_notes_prn,
                                                   i_flg_time            => i_flg_time,
                                                   i_flg_priority        => i_flg_priority,
                                                   i_order_recurr_plan   => i_order_recurr_plan,
                                                   i_flg_req_status      => i_flg_req_status);
        COMMIT;
        o_nnn_epis_indicator := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_indicator_update;

    FUNCTION get_next_indicator_eval_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_outcome   IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        o_eval               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_next_indicator_eval_info';
    BEGIN
        pk_nnn_api_db.get_next_indicator_eval_info(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_nnn_epis_outcome   => i_nnn_epis_outcome,
                                                   i_nnn_epis_indicator => i_nnn_epis_indicator,
                                                   o_eval               => o_eval);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_eval);
            RETURN FALSE;
    END get_next_indicator_eval_info;

    FUNCTION set_indicator_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN nnn_epis_ind_eval.id_patient%TYPE,
        i_episode            IN nnn_epis_ind_eval.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_ind_eval  IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_dt_evaluation      IN VARCHAR2,
        i_target_value       IN nnn_epis_ind_eval.target_value%TYPE,
        i_indicator_value    IN nnn_epis_ind_eval.indicator_value%TYPE,
        i_notes              IN CLOB,
        o_nnn_epis_ind_eval  OUT nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_evaluate';
        l_id nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE;
    BEGIN
        l_id := pk_nnn_api_db.set_indicator_evaluate(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_patient            => i_patient,
                                                     i_episode            => i_episode,
                                                     i_nnn_epis_indicator => i_nnn_epis_indicator,
                                                     i_nnn_epis_ind_eval  => i_nnn_epis_ind_eval,
                                                     i_dt_evaluation      => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                           i_prof      => i_prof,
                                                                                                           i_timestamp => i_dt_evaluation,
                                                                                                           i_timezone  => NULL),
                                                     i_target_value       => i_target_value,
                                                     i_indicator_value    => i_indicator_value,
                                                     i_notes              => i_notes);
    
        COMMIT;
        o_nnn_epis_ind_eval := l_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_indicator_evaluate;

    FUNCTION set_indicator_eval_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_lst_nnn_epis_ind_eval IN table_number,
        i_cancel_reason         IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_ind_eval.cancel_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_eval_cancel';
    BEGIN
        pk_nnn_api_db.set_indicator_eval_cancel(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_patient               => i_patient,
                                                i_episode               => i_episode,
                                                i_lst_nnn_epis_ind_eval => i_lst_nnn_epis_ind_eval,
                                                i_cancel_reason         => i_cancel_reason,
                                                i_cancel_notes          => i_cancel_notes);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_indicator_eval_cancel;

    FUNCTION get_indicator_evaluate
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_eval              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_indicator_evaluate';
        l_obj_epis_ind_eval  t_obj_nnn_epis_ind_eval;
        l_obj_epis_indicator t_obj_nnn_epis_indicator;
        l_obj_epis_outcome   t_obj_nnn_epis_outcome;
        l_obj_noc_indicator  t_obj_noc_indicator;
    
    BEGIN
        -- Gets the Evaluation of a NOC Indicator
        l_obj_epis_ind_eval := pk_nnn_api_db.get_epis_noc_indicator_eval(i_lang              => i_lang,
                                                                         i_prof              => i_prof,
                                                                         i_nnn_epis_outcome  => i_nnn_epis_outcome,
                                                                         i_nnn_epis_ind_eval => i_nnn_epis_ind_eval);
    
        -- Gets the Indicator request
        l_obj_epis_indicator := pk_nnn_api_db.get_epis_noc_indicator(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_nnn_epis_indicator => l_obj_epis_ind_eval.id_nnn_epis_indicator);
        -- Get the Outcome request                                                                                                  
        l_obj_epis_outcome := pk_nnn_api_db.get_epis_noc_outcome(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_nnn_epis_outcome => i_nnn_epis_outcome);
        -- Gets the NOC Indicator
        l_obj_noc_indicator := pk_noc_model.get_noc_indicator(i_lang          => i_lang,
                                                              i_noc_outcome   => l_obj_epis_outcome.id_noc_outcome,
                                                              i_noc_indicator => l_obj_epis_indicator.id_noc_indicator);
    
        -- Returns just the fields that matters for the UX. 
        -- Notice when using an object in SQL must use alias to identify the fields
        OPEN o_eval FOR
            SELECT l_obj_epis_ind_eval.id_nnn_epis_ind_eval id_nnn_epis_ind_eval,
                   l_obj_epis_ind_eval.id_nnn_epis_indicator id_nnn_epis_indicator,
                   l_obj_epis_indicator.id_noc_indicator id_noc_indicator,
                   pk_noc_model.get_indicator_name(i_noc_indicator => l_obj_epis_indicator.id_noc_indicator) indicator_name,
                   l_obj_epis_ind_eval.status.flg_status flg_status,
                   l_obj_epis_ind_eval.status.desc_flg_status desc_flg_status,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => l_obj_epis_ind_eval.dt_evaluation,
                                               i_prof => i_prof) dt_evaluation,
                   l_obj_noc_indicator.noc_scale.id_noc_scale id_noc_scale,
                   l_obj_epis_ind_eval.target_value.scale_level_value target_value,
                   l_obj_epis_ind_eval.indicator_value.scale_level_value indicator_value,
                   l_obj_epis_ind_eval.target_value.desc_scale_level_value desc_target_value,
                   l_obj_epis_ind_eval.indicator_value.desc_scale_level_value desc_indicator_value,
                   l_obj_epis_ind_eval.notes desc_notes
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_eval);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_indicator_evaluate;

    FUNCTION set_indicator_cancel
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        i_cancel_reason          IN nnn_epis_indicator.id_cancel_reason%TYPE,
        i_cancel_notes           IN nnn_epis_indicator.cancel_notes%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_cancel';
    BEGIN
        pk_nnn_api_db.set_indicator_cancel(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_patient                => i_patient,
                                           i_episode                => i_episode,
                                           i_lst_nnn_epis_indicator => i_lst_nnn_epis_indicator,
                                           i_cancel_reason          => i_cancel_reason,
                                           i_cancel_notes           => i_cancel_notes);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_indicator_cancel;

    FUNCTION set_indicator_hold
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_hold';
    BEGIN
        pk_nnn_api_db.set_indicator_hold(i_lang                   => i_lang,
                                         i_prof                   => i_prof,
                                         i_patient                => i_patient,
                                         i_episode                => i_episode,
                                         i_lst_nnn_epis_indicator => i_lst_nnn_epis_indicator);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_indicator_hold;

    FUNCTION set_indicator_resume
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_indicator_resume';
    BEGIN
        pk_nnn_api_db.set_indicator_resume(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_patient                => i_patient,
                                           i_episode                => i_episode,
                                           i_lst_nnn_epis_indicator => i_lst_nnn_epis_indicator);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_indicator_resume;

    FUNCTION set_intervention_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_cancel_reason             IN nnn_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_intervention.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_intervention_cancel';
    BEGIN
        pk_nnn_api_db.set_intervention_cancel(i_lang                      => i_lang,
                                              i_prof                      => i_prof,
                                              i_patient                   => i_patient,
                                              i_episode                   => i_episode,
                                              i_lst_nnn_epis_intervention => i_lst_nnn_epis_intervention,
                                              i_cancel_reason             => i_cancel_reason,
                                              i_cancel_notes              => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_intervention_cancel;

    FUNCTION set_intervention_hold
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_intervention_hold';
    BEGIN
        pk_nnn_api_db.set_intervention_hold(i_lang                      => i_lang,
                                            i_prof                      => i_prof,
                                            i_patient                   => i_patient,
                                            i_episode                   => i_episode,
                                            i_lst_nnn_epis_intervention => i_lst_nnn_epis_intervention);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_intervention_hold;

    FUNCTION set_intervention_resume
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_intervention_resume';
    BEGIN
        pk_nnn_api_db.set_intervention_resume(i_lang                      => i_lang,
                                              i_prof                      => i_prof,
                                              i_patient                   => i_patient,
                                              i_episode                   => i_episode,
                                              i_lst_nnn_epis_intervention => i_lst_nnn_epis_intervention);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_intervention_resume;

    FUNCTION get_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_activity          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_activity';
    BEGIN
        pk_nnn_core.get_epis_nic_activity(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_nnn_epis_activity => i_nnn_epis_activity,
                                          o_activity          => o_activity);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_activity);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_activity;

    FUNCTION set_activity_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_activity.id_patient%TYPE,
        i_episode             IN nnn_epis_activity.id_episode%TYPE,
        i_nic_activity        IN nnn_epis_activity.id_nic_activity%TYPE,
        i_nnn_epis_activity   IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_episode_origin      IN nnn_epis_activity.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_activity.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_activity.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_activity.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_activity.flg_req_status%TYPE,
        o_nnn_epis_activity   OUT nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_update';
        l_id nnn_epis_activity.id_nnn_epis_activity%TYPE;
    BEGIN
        l_id := pk_nnn_api_db.set_activity_update(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_patient             => i_patient,
                                                  i_episode             => i_episode,
                                                  i_nic_activity        => i_nic_activity,
                                                  i_nnn_epis_activity   => i_nnn_epis_activity,
                                                  i_episode_origin      => i_episode_origin,
                                                  i_episode_destination => i_episode_destination,
                                                  i_flg_prn             => i_flg_prn,
                                                  i_notes_prn           => i_notes_prn,
                                                  i_flg_time            => i_flg_time,
                                                  i_flg_priority        => i_flg_priority,
                                                  i_order_recurr_plan   => i_order_recurr_plan,
                                                  i_flg_req_status      => i_flg_req_status);
        COMMIT;
        o_nnn_epis_activity := l_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_activity_update;

    FUNCTION set_activity_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        i_cancel_reason         IN nnn_epis_activity.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_activity.cancel_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_cancel';
    BEGIN
        pk_nnn_api_db.set_activity_cancel(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_patient               => i_patient,
                                          i_episode               => i_episode,
                                          i_lst_nnn_epis_activity => i_lst_nnn_epis_activity,
                                          i_cancel_reason         => i_cancel_reason,
                                          i_cancel_notes          => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_activity_cancel;

    FUNCTION set_activity_hold
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_hold';
    BEGIN
        pk_nnn_api_db.set_activity_hold(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_patient               => i_patient,
                                        i_episode               => i_episode,
                                        i_lst_nnn_epis_activity => i_lst_nnn_epis_activity);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_activity_hold;

    FUNCTION set_activity_resume
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_resume';
    BEGIN
        pk_nnn_api_db.set_activity_resume(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_patient               => i_patient,
                                          i_episode               => i_episode,
                                          i_lst_nnn_epis_activity => i_lst_nnn_epis_activity);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_activity_resume;

    FUNCTION get_activity_info
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_outcome.id_patient%TYPE,
        i_episode                   IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_lst_nnn_epis_activity     IN table_number,
        o_info                      OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_activity_info';
    BEGIN
        pk_nnn_api_db.get_activity_info(i_lang                      => i_lang,
                                        i_prof                      => i_prof,
                                        i_patient                   => i_patient,
                                        i_episode                   => i_episode,
                                        i_lst_nnn_epis_intervention => i_lst_nnn_epis_intervention,
                                        i_lst_nnn_epis_activity     => i_lst_nnn_epis_activity,
                                        o_info                      => o_info);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_activity_info;

    FUNCTION get_next_activity_exec_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_nnn_epis_activity     IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_exec_info             OUT pk_types.cursor_type,
        o_activity_tasks        OUT pk_types.cursor_type,
        o_vs_info               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_next_activity_exec_info';
    BEGIN
        pk_nnn_api_db.get_next_activity_exec_info(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_patient               => i_patient,
                                                  i_episode               => i_episode,
                                                  i_nnn_epis_intervention => i_nnn_epis_intervention,
                                                  i_nnn_epis_activity     => i_nnn_epis_activity,
                                                  o_exec_info             => o_exec_info,
                                                  o_activity_tasks        => o_activity_tasks,
                                                  o_vs_info               => o_vs_info);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_exec_info);
            pk_types.open_my_cursor(o_activity_tasks);
            pk_types.open_my_cursor(o_vs_info);
            RETURN FALSE;
    END get_next_activity_exec_info;

    FUNCTION set_activity_execute
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode                   IN nnn_epis_activity_det.id_episode%TYPE,
        i_jsn_input_params          IN CLOB,
        o_lst_nnn_epis_activity_det OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_execute';
        l_lst_id table_number;
    BEGIN
        l_lst_id := pk_nnn_api_db.set_activity_execute(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_patient          => i_patient,
                                                       i_episode          => i_episode,
                                                       i_jsn_input_params => i_jsn_input_params);
    
        COMMIT;
        o_lst_nnn_epis_activity_det := l_lst_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_activity_execute;

    FUNCTION set_activity_exec_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_activity_det IN table_number,
        i_cancel_reason             IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_activity_det.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_activity_exec_cancel';
    BEGIN
        pk_nnn_api_db.set_activity_exec_cancel(i_lang                      => i_lang,
                                               i_prof                      => i_prof,
                                               i_patient                   => i_patient,
                                               i_episode                   => i_episode,
                                               i_lst_nnn_epis_activity_det => i_lst_nnn_epis_activity_det,
                                               i_cancel_reason             => i_cancel_reason,
                                               i_cancel_notes              => i_cancel_notes);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            /* Rollback changes */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_activity_exec_cancel;

    FUNCTION check_outcome_goals_achieved
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_nnn_epis_diagnosis  IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_flg_goals_archieved OUT VARCHAR2,
        o_goals_status        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'check_outcome_goals_achieved';
    BEGIN
        pk_nnn_core.check_outcome_goals_achieved(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_nnn_epis_diagnosis  => i_nnn_epis_diagnosis,
                                                 o_flg_goals_archieved => o_flg_goals_archieved,
                                                 o_goals_status        => o_goals_status);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_goals_status);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_outcome_goals_achieved;

    FUNCTION calculate_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_dt_start_date      IN VARCHAR2,
        i_duration           IN pk_types.t_med_num,
        i_unit_meas_duration IN nic_cfg_activity.id_unit_measure_duration%TYPE,
        i_dt_end_date        IN VARCHAR2,
        o_dt_start_date      OUT VARCHAR2,
        o_duration           OUT pk_types.t_med_num,
        o_duration_desc      OUT pk_types.t_big_byte,
        o_unit_meas_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE,
        o_dt_end_date        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'calculate_duration';
        l_in_start_date  pk_types.t_timestamp;
        l_in_end_date    pk_types.t_timestamp;
        l_out_start_date pk_types.t_timestamp;
        l_out_end_date   pk_types.t_timestamp;
    BEGIN
        g_error         := 'Call PK_DATE_UTILS.GET_STRING_TSTZ (i_dt_start_date)';
        l_in_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_dt_start_date,
                                                         i_timezone  => NULL);
    
        g_error       := 'Call PK_DATE_UTILS.GET_STRING_TSTZ (i_dt_end_date)';
        l_in_end_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_dt_end_date,
                                                       i_timezone  => NULL);
    
        g_error := 'Call PK_NNN_CORE.CALCULATE_DURATION';
        pk_nnn_core.calculate_duration(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_start_date         => l_in_start_date,
                                       i_duration           => i_duration,
                                       i_unit_meas_duration => i_unit_meas_duration,
                                       i_end_date           => l_in_end_date,
                                       o_start_date         => l_out_start_date,
                                       o_duration           => o_duration,
                                       o_duration_desc      => o_duration_desc,
                                       o_unit_meas_duration => o_unit_meas_duration,
                                       o_end_date           => l_out_end_date);
    
        o_dt_start_date := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_out_start_date, i_prof => i_prof);
        o_dt_end_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_out_end_date, i_prof => i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END calculate_duration;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_ux;
/
