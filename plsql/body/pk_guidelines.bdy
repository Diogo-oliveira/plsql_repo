/*-- Last Change Revision: $Rev: 2027177 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_guidelines IS

    /** 
    *  Convert date strings to date format
    *
    * @param C_date   String of date
    *
    * @return     TIMESTAMP WITH LOCAL TIME ZONE
    * @author     SB
    * @version    0.1
    * @since      2007/04/26
    */
    FUNCTION convert_to_date(c_date VARCHAR2) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        EXECUTE IMMEDIATE 'select ' || c_date || ' from dual'
            INTO l_date;
    
        RETURN l_date;
    
    END convert_to_date;

    /********************************************************************************************
    * return a number, converted from a string (if possible)
    *
    * @param       i_txt                     string to convert
    *
    * @return      number                    converted number (null if the conversion fails)
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/03/30
    ********************************************************************************************/
    FUNCTION safe_to_number(i_txt IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN to_number(i_txt);
    EXCEPTION
        WHEN value_error THEN
            RETURN NULL;
    END safe_to_number;

    /** 
    *  Get criteria info 
    *
    * @param C_GUIDELINE                     ID of Guideline
    * @param C_GUIDELINE_CRITERIA_TYPE       Criteria Type
    *
    * @return     Type t_coll_guidelines_generic (PIPELINED)
    * @author     SB
    * @version    0.1
    * @since      2007/04/19
    */
    FUNCTION get_other_criteria
    (
        c_guideline               guideline.id_guideline%TYPE,
        c_guideline_criteria_type guideline_criteria.criteria_type%TYPE
    ) RETURN t_coll_guidelines_generic
        PIPELINED IS
        rec_out t_rec_guidelines_generic;
    
    BEGIN
    
        FOR rec IN c_generic_link(c_guideline, c_guideline_criteria_type)
        LOOP
            rec_out := t_rec_guidelines_generic(rec.id_guideline_criteria_link,
                                                rec.id_link_other_criteria,
                                                rec.id_link_other_criteria_type);
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    END get_other_criteria;

    /** 
    *  Returns string with specific link type content separated by defined separator
    *
    * @param I_LANG                 Language
    * @param I_PROF                 Professional structure
    * @param I_ID_GUIDELINE         Guideline
    * @param I_LINK_TYPE            Type of Link
    * @param I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_link_id_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_link_type    IN guideline_link.link_type%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT id_guideline,
                   id_guideline_link,
                   id_link,
                   decode(link_type,
                          g_guide_link_pathol,
                          pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_diagnosis => id_link,
                                                     i_code         => code,
                                                     i_flg_other    => flag,
                                                     i_flg_std_diag => pk_alert_constant.g_yes),
                          g_guide_link_envi,
                          pk_translation.get_translation(i_lang, code),
                          g_guide_link_prof,
                          pk_translation.get_translation(i_lang, code),
                          g_guide_link_spec,
                          decode(i_prof.software,
                                 pk_alert_constant.g_soft_primary_care,
                                 pk_translation.get_translation(i_lang, code),
                                 pk_translation.get_translation(i_lang, code)),
                          g_guide_link_type,
                          pk_translation.get_translation(i_lang, code),
                          g_guide_link_edit_prof,
                          pk_translation.get_translation(i_lang, code),
                          g_guide_link_chief_complaint,
                          pk_translation.get_translation(i_lang, code),
                          g_unknown_link_type) AS str_desc
              FROM (
                    -- GUID_TYPE              
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            guid_typ.code_guideline_type AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN guideline_type guid_typ
                        ON guid_typ.id_guideline_type = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND g_guide_link_type = i_link_type
                    UNION ALL
                    -- DIAGNOSIS
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            diag.code_icd              AS code,
                            diag.flg_other             AS flag
                      FROM guideline_link guid_lnk
                      JOIN diagnosis diag
                        ON diag.id_diagnosis = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND g_guide_link_pathol = i_link_type
                    UNION ALL
                    -- CATEGORY
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            prof.code_category AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN category prof
                        ON prof.id_category = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND g_guide_link_prof = i_link_type
                    UNION ALL
                    -- DEPT
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            env.code_dept AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN dept env
                        ON env.id_dept = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND env.id_institution = i_prof.institution
                       AND g_guide_link_envi = i_link_type
                    UNION ALL
                    -- SPECIALITY
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            spec.code_speciality AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN speciality spec
                        ON spec.id_speciality = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND i_prof.software != pk_alert_constant.g_soft_primary_care
                       AND g_guide_link_spec = i_link_type
                    UNION ALL
                    -- CLINICAL SERVICE
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            cs.code_clinical_service AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND i_prof.software = pk_alert_constant.g_soft_primary_care
                       AND g_guide_link_spec = i_link_type
                    UNION ALL
                    -- COMPLAINT
                    SELECT guid_lnk.id_guideline,
                            guid_lnk.id_guideline_link,
                            guid_lnk.id_link,
                            guid_lnk.link_type,
                            c.code_complaint AS code,
                            '' AS flag
                      FROM guideline_link guid_lnk
                      JOIN complaint c
                        ON c.id_complaint = guid_lnk.id_link
                     WHERE guid_lnk.id_guideline = i_id_guideline
                       AND guid_lnk.link_type = i_link_type
                       AND g_guide_link_chief_complaint = i_link_type)
             ORDER BY str_desc;
    
        l_return_desc VARCHAR2(1000 CHAR);
    
        l_trunc BOOLEAN := FALSE;
    
        l_num_desc_chars NUMBER(6) := 0;
        l_link_str_len   NUMBER(6) := 0;
        l_separator_len  NUMBER(2) := length(i_separator);
        l_trunc_str_len  NUMBER(2) := length(g_trunc_str);
    BEGIN
        FOR rec IN c_get_descriptions
        LOOP
            -- get link description length
            l_link_str_len := nvl(length(rec.str_desc), 0);
        
            -- verify if the buffer has space to concatenate one more link description
            IF (l_num_desc_chars + l_link_str_len + l_separator_len) <= 1000 - l_trunc_str_len
            THEN
                l_return_desc    := l_return_desc || rec.str_desc || i_separator;
                l_num_desc_chars := l_num_desc_chars + l_link_str_len + l_separator_len;
            ELSE
                l_trunc := TRUE;
                EXIT;
            END IF;
        
        END LOOP;
    
        -- remove last separator from string
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - l_separator_len);
    
        -- truncate string if necessary
        IF l_trunc
        THEN
            l_return_desc := l_return_desc || g_trunc_str;
        END IF;
    
        RETURN l_return_desc;
    END get_link_id_str;

    /** 
    *  Returns string with the details of an item (guideline task or criteria) 
    *  between brackets and separated by defined separator
    *
    * @param  I_LANG          Language
    * @param  I_PROF          Professional structure
    * @param  I_TYPE_ITEM     Type of the guideline item (C)riteria or (T)ask
    * @param  I_ID_ITEM       ID of the item link
    *
    * @return     VARCHAR2
    * @author     TS
    * @version    0.1
    * @since      2007/11/08
    */
    FUNCTION get_item_details_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_type_item IN guideline_adv_input_value.flg_type%TYPE,
        i_id_item   IN guideline_adv_input_value.id_adv_input_link%TYPE,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT field.field_desc,
                   decode(field.id_advanced_input_field,
                          g_frequency_field,
                          freq.label,
                          g_allergy_status_field,
                          allergy_status.label,
                          g_allergy_react_field,
                          allergy_type.label,
                          g_diagnosis_status_field,
                          diagnosis_status.label,
                          g_diagnosis_nature_field,
                          diagnosis_nature.label,
                          g_nurse_diagnosis_status_field,
                          nurse_diag_status.label,
                          g_unknown_detail_type) AS str_desc
              FROM (SELECT guid_adv_input_val.id_advanced_input_field,
                           pk_translation.get_translation(i_lang, aif.code_advanced_input_field) AS field_desc,
                           decode(guid_adv_input_val.value_type,
                                  g_guideline_n_type,
                                  to_char(guid_adv_input_val.nvalue),
                                  g_guideline_d_type,
                                  to_char(guid_adv_input_val.dvalue),
                                  g_guideline_v_type,
                                  to_char(guid_adv_input_val.vvalue)) AS field_value
                      FROM guideline_adv_input_value guid_adv_input_val, advanced_input_field aif
                     WHERE guid_adv_input_val.flg_type = i_type_item
                       AND guid_adv_input_val.id_adv_input_link = i_id_item
                       AND guid_adv_input_val.id_advanced_input_field = aif.id_advanced_input_field
                       AND decode(guid_adv_input_val.value_type,
                                  g_guideline_n_type,
                                  to_char(guid_adv_input_val.nvalue),
                                  g_guideline_d_type,
                                  to_char(guid_adv_input_val.dvalue),
                                  g_guideline_v_type,
                                  guid_adv_input_val.vvalue) != to_char(g_detail_any)) field,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_adv_input_freq
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available) freq,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_allergy_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND val NOT IN (pk_problems.g_pat_probl_cancel)) allergy_status,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND flg_available = g_available
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = g_domain_allergy_type) allergy_type,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_nature
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available) diagnosis_nature,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND val NOT IN (g_pat_probl_not_capable, pk_problems.g_pat_probl_cancel)) diagnosis_status,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_nurse_diag_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND val IN (g_nurse_active, g_nurse_solved)
                       AND flg_available = g_available) nurse_diag_status
             WHERE field.field_value = field.field_value
               AND field.field_value = freq.data(+)
               AND field.field_value = allergy_status.data(+)
               AND field.field_value = allergy_type.data(+)
               AND field.field_value = diagnosis_nature.data(+)
               AND field.field_value = diagnosis_status.data(+)
               AND field.field_value = nurse_diag_status.data(+);
    
        --AND field.field_value != g_detail_any(+);
    
        l_return_desc       VARCHAR2(1000) := ' (';
        l_crit_with_details BOOLEAN := FALSE;
    BEGIN
    
        -- concatenate details
        FOR rec IN c_get_descriptions
        LOOP
            l_return_desc := l_return_desc || rec.field_desc || ': ' || rec.str_desc || i_separator;
        
            l_crit_with_details := TRUE;
        END LOOP;
    
        -- trim the string
        IF (l_crit_with_details)
        THEN
            l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - length(i_separator)) || ')';
        ELSE
            l_return_desc := '';
        END IF;
    
        RETURN l_return_desc;
    END get_item_details_str;

    /** 
    *  Returns string with specific link criteria type content separated by defined separator
    *
    * @param  I_LANG                       Language
    * @param  I_PROF                       Professional structure
    * @param  I_ID_GUIDELINE               Guideline
    * @param  I_CRIT_TYPE                  Type of Criteria: Inclusion or Exclusion
    * @param  I_ID_CRIT_OTHER_TYPE         ID of other type of criteria        
    * @param  I_BULLET                     Bullet for the criteria list
    * @param  I_SEPARATOR                  Separator between criteria
    * @param  I_FLG_DETAILS                Define if details should appear    
    * @param  I_ID_LINK_OTHER_CRITERIA     ID of other criteria
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.2
    * @since      2007/02/23
    */
    FUNCTION get_criteria_link_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        i_crit_type              IN guideline_criteria.criteria_type%TYPE,
        i_id_crit_other_type     IN guideline_criteria_link.id_link_other_criteria_type%TYPE,
        i_bullet                 IN VARCHAR2,
        i_separator              IN VARCHAR2,
        i_flg_details            IN VARCHAR2,
        i_id_link_other_criteria IN guideline_criteria_link.id_link_other_criteria%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT guid.id_guideline,
                   guid_crit.id_guideline_criteria,
                   guid_crit_lnk.id_guideline_criteria_link,
                   decode(guid_crit_lnk.id_link_other_criteria_type,
                          g_guideline_allergies,
                          pk_translation.get_translation(i_lang, alerg.code_allergy),
                          g_guideline_analysis,
                          nvl(pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', asys.code_analysis, NULL),
                              pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                        i_prof,
                                                                        'G',
                                                                        'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' ||
                                                                        safe_to_number(guid_crit_lnk.id_link_other_criteria),
                                                                        NULL)),
                          g_guideline_diagnosis,
                          pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_diagnosis => diag.id_diagnosis,
                                                     i_code         => diag.code_icd,
                                                     i_flg_other    => diag.flg_other,
                                                     i_flg_std_diag => pk_alert_constant.g_yes),
                          g_guideline_exams,
                          nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam),
                              pk_translation.get_translation(i_lang,
                                                             'EXAM_GROUP.CODE_EXAM_GROUP.' ||
                                                             safe_to_number(guid_crit_lnk.id_link_other_criteria))),
                          g_guideline_drug,
                          g_guideline_other_exams,
                          nvl(pk_exams_api_db.get_alias_translation(i_lang, i_prof, exother.code_exam),
                              pk_translation.get_translation(i_lang,
                                                             'EXAM_GROUP.CODE_EXAM_GROUP.' ||
                                                             safe_to_number(guid_crit_lnk.id_link_other_criteria))),
                          g_guideline_diagnosis_nurse,
                          pk_translation.get_translation(i_lang, ic.code_icnp_composition),
                          g_unknown_link_type) AS str_desc
              FROM guideline               guid,
                   guideline_criteria      guid_crit,
                   guideline_criteria_link guid_crit_lnk,
                   --
                   allergy          alerg,
                   analysis         asys,
                   diagnosis        diag,
                   exam             ex,
                   exam             exother,
                   icnp_composition ic
             WHERE guid.id_guideline = i_id_guideline
               AND guid.id_guideline = guid_crit.id_guideline
               AND guid_crit.criteria_type = i_crit_type
               AND guid_crit.id_guideline_criteria = guid_crit_lnk.id_guideline_criteria
               AND guid_crit_lnk.id_link_other_criteria =
                   nvl(i_id_link_other_criteria, guid_crit_lnk.id_link_other_criteria)
               AND guid_crit_lnk.id_link_other_criteria_type = i_id_crit_other_type
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = alerg.id_allergy(+)
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = asys.id_analysis(+)
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = diag.id_diagnosis(+)
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = ex.id_exam(+)
               AND ex.flg_type(+) = g_exam_only_img
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(guid_crit_lnk.id_link_other_criteria) = ic.id_composition(+)
               AND ic.flg_type(+) = g_composition_diag_type
               AND ic.flg_available(+) = g_available;
    
        l_return_desc      VARCHAR2(1000 CHAR);
        l_crit_details_str VARCHAR2(1000);
    
        l_trunc BOOLEAN := FALSE;
    
        l_num_desc_chars   NUMBER(6) := 0;
        l_crit_len         NUMBER(6) := 0;
        l_crit_details_len NUMBER(6) := 0;
        l_bullet_len       NUMBER(2) := nvl(length(i_bullet), 0);
        l_separator_len    NUMBER(2) := length(i_separator);
        l_trunc_str_len    NUMBER(2) := length(g_trunc_str);
    BEGIN
    
        -- concatenate criteria descriptions and truncate it if necessary
        FOR rec IN c_get_descriptions
        LOOP
            -- get string with criteria details
            IF (i_flg_details = g_available)
            THEN
                l_crit_details_str := get_item_details_str(i_lang,
                                                           i_prof,
                                                           g_adv_input_type_criterias,
                                                           rec.id_guideline_criteria_link,
                                                           g_separator2);
            ELSE
                l_crit_details_str := '';
            END IF;
        
            -- get criteria description length
            l_crit_len := nvl(length(rec.str_desc), 0);
        
            -- get length of criteria details description
            l_crit_details_len := nvl(length(l_crit_details_str), 0);
        
            -- verify if the buffer has space to concatenate one more criteria description
            IF (l_num_desc_chars + l_bullet_len + l_crit_len + l_crit_details_len + l_separator_len) <=
               1000 - l_trunc_str_len
            THEN
                l_return_desc    := l_return_desc || i_bullet || rec.str_desc || l_crit_details_str || i_separator;
                l_num_desc_chars := l_num_desc_chars + l_bullet_len + l_crit_len + l_crit_details_len + l_separator_len;
            ELSE
                l_trunc := TRUE;
                EXIT;
            END IF;
        END LOOP;
    
        -- remove last separator from string
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - l_separator_len);
    
        -- truncate string if necessary
        IF l_trunc
        THEN
            l_return_desc := l_return_desc || g_trunc_str;
        END IF;
    
        RETURN l_return_desc;
    END get_criteria_link_id_str;

    /** 
    *  Returns string with specific task ID content 
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE_PROCESS ID of guideline process
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_TYPE            Type of task
    * @param  I_TASK_CODICATION      Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_task_id_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task           IN guideline_task_link.id_task_link%TYPE,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_task_codification IN guideline_task_link.task_codification%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT /*+opt_estimate(table guid_task rows=1)*/
             i_id_task,
             decode(i_task_type,
                    -- Analysis
                    g_task_analysis,
                    pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', asys.code_analysis, NULL) ||
                    -- analysis codification              
                     (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                        FROM analysis_codification ac, codification c
                       WHERE i_task_codification IS NOT NULL
                         AND ac.id_analysis_codification = i_task_codification
                         AND ac.id_codification = c.id_codification),
                    -- Appointment
                    g_task_appoint,
                    decode(guid_task.column_value,
                           '-1',
                           pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                           pk_translation.get_translation(i_lang, appoint.code_clinical_service)),
                    -- Patient education
                    g_task_patient_education,
                    CASE guid_task.column_value
                        WHEN '-1' THEN
                         NULL --guid_task.task_notes,
                        ELSE
                         pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang, i_prof, guid_task.column_value)
                    END,
                    -- Image exam
                    g_task_img,
                    pk_exams_api_db.get_alias_translation(i_lang, i_prof, img.code_exam) ||
                    -- image exam codification              
                     (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                        FROM exam_codification ec, codification c
                       WHERE i_task_codification IS NOT NULL
                         AND ec.id_exam_codification = i_task_codification
                         AND ec.id_codification = c.id_codification),
                    g_task_vacc,
                    pk_translation.get_translation(i_lang, vac.code_vaccine),
                    g_task_enfint,
                    pk_translation.get_translation(i_lang, enfint.code_icnp_composition),
                    -- Other exam
                    g_task_otherexam,
                    pk_exams_api_db.get_alias_translation(i_lang, i_prof, exother.code_exam) ||
                    -- other exam codification
                     (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                        FROM exam_codification ec, codification c
                       WHERE i_task_codification IS NOT NULL
                         AND ec.id_exam_codification = i_task_codification
                         AND ec.id_codification = c.id_codification),
                    g_task_spec,
                    pk_translation.get_translation(i_lang, par.code_speciality),
                    -- Procedure
                    g_task_proc,
                    pk_procedures_api_db.get_alias_translation(i_lang, i_prof, interv.code_intervention, NULL) ||
                    -- procedure codification
                     (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                        FROM interv_codification ec, codification c
                       WHERE i_task_codification IS NOT NULL
                         AND ec.id_interv_codification = i_task_codification
                         AND ec.id_codification = c.id_codification),
                    g_task_monitorization,
                    pk_translation.get_translation(i_lang, monit_vs.code_vital_sign),
                    g_unknown_link_type) AS str_desc
              FROM TABLE(table_varchar(i_id_task)) guid_task,
                   analysis asys, -- Analises
                   (SELECT dcs.id_dep_clin_serv, cs.id_clinical_service, cs.code_clinical_service
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE cs.id_clinical_service = dcs.id_clinical_service) appoint, -- Consultas
                   --icnp_composition enf, -- Ensinos de enfermagem
                   exam             img, -- Imagem
                   vaccine          vac, -- Imunizações
                   icnp_composition enfint, --Intervenções de enfermagem
                   exam             exother, -- Outros exames
                   speciality       par, -- Pareceres
                   intervention     interv, -- Procedimentos                  
                   vital_sign       monit_vs -- Monitorizacoes
             WHERE guid_task.column_value = i_id_task
               AND safe_to_number(guid_task.column_value) = asys.id_analysis(+)
               AND safe_to_number(guid_task.column_value) = appoint.id_dep_clin_serv(+)
               AND safe_to_number(guid_task.column_value) = img.id_exam(+)
               AND img.flg_type(+) = g_exam_only_img
               AND safe_to_number(guid_task.column_value) = vac.id_vaccine(+)
               AND safe_to_number(guid_task.column_value) = enfint.id_composition(+)
               AND safe_to_number(guid_task.column_value) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(guid_task.column_value) = par.id_speciality(+)
               AND safe_to_number(guid_task.column_value) = interv.id_intervention(+)
               AND safe_to_number(guid_task.column_value) = monit_vs.id_vital_sign(+)
               AND i_task_type NOT IN (g_task_drug_ext, g_task_drug);
    
        l_return_desc c_get_descriptions%ROWTYPE;
    
    BEGIN
    
        OPEN c_get_descriptions;
        FETCH c_get_descriptions
            INTO l_return_desc;
        CLOSE c_get_descriptions;
    
        RETURN l_return_desc.str_desc;
    END get_task_id_desc;

    /** 
    *  Returns string with specific task content separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_TASK_TYPE            Type of task
    * @param  I_SEPARATOR            Separator between diferent elements of string
    * @param  I_FLG_NOTES            Define if notes should appear
    * @param  I_FLG_DETAILS          Define if details should appear
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_CODICATION      Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_task_id_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_separator         IN VARCHAR2,
        i_flg_notes         IN VARCHAR2,
        i_flg_details       IN VARCHAR2,
        i_id_task           IN guideline_task_link.id_task_link%TYPE DEFAULT NULL,
        i_task_codification IN guideline_task_link.task_codification%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT i_id_guideline AS id_guideline,
                   guid_task_lnk.id_guideline_task_link,
                   decode(guid_task_lnk.task_type,
                          -- Analysis
                          g_task_analysis,
                          pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', asys.code_analysis, NULL) ||
                          -- analysis codification              
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM analysis_codification ac, codification c
                             WHERE guid_task_lnk.task_codification IS NOT NULL
                               AND ac.id_analysis_codification = guid_task_lnk.task_codification
                               AND ac.id_codification = c.id_codification),
                          -- Appointments
                          g_task_appoint,
                          decode(guid_task_lnk.id_task_link,
                                 '-1',
                                 pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                                 pk_translation.get_translation(i_lang, appoint.code_clinical_service)),
                          -- Patient education
                          g_task_patient_education,
                          CASE guid_task_lnk.id_task_link
                              WHEN '-1' THEN
                               guid_task_lnk.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       guid_task_lnk.id_task_link)
                          END,
                          -- Image
                          g_task_img,
                          pk_exams_api_db.get_alias_translation(i_lang, i_prof, img.code_exam) ||
                          -- image exam codification              
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM exam_codification ec, codification c
                             WHERE guid_task_lnk.task_codification IS NOT NULL
                               AND ec.id_exam_codification = guid_task_lnk.task_codification
                               AND ec.id_codification = c.id_codification),
                          g_task_vacc,
                          pk_translation.get_translation(i_lang, vac.code_vaccine),
                          g_task_enfint,
                          pk_translation.get_translation(i_lang, enfint.code_icnp_composition),
                          -- Other exam
                          g_task_otherexam,
                          pk_exams_api_db.get_alias_translation(i_lang, i_prof, exother.code_exam) ||
                          -- other exam codification
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM exam_codification ec, codification c
                             WHERE guid_task_lnk.task_codification IS NOT NULL
                               AND ec.id_exam_codification = guid_task_lnk.task_codification
                               AND ec.id_codification = c.id_codification),
                          g_task_spec,
                          pk_translation.get_translation(i_lang, par.code_speciality) ||
                          decode(guid_task_lnk.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, guid_task_lnk.id_task_attach),
                                      ' (' ||
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, guid_task_lnk.id_task_attach) || ')',
                                      NULL)),
                          -- Procedure
                          g_task_proc,
                          pk_procedures_api_db.get_alias_translation(i_lang, i_prof, interv.code_intervention, NULL) ||
                          -- procedure codification
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM interv_codification ec, codification c
                             WHERE guid_task_lnk.task_codification IS NOT NULL
                               AND ec.id_interv_codification = guid_task_lnk.task_codification
                               AND ec.id_codification = c.id_codification),
                          -- Monitoring
                          g_task_monitorization,
                          pk_translation.get_translation(i_lang, monit_vs.code_vital_sign),
                          g_unknown_link_type) AS str_desc,
                   guid_task_lnk.task_notes AS task_notes
              FROM guideline_task_link guid_task_lnk,
                   --
                   analysis asys, -- Analises
                   (SELECT dcs.id_dep_clin_serv, cs.id_clinical_service, cs.code_clinical_service
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE cs.id_clinical_service = dcs.id_clinical_service) appoint,
                   exam img, -- Imagem
                   vaccine vac, -- Imunizações
                   icnp_composition enfint, --Intervenções de enfermagem
                   exam exother, -- Outros exames
                   speciality par, -- Pareceres
                   intervention interv, -- Procedimentos
                   vital_sign monit_vs -- Monitorizacoes
             WHERE guid_task_lnk.id_guideline = i_id_guideline
               AND guid_task_lnk.task_type = i_task_type
               AND guid_task_lnk.id_task_link = nvl(i_id_task, guid_task_lnk.id_task_link)
               AND nvl(guid_task_lnk.task_codification, -1) =
                   nvl(i_task_codification, nvl(guid_task_lnk.task_codification, -1))
               AND safe_to_number(guid_task_lnk.id_task_link) = asys.id_analysis(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = appoint.id_dep_clin_serv(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = img.id_exam(+)
               AND img.flg_type(+) = g_exam_only_img
               AND safe_to_number(guid_task_lnk.id_task_link) = vac.id_vaccine(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = enfint.id_composition(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(guid_task_lnk.id_task_link) = par.id_speciality(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = interv.id_intervention(+)
               AND safe_to_number(guid_task_lnk.id_task_link) = monit_vs.id_vital_sign(+)
               AND i_task_type NOT IN (g_task_drug_ext, g_task_drug);
    
        l_return_desc      VARCHAR2(4000);
        l_task_details_str VARCHAR2(1000);
        l_task_notes       VARCHAR2(4000) := NULL;
    BEGIN
        FOR rec IN c_get_descriptions
        LOOP
            -- get task notes
            IF (i_flg_notes = g_available AND rec.task_notes IS NOT NULL AND l_task_notes IS NULL)
            THEN
                l_task_notes := rec.task_notes;
            END IF;
        
            -- get string with criteria details
            IF (i_flg_details = g_available)
            THEN
                l_task_details_str := get_item_details_str(i_lang,
                                                           i_prof,
                                                           g_adv_input_type_tasks,
                                                           rec.id_guideline_task_link,
                                                           g_separator2);
            ELSE
                l_task_details_str := '';
            END IF;
        
            l_return_desc := l_return_desc || rec.str_desc || l_task_details_str || i_separator;
        END LOOP;
    
        -- remove last separator
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - length(i_separator));
    
        -- add task notes to the string
        IF (i_flg_notes = g_available AND l_task_notes IS NOT NULL)
        THEN
            l_return_desc := l_return_desc || chr(10) || chr(10) || pk_message.get_message(i_lang, g_message_notes) || ' ' ||
                             l_task_notes;
        END IF;
    
        RETURN l_return_desc;
    END get_task_id_str;

    /** 
    *  Returns string with picture name separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/04/16
    */
    FUNCTION get_image_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT img_desc AS str_desc
              FROM guideline_context_image guid_ctx_img
             WHERE guid_ctx_img.id_guideline = i_id_guideline
               AND flg_status = g_active;
    
        l_return_desc VARCHAR2(4000);
    BEGIN
        FOR rec IN c_get_descriptions
        LOOP
            l_return_desc := l_return_desc || rec.str_desc || i_separator;
        END LOOP;
    
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - length(i_separator));
        RETURN l_return_desc;
    END get_image_str;

    /** 
    *  Returns string with author of a specified guideline
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_context_author_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_author IS
            SELECT first_name || ' ' || last_name || g_separator || title AS str_desc
              FROM guideline_context_author guid_ctx_auth
             WHERE guid_ctx_auth.id_guideline = i_id_guideline;
    
        l_return_desc VARCHAR2(4000);
    BEGIN
        FOR rec IN c_get_author
        LOOP
            l_return_desc := l_return_desc || rec.str_desc || i_separator;
        END LOOP;
    
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - length(i_separator));
        RETURN l_return_desc;
    END get_context_author_str;

    /** 
    *  Returns string with specific criteria_type
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_CRITERIA_TYPE     Criteria type ID
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_criteria_type_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_criteria_type IN guideline_criteria_type.id_guideline_criteria_type%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT pk_translation.get_translation(i_lang, code_guideline_criteria_type) AS str_desc
              FROM guideline_criteria_type
             WHERE id_guideline_criteria_type = i_id_criteria_type;
    
        l_return_desc c_get_descriptions%ROWTYPE;
    
    BEGIN
    
        OPEN c_get_descriptions;
        FETCH c_get_descriptions
            INTO l_return_desc;
        CLOSE c_get_descriptions;
    
        RETURN l_return_desc.str_desc;
    END get_criteria_type_desc;

    ---------------------------------------
    -- Sequence IDs functions
    /** 
    * Function - Returns sequence ID for guideline
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_seq;

    -- Guideline Criteria
    /** 
    * Function - Returns sequence ID for guideline criteria
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_criteria_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_criteria.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_criteria_seq;

    -- Guideline_link
    /** 
    * Function - Returns sequence ID for guideline link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_link_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_link.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_link_seq;

    -- Guideline criteria link
    /** 
    * Function - Returns sequence ID for guideline criteria link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_crit_lnk_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_criteria_link.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_crit_lnk_seq;

    /** 
    * Function - Returns sequence ID for guideline advanced input value
    *
    * @return     NUMBER
    * @author     TS
    * @version    0.1
    * @since      2007/07/17
    */
    FUNCTION get_guide_advinput_value_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_adv_input_value.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guide_advinput_value_seq;

    -- Task Link
    /** 
    * Function - Returns sequence ID for guideline task link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_task_link_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_task_link.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_task_link_seq;

    /** 
    * Function - Returns sequence ID for guideline author
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_ctx_author_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_guideline_context_author.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_guideline_ctx_author_seq;

    /** 
    *  Create specific guideline
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Object (ID of professional, ID of institution, ID of software)
    * @param      I_DUPLICATE_FLG              Duplicate guideline (Y/N)
    * @param      O_ID_GUIDELINE               identifier of guideline created
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION create_guideline
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        i_duplicate_flg IN VARCHAR2,
        ---
        o_id_guideline OUT guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_guideline              guideline%ROWTYPE;
        l_guideline_criteria_inc guideline_criteria%ROWTYPE;
        l_guideline_criteria_exc guideline_criteria%ROWTYPE;
    
        TYPE t_guideline_criteria_link IS TABLE OF guideline_criteria_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_crit_link_inc t_guideline_criteria_link;
        ibt_guideline_crit_link_exc t_guideline_criteria_link;
    
        TYPE t_guideline_task_link IS TABLE OF guideline_task_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_task_link t_guideline_task_link;
    
        TYPE t_guideline_link IS TABLE OF guideline_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_link t_guideline_link;
    
        TYPE t_guideline_context_image IS TABLE OF guideline_context_image%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_context_image t_guideline_context_image;
    
        TYPE t_guideline_context_author IS TABLE OF guideline_context_author%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_context_author t_guideline_context_author;
    
        TYPE t_guideline_adv_input_value IS TABLE OF guideline_adv_input_value%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_adv_input_value t_guideline_adv_input_value;
    
        ----------------
        flg_new BOOLEAN := FALSE;
    
        CURSOR c_guideline(in_id_guideline NUMBER) IS
            SELECT *
              FROM guideline
             WHERE id_guideline = in_id_guideline;
    
        CURSOR c_guideline_criteria
        (
            in_id_guideline  NUMBER,
            in_criteria_type VARCHAR2
        ) IS
            SELECT *
              FROM guideline_criteria
             WHERE id_guideline = in_id_guideline
               AND criteria_type = in_criteria_type;
    
        -----------------
        CURSOR c_guideline_task_link
        (
            in_id_guideline     NUMBER,
            in_id_guideline_new NUMBER
        ) IS
            SELECT seq_guideline_task_link.nextval AS id_guideline_task_link_new,
                   id_guideline_task_link          AS id_guideline_task_link_old,
                   in_id_guideline_new             AS id_guideline,
                   id_task_link,
                   task_type,
                   task_notes,
                   id_task_attach,
                   task_codification
              FROM guideline_task_link
             WHERE id_guideline = in_id_guideline;
    
        CURSOR c_guideline_link
        (
            in_id_guideline     NUMBER,
            in_id_guideline_new NUMBER
        ) IS
            SELECT seq_guideline_link.nextval AS id_guideline_link,
                   in_id_guideline_new        AS id_guideline,
                   id_link,
                   link_type
              FROM guideline_link
             WHERE id_guideline = in_id_guideline;
    
        CURSOR c_guideline_criteria_link
        (
            in_id_guideline          NUMBER,
            in_id_guideline_crit_new NUMBER,
            in_criteria_type         guideline_criteria.criteria_type%TYPE
        ) IS
            SELECT seq_guideline_criteria_link.nextval        AS id_guideline_criteria_link_new,
                   guid_crit_link.id_guideline_criteria_link  AS id_guideline_criteria_link_old,
                   in_id_guideline_crit_new                   AS id_guideline_criteria,
                   guid_crit_link.id_link_other_criteria,
                   guid_crit_link.id_link_other_criteria_type
              FROM guideline_criteria_link guid_crit_link, guideline_criteria guid_crit
             WHERE guid_crit.id_guideline = in_id_guideline
               AND guid_crit_link.id_guideline_criteria = guid_crit.id_guideline_criteria
               AND guid_crit.criteria_type = in_criteria_type;
    
        CURSOR c_guideline_context_image
        (
            in_id_guideline     NUMBER,
            in_id_guideline_new NUMBER
        ) IS
            SELECT seq_guideline_context_image.nextval AS id_guideline_context_image,
                   in_id_guideline_new                 AS id_guideline,
                   file_name,
                   img_desc,
                   dt_img,
                   img,
                   img_thumbnail,
                   flg_status
              FROM guideline_context_image
             WHERE id_guideline = in_id_guideline;
    
        CURSOR c_guideline_context_author
        (
            in_id_guideline     NUMBER,
            in_id_guideline_new NUMBER
        ) IS
            SELECT seq_guideline_context_author.nextval AS id_guideline_context_author,
                   in_id_guideline_new                  AS id_guideline,
                   first_name,
                   last_name,
                   title
              FROM guideline_context_author guid_ctx_auth
             WHERE guid_ctx_auth.id_guideline = in_id_guideline;
    
        CURSOR c_guideline_adv_input_value
        (
            in_flg_type              VARCHAR2,
            in_id_adv_input_link     NUMBER,
            in_id_adv_input_link_new NUMBER
        ) IS
            SELECT seq_guideline_adv_input_value.nextval AS id_guideline_adv_input_value,
                   in_id_adv_input_link_new              AS id_adv_input_link,
                   flg_type,
                   value_type,
                   nvalue,
                   dvalue,
                   vvalue,
                   value_desc,
                   criteria_value_type,
                   id_advanced_input,
                   id_advanced_input_field,
                   id_advanced_input_field_det
              FROM guideline_adv_input_value
             WHERE flg_type = in_flg_type
               AND id_adv_input_link = in_id_adv_input_link;
    
        -----------------
        l_seq_guideline_id          NUMBER;
        l_seq_guideline_crit_inc_id NUMBER;
        l_seq_guideline_crit_exc_id NUMBER;
        l_counter                   NUMBER;
        l_sysdate                   TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        g_error := 'NEW OR EDITING';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- New or editing
        IF (i_id_guideline IS NULL)
        THEN
            -- new id if new guideline
            flg_new := TRUE;
        ELSE
            -- new id and previous equals current if editing
            flg_new := FALSE;
        END IF;
    
        g_error := 'GET IDS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        -- Get guideline basic IDs
        l_seq_guideline_id          := get_guideline_seq;
        l_seq_guideline_crit_inc_id := get_guideline_criteria_seq;
        l_seq_guideline_crit_exc_id := get_guideline_criteria_seq;
    
        -- Output guideline id created
        o_id_guideline := l_seq_guideline_id;
    
        IF (flg_new)
        THEN
            g_error := 'NEW GUIDELINE SET VARIABLES';
            pk_alertlog.log_debug(g_error, g_log_object_name);
            l_guideline.id_guideline                  := l_seq_guideline_id;
            l_guideline.id_guideline_previous_version := NULL;
            l_guideline.id_professional               := i_prof.id;
            l_guideline.dt_guideline                  := l_sysdate;
            l_guideline.flg_status                    := g_guideline_temp;
            l_guideline.id_context_language           := i_lang;
            l_guideline.id_institution                := i_prof.institution;
            l_guideline.id_software                   := i_prof.software;
            l_guideline.flg_type_recommendation       := g_default_type_rec;
            -- Inclusion Criteria
            l_guideline_criteria_inc.id_guideline          := l_seq_guideline_id;
            l_guideline_criteria_inc.id_guideline_criteria := l_seq_guideline_crit_inc_id;
            l_guideline_criteria_inc.criteria_type         := g_criteria_type_inc;
            -- Exclusion Criteria
            l_guideline_criteria_exc.id_guideline          := l_seq_guideline_id;
            l_guideline_criteria_exc.id_guideline_criteria := l_seq_guideline_crit_exc_id;
            l_guideline_criteria_exc.criteria_type         := g_criteria_type_exc;
        ELSE
            g_error := 'EDIT GUIDELINE SET VARIABLES';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Fetches parent guideline info
            OPEN c_guideline(i_id_guideline);
        
            FETCH c_guideline
                INTO l_guideline;
        
            CLOSE c_guideline;
        
            g_error := 'GET CRITERIA INC';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Criteria Inclusion
            OPEN c_guideline_criteria(i_id_guideline, g_criteria_type_inc);
        
            FETCH c_guideline_criteria
                INTO l_guideline_criteria_inc;
        
            CLOSE c_guideline_criteria;
        
            g_error := 'GET CRITERIA EXC';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Criteria Exclusion
            OPEN c_guideline_criteria(i_id_guideline, g_criteria_type_exc);
        
            FETCH c_guideline_criteria
                INTO l_guideline_criteria_exc;
        
            CLOSE c_guideline_criteria;
        
            g_error := 'GET IDS FOR OTHER TABLES';
            pk_alertlog.log_debug(g_error, g_log_object_name);
            --  Parent ID as we are editing
            l_guideline.id_guideline                  := l_seq_guideline_id;
            l_guideline.id_guideline_previous_version := i_id_guideline;
            l_guideline.id_professional               := i_prof.id;
            l_guideline.dt_guideline                  := l_sysdate;
            l_guideline.flg_status                    := g_guideline_temp;
            l_guideline.id_institution                := i_prof.institution;
            l_guideline.id_software                   := i_prof.software;
            l_guideline.dt_cancel                     := NULL;
            l_guideline.id_prof_cancel                := NULL;
        
            -- In case of duplication the link to the previous guideline and id_content column value must be deleted
            IF (i_duplicate_flg = g_yes)
            THEN
                l_guideline.id_guideline_previous_version := NULL;
                l_guideline.id_content                    := NULL;
            END IF;
        
            g_error := 'GET TASK LINKS';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Inclusion Criteria
            l_guideline_criteria_inc.id_guideline          := l_seq_guideline_id;
            l_guideline_criteria_inc.id_guideline_criteria := l_seq_guideline_crit_inc_id;
            -- Exclusion Criteria
            l_guideline_criteria_exc.id_guideline          := l_seq_guideline_id;
            l_guideline_criteria_exc.id_guideline_criteria := l_seq_guideline_crit_exc_id;
        
            -- Get data from previous Guideline -------------------------------------------------------------
            -- GUIDELINE_TASK_LINK
            FOR rec IN c_guideline_task_link(i_id_guideline, l_seq_guideline_id)
            LOOP
            
                l_counter := ibt_guideline_task_link.count + 1;
                ibt_guideline_task_link(l_counter).id_guideline_task_link := rec.id_guideline_task_link_new;
                ibt_guideline_task_link(l_counter).id_guideline := rec.id_guideline;
                ibt_guideline_task_link(l_counter).id_task_link := rec.id_task_link;
                ibt_guideline_task_link(l_counter).task_type := rec.task_type;
                ibt_guideline_task_link(l_counter).task_notes := rec.task_notes;
                ibt_guideline_task_link(l_counter).id_task_attach := rec.id_task_attach;
                ibt_guideline_task_link(l_counter).task_codification := rec.task_codification;
            
                -- related advanced input values
                FOR rec_adv_input IN c_guideline_adv_input_value(g_adv_input_type_tasks,
                                                                 rec.id_guideline_task_link_old,
                                                                 rec.id_guideline_task_link_new)
                LOOP
                    l_counter := ibt_guideline_adv_input_value.count + 1;
                    ibt_guideline_adv_input_value(l_counter).id_guideline_adv_input_value := rec_adv_input.id_guideline_adv_input_value;
                    ibt_guideline_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                    ibt_guideline_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                    ibt_guideline_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                    ibt_guideline_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                    ibt_guideline_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                    ibt_guideline_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                    ibt_guideline_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                    ibt_guideline_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                END LOOP;
            END LOOP;
        
            g_error := 'GET LINKS';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Guideline Link
            FOR rec IN c_guideline_link(i_id_guideline, l_seq_guideline_id)
            LOOP
                l_counter := ibt_guideline_link.count + 1;
                ibt_guideline_link(l_counter).id_guideline_link := rec.id_guideline_link;
                ibt_guideline_link(l_counter).id_guideline := rec.id_guideline;
                ibt_guideline_link(l_counter).id_link := rec.id_link;
                ibt_guideline_link(l_counter).link_type := rec.link_type;
            END LOOP;
        
            g_error := 'GET CRITERIA LINKS EXC';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Criteria Link
            FOR rec IN c_guideline_criteria_link(i_id_guideline, l_seq_guideline_crit_exc_id, g_criteria_type_exc)
            LOOP
                l_counter := ibt_guideline_crit_link_exc.count + 1;
                ibt_guideline_crit_link_exc(l_counter).id_guideline_criteria_link := rec.id_guideline_criteria_link_new;
                ibt_guideline_crit_link_exc(l_counter).id_guideline_criteria := rec.id_guideline_criteria;
                ibt_guideline_crit_link_exc(l_counter).id_link_other_criteria := rec.id_link_other_criteria;
                ibt_guideline_crit_link_exc(l_counter).id_link_other_criteria_type := rec.id_link_other_criteria_type;
            
                -- related advanced input values
                FOR rec_adv_input IN c_guideline_adv_input_value(g_adv_input_type_criterias,
                                                                 rec.id_guideline_criteria_link_old,
                                                                 rec.id_guideline_criteria_link_new)
                LOOP
                    l_counter := ibt_guideline_adv_input_value.count + 1;
                    ibt_guideline_adv_input_value(l_counter).id_guideline_adv_input_value := rec_adv_input.id_guideline_adv_input_value;
                    ibt_guideline_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                    ibt_guideline_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                    ibt_guideline_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                    ibt_guideline_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                    ibt_guideline_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                    ibt_guideline_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                    ibt_guideline_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                    ibt_guideline_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                END LOOP;
            END LOOP;
        
            g_error := 'GET CRITERIA LINKS INC';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            FOR rec IN c_guideline_criteria_link(i_id_guideline, l_seq_guideline_crit_inc_id, g_criteria_type_inc)
            LOOP
                l_counter := ibt_guideline_crit_link_inc.count + 1;
                ibt_guideline_crit_link_inc(l_counter).id_guideline_criteria_link := rec.id_guideline_criteria_link_new;
                ibt_guideline_crit_link_inc(l_counter).id_guideline_criteria := rec.id_guideline_criteria;
                ibt_guideline_crit_link_inc(l_counter).id_link_other_criteria := rec.id_link_other_criteria;
                ibt_guideline_crit_link_inc(l_counter).id_link_other_criteria_type := rec.id_link_other_criteria_type;
            
                -- related advanced input values
                FOR rec_adv_input IN c_guideline_adv_input_value(g_adv_input_type_criterias,
                                                                 rec.id_guideline_criteria_link_old,
                                                                 rec.id_guideline_criteria_link_new)
                LOOP
                    l_counter := ibt_guideline_adv_input_value.count + 1;
                    ibt_guideline_adv_input_value(l_counter).id_guideline_adv_input_value := rec_adv_input.id_guideline_adv_input_value;
                    ibt_guideline_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                    ibt_guideline_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                    ibt_guideline_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                    ibt_guideline_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                    ibt_guideline_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                    ibt_guideline_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                    ibt_guideline_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                    ibt_guideline_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                    ibt_guideline_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                END LOOP;
            END LOOP;
        
            g_error := 'GET CONTEXT IMAGE';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Context Image
            FOR rec IN c_guideline_context_image(i_id_guideline, l_seq_guideline_id)
            LOOP
                l_counter := ibt_guideline_context_image.count + 1;
                ibt_guideline_context_image(l_counter).id_guideline_context_image := rec.id_guideline_context_image;
                ibt_guideline_context_image(l_counter).id_guideline := rec.id_guideline;
                ibt_guideline_context_image(l_counter).file_name := rec.file_name;
                ibt_guideline_context_image(l_counter).img_desc := rec.img_desc;
                ibt_guideline_context_image(l_counter).dt_img := rec.dt_img;
                ibt_guideline_context_image(l_counter).img := rec.img;
                ibt_guideline_context_image(l_counter).img_thumbnail := rec.img_thumbnail;
                ibt_guideline_context_image(l_counter).flg_status := rec.flg_status;
            END LOOP;
        
            -- Context Author
            FOR rec IN c_guideline_context_author(i_id_guideline, l_seq_guideline_id)
            LOOP
                l_counter := ibt_guideline_context_author.count + 1;
                ibt_guideline_context_author(l_counter).id_guideline_context_author := rec.id_guideline_context_author;
                ibt_guideline_context_author(l_counter).id_guideline := rec.id_guideline;
                ibt_guideline_context_author(l_counter).first_name := rec.first_name;
                ibt_guideline_context_author(l_counter).last_name := rec.last_name;
                ibt_guideline_context_author(l_counter).title := rec.title;
            END LOOP;
        
            -- When we want to duplicate we delete the link to another guideline
            IF (i_duplicate_flg = g_yes)
            THEN
                l_guideline.id_guideline_previous_version := NULL;
            END IF;
        
            -- Get data from previous Guideline -------------------------------------------------------------
        END IF;
    
        g_error := 'INSERT GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Set guideline
        INSERT INTO guideline
        VALUES l_guideline;
    
        g_error := 'INSERT CRITERIA INC';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Set Criteria
        INSERT INTO guideline_criteria
        VALUES l_guideline_criteria_inc;
    
        g_error := 'INSERT GUIDELINE EXC';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        INSERT INTO guideline_criteria
        VALUES l_guideline_criteria_exc;
    
        IF (NOT flg_new)
        THEN
            -- Set Criteria Link
            BEGIN
                g_error := 'INSERT CRITERIA LINK INC';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_crit_link_inc.count > 0)
                THEN
                    FORALL i IN ibt_guideline_crit_link_inc.first .. ibt_guideline_crit_link_inc.last
                        INSERT INTO guideline_criteria_link
                        VALUES ibt_guideline_crit_link_inc
                            (i);
                
                END IF;
            EXCEPTION
                -- Error on inclusion criteria link insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            BEGIN
                g_error := 'INSERT CRITERIA LINK EXC';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_crit_link_exc.count > 0)
                THEN
                    FORALL i IN ibt_guideline_crit_link_exc.first .. ibt_guideline_crit_link_exc.last
                        INSERT INTO guideline_criteria_link
                        VALUES ibt_guideline_crit_link_exc
                            (i);
                END IF;
            EXCEPTION
                -- Error on exclusion criteria link insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Context Image
            BEGIN
                g_error := 'INSERT CONTEXT IMAGE';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_context_image.count > 0)
                THEN
                    FORALL i IN ibt_guideline_context_image.first .. ibt_guideline_context_image.last
                        INSERT INTO guideline_context_image
                        VALUES ibt_guideline_context_image
                            (i);
                END IF;
            EXCEPTION
                -- Error on context image insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Context Author
            BEGIN
                g_error := 'INSERT CONTEXT AUTHOR';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_context_author.count > 0)
                THEN
                    FORALL i IN ibt_guideline_context_author.first .. ibt_guideline_context_author.last
                        INSERT INTO guideline_context_author
                        VALUES ibt_guideline_context_author
                            (i);
                END IF;
            EXCEPTION
                -- Error on context author insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Link
            BEGIN
                g_error := 'INSERT LINK';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_link.count > 0)
                THEN
                
                    FORALL i IN ibt_guideline_link.first .. ibt_guideline_link.last
                        INSERT INTO guideline_link
                        VALUES ibt_guideline_link
                            (i);
                END IF;
            EXCEPTION
                -- Error on guideline links insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Task Link
            BEGIN
                g_error := 'INSERT TASK LINK';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_task_link.count > 0)
                THEN
                
                    FORALL i IN ibt_guideline_task_link.first .. ibt_guideline_task_link.last
                        INSERT INTO guideline_task_link
                        VALUES ibt_guideline_task_link
                            (i);
                END IF;
            EXCEPTION
                -- Error on task links insertion
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- advanced input values
            BEGIN
                g_error := 'INSERT ADVANCED INPUT VALUE';
                pk_alertlog.log_debug(g_error, g_log_object_name);
                IF (ibt_guideline_adv_input_value.count > 0)
                THEN
                
                    FORALL i IN ibt_guideline_adv_input_value.first .. ibt_guideline_adv_input_value.last
                        INSERT INTO guideline_adv_input_value
                        VALUES ibt_guideline_adv_input_value
                            (i);
                END IF;
                -- Error on advanced input values insertion
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on insertion of at least one of the items above
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END create_guideline;

    /** 
    *  Set specific guideline main attributes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_GUIDELINE_DESC             Guideline description       
    * @param      I_ID_GUIDELINE_TYPE          Guideline Type
    * @param      I_LINK_ENVIRONMENT           Guideline environment link        
    * @param      I_LINK_SPECIALTY             Guideline specialty link
    * @param      I_LINK_PROFESSIONAL          Guideline professional link
    * @param      I_LINK_EDIT_PROF             Guideline edit professional link
    * @param      I_TYPE_RECOMMEDNATION        Guideline type of recommendation
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/22
    */
    FUNCTION set_guideline_main
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline        IN guideline.id_guideline%TYPE,
        i_guideline_desc      IN guideline.guideline_desc%TYPE,
        i_link_type           IN table_number,
        i_link_environment    IN table_number,
        i_link_specialty      IN table_number,
        i_link_professional   IN table_number,
        i_link_edit_prof      IN table_number,
        i_type_recommendation IN guideline.flg_type_recommendation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_guideline_link IS TABLE OF guideline_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_link t_guideline_link;
        counter            PLS_INTEGER;
    
        l_ins_link BOOLEAN := FALSE;
        error_undefined_status EXCEPTION;
    BEGIN
        g_error := 'UPDATE GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        UPDATE guideline
           SET flg_type_recommendation = i_type_recommendation, guideline_desc = i_guideline_desc
         WHERE id_guideline = i_id_guideline
           AND flg_status = g_guideline_temp;
    
        IF (SQL%ROWCOUNT = 0)
        THEN
            RAISE error_undefined_status;
        END IF;
    
        counter := 0;
        g_error := 'CREATE RECORDS TYPE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_type.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_type.first .. i_link_type.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := i_link_type(i);
                ibt_guideline_link(counter).link_type := g_guide_link_type;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS ENVIRONMENT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_environment.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_environment.first .. i_link_environment.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := i_link_environment(i);
                ibt_guideline_link(counter).link_type := g_guide_link_envi;
                counter := counter + 1;
            END LOOP;
        END IF;
        g_error := 'CREATE RECORDS SPECIALTY';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_specialty.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_specialty.first .. i_link_specialty.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := i_link_specialty(i);
                ibt_guideline_link(counter).link_type := g_guide_link_spec;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS PROFESSIONAL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_professional.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_professional.first .. i_link_professional.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := i_link_professional(i);
                ibt_guideline_link(counter).link_type := g_guide_link_prof;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS EDIT PROFESSIONAL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_edit_prof.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_edit_prof.first .. i_link_edit_prof.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := i_link_edit_prof(i);
                ibt_guideline_link(counter).link_type := g_guide_link_edit_prof;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'DELETE GUIDELINE LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_link
         WHERE id_guideline = i_id_guideline
           AND link_type NOT IN (g_guide_link_pathol, g_guide_link_chief_complaint); -- pathology and chief complaints are being taken care of in another function
    
        g_error := 'INSERT GUIDELINE LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        BEGIN
        
            IF (l_ins_link)
            THEN
                FORALL i IN ibt_guideline_link.first .. ibt_guideline_link.last SAVE EXCEPTIONS
                    INSERT INTO guideline_link
                    VALUES ibt_guideline_link
                        (i);
            END IF;
        EXCEPTION
            -- Error on guideline links insertion
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Error if the guideline that has to be updated not exists
        WHEN error_undefined_status THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state for guideline',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_main;

    /** 
    *  Set specific guideline main pathology
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                  Guideline ID
    * @param      I_LINK_PATHOLOGY             Pathology link ID     
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/16
    */
    FUNCTION set_guideline_main_pathology
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_link_pathology IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_guideline_link IS TABLE OF guideline_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_link t_guideline_link;
        counter            PLS_INTEGER;
        l_link_pathology   table_number;
        l_ins_link         BOOLEAN := FALSE;
    BEGIN
        counter := 0;
    
        g_error := 'CREATE RECORDS PATHOLOGY';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_link_pathology.count != 0)
        THEN
            l_link_pathology := SET(i_link_pathology);
            l_ins_link       := TRUE;
            FOR i IN l_link_pathology.first .. l_link_pathology.last
            LOOP
                ibt_guideline_link(counter).id_guideline_link := get_guideline_link_seq;
                ibt_guideline_link(counter).id_guideline := i_id_guideline;
                ibt_guideline_link(counter).id_link := l_link_pathology(i);
                ibt_guideline_link(counter).link_type := g_guide_link_pathol;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'DELETE GUIDELINE LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_link
         WHERE id_guideline = i_id_guideline
           AND link_type = g_guide_link_pathol;
    
        g_error := 'INSERT GUIDELINE LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        BEGIN
        
            IF (l_ins_link)
            THEN
                FORALL i IN ibt_guideline_link.first .. ibt_guideline_link.last SAVE EXCEPTIONS
                    INSERT INTO guideline_link
                    VALUES ibt_guideline_link
                        (i);
            END IF;
        EXCEPTION
            -- Error on guideline links insertion
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on insertion/delete of new items associated to guideline
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN_PATHOLOGY',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception types
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN_PATHOLOGY',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_main_pathology;

    /** 
    *  Get guideline items to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_ITEMS     List of items to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/28
    */
    FUNCTION get_guideline_items
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_items OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET GUIDELINE ITEMS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_items FOR
            SELECT DISTINCT item, flg_item_type
              FROM (SELECT item,
                           flg_item_type,
                           first_value(gisi.flg_available) over(PARTITION BY gisi.item, gisi.flg_item_type ORDER BY gisi.id_market DESC, gisi.id_institution DESC, gisi.id_software DESC, gisi.flg_available) AS flg_avail
                      FROM guideline_item_soft_inst gisi
                     WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                       AND gisi.id_software IN (g_all_software, i_prof.software)
                       AND gisi.id_market IN (g_all_markets, l_market)) guide_item
             WHERE flg_avail = g_available
               AND ((guide_item.flg_item_type = g_guideline_item_criteria AND
                   guide_item.item NOT IN (SELECT id_guideline_criteria_type
                                               FROM guideline_criteria_type)) OR
                   guide_item.flg_item_type = g_guideline_item_tasks); -- without other criteria
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_ITEMS',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_items);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_items;

    /** 
    *  Get guideline main attributes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_MAIN             Guideline main attributes cursor
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_main
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_main OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_edit_permissions VARCHAR2(1000 CHAR) := get_link_id_str(i_lang,
                                                                       i_prof,
                                                                       i_id_guideline,
                                                                       g_guide_link_edit_prof,
                                                                       g_separator);
        l_desc_environment      VARCHAR2(1000 CHAR) := get_link_id_str(i_lang,
                                                                       i_prof,
                                                                       i_id_guideline,
                                                                       g_guide_link_envi,
                                                                       g_separator);
    
    BEGIN
    
        g_error := 'GET GUIDELINE MAIN';
        IF l_desc_environment IS NULL
           OR l_desc_environment = ''
        THEN
            BEGIN
                SELECT DISTINCT pk_translation.get_translation(i_lang, d.code_dept)
                  INTO l_desc_environment
                  FROM dept d, department dep, dep_clin_serv dcs, prof_dep_clin_serv pdcs, software_dept sd
                 WHERE d.id_institution = i_prof.institution
                   AND dep.id_dept = d.id_dept
                   AND dcs.id_department = dep.id_department
                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND sd.id_dept = d.id_dept
                   AND d.flg_available = g_available
                   AND dep.flg_available = g_available
                   AND dcs.flg_available = g_available
                   AND sd.id_software = i_prof.software
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_desc_environment := NULL;
            END;
        END IF;
    
        g_error := 'OPEN GUIDELINE MAIN';
        OPEN o_guideline_main FOR
            SELECT guid.id_guideline,
                   guid.flg_status,
                   guid.guideline_desc,
                   nvl((SELECT g_available
                         FROM guideline_link
                        WHERE id_guideline = i_id_guideline
                          AND link_type = g_guide_link_pathol
                          AND rownum = 1),
                       g_not_available) exist_pathologies,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator2) pathology_desc,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) type_desc,
                   l_desc_environment environment_desc,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_spec, g_separator) speciality_desc,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_prof, g_separator) professional_desc,
                   pk_message.get_message(i_lang, g_message_guideline_authors) ||
                   decode(l_desc_edit_permissions, '', '', g_separator) || l_desc_edit_permissions AS edit_professional_desc,
                   guid.flg_type_recommendation AS flg_type_rec,
                   pk_sysdomain.get_domain(g_domain_flg_type_rec, guid.flg_type_recommendation, i_lang) AS desc_recommendation,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_chief_complaint, g_separator) AS desc_chief_complaint
              FROM guideline guid
             WHERE guid.id_guideline = i_id_guideline;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_MAIN',
                                              o_error);
            pk_types.open_my_cursor(o_guideline_main);
            RETURN FALSE;
    END get_guideline_main;

    /** 
    *  Obtain all guidelines by title
    *
    * @param      I_LANG                 Preferred language ID for this professional
    * @param      I_PROF                 object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE                Value to search for        
    * @param      I_ID_PATIENT           Patient ID   
    * @param      O_GUIDELINES           cursor with all guidelines
    * @param      O_ERROR                error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_by_title
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        i_id_patient IN guideline_process.id_patient%TYPE,
        o_guidelines OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guidelines FOR
            SELECT guid.id_guideline AS id_guideline,
                   guid.guideline_desc AS guide_title,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator) pathology_desc,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) type_desc,
                   check_history_guideline(guid.id_guideline, i_id_patient) AS flg_already_recommended
              FROM guideline      guid,
                   guideline_link guid_lnk,
                   --guideline_link     guid_lnk2,
                   guideline_criteria guid_crit_inc,
                   guideline_criteria guid_crit_exc
             WHERE guid.flg_status = g_guideline_finished
                  -- professional category
               AND guid_lnk.id_guideline = guid.id_guideline
               AND guid_lnk.link_type = g_guide_link_prof
               AND guid_lnk.id_link = (SELECT pc.id_category
                                         FROM prof_cat pc
                                        WHERE pc.id_professional = i_prof.id
                                          AND pc.id_institution = i_prof.institution)
                  -- specialty
                  --AND guid_lnk2.id_guideline = guid.id_guideline
                  --AND guid_lnk2.link_type = g_guide_link_spec
                  --AND guid_lnk2.id_link = (SELECT id_speciality
                  --                           FROM professional
                  --                         WHERE id_professional = i_prof.id)
                  -- department/environment
               AND i_prof.software IN (SELECT sd.id_software
                                         FROM software_dept sd, guideline_link guid_lnk3
                                        WHERE guid_lnk3.id_guideline = guid.id_guideline
                                          AND guid_lnk3.link_type = g_guide_link_envi
                                          AND guid_lnk3.id_link = sd.id_dept)
               AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                            column_value
                                             FROM TABLE(l_institutions) inst)
               AND guid.flg_type_recommendation != g_type_rec_automatic
                  -- Guidelines created in Alert Care should not appear in the other softwares               
                  --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND guid.id_software = pk_alert_constant.g_soft_primary_care) OR
                  --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND guid.id_software != pk_alert_constant.g_soft_primary_care))
                  -- search for value
               AND ((translate(upper(guid.guideline_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
                  -- check patient gender                                         
               AND guid_crit_inc.id_guideline = guid.id_guideline
               AND guid_crit_inc.criteria_type = g_criteria_type_inc
               AND nvl(guid_crit_inc.gender, l_pat_gender) = l_pat_gender
               AND guid_crit_exc.id_guideline = guid.id_guideline
               AND guid_crit_exc.criteria_type = g_criteria_type_exc
               AND ((l_pat_gender != guid_crit_exc.gender AND guid_crit_exc.gender IS NOT NULL) OR
                   guid_crit_exc.gender IS NULL)
             ORDER BY upper(guide_title);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_BY_TITLE',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_by_title;

    /** 
    *  Get all guideline types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_TYPE             Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_type_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_type FOR
            SELECT guid_typ.id_guideline_type,
                   1 rank,
                   pk_translation.get_translation(i_lang, guid_typ.code_guideline_type) desc_guideline_type
              FROM guideline_type guid_typ
             WHERE guid_typ.flg_available = g_available
            UNION ALL
            SELECT g_id_guide_type_any id_guideline_type,
                   2 rank,
                   pk_message.get_message(i_lang, g_message_any) desc_guideline_type
              FROM dual
             ORDER BY rank, desc_guideline_type;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TYPE_ALL',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_type);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_type_all;

    /** 
    *  Get pathologies of a specific type of guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TYPE          ID of guideline type
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_GUIDELINE_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.4
    * @since      2007/05/04
    */
    FUNCTION get_guideline_pathologies
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline_type IN guideline_link.id_link%TYPE,
        i_id_patient        IN guideline_process.id_patient%TYPE,
        o_guideline_pathol  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_pathol   NUMBER(6);
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'COUNT PATHOLOGIES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT COUNT(1)
          INTO l_num_pathol
          FROM guideline          guid,
               guideline_link     guid_lnk,
               guideline_link     guid_lnk2,
               guideline_link     guid_lnk3,
               guideline_criteria guid_crit_inc,
               guideline_criteria guid_crit_exc
         WHERE guid.flg_status = g_guideline_finished
           AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                        column_value
                                         FROM TABLE(l_institutions) inst)
              -- Guidelines created in Alert Care should not appear in the other softwares
              --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND guid.id_software = pk_alert_constant.g_soft_primary_care) OR
              --   (i_prof.software != pk_alert_constant.g_soft_primary_care AND guid.id_software != pk_alert_constant.g_soft_primary_care))
           AND guid.flg_type_recommendation != g_type_rec_automatic
              -- professional category
           AND guid_lnk3.id_guideline = guid.id_guideline
           AND guid_lnk3.link_type = g_guide_link_prof
           AND guid_lnk3.id_link = (SELECT pc.id_category
                                      FROM prof_cat pc
                                     WHERE pc.id_professional = i_prof.id
                                       AND pc.id_institution = i_prof.institution)
              -- department/environment
           AND i_prof.software IN (SELECT sd.id_software
                                     FROM software_dept sd, guideline_link guid_lnk4
                                    WHERE guid_lnk4.id_guideline = guid.id_guideline
                                      AND guid_lnk4.link_type = g_guide_link_envi
                                      AND guid_lnk4.id_link = sd.id_dept)
              
           AND guid_lnk.id_guideline = guid.id_guideline
           AND guid_lnk.link_type = g_guide_link_pathol
           AND guid_lnk2.id_guideline = guid.id_guideline
           AND guid_lnk2.link_type = g_guide_link_type
           AND guid_lnk2.id_link =
               decode(i_id_guideline_type, g_id_guide_type_any, guid_lnk2.id_link, i_id_guideline_type)
              --AND guid.id_guideline NOT IN
              --   (SELECT id_guideline
              --       FROM guideline_process
              --      WHERE id_patient = i_id_patient
              --        AND flg_status IN (g_process_running, g_process_pending, g_process_recommended))
              -- check patient gender                                         
           AND guid_crit_inc.id_guideline = guid.id_guideline
           AND guid_crit_inc.criteria_type = g_criteria_type_inc
           AND nvl(guid_crit_inc.gender, l_pat_gender) = l_pat_gender
           AND guid_crit_exc.id_guideline = guid.id_guideline
           AND guid_crit_exc.criteria_type = g_criteria_type_exc
           AND ((l_pat_gender != guid_crit_exc.gender AND guid_crit_exc.gender IS NOT NULL) OR
               guid_crit_exc.gender IS NULL);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF l_num_pathol != 0
        THEN
        
            OPEN o_guideline_pathol FOR
                SELECT id_pathol, rank, desc_pathol, i_id_guideline_type
                  FROM (SELECT pathol.id_link AS id_pathol,
                               1 rank,
                               pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_diagnosis => diag.id_diagnosis,
                                                          i_code         => diag.code_icd,
                                                          i_flg_other    => diag.flg_other,
                                                          i_flg_std_diag => pk_alert_constant.g_yes) AS desc_pathol
                        
                          FROM (SELECT DISTINCT guid_lnk.id_link
                                  FROM guideline          guid,
                                       guideline_link     guid_lnk,
                                       guideline_link     guid_lnk2,
                                       guideline_link     guid_lnk3,
                                       guideline_criteria guid_crit_inc,
                                       guideline_criteria guid_crit_exc
                                 WHERE guid.flg_status = g_guideline_finished
                                   AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                                column_value
                                                                 FROM TABLE(l_institutions) inst)
                                      --AND guid.id_software = i_prof.software
                                   AND guid.flg_type_recommendation != g_type_rec_automatic
                                   AND guid_lnk3.id_guideline = guid.id_guideline
                                   AND guid_lnk3.link_type = g_guide_link_prof
                                   AND guid_lnk3.id_link =
                                       (SELECT pc.id_category
                                          FROM prof_cat pc
                                         WHERE pc.id_professional = i_prof.id
                                           AND pc.id_institution = i_prof.institution)
                                      
                                      -- department/environment
                                   AND i_prof.software IN (SELECT sd.id_software
                                                             FROM software_dept sd, guideline_link guid_lnk3
                                                            WHERE guid_lnk3.id_guideline = guid.id_guideline
                                                              AND guid_lnk3.link_type = g_guide_link_envi
                                                              AND guid_lnk3.id_link = sd.id_dept)
                                      
                                   AND guid_lnk.id_guideline = guid.id_guideline
                                   AND guid_lnk.link_type = g_guide_link_pathol
                                   AND guid_lnk2.id_guideline = guid.id_guideline
                                   AND guid_lnk2.link_type = g_guide_link_type
                                   AND guid_lnk2.id_link = decode(i_id_guideline_type,
                                                                  g_id_guide_type_any,
                                                                  guid_lnk2.id_link,
                                                                  i_id_guideline_type)
                                      --AND guid.id_guideline NOT IN
                                      --    (SELECT id_guideline
                                      --       FROM guideline_process
                                      --      WHERE id_patient = i_id_patient
                                      --        AND flg_status IN (g_process_running, g_process_pending, g_process_recommended))
                                      -- check patient gender                                         
                                   AND guid_crit_inc.id_guideline = guid.id_guideline
                                   AND guid_crit_inc.criteria_type = g_criteria_type_inc
                                   AND nvl(guid_crit_inc.gender, l_pat_gender) = l_pat_gender
                                   AND guid_crit_exc.id_guideline = guid.id_guideline
                                   AND guid_crit_exc.criteria_type = g_criteria_type_exc
                                   AND ((l_pat_gender != guid_crit_exc.gender AND guid_crit_exc.gender IS NOT NULL) OR
                                       guid_crit_exc.gender IS NULL)) pathol,
                               diagnosis diag -- pathology
                         WHERE pathol.id_link = diag.id_diagnosis
                        
                        UNION ALL
                        
                        SELECT g_id_guide_pathol_any AS id_pathol,
                               2 rank,
                               pk_message.get_message(i_lang, g_message_any) AS desc_pathol
                          FROM dual
                         WHERE l_num_pathol > 1)
                 ORDER BY rank, desc_pathol;
        ELSE
            pk_types.open_my_cursor(o_guideline_pathol);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_PATHOLOGIES',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_pathol);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_pathologies;

    /** 
    *  Get all guidelines by type and pathology
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TYPE          ID of guideline type
    * @param      I_ID_GUIDELINE_PATHO         ID of guideline pathology
    * @param      I_ID_PATIENT                 Patient ID   
    * @param      O_GUIDELINE_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_by_type_patho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline_type   IN guideline_link.id_link%TYPE,
        i_id_guideline_pathol IN guideline_link.id_link%TYPE,
        i_id_patient          IN guideline_process.id_patient%TYPE,
        o_guidelines          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guidelines FOR
            SELECT id_guideline,
                   guide_title,
                   check_history_guideline(id_guideline, i_id_patient) AS flg_already_recommended
              FROM (SELECT DISTINCT (guid.id_guideline), guid.guideline_desc AS guide_title
                      FROM guideline          guid,
                           guideline_link     guid_lnk,
                           guideline_link     guid_lnk2,
                           guideline_link     guid_lnk3,
                           guideline_criteria guid_crit_inc,
                           guideline_criteria guid_crit_exc
                     WHERE guid.flg_status = g_guideline_finished
                       AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                    column_value
                                                     FROM TABLE(l_institutions) inst)
                          -- Guidelines created in Alert Care should not appear in the other softwares
                          --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND guid.id_software = pk_alert_constant.g_soft_primary_care) OR
                          --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND guid.id_software != pk_alert_constant.g_soft_primary_care))
                       AND guid.flg_type_recommendation != g_type_rec_automatic
                          -- professional category
                       AND guid_lnk3.id_guideline = guid.id_guideline
                       AND guid_lnk3.link_type = g_guide_link_prof
                       AND guid_lnk3.id_link = (SELECT pc.id_category
                                                  FROM prof_cat pc
                                                 WHERE pc.id_professional = i_prof.id
                                                   AND pc.id_institution = i_prof.institution)
                          -- department/environment
                       AND i_prof.software IN (SELECT sd.id_software
                                                 FROM software_dept sd, guideline_link guid_lnk4
                                                WHERE guid_lnk4.id_guideline = guid.id_guideline
                                                  AND guid_lnk4.link_type = g_guide_link_envi
                                                  AND guid_lnk4.id_link = sd.id_dept)
                          
                       AND guid_lnk.id_guideline = guid.id_guideline
                       AND guid_lnk.link_type = g_guide_link_pathol
                       AND ((i_id_guideline_pathol != g_id_guide_pathol_any AND guid_lnk.id_link = i_id_guideline_pathol) OR
                           i_id_guideline_pathol = g_id_guide_pathol_any)
                       AND guid_lnk2.id_guideline = guid.id_guideline
                       AND guid_lnk2.link_type = g_guide_link_type
                       AND ((i_id_guideline_type != g_id_guide_type_any AND guid_lnk2.id_link = i_id_guideline_type) OR
                           i_id_guideline_type = g_id_guide_type_any)
                          -- check patient gender                                         
                       AND guid_crit_inc.id_guideline = guid.id_guideline
                       AND guid_crit_inc.criteria_type = g_criteria_type_inc
                       AND nvl(guid_crit_inc.gender, l_pat_gender) = l_pat_gender
                       AND guid_crit_exc.id_guideline = guid.id_guideline
                       AND guid_crit_exc.criteria_type = g_criteria_type_exc
                       AND ((l_pat_gender != guid_crit_exc.gender AND guid_crit_exc.gender IS NOT NULL) OR
                           guid_crit_exc.gender IS NULL))
             ORDER BY upper(guide_title);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_BY_TYPE_PATHO',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_by_type_patho;

    /** 
    *  Obtain all guidelines by pathology
    *
    * @param      I_LANG               Preferred language ID for this professional
    * @param      I_PROF               object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE              Value to search for        
    * @param      O_GUIDELINES         cursor with all guidelines classified by type
    * @param      O_ERROR              error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_guideline_by_pathology
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        o_guidelines OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions table_number;
    
    BEGIN
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guidelines FOR
            SELECT guid.id_guideline,
                   guid.guideline_desc,
                   decode(guid.flg_status, g_guideline_deleted, g_cancelled, g_not_cancelled) AS flg_cancel,
                   -- guideline cannot be edited or duplicated when it was created in other than professional's institution
                   decode(guid.id_institution,
                           i_prof.institution,
                           -- grants for professional
                           CASE
                               WHEN guid.id_content IS NULL THEN
                                decode(nvl((
                                           -- grants by author history
                                           SELECT g_available
                                             FROM guideline grants_guide
                                            WHERE id_professional = i_prof.id
                                              AND rownum = 1
                                            START WITH grants_guide.id_guideline = guid.id_guideline
                                           CONNECT BY PRIOR grants_guide.id_guideline = grants_guide.id_guideline_previous_version
                                           UNION
                                           -- grants by professional category
                                           SELECT g_available
                                             FROM guideline_link guid_lnk, prof_cat pc
                                            WHERE guid_lnk.id_guideline = guid.id_guideline
                                              AND guid_lnk.link_type = g_guide_link_edit_prof
                                              AND pc.id_professional = i_prof.id
                                              AND pc.id_institution = i_prof.institution
                                              AND guid_lnk.id_link = pc.id_category),
                                           g_not_available),
                                       g_available,
                                       decode(guid.flg_status, g_guideline_deleted, NULL, g_guideline_editable),
                                       NULL)
                               ELSE
                                NULL -- if this guideline has an id_content, then edit option should not be possible
                           END || '|' || g_guideline_duplicable || '|' || g_guideline_viewable,
                           g_guideline_viewable) AS flg_edit_options,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator) pathology_desc,
                   get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) type_desc,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional),
                       pk_message.get_message(i_lang, g_message_na)) || chr(10) ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, guid.dt_guideline, i_prof.institution, i_prof.software) author_date_desc,
                   pk_date_utils.date_send_tsz(i_lang, guid.dt_guideline, i_prof) AS dt_guideline
              FROM guideline guid
              LEFT OUTER JOIN professional prof
                ON (guid.id_professional = prof.id_professional)
             WHERE guid.flg_status != g_guideline_temp -- gets all guidelines status except temp and deprecated
               AND guid.flg_status != g_guideline_deprecated
               AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                            column_value
                                             FROM TABLE(l_institutions) inst)
                  -- Guidelines created in Alert Care should not appear in the other softwares             
                  --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND guid.id_software = pk_alert_constant.g_soft_primary_care) OR
                  --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND guid.id_software != pk_alert_constant.g_soft_primary_care))
                  -- ** search for value **
               AND ((translate(upper(get_link_id_str(i_lang,
                                                     i_prof,
                                                     guid.id_guideline,
                                                     g_guide_link_pathol,
                                                     g_separator) || guid.guideline_desc),
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                               'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
             ORDER BY flg_cancel, upper(guid.guideline_desc);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_BY_PATHOLOGY',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_by_pathology;

    /** 
    *  Gets guideline pathology ids
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_PATHOLOGY_ID               Guideline pathology ids
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_pathology_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_pathology_id OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET GUIDELINE MAIN';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_pathology_id FOR
            SELECT guid.id_guideline, guid_lnk.id_link
              FROM guideline guid, guideline_link guid_lnk
             WHERE guid.id_guideline = i_id_guideline
               AND guid_lnk.id_guideline = guid.id_guideline
               AND guid_lnk.link_type = g_guide_link_pathol;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PATHOLOGY_ID',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pathology_id);
            -- return failure of function
            RETURN FALSE;
        
    END get_pathology_id;

    /** 
    *  Get all types of appointments
    *
    * @param      I_LANG       Preferred language ID for this professional
    * @param      I_PROF       Object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE      Search value
    * @param      O_SPECS      Specialties
    * @param      O_ERROR      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.2
    * @since      2007/08/21
    */
    FUNCTION get_appointments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN VARCHAR2,
        o_specs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_specs FOR
            SELECT *
              FROM (SELECT -1 id_dep_clin_serv,
                           -1 id_clinical_service,
                           pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint) desc_appoint,
                           1 rank
                      FROM dual
                    UNION ALL
                    SELECT dcs.id_dep_clin_serv,
                           cs.id_clinical_service,
                           pk_message.get_message(i_lang, g_message_spec_appoint) || ' - ' ||
                           pk_translation.get_translation(i_lang, dep.code_department) || ' - ' ||
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_appoint,
                           2 rank
                      FROM department dep, dep_clin_serv dcs, clinical_service cs
                     WHERE dep.id_institution = i_prof.institution
                       AND instr(dep.flg_type, g_external_appoint) > 0
                       AND dcs.id_department = dep.id_department
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.flg_available = g_available
                          -- filter to enable/disable specialty appointments, even if follow-up appointments are enabled
                       AND NOT EXISTS (SELECT 1
                              FROM (SELECT item,
                                           flg_item_type,
                                           first_value(gisi.flg_available) over(PARTITION BY gisi.item, gisi.flg_item_type ORDER BY gisi.id_market DESC, gisi.id_institution DESC, gisi.id_software DESC, gisi.flg_available) AS flg_avail
                                      FROM guideline_item_soft_inst gisi
                                     WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                                       AND gisi.id_software IN (g_all_software, i_prof.software)
                                       AND gisi.id_market IN (g_all_markets, l_market)
                                       AND flg_item_type = g_guideline_item_tasks
                                       AND item IN (g_task_appoint, g_task_specialty_appointment))
                             WHERE (item = g_task_specialty_appointment AND flg_avail = g_not_available)
                                OR (item = g_task_appoint AND flg_avail = g_not_available))
                       AND EXISTS
                     (SELECT 1
                              FROM professional prf, prof_dep_clin_serv pdcs, prof_func pf
                             WHERE prf.flg_state = g_prof_active
                                  --AND prf.id_professional != i_prof.id
                               AND pdcs.id_professional = prf.id_professional
                               AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                               AND pdcs.flg_status = g_selectedpt
                               AND pf.id_professional = prf.id_professional
                               AND pf.id_functionality = pk_sysconfig.get_config(g_config_func_consult_req, i_prof)
                               AND pf.id_institution = i_prof.institution))
             WHERE translate(upper(desc_appoint), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
             ORDER BY rank, desc_appoint;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_APPOINTMENTS',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_specs);
            -- return failure of function
            RETURN FALSE;
        
    END get_appointments;

    /** 
    *  Set guideline criteria
    *
    * @param      I_LANG                         Preferred language ID for this professional
    * @param      I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                 Guideline ID
    * @param      I_CRITERIA_TYPE                Criteria Type: Inclusion / Exclusion
    * @param      I_GENDER                       Gender: Male / Female / Undefined
    * @param      I_MIN_AGE                      Minimum age
    * @param      I_MAX_AGE                      Maximum age
    * @param      I_MIN_WEIGHT                   Minimum weight
    * @param      I_MAX_WEIGHT                   Maximum weight
    * @param      I_ID_WEIGHT_UNIT_MEASURE       Measure for weight unit ID
    * @param      I_MIN_HEIGHT                   Minimum height
    * @param      I_MAX_HEIGHT                   Maximum height
    * @param      I_ID_HEIGHT_UNIT_MEASURE       Measure for height unit ID
    * @param      I_IMC_MIN                      IMC minimum value
    * @param      I_IMC_MAX                      IMC maximum value
    * @param      I_ID_BLOOD_PRESS_UNIT_MEASURE  Measure for height unit ID
    * @param      I_MIN_BLOOD_PRESSURE_S         Diastolic blood pressure minimum value
    * @param      I_MAX_BLOOD_PRESSURE_S         Diastolic blood pressure maximum value
    * @param      I_MIN_BLOOD_PRESSURE_D         Systolic blood pressure minimum value
    * @param      I_MAX_BLOOD_PRESSURE_D         Systolic blood pressure maximum value
    *
    * @param      O_ERROR                        error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/16
    */
    FUNCTION set_guideline_criteria
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_guideline                IN guideline.id_guideline%TYPE,
        i_criteria_type               IN guideline_criteria.criteria_type%TYPE,
        i_gender                      IN guideline_criteria.gender%TYPE,
        i_min_age                     IN guideline_criteria.min_age%TYPE,
        i_max_age                     IN guideline_criteria.max_age%TYPE,
        i_min_weight                  IN guideline_criteria.min_weight%TYPE,
        i_max_weight                  IN guideline_criteria.max_weight%TYPE,
        i_id_weight_unit_measure      IN guideline_criteria.id_weight_unit_measure%TYPE,
        i_min_height                  IN guideline_criteria.min_height%TYPE,
        i_max_height                  IN guideline_criteria.max_height%TYPE,
        i_id_height_unit_measure      IN guideline_criteria.id_height_unit_measure%TYPE,
        i_imc_min                     IN guideline_criteria.imc_min%TYPE,
        i_imc_max                     IN guideline_criteria.imc_max%TYPE,
        i_id_blood_press_unit_measure IN guideline_criteria.id_blood_pressure_unit_measure%TYPE,
        i_min_blood_pressure_s        IN guideline_criteria.min_blood_pressure_s%TYPE,
        i_max_blood_pressure_s        IN guideline_criteria.max_blood_pressure_s%TYPE,
        i_min_blood_pressure_d        IN guideline_criteria.min_blood_pressure_d%TYPE,
        i_max_blood_pressure_d        IN guideline_criteria.max_blood_pressure_d%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE GUIDELINE CRITERIA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Update guideline criteria
        UPDATE guideline_criteria
           SET gender                         = i_gender,
               min_age                        = i_min_age,
               max_age                        = i_max_age,
               min_weight                     = i_min_weight,
               max_weight                     = i_max_weight,
               id_weight_unit_measure         = i_id_weight_unit_measure,
               min_height                     = i_min_height,
               max_height                     = i_max_height,
               id_height_unit_measure         = i_id_height_unit_measure,
               imc_min                        = i_imc_min,
               imc_max                        = i_imc_max,
               id_blood_pressure_unit_measure = i_id_blood_press_unit_measure,
               min_blood_pressure_s           = i_min_blood_pressure_s,
               max_blood_pressure_s           = i_max_blood_pressure_s,
               min_blood_pressure_d           = i_min_blood_pressure_d,
               max_blood_pressure_d           = i_max_blood_pressure_d
         WHERE id_guideline = i_id_guideline
           AND criteria_type = i_criteria_type;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CRITERIA',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_criteria;

    /** 
    *  Set guideline criteria
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                Guideline ID
    * @param      I_CRITERIA_TYPE               Criteria Type: Inclusion / Exclusion
    * @param      I_ID_LINK_OTHER_CRITERIA      Other criterias link
    * @param      I_ID_LINK_OTHER_CRITERIA_TYPE Type of other criteria link
    * @param      O_ID_GUID_CRITERIA_LINK       New ID of each criteria
    * @param      O_ERROR                       error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_criteria_other
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_guideline                IN guideline.id_guideline%TYPE,
        i_criteria_type               IN guideline_criteria.criteria_type%TYPE,
        i_id_link_other_criteria      IN table_varchar,
        i_id_link_other_criteria_type IN table_number,
        o_id_guid_criteria_link       OUT table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_guideline_criteria_link IS TABLE OF guideline_criteria_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_criteria_link  t_guideline_criteria_link;
        l_id_guideline_criteria      guideline_criteria_link.id_guideline_criteria%TYPE;
        l_link_crit                  BOOLEAN := FALSE;
        l_id_guideline_criteria_link guideline_criteria_link.id_guideline_criteria_link%TYPE;
    BEGIN
        g_error := 'GET GUIDELINE CRITERIA ID';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT id_guideline_criteria
          INTO l_id_guideline_criteria
          FROM guideline_criteria
         WHERE id_guideline = i_id_guideline
           AND criteria_type = i_criteria_type;
    
        -- Delete old guideline_adv_input_value associated to criterias
        g_error := 'DELETE OLD ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_adv_input_value
         WHERE flg_type = g_adv_input_type_criterias
           AND id_adv_input_link IN
               (SELECT guid_crit_lnk.id_guideline_criteria_link
                  FROM guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                 WHERE guid_crit.id_guideline = i_id_guideline
                   AND guid_crit.criteria_type = i_criteria_type
                   AND guid_crit.id_guideline_criteria = guid_crit_lnk.id_guideline_criteria);
    
        -- Delete old criterias
        g_error := 'DELETE OLD GUIDELINE CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_criteria_link
         WHERE id_guideline_criteria_link IN
               (SELECT guid_crit_lnk.id_guideline_criteria_link
                  FROM guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                 WHERE guid_crit.id_guideline = i_id_guideline
                   AND guid_crit.criteria_type = i_criteria_type
                   AND guid_crit.id_guideline_criteria = guid_crit_lnk.id_guideline_criteria);
    
        g_error := 'SETUP NEW GUIDELINE CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        o_id_guid_criteria_link := table_number();
    
        -- Setup new criterias
        IF (i_id_link_other_criteria.count != 0)
        THEN
            l_link_crit := TRUE;
            FOR i IN i_id_link_other_criteria.first .. i_id_link_other_criteria.last
            LOOP
                l_id_guideline_criteria_link := get_guideline_crit_lnk_seq;
                o_id_guid_criteria_link.extend;
                o_id_guid_criteria_link(o_id_guid_criteria_link.last) := l_id_guideline_criteria_link;
                ibt_guideline_criteria_link(i).id_guideline_criteria_link := l_id_guideline_criteria_link;
                ibt_guideline_criteria_link(i).id_guideline_criteria := l_id_guideline_criteria;
                ibt_guideline_criteria_link(i).id_link_other_criteria := i_id_link_other_criteria(i);
                ibt_guideline_criteria_link(i).id_link_other_criteria_type := i_id_link_other_criteria_type(i);
            END LOOP;
        END IF;
        g_error := 'INSERT NEW GUIDELINE CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Insert new criterias
        BEGIN
            IF (l_link_crit)
            THEN
                FORALL i IN ibt_guideline_criteria_link.first .. ibt_guideline_criteria_link.last SAVE EXCEPTIONS
                    INSERT INTO guideline_criteria_link
                    VALUES ibt_guideline_criteria_link
                        (i);
            END IF;
        EXCEPTION
            -- Error on criteria insertion
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Error on insertion/delete of new criterias
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CRITERIA_OTHER',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CRITERIA_OTHER',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_criteria_other;

    /** 
    *  Get guideline criteria
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CRITERIA_TYPE              Criteria Type: Inclusion / Exclusion
    * @param      O_GUIDELINE_CRITERIA         Cursor for guideline criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_criteria
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_criteria_type      IN guideline_criteria.criteria_type%TYPE,
        o_guideline_criteria OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_unit_measure(c_id_vital_sign vital_sign.id_vital_sign%TYPE) IS
            SELECT DISTINCT /*+opt_estimate (table vsum rows=1)*/ vsum.id_vital_sign,
                            vsum.val_min,
                            vsum.val_max,
                            vsum.format_num,
                            pk_translation.get_translation(i_lang, um.code_unit_measure) AS desc_unit_measure,
                            vsum.id_unit_measure
              FROM TABLE(pk_vital_sign_core.tf_vital_sign_unit_measure(i_lang            => i_lang,
                                                                       i_prof            => i_prof,
                                                                       i_id_vital_sign   => c_id_vital_sign,
                                                                       i_id_unit_measure => (SELECT pk_vital_sign.get_vs_um_inst(c_id_vital_sign,
                                                                                                                                 i_prof.institution,
                                                                                                                                 i_prof.software)
                                                                                               FROM dual),
                                                                       i_id_institution  => i_prof.institution,
                                                                       i_id_software     => i_prof.software,
                                                                       i_age             => NULL)) vsum
             INNER JOIN vital_sign vs
                ON vsum.id_vital_sign = vs.id_vital_sign
             INNER JOIN unit_measure um
                ON vsum.id_unit_measure = um.id_unit_measure
            --INNER JOIN unit_mea_soft_inst umsi
            --   ON vsum.id_unit_measure = umsi.id_unit_measure
            --  AND vsum.id_institution = umsi.id_institution
            --  AND vsum.id_software = umsi.id_institution
             WHERE um.flg_available = pk_alert_constant.g_available
                  --AND vs.flg_available = pk_alert_constant.g_available
                  --AND umsi.flg_available = pk_alert_constant.g_available
               AND EXISTS (SELECT 1
                      FROM vs_soft_inst vsi
                      LEFT OUTER JOIN vital_sign_relation vsr
                        ON vsi.id_vital_sign = vsr.id_vital_sign_parent
                       AND vsr.flg_available = pk_alert_constant.g_available
                       AND vsr.relation_domain = pk_alert_constant.g_vs_rel_conc
                     WHERE vsum.id_vital_sign IN (vsi.id_vital_sign, vsr.id_vital_sign_detail)
                       AND vsum.id_unit_measure = vsi.id_unit_measure
                       AND vsum.id_institution = vsi.id_institution
                       AND vsum.id_software = vsi.id_software);
    
        l_height_um             c_unit_measure%ROWTYPE;
        l_weight_um             c_unit_measure%ROWTYPE;
        l_blood_press_s_um      c_unit_measure%ROWTYPE;
        l_blood_press_d_um      c_unit_measure%ROWTYPE;
        l_unit_meas_blood_press pk_translation.t_desc_translation;
    
    BEGIN
        g_error := 'GET DEFAULT UNIT MEASURES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_unit_meas_blood_press := pk_translation.get_translation(i_lang      => i_lang,
                                                                  i_code_mess => 'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                 g_blood_pressure_s_measure);
    
        -- get height default unit measure
        OPEN c_unit_measure(g_height_measure);
        FETCH c_unit_measure
            INTO l_height_um;
        CLOSE c_unit_measure;
    
        -- get height default unit measure
        OPEN c_unit_measure(g_weight_measure);
        FETCH c_unit_measure
            INTO l_weight_um;
        CLOSE c_unit_measure;
    
        -- get systolic blood pressure default unit measure
        OPEN c_unit_measure(g_blood_pressure_s_measure);
        FETCH c_unit_measure
            INTO l_blood_press_s_um;
        CLOSE c_unit_measure;
    
        -- get diastolic blood pressure default unit measure
        OPEN c_unit_measure(g_blood_pressure_d_measure);
        FETCH c_unit_measure
            INTO l_blood_press_d_um;
        CLOSE c_unit_measure;
    
        g_error := 'GET GUIDELINE CRITERIA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_criteria FOR
            SELECT guid_crit.criteria_type,
                   guid_crit.gender,
                   pk_sysdomain.get_domain(g_domain_gender, guid_crit.gender, i_lang) AS gender_desc,
                   guid_crit.min_age min_age,
                   guid_crit.max_age max_age,
                   
                   l_weight_um.id_unit_measure AS unit_measure_weight_id,
                   l_weight_um.val_min AS val_min_weight,
                   l_weight_um.val_max AS val_max_weight,
                   l_weight_um.format_num AS format_num_weight,
                   l_weight_um.desc_unit_measure AS desc_weight,
                   decode(guid_crit.id_weight_unit_measure,
                          l_weight_um.id_unit_measure,
                          guid_crit.min_weight,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.min_weight,
                                                                  guid_crit.id_weight_unit_measure,
                                                                  l_weight_um.id_unit_measure)) AS min_weight,
                   decode(guid_crit.id_weight_unit_measure,
                          l_weight_um.id_unit_measure,
                          guid_crit.max_weight,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.max_weight,
                                                                  guid_crit.id_weight_unit_measure,
                                                                  l_weight_um.id_unit_measure)) AS max_weight,
                   
                   guid_crit.imc_min,
                   guid_crit.imc_max,
                   
                   l_height_um.id_unit_measure AS unit_measure_height_id,
                   l_height_um.val_min AS val_min_height,
                   l_height_um.val_max AS val_max_height,
                   l_height_um.format_num AS format_num_height,
                   l_height_um.desc_unit_measure AS desc_height,
                   decode(guid_crit.id_height_unit_measure,
                          l_height_um.id_unit_measure,
                          guid_crit.min_height,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.min_height,
                                                                  guid_crit.id_height_unit_measure,
                                                                  l_height_um.id_unit_measure)) AS min_height,
                   
                   decode(guid_crit.id_height_unit_measure,
                          l_height_um.id_unit_measure,
                          guid_crit.max_height,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.max_height,
                                                                  guid_crit.id_height_unit_measure,
                                                                  l_height_um.id_unit_measure)) AS max_height,
                   
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_allergies) AS allergies_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_allergies,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_allergies,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_analysis) AS analysis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_analysis,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_analysis,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_diagnosis) AS diagnosis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_diagnosis,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_diagnosis,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_diagnosis_nurse) AS nurse_diagnosis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_diagnosis_nurse,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_nurse_diagnosis,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_exams) AS exams_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_exams,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_exams,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_drug) AS drug_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_drug,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_drug,
                   get_criteria_type_desc(i_lang, i_prof, g_guideline_other_exams) AS other_exams_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            g_guideline_other_exams,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_other_exams,
                   -- blood pressure
                   -- systolic blood pressure
                   l_blood_press_s_um.id_unit_measure AS unit_mea_blood_pressure_s_id,
                   l_blood_press_s_um.val_min AS val_min_blood_pressure_s,
                   l_blood_press_s_um.val_max AS val_max_blood_pressure_s,
                   l_blood_press_s_um.format_num AS format_num_blood_pressure_s,
                   nvl(l_blood_press_s_um.desc_unit_measure, l_unit_meas_blood_press) AS desc_blood_pressure_s,
                   decode(guid_crit.id_blood_pressure_unit_measure,
                          l_blood_press_s_um.id_unit_measure,
                          guid_crit.max_blood_pressure_s,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.max_blood_pressure_s,
                                                                  guid_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_s_um.id_unit_measure)) AS max_blood_pressure_s,
                   
                   decode(guid_crit.id_blood_pressure_unit_measure,
                          l_blood_press_s_um.id_unit_measure,
                          guid_crit.min_blood_pressure_s,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.min_blood_pressure_s,
                                                                  guid_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_s_um.id_unit_measure)) AS min_blood_pressure_s,
                   -- diastolic blood pressure
                   l_blood_press_d_um.id_unit_measure AS unit_mea_blood_pressure_d_id,
                   l_blood_press_d_um.val_min AS val_min_blood_pressure_d,
                   l_blood_press_d_um.val_max AS val_max_blood_pressure_d,
                   l_blood_press_d_um.format_num AS format_num_blood_pressure_d,
                   nvl(l_blood_press_d_um.desc_unit_measure, l_unit_meas_blood_press) AS desc_blood_pressure_d,
                   decode(guid_crit.id_blood_pressure_unit_measure,
                          l_blood_press_d_um.id_unit_measure,
                          guid_crit.max_blood_pressure_d,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.max_blood_pressure_d,
                                                                  guid_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_d_um.id_unit_measure)) AS max_blood_pressure_d,
                   
                   decode(guid_crit.id_blood_pressure_unit_measure,
                          l_blood_press_d_um.id_unit_measure,
                          guid_crit.min_blood_pressure_d,
                          pk_unit_measure.get_unit_mea_conversion(guid_crit.min_blood_pressure_d,
                                                                  guid_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_d_um.id_unit_measure)) AS min_blood_pressure_d
            
              FROM guideline_criteria guid_crit
             WHERE guid_crit.criteria_type = nvl(i_criteria_type, guid_crit.criteria_type)
               AND guid_crit.id_guideline = i_id_guideline;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CRITERIA',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_criteria);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_criteria;

    /** 
    *  Get guideline criteria
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CRITERIA         Cursor for guideline criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/20
    */
    FUNCTION get_guideline_criteria_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_criteria_all OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET GUIDELINE CRITERIA ALL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_criteria_all FOR
            SELECT guid_crit_lnk.id_guideline_criteria_link,
                   guid_crit.id_guideline,
                   guid_crit.criteria_type,
                   guid_crit_lnk.id_link_other_criteria,
                   guid_crit_lnk.id_link_other_criteria_type,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            guid_crit.id_guideline,
                                            guid_crit.criteria_type,
                                            guid_crit_lnk.id_link_other_criteria_type,
                                            NULL,
                                            g_separator2,
                                            g_not_available,
                                            guid_crit_lnk.id_link_other_criteria) AS desc_link_other_criteria,
                   pk_translation.get_translation(i_lang, guid_crit_type.code_guideline_criteria_type) AS crit_type_desc
              FROM guideline_criteria_link guid_crit_lnk,
                   guideline_criteria      guid_crit,
                   guideline_criteria_type guid_crit_type
             WHERE guid_crit.id_guideline = i_id_guideline
               AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
               AND guid_crit_lnk.id_link_other_criteria_type = guid_crit_type.id_guideline_criteria_type;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CRITERIA_ALL',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_criteria_all);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_criteria_all;

    /** 
    *  Get guideline tasks
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_TASK_TYPE                  Task type list wanted
    * @param      O_GUIDELINE_TASK             Cursor for guideline tasks
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_guideline_task_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_task_type          IN guideline_task_link.task_type%TYPE,
        o_guideline_task_all OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GUIDELINE TASK ALL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_task_all FOR
            SELECT guid_task_lnk.id_guideline_task_link,
                   guid_task_lnk.id_task_link,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid_task_lnk.id_guideline,
                                   guid_task_lnk.task_type,
                                   g_separator3,
                                   g_not_available,
                                   g_not_available,
                                   guid_task_lnk.id_task_link,
                                   guid_task_lnk.task_codification) AS desc_task,
                   guid_task_lnk.task_type,
                   pk_sysdomain.get_domain(g_domain_task_type, guid_task_lnk.task_type, i_lang) AS desc_type,
                   guid_task_lnk.task_notes,
                   guid_task_lnk.id_task_attach,
                   guid_task_lnk.task_codification
              FROM guideline_task_link guid_task_lnk
             WHERE guid_task_lnk.id_guideline = i_id_guideline
               AND guid_task_lnk.task_type = nvl(i_task_type, guid_task_lnk.task_type);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TASK_ALL',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_task_all);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_task_all;

    /** 
    *  Delete guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TASK_LINK     Guideline task link ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/11
    */
    FUNCTION delete_guideline_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline_task_link IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'DELETE GUIDELINE TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Delete guideline_adv_input_value associated to tasks to be deleted
        g_error := 'DELETE ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_adv_input_value
         WHERE flg_type = g_adv_input_type_tasks
           AND id_adv_input_link IN
               (SELECT id_guideline_task_link
                  FROM guideline_task_link
                 WHERE id_guideline_task_link IN (SELECT *
                                                    FROM TABLE(i_id_guideline_task_link)));
    
        -- Delete task links
        g_error := 'DELETE GUIDELINE TASK LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_task_link
         WHERE id_guideline_task_link IN (SELECT *
                                            FROM TABLE(i_id_guideline_task_link));
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'DELETE_GUIDELINE_TASK',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END delete_guideline_task;

    /** 
    *  Set guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_TASK_LINK               Task link ID
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_TASK_NOTES                 Task notes
    * @param      I_ID_TASK_ATTACH             Auxiliary IDs associated to the tasks
    * @param      I_TASK_CODIFICATION          Codification IDs associated to the tasks
    * @param      O_ID_GUID_TASK_LINK          New ID of each task
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_id_task_link      IN table_varchar,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_task_notes        IN table_varchar,
        i_id_task_attach    IN table_number,
        i_task_codification IN table_number,
        o_id_guid_task_link OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_guideline_task_link IS TABLE OF guideline_task_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_task_link  t_guideline_task_link;
        count_task_link          PLS_INTEGER;
        l_id_guideline_task_link guideline_task_link.id_guideline_task_link%TYPE;
    BEGIN
        g_error := 'UPDATE GUIDELINE TASK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        count_task_link := i_id_task_link.count;
    
        -- Delete old guideline_adv_input_value's associated to tasks
        g_error := 'DELETE OLD ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_adv_input_value
         WHERE flg_type = g_adv_input_type_tasks
           AND id_adv_input_link IN (SELECT id_guideline_task_link
                                       FROM guideline_task_link
                                      WHERE id_guideline = i_id_guideline
                                        AND task_type = i_task_type);
    
        -- Delete old task links
        g_error := 'DELETE OLD GUIDELINE TASK LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_task_link
         WHERE id_guideline = i_id_guideline
           AND task_type = i_task_type;
    
        g_error := 'SETUP NEW GUIDELINE TASK LINK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        o_id_guid_task_link := table_number();
    
        -- Setup new tasks
        IF (count_task_link != 0)
        THEN
            FOR i IN i_id_task_link.first .. i_id_task_link.last
            LOOP
                l_id_guideline_task_link := get_guideline_task_link_seq;
                o_id_guid_task_link.extend;
                o_id_guid_task_link(o_id_guid_task_link.last) := l_id_guideline_task_link;
                ibt_guideline_task_link(i).id_guideline_task_link := l_id_guideline_task_link;
                ibt_guideline_task_link(i).id_guideline := i_id_guideline;
                ibt_guideline_task_link(i).id_task_link := nvl(i_id_task_link(i), -i);
                ibt_guideline_task_link(i).task_type := i_task_type;
                ibt_guideline_task_link(i).task_notes := i_task_notes(i);
                ibt_guideline_task_link(i).id_task_attach := i_id_task_attach(i);
                ibt_guideline_task_link(i).task_codification := i_task_codification(i);
            END LOOP;
        
            g_error := 'INSERT NEW GUIDELINE TASK LINK';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Insert new criterias
            BEGIN
                FORALL i IN ibt_guideline_task_link.first .. ibt_guideline_task_link.last SAVE EXCEPTIONS
                    INSERT INTO guideline_task_link
                    VALUES ibt_guideline_task_link
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Error on insertion/delete/update of new guideline tasks
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_TASK',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type   
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_TASK',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_task;

    /** 
    *  Get guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_TASK             Cursor for guideline tasks
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GUIDELINE TASK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_task FOR
            SELECT get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_analysis,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_analysis,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_appoint,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_appoint,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_patient_education,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_patient_education,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_img,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_img,
                   -- get_task_id_str(i_lang, i_prof, guid.id_guideline, g_task_vacc, g_separator3, g_available, g_available) AS desc_vacc,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_enfint,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_enfint,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_drug,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_drug,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_drug_ext,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_drug_ext,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_otherexam,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_otherexam,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_spec,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_spec,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_proc,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_proc,
                   --get_task_id_str (i_lang,i_prof,guid_crit.id_guideline, g_task_rast, g_separator3, g_available, g_available) as desc_rast
                   get_task_id_str(i_lang,
                                   i_prof,
                                   guid.id_guideline,
                                   g_task_monitorization,
                                   g_separator3,
                                   g_available,
                                   g_available) AS desc_monit
              FROM guideline guid
             WHERE guid.id_guideline = i_id_guideline;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TASK',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_task);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_task;

    /** 
    *  Set guideline context
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CONTEXT_DESC               Context description      
    * @param      I_CONTEXT_TITLE              Context title
    * @param      I_CONTEXT_EBM                Context EBM
    * @param      I_CONTEXT_ADAPTATION         Context adaptation
    * @param      I_CONTEXT_TYPE_MEDIA         Context type of media
    * @param      I_CONTEXT_EDITOR             Context editor
    * @param      I_CONTEXT_EDITION_SITE       Context edition site
    * @param      I_CONTEXT_EDITION            Context edition
    * @param      I_DT_CONTEXT_EDITION         Date of context edition
    * @param      I_CONTEXT_ACCESS             Context access
    * @param      I_ID_CONTEXT_LANGUAGE        ID of context language
    * @param      I_ID_CONTEXT_SUBTITLE        Context subtitle       
    * @param      I_ID_CONTEXT_ASSOC_LANGUAGE  ID of context associated language
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_context
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline              IN guideline.id_guideline%TYPE,
        i_context_desc              IN guideline.context_desc%TYPE,
        i_context_title             IN guideline.context_title%TYPE,
        i_context_ebm               IN guideline.id_guideline_ebm%TYPE,
        i_context_adaptation        IN guideline.context_adaptation%TYPE,
        i_context_type_media        IN guideline.context_type_media%TYPE,
        i_context_editor            IN guideline.context_editor%TYPE,
        i_context_edition_site      IN guideline.context_edition_site%TYPE,
        i_context_edition           IN guideline.context_edition%TYPE,
        i_dt_context_edition        IN guideline.dt_context_edition%TYPE,
        i_context_access            IN guideline.context_access%TYPE,
        i_id_context_language       IN guideline.id_context_language%TYPE,
        i_context_subtitle          IN guideline.context_subtitle%TYPE,
        i_id_context_assoc_language IN guideline.id_context_associated_language%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'UPDATE GUIDELINE CONTEXT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Update guideline context
        UPDATE guideline
           SET context_desc                   = i_context_desc,
               context_title                  = i_context_title,
               id_guideline_ebm               = i_context_ebm,
               context_adaptation             = i_context_adaptation,
               context_type_media             = i_context_type_media,
               context_editor                 = i_context_editor,
               context_edition_site           = i_context_edition_site,
               context_edition                = i_context_edition,
               dt_context_edition             = i_dt_context_edition,
               context_access                 = i_context_access,
               id_context_language            = i_id_context_language,
               id_context_associated_language = i_id_context_assoc_language,
               context_subtitle               = i_context_subtitle
         WHERE id_guideline = i_id_guideline
           AND flg_status = g_guideline_temp;
    
        g_error := 'SETUP NEW GUIDELINE CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CONTEXT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_context;

    /** 
    *  Get guideline context
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CONTEXT          Cursor for guideline context
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_context
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        o_guideline_context OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GUIDELINE CONTEXT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_context FOR
            SELECT guid.context_desc,
                   guid.context_title,
                   guid.id_guideline_ebm,
                   pk_translation.get_translation(i_lang, guid_ebm.code_ebm) AS desc_ebm,
                   guid.context_adaptation,
                   guid.context_type_media,
                   pk_sysdomain.get_domain(g_domain_type_media, guid.context_type_media, i_lang) AS type_media_desc,
                   get_context_author_str(i_lang, i_prof, guid.id_guideline, g_separator2) AS author_desc,
                   guid.context_editor,
                   guid.context_edition_site,
                   guid.context_edition,
                   pk_date_utils.date_send(i_lang, guid.dt_context_edition, i_prof) AS dt_context_edition,
                   guid.context_access,
                   guid.id_context_language,
                   pk_sysdomain.get_domain(g_domain_language, guid.id_context_language, i_lang) AS orig_desc,
                   get_image_str(i_lang, i_prof, guid.id_guideline, g_separator) AS desc_image,
                   guid.context_subtitle,
                   guid.id_context_associated_language,
                   pk_sysdomain.get_domain(g_domain_language, guid.id_context_associated_language, i_lang) AS assoc_desc
              FROM guideline guid, ebm guid_ebm
             WHERE guid.id_guideline = i_id_guideline
               AND guid.id_guideline_ebm = guid_ebm.id_ebm(+);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CONTEXT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_context);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_context;

    /** 
    *  Set guideline context authors
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CONTEXT_AUTHOR_LAST_NAME   Context author last name
    * @param      I_CONTEXT_AUTHOR_FIRST_NAME  Context author first name
    * @param      I_CONTEXT_AUTHOR_TITLE       Context author title
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_context_author
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline              IN guideline.id_guideline%TYPE,
        i_context_author_last_name  IN table_varchar,
        i_context_author_first_name IN table_varchar,
        i_context_author_title      IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_guideline_context_author IS TABLE OF guideline_context_author%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_guideline_context_author t_guideline_context_author;
        count_author                 PLS_INTEGER;
    BEGIN
        g_error := 'SET AUTHOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        count_author := i_context_author_first_name.count;
    
        -- Delete old criterias
        g_error := 'DELETE OLD AUTHORS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        DELETE FROM guideline_context_author
         WHERE id_guideline = i_id_guideline;
    
        g_error := 'SETUP NEW AUTHORS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (count_author != 0)
        THEN
        
            FOR i IN i_context_author_first_name.first .. i_context_author_first_name.last
            LOOP
                ibt_guideline_context_author(i).id_guideline_context_author := get_guideline_ctx_author_seq;
                ibt_guideline_context_author(i).id_guideline := i_id_guideline;
                ibt_guideline_context_author(i).first_name := i_context_author_first_name(i);
                ibt_guideline_context_author(i).last_name := i_context_author_last_name(i);
                ibt_guideline_context_author(i).title := i_context_author_title(i);
            
            END LOOP;
        
            g_error := 'INSERT NEW GUIDELINE CONTEXT AUTHOR';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            BEGIN
                FORALL i IN ibt_guideline_context_author.first .. ibt_guideline_context_author.last SAVE EXCEPTIONS
                    INSERT INTO guideline_context_author
                    VALUES ibt_guideline_context_author
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on insertion/delete of new guideline context author
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CONTEXT_AUTHOR',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CONTEXT_AUTHOR',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_context_author;

    /** 
    *  Get guideline context authors
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CONTEXT_AUTHOR          Cursor for guideline context
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_context_author
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_guideline             IN guideline.id_guideline%TYPE,
        o_guideline_context_author OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GUIDELINE CONTEXT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_context_author FOR
            SELECT first_name, last_name, title
              FROM guideline_context_author guid_ctx_auth
             WHERE guid_ctx_auth.id_guideline = i_id_guideline;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CONTEXT_AUTHOR',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_context_author);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_context_author;

    /** 
    *  Sets a guideline as definitive
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline to set as final
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prev_guideline guideline.id_guideline%TYPE;
    BEGIN
        g_error := 'UPDATE GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- set guideline finished
        UPDATE guideline
           SET flg_status = g_guideline_finished
         WHERE id_guideline = i_id_guideline
           AND flg_status = g_guideline_temp
        RETURNING id_guideline_previous_version INTO l_id_prev_guideline;
    
        -- update guideline ID on guideline_frequent table
        UPDATE guideline_frequent
           SET id_guideline = i_id_guideline
         WHERE id_guideline = l_id_prev_guideline;
    
        -- update status of previous guideline  
        UPDATE guideline
           SET flg_status = g_guideline_deprecated, id_prof_cancel = i_prof.id, dt_cancel = current_timestamp
         WHERE id_guideline = l_id_prev_guideline
           AND flg_status = g_guideline_finished;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline;

    /** 
    *  Verify if a task type is available to a given software and institution
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE       Task type ID
    *
    * @return     VARCHAR2:         'Y': task type is available, 'N' task type is not available
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/28
    */
    FUNCTION check_task_type_soft_inst
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN guideline_action_category.task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_results PLS_INTEGER;
        l_market        market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
    BEGIN
    
        g_error := 'CHECK TASK TYPE SOFT INST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- verify if the task type is available for this software and institution
        SELECT COUNT(1)
          INTO l_count_results
          FROM (SELECT flg_available
                  FROM (SELECT flg_available
                          FROM guideline_item_soft_inst
                         WHERE id_institution IN (g_all_institution, i_prof.institution)
                           AND id_software IN (g_all_software, i_prof.software)
                           AND id_market IN (g_all_markets, l_market)
                           AND flg_item_type = g_guideline_item_tasks
                           AND item = i_task_type
                         ORDER BY id_market DESC, id_institution DESC, id_software DESC, flg_available)
                 WHERE rownum = 1)
         WHERE flg_available = g_available;
    
        -- check result
        IF (l_count_results = 0)
        THEN
            RETURN g_not_available;
        END IF;
    
        RETURN g_available;
    
    END check_task_type_soft_inst;

    /** 
    *  Verify if the user can make actions (has permissions) to a given task type
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE       Task type ID
    *
    * @return     VARCHAR2:         'Y': the user has permissions on this type of task, 'N' the user has no permissions on this type of task
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_task_type_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN guideline_action_category.task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_results PLS_INTEGER;
    
    BEGIN
    
        g_error := 'CHECK TASK TYPE PERMISSIONS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT COUNT(1)
          INTO l_count_results
          FROM (SELECT first_value(guid_ac.flg_available) over(PARTITION BY guid_ac.id_action ORDER BY(guid_ac.id_profile_template + guid_ac.task_type) DESC, guid_ac.flg_available) AS flg_avail
                  FROM guideline_action_category guid_ac, action act
                 WHERE guid_ac.id_category = (SELECT pc.id_category
                                                FROM prof_cat pc
                                               WHERE pc.id_professional = i_prof.id
                                                 AND pc.id_institution = i_prof.institution)
                   AND guid_ac.id_profile_template IN (SELECT ppt.id_profile_template
                                                         FROM prof_profile_template ppt
                                                        WHERE ppt.id_professional = i_prof.id
                                                          AND ppt.id_institution = i_prof.institution
                                                          AND ppt.id_software = i_prof.software
                                                       UNION ALL
                                                       SELECT g_all_profile_template AS id_profile_template
                                                         FROM dual)
                   AND guid_ac.task_type IN (i_task_type, g_all_tasks)
                   AND guid_ac.id_action = act.id_action
                   AND act.subject = g_action_guideline_tasks)
         WHERE flg_avail = g_available;
    
        -- check result
        IF (l_count_results = 0)
        THEN
            RETURN g_not_available;
        END IF;
    
        RETURN g_available;
    
    END check_task_type_permissions;

    /** 
    *  Check if it is possible to cancel a guideline process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       Guideline process ID
    *
    * @return     VARCHAR2:                    'Y': guideline can be canceled, 'N' guideline cannot be canceled
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_cancel_guideline_proc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_val_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'CHECK CANCEL GUIDELINE PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- verify if this guideline has tasks that cannot be canceled by this user
        SELECT COUNT(1)
          INTO l_ret_val_count
          FROM guideline_process_task gpt
         WHERE gpt.id_guideline_process = i_id_guideline_process
           AND gpt.flg_status_last NOT IN (g_process_pending, g_process_recommended)
           AND (check_task_type_permissions(i_lang, i_prof, gpt.task_type) = g_not_available OR
               check_task_type_soft_inst(i_lang, i_prof, gpt.task_type) = g_not_available);
    
        -- check result
        IF (l_ret_val_count = 0)
        THEN
            RETURN g_available;
        END IF;
    
        RETURN g_not_available;
    
    END check_cancel_guideline_proc;

    /** 
    *  Cancel guideline / mark as deleted
    *
    * @param      I_LANG              Preferred language ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.
    * @param      O_ERROR             error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION cancel_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_guideline(in_id_guideline NUMBER) IS
            SELECT id_guideline, flg_status
              FROM guideline
             WHERE id_guideline = in_id_guideline;
    
        l_guideline c_guideline%ROWTYPE;
        error_undefined_status EXCEPTION;
    BEGIN
        g_error := 'FETCH GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Checks if guideline is temp or definitive.
        OPEN c_guideline(i_id_guideline);
    
        FETCH c_guideline
            INTO l_guideline;
    
        CLOSE c_guideline;
    
        g_error := 'VERIFY STATE OF GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (l_guideline.flg_status = g_guideline_temp)
        THEN
        
            g_error := 'DELETE ADVANCED INPUT CRITERIAS DATA';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_adv_input_value
             WHERE flg_type = g_adv_input_type_criterias
               AND id_adv_input_link IN
                   (SELECT guid_crit_link.id_guideline_criteria_link
                      FROM guideline_criteria_link guid_crit_link, guideline_criteria guid_crit
                     WHERE guid_crit.id_guideline = i_id_guideline
                       AND guid_crit_link.id_guideline_criteria = guid_crit.id_guideline_criteria);
        
            g_error := 'DELETE CRITERIA LINK';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_criteria_link
             WHERE id_guideline_criteria_link IN
                   (SELECT guid_crit_link.id_guideline_criteria_link
                      FROM guideline_criteria_link guid_crit_link, guideline_criteria guid_crit
                     WHERE guid_crit.id_guideline = i_id_guideline
                       AND guid_crit_link.id_guideline_criteria = guid_crit.id_guideline_criteria);
        
            g_error := 'DELETE CRITERIA';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_criteria
             WHERE id_guideline = i_id_guideline;
        
            g_error := 'DELETE ADVANCED INPUT TASKS DATA';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_adv_input_value
             WHERE flg_type = g_adv_input_type_tasks
               AND id_adv_input_link IN (SELECT id_guideline_task_link
                                           FROM guideline_task_link
                                          WHERE id_guideline = i_id_guideline);
        
            g_error := 'DELETE TASK LINK';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_task_link
             WHERE id_guideline = i_id_guideline;
        
            g_error := 'DELETE LINK';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_link
             WHERE id_guideline = i_id_guideline;
        
            g_error := 'DELETE CONTEXT IMAGE';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_context_image
             WHERE id_guideline = i_id_guideline;
        
            g_error := 'DELETE CONTEXT AUTHOR';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline_context_author
             WHERE id_guideline = i_id_guideline;
        
            g_error := 'DELETE TEMP GUIDELINE';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            DELETE FROM guideline
             WHERE id_guideline = i_id_guideline
               AND flg_status = g_guideline_temp;
        
        ELSIF (l_guideline.flg_status = g_guideline_finished)
        THEN
            g_error := 'DELETE CLOSED GUIDELINE';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            UPDATE guideline
               SET flg_status = g_guideline_deleted, id_prof_cancel = i_prof.id, dt_cancel = current_timestamp
             WHERE id_guideline = i_id_guideline
               AND flg_status = g_guideline_finished;
        ELSE
            RAISE error_undefined_status;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on delete closed guideline
        WHEN error_undefined_status THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state for FLG_STATUS',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type   
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END cancel_guideline;

    /** 
    *  Get multichoice for guideline types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_TYPE             Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_type FOR
            SELECT id_guideline_type,
                   rank,
                   desc_guideline_type,
                   decode(id_guideline_type,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT guid_typ.id_guideline_type,
                           2 rank,
                           pk_translation.get_translation(i_lang, guid_typ.code_guideline_type) desc_guideline_type,
                           decode(guid_type_link.id_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM guideline_type guid_typ,
                           (SELECT id_link
                              FROM guideline_link guid_lnk_typ, guideline guid
                             WHERE guid.id_guideline(+) = i_id_guideline
                               AND guid_lnk_typ.id_guideline = guid.id_guideline
                               AND guid_lnk_typ.link_type(+) = g_guide_link_type) guid_type_link
                     WHERE guid_typ.flg_available = g_available
                       AND guid_typ.id_guideline_type = guid_type_link.id_link(+)
                    UNION ALL
                    SELECT -1 id_guideline_type,
                           1 rank,
                           pk_message.get_message(i_lang, g_message_all) desc_guideline_type,
                           g_not_selected flg_select
                      FROM dual)
             ORDER BY rank, desc_guideline_type;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TYPE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_type);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_type_list;

    /** 
    *  Get multichoice for environment
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_ENVIRONMENT      Cursor with all environment availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_environment OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_environment FOR
            SELECT id_dept,
                   rank,
                   desc_dep,
                   decode(id_dept,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT DISTINCT d.id_dept,
                                    2 rank,
                                    pk_translation.get_translation(i_lang, d.code_dept) desc_dep,
                                    decode(guid_lnk.id_guideline_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM dept               d,
                           department         dep,
                           dep_clin_serv      dcs,
                           prof_dep_clin_serv pdcs,
                           software_dept      sd,
                           guideline_link     guid_lnk
                     WHERE d.id_institution = i_prof.institution
                       AND dep.id_dept = d.id_dept
                       AND dcs.id_department = dep.id_department
                       AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                       AND sd.id_dept = d.id_dept
                       AND d.flg_available = g_available
                       AND dep.flg_available = g_available
                       AND dcs.flg_available = g_available
                       AND sd.id_software IN (pk_alert_constant.g_soft_outpatient,
                                              pk_alert_constant.g_soft_oris,
                                              pk_alert_constant.g_soft_primary_care,
                                              pk_alert_constant.g_soft_edis,
                                              pk_alert_constant.g_soft_inpatient,
                                              pk_alert_constant.g_soft_private_practice,
                                              pk_alert_constant.g_soft_ubu,
                                              pk_alert_constant.g_soft_nutritionist,
                                              pk_alert_constant.g_soft_home_care)
                       AND guid_lnk.id_link(+) = d.id_dept
                       AND guid_lnk.id_guideline(+) = i_id_guideline
                       AND guid_lnk.link_type(+) = g_guide_link_envi
                    UNION ALL
                    SELECT -1 id_dept,
                           1 rank,
                           pk_message.get_message(i_lang, g_message_all) desc_dep,
                           g_not_selected flg_select
                      FROM dual)
             ORDER BY rank, desc_dep;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_ENVIRONMENT_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_environment);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_environment_list;

    /**
    *  Get multichoice for specialty
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE              ID of guideline.
    * @param      O_GUIDELINE_SPECIALTY       Cursor with all specialty available
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/02/23
    */
    FUNCTION get_guideline_specialty_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline        IN guideline.id_guideline%TYPE,
        o_guideline_specialty OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_specialty FOR
            SELECT id_speciality,
                   rank,
                   desc_speciality,
                   decode(id_speciality,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT id_speciality, rank, desc_speciality, flg_select
                      FROM (SELECT d.id_speciality,
                                   2 rank,
                                   pk_translation.get_translation(i_lang, d.code_speciality) desc_speciality,
                                   decode(guid_lnk.id_guideline_link, NULL, g_not_selected, g_selected) AS flg_select
                              FROM speciality d, guideline_link guid_lnk
                             WHERE d.flg_available = g_available
                               AND guid_lnk.id_link(+) = d.id_speciality
                               AND guid_lnk.id_guideline(+) = i_id_guideline
                               AND guid_lnk.link_type(+) = g_guide_link_spec
                               AND d.id_speciality IN
                                   (SELECT nvl(prof.id_speciality, -1)
                                      FROM prof_soft_inst psi, professional prof
                                     WHERE psi.id_professional = prof.id_professional
                                       AND psi.id_institution = i_prof.institution
                                       AND psi.id_software IN (pk_alert_constant.g_soft_outpatient,
                                                               pk_alert_constant.g_soft_oris,
                                                               pk_alert_constant.g_soft_edis,
                                                               pk_alert_constant.g_soft_inpatient,
                                                               pk_alert_constant.g_soft_private_practice,
                                                               pk_alert_constant.g_soft_ubu,
                                                               pk_alert_constant.g_soft_nutritionist,
                                                               pk_alert_constant.g_soft_home_care))
                               AND i_prof.software NOT IN
                                   (pk_alert_constant.g_soft_primary_care, pk_alert_constant.g_soft_home_care)
                            UNION ALL
                            SELECT DISTINCT (cs.id_clinical_service) AS id_speciality,
                                            2 rank,
                                            pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_speciality,
                                            decode(guid_lnk.id_guideline_link, NULL, g_not_selected, g_selected) AS flg_select
                              FROM dep_clin_serv    dcs,
                                   department       dep,
                                   dept,
                                   clinical_service cs,
                                   software_dept    soft_dep,
                                   guideline_link   guid_lnk
                             WHERE dep.id_department = dcs.id_department
                               AND dept.id_dept = dep.id_dept
                               AND dep.id_institution = i_prof.institution
                               AND soft_dep.id_dept = dept.id_dept
                               AND soft_dep.id_software IN
                                   (pk_alert_constant.g_soft_primary_care, pk_alert_constant.g_soft_home_care)
                               AND cs.id_clinical_service = dcs.id_clinical_service
                               AND dcs.flg_available = g_available
                               AND dep.flg_available = g_available
                               AND dept.flg_available = g_available
                               AND cs.flg_available = g_available
                               AND guid_lnk.id_link(+) = cs.id_clinical_service
                               AND guid_lnk.id_guideline(+) = i_id_guideline
                               AND guid_lnk.link_type(+) = g_guide_link_spec
                               AND i_prof.software IN
                                   (pk_alert_constant.g_soft_primary_care, pk_alert_constant.g_soft_home_care)
                             ORDER BY desc_speciality)
                    UNION ALL
                    SELECT -1 id_speciality,
                           1 rank,
                           pk_message.get_message(i_lang, g_message_all) desc_speciality,
                           'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_speciality;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_SPECIALTY_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_specialty);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_specialty_list;

    /** 
    *  Get multichoice for professional
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_PROFESSIONAL     Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_professional FOR
            SELECT id_category,
                   rank,
                   desc_category,
                   decode(id_category,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT d.id_category,
                           2 rank,
                           pk_translation.get_translation(i_lang, d.code_category) desc_category,
                           decode(guid_lnk.id_guideline_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM category d, guideline_link guid_lnk
                     WHERE d.flg_available = g_available
                       AND d.flg_prof = g_available
                       AND d.flg_clinical = g_available
                       AND d.flg_type IN (pk_alert_constant.g_cat_type_doc,
                                          pk_alert_constant.g_cat_type_nurse,
                                          pk_alert_constant.g_cat_type_nutritionist)
                       AND guid_lnk.id_link(+) = d.id_category
                       AND guid_lnk.id_guideline(+) = i_id_guideline
                       AND guid_lnk.link_type(+) = g_guide_link_prof
                    UNION ALL
                    SELECT -1 id_category,
                           1 rank,
                           pk_message.get_message(i_lang, g_message_all) desc_category,
                           'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_category;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_prof_list;

    /** 
    *  Get multichoice for professionals that will be able to edit Guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_PROFESSIONAL     Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/02/26
    */
    FUNCTION get_guideline_edit_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_professional FOR
            SELECT id_category,
                   rank,
                   desc_category,
                   decode(id_category,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT d.id_category,
                           2 rank,
                           pk_translation.get_translation(i_lang, d.code_category) desc_category,
                           decode(guid_lnk.id_guideline_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM category d, guideline_link guid_lnk
                     WHERE d.flg_available = g_available
                       AND d.flg_prof = g_available
                       AND d.flg_clinical = g_available
                       AND d.flg_type IN (pk_alert_constant.g_cat_type_doc,
                                          pk_alert_constant.g_cat_type_nurse,
                                          pk_alert_constant.g_cat_type_nutritionist)
                       AND guid_lnk.id_link(+) = d.id_category
                       AND guid_lnk.id_guideline(+) = i_id_guideline
                       AND guid_lnk.link_type(+) = g_guide_link_edit_prof
                    UNION ALL
                    SELECT -1 id_category,
                           1 rank,
                           pk_message.get_message(i_lang, g_message_all) desc_category,
                           'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_category;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_EDIT_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_edit_prof_list;

    /** 
    *  Get multichoice for types of Guideline recommendation
    *
    * @param      I_LANG                  Preferred language ID for this professional
    * @param      I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_REC_MODE    Cursor with types of recommendation
    * @param      O_ERROR                 Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/02/26
    */
    FUNCTION get_guideline_type_rec_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_guideline_type_rec OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_type_rec FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_flg_type_rec
               AND flg_available = g_available
               AND domain_owner = pk_sysdomain.k_default_schema
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TYPE_REC_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_type_rec);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_type_rec_list;

    /** 
    *  Get multichoice for EBM
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_EBM              Cursor with all EBM values availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_ebm_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_guideline_ebm OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_ebm FOR
            SELECT guid_ebm.id_ebm,
                   2 rank,
                   pk_translation.get_translation(i_lang, guid_ebm.code_ebm) desc_ebm,
                   decode(guid.id_guideline_ebm, NULL, g_not_selected, g_selected) AS flg_select
              FROM guideline guid, ebm guid_ebm
             WHERE guid.id_guideline(+) = i_id_guideline
               AND guid.id_guideline_ebm(+) = guid_ebm.id_ebm
             ORDER BY rank, desc_ebm;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_EBM_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_ebm);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_ebm_list;

    /** 
    *  Get multichoice for Gender
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_CRITERIA_TYPE              Criteria Type : I- Incusion E - Exclusion
    * @param      O_GUIDELINE_GENDER           Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_gender_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_criteria_type    IN guideline_criteria.criteria_type%TYPE,
        o_guideline_gender OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_gender FOR
            SELECT val, desc_val
              FROM (SELECT val, desc_val, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = g_domain_gender
                    UNION ALL
                    SELECT NULL, desc_val, -1 AS rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = g_domain_inc_gen
                       AND i_criteria_type = g_criteria_type_inc
                    UNION ALL
                    SELECT NULL, desc_val, -1 AS rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = g_domain_exc_gen
                       AND i_criteria_type = g_criteria_type_exc)
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GENDER_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_gender);
            -- return failure of function
            RETURN FALSE;
        
    END get_gender_list;

    /** 
    *  Get multichoice for type of media
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_TM               Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_type_media_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_guideline_tm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_tm FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_type_media
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_available
             ORDER BY desc_val, rank;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_TYPE_MEDIA_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_tm);
            -- return failure of function
            RETURN FALSE;
        
    END get_type_media_list;

    /** 
    *  Get multichoice for guideline edit options
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_OPTIONS                    Cursor with all options
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/06/04
    */
    FUNCTION get_guideline_edit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_options FOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_options FOR
            SELECT g_edit_guideline_option data, pk_message.get_message(i_lang, g_message_edit_guideline) label
              FROM dual
            UNION ALL
            SELECT g_duplicate_guideline_option data,
                   pk_message.get_message(i_lang, g_message_duplicate_guideline) label
              FROM dual
            UNION ALL
            SELECT g_create_guideline_option data, pk_message.get_message(i_lang, g_message_create_guideline) label
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_EDIT_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_options);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_edit_list;

    /** 
    *  Get multichoice for languages
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_LANGUAGES                  Cursor with all languages
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_language_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_language language.id_language%TYPE := i_lang;
    BEGIN
    
        g_error := 'OPEN o_languages FOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_languages FOR
            SELECT to_number(val) data,
                   desc_val label,
                   decode(val, l_default_language, 'Y', 'N') flg_select,
                   9 order_field
              FROM sys_domain
             WHERE code_domain = g_domain_language
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_available
               AND id_language = i_lang
             ORDER BY label, rank;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_LANGUAGE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_languages);
            -- return failure of function
            RETURN FALSE;
        
    END get_language_list;

    /** 
    *  Get title list for professionals
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      O_TITLE                      Title cursor
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        IF NOT pk_backoffice.get_prof_title_list(i_lang, o_title, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PROF_TITLE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_title);
            -- return failure of function
            RETURN FALSE;
        
    END get_prof_title_list;

    /** 
    *  Get frequency list for guideline tasks
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_FREQ     Frequencies cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/19
    */
    FUNCTION get_guideline_task_freq_list
    (
        i_lang  IN language.id_language%TYPE,
        o_freq  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_freq FOR
            SELECT val AS data, desc_val AS label
              FROM sys_domain
             WHERE code_domain = g_domain_adv_input_freq
               AND id_language = i_lang
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_available
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TASK_FREQ_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_freq);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_task_freq_list;

    /** 
    *  Get status list for allergy criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_allergy_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_status FOR
            SELECT *
              FROM (SELECT val AS data, desc_val AS label, 2 rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_allergy_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND val NOT IN (pk_problems.g_pat_probl_cancel) -- CANCELADO NÃO DEVEM APARECER
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data, pk_message.get_message(i_lang, g_message_any) AS label, 1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_ALLERGY_STATUS_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_status);
            -- return failure of function
            RETURN FALSE;
        
    END get_allergy_status_list;

    /** 
    *  Get reactions list for allergy criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_REACTS   Reactions cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_allergy_react_list
    (
        i_lang   IN language.id_language%TYPE,
        o_reacts OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_reacts FOR
            SELECT *
              FROM (SELECT val AS data, desc_val AS label, 2 rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND code_domain = g_domain_allergy_type
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data, pk_message.get_message(i_lang, g_message_any) AS label, 1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_ALLERGY_REACT_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_reacts);
            -- return failure of function
            RETURN FALSE;
        
    END get_allergy_react_list;

    /** 
    *  Get status list for diagnose criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_diagnose_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_status FOR
            SELECT *
              FROM (SELECT val AS data, desc_val AS label, 2 rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND val NOT IN (g_pat_probl_not_capable, pk_problems.g_pat_probl_cancel) -- INCAPACITANTE E CANCELADO NÃO DEVEM APARECER
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data, pk_message.get_message(i_lang, g_message_any) AS label, 1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_DIAGNOSE_STATUS_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_status);
            -- return failure of function
            RETURN FALSE;
        
    END get_diagnose_status_list;

    /** 
    *  Get natures list for diagnose criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_NATURES  Natures cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_diagnose_nature_list
    (
        i_lang    IN language.id_language%TYPE,
        o_natures OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_natures FOR
            SELECT *
              FROM (SELECT val AS data, desc_val AS label, 2 rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_nature
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data, pk_message.get_message(i_lang, g_message_any) AS label, 1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_DIAGNOSE_NATURE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_natures);
            -- return failure of function
            RETURN FALSE;
        
    END get_diagnose_nature_list;

    /** 
    *  Get status list for nurse diagnosis criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_nurse_diag_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_status FOR
            SELECT *
              FROM (SELECT val AS data, desc_val AS label, 2 rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_nurse_diag_status
                       AND id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND val IN (g_nurse_active, g_nurse_solved) -- DEVEM APARECER APENAS OS ESTADOS ACTIVO e RESOLVIDO
                       AND flg_available = g_available
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data, pk_message.get_message(i_lang, g_message_any) AS label, 1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_NURSE_DIAG_STATUS_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_status);
            -- return failure of function
            RETURN FALSE;
        
    END get_nurse_diag_status_list;

    /** 
    *  Checks difference between number of allergies and criteria allergy choosen
    *
    * @param      i_prof                      professional structure id
    * @param      i_id_protocol               protocol id
    * @param      i_id_allergy                allergy id
    * @param      i_market                    allergies default market  
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_allergies
    (
        i_prof         profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_id_allergy   IN allergy.id_allergy%TYPE,
        i_market       PLS_INTEGER
    ) RETURN NUMBER IS
        l_count_ale  NUMBER;
        l_count_crit NUMBER;
        l_result     NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(guid_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_ale, l_count_crit
          FROM allergy ale
          JOIN allergy_inst_soft_market aism
            ON ale.id_allergy = aism.id_allergy
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                      WHERE guid.id_guideline = i_id_guideline
                        AND guid_crit.id_guideline = guid.id_guideline
                        AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                        AND guid_crit_lnk.id_link_other_criteria_type = g_guideline_allergies) guid_ids
            ON ale.id_allergy = safe_to_number(guid_ids.id_link_other_criteria)
         WHERE ale.flg_available = g_ale_available
           AND ale.flg_active = g_allergy_active
              --AND ale.id_allergy_parent = i_id_allergy
           AND aism.id_allergy_parent = i_id_allergy
           AND aism.id_market IN (pk_allergy.g_default_market, i_market)
           AND aism.id_institution IN (i_prof.institution, g_all_institution);
    
        IF (l_count_crit = 0)
        THEN
            l_result := g_criteria_clear;
        ELSIF (l_count_ale - l_count_crit = 0)
        THEN
            l_result := g_criteria_group_all;
        ELSIF (l_count_ale - l_count_crit > 0 AND l_count_crit != 0)
        THEN
            l_result := g_criteria_group_some;
        END IF;
    
        RETURN nvl(l_result, 0);
    
    END get_count_allergies;

    /** 
    *  Checks difference between number of nurse diagnosis and criteria nurse diagnosis choosen
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_NURSE_DIAG              Nurse diagnosis ID
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_nurse_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  guideline.id_guideline%TYPE,
        i_id_nurse_diag NUMBER
    ) RETURN NUMBER IS
        l_count_nurse NUMBER;
        l_count_crit  NUMBER;
        l_result      NUMBER;
    BEGIN
    
        IF (i_id_nurse_diag < 0)
        THEN
            SELECT COUNT(1), SUM(decode(guid_ids.id_link_other_criteria, NULL, 0, 1))
              INTO l_count_nurse, l_count_crit
              FROM (SELECT DISTINCT ic.id_composition AS val,
                                    pk_icnp.desc_composition(i_lang, ic.id_composition) desc_val,
                                    ic.flg_repeat,
                                    0 rank
                      FROM icnp_composition ic, icnp_compo_dcs icd
                     WHERE icd.id_composition = ic.id_composition
                       AND ic.flg_type = g_composition_diag_type
                       AND icd.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                      FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                                     WHERE d.id_department = dcs.id_department
                                                       AND d.id_institution = i_prof.institution
                                                       AND dp.id_dept = d.id_dept
                                                       AND sd.id_dept = dp.id_dept
                                                       AND sd.id_software = i_prof.software)) diag_specific
              LEFT JOIN (SELECT id_link_other_criteria
                           FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                          WHERE guid.id_guideline = i_id_guideline
                            AND guid_crit.id_guideline = guid.id_guideline
                            AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                            AND guid_crit_lnk.id_link_other_criteria_type = g_guideline_diagnosis_nurse) guid_ids
                ON diag_specific.val = safe_to_number(guid_ids.id_link_other_criteria);
        
        ELSE
        
            SELECT COUNT(1), SUM(decode(guid_ids.id_link_other_criteria, NULL, 0, 1))
              INTO l_count_nurse, l_count_crit
              FROM (SELECT DISTINCT ic.id_composition val,
                                    pk_icnp.desc_composition(i_lang, ic.id_composition) desc_val,
                                    ic.flg_repeat,
                                    0 rank
                      FROM icnp_composition ic, icnp_compo_dcs icd, dep_clin_serv dcs, department d, software_dept sd
                     WHERE icd.id_composition = ic.id_composition
                       AND ic.flg_type = g_composition_diag_type
                       AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                       AND dcs.id_clinical_service = i_id_nurse_diag
                       AND d.id_department = dcs.id_department
                       AND d.id_institution = i_prof.institution
                       AND sd.id_dept = d.id_dept
                       AND sd.id_software = i_prof.software
                       AND ic.flg_available = g_available) diag_specific
              LEFT JOIN (SELECT id_link_other_criteria
                           FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                          WHERE guid.id_guideline = i_id_guideline
                            AND guid_crit.id_guideline = guid.id_guideline
                            AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                            AND guid_crit_lnk.id_link_other_criteria_type = g_guideline_diagnosis_nurse) guid_ids
                ON diag_specific.val = safe_to_number(guid_ids.id_link_other_criteria);
        
        END IF;
    
        IF (l_count_crit = 0)
        THEN
            l_result := g_criteria_clear;
        ELSIF (l_count_nurse - l_count_crit = 0)
        THEN
            l_result := g_criteria_group_all;
        ELSIF (l_count_nurse - l_count_crit > 0 AND l_count_crit != 0)
        THEN
            l_result := g_criteria_group_some;
        END IF;
    
        RETURN nvl(l_result, 0);
    
    END get_count_nurse_diag;

    /** 
    *  Checks difference between number of diagnoses and criteria diagnoses choosen
    *
    * @param      I_ID_GUIDELINE   Guideline ID
    * @param      I_FLG_TYPE       Diagnoses type
    *
    * @return     NUMBER
    * @author     TS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_count_diagnoses
    (
        i_id_guideline guideline.id_guideline%TYPE,
        i_diags_type   diagnosis.flg_type%TYPE
    ) RETURN NUMBER IS
        l_count_diags NUMBER;
        l_count_crit  NUMBER;
        l_result      NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(guid_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_diags, l_count_crit
          FROM (SELECT DISTINCT dc.id_diagnosis
                  FROM diagnosis_content dc
                 WHERE dc.flg_select = g_diag_select
                   AND dc.flg_type = i_diags_type) diags
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                      WHERE guid.id_guideline = i_id_guideline
                        AND guid_crit.id_guideline = guid.id_guideline
                        AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                        AND guid_crit_lnk.id_link_other_criteria_type = g_guideline_allergies) guid_ids
            ON diags.id_diagnosis = safe_to_number(guid_ids.id_link_other_criteria);
    
        IF (l_count_crit = 0)
        THEN
            l_result := g_criteria_clear;
        ELSIF (l_count_diags - l_count_crit = 0)
        THEN
            l_result := g_criteria_group_all;
        ELSIF (l_count_diags - l_count_crit > 0 AND l_count_crit != 0)
        THEN
            l_result := g_criteria_group_some;
        END IF;
    
        RETURN nvl(l_result, 0);
    END get_count_diagnoses;

    /** 
    *  Checks difference between number of analysis and criteria 
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_SAMPLE_TYPE             Sample type ID
    * @param      I_ID_EXAM_CAT                Exam category
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_analysis_sample
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   guideline.id_guideline%TYPE,
        i_id_sample_type sample_type.id_sample_type%TYPE,
        i_id_exam_cat    exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER IS
        l_count_sample NUMBER;
        l_count_crit   NUMBER;
        l_result       NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(guid_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_sample, l_count_crit
          FROM (SELECT anl.id_analysis AS val
                  FROM analysis_instit_soft adcs, analysis anl, sample_type st, exam_cat ec
                 WHERE st.id_sample_type = nvl(i_id_sample_type, st.id_sample_type)
                   AND anl.id_sample_type = st.id_sample_type
                   AND anl.flg_available = g_analysis_available
                   AND ec.id_exam_cat = nvl(i_id_exam_cat, ec.id_exam_cat)
                   AND ec.id_exam_cat = adcs.id_exam_cat
                   AND adcs.id_analysis = anl.id_analysis
                   AND adcs.id_institution = i_prof.institution
                   AND adcs.id_software = i_prof.software) analysis
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                      WHERE guid.id_guideline = i_id_guideline
                        AND guid_crit.id_guideline = guid.id_guideline
                        AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                        AND guid_crit_lnk.id_link_other_criteria_type = g_guideline_analysis) guid_ids
            ON analysis.val = safe_to_number(guid_ids.id_link_other_criteria);
    
        IF (l_count_crit = 0)
        THEN
            l_result := g_criteria_clear;
        ELSIF (l_count_sample - l_count_crit = 0)
        THEN
            l_result := g_criteria_group_all;
        ELSIF (l_count_sample - l_count_crit > 0 AND l_count_crit != 0)
        THEN
            l_result := g_criteria_group_some;
        END IF;
    
        RETURN nvl(l_result, 0);
    
    END get_count_analysis_sample;

    /** 
    *  Search specific criterias
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CRITERIA_TYPE              Criteria type - 'I'nclusion / 'E'xclusion
    * @param      I_GUIDELINE_CRITERIA_SEARCH  Criteria search topics
    * @param      I_VALUE_SEARCH               Values to search
    * @param      o_flg_show                   shows warning message: Y - yes, N - No
    * @param      o_msg                        message text
    * @param      o_msg_title                  message title
    * @param      o_button                     buttons to show: N-No, R-Read, C-Confirmed
    * @param      O_CRITERIA_SEARCH            Cursor with all elements of specific criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.3
    * @since      2007/02/06
    */
    FUNCTION get_criteria_search
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline              IN guideline.id_guideline%TYPE,
        i_criteria_type             IN guideline_criteria.criteria_type%TYPE, -- Inclusion / exclusion
        i_guideline_criteria_search IN table_varchar,
        i_value_search              IN table_varchar,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_criteria_search           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit                   sys_config.value%TYPE;
        l_diag_rowids             table_varchar;
        l_diag_selected_rowids    table_varchar := table_varchar();
        l_last_level              PLS_INTEGER;
        l_value_search            VARCHAR2(50);
        l_guideline_criteria_type NUMBER;
    
        l_rcrit t_rec_criteria_sel_diag := t_rec_criteria_sel_diag(NULL, NULL);
        l_tcrit t_tbl_criteria_sel_diag := t_tbl_criteria_sel_diag();
    
        l_market         VARCHAR2(50);
        l_default_market PLS_INTEGER;
    
        o_allergies            pk_types.cursor_type;
        l_select_level         table_varchar;
        l_rank                 table_number;
        l_desc_allergy         table_varchar;
        l_desc_allergy_order   table_varchar;
        l_id_allergy_parent    table_number;
        l_id_allergy           table_number;
        l_flg_adverse_reaction table_varchar;
        o_select_level         VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
    
        l_allergies_limit_message sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'GET CURSOR CRITERIA SEARCH';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_limit    := pk_sysconfig.get_config(g_config_max_diag_rownum, i_prof);
        o_flg_show := pk_alert_constant.g_no;
    
        -- get number of levels
        l_last_level := i_guideline_criteria_search.count;
    
        -- get guideline criteria type
        l_guideline_criteria_type := i_guideline_criteria_search(1);
    
        -- get last value search
        l_value_search := i_value_search(l_last_level);
    
        -- diagnoses
        IF (l_guideline_criteria_type = g_guideline_diagnosis)
        THEN
            IF (l_last_level = 1)
            THEN
                -- Type of diagnoses
                OPEN o_criteria_search FOR
                    SELECT /*+opt_estimate(table,t,scale_rows=1))*/
                     t.desc_terminology desc_val,
                     t.flg_terminology val,
                     l_guideline_criteria_type AS val_type,
                     get_count_diagnoses(i_id_guideline, t.flg_terminology) AS flg_select_stat,
                     g_not_available AS flg_select
                      FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                         i_prof          => i_prof,
                                                                         i_tbl_task_type => table_number(pk_alert_constant.g_task_diagnosis,
                                                                                                         pk_alert_constant.g_task_problems))) t
                     WHERE ((translate(upper(t.desc_terminology),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                     ORDER BY rank;
            
            ELSE
            
                -- extract rowids until limit is reached
                SELECT diags.rowid_d
                  BULK COLLECT
                  INTO l_diag_rowids
                  FROM (SELECT diag.rowid_d,
                               pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_diagnosis => diag.id_diagnosis,
                                                          i_code         => diag.code_icd,
                                                          i_flg_other    => diag.flg_other,
                                                          i_flg_std_diag => pk_alert_constant.g_yes) desc_diagnosis,
                               diag.code_icd
                          FROM (SELECT to_char(d.id_diagnosis) rowid_d,
                                       d.id_diagnosis,
                                       d.code_icd,
                                       d.flg_other,
                                       d.id_diagnosis_parent
                                  FROM diagnosis d
                                 WHERE d.flg_type = i_guideline_criteria_search(2)
                                   AND rownum > 0) diag
                         WHERE nvl(diag.id_diagnosis_parent, -99) =
                               nvl(decode(l_last_level, 2, NULL, i_guideline_criteria_search(l_last_level)), -99)) diags
                ----------------------------------------------------------------------
                 WHERE ((translate(upper(desc_diagnosis || code_icd),
                                   'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                   'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' ||
                       translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                       l_value_search IS NOT NULL) OR l_value_search IS NULL)
                   AND rownum <= to_number(l_limit) + 1;
            
                -- extract rowids and criteria types for the selected diagnoses   
                FOR rec IN (SELECT diag.rowid_d AS row_id, crosslink.criteria_type
                              FROM (SELECT to_char(d.id_diagnosis) rowid_d, d.id_diagnosis, d.id_diagnosis_parent
                                      FROM diagnosis d
                                     WHERE d.flg_type = i_guideline_criteria_search(2)
                                       AND rownum > 0) diag
                              JOIN (SELECT guid_crit_lnk.id_link_other_criteria, guid_crit.criteria_type
                                     FROM guideline               guid,
                                          guideline_criteria      guid_crit,
                                          guideline_criteria_link guid_crit_lnk
                                    WHERE guid.id_guideline = i_id_guideline
                                      AND guid_crit.id_guideline = guid.id_guideline
                                      AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                      AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                                ON diag.id_diagnosis = safe_to_number(crosslink.id_link_other_criteria)
                             WHERE nvl(diag.id_diagnosis_parent, -99) =
                                   nvl(decode(l_last_level, 2, NULL, i_guideline_criteria_search(l_last_level)), -99))
                LOOP
                    l_diag_selected_rowids.extend;
                    l_diag_selected_rowids(l_diag_selected_rowids.count) := rec.row_id;
                
                    l_rcrit.diag_rowid    := rec.row_id;
                    l_rcrit.criteria_type := rec.criteria_type;
                    l_tcrit.extend;
                    l_tcrit(l_tcrit.count) := l_rcrit;
                END LOOP;
            
                -- join both collections to extract the number of records
                IF l_value_search IS NULL
                THEN
                    l_diag_rowids := l_diag_selected_rowids MULTISET UNION DISTINCT l_diag_rowids;
                END IF;
            
                -- check limit and warn user if the limit was reached
                IF l_diag_rowids.count > l_limit
                THEN
                    o_flg_show  := pk_alert_constant.g_yes; -- show warning pop-up
                    o_msg       := pk_search.get_overlimit_message(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_flg_has_action => pk_alert_constant.g_no,
                                                                   i_limit          => l_limit);
                    o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013'); -- "warning" title
                    o_button    := 'R'; -- read
                END IF;
            
                OPEN o_criteria_search FOR
                    SELECT *
                      FROM (SELECT desc_val, val, val_type, flg_select_stat, flg_select
                              FROM (SELECT /*+opt_estimate(table crosslink rows=1)*/
                                     diags.desc_diagnosis AS desc_val,
                                     diags.id_diagnosis AS val,
                                     l_guideline_criteria_type AS val_type,
                                     decode(crosslink.diag_rowid,
                                            NULL,
                                            g_criteria_clear,
                                            decode(crosslink.criteria_type,
                                                   i_criteria_type,
                                                   g_criteria_already_set,
                                                   g_criteria_already_crossset)) AS flg_select_stat,
                                     diags.flg_select AS flg_select,
                                     nvl2(crosslink.diag_rowid, 0, 1) AS rank
                                      FROM (SELECT /*+opt_estimate(table diag_rowids rows=1)*/
                                             pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_id_diagnosis => diag.id_diagnosis,
                                                                        i_code         => diag.code_icd,
                                                                        i_flg_other    => diag.flg_other,
                                                                        i_flg_std_diag => pk_alert_constant.g_yes) desc_diagnosis,
                                             diag.id_diagnosis,
                                             diag.code_icd,
                                             diag.flg_select,
                                             diag.rowid_d AS row_id
                                              FROM (SELECT DISTINCT to_char(d.id_diagnosis) rowid_d,
                                                                    d.id_diagnosis,
                                                                    d.code_icd,
                                                                    d.flg_other,
                                                                    d.flg_select
                                                      FROM diagnosis_content d) diag
                                              JOIN TABLE(l_diag_rowids) diag_rowids
                                                ON diag_rowids.column_value = diag.rowid_d) diags
                                      LEFT JOIN TABLE(CAST(l_tcrit AS t_tbl_criteria_sel_diag)) crosslink
                                        ON diags.row_id = crosslink.diag_rowid
                                     ORDER BY rank)
                             WHERE rownum <= to_number(l_limit))
                     ORDER BY desc_val;
            END IF;
        ELSIF (l_guideline_criteria_type = g_guideline_allergies)
        THEN
            IF (l_last_level = 1)
            THEN
                l_market         := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
                l_default_market := pk_allergy.get_default_allergy_market(l_market);
            
                OPEN o_criteria_search FOR
                    SELECT pk_translation.get_translation(i_lang, ale.code_allergy) AS desc_val,
                           ale.id_allergy AS val,
                           get_count_allergies(i_prof, i_id_guideline, ale.id_allergy, l_default_market) AS flg_select_stat,
                           --ale.flg_select AS flg_select
                           g_no AS flg_select
                      FROM allergy ale
                     WHERE ale.flg_available = g_ale_available
                       AND ale.flg_active = g_allergy_active
                       AND ale.id_allergy_parent IS NULL
                       AND ale.flg_without IS NULL
                          ----------------------------------------------------------------------
                       AND ((translate(upper(pk_translation.get_translation(i_lang, ale.code_allergy)),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                       AND ale.id_allergy IN
                           (SELECT aism.id_allergy
                              FROM allergy_inst_soft_market aism
                             WHERE aism.id_market IN (pk_allergy.g_default_market, l_default_market)
                               AND aism.id_institution IN (i_prof.institution, g_all_institution))
                     ORDER BY desc_val;
            
            ELSE
            
                IF NOT pk_allergy.get_allergy_type_subset_list(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_id_patient     => NULL,
                                                               i_id_episode     => NULL,
                                                               i_allergy_parent => i_guideline_criteria_search(l_last_level - 1),
                                                               i_level          => l_last_level,
                                                               i_flg_freq       => pk_alert_constant.g_no,
                                                               o_select_level   => o_select_level,
                                                               o_allergies      => o_allergies,
                                                               o_limit_message  => l_allergies_limit_message,
                                                               o_error          => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- delete any records present in tbl_temp and fill with allergies cursor from core
                DELETE FROM tbl_temp;
                FETCH o_allergies BULK COLLECT
                    INTO l_id_allergy,
                         l_id_allergy_parent,
                         l_desc_allergy,
                         l_desc_allergy_order,
                         l_rank,
                         l_flg_adverse_reaction,
                         l_select_level;
                CLOSE o_allergies;
            
                -- create temporary table with allergies info
                insert_tbl_temp(i_num_1 => l_id_allergy, i_vc_1 => l_desc_allergy, i_vc_3 => l_select_level);
            
                OPEN o_criteria_search FOR
                    SELECT core_allergy.vc_1 AS desc_val,
                           ale.id_allergy AS val,
                           l_guideline_criteria_type AS val_type,
                           decode(crosslink.id_link_other_criteria,
                                  NULL,
                                  g_criteria_clear,
                                  decode(crosslink.criteria_type,
                                         i_criteria_type,
                                         g_criteria_already_set,
                                         g_criteria_already_crossset)) AS flg_select_stat,
                           core_allergy.vc_3 AS flg_select
                      FROM allergy ale
                      JOIN tbl_temp core_allergy
                        ON ale.id_allergy = core_allergy.num_1
                      LEFT JOIN (SELECT guid_crit_lnk.id_link_other_criteria,
                                        guid_crit_lnk.id_link_other_criteria_type,
                                        guid_crit.criteria_type
                                   FROM guideline               guid,
                                        guideline_criteria      guid_crit,
                                        guideline_criteria_link guid_crit_lnk
                                  WHERE guid.id_guideline = i_id_guideline
                                    AND guid_crit.id_guideline = guid.id_guideline
                                    AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                    AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                        ON ale.id_allergy = safe_to_number(crosslink.id_link_other_criteria)
                    ----------------------------------------------------------------------
                     WHERE ((translate(upper(core_allergy.vc_1), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                     ORDER BY desc_val;
            END IF;
        
        ELSIF (l_guideline_criteria_type = g_guideline_analysis)
        THEN
        
            IF (l_last_level = 1)
            THEN
                OPEN o_criteria_search FOR
                    SELECT pk_translation.get_translation(i_lang, st.code_sample_type) desc_val,
                           st.id_sample_type val,
                           get_count_analysis_sample(i_lang, i_prof, i_id_guideline, st.id_sample_type, NULL) AS flg_select_stat,
                           g_not_available AS flg_select
                      FROM sample_type st
                     WHERE st.flg_available = g_samp_type_avail
                       AND st.id_sample_type IN (SELECT a.id_sample_type
                                                   FROM analysis a, analysis_instit_soft ad
                                                  WHERE ad.id_analysis = a.id_analysis
                                                    AND ad.id_software = i_prof.software
                                                    AND ad.id_institution = i_prof.institution
                                                    AND a.flg_available = g_analysis_available
                                                    AND ad.flg_type = 'P'
                                                    AND ad.flg_available = g_analysis_available
                                                    AND EXISTS (SELECT 1
                                                           FROM analysis_param ap
                                                          WHERE ap.id_analysis = a.id_analysis
                                                            AND ap.flg_available = 'Y'
                                                            AND ap.id_institution = i_prof.institution
                                                            AND ap.id_software = i_prof.software))
                          ---------------------------------------------------------------------------------------
                       AND ((translate(upper(pk_translation.get_translation(i_lang, st.code_sample_type)),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                    ---------------------------------------------------------------------------------------
                     ORDER BY st.rank, desc_val;
            
            ELSIF (l_last_level = 2)
            THEN
            
                OPEN o_criteria_search FOR
                    SELECT DISTINCT pk_translation.get_translation(i_lang, ec.code_exam_cat) AS desc_val,
                                    ec.id_exam_cat AS val,
                                    get_count_analysis_sample(i_lang,
                                                              i_prof,
                                                              i_id_guideline,
                                                              i_guideline_criteria_search(l_last_level),
                                                              ec.id_exam_cat) AS flg_select_stat,
                                    g_not_available AS flg_select
                      FROM analysis anls, sample_type st, exam_cat ec, analysis_instit_soft ais
                     WHERE st.id_sample_type = i_guideline_criteria_search(l_last_level)
                       AND anls.id_sample_type = st.id_sample_type
                       AND anls.flg_available = g_analysis_available
                       AND ec.id_exam_cat = ais.id_exam_cat
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software
                       AND anls.id_analysis = ais.id_analysis
                       AND ais.flg_available = g_analysis_available
                          ---------------------------------------------------------------------------------------
                       AND ((translate(upper(pk_translation.get_translation(i_lang, ec.code_exam_cat)),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                    ---------------------------------------------------------------------------------------
                     ORDER BY desc_val;
            
            ELSIF (l_last_level = 3)
            THEN
            
                OPEN o_criteria_search FOR
                    SELECT analysis.desc_val,
                           analysis.val,
                           decode(crosslink.id_link_other_criteria,
                                  NULL,
                                  g_criteria_clear,
                                  decode(crosslink.criteria_type,
                                         i_criteria_type,
                                         g_criteria_already_set,
                                         g_criteria_already_crossset)) AS flg_select_stat,
                           g_available AS flg_select
                      FROM (SELECT DISTINCT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      'A',
                                                                                      anls.code_analysis,
                                                                                      NULL) AS desc_val,
                                            anls.id_analysis AS val
                              FROM analysis anls, analysis_instit_soft ais
                             WHERE anls.id_sample_type = i_guideline_criteria_search(l_last_level - 1)
                               AND anls.flg_available = g_analysis_available
                               AND ais.id_exam_cat = i_guideline_criteria_search(l_last_level)
                               AND ais.id_analysis = anls.id_analysis
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.flg_available = g_analysis_available) analysis
                      LEFT JOIN (SELECT guid_crit_lnk.id_link_other_criteria,
                                        guid_crit_lnk.id_link_other_criteria_type,
                                        guid_crit.criteria_type
                                   FROM guideline               guid,
                                        guideline_criteria      guid_crit,
                                        guideline_criteria_link guid_crit_lnk
                                  WHERE guid.id_guideline = i_id_guideline
                                    AND guid_crit.id_guideline = guid.id_guideline
                                    AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                    AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                        ON analysis.val = safe_to_number(crosslink.id_link_other_criteria)
                    ---------------------------------------------------------------------------------------
                     WHERE ((translate(upper(analysis.desc_val), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                    ---------------------------------------------------------------------------------------
                     ORDER BY desc_val;
            
            END IF;
        
            ----------------------------------------------------------------------
        
        ELSIF (l_guideline_criteria_type = g_guideline_exams OR l_guideline_criteria_type = g_guideline_other_exams)
        THEN
        
            OPEN o_criteria_search FOR
                SELECT desc_val,
                       val,
                       val_type,
                       decode(crosslink.id_link_other_criteria,
                              NULL,
                              g_criteria_clear,
                              decode(crosslink.criteria_type,
                                     i_criteria_type,
                                     g_criteria_already_set,
                                     g_criteria_already_crossset)) AS flg_select_stat,
                       g_available AS flg_select
                  FROM (SELECT DISTINCT pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam) desc_val,
                                        ex.id_exam AS val,
                                        'E' AS val_type,
                                        0 AS rank -- ed.rank AS rank
                          FROM exam_dep_clin_serv ed1, exam ex, exam_cat ec
                         WHERE ex.flg_available = g_exam_available
                              ---------------------------------
                           AND ((ex.flg_type = g_exam_type_img AND l_guideline_criteria_type = g_guideline_exams) --se 'Imagem'
                               OR
                               (ex.flg_type != g_exam_type_img AND l_guideline_criteria_type = g_guideline_other_exams)) --se 'Outros exames'
                              ---------------------------------
                              --AND ed.id_software = i_prof.software
                           AND ec.id_exam_cat = ex.id_exam_cat
                           AND ed1.id_exam = ex.id_exam
                           AND ed1.flg_type = g_exam_can_req
                              --AND ed1.id_software = i_prof.software
                           AND ed1.id_institution = i_prof.institution
                        UNION
                        SELECT pk_translation.get_translation(i_lang, eg.code_exam_group) AS desc_val,
                               eg.id_exam_group AS val,
                               'G' AS val_type,
                               eg.rank AS rank
                          FROM exam_group eg, exam_egp exmg, exam ex, exam_cat ec
                         WHERE exmg.id_exam_group = eg.id_exam_group
                           AND ex.id_exam = exmg.id_exam
                           AND ex.flg_available = g_exam_available
                              ---------------------------------
                           AND ((ex.flg_type = g_exam_type_img AND l_guideline_criteria_type = g_guideline_exams) --se 'Imagem'
                               OR
                               (ex.flg_type != g_exam_type_img AND l_guideline_criteria_type = g_guideline_other_exams)) --se 'Outros exames'
                              ---------------------------------
                              --AND ed.id_software = i_prof.software
                           AND ec.id_exam_cat = ex.id_exam_cat) exams
                  LEFT JOIN (SELECT guid_crit_lnk.id_link_other_criteria,
                                    guid_crit_lnk.id_link_other_criteria_type,
                                    guid_crit.criteria_type
                               FROM guideline guid, guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
                              WHERE guid.id_guideline = i_id_guideline
                                AND guid_crit.id_guideline = guid.id_guideline
                                AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                    ON exams.val = safe_to_number(crosslink.id_link_other_criteria)
                 WHERE exams.desc_val IS NOT NULL
                   AND ((translate(upper(exams.desc_val), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' ||
                       translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                       l_value_search IS NOT NULL) OR l_value_search IS NULL)
                 ORDER BY rank, desc_val;
        
        ELSIF (l_guideline_criteria_type = g_guideline_diagnosis_nurse)
        THEN
        
            IF (l_last_level = 1)
            THEN
                OPEN o_criteria_search FOR
                    SELECT desc_val,
                           val,
                           get_count_nurse_diag(i_lang, i_prof, i_id_guideline, val) AS flg_select_stat,
                           g_not_available AS flg_select
                      FROM (SELECT desc_clinical_service AS desc_val, id_clinical_service AS val, rank
                              FROM (SELECT DISTINCT dcs.id_clinical_service id_clinical_service,
                                                    pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                                                    0 rank --i.RANK
                                      FROM icnp_compo_dcs   icd,
                                           dep_clin_serv    dcs,
                                           department       dep,
                                           software_dept    sd,
                                           clinical_service cs
                                     WHERE dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                                       AND dep.id_department = dcs.id_department
                                       AND sd.id_dept = dep.id_dept
                                       AND sd.id_software = i_prof.software
                                       AND cs.id_clinical_service = dcs.id_clinical_service
                                       AND dcs.id_department IN
                                           (SELECT dep.id_department
                                              FROM department dep
                                             WHERE dep.id_institution = i_prof.institution)
                                    UNION
                                    SELECT -1 id_clinical_service,
                                           pk_message.get_message(i_lang, i_prof, g_cipe) desc_clinical_service,
                                           -1
                                      FROM dual)) diagnosis_nurse
                     WHERE ((translate(upper(diagnosis_nurse.desc_val),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                     ORDER BY rank, desc_val;
            
            ELSE
            
                IF (i_guideline_criteria_search(l_last_level) < 0)
                THEN
                    OPEN o_criteria_search FOR
                        SELECT desc_val,
                               val,
                               decode(crosslink.id_link_other_criteria,
                                      NULL,
                                      g_criteria_clear,
                                      decode(crosslink.criteria_type,
                                             i_criteria_type,
                                             g_criteria_already_set,
                                             g_criteria_already_crossset)) AS flg_select_stat,
                               g_available AS flg_select
                          FROM (SELECT DISTINCT ic.id_composition AS val,
                                                pk_icnp.desc_composition(i_lang, ic.id_composition) desc_val,
                                                ic.flg_repeat,
                                                0 rank
                                  FROM icnp_composition ic, icnp_compo_dcs icd
                                 WHERE icd.id_composition = ic.id_composition
                                   AND ic.flg_type = g_composition_diag_type
                                   AND icd.id_dep_clin_serv IN
                                       (SELECT dcs.id_dep_clin_serv
                                          FROM dep_clin_serv dcs, department dep, dept dp, software_dept sd
                                         WHERE dep.id_department = dcs.id_department
                                           AND dep.id_institution = i_prof.institution
                                           AND dp.id_dept = dep.id_dept
                                           AND sd.id_dept = dp.id_dept
                                           AND sd.id_software = i_prof.software)) diag_specific
                          LEFT JOIN (SELECT guid_crit_lnk.id_link_other_criteria,
                                            guid_crit_lnk.id_link_other_criteria_type,
                                            guid_crit.criteria_type
                                       FROM guideline               guid,
                                            guideline_criteria      guid_crit,
                                            guideline_criteria_link guid_crit_lnk
                                      WHERE guid.id_guideline = i_id_guideline
                                        AND guid_crit.id_guideline = guid.id_guideline
                                        AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                        AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                            ON diag_specific.val = safe_to_number(crosslink.id_link_other_criteria)
                         WHERE ((translate(upper(diag_specific.desc_val),
                                           'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                           'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' || translate(upper(l_value_search),
                                                  'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                                  'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND l_value_search IS NOT NULL) OR
                               l_value_search IS NULL)
                         ORDER BY rank, desc_val;
                ELSE
                
                    OPEN o_criteria_search FOR
                        SELECT desc_val,
                               val,
                               rank,
                               decode(crosslink.id_link_other_criteria,
                                      NULL,
                                      g_criteria_clear,
                                      decode(crosslink.criteria_type,
                                             i_criteria_type,
                                             g_criteria_already_set,
                                             g_criteria_already_crossset)) AS flg_select_stat,
                               g_available AS flg_select
                          FROM (SELECT DISTINCT ic.id_composition val,
                                                pk_icnp.desc_composition(i_lang, ic.id_composition) desc_val,
                                                ic.flg_repeat,
                                                0 rank
                                  FROM icnp_composition ic,
                                       icnp_compo_dcs   icd,
                                       dep_clin_serv    dcs,
                                       department       dep,
                                       software_dept    sd
                                 WHERE icd.id_composition = ic.id_composition
                                   AND ic.flg_type = g_composition_diag_type
                                   AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                                   AND dcs.id_clinical_service = i_guideline_criteria_search(l_last_level)
                                   AND dep.id_department = dcs.id_department
                                   AND dep.id_institution = i_prof.institution
                                   AND sd.id_dept = dep.id_dept
                                   AND sd.id_software = i_prof.software
                                   AND ic.flg_available = g_available) diag_specific
                          LEFT JOIN (SELECT guid_crit_lnk.id_link_other_criteria,
                                            guid_crit_lnk.id_link_other_criteria_type,
                                            guid_crit.criteria_type
                                       FROM guideline               guid,
                                            guideline_criteria      guid_crit,
                                            guideline_criteria_link guid_crit_lnk
                                      WHERE guid.id_guideline = i_id_guideline
                                        AND guid_crit.id_guideline = guid.id_guideline
                                        AND guid_crit_lnk.id_guideline_criteria = guid_crit.id_guideline_criteria
                                        AND guid_crit_lnk.id_link_other_criteria_type = l_guideline_criteria_type) crosslink
                            ON diag_specific.val = safe_to_number(crosslink.id_link_other_criteria)
                         WHERE ((translate(upper(diag_specific.desc_val),
                                           'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                           'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' || translate(upper(l_value_search),
                                                  'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                                  'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND l_value_search IS NOT NULL) OR
                               l_value_search IS NULL)
                         ORDER BY rank, desc_val;
                
                END IF;
            
            END IF;
        ELSE
            pk_types.open_my_cursor(o_criteria_search);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_CRITERIA_SEARCH',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_criteria_search);
            -- return failure of function
            RETURN FALSE;
        
    END get_criteria_search;

    /** 
    *  Get criteria types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                  Guideline ID        
    * @param      O_CRITERIA_TYPE              cursor with all criteria types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_criteria_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_criteria_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET CURSOR CRITERIA TYPE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_criteria_type FOR
            SELECT guid_crit_typ.id_guideline_criteria_type,
                   pk_translation.get_translation(i_lang, guid_crit_typ.code_guideline_criteria_type) desc_guideline_criteria_type,
                   decode(guid_crit_lnk.counter_link, NULL, 0, 0, 0, g_criteria_group_some) AS flg_select
              FROM guideline_criteria_type guid_crit_typ,
                   (SELECT guid_crit_link.id_link_other_criteria_type AS id_link_other_criteria_type,
                           COUNT(1) AS counter_link
                      FROM guideline_criteria guid_crit, guideline_criteria_link guid_crit_link
                     WHERE guid_crit.id_guideline = i_id_guideline
                       AND guid_crit_link.id_guideline_criteria = guid_crit.id_guideline_criteria
                     GROUP BY guid_crit_link.id_link_other_criteria_type) guid_crit_lnk,
                   (SELECT DISTINCT item
                      FROM (SELECT item,
                                   first_value(gisi.flg_available) over(PARTITION BY gisi.item ORDER BY gisi.id_market DESC, gisi.id_institution DESC, gisi.id_software DESC, gisi.flg_available) AS flg_avail
                              FROM guideline_item_soft_inst gisi
                             WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                               AND gisi.id_software IN (g_all_software, i_prof.software)
                               AND gisi.id_market IN (g_all_markets, l_market)
                               AND gisi.flg_item_type = g_guideline_item_criteria)
                     WHERE flg_avail = g_available) guide_item
             WHERE guid_crit_typ.flg_available = g_available
               AND guid_crit_typ.id_guideline_criteria_type = guid_crit_lnk.id_link_other_criteria_type(+)
               AND guide_item.item = guid_crit_typ.id_guideline_criteria_type
             ORDER BY desc_guideline_criteria_type;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_CRITERIA_TYPE',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_criteria_type);
            -- return failure of function
            RETURN FALSE;
        
    END get_criteria_type;

    /** 
    *  Obtain all pathologies by search code
    *
    * @param      I_LANG                     Preferred language ID for this professional
    * @param      I_PROF                     object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELI               Guideline ID
    * @param      I_VALUE_CODE               Value with code to search for
    * @param      O_PATHOLOGY_BY_SEARCH      cursor with all pathologies
    * @param      O_ERROR                    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/08
    */
    FUNCTION get_pathology_by_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_value_code        IN VARCHAR2,
        o_pathology_by_code OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_diags pk_types.cursor_type;
        l_exception EXCEPTION;
        --
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg       sys_message.desc_message%TYPE;
        l_msg_title sys_message.desc_message%TYPE;
        l_button    VARCHAR2(1 CHAR);
        --
        l_diag_desc          table_varchar;
        l_id_diagnosis       table_number;
        l_code_icd           table_varchar;
        l_flg_select         table_varchar;
        l_rank               table_number;
        l_flg_other          table_varchar;
        l_id_alert_diagnosis table_number;
        --
        e_no_results_found EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_no_results_found, -06504); -- Return types of Result Set variables or query do not match
    
    BEGIN
        g_error := 'GET CURSOR PATHOLOGIES BY SEARCH CODE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF NOT pk_search.get_cod_diag_criteria(i_lang      => i_lang,
                                               i_value     => i_value_code,
                                               i_prof      => i_prof,
                                               i_patient   => NULL,
                                               o_flg_show  => l_flg_show,
                                               o_msg       => l_msg,
                                               o_msg_title => l_msg_title,
                                               o_button    => l_button,
                                               o_diag      => c_diags,
                                               o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_flg_show = '0'
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        -- delete any records present in tbl_temp and fill with diagnosis cursor
        DELETE FROM tbl_temp;
        BEGIN
            FETCH c_diags BULK COLLECT
                INTO l_diag_desc, l_id_diagnosis, l_code_icd, l_rank, l_flg_select, l_flg_other, l_id_alert_diagnosis;
        EXCEPTION
            WHEN e_no_results_found THEN
                NULL;
        END;
        CLOSE c_diags;
    
        -- create temporary table with diags info
        insert_tbl_temp(i_num_1 => l_id_diagnosis, i_vc_1 => l_diag_desc, i_vc_2 => l_flg_select);
    
        OPEN o_pathology_by_code FOR
            SELECT diags.vc_1 AS desc_diagnosis,
                   diags.num_1 AS id_diagnosis,
                   decode(guid_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM guideline_link guid_link
                                WHERE guid_link.link_type = g_guide_link_pathol
                                  AND guid_link.id_guideline = i_id_guideline) guid_lnk
                ON diags.num_1 = guid_lnk.id_link
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pathology_by_code);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_log_object_name, 'GET_PATHOLOGY_BY_CODE', o_error);
            -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PATHOLOGY_BY_CODE',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pathology_by_code);
            -- return failure of function
            RETURN FALSE;
        
    END get_pathology_by_code;

    /** 
    *  Obtain all pathologies by search
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_SEARCH        cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_pathology_by_search
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline        IN guideline.id_guideline%TYPE,
        i_value               IN VARCHAR2,
        o_pathology_by_search OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_diags      pk_types.cursor_type;
        c_epis_diags pk_types.cursor_type;
        l_exception EXCEPTION;
        --
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg       sys_message.desc_message%TYPE;
        l_msg_title sys_message.desc_message%TYPE;
        l_button    VARCHAR2(2 CHAR);
        --
        l_coll_id_diagnosis            table_number;
        l_coll_id_diagnosis_parent     table_number;
        l_coll_id_epis_diagnosis       table_number;
        l_coll_desc_diagnosis          table_varchar;
        l_coll_code_icd                table_varchar;
        l_coll_flg_other               table_varchar;
        l_coll_status_diagnosis        table_varchar;
        l_coll_icon_status             table_varchar;
        l_coll_avail_for_select        table_varchar;
        l_coll_default_new_status      table_varchar;
        l_coll_default_new_status_desc table_varchar;
        l_coll_id_alert_diagnosis      table_number;
        l_coll_desc_epis_diagnosis     table_varchar;
        l_coll_flg_terminology         table_varchar;
        l_coll_flg_diag_type           table_varchar;
        l_coll_rank                    table_number;
        l_coll_code_diagnosis          table_varchar;
        l_coll_flg_icd9                table_varchar;
        l_coll_flg_show_term_code      table_varchar;
        l_coll_id_language             table_number;
        --
        l_overlimit BOOLEAN;
        e_no_results_found EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_no_results_found, -06504); -- Return types of Result Set variables or query do not match
    
    BEGIN
        g_error := 'GET CURSOR PATHOLOGIES BY SEARCH';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF i_value IS NOT NULL
        THEN
        
            IF NOT pk_search.get_diag_criteria(i_lang      => i_lang,
                                               i_value     => i_value,
                                               i_prof      => i_prof,
                                               i_patient   => NULL,
                                               o_flg_show  => l_flg_show,
                                               o_msg       => l_msg,
                                               o_msg_title => l_msg_title,
                                               o_button    => l_button,
                                               o_diag      => c_diags,
                                               o_error     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_flg_show = pk_alert_constant.get_yes
            THEN
                l_overlimit := TRUE;
            END IF;
        
            -- delete any records present in tbl_temp and fill with diagnosis cursor
            DELETE FROM tbl_temp;
            BEGIN
                FETCH c_diags BULK COLLECT
                    INTO l_coll_desc_diagnosis,
                         l_coll_id_diagnosis,
                         l_coll_code_icd,
                         l_coll_rank,
                         l_coll_avail_for_select,
                         l_coll_flg_other,
                         l_coll_id_alert_diagnosis,
                         l_coll_flg_diag_type;
            EXCEPTION
                WHEN e_no_results_found THEN
                    NULL;
            END;
            CLOSE c_diags;
        
            -- create temporary table with diags info
            insert_tbl_temp(i_num_1 => l_coll_id_diagnosis,
                            i_vc_1  => l_coll_desc_diagnosis,
                            i_vc_2  => l_coll_avail_for_select);
        
        ELSE
            IF NOT pk_diagnosis.get_freq_diag_diff(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_patient        => NULL,
                                                   i_epis           => NULL,
                                                   o_diagnosis      => c_diags,
                                                   o_epis_diagnosis => c_epis_diags,
                                                   o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- delete any records present in tbl_temp and fill with diagnosis cursor
            DELETE FROM tbl_temp;
            BEGIN
                FETCH c_diags BULK COLLECT
                    INTO l_coll_id_diagnosis,
                         l_coll_id_diagnosis_parent,
                         l_coll_id_epis_diagnosis,
                         l_coll_desc_diagnosis,
                         l_coll_code_icd,
                         l_coll_flg_other,
                         l_coll_status_diagnosis,
                         l_coll_icon_status,
                         l_coll_avail_for_select,
                         l_coll_default_new_status,
                         l_coll_default_new_status_desc,
                         l_coll_id_alert_diagnosis,
                         l_coll_desc_epis_diagnosis,
                         l_coll_flg_terminology,
                         l_coll_flg_diag_type,
                         l_coll_rank,
                         l_coll_code_diagnosis,
                         l_coll_flg_icd9,
                         l_coll_flg_show_term_code,
                         l_coll_id_language;
            EXCEPTION
                WHEN e_no_results_found THEN
                    NULL;
            END;
            CLOSE c_diags;
        
            -- create temporary table with diags info
            insert_tbl_temp(i_num_1 => l_coll_id_diagnosis,
                            i_vc_1  => l_coll_desc_diagnosis,
                            i_vc_2  => l_coll_avail_for_select);
        
        END IF;
    
        OPEN o_pathology_by_search FOR
            SELECT diags.vc_1 AS desc_diagnosis,
                   diags.num_1 AS id_diagnosis,
                   decode(guid_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM guideline_link guide_link
                                WHERE guide_link.link_type = g_guide_link_pathol
                                  AND guide_link.id_guideline = i_id_guideline) guid_lnk
                ON diags.num_1 = guid_lnk.id_link
             ORDER BY desc_diagnosis;
    
        IF l_overlimit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_log_object_name, 'GET_PATHOLOGY_BY_SEARCH', o_error);
        
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PATHOLOGY_BY_SEARCH',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pathology_by_search);
            -- return failure of function
            RETURN FALSE;
        
    END get_pathology_by_search;

    /** 
    *  Obtain all pathologies by group
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_PARENT                  Parent ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_GROUP         cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/25
    */
    FUNCTION get_pathology_by_group
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_id_parent          IN diagnosis.id_diagnosis_parent%TYPE,
        i_value              IN VARCHAR2,
        o_pathology_by_group OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_diags pk_types.cursor_type;
        l_exception EXCEPTION;
        --
        l_id_diagnosis        table_number;
        l_id_alert_diagnosis  table_number;
        l_diag_desc           table_varchar;
        l_id_diagnosis_parent table_number;
        l_flg_select          table_varchar;
        --
        e_no_results_found EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_no_results_found, -06504); -- Return types of Result Set variables or query do not match
    
    BEGIN
        g_error := 'GET CURSOR PATHOLOGIES BY GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF NOT pk_list.get_cat_diag(i_lang      => i_lang,
                                    i_id_parent => i_id_parent,
                                    i_prof      => i_prof,
                                    i_patient   => NULL,
                                    o_list      => c_diags,
                                    o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- delete any records present in tbl_temp and fill with diagnosis cursor
        DELETE FROM tbl_temp;
        BEGIN
            FETCH c_diags BULK COLLECT
                INTO l_id_diagnosis, l_id_alert_diagnosis, l_diag_desc, l_id_diagnosis_parent, l_flg_select;
        EXCEPTION
            WHEN e_no_results_found THEN
                NULL;
        END;
        CLOSE c_diags;
    
        -- create temporary table with diags info
        insert_tbl_temp(i_num_1 => l_id_diagnosis,
                        i_num_2 => l_id_diagnosis_parent,
                        i_vc_1  => l_diag_desc,
                        i_vc_2  => l_flg_select);
    
        g_error := 'GET CURSOR';
        OPEN o_pathology_by_group FOR
            SELECT diags.vc_1 AS desc_diagnosis,
                   diags.num_1 AS id_diagnosis,
                   decode(guid_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.num_2 AS id_diagnosis_parent,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM guideline_link guid_link
                                WHERE guid_link.link_type = g_guide_link_pathol
                                  AND guid_link.id_guideline = i_id_guideline) guid_lnk
                ON diags.num_1 = guid_lnk.id_link
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PATHOLOGY_BY_GROUP',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pathology_by_group);
            -- return failure of function
            RETURN FALSE;
        
    END get_pathology_by_group;

    /** 
    *  Gets a specialty list to which can be requested a opinion
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_SPEC      Specialties list
    * @param      O_ERROR     Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/12
    */
    FUNCTION get_opinion_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_opt_func_id prof_func.id_functionality%TYPE;
    BEGIN
        g_error       := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(g_config_func_opinion, i_prof);
    
        g_error := 'OPEN O_SPEC';
        OPEN o_spec FOR
            SELECT id_speciality,
                   pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || id_speciality) spec_name
              FROM (SELECT DISTINCT p.id_speciality
                      FROM professional p, prof_soft_inst psi, prof_cat pc, category c
                     WHERE p.flg_state = g_prof_active
                       AND psi.id_professional = p.id_professional
                       AND psi.id_institution = i_prof.institution
                       AND p.id_professional IN (SELECT pf.id_professional
                                                   FROM prof_func pf
                                                  WHERE pf.id_functionality = l_opt_func_id
                                                    AND pf.id_institution = i_prof.institution)
                       AND p.id_professional = pc.id_professional
                       AND pc.id_category = c.id_category
                       AND pc.id_institution = i_prof.institution
                       AND p.id_speciality IS NOT NULL)
             ORDER BY spec_name;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_OPINION_SPEC_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_spec);
            -- return failure of function
            RETURN FALSE;
        
    END get_opinion_spec_list;

    /** 
    *  Gets a professionals list, of the given speciality, to which can be requested a opinion
    *
    * @param      I_LANG          Preferred language ID for this professional
    * @param      I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param      I_SPECIALITY    Professionals specialty
    * @param      O_PROF          Professionals list
    * @param      O_ERROR         Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/12
    */
    FUNCTION get_opinion_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_opt_func_id prof_func.id_functionality%TYPE;
    BEGIN
        g_error       := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(g_config_func_opinion, i_prof);
    
        g_error := 'OPEN O_PROF';
        OPEN o_prof FOR
            SELECT DISTINCT p.id_professional,
                            1 rank,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
              FROM professional p, prof_func pf, prof_cat pc, category c
             WHERE p.id_speciality = i_speciality
               AND p.flg_state = g_prof_active
               AND pf.id_professional = p.id_professional
               AND pf.id_institution = i_prof.institution
               AND pf.id_functionality = l_opt_func_id
               AND p.id_professional = pc.id_professional
               AND (p.flg_prof_test IS NULL OR p.flg_prof_test = g_no)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND pc.id_category = c.id_category
               AND pc.id_institution = i_prof.institution
            UNION
            SELECT -1 id_professional, -1 rank, pk_message.get_message(i_lang, g_message_opinion_any_prof) nick_name
              FROM dual
             WHERE EXISTS (SELECT 'X'
                      FROM professional p, prof_func pf, prof_soft_inst psi, prof_cat pc, category c
                     WHERE p.id_speciality = i_speciality
                       AND p.flg_state = g_prof_active
                       AND pf.id_professional = p.id_professional
                       AND pf.id_institution = i_prof.institution
                       AND pf.id_functionality = l_opt_func_id
                       AND psi.id_professional = p.id_professional
                       AND psi.id_institution = i_prof.institution
                       AND p.id_professional = pc.id_professional
                       AND (p.flg_prof_test IS NULL OR p.flg_prof_test = g_no)
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND pc.id_category = c.id_category
                       AND pc.id_institution = i_prof.institution)
             ORDER BY rank, nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_OPINION_PROF_SPEC_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_prof);
            -- return failure of function
            RETURN FALSE;
        
    END get_opinion_prof_spec_list;

    /** 
    *  Clean temp guidelines 
    *
    * @param      I_LANG              Preferred language ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.
    * @param      I_DATE_OFFSET       Date with offset in days
    * @param      O_ERROR             error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/27
    */
    FUNCTION clean_guideline_temp
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_date_offset  IN guideline.dt_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_guideline IS
            SELECT id_guideline, flg_status
              FROM guideline
             WHERE ((id_guideline = i_id_guideline AND i_id_guideline IS NOT NULL) OR i_id_guideline IS NULL)
               AND flg_status = g_guideline_temp
               AND dt_guideline < i_date_offset;
    
    BEGIN
    
        g_error := 'FETCH GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Checks if guideline is temp and clean
        FOR rec_guideline IN c_guideline
        LOOP
            IF (NOT cancel_guideline(i_lang, i_prof, rec_guideline.id_guideline, o_error))
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CLEAN_GUIDELINE_TEMP',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END clean_guideline_temp;

    /** 
    *  Cancel a task request
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)  
    * @param      I_TASK_TYPE                  Task Type
    * @param      i_id_episode                 episode id
    * @param      i_id_cancel_reason           cancel reason that justifies the task cancel
    * @param      i_cancel_notes               cancel notes (free text) that justifies the task cancel    
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/24
    */
    FUNCTION cancel_task_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN guideline_process_task.task_type%TYPE,
        i_id_request       IN guideline_process_task.id_request%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancel_result BOOLEAN;
        l_prof_cat      category.flg_type%TYPE;
        l_patient       episode.id_patient%TYPE;
    
        l_cancel_notes_text pk_translation.t_desc_translation;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_exception EXCEPTION;
    
    BEGIN
        -- check if cancel notes is null. if so, then change cancel notes text using the cancel reason description
        IF i_cancel_notes IS NULL
           AND i_id_cancel_reason IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
              INTO l_cancel_notes_text
              FROM cancel_reason cr
             WHERE cr.id_cancel_reason = i_id_cancel_reason;
        ELSE
            l_cancel_notes_text := i_cancel_notes;
        END IF;
    
        g_error := 'GET CATEGORY OF THE PROFESSIONAL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT cat.flg_type
          INTO l_prof_cat
          FROM prof_cat pc, category cat
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = cat.id_category;
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'CANCEL TASK REQUEST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        CASE i_task_type
            WHEN g_task_analysis THEN
                -- analysis
                l_cancel_result := pk_lab_tests_api_db.cancel_lab_test_request(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_analysis_req_det => table_number(i_id_request),
                                                                               i_dt_cancel        => NULL,
                                                                               i_cancel_reason    => i_id_cancel_reason,
                                                                               i_cancel_notes     => i_cancel_notes,
                                                                               i_prof_order       => NULL,
                                                                               i_dt_order         => NULL,
                                                                               i_order_type       => NULL,
                                                                               o_error            => o_error);
            
            WHEN g_task_appoint THEN
                -- Consultas
                l_cancel_result := pk_consult_req.cancel_consult_req(i_lang         => i_lang,
                                                                     i_consult_req  => i_id_request,
                                                                     i_prof_cancel  => i_prof,
                                                                     i_notes_cancel => l_cancel_notes_text,
                                                                     i_commit_data  => pk_alert_constant.g_no,
                                                                     o_error        => o_error);
            
            WHEN g_task_patient_education THEN
                -- Patient education
                l_cancel_result := pk_patient_education_api_db.cancel_patient_education(i_lang             => i_lang,
                                                                                        i_prof             => i_prof,
                                                                                        i_id_nurse_tea_req => table_number(i_id_request),
                                                                                        i_id_cancel_reason => i_id_cancel_reason,
                                                                                        i_cancel_notes     => i_cancel_notes,
                                                                                        o_error            => o_error);
            
            WHEN g_task_img THEN
                -- Imagem
                l_cancel_result := pk_exams_api_db.cancel_exam_request(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_exam_req_det   => table_number(i_id_request),
                                                                       i_dt_cancel      => NULL,
                                                                       i_cancel_reason  => i_id_cancel_reason,
                                                                       i_cancel_notes   => i_cancel_notes,
                                                                       i_prof_order     => NULL,
                                                                       i_dt_order       => NULL,
                                                                       i_order_type     => NULL,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error);
            
            WHEN g_task_vacc THEN
                -- imunizações
                l_cancel_result := FALSE;
            
            WHEN g_task_enfint THEN
                -- Intervenções de enfermagem
                BEGIN
                    pk_icnp_fo_api_db.set_interv_status_cancel(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => i_id_episode,
                                                               i_patient        => l_patient,
                                                               i_epis_interv_id => i_id_request,
                                                               i_cancel_reason  => i_id_cancel_reason,
                                                               i_cancel_notes   => i_cancel_notes,
                                                               i_sysdate_tstz   => current_timestamp);
                    l_cancel_result := TRUE;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_cancel_result := pk_alert_exceptions.process_error_short(i_lang    => i_lang,
                                                                                   i_sqlcode => SQLCODE,
                                                                                   i_sqlerrm => SQLERRM,
                                                                                   o_error   => o_error);
                END;
            
            WHEN g_task_otherexam THEN
                -- outros exames
                l_cancel_result := pk_exams_api_db.cancel_exam_request(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_exam_req_det   => table_number(i_id_request),
                                                                       i_dt_cancel      => NULL,
                                                                       i_cancel_reason  => i_id_cancel_reason,
                                                                       i_cancel_notes   => i_cancel_notes,
                                                                       i_prof_order     => NULL,
                                                                       i_dt_order       => NULL,
                                                                       i_order_type     => NULL,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error);
            
            WHEN g_task_spec THEN
                -- pareceres
                l_cancel_result := pk_opinion.cancel_opinion(i_lang          => i_lang,
                                                             i_opinion       => i_id_request,
                                                             i_prof          => i_prof,
                                                             i_notes         => i_cancel_notes,
                                                             i_cancel_reason => i_id_cancel_reason,
                                                             i_commit_data   => pk_alert_constant.g_no,
                                                             o_error         => o_error);
            
            WHEN g_task_rast THEN
                -- rastreios
                l_cancel_result := FALSE;
            
            WHEN g_task_proc THEN
                -- procedimentos
                l_cancel_result := pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                                                 i_prof             => i_prof,
                                                                                 i_interv_presc_det => table_number(i_id_request),
                                                                                 i_dt_cancel        => NULL,
                                                                                 i_cancel_reason    => i_id_cancel_reason,
                                                                                 i_cancel_notes     => i_cancel_notes,
                                                                                 i_prof_order       => NULL,
                                                                                 i_dt_order         => NULL,
                                                                                 i_order_type       => NULL,
                                                                                 o_error            => o_error);
            
            ELSE
                l_cancel_result := FALSE;
        END CASE;
    
        -- transaction control for new scheduler
        IF l_cancel_result
           AND i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        ELSIF NOT l_cancel_result
              AND i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        END IF;
    
        RETURN l_cancel_result;
    END cancel_task_request;

    /** 
    *  Verify if task request is scheduled.
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)  
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_REQUEST                 Request ID of the task
    *
    * @return     VARCHAR2
    * @author     TS
    * @version    0.1
    * @since      2007/06/13
    */
    FUNCTION get_task_request_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN guideline_process_task.task_type%TYPE,
        i_id_request IN guideline_process_task.id_request%TYPE
    ) RETURN VARCHAR2 IS
        l_task_req_stat VARCHAR2(1 CHAR);
        o_error         t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET TASK REQUEST SCHEDULE STATUS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        CASE i_task_type
        
            WHEN g_task_analysis THEN
                -- analysis
            
                g_error := 'GET SCHEDULE ANALYSIS REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(ana_req.flg_time, pk_alert_constant.g_flg_time_e, g_not_scheduled, g_scheduled)
                  INTO l_task_req_stat
                  FROM analysis_req_det ana_req_det, analysis_req ana_req
                 WHERE ana_req_det.id_analysis_req_det = i_id_request
                   AND ana_req_det.id_analysis_req = ana_req.id_analysis_req;
            
            WHEN g_task_appoint THEN
                -- Consultas
            
                g_error := 'GET SCHEDULE APPOINTMENT REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- id_request equal to -1 indicates that this consult request
                -- was scheduled directly on the scheduler
                IF (i_id_request = -1)
                THEN
                    l_task_req_stat := g_scheduled;
                ELSE
                    SELECT decode(flg_status,
                                  pk_consult_req.g_consult_req_stat_sched,
                                  g_scheduled,
                                  pk_consult_req.g_consult_req_stat_proc,
                                  g_scheduled,
                                  g_not_scheduled)
                      INTO l_task_req_stat
                      FROM consult_req
                     WHERE id_consult_req = i_id_request;
                END IF;
            
            WHEN g_task_patient_education THEN
                -- Patient education
                l_task_req_stat := NULL;
            
            WHEN g_task_img THEN
                -- Imagem
            
                g_error := 'GET SCHEDULE IMAGE EXAM REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(id_episode_origin,
                              NULL,
                              decode(flg_status_det,
                                     pk_exam_constant.g_exam_tosched,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_sched,
                                     g_scheduled,
                                     pk_exam_constant.g_exam_result,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_cancel,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_read,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_end_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_toexec,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_req,
                                     g_not_scheduled,
                                     decode(flg_time, pk_exam_constant.g_flg_time_n, g_scheduled, g_not_scheduled)),
                              decode(flg_status_det,
                                     pk_exam_constant.g_exam_tosched,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_sched,
                                     g_scheduled,
                                     pk_exam_constant.g_exam_result,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_cancel,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_read,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_end_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_toexec,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_req,
                                     decode(dt_begin, NULL, g_scheduled, g_not_scheduled),
                                     pk_exam_constant.g_exam_pending,
                                     decode(dt_begin, NULL, g_scheduled, g_not_scheduled),
                                     decode(flg_time, pk_exam_constant.g_flg_time_n, g_scheduled, g_not_scheduled)))
                  INTO l_task_req_stat
                  FROM exams_ea eea
                 WHERE eea.id_exam_req_det = i_id_request;
            
            WHEN g_task_vacc THEN
                -- imunizações
                l_task_req_stat := NULL;
            
            WHEN g_task_enfint THEN
                -- Intervenções de enfermagem
            
                g_error := 'GET SCHEDULE NURSE INTERVENTION REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_time,
                              pk_icnp_constant.g_epis_interv_time_curr_epis,
                              g_not_scheduled,
                              pk_icnp_constant.g_epis_interv_time_before_epis,
                              g_not_scheduled,
                              g_scheduled)
                  INTO l_task_req_stat
                  FROM icnp_epis_intervention
                 WHERE id_icnp_epis_interv = i_id_request;
            
            WHEN g_task_otherexam THEN
                -- outros exames
            
                g_error := 'GET SCHEDULE OTHER EXAM REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(id_episode_origin,
                              NULL,
                              decode(flg_status_det,
                                     pk_exam_constant.g_exam_tosched,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_sched,
                                     g_scheduled,
                                     pk_exam_constant.g_exam_result,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_cancel,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_read,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_end_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_exec,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_req,
                                     g_not_scheduled,
                                     decode(flg_time, pk_exam_constant.g_flg_time_n, g_scheduled, g_not_scheduled)),
                              decode(flg_status_det,
                                     pk_exam_constant.g_exam_tosched,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_sched,
                                     g_scheduled,
                                     pk_exam_constant.g_exam_result,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_cancel,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_read,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_end_transp,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_toexec,
                                     g_not_scheduled,
                                     pk_exam_constant.g_exam_req,
                                     decode(dt_begin, NULL, g_scheduled, g_not_scheduled),
                                     pk_exam_constant.g_exam_pending,
                                     decode(dt_begin, NULL, g_scheduled, g_not_scheduled),
                                     decode(flg_time, pk_exam_constant.g_flg_time_n, g_scheduled, g_not_scheduled)))
                  INTO l_task_req_stat
                  FROM exams_ea eea
                 WHERE eea.id_exam_req_det = i_id_request;
            
            WHEN g_task_spec THEN
                -- pareceres
                l_task_req_stat := NULL;
            
            WHEN g_task_rast THEN
                -- rastreios
                l_task_req_stat := NULL;
            
            WHEN g_task_drug_ext THEN
                -- medicação : exterior
                l_task_req_stat := NULL;
            
            WHEN g_task_proc THEN
                -- procedimentos
            
                g_error := 'GET SCHEDULE PROCEDURE REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(pea.flg_time,
                              pk_alert_constant.g_flg_time_e,
                              g_not_scheduled,
                              pk_alert_constant.g_flg_time_b,
                              g_not_scheduled,
                              g_scheduled)
                  INTO l_task_req_stat
                  FROM procedures_ea pea
                 WHERE pea.id_interv_presc_det = i_id_request;
            
            ELSE
                l_task_req_stat := NULL;
        END CASE;
    
        RETURN l_task_req_stat;
    END get_task_request_schedule;

    /** 
    *  Get status of a task request
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)  
    * @param      I_TASK_TYPE                  Task Type
    *
    * @return     Type of GUIDELINE_PROCESS_TASK.FLG_STATUS_LAST
    * @author     TS
    * @version    0.1
    * @since      2007/05/22
    */
    FUNCTION get_task_request_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN guideline_process_task.task_type%TYPE,
        i_id_request IN guideline_process_task.id_request%TYPE
    ) RETURN guideline_process_task.flg_status_last%TYPE IS
        l_task_req_stat guideline_process_task.flg_status_last%TYPE;
        o_error         t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET TASK REQUEST STATUS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        CASE i_task_type
        
            WHEN g_task_analysis THEN
                -- analysis
            
                g_error := 'GET STATUS ANALYSIS REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_status,
                              pk_alert_constant.g_flg_status_f,
                              g_process_finished,
                              pk_alert_constant.g_flg_status_l,
                              g_process_finished,
                              pk_alert_constant.g_flg_status_c,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM analysis_req_det
                 WHERE id_analysis_req_det = i_id_request;
            
            WHEN g_task_appoint THEN
                -- Consultas
            
                g_error := 'GET STATUS APPOINTMENT REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- id_request equal to -1 indicates that this consult request
                -- was scheduled directly on the scheduler
                IF (i_id_request = -1)
                THEN
                    l_task_req_stat := g_process_finished;
                ELSE
                    SELECT decode(flg_status,
                                  pk_consult_req.g_consult_req_stat_sched,
                                  g_process_finished,
                                  pk_consult_req.g_consult_req_stat_proc,
                                  g_process_finished,
                                  pk_consult_req.g_consult_req_stat_cancel,
                                  g_process_closed,
                                  pk_consult_req.g_consult_req_stat_rejected,
                                  g_process_closed,
                                  g_process_running)
                      INTO l_task_req_stat
                      FROM consult_req
                     WHERE id_consult_req = i_id_request;
                END IF;
            WHEN g_task_patient_education THEN
                -- Patient education
            
                g_error := 'GET STATUS PATIENT EDUCATION REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(ntr.flg_status,
                              pk_patient_education_constant.g_nurse_tea_req_pend,
                              g_process_running,
                              pk_patient_education_constant.g_nurse_tea_req_act,
                              g_process_running,
                              pk_patient_education_constant.g_nurse_tea_req_canc,
                              g_process_closed,
                              g_process_finished)
                  INTO l_task_req_stat
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_id_request;
            
            WHEN g_task_img THEN
                -- Imagem
            
                g_error := 'GET STATUS IMAGE EXAM REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_status,
                              pk_exam_constant.g_exam_result,
                              g_process_finished,
                              pk_exam_constant.g_exam_read,
                              g_process_finished,
                              pk_exam_constant.g_exam_exec,
                              g_process_finished,
                              pk_exam_constant.g_exam_cancel,
                              g_process_closed,
                              pk_exam_constant.g_exam_nr,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM exam_req_det
                 WHERE id_exam_req_det = i_id_request;
            
            WHEN g_task_vacc THEN
                -- imunizações
                l_task_req_stat := NULL;
            
            WHEN g_task_enfint THEN
                -- Intervenções de enfermagem
            
                g_error := 'GET STATUS NURSE INTERVENTION REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_status,
                              pk_icnp_constant.g_epis_interv_status_requested,
                              g_process_running,
                              pk_icnp_constant.g_epis_interv_status_cancelled,
                              g_process_closed,
                              g_process_finished)
                  INTO l_task_req_stat
                  FROM icnp_epis_intervention
                 WHERE id_icnp_epis_interv = i_id_request;
            
            WHEN g_task_otherexam THEN
                -- outros exames
            
                g_error := 'GET STATUS OTHER EXAM REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_status,
                              pk_exam_constant.g_exam_result,
                              g_process_finished,
                              pk_exam_constant.g_exam_read,
                              g_process_finished,
                              pk_exam_constant.g_exam_exec,
                              g_process_finished,
                              pk_exam_constant.g_exam_cancel,
                              g_process_closed,
                              pk_exam_constant.g_exam_nr,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM exam_req_det
                 WHERE id_exam_req_det = i_id_request;
            
            WHEN g_task_spec THEN
                -- pareceres
            
                g_error := 'GET STATUS OPINION REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_state,
                              pk_opinion.g_opinion_reply,
                              g_process_finished,
                              pk_opinion.g_opinion_reply_read,
                              g_process_finished,
                              pk_opinion.g_opinion_cancel,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM opinion
                 WHERE id_opinion = i_id_request;
            
            WHEN g_task_rast THEN
                -- rastreios
                l_task_req_stat := NULL;
            
            WHEN g_task_proc THEN
                -- procedimentos
            
                g_error := 'GET STATUS PROCEDURE REQUEST';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                SELECT decode(flg_status_det,
                              pk_procedures_constant.g_interv_finished,
                              g_process_finished,
                              pk_procedures_constant.g_interv_interrupted,
                              g_process_finished,
                              pk_procedures_constant.g_interv_cancel,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM procedures_ea
                 WHERE id_interv_presc_det = i_id_request;
            ELSE
                l_task_req_stat := NULL;
        END CASE;
    
        RETURN l_task_req_stat;
    END get_task_request_status;

    /** 
    *  Update guideline process tasks status
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/23
    */
    FUNCTION update_guide_proc_task_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_proc_tasks_running IS
            SELECT id_guideline_process_task, task_type, id_request, dt_request, flg_status_last
              FROM guideline_process_task
             WHERE id_guideline_process = i_id_guideline_process
               AND flg_status_last = g_process_running;
    
        CURSOR c_proc_tasks_scheduled IS
            SELECT id_guideline_process_task, task_type, id_request, dt_request, flg_status_last
              FROM guideline_process_task
             WHERE id_guideline_process = i_id_guideline_process
               AND flg_status_last = g_process_scheduled;
    
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_request_status guideline_process_task.flg_status_last%TYPE;
        l_next_rec       guideline_process_task_det.dvalue%TYPE;
    
    BEGIN
        g_error := 'UPDATE STATE OF SCHEDULED GUIDELINE PROCESS TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FOR rec IN c_proc_tasks_scheduled
        LOOP
            -- get next recommendation date
            SELECT dvalue
              INTO l_next_rec
              FROM guideline_process_task_det
             WHERE flg_detail_type = g_proc_task_det_next_rec
               AND id_guideline_process_task = rec.id_guideline_process_task;
        
            IF instr(pk_alert_constant.g_date_greater || pk_alert_constant.g_date_equal,
                     pk_date_utils.compare_dates_tsz(i_prof, l_sysdate, l_next_rec)) > 0
            THEN
                -- recommnend task again
                -- update state
                UPDATE guideline_process_task
                   SET flg_status_last  = g_process_recommended,
                       dt_status_last   = l_sysdate,
                       id_professional  = i_prof.id,
                       id_cancel_reason = NULL,
                       cancel_notes     = NULL
                 WHERE id_guideline_process_task = rec.id_guideline_process_task;
            END IF;
        END LOOP;
    
        g_error := 'UPDATE STATE OF RUNNING GUIDELINE PROCESS TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FOR rec IN c_proc_tasks_running
        LOOP
        
            l_request_status := get_task_request_status(i_lang, i_prof, rec.task_type, rec.id_request);
        
            IF (l_request_status IS NOT NULL AND l_request_status != g_process_running)
            THEN
            
                -- reset task frequency
                IF l_request_status = g_process_finished
                THEN
                
                    g_error := 'RESET TASK FREQUENCY';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    IF (reset_task_frequency(i_lang, i_prof, rec.id_guideline_process_task))
                    THEN
                        l_request_status := g_process_scheduled;
                    END IF;
                
                END IF;
            
                -- update state
                UPDATE guideline_process_task
                   SET flg_status_last  = l_request_status,
                       dt_status_last   = l_sysdate,
                       id_professional  = i_prof.id,
                       id_cancel_reason = NULL,
                       cancel_notes     = NULL
                 WHERE id_guideline_process_task = rec.id_guideline_process_task;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'UPDATE_GUIDE_PROC_TASK_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END update_guide_proc_task_status;

    /** 
    *  Update guideline process status
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/22
    */
    FUNCTION update_guide_proc_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_proc_status                 guideline_process.flg_status%TYPE;
        l_dt_status_guideline_process TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'UPDATE STATE OF GUIDELINE PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- calculate the new state of guideline process
        BEGIN
            SELECT flg_status_last
              INTO l_proc_status
              FROM (SELECT guid_proc_tsk.flg_status_last
                      FROM guideline_process_task guid_proc_tsk
                     WHERE guid_proc_tsk.id_guideline_process = i_id_guideline_process
                     ORDER BY decode(guid_proc_tsk.flg_status_last,
                                     g_process_pending,
                                     g_process_pending_weight,
                                     g_process_recommended,
                                     g_process_recommended_weight,
                                     g_process_running,
                                     g_process_running_weight,
                                     g_process_finished,
                                     g_process_finished_weight,
                                     g_process_suspended,
                                     g_process_suspended_weight,
                                     g_process_canceled,
                                     g_process_canceled_weight,
                                     g_process_scheduled,
                                     g_process_scheduled_weight,
                                     g_process_closed,
                                     g_process_closed_weight,
                                     1) DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                -- An unexpected condition: an associated guideline without tasks; 
                -- Probably is a content/parameterization error
                -- The workaround is force a cancellation
                UPDATE guideline_process
                   SET flg_status = g_process_canceled, dt_status = current_timestamp
                 WHERE id_guideline_process = i_id_guideline_process
                   AND flg_status != g_process_canceled;
            
                RETURN TRUE; -- Nothing else matters
        END;
    
        -- calculate dt_status of guideline_process
        SELECT MAX(dt_status_last)
          INTO l_dt_status_guideline_process
          FROM guideline_process_task
         WHERE id_guideline_process = i_id_guideline_process;
    
        -- update state of guideline process
        UPDATE guideline_process
           SET flg_status = decode(l_proc_status, g_process_closed, g_process_canceled, l_proc_status),
               dt_status  = l_dt_status_guideline_process
         WHERE id_guideline_process = i_id_guideline_process
           AND flg_status != g_process_canceled;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'UPDATE_GUIDE_PROC_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END update_guide_proc_status;

    /** 
    *  Update all guideline processes status (including tasks)
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                Patient ID
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/25
    */
    FUNCTION update_all_guide_proc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN guideline_process.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_procs IS
            SELECT id_guideline_process
              FROM guideline_process gp
             WHERE gp.id_patient = nvl(i_id_patient, gp.id_patient)
               AND gp.flg_status != g_process_canceled;
    
        b_result BOOLEAN;
        error_undefined EXCEPTION;
    BEGIN
        g_error := 'UPDATE STATE OF GUIDELINE PROCESSES AND ASSOCIATED TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FOR rec IN c_procs
        LOOP
        
            b_result := update_guide_proc_task_status(i_lang, i_prof, rec.id_guideline_process, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            b_result := update_guide_proc_status(i_lang, i_prof, rec.id_guideline_process, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on update of the guideline status or guideline tasks status
        WHEN error_undefined THEN
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ' || o_error.err_desc,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'UPDATE_ALL_GUIDE_PROC_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'UPDATE_ALL_GUIDE_PROC_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END update_all_guide_proc_status;

    /** 
    *  Get recommended guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_VALUE                      String to search for
    * @param      I_NUM_REG                    Max number of returned results
    * @param      I_SHOW_CANCEL_GUIDES         Show canceled guidelines (Y/N)
    * @param      DT_SERVER                    Current server time    
    * @param      O_GUIDELINE_RECOMMENDED      Guideline recommended for specific user
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_recommended_guidelines
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN guideline_process.id_patient%TYPE,
        i_value                 IN VARCHAR2,
        i_num_reg               IN NUMBER,
        i_show_cancel_guides    IN VARCHAR2,
        dt_server               OUT VARCHAR2,
        o_guideline_recommended OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        b_result BOOLEAN;
        error_undefined EXCEPTION;
    BEGIN
    
        IF (i_value IS NULL)
        THEN
        
            -- update of guideline processes and associated tasks
            b_result := update_all_guide_proc_status(i_lang, i_prof, i_id_patient, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            COMMIT;
        
            -- verify if any guideline should be automatically recommended to the patient
            b_result := run_batch_internal(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_patient         => i_id_patient,
                                           i_batch_desc         => NULL,
                                           i_id_guideline       => NULL,
                                           i_flg_create_process => TRUE,
                                           o_error              => o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            COMMIT;
        
        END IF;
    
        g_error := 'GET RECOMMENDED GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_recommended FOR
            SELECT *
              FROM (SELECT guid.id_guideline,
                           gp.id_guideline_process,
                           gp.flg_status,
                           pk_date_utils.date_send_tsz(i_lang, gp.dt_status, i_prof) AS dt_status,
                           pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline, gp.flg_status) rank,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator) AS desc_pathology,
                           guid.guideline_desc AS guideline_title,
                           
                           '0' || '|' || pk_date_utils.date_send_tsz(i_lang, dt_status, i_prof) --'xxxxxxxxxxxxxx'
                           || '|' || decode(gp.flg_status, g_process_finished, g_text_icon, g_icon) || '|' ||
                           decode(pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, gp.flg_status),
                                  g_alert_icon,
                                  decode(gp.flg_status, g_process_scheduled, g_green_color, g_red_color),
                                  g_waiting_icon,
                                  g_red_color,
                                  NULL) || '|' || pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, gp.flg_status) || '|' ||
                           pk_date_utils.dt_chr_year_short_tsz(i_lang, dt_status, i_prof) AS status,
                           check_cancel_guideline_proc(i_lang, i_prof, gp.id_guideline_process) AS flg_cancel
                      FROM guideline guid, guideline_process gp
                     WHERE guid.id_guideline = gp.id_guideline
                       AND gp.id_patient = i_id_patient
                       AND (i_show_cancel_guides = g_available OR
                           (gp.flg_status != g_process_canceled AND gp.flg_status != g_process_closed AND
                           i_show_cancel_guides = g_not_available))
                       AND rownum <= nvl(i_num_reg, rownum)
                    -- search for value
                    )
             WHERE ((translate(upper(guideline_title), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
             ORDER BY decode(flg_status,
                             g_process_suspended,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline, g_process_canceled),
                             g_process_canceled,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline, g_process_canceled),
                             rank) ASC,
                      dt_status DESC;
    
        COMMIT;
    
        -- return server time as close as possible to the end of function
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        -- Error on update of guideline processes and associated tasks
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state / ' || o_error.err_desc,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_RECOMMENDED_GUIDELINES',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_recommended);
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_RECOMMENDED_GUIDELINES',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_recommended);
            -- return failure of function
            RETURN FALSE;
        
    END get_recommended_guidelines;

    /** 
    *  Change state of recommended guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel       
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION set_rec_guideline_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        i_id_action            IN action.id_action%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes         IN VARCHAR2,
        i_transaction_id       IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_status IS
            SELECT guid_proc.flg_status, act.from_state, act.to_state
              FROM guideline_process guid_proc, action act
             WHERE guid_proc.id_guideline_process = i_id_guideline_process
               AND act.id_action = decode(i_id_action, g_state_cancel_operation, act.id_action, i_id_action)
               AND act.to_state = decode(i_id_action, g_state_cancel_operation, g_cancel_guideline, act.to_state)
               AND act.from_state = guid_proc.flg_status
               AND act.subject = g_guideline_actions;
    
        CURSOR c_task_status(i_status VARCHAR2) IS
            SELECT guid_proc_tsk.id_guideline_process_task,
                   guid_proc_tsk.id_task,
                   guid_proc_tsk.task_type,
                   guid_proc_tsk.id_request,
                   guid_proc_tsk.dt_request,
                   act.from_state,
                   act.to_state
              FROM guideline_process_task guid_proc_tsk, action act
             WHERE guid_proc_tsk.id_guideline_process = i_id_guideline_process
               AND ((i_status != g_cancel_guideline AND act.to_state = i_status) OR
                   (i_status = g_cancel_guideline AND act.to_state IN (g_cancel_task, g_close_task)))
               AND guid_proc_tsk.flg_status_last = act.from_state
               AND act.subject = g_task_actions;
    
        l_rec c_status%ROWTYPE;
        error_undefined EXCEPTION;
        l_sysdate TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        b_result  BOOLEAN;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET ACTION STATES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN c_status;
    
        FETCH c_status
            INTO l_rec;
    
        IF c_status%NOTFOUND
        THEN
            CLOSE c_status;
            RAISE error_undefined;
        END IF;
    
        CLOSE c_status;
    
        g_error := 'CHANGE STATE OF GUIDELINE_PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        UPDATE guideline_process
           SET flg_status       = l_rec.to_state,
               dt_status        = current_timestamp,
               cancel_notes     = decode(i_id_action, g_state_cancel_operation, i_cancel_notes),
               id_prof_cancel   = decode(i_id_action, g_state_cancel_operation, i_prof.id),
               id_cancel_reason = decode(i_id_action, g_state_cancel_operation, i_id_cancel_reason)
         WHERE id_guideline_process = i_id_guideline_process;
    
        g_error := 'CHANGE STATE OF GUIDELINE_PROCESS_TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        FOR rec_task IN c_task_status(l_rec.to_state)
        LOOP
        
            IF (rec_task.from_state = g_process_running)
            THEN
                -- cancel task request    
                b_result := cancel_task_request(i_lang,
                                                i_prof,
                                                rec_task.task_type,
                                                rec_task.id_request,
                                                i_id_episode,
                                                i_id_cancel_reason,
                                                i_cancel_notes,
                                                l_transaction_id,
                                                o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            END IF;
        
            UPDATE guideline_process_task
               SET flg_status_last  = rec_task.to_state,
                   dt_status_last   = l_sysdate,
                   id_professional  = i_prof.id,
                   id_cancel_reason = i_id_cancel_reason,
                   cancel_notes     = i_cancel_notes
             WHERE id_guideline_process_task = rec_task.id_guideline_process_task;
        
        END LOOP;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on cancel guideline task
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state / ' || o_error.err_desc,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_REC_GUIDELINE_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_REC_GUIDELINE_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_rec_guideline_status;

    /** 
    *  Cancel recommended guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel         
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION cancel_rec_guideline
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes         IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        error_undefined EXCEPTION;
        b_result BOOLEAN;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'CANCEL REC GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        b_result := set_rec_guideline_status(i_lang,
                                             i_prof,
                                             i_id_guideline_process,
                                             g_state_cancel_operation,
                                             i_id_episode,
                                             i_id_cancel_reason,
                                             i_cancel_notes,
                                             l_transaction_id,
                                             o_error);
    
        IF (NOT b_result)
        THEN
            RAISE error_undefined;
        END IF;
    
        COMMIT;
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        -- Error on set status of guideline
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Error on changing state to cancelled',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_REC_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_REC_GUIDELINE',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END cancel_rec_guideline;

    /********************************************************************************************
    *  Get all frequent guidelines
    *
    * @param      I_LANG                 Preferred language ID for this professional
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT           Patient ID
    * @param      I_ID_EPISODE           Episode ID   
    * @param      i_flg_filter                guidelines filter   
    * @param      I_VALUE                Value to search for        
    * @param      o_guideline_frequent        guidelines cursor
    * @param      O_ERROR                error
    *
    * @value      i_flg_filter                {*} 'C' filtered by chief complaint
    *                                         {*} 'S' filtered by i_prof specialty 
    *                                         {*} 'F' all frequent guidelines
    * 
    * @return     boolean                     true or false on success or error
    *
    * @author     Tiago Silva
    * @since      18-May-2007
    ********************************************************************************************/
    FUNCTION get_guideline_frequent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN guideline_process.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_filter         IN VARCHAR2,
        i_value              IN VARCHAR2,
        o_guideline_frequent OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
        l_id_complaint table_number;
        l_exception EXCEPTION;
        l_filter VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CHIEF COMPLAINT FOR EPISODE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_filter := i_flg_filter; -- staring mode for l_filter condition
        IF i_flg_filter = g_guide_filter_chief_compl
        THEN
            IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_id_episode,
                                                       o_id_complaint => l_id_complaint,
                                                       o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
            -- if no complaint was associated with the patient, then show all frequent guidelines
            IF l_id_complaint IS NULL
            THEN
                l_filter := g_guide_filter_frequent;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_frequent FOR
            SELECT id_guideline,
                   guide_title,
                   rank,
                   check_history_guideline(id_guideline, i_id_patient) AS flg_already_recommended
              FROM (SELECT DISTINCT (guid.id_guideline),
                                    guid.guideline_desc AS guide_title,
                                    nvl((SELECT gf.rank
                                          FROM guideline_frequent gf
                                         WHERE gf.id_institution = i_prof.institution
                                           AND gf.id_software IN (g_all_software, i_prof.software)
                                           AND gf.id_guideline = guid.id_guideline),
                                        -1) AS rank
                      FROM guideline          guid,
                           guideline_link     guid_lnk,
                           guideline_link     guid_lnk2,
                           guideline_criteria guid_crit_exc,
                           guideline_criteria guid_crit_inc
                     WHERE guid.flg_status = g_guideline_finished
                       AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                    column_value
                                                     FROM TABLE(l_institutions) inst)
                       AND ( -- guidelines edited by the professional
                            EXISTS (SELECT 1
                                      FROM guideline edit_guide
                                     WHERE edit_guide.id_professional = i_prof.id
                                       AND rownum = 1
                                     START WITH edit_guide.id_guideline = guid.id_guideline
                                    CONNECT BY PRIOR edit_guide.id_guideline = edit_guide.id_guideline_previous_version) OR
                           -- guidelines as most frequent
                            EXISTS (SELECT 1
                                      FROM guideline_frequent gft
                                     WHERE gft.id_institution = i_prof.institution
                                       AND gft.id_software IN (g_all_software, i_prof.software)
                                       AND gft.id_guideline = guid.id_guideline))
                          -- professional category
                       AND guid_lnk.id_guideline = guid.id_guideline
                       AND guid_lnk.link_type = g_guide_link_prof
                       AND guid_lnk.id_link = (SELECT pc.id_category
                                                 FROM prof_cat pc
                                                WHERE pc.id_professional = i_prof.id
                                                  AND pc.id_institution = i_prof.institution)
                          -- specialty or chief complaint
                       AND guid_lnk2.id_guideline = guid.id_guideline
                       AND guid_lnk2.link_type IN (g_guide_link_spec, g_guide_link_chief_complaint)
                       AND ((guid_lnk2.id_link IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    *
                                                     FROM TABLE(l_id_complaint) t) AND
                           l_filter = g_guide_filter_chief_compl) OR
                           (guid_lnk2.id_link = decode(i_prof.software,
                                                        pk_alert_constant.g_soft_primary_care,
                                                        (SELECT cs.id_clinical_service
                                                           FROM dep_clin_serv dcs, clinical_service cs, epis_info ei
                                                          WHERE dcs.id_dep_clin_serv = ei.id_dcs_requested
                                                            AND cs.id_clinical_service = dcs.id_clinical_service
                                                            AND ei.id_episode = i_id_episode),
                                                        (SELECT id_speciality
                                                           FROM professional
                                                          WHERE id_professional = i_prof.id)) AND
                           l_filter = g_guide_filter_specialty) OR
                           (guid_lnk2.id_link = guid_lnk2.id_link AND
                           l_filter NOT IN (g_guide_link_spec, g_guide_link_chief_complaint)))
                          -- department/environment
                       AND i_prof.software IN (SELECT sd.id_software
                                                 FROM software_dept sd, guideline_link guid_lnk3
                                                WHERE guid_lnk3.id_guideline = guid.id_guideline
                                                  AND guid_lnk3.link_type = g_guide_link_envi
                                                  AND guid_lnk3.id_link = sd.id_dept)
                          -- search for value
                       AND ((translate(upper(guid.guideline_desc),
                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                       'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           i_value IS NOT NULL) OR i_value IS NULL)
                          -- check patient gender                                         
                       AND guid_crit_inc.id_guideline = guid.id_guideline
                       AND guid_crit_inc.criteria_type = g_criteria_type_inc
                       AND nvl(guid_crit_inc.gender, l_pat_gender) = l_pat_gender
                       AND guid_crit_exc.id_guideline = guid.id_guideline
                       AND guid_crit_exc.criteria_type = g_criteria_type_exc
                       AND ((l_pat_gender != guid_crit_exc.gender AND guid_crit_exc.gender IS NOT NULL) OR
                           guid_crit_exc.gender IS NULL))
             ORDER BY rank, upper(guide_title);
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_FREQUENT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_frequent);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_frequent;

    /**
    *  Verify if a guideline task is available for the software, institution and professional
    *
    * @param      I_LANG             Prefered language ID for this professional
    * @param      I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE        Type of the task
    * @param      I_ID_TASK          Task ID
    * @param      I_ID_TASK_ATTACH   Auxiliary ID associated to the task
    * @param      I_TASK_CODIFICATION   Codification ID associated to the task    
    * @param      i_id_episode       ID of the current episode
    *
    * @return     VARCHAR2 (Y - available / N - not available)
    * @author     TS
    * @version    0.2
    * @since      2007/11/05
    */
    FUNCTION get_task_avail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_id_task           IN guideline_task_link.id_task_link%TYPE,
        i_id_task_attach    IN guideline_task_link.id_task_attach%TYPE,
        i_task_codification IN guideline_task_link.task_codification%TYPE,
        i_id_episode        IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_count_results      PLS_INTEGER;
        l_opt_func_id        prof_func.id_functionality%TYPE;
        l_prof_cat           category.flg_type%TYPE;
        l_flg_conflict       VARCHAR2(1 CHAR);
        l_aux_flg_reason_msg VARCHAR2(1 CHAR);
        l_id_patient         patient.id_patient%TYPE := pk_episode.get_id_patient(i_id_episode);
    
        l_available VARCHAR2(1 CHAR);
        l_area_code ehr_access_area_def.area%TYPE;
        l_error     t_error_out;
        e_unexpected_exception EXCEPTION;
    
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
    
        g_error := 'VERIFY IF TASK IS AVAILABLE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- verify if the task type is available for this software and institution
        IF (check_task_type_soft_inst(i_lang, i_prof, i_task_type) = g_not_available)
        THEN
            RETURN g_not_available;
        END IF;
    
        -- ALERT-18697
        -- check if task is available for execution if patient is inactive, or active but in scheduling or in an EHR event
        g_error := 'CALL CHECK_AREA_CREATE_PERMISSION';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        CASE i_task_type
            WHEN g_task_analysis THEN
                l_area_code := 'LAB'; -- task type: lab test
            WHEN g_task_proc THEN
                l_area_code := 'PROC'; -- task type: procedure
            WHEN g_task_img THEN
                l_area_code := 'IMEXAM'; -- task type: imaging exam    
            WHEN g_task_drug THEN
                l_area_code := 'MED'; -- task type: on-site medication
            WHEN g_task_otherexam THEN
                l_area_code := 'OEXAM'; -- task type: other exam    
            WHEN g_task_spec THEN
                l_area_code := 'CONSULT'; -- task type: consult
            ELSE
                l_area_code := NULL; -- not an elegible task to block, according to ALERT-18697 conditions
        END CASE;
    
        IF l_area_code IS NOT NULL -- check if task can be executed, according to ALERT-18697 conditions
        THEN
            IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode,
                                                              i_area    => l_area_code,
                                                              o_val     => l_available,
                                                              o_error   => l_error)
            THEN
                RAISE e_unexpected_exception;
            END IF;
        
            IF l_available = g_no
            THEN
                RETURN g_not_available;
            END IF;
        END IF;
    
        -- if is an appointment, but not the follow-up one (i.e. specialty appointment)
        -- proceed to the specialty appointments filter
        IF (i_task_type = g_task_appoint AND i_id_task != '-1')
        THEN
            -- filter to enable/disable specialty appointments, even if follow-up appointments are enabled
            SELECT COUNT(1)
              INTO l_count_results
              FROM (SELECT item,
                           first_value(gisi.flg_available) over(PARTITION BY gisi.item, gisi.flg_item_type ORDER BY gisi.id_market DESC, gisi.id_institution DESC, gisi.id_software DESC, gisi.flg_available) AS flg_avail
                      FROM guideline_item_soft_inst gisi
                     WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                       AND gisi.id_software IN (g_all_software, i_prof.software)
                       AND gisi.id_market IN (g_all_markets, l_market)
                       AND flg_item_type = g_guideline_item_tasks
                       AND item IN (g_task_appoint, g_task_specialty_appointment))
             WHERE (item = g_task_specialty_appointment AND flg_avail = g_not_available)
                OR (item = g_task_appoint AND flg_avail = g_not_available);
        
            -- check result
            IF (l_count_results != 0)
            THEN
                RETURN g_not_available;
            END IF;
        END IF;
    
        -- verify if the specific task is available  
        CASE i_task_type
        
            WHEN g_task_analysis THEN
                -- analysis
                IF NOT pk_lab_tests_external_api_db.check_lab_test_conflict(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_patient        => l_id_patient,
                                                                            i_episode        => i_id_episode,
                                                                            i_analysis       => to_number(i_id_task),
                                                                            i_analysis_group => NULL,
                                                                            o_flg_reason_msg => l_aux_flg_reason_msg,
                                                                            o_flg_conflict   => l_flg_conflict,
                                                                            o_error          => l_error)
                THEN
                    RAISE e_unexpected_exception;
                END IF;
            
                -- if analysis is already requested it is not considered has conflict
                IF (l_flg_conflict = g_yes AND l_aux_flg_reason_msg != 3)
                THEN
                    l_count_results := 0;
                ELSE
                    l_count_results := 1;
                END IF;
            
            WHEN g_task_appoint THEN
                -- Consultas
                SELECT COUNT(id_dep_clin_serv)
                  INTO l_count_results
                  FROM (SELECT -1 id_dep_clin_serv
                          FROM dual
                         WHERE i_id_task = '-1'
                        UNION ALL
                        SELECT dcs.id_dep_clin_serv
                          FROM department dep, dep_clin_serv dcs, clinical_service cs
                         WHERE dep.id_institution = i_prof.institution
                           AND instr(dep.flg_type, g_external_appoint) > 0
                           AND dcs.id_department = dep.id_department
                           AND cs.id_clinical_service = dcs.id_clinical_service
                           AND dcs.flg_available = g_available
                           AND EXISTS
                         (SELECT 1
                                  FROM professional prf, prof_dep_clin_serv pdcs, prof_func pf
                                 WHERE prf.flg_state = g_prof_active
                                   AND pdcs.id_professional = prf.id_professional
                                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                   AND pdcs.flg_status = g_selectedpt
                                   AND pf.id_professional = prf.id_professional
                                   AND pf.id_functionality = pk_sysconfig.get_config(g_config_func_consult_req, i_prof)
                                   AND pf.id_institution = i_prof.institution)
                           AND dcs.id_dep_clin_serv = to_number(i_id_task));
            
            WHEN g_task_patient_education THEN
                -- Patient education
                -- if we are working with the new patient education tasks, then validate task's availability
                IF i_id_task IS NOT NULL
                THEN
                    IF NOT pk_patient_education_api_db.check_nurse_teach_conflict(i_lang            => i_lang,
                                                                                  i_prof            => i_prof,
                                                                                  i_patient         => l_id_patient,
                                                                                  i_episode         => i_id_episode,
                                                                                  i_nurse_tea_topic => i_id_task,
                                                                                  o_flg_conflict    => l_flg_conflict,
                                                                                  o_error           => l_error)
                    THEN
                        RAISE e_unexpected_exception;
                    END IF;
                END IF;
            
                -- decode result (if we are working with the old patient education tasks, the i_id_task is null and we cannot work with them)
                IF i_id_task IS NULL
                   OR l_flg_conflict = pk_alert_constant.g_yes
                THEN
                    l_count_results := 0;
                ELSE
                    l_count_results := 1;
                END IF;
            
            WHEN g_task_img THEN
                -- Imagem
                IF NOT pk_exams_external_api_db.check_exam_conflict(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_patient      => l_id_patient,
                                                                    i_exam         => to_number(i_id_task),
                                                                    o_flg_conflict => l_flg_conflict,
                                                                    o_error        => l_error)
                THEN
                    RAISE e_unexpected_exception;
                
                END IF;
            
                -- decode result
                IF l_flg_conflict = pk_alert_constant.g_yes
                THEN
                    l_count_results := 0;
                ELSE
                    l_count_results := 1;
                END IF;
            
            WHEN g_task_vacc THEN
                -- imunizações
                -- is always available
                l_count_results := 1;
            
            WHEN g_task_enfint THEN
                -- Intervenções de enfermagem
                SELECT COUNT(id_composition)
                  INTO l_count_results
                  FROM dep_clin_serv dcs, department dep, dept, software_dept soft_dep, icnp_compo_dcs ic_dep
                 WHERE dep.id_department = dcs.id_department
                   AND dep.id_institution = i_prof.institution
                   AND dept.id_dept = dep.id_dept
                   AND soft_dep.id_dept = dept.id_dept
                   AND soft_dep.id_software = i_prof.software
                   AND ic_dep.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.flg_available = g_available
                   AND dep.flg_available = g_available
                   AND dept.flg_available = g_available
                   AND ic_dep.id_composition = to_number(i_id_task);
            
            WHEN g_task_otherexam THEN
                -- outros exames
                IF NOT pk_exams_external_api_db.check_exam_conflict(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_patient      => l_id_patient,
                                                                    i_exam         => to_number(i_id_task),
                                                                    o_flg_conflict => l_flg_conflict,
                                                                    o_error        => l_error)
                THEN
                    RAISE e_unexpected_exception;
                
                END IF;
            
                -- decode result
                IF l_flg_conflict = pk_alert_constant.g_yes
                THEN
                    l_count_results := 0;
                ELSE
                    l_count_results := 1;
                END IF;
            
            WHEN g_task_spec THEN
                -- pareceres
                l_opt_func_id := pk_sysconfig.get_config(g_config_func_opinion, i_prof);
            
                -- get professional category
                SELECT c.flg_type
                  INTO l_prof_cat
                  FROM prof_cat pc, category c
                 WHERE pc.id_category = c.id_category
                   AND pc.id_institution = i_prof.institution
                   AND pc.id_professional = i_prof.id;
            
                SELECT COUNT(p.id_professional)
                  INTO l_count_results
                  FROM professional p, prof_func pf, prof_soft_inst psi, prof_cat pc, category c
                 WHERE p.id_professional != i_prof.id
                   AND (i_id_task_attach = -1 OR (i_id_task_attach != -1 AND p.id_professional = i_id_task_attach))
                   AND p.id_speciality = to_number(i_id_task)
                   AND p.flg_state = g_prof_active
                   AND pf.id_professional = p.id_professional
                   AND pf.id_institution = i_prof.institution
                   AND pf.id_functionality = l_opt_func_id
                   AND psi.id_professional = p.id_professional
                   AND psi.id_institution = i_prof.institution
                   AND p.id_professional = pc.id_professional
                   AND pc.id_category = c.id_category
                   AND pc.id_institution = i_prof.institution
                   AND c.flg_type = l_prof_cat;
            
            WHEN g_task_rast THEN
                -- rastreios
                -- is always available
                l_count_results := 1;
            
            WHEN g_task_proc THEN
                -- procedimentos
                SELECT COUNT(id_intervention)
                  INTO l_count_results
                  FROM interv_dep_clin_serv
                 WHERE flg_type = g_proc_request
                   AND id_software = i_prof.software
                   AND id_institution = i_prof.institution
                   AND id_intervention = to_number(i_id_task);
            ELSE
                l_count_results := 0;
        END CASE;
    
        -- check result
        IF (l_count_results = 0)
        THEN
            RETURN g_not_available;
        ELSE
            RETURN g_available;
        END IF;
    END get_task_avail;

    /** 
    *  Get guideline tasks recommended
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       ID of guideline process
    * @param      i_id_episode                 ID of the current episode
    * @param      DT_SERVER                    Current server time    
    * @param      O_GUIDELINE_RECOMMENDED      Guideline recommended for specific user
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_recommended_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN table_number,
        i_id_episode           IN episode.id_episode%TYPE,
        dt_server              OUT VARCHAR2,
        o_task_recommended     OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient guideline_process.id_patient%TYPE;
    BEGIN
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT id_patient
          INTO l_id_patient
          FROM guideline_process
         WHERE id_guideline_process = i_id_guideline_process(1);
    
        g_error := 'GET RECOMMENDED GUIDELINE TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_task_recommended FOR
            SELECT /*+opt_estimate(table guid_proc_list rows=1)*/
             id_guideline_process,
             id_guideline_process_task,
             task_type,
             decode(task_type,
                    g_task_patient_education,
                    CASE guid_proc_tsk.id_task
                        WHEN '-1' THEN
                         guid_proc_tsk.task_notes
                        ELSE
                         pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang, i_prof, guid_proc_tsk.id_task)
                    END,
                    g_task_spec,
                    get_task_id_desc(i_lang, i_prof, id_task, task_type, task_codification) ||
                    decode(id_task_attach,
                           '-1', -- physician = <any>
                           '',
                           nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach),
                                ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach) || ')',
                                NULL)),
                    get_task_id_desc(i_lang, i_prof, id_task, task_type, task_codification)) || ' - ' ||
             pk_sysdomain.get_domain(g_domain_task_type, task_type, i_lang) AS str_desc, -- TODO: to be discontinued
             flg_status_last AS flg_status,
             pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline_task, flg_status_last) rank,
             
             '0' || '|' ||
             pk_date_utils.date_send_tsz(i_lang,
                                         decode(flg_status_last,
                                                g_process_scheduled,
                                                (SELECT dvalue
                                                   FROM guideline_process_task_det guid_proc_task_det
                                                  WHERE guid_proc_task_det.id_guideline_process_task =
                                                        guid_proc_tsk.id_guideline_process_task
                                                    AND guid_proc_task_det.flg_detail_type = g_proc_task_det_next_rec),
                                                g_process_running,
                                                dt_request,
                                                dt_status_last),
                                         i_prof) --'xxxxxxxxxxxxxx'
             || '|' ||
             decode(flg_status_last,
                    g_process_running,
                    decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request), g_scheduled, g_text, g_date),
                    g_process_scheduled,
                    g_text_icon,
                    g_process_finished,
                    g_text_icon,
                    g_icon) || '|' ||
             decode(pk_sysdomain.get_img(i_lang, g_domain_flg_guideline_task, flg_status_last),
                    g_alert_icon,
                    decode(flg_status_last, g_process_scheduled, g_green_color, g_red_color),
                    g_waiting_icon,
                    g_red_color,
                    decode(flg_status_last,
                           g_process_running,
                           decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                                  g_scheduled,
                                  g_green_color,
                                  NULL),
                           NULL)) || '|' ||
             decode(flg_status_last,
                    g_process_running,
                    decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                           g_scheduled,
                           pk_message.get_message(i_lang, g_message_scheduled),
                           NULL),
                    pk_sysdomain.get_img(i_lang, g_domain_flg_guideline_task, flg_status_last)) || '|' ||
             decode(flg_status_last,
                    g_process_scheduled,
                    pk_date_utils.get_elapsed_tsz_years(i_lang,
                                                        (SELECT dvalue
                                                           FROM guideline_process_task_det guid_proc_task_det
                                                          WHERE guid_proc_task_det.id_guideline_process_task =
                                                                guid_proc_tsk.id_guideline_process_task
                                                            AND guid_proc_task_det.flg_detail_type =
                                                                g_proc_task_det_next_rec)),
                    pk_date_utils.dt_chr_year_short_tsz(i_lang,
                                                        decode(flg_status_last,
                                                               g_process_running,
                                                               dt_request,
                                                               dt_status_last),
                                                        i_prof)) AS status,
             (CASE
              -- special case for image exam tasks
                  WHEN task_type = g_task_img
                       AND
                      -- if patient doesn't have a pregnancy process he can't request an image exam related with pregnancy
                       NOT EXISTS
                   (SELECT g_not_available
                          FROM dual
                         WHERE NOT EXISTS (SELECT 1
                                  FROM pat_pregnancy pp
                                 WHERE pp.id_patient = l_id_patient
                                   AND pp.flg_status = g_pregnancy_process_active)
                           AND EXISTS (SELECT 1
                                  FROM exam_type_group etg, exam_type et
                                 WHERE etg.id_software IN (i_prof.software, g_all_software)
                                   AND etg.id_institution IN (i_prof.institution, g_all_institution)
                                   AND et.flg_type = g_exam_pregnant_ultrasound
                                   AND et.id_exam_type = etg.id_exam_type
                                   AND etg.id_exam = safe_to_number(id_task)))
                       AND
                       get_task_avail(i_lang, i_prof, task_type, id_task, id_task_attach, task_codification, i_id_episode) =
                       g_available THEN
                   g_available
              -- if the task is not executed yet, check task permissions and availability
                  WHEN task_type != g_task_img
                       AND flg_status_last IN (g_process_pending, g_process_recommended, g_process_suspended)
                       AND check_task_type_permissions(i_lang, i_prof, task_type) = g_available
                       AND
                       get_task_avail(i_lang, i_prof, task_type, id_task, id_task_attach, task_codification, i_id_episode) =
                       g_available THEN
                  
                   g_available
              -- if the task is ongoing, check just check task availability
                  WHEN task_type != g_task_img
                       AND flg_status_last NOT IN (g_process_pending, g_process_recommended)
                       AND check_task_type_permissions(i_lang, i_prof, task_type) = g_available THEN
                   g_available
                  ELSE
                   g_not_available
              END) AS flg_avail,
             pk_sysdomain.get_domain(g_domain_task_type, task_type, i_lang) AS task_type_desc,
             decode(task_type,
                    g_task_patient_education,
                    CASE guid_proc_tsk.id_task
                        WHEN '-1' THEN
                         guid_proc_tsk.task_notes
                        ELSE
                         pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang, i_prof, guid_proc_tsk.id_task)
                    END,
                    g_task_spec,
                    get_task_id_desc(i_lang, i_prof, id_task, task_type, task_codification) ||
                    decode(id_task_attach,
                           '-1', -- physician = <any>
                           '',
                           nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach),
                                ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach) || ')',
                                NULL)),
                    get_task_id_desc(i_lang, i_prof, id_task, task_type, task_codification)) AS task_desc
            
              FROM guideline_process_task guid_proc_tsk, TABLE(i_id_guideline_process) guid_proc_list
             WHERE guid_proc_tsk.id_guideline_process = guid_proc_list.column_value
             ORDER BY decode(flg_status_last,
                             g_process_suspended,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline_task, g_process_canceled),
                             g_process_closed,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline_task, g_process_canceled),
                             rank) ASC,
                      decode(flg_status_last, g_process_running, dt_request, NULL) ASC,
                      decode(flg_status_last, g_process_pending, str_desc, g_process_recommended, str_desc, NULL) ASC,
                      decode(flg_status_last,
                             g_process_finished,
                             dt_status_last,
                             g_process_suspended,
                             dt_status_last,
                             g_process_canceled,
                             dt_status_last,
                             g_process_closed,
                             dt_status_last,
                             NULL) DESC;
    
        -- return server time as close as possible to the end of function
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_RECOMMENDED_TASKS',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_task_recommended);
            -- return failure of function
            RETURN FALSE;
        
    END get_recommended_tasks;

    /** 
    *  Get guideline tasks recommended details
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_GUIDELINE_PROCESS_TASK  ID da tarefa
    * @param      I_ID_EPISODE                 Episode ID     
    * @param      O_TASK_REC_DETAIL            Detail information for specific task
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/04/13
    */
    FUNCTION get_rec_task_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_task_type                 IN guideline_process_task.task_type%TYPE,
        i_id_guideline_process_task IN table_number,
        i_id_episode                IN episode.id_episode%TYPE,
        o_task_rec_detail           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET RECOMMENDED GUIDELINE TASK DETAIL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF (i_task_type = g_task_analysis)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 anl.id_analysis,
                 pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', anl.code_analysis, NULL) AS analysis_desc,
                 guid_proc_tsk.task_notes,
                 nvl(ais.flg_harvest, g_yes) flg_col_inst,
                 guid_proc_tsk.task_codification AS id_codification
                  FROM analysis_instit_soft ais,
                       analysis anl,
                       guideline_process_task guid_proc_tsk,
                       TABLE(i_id_guideline_process_task) gpt
                 WHERE anl.id_analysis = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value
                   AND ais.id_institution = i_prof.institution
                   AND ais.id_software = i_prof.software
                   AND ais.id_analysis = anl.id_analysis
                   AND ais.flg_available = g_available
                   AND ais.flg_type IN (pk_alert_constant.g_analysis_request, pk_alert_constant.g_analysis_exec);
        
        ELSIF (i_task_type = g_task_appoint)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 decode(guid_proc_tsk.id_task, '-1', -1, appoint.id_dep_clin_serv) AS id_dep_clin_serv,
                 decode(guid_proc_tsk.id_task,
                        '-1',
                        pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                        pk_translation.get_translation(i_lang, appoint.code_clinical_service)) AS desc_appoint,
                 guid_proc_tsk.task_notes
                  FROM (SELECT dcs.id_dep_clin_serv, cs.id_clinical_service, cs.code_clinical_service
                          FROM dep_clin_serv dcs, clinical_service cs
                         WHERE cs.id_clinical_service = dcs.id_clinical_service) appoint,
                       guideline_process_task guid_proc_tsk,
                       TABLE(i_id_guideline_process_task) gpt
                 WHERE appoint.id_dep_clin_serv(+) = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value;
        
        ELSIF (i_task_type = g_task_patient_education)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value AS id_guideline_process_task,
                 nts.id_nurse_tea_subject AS id_subject,
                 pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) AS desc_subject,
                 ntt.id_nurse_tea_topic AS id_topic,
                 pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) AS title_topic,
                 pk_translation.get_translation(i_lang, ntt.code_topic_description) AS desc_topic,
                 guid_proc_tsk.task_notes AS notes
                  FROM TABLE(i_id_guideline_process_task) gpt
                 INNER JOIN guideline_process_task guid_proc_tsk
                    ON gpt.column_value = guid_proc_tsk.id_guideline_process_task
                 INNER JOIN nurse_tea_topic ntt
                    ON ntt.id_nurse_tea_topic = safe_to_number(guid_proc_tsk.id_task)
                 INNER JOIN nurse_tea_subject nts
                    ON ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject;
        
        ELSIF (i_task_type = g_task_img)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 ex.id_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam) AS desc_image_exams,
                 guid_proc_tsk.task_notes,
                 decode(type_exam.id_exam, NULL, g_not_available, g_available) flg_preg_ultrasound,
                 guid_proc_tsk.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'E', ex.id_exam) flg_laterality_mcdt
                  FROM exam ex,
                       guideline_process_task guid_proc_tsk,
                       TABLE(i_id_guideline_process_task) gpt,
                       (SELECT etg.id_exam
                          FROM exam_type_group etg, exam_type et
                         WHERE etg.id_software IN (i_prof.software, g_all_software)
                           AND etg.id_institution IN (i_prof.institution, g_all_institution)
                           AND et.flg_type = g_exam_pregnant_ultrasound
                           AND et.id_exam_type = etg.id_exam_type) type_exam
                 WHERE ex.id_exam = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value
                   AND ex.flg_type = g_exam_only_img
                   AND type_exam.id_exam(+) = ex.id_exam;
        
        ELSIF (i_task_type = g_task_vacc)
        THEN
            pk_types.open_my_cursor(o_task_rec_detail);
        ELSIF (i_task_type = g_task_enfint)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 enfint.id_composition,
                 pk_translation.get_translation(i_lang, enfint.code_icnp_composition) AS desc_enfint,
                 guid_proc_tsk.task_notes
                  FROM icnp_composition enfint,
                       guideline_process_task guid_proc_tsk,
                       TABLE(i_id_guideline_process_task) gpt
                 WHERE enfint.id_composition = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value;
        
        ELSIF (i_task_type = g_task_otherexam)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 id_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam) AS desc_other_exams,
                 guid_proc_tsk.task_notes,
                 guid_proc_tsk.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'E', ex.id_exam) flg_laterality_mcdt
                  FROM exam ex, guideline_process_task guid_proc_tsk, TABLE(i_id_guideline_process_task) gpt
                 WHERE ex.id_exam = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value
                   AND ex.flg_type != g_exam_only_img;
        
        ELSIF (i_task_type = g_task_spec)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 id_speciality,
                 pk_translation.get_translation(i_lang, spec.code_speciality) AS desc_specialty,
                 guid_proc_tsk.task_notes,
                 guid_proc_tsk.id_task_attach
                  FROM speciality spec, guideline_process_task guid_proc_tsk, TABLE(i_id_guideline_process_task) gpt
                 WHERE spec.id_speciality = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value;
        
        ELSIF (i_task_type = g_task_rast)
        THEN
            pk_types.open_my_cursor(o_task_rec_detail);
        
        ELSIF (i_task_type = g_task_proc)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_guideline_process_task,
                 id_intervention AS id_procedure,
                 pk_procedures_api_db.get_alias_translation(i_lang, i_prof, interv.code_intervention, NULL) AS desc_procedure,
                 guid_proc_tsk.task_notes,
                 guid_proc_tsk.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', id_intervention) flg_laterality_mcdt
                  FROM intervention interv,
                       guideline_process_task guid_proc_tsk,
                       TABLE(i_id_guideline_process_task) gpt
                 WHERE interv.id_intervention = safe_to_number(guid_proc_tsk.id_task)
                   AND guid_proc_tsk.id_guideline_process_task = gpt.column_value;
        ELSE
            pk_types.open_my_cursor(o_task_rec_detail);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_REC_TASK_DETAIL',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_task_rec_detail);
            -- return failure of function
            RETURN FALSE;
        
    END get_rec_task_detail;

    /**
    *  Calculates the next recommendation date for a guideline task
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS_TASK  Guideline process task ID
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/11/06
    */
    FUNCTION reset_task_frequency
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE
    ) RETURN BOOLEAN IS
        l_freq_detail guideline_process_task_det.vvalue%TYPE;
        l_sysdate     TIMESTAMP WITH TIME ZONE := current_timestamp;
    BEGIN
    
        g_error := 'GET TASK FREQUENCY';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- get task frequency
        SELECT vvalue
          INTO l_freq_detail
          FROM guideline_process_task_det
         WHERE id_guideline_process_task = i_id_guideline_process_task
           AND flg_detail_type = g_proc_task_det_freq;
    
        g_error := 'UPDATE REC TASK DATE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- update recommendation date
        UPDATE guideline_process_task_det
           SET dvalue = pk_date_utils.add_to_ltstz(l_sysdate,
                                                   to_number(substr(l_freq_detail, 1, length(l_freq_detail) - 1)),
                                                   decode(substr(l_freq_detail, -1, 1),
                                                          'D',
                                                          'DAY',
                                                          'M',
                                                          'MONTH',
                                                          'Y',
                                                          'YEAR'))
         WHERE flg_detail_type = g_proc_task_det_next_rec
           AND id_guideline_process_task = i_id_guideline_process_task;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'TASK WITHOUT FREQUENCY';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            RETURN FALSE;
    END reset_task_frequency;

    /** 
    *  Change state of recommended tasks for a guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS_TASK Guideline process ID
    * @param      I_ID_ACTION                 Action ID 
    * @param      I_ID_REQUEST                Request ID
    * @param      I_DT_REQUEST                Date of request
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel   
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/03/29
    */
    FUNCTION set_rec_task_status
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN table_number,
        i_id_action                 IN table_number,
        i_id_request                IN table_number,
        i_dt_request                IN VARCHAR2,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        i_transaction_id            IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_status
        (
            c_id_guideline_process_task guideline_process_task.id_guideline_process_task%TYPE,
            c_id_action                 action.id_action%TYPE
        ) IS
            SELECT guid_proc_tsk.id_guideline_process_task,
                   guid_proc_tsk.id_guideline_process,
                   guid_proc_tsk.flg_status_last,
                   guid_proc_tsk.id_request,
                   guid_proc_tsk.dt_request,
                   guid_proc_tsk.task_type,
                   act.from_state,
                   act.to_state
              FROM guideline_process_task guid_proc_tsk, action act
             WHERE guid_proc_tsk.id_guideline_process_task = c_id_guideline_process_task
               AND act.id_action = decode(c_id_action, g_state_cancel_operation, act.id_action, c_id_action)
               AND (c_id_action != g_state_cancel_operation OR
                   (c_id_action = g_state_cancel_operation AND act.to_state IN (g_cancel_task, g_close_task)))
               AND act.from_state = guid_proc_tsk.flg_status_last
               AND act.subject = g_task_actions;
    
        l_rec            c_status%ROWTYPE;
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        b_result         BOOLEAN;
        l_request_status guideline_process_task.flg_status_last%TYPE;
        error_undefined   EXCEPTION;
        error_id_req_null EXCEPTION;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        IF i_id_guideline_process_task.count != 0
        THEN
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            FOR i IN i_id_guideline_process_task.first .. i_id_guideline_process_task.last
            LOOP
                g_error := 'GET ACTION STATES';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                OPEN c_status(i_id_guideline_process_task(i), i_id_action(i));
                FETCH c_status
                    INTO l_rec;
            
                IF c_status%NOTFOUND
                THEN
                    CLOSE c_status;
                    RAISE error_undefined;
                END IF;
            
                CLOSE c_status;
            
                IF (l_rec.from_state = g_process_running)
                THEN
                    g_error := 'CANCEL TASK REQUEST';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    b_result := cancel_task_request(i_lang,
                                                    i_prof,
                                                    l_rec.task_type,
                                                    l_rec.id_request,
                                                    i_id_episode,
                                                    i_id_cancel_reason,
                                                    i_cancel_notes,
                                                    l_transaction_id,
                                                    o_error);
                
                    IF (NOT b_result)
                    THEN
                        RAISE error_undefined;
                    END IF;
                END IF;
            
                -- reset task frequency
                l_request_status := NULL;
                IF l_rec.to_state = g_process_finished
                THEN
                
                    g_error := 'RESET TASK FREQUENCY';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    IF (reset_task_frequency(i_lang, i_prof, l_rec.id_guideline_process_task))
                    THEN
                        l_request_status := g_process_scheduled;
                    END IF;
                
                END IF;
            
                g_error := 'VERIFY IF REQUEST ID SHOULD BE NULL';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                IF (l_rec.to_state = g_process_running AND i_id_request(i) IS NULL)
                THEN
                    RAISE error_id_req_null;
                END IF;
            
                g_error := 'CHANGE STATE OF GUIDELINE_PROCESS TASK';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                UPDATE guideline_process_task
                   SET flg_status_last  = nvl(l_request_status, l_rec.to_state),
                       dt_status_last   = l_sysdate,
                       id_request       = i_id_request(i),
                       dt_request       = nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_request, NULL),
                                              l_sysdate),
                       id_professional  = i_prof.id,
                       id_cancel_reason = i_id_cancel_reason,
                       cancel_notes     = i_cancel_notes
                 WHERE id_guideline_process_task = l_rec.id_guideline_process_task;
            
            END LOOP;
        END IF;
    
        g_error := 'UPDATE GUIDELINE PROCESS STATUS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        b_result := update_guide_proc_status(i_lang, i_prof, l_rec.id_guideline_process, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE error_undefined;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error request ID is NULL
        WHEN error_id_req_null THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / REQUEST ID CANNOT BE NULL',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Error on guideline process status update
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_rec_task_status;

    /** 
    *  Change state of recommended tasks for a guideline
    *  Flash WRAPPER.DO NOT USE OTHERWISE.
    */
    FUNCTION set_rec_task_status
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN table_number,
        i_id_action                 IN table_number,
        i_id_request                IN table_number,
        i_dt_request                IN VARCHAR2,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN
    
     IS
    
    BEGIN
    
        IF NOT pk_guidelines.set_rec_task_status(i_lang                      => i_lang,
                                                 i_prof                      => i_prof,
                                                 i_id_guideline_process_task => i_id_guideline_process_task,
                                                 i_id_action                 => i_id_action,
                                                 i_id_request                => i_id_request,
                                                 i_dt_request                => i_dt_request,
                                                 i_id_episode                => i_id_episode,
                                                 i_id_cancel_reason          => i_id_cancel_reason,
                                                 i_cancel_notes              => i_cancel_notes,
                                                 i_transaction_id            => NULL,
                                                 o_error                     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END set_rec_task_status;

    /* Flash wrapper for cancel_rec_task. Do not use otherwise.*/
    FUNCTION cancel_rec_task
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_guidelines.cancel_rec_task(i_lang                      => i_lang,
                                             i_prof                      => i_prof,
                                             i_id_guideline_process_task => i_id_guideline_process_task,
                                             i_id_episode                => i_id_episode,
                                             i_id_cancel_reason          => i_id_cancel_reason,
                                             i_cancel_notes              => i_cancel_notes,
                                             i_transaction_id            => NULL,
                                             o_error                     => o_error);
    
    END cancel_rec_task;

    /** 
    *  Cancel recommended task for a guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS_TASK ID of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel
    * @param      i_transaction_id            transaction id for the new scheduler
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION cancel_rec_task
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        i_transaction_id            IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        error_undefined EXCEPTION;
        b_result BOOLEAN;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET ACTION STATES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        b_result := set_rec_task_status(i_lang,
                                        i_prof,
                                        table_number(i_id_guideline_process_task),
                                        table_number(g_state_cancel_operation),
                                        --i_id_action,
                                        table_number(NULL),
                                        NULL,
                                        i_id_episode,
                                        i_id_cancel_reason,
                                        i_cancel_notes,
                                        l_transaction_id,
                                        o_error);
        IF (NOT b_result)
        THEN
            RAISE error_undefined;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            COMMIT;
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on task status update
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Error changing state to cancelled',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_REC_TASK',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_REC_TASK',
                                              o_error);
            -- undo changes (rollback)
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END cancel_rec_task;

    /** 
    *  Get context info regarding a guideline
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_HELP             Cursor with all help information / context
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_guideline_help
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_help OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_help FOR
            SELECT guid.id_guideline,
                   guid.guideline_desc,
                   get_link_id_str(i_lang, i_prof, i_id_guideline, g_guide_link_pathol, g_separator) AS desc_path,
                   guid.context_desc,
                   guid.context_title,
                   guid.context_adaptation,
                   guid.context_type_media,
                   get_context_author_str(i_lang, i_prof, i_id_guideline, g_separator2) AS context_author,
                   guid.context_editor,
                   guid.context_edition_site,
                   guid.context_edition,
                   guid.context_access,
                   guid.id_context_language,
                   guid.id_context_associated_language
              FROM guideline guid
             WHERE guid.id_guideline = i_id_guideline;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_HELP',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_help);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_help;

    /** 
    *  Get history details for  a guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       Process ID
    * @param      I_ID_GUIDELINE_PROCESS_TASK  Process task ID    
    * @param      O_GUIDELINE_DETAIL           Cursor with all help information / context
    * @param      O_GUIDELINE_PROC_INFO        Cursor with guideline process detail
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/02/28
    */
    FUNCTION get_guideline_detail_hst
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process      IN guideline_process.id_guideline_process%TYPE,
        i_id_guideline_process_task IN table_number,
        o_guideline_detail          OUT pk_types.cursor_type,
        o_guideline_proc_info       OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count_guid_proc_task PLS_INTEGER;
    BEGIN
    
        l_count_guid_proc_task := i_id_guideline_process_task.count;
    
        g_error := 'GET GUIDELINE PROCCESS CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_proc_info FOR
            SELECT id_guideline,
                   flg_status,
                   guideline_desc,
                   pathology_desc,
                   type_desc,
                   environment_desc,
                   speciality_desc,
                   professional_desc,
                   chief_complaint_desc,
                   flg_type_rec,
                   desc_recommendation,
                   status_desc,
                   nvl2(prof_cancel, prof_cancel, NULL) AS prof_cancel,
                   nvl2(cancel_prof_spec, '(' || cancel_prof_spec || ')', NULL) AS cancel_prof_spec,
                   cancel_notes,
                   cancel_date,
                   cancel_reason
              FROM (SELECT guid.id_guideline id_guideline,
                           guid_proc.flg_status flg_status,
                           guid.guideline_desc guideline_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator2) pathology_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) type_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_envi, g_separator) environment_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_spec, g_separator) speciality_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_prof, g_separator) professional_desc,
                           get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_chief_complaint, g_separator) AS chief_complaint_desc,
                           guid.flg_type_recommendation AS flg_type_rec,
                           pk_sysdomain.get_domain(g_domain_flg_type_rec, guid.flg_type_recommendation, i_lang) AS desc_recommendation,
                           pk_sysdomain.get_domain(g_domain_flg_guideline, guid_proc.flg_status, i_lang) AS status_desc,
                           decode(guid_proc.flg_status,
                                  g_process_canceled,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc.id_prof_cancel),
                                  NULL) AS prof_cancel,
                           decode(guid_proc.flg_status,
                                  g_process_canceled,
                                  pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(guid_proc.id_prof_cancel,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)),
                                  NULL) cancel_prof_spec,
                           guid_proc.cancel_notes,
                           decode(guid_proc.flg_status,
                                  g_process_canceled,
                                  pk_date_utils.date_send_tsz(i_lang, guid_proc.dt_status, i_prof)) AS cancel_date,
                           nvl2(id_cancel_reason,
                                pk_translation.get_translation(i_lang,
                                                               'CANCEL_REASON.CODE_CANCEL_REASON.' || id_cancel_reason),
                                NULL) AS cancel_reason
                      FROM guideline guid, guideline_process guid_proc
                     WHERE guid.id_guideline = guid_proc.id_guideline
                       AND guid_proc.id_guideline_process = i_id_guideline_process);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_detail FOR
            SELECT guid_proc_task.id_guideline_process_task,
                   guid_proc_task.task_type,
                   pk_sysdomain.get_domain(g_domain_task_type, guid_proc_task.task_type, i_lang) AS task_type_desc,
                   guid_proc_task.id_task,
                   decode(guid_proc_task.task_type,
                          g_task_patient_education,
                          CASE guid_proc_task.id_task
                              WHEN '-1' THEN
                               guid_proc_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       guid_proc_task.id_task)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           guid_proc_task.id_task,
                                           guid_proc_task.task_type,
                                           guid_proc_task.task_codification) ||
                          decode(guid_proc_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach),
                                      ' (' ||
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach) || ')',
                                      NULL)),
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           guid_proc_task.id_task,
                                           guid_proc_task.task_type,
                                           guid_proc_task.task_codification)) AS task_desc,
                   decode(guid_proc_task.task_type,
                          g_task_patient_education,
                          CASE guid_proc_task.id_task
                              WHEN '-1' THEN
                               guid_proc_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       guid_proc_task.id_task)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           guid_proc_task.id_task,
                                           guid_proc_task.task_type,
                                           guid_proc_task.task_codification) ||
                          decode(guid_proc_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach),
                                      ' (' ||
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach) || ')',
                                      NULL)),
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           guid_proc_task.id_task,
                                           guid_proc_task.task_type,
                                           guid_proc_task.task_codification)) || ' - ' ||
                   pk_sysdomain.get_domain(g_domain_task_type, guid_proc_task.task_type, i_lang) AS task_id_desc,
                   guid_proc_task_hst.flg_status_old,
                   guid_proc_task_hst.id_request_old,
                   pk_date_utils.date_send_tsz(i_lang, guid_proc_task_hst.dt_request_old, i_prof) AS dt_request_old,
                   guid_proc_task_hst.flg_status_new,
                   pk_sysdomain.get_domain(g_domain_flg_guideline_task, guid_proc_task_hst.flg_status_new, i_lang) AS flg_status_new_desc,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      guid_proc_task_hst.dt_status_change,
                                                      i_prof.institution,
                                                      i_prof.software) AS dt_status_change,
                   guid_proc_task_hst.id_professional,
                   prof.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) ||
                   nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                         i_prof,
                                                         prof.id_professional,
                                                         guid_proc_task.dt_request,
                                                         guid_proc.id_episode),
                        ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 prof.id_professional,
                                                                 guid_proc_task.dt_request,
                                                                 guid_proc.id_episode) || ')',
                        NULL) AS name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) AS nick_name,
                   nvl2(guid_proc_task_hst.id_cancel_reason,
                        pk_translation.get_translation(i_lang,
                                                       'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                       guid_proc_task_hst.id_cancel_reason),
                        NULL) AS cancel_reason,
                   guid_proc_task_hst.cancel_notes
              FROM guideline_process_task_hist guid_proc_task_hst,
                   guideline_process_task      guid_proc_task,
                   guideline_process           guid_proc,
                   professional                prof
             WHERE guid_proc_task_hst.id_guideline_process_task = guid_proc_task.id_guideline_process_task
               AND (l_count_guid_proc_task = 0 OR
                   guid_proc_task.id_guideline_process_task IN
                   (SELECT /*+opt_estimate(table gpt rows=1)*/
                      column_value
                       FROM TABLE(i_id_guideline_process_task) gpt))
               AND guid_proc.id_guideline_process = guid_proc_task.id_guideline_process
               AND guid_proc.id_guideline_process = i_id_guideline_process
               AND prof.id_professional = guid_proc_task_hst.id_professional
             ORDER BY guid_proc_task.task_type, guid_proc_task.id_task, guid_proc_task_hst.dt_status_change;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_DETAIL_HST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_detail);
            pk_types.open_my_cursor(o_guideline_proc_info);
        
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_detail_hst;

    /** 
    *  Procedure - Call run_batch function. For being called by a job
    *
    * @param      i_lang        Preferred language ID for this professional
    * @param      i_prof        Object (ID of professional, ID of institution, ID of software)
    *
    * @author     TS
    * @version    0.1
    * @since      2007/06/01
    */
    PROCEDURE run_batch_job
    (
        i_lang language.id_language%TYPE,
        i_prof profissional
    ) IS
        RESULT  BOOLEAN;
        l_error t_error_out;
    BEGIN
    
        pk_alertlog.log_info('Guidelines run_batch job START', g_log_object_name);
    
        -- Call run_batch function
        RESULT := run_batch_internal(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_patient         => NULL,
                                     i_batch_desc         => NULL,
                                     i_id_guideline       => NULL,
                                     i_flg_create_process => TRUE,
                                     o_error              => l_error);
    
        IF (NOT RESULT)
        THEN
            ROLLBACK;
            pk_alertlog.log_error('Guidelines run_batch job ERROR: ' || l_error.err_desc, g_log_object_name);
        ELSE
            COMMIT;
            pk_alertlog.log_info('Guidelines run_batch job FINISHED OK.', g_log_object_name);
        END IF;
    END run_batch_job;

    /** 
    *  Check if a guideline can be recommended to a patient according its history
    *
    * @param      i_id_guideline Guideline ID
    * @param      i_id_patient        Patient ID        
    *
    * @author     TS
    * @version    0.1
    * @since      2007/09/22
    */
    FUNCTION check_history_guideline
    (
        i_id_guideline guideline.id_guideline%TYPE,
        i_id_patient   guideline_process.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        RESULT VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'CHECK GUIDELINE HISTORY';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT decode(COUNT(1), 0, g_not_available, g_available)
          INTO RESULT
          FROM (
               -- the guideline should not be recommended again if it or
               -- any of its previous versions are currently active to the patient
                (SELECT id_guideline
                   FROM guideline guid
                  START WITH guid.id_guideline = i_id_guideline
                 CONNECT BY guid.id_guideline = PRIOR guid.id_guideline_previous_version
                 
                 INTERSECT
                 
                 SELECT gp.id_guideline AS id_guideline
                   FROM guideline_process gp
                  WHERE gp.id_patient = i_id_patient
                    AND gp.flg_status IN (g_process_running, g_process_pending, g_process_recommended))
               
                UNION ALL
               
               -- the guideline should not be recommended again unless it has been edited
                (SELECT gp.id_guideline AS id_guideline
                   FROM guideline_process gp
                  WHERE gp.id_patient = i_id_patient
                    AND gp.id_guideline = i_id_guideline
                    AND gp.flg_status NOT IN (g_process_running, g_process_pending, g_process_recommended)));
    
        RETURN RESULT;
    END check_history_guideline;

    /** 
    *  Pick up patients for specific guidelines (internal use only)
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply guideline to
    * @param      I_BATCH_DESC                 Batch Description        
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_FLG_CREATE_PROCESS         Flag to indicate if the guideline process shall be created
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    * @change     2009/10/24 Rui Spratley 2.5.0.7
    */
    FUNCTION run_batch_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_batch_desc         IN guideline_batch.batch_desc%TYPE,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_flg_create_process IN BOOLEAN DEFAULT TRUE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions table_number;
    
        -----------------------------------------------------------------------------
        -- Cursor with info regarding guideline
        -----------------------------------------------------------------------------
        CURSOR c_guideline IS
            SELECT guid.id_guideline,
                   ----------- inclusion 
                   guid_crit_inc.gender               AS inc_gender,
                   guid_crit_inc.min_age              AS inc_min_age,
                   guid_crit_inc.max_age              AS inc_max_age,
                   guid_crit_inc.min_weight           AS inc_min_weight,
                   guid_crit_inc.max_weight           AS inc_max_weight,
                   guid_crit_inc.min_height           AS inc_min_height,
                   guid_crit_inc.max_height           AS inc_max_height,
                   guid_crit_inc.imc_min              AS inc_min_imc,
                   guid_crit_inc.imc_max              AS inc_max_imc,
                   guid_crit_inc.min_blood_pressure_s AS inc_min_blood_pressure_s,
                   guid_crit_inc.max_blood_pressure_s AS inc_max_blood_pressure_s,
                   guid_crit_inc.min_blood_pressure_d AS inc_min_blood_pressure_d,
                   guid_crit_inc.max_blood_pressure_d AS inc_max_blood_pressure_d,
                   ----------- exclusion
                   guid_crit_exc.gender               AS exc_gender,
                   guid_crit_exc.min_age              AS exc_min_age,
                   guid_crit_exc.max_age              AS exc_max_age,
                   guid_crit_exc.min_weight           AS exc_min_weight,
                   guid_crit_exc.max_weight           AS exc_max_weight,
                   guid_crit_exc.min_height           AS exc_min_height,
                   guid_crit_exc.max_height           AS exc_max_height,
                   guid_crit_exc.imc_min              AS exc_min_imc,
                   guid_crit_exc.imc_max              AS exc_max_imc,
                   guid_crit_exc.min_blood_pressure_s AS exc_min_blood_pressure_s,
                   guid_crit_exc.max_blood_pressure_s AS exc_max_blood_pressure_s,
                   guid_crit_exc.min_blood_pressure_d AS exc_min_blood_pressure_d,
                   guid_crit_exc.max_blood_pressure_d AS exc_max_blood_pressure_d
              FROM guideline guid, guideline_criteria guid_crit_inc, guideline_criteria guid_crit_exc
             WHERE guid.id_guideline = guid_crit_inc.id_guideline
               AND guid_crit_inc.criteria_type = g_criteria_type_inc
               AND guid.id_guideline = guid_crit_exc.id_guideline
               AND guid_crit_exc.criteria_type = g_criteria_type_exc
                  -- State of guideline 
               AND guid.flg_status = g_guideline_finished
                  -- i_prof
               AND guid.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                            column_value
                                             FROM TABLE(l_institutions) inst)
               AND guid.flg_type_recommendation != g_type_rec_manual
                  --AND guid.id_software = i_prof.software
                  -- Criteria
               AND guid.id_guideline = nvl(i_id_guideline, guid.id_guideline)
                  -- Verify if this guideline can be recommnended in this software
               AND (nvl(i_prof.software, g_all_software) = g_all_software OR
                   i_prof.software IN (SELECT id_software
                                          FROM software_dept sd, guideline_link guid_lnk
                                         WHERE guid_lnk.id_guideline = guid.id_guideline
                                           AND guid_lnk.link_type = g_guide_link_envi
                                           AND guid_lnk.id_link = sd.id_dept));
    
        -----------------------------------------------------------------------------
        -- Cursor with Patient info      
        -----------------------------------------------------------------------------
        CURSOR c_patient_criteria(
                                  ----------- inclusion   
                                  c_inc_gender               guideline_criteria.gender%TYPE,
                                  c_inc_min_age              guideline_criteria.min_age%TYPE,
                                  c_inc_max_age              guideline_criteria.max_age%TYPE,
                                  c_inc_min_weight           guideline_criteria.min_weight%TYPE,
                                  c_inc_max_weight           guideline_criteria.max_weight%TYPE,
                                  c_inc_min_height           guideline_criteria.min_height%TYPE,
                                  c_inc_max_height           guideline_criteria.max_height%TYPE,
                                  c_inc_min_imc              guideline_criteria.imc_min%TYPE,
                                  c_inc_max_imc              guideline_criteria.imc_max%TYPE,
                                  c_inc_min_blood_pressure_s guideline_criteria.min_blood_pressure_s%TYPE,
                                  c_inc_max_blood_pressure_s guideline_criteria.max_blood_pressure_s%TYPE,
                                  c_inc_min_blood_pressure_d guideline_criteria.min_blood_pressure_d%TYPE,
                                  c_inc_max_blood_pressure_d guideline_criteria.max_blood_pressure_d%TYPE,
                                  ----------- exclusion
                                  c_exc_gender               guideline_criteria.gender%TYPE,
                                  c_exc_min_age              guideline_criteria.min_age%TYPE,
                                  c_exc_max_age              guideline_criteria.max_age%TYPE,
                                  c_exc_min_weight           guideline_criteria.min_weight%TYPE,
                                  c_exc_max_weight           guideline_criteria.max_weight%TYPE,
                                  c_exc_min_height           guideline_criteria.min_height%TYPE,
                                  c_exc_max_height           guideline_criteria.max_height%TYPE,
                                  c_exc_min_imc              guideline_criteria.imc_min%TYPE,
                                  c_exc_max_imc              guideline_criteria.imc_max%TYPE,
                                  c_exc_min_blood_pressure_s guideline_criteria.min_blood_pressure_s%TYPE,
                                  c_exc_max_blood_pressure_s guideline_criteria.max_blood_pressure_s%TYPE,
                                  c_exc_min_blood_pressure_d guideline_criteria.min_blood_pressure_d%TYPE,
                                  c_exc_max_blood_pressure_d guideline_criteria.max_blood_pressure_d%TYPE,
                                  ----------- ID of guideline associated to the criterias
                                  c_id_guideline guideline.id_guideline%TYPE) IS
            SELECT id_patient, name, gender, desc_age, imc, weight, height
              FROM ((SELECT c.id_patient,
                            c.name,
                            c.gender,
                            c.dt_birth,
                            nvl(trunc(months_between(SYSDATE, c.dt_birth) / 12), c.age) AS desc_age,
                            pk_guidelines.get_imc(vit_sig_height.id_unit_measure,
                                                  vit_sig_height.value,
                                                  vit_sig_weight.id_unit_measure,
                                                  vit_sig_weight.value) AS imc,
                            vit_sig_weight.id_unit_measure,
                            decode(vit_sig_weight.id_unit_measure,
                                   g_imc_weight_default_um,
                                   vit_sig_weight.value,
                                   pk_unit_measure.get_unit_mea_conversion(vit_sig_weight.value,
                                                                           vit_sig_weight.id_unit_measure,
                                                                           g_imc_weight_default_um)) AS weight,
                            vit_sig_height.id_unit_measure,
                            decode(vit_sig_height.id_unit_measure,
                                   g_imc_height_default_um,
                                   vit_sig_height.value,
                                   pk_unit_measure.get_unit_mea_conversion(vit_sig_height.value,
                                                                           vit_sig_height.id_unit_measure,
                                                                           g_imc_height_default_um)) AS height,
                            vit_sig_syst_bp.id_unit_measure,
                            decode(vit_sig_syst_bp.id_unit_measure,
                                   g_blood_pressure_default_um,
                                   vit_sig_syst_bp.value,
                                   pk_unit_measure.get_unit_mea_conversion(vit_sig_syst_bp.value,
                                                                           vit_sig_syst_bp.id_unit_measure,
                                                                           g_blood_pressure_default_um)) AS blood_pressure_s,
                            vit_sig_diast_bp.id_unit_measure,
                            decode(vit_sig_diast_bp.id_unit_measure,
                                   g_blood_pressure_default_um,
                                   vit_sig_diast_bp.value,
                                   pk_unit_measure.get_unit_mea_conversion(vit_sig_diast_bp.value,
                                                                           vit_sig_diast_bp.id_unit_measure,
                                                                           g_blood_pressure_default_um)) AS blood_pressure_d
                       FROM (SELECT pat.*
                               FROM patient pat
                              WHERE pat.id_patient IN (SELECT vst.id_patient
                                                         FROM visit vst
                                                        WHERE vst.id_institution = i_prof.institution)
                                AND i_id_patient IS NULL
                             UNION ALL
                             SELECT pat.*
                               FROM patient pat
                              WHERE pat.id_patient = i_id_patient) c,
                            -- Weight
                            (SELECT t.*
                               FROM (SELECT a.id_vital_sign,
                                            vs_ea.id_vital_sign_read,
                                            vs_ea.dt_vital_sign_read,
                                            vs_ea.id_episode,
                                            vs_ea.value,
                                            vs_ea.id_patient,
                                            vs_ea.id_unit_measure,
                                            row_number() over(PARTITION BY id_patient ORDER BY vs_ea.dt_vital_sign_read DESC) rn
                                       FROM vital_sign a, vital_signs_ea vs_ea
                                      WHERE a.id_vital_sign = vs_ea.id_vital_sign
                                        AND a.id_vital_sign IN g_weight_measure
                                        AND vs_ea.flg_state = g_measure_active) t
                              WHERE t.rn = 1) vit_sig_weight,
                            -- Height
                            (SELECT t.*
                               FROM (SELECT a.id_vital_sign,
                                            vs_ea.id_vital_sign_read,
                                            vs_ea.dt_vital_sign_read,
                                            vs_ea.id_episode,
                                            vs_ea.value,
                                            vs_ea.id_patient,
                                            vs_ea.id_unit_measure,
                                            row_number() over(PARTITION BY id_patient ORDER BY vs_ea.dt_vital_sign_read DESC) rn
                                       FROM vital_sign a, vital_signs_ea vs_ea
                                      WHERE a.id_vital_sign = vs_ea.id_vital_sign
                                        AND a.id_vital_sign IN g_height_measure
                                        AND vs_ea.flg_state = g_measure_active) t
                              WHERE t.rn = 1) vit_sig_height,
                            -- Systolic blood pressure
                            (SELECT t.*
                               FROM (SELECT a.id_vital_sign,
                                            vs_ea.id_vital_sign_read,
                                            vs_ea.dt_vital_sign_read,
                                            vs_ea.id_episode,
                                            vs_ea.value,
                                            vs_ea.id_patient,
                                            vs_ea.id_unit_measure,
                                            row_number() over(PARTITION BY id_patient ORDER BY vs_ea.dt_vital_sign_read DESC) rn
                                       FROM vital_sign a, vital_signs_ea vs_ea
                                      WHERE a.id_vital_sign = vs_ea.id_vital_sign
                                        AND a.id_vital_sign IN g_blood_pressure_s_measure
                                        AND vs_ea.flg_state = g_measure_active) t
                              WHERE t.rn = 1) vit_sig_syst_bp,
                            -- Diastolic blood pressure
                            (SELECT t.*
                               FROM (SELECT a.id_vital_sign,
                                            vs_ea.id_vital_sign_read,
                                            vs_ea.dt_vital_sign_read,
                                            vs_ea.id_episode,
                                            vs_ea.value,
                                            vs_ea.id_patient,
                                            vs_ea.id_unit_measure,
                                            row_number() over(PARTITION BY id_patient ORDER BY vs_ea.dt_vital_sign_read DESC) rn
                                       FROM vital_sign a, vital_signs_ea vs_ea
                                      WHERE a.id_vital_sign = vs_ea.id_vital_sign
                                        AND a.id_vital_sign IN g_blood_pressure_d_measure
                                        AND vs_ea.flg_state = g_measure_active) t
                              WHERE t.rn = 1) vit_sig_diast_bp
                      WHERE c.id_patient = vit_sig_weight.id_patient(+)
                        AND c.id_patient = vit_sig_height.id_patient(+)
                        AND c.id_patient = vit_sig_syst_bp.id_patient(+)
                        AND c.id_patient = vit_sig_diast_bp.id_patient(+)
                           -----------------------------------------------------------<                                                  
                        AND c.dt_deceased IS NULL
                        AND c.flg_status = g_patient_active))
            ----------------------------------------------------------------
             WHERE -- check if the guideline can be recommended to the patient
             check_history_guideline(c_id_guideline, id_patient) = g_not_available
             AND gender = nvl(c_inc_gender, gender) -- Gender
             AND ((gender != c_exc_gender AND c_exc_gender IS NOT NULL) OR c_exc_gender IS NULL)
            -- Age 
             AND nvl(desc_age, g_max_age) >= nvl(c_inc_min_age, g_min_age)
             AND nvl(desc_age, g_min_age) <= nvl(c_inc_max_age, g_max_age)
             AND nvl(desc_age, g_min_age) < nvl(c_exc_min_age, g_max_age)
             AND nvl(desc_age, g_max_age) > nvl(c_exc_max_age, g_min_age)
            -- Height
             AND nvl(height, g_max_height) >= nvl(c_inc_min_height, g_min_height)
             AND nvl(height, g_min_height) <= nvl(c_inc_max_height, g_max_height)
             AND nvl(height, g_min_height) < nvl(c_exc_min_height, g_max_height)
             AND nvl(height, g_max_height) > nvl(c_exc_max_height, g_min_height)
            -- Weight
             AND nvl(weight, g_max_weight) >= nvl(c_inc_min_weight, g_min_weight)
             AND nvl(weight, g_min_weight) <= nvl(c_inc_max_weight, g_max_weight)
             AND nvl(weight, g_min_weight) < nvl(c_exc_min_weight, g_max_weight)
             AND nvl(weight, g_max_weight) > nvl(c_exc_max_weight, g_min_weight)
            -- IMC
             AND nvl(imc, g_max_imc) >= nvl(c_inc_min_imc, g_min_imc)
             AND nvl(imc, g_min_imc) <= nvl(c_inc_max_imc, g_max_imc)
             AND nvl(imc, g_min_imc) < nvl(c_exc_min_imc, g_max_imc)
             AND nvl(imc, g_max_imc) > nvl(c_exc_max_imc, g_min_imc)
            -- Systolic blood pressure
             AND nvl(blood_pressure_s, g_max_imc) >= nvl(c_inc_min_blood_pressure_s, g_min_blood_pressure_s)
             AND nvl(blood_pressure_s, g_min_imc) <= nvl(c_inc_max_blood_pressure_s, g_max_blood_pressure_s)
             AND nvl(blood_pressure_s, g_min_imc) < nvl(c_exc_min_blood_pressure_s, g_max_blood_pressure_s)
             AND nvl(blood_pressure_s, g_max_imc) > nvl(c_exc_max_blood_pressure_s, g_min_blood_pressure_s)
            -- Diastolic blood pressure
             AND nvl(blood_pressure_d, g_max_blood_pressure_d) >= nvl(c_inc_min_blood_pressure_d, g_min_blood_pressure_d)
             AND nvl(blood_pressure_d, g_min_blood_pressure_d) <= nvl(c_inc_max_blood_pressure_d, g_max_blood_pressure_d)
             AND nvl(blood_pressure_d, g_min_blood_pressure_d) < nvl(c_exc_min_blood_pressure_d, g_max_blood_pressure_d)
             AND nvl(blood_pressure_d, g_max_blood_pressure_d) > nvl(c_exc_max_blood_pressure_d, g_min_blood_pressure_d);
    
        l_applicable PLS_INTEGER := 0;
        l_id_batch   guideline_batch.id_batch%TYPE;
        l_counter    PLS_INTEGER := 0;
        error_create_process   EXCEPTION;
        error_update_processes EXCEPTION;
        b_result BOOLEAN;
    
    BEGIN
    
        g_error := 'UPDATE STATE OF GUIDELINE PROCESSES AND ASSOCIATED TASKS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        b_result := update_all_guide_proc_status(i_lang, i_prof, i_id_patient, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE error_update_processes;
        END IF;
    
        COMMIT;
    
        g_error := 'RUN BATCH';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Create Batch
        INSERT INTO guideline_batch
            (id_batch, batch_desc, batch_type, dt_guideline_batch)
        VALUES
            (seq_guideline_batch.nextval,
             i_batch_desc,
             decode(i_id_patient,
                    NULL,
                    decode(i_id_guideline, NULL, g_batch_all, g_batch_ap_1g),
                    decode(i_id_guideline, NULL, g_batch_1p_ag, g_batch_1p_1g)),
             --        l_type,
             current_timestamp)
        RETURNING id_batch INTO l_id_batch;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'Get Guidelines to look for';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- Get guidelines for this Institution / Software
        FOR rec_guid IN c_guideline
        LOOP
        
            g_error := 'Search patients for this guideline';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- Loop through patients
            FOR rec_pat IN c_patient_criteria(rec_guid.inc_gender,
                                              rec_guid.inc_min_age,
                                              rec_guid.inc_max_age,
                                              rec_guid.inc_min_weight,
                                              rec_guid.inc_max_weight,
                                              rec_guid.inc_min_height,
                                              rec_guid.inc_max_height,
                                              rec_guid.inc_min_imc,
                                              rec_guid.inc_max_imc,
                                              rec_guid.inc_min_blood_pressure_s,
                                              rec_guid.inc_max_blood_pressure_s,
                                              rec_guid.inc_min_blood_pressure_d,
                                              rec_guid.inc_max_blood_pressure_d,
                                              rec_guid.exc_gender,
                                              rec_guid.exc_min_age,
                                              rec_guid.exc_max_age,
                                              rec_guid.exc_min_weight,
                                              rec_guid.exc_max_weight,
                                              rec_guid.exc_min_height,
                                              rec_guid.exc_max_height,
                                              rec_guid.exc_min_imc,
                                              rec_guid.exc_max_imc,
                                              rec_guid.exc_min_blood_pressure_s,
                                              rec_guid.exc_max_blood_pressure_s,
                                              rec_guid.exc_min_blood_pressure_d,
                                              rec_guid.exc_max_blood_pressure_d,
                                              rec_guid.id_guideline)
            LOOP
                -- reset history of the previous criteria check
                l_applicable := 0;
            
                g_error := 'Check Other Criterias';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- Check other criterias
                g_error := 'Check Analysis';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- check analysis
                SELECT COUNT(1)
                  INTO l_counter
                  FROM (
                       -- Inclusion                     
                        (SELECT to_number(inc.link_other_crit)
                           FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                          WHERE inc.link_other_crit_typ = g_guideline_analysis
                         MINUS
                         SELECT id_analysis AS id_link
                           FROM analysis_result
                          WHERE id_patient = rec_pat.id_patient) UNION ALL
                       -- Exclusion
                        (SELECT to_number(exc.link_other_crit)
                           FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc
                          WHERE exc.link_other_crit_typ = g_guideline_analysis
                         INTERSECT
                         SELECT id_analysis AS id_link
                           FROM analysis_result
                          WHERE id_patient = rec_pat.id_patient));
            
                l_applicable := l_applicable + nvl(l_counter, 0);
            
                g_error := 'Check Allergies';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- check allergies        
                IF (l_applicable = 0)
                THEN
                    -- Inclusion                     
                    SELECT abs(COUNT(id_allergy) - COUNT(link_other_crit)) + COUNT(flg_status) + COUNT(flg_type) AS counter
                      INTO l_counter
                      FROM (SELECT /*+opt_estimate(table inc rows=1)*/
                             pat_all.id_allergy,
                             inc.link_other_crit,
                             -- check flg_status detail
                             decode((SELECT vvalue
                                      FROM guideline_adv_input_value
                                     WHERE flg_type = g_adv_input_type_criterias
                                       AND id_adv_input_link = inc.id_guideline_criteria_link
                                       AND id_advanced_input_field = g_allergy_status_field
                                       AND vvalue != to_char(g_detail_any)),
                                    NULL,
                                    NULL,
                                    pat_all.flg_status,
                                    NULL,
                                    1) AS flg_status,
                             -- ckeck flg_type detail
                             decode((SELECT vvalue
                                      FROM guideline_adv_input_value
                                     WHERE flg_type = g_adv_input_type_criterias
                                       AND id_adv_input_link = inc.id_guideline_criteria_link
                                       AND id_advanced_input_field = g_allergy_react_field
                                       AND vvalue != to_char(g_detail_any)),
                                    NULL,
                                    NULL,
                                    pat_all.flg_type,
                                    NULL,
                                    1) AS flg_type
                              FROM (SELECT id_allergy, flg_status, flg_type
                                      FROM pat_allergy
                                     WHERE id_patient = rec_pat.id_patient
                                       AND flg_status IN (g_allergy_active, g_allergy_passive)) pat_all,
                                   TABLE(pk_guidelines.get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_guideline_allergies
                               AND pat_all.id_allergy(+) = inc.link_other_crit);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    -- Exclusion
                    SELECT /*+opt_estimate(table exc rows=1)*/
                     COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc, pat_allergy
                     WHERE exc.link_other_crit_typ = g_guideline_allergies
                       AND id_patient = rec_pat.id_patient
                       AND flg_status IN (g_allergy_active, g_allergy_passive)
                       AND pat_allergy.id_allergy = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(pat_allergy.flg_status, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM guideline_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_guideline_criteria_link
                                      AND id_advanced_input_field = g_allergy_status_field
                                      AND vvalue != to_char(g_detail_any)),
                                   pat_allergy.flg_status),
                               -1)
                          -- check flg_type detail
                       AND nvl(pat_allergy.flg_type, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM guideline_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_guideline_criteria_link
                                      AND id_advanced_input_field = g_allergy_react_field
                                      AND vvalue != to_char(g_detail_any)),
                                   pat_allergy.flg_type),
                               -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                g_error := 'Check Diagnosis';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- check diagnosis            
                IF (l_applicable = 0)
                THEN
                
                    -- Inclusion                     
                    SELECT abs(COUNT(id_link) - COUNT(link_other_crit)) + COUNT(flg_status) + COUNT(flg_nature) AS counter
                      INTO l_counter
                      FROM (SELECT /*+opt_estimate(table inc rows=1)*/
                             prb.id_link,
                             inc.link_other_crit,
                             -- check flg_status detail
                             decode((SELECT vvalue
                                      FROM guideline_adv_input_value
                                     WHERE flg_type = g_adv_input_type_criterias
                                       AND id_adv_input_link = inc.id_guideline_criteria_link
                                       AND id_advanced_input_field = g_diagnosis_status_field
                                       AND vvalue != to_char(g_detail_any)),
                                    NULL,
                                    NULL,
                                    prb.flg_status,
                                    NULL,
                                    1) AS flg_status,
                             -- ckeck flg_type detail
                             decode((SELECT vvalue
                                      FROM guideline_adv_input_value
                                     WHERE flg_type = g_adv_input_type_criterias
                                       AND id_adv_input_link = inc.id_guideline_criteria_link
                                       AND id_advanced_input_field = g_diagnosis_nature_field
                                       AND vvalue != to_char(g_detail_any)),
                                    NULL,
                                    NULL,
                                    prb.flg_nature,
                                    NULL,
                                    1) AS flg_nature
                              FROM (SELECT nvl(d.id_diagnosis, d1.id_diagnosis) AS id_link,
                                           prob.flg_status,
                                           prob.flg_nature
                                      FROM pat_problem prob, diagnosis d, epis_diagnosis ed, diagnosis d1
                                     WHERE prob.id_diagnosis = d.id_diagnosis(+)
                                       AND prob.id_epis_diagnosis = ed.id_epis_diagnosis(+)
                                       AND ed.id_diagnosis = d1.id_diagnosis(+)
                                          -- only the ones with diagnosis
                                       AND nvl(d.id_diagnosis, d1.id_diagnosis) IS NOT NULL
                                       AND prob.id_patient = rec_pat.id_patient
                                    UNION
                                    SELECT d.id_diagnosis AS id_link, phd.flg_status, phd.flg_nature
                                      FROM diagnosis d, pat_history_diagnosis phd, alert_diagnosis ad
                                     WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
                                       AND ad.id_diagnosis = d.id_diagnosis
                                       AND phd.id_patient = rec_pat.id_patient) prb,
                                   TABLE(pk_guidelines.get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_guideline_diagnosis
                               AND prb.id_link(+) = inc.link_other_crit);
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                
                    -- Exclusion
                    SELECT /*+opt_estimate(table exc rows=1)*/
                     COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc,
                           (SELECT nvl(d.id_diagnosis, d1.id_diagnosis) AS id_link, prob.flg_status, prob.flg_nature
                              FROM pat_problem prob, diagnosis d, epis_diagnosis ed, diagnosis d1
                             WHERE prob.id_diagnosis = d.id_diagnosis(+)
                               AND prob.id_epis_diagnosis = ed.id_epis_diagnosis(+)
                               AND ed.id_diagnosis = d1.id_diagnosis(+)
                                  -- only the ones with diagnosis
                               AND nvl(d.id_diagnosis, d1.id_diagnosis) IS NOT NULL
                               AND prob.id_patient = rec_pat.id_patient
                            UNION
                            SELECT d.id_diagnosis AS id_link, phd.flg_status, phd.flg_nature
                              FROM diagnosis d, pat_history_diagnosis phd, alert_diagnosis ad
                             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
                               AND ad.id_diagnosis = d.id_diagnosis
                               AND phd.id_patient = rec_pat.id_patient) prb
                     WHERE exc.link_other_crit_typ = g_guideline_diagnosis
                       AND prb.id_link = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(prb.flg_status, -1) = nvl(nvl((SELECT vvalue
                                                               FROM guideline_adv_input_value
                                                              WHERE flg_type = g_adv_input_type_criterias
                                                                AND id_adv_input_link = exc.id_guideline_criteria_link
                                                                AND id_advanced_input_field = g_diagnosis_status_field
                                                                AND vvalue != to_char(g_detail_any)),
                                                             prb.flg_status),
                                                         -1)
                          -- check flg_nature detail
                       AND nvl(prb.flg_nature, -1) = nvl(nvl((SELECT vvalue
                                                               FROM guideline_adv_input_value
                                                              WHERE flg_type = g_adv_input_type_criterias
                                                                AND id_adv_input_link = exc.id_guideline_criteria_link
                                                                AND id_advanced_input_field = g_diagnosis_nature_field
                                                                AND vvalue != to_char(g_detail_any)),
                                                             prb.flg_nature),
                                                         -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    g_error := 'Check Exams';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    -- check exams
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM (
                           -- Inclusion                     
                            (SELECT to_number(inc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                              WHERE inc.link_other_crit_typ = g_guideline_exams
                             MINUS
                             
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type = g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel) UNION ALL
                           -- Exclusion
                            (SELECT to_number(exc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc
                              WHERE exc.link_other_crit_typ = g_guideline_exams
                             INTERSECT
                             
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type = g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel));
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    g_error := 'Check Other Exams';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    -- check other exams
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM (
                           -- Inclusion                     
                            (SELECT to_number(inc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                              WHERE inc.link_other_crit_typ = g_guideline_other_exams
                             MINUS
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type != g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel) UNION ALL
                           -- Exclusion
                            (SELECT to_number(exc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc
                              WHERE exc.link_other_crit_typ = g_guideline_other_exams
                             INTERSECT
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type != g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel));
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                g_error := 'Check Diagnosis Nurse';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                -- check diagnosis nurse
                IF (l_applicable = 0)
                THEN
                
                    -- Inclusion                     
                    SELECT abs(COUNT(id_composition) - COUNT(link_other_crit)) + COUNT(flg_status) AS counter
                      INTO l_counter
                      FROM (SELECT /*+opt_estimate(table inc rows=1)*/
                             nurse_diag.id_composition,
                             inc.link_other_crit,
                             -- check flg_status detail
                             decode((SELECT vvalue
                                      FROM guideline_adv_input_value
                                     WHERE flg_type = g_adv_input_type_criterias
                                       AND id_adv_input_link = inc.id_guideline_criteria_link
                                       AND id_advanced_input_field = g_nurse_diagnosis_status_field
                                       AND vvalue != to_char(g_detail_any)),
                                    NULL,
                                    NULL,
                                    nurse_diag.flg_status,
                                    NULL,
                                    1) AS flg_status
                              FROM (SELECT id_composition, flg_status
                                      FROM icnp_epis_diagnosis
                                     WHERE flg_status IN (g_nurse_active, g_nurse_solved)
                                       AND id_patient = rec_pat.id_patient) nurse_diag,
                                   TABLE(pk_guidelines.get_other_criteria(rec_guid.id_guideline, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_guideline_diagnosis_nurse
                               AND nurse_diag.id_composition(+) = inc.link_other_crit);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                
                    -- Exclusion
                    SELECT /*+opt_estimate(table exc rows=1)*/
                     COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_guid.id_guideline, g_criteria_type_exc)) exc,
                           icnp_epis_diagnosis nurse_diag
                     WHERE exc.link_other_crit_typ = g_guideline_diagnosis_nurse
                       AND nurse_diag.flg_status IN (g_nurse_active, g_nurse_solved)
                       AND nurse_diag.id_patient = rec_pat.id_patient
                       AND nurse_diag.id_composition = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(nurse_diag.flg_status, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM guideline_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_guideline_criteria_link
                                      AND id_advanced_input_field = g_nurse_diagnosis_status_field
                                      AND vvalue != to_char(g_detail_any)),
                                   nurse_diag.flg_status),
                               -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                -- if guideline match with patient profile, then create a guideline process
                IF (l_applicable = 0 AND i_flg_create_process)
                THEN
                    IF (NOT create_guideline_process(i_lang,
                                                     i_prof,
                                                     rec_guid.id_guideline,
                                                     l_id_batch,
                                                     NULL,
                                                     rec_pat.id_patient,
                                                     g_process_recommended,
                                                     o_error))
                    THEN
                        RAISE error_create_process;
                    END IF;
                ELSIF (l_applicable = 0 AND NOT i_flg_create_process)
                THEN
                    insert_tbl_temp(i_num_1 => table_number(rec_guid.id_guideline),
                                    i_num_2 => table_number(rec_pat.id_patient));
                END IF;
            
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on guideline processes status update and its tasks
        WHEN error_update_processes THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / COULD NOT UPDATE PROCESSES',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'RUN_BATCH_INTERNAL',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
        -- Error on process creation
        WHEN error_create_process THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / COULD NOT CREATE PROCESS',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'RUN_BATCH_INTERNAL',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
        -- Other erros not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'RUN_BATCH_INTERNAL',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END run_batch_internal;

    /** 
    *  Pick up patients for specific guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply guideline to
    * @param      I_BATCH_DESC                 Batch Description        
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     Rui Spratley
    * @version    2.5.0.7
    * @since      2009/10/24
    */
    FUNCTION run_batch
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_batch_desc   IN guideline_batch.batch_desc%TYPE,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        -- Call run_batch function
        IF NOT run_batch_internal(i_lang               => i_lang,
                                  i_prof               => i_prof,
                                  i_id_patient         => i_id_patient,
                                  i_batch_desc         => i_batch_desc,
                                  i_id_guideline       => i_id_guideline,
                                  i_flg_create_process => TRUE,
                                  o_error              => o_error)
        THEN
            g_error := 'error while calling run_batch_internal function';
            RAISE l_exception;
        END IF;
    
        -- commit changes
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        -- Other erros not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'RUN_BATCH',
                                              o_error);
            -- rollback changes
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
    END;

    /** 
    *  Create manual guideline processes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.2
    * @since      2007/05/11
    */
    FUNCTION create_guideline_proc_manual
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN table_number,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_batch guideline_batch.id_batch%TYPE;
        e_create_process_error EXCEPTION;
    BEGIN
        g_error := 'INSERT GUIDELINE BATCH';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- create batch
        INSERT INTO guideline_batch
            (id_batch, batch_type, dt_guideline_batch)
        VALUES
            (seq_guideline_batch.nextval, g_batch_1p_1g, current_timestamp)
        RETURNING id_batch INTO l_id_batch;
    
        g_error := 'CREATE GUIDELINE PROCESSES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- create all guideline processes
        IF i_id_guideline.count != 0
        THEN
            FOR i IN i_id_guideline.first .. i_id_guideline.last
            LOOP
                IF (NOT create_guideline_process(i_lang,
                                                 i_prof,
                                                 i_id_guideline(i),
                                                 l_id_batch,
                                                 i_id_episode,
                                                 i_id_patient,
                                                 g_process_pending,
                                                 o_error))
                THEN
                    RAISE e_create_process_error;
                END IF;
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN e_create_process_error THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / COULD NOT CREATE PROCESS',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_GUIDELINE_PROC_MANUAL',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_GUIDELINE_PROC_MANUAL',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END create_guideline_proc_manual;

    /** 
    *  Create guideline process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_BATCH                   Batch ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_FLG_INIT_STATUS            Guideline process initial status
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/07
    */
    FUNCTION create_guideline_process
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_guideline    IN guideline.id_guideline%TYPE,
        i_id_batch        IN guideline_batch.id_batch%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_flg_init_status IN guideline_process.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tasks IS
            SELECT guideline_task_link.*,
                   value_type,
                   nvalue,
                   dvalue,
                   vvalue,
                   nvl2(id_adv_input_link, g_available, g_not_available) AS flg_details
              FROM guideline_task_link, guideline_adv_input_value
             WHERE guideline_task_link.id_guideline = i_id_guideline
               AND guideline_adv_input_value.flg_type(+) = g_adv_input_type_tasks
               AND guideline_adv_input_value.id_advanced_input_field(+) = g_frequency_field -- Frequency
               AND guideline_task_link.id_guideline_task_link = guideline_adv_input_value.id_adv_input_link(+);
    
        l_id_guideline_process      guideline_process.id_guideline_process%TYPE;
        l_id_guideline_process_task guideline_process_task.id_guideline_process_task%TYPE;
    BEGIN
    
        g_error := 'INSERT PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- inserts process
        INSERT INTO guideline_process
            (id_guideline_process,
             id_batch,
             id_episode,
             id_patient,
             id_guideline,
             flg_status,
             dt_status,
             id_professional)
        VALUES
            (seq_guideline_process.nextval,
             i_id_batch,
             i_id_episode,
             i_id_patient,
             i_id_guideline,
             i_flg_init_status,
             current_timestamp,
             i_prof.id)
        RETURNING id_guideline_process INTO l_id_guideline_process;
    
        g_error := 'INSERT PROCESS TASKS AND RELATED DETAILS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- inserts process task and related details
        FOR rec IN c_tasks
        LOOP
            INSERT INTO guideline_process_task
                (id_guideline_process_task,
                 id_guideline_process,
                 id_task,
                 task_type,
                 id_request,
                 dt_request,
                 flg_status_last,
                 dt_status_last,
                 task_notes,
                 id_task_attach,
                 id_professional,
                 task_codification)
            VALUES
                (seq_guideline_process_task.nextval,
                 l_id_guideline_process,
                 rec.id_task_link,
                 rec.task_type,
                 NULL,
                 NULL,
                 i_flg_init_status,
                 current_timestamp,
                 rec.task_notes,
                 rec.id_task_attach,
                 i_prof.id,
                 rec.task_codification)
            RETURNING id_guideline_process_task INTO l_id_guideline_process_task;
        
            -- insert frequency detail 
            IF (rec.flg_details = g_available AND rec.vvalue != g_task_unique_freq)
            THEN
                INSERT INTO guideline_process_task_det
                    (id_guideline_process_task_det,
                     id_guideline_process_task,
                     flg_detail_type,
                     value_type,
                     nvalue,
                     dvalue,
                     vvalue)
                VALUES
                    (seq_guideline_process_task_det.nextval,
                     l_id_guideline_process_task,
                     g_proc_task_det_freq,
                     rec.value_type,
                     rec.nvalue,
                     rec.dvalue,
                     rec.vvalue);
            
                -- insert next recomendation detail
                INSERT INTO guideline_process_task_det
                    (id_guideline_process_task_det, id_guideline_process_task, flg_detail_type, value_type, dvalue)
                VALUES
                    (seq_guideline_process_task_det.nextval,
                     l_id_guideline_process_task,
                     g_proc_task_det_next_rec,
                     g_guideline_d_type,
                     current_timestamp);
            END IF;
        END LOOP;
    
        g_error := 'INSERT PROCESS TASKS HISTORY';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        INSERT INTO guideline_process_task_hist
            (id_guideline_process_task_hist,
             id_guideline_process_task,
             flg_status_old,
             id_request_old,
             dt_request_old,
             flg_status_new,
             dt_status_change,
             id_professional,
             id_request_new,
             dt_request_new)
            (SELECT seq_guideline_process_task_hst.nextval,
                    id_guideline_process_task,
                    NULL,
                    NULL,
                    NULL,
                    i_flg_init_status,
                    current_timestamp,
                    i_prof.id,
                    NULL,
                    NULL
               FROM guideline_process_task
              WHERE id_guideline_process = l_id_guideline_process);
    
        -- No commit as this should be done by the calling function
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_GUIDELINE_PROCESS',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END create_guideline_process;

    /** 
    * Function - Returns IMC for specific height and weight
    * @param      I_ID_UNIT_MEASURE_HEIGHT          Unit of measure of height
    * @param      I_HEIGHT                          Height        
    * @param      I_ID_UNIT_MEASURE_WEIGHT          Unit of measure of weight
    * @param      I_WEIGHT                          Weight
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/02
    */
    FUNCTION get_imc
    (
        i_id_unit_measure_height IN guideline_criteria.id_height_unit_measure%TYPE,
        i_height                 IN guideline_criteria.min_height%TYPE,
        i_id_unit_measure_weight IN guideline_criteria.id_weight_unit_measure%TYPE,
        i_weight                 IN guideline_criteria.min_weight%TYPE
    ) RETURN NUMBER IS
    
        l_imc NUMBER;
    BEGIN
    
        SELECT decode(i_height,
                      NULL,
                      NULL,
                      decode(i_id_unit_measure_weight,
                             g_imc_weight_default_um,
                             i_weight,
                             pk_unit_measure.get_unit_mea_conversion(i_weight,
                                                                     i_id_unit_measure_weight,
                                                                     g_imc_weight_default_um)) /
                      power(decode(i_id_unit_measure_height,
                                   g_imc_height_default_um,
                                   i_height,
                                   pk_unit_measure.get_unit_mea_conversion(i_height,
                                                                           i_id_unit_measure_height,
                                                                           g_imc_height_default_um)),
                            2)) AS imc
          INTO l_imc
          FROM dual;
    
        RETURN l_imc;
    END get_imc;

    /** 
    *  Get multichoice for action
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_subject                    Subject of action
    * @param      I_ID_state                   Original state from which we want an action        
    * @param      O_ACTION                     Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/03/13
    */
    FUNCTION get_action
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subject  IN table_varchar, --action.subject%TYPE,
        i_id_state IN action.from_state%TYPE,
        o_action   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat prof_cat.id_category%TYPE;
        l_market   market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        -- check if this profile is marked as "read-only"
        IF pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_intern_name => pk_access.g_view_only_profile) =
           pk_alert_constant.g_yes
        THEN
            -- "read-only" profile enabled - no actions should be returned
            pk_types.open_my_cursor(o_action);
        ELSE
            g_error := 'GET PROFESSIONAL CATEGORY';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            SELECT pc.id_category
              INTO l_prof_cat
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'GET CURSOR';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            -- get available actions for this professional
            OPEN o_action FOR
                SELECT DISTINCT subject,
                                act.id_action,
                                pk_message.get_message(i_lang, i_prof, code_action) AS action_desc,
                                icon,
                                from_state,
                                to_state,
                                flg_default,
                                decode(act.subject, g_guideline_actions, NULL, guid_act_cat.task_type) AS task_type,
                                act.rank
                  FROM action act,
                       TABLE(i_subject) t_subject,
                       (SELECT DISTINCT id_action, task_type
                          FROM (SELECT id_action,
                                       task_type,
                                       first_value(flg_available) over(PARTITION BY id_action, task_type ORDER BY id_profile_template DESC, flg_available) AS flg_avail
                                  FROM (SELECT gac.id_action, gac.task_type, gac.flg_available, gac.id_profile_template
                                          FROM guideline_action_category gac
                                         WHERE gac.id_category = l_prof_cat
                                           AND gac.task_type != 0
                                           AND gac.id_profile_template IN (SELECT ppt.id_profile_template
                                                                             FROM prof_profile_template ppt
                                                                            WHERE ppt.id_professional = i_prof.id
                                                                              AND ppt.id_institution = i_prof.institution
                                                                              AND ppt.id_software = i_prof.software
                                                                           UNION ALL
                                                                           SELECT g_all_profile_template AS id_profile_template
                                                                             FROM dual)
                                        UNION ALL
                                        SELECT guid_ac.id_action,
                                               items.item AS task_type,
                                               guid_ac.flg_available,
                                               guid_ac.id_profile_template
                                          FROM guideline_action_category guid_ac,
                                               (SELECT DISTINCT item
                                                  FROM guideline_item_soft_inst gisi
                                                 WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                                                   AND gisi.id_software IN (g_all_software, i_prof.software)
                                                   AND gisi.id_market IN (g_all_markets, l_market)
                                                   AND gisi.flg_item_type = g_guideline_item_tasks) items
                                         WHERE guid_ac.id_category = l_prof_cat
                                           AND guid_ac.id_profile_template IN
                                               (SELECT ppt.id_profile_template
                                                  FROM prof_profile_template ppt
                                                 WHERE ppt.id_professional = i_prof.id
                                                   AND ppt.id_institution = i_prof.institution
                                                   AND ppt.id_software = i_prof.software
                                                UNION ALL
                                                SELECT g_all_profile_template AS id_profile_template
                                                  FROM dual)
                                           AND guid_ac.task_type = 0))
                         WHERE flg_avail = g_available) guid_act_cat
                 WHERE t_subject.column_value = act.subject
                   AND act.flg_status = g_active
                   AND act.from_state = nvl(i_id_state, act.from_state)
                   AND guid_act_cat.id_action = act.id_action
                   AND (guid_act_cat.task_type IN
                       (SELECT DISTINCT item
                           FROM (SELECT item,
                                        first_value(gisi.flg_available) over(PARTITION BY gisi.item ORDER BY gisi.id_market DESC, gisi.id_institution DESC, gisi.id_software DESC, gisi.flg_available) AS flg_avail
                                   FROM guideline_item_soft_inst gisi
                                  WHERE gisi.id_institution IN (g_all_institution, i_prof.institution)
                                    AND gisi.id_software IN (g_all_software, i_prof.software)
                                    AND gisi.id_market IN (g_all_markets, l_market)
                                    AND gisi.flg_item_type = g_guideline_item_tasks)
                          WHERE flg_avail = g_available) OR
                       (act.from_state != g_process_running AND act.to_state != g_process_running))
                 ORDER BY rank;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_ACTION',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_action);
            -- return failure of function
            RETURN FALSE;
        
    END get_action;

    /**
     * Get Advanced Input for guideline.
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced input ID to be shown
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADVANCED_INPUT_LINK Tasks or Criterias links to get advanced input data
     * @param O_FIELDS                 Advanced input fields and it's configurations
     * @param O_FIELDS_DET             Advanced input fields details
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error (BOOLEAN)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    */
    FUNCTION get_guideline_advanced_input
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN guideline_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number,
        o_fields            OUT pk_types.cursor_type,
        o_fields_det        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ADVANCED INPUT STRUCTURE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_fields FOR
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aif.intern_name AS name,
                   pk_translation.get_translation(i_lang, aif.code_advanced_input_field) AS label,
                   aif.type,
                   aisi.flg_active,
                   pk_message.get_message(i_lang, aisi.error_message) errormessage,
                   aisi.rank
              FROM advanced_input ai, advanced_input_field aif, advanced_input_soft_inst aisi
             WHERE ai.id_advanced_input = i_id_advanced_input
               AND aisi.id_advanced_input = ai.id_advanced_input
               AND aif.id_advanced_input_field = aisi.id_advanced_input_field
               AND aisi.id_institution IN (i_prof.institution, g_all_institution)
               AND aisi.id_software IN (i_prof.software, g_all_software)
             ORDER BY aisi.rank;
    
        g_error := 'GET ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_fields_det FOR
            SELECT adv_input.id_advanced_input,
                   adv_input.id_advanced_input_field,
                   adv_input.id_advanced_input_field_det,
                   val.id_adv_input_link,
                   val.value,
                   val.value_date,
                   adv_input.max_value                   AS maxvalue,
                   adv_input.min_value                   AS minvalue,
                   adv_input.max_date                    AS maxdate,
                   adv_input.min_date                    AS mindate,
                   adv_input.format,
                   adv_input.alignment,
                   adv_input.separator,
                   adv_input.id_unit,
                   adv_input.rank
              FROM (SELECT ai.id_advanced_input,
                           aif.id_advanced_input_field,
                           aidet.id_advanced_input_field_det,
                           decode(aif.type,
                                  g_date_keypad,
                                  pk_date_utils.date_send_tsz(i_lang, convert_to_date(aidet.max_value), i_prof),
                                  NULL) AS max_date,
                           decode(aif.type,
                                  g_date_keypad,
                                  pk_date_utils.date_send_tsz(i_lang, convert_to_date(aidet.min_value), i_prof),
                                  NULL) AS min_date,
                           decode(aif.type, g_date_keypad, NULL, to_number(aidet.max_value)) AS max_value,
                           decode(aif.type, g_date_keypad, NULL, to_number(aidet.min_value)) AS min_value,
                           'DD/MM/YYYY hh:mm' AS format, --pk_message.get_message(i_lang,aidet.format_message) as FORMAT
                           aidet.alignment,
                           aidet.separator,
                           aidet.id_unit,
                           aidet.rank
                      FROM advanced_input           ai,
                           advanced_input_field     aif,
                           advanced_input_soft_inst aisi,
                           advanced_input_field_det aidet
                     WHERE ai.id_advanced_input = i_id_advanced_input
                       AND aisi.id_advanced_input = ai.id_advanced_input
                       AND aif.id_advanced_input_field = aisi.id_advanced_input_field
                       AND aisi.id_institution IN (i_prof.institution, g_all_institution)
                       AND aisi.id_software IN (i_prof.software, g_all_software)
                       AND aidet.id_advanced_input_field(+) = aif.id_advanced_input_field) adv_input,
                   TABLE(get_adv_input_field_value(i_lang,
                                                   i_prof,
                                                   adv_input.id_advanced_input,
                                                   i_flg_type,
                                                   i_id_adv_input_link)) val
             WHERE val.id_advanced_input(+) = adv_input.id_advanced_input
               AND val.id_advanced_input_field(+) = adv_input.id_advanced_input_field
            --AND val.id_advanced_input_field_det(+) = adv_input.id_advanced_input_field_det
            ---------------------------------------------------------------------
             ORDER BY adv_input.id_advanced_input,
                      adv_input.id_advanced_input_field,
                      adv_input.id_advanced_input_field_det;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_ADVANCED_INPUT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_fields);
            pk_types.open_my_cursor(o_fields_det);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_advanced_input;

    /**
     * Get field's value for the Advanced Input of guidelines
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced Input ID
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADV_INPUT_LINK      Tasks or Criterias links to get advanced input data
     *
     * @return                         type t_coll_guidelines_adv_input (PIPELINED)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    */
    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN guideline_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number
    ) RETURN t_coll_guidelines_adv_input
        PIPELINED IS
    
        rec_out t_rec_guidelines_adv_input := t_rec_guidelines_adv_input(NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         current_timestamp);
    
        CURSOR c_fields IS
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aidet.id_advanced_input_field_det,
                   --
                   guid_advinput_val.id_adv_input_link,
                   guid_advinput_val.flg_type,
                   guid_advinput_val.value_type,
                   guid_advinput_val.dvalue,
                   guid_advinput_val.nvalue,
                   guid_advinput_val.vvalue,
                   guid_advinput_val.value_desc,
                   guid_advinput_val.criteria_value_type
              FROM advanced_input_soft_inst ai,
                   guideline_adv_input_value guid_advinput_val,
                   TABLE(i_id_adv_input_link) advinput_link,
                   -------------------------------------------------------------------------
                   (advanced_input_field aif LEFT OUTER JOIN advanced_input_field_det aidet ON
                    aidet.id_advanced_input_field = aif.id_advanced_input_field)
             WHERE ai.id_advanced_input = i_id_advanced_input
               AND ai.id_institution IN (i_prof.institution, g_all_institution)
               AND ai.id_software IN (i_prof.software, g_all_software)
               AND aif.id_advanced_input_field = ai.id_advanced_input_field
                  --
               AND guid_advinput_val.id_adv_input_link = advinput_link.column_value
               AND guid_advinput_val.id_advanced_input = ai.id_advanced_input
               AND guid_advinput_val.id_advanced_input_field = ai.id_advanced_input_field
               AND guid_advinput_val.flg_type = i_flg_type;
    
    BEGIN
    
        g_error := 'GET VALUES FOR ADVANCED INPUT FIELDS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FOR rec IN c_fields
        LOOP
        
            rec_out.id_advanced_input           := rec.id_advanced_input;
            rec_out.id_advanced_input_field     := rec.id_advanced_input_field;
            rec_out.id_advanced_input_field_det := rec.id_advanced_input_field_det;
            rec_out.id_adv_input_link           := rec.id_adv_input_link;
        
            IF (rec.value_type = g_guideline_d_type)
            THEN
                rec_out.value_date := rec.dvalue;
            ELSIF (rec.value_type = g_guideline_n_type)
            THEN
                rec_out.value := rec.nvalue;
            ELSIF (rec.value_type = g_guideline_v_type)
            THEN
                rec_out.value := rec.vvalue;
            END IF;
        
            PIPE ROW(rec_out);
        END LOOP;
        RETURN;
    
    END get_adv_input_field_value;

    /**
     * Set Advanced Input field value for guideline.
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_FLG_TYPE                            Advanced for (C)riterias or (T)asks
     * @param I_ID_GUIDELINE_CRITERIA_LINK          Guideline criteria Link ID
     * @param I_VALUE_TYPE                          Value type : D-Date, V-Varchar N-Number
     * @param I_DVALUE                              Date value
     * @param I_NVALUE                              Number value
     * @param I_VVALUE                              Varchar value
     * @param I_VALUE_DESC                          Value description
     * @param I_CRITERIA_VALUE_TYPE                 Criteria Value Type
     * @param I_ID_ADVANCED_INPUT                   Advanced Input ID
     * @param I_ID_ADVANCED_INPUT_FIELD             Advanced Input Field ID        
     * @param O_ERROR                               Error message
     *
     * @return                         true or false on success or error (BOOLEAN)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/20
    */
    FUNCTION set_guideline_adv_input_value
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_adv_input_link           IN guideline_adv_input_value.id_adv_input_link%TYPE,
        i_flg_type                    IN guideline_adv_input_value.flg_type%TYPE,
        i_value_type                  IN table_varchar,
        i_dvalue                      IN table_date,
        i_nvalue                      IN table_number,
        i_vvalue                      IN table_varchar,
        i_value_desc                  IN table_varchar,
        i_criteria_value_type         IN table_number,
        i_id_advanced_input           IN table_number,
        i_id_advanced_input_field     IN table_number,
        i_id_advanced_input_field_det IN table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'INSERT ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        BEGIN
            FORALL i IN i_value_type.first .. i_value_type.last SAVE EXCEPTIONS
                INSERT INTO guideline_adv_input_value
                    (id_guideline_adv_input_value,
                     id_adv_input_link,
                     flg_type,
                     value_type,
                     nvalue,
                     dvalue,
                     vvalue,
                     value_desc,
                     criteria_value_type,
                     id_advanced_input,
                     id_advanced_input_field,
                     id_advanced_input_field_det)
                VALUES
                    (seq_guideline_adv_input_value.nextval,
                     i_id_adv_input_link,
                     i_flg_type,
                     i_value_type(i),
                     i_nvalue(i),
                     i_dvalue(i),
                     i_vvalue(i),
                     i_value_desc(i),
                     i_criteria_value_type(i),
                     i_id_advanced_input(i),
                     i_id_advanced_input_field(i),
                     i_id_advanced_input_field_det(i));
        EXCEPTION
            WHEN dml_errors THEN
                RAISE dml_errors;
            
        END;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        -- Error on new advanced input values insertion
        WHEN dml_errors THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_ADV_INPUT_VALUE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_ADV_INPUT_VALUE',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_adv_input_value;

    /** 
    *  Get all recommended guidelines
    *
    * @param      I_LANG                           Preferred language ID for this professional
    * @param      I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                     Episode ID
    * @param      I_VALUE_PAT_NAME_SEARCH          String to search for patient name
    * @param      I_VALUE_RECOM_GUIDELINES_SEARCH  String to search for recommended guidelines
    * @param      I_VALUE_GUIDELINES_TYPE_SEARCH   Sring to search for guidelines type
    * @param      DT_SERVER                        Current server time
    * @param      O_GUIDELINE_RECOMMENDED          Recommended guidelines of all users
    * @param      O_ERROR                          error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/2
    */
    FUNCTION get_all_recommended_guidelines
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_value_pat_name_search    IN VARCHAR2,
        i_value_recom_guide_search IN VARCHAR2,
        i_value_guide_type_search  IN VARCHAR2,
        dt_server                  OUT VARCHAR2,
        o_guidelines_recommended   OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_procs IS
            SELECT id_guideline_process
              FROM guideline_process gp;
    
        CURSOR c_pats
        (
            l_category category.flg_type%TYPE,
            l_hd_type  sys_config.value%TYPE
        ) IS
            SELECT id_patient
              FROM grids_ea gea
             WHERE pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    gea.id_episode,
                                                                                    l_category,
                                                                                    l_hd_type),
                                                i_prof.id) != -1
               AND gea.id_software = i_prof.software
               AND gea.id_institution = i_prof.institution
               AND (gea.id_episode, gea.id_patient) NOT IN
                   (SELECT gp.id_episode, gp.id_patient
                      FROM guideline_process gp);
    
        b_result BOOLEAN;
        l_cat    category.flg_type%TYPE;
        error_undefined EXCEPTION;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        -- verify professionals category
        l_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'DELETE TEMPORARY TABLE';
        DELETE FROM tbl_temp;
    
        -- verify if any guideline should be automatically recommended to the all the doctors patients
        -- Because this is done only when the deepnav is pressed it had also to be called here
        FOR r_pats IN c_pats(l_cat, l_handoff_type)
        LOOP
            b_result := run_batch_internal(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_patient         => r_pats.id_patient,
                                           i_batch_desc         => 'GET_RECOM_GUID',
                                           i_id_guideline       => NULL,
                                           i_flg_create_process => FALSE,
                                           --Do not create guideline process
                                           o_error => o_error);
        
        END LOOP;
    
        -- Because the use of the temporary table is only for the list of the patients and guidelines list
        -- no cursor is passed between the functions
    
        IF (i_value_pat_name_search IS NULL AND i_value_recom_guide_search IS NULL AND
           i_value_guide_type_search IS NULL)
        THEN
            g_error := 'UPDATE STATE OF ALL GUIDELINE PROCESSES AND ASSOCIATED TASKS';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            FOR rec IN c_procs
            LOOP
            
                b_result := update_guide_proc_task_status(i_lang, i_prof, rec.id_guideline_process, o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            
                b_result := update_guide_proc_status(i_lang, i_prof, rec.id_guideline_process, o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            END LOOP;
        
            COMMIT;
        END IF;
    
        g_error := 'GET ALL RECOMMENDED GUIDELINES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guidelines_recommended FOR
        -- Hints were added to the query to remove full in patient table
            SELECT *
              FROM (SELECT /*+ ordered use_nl(guid gp pat)*/
                     guid.id_guideline,
                     gea.id_episode,
                     gp.id_guideline_process,
                     gp.id_patient,
                     gp.flg_status,
                     pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline, gp.flg_status) AS rank,
                     pk_patient.get_pat_name(i_lang, i_prof, gp.id_patient, gea.id_episode, NULL) AS pat_name,
                     pk_patient.get_pat_name_to_sort(i_lang, i_prof, gp.id_patient, gea.id_episode, NULL) AS pat_name_sort,
                     pat.gender AS pat_gender,
                     pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) AS pat_age,
                     pk_patphoto.get_pat_photo(i_lang, i_prof, gp.id_patient, gea.id_episode, gea.id_schedule) AS pat_photo,
                     --get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator) AS guideline_desc,
                     guid.guideline_desc AS guideline_desc,
                     get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) AS guideline_typ,
                     
                     '0' || '|' || 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' ||
                     decode(pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, gp.flg_status),
                            g_alert_icon,
                            g_red_color,
                            g_waiting_icon,
                            g_red_color,
                            NULL) || '|' || pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, gp.flg_status) || '|' || NULL AS status,
                     g_guideline_shortcut AS guideline_shortcut,
                     gea.id_professional,
                     gea.id_first_nurse_resp
                      FROM guideline guid
                      JOIN guideline_process gp
                        ON guid.id_guideline = gp.id_guideline
                      JOIN patient pat
                        ON pat.id_patient = gp.id_patient
                      JOIN grids_ea gea
                        ON gea.id_patient = pat.id_patient
                     WHERE gea.id_software = i_prof.software
                       AND gea.id_institution = i_prof.institution
                       AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                            i_prof,
                                                                                            gea.id_episode,
                                                                                            l_cat,
                                                                                            l_handoff_type),
                                                        i_prof.id) != -1
                    UNION
                    -- This cursor is to search for all recomended guidelines that are still not 
                    -- associated with the patient record
                    -- All records will have 'g_process_recommended' for status
                    -- NUM_1 is for id_guideline
                    -- NUM_2 is for id_patient
                    SELECT /*+ ordered use_nl(guid gp pat)*/
                     tt.num_1 id_guideline,
                     gea.id_episode,
                     NULL id_guideline_process,
                     tt.num_2 id_patient,
                     g_process_recommended flg_status,
                     pk_sysdomain.get_rank(i_lang, g_domain_flg_guideline, g_process_recommended) AS rank,
                     pk_patient.get_pat_name(i_lang, i_prof, gea.id_patient, gea.id_episode, NULL) AS pat_name,
                     pk_patient.get_pat_name_to_sort(i_lang, i_prof, gea.id_patient, gea.id_episode, NULL) AS pat_name_sort,
                     pat.gender AS pat_gender,
                     pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) AS pat_age,
                     decode(pk_patphoto.check_blob(pat.id_patient),
                            'N',
                            '',
                            pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) AS pat_photo,
                     --get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_pathol, g_separator) AS guideline_desc,
                     guid.guideline_desc AS guideline_desc,
                     get_link_id_str(i_lang, i_prof, guid.id_guideline, g_guide_link_type, g_separator) AS guideline_typ,
                     
                     '0' || '|' || 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' ||
                     decode(pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, g_process_recommended),
                            g_alert_icon,
                            g_red_color,
                            g_waiting_icon,
                            g_red_color,
                            NULL) || '|' || pk_sysdomain.get_img(i_lang, g_domain_flg_guideline, g_process_recommended) || '|' || NULL AS status,
                     NULL AS guideline_shortcut,
                     gea.id_professional id_professional,
                     gea.id_first_nurse_resp id_first_nurse_resp
                      FROM guideline guid
                      JOIN tbl_temp tt
                        ON guid.id_guideline = tt.num_1
                      JOIN patient pat
                        ON pat.id_patient = tt.num_2
                      JOIN grids_ea gea
                        ON gea.id_patient = pat.id_patient
                     WHERE gea.id_software = i_prof.software
                       AND gea.id_institution = i_prof.institution
                       AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                            i_prof,
                                                                                            gea.id_episode,
                                                                                            l_cat,
                                                                                            l_handoff_type),
                                                        i_prof.id) != -1)
             WHERE ((translate(upper(pat_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' ||
                   translate(upper(i_value_pat_name_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value_pat_name_search IS NOT NULL) OR i_value_pat_name_search IS NULL)
               AND ((translate(upper(guideline_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value_recom_guide_search),
                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND i_value_recom_guide_search IS NOT NULL) OR
                   i_value_recom_guide_search IS NULL)
                  
               AND ((translate(upper(guideline_typ), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value_guide_type_search),
                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND i_value_guide_type_search IS NOT NULL) OR
                   i_value_guide_type_search IS NULL)
             ORDER BY pat_name_sort, rank, guideline_desc, guideline_typ;
    
        -- return server time as close as possible to the end of function
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        -- Error on guideline process status update and its tasks
        WHEN error_undefined THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / Undefined state',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_ALL_RECOMMENDED_GUIDELINES',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines_recommended);
            -- return failure of function
            RETURN FALSE;
        
        -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_ALL_RECOMMENDED_GUIDELINES',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines_recommended);
            -- return failure of function
            RETURN FALSE;
        
    END get_all_recommended_guidelines;

    /********************************************************************************************
    * get all complaints that can be associated to the guidelines
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               guideline id
    * @param      i_value                      search string   
    * @param      o_complaints                 cursor with all complaints that can be associated to the guidelines
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   26-Nov-2010
    ********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_value        IN VARCHAR2,
        o_complaints   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_id_complaints   table_number;
        l_desc_complaints table_varchar;
        l_tbl             t_tbl_guideline_complaints := t_tbl_guideline_complaints();
        l_complaints      pk_types.cursor_type;
    BEGIN
        -- get all complaints that can be used in this (i_prof) hospital group
        IF NOT pk_complaint.get_all_complaints_list(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    o_complaints => l_complaints,
                                                    o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- o_complaints already open
        FETCH l_complaints BULK COLLECT
            INTO l_id_complaints, l_desc_complaints;
        CLOSE l_complaints;
    
        -- loop for all complaints to build t_tbl_guideline_complaints array
        FOR i IN 1 .. l_id_complaints.count
        LOOP
            l_tbl.extend;
            l_tbl(l_tbl.count) := t_rec_guideline_complaints(l_id_complaints(i), l_desc_complaints(i));
        END LOOP;
    
        -- open cursor o_complaints
        OPEN o_complaints FOR
            SELECT /*+opt_estimate(table c rows=1)*/
             c.id_complaint, c.desc_complaint, nvl2(gl.id_guideline_link, g_active, g_inactive) AS flg_select
              FROM TABLE(CAST(l_tbl AS t_tbl_guideline_complaints)) c
              LEFT JOIN guideline_link gl
                ON c.id_complaint = gl.id_link
               AND gl.link_type = g_guide_link_chief_complaint
               AND gl.id_guideline = i_id_guideline
             WHERE i_value IS NULL
                OR (i_value IS NOT NULL AND
                   (translate(upper(c.desc_complaint), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'))
             ORDER BY c.desc_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_COMPLAINT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_complaints);
            RETURN FALSE;
        
    END get_complaint_list;

    /********************************************************************************************
    * set guideline complaints
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               guideline id
    * @param      i_link_complaint             array with complaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   29-Nov-2010
    ********************************************************************************************/
    FUNCTION set_guideline_chief_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_link_complaint IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'delete existing guideline chief complaint links';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        DELETE FROM guideline_link
         WHERE id_guideline = i_id_guideline
           AND link_type = g_guide_link_chief_complaint;
    
        g_error := 'insert new guideline chief complaint links';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        INSERT INTO guideline_link
            (id_guideline_link, id_guideline, id_link, link_type)
            SELECT seq_guideline_link.nextval, i_id_guideline, column_value, g_guide_link_chief_complaint
              FROM TABLE(i_link_complaint);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_CHIEF_COMPLAINT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_guideline_chief_complaint;

    /********************************************************************************************
    * get all filters for frequent guidelines screen
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      i_episode                    episode id    
    * @param      o_filters                    cursor with all filters for frequent guidelines screen
    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   29-Nov-2010
    ********************************************************************************************/
    FUNCTION get_guideline_filters
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_filters OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_complaint          table_number;
        l_has_complaint_results VARCHAR2(1 CHAR);
        l_has_specialty_results VARCHAR2(1 CHAR);
        l_has_results           VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
    
        l_guideline_id         guideline.id_guideline%TYPE;
        l_guideline_title      guideline.guideline_desc%TYPE;
        l_guideline_rank       guideline_frequent.rank%TYPE;
        l_guideline_duplicated VARCHAR2(1 CHAR);
    
        l_most_freq_guidelines pk_types.cursor_type;
    BEGIN
        -- chief complaints filter is only active if patient has an associated active chief complaint
        g_error := 'GET CHIEF COMPLAINT FOR EPISODE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   o_id_complaint => l_id_complaint,
                                                   o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- check if there are order sets for this chief complaint
        IF l_id_complaint IS NOT NULL
           AND l_id_complaint.count > 0
        THEN
        
            IF NOT get_guideline_frequent(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_patient         => i_patient,
                                          i_id_episode         => i_episode,
                                          i_flg_filter         => g_guide_filter_chief_compl,
                                          i_value              => NULL,
                                          o_guideline_frequent => l_most_freq_guidelines,
                                          o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_guidelines
                INTO l_guideline_id, l_guideline_title, l_guideline_rank, l_guideline_duplicated;
        
            IF l_most_freq_guidelines%NOTFOUND
            THEN
                l_has_complaint_results := pk_alert_constant.g_no;
            ELSE
                l_has_complaint_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_guidelines;
        
        ELSE
            l_has_complaint_results := pk_alert_constant.g_no;
        END IF;
    
        -- check if there are order sets for professional specialty
        -- (this ony need to be done if there are no results for chief complaint)
        IF l_has_complaint_results = pk_alert_constant.g_no
        THEN
        
            IF NOT get_guideline_frequent(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_patient         => i_patient,
                                          i_id_episode         => i_episode,
                                          i_flg_filter         => g_guide_filter_specialty,
                                          i_value              => NULL,
                                          o_guideline_frequent => l_most_freq_guidelines,
                                          o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_guidelines
                INTO l_guideline_id, l_guideline_title, l_guideline_rank, l_guideline_duplicated;
        
            IF l_most_freq_guidelines%NOTFOUND
            THEN
                l_has_specialty_results := pk_alert_constant.g_no;
            ELSE
                l_has_specialty_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_guidelines;
        ELSE
            l_has_specialty_results := pk_alert_constant.g_yes;
        END IF;
    
        -- if there are no results for this chief complaint and professional specialty,
        -- check if there are guidelines for this software and institution
        IF l_has_complaint_results = pk_alert_constant.g_no
           AND l_has_specialty_results = pk_alert_constant.g_no
        THEN
        
            IF NOT get_guideline_frequent(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_patient         => i_patient,
                                          i_id_episode         => i_episode,
                                          i_flg_filter         => g_guide_filter_frequent,
                                          i_value              => NULL,
                                          o_guideline_frequent => l_most_freq_guidelines,
                                          o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_guidelines
                INTO l_guideline_id, l_guideline_title, l_guideline_rank, l_guideline_duplicated;
        
            IF l_most_freq_guidelines%NOTFOUND
            THEN
                l_has_results := pk_alert_constant.g_no;
            ELSE
                l_has_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_guidelines;
        ELSE
            l_has_results := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'get o_filters cursor';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_filters FOR
            SELECT sd.val AS id_action,
                   NULL   AS id_parent,
                   1      AS "LEVEL",
                   NULL   AS to_state,
                   -- name for specialty filter may differ from one to other environments
                   decode(sd.val,
                          g_guide_filter_specialty,
                          pk_message.get_message(i_lang, i_prof, 'GUIDELINE_M347'),
                          sd.desc_val) AS desc_action,
                   sd.img_name AS icon,
                   decode(sd.val,
                           g_guide_filter_chief_compl,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END),
                           g_guide_filter_specialty,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_no
                                    AND l_has_specialty_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END),
                           g_guide_filter_frequent,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_no
                                    AND l_has_specialty_results = pk_alert_constant.g_no
                                    AND l_has_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END)) AS flg_default,
                   decode(sd.val,
                          g_guide_filter_chief_compl,
                          decode(l_has_complaint_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          g_guide_filter_specialty,
                          decode(l_has_specialty_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          g_guide_filter_frequent,
                          decode(l_has_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive)) AS flg_active
              FROM sys_domain sd
             WHERE sd.code_domain = 'GUIDELINE_FREQUENT_FILTER'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY sd.rank, sd.desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_FILTERS',
                                              o_error);
            pk_types.open_my_cursor(o_filters);
            RETURN FALSE;
    END get_guideline_filters;

---------------------------------------------------------------------------------------<
---------------------------------------------------------------------------------------<
BEGIN

    -- Guideline type
    g_id_guide_type_any := -1;

    -- Pathology type
    g_id_guide_pathol_any := -1;

    -- Truncate string
    g_trunc_str := '...';

    -- Link types   
    g_guide_link_pathol          := 'H';
    g_guide_link_envi            := 'E';
    g_guide_link_prof            := 'P';
    g_guide_link_spec            := 'S';
    g_guide_link_type            := 'T';
    g_guide_link_edit_prof       := 'D';
    g_guide_link_chief_complaint := 'C';

    -- frequent guideline filter types
    g_guide_filter_chief_compl := 'C';
    g_guide_filter_specialty   := 'S';
    g_guide_filter_frequent    := 'F';

    -- Diagnosis
    g_diag_available  := 'Y';
    g_diag_select     := 'Y';
    g_diag_not_select := 'N';
    g_diag_freq       := 'M';
    g_diag_req        := 'P';
    -- Allergy
    g_ale_available  := 'Y';
    g_ale_select     := 'Y';
    g_ale_not_select := 'N';
    g_ale_freq       := 'M';
    -- Professional
    g_prof_selected := 'S';
    -- Criteria
    g_criteria_type_inc := 'I';
    g_criteria_type_exc := 'E';
    -- Generic
    g_available     := 'Y';
    g_not_available := 'N';
    g_active        := 'A';
    g_inactive      := 'I';

    g_selectedpt     := 'S';
    g_not_selectedpt := 'N';
    g_selected       := 'Y';
    g_not_selected   := 'N';

    g_separator  := ', ';
    g_separator2 := '; ';
    g_separator3 := ';' || chr(10);
    g_bullet     := chr(10) || '- ';

    g_all_institution      := 0;
    g_all_software         := 0;
    g_all_profile_template := 0;
    g_all_markets          := 0;

    -- Criteria states
    g_criteria_already_set      := 1;
    g_criteria_clear            := 0;
    g_criteria_already_crossset := 2;
    g_criteria_group_some       := 3;
    g_criteria_group_all        := 4;
    -- Link State
    g_link_state_new  := 0;
    g_link_state_del  := 1;
    g_link_state_keep := 2;
    -- Guideline state
    g_guideline_temp       := 'T';
    g_guideline_finished   := 'F';
    g_guideline_deleted    := 'C'; -- cancelled
    g_guideline_deprecated := 'D';
    -- Bulk fetch limit
    g_bulk_fetch_rows := 100;
    -- Other criteria type
    g_guideline_allergies       := 1;
    g_guideline_analysis        := 2;
    g_guideline_diagnosis       := 3;
    g_guideline_exams           := 4;
    g_guideline_drug            := 5;
    g_guideline_other_exams     := 6;
    g_guideline_diagnosis_nurse := 7;

    -- TASK TYPE
    g_all_tasks := 0;
    -- analysis
    g_task_analysis := 1;
    -- Consultas
    g_task_appoint := 2;
    -- patient education
    g_task_patient_education := 3;
    -- Imagem
    g_task_img := 4;
    -- imunizações
    g_task_vacc := 5;
    -- Intervenções de enfermagem
    g_task_enfint := 6;
    -- medicação : Local
    g_task_drug := 7;
    -- outros exames
    g_task_otherexam := 8;
    -- pareceres
    g_task_spec := 9;
    -- rastreios    
    g_task_rast := 10;
    -- medicação : exterior
    g_task_drug_ext := 11;
    -- procedimentos
    g_task_proc := 12;
    -- soros
    g_task_fluid := 13;
    -- monitorizacoes
    g_task_monitorization := 14;
    -- consultas de especialidade
    g_task_specialty_appointment := 15;

    -- CRITERIA
    -- idade
    g_crit_age := -1;
    -- peso
    g_crit_weight := -2;
    -- altura
    g_crit_height := -3;
    -- IMC (índice de massa corporal)
    g_crit_imc := -4;
    -- Pressão arterial sistólica
    g_crit_sistolic_blood_press := -5;
    -- Pressão arterial diastólica
    g_crit_diastolic_blood_press := -6;

    -- gender
    g_gender_male   := 'M';
    g_gender_female := 'F';
    -- Exam Types
    g_exam_only_img := 'I';
    -- Image status 
    g_img_inactive := 'I';
    g_img_active   := 'A';

    -- State of process / process task
    g_process_pending     := 'P';
    g_process_recommended := 'R';
    g_process_running     := 'E';
    g_process_finished    := 'F';
    g_process_suspended   := 'S';
    g_process_canceled    := 'C';
    g_process_scheduled   := 'H';
    g_process_closed      := 'O';

    -- Weights of process states
    g_process_running_weight     := 7;
    g_process_recommended_weight := 6;
    g_process_pending_weight     := 5;
    g_process_scheduled_weight   := 4;
    g_process_finished_weight    := 3;
    g_process_suspended_weight   := 2;
    g_process_canceled_weight    := 1;
    g_process_closed_weight      := 1;

    -- Task process action
    g_task_exec     := 'E';
    g_task_inform   := 'I';
    g_task_executed := 'F';
    -- IMC values
    g_imc_weight_default_um     := 10;
    g_imc_height_default_um     := 12;
    g_blood_pressure_default_um := 6;

    -- Vital sign criterias
    g_weight_measure           := 29;
    g_height_measure           := 30;
    g_blood_pressure_s_measure := 6;
    g_blood_pressure_d_measure := 7;
    g_blood_pressure_measure   := 28;

    -- Active states for measures
    g_patient_active := 'A';
    g_measure_active := 'A';
    -- Min and max biometric values 
    g_max_age              := 100000;
    g_min_age              := -100000;
    g_min_height           := -100000;
    g_max_height           := 100000;
    g_min_weight           := -100000;
    g_max_weight           := 100000;
    g_min_imc              := -100000;
    g_max_imc              := 100000;
    g_min_blood_pressure_s := -100000;
    g_max_blood_pressure_s := 100000;
    g_min_blood_pressure_d := -100000;
    g_max_blood_pressure_d := 100000;
    -- Batch types
    g_batch_all   := 'A'; -- all guidelines / all patients
    g_batch_1p_ag := 'P'; -- one user /all guidelines
    g_batch_1p_1g := 'O'; -- one user /one guidelines
    g_batch_ap_1g := 'G'; -- all users /one guidelines

    -- Process status
    g_process_active   := 'A';
    g_process_inactive := 'I';

    -- Pat Allergy flg_status
    g_allergy_active  := 'A';
    g_allergy_passive := 'P';
    -- Nurse diagnosis flg_status
    g_nurse_active := 'A';
    g_nurse_solved := 'S';
    -- Cancel flag
    g_cancelled     := 'Y';
    g_not_cancelled := 'N';

    -- Analysis criteria
    g_analysis_available := 'Y';
    g_analysis_selected  := 'S';
    g_samp_type_avail    := 'Y';

    -- Nurse diagnosis criteria
    g_composition_diag_type := 'D';

    -- Exams
    g_exam_type_img            := 'I';
    g_exam_can_req             := 'P';
    g_exam_available           := 'Y';
    g_exam_freq                := 'M';
    g_exam_selected            := 'S';
    g_exam_pregnant_ultrasound := 'U';

    -- Tasks and guidelines action domais
    g_guideline_actions := 'GUIDELINES';
    g_task_actions      := 'GUIDELINE_TASKS';
    -- Domains in SYS_DOMAIN
    --g_domain_gender     := 'GUIDELINE_CRITERIA.GENDER';
    g_domain_gender     := 'PATIENT.GENDER';
    g_domain_type_media := 'GUIDELINE_CONTEXT.CONTEXT_TYPE_MEDIA';

    g_domain_inc_gen := 'GUIDELINE_CRITERIA.INCLUSION';
    g_domain_exc_gen := 'GUIDELINE_CRITERIA.EXCLUSION';

    g_domain_flg_guideline      := 'GUIDELINE_PROCESS.FLG_STATUS';
    g_domain_flg_guideline_task := 'GUIDELINE_PROCESS_TASK.FLG_STATUS';
    g_domain_task_type          := 'GUIDELINE_TASK_LINK.TASK_TYPE';
    g_domain_flg_type_rec       := 'GUIDELINE.FLG_TYPE_RECOMMENDATION';

    g_domain_language            := 'LANGUAGE';
    g_domain_professional_title  := 'PROFESSIONAL.TITLE';
    g_domain_allergy_type        := 'PAT_ALLERGY.FLG_TYPE';
    g_domain_allergy_status      := 'PAT_ALLERGY.FLG_STATUS';
    g_domain_diagnosis_status    := 'PAT_PROBLEM.FLG_STATUS';
    g_domain_diagnosis_nature    := 'PAT_PROBLEM.FLG_NATURE';
    g_domain_nurse_diag_status   := 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS';
    g_domain_adv_input_freq      := 'GUIDELINE_ADV_INPUT_VALUE.FREQUENCY';
    g_domain_adv_input_flg_type  := 'GUIDELINE_ADV_INPUT_VALUE.FLG_TYPE';
    g_domain_guideline_item_type := 'GUIDELINE_ITEM_SOFT_INST.FLG_ITEM_TYPE';

    g_domain_take    := 'DRUG_PRESC_DET.FLG_TAKE_TYPE';
    g_domain_time    := 'DRUG_PRESCRIPTION.FLG_TIME';
    g_domain_status  := 'DRUG_PRESC_DET.FLG_STATUS';
    g_presc_flg_type := 'PRESCRIPTION.FLG_TYPE';

    g_alert_icon   := 'AlertIcon';
    g_waiting_icon := 'WaitingIcon';

    g_unknown_link_type   := 'Unknown Link Type';
    g_unknown_detail_type := 'Unknown Detail Type';

    g_close_task             := 'O';
    g_cancel_task            := 'C';
    g_cancel_guideline       := 'C';
    g_state_cancel_operation := -1978;

    -- Drug external
    g_yes := 'Y';
    g_no  := 'N';

    -- Local drug
    g_drug             := 'M';
    g_det_req          := 'R';
    g_det_pend         := 'D';
    g_det_exe          := 'E';
    g_drug_presc_det_a := 'A';
    g_flg_time_epis    := 'E';
    g_flg_freq         := 'M';

    g_sch  := 'SCH_Todos';
    g_cipe := 'TodasEspecialidadesCIPE';

    -- Advanced Input type
    g_adv_input_type_tasks     := 'T';
    g_adv_input_type_criterias := 'C';

    -- Criteria Value
    g_guideline_d_type := 'D';
    g_guideline_n_type := 'N';
    g_guideline_v_type := 'V';

    -- Keypad Date 
    g_date_keypad := 'DT';

    -- Boolean values
    g_true  := 'T';
    g_false := 'F';

    -- Edit Guideline options
    g_message_edit_guideline      := 'GUIDELINE_M066';
    g_message_create_guideline    := 'GUIDELINE_M065';
    g_message_duplicate_guideline := 'GUIDELINE_M068';
    g_edit_guideline_option       := 'E';
    g_create_guideline_option     := 'C';
    g_duplicate_guideline_option  := 'D';

    -- Guideline edit options
    g_guideline_editable   := 'E';
    g_guideline_duplicable := 'D';
    g_guideline_viewable   := 'V';

    g_message_any       := 'GUIDELINE_M333';
    g_message_scheduled := 'ICON_T056';

    -- Guideline type recommendation
    g_default_type_rec   := 'M';
    g_type_rec_manual    := 'M';
    g_type_rec_automatic := 'A';

    -- Process task details type
    g_proc_task_det_freq     := 'F';
    g_proc_task_det_next_rec := 'R';

    -- Advanced input field ID
    g_frequency_field              := 30;
    g_allergy_status_field         := 31;
    g_allergy_react_field          := 32;
    g_diagnosis_status_field       := 33;
    g_diagnosis_nature_field       := 34;
    g_nurse_diagnosis_status_field := 35;

    -- Type of patient problems
    g_pat_probl_not_capable := 'I';

    -- Appointments specialties
    g_prof_active             := 'A';
    g_external_appoint        := 'C';
    g_message_spec_appoint    := 'GUIDELINE_M069';
    g_message_foll_up_appoint := 'GUIDELINE_M067';

    -- Error message
    g_message_error := 'COMMON_M001';

    -- All message
    g_message_all := 'COMMON_M014';

    -- NOTES message
    g_message_notes := 'GUIDELINE_M079';

    -- Opinion message
    g_message_opinion_any_prof := 'OPINION_M001';

    -- NA message
    g_message_na := 'COMMON_M036';

    -- CONFIGS in SYS_CONFIG
    g_config_func_consult_req := 'FUNCTIONALITY_CONSULT_REQ';

    g_config_func_opinion    := 'FUNCTIONALITY_OPINION';
    g_config_max_diag_rownum := 'NUM_RECORD_SEARCH';

    -- Action subjects
    g_action_guideline_tasks := 'GUIDELINE_TASKS';

    -- Icon colors
    g_green_color := 'G';
    g_red_color   := 'R';

    -- State symbols
    g_icon      := 'I';
    g_text_icon := 'TI';
    g_text      := 'T';
    g_date      := 'D';

    -- Type guideline items
    g_guideline_item_tasks    := 'T';
    g_guideline_item_criteria := 'C';

    -- Task frequency
    g_task_unique_freq := 0;

    -- Schedule task
    g_scheduled     := 'Y';
    g_not_scheduled := 'N';

    -- Tasks request
    g_img_request       := 'P';
    g_otherexam_request := 'P';
    g_proc_request      := 'P';
    g_drug_request      := 'P';
    g_drug_ext_request  := 'P';
    -- Predefined guideline authors
    g_message_guideline_authors := 'GUIDELINE_M080';

    -- Any criteria detail value
    g_detail_any := -1;

    -- Pregnancy process
    g_pregnancy_process_active := 'A';

    -- Shortcut for guidelines
    g_guideline_shortcut := 656;

    -- Logging mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);

END pk_guidelines;
/
